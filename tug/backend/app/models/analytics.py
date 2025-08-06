# app/models/analytics.py
from beanie import Document, Indexed
from typing import Dict, Any, Optional, List
from datetime import datetime
from pydantic import Field
from enum import Enum


class AnalyticsType(str, Enum):
    """Types of analytics data"""
    DAILY = "daily"
    WEEKLY = "weekly"
    MONTHLY = "monthly"
    YEARLY = "yearly"


class MetricType(str, Enum):
    """Types of metrics tracked"""
    ACTIVITY_COUNT = "activity_count"
    DURATION_TOTAL = "duration_total"
    STREAK_LENGTH = "streak_length"
    VALUE_PROGRESS = "value_progress"
    CONSISTENCY_SCORE = "consistency_score"
    GOAL_ACHIEVEMENT = "goal_achievement"


class UserAnalytics(Document):
    """Aggregated analytics data for users"""
    user_id: str = Indexed()
    analytics_type: AnalyticsType = Indexed()
    metric_type: MetricType = Indexed()
    date_range_start: datetime = Indexed()
    date_range_end: datetime = Indexed()
    
    # Core metrics
    value: float = Field(..., description="Primary metric value")
    previous_value: Optional[float] = Field(None, description="Previous period value for comparison")
    percentage_change: Optional[float] = Field(None, description="Percentage change from previous period")
    
    # Additional context data
    metadata: Dict[str, Any] = Field(default_factory=dict)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

    class Settings:
        name = "user_analytics"
        indexes = [
            # Core analytics queries - high priority
            [("user_id", 1), ("analytics_type", 1), ("metric_type", 1)],  # Primary lookup
            [("user_id", 1), ("date_range_start", -1)],  # User analytics timeline
            [("analytics_type", 1), ("metric_type", 1), ("date_range_start", -1)],  # Global analytics
            
            # Performance and trending queries
            [("user_id", 1), ("analytics_type", 1), ("value", -1)],  # User performance ranking
            [("user_id", 1), ("metric_type", 1), ("value", -1)],  # User metric ranking
            [("analytics_type", 1), ("value", -1), ("date_range_start", -1)],  # Global performance
            
            # Comparison and growth analytics
            [("user_id", 1), ("percentage_change", -1)],  # User growth ranking
            [("analytics_type", 1), ("percentage_change", -1)],  # Global growth trends
            [("metric_type", 1), ("percentage_change", -1)],  # Metric growth trends
            
            # Time-based analytics
            [("date_range_start", -1), ("analytics_type", 1)],  # Historical analytics by type
            [("date_range_end", -1), ("user_id", 1)],  # Recent completed analytics
            [("created_at", -1)],  # Analytics creation timeline
            [("updated_at", -1)],  # Recently updated analytics
            
            # Compound performance queries
            [("user_id", 1), ("analytics_type", 1), ("date_range_start", -1), ("value", -1)],  # User performance over time
            [("analytics_type", 1), ("metric_type", 1), ("value", -1)],  # Global metric performance
        ]


class ValueInsights(Document):
    """Detailed insights for specific values"""
    user_id: str = Indexed()
    value_id: str = Indexed()
    
    # Progress patterns
    best_day_of_week: Optional[str] = None
    best_time_of_day: Optional[int] = None  # Hour of day (0-23)
    average_session_duration: float = 0.0
    total_sessions: int = 0
    consistency_score: float = 0.0  # 0-100 score
    
    # Streak analysis
    current_streak: int = 0
    longest_streak: int = 0
    streak_history: List[Dict[str, Any]] = Field(default_factory=list)
    
    # Predictions and recommendations
    predicted_next_activity: Optional[datetime] = None
    recommended_duration: Optional[int] = None
    success_probability: float = 0.0  # Probability of achieving goals
    
    # Time-based data
    date_range_start: datetime = Indexed()
    date_range_end: datetime = Indexed()
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

    class Settings:
        name = "value_insights"
        indexes = [
            # Core insights queries - high priority
            [("user_id", 1), ("value_id", 1)],  # Primary lookup
            [("user_id", 1), ("consistency_score", -1)],  # User value consistency ranking
            [("value_id", 1), ("consistency_score", -1)],  # Value performance across users
            
            # Streak analytics
            [("user_id", 1), ("current_streak", -1)],  # User's current streaks
            [("user_id", 1), ("longest_streak", -1)],  # User's achievement streaks
            [("value_id", 1), ("current_streak", -1)],  # Value streak performance
            [("value_id", 1), ("longest_streak", -1)],  # Value achievement tracking
            
            # Session and usage analytics
            [("user_id", 1), ("total_sessions", -1)],  # User activity levels
            [("user_id", 1), ("average_session_duration", -1)],  # User session patterns
            [("value_id", 1), ("total_sessions", -1)],  # Value popularity
            [("value_id", 1), ("average_session_duration", -1)],  # Value engagement patterns
            
            # Time-based insights
            [("date_range_start", -1)],  # Historical insights
            [("user_id", 1), ("date_range_start", -1)],  # User insights timeline
            [("created_at", -1)],  # Recent insights
            [("updated_at", -1)],  # Recently updated insights
            
            # Pattern analysis
            [("best_day_of_week", 1), ("consistency_score", -1)],  # Day-of-week patterns
            [("best_time_of_day", 1), ("consistency_score", -1)],  # Time-of-day patterns
            [("success_probability", -1), ("user_id", 1)],  # Success prediction ranking
            
            # Compound insights queries
            [("user_id", 1), ("value_id", 1), ("date_range_start", -1)],  # User-value insights timeline
            [("consistency_score", -1), ("current_streak", -1)],  # Performance correlation
        ]


