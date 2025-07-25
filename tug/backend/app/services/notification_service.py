# app/services/notification_service.py
import logging
from typing import List, Optional
from datetime import datetime
from fastapi import HTTPException, status
from bson import ObjectId

from ..models.user import User
from ..models.notification import Notification, NotificationBatch, NotificationType
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
        """Create a batched notification when someone comments on a post"""
        try:
            if post_owner_id != commenter_id:  # Don't notify about own comments
                # Create the individual notification first
                notification = await Notification.create_comment_notification(
                    user_id=post_owner_id,
                    commenter_id=commenter_id,
                    commenter_name=commenter_name,
                    post_id=post_id,
                    post_content_preview=post_content
                )
                
                # Add to batch
                if notification:
                    await NotificationService._add_to_batch(
                        user_id=post_owner_id,
                        notification_type=NotificationType.COMMENT,
                        notification_id=str(notification.id),
                        related_user_id=commenter_id,
                        related_user_name=commenter_name,
                        related_id=post_id
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
        """Create a batched notification when someone sends a friend request"""
        try:
            # Create the individual notification first
            notification = await Notification.create_friend_request_notification(
                user_id=addressee_id,
                requester_id=requester_id,
                requester_name=requester_name,
                friendship_id=friendship_id
            )
            
            # Add to batch
            if notification:
                await NotificationService._add_to_batch(
                    user_id=addressee_id,
                    notification_type=NotificationType.FRIEND_REQUEST,
                    notification_id=str(notification.id),
                    related_user_id=requester_id,
                    related_user_name=requester_name,
                    related_id=friendship_id
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
        """Create a batched notification when someone accepts a friend request"""
        try:
            # Create the individual notification first
            notification = await Notification.create_friend_accepted_notification(
                user_id=requester_id,
                accepter_id=accepter_id,
                accepter_name=accepter_name,
                friendship_id=friendship_id
            )
            
            # Add to batch
            if notification:
                await NotificationService._add_to_batch(
                    user_id=requester_id,
                    notification_type=NotificationType.FRIEND_ACCEPTED,
                    notification_id=str(notification.id),
                    related_user_id=accepter_id,
                    related_user_name=accepter_name,
                    related_id=friendship_id
                )
        except Exception as e:
            logger.error(f"Error creating friend accepted notification: {e}", exc_info=True)
            # Don't raise exception to avoid breaking friend acceptance
    
    @staticmethod
    async def _add_to_batch(
        user_id: str,
        notification_type: NotificationType,
        notification_id: str,
        related_user_id: str,
        related_user_name: str,
        related_id: Optional[str] = None,
        window_minutes: int = 5
    ):
        """Add a notification to a batch"""
        try:
            # Find or create batch
            batch = await NotificationBatch.find_or_create_batch(
                user_id=user_id,
                batch_type=notification_type,
                related_id=related_id,
                window_minutes=window_minutes
            )
            
            # Add notification to batch
            batch.add_notification(
                notification_id=notification_id,
                user_id=related_user_id,
                user_name=related_user_name
            )
            
            # Save the updated batch
            await batch.save()
            
            logger.info(f"Added notification {notification_id} to batch {batch.id} for user {user_id}")
            
        except Exception as e:
            logger.error(f"Error adding notification to batch: {e}", exc_info=True)
            # Don't raise exception to avoid breaking notification creation
    
    @staticmethod
    async def get_batched_notifications(
        current_user: User,
        limit: int = 20,
        skip: int = 0,
        unread_only: bool = False
    ) -> NotificationResponse:
        """Get batched notifications for the current user"""
        try:
            # Build filter for batches
            filter_dict = {"user_id": str(current_user.id)}
            if unread_only:
                filter_dict["is_read"] = False
            
            # Get batched notifications
            batches = await NotificationBatch.find(filter_dict)\
                .sort([("updated_at", -1)])\
                .skip(skip)\
                .limit(limit)\
                .to_list()
            
            # Get total count
            total_count = await NotificationBatch.find(filter_dict).count()
            
            # Convert batches to notification data format
            notification_data_list = []
            for batch in batches:
                notification_data = NotificationData(
                    id=str(batch.id),
                    user_id=batch.user_id,
                    type=batch.batch_type,
                    title=batch.title,
                    message=batch.message,
                    related_id=batch.related_id,
                    related_user_id=batch.user_ids[0] if batch.user_ids else None,
                    is_read=batch.is_read,
                    created_at=batch.created_at,
                    updated_at=batch.updated_at,
                    related_username=batch.user_names[0] if batch.user_names else None,
                    related_display_name=batch.user_names[0] if batch.user_names else None
                )
                notification_data_list.append(notification_data)
            
            return NotificationResponse(
                notifications=notification_data_list,
                has_more=len(notification_data_list) == limit,
                total_count=total_count
            )
            
        except Exception as e:
            logger.error(f"Error getting batched notifications: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to get batched notifications"
            )
    
    @staticmethod
    async def get_batched_notification_summary(current_user: User) -> NotificationSummary:
        """Get batched notification summary for the current user"""
        try:
            # Get unread count from batches
            unread_count = await NotificationBatch.find({
                "user_id": str(current_user.id),
                "is_read": False
            }).count()
            
            # Get total count from batches
            total_count = await NotificationBatch.find({
                "user_id": str(current_user.id)
            }).count()
            
            # Get latest 3 batched notifications
            latest_batches = await NotificationBatch.find({
                "user_id": str(current_user.id)
            }).sort([("updated_at", -1)]).limit(3).to_list()
            
            # Convert to notification data format
            latest_data = []
            for batch in latest_batches:
                notification_data = NotificationData(
                    id=str(batch.id),
                    user_id=batch.user_id,
                    type=batch.batch_type,
                    title=batch.title,
                    message=batch.message,
                    related_id=batch.related_id,
                    related_user_id=batch.user_ids[0] if batch.user_ids else None,
                    is_read=batch.is_read,
                    created_at=batch.created_at,
                    updated_at=batch.updated_at,
                    related_username=batch.user_names[0] if batch.user_names else None,
                    related_display_name=batch.user_names[0] if batch.user_names else None
                )
                latest_data.append(notification_data)
            
            return NotificationSummary(
                unread_count=unread_count,
                total_count=total_count,
                latest_notifications=latest_data
            )
            
        except Exception as e:
            logger.error(f"Error getting batched notification summary: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to get batched notification summary"
            )