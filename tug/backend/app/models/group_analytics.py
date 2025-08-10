# app/models/group_analytics.py
from beanie import Document
from pydantic import Field
from typing import Dict, List, Any, Optional
from datetime import datetime, date
from enum import Enum

class AnalyticsPeriod(str, Enum):
    DAILY = "daily"
    WEEKLY = "weekly"
    MONTHLY = "monthly"
    QUARTERLY = "quarterly"

class GroupAnalytics(Document):
    """Advanced analytics and insights for premium groups"""
    
    group_id: str = Field(..., description="ID of the group these analytics belong to")
    period: AnalyticsPeriod = Field(..., description="Analytics time period")
    period_start: date = Field(..., description="Start date of analytics period")
    period_end: date = Field(..., description="End date of analytics period")
    
    # Member engagement metrics
    total_members: int = Field(default=0, description="Total members at end of period")
    active_members: int = Field(default=0, description="Members who were active in period")
    new_members: int = Field(default=0, description="New members joined in period")
    departed_members: int = Field(default=0, description="Members who left in period")
    member_retention_rate: float = Field(default=0.0, description="Member retention percentage")
    
    # Activity and participation metrics
    total_posts: int = Field(default=0, description="Total posts in period")
    total_comments: int = Field(default=0, description="Total comments in period")
    total_activities_shared: int = Field(default=0, description="Activities shared by members")
    total_challenges_completed: int = Field(default=0, description="Challenges completed")
    
    # Engagement quality metrics
    average_session_duration: float = Field(default=0.0, description="Average time spent in group")
    posts_per_active_member: float = Field(default=0.0, description="Average posts per active member")
    comments_per_post: float = Field(default=0.0, description="Average comments per post")
    member_interaction_rate: float = Field(default=0.0, description="Percentage of members who interacted")
    
    # Growth and performance indicators
    growth_rate: float = Field(default=0.0, description="Member growth rate percentage")
    engagement_trend: float = Field(default=0.0, description="Engagement trend (positive/negative)")
    activity_trend: float = Field(default=0.0, description="Activity trend over time")
    satisfaction_score: float = Field(default=0.0, description="Derived member satisfaction score")
    
    # Top performers and insights
    top_contributors: List[Dict[str, Any]] = Field(
        default_factory=list,
        description="Top contributing members with stats"
    )
    popular_topics: List[Dict[str, Any]] = Field(
        default_factory=list,
        description="Most popular discussion topics/tags"
    )
    peak_activity_hours: List[int] = Field(
        default_factory=list,
        description="Hours when group is most active"
    )
    most_engaging_content_types: List[Dict[str, Any]] = Field(
        default_factory=list,
        description="Content types that generate most engagement"
    )
    
    # Comparative analytics
    group_ranking: Optional[int] = Field(None, description="Ranking among similar groups")
    percentile_performance: Dict[str, float] = Field(
        default_factory=dict,
        description="Performance percentiles vs other groups"
    )
    benchmark_comparisons: Dict[str, Any] = Field(
        default_factory=dict,
        description="Comparisons to group type benchmarks"
    )
    
    # Predictive insights (ML-powered)
    predicted_growth: Dict[str, float] = Field(
        default_factory=dict,
        description="Predicted growth metrics for next periods"
    )
    churn_risk_members: List[str] = Field(
        default_factory=list,
        description="Members at risk of leaving (user IDs)"
    )
    engagement_opportunities: List[Dict[str, Any]] = Field(
        default_factory=list,
        description="AI-identified opportunities to boost engagement"
    )
    recommended_actions: List[Dict[str, Any]] = Field(
        default_factory=list,
        description="AI-recommended actions for group improvement"
    )
    
    # Timestamps and metadata
    calculated_at: datetime = Field(default_factory=datetime.utcnow)
    data_quality_score: float = Field(default=1.0, description="Quality score of underlying data")
    confidence_intervals: Dict[str, Dict[str, float]] = Field(
        default_factory=dict,
        description="Statistical confidence intervals for key metrics"
    )
    
    class Settings:
        collection = "group_analytics"
        indexes = [
            # Primary queries for analytics retrieval
            [("group_id", 1), ("period", 1), ("period_start", -1)],  # Group analytics by period
            [("group_id", 1), ("period_start", -1)],  # Latest analytics for group
            
            # Performance comparisons
            [("period", 1), ("period_start", 1), ("engagement_trend", -1)],  # Top performing groups
            [("period", 1), ("period_start", 1), ("growth_rate", -1)],  # Fastest growing groups
            [("period", 1), ("period_start", 1), ("satisfaction_score", -1)],  # Highest satisfaction
            
            # Time series analysis
            [("group_id", 1), ("period", 1), ("calculated_at", -1)],  # Historical trends
            [("period_start", 1), ("period_end", 1)],  # Period-based queries
            
            # Ranking and benchmarks
            [("group_ranking", 1), ("period", 1)],  # Rankings over time
            [("calculated_at", -1)],  # Recently calculated analytics
            
            # Basic field indexes
            "group_id",
            "period",
            "period_start"
        ]


