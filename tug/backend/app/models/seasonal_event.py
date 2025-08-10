# app/models/seasonal_event.py
from beanie import Document
from pydantic import Field
from typing import Optional, List, Dict, Any
from datetime import datetime, timedelta
from enum import Enum

class EventType(str, Enum):
    SEASONAL = "seasonal"
    HOLIDAY = "holiday"
    COMMUNITY = "community"
    MILESTONE = "milestone"
    SPECIAL = "special"

class EventStatus(str, Enum):
    UPCOMING = "upcoming"
    ACTIVE = "active"
    ENDING_SOON = "ending_soon"
    COMPLETED = "completed"
    CANCELLED = "cancelled"

class ParticipationLevel(str, Enum):
    BRONZE = "bronze"
    SILVER = "silver"
    GOLD = "gold"
    PLATINUM = "platinum"
    DIAMOND = "diamond"


class SeasonalEvent(Document):
    """Seasonal events and time-limited challenges"""
    
    # Event identification
    event_id: str = Field(..., description="Unique event identifier")
    name: str = Field(..., min_length=1, max_length=100, description="Event name")
    description: str = Field(..., max_length=1000, description="Event description")
    theme: str = Field(..., description="Event theme (summer, winter, new_year, etc.)")
    
    # Event classification
    event_type: EventType = Field(..., description="Type of event")
    status: EventStatus = Field(default=EventStatus.UPCOMING, description="Current event status")
    
    # Time parameters
    start_date: datetime = Field(..., description="Event start date")
    end_date: datetime = Field(..., description="Event end date")
    early_access_date: Optional[datetime] = Field(None, description="Early access for premium users")
    
    # Participation settings
    requires_premium: bool = Field(default=False, description="Premium-only event")
    max_participants: Optional[int] = Field(None, description="Maximum participants")
    auto_enroll_eligible: bool = Field(default=True, description="Auto-enroll qualifying users")
    
    # Event mechanics
    point_multiplier: float = Field(default=2.0, description="Points multiplier during event")
    special_rewards: Dict[str, Any] = Field(default_factory=dict, description="Event-specific rewards")
    milestone_rewards: List[Dict[str, Any]] = Field(default_factory=list, description="Progressive milestone rewards")
    
    # Event challenges
    featured_challenges: List[str] = Field(default_factory=list, description="Challenge IDs featured in event")
    exclusive_challenges: List[str] = Field(default_factory=list, description="Event-exclusive challenge IDs")
    daily_challenges: Dict[str, str] = Field(default_factory=dict, description="Daily challenge rotation")
    
    # Visual and branding
    color_theme: Dict[str, str] = Field(
        default_factory=lambda: {"primary": "#FF6B35", "secondary": "#F7931E", "accent": "#FFD23F"},
        description="Event color scheme"
    )
    banner_url: Optional[str] = Field(None, description="Event banner image")
    icon: str = Field(default="🎉", description="Event icon/emoji")
    background_music_url: Optional[str] = Field(None, description="Background music URL")
    
    # Progression system
    participation_levels: Dict[ParticipationLevel, Dict[str, Any]] = Field(
        default_factory=lambda: {
            ParticipationLevel.BRONZE: {"min_points": 100, "rewards": []},
            ParticipationLevel.SILVER: {"min_points": 500, "rewards": []},
            ParticipationLevel.GOLD: {"min_points": 1000, "rewards": []},
            ParticipationLevel.PLATINUM: {"min_points": 2500, "rewards": []},
            ParticipationLevel.DIAMOND: {"min_points": 5000, "rewards": []}
        },
        description="Participation level requirements and rewards"
    )
    
    # Social features
    enable_event_leaderboard: bool = Field(default=True, description="Show event leaderboard")
    enable_team_competitions: bool = Field(default=False, description="Allow team competitions")
    enable_social_sharing: bool = Field(default=True, description="Enable sharing event progress")
    
    # Analytics and engagement
    total_participants: int = Field(default=0, description="Total participants")
    active_participants: int = Field(default=0, description="Currently active participants")
    total_points_awarded: int = Field(default=0, description="Total event points awarded")
    challenges_completed: int = Field(default=0, description="Challenges completed during event")
    
    # Notification settings
    reminder_intervals: List[int] = Field(
        default_factory=lambda: [7, 3, 1], 
        description="Days before event to send reminders"
    )
    
    # Timestamps
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Settings:
        collection = "seasonal_events"
        indexes = [
            [("status", 1), ("start_date", 1)],  # Active/upcoming events
            [("theme", 1), ("event_type", 1)],  # Events by theme
            [("start_date", 1), ("end_date", 1)],  # Date range queries
            [("requires_premium", 1), ("status", 1)],  # Premium events
            [("total_participants", -1)],  # Popular events
            [("featured_challenges", 1)],  # Events featuring specific challenges
            "event_id",
            "status",
            "theme",
            "start_date"
        ]
    
    def update_timestamp(self):
        """Update the updated_at timestamp"""
        self.updated_at = datetime.utcnow()
    
    def is_active(self) -> bool:
        """Check if event is currently active"""
        now = datetime.utcnow()
        return self.status == EventStatus.ACTIVE and self.start_date <= now <= self.end_date
    
    def is_ending_soon(self, hours_threshold: int = 24) -> bool:
        """Check if event is ending soon"""
        if not self.is_active():
            return False
        
        now = datetime.utcnow()
        threshold = now + timedelta(hours=hours_threshold)
        return threshold >= self.end_date
    
    def can_participate(self, user_premium: bool, current_time: datetime = None) -> bool:
        """Check if user can participate in event"""
        if current_time is None:
            current_time = datetime.utcnow()
        
        # Check premium requirement
        if self.requires_premium and not user_premium:
            return False
        
        # Check if event is active or has early access
        if self.status != EventStatus.ACTIVE:
            if self.early_access_date and user_premium and current_time >= self.early_access_date:
                return True
            return False
        
        # Check capacity
        if self.max_participants and self.total_participants >= self.max_participants:
            return False
        
        return True
    
    def get_participation_level(self, points: int) -> ParticipationLevel:
        """Get user's participation level based on points"""
        for level in [ParticipationLevel.DIAMOND, ParticipationLevel.PLATINUM, 
                     ParticipationLevel.GOLD, ParticipationLevel.SILVER, ParticipationLevel.BRONZE]:
            if points >= self.participation_levels[level]["min_points"]:
                return level
        return ParticipationLevel.BRONZE
    
    def get_next_milestone(self, current_points: int) -> Optional[Dict[str, Any]]:
        """Get next milestone reward user can achieve"""
        current_level = self.get_participation_level(current_points)
        level_hierarchy = [ParticipationLevel.BRONZE, ParticipationLevel.SILVER, 
                          ParticipationLevel.GOLD, ParticipationLevel.PLATINUM, ParticipationLevel.DIAMOND]
        
        current_index = level_hierarchy.index(current_level)
        if current_index < len(level_hierarchy) - 1:
            next_level = level_hierarchy[current_index + 1]
            return {
                "level": next_level,
                "points_needed": self.participation_levels[next_level]["min_points"] - current_points,
                "rewards": self.participation_levels[next_level]["rewards"]
            }
        
        return None


