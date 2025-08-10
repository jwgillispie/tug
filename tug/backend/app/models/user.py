# app/models/user.py
from beanie import Document, Indexed
from pydantic import EmailStr, Field
from typing import Dict, Any, Optional, ClassVar, List
from datetime import datetime
from bson import ObjectId
import logging
import re
import secrets
from enum import Enum

logger = logging.getLogger(__name__)

class SubscriptionTier(str, Enum):
    FREE = "free"
    PREMIUM = "premium"
    LIFETIME = "lifetime"

class SubscriptionStatus(str, Enum):
    ACTIVE = "active"
    EXPIRED = "expired"
    CANCELLED = "cancelled"
    TRIAL = "trial"
    GRACE_PERIOD = "grace_period"

class User(Document):
    """User model for MongoDB with Beanie ODM"""
    firebase_uid: Indexed(str, unique=True)
    email: Indexed(EmailStr, unique=True)
    username: Optional[Indexed(str, unique=True)] = None
    display_name: str
    profile_picture_url: Optional[str] = None
    bio: Optional[str] = Field(default=None, max_length=300)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    last_login: datetime = Field(default_factory=datetime.utcnow)
    onboarding_completed: bool = False
    settings: Dict[str, Any] = Field(default_factory=dict)
    version: int = 1
    
    # Subscription fields
    subscription_tier: SubscriptionTier = Field(default=SubscriptionTier.FREE)
    subscription_status: Optional[SubscriptionStatus] = None
    subscription_product_id: Optional[str] = None
    subscription_original_transaction_id: Optional[str] = None
    subscription_expires_at: Optional[datetime] = None
    subscription_purchased_at: Optional[datetime] = None
    subscription_cancelled_at: Optional[datetime] = None
    subscription_revenue_cat_id: Optional[str] = None
    subscription_auto_renew: bool = True
    subscription_trial_ends_at: Optional[datetime] = None
    subscription_grace_period_ends_at: Optional[datetime] = None
    
    # Premium onboarding tracking
    premium_onboarding_completed: bool = False
    premium_features_discovered: List[str] = Field(default_factory=list)
    premium_upgrade_prompts_shown: Dict[str, int] = Field(default_factory=dict)
    premium_feature_usage_stats: Dict[str, Any] = Field(default_factory=dict)
    first_premium_activation: Optional[datetime] = None
    
    # A/B testing and conversion tracking
    ab_test_cohorts: Dict[str, str] = Field(default_factory=dict)
    conversion_events: List[Dict[str, Any]] = Field(default_factory=list)
    paywall_interactions: List[Dict[str, Any]] = Field(default_factory=list)

    class Settings:
        name = "users"
        indexes = [
            # Authentication and lookup indexes - high priority
            [("firebase_uid", 1)],  # Primary auth lookup
            [("email", 1)],  # Email lookup
            [("username", 1)],  # Username lookup
            
            # Compound indexes for common query patterns
            [("firebase_uid", 1), ("email", 1)],  # Auth verification
            [("onboarding_completed", 1), ("created_at", -1)],  # Onboarding analytics
            [("last_login", -1)],  # Recent activity queries
            [("created_at", -1)],  # User timeline queries
            
            # Performance indexes for user discovery
            [("username", 1), ("display_name", 1)],  # Search functionality
            [("created_at", -1), ("onboarding_completed", 1)],  # User analytics
            
            # Subscription indexes for premium features and analytics
            [("subscription_tier", 1)],  # Premium user queries
            [("subscription_tier", 1), ("subscription_status", 1)],  # Active premium users
            [("subscription_expires_at", 1)],  # Expiration tracking
            [("subscription_tier", 1), ("subscription_expires_at", 1)],  # Premium expiration queries
            [("ab_test_cohorts", 1)],  # A/B testing queries
            [("premium_onboarding_completed", 1), ("subscription_tier", 1)]  # Onboarding analytics
        ]

    class Config:
        json_schema_extra = {
            "example": {
                "firebase_uid": "abc123",
                "email": "user@example.com",
                "username": "johndoe",
                "display_name": "John Doe",
                "created_at": "2024-02-12T00:00:00Z",
                "last_login": "2024-02-12T00:00:00Z",
                "onboarding_completed": True,
                "settings": {
                    "notifications_enabled": True,
                    "theme": "light"
                }
            }
        }
    
    @classmethod
    async def get_by_id(cls, id: str):
        """Get user by ID with proper ObjectId conversion"""
        try:
            # Convert string ID to ObjectId if it's not already
            if not isinstance(id, ObjectId):
                try:
                    object_id = ObjectId(id)
                except Exception as e:
                    logger.error(f"Invalid ObjectId format: {id}, Error: {e}")
                    return None
            else:
                object_id = id
                
            # Find the user by ID
            return await cls.find_one(cls.id == object_id)
        except Exception as e:
            logger.error(f"Error in get_by_id: {e}")
            return None

    async def ensure_username(self):
        """Ensure user has a username, generate one if missing"""
        if self.username:
            return self.username
            
        # Generate username from email or display_name
        base_username = None
        if self.display_name:
            # Use display name, remove spaces and special chars
            base_username = re.sub(r'[^a-zA-Z0-9]', '', self.display_name.lower())
        else:
            # Fall back to email prefix
            base_username = self.email.split('@')[0]
            base_username = re.sub(r'[^a-zA-Z0-9]', '', base_username.lower())
        
        # Ensure minimum length
        if len(base_username) < 3:
            base_username = base_username + "user"
            
        # Find available username
        username = base_username
        counter = 1
        while True:
            existing = await User.find_one(User.username == username)
            if not existing:
                break
            username = f"{base_username}{counter}"
            counter += 1
            
        self.username = username
        await self.save()
        return username

    @property
    def effective_username(self) -> str:
        """Get username or fallback to display_name/email"""
        return self.username or self.display_name or self.email.split('@')[0]
    
    @property
    def is_premium(self) -> bool:
        """Check if user has active premium subscription"""
        if self.subscription_tier == SubscriptionTier.FREE:
            return False
        
        if self.subscription_tier == SubscriptionTier.LIFETIME:
            return True
            
        # Check if premium subscription is active and not expired
        if self.subscription_status == SubscriptionStatus.ACTIVE:
            if self.subscription_expires_at:
                return datetime.utcnow() < self.subscription_expires_at
            return True
        
        # Check for trial period
        if self.subscription_status == SubscriptionStatus.TRIAL:
            if self.subscription_trial_ends_at:
                return datetime.utcnow() < self.subscription_trial_ends_at
            return True
        
        # Check for grace period
        if self.subscription_status == SubscriptionStatus.GRACE_PERIOD:
            if self.subscription_grace_period_ends_at:
                return datetime.utcnow() < self.subscription_grace_period_ends_at
            return True
        
        return False
    
    @property
    def subscription_days_remaining(self) -> Optional[int]:
        """Get days remaining in subscription"""
        if not self.is_premium:
            return None
            
        if self.subscription_tier == SubscriptionTier.LIFETIME:
            return None  # Lifetime subscription
            
        expiry_date = None
        if self.subscription_status == SubscriptionStatus.TRIAL and self.subscription_trial_ends_at:
            expiry_date = self.subscription_trial_ends_at
        elif self.subscription_status == SubscriptionStatus.GRACE_PERIOD and self.subscription_grace_period_ends_at:
            expiry_date = self.subscription_grace_period_ends_at
        elif self.subscription_expires_at:
            expiry_date = self.subscription_expires_at
            
        if expiry_date:
            delta = expiry_date - datetime.utcnow()
            return max(0, delta.days)
        
        return None
    
    def add_conversion_event(self, event_type: str, context: Dict[str, Any] = None):
        """Track a conversion event for analytics"""
        event = {
            "event_type": event_type,
            "timestamp": datetime.utcnow(),
            "context": context or {}
        }
        self.conversion_events.append(event)
        
        # Keep only last 50 events to prevent document bloat
        if len(self.conversion_events) > 50:
            self.conversion_events = self.conversion_events[-50:]
    
    def add_paywall_interaction(self, screen: str, action: str, context: Dict[str, Any] = None):
        """Track paywall interactions for optimization"""
        interaction = {
            "screen": screen,
            "action": action,
            "timestamp": datetime.utcnow(),
            "context": context or {}
        }
        self.paywall_interactions.append(interaction)
        
        # Keep only last 100 interactions
        if len(self.paywall_interactions) > 100:
            self.paywall_interactions = self.paywall_interactions[-100:]
    
    def increment_upgrade_prompt(self, prompt_type: str):
        """Increment the count for a specific upgrade prompt"""
        current_count = self.premium_upgrade_prompts_shown.get(prompt_type, 0)
        self.premium_upgrade_prompts_shown[prompt_type] = current_count + 1
    
    def assign_ab_test_cohort(self, test_name: str, cohort: str):
        """Assign user to A/B test cohort"""
        self.ab_test_cohorts[test_name] = cohort
    
    def get_ab_test_cohort(self, test_name: str) -> Optional[str]:
        """Get user's A/B test cohort"""
        return self.ab_test_cohorts.get(test_name)
    
    def mark_feature_discovered(self, feature_name: str):
        """Mark a premium feature as discovered"""
        if feature_name not in self.premium_features_discovered:
            self.premium_features_discovered.append(feature_name)
    
    async def activate_premium_subscription(
        self, 
        tier: SubscriptionTier,
        status: SubscriptionStatus,
        product_id: str,
        transaction_id: str,
        expires_at: Optional[datetime] = None,
        revenue_cat_id: Optional[str] = None
    ):
        """Activate premium subscription with tracking"""
        was_free = not self.is_premium
        
        self.subscription_tier = tier
        self.subscription_status = status
        self.subscription_product_id = product_id
        self.subscription_original_transaction_id = transaction_id
        self.subscription_expires_at = expires_at
        self.subscription_purchased_at = datetime.utcnow()
        self.subscription_revenue_cat_id = revenue_cat_id
        
        if was_free:
            self.first_premium_activation = datetime.utcnow()
            self.add_conversion_event("premium_activated", {
                "tier": tier,
                "product_id": product_id
            })
        
        await self.save()