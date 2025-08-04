# app/models/achievement.py
from datetime import datetime
from typing import Optional, List
from beanie import Document, Link
from pydantic import Field
from enum import Enum
from .user import User

class AchievementType(str, Enum):
    streak = "streak"
    balance = "balance"
    frequency = "frequency"
    milestone = "milestone"
    special = "special"

class Achievement(Document):
    """
    Achievement model to track predefined achievements and user progress.
    """
    user_id: str = Field(..., description="ID of the user this achievement belongs to")
    achievement_id: str = Field(..., description="Unique identifier for the achievement type")
    type: AchievementType = Field(..., description="Type of achievement")
    title: str = Field(..., description="Title of the achievement")
    description: str = Field(..., description="Description of the achievement")
    icon: str = Field(..., description="Emoji icon representing the achievement")
    required_value: int = Field(..., description="Value required to unlock this achievement")
    progress: float = Field(default=0.0, description="Current progress toward achievement (0.0-1.0)")
    is_unlocked: bool = Field(default=False, description="Whether the achievement has been unlocked")
    unlocked_at: Optional[datetime] = Field(default=None, description="When the achievement was unlocked")
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Settings:
        name = "achievements"
        
    @classmethod
    async def get_user_achievements(cls, user_id: str) -> List["Achievement"]:
        """Get all achievements for a specific user"""
        return await cls.find(Achievement.user_id == user_id).to_list(length=None)
    
    @classmethod
    async def get_achievement(cls, user_id: str, achievement_id: str) -> Optional["Achievement"]:
        """Get a specific achievement for a user"""
        return await cls.find_one(
            Achievement.user_id == user_id,
            Achievement.achievement_id == achievement_id
        )