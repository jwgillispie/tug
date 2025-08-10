# app/main.py
import logging
import time
import os
from fastapi import FastAPI, Request, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import JSONResponse

from .core.config import settings
from .core.database import init_db, close_db
from .core.logging_config import setup_logging, get_logger
from .core.middleware import RequestTrackingMiddleware, ErrorHandlingMiddleware
from .core.errors import error_registry, TugException, create_http_exception
from .api.routes import api_router
from .monitoring import (
    MonitoringMiddleware, 
    monitoring_router, 
    metrics_collector, 
    alert_manager,
    user_activity_monitor,
    error_tracker
)

# Setup structured logging
setup_logging(
    level=os.environ.get("LOG_LEVEL", "INFO"),
    service_name="tug-api",
    environment=os.environ.get("ENVIRONMENT", "production"),
    log_file_path=os.environ.get("LOG_FILE_PATH")
)

logger = get_logger(__name__)

# Create FastAPI app
app = FastAPI(
    title=settings.APP_NAME,
    debug=settings.DEBUG,
    redirect_slashes=True,
    docs_url="/docs",
    redoc_url="/redoc"
)

# Security middleware for rate limiting and request size limits
class SecurityMiddleware(BaseHTTPMiddleware):
    def __init__(self, app, max_request_size: int = None):
        super().__init__(app)
        self.max_request_size = max_request_size or settings.MAX_REQUEST_SIZE
        self.rate_limit_storage = {}  # In production, use Redis
        self.requests_per_minute = settings.RATE_LIMIT_REQUESTS_PER_MINUTE
        self.burst_requests = settings.RATE_LIMIT_BURST
    
    async def dispatch(self, request: Request, call_next):
        # Check request size
        if "content-length" in request.headers:
            content_length = int(request.headers["content-length"])
            if content_length > self.max_request_size:
                return JSONResponse(
                    status_code=413,
                    content={
                        "error": "payload_too_large",
                        "message": f"Request payload exceeds maximum size of {self.max_request_size} bytes",
                        "max_size": self.max_request_size
                    }
                )
        
        # Simple rate limiting (in production, use Redis with sliding window)
        client_ip = request.client.host if request.client else "unknown"
        current_time = time.time()
        minute_key = f"{client_ip}:{int(current_time // 60)}"
        
        if minute_key not in self.rate_limit_storage:
            self.rate_limit_storage[minute_key] = []
        
        # Clean old entries
        self.rate_limit_storage[minute_key] = [
            req_time for req_time in self.rate_limit_storage[minute_key]
            if current_time - req_time < 60
        ]
        
        # Check rate limit
        if len(self.rate_limit_storage[minute_key]) >= self.requests_per_minute:
            return JSONResponse(
                status_code=429,
                content={
                    "error": "rate_limit_exceeded",
                    "message": "Too many requests. Please slow down.",
                    "limit": self.requests_per_minute,
                    "window": "1 minute"
                },
                headers={
                    "Retry-After": "60",
                    "X-RateLimit-Limit": str(self.requests_per_minute),
                    "X-RateLimit-Remaining": "0",
                    "X-RateLimit-Reset": str(int(current_time) + 60)
                }
            )
        
        # Add current request
        self.rate_limit_storage[minute_key].append(current_time)
        
        # Process request
        response = await call_next(request)
        
        # Add security headers
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["X-XSS-Protection"] = "1; mode=block"
        response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
        response.headers["Permissions-Policy"] = "geolocation=(), microphone=(), camera=()"
        
        return response

# Add error handling middleware first
app.add_middleware(ErrorHandlingMiddleware)

# Add monitoring middleware
app.add_middleware(MonitoringMiddleware, collect_system_metrics=True)

# Add request tracking middleware
app.add_middleware(RequestTrackingMiddleware, enable_detailed_logging=settings.DEBUG)

# Add security middleware
app.add_middleware(SecurityMiddleware)

# Add trusted host middleware for production
if not settings.DEBUG:
    app.add_middleware(
        TrustedHostMiddleware,
        allowed_hosts=settings.TRUSTED_HOSTS
    )

