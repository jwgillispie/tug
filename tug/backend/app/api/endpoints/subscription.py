# app/api/endpoints/subscription.py
from fastapi import APIRouter, Depends, HTTPException, Request, status
from typing import Any, Dict, Optional
from datetime import datetime
import logging
import hashlib
import hmac

from ...models.user import User
from ...services.subscription_service import SubscriptionService
from ...core.auth import get_current_user
from ...core.config import settings

router = APIRouter()
logger = logging.getLogger(__name__)

# settings already imported above

@router.get("/status", status_code=status.HTTP_200_OK)
async def get_subscription_status(current_user: User = Depends(get_current_user)):
    """Get current user's subscription status"""
    try:
        # Validate and update subscription status
        await SubscriptionService.validate_subscription_status(current_user)
        
        # Get premium feature usage
        feature_usage = await SubscriptionService.get_premium_feature_usage(current_user)
        
        return {
            "success": True,
            "data": {
                "is_premium": current_user.is_premium,
                "subscription_tier": current_user.subscription_tier,
                "subscription_status": current_user.subscription_status,
                "subscription_expires_at": current_user.subscription_expires_at,
                "days_remaining": current_user.subscription_days_remaining,
                "auto_renew": current_user.subscription_auto_renew,
                "premium_features": feature_usage
            }
        }
        
    except Exception as e:
        logger.error(f"Error getting subscription status for user {current_user.id}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get subscription status"
        )

@router.post("/webhook", status_code=status.HTTP_200_OK)
async def revenuecat_webhook(request: Request):
    """Handle RevenueCat webhook events"""
    try:
        # Get webhook data
        webhook_data = await request.json()
        
        # Verify webhook signature if configured
        if hasattr(settings, 'REVENUECAT_WEBHOOK_SECRET') and settings.REVENUECAT_WEBHOOK_SECRET:
            signature = request.headers.get("Authorization", "").replace("Bearer ", "")
            if not _verify_webhook_signature(webhook_data, signature, settings.REVENUECAT_WEBHOOK_SECRET):
                raise HTTPException(status_code=401, detail="Invalid webhook signature")
        
        # Process the webhook
        success = await SubscriptionService.process_revenuecat_webhook(webhook_data)
        
        if success:
            return {"success": True, "message": "Webhook processed successfully"}
        else:
            return {"success": False, "message": "Webhook processing failed"}
            
    except Exception as e:
        logger.error(f"Error processing RevenueCat webhook: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to process webhook"
        )

@router.post("/feature-usage", status_code=status.HTTP_200_OK)
async def track_feature_usage(
    feature_name: str,
    usage_data: Optional[Dict[str, Any]] = None,
    current_user: User = Depends(get_current_user)
):
    """Track usage of a premium feature"""
    try:
        await SubscriptionService.track_feature_usage(current_user, feature_name, usage_data)
        
        return {
            "success": True,
            "message": "Feature usage tracked successfully"
        }
        
    except Exception as e:
        logger.error(f"Error tracking feature usage for user {current_user.id}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to track feature usage"
        )

@router.get("/analytics", status_code=status.HTTP_200_OK)
async def get_subscription_analytics(current_user: User = Depends(get_current_user)):
    """Get subscription analytics - Admin only"""
    # This would typically require admin role check
    # For now, limiting to premium users as a basic check
    if not current_user.is_premium:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required"
        )
    
    try:
        analytics = await SubscriptionService.get_subscription_analytics()
        
        return {
            "success": True,
            "data": analytics
        }
        
    except Exception as e:
        logger.error(f"Error getting subscription analytics: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get subscription analytics"
        )

@router.post("/upgrade-prompt", status_code=status.HTTP_200_OK)
async def track_upgrade_prompt(
    prompt_type: str,
    action: str,  # "shown", "dismissed", "clicked"
    context: Optional[Dict[str, Any]] = None,
    current_user: User = Depends(get_current_user)
):
    """Track upgrade prompt interactions"""
    try:
        if action == "shown":
            current_user.increment_upgrade_prompt(prompt_type)
        
        # Track paywall interaction
        current_user.add_paywall_interaction(
            screen=prompt_type,
            action=action,
            context=context
        )
        
        await current_user.save()
        
        return {
            "success": True,
            "message": "Upgrade prompt interaction tracked"
        }
        
    except Exception as e:
        logger.error(f"Error tracking upgrade prompt for user {current_user.id}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to track upgrade prompt"
        )

@router.get("/should-show-prompt/{prompt_type}", status_code=status.HTTP_200_OK)
async def should_show_upgrade_prompt(
    prompt_type: str,
    max_prompts: int = 3,
    current_user: User = Depends(get_current_user)
):
    """Check if upgrade prompt should be shown to user"""
    try:
        should_show = await SubscriptionService.should_show_upgrade_prompt(
            current_user, prompt_type, max_prompts
        )
        
        return {
            "success": True,
            "should_show": should_show,
            "prompts_shown": current_user.premium_upgrade_prompts_shown.get(prompt_type, 0)
        }
        
    except Exception as e:
        logger.error(f"Error checking upgrade prompt for user {current_user.id}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to check upgrade prompt"
        )

@router.post("/ab-test/{test_name}", status_code=status.HTTP_200_OK)
async def get_ab_test_cohort(
    test_name: str,
    current_user: User = Depends(get_current_user)
):
    """Get user's A/B test cohort"""
    try:
        cohort = await SubscriptionService.assign_ab_test_cohort(current_user, test_name)
        
        return {
            "success": True,
            "test_name": test_name,
            "cohort": cohort
        }
        
    except Exception as e:
        logger.error(f"Error getting A/B test cohort for user {current_user.id}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get A/B test cohort"
        )

@router.post("/conversion-event", status_code=status.HTTP_200_OK)
async def track_conversion_event(
    event_type: str,
    context: Optional[Dict[str, Any]] = None,
    current_user: User = Depends(get_current_user)
):
    """Track a conversion event"""
    try:
        current_user.add_conversion_event(event_type, context)
        await current_user.save()
        
        return {
            "success": True,
            "message": "Conversion event tracked"
        }
        
    except Exception as e:
        logger.error(f"Error tracking conversion event for user {current_user.id}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to track conversion event"
        )

def _verify_webhook_signature(payload: Dict[str, Any], signature: str, secret: str) -> bool:
    """Verify RevenueCat webhook signature"""
    try:
        import json
        payload_str = json.dumps(payload, separators=(',', ':'))
        expected_signature = hmac.new(
            secret.encode('utf-8'),
            payload_str.encode('utf-8'),
            hashlib.sha256
        ).hexdigest()
        
        return hmac.compare_digest(signature, expected_signature)
        
    except Exception as e:
        logger.error(f"Error verifying webhook signature: {e}")
        return False