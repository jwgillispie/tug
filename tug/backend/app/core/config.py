# app/core/config.py
from pydantic_settings import BaseSettings
from typing import List
import os

class Settings(BaseSettings):
    """Application settings"""
    # API Settings
    APP_NAME: str = "ValueAlign API"
    API_V1_PREFIX: str = "/api/v1"
    DEBUG: bool = os.environ.get("DEBUG", "False").lower() == "true"
    
    # CORS Settings
    CORS_ORIGINS: List[str] = ["*"]
    
    # Database Settings
    MONGODB_URL: str = os.environ.get("MONGODB_URL", "mongodb://localhost:27017")
    MONGODB_DB_NAME: str = os.environ.get("MONGODB_DB_NAME", "valuealign")
    
    # Auth Settings
    FIREBASE_CREDENTIALS_PATH: str = os.environ.get(
        "FIREBASE_CREDENTIALS_PATH", 
        "firebase-credentials.json"
    )
    
    class Config:
        env_file = ".env"
        case_sensitive = True

# Instantiate settings
settings = Settings()