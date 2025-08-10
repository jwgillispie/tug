# app/models/habit_suggestion.py
from beanie import Document, Indexed
from typing import Optional, List, Dict, Any
from datetime import datetime
from pydantic import Field
from enum import Enum

class SuggestionType(str, Enum):
    MICRO_HABIT = "micro_habit"
    HABIT_STACK = "habit_stack"  
    COMPLEMENTARY = "complementary"
    GOAL_ORIENTED = "goal_oriented"
    TIMING_OPTIMIZED = "timing_optimized"
    RECOVERY = "recovery"
    SEASONAL = "seasonal"
    PROGRESSIVE = "progressive"

class SuggestionCategory(str, Enum):
    HEALTH_FITNESS = "health_fitness"
    MINDFULNESS = "mindfulness"
    PRODUCTIVITY = "productivity"
    RELATIONSHIPS = "relationships"
    LEARNING = "learning"
    CREATIVITY = "creativity"
    SELF_CARE = "self_care"
    CAREER = "career"
    FINANCE = "finance"
    ENVIRONMENT = "environment"

class DifficultyLevel(str, Enum):
    VERY_EASY = "very_easy"      # 1-2 minutes
    EASY = "easy"                # 5-10 minutes
    MEDIUM = "medium"            # 15-30 minutes
    HARD = "hard"                # 45-60 minutes
    VERY_HARD = "very_hard"      # 90+ minutes

class HabitTemplate(Document):
    """Template for habit suggestions with metadata"""
    
    name: str = Field(..., min_length=2, max_length=50)
    description: str = Field(..., max_length=500)
    category: SuggestionCategory
    difficulty_level: DifficultyLevel
    estimated_duration: int = Field(..., gt=0, le=180)  # minutes
    
    # Tags for matching and filtering
    tags: List[str] = Field(default_factory=list)
    value_categories: List[str] = Field(default_factory=list)  # Maps to common value types
    
    # Behavioral requirements
    requires_equipment: bool = False
    requires_outdoors: bool = False
    requires_quiet: bool = False
    optimal_time_of_day: List[str] = Field(default_factory=list)  # morning, afternoon, evening, night
    
    # Success metrics
    success_indicators: List[str] = Field(default_factory=list)
    common_obstacles: List[str] = Field(default_factory=list)
    tips_for_success: List[str] = Field(default_factory=list)
    
    # Habit stacking information
    good_before_habits: List[str] = Field(default_factory=list)  # Habits that work well before this one
    good_after_habits: List[str] = Field(default_factory=list)   # Habits that work well after this one
    
    # Metadata
    popularity_score: float = Field(default=0.0, ge=0.0, le=1.0)
    effectiveness_rating: float = Field(default=0.0, ge=0.0, le=5.0)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    is_active: bool = True
    
    class Settings:
        name = "habit_templates"
        indexes = [
            [("category", 1), ("difficulty_level", 1)],
            [("tags", 1)],
            [("value_categories", 1)],
            [("popularity_score", -1)],
            [("effectiveness_rating", -1)],
            [("is_active", 1), ("category", 1)]
        ]

class PersonalizedSuggestion(Document):
    """Personalized habit suggestion for a specific user"""
    
    user_id: str = Indexed()
    habit_template_id: str = Indexed()
    suggestion_type: SuggestionType
    
    # Personalization
    customized_name: Optional[str] = None
    customized_description: Optional[str] = None
    suggested_duration: int = Field(..., gt=0, le=180)  # minutes
    suggested_frequency: str = Field(default="daily")  # daily, weekly, weekdays, etc.
    
    # Context
    suggested_times: List[str] = Field(default_factory=list)  # Specific time suggestions
    context_tags: List[str] = Field(default_factory=list)    # Personal context (at_home, at_work, etc.)
    related_value_ids: List[str] = Field(default_factory=list)
    
    # ML-driven scores
    compatibility_score: float = Field(..., ge=0.0, le=1.0)  # How well it matches user
    success_probability: float = Field(..., ge=0.0, le=1.0)  # Predicted success rate
    urgency_score: float = Field(default=0.0, ge=0.0, le=1.0)  # How urgently needed
    
    # Recommendation reasoning
    reasons: List[str] = Field(default_factory=list)
    personalization_factors: Dict[str, Any] = Field(default_factory=dict)
    
    # User interaction tracking
    shown_count: int = 0
    clicked: bool = False
    dismissed: bool = False
    adopted: bool = False
    adopted_date: Optional[datetime] = None
    feedback_rating: Optional[int] = Field(None, ge=1, le=5)
    
    # Metadata
    created_at: datetime = Field(default_factory=datetime.utcnow)
    expires_at: Optional[datetime] = None  # When this suggestion expires
    last_shown: Optional[datetime] = None
    
    class Settings:
        name = "personalized_suggestions"
        indexes = [
            [("user_id", 1), ("created_at", -1)],
            [("user_id", 1), ("suggestion_type", 1)],
            [("user_id", 1), ("compatibility_score", -1)],
            [("user_id", 1), ("success_probability", -1)],
            [("user_id", 1), ("dismissed", 1), ("adopted", 1)],
            [("habit_template_id", 1), ("adopted", 1)],
            [("expires_at", 1)],
            [("user_id", 1), ("urgency_score", -1)]
        ]

class SuggestionFeedback(Document):
    """User feedback on habit suggestions for ML training"""
    
    user_id: str = Indexed()
    suggestion_id: str = Indexed()
    habit_template_id: str
    
    # Feedback data
    action: str = Field(..., pattern="^(viewed|clicked|dismissed|adopted|rated)$")
    rating: Optional[int] = Field(None, ge=1, le=5)
    feedback_text: Optional[str] = Field(None, max_length=500)
    
    # Context when feedback was given
    user_context: Dict[str, Any] = Field(default_factory=dict)
    suggestion_context: Dict[str, Any] = Field(default_factory=dict)
    
    # Timing
    created_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Settings:
        name = "suggestion_feedback"
        indexes = [
            [("user_id", 1), ("created_at", -1)],
            [("suggestion_id", 1)],
            [("habit_template_id", 1), ("action", 1)],
            [("action", 1), ("created_at", -1)]
        ]

class HabitRecommendationConfig(Document):
    """Global configuration for habit recommendation algorithm"""
    
    # Algorithm weights
    compatibility_weight: float = 0.3
    success_probability_weight: float = 0.25
    urgency_weight: float = 0.2
    novelty_weight: float = 0.15
    popularity_weight: float = 0.1
    
    # Filtering thresholds
    min_compatibility_score: float = 0.3
    min_success_probability: float = 0.2
    max_suggestions_per_user: int = 10
    
    # Timing parameters
    suggestion_refresh_hours: int = 24
    max_suggestion_lifetime_days: int = 7
    
    # User behavior parameters
    max_shown_before_rotation: int = 3
    cooldown_after_dismiss_hours: int = 48
    
    # Defaults
    default_suggestion_duration: int = 15
    default_difficulty_preference: DifficultyLevel = DifficultyLevel.EASY
    
    # Metadata
    version: str = "1.0"
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    is_active: bool = True
    
    class Settings:
        name = "habit_recommendation_config"
        indexes = [
            [("version", 1)],
            [("is_active", 1), ("updated_at", -1)]
        ]