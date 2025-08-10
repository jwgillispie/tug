# app/models/challenge.py
from beanie import Document
from pydantic import Field
from typing import Optional, List, Dict, Any, Union
from datetime import datetime, timedelta
from enum import Enum

class ChallengeType(str, Enum):
    INDIVIDUAL = "individual"
    GROUP = "group"
    COMMUNITY = "community"
    SEASONAL = "seasonal"

class ChallengeDifficulty(str, Enum):
    EASY = "easy"
    MEDIUM = "medium"
    HARD = "hard"
    EXTREME = "extreme"

class ChallengeStatus(str, Enum):
    DRAFT = "draft"
    UPCOMING = "upcoming" 
    ACTIVE = "active"
    PAUSED = "paused"
    COMPLETED = "completed"
    CANCELLED = "cancelled"

class ChallengeCategory(str, Enum):
    HEALTH = "health"
    FITNESS = "fitness"
    MINDFULNESS = "mindfulness"
    PRODUCTIVITY = "productivity"
    SOCIAL = "social"
    LEARNING = "learning"
    CREATIVE = "creative"
    FINANCIAL = "financial"
    ENVIRONMENTAL = "environmental"
    CUSTOM = "custom"

class RewardType(str, Enum):
    POINTS = "points"
    BADGE = "badge"
    PREMIUM_BENEFIT = "premium_benefit"
    VIRTUAL_ITEM = "virtual_item"
    STREAK_MULTIPLIER = "streak_multiplier"
    CUSTOM = "custom"

class ChallengeMechanic(str, Enum):
    DAILY_STREAK = "daily_streak"
    TOTAL_COUNT = "total_count" 
    TIME_BASED = "time_based"
    PROGRESSION = "progression"
    COMPETITIVE = "competitive"
    COLLABORATIVE = "collaborative"

