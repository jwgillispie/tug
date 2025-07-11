# app/schemas/notification.py
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from ..models.notification import NotificationType

class NotificationData(BaseModel):
    id: str
    user_id: str
    type: NotificationType
    title: str
    message: str
    related_id: Optional[str] = None
    related_user_id: Optional[str] = None
    is_read: bool
    created_at: datetime
    updated_at: datetime
    
    # Additional user info for display
    related_username: Optional[str] = None
    related_display_name: Optional[str] = None

class NotificationSummary(BaseModel):
    unread_count: int
    total_count: int
    latest_notifications: List[NotificationData]

class MarkNotificationReadRequest(BaseModel):
    notification_ids: List[str] = Field(..., description="List of notification IDs to mark as read")

class NotificationResponse(BaseModel):
    notifications: List[NotificationData]
    has_more: bool
    total_count: int