class MemberAnalytics(Document):
    """Individual member analytics within groups"""
    
    group_id: str = Field(..., description="ID of the group")
    user_id: str = Field(..., description="ID of the member")
    period: AnalyticsPeriod = Field(..., description="Analytics time period")
    period_start: date = Field(..., description="Start date of analytics period")
    period_end: date = Field(..., description="End date of analytics period")
    
    # Individual engagement metrics
    posts_created: int = Field(default=0, description="Posts created by member")
    comments_made: int = Field(default=0, description="Comments made by member")
    activities_shared: int = Field(default=0, description="Activities shared")
    challenges_participated: int = Field(default=0, description="Challenges joined")
    challenges_completed: int = Field(default=0, description="Challenges completed")
    
    # Participation quality
    session_count: int = Field(default=0, description="Number of app sessions")
    total_time_spent: float = Field(default=0.0, description="Total time spent in group (minutes)")
    average_session_duration: float = Field(default=0.0, description="Average session length")
    engagement_score: float = Field(default=0.0, description="Calculated engagement score")
    influence_score: float = Field(default=0.0, description="Member influence on group activity")
    
    # Social interaction metrics
    likes_received: int = Field(default=0, description="Likes received on posts/comments")
    likes_given: int = Field(default=0, description="Likes given to others")
    mentions_received: int = Field(default=0, description="Times mentioned by others")
    mentions_given: int = Field(default=0, description="Times mentioned others")
    help_requests_made: int = Field(default=0, description="Help/support requests made")
    help_provided: int = Field(default=0, description="Times helped other members")
    
    # Leadership and contribution
    moderation_actions: int = Field(default=0, description="Moderation actions taken")
    content_quality_score: float = Field(default=0.0, description="Quality of content shared")
    positive_feedback_ratio: float = Field(default=0.0, description="Ratio of positive to negative feedback")
    mentor_activities: int = Field(default=0, description="Mentoring activities performed")
    
    # Behavioral patterns
    most_active_hours: List[int] = Field(
        default_factory=list,
        description="Hours when member is most active"
    )
    preferred_content_types: List[str] = Field(
        default_factory=list,
        description="Types of content member engages with most"
    )
    interaction_patterns: Dict[str, Any] = Field(
        default_factory=dict,
        description="Patterns in member interactions"
    )
    
    # Predictive insights
    churn_risk_score: float = Field(default=0.0, description="Risk of member leaving (0-1)")
    growth_potential: float = Field(default=0.0, description="Potential for increased engagement")
    leadership_readiness: float = Field(default=0.0, description="Readiness for leadership role")
    recommended_actions: List[str] = Field(
        default_factory=list,
        description="Recommended actions for member growth"
    )
    
    # Comparative metrics
    group_percentile_rank: Dict[str, float] = Field(
        default_factory=dict,
        description="Member's percentile rank in various metrics within group"
    )
    improvement_trends: Dict[str, float] = Field(
        default_factory=dict,
        description="Improvement trends for key metrics"
    )
    
    # Timestamps
    calculated_at: datetime = Field(default_factory=datetime.utcnow)
    last_updated: datetime = Field(default_factory=datetime.utcnow)
    
    class Settings:
        collection = "member_analytics"
        indexes = [
            # Primary member analytics queries
            [("group_id", 1), ("user_id", 1), ("period", 1), ("period_start", -1)],  # Member timeline
            [("user_id", 1), ("period", 1), ("period_start", -1)],  # User's group analytics
            
            # Group member performance
            [("group_id", 1), ("period", 1), ("engagement_score", -1)],  # Top engaged members
            [("group_id", 1), ("period", 1), ("influence_score", -1)],  # Most influential members
            [("group_id", 1), ("period", 1), ("churn_risk_score", -1)],  # At-risk members
            
            # Leadership identification
            [("group_id", 1), ("leadership_readiness", -1)],  # Leadership candidates
            [("group_id", 1), ("content_quality_score", -1)],  # High-quality contributors
            [("group_id", 1), ("help_provided", -1)],  # Helpful members
            
            # Time-based analysis
            [("group_id", 1), ("calculated_at", -1)],  # Recent analytics
            [("period_start", 1), ("period_end", 1)],  # Period analysis
            
            # Basic indexes
            "group_id",
            "user_id",
            "period",
            "calculated_at"
        ]


