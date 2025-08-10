# app/services/group_messaging_service.py
import logging
import asyncio
from typing import Optional, List, Dict, Any, Tuple
from datetime import datetime, timedelta
from uuid import uuid4

from fastapi import HTTPException, status
from motor.motor_asyncio import AsyncIOMotorDatabase
from pymongo import DESCENDING, ASCENDING
from beanie import PydanticObjectId

from ..models.user import User
from ..models.premium_group import GroupMembership, MembershipStatus, GroupRole, PremiumGroup
from ..models.group_message import (
    GroupMessage, MessageReaction, TypingIndicator, MessageQueue,
    MessageType, MessageStatus, ReactionType
)
from ..schemas.group_message import (
    SendMessageRequest, EditMessageRequest, ReactToMessageRequest,
    MarkMessagesReadRequest, MessageSearchRequest, TypingIndicatorRequest,
    MessageData, MessageAuthor, MessageReactionData, MessageListResponse,
    MessageSearchResponse, TypingUser, TypingIndicatorResponse,
    WebSocketMessage, WebSocketMessageType
)
from ..core.database import get_database
from ..services.websocket_manager import websocket_manager
from ..services.notification_service import NotificationService
from ..utils.validation import sanitize_text_content

logger = logging.getLogger(__name__)

class GroupMessagingService:
    """Comprehensive service for real-time group messaging"""
    
    def __init__(self):
        self.db = None
        
    async def _get_db(self) -> AsyncIOMotorDatabase:
        """Get database connection"""
        if not self.db:
            self.db = await get_database()
        return self.db
    
    async def send_message(
        self, 
        current_user: User, 
        group_id: str, 
        message_data: SendMessageRequest
    ) -> MessageData:
        """Send a new message to a group"""
        try:
            # Verify group membership and permissions
            membership = await self._verify_group_access(current_user.id, group_id)
            group = await PremiumGroup.get(group_id)
            
            if not group or not membership:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Access denied to group"
                )
            
            # Check if replying to thread
            parent_message = None
            if message_data.thread_id:
                parent_message = await GroupMessage.get(message_data.thread_id)
                if not parent_message or parent_message.group_id != group_id:
                    raise HTTPException(
                        status_code=status.HTTP_400_BAD_REQUEST,
                        detail="Invalid thread ID"
                    )
            
            # Sanitize content
            sanitized_content = sanitize_text_content(message_data.content)
            
            # Create message
            message = GroupMessage(
                group_id=group_id,
                user_id=current_user.id,
                content=sanitized_content,
                message_type=message_data.message_type,
                thread_id=message_data.thread_id,
                mentioned_user_ids=message_data.mentioned_user_ids,
                notify_all=message_data.notify_all,
                is_announcement=message_data.is_announcement and self._can_create_announcements(membership),
                media_urls=message_data.media_urls,
                attachment_data=message_data.attachment_data,
                status=MessageStatus.SENT
            )
            
            # Set threading properties
            if message_data.thread_id:
                message.is_thread_starter = False
            else:
                message.is_thread_starter = True
            
            await message.save()
            
            # Update parent message reply count if this is a thread reply
            if parent_message:
                parent_message.increment_reply_count()
                await parent_message.save()
            
            # Update group activity
            group.update_activity_timestamp()
            await group.save()
            
            # Update member activity
            membership.update_activity()
            membership.total_posts += 1
            await membership.save()
            
            # Create message data for response and broadcasting
            message_data_obj = await self._format_message_data(message, current_user)
            
            # Broadcast to connected group members
            await websocket_manager.broadcast_message(group_id, message_data_obj.dict())
            
            # Handle mentions and notifications
            await self._handle_message_mentions(message, group, current_user)
            
            # Queue message for offline users
            await self._queue_message_for_offline_users(message, group_id)
            
            logger.info(f"Message sent by {current_user.username} to group {group_id}")
            
            return message_data_obj
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error sending message to group {group_id}: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to send message"
            )
    
    async def edit_message(
        self, 
        current_user: User, 
        message_id: str, 
        edit_data: EditMessageRequest
    ) -> MessageData:
        """Edit an existing message"""
        try:
            message = await GroupMessage.get(message_id)
            if not message:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Message not found"
                )
            
            # Verify permissions
            if message.user_id != current_user.id and not await self._is_group_admin(current_user.id, message.group_id):
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Cannot edit this message"
                )
            
            # Check edit time limit (15 minutes for regular users, unlimited for admins)
            if (message.user_id == current_user.id and 
                not await self._is_group_admin(current_user.id, message.group_id)):
                edit_time_limit = datetime.utcnow() - timedelta(minutes=15)
                if message.created_at < edit_time_limit:
                    raise HTTPException(
                        status_code=status.HTTP_400_BAD_REQUEST,
                        detail="Message edit time limit exceeded (15 minutes)"
                    )
            
            # Update message
            message.content = sanitize_text_content(edit_data.content)
            message.mentioned_user_ids = edit_data.mentioned_user_ids
            message.mark_as_edited()
            await message.save()
            
            # Create updated message data
            message_data = await self._format_message_data(message, current_user)
            
            # Broadcast update to connected group members
            await websocket_manager.broadcast_message_update(message.group_id, message_data.dict())
            
            logger.info(f"Message {message_id} edited by {current_user.username}")
            
            return message_data
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error editing message {message_id}: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to edit message"
            )
    
    async def delete_message(
        self, 
        current_user: User, 
        message_id: str
    ):
        """Delete a message (soft delete)"""
        try:
            message = await GroupMessage.get(message_id)
            if not message:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Message not found"
                )
            
            # Verify permissions
            if message.user_id != current_user.id and not await self._is_group_admin(current_user.id, message.group_id):
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Cannot delete this message"
                )
            
            # Soft delete message
            message.soft_delete(current_user.id)
            await message.save()
            
            # Broadcast deletion to connected group members
            await websocket_manager.broadcast_message_deletion(message.group_id, message_id)
            
            logger.info(f"Message {message_id} deleted by {current_user.username}")
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error deleting message {message_id}: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to delete message"
            )
    
    async def react_to_message(
        self, 
        current_user: User, 
        message_id: str, 
        reaction_data: ReactToMessageRequest
    ):
        """Add or update reaction to a message"""
        try:
            message = await GroupMessage.get(message_id)
            if not message:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Message not found"
                )
            
            # Verify group access
            await self._verify_group_access(current_user.id, message.group_id)
            
            # Check for existing reaction
            existing_reaction = await MessageReaction.find_one({
                "message_id": message_id,
                "user_id": current_user.id
            })
            
            if existing_reaction:
                # Update existing reaction
                existing_reaction.reaction_type = reaction_data.reaction_type
                existing_reaction.custom_emoji = reaction_data.custom_emoji
                existing_reaction.update_timestamp()
                await existing_reaction.save()
            else:
                # Create new reaction
                reaction = MessageReaction(
                    message_id=message_id,
                    group_id=message.group_id,
                    user_id=current_user.id,
                    reaction_type=reaction_data.reaction_type,
                    custom_emoji=reaction_data.custom_emoji
                )
                await reaction.save()
            
            # Get updated reaction data
            reaction_summary = await self._get_message_reactions(message_id, current_user.id)
            
            # Broadcast reaction update
            await websocket_manager.broadcast_reaction(message.group_id, {
                "message_id": message_id,
                "user_id": current_user.id,
                "username": current_user.username,
                "reaction_type": reaction_data.reaction_type.value,
                "reactions_summary": reaction_summary
            })
            
            logger.info(f"User {current_user.username} reacted to message {message_id}")
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error reacting to message {message_id}: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to react to message"
            )
    
    async def mark_messages_read(
        self, 
        current_user: User, 
        group_id: str, 
        read_data: MarkMessagesReadRequest
    ):
        """Mark messages as read"""
        try:
            # Verify group access
            await self._verify_group_access(current_user.id, group_id)
            
            # Get messages to mark as read
            messages = await GroupMessage.find({
                "_id": {"$in": [PydanticObjectId(msg_id) for msg_id in read_data.message_ids]},
                "group_id": group_id,
                "is_deleted": False
            }).to_list()
            
            read_at = read_data.read_at or datetime.utcnow()
            
            # Add read receipts
            for message in messages:
                message.add_read_receipt(current_user.id, read_at)
                await message.save()
            
            # Broadcast read receipts for real-time updates
            for message in messages:
                await websocket_manager.send_to_user(message.user_id, {
                    "type": WebSocketMessageType.MESSAGE_READ,
                    "data": {
                        "message_id": str(message.id),
                        "reader_user_id": current_user.id,
                        "reader_username": current_user.username,
                        "read_at": read_at.isoformat()
                    }
                })
            
            logger.info(f"User {current_user.username} marked {len(messages)} messages as read in group {group_id}")
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error marking messages as read: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to mark messages as read"
            )
    
    async def get_group_messages(
        self, 
        current_user: User, 
        group_id: str, 
        limit: int = 50, 
        before_message_id: Optional[str] = None
    ) -> MessageListResponse:
        """Get paginated group messages"""
        try:
            # Verify group access
            await self._verify_group_access(current_user.id, group_id)
            
            # Build query
            query = {
                "group_id": group_id,
                "is_deleted": False
            }
            
            if before_message_id:
                before_message = await GroupMessage.get(before_message_id)
                if before_message:
                    query["created_at"] = {"$lt": before_message.created_at}
            
            # Get messages
            messages = await GroupMessage.find(query).sort([("created_at", DESCENDING)]).limit(limit + 1).to_list()
            
            has_more = len(messages) > limit
            if has_more:
                messages = messages[:limit]
            
            # Format message data
            formatted_messages = []
            for message in messages:
                author = await self._get_message_author(message.user_id)
                formatted_message = await self._format_message_data(message, current_user, author)
                formatted_messages.append(formatted_message)
            
            # Get total count for this group
            total_count = await GroupMessage.find({
                "group_id": group_id,
                "is_deleted": False
            }).count()
            
            last_message_at = messages[0].created_at if messages else None
            
            return MessageListResponse(
                messages=formatted_messages,
                has_more=has_more,
                total_count=total_count,
                last_message_at=last_message_at
            )
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error getting messages for group {group_id}: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to get group messages"
            )
    
    async def search_messages(
        self, 
        current_user: User, 
        group_id: str, 
        search_data: MessageSearchRequest
    ) -> MessageSearchResponse:
        """Search messages within a group"""
        try:
            # Verify group access
            await self._verify_group_access(current_user.id, group_id)
            
            # Build search query
            query = {
                "group_id": group_id,
                "is_deleted": False,
                "$text": {"$search": search_data.query}
            }
            
            # Add filters
            if search_data.message_type:
                query["message_type"] = search_data.message_type.value
            if search_data.user_id:
                query["user_id"] = search_data.user_id
            if search_data.thread_id:
                query["thread_id"] = search_data.thread_id
            if search_data.date_from:
                query["created_at"] = {"$gte": search_data.date_from}
            if search_data.date_to:
                if "created_at" in query:
                    query["created_at"]["$lte"] = search_data.date_to
                else:
                    query["created_at"] = {"$lte": search_data.date_to}
            
            # Execute search
            messages = await GroupMessage.find(query).sort([("created_at", DESCENDING)]).skip(search_data.skip).limit(search_data.limit + 1).to_list()
            
            has_more = len(messages) > search_data.limit
            if has_more:
                messages = messages[:search_data.limit]
            
            # Format results
            formatted_messages = []
            for message in messages:
                author = await self._get_message_author(message.user_id)
                formatted_message = await self._format_message_data(message, current_user, author)
                formatted_messages.append(formatted_message)
            
            # Get total results count
            total_results = await GroupMessage.find({
                "group_id": group_id,
                "is_deleted": False,
                "$text": {"$search": search_data.query}
            }).count()
            
            return MessageSearchResponse(
                results=formatted_messages,
                total_results=total_results,
                query=search_data.query,
                has_more=has_more
            )
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error searching messages in group {group_id}: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to search messages"
            )
    
    async def handle_typing_indicator(
        self, 
        current_user: User, 
        group_id: str, 
        typing_data: TypingIndicatorRequest
    ):
        """Handle typing indicator updates"""
        try:
            # Verify group access
            await self._verify_group_access(current_user.id, group_id)
            
            if typing_data.is_typing:
                # Update or create typing indicator
                typing_indicator = await TypingIndicator.find_one({
                    "group_id": group_id,
                    "user_id": current_user.id,
                    "thread_id": typing_data.thread_id
                })
                
                if typing_indicator:
                    typing_indicator.refresh_typing()
                    await typing_indicator.save()
                else:
                    typing_indicator = TypingIndicator(
                        group_id=group_id,
                        user_id=current_user.id,
                        thread_id=typing_data.thread_id,
                        expires_at=datetime.utcnow() + timedelta(seconds=10)
                    )
                    await typing_indicator.save()
                
                # Broadcast typing start
                await websocket_manager.broadcast_typing_start(
                    group_id,
                    {
                        "user_id": current_user.id,
                        "username": current_user.username
                    },
                    typing_data.thread_id
                )
            else:
                # Stop typing
                await TypingIndicator.find({
                    "group_id": group_id,
                    "user_id": current_user.id,
                    "thread_id": typing_data.thread_id
                }).delete()
                
                # Broadcast typing stop
                await websocket_manager.broadcast_typing_stop(
                    group_id,
                    {
                        "user_id": current_user.id,
                        "username": current_user.username
                    },
                    typing_data.thread_id
                )
                
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error handling typing indicator: {e}")
    
    async def get_typing_users(
        self, 
        current_user: User, 
        group_id: str
    ) -> TypingIndicatorResponse:
        """Get users currently typing in a group"""
        try:
            # Verify group access
            await self._verify_group_access(current_user.id, group_id)
            
            # Get active typing indicators
            typing_indicators = await TypingIndicator.find({
                "group_id": group_id,
                "is_typing": True,
                "expires_at": {"$gt": datetime.utcnow()},
                "user_id": {"$ne": current_user.id}  # Exclude current user
            }).to_list()
            
            # Format typing users
            typing_users = []
            for indicator in typing_indicators:
                user = await User.get(indicator.user_id)
                if user:
                    typing_users.append(TypingUser(
                        user_id=indicator.user_id,
                        username=user.username,
                        display_name=user.display_name,
                        thread_id=indicator.thread_id
                    ))
            
            return TypingIndicatorResponse(
                group_id=group_id,
                typing_users=typing_users,
                count=len(typing_users)
            )
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error getting typing users for group {group_id}: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to get typing users"
            )
    
    # Helper methods
    
    async def _verify_group_access(self, user_id: str, group_id: str) -> GroupMembership:
        """Verify user has access to group"""
        membership = await GroupMembership.find_one({
            "group_id": group_id,
            "user_id": user_id,
            "status": MembershipStatus.ACTIVE
        })
        
        if not membership:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Access denied to group"
            )
        
        return membership
    
    async def _is_group_admin(self, user_id: str, group_id: str) -> bool:
        """Check if user is admin or owner of group"""
        membership = await GroupMembership.find_one({
            "group_id": group_id,
            "user_id": user_id,
            "status": MembershipStatus.ACTIVE
        })
        
        return membership and membership.role in [GroupRole.ADMIN, GroupRole.OWNER]
    
    def _can_create_announcements(self, membership: GroupMembership) -> bool:
        """Check if user can create announcements"""
        return membership.role in [GroupRole.ADMIN, GroupRole.OWNER, GroupRole.MODERATOR]
    
    async def _format_message_data(
        self, 
        message: GroupMessage, 
        current_user: User,
        author: Optional[MessageAuthor] = None
    ) -> MessageData:
        """Format message data for API responses"""
        if not author:
            author = await self._get_message_author(message.user_id)
        
        # Get reactions
        reactions = await self._get_message_reactions(str(message.id), current_user.id)
        
        # Check user permissions
        can_edit = (message.user_id == current_user.id or 
                   await self._is_group_admin(current_user.id, message.group_id))
        can_delete = (message.user_id == current_user.id or 
                     await self._is_group_admin(current_user.id, message.group_id))
        
        return MessageData(
            id=str(message.id),
            group_id=message.group_id,
            user_id=message.user_id,
            content=message.content,
            message_type=message.message_type,
            status=message.status,
            author=author,
            thread_id=message.thread_id,
            reply_count=message.reply_count,
            is_thread_starter=message.is_thread_starter,
            is_pinned=message.is_pinned,
            is_announcement=message.is_announcement,
            is_edited=message.is_edited,
            is_deleted=message.is_deleted,
            created_at=message.created_at,
            updated_at=message.updated_at,
            edited_at=message.edited_at,
            media_urls=message.media_urls,
            attachment_data=message.attachment_data,
            mentioned_user_ids=message.mentioned_user_ids,
            reactions=reactions,
            delivery_count=len(message.delivery_receipts),
            read_count=len(message.read_receipts),
            user_can_edit=can_edit,
            user_can_delete=can_delete
        )
    
    async def _get_message_author(self, user_id: str) -> MessageAuthor:
        """Get message author information"""
        user = await User.get(user_id)
        if not user:
            return MessageAuthor(
                id=user_id,
                username="Unknown User",
                display_name=None,
                avatar_url=None,
                role=None
            )
        
        return MessageAuthor(
            id=user_id,
            username=user.username,
            display_name=user.display_name,
            avatar_url=user.profile_picture_url,
            role=None  # Will be populated with group role if needed
        )
    
    async def _get_message_reactions(self, message_id: str, current_user_id: str) -> List[MessageReactionData]:
        """Get aggregated reaction data for a message"""
        reactions = await MessageReaction.find({"message_id": message_id}).to_list()
        
        # Group reactions by type
        reaction_groups = {}
        for reaction in reactions:
            reaction_type = reaction.reaction_type.value
            if reaction_type not in reaction_groups:
                reaction_groups[reaction_type] = {
                    "user_ids": [],
                    "custom_emoji": reaction.custom_emoji
                }
            reaction_groups[reaction_type]["user_ids"].append(reaction.user_id)
        
        # Format reaction data
        formatted_reactions = []
        for reaction_type, data in reaction_groups.items():
            user_reacted = current_user_id in data["user_ids"]
            formatted_reactions.append(MessageReactionData(
                reaction_type=ReactionType(reaction_type),
                count=len(data["user_ids"]),
                user_ids=data["user_ids"],
                user_reacted=user_reacted,
                custom_emoji=data["custom_emoji"]
            ))
        
        return formatted_reactions
    
    async def _handle_message_mentions(
        self, 
        message: GroupMessage, 
        group: PremiumGroup, 
        sender: User
    ):
        """Handle notifications for message mentions"""
        try:
            mentioned_users = message.get_mentioned_users()
            
            if message.notify_all:
                # Get all group members
                memberships = await GroupMembership.find({
                    "group_id": message.group_id,
                    "status": MembershipStatus.ACTIVE
                }).to_list()
                
                for membership in memberships:
                    if membership.user_id != sender.id:  # Don't notify sender
                        await NotificationService.create_group_message_notification(
                            user_id=membership.user_id,
                            sender_id=sender.id,
                            sender_name=sender.display_name or sender.username,
                            group_id=message.group_id,
                            group_name=group.name,
                            message_content=message.content[:100],
                            is_mention=True
                        )
            else:
                # Notify mentioned users
                for user_id in mentioned_users:
                    if user_id != sender.id:  # Don't notify sender
                        await NotificationService.create_group_message_notification(
                            user_id=user_id,
                            sender_id=sender.id,
                            sender_name=sender.display_name or sender.username,
                            group_id=message.group_id,
                            group_name=group.name,
                            message_content=message.content[:100],
                            is_mention=True
                        )
                        
        except Exception as e:
            logger.error(f"Error handling message mentions: {e}")
    
    async def _queue_message_for_offline_users(self, message: GroupMessage, group_id: str):
        """Queue message for offline users"""
        try:
            # Get all group members
            memberships = await GroupMembership.find({
                "group_id": group_id,
                "status": MembershipStatus.ACTIVE
            }).to_list()
            
            # Get currently connected users
            connected_users = set(websocket_manager.user_connections.keys())
            
            # Find offline users
            offline_users = []
            for membership in memberships:
                if membership.user_id not in connected_users:
                    offline_users.append(membership.user_id)
            
            if offline_users:
                # Create message queue entry
                queue_item = MessageQueue(
                    message_id=str(message.id),
                    group_id=group_id,
                    recipient_user_ids=offline_users,
                    priority=2 if message.is_announcement else 1,
                    delivery_type="push"
                )
                await queue_item.save()
                
        except Exception as e:
            logger.error(f"Error queuing message for offline users: {e}")

# Global service instance
group_messaging_service = GroupMessagingService()