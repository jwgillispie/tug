# app/services/coaching_background_service.py
import asyncio
import logging
from typing import List, Dict, Any, Optional
from datetime import datetime, timedelta, timezone

from ..models.user import User
from ..models.activity import Activity
from ..models.value import Value
from ..models.coaching_message import (
    CoachingMessage, CoachingMessageStatus, UserPersonalizationProfile
)
from ..services.coaching_service import CoachingService
from ..services.notification_service import NotificationService
from ..core.database import get_database

logger = logging.getLogger(__name__)

class CoachingBackgroundService:
    """Background service for coaching message processing and delivery"""
    
    def __init__(self):
        self.coaching_service = CoachingService()
        self.notification_service = NotificationService()
        
        # Configuration
        self.batch_size = 50  # Users to process per batch
        self.max_concurrent_users = 10  # Maximum concurrent user processing
        self.delivery_batch_size = 100  # Messages to deliver per batch
        
    async def process_all_users_for_coaching_messages(self) -> Dict[str, Any]:
        """Process all active users for coaching message generation"""
        
        start_time = datetime.utcnow()
        stats = {
            "users_processed": 0,
            "messages_generated": 0,
            "errors": 0,
            "processing_time_seconds": 0
        }
        
        try:
            logger.info("Starting coaching message generation for all users")
            
            # Get all active users (users who have logged in recently or have activities)
            cutoff_date = datetime.now(timezone.utc) - timedelta(days=30)
            
            # Find active users using aggregation for better performance
            db = await get_database()
            pipeline = [
                {
                    "$match": {
                        "$or": [
                            {"last_login": {"$gte": cutoff_date}},
                            {"created_at": {"$gte": cutoff_date}}
                        ]
                    }
                },
                {
                    "$lookup": {
                        "from": "activities",
                        "localField": "_id",
                        "foreignField": "user_id",
                        "as": "recent_activities",
                        "pipeline": [
                            {
                                "$match": {
                                    "date": {"$gte": cutoff_date}
                                }
                            },
                            {"$limit": 1}  # Just check if any exist
                        ]
                    }
                },
                {
                    "$match": {
                        "$or": [
                            {"recent_activities": {"$ne": []}},
                            {"last_login": {"$gte": cutoff_date}}
                        ]
                    }
                },
                {
                    "$project": {
                        "_id": 1,
                        "firebase_uid": 1,
                        "display_name": 1,
                        "created_at": 1,
                        "subscription_tier": 1,
                        "last_login": 1
                    }
                }
            ]
            
            active_users_cursor = db.users.aggregate(pipeline)
            active_users = await active_users_cursor.to_list(length=None)
            
            logger.info(f"Found {len(active_users)} active users to process")
            
            # Process users in batches
            for i in range(0, len(active_users), self.batch_size):
                batch = active_users[i:i + self.batch_size]
                batch_stats = await self._process_user_batch(batch)
                
                stats["users_processed"] += batch_stats["users_processed"]
                stats["messages_generated"] += batch_stats["messages_generated"]
                stats["errors"] += batch_stats["errors"]
                
                # Small delay between batches to prevent overload
                await asyncio.sleep(1)
            
            stats["processing_time_seconds"] = (datetime.utcnow() - start_time).total_seconds()
            
            logger.info(
                f"Coaching message generation completed. "
                f"Users: {stats['users_processed']}, "
                f"Messages: {stats['messages_generated']}, "
                f"Errors: {stats['errors']}, "
                f"Time: {stats['processing_time_seconds']:.1f}s"
            )
            
            return stats
            
        except Exception as e:
            logger.error(f"Error in coaching message generation process: {e}", exc_info=True)
            stats["errors"] += 1
            stats["processing_time_seconds"] = (datetime.utcnow() - start_time).total_seconds()
            return stats

    async def _process_user_batch(self, user_batch: List[Dict]) -> Dict[str, Any]:
        """Process a batch of users for coaching messages"""
        
        batch_stats = {
            "users_processed": 0,
            "messages_generated": 0,
            "errors": 0
        }
        
        # Create semaphore to limit concurrent processing
        semaphore = asyncio.Semaphore(self.max_concurrent_users)
        
        async def process_single_user(user_data: Dict) -> Dict[str, Any]:
            async with semaphore:
                return await self._process_user_for_coaching(user_data)
        
        # Process users concurrently
        tasks = [process_single_user(user_data) for user_data in user_batch]
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        # Aggregate results
        for result in results:
            if isinstance(result, Exception):
                batch_stats["errors"] += 1
                logger.error(f"Error processing user in batch: {result}")
            else:
                batch_stats["users_processed"] += result["users_processed"]
                batch_stats["messages_generated"] += result["messages_generated"]
                batch_stats["errors"] += result["errors"]
        
        return batch_stats

    async def _process_user_for_coaching(self, user_data: Dict) -> Dict[str, Any]:
        """Process a single user for coaching message generation"""
        
        user_stats = {
            "users_processed": 0,
            "messages_generated": 0,
            "errors": 0
        }
        
        try:
            # Convert dict to User object
            user = User(**user_data)
            user.id = user_data["_id"]
            
            # Check if user needs coaching messages
            if not await self._should_generate_messages_for_user(user):
                user_stats["users_processed"] = 1
                return user_stats
            
            # Get user's recent activities and values
            activities = await Activity.find({
                "user_id": str(user.id),
                "date": {"$gte": datetime.now(timezone.utc) - timedelta(days=60)}
            }).sort([("date", -1)]).limit(200).to_list()
            
            values = await Value.find({
                "user_id": str(user.id)
            }).to_list()
            
            # Generate coaching messages
            messages = await self.coaching_service.analyze_user_behavior_and_generate_messages(
                user, activities, values
            )
            
            user_stats["users_processed"] = 1
            user_stats["messages_generated"] = len(messages)
            
            logger.debug(f"Generated {len(messages)} messages for user {user.id}")
            
        except Exception as e:
            logger.error(f"Error processing user {user_data.get('_id')}: {e}")
            user_stats["errors"] = 1
        
        return user_stats

    async def _should_generate_messages_for_user(self, user: User) -> bool:
        """Check if we should generate messages for this user"""
        
        try:
            # Check user's personalization profile
            profile = await UserPersonalizationProfile.find_one({"user_id": str(user.id)})
            
            if profile:
                # Check if user wants minimal messaging
                if profile.message_frequency == "minimal":
                    # For minimal users, only generate high-priority messages
                    last_urgent = await CoachingMessage.find_one({
                        "user_id": str(user.id),
                        "priority": "urgent",
                        "created_at": {"$gte": datetime.now(timezone.utc) - timedelta(days=3)}
                    })
                    if last_urgent:
                        return False
                
                # Check daily message limit
                today = datetime.now(timezone.utc).date()
                messages_today = await CoachingMessage.find({
                    "user_id": str(user.id),
                    "created_at": {
                        "$gte": datetime.combine(today, datetime.min.time()),
                        "$lt": datetime.combine(today + timedelta(days=1), datetime.min.time())
                    },
                    "status": {"$nin": ["cancelled", "expired"]}
                }).count()
                
                daily_limit = {
                    "minimal": 1,
                    "optimal": 3,
                    "frequent": 5,
                    "daily": 2
                }.get(profile.message_frequency, 3)
                
                if messages_today >= daily_limit:
                    return False
            
            # Check if user has recent activity (active users get more messages)
            recent_activity = await Activity.find_one({
                "user_id": str(user.id),
                "date": {"$gte": datetime.now(timezone.utc) - timedelta(days=7)}
            })
            
            if not recent_activity:
                # For inactive users, be more conservative
                recent_message = await CoachingMessage.find_one({
                    "user_id": str(user.id),
                    "created_at": {"$gte": datetime.now(timezone.utc) - timedelta(days=2)}
                })
                if recent_message:
                    return False
            
            return True
            
        except Exception as e:
            logger.error(f"Error checking if should generate messages for user: {e}")
            return True  # Default to generating messages

    async def deliver_scheduled_messages(self) -> Dict[str, Any]:
        """Deliver all scheduled coaching messages that are due"""
        
        start_time = datetime.utcnow()
        stats = {
            "messages_processed": 0,
            "messages_delivered": 0,
            "messages_expired": 0,
            "delivery_errors": 0,
            "processing_time_seconds": 0
        }
        
        try:
            logger.info("Starting scheduled coaching message delivery")
            
            # Find messages that are due for delivery
            now = datetime.now(timezone.utc)
            due_messages = await CoachingMessage.find({
                "status": {"$in": ["pending", "scheduled"]},
                "scheduled_for": {"$lte": now},
                "$or": [
                    {"expires_at": {"$gt": now}},
                    {"expires_at": None}
                ]
            }).sort([("priority", -1), ("scheduled_for", 1)]).to_list()
            
            logger.info(f"Found {len(due_messages)} messages ready for delivery")
            
            # Process messages in batches
            for i in range(0, len(due_messages), self.delivery_batch_size):
                batch = due_messages[i:i + self.delivery_batch_size]
                batch_stats = await self._deliver_message_batch(batch)
                
                stats["messages_processed"] += batch_stats["messages_processed"]
                stats["messages_delivered"] += batch_stats["messages_delivered"]
                stats["messages_expired"] += batch_stats["messages_expired"]
                stats["delivery_errors"] += batch_stats["delivery_errors"]
                
                # Small delay between batches
                await asyncio.sleep(0.5)
            
            # Clean up expired messages
            expired_stats = await self._cleanup_expired_messages()
            stats["messages_expired"] += expired_stats["expired_count"]
            
            stats["processing_time_seconds"] = (datetime.utcnow() - start_time).total_seconds()
            
            logger.info(
                f"Message delivery completed. "
                f"Processed: {stats['messages_processed']}, "
                f"Delivered: {stats['messages_delivered']}, "
                f"Expired: {stats['messages_expired']}, "
                f"Errors: {stats['delivery_errors']}, "
                f"Time: {stats['processing_time_seconds']:.1f}s"
            )
            
            return stats
            
        except Exception as e:
            logger.error(f"Error in message delivery process: {e}", exc_info=True)
            stats["delivery_errors"] += 1
            stats["processing_time_seconds"] = (datetime.utcnow() - start_time).total_seconds()
            return stats

    async def _deliver_message_batch(self, message_batch: List[CoachingMessage]) -> Dict[str, Any]:
        """Deliver a batch of coaching messages"""
        
        batch_stats = {
            "messages_processed": 0,
            "messages_delivered": 0,
            "messages_expired": 0,
            "delivery_errors": 0
        }
        
        for message in message_batch:
            try:
                batch_stats["messages_processed"] += 1
                
                # Check if message has expired
                if message.is_expired():
                    message.status = CoachingMessageStatus.EXPIRED
                    await message.save()
                    batch_stats["messages_expired"] += 1
                    continue
                
                # Get user for message delivery
                user = await User.find_one({"_id": message.user_id})
                if not user:
                    logger.warning(f"User not found for message {message.id}")
                    message.status = CoachingMessageStatus.CANCELLED
                    await message.save()
                    continue
                
                # Deliver the message
                success = await self._deliver_single_message(message, user)
                
                if success:
                    message.mark_sent()
                    await message.save()
                    batch_stats["messages_delivered"] += 1
                    
                    # Update user's personalization profile
                    profile = await UserPersonalizationProfile.find_one({
                        "user_id": str(user.id)
                    })
                    if profile:
                        profile.last_message_sent = datetime.utcnow()
                        await profile.save()
                    
                    logger.debug(f"Delivered coaching message {message.id} to user {user.id}")
                else:
                    batch_stats["delivery_errors"] += 1
                    logger.warning(f"Failed to deliver message {message.id}")
                
            except Exception as e:
                logger.error(f"Error delivering message {message.id}: {e}")
                batch_stats["delivery_errors"] += 1
        
        return batch_stats

    async def _deliver_single_message(
        self, 
        message: CoachingMessage, 
        user: User
    ) -> bool:
        """Deliver a single coaching message to a user"""
        
        try:
            # Create a notification for the coaching message
            # This integrates with the existing notification system
            notification_created = await NotificationService.create_coaching_notification(
                user_id=str(user.id),
                message_id=str(message.id),
                title=message.title,
                body=message.message,
                action_text=message.action_text,
                action_url=message.action_url,
                priority=message.priority.value,
                message_type=message.message_type.value
            )
            
            return notification_created
            
        except Exception as e:
            logger.error(f"Error in single message delivery: {e}")
            return False

    async def _cleanup_expired_messages(self) -> Dict[str, int]:
        """Clean up expired coaching messages"""
        
        try:
            now = datetime.now(timezone.utc)
            
            # Find and update expired messages
            expired_messages = await CoachingMessage.find({
                "status": {"$in": ["pending", "scheduled"]},
                "expires_at": {"$lte": now}
            }).to_list()
            
            expired_count = 0
            for message in expired_messages:
                message.status = CoachingMessageStatus.EXPIRED
                await message.save()
                expired_count += 1
            
            logger.info(f"Cleaned up {expired_count} expired messages")
            
            return {"expired_count": expired_count}
            
        except Exception as e:
            logger.error(f"Error cleaning up expired messages: {e}")
            return {"expired_count": 0}

    async def cleanup_old_messages(self, days_to_keep: int = 90) -> Dict[str, Any]:
        """Clean up old coaching messages to manage database size"""
        
        try:
            cutoff_date = datetime.now(timezone.utc) - timedelta(days=days_to_keep)
            
            # Delete old messages (keep important ones longer)
            important_statuses = [CoachingMessageStatus.ACTED_ON]
            
            # Delete non-important old messages
            delete_result = await CoachingMessage.find({
                "created_at": {"$lt": cutoff_date},
                "status": {"$nin": important_statuses}
            }).delete()
            
            # Delete very old important messages (keep for 1 year)
            very_old_cutoff = datetime.now(timezone.utc) - timedelta(days=365)
            old_important_result = await CoachingMessage.find({
                "created_at": {"$lt": very_old_cutoff},
                "status": {"$in": important_statuses}
            }).delete()
            
            total_deleted = delete_result.deleted_count + old_important_result.deleted_count
            
            logger.info(f"Cleaned up {total_deleted} old coaching messages")
            
            return {
                "deleted_count": total_deleted,
                "cutoff_date": cutoff_date,
                "days_kept": days_to_keep
            }
            
        except Exception as e:
            logger.error(f"Error cleaning up old messages: {e}")
            return {"deleted_count": 0, "error": str(e)}

    async def generate_coaching_analytics(self) -> Dict[str, Any]:
        """Generate coaching system analytics"""
        
        try:
            now = datetime.now(timezone.utc)
            week_ago = now - timedelta(days=7)
            month_ago = now - timedelta(days=30)
            
            # Overall message stats
            total_messages = await CoachingMessage.find({}).count()
            week_messages = await CoachingMessage.find({
                "created_at": {"$gte": week_ago}
            }).count()
            
            # Engagement stats
            sent_messages = await CoachingMessage.find({
                "status": {"$in": ["sent", "read", "acted_on"]},
                "created_at": {"$gte": month_ago}
            }).to_list()
            
            if sent_messages:
                read_count = len([m for m in sent_messages if m.status in ["read", "acted_on"]])
                acted_count = len([m for m in sent_messages if m.status == "acted_on"])
                
                read_rate = read_count / len(sent_messages)
                action_rate = acted_count / len(sent_messages)
            else:
                read_rate = 0.0
                action_rate = 0.0
            
            # Message type effectiveness
            type_stats = {}
            for message in sent_messages:
                msg_type = message.message_type.value
                if msg_type not in type_stats:
                    type_stats[msg_type] = {"sent": 0, "acted": 0}
                
                type_stats[msg_type]["sent"] += 1
                if message.status == CoachingMessageStatus.ACTED_ON:
                    type_stats[msg_type]["acted"] += 1
            
            # Calculate effectiveness scores
            type_effectiveness = {}
            for msg_type, stats in type_stats.items():
                if stats["sent"] > 0:
                    type_effectiveness[msg_type] = stats["acted"] / stats["sent"]
                else:
                    type_effectiveness[msg_type] = 0.0
            
            # Active users with coaching
            active_users = await CoachingMessage.distinct("user_id", {
                "created_at": {"$gte": month_ago}
            })
            
            # System health metrics
            pending_messages = await CoachingMessage.find({
                "status": "pending"
            }).count()
            
            scheduled_messages = await CoachingMessage.find({
                "status": "scheduled"
            }).count()
            
            expired_messages = await CoachingMessage.find({
                "status": "expired",
                "created_at": {"$gte": week_ago}
            }).count()
            
            return {
                "system_overview": {
                    "total_messages_all_time": total_messages,
                    "messages_this_week": week_messages,
                    "active_users_this_month": len(active_users),
                    "overall_read_rate": round(read_rate * 100, 1),
                    "overall_action_rate": round(action_rate * 100, 1)
                },
                "message_queue": {
                    "pending_messages": pending_messages,
                    "scheduled_messages": scheduled_messages,
                    "expired_this_week": expired_messages
                },
                "message_type_effectiveness": {
                    k: round(v * 100, 1) for k, v in 
                    sorted(type_effectiveness.items(), key=lambda x: x[1], reverse=True)
                },
                "engagement_trends": {
                    "total_sent_last_30_days": len(sent_messages),
                    "read_rate_percent": round(read_rate * 100, 1),
                    "action_rate_percent": round(action_rate * 100, 1),
                    "best_performing_types": [
                        k for k, v in sorted(type_effectiveness.items(), 
                                           key=lambda x: x[1], reverse=True)[:3]
                    ]
                },
                "generated_at": now
            }
            
        except Exception as e:
            logger.error(f"Error generating coaching analytics: {e}")
            return {"error": str(e), "generated_at": now}

# Extension to NotificationService to handle coaching messages
# This would be added to the existing notification_service.py

async def create_coaching_notification(
    user_id: str,
    message_id: str,
    title: str,
    body: str,
    action_text: Optional[str] = None,
    action_url: Optional[str] = None,
    priority: str = "medium",
    message_type: str = "coaching"
) -> bool:
    """Create a notification for a coaching message"""
    
    try:
        from ..models.notification import Notification, NotificationType
        
        # Create notification
        notification = Notification(
            user_id=user_id,
            type=NotificationType.COACHING if hasattr(NotificationType, 'COACHING') else NotificationType.ACHIEVEMENT,
            title=title,
            message=body[:500],  # Truncate if too long
            related_id=message_id
        )
        
        await notification.save()
        
        # Here you would integrate with push notification service
        # For now, we'll just log that a notification was created
        logger.info(f"Created coaching notification {notification.id} for user {user_id}")
        
        return True
        
    except Exception as e:
        logger.error(f"Error creating coaching notification: {e}")
        return False

# Add this method to the existing NotificationService class
setattr(NotificationService, 'create_coaching_notification', staticmethod(create_coaching_notification))