# app/models/post_comment.py
from beanie import Document
from pydantic import Field
from typing import List
from datetime import datetime

class PostComment(Document):
    """Comment model for social post interactions"""
    
    post_id: str = Field(..., description="ID of the post this comment belongs to")
    user_id: str = Field(..., description="ID of user who made the comment")
    content: str = Field(..., min_length=1, max_length=300, description="Comment content")
    
    # Engagement
    likes: List[str] = Field(default=[], description="List of user IDs who liked this comment")
    
    # Timestamps
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Settings:
        collection = "post_comments"
        indexes = [
            "post_id",
            "user_id",
            [("post_id", 1), ("created_at", 1)],
            "created_at",
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