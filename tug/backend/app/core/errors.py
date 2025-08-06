# app/core/errors.py
from typing import Any, Dict, Optional, List
from fastapi import HTTPException, status
from enum import Enum

class ErrorCode(str, Enum):
    """Standardized error codes for the application"""
    
    # Authentication & Authorization
    INVALID_CREDENTIALS = "invalid_credentials"
    TOKEN_EXPIRED = "token_expired"
    TOKEN_INVALID = "token_invalid"
    INSUFFICIENT_PERMISSIONS = "insufficient_permissions"
    USER_NOT_FOUND = "user_not_found"
    USER_ALREADY_EXISTS = "user_already_exists"
    
    # Validation
    VALIDATION_ERROR = "validation_error"
    INVALID_INPUT = "invalid_input"
    MISSING_REQUIRED_FIELD = "missing_required_field"
    INVALID_FORMAT = "invalid_format"
    VALUE_OUT_OF_RANGE = "value_out_of_range"
    
    # Resource Management
    RESOURCE_NOT_FOUND = "resource_not_found"
    RESOURCE_ALREADY_EXISTS = "resource_already_exists"
    RESOURCE_CONFLICT = "resource_conflict"
    RESOURCE_LOCKED = "resource_locked"
    
    # Rate Limiting & Quotas
    RATE_LIMIT_EXCEEDED = "rate_limit_exceeded"
    QUOTA_EXCEEDED = "quota_exceeded"
    TOO_MANY_REQUESTS = "too_many_requests"
    
    # External Services
    EXTERNAL_SERVICE_ERROR = "external_service_error"
    DATABASE_ERROR = "database_error"
    NETWORK_ERROR = "network_error"
    TIMEOUT_ERROR = "timeout_error"
    
    # Business Logic
    BUSINESS_RULE_VIOLATION = "business_rule_violation"
    INVALID_STATE = "invalid_state"
    OPERATION_NOT_ALLOWED = "operation_not_allowed"
    
    # System
    INTERNAL_SERVER_ERROR = "internal_server_error"
    SERVICE_UNAVAILABLE = "service_unavailable"
    MAINTENANCE_MODE = "maintenance_mode"

class TugException(Exception):
    """Base exception class for Tug application"""
    
    def __init__(
        self,
        message: str,
        code: ErrorCode = ErrorCode.INTERNAL_SERVER_ERROR,
        details: Optional[Dict[str, Any]] = None,
        user_message: Optional[str] = None,
        context: Optional[Dict[str, Any]] = None
    ):
        self.message = message
        self.code = code
        self.details = details or {}
        self.user_message = user_message or message
        self.context = context or {}
        super().__init__(self.message)

class ValidationException(TugException):
    """Exception for validation errors"""
    
    def __init__(
        self,
        message: str,
        field: Optional[str] = None,
        value: Optional[Any] = None,
        details: Optional[Dict[str, Any]] = None
    ):
        details = details or {}
        if field:
            details['field'] = field
        if value is not None:
            details['value'] = value
        
        super().__init__(
            message=message,
            code=ErrorCode.VALIDATION_ERROR,
            details=details,
            user_message=message
        )

class AuthenticationException(TugException):
    """Exception for authentication errors"""
    
    def __init__(
        self,
        message: str = "Authentication failed",
        code: ErrorCode = ErrorCode.INVALID_CREDENTIALS,
        details: Optional[Dict[str, Any]] = None
    ):
        super().__init__(
            message=message,
            code=code,
            details=details,
            user_message="Authentication failed. Please check your credentials."
        )

class AuthorizationException(TugException):
    """Exception for authorization errors"""
    
    def __init__(
        self,
        message: str = "Access denied",
        resource: Optional[str] = None,
        action: Optional[str] = None,
        details: Optional[Dict[str, Any]] = None
    ):
        details = details or {}
        if resource:
            details['resource'] = resource
        if action:
            details['action'] = action
        
        super().__init__(
            message=message,
            code=ErrorCode.INSUFFICIENT_PERMISSIONS,
            details=details,
            user_message="You don't have permission to perform this action."
        )

class ResourceNotFoundException(TugException):
    """Exception for resource not found errors"""
    
    def __init__(
        self,
        resource_type: str,
        resource_id: Optional[str] = None,
        details: Optional[Dict[str, Any]] = None
    ):
        details = details or {}
        details['resource_type'] = resource_type
        if resource_id:
            details['resource_id'] = resource_id
        
        message = f"{resource_type} not found"
        if resource_id:
            message += f" with ID: {resource_id}"
        
        super().__init__(
            message=message,
            code=ErrorCode.RESOURCE_NOT_FOUND,
            details=details,
            user_message=f"The requested {resource_type.lower()} was not found."
        )

class BusinessRuleException(TugException):
    """Exception for business rule violations"""
    
    def __init__(
        self,
        rule: str,
        message: str,
        details: Optional[Dict[str, Any]] = None
    ):
        details = details or {}
        details['business_rule'] = rule
        
        super().__init__(
            message=message,
            code=ErrorCode.BUSINESS_RULE_VIOLATION,
            details=details,
            user_message=message
        )

class ExternalServiceException(TugException):
    """Exception for external service errors"""
    
    def __init__(
        self,
        service: str,
        message: str,
        status_code: Optional[int] = None,
        details: Optional[Dict[str, Any]] = None
    ):
        details = details or {}
        details['service'] = service
        if status_code:
            details['status_code'] = status_code
        
        super().__init__(
            message=message,
            code=ErrorCode.EXTERNAL_SERVICE_ERROR,
            details=details,
            user_message="An external service is currently unavailable. Please try again later."
        )

