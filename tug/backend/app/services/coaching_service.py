# app/services/coaching_service.py
import logging
import asyncio
from typing import List, Dict, Any, Optional, Tuple
from datetime import datetime, timedelta, timezone
from collections import defaultdict
from fastapi import HTTPException, status
from bson import ObjectId

from ..models.user import User
from ..models.activity import Activity
from ..models.value import Value
from ..models.coaching_message import (
    CoachingMessage, CoachingMessageTemplate, UserPersonalizationProfile,
    CoachingMessageType, CoachingMessagePriority, CoachingMessageTone,
    CoachingMessageStatus
)
from ..schemas.coaching_message import (
    CoachingMessageData, CoachingMessageSummary, UserPersonalizationProfileData,
    UpdatePersonalizationProfileRequest, CoachingInsightsResponse,
    BehavioralTriggerData, CoachingAnalyticsResponse
)
from ..services.ml_prediction_service import MLPredictionService
from ..services.notification_service import NotificationService

logger = logging.getLogger(__name__)

class CoachingService:
    """Intelligent coaching message service with ML-powered personalization"""
    
    def __init__(self):
        self.ml_service = MLPredictionService()
        
        # Message type frequency limits (messages per day by type)
        self.frequency_limits = {
            CoachingMessageType.PROGRESS_ENCOURAGEMENT: 1,
            CoachingMessageType.MILESTONE_CELEBRATION: 3,
            CoachingMessageType.STREAK_ACHIEVEMENT: 2,
            CoachingMessageType.CONSISTENCY_RECOGNITION: 1,
            CoachingMessageType.STREAK_RECOVERY: 2,
            CoachingMessageType.STREAK_RISK_WARNING: 1,
            CoachingMessageType.STREAK_MOTIVATION: 1,
            CoachingMessageType.COMEBACK_SUPPORT: 1,
            CoachingMessageType.CHALLENGE_MOTIVATION: 1,
            CoachingMessageType.GOAL_SUGGESTION: 1,
            CoachingMessageType.HABIT_EXPANSION: 1,
            CoachingMessageType.DIFFICULTY_INCREASE: 1,
            CoachingMessageType.HABIT_TIP: 2,
            CoachingMessageType.WISDOM_INSIGHT: 1,
            CoachingMessageType.BEHAVIORAL_INSIGHT: 1,
            CoachingMessageType.TIMING_OPTIMIZATION: 1,
            CoachingMessageType.MORNING_MOTIVATION: 1,
            CoachingMessageType.EVENING_REFLECTION: 1,
            CoachingMessageType.WEEKEND_ENCOURAGEMENT: 2,
            CoachingMessageType.REACTIVATION: 1
        }
        
        # Global message frequency limits by user preference
        self.daily_limits = {
            "minimal": 1,
            "optimal": 3,
            "frequent": 5,
            "daily": 2
        }

    async def analyze_user_behavior_and_generate_messages(
        self,
        user: User,
        activities: List[Activity],
        values: List[Value]
    ) -> List[CoachingMessage]:
        """Analyze user behavior and generate appropriate coaching messages"""
        
        try:
            # Get user's personalization profile
            profile = await self._get_or_create_personalization_profile(user)
            
            # Get ML predictions for behavioral insights
            ml_predictions = await MLPredictionService.generate_comprehensive_predictions(
                user, activities, values
            )
            
            # Analyze behavioral triggers
            triggers = await self._analyze_behavioral_triggers(user, activities, values, ml_predictions)
            
            # Generate messages based on triggers
            generated_messages = []
            
            for trigger in triggers:
                # Check frequency limits and user preferences
                if await self._should_generate_message(user, trigger, profile):
                    messages = await self._generate_messages_for_trigger(
                        user, trigger, profile, ml_predictions, activities, values
                    )
                    generated_messages.extend(messages)
            
            # Apply personalization and scheduling optimization
            optimized_messages = await self._optimize_message_delivery(
                generated_messages, profile, ml_predictions
            )
            
            # Save messages to database
            saved_messages = []
            for message in optimized_messages:
                await message.save()
                saved_messages.append(message)
                
            logger.info(f"Generated {len(saved_messages)} coaching messages for user {user.id}")
            
            return saved_messages
            
        except Exception as e:
            logger.error(f"Error generating coaching messages for user {user.id}: {e}", exc_info=True)
            return []

    async def _analyze_behavioral_triggers(
        self,
        user: User,
        activities: List[Activity],
        values: List[Value],
        ml_predictions: Dict[str, Any]
    ) -> List[BehavioralTriggerData]:
        """Analyze user behavior and identify triggers for coaching messages"""
        
        triggers = []
        
        try:
            # 1. Streak Risk Analysis
            streak_risk = ml_predictions.get("streak_risk", {})
            if streak_risk.get("risk_level") == "high":
                triggers.append(BehavioralTriggerData(
                    trigger_type="streak_risk",
                    trigger_description=f"High risk of breaking {streak_risk.get('current_streak', 0)}-day streak",
                    confidence_score=0.9,
                    recommended_message_types=[
                        CoachingMessageType.STREAK_RISK_WARNING,
                        CoachingMessageType.STREAK_MOTIVATION
                    ],
                    urgency_level="high",
                    context_data={
                        "risk_level": streak_risk.get("risk_level"),
                        "current_streak": streak_risk.get("current_streak", 0),
                        "time_since_last_hours": streak_risk.get("time_since_last_activity_hours", 0),
                        "recommendations": streak_risk.get("recommendations", [])
                    }
                ))
            
            # 2. Milestone Achievement Detection
            if activities:
                recent_streaks = self._calculate_recent_streaks(activities)
                for streak_data in recent_streaks:
                    if self._is_milestone_worthy(streak_data["length"]):
                        triggers.append(BehavioralTriggerData(
                            trigger_type="milestone_achievement",
                            trigger_description=f"Achieved {streak_data['length']}-day streak",
                            confidence_score=1.0,
                            recommended_message_types=[
                                CoachingMessageType.MILESTONE_CELEBRATION,
                                CoachingMessageType.STREAK_ACHIEVEMENT
                            ],
                            urgency_level="medium",
                            context_data=streak_data
                        ))
            
            # 3. Progress Encouragement
            habit_formation = ml_predictions.get("habit_formation", {})
            if habit_formation.get("formation_probability", 0) > 70:
                triggers.append(BehavioralTriggerData(
                    trigger_type="strong_progress",
                    trigger_description="Strong habit formation progress detected",
                    confidence_score=habit_formation.get("confidence_score", 0) / 100,
                    recommended_message_types=[
                        CoachingMessageType.PROGRESS_ENCOURAGEMENT,
                        CoachingMessageType.CONSISTENCY_RECOGNITION
                    ],
                    urgency_level="low",
                    context_data={
                        "formation_probability": habit_formation.get("formation_probability"),
                        "key_factors": habit_formation.get("key_factors", []),
                        "recommendations": habit_formation.get("recommendations", [])
                    }
                ))
            
            # 4. Comeback Support
            if self._detect_comeback_pattern(activities):
                triggers.append(BehavioralTriggerData(
                    trigger_type="comeback",
                    trigger_description="User returning after break in activity",
                    confidence_score=0.8,
                    recommended_message_types=[
                        CoachingMessageType.COMEBACK_SUPPORT,
                        CoachingMessageType.REACTIVATION
                    ],
                    urgency_level="medium",
                    context_data=self._get_comeback_context(activities)
                ))
            
            # 5. Goal Recommendation Triggers
            goal_recommendations = ml_predictions.get("goal_recommendations", {})
            if goal_recommendations.get("recommended_goals"):
                triggers.append(BehavioralTriggerData(
                    trigger_type="goal_opportunity",
                    trigger_description="New goal opportunities identified",
                    confidence_score=goal_recommendations.get("confidence_score", 0) / 100,
                    recommended_message_types=[
                        CoachingMessageType.GOAL_SUGGESTION,
                        CoachingMessageType.HABIT_EXPANSION
                    ],
                    urgency_level="low",
                    context_data={
                        "recommended_goals": goal_recommendations.get("recommended_goals", []),
                        "top_performing_values": goal_recommendations.get("top_performing_values", [])
                    }
                ))
            
            # 6. Timing Optimization Triggers
            optimal_timing = ml_predictions.get("optimal_timing", {})
            if optimal_timing.get("confidence_score", 0) > 60:
                triggers.append(BehavioralTriggerData(
                    trigger_type="timing_optimization",
                    trigger_description="Optimal timing insights available",
                    confidence_score=optimal_timing.get("confidence_score", 0) / 100,
                    recommended_message_types=[
                        CoachingMessageType.TIMING_OPTIMIZATION,
                        CoachingMessageType.BEHAVIORAL_INSIGHT
                    ],
                    urgency_level="low",
                    context_data={
                        "peak_performance_time": optimal_timing.get("peak_performance_time"),
                        "peak_performance_day": optimal_timing.get("peak_performance_day"),
                        "optimal_hours": optimal_timing.get("optimal_hours", []),
                        "recommendations": optimal_timing.get("recommendations", [])
                    }
                ))
            
            # 7. Challenge and Growth Opportunities
            user_segment = ml_predictions.get("user_segmentation", {}).get("user_segment", "")
            if user_segment in ["Habit Master", "Quality Focused"] and len(activities) > 30:
                triggers.append(BehavioralTriggerData(
                    trigger_type="growth_challenge",
                    trigger_description="Ready for advanced challenges",
                    confidence_score=0.7,
                    recommended_message_types=[
                        CoachingMessageType.CHALLENGE_MOTIVATION,
                        CoachingMessageType.DIFFICULTY_INCREASE
                    ],
                    urgency_level="low",
                    context_data={
                        "user_segment": user_segment,
                        "activity_count": len(activities),
                        "segment_characteristics": ml_predictions.get("user_segmentation", {}).get("segment_characteristics", [])
                    }
                ))
            
            # 8. Weekend/Time-based Triggers
            now = datetime.now(timezone.utc)
            if now.weekday() >= 5:  # Weekend
                triggers.append(BehavioralTriggerData(
                    trigger_type="weekend_motivation",
                    trigger_description="Weekend motivation opportunity",
                    confidence_score=0.6,
                    recommended_message_types=[
                        CoachingMessageType.WEEKEND_ENCOURAGEMENT
                    ],
                    urgency_level="low",
                    context_data={"day_of_week": now.weekday()}
                ))
            
            # 9. Morning/Evening Contextual Triggers
            current_hour = now.hour
            if 6 <= current_hour <= 10:
                triggers.append(BehavioralTriggerData(
                    trigger_type="morning_opportunity",
                    trigger_description="Morning motivation window",
                    confidence_score=0.5,
                    recommended_message_types=[
                        CoachingMessageType.MORNING_MOTIVATION
                    ],
                    urgency_level="low",
                    context_data={"hour": current_hour}
                ))
            elif 17 <= current_hour <= 21:
                triggers.append(BehavioralTriggerData(
                    trigger_type="evening_reflection",
                    trigger_description="Evening reflection opportunity",
                    confidence_score=0.5,
                    recommended_message_types=[
                        CoachingMessageType.EVENING_REFLECTION
                    ],
                    urgency_level="low",
                    context_data={"hour": current_hour}
                ))
                
            return triggers
            
        except Exception as e:
            logger.error(f"Error analyzing behavioral triggers: {e}", exc_info=True)
            return []

    async def _should_generate_message(
        self,
        user: User,
        trigger: BehavioralTriggerData,
        profile: UserPersonalizationProfile
    ) -> bool:
        """Determine if a message should be generated based on frequency limits and preferences"""
        
        try:
            # Check if user wants this type of message
            message_types = [msg_type.value for msg_type in trigger.recommended_message_types]
            
            # Get average preference for message types
            avg_preference = sum(
                profile.message_type_preferences.get(msg_type, 0.5) 
                for msg_type in message_types
            ) / len(message_types)
            
            if avg_preference < 0.1:  # User disabled this type
                return False
            
            # Check daily global limit
            today = datetime.now(timezone.utc).date()
            daily_limit = self.daily_limits.get(profile.message_frequency, 3)
            
            messages_today = await CoachingMessage.find({
                "user_id": str(user.id),
                "created_at": {
                    "$gte": datetime.combine(today, datetime.min.time()),
                    "$lt": datetime.combine(today + timedelta(days=1), datetime.min.time())
                },
                "status": {"$nin": ["cancelled", "expired"]}
            }).count()
            
            if messages_today >= daily_limit:
                return False
            
            # Check specific message type frequency limits
            for msg_type in trigger.recommended_message_types:
                type_limit = self.frequency_limits.get(msg_type, 1)
                
                type_messages_today = await CoachingMessage.find({
                    "user_id": str(user.id),
                    "message_type": msg_type,
                    "created_at": {
                        "$gte": datetime.combine(today, datetime.min.time()),
                        "$lt": datetime.combine(today + timedelta(days=1), datetime.min.time())
                    },
                    "status": {"$nin": ["cancelled", "expired"]}
                }).count()
                
                if type_messages_today >= type_limit:
                    continue  # Skip this message type, but try others
                else:
                    return True  # At least one message type is under limit
            
            return False  # All message types are at limit
            
        except Exception as e:
            logger.error(f"Error checking message generation criteria: {e}")
            return False

    async def _generate_messages_for_trigger(
        self,
        user: User,
        trigger: BehavioralTriggerData,
        profile: UserPersonalizationProfile,
        ml_predictions: Dict[str, Any],
        activities: List[Activity],
        values: List[Value]
    ) -> List[CoachingMessage]:
        """Generate personalized coaching messages for a behavioral trigger"""
        
        try:
            messages = []
            
            for message_type in trigger.recommended_message_types:
                # Check if we should generate this specific message type
                if not await self._should_generate_specific_message_type(
                    user, message_type, profile, trigger
                ):
                    continue
                
                # Find appropriate template
                template = await self._find_best_template(
                    message_type, user, profile, trigger
                )
                
                if not template:
                    # Generate message without template (fallback)
                    message = await self._generate_message_fallback(
                        user, message_type, trigger, profile, ml_predictions
                    )
                else:
                    # Generate message from template
                    context = self._build_message_context(
                        user, trigger, ml_predictions, activities, values
                    )
                    message = template.generate_message(str(user.id), context, profile)
                
                if message:
                    # Enhance with ML predictions and trigger data
                    message.behavioral_trigger = trigger.trigger_type
                    message.ml_confidence_score = trigger.confidence_score
                    message.expected_engagement_score = profile.engagement_scores.get(
                        message_type.value, 0.5
                    )
                    
                    # Set priority based on trigger urgency
                    if trigger.urgency_level == "high":
                        message.priority = CoachingMessagePriority.URGENT
                    elif trigger.urgency_level == "medium":
                        message.priority = CoachingMessagePriority.HIGH
                    else:
                        message.priority = CoachingMessagePriority.MEDIUM
                    
                    messages.append(message)
            
            return messages
            
        except Exception as e:
            logger.error(f"Error generating messages for trigger: {e}", exc_info=True)
            return []

    async def _should_generate_specific_message_type(
        self,
        user: User,
        message_type: CoachingMessageType,
        profile: UserPersonalizationProfile,
        trigger: BehavioralTriggerData
    ) -> bool:
        """Check if a specific message type should be generated"""
        
        try:
            # Check user preference for this message type
            preference = profile.message_type_preferences.get(message_type.value, 0.5)
            if preference < 0.1:
                return False
            
            # Check cooldown period for this message type
            template = await CoachingMessageTemplate.find_one({
                "message_type": message_type,
                "is_active": True
            })
            
            if template:
                cooldown_hours = template.cooldown_hours
                cutoff_time = datetime.now(timezone.utc) - timedelta(hours=cooldown_hours)
                
                recent_message = await CoachingMessage.find_one({
                    "user_id": str(user.id),
                    "message_type": message_type,
                    "created_at": {"$gte": cutoff_time},
                    "status": {"$nin": ["cancelled", "expired"]}
                })
                
                if recent_message:
                    return False
            
            # Check trigger confidence threshold
            min_confidence = 0.3
            if message_type in [
                CoachingMessageType.STREAK_RISK_WARNING,
                CoachingMessageType.COMEBACK_SUPPORT
            ]:
                min_confidence = 0.7  # Higher threshold for important messages
            
            if trigger.confidence_score < min_confidence:
                return False
            
            return True
            
        except Exception as e:
            logger.error(f"Error checking specific message type generation: {e}")
            return False

    def _build_message_context(
        self,
        user: User,
        trigger: BehavioralTriggerData,
        ml_predictions: Dict[str, Any],
        activities: List[Activity],
        values: List[Value]
    ) -> Dict[str, Any]:
        """Build context dictionary for message template personalization"""
        
        context = {
            "user_name": user.display_name,
            "user_first_name": user.display_name.split()[0] if user.display_name else "there",
            "trigger_type": trigger.trigger_type,
            "confidence_score": round(trigger.confidence_score * 100),
            "current_date": datetime.now().strftime("%B %d"),
            "current_day": datetime.now().strftime("%A"),
            "total_activities": len(activities),
            "total_values": len(values)
        }
        
        # Add trigger-specific context
        context.update(trigger.context_data)
        
        # Add ML prediction context
        if "streak_risk" in ml_predictions:
            streak_data = ml_predictions["streak_risk"]
            context.update({
                "current_streak": streak_data.get("current_streak", 0),
                "streak_days": streak_data.get("current_streak", 0),
                "time_since_last": round(streak_data.get("time_since_last_activity_hours", 0), 1),
                "risk_level": streak_data.get("risk_level", "medium")
            })
        
        if "habit_formation" in ml_predictions:
            habit_data = ml_predictions["habit_formation"]
            context.update({
                "formation_probability": round(habit_data.get("formation_probability", 50)),
                "habit_confidence": round(habit_data.get("confidence_score", 50))
            })
        
        if "optimal_timing" in ml_predictions:
            timing_data = ml_predictions["optimal_timing"]
            context.update({
                "peak_time": timing_data.get("peak_performance_time", "9:00 AM"),
                "peak_day": timing_data.get("peak_performance_day", "Monday")
            })
        
        if "user_segmentation" in ml_predictions:
            segment_data = ml_predictions["user_segmentation"]
            context.update({
                "user_segment": segment_data.get("user_segment", "Getting Started"),
                "segment_description": segment_data.get("segment_description", "")
            })
        
        # Add activity patterns
        if activities:
            recent_activities = [a for a in activities if a.date >= datetime.now(timezone.utc) - timedelta(days=7)]
            context.update({
                "recent_activity_count": len(recent_activities),
                "avg_daily_activities": round(len(recent_activities) / 7, 1),
                "consistency_this_week": len(set(a.date.date() for a in recent_activities))
            })
        
        return context

    async def _find_best_template(
        self,
        message_type: CoachingMessageType,
        user: User,
        profile: UserPersonalizationProfile,
        trigger: BehavioralTriggerData
    ) -> Optional[CoachingMessageTemplate]:
        """Find the best message template for the given context"""
        
        try:
            # Calculate user age in days
            user_age_days = (datetime.now(timezone.utc) - user.created_at).days
            
            # Get user segment from recent ML predictions if available
            user_segments = [ml_predictions.get("user_segmentation", {}).get("user_segment", "")]
            
            # Build query criteria
            query = {
                "message_type": message_type,
                "is_active": True,
                "min_user_age_days": {"$lte": user_age_days}
            }
            
            # Add optional criteria
            if user.subscription_tier != "free":
                query["$or"] = [
                    {"premium_only": False},
                    {"premium_only": True}
                ]
            else:
                query["premium_only"] = False
            
            # Find matching templates
            templates = await CoachingMessageTemplate.find(query).to_list()
            
            if not templates:
                return None
            
            # Score templates based on fit
            scored_templates = []
            for template in templates:
                score = 0.0
                
                # Base score from engagement history
                score += template.average_engagement * 0.4
                
                # User segment match
                if any(seg in template.user_segments for seg in user_segments if seg):
                    score += 0.3
                elif not template.user_segments:  # Universal template
                    score += 0.2
                
                # Tone preference match
                if template.tone == profile.preferred_tone:
                    score += 0.2
                
                # Trigger confidence bonus
                score += trigger.confidence_score * 0.1
                
                scored_templates.append((template, score))
            
            # Return highest scoring template
            scored_templates.sort(key=lambda x: x[1], reverse=True)
            return scored_templates[0][0] if scored_templates else None
            
        except Exception as e:
            logger.error(f"Error finding best template: {e}")
            return None

    async def _generate_message_fallback(
        self,
        user: User,
        message_type: CoachingMessageType,
        trigger: BehavioralTriggerData,
        profile: UserPersonalizationProfile,
        ml_predictions: Dict[str, Any]
    ) -> Optional[CoachingMessage]:
        """Generate message without template as fallback"""
        
        try:
            context = trigger.context_data
            user_name = user.display_name.split()[0] if user.display_name else "there"
            
            # Define fallback message content by type
            fallback_messages = {
                CoachingMessageType.PROGRESS_ENCOURAGEMENT: {
                    "title": f"Great progress, {user_name}! 🌟",
                    "message": f"You're building something amazing with your consistent efforts. Your dedication to personal growth is inspiring!",
                    "action_text": "Keep Going"
                },
                CoachingMessageType.STREAK_RISK_WARNING: {
                    "title": f"Don't break the chain! ⏰",
                    "message": f"Your {context.get('current_streak', 0)}-day streak is at risk. A quick 5-minute session can keep your momentum going!",
                    "action_text": "Log Activity"
                },
                CoachingMessageType.MILESTONE_CELEBRATION: {
                    "title": f"Milestone achieved! 🎉",
                    "message": f"Congratulations on reaching {context.get('length', 0)} days of consistent practice. You're proving that small steps lead to big changes!",
                    "action_text": "Celebrate"
                },
                CoachingMessageType.COMEBACK_SUPPORT: {
                    "title": f"Welcome back, {user_name}! 💪",
                    "message": "Every champion faces setbacks. What matters is getting back up. You're here now, and that's what counts.",
                    "action_text": "Start Fresh"
                },
                CoachingMessageType.GOAL_SUGGESTION: {
                    "title": f"Ready for something new? 🚀",
                    "message": "Based on your progress, you might be ready to expand your practice. Small additions can lead to big transformations.",
                    "action_text": "Explore Goals"
                }
            }
            
            fallback = fallback_messages.get(message_type)
            if not fallback:
                return None
            
            # Create message
            scheduled_time = datetime.now(timezone.utc) + timedelta(minutes=5)
            expires_at = scheduled_time + timedelta(hours=48)
            
            message = CoachingMessage(
                user_id=str(user.id),
                message_type=message_type,
                priority=CoachingMessagePriority.MEDIUM,
                tone=profile.preferred_tone,
                title=fallback["title"],
                message=fallback["message"],
                action_text=fallback["action_text"],
                personalization_context=context,
                scheduled_for=scheduled_time,
                expires_at=expires_at,
                behavioral_trigger=trigger.trigger_type,
                ml_confidence_score=trigger.confidence_score
            )
            
            return message
            
        except Exception as e:
            logger.error(f"Error generating fallback message: {e}")
            return None

    async def _optimize_message_delivery(
        self,
        messages: List[CoachingMessage],
        profile: UserPersonalizationProfile,
        ml_predictions: Dict[str, Any]
    ) -> List[CoachingMessage]:
        """Optimize message delivery timing and personalization"""
        
        try:
            if not messages:
                return messages
            
            # Sort messages by priority and confidence
            messages.sort(key=lambda m: (
                {"urgent": 4, "high": 3, "medium": 2, "low": 1}[m.priority.value],
                m.ml_confidence_score
            ), reverse=True)
            
            # Spread messages across time to avoid overwhelming user
            now = datetime.now(timezone.utc)
            optimal_times = profile.preferred_times or [9, 18]
            quiet_hours = profile.quiet_hours
            
            scheduled_times = []
            for i, message in enumerate(messages):
                # Calculate optimal send time
                if message.priority == CoachingMessagePriority.URGENT:
                    # Send urgent messages ASAP (but respect quiet hours if possible)
                    send_time = now + timedelta(minutes=5 + i * 2)
                    if send_time.hour in quiet_hours and len(optimal_times) > 0:
                        # Try to find next non-quiet hour
                        for hour in optimal_times:
                            potential_time = send_time.replace(hour=hour, minute=0, second=0)
                            if potential_time > now and hour not in quiet_hours:
                                send_time = potential_time
                                break
                else:
                    # Find next optimal time slot
                    base_delay = i * 120  # 2 hours between messages
                    send_time = self._find_next_optimal_time(
                        now + timedelta(minutes=base_delay),
                        optimal_times,
                        quiet_hours,
                        scheduled_times
                    )
                
                message.scheduled_for = send_time
                scheduled_times.append(send_time)
            
            return messages
            
        except Exception as e:
            logger.error(f"Error optimizing message delivery: {e}")
            return messages

    def _find_next_optimal_time(
        self,
        base_time: datetime,
        optimal_hours: List[int],
        quiet_hours: List[int],
        avoid_times: List[datetime]
    ) -> datetime:
        """Find next optimal time to send message"""
        
        try:
            # Start with base time
            candidate_time = base_time
            
            # If current hour is optimal and not quiet, use it
            if (candidate_time.hour in optimal_hours and 
                candidate_time.hour not in quiet_hours and
                not self._time_conflicts_with_existing(candidate_time, avoid_times)):
                return candidate_time
            
            # Find next optimal hour
            for _ in range(168):  # Search up to 1 week ahead
                for hour in sorted(optimal_hours):
                    candidate = candidate_time.replace(hour=hour, minute=0, second=0, microsecond=0)
                    
                    # Make sure it's in the future
                    if candidate <= base_time:
                        candidate += timedelta(days=1)
                    
                    # Check if time is good
                    if (hour not in quiet_hours and 
                        not self._time_conflicts_with_existing(candidate, avoid_times)):
                        return candidate
                
                # Move to next day if no good hour found
                candidate_time += timedelta(days=1)
            
            # Fallback: just use base time + 1 hour
            return base_time + timedelta(hours=1)
            
        except Exception as e:
            logger.error(f"Error finding optimal time: {e}")
            return base_time + timedelta(hours=1)

    def _time_conflicts_with_existing(
        self,
        candidate_time: datetime,
        existing_times: List[datetime],
        min_gap_minutes: int = 30
    ) -> bool:
        """Check if candidate time conflicts with existing scheduled times"""
        
        for existing_time in existing_times:
            time_diff = abs((candidate_time - existing_time).total_seconds() / 60)
            if time_diff < min_gap_minutes:
                return True
        return False

    # Utility methods for behavioral analysis
    
    def _calculate_recent_streaks(self, activities: List[Activity]) -> List[Dict[str, Any]]:
        """Calculate recent streak achievements"""
        
        if not activities:
            return []
        
        # Sort activities by date
        sorted_activities = sorted(activities, key=lambda x: x.date)
        
        # Group by date
        activity_dates = {}
        for activity in sorted_activities:
            date_key = activity.date.date()
            if date_key not in activity_dates:
                activity_dates[date_key] = []
            activity_dates[date_key].append(activity)
        
        # Calculate streaks
        streaks = []
        current_streak = 0
        current_start = None
        
        # Check last 30 days for streaks
        today = datetime.now().date()
        for i in range(30):
            check_date = today - timedelta(days=i)
            
            if check_date in activity_dates:
                if current_streak == 0:
                    current_start = check_date
                current_streak += 1
            else:
                if current_streak > 0:
                    streaks.append({
                        "length": current_streak,
                        "start_date": current_start,
                        "end_date": check_date + timedelta(days=1),
                        "activities": sum(len(activity_dates.get(d, [])) 
                                       for d in [current_start + timedelta(days=j) 
                                               for j in range(current_streak)])
                    })
                current_streak = 0
        
        # Add current ongoing streak if any
        if current_streak > 0:
            streaks.append({
                "length": current_streak,
                "start_date": current_start,
                "end_date": today,
                "activities": sum(len(activity_dates.get(d, [])) 
                               for d in [current_start + timedelta(days=j) 
                                       for j in range(current_streak)]),
                "is_current": True
            })
        
        return streaks

    def _is_milestone_worthy(self, streak_length: int) -> bool:
        """Determine if a streak length is worthy of milestone celebration"""
        
        milestone_days = [3, 7, 14, 21, 30, 60, 90, 180, 365]
        return streak_length in milestone_days

    def _detect_comeback_pattern(self, activities: List[Activity]) -> bool:
        """Detect if user is coming back after a break"""
        
        if len(activities) < 2:
            return False
        
        # Sort activities by date
        sorted_activities = sorted(activities, key=lambda x: x.date, reverse=True)
        
        # Check if there's recent activity after a gap
        now = datetime.now(timezone.utc)
        recent_activity = sorted_activities[0]
        
        # Must have activity in last 24 hours
        if (now - recent_activity.date).days > 1:
            return False
        
        # Look for gap of 3+ days before the recent activity
        for i in range(1, min(len(sorted_activities), 10)):  # Check last 10 activities
            time_gap = (sorted_activities[i-1].date - sorted_activities[i].date).days
            if time_gap >= 3:
                return True
        
        return False

    def _get_comeback_context(self, activities: List[Activity]) -> Dict[str, Any]:
        """Get context data for comeback pattern"""
        
        if not activities:
            return {}
        
        sorted_activities = sorted(activities, key=lambda x: x.date, reverse=True)
        
        # Find the gap
        gap_days = 0
        for i in range(1, min(len(sorted_activities), 10)):
            time_gap = (sorted_activities[i-1].date - sorted_activities[i].date).days
            if time_gap >= 3:
                gap_days = time_gap
                break
        
        # Count previous streak before the gap
        previous_streak = 0
        if len(sorted_activities) > 1:
            # This is simplified - in practice you'd calculate actual streak
            previous_streak = min(len(sorted_activities) - 1, 7)
        
        return {
            "gap_days": gap_days,
            "previous_streak": previous_streak,
            "total_activities": len(activities),
            "last_activity_date": sorted_activities[0].date.strftime("%B %d")
        }

    async def _get_or_create_personalization_profile(
        self, user: User
    ) -> UserPersonalizationProfile:
        """Get or create user's personalization profile"""
        
        try:
            profile = await UserPersonalizationProfile.find_one({"user_id": str(user.id)})
            
            if not profile:
                # Create new profile with defaults
                profile = UserPersonalizationProfile(
                    user_id=str(user.id),
                    preferred_tone=CoachingMessageTone.ENCOURAGING,
                    message_frequency="optimal"
                )
                await profile.save()
            
            return profile
            
        except Exception as e:
            logger.error(f"Error getting personalization profile: {e}")
            # Return default profile as fallback
            return UserPersonalizationProfile(
                user_id=str(user.id),
                preferred_tone=CoachingMessageTone.ENCOURAGING,
                message_frequency="optimal"
            )

    # Public API methods
    
    async def get_user_coaching_messages(
        self,
        user: User,
        limit: int = 20,
        skip: int = 0,
        status_filter: Optional[str] = None,
        message_type_filter: Optional[str] = None
    ) -> Dict[str, Any]:
        """Get coaching messages for a user"""
        
        try:
            # Build query
            query = {"user_id": str(user.id)}
            
            if status_filter:
                query["status"] = status_filter
                
            if message_type_filter:
                query["message_type"] = message_type_filter
            
            # Get messages
            messages = await CoachingMessage.find(query)\
                .sort([("created_at", -1)])\
                .skip(skip)\
                .limit(limit)\
                .to_list()
            
            # Get total count
            total_count = await CoachingMessage.find(query).count()
            
            # Convert to response format
            message_data = []
            for msg in messages:
                message_data.append(CoachingMessageData(
                    id=str(msg.id),
                    user_id=msg.user_id,
                    message_type=msg.message_type,
                    priority=msg.priority,
                    tone=msg.tone,
                    title=msg.title,
                    message=msg.message,
                    action_text=msg.action_text,
                    action_url=msg.action_url,
                    status=msg.status,
                    scheduled_for=msg.scheduled_for,
                    expires_at=msg.expires_at,
                    created_at=msg.created_at,
                    sent_at=msg.sent_at,
                    read_at=msg.read_at,
                    acted_on_at=msg.acted_on_at,
                    ml_confidence_score=msg.ml_confidence_score,
                    expected_engagement_score=msg.expected_engagement_score,
                    behavioral_trigger=msg.behavioral_trigger,
                    ab_test_variant=msg.ab_test_variant,
                    delivery_channel=msg.delivery_channel,
                    engagement_score=msg.engagement_score
                ))
            
            # Calculate engagement stats
            sent_messages = [m for m in messages if m.status in [
                CoachingMessageStatus.SENT, 
                CoachingMessageStatus.READ, 
                CoachingMessageStatus.ACTED_ON
            ]]
            
            engagement_stats = {}
            if sent_messages:
                read_count = len([m for m in sent_messages if m.status in [
                    CoachingMessageStatus.READ, CoachingMessageStatus.ACTED_ON
                ]])
                acted_count = len([m for m in sent_messages if m.status == CoachingMessageStatus.ACTED_ON])
                
                engagement_stats = {
                    "total_sent": len(sent_messages),
                    "read_count": read_count,
                    "acted_count": acted_count,
                    "read_rate": read_count / len(sent_messages) if sent_messages else 0,
                    "action_rate": acted_count / len(sent_messages) if sent_messages else 0
                }
            
            return {
                "messages": message_data,
                "has_more": len(message_data) == limit,
                "total_count": total_count,
                "engagement_stats": engagement_stats
            }
            
        except Exception as e:
            logger.error(f"Error getting user coaching messages: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to get coaching messages"
            )

    async def update_user_personalization_profile(
        self,
        user: User,
        update_request: UpdatePersonalizationProfileRequest
    ) -> UserPersonalizationProfileData:
        """Update user's personalization profile"""
        
        try:
            profile = await self._get_or_create_personalization_profile(user)
            
            # Update fields
            update_data = update_request.dict(exclude_unset=True)
            
            for field, value in update_data.items():
                setattr(profile, field, value)
            
            profile.updated_at = datetime.utcnow()
            await profile.save()
            
            # Return updated profile
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
            logger.error(f"Error updating personalization profile: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to update personalization profile"
            )

    async def record_message_interaction(
        self,
        user: User,
        message_id: str,
        interaction_type: str,
        interaction_data: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """Record user interaction with a coaching message"""
        
        try:
            # Get the message
            message = await CoachingMessage.find_one({
                "_id": ObjectId(message_id),
                "user_id": str(user.id)
            })
            
            if not message:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Message not found"
                )
            
            # Update message status based on interaction type
            if interaction_type == "read":
                message.mark_read()
            elif interaction_type == "acted_on":
                message.mark_acted_on()
            elif interaction_type == "dismissed":
                # Message remains in current state but we record low engagement
                pass
            elif interaction_type == "snoozed":
                # Reschedule message for later
                snooze_hours = interaction_data.get("snooze_hours", 4) if interaction_data else 4
                message.scheduled_for = datetime.utcnow() + timedelta(hours=snooze_hours)
                message.status = CoachingMessageStatus.SCHEDULED
            
            await message.save()
            
            # Update user's personalization profile
            profile = await self._get_or_create_personalization_profile(user)
            engaged = interaction_type in ["read", "acted_on"]
            profile.update_engagement(message.message_type.value, engaged)
            await profile.save()
            
            return {
                "success": True,
                "message_id": message_id,
                "interaction_type": interaction_type,
                "updated_status": message.status.value
            }
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error recording message interaction: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to record message interaction"
            )

    async def get_coaching_insights(
        self, user: User
    ) -> CoachingInsightsResponse:
        """Get coaching insights and analytics for a user"""
        
        try:
            # Get user's recent activities and ML predictions
            # This would integrate with existing services
            recent_activities = await Activity.find({
                "user_id": str(user.id),
                "date": {"$gte": datetime.now(timezone.utc) - timedelta(days=30)}
            }).sort([("date", -1)]).limit(100).to_list()
            
            values = await Value.find({"user_id": str(user.id)}).to_list()
            
            ml_predictions = await MLPredictionService.generate_comprehensive_predictions(
                user, recent_activities, values
            )
            
            # Get personalization profile
            profile = await self._get_or_create_personalization_profile(user)
            
            # Get message engagement data
            recent_messages = await CoachingMessage.find({
                "user_id": str(user.id),
                "created_at": {"$gte": datetime.now(timezone.utc) - timedelta(days=30)}
            }).to_list()
            
            # Analyze engagement patterns
            engagement_patterns = {}
            message_effectiveness = {}
            
            for msg in recent_messages:
                msg_type = msg.message_type.value
                if msg_type not in engagement_patterns:
                    engagement_patterns[msg_type] = {"sent": 0, "read": 0, "acted": 0}
                
                engagement_patterns[msg_type]["sent"] += 1
                if msg.status in [CoachingMessageStatus.READ, CoachingMessageStatus.ACTED_ON]:
                    engagement_patterns[msg_type]["read"] += 1
                if msg.status == CoachingMessageStatus.ACTED_ON:
                    engagement_patterns[msg_type]["acted"] += 1
            
            # Calculate effectiveness scores
            for msg_type, stats in engagement_patterns.items():
                if stats["sent"] > 0:
                    message_effectiveness[msg_type] = stats["acted"] / stats["sent"]
                else:
                    message_effectiveness[msg_type] = 0.0
            
            # Generate recommendations
            recommendations = []
            if profile.total_messages_sent > 5:
                engagement_rate = profile.total_messages_engaged / profile.total_messages_sent
                if engagement_rate < 0.3:
                    recommendations.append("Consider adjusting message frequency or types")
                elif engagement_rate > 0.7:
                    recommendations.append("You're highly engaged! Keep up the great work")
            
            # Generate next suggested actions based on ML predictions
            next_actions = []
            
            # Streak risk actions
            if ml_predictions.get("streak_risk", {}).get("risk_level") == "high":
                next_actions.append({
                    "type": "urgent",
                    "title": "Streak at Risk",
                    "description": "Your streak needs attention - quick action recommended",
                    "action": "log_activity"
                })
            
            # Goal suggestions
            goal_recs = ml_predictions.get("goal_recommendations", {}).get("recommended_goals", [])
            if goal_recs:
                next_actions.append({
                    "type": "growth",
                    "title": "New Goal Opportunity",
                    "description": f"Ready to try: {goal_recs[0].get('goal', 'new challenge')}",
                    "action": "view_goals"
                })
            
            return CoachingInsightsResponse(
                user_segment=ml_predictions.get("user_segmentation", {}).get("user_segment", "Getting Started"),
                engagement_patterns=engagement_patterns,
                optimal_timing=ml_predictions.get("optimal_timing", {}),
                message_effectiveness=message_effectiveness,
                personalization_recommendations=recommendations,
                next_suggested_actions=next_actions
            )
            
        except Exception as e:
            logger.error(f"Error getting coaching insights: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to get coaching insights"
            )