# app/models/gamification.py
from beanie import Document
from pydantic import Field
from typing import Optional, List, Dict, Any, Union
from datetime import datetime, timedelta
from enum import Enum

class BadgeRarity(str, Enum):
    COMMON = "common"
    UNCOMMON = "uncommon" 
    RARE = "rare"
    EPIC = "epic"
    LEGENDARY = "legendary"

class BadgeCategory(str, Enum):
    ACHIEVEMENT = "achievement"
    MILESTONE = "milestone"
    STREAK = "streak"
    SOCIAL = "social"
    SEASONAL = "seasonal"
    PREMIUM = "premium"
    SPECIAL = "special"

class UserLevel(str, Enum):
    NOVICE = "novice"          # Level 1-10
    APPRENTICE = "apprentice"  # Level 11-25
    PRACTITIONER = "practitioner"  # Level 26-50
    EXPERT = "expert"          # Level 51-75
    MASTER = "master"          # Level 76-90
    GRANDMASTER = "grandmaster"  # Level 91+

class RewardStatus(str, Enum):
    AVAILABLE = "available"
    CLAIMED = "claimed"
    EXPIRED = "expired"
    LOCKED = "locked"


class Badge(Document):
    """Badge definitions for the gamification system"""
    
    # Badge identification
    badge_id: str = Field(..., description="Unique badge identifier")
    name: str = Field(..., min_length=1, max_length=50, description="Badge name")
    description: str = Field(..., max_length=200, description="Badge description")
    icon: str = Field(..., description="Badge icon/emoji")
    image_url: Optional[str] = Field(None, description="Badge image URL")
    
    # Badge classification
    category: BadgeCategory = Field(..., description="Badge category")
    rarity: BadgeRarity = Field(default=BadgeRarity.COMMON, description="Badge rarity")
    points_value: int = Field(default=100, description="Points awarded for earning badge")
    
    # Unlock conditions
    unlock_conditions: Dict[str, Any] = Field(
        default_factory=dict,
        description="Conditions required to unlock this badge"
    )
    prerequisite_badges: List[str] = Field(default_factory=list, description="Required badges")
    
    # Badge properties
    is_stackable: bool = Field(default=False, description="Can be earned multiple times")
    max_stack: Optional[int] = Field(None, description="Maximum stack count if stackable")
    is_premium_only: bool = Field(default=False, description="Requires premium subscription")
    is_seasonal: bool = Field(default=False, description="Limited-time seasonal badge")
    
    # Seasonal/Event data
    available_from: Optional[datetime] = Field(None, description="When badge becomes available")
    available_until: Optional[datetime] = Field(None, description="When badge expires")
    seasonal_theme: Optional[str] = Field(None, description="Seasonal theme identifier")
    
    # Analytics
    total_earned: int = Field(default=0, description="Total times this badge was earned")
    rarity_percentage: float = Field(default=0.0, description="Percentage of users who have this badge")
    
    # Timestamps
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Settings:
        collection = "badges"
        indexes = [
            [("category", 1), ("rarity", 1)],  # Badges by category and rarity
            [("is_seasonal", 1), ("seasonal_theme", 1)],  # Seasonal badges
            [("is_premium_only", 1)],  # Premium badges
            [("available_from", 1), ("available_until", 1)],  # Time-limited badges
            [("total_earned", -1)],  # Popular badges
            [("rarity_percentage", 1)],  # Rare badges
            "badge_id",
            "category",
            "rarity",
            "created_at"
        ]
    
    def update_timestamp(self):
        """Update the updated_at timestamp"""
        self.updated_at = datetime.utcnow()
    
    def is_available(self, user_premium: bool = False, current_time: datetime = None) -> bool:
        """Check if badge is currently available to earn"""
        if current_time is None:
            current_time = datetime.utcnow()
        
        # Check premium requirement
        if self.is_premium_only and not user_premium:
            return False
        
        # Check time availability
        if self.available_from and current_time < self.available_from:
            return False
        
        if self.available_until and current_time > self.available_until:
            return False
        
        return True


