# app/schemas/achievement.py
from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, Field
from ..models.achievement import AchievementType

class AchievementBase(BaseModel):
    """Base schema for achievement data"""
    achievement_id: str = Field(..., description="Unique identifier for the achievement type")
    type: AchievementType = Field(..., description="Type of achievement")
    title: str = Field(..., description="Title of the achievement")
    description: str = Field(..., description="Description of the achievement")
    icon: str = Field(..., description="Emoji icon representing the achievement")
    required_value: int = Field(..., description="Value required to unlock this achievement")

class AchievementCreate(AchievementBase):
    """Schema for creating a new achievement"""
    user_id: str = Field(..., description="ID of the user this achievement belongs to")
    
class AchievementUpdate(BaseModel):
    """Schema for updating an achievement"""
    progress: Optional[float] = Field(None, description="Current progress toward achievement (0.0-1.0)")
    is_unlocked: Optional[bool] = Field(None, description="Whether the achievement has been unlocked")
    unlocked_at: Optional[datetime] = Field(None, description="When the achievement was unlocked")
    
    class Config:
        json_schema_extra = {
            "example": {
                "progress": 0.75,
                "is_unlocked": True,
                "unlocked_at": "2025-05-08T12:30:45"
            }
        }

class AchievementResponse(AchievementBase):
    """Schema for achievement responses"""
    id: str = Field(..., description="MongoDB ObjectID of the achievement")
    user_id: str = Field(..., description="ID of the user this achievement belongs to")
    progress: float = Field(..., description="Current progress toward achievement (0.0-1.0)")
    is_unlocked: bool = Field(..., description="Whether the achievement has been unlocked")
    unlocked_at: Optional[datetime] = Field(None, description="When the achievement was unlocked")
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True
        json_schema_extra = {
            "example": {
                "id": "60d21b4667d0d8992e610c85",
                "user_id": "60d21b4667d0d8992e610c85",
                "achievement_id": "streak_7",
                "type": "streak",
                "title": "Week Warrior",
                "description": "Complete activities for the same value 7 days in a row",
                "icon": "📅",
                "required_value": 7,
                "progress": 0.75,
                "is_unlocked": False,
                "unlocked_at": None,
                "created_at": "2025-05-01T12:00:00",
                "updated_at": "2025-05-08T12:30:45"
            }
        }

class PredefinedAchievement(BaseModel):
    """Schema for predefined achievement templates"""
    achievement_id: str
    type: AchievementType
    title: str
    description: str
    icon: str
    required_value: int
    
    class Config:
        json_schema_extra = {
            "example": {
                "achievement_id": "streak_7",
                "type": "streak",
                "title": "Week Warrior",
                "description": "Complete activities for the same value 7 days in a row",
                "icon": "📅",
                "required_value": 7
            }
        }