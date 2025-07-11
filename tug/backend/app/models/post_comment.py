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
    