class UserBadge(Document):
    """Individual badge earned by a user"""
    
    user_id: str = Field(..., description="User ID who earned the badge")
    badge_id: str = Field(..., description="Badge ID that was earned")
    
    # Badge instance data
    stack_count: int = Field(default=1, description="Number of times earned if stackable")
    earned_at: datetime = Field(default_factory=datetime.utcnow, description="When badge was earned")
    earned_from: str = Field(..., description="What triggered the badge (challenge_id, achievement_id, etc.)")
    earned_context: Dict[str, Any] = Field(default_factory=dict, description="Additional context")
    
    # Display settings
    is_showcased: bool = Field(default=False, description="Whether user showcases this badge")
    showcase_order: Optional[int] = Field(None, description="Order in showcase")
    
    # Timestamps
    created_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Settings:
        collection = "user_badges"
        indexes = [
            [("user_id", 1), ("badge_id", 1)],  # User's specific badge
            [("user_id", 1), ("earned_at", -1)],  # User's badge history
            [("user_id", 1), ("is_showcased", -1)],  # User's showcased badges
            [("badge_id", 1), ("earned_at", -1)],  # Badge leaderboard
            [("earned_from", 1)],  # Badges from challenges/achievements
            "user_id",
            "badge_id",
            "earned_at"
        ]


