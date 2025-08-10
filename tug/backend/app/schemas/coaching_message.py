# app/schemas/coaching_message.py
from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime
from ..models.coaching_message import (
    CoachingMessageType, CoachingMessagePriority, CoachingMessageTone, 
    CoachingMessageStatus
)

class CoachingMessageData(BaseModel):
    """Data model for coaching message responses"""
    id: str
    user_id: str
    message_type: CoachingMessageType
    priority: CoachingMessagePriority
    tone: CoachingMessageTone
    title: str
    message: str
    action_text: Optional[str] = None
    action_url: Optional[str] = None
    status: CoachingMessageStatus
    scheduled_for: datetime
    expires_at: Optional[datetime] = None
    created_at: datetime
    sent_at: Optional[datetime] = None
    read_at: Optional[datetime] = None
    acted_on_at: Optional[datetime] = None
    ml_confidence_score: float
    expected_engagement_score: float
    behavioral_trigger: Optional[str] = None
    ab_test_variant: Optional[str] = None
    delivery_channel: str
    engagement_score: Optional[float] = None

class CoachingMessageSummary(BaseModel):
    """Summary of coaching messages for a user"""
    unread_count: int
    pending_count: int
    total_sent: int
    engagement_rate: float
    last_message_sent: Optional[datetime] = None
    next_scheduled: Optional[datetime] = None
    recent_messages: List[CoachingMessageData]

class UserPersonalizationProfileData(BaseModel):
    """Data model for user personalization profile"""
    user_id: str
    preferred_tone: CoachingMessageTone
    message_frequency: str
    quiet_hours: List[int]
    preferred_times: List[int]
    message_type_preferences: Dict[str, float]
    language_preference: str
    cultural_context: Optional[str] = None
    ai_personalization_enabled: bool
    custom_motivations: List[str]
    total_messages_sent: int
    total_messages_engaged: int
    engagement_rate: float

class UpdatePersonalizationProfileRequest(BaseModel):
    """Request to update user personalization profile"""
    preferred_tone: Optional[CoachingMessageTone] = None
    message_frequency: Optional[str] = Field(None, pattern="^(daily|frequent|optimal|minimal)$")
    quiet_hours: Optional[List[int]] = Field(None, min_items=0, max_items=24)
    preferred_times: Optional[List[int]] = Field(None, min_items=0, max_items=24)
    message_type_preferences: Optional[Dict[str, float]] = None
    language_preference: Optional[str] = None
    cultural_context: Optional[str] = None
    custom_motivations: Optional[List[str]] = Field(None, max_items=10)

class CoachingMessageResponse(BaseModel):
    """Response containing coaching messages"""
    messages: List[CoachingMessageData]
    has_more: bool
    total_count: int
    engagement_stats: Optional[Dict[str, Any]] = None

class MessageFeedbackRequest(BaseModel):
    """Request to provide feedback on a coaching message"""
    message_id: str = Field(..., description="ID of the message")
    feedback_type: str = Field(..., pattern="^(helpful|not_helpful|inappropriate|timing_bad)$")
    feedback_text: Optional[str] = Field(None, max_length=500, description="Optional feedback text")
    engaged: bool = Field(default=False, description="Whether user engaged with the message")

class MessageInteractionRequest(BaseModel):
    """Request to record message interaction"""
    message_id: str = Field(..., description="ID of the message")
    interaction_type: str = Field(..., pattern="^(read|acted_on|dismissed|snoozed)$")
    interaction_data: Optional[Dict[str, Any]] = Field(None, description="Additional interaction data")

class CoachingInsightsResponse(BaseModel):
    """Response containing coaching insights and analytics"""
    user_segment: str
    engagement_patterns: Dict[str, Any]
    optimal_timing: Dict[str, Any]
    message_effectiveness: Dict[str, float]
    personalization_recommendations: List[str]
    next_suggested_actions: List[Dict[str, Any]]

class BehavioralTriggerData(BaseModel):
    """Data about behavioral triggers for coaching messages"""
    trigger_type: str
    trigger_description: str
    confidence_score: float
    recommended_message_types: List[CoachingMessageType]
    urgency_level: str
    context_data: Dict[str, Any]

