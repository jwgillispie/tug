# app/api/endpoints/social.py
from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import List, Optional
import logging

from ...models.user import User
from ...schemas.social import (
    FriendRequestCreate, FriendRequestResponse, FriendshipData,
    SocialPostCreate, SocialPostUpdate, SocialPostData,
    CommentCreate, CommentData, UserSearchResult, SocialStatisticsResponse
)
from ...services.social_service import SocialService
from ...core.auth import get_current_user
from ...utils.json_utils import MongoJSONEncoder

router = APIRouter()
logger = logging.getLogger(__name__)

# Friend Management Endpoints

@router.post("/friends/request", status_code=status.HTTP_201_CREATED)
async def send_friend_request(
    request: FriendRequestCreate,
    current_user: User = Depends(get_current_user)
):
    """Send a friend request to another user"""
    try:
        friendship = await SocialService.send_friend_request(current_user, request)
        
        friendship_dict = friendship.dict()
        friendship_dict = MongoJSONEncoder.encode_mongo_data(friendship_dict)
        
        return {"friendship": friendship_dict}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in send_friend_request endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to send friend request"
        )

@router.post("/friends/respond/{friendship_id}")
async def respond_to_friend_request(
    friendship_id: str,
    accept: bool = Query(..., description="True to accept, False to reject"),
    current_user: User = Depends(get_current_user)
):
    """Accept or reject a friend request"""
    try:
        friendship = await SocialService.respond_to_friend_request(current_user, friendship_id, accept)
        
        if not accept:
            return {"message": "Friend request rejected"}
        
        friendship_dict = friendship.dict()
        friendship_dict = MongoJSONEncoder.encode_mongo_data(friendship_dict)
        
        return {"friendship": friendship_dict}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in respond_to_friend_request endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to respond to friend request"
        )

@router.get("/friends")
async def get_friends(
    current_user: User = Depends(get_current_user)
):
    """Get list of user's friends"""
    try:
        friends = await SocialService.get_friends(current_user)
        
        friends_list = []
        for friend in friends:
            friend_dict = friend.dict()
            friend_dict = MongoJSONEncoder.encode_mongo_data(friend_dict)
            friends_list.append(friend_dict)
        
        return {"friends": friends_list}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in get_friends endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get friends"
        )

@router.get("/friends/requests")
async def get_pending_friend_requests(
    current_user: User = Depends(get_current_user)
):
    """Get pending friend requests"""
    try:
        requests = await SocialService.get_pending_friend_requests(current_user)
        
        requests_list = []
        for request in requests:
            request_dict = request.dict()
            request_dict = MongoJSONEncoder.encode_mongo_data(request_dict)
            requests_list.append(request_dict)
        
        return {"friend_requests": requests_list}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in get_pending_friend_requests endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get friend requests"
        )

@router.get("/users/search")
async def search_users(
    q: str = Query(..., min_length=1, description="Search query"),
    limit: int = Query(10, ge=1, le=50, description="Number of results to return"),
    current_user: User = Depends(get_current_user)
):
    """Search for users"""
    try:
        results = await SocialService.search_users(current_user, q, limit)
        return {"users": results}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in search_users endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to search users"
        )

# Social Posts Endpoints

@router.post("/posts", status_code=status.HTTP_201_CREATED)
async def create_post(
    post: SocialPostCreate,
    current_user: User = Depends(get_current_user)
):
    """Create a new social post"""
    try:
        new_post = await SocialService.create_post(current_user, post)
        
        post_dict = new_post.dict()
        post_dict = MongoJSONEncoder.encode_mongo_data(post_dict)
        
        return {"post": post_dict}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in create_post endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create post"
        )

@router.get("/feed")
async def get_social_feed(
    limit: int = Query(20, ge=1, le=50, description="Number of posts to return"),
    skip: int = Query(0, ge=0, description="Number of posts to skip"),
    current_user: User = Depends(get_current_user)
):
    """Get social feed for current user"""
    try:
        posts = await SocialService.get_social_feed(current_user, limit, skip)
        return {"posts": posts}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in get_social_feed endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get social feed"
        )


@router.post("/posts/{post_id}/comments", status_code=status.HTTP_201_CREATED)
async def add_comment(
    post_id: str,
    comment: CommentCreate,
    current_user: User = Depends(get_current_user)
):
    """Add a comment to a post"""
    try:
        new_comment = await SocialService.add_comment(current_user, post_id, comment)
        
        comment_dict = new_comment.dict()
        comment_dict = MongoJSONEncoder.encode_mongo_data(comment_dict)
        
        return {"comment": comment_dict}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in add_comment endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to add comment"
        )

@router.get("/posts/{post_id}/comments")
async def get_post_comments(
    post_id: str,
    limit: int = Query(50, ge=1, le=100, description="Number of comments to return"),
    skip: int = Query(0, ge=0, description="Number of comments to skip"),
    current_user: User = Depends(get_current_user)
):
    """Get comments for a post"""
    try:
        comments = await SocialService.get_post_comments(post_id, limit, skip)
        return {"comments": comments}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in get_post_comments endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get comments"
        )


# Social Statistics Endpoint

@router.get("/statistics", response_model=SocialStatisticsResponse)
async def get_social_statistics(
    current_user: User = Depends(get_current_user)
):
    """Get comprehensive social statistics for the current user"""
    try:
        stats = await SocialService.get_social_statistics(current_user)
        return stats
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in get_social_statistics endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get social statistics"
        )