# app/schemas/group_message.py
from pydantic import BaseModel, Field, validator
from typing import Optional, List, Dict, Any, Union
from datetime import datetime
from enum import Enum

from ..models.group_message import MessageType, MessageStatus, ReactionType

# Request Schemas
class SendMessageRequest(BaseModel):
    """Request schema for sending a new message"""
    content: str = Field(..., min_length=1, max_length=4000, description="Message content")
    message_type: MessageType = Field(default=MessageType.TEXT, description="Type of message")
    thread_id: Optional[str] = Field(None, description="Parent message ID for replies")
    mentioned_user_ids: List[str] = Field(default_factory=list, description="Users to mention")
    notify_all: bool = Field(default=False, description="Notify all group members")
    is_announcement: bool = Field(default=False, description="Whether this is an announcement")
    
    # Media attachments
    media_urls: List[str] = Field(default_factory=list, description="Media file URLs")
    attachment_data: Dict[str, Any] = Field(default_factory=dict, description="Attachment metadata")
    
    @validator('content')
    def validate_content(cls, v):
        if not v or not v.strip():
            raise ValueError('Message content cannot be empty')
        return v.strip()
    
    @validator('media_urls')
    def validate_media_urls(cls, v):
        if len(v) > 10:  # Limit media attachments
            raise ValueError('Maximum 10 media attachments allowed per message')
        return v

class EditMessageRequest(BaseModel):
    """Request schema for editing a message"""
    content: str = Field(..., min_length=1, max_length=4000, description="Updated message content")
    mentioned_user_ids: List[str] = Field(default_factory=list, description="Updated mentions")
    
    @validator('content')
    def validate_content(cls, v):
        if not v or not v.strip():
            raise ValueError('Message content cannot be empty')
        return v.strip()

class ReactToMessageRequest(BaseModel):
    """Request schema for reacting to a message"""
    reaction_type: ReactionType = Field(..., description="Type of reaction")
    custom_emoji: Optional[str] = Field(None, description="Custom emoji code")

class MarkMessagesReadRequest(BaseModel):
    """Request schema for marking messages as read"""
    message_ids: List[str] = Field(..., min_items=1, description="List of message IDs to mark as read")
    read_at: Optional[datetime] = Field(None, description="When messages were read")

class MessageSearchRequest(BaseModel):
    """Request schema for searching messages"""
    query: str = Field(..., min_length=1, description="Search query")
    message_type: Optional[MessageType] = Field(None, description="Filter by message type")
    user_id: Optional[str] = Field(None, description="Filter by user")
    thread_id: Optional[str] = Field(None, description="Search within specific thread")
    date_from: Optional[datetime] = Field(None, description="Search from date")
    date_to: Optional[datetime] = Field(None, description="Search to date")
    limit: int = Field(default=20, ge=1, le=100, description="Number of results")
    skip: int = Field(default=0, ge=0, description="Number of results to skip")

class TypingIndicatorRequest(BaseModel):
    """Request schema for typing indicators"""
    is_typing: bool = Field(..., description="Whether user is typing")
    thread_id: Optional[str] = Field(None, description="Thread ID if typing in thread")

# Response Schemas
class MessageAuthor(BaseModel):
    """Message author information"""
    id: str = Field(..., description="User ID")
    username: str = Field(..., description="Username")
    display_name: Optional[str] = Field(None, description="Display name")
    avatar_url: Optional[str] = Field(None, description="Profile picture URL")
    role: Optional[str] = Field(None, description="Role in group")

class MessageReactionData(BaseModel):
    """Message reaction data"""
    reaction_type: ReactionType = Field(..., description="Type of reaction")
    count: int = Field(..., description="Number of users with this reaction")
    user_ids: List[str] = Field(..., description="Users who reacted")
    user_reacted: bool = Field(default=False, description="Whether current user reacted")
    custom_emoji: Optional[str] = Field(None, description="Custom emoji code")

class MessageData(BaseModel):
    """Complete message data for API responses"""
    id: str = Field(..., description="Message ID")
    group_id: str = Field(..., description="Group ID")
    user_id: str = Field(..., description="Sender user ID")
    content: str = Field(..., description="Message content")
    message_type: MessageType = Field(..., description="Message type")
    status: MessageStatus = Field(..., description="Message status")
    
    # Author information
    author: MessageAuthor = Field(..., description="Message author details")
    
    # Threading
    thread_id: Optional[str] = Field(None, description="Parent message ID for replies")
    reply_count: int = Field(default=0, description="Number of replies")
    is_thread_starter: bool = Field(default=False, description="Whether this starts a thread")
    
    # Message features
    is_pinned: bool = Field(default=False, description="Whether message is pinned")
    is_announcement: bool = Field(default=False, description="Whether this is an announcement")
    is_edited: bool = Field(default=False, description="Whether message was edited")
    is_deleted: bool = Field(default=False, description="Whether message is deleted")
    
    # Timestamps
    created_at: datetime = Field(..., description="When message was created")
    updated_at: datetime = Field(..., description="When message was last updated")
    edited_at: Optional[datetime] = Field(None, description="When message was edited")
    
    # Media and attachments
    media_urls: List[str] = Field(default_factory=list, description="Media URLs")
    attachment_data: Dict[str, Any] = Field(default_factory=dict, description="Attachment metadata")
    
    # Engagement
    mentioned_user_ids: List[str] = Field(default_factory=list, description="Mentioned users")
    reactions: List[MessageReactionData] = Field(default_factory=list, description="Message reactions")
    
    # Read receipts (for sender only)
    delivery_count: int = Field(default=0, description="Number of users message was delivered to")
    read_count: int = Field(default=0, description="Number of users who read message")
    
    # User context
    user_can_edit: bool = Field(default=False, description="Whether current user can edit")
    user_can_delete: bool = Field(default=False, description="Whether current user can delete")