class GroupInsight(Document):
    """AI-generated insights and recommendations for groups"""
    
    group_id: str = Field(..., description="ID of the group")
    insight_type: str = Field(..., description="Type of insight (growth, engagement, retention, etc.)")
    category: str = Field(..., description="Insight category (opportunity, warning, achievement, etc.)")
    priority: int = Field(default=1, description="Priority level (1-5)")
    
    # Insight content
    title: str = Field(..., description="Insight title/headline")
    description: str = Field(..., description="Detailed description of the insight")
    supporting_data: Dict[str, Any] = Field(
        default_factory=dict,
        description="Data points supporting this insight"
    )
    
    # Actionable recommendations
    recommended_actions: List[Dict[str, Any]] = Field(
        default_factory=list,
        description="Specific actions recommended based on insight"
    )
    potential_impact: str = Field(..., description="Expected impact of taking action")
    difficulty_level: int = Field(default=1, description="Implementation difficulty (1-5)")
    
    # Insight metadata
    confidence_score: float = Field(default=0.8, description="AI confidence in this insight")
    data_sources: List[str] = Field(
        default_factory=list,
        description="Data sources used to generate insight"
    )
    applicable_period: Dict[str, date] = Field(
        default_factory=dict,
        description="Time period this insight applies to"
    )
    
    # Status and tracking
    status: str = Field(default="active", description="Insight status")
    acknowledged_by: Optional[str] = Field(None, description="Group leader who acknowledged")
    acknowledged_at: Optional[datetime] = Field(None, description="When insight was acknowledged")
    action_taken: Optional[str] = Field(None, description="Action taken by group leaders")
    outcome_notes: Optional[str] = Field(None, description="Notes on outcome of actions taken")
    
    # Timestamps
    generated_at: datetime = Field(default_factory=datetime.utcnow)
    expires_at: Optional[datetime] = Field(None, description="When this insight becomes irrelevant")
    
    class Settings:
        collection = "group_insights"
        indexes = [
            # Primary insight queries
            [("group_id", 1), ("status", 1), ("priority", -1)],  # Active insights by priority
            [("group_id", 1), ("category", 1), ("generated_at", -1)],  # Insights by category
            [("group_id", 1), ("insight_type", 1)],  # Insights by type
            
            # Management and tracking
            [("group_id", 1), ("status", 1), ("acknowledged_at", -1)],  # Acknowledged insights
            [("status", 1), ("expires_at", 1)],  # Expiring insights
            [("priority", -1), ("generated_at", -1)],  # High priority insights
            
            # Performance analysis
            [("confidence_score", -1), ("status", 1)],  # High-confidence insights
            [("generated_at", -1)],  # Recent insights
            
            # Basic indexes
            "group_id",
            "insight_type",
            "category",
            "status",
            "generated_at"
        ]