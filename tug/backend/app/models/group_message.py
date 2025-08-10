# app/models/group_message.py
from beanie import Document
from pydantic import Field
from typing import Optional, List, Dict, Any
from datetime import datetime
from enum import Enum

class MessageType(str, Enum):
    TEXT = "text"
    IMAGE = "image"
    VOICE = "voice"
    FILE = "file"
    SYSTEM = "system"
    ANNOUNCEMENT = "announcement"
    THREAD_REPLY = "thread_reply"

class MessageStatus(str, Enum):
    SENDING = "sending"
    SENT = "sent"
    DELIVERED = "delivered"
    READ = "read"
    FAILED = "failed"

class ReactionType(str, Enum):
    LIKE = "like"
    LOVE = "love"
    LAUGH = "laugh"
    WOW = "wow"
    SAD = "sad"
    ANGRY = "angry"
    THUMBS_UP = "thumbs_up"
    THUMBS_DOWN = "thumbs_down"
    FIRE = "fire"
    HEART = "heart"

class GroupMessage(Document):
    """Real-time group messaging model with threading and media support"""
    
    # Basic message information
    group_id: str = Field(..., description="ID of the premium group")
    user_id: str = Field(..., description="ID of user who sent the message")
    content: str = Field(..., min_length=1, max_length=4000, description="Message content")
    message_type: MessageType = Field(default=MessageType.TEXT, description="Type of message")
    
    # Threading support
    thread_id: Optional[str] = Field(None, description="Parent message ID for threaded replies")
    reply_count: int = Field(default=0, description="Number of replies in this thread")
    is_thread_starter: bool = Field(default=False, description="Whether this message started a thread")
    
    # Message status and delivery
    status: MessageStatus = Field(default=MessageStatus.SENT, description="Message delivery status")
    delivery_receipts: List[Dict[str, Any]] = Field(default_factory=list, description="Delivery confirmation data")
    read_receipts: List[Dict[str, Any]] = Field(default_factory=list, description="Read confirmation data")
    
    # Media and attachments
    media_urls: List[str] = Field(default_factory=list, description="Media file URLs")
    attachment_data: Dict[str, Any] = Field(default_factory=dict, description="Structured attachment metadata")
    file_metadata: Optional[Dict[str, Any]] = Field(None, description="File attachment metadata")
    
    # Message features
    is_pinned: bool = Field(default=False, description="Whether message is pinned")
    is_announcement: bool = Field(default=False, description="Whether this is an announcement")
    is_edited: bool = Field(default=False, description="Whether message has been edited")
    edited_at: Optional[datetime] = Field(None, description="When message was last edited")
    
    # Mentions and notifications
    mentioned_user_ids: List[str] = Field(default_factory=list, description="Users mentioned in this message")
    notify_all: bool = Field(default=False, description="Notify all group members")
    
    # Moderation and management
    is_deleted: bool = Field(default=False, description="Whether message is soft deleted")
    deleted_at: Optional[datetime] = Field(None, description="When message was deleted")
    deleted_by: Optional[str] = Field(None, description="Who deleted the message")
    
    # Engagement metrics
    reaction_count: int = Field(default=0, description="Total number of reactions")
    reply_count: int = Field(default=0, description="Number of direct replies")
    
    # Timestamps
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Settings:
        collection = "group_messages"
        indexes = [
            # Core message queries
            [("group_id", 1), ("created_at", -1)],  # Group message timeline
            [("group_id", 1), ("is_deleted", 1), ("created_at", -1)],  # Active messages
            [("group_id", 1), ("message_type", 1), ("created_at", -1)],  # Messages by type
            
            # Threading support
            [("thread_id", 1), ("created_at", 1)],  # Thread replies
            [("group_id", 1), ("is_thread_starter", 1), ("created_at", -1)],  # Thread starters
            [("group_id", 1), ("thread_id", 1)],  # Thread lookup
            
            # User activity
            [("user_id", 1), ("created_at", -1)],  # User's messages
            [("user_id", 1), ("group_id", 1)],  # User's group messages
            
            # Message features
            [("group_id", 1), ("is_pinned", 1)],  # Pinned messages
            [("group_id", 1), ("is_announcement", 1)],  # Announcements
            [("mentioned_user_ids", 1)],  # Mentioned users
            
            # Status and delivery
            [("group_id", 1), ("status", 1)],  # Messages by status
            [("user_id", 1), ("status", 1)],  # User message status
            
            # Search and discovery
            [("group_id", 1), ("content", "text")],  # Content search
            [("group_id", 1), ("attachment_data.filename", 1)],  # File search
            
            # Basic field indexes
            "group_id",
            "user_id",
            "message_type",
            "thread_id",
            "created_at"
        ]
    
    def update_timestamp(self):
        """Update the updated_at timestamp"""
        self.updated_at = datetime.utcnow()
    
    def mark_as_edited(self):
        """Mark message as edited"""
        self.is_edited = True
        self.edited_at = datetime.utcnow()
        self.update_timestamp()
    
    def soft_delete(self, deleted_by: str):
        """Soft delete the message"""
        self.is_deleted = True
        self.deleted_at = datetime.utcnow()
        self.deleted_by = deleted_by
        self.update_timestamp()
    
    def add_delivery_receipt(self, user_id: str, delivered_at: datetime = None):
        """Add delivery confirmation"""
        if delivered_at is None:
            delivered_at = datetime.utcnow()
        
        # Check if receipt already exists
        for receipt in self.delivery_receipts:
            if receipt.get("user_id") == user_id:
                return
        
        self.delivery_receipts.append({
            "user_id": user_id,
            "delivered_at": delivered_at
        })
        
        # Update status if needed
        if self.status == MessageStatus.SENT:
            self.status = MessageStatus.DELIVERED
        
        self.update_timestamp()
    
    def add_read_receipt(self, user_id: str, read_at: datetime = None):
        """Add read confirmation"""
        if read_at is None:
            read_at = datetime.utcnow()
        
        # Check if receipt already exists
        for receipt in self.read_receipts:
            if receipt.get("user_id") == user_id:
                receipt["read_at"] = read_at  # Update read time
                return
        
        self.read_receipts.append({
            "user_id": user_id,
            "read_at": read_at
        })
        
        # Add delivery receipt if not exists
        self.add_delivery_receipt(user_id, read_at)
        
        # Update status
        self.status = MessageStatus.READ
        self.update_timestamp()
    
    def increment_reply_count(self):
        """Increment reply count for threaded messages"""
        self.reply_count += 1
        self.update_timestamp()
    
    def get_mentioned_users(self) -> List[str]:
        """Extract mentioned user IDs from message content and explicit mentions"""
        mentioned = set(self.mentioned_user_ids)
        
        # Parse @mentions from content
        import re
        mention_pattern = r'@(\w+)'
        content_mentions = re.findall(mention_pattern, self.content)
        mentioned.update(content_mentions)
        
        return list(mentioned)