class UserProgression(Document):
    """User progression system with levels and XP"""
    
    user_id: str = Field(..., description="User ID", unique=True)
    
    # Experience and levels
    total_xp: int = Field(default=0, description="Total experience points earned")
    current_level: int = Field(default=1, description="Current user level")
    xp_to_next_level: int = Field(default=100, description="XP needed for next level")
    level_tier: UserLevel = Field(default=UserLevel.NOVICE, description="Current level tier")
    
    # Points system
    lifetime_points: int = Field(default=0, description="Total points earned ever")
    current_points: int = Field(default=0, description="Current spendable points")
    points_spent: int = Field(default=0, description="Total points spent on rewards")
    
    # Streak systems
    current_streak: int = Field(default=0, description="Current daily activity streak")
    longest_streak: int = Field(default=0, description="Longest streak ever achieved")
    streak_multiplier: float = Field(default=1.0, description="Current streak bonus multiplier")
    
    # Progression milestones
    challenges_completed: int = Field(default=0, description="Total challenges completed")
    badges_earned: int = Field(default=0, description="Total badges earned")
    achievements_unlocked: int = Field(default=0, description="Total achievements unlocked")
    
    # Social progression
    friends_helped: int = Field(default=0, description="Number of friends encouraged/helped")
    community_contributions: int = Field(default=0, description="Community posts/comments made")
    leaderboard_appearances: int = Field(default=0, description="Times appeared on leaderboards")
    
    # Premium progression
    premium_challenges_completed: int = Field(default=0, description="Premium challenges completed")
    premium_rewards_earned: int = Field(default=0, description="Premium rewards earned")
    group_leadership_actions: int = Field(default=0, description="Group moderation/leadership actions")
    
    # Activity-based progression
    total_activities_logged: int = Field(default=0, description="Total activities logged")
    total_time_tracked: int = Field(default=0, description="Total minutes tracked")
    values_practiced: int = Field(default=0, description="Number of different values practiced")
    
    # Seasonal and time-based
    monthly_xp: Dict[str, int] = Field(default_factory=dict, description="XP earned per month")
    seasonal_progress: Dict[str, Dict[str, Any]] = Field(default_factory=dict, description="Seasonal event progress")
    
    # Personalization and preferences
    favorite_categories: List[str] = Field(default_factory=list, description="User's preferred challenge categories")
    progression_goals: Dict[str, Any] = Field(default_factory=dict, description="User-set progression goals")
    
    # Last activity tracking
    last_xp_gain: datetime = Field(default_factory=datetime.utcnow, description="Last time XP was gained")
    last_level_up: Optional[datetime] = Field(None, description="Last time user leveled up")
    last_streak_update: datetime = Field(default_factory=datetime.utcnow, description="Last streak update")
    
    # Timestamps
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Settings:
        collection = "user_progression"
        indexes = [
            [("current_level", -1), ("total_xp", -1)],  # Level leaderboard
            [("longest_streak", -1)],  # Streak leaderboard
            [("lifetime_points", -1)],  # Points leaderboard
            [("challenges_completed", -1)],  # Challenge completion leaderboard
            [("level_tier", 1), ("current_level", -1)],  # Users by tier and level
            [("last_xp_gain", -1)],  # Recently active users
            [("premium_challenges_completed", -1)],  # Premium leaderboard
            "user_id",
            "current_level",
            "total_xp",
            "updated_at"
        ]
    
    def update_timestamp(self):
        """Update the updated_at timestamp"""
        self.updated_at = datetime.utcnow()
    
    def add_xp(self, xp_amount: int, source: str = "activity"):
        """Add XP and handle level ups"""
        self.total_xp += xp_amount
        self.last_xp_gain = datetime.utcnow()
        
        # Add to monthly tracking
        current_month = datetime.utcnow().strftime("%Y-%m")
        self.monthly_xp[current_month] = self.monthly_xp.get(current_month, 0) + xp_amount
        
        # Check for level up
        while self.total_xp >= self.calculate_xp_for_level(self.current_level + 1):
            self._level_up()
        
        # Update XP to next level
        self.xp_to_next_level = self.calculate_xp_for_level(self.current_level + 1) - self.total_xp
        
        self.update_timestamp()
    
    def add_points(self, points_amount: int, source: str = "challenge"):
        """Add points to user's balance"""
        points_with_multiplier = int(points_amount * self.streak_multiplier)
        self.current_points += points_with_multiplier
        self.lifetime_points += points_with_multiplier
        self.update_timestamp()
    
    def spend_points(self, points_amount: int) -> bool:
        """Spend points if user has enough"""
        if self.current_points >= points_amount:
            self.current_points -= points_amount
            self.points_spent += points_amount
            self.update_timestamp()
            return True
        return False
    
    def update_streak(self, increment: bool = True):
        """Update activity streak"""
        if increment:
            self.current_streak += 1
            self.longest_streak = max(self.longest_streak, self.current_streak)
            
            # Update streak multiplier (max 3x at 30+ streak)
            if self.current_streak >= 30:
                self.streak_multiplier = 3.0
            elif self.current_streak >= 14:
                self.streak_multiplier = 2.0
            elif self.current_streak >= 7:
                self.streak_multiplier = 1.5
            else:
                self.streak_multiplier = 1.0 + (self.current_streak * 0.1)
        else:
            self.current_streak = 0
            self.streak_multiplier = 1.0
        
        self.last_streak_update = datetime.utcnow()
        self.update_timestamp()
    
    def _level_up(self):
        """Handle level up logic"""
        self.current_level += 1
        self.last_level_up = datetime.utcnow()
        
        # Update level tier
        if self.current_level >= 91:
            self.level_tier = UserLevel.GRANDMASTER
        elif self.current_level >= 76:
            self.level_tier = UserLevel.MASTER
        elif self.current_level >= 51:
            self.level_tier = UserLevel.EXPERT
        elif self.current_level >= 26:
            self.level_tier = UserLevel.PRACTITIONER
        elif self.current_level >= 11:
            self.level_tier = UserLevel.APPRENTICE
        else:
            self.level_tier = UserLevel.NOVICE
    
    @staticmethod
    def calculate_xp_for_level(level: int) -> int:
        """Calculate total XP required to reach a specific level"""
        if level <= 1:
            return 0
        
        # Progressive XP scaling: base * level^1.5
        base_xp = 100
        return int(base_xp * (level - 1) ** 1.5)
    
    def get_level_progress_percentage(self) -> float:
        """Get progress percentage to next level"""
        current_level_xp = self.calculate_xp_for_level(self.current_level)
        next_level_xp = self.calculate_xp_for_level(self.current_level + 1)
        
        if next_level_xp == current_level_xp:
            return 100.0
        
        progress = (self.total_xp - current_level_xp) / (next_level_xp - current_level_xp)
        return min(100.0, max(0.0, progress * 100))


