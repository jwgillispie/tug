# app/models/social_post.py
from beanie import Document
from pydantic import Field
from typing import Optional, List
from datetime import datetime
from enum import Enum

class PostType(str, Enum):
    ACTIVITY_UPDATE = "activity_update"
    VICE_PROGRESS = "vice_progress"
    ACHIEVEMENT = "achievement"
    GENERAL = "general"

class SocialPost(Document):
    """Social post model for user activity sharing"""
    
    user_id: str = Field(..., description="ID of user who created the post")
    content: str = Field(..., min_length=1, max_length=500, description="Post content")
    post_type: PostType = Field(default=PostType.GENERAL)
    
    # Optional references to related data
    activity_id: Optional[str] = Field(None, description="Related activity ID")
    vice_id: Optional[str] = Field(None, description="Related vice ID")
    achievement_id: Optional[str] = Field(None, description="Related achievement ID")
    
    # Engagement metrics
    likes: List[str] = Field(default=[], description="List of user IDs who liked this post")
    comments_count: int = Field(default=0, description="Number of comments on this post")
    
    # Privacy and visibility
    is_public: bool = Field(default=True, description="Whether post is visible to all friends")
    
    # Timestamps
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Settings:
        collection = "social_posts"
        indexes = [
            "user_id",
            "post_type",
            "created_at",
            "is_public",
            [("user_id", 1), ("created_at", -1)],
        ]
    
    def update_timestamp(self):
        """Update the updated_at timestamp"""
        self.updated_at = datetime.utcnow()
    
    def add_like(self, user_id: str) -> bool:
        """Add a like from a user. Returns True if like was added, False if already liked"""
        if user_id not in self.likes:
            self.likes.append(user_id)
            self.update_timestamp()
            return True
        return False
    
    def remove_like(self, user_id: str) -> bool:
        """Remove a like from a user. Returns True if like was removed, False if not found"""
        if user_id in self.likes:
            self.likes.remove(user_id)
            self.update_timestamp()
            return True
        return False
    
    def increment_comments(self):
        """Increment comment count"""
        self.comments_count += 1
        self.update_timestamp()
    
    def decrement_comments(self):
        """Decrement comment count"""
        if self.comments_count > 0:
            self.comments_count -= 1
            self.update_timestamp()