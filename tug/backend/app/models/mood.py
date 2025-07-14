# app/models/mood.py
from beanie import Document
from datetime import datetime
from typing import Optional
from enum import Enum
from pydantic import Field

class MoodType(str, Enum):
    ECSTATIC = "ecstatic"
    JOYFUL = "joyful"
    CONFIDENT = "confident"
    CONTENT = "content"
    FOCUSED = "focused"
    NEUTRAL = "neutral"
    RESTLESS = "restless"
    TIRED = "tired"
    FRUSTRATED = "frustrated"
    ANXIOUS = "anxious"
    SAD = "sad"
    OVERWHELMED = "overwhelmed"
    ANGRY = "angry"
    DEFEATED = "defeated"
    DEPRESSED = "depressed"

# Mood positivity mapping
MOOD_POSITIVITY_SCORES = {
    MoodType.ECSTATIC: 10,
    MoodType.JOYFUL: 9,
    MoodType.CONFIDENT: 8,
    MoodType.CONTENT: 7,
    MoodType.FOCUSED: 6,
    MoodType.NEUTRAL: 5,
    MoodType.RESTLESS: 4,
    MoodType.TIRED: 3,
    MoodType.FRUSTRATED: 2,
    MoodType.ANXIOUS: 2,
    MoodType.SAD: 1,
    MoodType.OVERWHELMED: 1,
    MoodType.ANGRY: 1,
    MoodType.DEFEATED: 0,
    MoodType.DEPRESSED: 0,
}

class MoodEntry(Document):
    """Mood tracking entry linked to activities or indulgences"""
    
    user_id: str = Field(..., description="User who recorded this mood")
    mood_type: MoodType = Field(..., description="The selected mood")
    positivity_score: int = Field(..., description="Numerical positivity value (0-10)")
    notes: Optional[str] = Field(None, description="Optional elaboration on the mood")
    
    # Link to related activity or indulgence
    activity_id: Optional[str] = Field(None, description="Related activity ID if applicable")
    indulgence_id: Optional[str] = Field(None, description="Related indulgence ID if applicable")
    
    # Timestamps
    recorded_at: datetime = Field(default_factory=datetime.utcnow, description="When mood was recorded")
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    def update_timestamp(self):
        """Update the updated_at timestamp"""
        self.updated_at = datetime.utcnow()
    
    @classmethod
    def get_positivity_score(cls, mood_type: MoodType) -> int:
        """Get the positivity score for a mood type"""
        return MOOD_POSITIVITY_SCORES.get(mood_type, 5)
    
    @classmethod
    def create_mood_entry(cls, user_id: str, mood_type: MoodType, notes: Optional[str] = None, 
                         activity_id: Optional[str] = None, indulgence_id: Optional[str] = None):
        """Create a new mood entry with automatic positivity score"""
        positivity_score = cls.get_positivity_score(mood_type)
        return cls(
            user_id=user_id,
            mood_type=mood_type,
            positivity_score=positivity_score,
            notes=notes,
            activity_id=activity_id,
            indulgence_id=indulgence_id
        )

    class Settings:
        name = "mood_entries"
        indexes = [
            [("user_id", 1), ("recorded_at", -1)],  # For user mood history
            [("user_id", 1), ("activity_id", 1)],   # For activity-mood correlations
            [("user_id", 1), ("indulgence_id", 1)], # For indulgence-mood correlations
        ]