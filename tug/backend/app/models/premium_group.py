# app/models/premium_group.py
from beanie import Document
from pydantic import Field
from typing import Optional, List, Dict, Any
from datetime import datetime
from enum import Enum

class GroupType(str, Enum):
    PRIVATE_PREMIUM = "private_premium"
    PREMIUM_CHALLENGE = "premium_challenge"
    PREMIUM_COACHING = "premium_coaching"
    ACCOUNTABILITY_CIRCLE = "accountability_circle"

class GroupPrivacyLevel(str, Enum):
    PRIVATE = "private"  # Invite only
    DISCOVERABLE = "discoverable"  # Can be found but requires approval
    PUBLIC = "public"  # Anyone with premium can join

class GroupRole(str, Enum):
    OWNER = "owner"
    ADMIN = "admin"
    MODERATOR = "moderator"
    MEMBER = "member"

class GroupStatus(str, Enum):
    ACTIVE = "active"
    ARCHIVED = "archived"
    SUSPENDED = "suspended"

class MembershipStatus(str, Enum):
    ACTIVE = "active"
    PENDING = "pending"
    INVITED = "invited"
    REMOVED = "removed"

class PremiumGroup(Document):
    """Premium group model for exclusive group features"""
    
    # Basic group information
    name: str = Field(..., min_length=1, max_length=100, description="Group name")
    description: str = Field(..., max_length=500, description="Group description")
    group_type: GroupType = Field(..., description="Type of premium group")
    privacy_level: GroupPrivacyLevel = Field(default=GroupPrivacyLevel.PRIVATE)
    status: GroupStatus = Field(default=GroupStatus.ACTIVE)
    
    # Group branding and customization (premium features)
    avatar_url: Optional[str] = Field(None, description="Group avatar/logo URL")
    banner_url: Optional[str] = Field(None, description="Group banner image URL")
    theme_color: str = Field(default="#6366f1", description="Group theme color")
    custom_tags: List[str] = Field(default_factory=list, description="Custom group tags")
    
    # Group rules and settings
    rules: List[str] = Field(default_factory=list, description="Group rules and guidelines")
    activity_requirements: Dict[str, Any] = Field(
        default_factory=lambda: {
            "min_activities_per_week": 0,
            "required_check_ins": 0,
            "engagement_requirements": {}
        },
        description="Activity requirements for members"
    )
    
    # Member management
    max_members: int = Field(default=50, description="Maximum number of members allowed")
    approval_required: bool = Field(default=True, description="Whether new members need approval")
    
    # Group analytics settings
    analytics_enabled: bool = Field(default=True, description="Enable detailed analytics")
    leaderboard_enabled: bool = Field(default=True, description="Enable group leaderboard")
    public_stats: bool = Field(default=False, description="Make group stats publicly visible")
    
    # Premium features configuration
    coaching_enabled: bool = Field(default=True, description="Enable AI group coaching")
    challenge_creation_enabled: bool = Field(default=True, description="Allow challenge creation")
    advanced_moderation: bool = Field(default=True, description="Enable advanced moderation tools")
    custom_rewards: bool = Field(default=True, description="Enable custom group rewards")
    
    # Timestamps and metadata
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    last_activity_at: datetime = Field(default_factory=datetime.utcnow)
    
    # Analytics and performance data
    total_members: int = Field(default=0)
    active_members_30d: int = Field(default=0)
    total_activities: int = Field(default=0)
    total_posts: int = Field(default=0)
    average_engagement_score: float = Field(default=0.0)
    
    class Settings:
        collection = "premium_groups"
        indexes = [
            # Primary queries
            [("status", 1), ("created_at", -1)],  # Active groups
            [("group_type", 1), ("status", 1)],  # Groups by type
            [("privacy_level", 1), ("status", 1)],  # Discoverable groups
            
            # Search and discovery
            [("name", "text"), ("description", "text")],  # Text search
            [("custom_tags", 1)],  # Tag-based search
            [("group_type", 1), ("privacy_level", 1), ("status", 1)],  # Filtered discovery
            
            # Analytics and performance
            [("total_members", -1)],  # Popular groups
            [("average_engagement_score", -1)],  # High engagement groups
            [("last_activity_at", -1)],  # Recently active groups
            
            # Time-based queries
            [("created_at", -1)],  # Newest groups
            [("updated_at", -1)],  # Recently updated
            
            # Basic field indexes
            "group_type",
            "status",
            "privacy_level",
            "created_at"
        ]
    
    def update_timestamp(self):
        """Update the updated_at timestamp"""
        self.updated_at = datetime.utcnow()
    
    def update_activity_timestamp(self):
        """Update the last_activity_at timestamp"""
        self.last_activity_at = datetime.utcnow()
        self.update_timestamp()


