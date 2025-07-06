# app/models/user.py
from beanie import Document, Indexed
from pydantic import EmailStr, Field
from typing import Dict, Any, Optional, ClassVar
from datetime import datetime
from bson import ObjectId
import logging
import re
import secrets

logger = logging.getLogger(__name__)

class User(Document):
    """User model for MongoDB with Beanie ODM"""
    firebase_uid: Indexed(str, unique=True)
    email: Indexed(EmailStr, unique=True)
    username: Optional[Indexed(str, unique=True)] = None
    display_name: str
    profile_picture_url: Optional[str] = None
    bio: Optional[str] = Field(default=None, max_length=300)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    last_login: datetime = Field(default_factory=datetime.utcnow)
    onboarding_completed: bool = False
    settings: Dict[str, Any] = Field(default_factory=dict)
    version: int = 1

    class Settings:
        name = "users"
        indexes = [
            [("firebase_uid", 1), ("email", 1)],
            [("username", 1)],
            [("created_at", -1)]
        ]

    class Config:
        schema_extra = {
            "example": {
                "firebase_uid": "abc123",
                "email": "user@example.com",
                "username": "johndoe",
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
    
    @classmethod
    async def get_by_id(cls, id: str):
        """Get user by ID with proper ObjectId conversion"""
        try:
            # Convert string ID to ObjectId if it's not already
            if not isinstance(id, ObjectId):
                try:
                    object_id = ObjectId(id)
                except Exception as e:
                    logger.error(f"Invalid ObjectId format: {id}, Error: {e}")
                    return None
            else:
                object_id = id
                
            # Find the user by ID
            return await cls.find_one(cls.id == object_id)
        except Exception as e:
            logger.error(f"Error in get_by_id: {e}")
            return None

    async def ensure_username(self):
        """Ensure user has a username, generate one if missing"""
        if self.username:
            return self.username
            
        # Generate username from email or display_name
        base_username = None
        if self.display_name:
            # Use display name, remove spaces and special chars
            base_username = re.sub(r'[^a-zA-Z0-9]', '', self.display_name.lower())
        else:
            # Fall back to email prefix
            base_username = self.email.split('@')[0]
            base_username = re.sub(r'[^a-zA-Z0-9]', '', base_username.lower())
        
        # Ensure minimum length
        if len(base_username) < 3:
            base_username = base_username + "user"
            
        # Find available username
        username = base_username
        counter = 1
        while True:
            existing = await User.find_one(User.username == username)
            if not existing:
                break
            username = f"{base_username}{counter}"
            counter += 1
            
        self.username = username
        await self.save()
        return username

    @property
    def effective_username(self) -> str:
        """Get username or fallback to display_name/email"""
        return self.username or self.display_name or self.email.split('@')[0]