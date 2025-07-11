# app/models/notification.py
from beanie import Document
from pydantic import Field
from typing import Optional
from datetime import datetime
from enum import Enum

class NotificationType(str, Enum):
    COMMENT = "comment"
    FRIEND_REQUEST = "friend_request"
    FRIEND_ACCEPTED = "friend_accepted"
    POST_MENTION = "post_mention"
    ACHIEVEMENT = "achievement"
    MILESTONE = "milestone"

class Notification(Document):
    """Notification model for user activity notifications"""
    
    user_id: str = Field(..., description="ID of user who will receive the notification")
    type: NotificationType = Field(..., description="Type of notification")
    title: str = Field(..., min_length=1, max_length=200, description="Notification title")
    message: str = Field(..., min_length=1, max_length=500, description="Notification message")
    
    # Related data
    related_id: Optional[str] = Field(None, description="Related entity ID (post, comment, friend request, etc.)")
    related_user_id: Optional[str] = Field(None, description="User who triggered the notification")
    
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