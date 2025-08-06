# app/core/retry.py
import asyncio
import random
import time
from typing import Any, Callable, Optional, Type, Union, List
from functools import wraps
from enum import Enum

from .logging_config import get_logger
from .errors import (
    TugException, 
    ExternalServiceException, 
    DatabaseException, 
    ErrorCode
)

logger = get_logger(__name__)

class RetryStrategy(str, Enum):
    """Retry strategy types"""
    FIXED = "fixed"
    EXPONENTIAL = "exponential"
    LINEAR = "linear"
    RANDOM = "random"

class CircuitBreakerState(str, Enum):
    """Circuit breaker states"""
    CLOSED = "closed"      # Normal operation
    OPEN = "open"          # Failing, reject requests
    HALF_OPEN = "half_open" # Testing if service recovered

class RetryConfig:
    """Configuration for retry behavior"""
    
    def __init__(
        self,
        max_attempts: int = 3,
        base_delay: float = 1.0,
        max_delay: float = 60.0,
        strategy: RetryStrategy = RetryStrategy.EXPONENTIAL,
        backoff_multiplier: float = 2.0,
        jitter: bool = True,
        retryable_exceptions: Optional[List[Type[Exception]]] = None,
        non_retryable_exceptions: Optional[List[Type[Exception]]] = None
    ):
        self.max_attempts = max_attempts
        self.base_delay = base_delay
        self.max_delay = max_delay
        self.strategy = strategy
        self.backoff_multiplier = backoff_multiplier
        self.jitter = jitter
        self.retryable_exceptions = retryable_exceptions or [
            ConnectionError,
            TimeoutError,
            ExternalServiceException,
            DatabaseException
        ]
        self.non_retryable_exceptions = non_retryable_exceptions or [
            ValueError,
            TypeError,
            KeyError
        ]
    
    def is_retryable(self, exception: Exception) -> bool:
        """Check if exception is retryable"""
        # Check non-retryable exceptions first
        for exc_type in self.non_retryable_exceptions:
            if isinstance(exception, exc_type):
                return False
        
        # Check retryable exceptions
        for exc_type in self.retryable_exceptions:
            if isinstance(exception, exc_type):
                return True
        
        # For TugException, check specific error codes
        if isinstance(exception, TugException):
            non_retryable_codes = {
                ErrorCode.INVALID_CREDENTIALS,
                ErrorCode.INSUFFICIENT_PERMISSIONS,
                ErrorCode.VALIDATION_ERROR,
                ErrorCode.BUSINESS_RULE_VIOLATION,
                ErrorCode.RESOURCE_NOT_FOUND
            }
            return exception.code not in non_retryable_codes
        
        return False
    
    def calculate_delay(self, attempt: int) -> float:
        """Calculate delay for given attempt"""
        if self.strategy == RetryStrategy.FIXED:
            delay = self.base_delay
        elif self.strategy == RetryStrategy.LINEAR:
            delay = self.base_delay * attempt
        elif self.strategy == RetryStrategy.EXPONENTIAL:
            delay = self.base_delay * (self.backoff_multiplier ** (attempt - 1))
        elif self.strategy == RetryStrategy.RANDOM:
            delay = random.uniform(self.base_delay, self.max_delay)
        else:
            delay = self.base_delay
        
        # Apply jitter to prevent thundering herd
        if self.jitter and self.strategy != RetryStrategy.RANDOM:
            jitter_range = delay * 0.1  # 10% jitter
            delay += random.uniform(-jitter_range, jitter_range)
        
        return min(delay, self.max_delay)

class CircuitBreaker:
    """Circuit breaker implementation for fault tolerance"""
    
    def __init__(
        self,
        failure_threshold: int = 5,
        recovery_timeout: float = 60.0,
        expected_exception: Type[Exception] = Exception
    ):
        self.failure_threshold = failure_threshold
        self.recovery_timeout = recovery_timeout
        self.expected_exception = expected_exception
        
        self.failure_count = 0
        self.last_failure_time: Optional[float] = None
        self.state = CircuitBreakerState.CLOSED
    
    def __enter__(self):
        if self.state == CircuitBreakerState.OPEN:
            if self._should_attempt_reset():
                logger.info("Circuit breaker attempting reset to HALF_OPEN")
                self.state = CircuitBreakerState.HALF_OPEN
            else:
                raise ExternalServiceException(
                    service="circuit_breaker",
                    message="Service is currently unavailable (circuit breaker open)"
                )
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        if exc_type is None:
            # Success
            self._on_success()
        elif issubclass(exc_type, self.expected_exception):
            # Expected failure
            self._on_failure()
        # Unexpected exceptions are not counted as failures
    
    def _should_attempt_reset(self) -> bool:
        """Check if circuit breaker should attempt reset"""
        return (
            self.last_failure_time is not None and
            time.time() - self.last_failure_time >= self.recovery_timeout
        )
    
    def _on_success(self):
        """Handle successful operation"""
        logger.info(f"Circuit breaker success - state: {self.state}")
        self.failure_count = 0
        self.state = CircuitBreakerState.CLOSED
    
    def _on_failure(self):
        """Handle failed operation"""
        self.failure_count += 1
        self.last_failure_time = time.time()
        
        logger.warning(f"Circuit breaker failure {self.failure_count}/{self.failure_threshold}")
        
        if self.failure_count >= self.failure_threshold:
            logger.error("Circuit breaker opened due to too many failures")
            self.state = CircuitBreakerState.OPEN

