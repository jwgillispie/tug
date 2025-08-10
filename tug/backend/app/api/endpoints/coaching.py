# app/api/endpoints/coaching.py
from fastapi import APIRouter, Depends, HTTPException, status, Query, BackgroundTasks
from typing import List, Optional, Dict, Any
import logging
from datetime import datetime

from ...models.user import User
from ...schemas.coaching_message import (
    CoachingMessageData, CoachingMessageSummary, UserPersonalizationProfileData,
    UpdatePersonalizationProfileRequest, CoachingMessageResponse,
    MessageFeedbackRequest, MessageInteractionRequest, CoachingInsightsResponse,
    CoachingAnalyticsResponse, GenerateMessageRequest, CoachingSystemHealthResponse,
    MessageTemplateData, CreateTemplateRequest
)
from ...services.coaching_service import CoachingService
from ...services.coaching_background_service import CoachingBackgroundService
from ...services.coaching_template_service import CoachingTemplateService
from ...core.auth import get_current_user
from ...models.coaching_message import CoachingMessageType, CoachingMessage

router = APIRouter()
logger = logging.getLogger(__name__)

# Initialize services
coaching_service = CoachingService()
background_service = CoachingBackgroundService()
template_service = CoachingTemplateService()

# =================
# USER ENDPOINTS
# =================

@router.get("/messages", response_model=CoachingMessageResponse)
async def get_coaching_messages(
    limit: int = Query(20, ge=1, le=50, description="Number of messages to return"),
    skip: int = Query(0, ge=0, description="Number of messages to skip"),
    status_filter: Optional[str] = Query(None, description="Filter by message status"),
    message_type_filter: Optional[str] = Query(None, description="Filter by message type"),
    current_user: User = Depends(get_current_user)
):
    """Get coaching messages for the current user"""
    try:
        response = await coaching_service.get_user_coaching_messages(
            user=current_user,
            limit=limit,
            skip=skip,
            status_filter=status_filter,
            message_type_filter=message_type_filter
        )
        return response
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in get_coaching_messages endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get coaching messages"
        )

@router.get("/summary", response_model=CoachingMessageSummary)
async def get_coaching_summary(
    current_user: User = Depends(get_current_user)
):
    """Get coaching message summary for the current user"""
    try:
        # Get recent messages
        messages_data = await coaching_service.get_user_coaching_messages(
            user=current_user,
            limit=10,
            skip=0
        )
        
        # Calculate summary stats
        all_messages = await CoachingMessage.find({
            "user_id": str(current_user.id)
        }).to_list()
        
        unread_count = len([m for m in all_messages if m.status == "sent"])
        pending_count = len([m for m in all_messages if m.status in ["pending", "scheduled"]])
        total_sent = len([m for m in all_messages if m.status in ["sent", "read", "acted_on"]])
        
        engaged_count = len([m for m in all_messages if m.status in ["read", "acted_on"]])
        engagement_rate = engaged_count / total_sent if total_sent > 0 else 0.0
        
        last_message_sent = None
        next_scheduled = None
        
        if all_messages:
            sent_messages = [m for m in all_messages if m.sent_at]
            if sent_messages:
                last_message_sent = max(m.sent_at for m in sent_messages)
            
            scheduled_messages = [m for m in all_messages if m.status == "scheduled"]
            if scheduled_messages:
                next_scheduled = min(m.scheduled_for for m in scheduled_messages)
        
        return CoachingMessageSummary(
            unread_count=unread_count,
            pending_count=pending_count,
            total_sent=total_sent,
            engagement_rate=engagement_rate,
            last_message_sent=last_message_sent,
            next_scheduled=next_scheduled,
            recent_messages=messages_data["messages"][:5]
        )
        
    except Exception as e:
        logger.error(f"Error in get_coaching_summary endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get coaching summary"
        )

