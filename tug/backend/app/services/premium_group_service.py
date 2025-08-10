# app/services/premium_group_service.py
import logging
from typing import List, Optional, Tuple, Dict, Any
from datetime import datetime, timedelta, date
from fastapi import HTTPException, status
from bson import ObjectId
import asyncio

from ..models.user import User, SubscriptionTier
from ..models.premium_group import (
    PremiumGroup, GroupMembership, GroupChallenge, GroupPost,
    GroupType, GroupPrivacyLevel, GroupRole, GroupStatus, MembershipStatus
)
from ..models.group_analytics import GroupAnalytics, MemberAnalytics, GroupInsight
from ..schemas.premium_group import (
    PremiumGroupCreate, PremiumGroupUpdate, PremiumGroupData,
    GroupInvitationCreate, GroupMemberData, GroupChallengeCreate, 
    GroupChallengeData, GroupPostCreate, GroupPostData,
    GroupAnalyticsData, GroupInsightData, GroupSearchFilters, GroupSearchResult,
    GroupDashboardData, GroupLeaderboardEntry
)
from .notification_service import NotificationService
from .ml_prediction_service import MLPredictionService
from ..utils.validation import InputValidator

logger = logging.getLogger(__name__)

class PremiumGroupService:
    """Service for managing premium group features and functionality"""
    
    # Premium Group Management
    @staticmethod
    async def create_group(current_user: User, group_data: PremiumGroupCreate) -> PremiumGroup:
        """Create a new premium group (premium users only)"""
        try:
            # Check if user has premium subscription
            if not PremiumGroupService._is_premium_user(current_user):
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Premium subscription required to create groups"
                )
            
            # Check if user has reached group creation limit
            user_owned_groups = await GroupMembership.find({
                "user_id": str(current_user.id),
                "role": GroupRole.OWNER,
                "status": MembershipStatus.ACTIVE
            }).count()
            
            max_owned_groups = 10 if current_user.subscription_tier == SubscriptionTier.PREMIUM else 50
            if user_owned_groups >= max_owned_groups:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Maximum number of owned groups ({max_owned_groups}) reached"
                )
            
            # Validate and sanitize input
            sanitized_name = InputValidator.sanitize_string(group_data.name, max_length=100)
            sanitized_description = InputValidator.sanitize_string(group_data.description, max_length=500)
            
            # Create the group
            group = PremiumGroup(
                name=sanitized_name,
                description=sanitized_description,
                group_type=group_data.group_type,
                privacy_level=group_data.privacy_level,
                theme_color=group_data.theme_color,
                custom_tags=group_data.custom_tags,
                rules=group_data.rules,
                max_members=group_data.max_members,
                approval_required=group_data.approval_required,
                analytics_enabled=group_data.analytics_enabled,
                leaderboard_enabled=group_data.leaderboard_enabled,
                coaching_enabled=group_data.coaching_enabled,
                challenge_creation_enabled=group_data.challenge_creation_enabled,
                total_members=1  # Creator is first member
            )
            
            await group.save()
            
            # Create owner membership
            membership = GroupMembership(
                group_id=str(group.id),
                user_id=str(current_user.id),
                role=GroupRole.OWNER,
                status=MembershipStatus.ACTIVE,
                join_date=datetime.utcnow()
            )
            await membership.save()
            
            logger.info(f"Premium group created: {group.id} by user {current_user.id}")
            
            # Initialize analytics
            await PremiumGroupService._initialize_group_analytics(str(group.id))
            
            return group
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error creating premium group: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create group"
            )
    
    @staticmethod
    async def update_group(current_user: User, group_id: str, group_data: PremiumGroupUpdate) -> PremiumGroup:
        """Update group settings (admin/owner only)"""
        try:
            group = await PremiumGroup.get(group_id)
            if not group:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Group not found"
                )
            
            # Check user permissions
            membership = await PremiumGroupService._get_user_membership(str(current_user.id), group_id)
            if not membership or membership.role not in [GroupRole.OWNER, GroupRole.ADMIN]:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Insufficient permissions to update group"
                )
            
            # Update fields
            update_data = group_data.dict(exclude_unset=True)
            for field, value in update_data.items():
                if hasattr(group, field):
                    setattr(group, field, value)
            
            group.update_timestamp()
            await group.save()
            
            logger.info(f"Group updated: {group_id} by user {current_user.id}")
            return group
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error updating group: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to update group"
            )
    
    @staticmethod
    async def get_group_details(current_user: User, group_id: str) -> PremiumGroupData:
        """Get detailed group information"""
        try:
            group = await PremiumGroup.get(group_id)
            if not group:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Group not found"
                )
            
            # Check if user can view this group
            membership = await PremiumGroupService._get_user_membership(str(current_user.id), group_id)
            
            if group.privacy_level == GroupPrivacyLevel.PRIVATE and not membership:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Group is private"
                )
            
            # Build group data with user context
            group_data = PremiumGroupData(
                id=str(group.id),
                name=group.name,
                description=group.description,
                group_type=group.group_type,
                privacy_level=group.privacy_level,
                status=group.status,
                avatar_url=group.avatar_url,
                banner_url=group.banner_url,
                theme_color=group.theme_color,
                custom_tags=group.custom_tags,
                rules=group.rules,
                max_members=group.max_members,
                total_members=group.total_members,
                active_members_30d=group.active_members_30d,
                approval_required=group.approval_required,
                analytics_enabled=group.analytics_enabled,
                leaderboard_enabled=group.leaderboard_enabled,
                coaching_enabled=group.coaching_enabled,
                challenge_creation_enabled=group.challenge_creation_enabled,
                created_at=group.created_at,
                updated_at=group.updated_at,
                last_activity_at=group.last_activity_at,
                average_engagement_score=group.average_engagement_score,
                user_role=membership.role if membership else None,
                user_membership_status=membership.status if membership else None
            )
            
            return group_data
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error getting group details: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to get group details"
            )
    
    # Member Management
    @staticmethod
    async def invite_member(current_user: User, group_id: str, invitation: GroupInvitationCreate) -> GroupMembership:
        """Invite a user to join the group"""
        try:
            # Check permissions
            membership = await PremiumGroupService._get_user_membership(str(current_user.id), group_id)
            if not membership or membership.role not in [GroupRole.OWNER, GroupRole.ADMIN, GroupRole.MODERATOR]:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Insufficient permissions to invite members"
                )
            
            # Check if user exists and has premium
            invitee = await User.get(invitation.user_id)
            if not invitee:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="User not found"
                )
            
            if not PremiumGroupService._is_premium_user(invitee):
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="User must have premium subscription to join groups"
                )
            
            # Check if invitation already exists
            existing_membership = await PremiumGroupService._get_user_membership(invitation.user_id, group_id)
            if existing_membership:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="User is already a member or has pending invitation"
                )
            
            # Check group capacity
            group = await PremiumGroup.get(group_id)
            if group.total_members >= group.max_members:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Group has reached maximum capacity"
                )
            
            # Create invitation
            new_membership = GroupMembership(
                group_id=group_id,
                user_id=invitation.user_id,
                role=invitation.role,
                status=MembershipStatus.INVITED,
                invited_by=str(current_user.id),
                invitation_message=invitation.invitation_message
            )
            
            await new_membership.save()
            
            # Send notification to invitee
            await NotificationService.create_group_invitation_notification(
                invitee_id=invitation.user_id,
                inviter_id=str(current_user.id),
                inviter_name=current_user.display_name or current_user.username,
                group_id=group_id,
                group_name=group.name
            )
            
            logger.info(f"Group invitation sent: {group_id} to user {invitation.user_id}")
            return new_membership
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error inviting member: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to invite member"
            )
    
    @staticmethod
    async def respond_to_invitation(current_user: User, group_id: str, accept: bool) -> GroupMembership:
        """Accept or reject a group invitation"""
        try:
            membership = await PremiumGroupService._get_user_membership(str(current_user.id), group_id)
            if not membership or membership.status != MembershipStatus.INVITED:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="No pending invitation found"
                )
            
            if accept:
                # Check premium status again
                if not PremiumGroupService._is_premium_user(current_user):
                    raise HTTPException(
                        status_code=status.HTTP_403_FORBIDDEN,
                        detail="Premium subscription required to join groups"
                    )
                
                # Check group capacity
                group = await PremiumGroup.get(group_id)
                if group.total_members >= group.max_members:
                    raise HTTPException(
                        status_code=status.HTTP_400_BAD_REQUEST,
                        detail="Group has reached maximum capacity"
                    )
                
                # Accept invitation
                membership.status = MembershipStatus.ACTIVE
                membership.join_date = datetime.utcnow()
                membership.update_timestamp()
                await membership.save()
                
                # Update group member count
                group.total_members += 1
                group.update_activity_timestamp()
                await group.save()
                
                logger.info(f"Group invitation accepted: {group_id} by user {current_user.id}")
                
            else:
                # Reject invitation
                await membership.delete()
                logger.info(f"Group invitation rejected: {group_id} by user {current_user.id}")
            
            return membership
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error responding to invitation: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to respond to invitation"
            )
    
    @staticmethod
    async def get_group_members(current_user: User, group_id: str, limit: int = 50, skip: int = 0) -> List[GroupMemberData]:
        """Get list of group members"""
        try:
            # Check if user can view members
            membership = await PremiumGroupService._get_user_membership(str(current_user.id), group_id)
            if not membership:
                group = await PremiumGroup.get(group_id)
                if not group or group.privacy_level == GroupPrivacyLevel.PRIVATE:
                    raise HTTPException(
                        status_code=status.HTTP_403_FORBIDDEN,
                        detail="Cannot view members of this group"
                    )
            
            # Get active memberships
            memberships = await GroupMembership.find({
                "group_id": group_id,
                "status": MembershipStatus.ACTIVE
            }).sort([("join_date", -1)]).skip(skip).limit(limit).to_list()
            
            # Get user info for members
            member_user_ids = [m.user_id for m in memberships]
            users = await User.find({"_id": {"$in": [ObjectId(uid) for uid in member_user_ids]}}).to_list()
            user_map = {str(user.id): user for user in users}
            
            # Build member data
            member_data_list = []
            for membership in memberships:
                user = user_map.get(membership.user_id)
                if user:
                    member_data = GroupMemberData(
                        id=str(membership.id),
                        user_id=membership.user_id,
                        username=user.username or user.effective_username,
                        display_name=user.display_name,
                        role=membership.role,
                        status=membership.status,
                        join_date=membership.join_date,
                        last_active_at=membership.last_active_at,
                        total_posts=membership.total_posts,
                        engagement_score=membership.engagement_score,
                        participation_streak=membership.participation_streak,
                        group_achievements=membership.group_achievements
                    )
                    member_data_list.append(member_data)
            
            return member_data_list
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error getting group members: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to get group members"
            )
    
    # Group Analytics
    @staticmethod
    async def get_group_analytics(current_user: User, group_id: str, period: str = "monthly") -> GroupAnalyticsData:
        """Get group analytics (admin/owner only)"""
        try:
            # Check permissions
            membership = await PremiumGroupService._get_user_membership(str(current_user.id), group_id)
            if not membership or membership.role not in [GroupRole.OWNER, GroupRole.ADMIN]:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Insufficient permissions to view analytics"
                )
            
            # Get latest analytics for the period
            analytics = await GroupAnalytics.find({
                "group_id": group_id,
                "period": period
            }).sort([("period_start", -1)]).limit(1).to_list()
            
            if not analytics:
                # Generate analytics if none exist
                await PremiumGroupService._generate_group_analytics(group_id, period)
                analytics = await GroupAnalytics.find({
                    "group_id": group_id,
                    "period": period
                }).sort([("period_start", -1)]).limit(1).to_list()
            
            if not analytics:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Analytics data not available"
                )
            
            analytics_data = analytics[0]
            return GroupAnalyticsData(
                period=analytics_data.period,
                period_start=analytics_data.period_start,
                period_end=analytics_data.period_end,
                total_members=analytics_data.total_members,
                active_members=analytics_data.active_members,
                new_members=analytics_data.new_members,
                departed_members=analytics_data.departed_members,
                member_retention_rate=analytics_data.member_retention_rate,
                total_posts=analytics_data.total_posts,
                total_comments=analytics_data.total_comments,
                total_activities_shared=analytics_data.total_activities_shared,
                posts_per_active_member=analytics_data.posts_per_active_member,
                comments_per_post=analytics_data.comments_per_post,
                member_interaction_rate=analytics_data.member_interaction_rate,
                growth_rate=analytics_data.growth_rate,
                engagement_trend=analytics_data.engagement_trend,
                satisfaction_score=analytics_data.satisfaction_score,
                top_contributors=analytics_data.top_contributors,
                popular_topics=analytics_data.popular_topics,
                peak_activity_hours=analytics_data.peak_activity_hours
            )
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error getting group analytics: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to get group analytics"
            )
    
    # Helper Methods
    @staticmethod
    def _is_premium_user(user: User) -> bool:
        """Check if user has premium subscription"""
        if user.subscription_tier in [SubscriptionTier.PREMIUM, SubscriptionTier.LIFETIME]:
            # Check if subscription is active
            if user.subscription_tier == SubscriptionTier.LIFETIME:
                return True
            if user.subscription_expires_at and user.subscription_expires_at > datetime.utcnow():
                return True
        return False
    
    @staticmethod
    async def _get_user_membership(user_id: str, group_id: str) -> Optional[GroupMembership]:
        """Get user's membership in a group"""
        return await GroupMembership.find_one({
            "user_id": user_id,
            "group_id": group_id
        })
    
    @staticmethod
    async def _initialize_group_analytics(group_id: str):
        """Initialize analytics for a new group"""
        try:
            # Create initial analytics record
            today = date.today()
            analytics = GroupAnalytics(
                group_id=group_id,
                period="monthly",
                period_start=today.replace(day=1),
                period_end=today,
                total_members=1,
                active_members=1,
                new_members=1
            )
            await analytics.save()
            
        except Exception as e:
            logger.error(f"Error initializing group analytics: {e}")
    
    @staticmethod
    async def _generate_group_analytics(group_id: str, period: str):
        """Generate analytics for a group"""
        # This would implement the analytics calculation logic
        # For brevity, this is a placeholder
        pass
    
    @staticmethod
    async def get_user_groups(current_user: User) -> List[PremiumGroupData]:
        """Get all groups the user is a member of"""
        try:
            if not PremiumGroupService._is_premium_user(current_user):
                return []
            
            # Get user's memberships
            memberships = await GroupMembership.find({
                "user_id": str(current_user.id),
                "status": MembershipStatus.ACTIVE
            }).to_list()
            
            if not memberships:
                return []
            
            # Get groups
            group_ids = [m.group_id for m in memberships]
            groups = await PremiumGroup.find({
                "_id": {"$in": [ObjectId(gid) for gid in group_ids]},
                "status": GroupStatus.ACTIVE
            }).to_list()
            
            # Create membership lookup
            membership_map = {m.group_id: m for m in memberships}
            
            # Build group data
            group_data_list = []
            for group in groups:
                membership = membership_map[str(group.id)]
                group_data = PremiumGroupData(
                    id=str(group.id),
                    name=group.name,
                    description=group.description,
                    group_type=group.group_type,
                    privacy_level=group.privacy_level,
                    status=group.status,
                    avatar_url=group.avatar_url,
                    banner_url=group.banner_url,
                    theme_color=group.theme_color,
                    custom_tags=group.custom_tags,
                    rules=group.rules,
                    max_members=group.max_members,
                    total_members=group.total_members,
                    active_members_30d=group.active_members_30d,
                    approval_required=group.approval_required,
                    analytics_enabled=group.analytics_enabled,
                    leaderboard_enabled=group.leaderboard_enabled,
                    coaching_enabled=group.coaching_enabled,
                    challenge_creation_enabled=group.challenge_creation_enabled,
                    created_at=group.created_at,
                    updated_at=group.updated_at,
                    last_activity_at=group.last_activity_at,
                    average_engagement_score=group.average_engagement_score,
                    user_role=membership.role,
                    user_membership_status=membership.status
                )
                group_data_list.append(group_data)
            
            return sorted(group_data_list, key=lambda x: x.last_activity_at, reverse=True)
            
        except Exception as e:
            logger.error(f"Error getting user groups: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to get user groups"
            )

    @staticmethod
    async def update_member_role(current_user: User, group_id: str, role_update) -> GroupMembership:
        """Update a member's role in the group"""
        try:
            # Check if current user has permission to change roles
            current_membership = await PremiumGroupService._get_user_membership(str(current_user.id), group_id)
            if not current_membership or current_membership.role not in [GroupRole.OWNER, GroupRole.ADMIN]:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Insufficient permissions to change member roles"
                )
            
            # Get target member's membership
            target_membership = await PremiumGroupService._get_user_membership(role_update.user_id, group_id)
            if not target_membership:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Member not found in group"
                )
            
            # Prevent self-demotion from owner
            if target_membership.user_id == str(current_user.id) and target_membership.role == GroupRole.OWNER:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Cannot change your own owner role"
                )
            
            # Check role hierarchy (admins can't promote to owner unless they are owner)
            if role_update.new_role == GroupRole.OWNER and current_membership.role != GroupRole.OWNER:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Only group owners can assign owner role"
                )
            
            # Update role
            target_membership.role = role_update.new_role
            target_membership.update_timestamp()
            await target_membership.save()
            
            logger.info(f"Member role updated: {role_update.user_id} to {role_update.new_role} in group {group_id}")
            return target_membership
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error updating member role: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to update member role"
            )

    @staticmethod
    async def remove_member(current_user: User, group_id: str, user_id: str) -> bool:
        """Remove a member from the group"""
        try:
            # Check permissions
            current_membership = await PremiumGroupService._get_user_membership(str(current_user.id), group_id)
            if not current_membership or current_membership.role not in [GroupRole.OWNER, GroupRole.ADMIN, GroupRole.MODERATOR]:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Insufficient permissions to remove members"
                )
            
            # Get target membership
            target_membership = await PremiumGroupService._get_user_membership(user_id, group_id)
            if not target_membership:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Member not found in group"
                )
            
            # Prevent removing owners unless you're an owner
            if target_membership.role == GroupRole.OWNER and current_membership.role != GroupRole.OWNER:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Cannot remove group owners"
                )
            
            # Update membership status
            target_membership.status = MembershipStatus.REMOVED
            target_membership.update_timestamp()
            await target_membership.save()
            
            # Update group member count
            group = await PremiumGroup.get(group_id)
            if group:
                group.total_members = max(0, group.total_members - 1)
                await group.save()
            
            logger.info(f"Member removed: {user_id} from group {group_id} by {current_user.id}")
            return True
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error removing member: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to remove member"
            )

    @staticmethod
    async def delete_group(current_user: User, group_id: str) -> bool:
        """Delete a group (owner only)"""
        try:
            # Check ownership
            membership = await PremiumGroupService._get_user_membership(str(current_user.id), group_id)
            if not membership or membership.role != GroupRole.OWNER:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Only group owners can delete groups"
                )
            
            # Archive the group instead of hard delete
            group = await PremiumGroup.get(group_id)
            if not group:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Group not found"
                )
            
            group.status = GroupStatus.ARCHIVED
            group.update_timestamp()
            await group.save()
            
            # Update all memberships to removed
            await GroupMembership.find({
                "group_id": group_id,
                "status": MembershipStatus.ACTIVE
            }).update_many({"$set": {"status": MembershipStatus.REMOVED}})
            
            logger.info(f"Group deleted/archived: {group_id} by owner {current_user.id}")
            return True
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error deleting group: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to delete group"
            )

    @staticmethod
    async def search_groups(current_user: User, query: Optional[str], filters, limit: int = 20, skip: int = 0):
        """Search and discover premium groups"""
        try:
            if not PremiumGroupService._is_premium_user(current_user):
                return []
            
            # Build search query
            search_query = {
                "status": GroupStatus.ACTIVE,
                "privacy_level": {"$in": [GroupPrivacyLevel.PUBLIC, GroupPrivacyLevel.DISCOVERABLE]}
            }
            
            # Add text search if query provided
            if query:
                search_query["$or"] = [
                    {"name": {"$regex": query, "$options": "i"}},
                    {"description": {"$regex": query, "$options": "i"}},
                    {"custom_tags": {"$in": [query]}}
                ]
            
            # Add filters
            if filters.group_type:
                search_query["group_type"] = filters.group_type
            if filters.privacy_level:
                search_query["privacy_level"] = filters.privacy_level
            if filters.tags:
                search_query["custom_tags"] = {"$in": filters.tags}
            if filters.min_members:
                search_query["total_members"] = {"$gte": filters.min_members}
            if filters.max_members:
                search_query.setdefault("total_members", {})["$lte"] = filters.max_members
            
            # Execute search
            groups = await PremiumGroup.find(search_query)\
                .sort([("average_engagement_score", -1), ("total_members", -1)])\
                .skip(skip)\
                .limit(limit)\
                .to_list()
            
            # Convert to search results
            results = []
            for group in groups:
                result = GroupSearchResult(
                    id=str(group.id),
                    name=group.name,
                    description=group.description,
                    group_type=group.group_type,
                    privacy_level=group.privacy_level,
                    theme_color=group.theme_color,
                    avatar_url=group.avatar_url,
                    total_members=group.total_members,
                    active_members_30d=group.active_members_30d,
                    custom_tags=group.custom_tags,
                    average_engagement_score=group.average_engagement_score,
                    created_at=group.created_at,
                    last_activity_at=group.last_activity_at,
                    relevance_score=1.0,  # Would calculate based on search match
                    user_can_join=True,
                    join_requirements=["Premium subscription required"]
                )
                results.append(result)
            
            return results
            
        except Exception as e:
            logger.error(f"Error searching groups: {e}", exc_info=True)
            return []

    @staticmethod
    async def get_recommended_groups(current_user: User, limit: int = 10):
        """Get AI-recommended groups for the user"""
        try:
            from .group_ml_service import GroupMLService
            recommendations = await GroupMLService.get_personalized_group_recommendations(str(current_user.id))
            return recommendations[:limit]
        except Exception as e:
            logger.error(f"Error getting recommended groups: {e}")
            return []

    @staticmethod
    async def get_group_dashboard(current_user: User, group_id: str):
        """Get comprehensive group dashboard (admin/owner only)"""
        try:
            # Check permissions
            membership = await PremiumGroupService._get_user_membership(str(current_user.id), group_id)
            if not membership or membership.role not in [GroupRole.OWNER, GroupRole.ADMIN]:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Insufficient permissions to view dashboard"
                )
            
            # Get group details
            group_data = await PremiumGroupService.get_group_details(current_user, group_id)
            
            # Get recent analytics
            analytics = await PremiumGroupService.get_group_analytics(current_user, group_id)
            
            # Get member count and pending invitations
            member_count = await GroupMembership.find({
                "group_id": group_id,
                "status": MembershipStatus.ACTIVE
            }).count()
            
            pending_invitations = await GroupMembership.find({
                "group_id": group_id,
                "status": MembershipStatus.INVITED
            }).count()
            
            # Get active challenges
            from .group_challenge_service import GroupChallengeService
            challenges = await GroupChallengeService.get_group_challenges(current_user, group_id, "active", 5, 0)
            
            # Get recent posts
            from .group_post_service import GroupPostService
            posts = await GroupPostService.get_group_feed(current_user, group_id, 10, 0)
            
            # Get top members
            top_members = await PremiumGroupService.get_group_members(current_user, group_id, 10, 0)
            top_members = sorted(top_members, key=lambda x: x.engagement_score, reverse=True)[:5]
            
            # Get recent insights
            from .group_analytics_service import GroupAnalyticsService
            insights = await GroupAnalyticsService.get_group_insights(current_user, group_id, 5)
            
            dashboard = GroupDashboardData(
                group=group_data,
                recent_analytics=analytics,
                member_count=member_count,
                pending_invitations=pending_invitations,
                active_challenges=len(challenges),
                recent_posts=posts[:5],
                top_members=top_members,
                recent_insights=insights,
                engagement_summary={
                    "total_posts_this_month": analytics.total_posts,
                    "active_member_percentage": (analytics.active_members / analytics.total_members * 100) if analytics.total_members > 0 else 0,
                    "growth_rate": analytics.growth_rate
                }
            )
            
            return dashboard
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error getting group dashboard: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to get group dashboard"
            )