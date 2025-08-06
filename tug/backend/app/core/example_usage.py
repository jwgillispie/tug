# app/core/example_usage.py
"""
Example usage of the comprehensive error handling and logging system.

This file demonstrates how to use all the error handling components together:
- Structured logging with correlation IDs
- Retry logic with circuit breakers
- Graceful degradation with fallbacks
- Custom error types and handling
"""

from typing import Optional, Dict, Any
from datetime import datetime
import asyncio

from .logging_config import get_logger, set_correlation_id, generate_correlation_id
from .errors import (
    TugException, ValidationException, ResourceNotFoundException, 
    ExternalServiceException, DatabaseException
)
from .retry import with_retry, RetryConfigs, CircuitBreaker
from .graceful_degradation import with_graceful_degradation, degradation_manager

logger = get_logger(__name__)

class ExampleService:
    """Example service demonstrating comprehensive error handling"""
    
    def __init__(self):
        # Set up circuit breaker for external API
        self.api_circuit_breaker = CircuitBreaker(
            failure_threshold=3,
            recovery_timeout=30.0,
            expected_exception=ExternalServiceException
        )
        
        # Register fallback for analytics service
        degradation_manager.register_fallback(
            'analytics_service', 
            self._analytics_fallback
        )
    
    @with_retry(config=RetryConfigs.DATABASE)
    async def create_user_record(self, user_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Example of database operation with retry logic and comprehensive error handling
        """
        # Set correlation ID for request tracking
        correlation_id = generate_correlation_id()
        set_correlation_id(correlation_id)
        
        logger.info(
            f"Creating user record",
            extra={
                'operation': 'create_user_record',
                'user_email': user_data.get('email'),
                'correlation_id': correlation_id
            }
        )
        
        try:
            # Validate input
            if not user_data.get('email'):
                raise ValidationException(
                    message="Email is required",
                    field="email",
                    value=user_data.get('email')
                )
            
            # Simulate database operation
            await asyncio.sleep(0.1)  # Simulate DB call
            
            # Simulate occasional failure for demo
            import random
            if random.random() < 0.3:  # 30% chance of failure
                raise DatabaseException(
                    operation="create_user_record",
                    message="Simulated database connection error"
                )
            
            user_record = {
                'id': f'user_{hash(user_data["email"])}',
                'email': user_data['email'],
                'created_at': datetime.utcnow().isoformat(),
                'correlation_id': correlation_id
            }
            
            logger.info(
                f"Successfully created user record",
                extra={
                    'operation': 'create_user_record_success',
                    'user_id': user_record['id'],
                    'correlation_id': correlation_id
                }
            )
            
            return user_record
            
        except ValidationException:
            # Don't retry validation errors
            raise
        except Exception as e:
            logger.error(
                f"Failed to create user record",
                extra={
                    'operation': 'create_user_record_error',
                    'error': str(e),
                    'correlation_id': correlation_id
                },
                exc_info=True
            )
            raise
    
    @with_graceful_degradation(
        service_name='external_api',
        fallback_value={'status': 'unavailable', 'data': None},
        timeout_seconds=5.0
    )
    async def fetch_external_data(self, user_id: str) -> Dict[str, Any]:
        """
        Example of external API call with graceful degradation
        """
        logger.info(
            f"Fetching external data for user",
            extra={
                'operation': 'fetch_external_data',
                'user_id': user_id
            }
        )
        
        try:
            # Use circuit breaker for external API calls
            with self.api_circuit_breaker:
                # Simulate external API call
                await asyncio.sleep(0.2)
                
                # Simulate occasional failure
                import random
                if random.random() < 0.4:  # 40% chance of failure
                    raise ExternalServiceException(
                        service="external_api",
                        message="External service is temporarily unavailable",
                        status_code=503
                    )
                
                return {
                    'status': 'success',
                    'data': {
                        'user_id': user_id,
                        'external_info': f'data_for_{user_id}',
                        'timestamp': datetime.utcnow().isoformat()
                    }
                }
        
        except ExternalServiceException as e:
            logger.warning(
                f"External API failed, will use fallback",
                extra={
                    'operation': 'fetch_external_data_fallback',
                    'user_id': user_id,
                    'error': str(e)
                }
            )
            raise
    
    @with_graceful_degradation(
        service_name='analytics_service',
        fallback_value=None,
        timeout_seconds=10.0
    )
    async def generate_user_analytics(self, user_id: str) -> Optional[Dict[str, Any]]:
        """
        Example of analytics service with fallback
        """
        logger.info(
            f"Generating analytics for user",
            extra={
                'operation': 'generate_user_analytics',
                'user_id': user_id
            }
        )
        
        # Simulate heavy computation
        await asyncio.sleep(0.5)
        
        # Simulate occasional timeout
        import random
        if random.random() < 0.2:  # 20% chance of timeout
            await asyncio.sleep(12)  # This will trigger timeout
        
        return {
            'user_id': user_id,
            'analytics': {
                'activity_score': random.uniform(60, 100),
                'engagement_level': 'high',
                'recommendations': [
                    'Continue your current routine',
                    'Try adding meditation to your day'
                ]
            },
            'generated_at': datetime.utcnow().isoformat()
        }
    
    async def _analytics_fallback(self, user_id: str, *args, **kwargs) -> Dict[str, Any]:
        """Fallback for analytics service"""
        logger.info(
            f"Using analytics fallback for user",
            extra={
                'operation': 'analytics_fallback',
                'user_id': user_id
            }
        )
        
        return {
            'user_id': user_id,
            'analytics': {
                'activity_score': 75.0,  # Default score
                'engagement_level': 'medium',
                'recommendations': [
                    'Analytics temporarily unavailable',
                    'Check back later for personalized insights'
                ]
            },
            'generated_at': datetime.utcnow().isoformat(),
            'fallback': True
        }
    
    async def comprehensive_user_operation(self, user_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Example of a comprehensive operation that uses all error handling features
        """
        correlation_id = generate_correlation_id()
        set_correlation_id(correlation_id)
        
        logger.info(
            f"Starting comprehensive user operation",
            extra={
                'operation': 'comprehensive_user_operation',
                'correlation_id': correlation_id
            }
        )
        
        results = {}
        errors = []
        
        # Step 1: Create user record (with retry)
        try:
            user_record = await self.create_user_record(user_data)
            results['user_record'] = user_record
            logger.info(f"Step 1 completed: User record created")
        except Exception as e:
            error_msg = f"Failed to create user record: {str(e)}"
            errors.append(error_msg)
            logger.error(error_msg, exc_info=True)
        
        # Step 2: Fetch external data (with graceful degradation)
        try:
            if 'user_record' in results:
                user_id = results['user_record']['id']
                external_data = await self.fetch_external_data(user_id)
                results['external_data'] = external_data
                logger.info(f"Step 2 completed: External data fetched")
        except Exception as e:
            error_msg = f"Failed to fetch external data: {str(e)}"
            errors.append(error_msg)
            logger.error(error_msg, exc_info=True)
        
        # Step 3: Generate analytics (with fallback)
        try:
            if 'user_record' in results:
                user_id = results['user_record']['id']
                analytics = await self.generate_user_analytics(user_id)
                results['analytics'] = analytics
                logger.info(f"Step 3 completed: Analytics generated")
        except Exception as e:
            error_msg = f"Failed to generate analytics: {str(e)}"
            errors.append(error_msg)
            logger.error(error_msg, exc_info=True)
        
        # Compile final results
        final_result = {
            'success': len(errors) == 0,
            'results': results,
            'errors': errors,
            'correlation_id': correlation_id,
            'timestamp': datetime.utcnow().isoformat()
        }
        
        logger.info(
            f"Comprehensive operation completed",
            extra={
                'operation': 'comprehensive_user_operation_complete',
                'success': final_result['success'],
                'errors_count': len(errors),
                'correlation_id': correlation_id
            }
        )
        
        return final_result

# Example usage
async def main():
    """Example of how to use the service"""
    service = ExampleService()
    
    # Example user data
    user_data = {
        'email': 'test@example.com',
        'name': 'Test User'
    }
    
    try:
        result = await service.comprehensive_user_operation(user_data)
        print(f"Operation result: {result}")
        
    except TugException as e:
        print(f"Application error: {e.message} (Code: {e.code})")
    except Exception as e:
        print(f"Unexpected error: {str(e)}")

if __name__ == "__main__":
    asyncio.run(main())