class Challenge(Document):
    """Enhanced challenge system supporting multiple types, difficulties, and reward mechanisms"""
    
    # Basic challenge information
    title: str = Field(..., min_length=1, max_length=100, description="Challenge title")
    description: str = Field(..., max_length=1000, description="Detailed challenge description") 
    short_description: str = Field(..., max_length=200, description="Brief challenge summary")
    
    # Challenge classification
    challenge_type: ChallengeType = Field(..., description="Type of challenge")
    category: ChallengeCategory = Field(..., description="Challenge category")
    difficulty: ChallengeDifficulty = Field(..., description="Challenge difficulty level")
    mechanic: ChallengeMechanic = Field(..., description="Core challenge mechanic")
    
    # Challenge parameters
    target_metric: str = Field(..., description="What to measure (activities, days, hours, etc.)")
    target_value: float = Field(..., gt=0, description="Target value to achieve")
    duration_days: int = Field(..., gt=0, le=365, description="Challenge duration in days")
    
    # Multi-stage challenge support
    is_multi_stage: bool = Field(default=False, description="Whether this is a multi-stage challenge")
    stages: List[Dict[str, Any]] = Field(default_factory=list, description="Challenge stages if multi-stage")
    current_stage: int = Field(default=1, description="Current stage number")
    
    # Difficulty scaling
    difficulty_multiplier: float = Field(default=1.0, description="Difficulty-based reward multiplier")
    base_points: int = Field(default=100, description="Base points for completion")
    bonus_points: int = Field(default=0, description="Bonus points for exceptional performance")
    
    # Time parameters
    start_date: datetime = Field(..., description="Challenge start date")
    end_date: datetime = Field(..., description="Challenge end date")
    registration_start: Optional[datetime] = Field(None, description="When registration opens")
    registration_end: Optional[datetime] = Field(None, description="Registration deadline")
    
    # Participation settings
    max_participants: Optional[int] = Field(None, description="Maximum participants (null = unlimited)")
    min_participants: int = Field(default=1, description="Minimum participants to start")
    auto_join_eligible: bool = Field(default=False, description="Auto-join qualifying users")
    requires_premium: bool = Field(default=False, description="Requires premium subscription")
    
    # Status and lifecycle
    status: ChallengeStatus = Field(default=ChallengeStatus.DRAFT, description="Current challenge status")
    created_by: str = Field(..., description="User ID who created the challenge")
    approved_by: Optional[str] = Field(None, description="Admin who approved the challenge")
    
    # Rewards configuration
    reward_pool: Dict[str, Any] = Field(
        default_factory=lambda: {
            "completion": {"type": "points", "amount": 100},
            "streak_bonus": {"type": "points", "amount": 50},
            "top_performer": {"type": "badge", "badge_id": "top_performer"},
            "participation": {"type": "points", "amount": 25}
        },
        description="Available rewards for different achievements"
    )
    
    # Seasonal/Event specific
    is_seasonal: bool = Field(default=False, description="Whether this is a seasonal challenge")
    seasonal_theme: Optional[str] = Field(None, description="Seasonal theme identifier")
    unlock_conditions: Dict[str, Any] = Field(default_factory=dict, description="Conditions to unlock challenge")
    
    # AI and personalization
    ai_generated: bool = Field(default=False, description="Whether challenge was AI-generated")
    personalization_data: Dict[str, Any] = Field(default_factory=dict, description="User-specific customization")
    recommended_for: List[str] = Field(default_factory=list, description="User IDs this is recommended for")
    
    # Analytics and engagement
    total_participants: int = Field(default=0, description="Total number of participants")
    active_participants: int = Field(default=0, description="Currently active participants") 
    completion_count: int = Field(default=0, description="Number of completions")
    average_progress: float = Field(default=0.0, description="Average participant progress")
    engagement_score: float = Field(default=0.0, description="Overall engagement metric")
    
    # Social features
    is_public: bool = Field(default=True, description="Whether challenge is publicly visible")
    allow_teams: bool = Field(default=False, description="Whether teams are allowed")
    enable_leaderboard: bool = Field(default=True, description="Whether to show leaderboard")
    enable_social_sharing: bool = Field(default=True, description="Enable social sharing")
    
    # Premium features
    premium_rewards: Dict[str, Any] = Field(default_factory=dict, description="Additional premium rewards")
    exclusive_access: bool = Field(default=False, description="Premium-only access")
    custom_branding: Dict[str, Any] = Field(default_factory=dict, description="Custom branding for premium")
    
    # Tags and metadata
    tags: List[str] = Field(default_factory=list, description="Challenge tags")
    image_url: Optional[str] = Field(None, description="Challenge banner image")
    icon: str = Field(default="🏆", description="Challenge icon/emoji")
    featured: bool = Field(default=False, description="Whether challenge is featured")
    
    # Timestamps
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Settings:
        collection = "challenges"
        indexes = [
            # Core queries
            [("status", 1), ("start_date", 1)],  # Active/upcoming challenges
            [("challenge_type", 1), ("status", 1)],  # Challenges by type
            [("category", 1), ("difficulty", 1), ("status", 1)],  # Discovery
            
            # User and participation
            [("created_by", 1), ("created_at", -1)],  # User's challenges
            [("requires_premium", 1), ("status", 1)],  # Premium challenges
            [("recommended_for", 1)],  # Personalized recommendations
            
            # Time-based
            [("start_date", 1), ("end_date", 1)],  # Date range queries
            [("is_seasonal", 1), ("seasonal_theme", 1)],  # Seasonal challenges
            [("registration_start", 1), ("registration_end", 1)],  # Registration period
            
            # Analytics and discovery
            [("featured", -1), ("engagement_score", -1)],  # Featured challenges
            [("total_participants", -1)],  # Popular challenges
            [("difficulty", 1), ("base_points", -1)],  # By difficulty/rewards
            [("tags", 1)],  # Tag-based search
            
            # Social and visibility
            [("is_public", 1), ("status", 1)],  # Public challenges
            [("enable_leaderboard", 1)],  # Leaderboard challenges
            
            # Multi-stage support
            [("is_multi_stage", 1), ("current_stage", 1)],  # Multi-stage challenges
            
            # Basic indexes
            "status",
            "challenge_type",
            "category", 
            "difficulty",
            "created_by",
            "start_date",
            "created_at"
        ]
    
    def update_timestamp(self):
        """Update the updated_at timestamp"""
        self.updated_at = datetime.utcnow()
    
    def is_registration_open(self) -> bool:
        """Check if registration is currently open"""
        now = datetime.utcnow()
        
        if self.registration_start and now < self.registration_start:
            return False
        
        if self.registration_end and now > self.registration_end:
            return False
            
        return self.status in [ChallengeStatus.UPCOMING, ChallengeStatus.ACTIVE]
    
    def is_active(self) -> bool:
        """Check if challenge is currently active"""
        now = datetime.utcnow()
        return (self.status == ChallengeStatus.ACTIVE and 
                self.start_date <= now <= self.end_date)
    
    def get_progress_percentage(self) -> float:
        """Get overall challenge progress as percentage"""
        if self.status == ChallengeStatus.COMPLETED:
            return 100.0
        
        if self.status not in [ChallengeStatus.ACTIVE, ChallengeStatus.PAUSED]:
            return 0.0
            
        # Calculate based on time elapsed
        now = datetime.utcnow()
        total_duration = (self.end_date - self.start_date).total_seconds()
        elapsed_duration = (now - self.start_date).total_seconds()
        
        if total_duration <= 0:
            return 0.0
            
        return min(100.0, (elapsed_duration / total_duration) * 100)
    
    def calculate_reward_points(self, completion_rate: float = 1.0, streak_bonus: int = 0) -> int:
        """Calculate total reward points for a participant"""
        base = int(self.base_points * self.difficulty_multiplier * completion_rate)
        
        # Streak bonus
        streak_points = streak_bonus * self.reward_pool.get("streak_bonus", {}).get("amount", 0)
        
        # Performance bonus
        bonus = self.bonus_points if completion_rate >= 1.0 else 0
        
        return base + streak_points + bonus


