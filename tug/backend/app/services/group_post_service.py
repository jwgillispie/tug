# app/services/group_post_service.py
import logging
from typing import List, Optional, Dict, Any
from datetime import datetime
from fastapi import HTTPException, status
from bson import ObjectId

from ..models.user import User
from ..models.premium_group import PremiumGroup, GroupMembership, GroupPost, GroupRole
from ..models.activity import Activity
from ..models.achievement import Achievement
from ..schemas.premium_group import GroupPostCreate, GroupPostData
from .notification_service import NotificationService
from ..utils.validation import InputValidator

logger = logging.getLogger(__name__)

class GroupPostService:
    """Service for managing premium group posts and feeds"""
    
    @staticmethod
    async def create_post(current_user: User, group_id: str, post_data: GroupPostCreate) -> GroupPost:
        """Create a new group post"""
        try:
            # Check if user is group member
            membership = await GroupMembership.find_one({
                "group_id": group_id,
                "user_id": str(current_user.id),
                "status": "active"
            })
            
            if not membership:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Must be a group member to create posts"
                )
            
            # Get group to check status
            group = await PremiumGroup.get(group_id)
            if not group or group.status != "active":
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Cannot post to this group"
                )
            
            # Validate and sanitize content
            sanitized_content = InputValidator.sanitize_string(post_data.content, max_length=1000)
            
            # Validate media URLs if provided
            media_urls = []
            if post_data.media_urls:
                for url in post_data.media_urls[:5]:  # Limit to 5 media items
                    if InputValidator.is_valid_url(url):
                        media_urls.append(url)
            
            # Create post
            post = GroupPost(
                group_id=group_id,
                user_id=str(current_user.id),
                content=sanitized_content,
                post_type=post_data.post_type,
                category=post_data.category,
                tags=post_data.tags[:10],  # Limit to 10 tags
                media_urls=media_urls,
                related_activity_id=post_data.related_activity_id,
                related_challenge_id=post_data.related_challenge_id,
                related_achievement_id=post_data.related_achievement_id
            )
            
            await post.save()
            
            # Update member's post count
            membership.total_posts += 1
            membership.update_activity()
            await membership.save()
            
            # Update group activity
            group.total_posts += 1
            group.update_activity_timestamp()
            await group.save()
            
            # Send notifications to group members (except poster)
            await GroupPostService._notify_new_post(group_id, str(current_user.id), post)
            
            logger.info(f"Group post created: {post.id} in group {group_id} by user {current_user.id}")
            return post
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error creating group post: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create post"
            )
    
    @staticmethod
    async def get_group_feed(current_user: User, group_id: str, limit: int = 20, skip: int = 0, 
                           post_type: Optional[str] = None) -> List[GroupPostData]:
        """Get group activity feed"""
        try:
            # Check if user can view feed
            membership = await GroupMembership.find_one({
                "group_id": group_id,
                "user_id": str(current_user.id),
                "status": "active"
            })
            
            if not membership:
                # Check if group is public/discoverable
                group = await PremiumGroup.get(group_id)
                if not group or group.privacy_level == "private":
                    raise HTTPException(
                        status_code=status.HTTP_403_FORBIDDEN,
                        detail="Cannot view feed for this group"
                    )
            
            # Build query
            query = {"group_id": group_id}
            if post_type:
                query["post_type"] = post_type
            
            # Get posts with pinned posts first
            posts = await GroupPost.find(query)\
                .sort([("is_pinned", -1), ("created_at", -1)])\
                .skip(skip)\
                .limit(limit)\
                .to_list()
            
            # Get user info for posts
            post_user_ids = list(set([post.user_id for post in posts]))
            users = await User.find({"_id": {"$in": [ObjectId(uid) for uid in post_user_ids]}}).to_list()
            user_map = {str(user.id): user for user in users}
            
            # Get related content info
            activity_ids = [post.related_activity_id for post in posts if post.related_activity_id]
            challenge_ids = [post.related_challenge_id for post in posts if post.related_challenge_id]
            achievement_ids = [post.related_achievement_id for post in posts if post.related_achievement_id]
            
            # Get activities
            activities = {}
            if activity_ids:
                activity_docs = await Activity.find({"_id": {"$in": [ObjectId(aid) for aid in activity_ids]}}).to_list()
                activities = {str(act.id): act for act in activity_docs}
            
            # Get challenges
            challenges = {}
            if challenge_ids:
                from ..models.premium_group import GroupChallenge
                challenge_docs = await GroupChallenge.find({"_id": {"$in": [ObjectId(cid) for cid in challenge_ids]}}).to_list()
                challenges = {str(ch.id): ch for ch in challenge_docs}
            
            # Get achievements
            achievements = {}
            if achievement_ids:
                achievement_docs = await Achievement.find({"_id": {"$in": [ObjectId(aid) for aid in achievement_ids]}}).to_list()
                achievements = {str(ach.id): ach for ach in achievement_docs}
            
            # Build post data
            post_data_list = []
            for post in posts:
                user = user_map.get(post.user_id)
                activity = activities.get(post.related_activity_id) if post.related_activity_id else None
                challenge = challenges.get(post.related_challenge_id) if post.related_challenge_id else None
                
                post_data = GroupPostData(
                    id=str(post.id),
                    group_id=post.group_id,
                    user_id=post.user_id,
                    username=user.username if user else "Unknown",
                    user_display_name=user.display_name if user else None,
                    content=post.content,
                    post_type=post.post_type,
                    category=post.category,
                    tags=post.tags,
                    is_announcement=post.is_announcement,
                    is_pinned=post.is_pinned,
                    priority_level=post.priority_level,
                    media_urls=post.media_urls,
                    likes_count=post.likes_count,
                    comments_count=post.comments_count,
                    shares_count=post.shares_count,
                    engagement_score=post.engagement_score,
                    created_at=post.created_at,
                    updated_at=post.updated_at,
                    related_activity_name=activity.name if activity else None,
                    related_challenge_title=challenge.title if challenge else None
                )
                post_data_list.append(post_data)
            
            return post_data_list
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error getting group feed: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to get group feed"
            )
    
    @staticmethod
    async def like_post(current_user: User, group_id: str, post_id: str) -> Dict[str, Any]:
        """Like or unlike a group post"""
        try:
            # Check if user is group member
            membership = await GroupMembership.find_one({
                "group_id": group_id,
                "user_id": str(current_user.id),
                "status": "active"
            })
            
            if not membership:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Must be a group member to interact with posts"
                )
            
            # Get post
            post = await GroupPost.get(post_id)
            if not post or post.group_id != group_id:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Post not found"
                )
            
            # Toggle like (simplified - would need proper like tracking)
            post.increment_engagement("likes")
            await post.save()
            
            # Update member's engagement
            membership.likes_given = getattr(membership, 'likes_given', 0) + 1
            membership.update_activity()
            await membership.save()
            
            # Send notification to post author
            if post.user_id != str(current_user.id):
                await NotificationService.create_group_like_notification(
                    post_owner_id=post.user_id,
                    liker_id=str(current_user.id),
                    liker_name=current_user.display_name or current_user.username,
                    group_id=group_id,
                    post_id=post_id
                )
            
            return {"liked": True, "likes_count": post.likes_count}
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error liking post: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to like post"
            )
    
    @staticmethod
    async def update_post(current_user: User, group_id: str, post_id: str, content: str) -> GroupPost:
        """Update a group post (author or admin only)"""
        try:
            # Get post
            post = await GroupPost.get(post_id)
            if not post or post.group_id != group_id:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Post not found"
                )
            
            # Check permissions
            membership = await GroupMembership.find_one({
                "group_id": group_id,
                "user_id": str(current_user.id),
                "status": "active"
            })
            
            if not membership:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Must be a group member to edit posts"
                )
            
            # Check if user can edit (author or admin)
            if post.user_id != str(current_user.id) and membership.role not in [GroupRole.OWNER, GroupRole.ADMIN, GroupRole.MODERATOR]:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Insufficient permissions to edit this post"
                )
            
            # Update content
            sanitized_content = InputValidator.sanitize_string(content, max_length=1000)
            post.content = sanitized_content
            post.update_timestamp()
            await post.save()
            
            logger.info(f"Post updated: {post_id} by user {current_user.id}")
            return post
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error updating post: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to update post"
            )
    
    @staticmethod
    async def delete_post(current_user: User, group_id: str, post_id: str) -> bool:
        """Delete a group post (author or admin only)"""
        try:
            # Get post
            post = await GroupPost.get(post_id)
            if not post or post.group_id != group_id:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Post not found"
                )
            
            # Check permissions
            membership = await GroupMembership.find_one({
                "group_id": group_id,
                "user_id": str(current_user.id),
                "status": "active"
            })
            
            if not membership:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Must be a group member to delete posts"
                )
            
            # Check if user can delete (author or admin)
            if post.user_id != str(current_user.id) and membership.role not in [GroupRole.OWNER, GroupRole.ADMIN, GroupRole.MODERATOR]:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Insufficient permissions to delete this post"
                )
            
            # Delete post
            await post.delete()
            
            # Update member's post count if they're the author
            if post.user_id == str(current_user.id):
                membership.total_posts = max(0, membership.total_posts - 1)
                await membership.save()
            
            # Update group post count
            group = await PremiumGroup.get(group_id)
            if group:
                group.total_posts = max(0, group.total_posts - 1)
                await group.save()
            
            logger.info(f"Post deleted: {post_id} by user {current_user.id}")
            return True
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error deleting post: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to delete post"
            )
    
    @staticmethod
    async def pin_post(current_user: User, group_id: str, post_id: str, pin: bool = True) -> GroupPost:
        """Pin or unpin a post (admin only)"""
        try:
            # Check admin permissions
            membership = await GroupMembership.find_one({
                "group_id": group_id,
                "user_id": str(current_user.id),
                "status": "active",
                "role": {"$in": [GroupRole.OWNER, GroupRole.ADMIN, GroupRole.MODERATOR]}
            })
            
            if not membership:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Insufficient permissions to pin posts"
                )
            
            # Get post
            post = await GroupPost.get(post_id)
            if not post or post.group_id != group_id:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Post not found"
                )
            
            # Update pin status
            post.is_pinned = pin
            if pin:
                post.priority_level = 5  # High priority for pinned posts
            post.update_timestamp()
            await post.save()
            
            # Update member's leadership actions
            membership.leadership_actions += 1
            await membership.save()
            
            logger.info(f"Post {'pinned' if pin else 'unpinned'}: {post_id} by user {current_user.id}")
            return post
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error pinning/unpinning post: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to update post pin status"
            )
    
    @staticmethod
    async def _notify_new_post(group_id: str, author_id: str, post: GroupPost):
        """Send notifications for new group post"""
        try:
            # Get group members who want post notifications
            memberships = await GroupMembership.find({
                "group_id": group_id,
                "status": "active",
                "user_id": {"$ne": author_id}  # Exclude post author
            }).to_list()
            
            # Get author info
            author = await User.get(author_id)
            author_name = author.display_name or author.username if author else "A member"
            
            # Send notifications to members who opted in
            for membership in memberships:
                if membership.notification_preferences.get("group_posts", True):
                    await NotificationService.create_group_post_notification(
                        member_id=membership.user_id,
                        author_id=author_id,
                        author_name=author_name,
                        group_id=group_id,
                        post_id=str(post.id),
                        post_content=post.content[:100]  # First 100 chars
                    )
            
        except Exception as e:
            logger.error(f"Error sending new post notifications: {e}")
    
    @staticmethod
    async def create_automated_post(group_id: str, post_type: str, content: str, data: Dict[str, Any]) -> Optional[GroupPost]:
        """Create automated system posts for group events"""
        try:
            group = await PremiumGroup.get(group_id)
            if not group:
                return None
            
            # Create system post
            post = GroupPost(
                group_id=group_id,
                user_id="system",  # System posts
                content=content,
                post_type=post_type,
                is_announcement=True,
                priority_level=3,
                attachment_data=data
            )
            
            await post.save()
            
            # Update group activity
            group.update_activity_timestamp()
            await group.save()
            
            logger.info(f"Automated post created in group {group_id}: {post_type}")
            return post
            
        except Exception as e:
            logger.error(f"Error creating automated post: {e}")
            return None