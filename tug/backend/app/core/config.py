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
    
    # CORS Settings
    CORS_ORIGINS: List[str] = ["*"]
    
    # Database Settings
    MONGODB_URL: str = os.environ.get("MONGODB_URL", "mongodb://localhost:27017")
    MONGODB_DB_NAME: str = os.environ.get("MONGODB_DB_NAME", "tug")
    
    # Auth Settings
    FIREBASE_CREDENTIALS_PATH: str = os.environ.get(
        "FIREBASE_CREDENTIALS_PATH", 
        "firebase-credentials.json"
    )
    
    class Config:
        env_file = ".env"
        case_sensitive = True
        extra = "ignore"  # Ignore extra environment variables

# Create an instance of the Settings class
settings = Settings()