class GroupMembership(Document):
    """Group membership model managing user roles and status in groups"""
    
    group_id: str = Field(..., description="ID of the premium group")
    user_id: str = Field(..., description="ID of the user")
    role: GroupRole = Field(default=GroupRole.MEMBER, description="User's role in the group")
    status: MembershipStatus = Field(default=MembershipStatus.PENDING, description="Membership status")
    
    # Invitation and approval tracking
    invited_by: Optional[str] = Field(None, description="ID of user who sent invitation")
    approved_by: Optional[str] = Field(None, description="ID of user who approved membership")
    invitation_message: Optional[str] = Field(None, description="Custom invitation message")
    
    # Member activity and engagement
    join_date: Optional[datetime] = Field(None, description="Date user actually joined")
    last_active_at: datetime = Field(default_factory=datetime.utcnow)
    total_posts: int = Field(default=0)
    total_activities_shared: int = Field(default=0)
    engagement_score: float = Field(default=0.0)
    
    # Member statistics and achievements within group
    group_achievements: List[str] = Field(default_factory=list, description="Group-specific achievements")
    participation_streak: int = Field(default=0, description="Days of consecutive participation")
    leadership_actions: int = Field(default=0, description="Number of leadership/moderation actions taken")
    
    # Custom member data and preferences
    member_notes: Optional[str] = Field(None, description="Private notes about member (admin only)")
    notification_preferences: Dict[str, bool] = Field(
        default_factory=lambda: {
            "group_posts": True,
            "challenges": True,
            "coaching_messages": True,
            "member_activities": True,
            "announcements": True
        }
    )
    
    # Timestamps
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Settings:
        collection = "group_memberships"
        indexes = [
            # Primary relationship queries
            [("group_id", 1), ("status", 1)],  # Active group members
            [("user_id", 1), ("status", 1)],  # User's group memberships
            [("group_id", 1), ("user_id", 1)],  # Unique membership lookup
            
            # Role and permission queries
            [("group_id", 1), ("role", 1), ("status", 1)],  # Group admins/moderators
            [("group_id", 1), ("role", 1)],  # Members by role
            
            # Activity and engagement
            [("group_id", 1), ("engagement_score", -1)],  # Most engaged members
            [("group_id", 1), ("last_active_at", -1)],  # Recently active members
            [("group_id", 1), ("join_date", -1)],  # Newest members
            
            # Invitation and approval management
            [("group_id", 1), ("status", 1), ("created_at", -1)],  # Pending approvals
            [("invited_by", 1)],  # Track invitation patterns
            [("approved_by", 1)],  # Track approval patterns
            
            # Analytics queries
            [("user_id", 1), ("engagement_score", -1)],  # User's most engaging groups
            [("participation_streak", -1)],  # High-participation members
            
            # Basic field indexes
            "group_id",
            "user_id",
            "role",
            "status",
            "created_at"
        ]
    
    def update_timestamp(self):
        """Update the updated_at timestamp"""
        self.updated_at = datetime.utcnow()
    
    def update_activity(self):
        """Update last activity timestamp"""
        self.last_active_at = datetime.utcnow()
        self.update_timestamp()
    
    def promote_role(self) -> bool:
        """Promote user to next role level"""
        role_hierarchy = [GroupRole.MEMBER, GroupRole.MODERATOR, GroupRole.ADMIN, GroupRole.OWNER]
        current_index = role_hierarchy.index(self.role)
        if current_index < len(role_hierarchy) - 1:
            self.role = role_hierarchy[current_index + 1]
            self.leadership_actions += 1
            self.update_timestamp()
            return True
        return False
    
    def demote_role(self) -> bool:
        """Demote user to previous role level"""
        role_hierarchy = [GroupRole.MEMBER, GroupRole.MODERATOR, GroupRole.ADMIN, GroupRole.OWNER]
        current_index = role_hierarchy.index(self.role)
        if current_index > 0:
            self.role = role_hierarchy[current_index - 1]
            self.update_timestamp()
            return True
        return False


