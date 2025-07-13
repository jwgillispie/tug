# app/models/social_post.py
from beanie import Document
from pydantic import Field
from typing import Optional, List
from datetime import datetime
from enum import Enum

class PostType(str, Enum):
    ACTIVITY_UPDATE = "activity_update"
    VICE_PROGRESS = "vice_progress"
    VICE_INDULGENCE = "vice_indulgence"
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
    
    
    def increment_comments(self):
        """Increment comment count"""
        self.comments_count += 1
        self.update_timestamp()
    
    def decrement_comments(self):
        """Decrement comment count"""
        if self.comments_count > 0:
            self.comments_count -= 1
            self.update_timestamp()