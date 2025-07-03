# app/models/indulgence.py
from beanie import Document, Indexed, Link
from typing import Optional, Any, Dict, List
from datetime import datetime
from pydantic import Field
from .vice import Vice

class Indulgence(Document):
    """Indulgence model for MongoDB with Beanie ODM"""
    vice_id: str = Indexed()
    user_id: str = Indexed()
    date: datetime = Field(..., description="When the indulgence occurred")
    duration: Optional[int] = Field(default=None, ge=0, description="Duration in minutes (optional)")
    notes: str = Field(default="", max_length=1000, description="Personal notes about the indulgence")
    severity_at_time: int = Field(..., ge=1, le=5, description="Vice severity level at time of indulgence")
    triggers: List[str] = Field(default_factory=list, description="What triggered this indulgence")
    emotional_state: int = Field(default=5, ge=1, le=10, description="Emotional state before indulgence (1-10)")
    is_public: bool = Field(default=False, description="Whether indulgence is shared publicly")
    notes_public: bool = Field(default=False, description="Whether notes are shared publicly")
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

    class Settings:
        name = "indulgences"
        indexes = [
            [("user_id", 1), ("date", -1)],
            [("vice_id", 1), ("date", -1)],
            [("user_id", 1), ("vice_id", 1), ("date", -1)]
        ]

    class Config:
        schema_extra = {
            "example": {
                "vice_id": "vice123",
                "user_id": "user123",
                "date": "2024-02-12T14:30:00Z",
                "duration": 15,
                "notes": "Felt stressed after work meeting",
                "severity_at_time": 3,
                "triggers": ["stress", "work"],
                "emotional_state": 3
            }
        }
    
    def dict(self, **kwargs) -> Dict[str, Any]:
        """Override default dict to convert ObjectId to string and format dates."""
        data = super().dict(**kwargs)
        # Convert the _id field to a string
        if '_id' in data:
            data['id'] = str(data.pop('_id'))
        elif 'id' in data and data['id'] is not None:
            data['id'] = str(data['id'])
        
        # Convert datetime fields to ISO format strings for JSON serialization
        datetime_fields = ['date', 'created_at', 'updated_at']
        for field in datetime_fields:
            if field in data and data[field] is not None:
                if isinstance(data[field], datetime):
                    data[field] = data[field].isoformat()
        
        return data

    @property
    def time_of_day(self) -> str:
        """Get time of day when indulgence occurred"""
        hour = self.date.hour
        if hour < 6:
            return "Late Night"
        elif hour < 12:
            return "Morning"
        elif hour < 17:
            return "Afternoon"
        elif hour < 21:
            return "Evening"
        else:
            return "Night"

    @property
    def emotional_state_description(self) -> str:
        """Get emotional state description"""
        if self.emotional_state <= 2:
            return "Very Low"
        elif self.emotional_state <= 4:
            return "Low"
        elif self.emotional_state <= 6:
            return "Neutral"
        elif self.emotional_state <= 8:
            return "Good"
        else:
            return "Very Good"

    @property
    def is_high_risk(self) -> bool:
        """Check if this was a high-risk indulgence"""
        return self.severity_at_time >= 4 or self.emotional_state <= 3

    @property
    def formatted_duration(self) -> str:
        """Get formatted duration string"""
        if self.duration is None:
            return "Not tracked"
        if self.duration < 60:
            return f"{self.duration}m"
        
        hours = self.duration // 60
        minutes = self.duration % 60
        if minutes == 0:
            return f"{hours}h"
        return f"{hours}h {minutes}m"

    async def update_vice_streak(self):
        """Update the associated vice's streak when this indulgence is recorded"""
        try:
            # Find the associated vice
            vice = await Vice.get(self.vice_id)
            if vice:
                await vice.update_streak_on_indulgence()
        except Exception as e:
            # Log error but don't fail the indulgence creation
            print(f"Error updating vice streak: {e}")
            pass