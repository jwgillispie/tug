# app/core/graceful_degradation.py
import asyncio
import time
from typing import Any, Callable, Optional, Dict, TypeVar, Generic
from functools import wraps
from enum import Enum

from .logging_config import get_logger
from .errors import ExternalServiceException, TugException, ErrorCode

logger = get_logger(__name__)

T = TypeVar('T')

class ServiceHealth(str, Enum):
    """Service health status"""
    HEALTHY = "healthy"
    DEGRADED = "degraded"
    UNHEALTHY = "unhealthy"
    UNKNOWN = "unknown"

class ServiceStatus:
    """Track service health and performance"""
    
    def __init__(self, name: str, unhealthy_threshold: int = 5, degraded_threshold: int = 3):
        self.name = name
        self.health = ServiceHealth.UNKNOWN
        self.failure_count = 0
        self.success_count = 0
        self.last_check = time.time()
        self.last_success = None
        self.last_failure = None
        self.unhealthy_threshold = unhealthy_threshold
        self.degraded_threshold = degraded_threshold
        self.response_times = []  # Track last 10 response times
        self.max_response_times = 10
    
    def record_success(self, response_time: float = None):
        """Record a successful operation"""
        self.success_count += 1
        self.last_success = time.time()
        self.last_check = time.time()
        
        if response_time is not None:
            self.response_times.append(response_time)
            if len(self.response_times) > self.max_response_times:
                self.response_times.pop(0)
        
        # Reset failure count on success
        if self.failure_count > 0:
            self.failure_count = max(0, self.failure_count - 1)
        
        self._update_health()
    
    def record_failure(self, error: Exception = None):
        """Record a failed operation"""
        self.failure_count += 1
        self.last_failure = time.time()
        self.last_check = time.time()
        
        logger.warning(
            f"Service {self.name} failure recorded",
            extra={
                'service': self.name,
                'failure_count': self.failure_count,
                'error': str(error) if error else None
            }
        )
        
        self._update_health()
    
    def _update_health(self):
        """Update health status based on failure count"""
        if self.failure_count >= self.unhealthy_threshold:
            self.health = ServiceHealth.UNHEALTHY
        elif self.failure_count >= self.degraded_threshold:
            self.health = ServiceHealth.DEGRADED
        else:
            self.health = ServiceHealth.HEALTHY
        
        logger.info(
            f"Service {self.name} health updated to {self.health.value}",
            extra={
                'service': self.name,
                'health': self.health.value,
                'failure_count': self.failure_count,
                'success_count': self.success_count
            }
        )
    
    def is_healthy(self) -> bool:
        """Check if service is healthy"""
        return self.health == ServiceHealth.HEALTHY
    
    def is_degraded(self) -> bool:
        """Check if service is degraded"""
        return self.health == ServiceHealth.DEGRADED
    
    def is_unhealthy(self) -> bool:
        """Check if service is unhealthy"""
        return self.health == ServiceHealth.UNHEALTHY
    
    def get_average_response_time(self) -> Optional[float]:
        """Get average response time from recent operations"""
        if not self.response_times:
            return None
        return sum(self.response_times) / len(self.response_times)
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for monitoring"""
        return {
            'name': self.name,
            'health': self.health.value,
            'failure_count': self.failure_count,
            'success_count': self.success_count,
            'last_check': self.last_check,
            'last_success': self.last_success,
            'last_failure': self.last_failure,
            'average_response_time': self.get_average_response_time()
        }

class GracefulDegradationManager:
    """Manage graceful degradation for multiple services"""
    
    def __init__(self):
        self._services: Dict[str, ServiceStatus] = {}
        self._fallback_handlers: Dict[str, Callable] = {}
    
    def register_service(
        self, 
        name: str, 
        unhealthy_threshold: int = 5, 
        degraded_threshold: int = 3
    ) -> ServiceStatus:
        """Register a service for monitoring"""
        service = ServiceStatus(name, unhealthy_threshold, degraded_threshold)
        self._services[name] = service
        
        logger.info(
            f"Registered service for graceful degradation: {name}",
            extra={
                'service': name,
                'unhealthy_threshold': unhealthy_threshold,
                'degraded_threshold': degraded_threshold
            }
        )
        
        return service
    
    def register_fallback(self, service_name: str, fallback_handler: Callable):
        """Register a fallback handler for a service"""
        self._fallback_handlers[service_name] = fallback_handler
        
        logger.info(
            f"Registered fallback handler for service: {service_name}",
            extra={'service': service_name}
        )
    
    def get_service_status(self, name: str) -> Optional[ServiceStatus]:
        """Get service status"""
        return self._services.get(name)
    
    def get_all_services_status(self) -> Dict[str, Dict[str, Any]]:
        """Get status of all services"""
        return {name: service.to_dict() for name, service in self._services.items()}
    
    def should_degrade(self, service_name: str) -> bool:
        """Check if service should be degraded"""
        service = self._services.get(service_name)
        if not service:
            return False
        
        return service.is_degraded() or service.is_unhealthy()
    
    def get_fallback_handler(self, service_name: str) -> Optional[Callable]:
        """Get fallback handler for service"""
        return self._fallback_handlers.get(service_name)

# Global instance
degradation_manager = GracefulDegradationManager()

def with_graceful_degradation(
    service_name: str,
    fallback_value: Any = None,
    unhealthy_threshold: int = 5,
    degraded_threshold: int = 3,
    timeout_seconds: float = 30.0
):
    """Decorator for graceful degradation"""
    
    def decorator(func: Callable) -> Callable:
        # Register service if not already registered
        if not degradation_manager.get_service_status(service_name):
            degradation_manager.register_service(
                service_name, 
                unhealthy_threshold, 
                degraded_threshold
            )
        
        if asyncio.iscoroutinefunction(func):
            @wraps(func)
            async def async_wrapper(*args, **kwargs):
                return await _execute_with_degradation(
                    func, service_name, fallback_value, timeout_seconds, *args, **kwargs
                )
            return async_wrapper
        else:
            @wraps(func)
            def sync_wrapper(*args, **kwargs):
                return _execute_sync_with_degradation(
                    func, service_name, fallback_value, *args, **kwargs
                )
            return sync_wrapper
    
    return decorator

async def _execute_with_degradation(
    func: Callable,
    service_name: str,
    fallback_value: Any,
    timeout_seconds: float,
    *args,
    **kwargs
) -> Any:
    """Execute async function with graceful degradation"""
    
    service = degradation_manager.get_service_status(service_name)
    start_time = time.time()
    
    # If service is unhealthy, try fallback immediately
    if service and service.is_unhealthy():
        logger.warning(
            f"Service {service_name} is unhealthy, using fallback",
            extra={'service': service_name, 'health': service.health.value}
        )
        
        fallback_handler = degradation_manager.get_fallback_handler(service_name)
        if fallback_handler:
            try:
                return await fallback_handler(*args, **kwargs)
            except Exception as e:
                logger.error(
                    f"Fallback handler failed for service {service_name}",
                    extra={'service': service_name, 'error': str(e)},
                    exc_info=True
                )
        
        return fallback_value
    
    try:
        # Execute with timeout
        result = await asyncio.wait_for(func(*args, **kwargs), timeout=timeout_seconds)
        
        # Record success
        execution_time = time.time() - start_time
        if service:
            service.record_success(execution_time)
        
        return result
        
    except asyncio.TimeoutError:
        if service:
            service.record_failure(TimeoutError(f"Service {service_name} timed out"))
        
        logger.error(
            f"Service {service_name} timed out after {timeout_seconds}s",
            extra={
                'service': service_name,
                'timeout_seconds': timeout_seconds,
                'execution_time': time.time() - start_time
            }
        )
        
        # Try fallback on timeout
        fallback_handler = degradation_manager.get_fallback_handler(service_name)
        if fallback_handler:
            try:
                return await fallback_handler(*args, **kwargs)
            except Exception as e:
                logger.error(
                    f"Fallback handler failed for service {service_name}",
                    extra={'service': service_name, 'error': str(e)},
                    exc_info=True
                )
        
        return fallback_value
        
    except Exception as e:
        if service:
            service.record_failure(e)
        
        logger.error(
            f"Service {service_name} failed",
            extra={
                'service': service_name,
                'error': str(e),
                'execution_time': time.time() - start_time
            },
            exc_info=True
        )
        
        # Try fallback on error
        fallback_handler = degradation_manager.get_fallback_handler(service_name)
        if fallback_handler:
            try:
                return await fallback_handler(*args, **kwargs)
            except Exception as fe:
                logger.error(
                    f"Fallback handler failed for service {service_name}",
                    extra={'service': service_name, 'error': str(fe)},
                    exc_info=True
                )
        
        # If this is a TugException, re-raise it
        if isinstance(e, TugException):
            raise e
        
        # Otherwise, raise as ExternalServiceException
        raise ExternalServiceException(
            service=service_name,
            message=f"Service {service_name} failed: {str(e)}"
        )

def _execute_sync_with_degradation(
    func: Callable,
    service_name: str,
    fallback_value: Any,
    *args,
    **kwargs
) -> Any:
    """Execute sync function with graceful degradation"""
    
    service = degradation_manager.get_service_status(service_name)
    start_time = time.time()
    
    # If service is unhealthy, try fallback immediately
    if service and service.is_unhealthy():
        logger.warning(
            f"Service {service_name} is unhealthy, using fallback",
            extra={'service': service_name, 'health': service.health.value}
        )
        
        fallback_handler = degradation_manager.get_fallback_handler(service_name)
        if fallback_handler:
            try:
                return fallback_handler(*args, **kwargs)
            except Exception as e:
                logger.error(
                    f"Fallback handler failed for service {service_name}",
                    extra={'service': service_name, 'error': str(e)},
                    exc_info=True
                )
        
        return fallback_value
    
    try:
        result = func(*args, **kwargs)
        
        # Record success
        execution_time = time.time() - start_time
        if service:
            service.record_success(execution_time)
        
        return result
        
    except Exception as e:
        if service:
            service.record_failure(e)
        
        logger.error(
            f"Service {service_name} failed",
            extra={
                'service': service_name,
                'error': str(e),
                'execution_time': time.time() - start_time
            },
            exc_info=True
        )
        
        # Try fallback on error
        fallback_handler = degradation_manager.get_fallback_handler(service_name)
        if fallback_handler:
            try:
                return fallback_handler(*args, **kwargs)
            except Exception as fe:
                logger.error(
                    f"Fallback handler failed for service {service_name}",
                    extra={'service': service_name, 'error': str(fe)},
                    exc_info=True
                )
        
        # If this is a TugException, re-raise it
        if isinstance(e, TugException):
            raise e
        
        # Otherwise, raise as ExternalServiceException
        raise ExternalServiceException(
            service=service_name,
            message=f"Service {service_name} failed: {str(e)}"
        )

# Health check endpoint helper
def get_system_health() -> Dict[str, Any]:
    """Get overall system health status"""
    services_status = degradation_manager.get_all_services_status()
    
    overall_health = ServiceHealth.HEALTHY
    unhealthy_services = []
    degraded_services = []
    
    for service_name, status in services_status.items():
        if status['health'] == ServiceHealth.UNHEALTHY.value:
            unhealthy_services.append(service_name)
            overall_health = ServiceHealth.UNHEALTHY
        elif status['health'] == ServiceHealth.DEGRADED.value:
            degraded_services.append(service_name)
            if overall_health == ServiceHealth.HEALTHY:
                overall_health = ServiceHealth.DEGRADED
    
    return {
        'overall_health': overall_health.value,
        'unhealthy_services': unhealthy_services,
        'degraded_services': degraded_services,
        'services': services_status,
        'timestamp': time.time()
    }