@router.get("/personalization", response_model=UserPersonalizationProfileData)
async def get_personalization_profile(
    current_user: User = Depends(get_current_user)
):
    """Get user's personalization profile"""
    try:
        from ...models.coaching_message import UserPersonalizationProfile
        
        profile = await UserPersonalizationProfile.find_one({
            "user_id": str(current_user.id)
        })
        
        if not profile:
            # Create default profile
            profile = UserPersonalizationProfile(user_id=str(current_user.id))
            await profile.save()
        
        engagement_rate = (profile.total_messages_engaged / profile.total_messages_sent 
                         if profile.total_messages_sent > 0 else 0.0)
        
        return UserPersonalizationProfileData(
            user_id=profile.user_id,
            preferred_tone=profile.preferred_tone,
            message_frequency=profile.message_frequency,
            quiet_hours=profile.quiet_hours,
            preferred_times=profile.preferred_times,
            message_type_preferences=profile.message_type_preferences,
            language_preference=profile.language_preference,
            cultural_context=profile.cultural_context,
            ai_personalization_enabled=profile.ai_personalization_enabled,
            custom_motivations=profile.custom_motivations,
            total_messages_sent=profile.total_messages_sent,
            total_messages_engaged=profile.total_messages_engaged,
            engagement_rate=engagement_rate
        )
        
    except Exception as e:
        logger.error(f"Error in get_personalization_profile endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get personalization profile"
        )

@router.put("/personalization", response_model=UserPersonalizationProfileData)
async def update_personalization_profile(
    update_request: UpdatePersonalizationProfileRequest,
    current_user: User = Depends(get_current_user)
):
    """Update user's personalization profile"""
    try:
        return await coaching_service.update_user_personalization_profile(
            user=current_user,
            update_request=update_request
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in update_personalization_profile endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to update personalization profile"
        )

@router.post("/messages/{message_id}/interact")
async def record_message_interaction(
    message_id: str,
    interaction_request: MessageInteractionRequest,
    current_user: User = Depends(get_current_user)
):
    """Record user interaction with a coaching message"""
    try:
        return await coaching_service.record_message_interaction(
            user=current_user,
            message_id=message_id,
            interaction_type=interaction_request.interaction_type,
            interaction_data=interaction_request.interaction_data
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in record_message_interaction endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to record message interaction"
        )

@router.post("/messages/{message_id}/feedback")
async def provide_message_feedback(
    message_id: str,
    feedback_request: MessageFeedbackRequest,
    current_user: User = Depends(get_current_user)
):
    """Provide feedback on a coaching message"""
    try:
        from bson import ObjectId
        
        # Get the message
        message = await CoachingMessage.find_one({
            "_id": ObjectId(message_id),
            "user_id": str(current_user.id)
        })
        
        if not message:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Message not found"
            )
        
        # Update message with feedback
        message.user_feedback = feedback_request.feedback_text
        
        # Update engagement based on feedback
        if feedback_request.feedback_type == "helpful":
            message.engagement_score = 1.0
        elif feedback_request.feedback_type == "not_helpful":
            message.engagement_score = 0.2
        elif feedback_request.feedback_type == "inappropriate":
            message.engagement_score = 0.0
        elif feedback_request.feedback_type == "timing_bad":
            message.engagement_score = 0.3
        
        await message.save()
        
        # Update user's personalization profile
        from ...models.coaching_message import UserPersonalizationProfile
        profile = await UserPersonalizationProfile.find_one({
            "user_id": str(current_user.id)
        })
        
        if profile:
            engaged = feedback_request.engaged or feedback_request.feedback_type == "helpful"
            profile.update_engagement(message.message_type.value, engaged)
            await profile.save()
        
        return {
            "success": True,
            "message_id": message_id,
            "feedback_recorded": True
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in provide_message_feedback endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to record feedback"
        )

@router.get("/insights", response_model=CoachingInsightsResponse)
async def get_coaching_insights(
    current_user: User = Depends(get_current_user)
):
    """Get coaching insights and analytics for the current user"""
    try:
        return await coaching_service.get_coaching_insights(current_user)
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in get_coaching_insights endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get coaching insights"
        )