class Reward(Document):
    """Rewards available in the system"""
    
    # Reward identification
    reward_id: str = Field(..., description="Unique reward identifier")
    name: str = Field(..., min_length=1, max_length=50, description="Reward name")
    description: str = Field(..., max_length=200, description="Reward description")
    icon: str = Field(..., description="Reward icon/emoji")
    image_url: Optional[str] = Field(None, description="Reward image URL")
    
    # Reward type and value
    reward_type: str = Field(..., description="Type of reward (points, badge, premium_benefit, etc.)")
    points_cost: int = Field(default=0, description="Cost in points to claim")
    level_requirement: int = Field(default=1, description="Minimum level to access")
    premium_required: bool = Field(default=False, description="Requires premium subscription")
    
    # Reward data
    reward_data: Dict[str, Any] = Field(default_factory=dict, description="Reward-specific data")
    
    # Availability
    is_active: bool = Field(default=True, description="Whether reward is currently available")
    stock_limit: Optional[int] = Field(None, description="Maximum number of times claimable")
    stock_remaining: Optional[int] = Field(None, description="Current stock remaining")
    
    # Time limits
    available_from: Optional[datetime] = Field(None, description="When reward becomes available")
    available_until: Optional[datetime] = Field(None, description="When reward expires")
    
    # Analytics
    times_claimed: int = Field(default=0, description="Total times this reward was claimed")
    
    # Timestamps
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Settings:
        collection = "rewards"
        indexes = [
            [("reward_type", 1), ("is_active", 1)],  # Rewards by type
            [("points_cost", 1), ("level_requirement", 1)],  # Affordable rewards
            [("premium_required", 1)],  # Premium rewards
            [("available_from", 1), ("available_until", 1)],  # Time-limited rewards
            [("times_claimed", -1)],  # Popular rewards
            "reward_id",
            "reward_type",
            "is_active"
        ]
    
    def update_timestamp(self):
        """Update the updated_at timestamp"""
        self.updated_at = datetime.utcnow()
    
    def is_available(self, user_level: int, user_premium: bool, current_time: datetime = None) -> bool:
        """Check if reward is available to user"""
        if current_time is None:
            current_time = datetime.utcnow()
        
        if not self.is_active:
            return False
        
        if user_level < self.level_requirement:
            return False
        
        if self.premium_required and not user_premium:
            return False
        
        if self.available_from and current_time < self.available_from:
            return False
        
        if self.available_until and current_time > self.available_until:
            return False
        
        if self.stock_remaining is not None and self.stock_remaining <= 0:
            return False
        
        return True
    
    def claim_reward(self) -> bool:
        """Attempt to claim reward (handles stock)"""
        if self.stock_remaining is None:
            # Unlimited stock
            self.times_claimed += 1
            self.update_timestamp()
            return True
        elif self.stock_remaining > 0:
            # Limited stock available
            self.stock_remaining -= 1
            self.times_claimed += 1
            self.update_timestamp()
            return True
        else:
            # Out of stock
            return False


