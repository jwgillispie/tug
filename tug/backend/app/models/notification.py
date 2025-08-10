# app/models/notification.py
from beanie import Document
from pydantic import Field
from typing import Optional, List, Dict, Any
from datetime import datetime, timedelta
from enum import Enum

class NotificationType(str, Enum):
    COMMENT = "comment"
    FRIEND_REQUEST = "friend_request"
    FRIEND_ACCEPTED = "friend_accepted"
    POST_MENTION = "post_mention"
    ACHIEVEMENT = "achievement"
    MILESTONE = "milestone"
    COACHING = "coaching"
    LIKE = "like"
    GROUP_INVITATION = "group_invitation"
    GROUP_ACTIVITY = "group_activity"
    GROUP_POST = "group_post"
    GROUP_CHALLENGE = "group_challenge"

class Notification(Document):
    """Notification model for user activity notifications"""
    
    user_id: str = Field(..., description="ID of user who will receive the notification")
    type: NotificationType = Field(..., description="Type of notification")
    title: str = Field(..., min_length=1, max_length=200, description="Notification title")
    message: str = Field(..., min_length=1, max_length=500, description="Notification message")
    
    # Related data
    related_id: Optional[str] = Field(None, description="Related entity ID (post, comment, friend request, etc.)")
    related_user_id: Optional[str] = Field(None, description="User who triggered the notification")
    metadata: Dict[str, Any] = Field(default_factory=dict, description="Additional notification metadata")
    
    # Status
    is_read: bool = Field(default=False, description="Whether the notification has been read")
    
    # Timestamps
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Settings:
        collection = "notifications"
        indexes = [
            "user_id",
            "type",
            "is_read",
            "created_at",
            [("user_id", 1), ("is_read", 1), ("created_at", -1)],
            [("user_id", 1), ("created_at", -1)],
        ]
    
    def update_timestamp(self):
        """Update the updated_at timestamp"""
        self.updated_at = datetime.utcnow()
    
    def mark_as_read(self):
        """Mark notification as read"""
        self.is_read = True
        self.update_timestamp()
    
    @classmethod
    async def create_comment_notification(
        cls,
        user_id: str,
        commenter_id: str,
        commenter_name: str,
        post_id: str,
        post_content_preview: str
    ) -> "Notification":
        """Create a notification for a new comment"""
        # Don't notify users about their own comments
        if user_id == commenter_id:
            return None
            
        notification = cls(
            user_id=user_id,
            type=NotificationType.COMMENT,
            title=f"{commenter_name} commented on your post",
            message=f'"{post_content_preview[:50]}{"..." if len(post_content_preview) > 50 else ""}"',
            related_id=post_id,
            related_user_id=commenter_id
        )
        await notification.save()
        return notification
    
    @classmethod
    async def create_friend_request_notification(
        cls,
        user_id: str,
        requester_id: str,
        requester_name: str,
        friendship_id: str
    ) -> "Notification":
        """Create a notification for a friend request"""
        notification = cls(
            user_id=user_id,
            type=NotificationType.FRIEND_REQUEST,
            title=f"{requester_name} sent you a friend request",
            message="Tap to view and respond to the friend request",
            related_id=friendship_id,
            related_user_id=requester_id
        )
        await notification.save()
        return notification
    
    @classmethod
    async def create_friend_accepted_notification(
        cls,
        user_id: str,
        accepter_id: str,
        accepter_name: str,
        friendship_id: str
    ) -> "Notification":
        """Create a notification for an accepted friend request"""
        notification = cls(
            user_id=user_id,
            type=NotificationType.FRIEND_ACCEPTED,
            title=f"{accepter_name} accepted your friend request",
            message="You are now friends! Check out their recent activity",
            related_id=friendship_id,
            related_user_id=accepter_id
        )
        await notification.save()
        return notification
    
    @classmethod
    async def create_milestone_notification(
        cls,
        user_id: str,
        milestone_type: str,
        milestone_value: int,
        entity_name: str
    ) -> "Notification":
        """Create a notification for milestone achievements"""
        notification = cls(
            user_id=user_id,
            type=NotificationType.MILESTONE,
            title=f"🎯 {milestone_value} days milestone reached!",
            message=f"Congratulations on {milestone_value} days of progress with {entity_name}!",
            related_id=None,
            related_user_id=None
        )
        await notification.save()
        return notification