class DatabaseException(TugException):
    """Exception for database errors"""
    
    def __init__(
        self,
        operation: str,
        message: str,
        details: Optional[Dict[str, Any]] = None
    ):
        details = details or {}
        details['operation'] = operation
        
        super().__init__(
            message=message,
            code=ErrorCode.DATABASE_ERROR,
            details=details,
            user_message="A database error occurred. Please try again later."
        )

def create_http_exception(
    exc: TugException,
    include_details: bool = False
) -> HTTPException:
    """Convert TugException to FastAPI HTTPException"""
    
    # Map error codes to HTTP status codes
    status_map = {
        ErrorCode.INVALID_CREDENTIALS: status.HTTP_401_UNAUTHORIZED,
        ErrorCode.TOKEN_EXPIRED: status.HTTP_401_UNAUTHORIZED,
        ErrorCode.TOKEN_INVALID: status.HTTP_401_UNAUTHORIZED,
        ErrorCode.INSUFFICIENT_PERMISSIONS: status.HTTP_403_FORBIDDEN,
        ErrorCode.USER_NOT_FOUND: status.HTTP_404_NOT_FOUND,
        ErrorCode.USER_ALREADY_EXISTS: status.HTTP_409_CONFLICT,
        
        ErrorCode.VALIDATION_ERROR: status.HTTP_400_BAD_REQUEST,
        ErrorCode.INVALID_INPUT: status.HTTP_400_BAD_REQUEST,
        ErrorCode.MISSING_REQUIRED_FIELD: status.HTTP_400_BAD_REQUEST,
        ErrorCode.INVALID_FORMAT: status.HTTP_400_BAD_REQUEST,
        ErrorCode.VALUE_OUT_OF_RANGE: status.HTTP_400_BAD_REQUEST,
        
        ErrorCode.RESOURCE_NOT_FOUND: status.HTTP_404_NOT_FOUND,
        ErrorCode.RESOURCE_ALREADY_EXISTS: status.HTTP_409_CONFLICT,
        ErrorCode.RESOURCE_CONFLICT: status.HTTP_409_CONFLICT,
        ErrorCode.RESOURCE_LOCKED: status.HTTP_423_LOCKED,
        
        ErrorCode.RATE_LIMIT_EXCEEDED: status.HTTP_429_TOO_MANY_REQUESTS,
        ErrorCode.QUOTA_EXCEEDED: status.HTTP_429_TOO_MANY_REQUESTS,
        ErrorCode.TOO_MANY_REQUESTS: status.HTTP_429_TOO_MANY_REQUESTS,
        
        ErrorCode.EXTERNAL_SERVICE_ERROR: status.HTTP_502_BAD_GATEWAY,
        ErrorCode.DATABASE_ERROR: status.HTTP_503_SERVICE_UNAVAILABLE,
        ErrorCode.NETWORK_ERROR: status.HTTP_502_BAD_GATEWAY,
        ErrorCode.TIMEOUT_ERROR: status.HTTP_504_GATEWAY_TIMEOUT,
        
        ErrorCode.BUSINESS_RULE_VIOLATION: status.HTTP_400_BAD_REQUEST,
        ErrorCode.INVALID_STATE: status.HTTP_400_BAD_REQUEST,
        ErrorCode.OPERATION_NOT_ALLOWED: status.HTTP_405_METHOD_NOT_ALLOWED,
        
        ErrorCode.INTERNAL_SERVER_ERROR: status.HTTP_500_INTERNAL_SERVER_ERROR,
        ErrorCode.SERVICE_UNAVAILABLE: status.HTTP_503_SERVICE_UNAVAILABLE,
        ErrorCode.MAINTENANCE_MODE: status.HTTP_503_SERVICE_UNAVAILABLE,
    }
    
    http_status = status_map.get(exc.code, status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    # Create error response
    error_response = {
        "error": exc.code.value,
        "message": exc.user_message,
        "timestamp": time.time()
    }
    
    # Include details in development or if explicitly requested
    if include_details and exc.details:
        error_response["details"] = exc.details
    
    # Include context if available
    if exc.context:
        error_response["context"] = exc.context
    
    return HTTPException(status_code=http_status, detail=error_response)

# Error handler registry
class ErrorHandlerRegistry:
    """Registry for custom error handlers"""
    
    def __init__(self):
        self._handlers: Dict[type, callable] = {}
    
    def register(self, exception_type: type, handler: callable) -> None:
        """Register a custom error handler"""
        self._handlers[exception_type] = handler
    
    def handle(self, exception: Exception) -> Optional[HTTPException]:
        """Handle an exception using registered handlers"""
        for exc_type, handler in self._handlers.items():
            if isinstance(exception, exc_type):
                return handler(exception)
        return None

# Global error handler registry
error_registry = ErrorHandlerRegistry()

# Register default handlers
def handle_value_error(exc: ValueError) -> HTTPException:
    """Handle ValueError exceptions"""
    return create_http_exception(
        ValidationException(str(exc)),
        include_details=False
    )

def handle_key_error(exc: KeyError) -> HTTPException:
    """Handle KeyError exceptions"""
    return create_http_exception(
        ValidationException(f"Missing required field: {str(exc)}"),
        include_details=False
    )

def handle_type_error(exc: TypeError) -> HTTPException:
    """Handle TypeError exceptions"""
    return create_http_exception(
        ValidationException(f"Invalid type: {str(exc)}"),
        include_details=False
    )

# Register default handlers
error_registry.register(ValueError, handle_value_error)
error_registry.register(KeyError, handle_key_error)
error_registry.register(TypeError, handle_type_error)