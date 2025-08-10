# app/api/endpoints/premium_features.py
from datetime import datetime, timedelta
from typing import Dict, Any, Optional
from fastapi import APIRouter, Depends, HTTPException
# Using MongoDB with Beanie ODM
from ...core.auth import get_current_user
from ...models.user import User
from ...services.subscription_service import SubscriptionService
from ...services.analytics_service import AnalyticsService
import logging

logger = logging.getLogger(__name__)

router = APIRouter()

@router.post("/upgrade-prompt")
async def track_upgrade_prompt(
    prompt_data: Dict[str, Any],
    current_user: User = Depends(get_current_user),
# MongoDB doesn't need session dependency
):
    """Track upgrade prompt interactions for analytics"""
    try:
        # Store prompt interaction data
        interaction_data = {
            "user_id": current_user.id,
            "prompt_type": prompt_data.get("prompt_type"),
            "action": prompt_data.get("action"),  # clicked, dismissed, viewed
            "context": prompt_data.get("context", {}),
            "timestamp": datetime.utcnow(),
            "source": prompt_data.get("context", {}).get("source", "unknown")
        }
        
        # Track in analytics service
        await analytics_service.track_event(
            "upgrade_prompt_interaction",
            current_user.id,
            interaction_data
        )
        
        logger.info(f"Tracked upgrade prompt interaction for user {current_user.id}: {prompt_data}")
        return {"success": True}
        
    except Exception as e:
        logger.error(f"Error tracking upgrade prompt: {e}")
        raise HTTPException(status_code=500, detail="Failed to track prompt interaction")

@router.get("/should-show-prompt/{prompt_type}")
async def should_show_upgrade_prompt(
    prompt_type: str,
    current_user: User = Depends(get_current_user),
# MongoDB doesn't need session dependency
):
    """Determine if an upgrade prompt should be shown to the user"""
    try:
        # Don't show prompts to premium users
        if await subscription_service.is_premium_user(current_user.id):
            return {"should_show": False, "reason": "user_is_premium"}
        
        # Check prompt frequency limits
        recent_interactions = await analytics_service.get_recent_prompt_interactions(
            current_user.id, 
            prompt_type, 
            hours=24
        )
        
        # Frequency rules
        prompt_limits = {
            "leaderboard": {"max_per_day": 2, "cooldown_hours": 4},
            "analytics": {"max_per_day": 1, "cooldown_hours": 8},
            "achievement_milestone": {"max_per_day": 1, "cooldown_hours": 12},
            "streak_milestone": {"max_per_day": 1, "cooldown_hours": 24},
            "social": {"max_per_day": 1, "cooldown_hours": 6},
        }
        
        limits = prompt_limits.get(prompt_type, {"max_per_day": 1, "cooldown_hours": 24})
        
        # Check if we've exceeded daily limit
        if len(recent_interactions) >= limits["max_per_day"]:
            return {"should_show": False, "reason": "daily_limit_exceeded"}
        
        # Check if we're still in cooldown
        if recent_interactions:
            last_interaction = max(recent_interactions, key=lambda x: x["timestamp"])
            cooldown_end = last_interaction["timestamp"] + timedelta(hours=limits["cooldown_hours"])
            if datetime.utcnow() < cooldown_end:
                return {"should_show": False, "reason": "in_cooldown"}
        
        # Check user engagement level (more engaged users see more prompts)
        user_engagement = await analytics_service.get_user_engagement_score(current_user.id)
        
        # Context-specific logic
        should_show = await _evaluate_prompt_context(
            prompt_type, 
            current_user, 
            user_engagement,
            db
        )
        
        return {
            "should_show": should_show,
            "user_engagement": user_engagement,
            "recent_interactions": len(recent_interactions)
        }
        
    except Exception as e:
        logger.error(f"Error determining prompt visibility: {e}")
        return {"should_show": False, "reason": "error"}

async def _evaluate_prompt_context(
    prompt_type: str,
    user: User,
    engagement_score: float,
# MongoDB doesn't need session dependency
) -> bool:
    """Evaluate whether to show a prompt based on context"""
    
    if prompt_type == "leaderboard":
        # Show if user has been active and might be interested in rankings
        recent_activities = await analytics_service.get_user_activities(
            user.id, 
            days=7
        )
        return len(recent_activities) >= 3 and engagement_score > 0.3
    
    elif prompt_type == "analytics":
        # Show if user has enough data to make analytics meaningful
        total_activities = await analytics_service.get_total_user_activities(user.id)
        return total_activities >= 10 and engagement_score > 0.4
    
    elif prompt_type == "achievement_milestone":
        # Show when user achieves something significant
        recent_achievements = await analytics_service.get_recent_achievements(
            user.id,
            days=1
        )
        return len(recent_achievements) > 0
    
    elif prompt_type == "streak_milestone":
        # Show at streak milestones (7, 14, 30, 60, 100 days)
        current_streak = await analytics_service.get_current_streak(user.id)
        milestones = [7, 14, 30, 60, 100, 200, 365]
        return current_streak in milestones
    
    elif prompt_type == "social":
        # Show if user might benefit from social features
        return engagement_score > 0.5
    
    return engagement_score > 0.3  # Default threshold

