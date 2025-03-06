# app/models/user.py
from beanie import Document, Indexed
from pydantic import EmailStr, Field
from typing import Dict, Any, Optional
from datetime import datetime

class User(Document):
    """User model for MongoDB with Beanie ODM"""
    firebase_uid: Indexed(str, unique=True)
    email: Indexed(EmailStr, unique=True)
    display_name: str
    created_at: datetime = Field(default_factory=datetime.utcnow)
    last_login: datetime = Field(default_factory=datetime.utcnow)
    onboarding_completed: bool = False
    settings: Dict[str, Any] = Field(default_factory=dict)
    version: int = 1

    class Settings:
        name = "users"
        indexes = [
            [("firebase_uid", 1), ("email", 1)],
            [("created_at", -1)]
        ]

    class Config:
        schema_extra = {
            "example": {
                "firebase_uid": "abc123",
                "email": "user@example.com",
                "display_name": "John Doe",
                "created_at": "2024-02-12T00:00:00Z",
                "last_login": "2024-02-12T00:00:00Z",
                "onboarding_completed": True,
                "settings": {
                    "notifications_enabled": True,
                    "theme": "light"
                }
            }
        }