class ChallengeParticipation(Document):
    """Track individual user participation in challenges"""
    
    challenge_id: str = Field(..., description="ID of the challenge")
    user_id: str = Field(..., description="ID of the participating user")
    team_id: Optional[str] = Field(None, description="Team ID if participating as team")
    
    # Participation status
    status: str = Field(default="active", description="Participation status")
    joined_at: datetime = Field(default_factory=datetime.utcnow, description="When user joined")
    completed_at: Optional[datetime] = Field(None, description="When user completed challenge")
    
    # Progress tracking
    current_progress: float = Field(default=0.0, description="Current progress value")
    progress_percentage: float = Field(default=0.0, description="Progress as percentage")
    current_streak: int = Field(default=0, description="Current streak count")
    best_streak: int = Field(default=0, description="Best streak achieved")
    
    # Multi-stage progress
    current_stage: int = Field(default=1, description="Current stage if multi-stage")
    stages_completed: List[int] = Field(default_factory=list, description="List of completed stages")
    stage_progress: Dict[int, float] = Field(default_factory=dict, description="Progress per stage")
    
    # Performance metrics
    daily_progress: Dict[str, float] = Field(default_factory=dict, description="Daily progress tracking")
    milestone_achievements: List[Dict[str, Any]] = Field(default_factory=list, description="Milestones reached")
    personal_best: float = Field(default=0.0, description="Personal best performance")
    
    # Rewards earned
    points_earned: int = Field(default=0, description="Total points earned")
    badges_earned: List[str] = Field(default_factory=list, description="Badge IDs earned")
    rewards_claimed: List[Dict[str, Any]] = Field(default_factory=list, description="All rewards claimed")
    
    # Social and engagement
    likes_received: int = Field(default=0, description="Likes on progress posts")
    comments_received: int = Field(default=0, description="Comments on progress")
    encouragements_sent: int = Field(default=0, description="Encouragements sent to others")
    encouragements_received: int = Field(default=0, description="Encouragements received")
    
    # Analytics data
    activity_log: List[Dict[str, Any]] = Field(default_factory=list, description="Detailed activity log")
    engagement_score: float = Field(default=0.0, description="Participation engagement score")
    consistency_score: float = Field(default=0.0, description="Consistency metric")
    
    # Timestamps
    last_activity_at: datetime = Field(default_factory=datetime.utcnow, description="Last activity timestamp")
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Settings:
        collection = "challenge_participations"
        indexes = [
            # Primary queries
            [("challenge_id", 1), ("user_id", 1)],  # Unique participation
            [("challenge_id", 1), ("status", 1)],  # Challenge participants
            [("user_id", 1), ("status", 1)],  # User's active challenges
            [("user_id", 1), ("joined_at", -1)],  # User's challenge history
            
            # Progress and performance
            [("challenge_id", 1), ("progress_percentage", -1)],  # Leaderboard
            [("challenge_id", 1), ("current_streak", -1)],  # Streak leaderboard
            [("challenge_id", 1), ("points_earned", -1)],  # Points leaderboard
            
            # Team support
            [("team_id", 1), ("status", 1)],  # Team members
            [("challenge_id", 1), ("team_id", 1)],  # Challenge teams
            
            # Analytics
            [("user_id", 1), ("points_earned", -1)],  # User's best performances
            [("challenge_id", 1), ("engagement_score", -1)],  # Most engaged participants
            [("last_activity_at", -1)],  # Recently active
            
            # Multi-stage
            [("challenge_id", 1), ("current_stage", 1)],  # Stage progression
            [("user_id", 1), ("current_stage", 1)],  # User stage progress
            
            # Basic indexes
            "challenge_id",
            "user_id",
            "status",
            "team_id",
            "joined_at"
        ]
    
    def update_timestamp(self):
        """Update timestamps"""
        self.updated_at = datetime.utcnow()
        self.last_activity_at = datetime.utcnow()
    
    def update_progress(self, new_progress: float, stage: int = 1):
        """Update progress and related metrics"""
        old_progress = self.current_progress
        self.current_progress = max(self.current_progress, new_progress)
        
        # Update stage progress if multi-stage
        if stage not in self.stage_progress or new_progress > self.stage_progress.get(stage, 0):
            self.stage_progress[stage] = new_progress
        
        # Update personal best
        self.personal_best = max(self.personal_best, new_progress)
        
        # Log the progress update
        today = datetime.utcnow().strftime("%Y-%m-%d")
        self.daily_progress[today] = new_progress
        
        # Update activity log
        self.activity_log.append({
            "timestamp": datetime.utcnow(),
            "type": "progress_update",
            "old_value": old_progress,
            "new_value": new_progress,
            "stage": stage
        })
        
        self.update_timestamp()
    
    def add_milestone(self, milestone_name: str, value: float, reward_data: Dict[str, Any]):
        """Add a milestone achievement"""
        milestone = {
            "name": milestone_name,
            "value": value,
            "achieved_at": datetime.utcnow(),
            "reward": reward_data
        }
        self.milestone_achievements.append(milestone)
        self.update_timestamp()
    
    def calculate_consistency_score(self) -> float:
        """Calculate consistency score based on daily progress"""
        if not self.daily_progress:
            return 0.0
        
        # Count days with progress
        active_days = sum(1 for progress in self.daily_progress.values() if progress > 0)
        total_days = len(self.daily_progress)
        
        return (active_days / total_days) * 100 if total_days > 0 else 0.0


