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
            # Core query patterns - high priority
            [("user_id", 1), ("created_at", -1)],  # User's posts timeline
            [("is_public", 1), ("created_at", -1)],  # Public feed
            [("post_type", 1), ("created_at", -1)],  # Posts by type
            
            # Feed and discovery queries
            [("is_public", 1), ("post_type", 1), ("created_at", -1)],  # Filtered public feed
            [("user_id", 1), ("is_public", 1), ("created_at", -1)],  # User's public posts
            [("user_id", 1), ("post_type", 1), ("created_at", -1)],  # User's posts by type
            
            # Engagement analytics
            [("comments_count", -1), ("created_at", -1)],  # Popular posts
            [("user_id", 1), ("comments_count", -1)],  # User's popular posts
            
            # Reference lookups
            [("activity_id", 1)],  # Activity-related posts
            [("vice_id", 1)],  # Vice-related posts
            [("achievement_id", 1)],  # Achievement posts
            
            # Compound reference queries
            [("user_id", 1), ("activity_id", 1)],  # User's activity posts
            [("user_id", 1), ("vice_id", 1)],  # User's vice posts
            
            # Basic field indexes
            "user_id",
            "post_type", 
            "created_at",
            "is_public"
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