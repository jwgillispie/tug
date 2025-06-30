# app/models/friendship.py
from beanie import Document
from pydantic import Field
from typing import Optional
from datetime import datetime
from enum import Enum

class FriendshipStatus(str, Enum):
    PENDING = "pending"
    ACCEPTED = "accepted"
    BLOCKED = "blocked"

class Friendship(Document):
    """Friendship model for managing user relationships"""
    
    requester_id: str = Field(..., description="ID of user who sent friend request")
    addressee_id: str = Field(..., description="ID of user who received friend request")
    status: FriendshipStatus = Field(default=FriendshipStatus.PENDING)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Settings:
        collection = "friendships"
        indexes = [
            [("requester_id", 1), ("addressee_id", 1)],
            "requester_id",
            "addressee_id",
            "status",
        ]
    
    def update_timestamp(self):
        """Update the updated_at timestamp"""
        self.updated_at = datetime.utcnow()