class GroupChallenge(Document):
    """Premium group challenges with enhanced features"""
    
    group_id: str = Field(..., description="ID of the group this challenge belongs to")
    creator_id: str = Field(..., description="ID of user who created the challenge")
    
    # Challenge details
    title: str = Field(..., min_length=1, max_length=100, description="Challenge title")
    description: str = Field(..., max_length=1000, description="Detailed challenge description")
    challenge_type: str = Field(..., description="Type of challenge (habit, activity, vice, custom)")
    
    # Challenge parameters and goals
    target_metric: str = Field(..., description="What metric to track (days, activities, hours, etc.)")
    target_value: float = Field(..., description="Target value to achieve")
    duration_days: int = Field(..., description="Challenge duration in days")
    
    # Premium challenge features
    reward_type: Optional[str] = Field(None, description="Type of reward (badge, points, custom)")
    reward_data: Dict[str, Any] = Field(default_factory=dict, description="Reward configuration")
    difficulty_level: int = Field(default=1, description="Challenge difficulty (1-5)")
    category_tags: List[str] = Field(default_factory=list, description="Challenge categories")
    
    # Participation and tracking
    max_participants: Optional[int] = Field(None, description="Maximum number of participants")
    auto_join_eligible: bool = Field(default=True, description="Auto-join eligible group members")
    requires_approval: bool = Field(default=False, description="Require approval to join")
    
    # Challenge status and timing
    status: str = Field(default="upcoming", description="Challenge status")
    start_date: datetime = Field(..., description="Challenge start date")
    end_date: datetime = Field(..., description="Challenge end date")
    registration_deadline: Optional[datetime] = Field(None, description="Last day to join")
    
    # Analytics and engagement
    total_participants: int = Field(default=0)
    completed_participants: int = Field(default=0)
    average_completion_rate: float = Field(default=0.0)
    
    # Timestamps
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Settings:
        collection = "group_challenges"
        indexes = [
            # Group and creator queries
            [("group_id", 1), ("status", 1)],  # Group challenges by status
            [("group_id", 1), ("start_date", -1)],  # Recent group challenges
            [("creator_id", 1), ("created_at", -1)],  # User's created challenges
            
            # Challenge discovery and filtering
            [("status", 1), ("start_date", 1)],  # Upcoming challenges
            [("challenge_type", 1), ("status", 1)],  # Challenges by type
            [("difficulty_level", 1), ("status", 1)],  # Challenges by difficulty
            [("category_tags", 1)],  # Tag-based discovery
            
            # Analytics and performance
            [("group_id", 1), ("total_participants", -1)],  # Popular group challenges
            [("average_completion_rate", -1)],  # High-success challenges
            
            # Time-based queries
            [("start_date", 1), ("end_date", 1)],  # Active challenges
            [("created_at", -1)],  # Recently created
            
            # Basic indexes
            "group_id",
            "creator_id", 
            "status",
            "start_date"
        ]
    
    def update_timestamp(self):
        """Update the updated_at timestamp"""
        self.updated_at = datetime.utcnow()


class GroupPost(Document):
    """Enhanced group posts with premium features"""
    
    group_id: str = Field(..., description="ID of the group this post belongs to")
    user_id: str = Field(..., description="ID of user who created the post")
    content: str = Field(..., min_length=1, max_length=1000, description="Post content")
    
    # Post type and categorization
    post_type: str = Field(default="general", description="Type of post")
    category: Optional[str] = Field(None, description="Post category for organization")
    tags: List[str] = Field(default_factory=list, description="Post tags")
    
    # Premium post features
    is_announcement: bool = Field(default=False, description="Whether this is an official announcement")
    is_pinned: bool = Field(default=False, description="Whether post is pinned to top")
    priority_level: int = Field(default=0, description="Post priority (0-5)")
    
    # Media and attachments
    media_urls: List[str] = Field(default_factory=list, description="Media attachment URLs")
    attachment_data: Dict[str, Any] = Field(default_factory=dict, description="Structured attachment data")
    
    # Related content
    related_activity_id: Optional[str] = Field(None, description="Related activity ID")
    related_challenge_id: Optional[str] = Field(None, description="Related challenge ID")
    related_achievement_id: Optional[str] = Field(None, description="Related achievement ID")
    
    # Engagement metrics
    likes_count: int = Field(default=0)
    comments_count: int = Field(default=0)
    shares_count: int = Field(default=0)
    engagement_score: float = Field(default=0.0)
    
    # Moderation and management
    is_moderated: bool = Field(default=False, description="Whether post has been moderated")
    moderated_by: Optional[str] = Field(None, description="ID of user who moderated")
    moderation_notes: Optional[str] = Field(None, description="Moderation notes")
    reported_count: int = Field(default=0, description="Number of reports")
    
    # Timestamps
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Settings:
        collection = "group_posts"
        indexes = [
            # Group feed queries
            [("group_id", 1), ("created_at", -1)],  # Group timeline
            [("group_id", 1), ("is_pinned", -1), ("created_at", -1)],  # Pinned posts first
            [("group_id", 1), ("post_type", 1), ("created_at", -1)],  # Posts by type
            
            # User activity
            [("user_id", 1), ("created_at", -1)],  # User's posts
            [("user_id", 1), ("group_id", 1)],  # User's posts in group
            
            # Content discovery
            [("group_id", 1), ("category", 1)],  # Posts by category
            [("group_id", 1), ("tags", 1)],  # Posts by tags
            [("is_announcement", 1), ("group_id", 1)],  # Group announcements
            
            # Engagement and moderation
            [("group_id", 1), ("engagement_score", -1)],  # Popular posts
            [("group_id", 1), ("likes_count", -1)],  # Most liked posts
            [("reported_count", -1), ("is_moderated", 1)],  # Moderation queue
            
            # Related content
            [("related_challenge_id", 1)],  # Challenge posts
            [("related_activity_id", 1)],  # Activity posts
            
            # Basic indexes
            "group_id",
            "user_id",
            "post_type",
            "created_at"
        ]
    
    def update_timestamp(self):
        """Update the updated_at timestamp"""
        self.updated_at = datetime.utcnow()
    
    def increment_engagement(self, metric: str):
        """Increment engagement metric"""
        if metric == "likes":
            self.likes_count += 1
        elif metric == "comments":
            self.comments_count += 1
        elif metric == "shares":
            self.shares_count += 1
        
        # Recalculate engagement score
        self.engagement_score = (self.likes_count * 1.0 + 
                               self.comments_count * 2.0 + 
                               self.shares_count * 3.0)
        self.update_timestamp()