class EventParticipation(Document):
    """Track individual user participation in seasonal events"""
    
    event_id: str = Field(..., description="Event ID")
    user_id: str = Field(..., description="User ID")
    
    # Participation details
    joined_at: datetime = Field(default_factory=datetime.utcnow, description="When user joined event")
    last_activity_at: datetime = Field(default_factory=datetime.utcnow, description="Last event activity")
    
    # Progress tracking
    points_earned: int = Field(default=0, description="Points earned in this event")
    current_level: ParticipationLevel = Field(default=ParticipationLevel.BRONZE, description="Current participation level")
    milestones_achieved: List[str] = Field(default_factory=list, description="Milestone IDs achieved")
    
    # Challenge participation
    challenges_completed: List[str] = Field(default_factory=list, description="Challenge IDs completed")
    daily_challenges_completed: Dict[str, List[str]] = Field(default_factory=dict, description="Daily challenges by date")
    
    # Social engagement
    social_shares: int = Field(default=0, description="Number of social shares")
    encouragements_given: int = Field(default=0, description="Encouragements given to other participants")
    encouragements_received: int = Field(default=0, description="Encouragements received")
    
    # Team participation (if applicable)
    team_id: Optional[str] = Field(None, description="Team ID if participating in team event")
    team_role: Optional[str] = Field(None, description="Role within team")
    
    # Rewards claimed
    rewards_claimed: List[Dict[str, Any]] = Field(default_factory=list, description="Rewards claimed from event")
    badges_earned: List[str] = Field(default_factory=list, description="Event-specific badges earned")
    
    # Personal stats
    streak_during_event: int = Field(default=0, description="Streak maintained during event")
    best_daily_score: int = Field(default=0, description="Best single-day point score")
    consistency_score: float = Field(default=0.0, description="Consistency metric for event participation")
    
    # Timestamps
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Settings:
        collection = "event_participations"
        indexes = [
            [("event_id", 1), ("user_id", 1)],  # Unique participation
            [("event_id", 1), ("points_earned", -1)],  # Event leaderboard
            [("event_id", 1), ("current_level", 1)],  # Participants by level
            [("user_id", 1), ("joined_at", -1)],  # User's event history
            [("team_id", 1)],  # Team members
            [("event_id", 1), ("last_activity_at", -1)],  # Recently active participants
            [("event_id", 1), ("consistency_score", -1)],  # Most consistent participants
            "event_id",
            "user_id",
            "points_earned"
        ]
    
    def update_timestamp(self):
        """Update timestamps"""
        self.updated_at = datetime.utcnow()
        self.last_activity_at = datetime.utcnow()
    
    def add_points(self, points: int, source: str = "challenge"):
        """Add points and update level if necessary"""
        self.points_earned += points
        
        # Update best daily score
        today = datetime.utcnow().strftime("%Y-%m-%d")
        daily_points = self.daily_challenges_completed.get(today, [])
        daily_total = len(daily_points) * 50  # Assume 50 points per daily challenge
        self.best_daily_score = max(self.best_daily_score, daily_total)
        
        self.update_timestamp()
    
    def complete_challenge(self, challenge_id: str, is_daily: bool = False):
        """Mark a challenge as completed"""
        if challenge_id not in self.challenges_completed:
            self.challenges_completed.append(challenge_id)
        
        if is_daily:
            today = datetime.utcnow().strftime("%Y-%m-%d")
            if today not in self.daily_challenges_completed:
                self.daily_challenges_completed[today] = []
            if challenge_id not in self.daily_challenges_completed[today]:
                self.daily_challenges_completed[today].append(challenge_id)
        
        self.update_timestamp()
    
    def achieve_milestone(self, milestone_id: str, reward_data: Dict[str, Any]):
        """Record milestone achievement"""
        if milestone_id not in self.milestones_achieved:
            self.milestones_achieved.append(milestone_id)
            self.rewards_claimed.append({
                "milestone_id": milestone_id,
                "reward": reward_data,
                "achieved_at": datetime.utcnow()
            })
        
        self.update_timestamp()
    
    def calculate_consistency_score(self, event_duration_days: int) -> float:
        """Calculate consistency score based on daily participation"""
        if event_duration_days <= 0:
            return 0.0
        
        # Count unique days with activity
        active_days = len(self.daily_challenges_completed)
        
        # Calculate consistency as percentage of days active
        consistency = (active_days / event_duration_days) * 100
        
        self.consistency_score = min(100.0, consistency)
        return self.consistency_score