# Add CORS middleware with strict configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allow_headers=[
        "Accept",
        "Accept-Language",
        "Content-Language",
        "Content-Type",
        "Authorization",
        "X-Requested-With"
    ],  # Strict header allowlist
    expose_headers=["X-RateLimit-Limit", "X-RateLimit-Remaining", "X-RateLimit-Reset"],
    max_age=3600,  # Cache preflight requests for 1 hour
)

# Global exception handler for TugException
@app.exception_handler(TugException)
async def tug_exception_handler(request: Request, exc: TugException):
    """Handle TugException instances"""
    http_exc = create_http_exception(exc, include_details=settings.DEBUG)
    logger.error(
        f"TugException: {exc.message}",
        extra={
            'error_code': exc.code.value,
            'error_details': exc.details,
            'user_message': exc.user_message,
            'context': exc.context
        },
        exc_info=True
    )
    return JSONResponse(
        status_code=http_exc.status_code,
        content=http_exc.detail
    )

# Global exception handler for unhandled exceptions
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """Handle all other exceptions"""
    # Try custom error handlers first
    custom_response = error_registry.handle(exc)
    if custom_response:
        return JSONResponse(
            status_code=custom_response.status_code,
            content=custom_response.detail
        )
    
    # Log unhandled exception
    logger.error(
        f"Unhandled exception: {str(exc)}",
        extra={'exception_type': type(exc).__name__},
        exc_info=True
    )
    
    # Return generic error response
    return JSONResponse(
        status_code=500,
        content={
            "error": "internal_server_error",
            "message": "An internal server error occurred",
            "timestamp": time.time()
        }
    )

# Include API router with the correct prefix
app.include_router(api_router, prefix=settings.API_V1_PREFIX)

# Include monitoring router
app.include_router(monitoring_router)

# Mount static files for profile pictures
import os
uploads_dir = "uploads"
os.makedirs(uploads_dir, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=uploads_dir), name="uploads")

# Event handlers
@app.on_event("startup")
async def startup_event():
    """Initialize database connection and start services on startup"""
    logger.info("Starting application")
    await init_db()
    logger.info("Database initialized")
    
    # Start coaching scheduler
    try:
        from .services.coaching_scheduler import start_coaching_scheduler
        await start_coaching_scheduler()
        logger.info("Coaching scheduler started")
    except Exception as e:
        logger.error(f"Failed to start coaching scheduler: {e}")
        # Don't fail startup if coaching scheduler fails
    
    # Start WebSocket manager
    try:
        from .services.websocket_manager import websocket_manager
        await websocket_manager.start_manager()
        logger.info("WebSocket manager started")
    except Exception as e:
        logger.error(f"Failed to start WebSocket manager: {e}")
        # Don't fail startup if WebSocket manager fails

@app.on_event("shutdown")
async def shutdown_event():
    """Stop services and close database connection on shutdown"""
    logger.info("Shutting down application")
    
    # Stop WebSocket manager
    try:
        from .services.websocket_manager import websocket_manager
        await websocket_manager.stop_manager()
        logger.info("WebSocket manager stopped")
    except Exception as e:
        logger.error(f"Error stopping WebSocket manager: {e}")
    
    # Stop coaching scheduler
    try:
        from .services.coaching_scheduler import stop_coaching_scheduler
        stop_coaching_scheduler()
        logger.info("Coaching scheduler stopped")
    except Exception as e:
        logger.error(f"Error stopping coaching scheduler: {e}")
    
    await close_db()
    logger.info("Database connection closed")

# Health check endpoint
@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "version": "3.0.0"}

# Root endpoint for testing
@app.get("/")
async def root():
    """Root endpoint for basic API testing"""
    return {
        "message": "tug API is running",
        "version": "3.0.0",
        "api_prefix": settings.API_V1_PREFIX,
        "endpoints": [
            f"{settings.API_V1_PREFIX}/users",
            f"{settings.API_V1_PREFIX}/values",
            f"{settings.API_V1_PREFIX}/activities",
            f"{settings.API_V1_PREFIX}/vices",
            f"{settings.API_V1_PREFIX}/social",
            f"{settings.API_V1_PREFIX}/notifications",
            f"{settings.API_V1_PREFIX}/mood"
        ]
    }