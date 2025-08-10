# app/api/endpoints/premium_groups.py
from fastapi import APIRouter, Depends, HTTPException, status, Query, Path
from typing import List, Optional
import logging

from ...models.user import User
from ...schemas.premium_group import (
    PremiumGroupCreate, PremiumGroupUpdate, PremiumGroupData,
    GroupInvitationCreate, GroupMemberData, GroupChallengeCreate, 
    GroupChallengeData, GroupPostCreate, GroupPostData,
    GroupAnalyticsData, GroupInsightData, GroupSearchFilters, GroupSearchResult,
    GroupDashboardData, GroupLeaderboardEntry, GroupRoleUpdate
)
from ...services.premium_group_service import PremiumGroupService
from ...services.group_analytics_service import GroupAnalyticsService
from ...services.group_challenge_service import GroupChallengeService
from ...services.group_post_service import GroupPostService
from ...core.auth import get_current_user
from ...utils.json_utils import MongoJSONEncoder

router = APIRouter()
logger = logging.getLogger(__name__)

# Group Management Endpoints

@router.post("/", status_code=status.HTTP_201_CREATED)
async def create_premium_group(
    group_data: PremiumGroupCreate,
    current_user: User = Depends(get_current_user)
):
    """Create a new premium group (premium users only)"""
    try:
        group = await PremiumGroupService.create_group(current_user, group_data)
        
        group_dict = group.dict()
        group_dict = MongoJSONEncoder.encode_mongo_data(group_dict)
        
        return {"group": group_dict}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in create_premium_group endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create premium group"
        )

@router.get("/my-groups")
async def get_user_groups(
    current_user: User = Depends(get_current_user)
):
    """Get all groups the user is a member of"""
    try:
        groups = await PremiumGroupService.get_user_groups(current_user)
        return {"groups": groups}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in get_user_groups endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get user groups"
        )

@router.get("/{group_id}")
async def get_group_details(
    group_id: str = Path(..., description="Group ID"),
    current_user: User = Depends(get_current_user)
):
    """Get detailed information about a specific group"""
    try:
        group_data = await PremiumGroupService.get_group_details(current_user, group_id)
        return {"group": group_data}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in get_group_details endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get group details"
        )

@router.put("/{group_id}")
async def update_group(
    group_id: str = Path(..., description="Group ID"),
    group_data: PremiumGroupUpdate = ...,
    current_user: User = Depends(get_current_user)
):
    """Update group settings (admin/owner only)"""
    try:
        updated_group = await PremiumGroupService.update_group(current_user, group_id, group_data)
        
        group_dict = updated_group.dict()
        group_dict = MongoJSONEncoder.encode_mongo_data(group_dict)
        
        return {"group": group_dict}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in update_group endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to update group"
        )

@router.delete("/{group_id}")
async def delete_group(
    group_id: str = Path(..., description="Group ID"),
    current_user: User = Depends(get_current_user)
):
    """Delete a group (owner only)"""
    try:
        await PremiumGroupService.delete_group(current_user, group_id)
        return {"message": "Group deleted successfully"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in delete_group endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to delete group"
        )

# Member Management Endpoints

@router.post("/{group_id}/invite", status_code=status.HTTP_201_CREATED)
async def invite_member(
    group_id: str = Path(..., description="Group ID"),
    invitation: GroupInvitationCreate = ...,
    current_user: User = Depends(get_current_user)
):
    """Invite a user to join the group"""
    try:
        membership = await PremiumGroupService.invite_member(current_user, group_id, invitation)
        
        membership_dict = membership.dict()
        membership_dict = MongoJSONEncoder.encode_mongo_data(membership_dict)
        
        return {"membership": membership_dict}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in invite_member endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to invite member"
        )

@router.post("/{group_id}/respond-invitation")
async def respond_to_invitation(
    group_id: str = Path(..., description="Group ID"),
    accept: bool = Query(..., description="True to accept, False to reject"),
    current_user: User = Depends(get_current_user)
):
    """Accept or reject a group invitation"""
    try:
        membership = await PremiumGroupService.respond_to_invitation(current_user, group_id, accept)
        
        if not accept:
            return {"message": "Invitation rejected"}
        
        membership_dict = membership.dict()
        membership_dict = MongoJSONEncoder.encode_mongo_data(membership_dict)
        
        return {"membership": membership_dict}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in respond_to_invitation endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to respond to invitation"
        )