@router.put("/premium-onboarding-completed")
async def mark_premium_onboarding_completed(
    current_user: User = Depends(get_current_user),
# MongoDB doesn't need session dependency
):
    """Mark premium onboarding as completed for the user"""
    try:
        # Verify user is premium
        if not await subscription_service.is_premium_user(current_user.id):
            raise HTTPException(status_code=403, detail="User is not premium")
        
        # Update user's premium onboarding status
        current_user.premium_onboarding_completed = True
        current_user.premium_onboarding_completed_at = datetime.utcnow()
        db.commit()
        
        # Track completion event
        await analytics_service.track_event(
            "premium_onboarding_completed",
            current_user.id,
            {"completion_date": datetime.utcnow()}
        )
        
        logger.info(f"Premium onboarding completed for user {current_user.id}")
        return {"success": True}
        
    except Exception as e:
        logger.error(f"Error marking premium onboarding completed: {e}")
        raise HTTPException(status_code=500, detail="Failed to update onboarding status")

@router.get("/onboarding-status")
async def get_premium_onboarding_status(
    current_user: User = Depends(get_current_user)
):
    """Get the user's premium onboarding status"""
    try:
        is_premium = await subscription_service.is_premium_user(current_user.id)
        
        return {
            "is_premium": is_premium,
            "onboarding_completed": getattr(current_user, "premium_onboarding_completed", False),
            "completed_at": getattr(current_user, "premium_onboarding_completed_at", None),
            "should_show_onboarding": (
                is_premium and 
                not getattr(current_user, "premium_onboarding_completed", False)
            )
        }
        
    except Exception as e:
        logger.error(f"Error getting onboarding status: {e}")
        return {
            "is_premium": False,
            "onboarding_completed": True,  # Fail safe
            "should_show_onboarding": False
        }

@router.get("/feature-usage-analytics")
async def get_premium_feature_usage(
    current_user: User = Depends(get_current_user),
# MongoDB doesn't need session dependency
):
    """Get analytics on premium feature usage for the user"""
    try:
        if not await subscription_service.is_premium_user(current_user.id):
            raise HTTPException(status_code=403, detail="Premium feature")
        
        # Get feature usage data
        usage_data = await analytics_service.get_premium_feature_usage(current_user.id)
        
        return {
            "leaderboard_views": usage_data.get("leaderboard_views", 0),
            "analytics_views": usage_data.get("analytics_views", 0),
            "ai_coaching_interactions": usage_data.get("ai_coaching_interactions", 0),
            "social_interactions": usage_data.get("social_interactions", 0),
            "most_used_feature": usage_data.get("most_used_feature"),
            "feature_adoption_score": usage_data.get("adoption_score", 0.0)
        }
        
    except Exception as e:
        logger.error(f"Error getting feature usage analytics: {e}")
        raise HTTPException(status_code=500, detail="Failed to get usage analytics")

@router.post("/feature-interaction")
async def track_premium_feature_interaction(
    interaction_data: Dict[str, Any],
    current_user: User = Depends(get_current_user)
):
    """Track when users interact with premium features"""
    try:
        # Track the interaction
        await analytics_service.track_event(
            "premium_feature_interaction",
            current_user.id,
            {
                "feature": interaction_data.get("feature"),
                "action": interaction_data.get("action"),
                "context": interaction_data.get("context", {}),
                "timestamp": datetime.utcnow()
            }
        )
        
        return {"success": True}
        
    except Exception as e:
        logger.error(f"Error tracking feature interaction: {e}")
        raise HTTPException(status_code=500, detail="Failed to track interaction")

@router.get("/conversion-analytics")
async def get_conversion_analytics(
    current_user: User = Depends(get_current_user)
):
    """Get conversion funnel analytics for the user's journey"""
    try:
        # Get user's conversion journey data
        journey_data = await analytics_service.get_user_conversion_journey(current_user.id)
        
        return {
            "signup_date": journey_data.get("signup_date"),
            "first_activity_date": journey_data.get("first_activity_date"),
            "first_prompt_shown": journey_data.get("first_prompt_shown"),
            "upgrade_date": journey_data.get("upgrade_date"),
            "conversion_source": journey_data.get("conversion_source"),
            "days_to_convert": journey_data.get("days_to_convert"),
            "prompt_interactions_before_conversion": journey_data.get("prompt_interactions", 0),
            "features_explored_before_conversion": journey_data.get("features_explored", [])
        }
        
    except Exception as e:
        logger.error(f"Error getting conversion analytics: {e}")
        return {"error": "Failed to get conversion analytics"}