class NotificationBatch(Document):
    """Notification batch model for grouping related notifications"""
    
    user_id: str = Field(..., description="ID of user who will receive the batched notification")
    batch_type: NotificationType = Field(..., description="Type of notifications in this batch")
    related_id: Optional[str] = Field(None, description="Related entity ID (post, comment, etc.)")
    
    # Batch content
    title: str = Field(..., min_length=1, max_length=200, description="Batched notification title")
    message: str = Field(..., min_length=1, max_length=500, description="Batched notification message")
    notification_ids: List[str] = Field(default_factory=list, description="IDs of notifications in this batch")
    user_ids: List[str] = Field(default_factory=list, description="IDs of users who triggered notifications")
    user_names: List[str] = Field(default_factory=list, description="Names of users who triggered notifications")
    
    # Batch metadata
    notification_count: int = Field(default=1, description="Number of notifications in this batch")
    batch_window_start: datetime = Field(..., description="Start of the batching time window")
    batch_window_end: datetime = Field(..., description="End of the batching time window")
    
    # Status
    is_read: bool = Field(default=False, description="Whether the batched notification has been read")
    is_active: bool = Field(default=True, description="Whether this batch is still collecting notifications")
    
    # Timestamps
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Settings:
        collection = "notification_batches"
        indexes = [
            "user_id",
            "batch_type",
            "is_read",
            "is_active",
            "batch_window_end",
            [("user_id", 1), ("batch_type", 1), ("related_id", 1), ("is_active", 1)],
            [("user_id", 1), ("is_read", 1), ("updated_at", -1)],
        ]
    
    def update_timestamp(self):
        """Update the updated_at timestamp"""
        self.updated_at = datetime.utcnow()
    
    def mark_as_read(self):
        """Mark batched notification as read"""
        self.is_read = True
        self.update_timestamp()
    
    def close_batch(self):
        """Close this batch to prevent further additions"""
        self.is_active = False
        self.update_timestamp()
    
    def add_notification(self, notification_id: str, user_id: str, user_name: str):
        """Add a notification to this batch"""
        if notification_id not in self.notification_ids:
            self.notification_ids.append(notification_id)
            if user_id not in self.user_ids:
                self.user_ids.append(user_id)
                self.user_names.append(user_name)
            self.notification_count = len(self.notification_ids)
            self._update_batch_message()
            self.update_timestamp()
    
    def _update_batch_message(self):
        """Update the batch message based on current content"""
        if self.batch_type == NotificationType.COMMENT:
            if self.notification_count == 1:
                self.title = f"{self.user_names[0]} commented on your post"
                self.message = "Tap to view the comment"
            elif self.notification_count == 2:
                self.title = f"{self.user_names[0]} and {self.user_names[1]} commented on your post"
                self.message = "Tap to view the comments"
            else:
                others_count = self.notification_count - 1
                self.title = f"{self.user_names[0]} and {others_count} others commented on your post"
                self.message = f"Tap to view all {self.notification_count} comments"
        
        elif self.batch_type == NotificationType.FRIEND_REQUEST:
            if self.notification_count == 1:
                self.title = f"{self.user_names[0]} sent you a friend request"
                self.message = "Tap to view and respond"
            else:
                self.title = f"You have {self.notification_count} new friend requests"
                self.message = f"From {self.user_names[0]} and {self.notification_count - 1} others"
        
        elif self.batch_type == NotificationType.FRIEND_ACCEPTED:
            if self.notification_count == 1:
                self.title = f"{self.user_names[0]} accepted your friend request"
                self.message = "You are now friends!"
            else:
                self.title = f"{self.notification_count} people accepted your friend requests"
                self.message = f"{self.user_names[0]} and {self.notification_count - 1} others are now your friends"
    
    @classmethod
    async def find_or_create_batch(
        cls,
        user_id: str,
        batch_type: NotificationType,
        related_id: Optional[str] = None,
        window_minutes: int = 5
    ) -> "NotificationBatch":
        """Find an existing active batch or create a new one"""
        
        # Calculate the current batch window
        now = datetime.utcnow()
        window_start = now - timedelta(minutes=window_minutes)
        
        # Try to find an existing active batch
        existing_batch = await cls.find_one({
            "user_id": user_id,
            "batch_type": batch_type,
            "related_id": related_id,
            "is_active": True,
            "batch_window_end": {"$gt": now}
        })
        
        if existing_batch:
            return existing_batch
        
        # Create a new batch
        batch = cls(
            user_id=user_id,
            batch_type=batch_type,
            related_id=related_id,
            title="",  # Will be set when first notification is added
            message="",  # Will be set when first notification is added
            batch_window_start=window_start,
            batch_window_end=now + timedelta(minutes=window_minutes)
        )
        await batch.save()
        return batch