def with_retry(
    config: Optional[RetryConfig] = None,
    circuit_breaker: Optional[CircuitBreaker] = None
):
    """Decorator for adding retry logic to functions"""
    
    if config is None:
        config = RetryConfig()
    
    def decorator(func: Callable) -> Callable:
        if asyncio.iscoroutinefunction(func):
            @wraps(func)
            async def async_wrapper(*args, **kwargs):
                return await _retry_async(func, config, circuit_breaker, *args, **kwargs)
            return async_wrapper
        else:
            @wraps(func)
            def sync_wrapper(*args, **kwargs):
                return _retry_sync(func, config, circuit_breaker, *args, **kwargs)
            return sync_wrapper
    
    return decorator

async def _retry_async(
    func: Callable,
    config: RetryConfig,
    circuit_breaker: Optional[CircuitBreaker],
    *args,
    **kwargs
) -> Any:
    """Execute async function with retry logic"""
    
    last_exception = None
    
    for attempt in range(1, config.max_attempts + 1):
        try:
            # Use circuit breaker if provided
            if circuit_breaker:
                with circuit_breaker:
                    result = await func(*args, **kwargs)
            else:
                result = await func(*args, **kwargs)
            
            # Success - log if this wasn't the first attempt
            if attempt > 1:
                logger.info(
                    f"Function {func.__name__} succeeded on attempt {attempt}",
                    extra={
                        'function': func.__name__,
                        'attempt': attempt,
                        'total_attempts': config.max_attempts
                    }
                )
            
            return result
            
        except Exception as exc:
            last_exception = exc
            
            # Check if exception is retryable
            if not config.is_retryable(exc):
                logger.warning(
                    f"Non-retryable exception in {func.__name__}: {str(exc)}",
                    extra={
                        'function': func.__name__,
                        'exception_type': type(exc).__name__,
                        'attempt': attempt
                    }
                )
                raise exc
            
            # Don't retry on last attempt
            if attempt == config.max_attempts:
                logger.error(
                    f"Function {func.__name__} failed after {attempt} attempts",
                    extra={
                        'function': func.__name__,
                        'attempts': attempt,
                        'final_exception': str(exc)
                    },
                    exc_info=True
                )
                raise exc
            
            # Calculate delay and wait
            delay = config.calculate_delay(attempt)
            
            logger.warning(
                f"Function {func.__name__} failed on attempt {attempt}, retrying in {delay:.2f}s",
                extra={
                    'function': func.__name__,
                    'attempt': attempt,
                    'delay_seconds': delay,
                    'exception': str(exc),
                    'exception_type': type(exc).__name__
                }
            )
            
            await asyncio.sleep(delay)
    
    # This should never be reached, but just in case
    raise last_exception

def _retry_sync(
    func: Callable,
    config: RetryConfig,
    circuit_breaker: Optional[CircuitBreaker],
    *args,
    **kwargs
) -> Any:
    """Execute sync function with retry logic"""
    
    last_exception = None
    
    for attempt in range(1, config.max_attempts + 1):
        try:
            # Use circuit breaker if provided
            if circuit_breaker:
                with circuit_breaker:
                    result = func(*args, **kwargs)
            else:
                result = func(*args, **kwargs)
            
            # Success - log if this wasn't the first attempt
            if attempt > 1:
                logger.info(
                    f"Function {func.__name__} succeeded on attempt {attempt}",
                    extra={
                        'function': func.__name__,
                        'attempt': attempt,
                        'total_attempts': config.max_attempts
                    }
                )
            
            return result
            
        except Exception as exc:
            last_exception = exc
            
            # Check if exception is retryable
            if not config.is_retryable(exc):
                logger.warning(
                    f"Non-retryable exception in {func.__name__}: {str(exc)}",
                    extra={
                        'function': func.__name__,
                        'exception_type': type(exc).__name__,
                        'attempt': attempt
                    }
                )
                raise exc
            
            # Don't retry on last attempt
            if attempt == config.max_attempts:
                logger.error(
                    f"Function {func.__name__} failed after {attempt} attempts",
                    extra={
                        'function': func.__name__,
                        'attempts': attempt,
                        'final_exception': str(exc)
                    },
                    exc_info=True
                )
                raise exc
            
            # Calculate delay and wait
            delay = config.calculate_delay(attempt)
            
            logger.warning(
                f"Function {func.__name__} failed on attempt {attempt}, retrying in {delay:.2f}s",
                extra={
                    'function': func.__name__,
                    'attempt': attempt,
                    'delay_seconds': delay,
                    'exception': str(exc),
                    'exception_type': type(exc).__name__
                }
            )
            
            time.sleep(delay)
    
    # This should never be reached, but just in case
    raise last_exception

# Predefined retry configurations
class RetryConfigs:
    """Predefined retry configurations for common scenarios"""
    
    # Database operations
    DATABASE = RetryConfig(
        max_attempts=3,
        base_delay=0.5,
        max_delay=5.0,
        strategy=RetryStrategy.EXPONENTIAL,
        retryable_exceptions=[ConnectionError, TimeoutError, DatabaseException]
    )
    
    # External API calls
    EXTERNAL_API = RetryConfig(
        max_attempts=5,
        base_delay=1.0,
        max_delay=30.0,
        strategy=RetryStrategy.EXPONENTIAL,
        retryable_exceptions=[ConnectionError, TimeoutError, ExternalServiceException]
    )
    
    # File operations
    FILE_OPERATIONS = RetryConfig(
        max_attempts=3,
        base_delay=0.1,
        max_delay=1.0,
        strategy=RetryStrategy.LINEAR,
        retryable_exceptions=[OSError, IOError]
    )
    
    # Network operations
    NETWORK = RetryConfig(
        max_attempts=4,
        base_delay=2.0,
        max_delay=15.0,
        strategy=RetryStrategy.EXPONENTIAL,
        jitter=True,
        retryable_exceptions=[ConnectionError, TimeoutError]
    )