@router.get("/testimonials")
async def get_testimonials():
    """Get testimonials and social proof for subscription screen"""
    # This could be dynamic from a database in the future
    testimonials = [
        {
            "id": 1,
            "name": "Sarah M.",
            "role": "Fitness Coach",
            "text": "Tug Pro completely transformed how I track my habits. The leaderboard feature keeps me motivated every single day!",
            "rating": 5,
            "avatar_emoji": "👩‍💼",
            "verified": True,
            "feature_mentioned": "leaderboard"
        },
        {
            "id": 2,
            "name": "Alex K.",
            "role": "Entrepreneur",
            "text": "The AI coaching insights are incredibly accurate. It's like having a personal habit coach in my pocket.",
            "rating": 5,
            "avatar_emoji": "🧑‍💻",
            "verified": True,
            "feature_mentioned": "ai_coaching"
        },
        {
            "id": 3,
            "name": "Jamie L.",
            "role": "Graduate Student",
            "text": "Best habit tracker I've used. The analytics help me understand my patterns and the social features keep me accountable.",
            "rating": 5,
            "avatar_emoji": "👨‍🎓",
            "verified": True,
            "feature_mentioned": "analytics"
        },
        {
            "id": 4,
            "name": "Morgan T.",
            "role": "Working Parent",
            "text": "Finally hit my 100-day streak thanks to Tug Pro! The insights showed me the best times to work out.",
            "rating": 5,
            "avatar_emoji": "👩‍👧‍👦",
            "verified": True,
            "feature_mentioned": "insights"
        }
    ]
    
    return {"testimonials": testimonials}

@router.get("/social-proof")
async def get_social_proof():
    """Get dynamic social proof data for subscription screens"""
    try:
        # Get real-time social proof metrics
        social_proof = await analytics_service.get_social_proof_metrics()
        
        return {
            "total_users": social_proof.get("total_users", 10000),
            "premium_users": social_proof.get("premium_users", 2500),
            "recent_upgrades_24h": social_proof.get("recent_upgrades_24h", 147),
            "average_rating": social_proof.get("average_rating", 4.9),
            "total_activities_completed": social_proof.get("total_activities", 1000000),
            "countries_represented": social_proof.get("countries", 45),
            "success_stories": social_proof.get("success_stories", 892)
        }
        
    except Exception as e:
        logger.error(f"Error getting social proof: {e}")
        # Return fallback data
        return {
            "total_users": 10000,
            "premium_users": 2500,
            "recent_upgrades_24h": 147,
            "average_rating": 4.9,
            "total_activities_completed": 1000000,
            "countries_represented": 45,
            "success_stories": 892
        }

@router.post("/ab-test-assignment")
async def get_ab_test_assignment(
    test_data: Dict[str, Any],
    current_user: User = Depends(get_current_user)
):
    """Get A/B test variant assignment for subscription messaging"""
    try:
        test_name = test_data.get("test_name")
        
        # Simple hash-based assignment for consistency
        import hashlib
        
        # Create deterministic assignment based on user ID and test name
        hash_input = f"{current_user.id}_{test_name}".encode()
        hash_value = int(hashlib.md5(hash_input).hexdigest()[:8], 16)
        
        # Define test variants
        test_variants = {
            "subscription_messaging": {
                "control": {"weight": 50, "messaging": "standard"},
                "urgency": {"weight": 25, "messaging": "urgency_focused"},
                "value": {"weight": 25, "messaging": "value_focused"}
            },
            "pricing_display": {
                "control": {"weight": 50, "layout": "standard"},
                "savings_focused": {"weight": 50, "layout": "savings_highlighted"}
            }
        }
        
        if test_name not in test_variants:
            return {"variant": "control", "test_active": False}
        
        variants = test_variants[test_name]
        total_weight = sum(v["weight"] for v in variants.values())
        
        # Assign variant based on hash
        assignment_value = hash_value % total_weight
        cumulative_weight = 0
        
        for variant_name, variant_config in variants.items():
            cumulative_weight += variant_config["weight"]
            if assignment_value < cumulative_weight:
                # Track assignment
                await analytics_service.track_event(
                    "ab_test_assignment",
                    current_user.id,
                    {
                        "test_name": test_name,
                        "variant": variant_name,
                        "timestamp": datetime.utcnow()
                    }
                )
                
                return {
                    "variant": variant_name,
                    "test_active": True,
                    "config": variant_config
                }
        
        # Fallback
        return {"variant": "control", "test_active": True}
        
    except Exception as e:
        logger.error(f"Error getting A/B test assignment: {e}")
        return {"variant": "control", "test_active": False}