class MessageReaction(Document):
    """Message reactions and emoji responses"""
    
    message_id: str = Field(..., description="ID of the message")
    group_id: str = Field(..., description="ID of the group")
    user_id: str = Field(..., description="ID of user who reacted")
    reaction_type: ReactionType = Field(..., description="Type of reaction")
    
    # Custom reaction support
    custom_emoji: Optional[str] = Field(None, description="Custom emoji code")
    emoji_url: Optional[str] = Field(None, description="Custom emoji image URL")
    
    # Timestamps
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Settings:
        collection = "message_reactions"
        indexes = [
            # Core reaction queries
            [("message_id", 1), ("user_id", 1)],  # User's reaction to message (unique)
            [("message_id", 1), ("reaction_type", 1)],  # Reactions by type
            [("group_id", 1), ("user_id", 1)],  # User's reactions in group
            
            # Analytics
            [("message_id", 1), ("created_at", -1)],  # Recent reactions
            [("user_id", 1), ("created_at", -1)],  # User's recent reactions
            
            # Basic indexes
            "message_id",
            "group_id", 
            "user_id",
            "reaction_type"
        ]
    
    def update_timestamp(self):
        """Update the updated_at timestamp"""
        self.updated_at = datetime.utcnow()


class TypingIndicator(Document):
    """Real-time typing indicators for group chat"""
    
    group_id: str = Field(..., description="ID of the group")
    user_id: str = Field(..., description="ID of user who is typing")
    thread_id: Optional[str] = Field(None, description="Thread ID if typing in a thread")
    
    # Typing status
    is_typing: bool = Field(default=True, description="Whether user is currently typing")
    last_typed_at: datetime = Field(default_factory=datetime.utcnow)
    
    # Auto-expire typing indicators after 10 seconds of inactivity
    expires_at: datetime = Field(default_factory=lambda: datetime.utcnow())
    
    class Settings:
        collection = "typing_indicators"
        indexes = [
            [("group_id", 1), ("is_typing", 1)],  # Active typing users in group
            [("group_id", 1), ("thread_id", 1), ("is_typing", 1)],  # Thread typing
            [("user_id", 1), ("last_typed_at", -1)],  # User's typing activity
            [("expires_at", 1)],  # TTL index for auto-cleanup
            
            "group_id",
            "user_id"
        ]
    
    def refresh_typing(self):
        """Refresh typing indicator timestamp"""
        self.last_typed_at = datetime.utcnow()
        self.expires_at = datetime.utcnow()
        self.is_typing = True
    
    def stop_typing(self):
        """Stop typing indicator"""
        self.is_typing = False
        self.last_typed_at = datetime.utcnow()


class MessageQueue(Document):
    """Queue for offline message delivery and failed message retry"""
    
    message_id: str = Field(..., description="ID of the message to deliver")
    group_id: str = Field(..., description="ID of the group")
    recipient_user_ids: List[str] = Field(..., description="List of users to deliver to")
    
    # Queue status
    status: str = Field(default="pending", description="Queue status: pending, processing, completed, failed")
    retry_count: int = Field(default=0, description="Number of delivery attempts")
    max_retries: int = Field(default=3, description="Maximum retry attempts")
    
    # Queue metadata
    priority: int = Field(default=1, description="Delivery priority (1-5, 5 being highest)")
    delivery_type: str = Field(default="realtime", description="Delivery type: realtime, push, email")
    
    # Timestamps
    created_at: datetime = Field(default_factory=datetime.utcnow)
    scheduled_for: datetime = Field(default_factory=datetime.utcnow)
    last_attempt_at: Optional[datetime] = Field(None)
    completed_at: Optional[datetime] = Field(None)
    
    class Settings:
        collection = "message_queue"
        indexes = [
            [("status", 1), ("scheduled_for", 1)],  # Pending messages to process
            [("group_id", 1), ("status", 1)],  # Group message queue
            [("message_id", 1)],  # Message queue lookup
            [("recipient_user_ids", 1)],  # User delivery queue
            [("priority", -1), ("created_at", 1)],  # Priority queue
            
            "status",
            "scheduled_for",
            "created_at"
        ]
    
    def increment_retry(self):
        """Increment retry count and update timestamp"""
        self.retry_count += 1
        self.last_attempt_at = datetime.utcnow()
        
        if self.retry_count >= self.max_retries:
            self.status = "failed"
        
    def mark_completed(self):
        """Mark queue item as completed"""
        self.status = "completed"
        self.completed_at = datetime.utcnow()