class StreakHistory(Document):
    """Historical streak data for detailed analysis"""
    user_id: str = Indexed()
    value_id: str = Indexed()
    
    # Streak details
    streak_start: datetime = Indexed()
    streak_end: Optional[datetime] = None
    streak_length: int = Field(..., ge=0)
    is_active: bool = Field(default=True)
    
    # Context data
    activities_count: int = Field(..., ge=0)
    total_duration: int = Field(..., ge=0)  # in minutes
    average_daily_duration: float = 0.0
    
    # Break analysis
    break_reason: Optional[str] = None
    break_duration: Optional[int] = None  # days between streaks
    
    created_at: datetime = Field(default_factory=datetime.utcnow)

    class Settings:
        name = "streak_history"
        indexes = [
            # Core streak queries - high priority
            [("user_id", 1), ("value_id", 1), ("streak_start", -1)],  # User-value streak history
            [("user_id", 1), ("is_active", 1)],  # User's active streaks
            [("value_id", 1), ("is_active", 1)],  # Value's active streaks
            [("streak_length", -1)],  # Global streak leaderboard
            
            # Streak analytics
            [("user_id", 1), ("streak_length", -1)],  # User's streak achievements
            [("value_id", 1), ("streak_length", -1)],  # Value streak performance
            [("user_id", 1), ("value_id", 1), ("streak_length", -1)],  # User-value streak ranking
            
            # Time-based streak analysis
            [("streak_start", -1), ("is_active", 1)],  # Recent streak starts
            [("streak_end", -1)],  # Recent streak ends
            [("user_id", 1), ("streak_start", -1), ("is_active", 1)],  # User's recent streak activity
            
            # Break analysis
            [("break_duration", -1), ("user_id", 1)],  # Break duration analysis
            [("break_reason", 1), ("break_duration", -1)],  # Break pattern analysis
            [("user_id", 1), ("break_reason", 1)],  # User break patterns
            
            # Performance analytics
            [("activities_count", -1), ("streak_length", -1)],  # Activity vs streak correlation
            [("total_duration", -1), ("streak_length", -1)],  # Duration vs streak correlation
            [("average_daily_duration", -1), ("user_id", 1)],  # User performance patterns
            
            # Compound analytics queries
            [("user_id", 1), ("value_id", 1), ("is_active", 1), ("streak_length", -1)],  # Active streak performance
            [("is_active", 1), ("streak_length", -1), ("streak_start", -1)],  # Global active streak trends
        ]


class ActivityPattern(Document):
    """User activity patterns for AI insights"""
    user_id: str = Indexed()
    
    # Weekly patterns (0-6, Sunday=0)
    day_of_week_distribution: Dict[str, float] = Field(default_factory=dict)
    
    # Hourly patterns (0-23)
    hour_of_day_distribution: Dict[str, float] = Field(default_factory=dict)
    
    # Duration patterns
    preferred_duration_ranges: List[Dict[str, Any]] = Field(default_factory=list)
    
    # Value correlations
    value_correlations: Dict[str, float] = Field(default_factory=dict)
    
    # Productivity scores by time
    productivity_by_day: Dict[str, float] = Field(default_factory=dict)
    productivity_by_hour: Dict[str, float] = Field(default_factory=dict)
    
    # Data freshness
    last_analyzed: datetime = Field(default_factory=datetime.utcnow)
    data_range_days: int = 30  # How many days of data this analysis covers
    
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

    class Settings:
        name = "activity_patterns"
        indexes = [
            # Core pattern queries - high priority
            [("user_id", 1)],  # Primary user lookup
            [("last_analyzed", -1)],  # Recent analysis tracking
            [("user_id", 1), ("last_analyzed", -1)],  # User's analysis timeline
            
            # Data freshness and validity
            [("data_range_days", -1), ("last_analyzed", -1)],  # Analysis scope tracking
            [("user_id", 1), ("data_range_days", -1)],  # User's analysis depth
            
            # Pattern analysis efficiency
            [("last_analyzed", -1), ("data_range_days", -1)],  # Analysis prioritization
            [("user_id", 1), ("updated_at", -1)],  # Recent pattern updates
            
            # Time-based pattern queries
            [("created_at", -1)],  # Pattern creation timeline
            [("updated_at", -1)],  # Recently updated patterns
        ]