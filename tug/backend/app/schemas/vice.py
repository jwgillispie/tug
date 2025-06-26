# app/schemas/vice.py
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime

class ViceBase(BaseModel):
    """Base vice schema with common attributes"""
    name: str = Field(..., min_length=2, max_length=50)
    severity: int = Field(..., ge=1, le=5, description="Severity level from 1 (mild) to 5 (critical)")
    description: Optional[str] = Field(default="", max_length=500)
    color: str = Field(..., pattern="^#[0-9a-fA-F]{6}$")

class ViceCreate(ViceBase):
    """Schema for creating a new vice"""
    pass

class ViceUpdate(BaseModel):
    """Schema for updating a vice"""
    name: Optional[str] = Field(None, min_length=2, max_length=50)
    severity: Optional[int] = Field(None, ge=1, le=5)
    description: Optional[str] = Field(None, max_length=500)
    color: Optional[str] = Field(None, pattern="^#[0-9a-fA-F]{6}$")
    active: Optional[bool] = None

class ViceInDB(ViceBase):
    """Schema for vice as stored in database"""
    id: str
    user_id: str
    active: bool
    created_at: datetime
    updated_at: datetime
    current_streak: int
    longest_streak: int
    last_indulgence_date: Optional[datetime]
    total_indulgences: int
    indulgence_dates: List[datetime]

    class Config:
        from_attributes = True

class ViceResponse(ViceBase):
    """Schema for vice data returned to client"""
    id: str
    active: bool
    created_at: datetime
    updated_at: datetime
    current_streak: int
    longest_streak: int
    last_indulgence_date: Optional[datetime]
    total_indulgences: int
    indulgence_dates: List[datetime]

    class Config:
        from_attributes = True

class StreakUpdate(BaseModel):
    """Schema for updating vice streak"""
    current_streak: int = Field(..., ge=0)

class CleanDay(BaseModel):
    """Schema for marking a clean day"""
    date: datetime = Field(..., description="Date to mark as clean day")