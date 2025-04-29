# app/models/user.py
from beanie import Document, Indexed
from bson import ObjectId
from fastapi import logger
from pydantic import EmailStr, Field
from typing import Dict, Any, Optional
from datetime import datetime

class User(Document):
    """User model for MongoDB with Beanie ODM"""
    @classmethod
    async def get_by_id(cls, id: str):
        """Get user by ID with proper ObjectId conversion"""
        try:
            # Convert string ID to ObjectId if it's not already
            if not isinstance(id, ObjectId):
                try:
                    object_id = ObjectId(id)
                except:
                    return None
            else:
                object_id = id
                
            # Find the user by ID
            return await cls.find_one(cls.id == object_id)
        except Exception as e:
            logger.error(f"Error in get_by_id: {e}")
        return None
    firebase_uid: Indexed(str, unique=True) # type: ignore
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