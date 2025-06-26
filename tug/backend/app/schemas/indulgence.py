# app/schemas/indulgence.py
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime

class IndulgenceBase(BaseModel):
    """Base indulgence schema with common attributes"""
    date: datetime = Field(..., description="When the indulgence occurred")
    duration: Optional[int] = Field(default=None, ge=0, description="Duration in minutes (optional)")
    notes: str = Field(default="", max_length=1000, description="Personal notes about the indulgence")
    severity_at_time: int = Field(..., ge=1, le=5, description="Vice severity level at time of indulgence")
    triggers: List[str] = Field(default_factory=list, description="What triggered this indulgence")
    emotional_state: int = Field(default=5, ge=1, le=10, description="Emotional state before indulgence (1-10)")

class IndulgenceCreate(IndulgenceBase):
    """Schema for creating a new indulgence"""
    vice_id: str = Field(..., description="ID of the vice this indulgence is for")

class IndulgenceUpdate(BaseModel):
    """Schema for updating an indulgence"""
    date: Optional[datetime] = None
    duration: Optional[int] = Field(None, ge=0)
    notes: Optional[str] = Field(None, max_length=1000)
    severity_at_time: Optional[int] = Field(None, ge=1, le=5)
    triggers: Optional[List[str]] = None
    emotional_state: Optional[int] = Field(None, ge=1, le=10)

class IndulgenceInDB(IndulgenceBase):
    """Schema for indulgence as stored in database"""
    id: str
    vice_id: str
    user_id: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class IndulgenceResponse(IndulgenceBase):
    """Schema for indulgence data returned to client"""
    id: str
    vice_id: str
    user_id: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True