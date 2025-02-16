# app/core/config.py
from pydantic_settings import BaseSettings
from functools import lru_cache

class Settings(BaseSettings):
    # Base
    APP_NAME: str = "ValueAlign"
    API_V1_STR: str = "/api/v1"
    
    # MongoDB
    MONGODB_URL: str = "mongodb://mongo:27017"
    MONGODB_DB_NAME: str = "valuealign"
    
    # Firebase
    FIREBASE_CREDENTIALS_PATH: str = "firebase-credentials.json"
    
    # CORS
    CORS_ORIGINS: list = ["*"]  # Adjust for production
    
    class Config:
        env_file = ".env"

@lru_cache()
def get_settings():
    return Settings()

settings = get_settings()