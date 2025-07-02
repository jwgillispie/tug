# app/schemas/activity.py
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime

class ActivityBase(BaseModel):
    """Base activity schema with common attributes"""
    name: str = Field(..., min_length=2, max_length=50)
    duration: int = Field(..., gt=0, le=1440)  # in minutes, max 24 hours
    value_id: str
    notes: Optional[str] = None
    is_public: bool = Field(default=True)  # Whether activity is shared publicly
    notes_public: bool = Field(default=False)  # Whether notes are shared publicly

class ActivityCreate(ActivityBase):
    """Schema for creating a new activity"""
    date: datetime = Field(default_factory=datetime.utcnow)

class ActivityUpdate(BaseModel):
    """Schema for updating an activity"""
    name: Optional[str] = Field(None, min_length=2, max_length=50)
    duration: Optional[int] = Field(None, gt=0, le=1440)
    value_id: Optional[str] = None
    date: Optional[datetime] = None
    notes: Optional[str] = None
    is_public: Optional[bool] = None
    notes_public: Optional[bool] = None

class ActivityInDB(ActivityBase):
    """Schema for activity as stored in database"""
    id: str
    user_id: str
    date: datetime
    created_at: datetime

    class Config:
        from_attributes = True

class ActivityResponse(ActivityBase):
    """Schema for activity data returned to client"""
    id: str
    date: datetime
    created_at: datetime

    class Config:
        from_attributes = True
        arbitrary_types_allowed = True
        
    @property
    def duration_hours(self) -> float:
        """Convert minutes to hours"""
        return round(self.duration / 60, 2)

class ActivityStatistics(BaseModel):
    """Schema for activity statistics"""
    total_activities: int
    total_duration_minutes: int
    total_duration_hours: float
    average_duration_minutes: float