@router.get("/{group_id}/members")
async def get_group_members(
    group_id: str = Path(..., description="Group ID"),
    limit: int = Query(50, ge=1, le=100, description="Number of members to return"),
    skip: int = Query(0, ge=0, description="Number of members to skip"),
    current_user: User = Depends(get_current_user)
):
    """Get list of group members"""
    try:
        members = await PremiumGroupService.get_group_members(current_user, group_id, limit, skip)
        return {"members": members}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in get_group_members endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get group members"
        )

@router.put("/{group_id}/members/role")
async def update_member_role(
    group_id: str = Path(..., description="Group ID"),
    role_update: GroupRoleUpdate = ...,
    current_user: User = Depends(get_current_user)
):
    """Update a member's role (admin/owner only)"""
    try:
        membership = await PremiumGroupService.update_member_role(current_user, group_id, role_update)
        
        membership_dict = membership.dict()
        membership_dict = MongoJSONEncoder.encode_mongo_data(membership_dict)
        
        return {"membership": membership_dict}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in update_member_role endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to update member role"
        )

@router.delete("/{group_id}/members/{user_id}")
async def remove_member(
    group_id: str = Path(..., description="Group ID"),
    user_id: str = Path(..., description="User ID to remove"),
    current_user: User = Depends(get_current_user)
):
    """Remove a member from the group (admin/owner only)"""
    try:
        await PremiumGroupService.remove_member(current_user, group_id, user_id)
        return {"message": "Member removed successfully"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in remove_member endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to remove member"
        )

# Analytics Endpoints

@router.get("/{group_id}/analytics")
async def get_group_analytics(
    group_id: str = Path(..., description="Group ID"),
    period: str = Query("monthly", regex="^(daily|weekly|monthly|quarterly)$", description="Analytics period"),
    current_user: User = Depends(get_current_user)
):
    """Get group analytics (admin/owner only)"""
    try:
        analytics = await PremiumGroupService.get_group_analytics(current_user, group_id, period)
        return {"analytics": analytics}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in get_group_analytics endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get group analytics"
        )

@router.get("/{group_id}/insights")
async def get_group_insights(
    group_id: str = Path(..., description="Group ID"),
    limit: int = Query(10, ge=1, le=50, description="Number of insights to return"),
    current_user: User = Depends(get_current_user)
):
    """Get AI-generated insights for the group (admin/owner only)"""
    try:
        insights = await GroupAnalyticsService.get_group_insights(current_user, group_id, limit)
        return {"insights": insights}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in get_group_insights endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get group insights"
        )

@router.get("/{group_id}/leaderboard")
async def get_group_leaderboard(
    group_id: str = Path(..., description="Group ID"),
    metric: str = Query("engagement", regex="^(engagement|posts|activities|streak)$", description="Leaderboard metric"),
    limit: int = Query(20, ge=1, le=100, description="Number of entries to return"),
    current_user: User = Depends(get_current_user)
):
    """Get group leaderboard"""
    try:
        leaderboard = await GroupAnalyticsService.get_group_leaderboard(current_user, group_id, metric, limit)
        return {"leaderboard": leaderboard}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in get_group_leaderboard endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get group leaderboard"
        )

# Challenge Endpoints

@router.post("/{group_id}/challenges", status_code=status.HTTP_201_CREATED)
async def create_group_challenge(
    group_id: str = Path(..., description="Group ID"),
    challenge_data: GroupChallengeCreate = ...,
    current_user: User = Depends(get_current_user)
):
    """Create a new group challenge"""
    try:
        challenge = await GroupChallengeService.create_challenge(current_user, group_id, challenge_data)
        
        challenge_dict = challenge.dict()
        challenge_dict = MongoJSONEncoder.encode_mongo_data(challenge_dict)
        
        return {"challenge": challenge_dict}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in create_group_challenge endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create group challenge"
        )

