# app/schemas/premium_group.py
from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime, date
from ..models.premium_group import GroupType, GroupPrivacyLevel, GroupRole, GroupStatus, MembershipStatus

# Premium Group Schemas
class PremiumGroupCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=100, description="Group name")
    description: str = Field(..., max_length=500, description="Group description")
    group_type: GroupType = Field(..., description="Type of premium group")
    privacy_level: GroupPrivacyLevel = Field(default=GroupPrivacyLevel.PRIVATE)
    theme_color: str = Field(default="#6366f1", description="Group theme color")
    custom_tags: List[str] = Field(default_factory=list, description="Custom group tags")
    rules: List[str] = Field(default_factory=list, description="Group rules and guidelines")
    max_members: int = Field(default=50, ge=5, le=500, description="Maximum number of members allowed")
    approval_required: bool = Field(default=True, description="Whether new members need approval")
    
    # Premium feature settings
    analytics_enabled: bool = Field(default=True, description="Enable detailed analytics")
    leaderboard_enabled: bool = Field(default=True, description="Enable group leaderboard")
    coaching_enabled: bool = Field(default=True, description="Enable AI group coaching")
    challenge_creation_enabled: bool = Field(default=True, description="Allow challenge creation")

class PremiumGroupUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=100)
    description: Optional[str] = Field(None, max_length=500)
    privacy_level: Optional[GroupPrivacyLevel] = None
    theme_color: Optional[str] = None
    custom_tags: Optional[List[str]] = None
    rules: Optional[List[str]] = None
    avatar_url: Optional[str] = None
    banner_url: Optional[str] = None
    max_members: Optional[int] = Field(None, ge=5, le=500)
    approval_required: Optional[bool] = None
    analytics_enabled: Optional[bool] = None
    leaderboard_enabled: Optional[bool] = None
    coaching_enabled: Optional[bool] = None
    challenge_creation_enabled: Optional[bool] = None

class PremiumGroupData(BaseModel):
    id: str
    name: str
    description: str
    group_type: GroupType
    privacy_level: GroupPrivacyLevel
    status: GroupStatus
    avatar_url: Optional[str] = None
    banner_url: Optional[str] = None
    theme_color: str
    custom_tags: List[str]
    rules: List[str]
    max_members: int
    total_members: int
    active_members_30d: int
    approval_required: bool
    analytics_enabled: bool
    leaderboard_enabled: bool
    coaching_enabled: bool
    challenge_creation_enabled: bool
    created_at: datetime
    updated_at: datetime
    last_activity_at: datetime
    average_engagement_score: float
    
    # User's relationship to this group
    user_role: Optional[GroupRole] = None
    user_membership_status: Optional[MembershipStatus] = None

# Group Membership Schemas
class GroupInvitationCreate(BaseModel):
    user_id: str = Field(..., description="ID of user to invite")
    role: GroupRole = Field(default=GroupRole.MEMBER, description="Role to assign to invited user")
    invitation_message: Optional[str] = Field(None, max_length=300, description="Custom invitation message")

class GroupMembershipResponse(BaseModel):
    membership_id: str
    accept: bool = Field(..., description="True to accept, False to reject")

class GroupMemberData(BaseModel):
    id: str
    user_id: str
    username: str
    display_name: Optional[str] = None
    role: GroupRole
    status: MembershipStatus
    join_date: Optional[datetime] = None
    last_active_at: datetime
    total_posts: int
    engagement_score: float
    participation_streak: int
    group_achievements: List[str]

class GroupRoleUpdate(BaseModel):
    user_id: str
    new_role: GroupRole

# Group Challenge Schemas
class GroupChallengeCreate(BaseModel):
    title: str = Field(..., min_length=1, max_length=100, description="Challenge title")
    description: str = Field(..., max_length=1000, description="Detailed challenge description")
    challenge_type: str = Field(..., description="Type of challenge")
    target_metric: str = Field(..., description="What metric to track")
    target_value: float = Field(..., ge=0, description="Target value to achieve")
    duration_days: int = Field(..., ge=1, le=365, description="Challenge duration in days")
    start_date: datetime = Field(..., description="Challenge start date")
    max_participants: Optional[int] = Field(None, ge=1, description="Maximum participants")
    difficulty_level: int = Field(default=1, ge=1, le=5, description="Challenge difficulty")
    category_tags: List[str] = Field(default_factory=list, description="Challenge categories")
    reward_type: Optional[str] = None
    reward_data: Dict[str, Any] = Field(default_factory=dict)

class GroupChallengeData(BaseModel):
    id: str
    group_id: str
    creator_id: str
    creator_username: str
    title: str
    description: str
    challenge_type: str
    target_metric: str
    target_value: float
    duration_days: int
    difficulty_level: int
    category_tags: List[str]
    status: str
    start_date: datetime
    end_date: datetime
    total_participants: int
    completed_participants: int
    average_completion_rate: float
    created_at: datetime
    
    # User's participation status
    user_participating: bool = False
    user_progress: Optional[Dict[str, Any]] = None

