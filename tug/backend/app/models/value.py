# app/models/value.py
from beanie import Document, Indexed, Link
from typing import Optional, Any, Dict, List
from datetime import datetime, date
from pydantic import Field

class Value(Document):
    """Value model for MongoDB with Beanie ODM"""
    user_id: str = Indexed()
    name: str = Field(..., min_length=2, max_length=30)
    importance: int = Field(..., ge=1, le=5)
    description: Optional[str] = None
    color: str = Field(..., pattern="^#[0-9a-fA-F]{6}$")    
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    active: bool = True
    version: int = 1
    current_streak: int = 0
    longest_streak: int = 0
    last_activity_date: Optional[date] = None
    streak_dates: List[date] = []

    class Settings:
        name = "values"
        indexes = [
            # Core user queries - high priority
            [("user_id", 1), ("active", 1)],  # Active values lookup
            [("user_id", 1), ("created_at", -1)],  # Value timeline
            [("user_id", 1), ("importance", -1)],  # Sorted by importance
            
            # Compound indexes for common patterns
            [("user_id", 1), ("active", 1), ("importance", -1)],  # Active values by importance
            [("user_id", 1), ("active", 1), ("created_at", -1)],  # Active values timeline
            
            # Analytics support
            [("user_id", 1), ("current_streak", -1)],  # Streak leaderboards
            [("user_id", 1), ("longest_streak", -1)],  # Achievement tracking
            [("user_id", 1), ("last_activity_date", -1)],  # Recent activity analysis
            
            # Global analytics (optional, for cross-user insights)
            [("active", 1), ("importance", -1)],  # Popular values analysis
        ]

    class Config:
        json_schema_extra = {
            "example": {
                "user_id": "user123",
                "name": "Health",
                "importance": 5,
                "description": "Physical and mental well-being",
                "color": "#4CAF50",
                "created_at": "2024-02-12T00:00:00Z",
                "updated_at": "2024-02-12T00:00:00Z",
                "active": True
            }
        }
    
    def dict(self, **kwargs) -> Dict[str, Any]:
        """Override default dict to convert ObjectId to string."""
        data = super().dict(**kwargs)
        # Convert the _id field to a string
        if '_id' in data:
            data['id'] = str(data.pop('_id'))
        elif 'id' in data and data['id'] is not None:
            data['id'] = str(data['id'])
        return data