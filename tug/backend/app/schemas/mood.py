# app/schemas/mood.py
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from ..models.mood import MoodType

# Request schemas
class MoodEntryCreate(BaseModel):
    mood_type: MoodType = Field(..., description="The selected mood")
    notes: Optional[str] = Field(None, max_length=500, description="Optional elaboration on the mood")
    activity_id: Optional[str] = Field(None, description="Related activity ID if applicable")
    indulgence_id: Optional[str] = Field(None, description="Related indulgence ID if applicable")

class MoodEntryUpdate(BaseModel):
    mood_type: Optional[MoodType] = Field(None, description="Updated mood type")
    notes: Optional[str] = Field(None, max_length=500, description="Updated mood notes")

# Response schemas
class MoodEntryResponse(BaseModel):
    id: str
    user_id: str
    mood_type: MoodType
    positivity_score: int
    notes: Optional[str] = None
    activity_id: Optional[str] = None
    indulgence_id: Optional[str] = None
    recorded_at: datetime
    created_at: datetime
    updated_at: datetime

class MoodOption(BaseModel):
    """Available mood options with their details"""
    mood_type: MoodType
    display_name: str
    positivity_score: int
    description: str
    emoji: str

class MoodOptionsResponse(BaseModel):
    """Response containing all available mood options"""
    moods: List[MoodOption]

class MoodStatistics(BaseModel):
    """Mood statistics for a user"""
    average_positivity: float
    total_entries: int
    most_common_mood: Optional[MoodType] = None
    recent_trend: str  # "improving", "declining", "stable"
    mood_distribution: dict  # mood_type -> count

class MoodCorrelation(BaseModel):
    """Correlation between activities/indulgences and mood"""
    activity_name: Optional[str] = None
    value_name: Optional[str] = None
    indulgence_type: Optional[str] = None
    average_mood_before: float
    average_mood_after: float
    mood_impact: float  # Difference between before/after
    sample_size: int

class MoodAnalyticsResponse(BaseModel):
    """Comprehensive mood analytics"""
    statistics: MoodStatistics
    correlations: List[MoodCorrelation]
    daily_averages: List[dict]  # date -> average_positivity
    mood_timeline: List[MoodEntryResponse]

# Chart data for frontend
class MoodChartData(BaseModel):
    """Data formatted for mood charts"""
    date: datetime
    mood_score: float
    mood_type: MoodType
    activity_name: Optional[str] = None
    value_name: Optional[str] = None

class MoodChartResponse(BaseModel):
    """Response for mood chart overlay"""
    mood_data: List[MoodChartData]
    date_range: dict  # start_date, end_date
    average_mood: float