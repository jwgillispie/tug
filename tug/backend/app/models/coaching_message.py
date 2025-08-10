# app/models/coaching_message.py
from beanie import Document
from pydantic import Field
from typing import Optional, List, Dict, Any
from datetime import datetime, timedelta
from enum import Enum
from bson import ObjectId

class CoachingMessageType(str, Enum):
    """Types of coaching messages"""
    # Progress and Achievement
    PROGRESS_ENCOURAGEMENT = "progress_encouragement"
    MILESTONE_CELEBRATION = "milestone_celebration" 
    STREAK_ACHIEVEMENT = "streak_achievement"
    CONSISTENCY_RECOGNITION = "consistency_recognition"
    
    # Streak and Risk Management
    STREAK_RECOVERY = "streak_recovery"
    STREAK_RISK_WARNING = "streak_risk_warning"
    STREAK_MOTIVATION = "streak_motivation"
    COMEBACK_SUPPORT = "comeback_support"
    
    # Challenge and Growth
    CHALLENGE_MOTIVATION = "challenge_motivation"
    GOAL_SUGGESTION = "goal_suggestion"
    HABIT_EXPANSION = "habit_expansion"
    DIFFICULTY_INCREASE = "difficulty_increase"
    
    # Wisdom and Tips
    HABIT_TIP = "habit_tip"
    WISDOM_INSIGHT = "wisdom_insight"
    BEHAVIORAL_INSIGHT = "behavioral_insight"
    TIMING_OPTIMIZATION = "timing_optimization"
    
    # Contextual Support
    MORNING_MOTIVATION = "morning_motivation"
    EVENING_REFLECTION = "evening_reflection"
    WEEKEND_ENCOURAGEMENT = "weekend_encouragement"
    REACTIVATION = "reactivation"

class CoachingMessagePriority(str, Enum):
    """Priority levels for coaching messages"""
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    URGENT = "urgent"

class CoachingMessageTone(str, Enum):
    """Tone of coaching messages"""
    ENCOURAGING = "encouraging"
    MOTIVATIONAL = "motivational"
    SUPPORTIVE = "supportive"
    CHALLENGING = "challenging"
    CELEBRATORY = "celebratory"
    GENTLE = "gentle"
    URGENT = "urgent"
    WISE = "wise"

class CoachingMessageStatus(str, Enum):
    """Status of coaching messages"""
    PENDING = "pending"
    SCHEDULED = "scheduled"
    SENT = "sent"
    READ = "read"
    ACTED_ON = "acted_on"
    EXPIRED = "expired"
    CANCELLED = "cancelled"

class UserPersonalizationProfile(Document):
    """User's personalization profile for coaching messages"""
    
    user_id: str = Field(..., description="User ID this profile belongs to")
    
    # Preferred communication style
    preferred_tone: CoachingMessageTone = Field(default=CoachingMessageTone.ENCOURAGING)
    message_frequency: str = Field(default="optimal", description="daily, frequent, optimal, minimal")
    quiet_hours: List[int] = Field(default_factory=lambda: [22, 23, 0, 1, 2, 3, 4, 5, 6], description="Hours to avoid sending messages")
    preferred_times: List[int] = Field(default_factory=lambda: [9, 18], description="Preferred hours for messages")
    
    # Message type preferences (0-1 scale, 0=disabled, 1=max frequency)
    message_type_preferences: Dict[str, float] = Field(default_factory=lambda: {
        "progress_encouragement": 0.8,
        "milestone_celebration": 1.0,
        "streak_recovery": 0.9,
        "challenge_motivation": 0.6,
        "habit_tip": 0.7,
        "wisdom_insight": 0.5,
        "morning_motivation": 0.4,
        "evening_reflection": 0.3,
        "reactivation": 0.8
    })
    
    # Personalization data learned from user behavior
    response_patterns: Dict[str, Any] = Field(default_factory=dict, description="How user responds to different message types")
    engagement_scores: Dict[str, float] = Field(default_factory=dict, description="Engagement scores by message type")
    optimal_timing: Dict[str, Any] = Field(default_factory=dict, description="ML-learned optimal timing patterns")
    
    # Cultural and linguistic preferences
    language_preference: str = Field(default="en", description="Language code")
    cultural_context: Optional[str] = Field(default=None, description="Cultural context for message adaptation")
    
    # Premium features
    ai_personalization_enabled: bool = Field(default=False, description="Advanced AI personalization for premium users")
    custom_motivations: List[str] = Field(default_factory=list, description="User's custom motivational phrases")
    
    # Analytics and optimization
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    last_message_sent: Optional[datetime] = Field(default=None)
    total_messages_sent: int = Field(default=0)
    total_messages_engaged: int = Field(default=0)
    
    class Settings:
        collection = "user_personalization_profiles"
        indexes = [
            "user_id",
            "updated_at",
            "last_message_sent",
            [("user_id", 1), ("updated_at", -1)]
        ]
    
    def update_engagement(self, message_type: str, engaged: bool):
        """Update engagement metrics for a message type"""
        if message_type not in self.engagement_scores:
            self.engagement_scores[message_type] = 0.0
            
        # Weighted moving average (recent activity weighted higher)
        current_score = self.engagement_scores[message_type]
        new_score = 1.0 if engaged else 0.0
        self.engagement_scores[message_type] = (current_score * 0.8) + (new_score * 0.2)
        
        if engaged:
            self.total_messages_engaged += 1
            
        self.total_messages_sent += 1
        self.updated_at = datetime.utcnow()

