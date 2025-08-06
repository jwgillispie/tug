# app/core/middleware.py
import time
import uuid
from typing import Callable, Optional
from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import JSONResponse

from .logging_config import (
    get_logger, 
    set_correlation_id, 
    generate_correlation_id,
    get_correlation_id,
    log_security_event,
    log_performance_metric
)

logger = get_logger(__name__)

class RequestTrackingMiddleware(BaseHTTPMiddleware):
    """Middleware for request tracking, correlation IDs, and performance monitoring"""
    
    def __init__(self, app, enable_detailed_logging: bool = True):
        super().__init__(app)
        self.enable_detailed_logging = enable_detailed_logging
    
    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        # Generate or extract correlation ID
        correlation_id = request.headers.get('X-Correlation-ID') or generate_correlation_id()
        set_correlation_id(correlation_id)
        
        # Extract request information
        client_ip = self._get_client_ip(request)
        user_agent = request.headers.get('User-Agent', 'Unknown')
        method = request.method
        path = request.url.path
        query_params = str(request.query_params) if request.query_params else None
        
        # Extract user information if available
        user_id = None
        if hasattr(request.state, 'user_id'):
            user_id = request.state.user_id
        
        # Start timing
        start_time = time.time()
        
        # Log request start
        if self.enable_detailed_logging:
            logger.info(
                f"Request started: {method} {path}",
                extra={
                    'request_id': correlation_id,
                    'user_id': user_id,
                    'ip_address': client_ip,
                    'user_agent': user_agent,
                    'endpoint': path,
                    'method': method,
                    'query_params': query_params,
                    'event_type': 'request_start'
                }
            )
        
        # Security monitoring
        self._monitor_security_events(request, client_ip, user_agent, user_id)
        
        response = None
        error_occurred = False
        
        try:
            # Process request
            response = await call_next(request)
            
        except Exception as exc:
            error_occurred = True
            
            # Log error with context
            logger.error(
                f"Request failed: {method} {path} - {str(exc)}",
                extra={
                    'request_id': correlation_id,
                    'user_id': user_id,
                    'ip_address': client_ip,
                    'user_agent': user_agent,
                    'endpoint': path,
                    'method': method,
                    'error_type': type(exc).__name__,
                    'event_type': 'request_error'
                },
                exc_info=True
            )
            
            # Return error response
            response = JSONResponse(
                status_code=500,
                content={
                    "error": "internal_server_error",
                    "message": "An internal server error occurred",
                    "correlation_id": correlation_id,
                    "timestamp": time.time()
                }
            )
        
        # Calculate response time
        end_time = time.time()
        response_time_ms = (end_time - start_time) * 1000
        
        # Add correlation ID to response headers
        response.headers['X-Correlation-ID'] = correlation_id
        response.headers['X-Response-Time'] = f"{response_time_ms:.2f}ms"
        
        # Log request completion
        status_code = response.status_code
        
        if self.enable_detailed_logging:
            log_level = logger.error if error_occurred or status_code >= 400 else logger.info
            log_level(
                f"Request completed: {method} {path} - {status_code} ({response_time_ms:.2f}ms)",
                extra={
                    'request_id': correlation_id,
                    'user_id': user_id,
                    'ip_address': client_ip,
                    'user_agent': user_agent,
                    'endpoint': path,
                    'method': method,
                    'status_code': status_code,
                    'response_time_ms': response_time_ms,
                    'event_type': 'request_complete',
                    'error_occurred': error_occurred
                }
            )
        
        # Log performance metrics for slow requests
        if response_time_ms > 1000:  # Log requests slower than 1 second
            log_performance_metric(
                logger,
                'slow_request',
                response_time_ms,
                'ms',
                {
                    'endpoint': path,
                    'method': method,
                    'status_code': status_code,
                    'user_id': user_id
                }
            )
        
        return response
    
    def _get_client_ip(self, request: Request) -> str:
        """Extract client IP address from request"""
        # Check for forwarded headers first (from load balancers/proxies)
        forwarded_for = request.headers.get('X-Forwarded-For')
        if forwarded_for:
            # X-Forwarded-For can contain multiple IPs, take the first one
            return forwarded_for.split(',')[0].strip()
        
        real_ip = request.headers.get('X-Real-IP')
        if real_ip:
            return real_ip
        
        # Fallback to direct client host
        return request.client.host if request.client else 'unknown'
    
    def _monitor_security_events(
        self, 
        request: Request, 
        client_ip: str, 
        user_agent: str, 
        user_id: Optional[str]
    ) -> None:
        """Monitor for potential security threats"""
        
        # Check for suspicious user agents
        suspicious_agents = [
            'sqlmap', 'nikto', 'nmap', 'masscan', 'burpsuite',
            'dirbuster', 'gobuster', 'wget', 'curl'
        ]
        
        if any(agent.lower() in user_agent.lower() for agent in suspicious_agents):
            log_security_event(
                logger,
                'suspicious_user_agent',
                'medium',
                f"Suspicious user agent detected: {user_agent}",
                user_id=user_id,
                ip_address=client_ip,
                additional_data={'user_agent': user_agent}
            )
        
        # Check for SQL injection patterns in query parameters
        sql_patterns = ['union select', 'drop table', 'insert into', '--', ';--']
        query_string = str(request.query_params).lower()
        
        for pattern in sql_patterns:
            if pattern in query_string:
                log_security_event(
                    logger,
                    'sql_injection_attempt',
                    'high',
                    f"Potential SQL injection attempt in query parameters",
                    user_id=user_id,
                    ip_address=client_ip,
                    additional_data={
                        'query_params': str(request.query_params),
                        'detected_pattern': pattern
                    }
                )
                break
        
        # Check for XSS patterns
        xss_patterns = ['<script', 'javascript:', 'onerror=', 'onload=']
        for pattern in xss_patterns:
            if pattern in query_string:
                log_security_event(
                    logger,
                    'xss_attempt',
                    'high',
                    f"Potential XSS attempt detected",
                    user_id=user_id,
                    ip_address=client_ip,
                    additional_data={
                        'query_params': str(request.query_params),
                        'detected_pattern': pattern
                    }
                )
                break
        
        # Monitor for unusual request patterns
        path = request.url.path
        if path.count('../') > 2:
            log_security_event(
                logger,
                'path_traversal_attempt',
                'high',
                f"Potential path traversal attempt: {path}",
                user_id=user_id,
                ip_address=client_ip,
                additional_data={'path': path}
            )