class ChallengeTeam(Document):
    """Support for team-based challenges"""
    
    challenge_id: str = Field(..., description="ID of the challenge")
    name: str = Field(..., min_length=1, max_length=50, description="Team name")
    description: Optional[str] = Field(None, max_length=200, description="Team description")
    
    # Team composition
    leader_id: str = Field(..., description="Team leader user ID")
    member_ids: List[str] = Field(default_factory=list, description="Team member user IDs") 
    max_members: int = Field(default=5, description="Maximum team size")
    
    # Team settings
    is_public: bool = Field(default=True, description="Whether team is publicly joinable")
    requires_approval: bool = Field(default=False, description="Whether joining requires approval")
    team_color: str = Field(default="#3B82F6", description="Team color")
    team_emoji: str = Field(default="⭐", description="Team emoji")
    
    # Progress and performance
    total_progress: float = Field(default=0.0, description="Combined team progress")
    average_progress: float = Field(default=0.0, description="Average member progress")
    team_streak: int = Field(default=0, description="Team-wide streak")
    points_earned: int = Field(default=0, description="Total team points")
    
    # Analytics
    collaboration_score: float = Field(default=0.0, description="Team collaboration metric")
    member_engagement: Dict[str, float] = Field(default_factory=dict, description="Per-member engagement")
    
    # Timestamps
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Settings:
        collection = "challenge_teams"
        indexes = [
            [("challenge_id", 1), ("created_at", -1)],  # Challenge teams
            [("leader_id", 1)],  # Teams led by user
            [("member_ids", 1)],  # Teams user belongs to
            [("challenge_id", 1), ("total_progress", -1)],  # Team leaderboard
            [("is_public", 1), ("challenge_id", 1)],  # Public teams
            "challenge_id",
            "leader_id"
        ]
    
    def update_timestamp(self):
        """Update the updated_at timestamp"""
        self.updated_at = datetime.utcnow()
    
    def add_member(self, user_id: str) -> bool:
        """Add a member to the team"""
        if len(self.member_ids) >= self.max_members:
            return False
        
        if user_id not in self.member_ids:
            self.member_ids.append(user_id)
            self.member_engagement[user_id] = 0.0
            self.update_timestamp()
            return True
        
        return False
    
    def remove_member(self, user_id: str) -> bool:
        """Remove a member from the team"""
        if user_id in self.member_ids:
            self.member_ids.remove(user_id)
            self.member_engagement.pop(user_id, None)
            self.update_timestamp()
            return True
        
        return False
    
    def calculate_team_metrics(self, participations: List[ChallengeParticipation]):
        """Calculate team-wide metrics from member participations"""
        if not participations:
            return
        
        # Calculate totals and averages
        total_progress = sum(p.current_progress for p in participations)
        avg_progress = total_progress / len(participations)
        total_points = sum(p.points_earned for p in participations)
        
        # Update team metrics
        self.total_progress = total_progress
        self.average_progress = avg_progress
        self.points_earned = total_points
        
        # Calculate collaboration score (how evenly distributed the progress is)
        if len(participations) > 1:
            progress_values = [p.current_progress for p in participations]
            mean_progress = avg_progress
            variance = sum((x - mean_progress) ** 2 for x in progress_values) / len(progress_values)
            # Lower variance = better collaboration (more even progress)
            self.collaboration_score = max(0.0, 100.0 - (variance / mean_progress * 100) if mean_progress > 0 else 0.0)
        else:
            self.collaboration_score = 100.0  # Single member = perfect collaboration
        
        self.update_timestamp()