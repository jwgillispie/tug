# app/models/activity.py
from beanie import Document, Indexed, Link
from typing import Optional, List
from datetime import datetime, timedelta
from bson import ObjectId
from fastapi import logger
from pydantic import Field

class Activity(Document):
    """Activity model for MongoDB with Beanie ODM"""
    user_id: str = Indexed()
    # Support both old and new formats for backward compatibility
    value_ids: Optional[List[str]] = Field(None, description="IDs of the values this activity is for")
    value_id: Optional[str] = Field(None, description="Legacy single value ID (deprecated)")
    name: str = Field(..., min_length=2, max_length=50)
    duration: int = Field(..., gt=0, le=1440)  # in minutes, max 24 hours
    date: datetime = Indexed()
    notes: Optional[str] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)
    is_public: bool = Field(default=True)  # Whether activity is shared publicly
    notes_public: bool = Field(default=False)  # Whether notes are shared publicly
    version: int = 1

    def __init__(self, **data):
        # Handle migration from old value_id to new value_ids
        if 'value_id' in data and 'value_ids' not in data:
            data['value_ids'] = [data['value_id']]
        elif 'value_ids' in data and 'value_id' not in data and data['value_ids']:
            data['value_id'] = data['value_ids'][0]
        super().__init__(**data)
    
    @classmethod
    def model_validate(cls, obj):
        """Custom validation to handle legacy data format"""
        if isinstance(obj, dict):
            # Handle legacy format where only value_id exists
            if 'value_id' in obj and 'value_ids' not in obj:
                obj = obj.copy()
                obj['value_ids'] = [obj['value_id']]
            # Handle new format where only value_ids exists
            elif 'value_ids' in obj and 'value_id' not in obj and obj['value_ids']:
                obj = obj.copy()
                obj['value_id'] = obj['value_ids'][0]
        return super().model_validate(obj)

    @property
    def primary_value_id(self) -> Optional[str]:
        """Return the primary (first) value ID"""
        if self.value_ids:
            return self.value_ids[0]
        return self.value_id
    
    @property
    def has_multiple_values(self) -> bool:
        """Check if this activity has multiple values"""
        return self.value_ids is not None and len(self.value_ids) > 1

    @property
    def effective_value_ids(self) -> List[str]:
        """Get the effective list of value IDs, handling both old and new formats"""
        if self.value_ids:
            return self.value_ids
        elif self.value_id:
            return [self.value_id]
        return []

    class Settings:
        name = "activities"
        indexes = [
            # Core query patterns - high priority
            [("user_id", 1), ("date", -1)],  # User activity timeline
            [("user_id", 1), ("value_ids", 1), ("date", -1)],  # Value-specific queries
            [("value_ids", 1), ("date", -1)],  # Cross-user value analytics
            
            # Analytics and aggregation optimization
            [("user_id", 1), ("date", -1), ("duration", 1)],  # Duration aggregations
            [("date", -1), ("user_id", 1)],  # Global activity feed and rankings
            [("user_id", 1), ("created_at", -1)],  # User activity history
            
            # Public/privacy queries
            [("is_public", 1), ("date", -1)],  # Public activity feed
            [("user_id", 1), ("is_public", 1), ("date", -1)],  # User's public activities
            
            # Analytics support indexes
            [("date", -1), ("duration", 1)],  # Global analytics queries
            [("user_id", 1), ("date", 1)],  # Ascending date for streak calculations
            [("value_ids", 1), ("user_id", 1), ("date", -1)],  # Value analytics by user
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
        json_schema_extra = {
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