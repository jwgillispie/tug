# app/schemas/habit_suggestion.py
from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime
from enum import Enum

from ..models.habit_suggestion import SuggestionType, SuggestionCategory, DifficultyLevel

class HabitTemplateResponse(BaseModel):
    """Response schema for habit templates"""
    id: str
    name: str
    description: str
    category: SuggestionCategory
    difficulty_level: DifficultyLevel
    estimated_duration: int
    tags: List[str] = []
    value_categories: List[str] = []
    requires_equipment: bool = False
    requires_outdoors: bool = False
    requires_quiet: bool = False
    optimal_time_of_day: List[str] = []
    success_indicators: List[str] = []
    tips_for_success: List[str] = []
    popularity_score: float = 0.0
    effectiveness_rating: float = 0.0

class PersonalizedSuggestionResponse(BaseModel):
    """Response schema for personalized suggestions"""
    id: str
    suggestion_type: SuggestionType
    template: Optional[HabitTemplateResponse] = None
    customized_name: Optional[str] = None
    customized_description: Optional[str] = None
    suggested_duration: int
    suggested_frequency: str = "daily"
    suggested_times: List[str] = []
    context_tags: List[str] = []
    related_value_ids: List[str] = []
    compatibility_score: float
    success_probability: float
    urgency_score: float = 0.0
    reasons: List[str] = []
    personalization_factors: Dict[str, Any] = {}
    shown_count: int = 0
    created_at: datetime
    expires_at: Optional[datetime] = None

class SuggestionInteractionRequest(BaseModel):
    """Request schema for suggestion interactions"""
    action: str = Field(..., pattern="^(viewed|clicked|dismissed|adopted)$")
    context: Optional[Dict[str, Any]] = None

class SuggestionFeedbackRequest(BaseModel):
    """Request schema for suggestion feedback"""
    rating: Optional[int] = Field(None, ge=1, le=5)
    feedback_text: Optional[str] = Field(None, max_length=500)

class HabitDiscoveryRequest(BaseModel):
    """Request schema for habit discovery"""
    category: Optional[SuggestionCategory] = None
    difficulty: Optional[DifficultyLevel] = None
    max_duration: Optional[int] = Field(None, ge=1, le=180)
    tags: Optional[List[str]] = None

class SuggestionGenerationRequest(BaseModel):
    """Request schema for generating suggestions"""
    max_suggestions: Optional[int] = Field(10, ge=1, le=20)
    suggestion_types: Optional[List[SuggestionType]] = None
    refresh_existing: bool = False

class SuggestionAnalyticsResponse(BaseModel):
    """Response schema for suggestion analytics"""
    total_suggestions: int
    viewed_suggestions: int
    clicked_suggestions: int
    dismissed_suggestions: int
    adopted_suggestions: int
    view_rate: float
    click_rate: float
    adoption_rate: float
    dismiss_rate: float
    avg_rating: float
    total_feedback: int
    popular_suggestion_types: List[tuple] = []

class CategoryStatsResponse(BaseModel):
    """Response schema for category statistics"""
    category: SuggestionCategory
    count: int
    avg_popularity: float
    avg_effectiveness: float

class SuggestionConfigResponse(BaseModel):
    """Response schema for suggestion configuration"""
    compatibility_weight: float
    success_probability_weight: float
    urgency_weight: float
    novelty_weight: float
    popularity_weight: float
    min_compatibility_score: float
    min_success_probability: float
    max_suggestions_per_user: int
    suggestion_refresh_hours: int
    max_suggestion_lifetime_days: int