class UserReward(Document):
    """Rewards claimed by users"""
    
    user_id: str = Field(..., description="User ID who claimed the reward")
    reward_id: str = Field(..., description="Reward ID that was claimed")
    
    # Claim details
    status: RewardStatus = Field(default=RewardStatus.CLAIMED, description="Reward status")
    claimed_at: datetime = Field(default_factory=datetime.utcnow, description="When reward was claimed")
    expires_at: Optional[datetime] = Field(None, description="When reward expires")
    
    # Usage tracking
    used_at: Optional[datetime] = Field(None, description="When reward was used/activated")
    usage_data: Dict[str, Any] = Field(default_factory=dict, description="Usage-specific data")
    
    # Metadata
    claim_context: Dict[str, Any] = Field(default_factory=dict, description="Context when claimed")
    
    # Timestamps
    created_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Settings:
        collection = "user_rewards"
        indexes = [
            [("user_id", 1), ("status", 1)],  # User's active rewards
            [("user_id", 1), ("claimed_at", -1)],  # User's reward history
            [("reward_id", 1), ("claimed_at", -1)],  # Reward usage stats
            [("status", 1), ("expires_at", 1)],  # Expiring rewards
            "user_id",
            "reward_id",
            "status"
        ]
    
    def is_expired(self, current_time: datetime = None) -> bool:
        """Check if reward has expired"""
        if self.expires_at is None:
            return False
        
        if current_time is None:
            current_time = datetime.utcnow()
        
        return current_time > self.expires_at
    
    def use_reward(self, usage_data: Dict[str, Any] = None):
        """Mark reward as used"""
        self.used_at = datetime.utcnow()
        if usage_data:
            self.usage_data.update(usage_data)


class Leaderboard(Document):
    """Leaderboard configurations and cached results"""
    
    # Leaderboard identification
    leaderboard_id: str = Field(..., description="Unique leaderboard identifier")
    name: str = Field(..., description="Leaderboard display name")
    description: str = Field(..., description="Leaderboard description")
    
    # Leaderboard configuration
    leaderboard_type: str = Field(..., description="Type (global, group, friends, etc.)")
    metric: str = Field(..., description="Metric being ranked (xp, points, streaks, etc.)")
    time_period: str = Field(default="all_time", description="Time period (daily, weekly, monthly, all_time)")
    
    # Filtering and scope
    category_filter: Optional[str] = Field(None, description="Category filter if applicable")
    group_id: Optional[str] = Field(None, description="Group ID for group leaderboards")
    premium_only: bool = Field(default=False, description="Premium users only")
    
    # Display settings
    max_entries: int = Field(default=100, description="Maximum entries to show")
    is_public: bool = Field(default=True, description="Whether leaderboard is publicly visible")
    show_rankings: bool = Field(default=True, description="Whether to show rank numbers")
    
    # Cached results (for performance)
    cached_results: List[Dict[str, Any]] = Field(default_factory=list, description="Cached leaderboard results")
    last_calculated: datetime = Field(default_factory=datetime.utcnow, description="Last calculation time")
    cache_duration_hours: int = Field(default=1, description="How long to cache results")
    
    # Analytics
    view_count: int = Field(default=0, description="Times leaderboard was viewed")
    participant_count: int = Field(default=0, description="Number of participants")
    
    # Timestamps
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Settings:
        collection = "leaderboards"
        indexes = [
            [("leaderboard_type", 1), ("time_period", 1)],  # Leaderboard discovery
            [("metric", 1), ("time_period", 1)],  # Leaderboards by metric
            [("group_id", 1)],  # Group leaderboards
            [("is_public", 1), ("view_count", -1)],  # Popular public leaderboards
            [("last_calculated", 1)],  # Stale cache cleanup
            "leaderboard_id",
            "leaderboard_type",
            "metric"
        ]
    
    def update_timestamp(self):
        """Update the updated_at timestamp"""
        self.updated_at = datetime.utcnow()
    
    def is_cache_valid(self) -> bool:
        """Check if cached results are still valid"""
        cache_expiry = self.last_calculated + timedelta(hours=self.cache_duration_hours)
        return datetime.utcnow() < cache_expiry
    
    def update_cache(self, results: List[Dict[str, Any]]):
        """Update cached results"""
        self.cached_results = results
        self.last_calculated = datetime.utcnow()
        self.participant_count = len(results)
        self.update_timestamp()
    
    def increment_views(self):
        """Increment view count"""
        self.view_count += 1