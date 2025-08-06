# app/monitoring/middleware.py
import time
import psutil
import asyncio
from typing import Callable, Optional
from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware

from .metrics import metrics_collector
from .health import health_checker
from ..core.logging_config import get_logger

logger = get_logger(__name__)

class MonitoringMiddleware(BaseHTTPMiddleware):
    """Comprehensive monitoring middleware for production observability"""
    
    def __init__(self, app, collect_system_metrics: bool = True):
        super().__init__(app)
        self.collect_system_metrics = collect_system_metrics
        self._system_metrics_task = None
        
        if collect_system_metrics:
            # Start system metrics collection
            asyncio.create_task(self._start_system_metrics_collection())
    
    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        # Track request start
        start_time = time.time()
        
        # Extract request info
        method = request.method
        path = request.url.path
        
        # Skip monitoring for monitoring endpoints to avoid recursion
        if path.startswith('/metrics') or path.startswith('/health'):
            return await call_next(request)
        
        # Increment in-flight requests
        metrics_collector.set_gauge("http_requests_in_flight", 
                                  metrics_collector.get_metric_value("http_requests_in_flight") or 0 + 1)
        
        try:
            # Process request
            response = await call_next(request)
            status_code = response.status_code
            
        except Exception as e:
            # Track errors
            metrics_collector.increment_counter("errors_total", labels={'error_type': type(e).__name__})
            logger.error(f"Request failed: {method} {path} - {str(e)}", exc_info=True)
            raise
        
        finally:
            # Calculate duration
            duration_ms = (time.time() - start_time) * 1000
            
            # Track performance metrics
            metrics_collector.track_request_duration(path, method, duration_ms, status_code)
            
            # Decrement in-flight requests
            current_in_flight = metrics_collector.get_metric_value("http_requests_in_flight") or 1
            metrics_collector.set_gauge("http_requests_in_flight", max(0, current_in_flight - 1))
            
            # Log slow requests
            if duration_ms > 1000:  # Log requests slower than 1 second
                logger.warning(
                    f"Slow request: {method} {path} took {duration_ms:.2f}ms",
                    extra={
                        'endpoint': path,
                        'method': method,
                        'duration_ms': duration_ms,
                        'status_code': status_code,
                        'slow_request': True
                    }
                )
        
        return response
    
    async def _start_system_metrics_collection(self):
        """Start background system metrics collection"""
        if self._system_metrics_task:
            return
        
        self._system_metrics_task = asyncio.create_task(self._collect_system_metrics())
        logger.info("Started system metrics collection")
    
    async def _collect_system_metrics(self):
        """Collect system metrics periodically"""
        while True:
            try:
                # Collect system metrics
                memory = psutil.virtual_memory()
                cpu_percent = psutil.cpu_percent(interval=1)
                
                # Update metrics
                metrics_collector.update_system_metrics(
                    memory_usage=memory.used,
                    cpu_usage=cpu_percent,
                    active_connections=getattr(self, '_active_connections', 0)
                )
                
                # Sleep for 30 seconds before next collection
                await asyncio.sleep(30)
                
            except Exception as e:
                logger.error(f"Error collecting system metrics: {str(e)}")
                await asyncio.sleep(60)  # Wait longer on error

class DatabaseMonitoringMiddleware:
    """Middleware to monitor database operations"""
    
    def __init__(self):
        self.active_queries = {}
    
    async def before_query(self, operation: str, collection: str, query_info: dict):
        """Called before executing a database query"""
        query_id = id(query_info)
        self.active_queries[query_id] = {
            'start_time': time.time(),
            'operation': operation,
            'collection': collection
        }
        
        # Track active database connections
        current_active = metrics_collector.get_metric_value("database_connections_active") or 0
        metrics_collector.set_gauge("database_connections_active", current_active + 1)
        
        return query_id
    
    async def after_query(self, query_id: int, success: bool = True, error: Optional[Exception] = None):
        """Called after executing a database query"""
        if query_id not in self.active_queries:
            return
        
        query_info = self.active_queries.pop(query_id)
        duration_ms = (time.time() - query_info['start_time']) * 1000
        
        # Track database performance
        metrics_collector.track_database_query(
            operation=query_info['operation'],
            collection=query_info['collection'],
            duration_ms=duration_ms,
            success=success
        )
        
        # Log slow queries
        if duration_ms > 100:  # Log queries slower than 100ms
            logger.warning(
                f"Slow query: {query_info['operation']} on {query_info['collection']} took {duration_ms:.2f}ms",
                extra={
                    'operation': query_info['operation'],
                    'collection': query_info['collection'],
                    'duration_ms': duration_ms,
                    'slow_query': True,
                    'error': str(error) if error else None
                }
            )
        
        # Update active connections count
        current_active = metrics_collector.get_metric_value("database_connections_active") or 1
        metrics_collector.set_gauge("database_connections_active", max(0, current_active - 1))

