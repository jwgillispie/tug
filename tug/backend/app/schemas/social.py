# app/schemas/social.py
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from ..models.friendship import FriendshipStatus
from ..models.social_post import PostType

# Friendship schemas
class FriendRequestCreate(BaseModel):
    addressee_id: str = Field(..., description="ID of user to send friend request to")

class FriendRequestResponse(BaseModel):
    friendship_id: str = Field(..., description="ID of the friendship record")
    action: str = Field(..., description="'accept' or 'reject'")

class FriendshipData(BaseModel):
    id: str
    requester_id: str
    addressee_id: str
    status: FriendshipStatus
    created_at: datetime
    updated_at: datetime

# Social post schemas
class SocialPostCreate(BaseModel):
    content: str = Field(..., min_length=1, max_length=500)
    post_type: PostType = Field(default=PostType.GENERAL)
    activity_id: Optional[str] = None
    vice_id: Optional[str] = None
    achievement_id: Optional[str] = None
    is_public: bool = Field(default=True)

class SocialPostUpdate(BaseModel):
    content: Optional[str] = Field(None, min_length=1, max_length=500)
    is_public: Optional[bool] = None

class SocialPostData(BaseModel):
    id: str
    user_id: str
    content: str
    post_type: PostType
    activity_id: Optional[str] = None
    vice_id: Optional[str] = None
    achievement_id: Optional[str] = None
    likes: List[str]
    comments_count: int
    is_public: bool
    created_at: datetime
    updated_at: datetime
    
    # Additional user info for display
    username: Optional[str] = None
    user_display_name: Optional[str] = None

# Comment schemas
class CommentCreate(BaseModel):
    content: str = Field(..., min_length=1, max_length=300)

class CommentUpdate(BaseModel):
    content: str = Field(..., min_length=1, max_length=300)

class CommentData(BaseModel):
    id: str
    post_id: str
    user_id: str
    content: str
    likes: List[str]
    created_at: datetime
    updated_at: datetime
    
    # Additional user info for display
    username: Optional[str] = None
    user_display_name: Optional[str] = None

# Search and feed schemas
class UserSearchResult(BaseModel):
    id: str
    username: str
    display_name: Optional[str] = None
    friendship_status: Optional[str] = None  # None, 'pending', 'accepted', 'blocked'

class SocialFeedResponse(BaseModel):
    posts: List[SocialPostData]
    has_more: bool
    next_cursor: Optional[str] = None

# Social statistics schemas
class PostTypeStats(BaseModel):
    activity_update: int = 0
    vice_progress: int = 0
    achievement: int = 0
    general: int = 0

class SocialStatisticsResponse(BaseModel):
    total_posts: int
    total_likes: int
    total_comments: int
    friends_count: int
    pending_requests: int
    avg_likes_per_post: float
    avg_comments_per_post: float
    post_type_breakdown: PostTypeStats
    most_popular_post_id: Optional[str] = None
    most_popular_post_likes: int = 0