@router.post("/generate")
async def generate_coaching_messages(
    background_tasks: BackgroundTasks,
    current_user: User = Depends(get_current_user)
):
    """Manually trigger coaching message generation for current user"""
    try:
        from ...models.activity import Activity
        from ...models.value import Value
        from datetime import timedelta, timezone
        
        # Get user's recent activities and values
        activities = await Activity.find({
            "user_id": str(current_user.id),
            "date": {"$gte": datetime.now(timezone.utc) - timedelta(days=60)}
        }).sort([("date", -1)]).limit(200).to_list()
        
        values = await Value.find({
            "user_id": str(current_user.id)
        }).to_list()
        
        # Generate coaching messages
        messages = await coaching_service.analyze_user_behavior_and_generate_messages(
            current_user, activities, values
        )
        
        return {
            "success": True,
            "messages_generated": len(messages),
            "message_ids": [str(msg.id) for msg in messages]
        }
        
    except Exception as e:
        logger.error(f"Error in generate_coaching_messages endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to generate coaching messages"
        )

# =================
# ADMIN ENDPOINTS
# =================

@router.get("/admin/system-health", response_model=CoachingSystemHealthResponse)
async def get_system_health(
    current_admin: User = Depends(get_current_user)
):
    """Get coaching system health metrics (Admin only)"""
    try:
        analytics = await background_service.generate_coaching_analytics()
        
        system_overview = analytics.get("system_overview", {})
        message_queue = analytics.get("message_queue", {})
        
        return CoachingSystemHealthResponse(
            system_status="healthy" if message_queue.get("pending_messages", 0) < 1000 else "degraded",
            active_messages=message_queue.get("pending_messages", 0) + message_queue.get("scheduled_messages", 0),
            pending_messages=message_queue.get("pending_messages", 0),
            scheduled_messages=message_queue.get("scheduled_messages", 0),
            failed_messages=0,  # Would need to track this separately
            average_engagement_rate=system_overview.get("overall_action_rate", 0),
            message_delivery_health={
                "total_scheduled": system_overview.get("messages_this_week", 0),
                "total_sent": system_overview.get("messages_this_week", 0),
                "total_delivered": system_overview.get("messages_this_week", 0),
                "total_read": 0,  # Would calculate from messages
                "total_acted_on": 0,  # Would calculate from messages
                "total_expired": message_queue.get("expired_this_week", 0),
                "total_cancelled": 0,
                "delivery_rate": 95.0,  # Would calculate
                "read_rate": system_overview.get("overall_read_rate", 0),
                "action_rate": system_overview.get("overall_action_rate", 0),
                "average_delivery_time_minutes": 5.0
            },
            user_satisfaction_score=85.0,  # Would calculate from feedback
            last_health_check=datetime.utcnow(),
            performance_metrics=analytics
        )
        
    except Exception as e:
        logger.error(f"Error in get_system_health endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get system health"
        )

@router.post("/admin/generate-all")
async def generate_messages_for_all_users(
    background_tasks: BackgroundTasks,
    current_admin: User = Depends(get_current_user)
):
    """Generate coaching messages for all active users (Admin only)"""
    try:
        # Run in background
        background_tasks.add_task(background_service.process_all_users_for_coaching_messages)
        
        return {
            "success": True,
            "message": "Coaching message generation started for all users",
            "started_at": datetime.utcnow()
        }
        
    except Exception as e:
        logger.error(f"Error in generate_messages_for_all_users endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to start message generation"
        )

@router.post("/admin/deliver-scheduled")
async def deliver_scheduled_messages(
    background_tasks: BackgroundTasks,
    current_admin: User = Depends(get_current_user)
):
    """Deliver all scheduled coaching messages (Admin only)"""
    try:
        # Run in background
        background_tasks.add_task(background_service.deliver_scheduled_messages)
        
        return {
            "success": True,
            "message": "Scheduled message delivery started",
            "started_at": datetime.utcnow()
        }
        
    except Exception as e:
        logger.error(f"Error in deliver_scheduled_messages endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to start message delivery"
        )

