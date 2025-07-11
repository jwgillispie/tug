# app/services/notification_service.py
import logging
from typing import List, Optional
from datetime import datetime
from fastapi import HTTPException, status
from bson import ObjectId

from ..models.user import User
from ..models.notification import Notification, NotificationType
from ..schemas.notification import (
    NotificationData, NotificationSummary, 
    MarkNotificationReadRequest, NotificationResponse
)

logger = logging.getLogger(__name__)

class NotificationService:
    
    @staticmethod
    async def get_notifications(
        current_user: User, 
        limit: int = 20, 
        skip: int = 0,
        unread_only: bool = False
    ) -> NotificationResponse:
        """Get notifications for the current user"""
        try:
            # Build filter
            filter_dict = {"user_id": str(current_user.id)}
            if unread_only:
                filter_dict["is_read"] = False
            
            # Get notifications
            notifications = await Notification.find(filter_dict)\
                .sort([("created_at", -1)])\
                .skip(skip)\
                .limit(limit)\
                .to_list()
            
            # Get total count
            total_count = await Notification.find(filter_dict).count()
            
            # Get user info for notifications with related users
            related_user_ids = [n.related_user_id for n in notifications if n.related_user_id]
            users = []
            if related_user_ids:
                users = await User.find({"_id": {"$in": [ObjectId(uid) for uid in related_user_ids]}}).to_list()
            user_map = {str(user.id): user for user in users}
            
            # Build notification data with user info
            notification_data_list = []
            for notification in notifications:
                related_user = user_map.get(notification.related_user_id) if notification.related_user_id else None
                
                # Ensure related user has username
                if related_user and not related_user.username:
                    await related_user.ensure_username()
                
                notification_data = NotificationData(
                    id=str(notification.id),
                    user_id=notification.user_id,
                    type=notification.type,
                    title=notification.title,
                    message=notification.message,
                    related_id=notification.related_id,
                    related_user_id=notification.related_user_id,
                    is_read=notification.is_read,
                    created_at=notification.created_at,
                    updated_at=notification.updated_at,
                    related_username=related_user.username or related_user.effective_username if related_user else None,
                    related_display_name=related_user.display_name if related_user else None
                )
                notification_data_list.append(notification_data)
            
            return NotificationResponse(
                notifications=notification_data_list,
                has_more=len(notification_data_list) == limit,
                total_count=total_count
            )
            
        except Exception as e:
            logger.error(f"Error getting notifications: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to get notifications"
            )
    
    @staticmethod
    async def get_notification_summary(current_user: User) -> NotificationSummary:
        """Get notification summary for the current user"""
        try:
            # Get unread count
            unread_count = await Notification.find({
                "user_id": str(current_user.id),
                "is_read": False
            }).count()
            
            # Get total count
            total_count = await Notification.find({
                "user_id": str(current_user.id)
            }).count()
            
            # Get latest 3 notifications
            latest_notifications = await Notification.find({
                "user_id": str(current_user.id)
            }).sort([("created_at", -1)]).limit(3).to_list()
            
            # Get user info for latest notifications
            related_user_ids = [n.related_user_id for n in latest_notifications if n.related_user_id]
            users = []
            if related_user_ids:
                users = await User.find({"_id": {"$in": [ObjectId(uid) for uid in related_user_ids]}}).to_list()
            user_map = {str(user.id): user for user in users}
            
            # Build latest notification data
            latest_data = []
            for notification in latest_notifications:
                related_user = user_map.get(notification.related_user_id) if notification.related_user_id else None
                
                # Ensure related user has username
                if related_user and not related_user.username:
                    await related_user.ensure_username()
                
                notification_data = NotificationData(
                    id=str(notification.id),
                    user_id=notification.user_id,
                    type=notification.type,
                    title=notification.title,
                    message=notification.message,
                    related_id=notification.related_id,
                    related_user_id=notification.related_user_id,
                    is_read=notification.is_read,
                    created_at=notification.created_at,
                    updated_at=notification.updated_at,
                    related_username=related_user.username or related_user.effective_username if related_user else None,
                    related_display_name=related_user.display_name if related_user else None
                )
                latest_data.append(notification_data)
            
            return NotificationSummary(
                unread_count=unread_count,
                total_count=total_count,
                latest_notifications=latest_data
            )
            
        except Exception as e:
            logger.error(f"Error getting notification summary: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to get notification summary"
            )
    
    @staticmethod
    async def mark_notifications_as_read(
        current_user: User, 
        request: MarkNotificationReadRequest
    ) -> dict:
        """Mark specific notifications as read"""
        try:
            # Update notifications
            result = await Notification.find({
                "_id": {"$in": [ObjectId(nid) for nid in request.notification_ids]},
                "user_id": str(current_user.id)  # Ensure user can only mark their own notifications
            }).update_many({"$set": {"is_read": True, "updated_at": datetime.utcnow()}})
            
            logger.info(f"Marked {result.modified_count} notifications as read for user {current_user.id}")
            
            return {
                "success": True,
                "marked_count": result.modified_count
            }
            
        except Exception as e:
            logger.error(f"Error marking notifications as read: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to mark notifications as read"
            )
    
    @staticmethod
    async def mark_all_notifications_as_read(current_user: User) -> dict:
        """Mark all notifications as read for the current user"""
        try:
            # Update all unread notifications for the user
            result = await Notification.find({
                "user_id": str(current_user.id),
                "is_read": False
            }).update_many({"$set": {"is_read": True, "updated_at": datetime.utcnow()}})
            
            logger.info(f"Marked all {result.modified_count} notifications as read for user {current_user.id}")
            
            return {
                "success": True,
                "marked_count": result.modified_count
            }
            
        except Exception as e:
            logger.error(f"Error marking all notifications as read: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to mark all notifications as read"
            )
    
    @staticmethod
    async def create_comment_notification(
        post_owner_id: str,
        commenter_id: str,
        commenter_name: str,
        post_id: str,
        post_content: str
    ):
        """Create a notification when someone comments on a post"""
        try:
            if post_owner_id != commenter_id:  # Don't notify about own comments
                await Notification.create_comment_notification(
                    user_id=post_owner_id,
                    commenter_id=commenter_id,
                    commenter_name=commenter_name,
                    post_id=post_id,
                    post_content_preview=post_content
                )
        except Exception as e:
            logger.error(f"Error creating comment notification: {e}", exc_info=True)
            # Don't raise exception to avoid breaking comment creation
    
    @staticmethod
    async def create_friend_request_notification(
        addressee_id: str,
        requester_id: str,
        requester_name: str,
        friendship_id: str
    ):
        """Create a notification when someone sends a friend request"""
        try:
            await Notification.create_friend_request_notification(
                user_id=addressee_id,
                requester_id=requester_id,
                requester_name=requester_name,
                friendship_id=friendship_id
            )
        except Exception as e:
            logger.error(f"Error creating friend request notification: {e}", exc_info=True)
            # Don't raise exception to avoid breaking friend request
    
    @staticmethod
    async def create_friend_accepted_notification(
        requester_id: str,
        accepter_id: str,
        accepter_name: str,
        friendship_id: str
    ):
        """Create a notification when someone accepts a friend request"""
        try:
            await Notification.create_friend_accepted_notification(
                user_id=requester_id,
                accepter_id=accepter_id,
                accepter_name=accepter_name,
                friendship_id=friendship_id
            )
        except Exception as e:
            logger.error(f"Error creating friend accepted notification: {e}", exc_info=True)
            # Don't raise exception to avoid breaking friend acceptance