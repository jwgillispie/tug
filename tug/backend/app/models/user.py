# app/models/user.py
from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from datetime import datetime

class UserBase(BaseModel):
    email: EmailStr
    display_name: str = Field(..., min_length=2, max_length=50)

class UserCreate(UserBase):
    pass

class UserInDB(UserBase):
    id: str
    firebase_uid: str
    created_at: datetime
    last_login: datetime
    onboarding_completed: bool = False

    class Config:
        from_attributes = True

class UserUpdate(BaseModel):
    display_name: Optional[str] = Field(None, min_length=2, max_length=50)
    onboarding_completed: Optional[bool] = None