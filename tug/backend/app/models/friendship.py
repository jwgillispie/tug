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
            # Core relationship queries - high priority
            [("requester_id", 1), ("addressee_id", 1)],  # Unique relationship lookup
            [("requester_id", 1), ("status", 1)],  # User's outgoing requests by status
            [("addressee_id", 1), ("status", 1)],  # User's incoming requests by status
            
            # Friend discovery and management
            [("status", 1), ("created_at", -1)],  # Recent requests by status
            [("requester_id", 1), ("status", 1), ("created_at", -1)],  # User's requests timeline
            [("addressee_id", 1), ("status", 1), ("created_at", -1)],  # User's received requests timeline
            
            # Analytics queries
            [("status", 1), ("updated_at", -1)],  # Friendship analytics
            [("created_at", -1)],  # Friendship growth metrics
            
            # Bidirectional friendship queries (for friend lists)
            [("requester_id", 1), ("status", 1), ("updated_at", -1)],  # Active friendships
            [("addressee_id", 1), ("status", 1), ("updated_at", -1)],  # Active friendships reverse
            
            # Basic field indexes
            "requester_id",
            "addressee_id", 
            "status"
        ]
    
    def update_timestamp(self):
        """Update the updated_at timestamp"""
        self.updated_at = datetime.utcnow()