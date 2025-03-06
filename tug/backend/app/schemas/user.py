# app/schemas/user.py
from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from datetime import datetime

class UserBase(BaseModel):
    """Base user schema with common attributes"""
    email: EmailStr
    display_name: str = Field(..., min_length=2, max_length=50)

class UserCreate(UserBase):
    """Schema for creating a new user"""
    pass

class UserUpdate(BaseModel):
    """Schema for updating user data"""
    display_name: Optional[str] = Field(None, min_length=2, max_length=50)
    onboarding_completed: Optional[bool] = None

class UserInDB(UserBase):
    """Schema for user as stored in database"""
    id: str
    firebase_uid: str
    created_at: datetime
    last_login: datetime
    onboarding_completed: bool = False

    class Config:
        from_attributes = True

class UserResponse(UserBase):
    """Schema for user data returned to client"""
    id: str
    onboarding_completed: bool

    class Config:
        from_attributes = True