class CoachingAnalyticsResponse(BaseModel):
    """Response containing coaching analytics data"""
    user_id: str
    time_period: str
    total_messages_sent: int
    total_messages_read: int
    total_messages_acted_on: int
    engagement_rate: float
    most_effective_message_types: List[Dict[str, Any]]
    optimal_send_times: List[int]
    behavioral_improvements: Dict[str, Any]
    streak_recovery_rate: float
    habit_formation_success_rate: float

class GenerateMessageRequest(BaseModel):
    """Request to generate a coaching message"""
    message_type: CoachingMessageType
    context: Dict[str, Any] = Field(default_factory=dict)
    priority_override: Optional[CoachingMessagePriority] = None
    schedule_time: Optional[datetime] = None
    force_send: bool = Field(default=False, description="Send even if frequency limits would prevent")

class BulkMessageRequest(BaseModel):
    """Request to send bulk coaching messages"""
    user_ids: List[str] = Field(..., min_items=1, max_items=1000)
    message_type: CoachingMessageType
    template_id: Optional[str] = None
    context: Dict[str, Any] = Field(default_factory=dict)
    priority: CoachingMessagePriority = Field(default=CoachingMessagePriority.MEDIUM)
    schedule_time: Optional[datetime] = None
    dry_run: bool = Field(default=False, description="Preview messages without sending")

class MessageTemplateData(BaseModel):
    """Data model for message templates"""
    template_id: str
    message_type: CoachingMessageType
    name: str
    description: str
    title_template: str
    message_template: str
    action_text_template: Optional[str] = None
    tone: CoachingMessageTone
    priority: CoachingMessagePriority
    min_user_age_days: int
    max_user_age_days: Optional[int] = None
    min_activity_count: int
    user_segments: List[str]
    premium_only: bool
    cooldown_hours: int
    expiry_hours: int
    optimal_hours: List[int]
    avoid_days: List[int]
    usage_count: int
    average_engagement: float
    is_active: bool

class CreateTemplateRequest(BaseModel):
    """Request to create a message template"""
    template_id: str = Field(..., min_length=3, max_length=50)
    message_type: CoachingMessageType
    name: str = Field(..., min_length=5, max_length=100)
    description: str = Field(..., min_length=10, max_length=500)
    title_template: str = Field(..., min_length=5, max_length=200)
    message_template: str = Field(..., min_length=10, max_length=1000)
    action_text_template: Optional[str] = Field(None, max_length=50)
    tone: CoachingMessageTone = Field(default=CoachingMessageTone.ENCOURAGING)
    priority: CoachingMessagePriority = Field(default=CoachingMessagePriority.MEDIUM)
    min_user_age_days: int = Field(default=0, ge=0)
    max_user_age_days: Optional[int] = Field(None, ge=0)
    min_activity_count: int = Field(default=0, ge=0)
    user_segments: List[str] = Field(default_factory=list)
    premium_only: bool = Field(default=False)
    cooldown_hours: int = Field(default=24, ge=1, le=168)  # 1 hour to 1 week
    expiry_hours: int = Field(default=48, ge=1, le=720)  # 1 hour to 30 days
    optimal_hours: List[int] = Field(default_factory=list, min_items=0, max_items=24)
    avoid_days: List[int] = Field(default_factory=list, min_items=0, max_items=7)

class MessageDeliveryStats(BaseModel):
    """Statistics about message delivery"""
    total_scheduled: int
    total_sent: int
    total_delivered: int
    total_read: int
    total_acted_on: int
    total_expired: int
    total_cancelled: int
    delivery_rate: float
    read_rate: float
    action_rate: float
    average_delivery_time_minutes: float

class CoachingSystemHealthResponse(BaseModel):
    """Response containing coaching system health metrics"""
    system_status: str
    active_messages: int
    pending_messages: int
    scheduled_messages: int
    failed_messages: int
    average_engagement_rate: float
    message_delivery_health: MessageDeliveryStats
    user_satisfaction_score: float
    last_health_check: datetime
    performance_metrics: Dict[str, Any]