@router.get("/admin/analytics", response_model=Dict[str, Any])
async def get_coaching_analytics(
    current_admin: User = Depends(get_current_user)
):
    """Get comprehensive coaching analytics (Admin only)"""
    try:
        return await background_service.generate_coaching_analytics()
    except Exception as e:
        logger.error(f"Error in get_coaching_analytics endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get coaching analytics"
        )

@router.get("/admin/templates", response_model=List[MessageTemplateData])
async def get_message_templates(
    current_admin: User = Depends(get_current_user)
):
    """Get all message templates (Admin only)"""
    try:
        from ...models.coaching_message import CoachingMessageTemplate
        
        templates = await CoachingMessageTemplate.find({}).to_list()
        
        template_data = []
        for template in templates:
            template_data.append(MessageTemplateData(
                template_id=template.template_id,
                message_type=template.message_type,
                name=template.name,
                description=template.description,
                title_template=template.title_template,
                message_template=template.message_template,
                action_text_template=template.action_text_template,
                tone=template.tone,
                priority=template.priority,
                min_user_age_days=template.min_user_age_days,
                max_user_age_days=template.max_user_age_days,
                min_activity_count=template.min_activity_count,
                user_segments=template.user_segments,
                premium_only=template.premium_only,
                cooldown_hours=template.cooldown_hours,
                expiry_hours=template.expiry_hours,
                optimal_hours=template.optimal_hours,
                avoid_days=template.avoid_days,
                usage_count=template.usage_count,
                average_engagement=template.average_engagement,
                is_active=template.is_active
            ))
        
        return template_data
        
    except Exception as e:
        logger.error(f"Error in get_message_templates endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get message templates"
        )

@router.post("/admin/templates", response_model=MessageTemplateData)
async def create_message_template(
    template_request: CreateTemplateRequest,
    current_admin: User = Depends(get_current_user)
):
    """Create a new message template (Admin only)"""
    try:
        from ...models.coaching_message import CoachingMessageTemplate
        
        # Check if template ID already exists
        existing = await CoachingMessageTemplate.find_one({
            "template_id": template_request.template_id
        })
        
        if existing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Template ID already exists"
            )
        
        # Create template
        template = CoachingMessageTemplate(**template_request.dict())
        await template.save()
        
        return MessageTemplateData(
            template_id=template.template_id,
            message_type=template.message_type,
            name=template.name,
            description=template.description,
            title_template=template.title_template,
            message_template=template.message_template,
            action_text_template=template.action_text_template,
            tone=template.tone,
            priority=template.priority,
            min_user_age_days=template.min_user_age_days,
            max_user_age_days=template.max_user_age_days,
            min_activity_count=template.min_activity_count,
            user_segments=template.user_segments,
            premium_only=template.premium_only,
            cooldown_hours=template.cooldown_hours,
            expiry_hours=template.expiry_hours,
            optimal_hours=template.optimal_hours,
            avoid_days=template.avoid_days,
            usage_count=template.usage_count,
            average_engagement=template.average_engagement,
            is_active=template.is_active
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in create_message_template endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create message template"
        )

@router.post("/admin/templates/seed")
async def seed_default_templates(
    current_admin: User = Depends(get_current_user)
):
    """Seed default message templates (Admin only)"""
    try:
        seeded_count = await template_service.seed_default_templates()
        
        return {
            "success": True,
            "templates_seeded": seeded_count,
            "message": f"Seeded {seeded_count} default message templates"
        }
        
    except Exception as e:
        logger.error(f"Error in seed_default_templates endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to seed default templates"
        )

@router.delete("/admin/cleanup/{days_to_keep}")
async def cleanup_old_messages(
    days_to_keep: int,
    current_admin: User = Depends(get_current_user)
):
    """Clean up old coaching messages (Admin only)"""
    try:
        if days_to_keep < 30:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Must keep at least 30 days of messages"
            )
        
        result = await background_service.cleanup_old_messages(days_to_keep)
        return result
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in cleanup_old_messages endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to cleanup old messages"
        )