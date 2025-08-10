# app/services/subscription_service.py
import logging
from typing import Dict, Any, Optional, List, Tuple
from datetime import datetime, timedelta
from bson import ObjectId

from ..models.user import User, SubscriptionTier, SubscriptionStatus
from ..core.retry import with_retry, RetryConfigs
from ..core.graceful_degradation import with_graceful_degradation
from ..core.logging_config import get_logger
from ..core.config import settings

logger = get_logger(__name__)

class SubscriptionService:
    """Service for managing subscription operations and premium features"""
    
    @staticmethod
    @with_retry(config=RetryConfigs.DATABASE)
    async def validate_subscription_status(user: User) -> bool:
        """Validate user's subscription status and update if needed"""
        try:
            # Check if subscription has expired
            if user.subscription_tier != SubscriptionTier.FREE and user.subscription_expires_at:
                if datetime.utcnow() > user.subscription_expires_at:
                    # Check for grace period
                    if user.subscription_grace_period_ends_at and datetime.utcnow() <= user.subscription_grace_period_ends_at:
                        user.subscription_status = SubscriptionStatus.GRACE_PERIOD
                    else:
                        # Subscription has expired
                        user.subscription_status = SubscriptionStatus.EXPIRED
                        user.subscription_tier = SubscriptionTier.FREE
                    
                    await user.save()
                    logger.info(f"Updated subscription status for user {user.id}: {user.subscription_status}")
            
            return user.is_premium
            
        except Exception as e:
            logger.error(f"Error validating subscription status for user {user.id}: {e}")
            # In case of error, return current status without modification
            return user.is_premium
    
    @staticmethod
    @with_retry(config=RetryConfigs.DATABASE)
    async def process_revenuecat_webhook(webhook_data: Dict[str, Any]) -> bool:
        """Process RevenueCat webhook events to update subscription status"""
        try:
            event_type = webhook_data.get("type")
            app_user_id = webhook_data.get("app_user_id")
            
            if not app_user_id:
                logger.warning("Webhook missing app_user_id")
                return False
            
            # Find user by RevenueCat ID or Firebase UID
            user = await User.find_one(
                {"$or": [
                    {"subscription_revenue_cat_id": app_user_id},
                    {"firebase_uid": app_user_id}
                ]}
            )
            
            if not user:
                logger.warning(f"User not found for RevenueCat ID: {app_user_id}")
                return False
            
            # Process different event types
            if event_type == "INITIAL_PURCHASE":
                await SubscriptionService._handle_initial_purchase(user, webhook_data)
            elif event_type == "RENEWAL":
                await SubscriptionService._handle_renewal(user, webhook_data)
            elif event_type == "CANCELLATION":
                await SubscriptionService._handle_cancellation(user, webhook_data)
            elif event_type == "UNCANCELLATION":
                await SubscriptionService._handle_uncancellation(user, webhook_data)
            elif event_type == "EXPIRATION":
                await SubscriptionService._handle_expiration(user, webhook_data)
            elif event_type == "PRODUCT_CHANGE":
                await SubscriptionService._handle_product_change(user, webhook_data)
            
            return True
            
        except Exception as e:
            logger.error(f"Error processing RevenueCat webhook: {e}")
            return False
    
    @staticmethod
    async def _handle_initial_purchase(user: User, webhook_data: Dict[str, Any]):
        """Handle initial subscription purchase"""
        event_data = webhook_data.get("event", {})
        product_id = event_data.get("product_id")
        transaction_id = event_data.get("original_transaction_id")
        expires_date_ms = event_data.get("expires_date_ms")
        
        # Determine subscription tier based on product ID
        if "lifetime" in product_id.lower():
            tier = SubscriptionTier.LIFETIME
            expires_at = None
        else:
            tier = SubscriptionTier.PREMIUM
            expires_at = datetime.fromtimestamp(int(expires_date_ms) / 1000) if expires_date_ms else None
        
        await user.activate_premium_subscription(
            tier=tier,
            status=SubscriptionStatus.ACTIVE,
            product_id=product_id,
            transaction_id=transaction_id,
            expires_at=expires_at,
            revenue_cat_id=webhook_data.get("app_user_id")
        )
        
        logger.info(f"Activated premium subscription for user {user.id}: {product_id}")
    
    @staticmethod
    async def _handle_renewal(user: User, webhook_data: Dict[str, Any]):
        """Handle subscription renewal"""
        event_data = webhook_data.get("event", {})
        expires_date_ms = event_data.get("expires_date_ms")
        
        if expires_date_ms:
            user.subscription_expires_at = datetime.fromtimestamp(int(expires_date_ms) / 1000)
            user.subscription_status = SubscriptionStatus.ACTIVE
            await user.save()
            
            logger.info(f"Renewed subscription for user {user.id}")
    
    @staticmethod
    async def _handle_cancellation(user: User, webhook_data: Dict[str, Any]):
        """Handle subscription cancellation"""
        user.subscription_cancelled_at = datetime.utcnow()
        user.subscription_auto_renew = False
        # Keep subscription active until expiration
        await user.save()
        
        logger.info(f"Cancelled subscription for user {user.id}")
    
    @staticmethod
    async def _handle_uncancellation(user: User, webhook_data: Dict[str, Any]):
        """Handle subscription uncancellation"""
        user.subscription_cancelled_at = None
        user.subscription_auto_renew = True
        user.subscription_status = SubscriptionStatus.ACTIVE
        await user.save()
        
        logger.info(f"Uncancelled subscription for user {user.id}")
    
    @staticmethod
    async def _handle_expiration(user: User, webhook_data: Dict[str, Any]):
        """Handle subscription expiration"""
        user.subscription_status = SubscriptionStatus.EXPIRED
        user.subscription_tier = SubscriptionTier.FREE
        await user.save()
        
        logger.info(f"Expired subscription for user {user.id}")
    
    @staticmethod
    async def _handle_product_change(user: User, webhook_data: Dict[str, Any]):
        """Handle subscription product change (upgrade/downgrade)"""
        event_data = webhook_data.get("event", {})
        new_product_id = event_data.get("product_id")
        expires_date_ms = event_data.get("expires_date_ms")
        
        user.subscription_product_id = new_product_id
        if expires_date_ms:
            user.subscription_expires_at = datetime.fromtimestamp(int(expires_date_ms) / 1000)
        
        await user.save()
        logger.info(f"Changed subscription product for user {user.id}: {new_product_id}")
    
    @staticmethod
    @with_graceful_degradation(service_name="subscription_analytics", fallback_value={})
    async def get_subscription_analytics() -> Dict[str, Any]:
        """Get subscription analytics for business metrics"""
        try:
            # Get subscription counts by tier
            subscription_counts = {}
            for tier in SubscriptionTier:
                count = await User.find({"subscription_tier": tier}).count()
                subscription_counts[tier.value] = count
            
            # Get active premium users
            active_premium = await User.find({
                "subscription_tier": {"$ne": SubscriptionTier.FREE},
                "subscription_status": {"$in": [SubscriptionStatus.ACTIVE, SubscriptionStatus.TRIAL]}
            }).count()
            
            # Get expiring subscriptions (next 7 days)
            expiring_soon = await User.find({
                "subscription_expires_at": {
                    "$gte": datetime.utcnow(),
                    "$lte": datetime.utcnow() + timedelta(days=7)
                }
            }).count()
            
            # Get conversion rate (premium users / total users)
            total_users = await User.find().count()
            conversion_rate = (active_premium / total_users * 100) if total_users > 0 else 0
            
            # Get monthly recurring revenue (MRR) estimate
            # This would need actual product pricing data
            mrr_estimate = active_premium * 9.99  # Placeholder calculation
            
            return {
                "subscription_counts": subscription_counts,
                "active_premium_users": active_premium,
                "total_users": total_users,
                "conversion_rate": round(conversion_rate, 2),
                "expiring_soon": expiring_soon,
                "mrr_estimate": round(mrr_estimate, 2),
                "generated_at": datetime.utcnow()
            }
            
        except Exception as e:
            logger.error(f"Error getting subscription analytics: {e}")
            return {}
    
    @staticmethod
    async def get_premium_feature_usage(user: User) -> Dict[str, Any]:
        """Get premium feature usage statistics for user"""
        try:
            # Analyze user's premium feature usage
            feature_usage = user.premium_feature_usage_stats.copy()
            
            # Add computed metrics
            days_since_premium = None
            if user.first_premium_activation:
                days_since_premium = (datetime.utcnow() - user.first_premium_activation).days
            
            return {
                "is_premium": user.is_premium,
                "subscription_tier": user.subscription_tier,
                "days_remaining": user.subscription_days_remaining,
                "features_discovered": user.premium_features_discovered,
                "feature_usage_stats": feature_usage,
                "days_since_activation": days_since_premium,
                "onboarding_completed": user.premium_onboarding_completed,
                "upgrade_prompts_shown": user.premium_upgrade_prompts_shown
            }
            
        except Exception as e:
            logger.error(f"Error getting premium feature usage for user {user.id}: {e}")
            return {"error": "Failed to get feature usage"}
    
    @staticmethod
    async def track_feature_usage(user: User, feature_name: str, usage_data: Dict[str, Any] = None):
        """Track usage of a premium feature"""
        try:
            # Initialize feature usage if not exists
            if feature_name not in user.premium_feature_usage_stats:
                user.premium_feature_usage_stats[feature_name] = {
                    "first_used": datetime.utcnow(),
                    "usage_count": 0,
                    "last_used": None
                }
            
            # Update usage statistics
            feature_stats = user.premium_feature_usage_stats[feature_name]
            feature_stats["usage_count"] += 1
            feature_stats["last_used"] = datetime.utcnow()
            
            # Add any additional usage data
            if usage_data:
                feature_stats.update(usage_data)
            
            # Mark feature as discovered
            user.mark_feature_discovered(feature_name)
            
            await user.save()
            
        except Exception as e:
            logger.error(f"Error tracking feature usage for user {user.id}: {e}")
    
    @staticmethod
    async def should_show_upgrade_prompt(user: User, prompt_type: str, max_prompts: int = 3) -> bool:
        """Determine if upgrade prompt should be shown to user"""
        if user.is_premium:
            return False
        
        # Check if max prompts reached
        prompts_shown = user.premium_upgrade_prompts_shown.get(prompt_type, 0)
        if prompts_shown >= max_prompts:
            return False
        
        # Add time-based logic (e.g., don't show again for 24 hours)
        # This would require tracking last prompt time
        
        return True
    
    @staticmethod
    async def get_users_for_retention_campaign() -> List[User]:
        """Get users who should receive retention campaigns"""
        try:
            # Users whose subscriptions expire in 3-7 days
            retention_candidates = await User.find({
                "subscription_tier": {"$ne": SubscriptionTier.FREE},
                "subscription_expires_at": {
                    "$gte": datetime.utcnow() + timedelta(days=3),
                    "$lte": datetime.utcnow() + timedelta(days=7)
                },
                "subscription_cancelled_at": {"$ne": None}  # Already cancelled
            }).to_list()
            
            return retention_candidates
            
        except Exception as e:
            logger.error(f"Error getting retention campaign users: {e}")
            return []
    
    @staticmethod
    async def assign_ab_test_cohort(user: User, test_name: str) -> str:
        """Assign user to A/B test cohort if not already assigned"""
        existing_cohort = user.get_ab_test_cohort(test_name)
        if existing_cohort:
            return existing_cohort
        
        # Simple A/B split based on user ID
        user_id_int = int(str(user.id)[-4:], 16)  # Last 4 hex digits
        cohort = "A" if user_id_int % 2 == 0 else "B"
        
        user.assign_ab_test_cohort(test_name, cohort)
        await user.save()
        
        return cohort