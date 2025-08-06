# app/core/config.py
from pydantic_settings import BaseSettings
from typing import List
import os

class Settings(BaseSettings):
    """Application settings"""
    # API Settings
    APP_NAME: str = "Tug API"
    API_V1_PREFIX: str = "/api/v1"
    DEBUG: bool = os.environ.get("DEBUG", "False").lower() == "true"
    
    # Add this line:
    API_URL: str = os.environ.get("API_URL", "http://localhost:8000")
    
    # CORS Settings - Strict in production
    CORS_ORIGINS: List[str] = [
        "https://tugg-app.web.app",
        "http://localhost:3000",
        "http://127.0.0.1:3000"
    ] if not os.environ.get("DEBUG", "False").lower() == "true" else ["*"]
    
    # Database Settings
    MONGODB_URL: str = os.environ.get("MONGODB_URL", "mongodb://localhost:27017")
    MONGODB_DB_NAME: str = os.environ.get("MONGODB_DB_NAME", "tug")
    
    # Database Performance Settings
    MONGODB_MAX_POOL_SIZE: int = int(os.environ.get("MONGODB_MAX_POOL_SIZE", 50))
    MONGODB_MIN_POOL_SIZE: int = int(os.environ.get("MONGODB_MIN_POOL_SIZE", 5))
    MONGODB_MAX_IDLE_TIME_MS: int = int(os.environ.get("MONGODB_MAX_IDLE_TIME_MS", 30000))
    MONGODB_CONNECT_TIMEOUT_MS: int = int(os.environ.get("MONGODB_CONNECT_TIMEOUT_MS", 5000))
    MONGODB_SERVER_SELECTION_TIMEOUT_MS: int = int(os.environ.get("MONGODB_SERVER_SELECTION_TIMEOUT_MS", 5000))
    MONGODB_SOCKET_TIMEOUT_MS: int = int(os.environ.get("MONGODB_SOCKET_TIMEOUT_MS", 30000))
    
    # Query Performance Settings
    SLOW_QUERY_THRESHOLD_MS: float = float(os.environ.get("SLOW_QUERY_THRESHOLD_MS", 100.0))
    ENABLE_QUERY_MONITORING: bool = os.environ.get("ENABLE_QUERY_MONITORING", "True").lower() == "true"
    
    # Auth Settings
    FIREBASE_CREDENTIALS_PATH: str = os.environ.get(
        "FIREBASE_CREDENTIALS_PATH", 
        "firebase-credentials.json"
    )
    
    # Security Settings
    MAX_REQUEST_SIZE: int = int(os.environ.get("MAX_REQUEST_SIZE", 10 * 1024 * 1024))  # 10MB
    RATE_LIMIT_REQUESTS_PER_MINUTE: int = int(os.environ.get("RATE_LIMIT_RPM", 100))
    RATE_LIMIT_BURST: int = int(os.environ.get("RATE_LIMIT_BURST", 20))
    
    # Security headers
    ENABLE_SECURITY_HEADERS: bool = os.environ.get("ENABLE_SECURITY_HEADERS", "True").lower() == "true"
    
    # Trusted hosts for production
    TRUSTED_HOSTS: List[str] = [
        "tugg-app.web.app",
        "*.tugg-app.web.app", 
        "localhost",
        "127.0.0.1"
    ]
    
    class Config:
        env_file = ".env"
        case_sensitive = True
        extra = "ignore"  # Ignore extra environment variables

# Create an instance of the Settings class
settings = Settings()