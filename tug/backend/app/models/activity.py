# app/models/activity.py
from beanie import Document, Indexed, Link
from typing import Optional
from datetime import datetime, timedelta
from bson import ObjectId
from fastapi import logger
from pydantic import Field

class Activity(Document):
    """Activity model for MongoDB with Beanie ODM"""
    user_id: str = Indexed()
    value_id: str = Indexed()
    name: str = Field(..., min_length=2, max_length=50)
    duration: int = Field(..., gt=0, le=1440)  # in minutes, max 24 hours
    date: datetime = Indexed()
    notes: Optional[str] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)
    is_public: bool = Field(default=True)  # Whether activity is shared publicly
    notes_public: bool = Field(default=False)  # Whether notes are shared publicly
    version: int = 1

    class Settings:
        name = "activities"
        indexes = [
            [("user_id", 1), ("date", -1)],
            [("value_id", 1), ("date", -1)],
            [("user_id", 1), ("value_id", 1), ("date", -1)]
        ]
# Add this method to the Activity model in app/models/activity.py if it doesn't exist or update it

    @classmethod
    async def get_by_id(cls, id: str, user_id: str):
        """Get activity by ID with proper ObjectId conversion"""
        try:
            # Convert string ID to ObjectId if it's not already
            if not isinstance(id, ObjectId):
                try:
                    object_id = ObjectId(id)
                except:
                    return None
            else:
                object_id = id
                
            # Find the activity by ID and user_id
            return await cls.find_one(
                cls.id == object_id,
                cls.user_id == user_id
            )
        except Exception as e:
            logger.error(f"Error in get_by_id: {e}")
            return None
    @property
    def duration_hours(self) -> float:
        """Convert minutes to hours"""
        return round(self.duration / 60, 2)

    async def calculate_daily_total(self) -> int:
        """Calculate total minutes for this activity on this date"""
        start_of_day = datetime.combine(self.date.date(), datetime.min.time())
        end_of_day = start_of_day + timedelta(days=1)
        
        total = await Activity.find(
            Activity.user_id == self.user_id,
            Activity.date >= start_of_day,
            Activity.date < end_of_day
        ).sum("duration")
        
        return total or 0

    class Config:
        schema_extra = {
            "example": {
                "user_id": "user123",
                "value_id": "value456",
                "name": "Morning Exercise",
                "duration": 30,
                "date": "2024-02-12T08:00:00Z",
                "notes": "Morning jog in the park",
                "created_at": "2024-02-12T08:30:00Z"
            }
        }