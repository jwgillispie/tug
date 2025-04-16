# app/main.py
import logging
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from .core.config import settings
from .core.database import init_db, close_db
from .api.routes import api_router

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
)
logger = logging.getLogger(__name__)

# Create FastAPI app
app = FastAPI(
    title=settings.APP_NAME,
    debug=settings.DEBUG,
    redirect_slashes= False
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # You should restrict this in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Add request logging middleware
@app.middleware("http")
async def log_requests(request: Request, call_next):
    logger.info(f"{request.method} {request.url.path}")
    # Log headers for debugging
    auth_header = request.headers.get('Authorization')
    logger.info(f"Authorization header present: {auth_header is not None}")
    
    response = await call_next(request)
    logger.info(f"Response status: {response.status_code}")
    return response

# Include API router with the correct prefix
app.include_router(api_router, prefix=settings.API_V1_PREFIX)

# Event handlers
@app.on_event("startup")
async def startup_event():
    """Initialize database connection on startup"""
    logger.info("Starting application")
    await init_db()
    logger.info("Database initialized")

@app.on_event("shutdown")
async def shutdown_event():
    """Close database connection on shutdown"""
    logger.info("Shutting down application")
    await close_db()
    logger.info("Database connection closed")

# Health check endpoint
@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "version": "1.0.0"}

# Root endpoint for testing
@app.get("/")
async def root():
    """Root endpoint for basic API testing"""
    return {
        "message": "tug API is running",
        "version": "1.0.0",
        "api_prefix": settings.API_V1_PREFIX,
        "endpoints": [
            f"{settings.API_V1_PREFIX}/users",
            f"{settings.API_V1_PREFIX}/values",
            f"{settings.API_V1_PREFIX}/activities"
        ]
    }