class EventTeam(Document):
    """Teams for seasonal events that support team competitions"""
    
    event_id: str = Field(..., description="Event ID")
    team_id: str = Field(..., description="Unique team identifier")
    name: str = Field(..., min_length=1, max_length=50, description="Team name")
    description: Optional[str] = Field(None, max_length=200, description="Team description")
    
    # Team composition
    leader_id: str = Field(..., description="Team leader user ID")
    member_ids: List[str] = Field(default_factory=list, description="Team member user IDs")
    max_members: int = Field(default=5, description="Maximum team size")
    
    # Team customization
    team_color: str = Field(default="#3B82F6", description="Team color")
    team_emoji: str = Field(default="⭐", description="Team emoji")
    team_motto: Optional[str] = Field(None, max_length=100, description="Team motto/slogan")
    
    # Team performance
    total_points: int = Field(default=0, description="Combined team points")
    average_points: float = Field(default=0.0, description="Average points per member")
    challenges_completed: int = Field(default=0, description="Total challenges completed by team")
    
    # Team achievements
    team_achievements: List[str] = Field(default_factory=list, description="Team-specific achievements")
    team_badges: List[str] = Field(default_factory=list, description="Badges earned as a team")
    team_rank: Optional[int] = Field(None, description="Current team ranking")
    
    # Team settings
    is_public: bool = Field(default=True, description="Whether team accepts public applications")
    requires_approval: bool = Field(default=False, description="Whether joining requires leader approval")
    
    # Timestamps
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Settings:
        collection = "event_teams"
        indexes = [
            [("event_id", 1), ("total_points", -1)],  # Event team leaderboard
            [("event_id", 1), ("created_at", -1)],  # Event teams by creation
            [("leader_id", 1)],  # Teams led by user
            [("member_ids", 1)],  # Teams user belongs to
            [("is_public", 1), ("event_id", 1)],  # Public teams for event
            "event_id",
            "team_id",
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
            self.update_timestamp()
            return True
        
        return False
    
    def remove_member(self, user_id: str) -> bool:
        """Remove a member from the team"""
        if user_id in self.member_ids:
            self.member_ids.remove(user_id)
            self.update_timestamp()
            return True
        
        return False
    
    def calculate_team_metrics(self, participations: List[EventParticipation]):
        """Calculate team performance metrics"""
        if not participations:
            return
        
        # Calculate totals
        self.total_points = sum(p.points_earned for p in participations)
        self.average_points = self.total_points / len(participations)
        self.challenges_completed = sum(len(p.challenges_completed) for p in participations)
        
        self.update_timestamp()
    
    def get_member_count(self) -> int:
        """Get current member count including leader"""
        return len(self.member_ids) + 1  # +1 for leader