# Global database monitoring instance
db_monitor = DatabaseMonitoringMiddleware()

class UserActivityMonitoringMiddleware:
    """Monitor user activities for analytics and performance insights"""
    
    @staticmethod
    def track_user_registration(user_id: str, method: str = "email"):
        """Track user registration"""
        metrics_collector.track_user_activity("user_registrations", user_id)
        logger.info(
            f"User registered: {user_id}",
            extra={
                'user_id': user_id,
                'registration_method': method,
                'event_type': 'user_registration'
            }
        )
    
    @staticmethod
    def track_user_login(user_id: str, success: bool = True):
        """Track user login attempt"""
        activity_type = "user_logins" if success else "user_login_failures"
        metrics_collector.track_user_activity(activity_type, user_id)
        
        logger.info(
            f"User login {'successful' if success else 'failed'}: {user_id}",
            extra={
                'user_id': user_id,
                'login_success': success,
                'event_type': 'user_login'
            }
        )
    
    @staticmethod
    def track_activity_creation(user_id: str, activity_type: str):
        """Track activity creation"""
        metrics_collector.track_user_activity("activities_created", user_id)
        logger.info(
            f"Activity created: {activity_type} by {user_id}",
            extra={
                'user_id': user_id,
                'activity_type': activity_type,
                'event_type': 'activity_creation'
            }
        )
    
    @staticmethod
    def track_feature_usage(user_id: str, feature: str, usage_data: Optional[dict] = None):
        """Track feature usage"""
        metrics_collector.increment_counter(
            "feature_usage_total",
            labels={'feature': feature}
        )
        
        logger.info(
            f"Feature used: {feature} by {user_id}",
            extra={
                'user_id': user_id,
                'feature': feature,
                'usage_data': usage_data,
                'event_type': 'feature_usage'
            }
        )

# Global user activity monitoring instance
user_activity_monitor = UserActivityMonitoringMiddleware()

class ErrorTrackingMiddleware:
    """Track and categorize application errors"""
    
    @staticmethod
    def track_error(error: Exception, user_id: Optional[str] = None, context: Optional[dict] = None):
        """Track application error"""
        error_type = type(error).__name__
        
        metrics_collector.increment_counter(
            "errors_total",
            labels={'error_type': error_type}
        )
        
        logger.error(
            f"Application error: {error_type} - {str(error)}",
            extra={
                'error_type': error_type,
                'error_message': str(error),
                'user_id': user_id,
                'context': context,
                'event_type': 'application_error'
            },
            exc_info=True
        )
    
    @staticmethod
    def track_validation_error(field: str, value: str, user_id: Optional[str] = None):
        """Track validation errors"""
        metrics_collector.increment_counter(
            "validation_errors_total",
            labels={'field': field}
        )
        
        logger.warning(
            f"Validation error: {field} = {value}",
            extra={
                'field': field,
                'invalid_value': value,
                'user_id': user_id,
                'event_type': 'validation_error'
            }
        )
    
    @staticmethod
    def track_security_event(event_type: str, severity: str, user_id: Optional[str] = None, details: Optional[dict] = None):
        """Track security events"""
        metrics_collector.increment_counter(
            "security_events_total",
            labels={'event_type': event_type, 'severity': severity}
        )
        
        log_level = logger.error if severity == 'high' else logger.warning
        log_level(
            f"Security event: {event_type} ({severity})",
            extra={
                'security_event': event_type,
                'severity': severity,
                'user_id': user_id,
                'details': details,
                'event_type': 'security_event'
            }
        )

# Global error tracking instance
error_tracker = ErrorTrackingMiddleware()