class ErrorHandlingMiddleware(BaseHTTPMiddleware):
    """Centralized error handling middleware"""
    
    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        try:
            response = await call_next(request)
            return response
            
        except ValueError as exc:
            logger.warning(
                f"Validation error: {str(exc)}",
                extra={'error_type': 'validation_error'},
                exc_info=True
            )
            return JSONResponse(
                status_code=400,
                content={
                    "error": "validation_error",
                    "message": str(exc),
                    "correlation_id": get_correlation_id()
                }
            )
            
        except PermissionError as exc:
            logger.warning(
                f"Permission denied: {str(exc)}",
                extra={'error_type': 'permission_denied'},
                exc_info=True
            )
            return JSONResponse(
                status_code=403,
                content={
                    "error": "permission_denied",
                    "message": "You don't have permission to access this resource",
                    "correlation_id": get_correlation_id()
                }
            )
            
        except FileNotFoundError as exc:
            logger.warning(
                f"Resource not found: {str(exc)}",
                extra={'error_type': 'not_found'},
                exc_info=True
            )
            return JSONResponse(
                status_code=404,
                content={
                    "error": "not_found",
                    "message": "The requested resource was not found",
                    "correlation_id": get_correlation_id()
                }
            )
            
        except Exception as exc:
            # Log unhandled exceptions
            logger.error(
                f"Unhandled exception: {str(exc)}",
                extra={'error_type': 'unhandled_exception'},
                exc_info=True
            )
            
            return JSONResponse(
                status_code=500,
                content={
                    "error": "internal_server_error",
                    "message": "An internal server error occurred",
                    "correlation_id": get_correlation_id()
                }
            )