@router.get("/{group_id}/challenges")
async def get_group_challenges(
    group_id: str = Path(..., description="Group ID"),
    status_filter: Optional[str] = Query(None, regex="^(upcoming|active|completed|cancelled)$", description="Filter by challenge status"),
    limit: int = Query(20, ge=1, le=100, description="Number of challenges to return"),
    skip: int = Query(0, ge=0, description="Number of challenges to skip"),
    current_user: User = Depends(get_current_user)
):
    """Get group challenges"""
    try:
        challenges = await GroupChallengeService.get_group_challenges(current_user, group_id, status_filter, limit, skip)
        return {"challenges": challenges}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in get_group_challenges endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get group challenges"
        )

@router.post("/{group_id}/challenges/{challenge_id}/join")
async def join_challenge(
    group_id: str = Path(..., description="Group ID"),
    challenge_id: str = Path(..., description="Challenge ID"),
    current_user: User = Depends(get_current_user)
):
    """Join a group challenge"""
    try:
        participation = await GroupChallengeService.join_challenge(current_user, group_id, challenge_id)
        
        participation_dict = participation.dict()
        participation_dict = MongoJSONEncoder.encode_mongo_data(participation_dict)
        
        return {"participation": participation_dict}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in join_challenge endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to join challenge"
        )

# Post and Feed Endpoints

@router.post("/{group_id}/posts", status_code=status.HTTP_201_CREATED)
async def create_group_post(
    group_id: str = Path(..., description="Group ID"),
    post_data: GroupPostCreate = ...,
    current_user: User = Depends(get_current_user)
):
    """Create a new group post"""
    try:
        post = await GroupPostService.create_post(current_user, group_id, post_data)
        
        post_dict = post.dict()
        post_dict = MongoJSONEncoder.encode_mongo_data(post_dict)
        
        return {"post": post_dict}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in create_group_post endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create group post"
        )

@router.get("/{group_id}/feed")
async def get_group_feed(
    group_id: str = Path(..., description="Group ID"),
    limit: int = Query(20, ge=1, le=50, description="Number of posts to return"),
    skip: int = Query(0, ge=0, description="Number of posts to skip"),
    post_type: Optional[str] = Query(None, description="Filter by post type"),
    current_user: User = Depends(get_current_user)
):
    """Get group activity feed"""
    try:
        posts = await GroupPostService.get_group_feed(current_user, group_id, limit, skip, post_type)
        return {"posts": posts}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in get_group_feed endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get group feed"
        )

# Group Discovery

@router.get("/search")
async def search_groups(
    q: Optional[str] = Query(None, min_length=1, description="Search query"),
    group_type: Optional[str] = Query(None, description="Filter by group type"),
    privacy_level: Optional[str] = Query(None, description="Filter by privacy level"),
    tags: Optional[str] = Query(None, description="Comma-separated list of tags"),
    limit: int = Query(20, ge=1, le=50, description="Number of results to return"),
    skip: int = Query(0, ge=0, description="Number of results to skip"),
    current_user: User = Depends(get_current_user)
):
    """Search and discover premium groups"""
    try:
        # Parse tags from comma-separated string
        tag_list = []
        if tags:
            tag_list = [tag.strip() for tag in tags.split(",") if tag.strip()]
        
        # Build search filters
        filters = GroupSearchFilters(
            tags=tag_list
        )
        
        if group_type:
            filters.group_type = group_type
        if privacy_level:
            filters.privacy_level = privacy_level
        
        results = await PremiumGroupService.search_groups(current_user, q, filters, limit, skip)
        return {"groups": results, "total": len(results)}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in search_groups endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to search groups"
        )

@router.get("/recommended")
async def get_recommended_groups(
    limit: int = Query(10, ge=1, le=20, description="Number of recommendations to return"),
    current_user: User = Depends(get_current_user)
):
    """Get AI-recommended groups for the user"""
    try:
        recommendations = await PremiumGroupService.get_recommended_groups(current_user, limit)
        return {"recommended_groups": recommendations}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in get_recommended_groups endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get recommended groups"
        )

# Dashboard

@router.get("/{group_id}/dashboard")
async def get_group_dashboard(
    group_id: str = Path(..., description="Group ID"),
    current_user: User = Depends(get_current_user)
):
    """Get comprehensive group dashboard data (admin/owner only)"""
    try:
        dashboard = await PremiumGroupService.get_group_dashboard(current_user, group_id)
        return {"dashboard": dashboard}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in get_group_dashboard endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get group dashboard"
        )