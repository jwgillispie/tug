# app/schemas/value.py
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

class ValueBase(BaseModel):
    """Base value schema with common attributes"""
    name: str = Field(..., min_length=2, max_length=30)
    importance: int = Field(..., ge=1, le=5)
    description: Optional[str] = None
color: str = Field(..., pattern="^#[0-9a-fA-F]{6}$")
class ValueCreate(ValueBase):
    """Schema for creating a new value"""
    pass

class ValueUpdate(BaseModel):
    """Schema for updating a value"""
    name: Optional[str] = Field(None, min_length=2, max_length=30)
    importance: Optional[int] = Field(None, ge=1, le=5)
    description: Optional[str] = None
    color: Optional[str] = Field(None, pattern="^#[0-9a-fA-F]{6}$")
    active: Optional[bool] = None

class ValueInDB(ValueBase):
    """Schema for value as stored in database"""
    id: str
    user_id: str
    created_at: datetime
    updated_at: datetime
    active: bool

    class Config:
        from_attributes = True

class ValueResponse(ValueBase):
    """Schema for value data returned to client"""
    id: str
    created_at: datetime
    updated_at: datetime
    active: bool

    class Config:
        from_attributes = True