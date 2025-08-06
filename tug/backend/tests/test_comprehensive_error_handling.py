# tests/test_comprehensive_error_handling.py
"""
Comprehensive tests for the error handling and logging system.
"""

import pytest
import asyncio
from unittest.mock import patch, MagicMock
from datetime import datetime

from app.core.errors import (
    TugException, ValidationException, ResourceNotFoundException,
    ExternalServiceException, DatabaseException, BusinessRuleException
)
from app.core.retry import with_retry, RetryConfigs, CircuitBreaker
from app.core.graceful_degradation import (
    with_graceful_degradation, degradation_manager, ServiceHealth
)
from app.core.logging_config import (
    set_correlation_id, get_correlation_id, generate_correlation_id
)

class TestErrorTypes:
    """Test custom error types and handling"""
    
    def test_validation_exception(self):
        """Test ValidationException creation and properties"""
        exc = ValidationException(
            message="Invalid email format",
            field="email",
            value="invalid-email"
        )
        
        assert exc.message == "Invalid email format"
        assert exc.details['field'] == "email"
        assert exc.details['value'] == "invalid-email"
        assert exc.user_message == "Invalid email format"
    
    def test_resource_not_found_exception(self):
        """Test ResourceNotFoundException creation"""
        exc = ResourceNotFoundException(
            resource_type="User",
            resource_id="12345"
        )
        
        assert exc.message == "User not found with ID: 12345"
        assert exc.details['resource_type'] == "User"
        assert exc.details['resource_id'] == "12345"
        assert exc.user_message == "The requested user was not found."
    
    def test_business_rule_exception(self):
        """Test BusinessRuleException creation"""
        exc = BusinessRuleException(
            rule="max_daily_activities",
            message="User has reached maximum daily activities limit"
        )
        
        assert exc.message == "User has reached maximum daily activities limit"
        assert exc.details['business_rule'] == "max_daily_activities"
        assert exc.user_message == "User has reached maximum daily activities limit"
    
    def test_external_service_exception(self):
        """Test ExternalServiceException creation"""
        exc = ExternalServiceException(
            service="payment_gateway",
            message="Payment service unavailable",
            status_code=503
        )
        
        assert exc.message == "Payment service unavailable"
        assert exc.details['service'] == "payment_gateway"
        assert exc.details['status_code'] == 503
        assert exc.user_message == "An external service is currently unavailable. Please try again later."

class TestRetryLogic:
    """Test retry logic and circuit breakers"""
    
    @pytest.mark.asyncio
    async def test_retry_success_after_failure(self):
        """Test that retry works after initial failures"""
        call_count = 0
        
        @with_retry(config=RetryConfigs.DATABASE)
        async def flaky_function():
            nonlocal call_count
            call_count += 1
            if call_count <= 2:
                raise DatabaseException("connection", "Temporary connection error")
            return "success"
        
        result = await flaky_function()
        assert result == "success"
        assert call_count == 3  # Failed twice, succeeded on third try
    
    @pytest.mark.asyncio
    async def test_retry_max_attempts_exceeded(self):
        """Test that retry gives up after max attempts"""
        call_count = 0
        
        @with_retry(config=RetryConfigs.DATABASE)
        async def always_failing_function():
            nonlocal call_count
            call_count += 1
            raise DatabaseException("connection", "Persistent connection error")
        
        with pytest.raises(DatabaseException):
            await always_failing_function()
        
        assert call_count == 3  # Default max attempts
    
    @pytest.mark.asyncio
    async def test_non_retryable_exception(self):
        """Test that non-retryable exceptions are not retried"""
        call_count = 0
        
        @with_retry(config=RetryConfigs.DATABASE)
        async def validation_error_function():
            nonlocal call_count
            call_count += 1
            raise ValidationException("Invalid input")
        
        with pytest.raises(ValidationException):
            await validation_error_function()
        
        assert call_count == 1  # Should not retry validation errors
    
    def test_circuit_breaker_opens_after_failures(self):
        """Test that circuit breaker opens after threshold failures"""
        circuit_breaker = CircuitBreaker(failure_threshold=2, recovery_timeout=1.0)
        
        # First failure
        with pytest.raises(Exception):
            with circuit_breaker:
                raise Exception("Test failure 1")
        
        # Second failure - should open circuit
        with pytest.raises(Exception):
            with circuit_breaker:
                raise Exception("Test failure 2")
        
        # Third attempt should be rejected by open circuit
        with pytest.raises(ExternalServiceException):
            with circuit_breaker:
                pass  # This shouldn't be reached

