# app/services/social_service.py
import logging
from typing import List, Optional, Tuple
from datetime import datetime
from fastapi import HTTPException, status
from bson import ObjectId

from ..models.user import User
from ..models.friendship import Friendship, FriendshipStatus
from ..models.social_post import SocialPost, PostType
from ..models.post_comment import PostComment
from ..models.activity import Activity
from ..models.value import Value
from ..models.vice import Vice
from ..schemas.social import (
    FriendRequestCreate, SocialPostCreate, SocialPostUpdate,
    CommentCreate, CommentUpdate, UserSearchResult, SocialPostData, CommentData,
    SocialStatisticsResponse, PostTypeStats, FriendshipData
)
from .notification_service import NotificationService

logger = logging.getLogger(__name__)

class SocialService:
    
    # Friend Management
    @staticmethod
    async def send_friend_request(current_user: User, request: FriendRequestCreate) -> Friendship:
        """Send a friend request to another user"""
        try:
            # Check if user is trying to add themselves
            if str(current_user.id) == request.addressee_id:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Cannot send friend request to yourself"
                )
            
            # Check if addressee exists
            addressee = await User.get(request.addressee_id)
            if not addressee:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="User not found"
                )
            
            # Check if friendship already exists
            existing_friendship = await Friendship.find_one({
                "$or": [
                    {"requester_id": str(current_user.id), "addressee_id": request.addressee_id},
                    {"requester_id": request.addressee_id, "addressee_id": str(current_user.id)}
                ]
            })
            
            if existing_friendship:
                if existing_friendship.status == FriendshipStatus.ACCEPTED:
                    raise HTTPException(
                        status_code=status.HTTP_400_BAD_REQUEST,
                        detail="Already friends with this user"
                    )
                elif existing_friendship.status == FriendshipStatus.PENDING:
                    raise HTTPException(
                        status_code=status.HTTP_400_BAD_REQUEST,
                        detail="Friend request already pending"
                    )
                elif existing_friendship.status == FriendshipStatus.BLOCKED:
                    raise HTTPException(
                        status_code=status.HTTP_400_BAD_REQUEST,
                        detail="Cannot send friend request to blocked user"
                    )
            
            # Create new friendship
            friendship = Friendship(
                requester_id=str(current_user.id),
                addressee_id=request.addressee_id,
                status=FriendshipStatus.PENDING
            )
            
            await friendship.save()
            logger.info(f"Friend request sent from {current_user.id} to {request.addressee_id}")
            
            # Create notification for the addressee
            await NotificationService.create_friend_request_notification(
                addressee_id=request.addressee_id,
                requester_id=str(current_user.id),
                requester_name=current_user.display_name or current_user.username or current_user.effective_username,
                friendship_id=str(friendship.id)
            )
            
            return friendship
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error sending friend request: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to send friend request"
            )
    
    @staticmethod
    async def respond_to_friend_request(current_user: User, friendship_id: str, accept: bool) -> Friendship:
        """Accept or reject a friend request"""
        try:
            friendship = await Friendship.get(friendship_id)
            if not friendship:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Friend request not found"
                )
            
            # Check if current user is the addressee
            if friendship.addressee_id != str(current_user.id):
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Not authorized to respond to this friend request"
                )
            
            # Check if request is still pending
            if friendship.status != FriendshipStatus.PENDING:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Friend request is no longer pending"
                )
            
            # Update friendship status
            if accept:
                friendship.status = FriendshipStatus.ACCEPTED
                logger.info(f"Friend request accepted: {friendship_id}")
            else:
                # For rejection, we delete the friendship record
                await friendship.delete()
                logger.info(f"Friend request rejected and deleted: {friendship_id}")
                return friendship
            
            friendship.update_timestamp()
            await friendship.save()
            
            # Create notification for the requester that their request was accepted
            requester = await User.get(friendship.requester_id)
            if requester:
                await NotificationService.create_friend_accepted_notification(
                    requester_id=friendship.requester_id,
                    accepter_id=str(current_user.id),
                    accepter_name=current_user.display_name or current_user.username or current_user.effective_username,
                    friendship_id=str(friendship.id)
                )
            
            return friendship
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error responding to friend request: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to respond to friend request"
            )
    
    @staticmethod
    async def get_friends(current_user: User) -> List[FriendshipData]:
        """Get list of user's friends with friendship data"""
        try:
            # Find all accepted friendships where user is involved
            friendships = await Friendship.find({
                "$and": [
                    {"status": FriendshipStatus.ACCEPTED},
                    {"$or": [
                        {"requester_id": str(current_user.id)},
                        {"addressee_id": str(current_user.id)}
                    ]}
                ]
            }).to_list()
            
            # Extract friend user IDs and create ID mapping
            friend_ids = []
            friendship_map = {}
            for friendship in friendships:
                if friendship.requester_id == str(current_user.id):
                    friend_id = friendship.addressee_id
                else:
                    friend_id = friendship.requester_id
                friend_ids.append(friend_id)
                friendship_map[friend_id] = friendship
            
            # Get friend user objects
            friends = await User.find({"_id": {"$in": [ObjectId(fid) for fid in friend_ids]}}).to_list()
            
            # Build friendship data with user info
            friendship_data_list = []
            for friend in friends:
                friend_id = str(friend.id)
                friendship = friendship_map[friend_id]
                
                # Ensure friend has username
                if not friend.username:
                    await friend.ensure_username()
                
                friendship_data = FriendshipData(
                    id=str(friendship.id),
                    requester_id=friendship.requester_id,
                    addressee_id=friendship.addressee_id,
                    status=friendship.status,
                    created_at=friendship.created_at,
                    updated_at=friendship.updated_at,
                    friend_username=friend.username or friend.effective_username,
                    friend_display_name=friend.display_name
                )
                friendship_data_list.append(friendship_data)
            
            return friendship_data_list
            
        except Exception as e:
            logger.error(f"Error getting friends: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to get friends list"
            )
    
    @staticmethod
    async def get_pending_friend_requests(current_user: User) -> List[FriendshipData]:
        """Get pending friend requests for current user with requester info"""
        try:
            pending_requests = await Friendship.find({
                "addressee_id": str(current_user.id),
                "status": FriendshipStatus.PENDING
            }).to_list()
            
            # Get requester user info
            requester_ids = [req.requester_id for req in pending_requests]
            requesters = await User.find({"_id": {"$in": [ObjectId(uid) for uid in requester_ids]}}).to_list()
            requester_map = {str(user.id): user for user in requesters}
            
            # Build friendship data with requester info
            request_data_list = []
            for request in pending_requests:
                requester = requester_map.get(request.requester_id)
                
                # Ensure requester has username
                if requester and not requester.username:
                    await requester.ensure_username()
                
                request_data = FriendshipData(
                    id=str(request.id),
                    requester_id=request.requester_id,
                    addressee_id=request.addressee_id,
                    status=request.status,
                    created_at=request.created_at,
                    updated_at=request.updated_at,
                    friend_username=requester.username or requester.effective_username if requester else "Unknown",
                    friend_display_name=requester.display_name if requester else None
                )
                request_data_list.append(request_data)
            
            return request_data_list
            
        except Exception as e:
            logger.error(f"Error getting pending friend requests: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to get pending friend requests"
            )
    
    @staticmethod
    async def search_users(current_user: User, query: str, limit: int = 10) -> List[UserSearchResult]:
        """Search for users by username or display name"""
        try:
            # Search users by username, display_name, or email (case insensitive)
            # Handle case where username might be None for older users
            users = await User.find({
                "$and": [
                    {"_id": {"$ne": ObjectId(current_user.id)}},  # Exclude current user
                    {"$or": [
                        {"username": {"$regex": query, "$options": "i"}},
                        {"display_name": {"$regex": query, "$options": "i"}},
                        {"email": {"$regex": query, "$options": "i"}}
                    ]}
                ]
            }).limit(limit).to_list()
            
            # Get friendship statuses for found users
            user_ids = [str(user.id) for user in users]
            friendships = await Friendship.find({
                "$or": [
                    {"requester_id": str(current_user.id), "addressee_id": {"$in": user_ids}},
                    {"requester_id": {"$in": user_ids}, "addressee_id": str(current_user.id)}
                ]
            }).to_list()
            
            # Create friendship status map
            friendship_map = {}
            for friendship in friendships:
                other_user_id = friendship.addressee_id if friendship.requester_id == str(current_user.id) else friendship.requester_id
                friendship_map[other_user_id] = friendship.status.value
            
            # Build search results
            results = []
            for user in users:
                user_id = str(user.id)
                
                # Ensure user has a username, generate if missing
                if not user.username:
                    await user.ensure_username()
                
                results.append(UserSearchResult(
                    id=user_id,
                    username=user.username or user.effective_username,
                    display_name=user.display_name,
                    friendship_status=friendship_map.get(user_id)
                ))
            
            return results
            
        except Exception as e:
            logger.error(f"Error searching users: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to search users"
            )
    
    # Social Posts
    @staticmethod
    async def create_post(current_user: User, post_data: SocialPostCreate) -> SocialPost:
        """Create a new social post"""
        try:
            post = SocialPost(
                user_id=str(current_user.id),
                content=post_data.content,
                post_type=post_data.post_type,
                activity_id=post_data.activity_id,
                vice_id=post_data.vice_id,
                achievement_id=post_data.achievement_id,
                is_public=post_data.is_public
            )
            
            await post.save()
            logger.info(f"Social post created by user {current_user.id}: {post.id}")
            
            return post
            
        except Exception as e:
            logger.error(f"Error creating social post: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create post"
            )
    
    @staticmethod
    async def update_post(current_user: User, post_id: str, post_data: SocialPostUpdate) -> SocialPost:
        """Update a social post (only content can be updated)"""
        try:
            post = await SocialPost.get(post_id)
            if not post:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Post not found"
                )
            
            # Check if current user owns the post
            if post.user_id != str(current_user.id):
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Not authorized to update this post"
                )
            
            # Update post content
            post.content = post_data.content
            post.update_timestamp()
            await post.save()
            
            logger.info(f"Social post updated by user {current_user.id}: {post.id}")
            
            return post
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error updating social post: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to update post"
            )
    
    @staticmethod
    async def delete_post(current_user: User, post_id: str) -> bool:
        """Delete a social post"""
        try:
            post = await SocialPost.get(post_id)
            if not post:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Post not found"
                )
            
            # Check if current user owns the post
            if post.user_id != str(current_user.id):
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Not authorized to delete this post"
                )
            
            # Delete all comments for this post first
            await PostComment.find({"post_id": post_id}).delete()
            
            # Delete the post
            await post.delete()
            
            logger.info(f"Social post deleted by user {current_user.id}: {post_id}")
            
            return True
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error deleting social post: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to delete post"
            )
    
    @staticmethod
    async def create_vice_milestone_post(user: User, vice, milestone: int) -> SocialPost:
        """Create an automatic social post for vice milestone achievements"""
        try:
            # Generate milestone message
            milestone_messages = {
                7: f"🌟 One week clean from {vice.name}! Small steps, big progress! 💪",
                30: f"🎉 30 days clean from {vice.name}! This is just the beginning of amazing things! ✨",
                100: f"🔥 100 DAYS clean from {vice.name}! What an incredible achievement! This is the power of commitment! 💎",
                365: f"🏆 ONE YEAR clean from {vice.name}! A full year of growth, strength, and dedication! Absolutely inspiring! 🌈"
            }
            
            content = milestone_messages.get(milestone, f"🎯 {milestone} days clean from {vice.name}! Keep going strong! 💪")
            
            post = SocialPost(
                user_id=str(user.id),
                content=content,
                post_type=PostType.VICE_PROGRESS,
                vice_id=str(vice.id),
                is_public=True
            )
            
            await post.save()
            logger.info(f"Vice milestone post created for user {user.id}: {milestone} days clean from {vice.name}")
            
            return post
            
        except Exception as e:
            logger.error(f"Error creating vice milestone post: {e}", exc_info=True)
            # Don't raise exception here to avoid breaking vice update flow
            return None
    
    @staticmethod
    async def get_social_feed(current_user: User, limit: int = 20, skip: int = 0) -> List[SocialPostData]:
        """Get social feed for current user (posts from friends)"""
        try:
            # Get user's friends
            friendships = await SocialService.get_friends(current_user)
            friend_ids = []
            for friendship in friendships:
                # Get the friend's ID (the other person in the friendship)
                if friendship.requester_id == str(current_user.id):
                    friend_ids.append(friendship.addressee_id)
                else:
                    friend_ids.append(friendship.requester_id)
            
            # Include current user's posts in feed
            user_ids = friend_ids + [str(current_user.id)]
            
            # Get posts from friends and self, ordered by creation date
            posts = await SocialPost.find({
                "user_id": {"$in": user_ids},
                "is_public": True
            }).sort([("created_at", -1)]).skip(skip).limit(limit).to_list()
            
            logger.info(f"Social feed: Current user {current_user.id}, Friend IDs: {friend_ids}, Total user IDs: {user_ids}, Found {len(posts)} posts")
            
            # Debug: Check if there are any posts at all from these users
            all_posts_from_users = await SocialPost.find({"user_id": {"$in": user_ids}}).to_list()
            public_posts_from_users = await SocialPost.find({"user_id": {"$in": user_ids}, "is_public": True}).to_list()
            logger.info(f"Debug: Total posts from these users: {len(all_posts_from_users)}, Public posts: {len(public_posts_from_users)}")
            
            # Debug: Check all posts in database
            all_posts = await SocialPost.find({}).to_list()
            logger.info(f"Debug: Total posts in database: {len(all_posts)}")
            if all_posts:
                sample_post = all_posts[0]
                logger.info(f"Debug: Sample post - user_id: {sample_post.user_id}, is_public: {sample_post.is_public}, content: {sample_post.content[:50]}...")
            
            # Get user info for posts
            post_user_ids = list(set([post.user_id for post in posts]))
            users = await User.find({"_id": {"$in": [ObjectId(uid) for uid in post_user_ids]}}).to_list()
            user_map = {str(user.id): user for user in users}
            
            # Get activity and value info for posts
            activity_ids = [post.activity_id for post in posts if post.activity_id]
            activities = await Activity.find({"_id": {"$in": [ObjectId(aid) for aid in activity_ids]}}).to_list()
            activity_map = {str(activity.id): activity for activity in activities}
            
            # Get value info for activities
            value_ids = [activity.value_id for activity in activities if activity.value_id]
            values = await Value.find({"_id": {"$in": [ObjectId(vid) for vid in value_ids]}}).to_list()
            value_map = {str(value.id): value for value in values}
            
            # Get vice info for indulgence posts
            vice_ids = [post.vice_id for post in posts if post.vice_id]
            vices = await Vice.find({"_id": {"$in": [ObjectId(vid) for vid in vice_ids]}}).to_list()
            vice_map = {str(vice.id): vice for vice in vices}
            
            # Build post data with user, activity, value, and vice info
            feed_posts = []
            for post in posts:
                user = user_map.get(post.user_id)
                activity = activity_map.get(post.activity_id) if post.activity_id else None
                value = value_map.get(activity.value_id) if activity and activity.value_id else None
                vice = vice_map.get(post.vice_id) if post.vice_id else None
                
                post_data = SocialPostData(
                    id=str(post.id),
                    user_id=post.user_id,
                    content=post.content,
                    post_type=post.post_type,
                    activity_id=post.activity_id,
                    vice_id=post.vice_id,
                    achievement_id=post.achievement_id,
                    comments_count=post.comments_count,
                    is_public=post.is_public,
                    created_at=post.created_at,
                    updated_at=post.updated_at,
                    username=user.username if user else "Unknown",
                    user_display_name=user.display_name if user else None,
                    # Activity and value info
                    value_name=value.name if value else None,
                    value_color=value.color if value else None,
                    activity_name=activity.name if activity else None,
                    activity_duration=activity.duration if activity else None,
                    activity_notes=activity.notes if activity and activity.notes_public else None,
                    # Vice info for indulgence posts
                    vice_name=vice.name if vice else None,
                    vice_color=vice.color if vice else None
                )
                feed_posts.append(post_data)
            
            return feed_posts
            
        except Exception as e:
            logger.error(f"Error getting social feed: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to get social feed"
            )
    
    
    @staticmethod
    async def add_comment(current_user: User, post_id: str, comment_data: CommentCreate) -> PostComment:
        """Add a comment to a post"""
        try:
            # Check if post exists
            post = await SocialPost.get(post_id)
            if not post:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Post not found"
                )
            
            # Create comment
            comment = PostComment(
                post_id=post_id,
                user_id=str(current_user.id),
                content=comment_data.content
            )
            
            await comment.save()
            
            # Update post comment count
            post.increment_comments()
            await post.save()
            
            # Create notification for post owner
            if post.user_id != str(current_user.id):
                await NotificationService.create_comment_notification(
                    post_owner_id=post.user_id,
                    commenter_id=str(current_user.id),
                    commenter_name=current_user.display_name or current_user.username or current_user.effective_username,
                    post_id=post_id,
                    post_content=post.content
                )
            
            logger.info(f"Comment added by user {current_user.id} to post {post_id}")
            
            return comment
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error adding comment: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to add comment"
            )
    
    @staticmethod
    async def get_post_comments(post_id: str, limit: int = 50, skip: int = 0) -> List[CommentData]:
        """Get comments for a post"""
        try:
            # Get comments for the post
            comments = await PostComment.find({
                "post_id": post_id
            }).sort([("created_at", 1)]).skip(skip).limit(limit).to_list()
            
            # Get user info for comments
            comment_user_ids = list(set([comment.user_id for comment in comments]))
            users = await User.find({"_id": {"$in": [ObjectId(uid) for uid in comment_user_ids]}}).to_list()
            user_map = {str(user.id): user for user in users}
            
            # Build comment data with user info
            comment_data_list = []
            for comment in comments:
                user = user_map.get(comment.user_id)
                comment_data = CommentData(
                    id=str(comment.id),
                    post_id=comment.post_id,
                    user_id=comment.user_id,
                    content=comment.content,
                    created_at=comment.created_at,
                    updated_at=comment.updated_at,
                    username=user.username if user else "Unknown",
                    user_display_name=user.display_name if user else None
                )
                comment_data_list.append(comment_data)
            
            return comment_data_list
            
        except Exception as e:
            logger.error(f"Error getting post comments: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to get post comments"
            )
    
    
    @staticmethod
    async def get_social_statistics(current_user: User) -> SocialStatisticsResponse:
        """Get comprehensive social statistics for the current user"""
        try:
            # Get all user's posts
            user_posts = await SocialPost.find({"user_id": str(current_user.id)}).to_list()
            
            # Get friends count
            friends = await Friendship.find({
                "$or": [
                    {"requester_id": str(current_user.id), "status": FriendshipStatus.ACCEPTED},
                    {"addressee_id": str(current_user.id), "status": FriendshipStatus.ACCEPTED}
                ]
            }).to_list()
            
            # Get pending friend requests
            pending_requests = await Friendship.find({
                "addressee_id": str(current_user.id),
                "status": FriendshipStatus.PENDING
            }).to_list()
            
            # Calculate basic stats
            total_posts = len(user_posts)
            total_comments = sum(post.comments_count for post in user_posts)
            friends_count = len(friends)
            pending_requests_count = len(pending_requests)
            
            # Calculate averages
            avg_comments_per_post = total_comments / total_posts if total_posts > 0 else 0.0
            
            # Find most popular post (by comments)
            most_popular_post = None
            most_popular_comments = 0
            for post in user_posts:
                if post.comments_count > most_popular_comments:
                    most_popular_post = post
                    most_popular_comments = post.comments_count
            
            # Calculate post type breakdown
            post_type_counts = {
                PostType.ACTIVITY_UPDATE: 0,
                PostType.VICE_PROGRESS: 0,
                PostType.VICE_INDULGENCE: 0,
                PostType.ACHIEVEMENT: 0,
                PostType.GENERAL: 0
            }
            
            for post in user_posts:
                if post.post_type in post_type_counts:
                    post_type_counts[post.post_type] += 1
            
            post_type_breakdown = PostTypeStats(
                activity_update=post_type_counts[PostType.ACTIVITY_UPDATE],
                vice_progress=post_type_counts[PostType.VICE_PROGRESS],
                vice_indulgence=post_type_counts[PostType.VICE_INDULGENCE],
                achievement=post_type_counts[PostType.ACHIEVEMENT],
                general=post_type_counts[PostType.GENERAL]
            )
            
            return SocialStatisticsResponse(
                total_posts=total_posts,
                total_comments=total_comments,
                friends_count=friends_count,
                pending_requests=pending_requests_count,
                avg_comments_per_post=round(avg_comments_per_post, 2),
                post_type_breakdown=post_type_breakdown,
                most_popular_post_id=str(most_popular_post.id) if most_popular_post else None
            )
            
        except Exception as e:
            logger.error(f"Error getting social statistics: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to get social statistics"
            )