# Group Post Schemas
class GroupPostCreate(BaseModel):
    content: str = Field(..., min_length=1, max_length=1000, description="Post content")
    post_type: str = Field(default="general", description="Type of post")
    category: Optional[str] = None
    tags: List[str] = Field(default_factory=list, description="Post tags")
    media_urls: List[str] = Field(default_factory=list, description="Media attachment URLs")
    related_activity_id: Optional[str] = None
    related_challenge_id: Optional[str] = None
    related_achievement_id: Optional[str] = None

class GroupPostData(BaseModel):
    id: str
    group_id: str
    user_id: str
    username: str
    user_display_name: Optional[str] = None
    content: str
    post_type: str
    category: Optional[str] = None
    tags: List[str]
    is_announcement: bool
    is_pinned: bool
    priority_level: int
    media_urls: List[str]
    likes_count: int
    comments_count: int
    shares_count: int
    engagement_score: float
    created_at: datetime
    updated_at: datetime
    
    # Related content info
    related_activity_name: Optional[str] = None
    related_challenge_title: Optional[str] = None

# Group Analytics Schemas
class GroupAnalyticsData(BaseModel):
    period: str
    period_start: date
    period_end: date
    total_members: int
    active_members: int
    new_members: int
    departed_members: int
    member_retention_rate: float
    total_posts: int
    total_comments: int
    total_activities_shared: int
    posts_per_active_member: float
    comments_per_post: float
    member_interaction_rate: float
    growth_rate: float
    engagement_trend: float
    satisfaction_score: float
    top_contributors: List[Dict[str, Any]]
    popular_topics: List[Dict[str, Any]]
    peak_activity_hours: List[int]

class MemberAnalyticsData(BaseModel):
    user_id: str
    username: str
    period: str
    period_start: date
    period_end: date
    posts_created: int
    comments_made: int
    activities_shared: int
    challenges_participated: int
    challenges_completed: int
    engagement_score: float
    influence_score: float
    churn_risk_score: float
    growth_potential: float
    leadership_readiness: float
    group_percentile_rank: Dict[str, float]

class GroupInsightData(BaseModel):
    id: str
    insight_type: str
    category: str
    priority: int
    title: str
    description: str
    recommended_actions: List[Dict[str, Any]]
    potential_impact: str
    difficulty_level: int
    confidence_score: float
    status: str
    generated_at: datetime
    expires_at: Optional[datetime] = None

# Group Dashboard Schemas
class GroupDashboardData(BaseModel):
    group: PremiumGroupData
    recent_analytics: GroupAnalyticsData
    member_count: int
    pending_invitations: int
    active_challenges: int
    recent_posts: List[GroupPostData]
    top_members: List[GroupMemberData]
    recent_insights: List[GroupInsightData]
    engagement_summary: Dict[str, Any]

# Group Discovery and Search
class GroupSearchFilters(BaseModel):
    group_type: Optional[GroupType] = None
    privacy_level: Optional[GroupPrivacyLevel] = None
    tags: List[str] = Field(default_factory=list)
    min_members: Optional[int] = None
    max_members: Optional[int] = None
    has_challenges: Optional[bool] = None
    activity_level: Optional[str] = None  # "high", "medium", "low"

class GroupSearchResult(BaseModel):
    id: str
    name: str
    description: str
    group_type: GroupType
    privacy_level: GroupPrivacyLevel
    theme_color: str
    avatar_url: Optional[str] = None
    total_members: int
    active_members_30d: int
    custom_tags: List[str]
    average_engagement_score: float
    created_at: datetime
    last_activity_at: datetime
    
    # Search relevance and user relationship
    relevance_score: float = 0.0
    user_can_join: bool = True
    join_requirements: List[str] = Field(default_factory=list)

# Group Statistics and Leaderboards
class GroupLeaderboardEntry(BaseModel):
    user_id: str
    username: str
    display_name: Optional[str] = None
    rank: int
    score: float
    metric_name: str
    achievement_badges: List[str] = Field(default_factory=list)
    trend: str  # "up", "down", "stable"

class GroupStatistics(BaseModel):
    total_premium_groups: int
    user_groups: int
    user_owned_groups: int
    user_admin_groups: int
    average_group_size: float
    most_active_group: Optional[PremiumGroupData] = None
    engagement_ranking: Optional[int] = None
    total_group_achievements: int

# Notification Schemas for Groups
class GroupNotificationPreferences(BaseModel):
    group_posts: bool = True
    challenges: bool = True
    coaching_messages: bool = True
    member_activities: bool = True
    announcements: bool = True
    role_changes: bool = True
    new_members: bool = False
    group_insights: bool = True

# Group Export and Reporting
class GroupDataExport(BaseModel):
    group_id: str
    export_type: str  # "analytics", "members", "posts", "challenges", "full"
    date_range: Dict[str, date]
    include_personal_data: bool = False
    format: str = "json"  # "json", "csv", "xlsx"