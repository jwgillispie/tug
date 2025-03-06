# app/main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .core.config import settings
from .core.database import init_db, close_db
from .api.routes import api_router

# Create FastAPI app
app = FastAPI(
    title=settings.APP_NAME,
    debug=settings.DEBUG
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include API router with the correct prefix
app.include_router(api_router, prefix=settings.API_V1_PREFIX)

# Event handlers
@app.on_event("startup")
async def startup_event():
    """Initialize database connection on startup"""
    await init_db()

@app.on_event("shutdown")
async def shutdown_event():
    """Close database connection on shutdown"""
    await close_db()

# Health check endpoint
@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "version": "1.0.0"}