class CoachingMessage(Document):
    """Individual coaching message model"""
    
    user_id: str = Field(..., description="User ID this message is for")
    message_type: CoachingMessageType = Field(..., description="Type of coaching message")
    priority: CoachingMessagePriority = Field(default=CoachingMessagePriority.MEDIUM)
    tone: CoachingMessageTone = Field(default=CoachingMessageTone.ENCOURAGING)
    
    # Message content
    title: str = Field(..., min_length=1, max_length=200, description="Message title")
    message: str = Field(..., min_length=1, max_length=1000, description="Message content")
    action_text: Optional[str] = Field(None, max_length=50, description="Call-to-action button text")
    action_url: Optional[str] = Field(None, description="Deep link or URL for action")
    
    # Personalization context
    personalization_context: Dict[str, Any] = Field(default_factory=dict, description="Context used for personalization")
    related_activity_id: Optional[str] = Field(None, description="Related activity ID if applicable")
    related_value_id: Optional[str] = Field(None, description="Related value ID if applicable")
    related_streak_info: Optional[Dict[str, Any]] = Field(None, description="Related streak information")
    
    # Scheduling and delivery
    scheduled_for: datetime = Field(..., description="When this message should be sent")
    expires_at: Optional[datetime] = Field(None, description="When this message expires")
    status: CoachingMessageStatus = Field(default=CoachingMessageStatus.PENDING)
    
    # ML and analytics data
    ml_confidence_score: float = Field(default=0.0, description="ML confidence in message relevance")
    behavioral_trigger: Optional[str] = Field(None, description="What behavioral pattern triggered this message")
    expected_engagement_score: float = Field(default=0.0, description="Predicted engagement likelihood")
    ab_test_variant: Optional[str] = Field(None, description="A/B test variant if applicable")
    
    # Delivery tracking
    created_at: datetime = Field(default_factory=datetime.utcnow)
    sent_at: Optional[datetime] = Field(None)
    read_at: Optional[datetime] = Field(None)
    acted_on_at: Optional[datetime] = Field(None)
    cancelled_at: Optional[datetime] = Field(None)
    
    # Engagement tracking
    engagement_score: Optional[float] = Field(None, description="Actual engagement score (0-1)")
    user_feedback: Optional[str] = Field(None, description="User feedback on message")
    delivery_channel: str = Field(default="push", description="How message was delivered")
    
    class Settings:
        collection = "coaching_messages"
        indexes = [
            "user_id",
            "message_type", 
            "priority",
            "status",
            "scheduled_for",
            "expires_at",
            "created_at",
            [("user_id", 1), ("status", 1), ("scheduled_for", 1)],
            [("user_id", 1), ("message_type", 1), ("created_at", -1)],
            [("status", 1), ("scheduled_for", 1)],
            [("expires_at", 1), ("status", 1)],
            [("behavioral_trigger", 1), ("created_at", -1)]
        ]
    
    def mark_sent(self):
        """Mark message as sent"""
        self.status = CoachingMessageStatus.SENT
        self.sent_at = datetime.utcnow()
    
    def mark_read(self):
        """Mark message as read"""
        if self.status == CoachingMessageStatus.SENT:
            self.status = CoachingMessageStatus.READ
            self.read_at = datetime.utcnow()
    
    def mark_acted_on(self):
        """Mark message as acted upon"""
        if self.status in [CoachingMessageStatus.SENT, CoachingMessageStatus.READ]:
            self.status = CoachingMessageStatus.ACTED_ON
            self.acted_on_at = datetime.utcnow()
    
    def cancel(self):
        """Cancel this message"""
        if self.status in [CoachingMessageStatus.PENDING, CoachingMessageStatus.SCHEDULED]:
            self.status = CoachingMessageStatus.CANCELLED
            self.cancelled_at = datetime.utcnow()
    
    def is_expired(self) -> bool:
        """Check if message has expired"""
        if self.expires_at and datetime.utcnow() > self.expires_at:
            return True
        return False
    
    def calculate_engagement_score(self) -> float:
        """Calculate engagement score based on user interaction"""
        if self.status == CoachingMessageStatus.ACTED_ON:
            return 1.0
        elif self.status == CoachingMessageStatus.READ and self.read_at:
            # Time-based engagement scoring (quick reads score lower)
            if self.sent_at:
                read_time = (self.read_at - self.sent_at).total_seconds()
                if read_time < 5:  # Less than 5 seconds - likely accidental
                    return 0.2
                elif read_time < 30:  # 5-30 seconds - quick glance
                    return 0.4
                else:  # 30+ seconds - genuine read
                    return 0.6
            return 0.5
        elif self.status == CoachingMessageStatus.SENT:
            return 0.1  # Delivered but not read
        else:
            return 0.0  # Not delivered