class ThreadData(BaseModel):
    """Thread conversation data"""
    thread_starter: MessageData = Field(..., description="Original message that started thread")
    replies: List[MessageData] = Field(..., description="Thread replies")
    total_replies: int = Field(..., description="Total number of replies in thread")
    participants: List[MessageAuthor] = Field(..., description="Thread participants")

class MessageListResponse(BaseModel):
    """Response schema for message list endpoints"""
    messages: List[MessageData] = Field(..., description="List of messages")
    has_more: bool = Field(..., description="Whether more messages are available")
    total_count: int = Field(..., description="Total number of messages")
    last_message_at: Optional[datetime] = Field(None, description="Timestamp of last message")

class MessageSearchResponse(BaseModel):
    """Response schema for message search"""
    results: List[MessageData] = Field(..., description="Search results")
    total_results: int = Field(..., description="Total number of matching messages")
    query: str = Field(..., description="Search query used")
    has_more: bool = Field(..., description="Whether more results are available")

class TypingUser(BaseModel):
    """User who is currently typing"""
    user_id: str = Field(..., description="User ID")
    username: str = Field(..., description="Username") 
    display_name: Optional[str] = Field(None, description="Display name")
    thread_id: Optional[str] = Field(None, description="Thread being typed in")

class TypingIndicatorResponse(BaseModel):
    """Response schema for typing indicators"""
    group_id: str = Field(..., description="Group ID")
    typing_users: List[TypingUser] = Field(..., description="Users currently typing")
    count: int = Field(..., description="Number of users typing")

# WebSocket Message Schemas
class WebSocketMessageType(str, Enum):
    # Outgoing (server -> client)
    MESSAGE = "message"
    MESSAGE_UPDATED = "message_updated"
    MESSAGE_DELETED = "message_deleted"
    MESSAGE_REACTION = "message_reaction"
    TYPING_START = "typing_start"
    TYPING_STOP = "typing_stop"
    USER_JOINED = "user_joined"
    USER_LEFT = "user_left"
    THREAD_REPLY = "thread_reply"
    MESSAGE_READ = "message_read"
    ERROR = "error"
    PONG = "pong"
    
    # Incoming (client -> server)
    SEND_MESSAGE = "send_message"
    EDIT_MESSAGE = "edit_message"
    DELETE_MESSAGE = "delete_message"
    REACT_TO_MESSAGE = "react_to_message"
    MARK_READ = "mark_read"
    START_TYPING = "start_typing"
    STOP_TYPING = "stop_typing"
    JOIN_THREAD = "join_thread"
    LEAVE_THREAD = "leave_thread"
    PING = "ping"

class WebSocketMessage(BaseModel):
    """Base WebSocket message structure"""
    type: WebSocketMessageType = Field(..., description="Message type")
    group_id: str = Field(..., description="Group ID")
    data: Dict[str, Any] = Field(default_factory=dict, description="Message payload")
    timestamp: datetime = Field(default_factory=datetime.utcnow, description="Message timestamp")
    message_id: Optional[str] = Field(None, description="Unique message ID for tracking")

class WebSocketError(BaseModel):
    """WebSocket error message"""
    error_code: str = Field(..., description="Error code")
    error_message: str = Field(..., description="Human-readable error message")
    details: Optional[Dict[str, Any]] = Field(None, description="Additional error details")

# Media Upload Schemas
class MediaUploadRequest(BaseModel):
    """Request schema for media upload"""
    file_type: str = Field(..., description="File type (image, voice, file)")
    filename: str = Field(..., description="Original filename")
    file_size: int = Field(..., description="File size in bytes")
    mime_type: str = Field(..., description="File MIME type")
    
    @validator('file_size')
    def validate_file_size(cls, v):
        max_sizes = {
            'image': 10 * 1024 * 1024,    # 10MB
            'voice': 25 * 1024 * 1024,    # 25MB
            'file': 50 * 1024 * 1024      # 50MB
        }
        # Default max size
        if v > max_sizes.get('file', 50 * 1024 * 1024):
            raise ValueError('File size exceeds maximum allowed')
        return v

class MediaUploadResponse(BaseModel):
    """Response schema for media upload"""
    upload_url: str = Field(..., description="Pre-signed URL for file upload")
    file_id: str = Field(..., description="Unique file identifier")
    file_url: str = Field(..., description="URL for accessing uploaded file")
    expires_at: datetime = Field(..., description="When upload URL expires")

# Group Chat Summary Schemas
class GroupChatSummary(BaseModel):
    """Summary of group chat activity"""
    group_id: str = Field(..., description="Group ID")
    total_messages: int = Field(..., description="Total messages in group")
    messages_today: int = Field(..., description="Messages sent today")
    active_participants: int = Field(..., description="Number of active participants")
    last_message: Optional[MessageData] = Field(None, description="Most recent message")
    unread_count: int = Field(..., description="Number of unread messages for user")
    user_mentions: int = Field(..., description="Number of unread mentions for user")

class GroupChatStats(BaseModel):
    """Detailed group chat statistics"""
    group_id: str = Field(..., description="Group ID")
    total_messages: int = Field(..., description="Total messages")
    total_threads: int = Field(..., description="Total message threads")
    total_reactions: int = Field(..., description="Total reactions")
    most_active_users: List[Dict[str, Any]] = Field(..., description="Most active users")
    popular_reactions: List[Dict[str, Any]] = Field(..., description="Most used reactions")
    peak_activity_hours: List[int] = Field(..., description="Hours with most activity")
    average_messages_per_day: float = Field(..., description="Average daily messages")
    response_time_avg: float = Field(..., description="Average response time in minutes")