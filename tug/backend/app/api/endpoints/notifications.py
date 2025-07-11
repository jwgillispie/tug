# app/api/endpoints/notifications.py
from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import List, Optional
import logging

from ...models.user import User
from ...schemas.notification import (
    NotificationData, NotificationSummary, MarkNotificationReadRequest,
    NotificationResponse
)
from ...services.notification_service import NotificationService
from ...core.auth import get_current_user

router = APIRouter()
logger = logging.getLogger(__name__)

@router.get("/summary", response_model=NotificationSummary)
async def get_notification_summary(
    current_user: User = Depends(get_current_user)
):
    """Get notification summary for the current user"""
    try:
        summary = await NotificationService.get_notification_summary(current_user)
        return summary
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in get_notification_summary endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get notification summary"
        )

@router.get("", response_model=NotificationResponse)
async def get_notifications(
    limit: int = Query(20, ge=1, le=50, description="Number of notifications to return"),
    skip: int = Query(0, ge=0, description="Number of notifications to skip"),
    unread_only: bool = Query(False, description="Return only unread notifications"),
    current_user: User = Depends(get_current_user)
):
    """Get notifications for the current user"""
    try:
        response = await NotificationService.get_notifications(
            current_user, limit, skip, unread_only
        )
        return response
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in get_notifications endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get notifications"
        )

@router.post("/mark-read")
async def mark_notifications_as_read(
    request: MarkNotificationReadRequest,
    current_user: User = Depends(get_current_user)
):
    """Mark specific notifications as read"""
    try:
        result = await NotificationService.mark_notifications_as_read(current_user, request)
        return result
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in mark_notifications_as_read endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to mark notifications as read"
        )

@router.post("/mark-all-read")
async def mark_all_notifications_as_read(
    current_user: User = Depends(get_current_user)
):
    """Mark all notifications as read for the current user"""
    try:
        result = await NotificationService.mark_all_notifications_as_read(current_user)
        return result
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in mark_all_notifications_as_read endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to mark all notifications as read"
        )

@router.get("/batched/summary", response_model=NotificationSummary)
async def get_batched_notification_summary(
    current_user: User = Depends(get_current_user)
):
    """Get batched notification summary for the current user"""
    try:
        summary = await NotificationService.get_batched_notification_summary(current_user)
        return summary
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in get_batched_notification_summary endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get batched notification summary"
        )

@router.get("/batched", response_model=NotificationResponse)
async def get_batched_notifications(
    limit: int = Query(20, ge=1, le=50, description="Number of batched notifications to return"),
    skip: int = Query(0, ge=0, description="Number of batched notifications to skip"),
    unread_only: bool = Query(False, description="Return only unread batched notifications"),
    current_user: User = Depends(get_current_user)
):
    """Get batched notifications for the current user"""
    try:
        response = await NotificationService.get_batched_notifications(
            current_user, limit, skip, unread_only
        )
        return response
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in get_batched_notifications endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get batched notifications"
        )