class CoachingMessageTemplate(Document):
    """Template for generating coaching messages"""
    
    template_id: str = Field(..., description="Unique template identifier")
    message_type: CoachingMessageType = Field(..., description="Type of message this template generates")
    name: str = Field(..., description="Human-readable template name")
    description: str = Field(..., description="Description of when to use this template")
    
    # Template content with placeholders
    title_template: str = Field(..., description="Title template with placeholders like {streak_days}")
    message_template: str = Field(..., description="Message template with placeholders")
    action_text_template: Optional[str] = Field(None, description="Action button text template")
    
    # Personalization parameters
    tone: CoachingMessageTone = Field(default=CoachingMessageTone.ENCOURAGING)
    priority: CoachingMessagePriority = Field(default=CoachingMessagePriority.MEDIUM)
    
    # Targeting criteria
    min_user_age_days: int = Field(default=0, description="Minimum user age in days")
    max_user_age_days: Optional[int] = Field(None, description="Maximum user age in days")
    min_activity_count: int = Field(default=0, description="Minimum activity count")
    user_segments: List[str] = Field(default_factory=list, description="Target user segments")
    premium_only: bool = Field(default=False, description="Premium users only")
    
    # Timing and frequency
    cooldown_hours: int = Field(default=24, description="Hours to wait before sending similar message")
    expiry_hours: int = Field(default=48, description="Hours until message expires")
    optimal_hours: List[int] = Field(default_factory=list, description="Optimal hours to send (empty = any)")
    avoid_days: List[int] = Field(default_factory=list, description="Days of week to avoid (0=Monday)")
    
    # A/B Testing
    ab_test_variants: Dict[str, Any] = Field(default_factory=dict, description="A/B test variants")
    
    # Analytics
    usage_count: int = Field(default=0, description="How many times this template has been used")
    average_engagement: float = Field(default=0.0, description="Average engagement score")
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    is_active: bool = Field(default=True, description="Whether template is active")
    
    class Settings:
        collection = "coaching_message_templates"
        indexes = [
            "template_id",
            "message_type",
            "is_active",
            "user_segments",
            "premium_only",
            [("message_type", 1), ("is_active", 1)],
            [("user_segments", 1), ("is_active", 1)],
            [("average_engagement", -1), ("usage_count", -1)]
        ]
    
    def generate_message(
        self, 
        user_id: str, 
        context: Dict[str, Any], 
        personalization_profile: UserPersonalizationProfile
    ) -> CoachingMessage:
        """Generate a personalized coaching message from this template"""
        
        # Apply personalization context to templates
        title = self.title_template.format(**context)
        message = self.message_template.format(**context)
        action_text = self.action_text_template.format(**context) if self.action_text_template else None
        
        # Adjust tone based on user preference
        tone = personalization_profile.preferred_tone
        
        # Calculate expiry time
        expires_at = datetime.utcnow() + timedelta(hours=self.expiry_hours)
        
        # Determine scheduling time based on user preferences
        scheduled_for = self._calculate_optimal_send_time(personalization_profile)
        
        return CoachingMessage(
            user_id=user_id,
            message_type=self.message_type,
            priority=self.priority,
            tone=tone,
            title=title,
            message=message,
            action_text=action_text,
            personalization_context=context,
            scheduled_for=scheduled_for,
            expires_at=expires_at,
            expected_engagement_score=personalization_profile.engagement_scores.get(
                self.message_type.value, 0.5
            )
        )
    
    def _calculate_optimal_send_time(self, profile: UserPersonalizationProfile) -> datetime:
        """Calculate optimal time to send message based on user preferences"""
        
        now = datetime.utcnow()
        current_hour = now.hour
        
        # If current time is good, send soon
        if (current_hour not in profile.quiet_hours and 
            current_hour in profile.preferred_times):
            return now + timedelta(minutes=5)  # Small delay for processing
        
        # Find next preferred time that's not in quiet hours
        for hour in sorted(profile.preferred_times):
            potential_time = now.replace(hour=hour, minute=0, second=0, microsecond=0)
            
            # If time has passed today, try tomorrow
            if potential_time <= now:
                potential_time += timedelta(days=1)
            
            if hour not in profile.quiet_hours:
                return potential_time
        
        # Fallback: send at 9 AM tomorrow
        return (now + timedelta(days=1)).replace(hour=9, minute=0, second=0, microsecond=0)