class TestGracefulDegradation:
    """Test graceful degradation system"""
    
    @pytest.mark.asyncio
    async def test_graceful_degradation_with_fallback(self):
        """Test that fallback is used when service fails"""
        # Register a fallback
        async def test_fallback(*args, **kwargs):
            return {"fallback": True, "data": "fallback_data"}
        
        degradation_manager.register_fallback('test_service', test_fallback)
        
        @with_graceful_degradation(
            service_name='test_service',
            fallback_value={"fallback": False}
        )
        async def failing_service():
            raise Exception("Service failure")
        
        result = await failing_service()
        assert result["fallback"] is True
        assert result["data"] == "fallback_data"
    
    @pytest.mark.asyncio
    async def test_graceful_degradation_timeout(self):
        """Test that timeout triggers fallback"""
        @with_graceful_degradation(
            service_name='timeout_service',
            fallback_value={"timeout": True},
            timeout_seconds=0.1
        )
        async def slow_service():
            await asyncio.sleep(0.5)  # Longer than timeout
            return {"timeout": False}
        
        result = await slow_service()
        assert result["timeout"] is True
    
    def test_service_health_tracking(self):
        """Test service health status tracking"""
        service = degradation_manager.register_service(
            'health_test_service',
            unhealthy_threshold=2,
            degraded_threshold=1
        )
        
        # Initially should be unknown/healthy
        assert service.health in [ServiceHealth.UNKNOWN, ServiceHealth.HEALTHY]
        
        # Record failure - should become degraded
        service.record_failure(Exception("Test failure"))
        assert service.health == ServiceHealth.DEGRADED
        
        # Record another failure - should become unhealthy
        service.record_failure(Exception("Another failure"))
        assert service.health == ServiceHealth.UNHEALTHY
        
        # Record success - should improve
        service.record_success()
        assert service.health == ServiceHealth.DEGRADED

class TestLogging:
    """Test structured logging and correlation IDs"""
    
    def test_correlation_id_generation(self):
        """Test correlation ID generation and storage"""
        correlation_id = generate_correlation_id()
        assert correlation_id is not None
        assert len(correlation_id) > 0
        
        set_correlation_id(correlation_id)
        retrieved_id = get_correlation_id()
        assert retrieved_id == correlation_id
    
    def test_correlation_id_context(self):
        """Test that correlation ID is maintained across async calls"""
        async def test_async_context():
            correlation_id = generate_correlation_id()
            set_correlation_id(correlation_id)
            
            # Simulate async operation
            await asyncio.sleep(0.01)
            
            # Correlation ID should still be available
            retrieved_id = get_correlation_id()
            assert retrieved_id == correlation_id
        
        asyncio.run(test_async_context())

class TestIntegration:
    """Integration tests for the complete error handling system"""
    
    @pytest.mark.asyncio
    async def test_complete_error_handling_flow(self):
        """Test complete error handling flow with all components"""
        
        # Set up correlation ID
        correlation_id = generate_correlation_id()
        set_correlation_id(correlation_id)
        
        # Register fallback
        async def integration_fallback(*args, **kwargs):
            return {"source": "fallback", "correlation_id": get_correlation_id()}
        
        degradation_manager.register_fallback('integration_service', integration_fallback)
        
        call_count = 0
        
        @with_retry(config=RetryConfigs.EXTERNAL_API)
        @with_graceful_degradation(
            service_name='integration_service',
            fallback_value={"source": "default"}
        )
        async def complex_service_call():
            nonlocal call_count
            call_count += 1
            
            # Simulate different failure modes
            if call_count == 1:
                raise ExternalServiceException("external_api", "Temporary failure")
            elif call_count == 2:
                raise ExternalServiceException("external_api", "Another failure")
            else:
                # This should trigger fallback after retries
                raise ExternalServiceException("external_api", "Persistent failure")
        
        result = await complex_service_call()
        
        # Should have used fallback after retries
        assert result["source"] == "fallback"
        assert result["correlation_id"] == correlation_id
        assert call_count >= 2  # Should have retried at least once

# Run the tests
if __name__ == "__main__":
    pytest.main([__file__, "-v"])