# app/services/group_challenge_service.py
import logging
from typing import List, Optional, Dict, Any
from datetime import datetime, timedelta
from fastapi import HTTPException, status
from bson import ObjectId

from ..models.user import User
from ..models.premium_group import PremiumGroup, GroupMembership, GroupChallenge, GroupRole
from ..schemas.premium_group import GroupChallengeCreate, GroupChallengeData
from .notification_service import NotificationService
from ..utils.validation import InputValidator

logger = logging.getLogger(__name__)

class GroupChallengeService:
    """Service for managing premium group challenges"""
    
    @staticmethod
    async def create_challenge(current_user: User, group_id: str, challenge_data: GroupChallengeCreate) -> GroupChallenge:
        """Create a new group challenge"""
        try:
            # Check if user is member and group allows challenge creation
            membership = await GroupMembership.find_one({
                "group_id": group_id,
                "user_id": str(current_user.id),
                "status": "active"
            })
            
            if not membership:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Must be a group member to create challenges"
                )
            
            group = await PremiumGroup.get(group_id)
            if not group or not group.challenge_creation_enabled:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Challenge creation is not enabled for this group"
                )
            
            # Check if user has challenge creation permissions
            if membership.role == GroupRole.MEMBER and not group.challenge_creation_enabled:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Insufficient permissions to create challenges"
                )
            
            # Validate challenge data
            sanitized_title = InputValidator.sanitize_string(challenge_data.title, max_length=100)
            sanitized_description = InputValidator.sanitize_string(challenge_data.description, max_length=1000)
            
            # Validate dates
            if challenge_data.start_date <= datetime.utcnow():
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Challenge start date must be in the future"
                )
            
            # Calculate end date
            end_date = challenge_data.start_date + timedelta(days=challenge_data.duration_days)
            registration_deadline = challenge_data.start_date - timedelta(hours=1)  # 1 hour before start
            
            # Create challenge
            challenge = GroupChallenge(
                group_id=group_id,
                creator_id=str(current_user.id),
                title=sanitized_title,
                description=sanitized_description,
                challenge_type=challenge_data.challenge_type,
                target_metric=challenge_data.target_metric,
                target_value=challenge_data.target_value,
                duration_days=challenge_data.duration_days,
                start_date=challenge_data.start_date,
                end_date=end_date,
                registration_deadline=registration_deadline,
                max_participants=challenge_data.max_participants,
                difficulty_level=challenge_data.difficulty_level,
                category_tags=challenge_data.category_tags,
                reward_type=challenge_data.reward_type,
                reward_data=challenge_data.reward_data,
                status="upcoming"
            )
            
            await challenge.save()
            
            # Update group activity
            group.update_activity_timestamp()
            await group.save()
            
            # Notify group members about new challenge
            await GroupChallengeService._notify_group_members(
                group_id,
                "new_challenge",
                f"New challenge '{challenge.title}' created by {current_user.display_name or current_user.username}",
                {"challenge_id": str(challenge.id)}
            )
            
            logger.info(f"Challenge created: {challenge.id} in group {group_id} by user {current_user.id}")
            return challenge
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error creating group challenge: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create challenge"
            )
    
    @staticmethod
    async def get_group_challenges(current_user: User, group_id: str, status_filter: Optional[str] = None, 
                                 limit: int = 20, skip: int = 0) -> List[GroupChallengeData]:
        """Get challenges for a group"""
        try:
            # Check if user can view challenges
            membership = await GroupMembership.find_one({
                "group_id": group_id,
                "user_id": str(current_user.id),
                "status": "active"
            })
            
            if not membership:
                # Check if group is public
                group = await PremiumGroup.get(group_id)
                if not group or group.privacy_level == "private":
                    raise HTTPException(
                        status_code=status.HTTP_403_FORBIDDEN,
                        detail="Cannot view challenges for this group"
                    )
            
            # Build query
            query = {"group_id": group_id}
            if status_filter:
                query["status"] = status_filter
            
            # Get challenges
            challenges = await GroupChallenge.find(query)\
                .sort([("start_date", -1)])\
                .skip(skip)\
                .limit(limit)\
                .to_list()
            
            # Get creator info
            creator_ids = list(set([c.creator_id for c in challenges]))
            creators = await User.find({"_id": {"$in": [ObjectId(cid) for cid in creator_ids]}}).to_list()
            creator_map = {str(user.id): user for user in creators}
            
            # Build challenge data
            challenge_data_list = []
            for challenge in challenges:
                creator = creator_map.get(challenge.creator_id)
                challenge_data = GroupChallengeData(
                    id=str(challenge.id),
                    group_id=challenge.group_id,
                    creator_id=challenge.creator_id,
                    creator_username=creator.username if creator else "Unknown",
                    title=challenge.title,
                    description=challenge.description,
                    challenge_type=challenge.challenge_type,
                    target_metric=challenge.target_metric,
                    target_value=challenge.target_value,
                    duration_days=challenge.duration_days,
                    difficulty_level=challenge.difficulty_level,
                    category_tags=challenge.category_tags,
                    status=challenge.status,
                    start_date=challenge.start_date,
                    end_date=challenge.end_date,
                    total_participants=challenge.total_participants,
                    completed_participants=challenge.completed_participants,
                    average_completion_rate=challenge.average_completion_rate,
                    created_at=challenge.created_at,
                    user_participating=False  # Would check participation status
                )
                challenge_data_list.append(challenge_data)
            
            return challenge_data_list
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error getting group challenges: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to get group challenges"
            )
    
    @staticmethod
    async def join_challenge(current_user: User, group_id: str, challenge_id: str) -> Dict[str, Any]:
        """Join a group challenge"""
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
                    detail="Must be a group member to join challenges"
                )
            
            # Get challenge
            challenge = await GroupChallenge.get(challenge_id)
            if not challenge or challenge.group_id != group_id:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Challenge not found"
                )
            
            # Check if challenge is still open for registration
            if challenge.status != "upcoming":
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Challenge is no longer accepting participants"
                )
            
            if challenge.registration_deadline and challenge.registration_deadline < datetime.utcnow():
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Registration deadline has passed"
                )
            
            # Check capacity
            if challenge.max_participants and challenge.total_participants >= challenge.max_participants:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Challenge has reached maximum capacity"
                )
            
            # Create participation record (simplified - would need proper model)
            participation_data = {
                "challenge_id": challenge_id,
                "user_id": str(current_user.id),
                "group_id": group_id,
                "joined_at": datetime.utcnow(),
                "status": "active",
                "progress": 0.0
            }
            
            # Update challenge participant count
            challenge.total_participants += 1
            challenge.update_timestamp()
            await challenge.save()
            
            # Update member's challenge participation
            membership.challenges_participated = getattr(membership, 'challenges_participated', 0) + 1
            membership.update_timestamp()
            await membership.save()
            
            logger.info(f"User {current_user.id} joined challenge {challenge_id}")
            return participation_data
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error joining challenge: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to join challenge"
            )
    
    @staticmethod
    async def update_challenge_progress(user_id: str, challenge_id: str, progress_data: Dict[str, Any]):
        """Update a user's progress in a challenge"""
        try:
            challenge = await GroupChallenge.get(challenge_id)
            if not challenge:
                return
            
            # This would update the user's progress tracking
            # For now, just log the progress update
            logger.info(f"Progress updated for user {user_id} in challenge {challenge_id}: {progress_data}")
            
            # Check if user completed the challenge
            if progress_data.get('completed', False):
                # Update challenge completion stats
                challenge.completed_participants += 1
                if challenge.total_participants > 0:
                    challenge.average_completion_rate = (challenge.completed_participants / challenge.total_participants) * 100
                await challenge.save()
                
                # Award achievements or rewards
                await GroupChallengeService._award_challenge_completion(user_id, challenge_id)
            
        except Exception as e:
            logger.error(f"Error updating challenge progress: {e}", exc_info=True)
    
    @staticmethod
    async def _notify_group_members(group_id: str, notification_type: str, message: str, data: Dict[str, Any]):
        """Send notifications to group members"""
        try:
            # Get active group members
            memberships = await GroupMembership.find({
                "group_id": group_id,
                "status": "active"
            }).to_list()
            
            # Send notifications
            for membership in memberships:
                # Check notification preferences
                if membership.notification_preferences.get("challenges", True):
                    await NotificationService.create_group_notification(
                        user_id=membership.user_id,
                        group_id=group_id,
                        notification_type=notification_type,
                        message=message,
                        data=data
                    )
            
        except Exception as e:
            logger.error(f"Error sending group notifications: {e}")
    
    @staticmethod
    async def _award_challenge_completion(user_id: str, challenge_id: str):
        """Award rewards for challenge completion"""
        try:
            challenge = await GroupChallenge.get(challenge_id)
            if not challenge or not challenge.reward_type:
                return
            
            # Get user's membership
            membership = await GroupMembership.find_one({
                "group_id": challenge.group_id,
                "user_id": user_id
            })
            
            if not membership:
                return
            
            # Award based on reward type
            if challenge.reward_type == "badge":
                badge_name = f"challenge_completion_{challenge_id}"
                if badge_name not in membership.group_achievements:
                    membership.group_achievements.append(badge_name)
                    await membership.save()
            
            elif challenge.reward_type == "points":
                points = challenge.reward_data.get("points", 10)
                membership.engagement_score += points
                await membership.save()
            
            logger.info(f"Awarded {challenge.reward_type} to user {user_id} for completing challenge {challenge_id}")
            
        except Exception as e:
            logger.error(f"Error awarding challenge completion: {e}")
    
    @staticmethod
    async def process_challenge_lifecycle():
        """Background task to update challenge statuses"""
        try:
            now = datetime.utcnow()
            
            # Start upcoming challenges
            await GroupChallenge.find({
                "status": "upcoming",
                "start_date": {"$lte": now}
            }).update_many({"$set": {"status": "active"}})
            
            # End active challenges
            await GroupChallenge.find({
                "status": "active",
                "end_date": {"$lte": now}
            }).update_many({"$set": {"status": "completed"}})
            
            logger.info("Challenge lifecycle processing completed")
            
        except Exception as e:
            logger.error(f"Error processing challenge lifecycle: {e}")