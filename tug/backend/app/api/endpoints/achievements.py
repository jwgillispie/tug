# app/api/endpoints/achievements.py
from fastapi import APIRouter, Depends, HTTPException, status
from typing import List, Dict, Any, Optional
import logging

from ...models.user import User
from ...models.achievement import Achievement
from ...schemas.achievement import (
    AchievementResponse,
    AchievementUpdate,
    PredefinedAchievement
)
from ...services.achievement_service import AchievementService
from ...core.auth import get_current_user
from ...utils.json_utils import MongoJSONEncoder

router = APIRouter()
logger = logging.getLogger(__name__)

@router.get("/", response_model=List[AchievementResponse])
async def get_achievements(
    current_user: User = Depends(get_current_user)
):
    """Get all achievements for the current user with calculated progress"""
    try:
        logger.info(f"Getting achievements for user: {current_user.id}")
        
        achievements = await AchievementService.get_user_achievements(current_user)
        
        # Convert to dictionary and encode MongoDB types
        achievements_list = []
        for achievement in achievements:
            achievement_dict = achievement.model_dump()
            achievement_dict = MongoJSONEncoder.encode_mongo_data(achievement_dict)
            achievements_list.append(achievement_dict)
        
        logger.info(f"Retrieved {len(achievements)} achievements")
        return achievements_list
    except Exception as e:
        logger.error(f"Error getting achievements: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get achievements: {str(e)}"
        )

@router.get("/predefined", response_model=List[PredefinedAchievement])
async def get_predefined_achievements():
    """Get list of all predefined achievement templates"""
    try:
        logger.info("Getting predefined achievements")
        predefined = AchievementService.get_predefined_achievements()
        logger.info(f"Retrieved {len(predefined)} predefined achievements")
        return predefined
    except Exception as e:
        logger.error(f"Error getting predefined achievements: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get predefined achievements: {str(e)}"
        )

@router.get("/check", response_model=List[AchievementResponse])
async def check_achievements(
    current_user: User = Depends(get_current_user)
):
    """Check and update all achievements, return newly unlocked achievements"""
    try:
        logger.info(f"Checking achievements for user: {current_user.id}")
        
        newly_unlocked = await AchievementService.check_and_update_achievements(current_user)
        
        # Convert to dictionary and encode MongoDB types
        achievements_list = []
        for achievement in newly_unlocked:
            achievement_dict = achievement.model_dump()
            achievement_dict = MongoJSONEncoder.encode_mongo_data(achievement_dict)
            achievements_list.append(achievement_dict)
        
        logger.info(f"User {current_user.id} unlocked {len(newly_unlocked)} new achievements")
        return achievements_list
    except Exception as e:
        logger.error(f"Error checking achievements: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to check achievements: {str(e)}"
        )

@router.get("/{achievement_id}", response_model=AchievementResponse)
async def get_achievement(
    achievement_id: str,
    current_user: User = Depends(get_current_user)
):
    """Get a specific achievement by ID"""
    try:
        logger.info(f"Getting achievement {achievement_id} for user: {current_user.id}")
        
        achievement = await AchievementService.get_achievement(current_user, achievement_id)
        
        # Convert to dictionary and encode MongoDB types
        achievement_dict = achievement.model_dump()
        achievement_dict = MongoJSONEncoder.encode_mongo_data(achievement_dict)
        
        return achievement_dict
    except HTTPException:
        # Re-raise HTTP exceptions
        raise
    except Exception as e:
        logger.error(f"Error getting achievement: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get achievement: {str(e)}"
        )

@router.patch("/{achievement_id}", response_model=AchievementResponse)
async def update_achievement(
    achievement_id: str,
    updates: AchievementUpdate,
    current_user: User = Depends(get_current_user)
):
    """Update a specific achievement (admin functionality)"""
    try:
        logger.info(f"Updating achievement {achievement_id} for user: {current_user.id}")
        
        # Check if user is admin (you might want to add proper admin check here)
        # For now we'll allow users to update their own achievements
        
        # Update the achievement
        achievement = await AchievementService.update_achievement(
            current_user, 
            achievement_id, 
            updates
        )
        
        # Convert to dictionary and encode MongoDB types
        achievement_dict = achievement.model_dump()
        achievement_dict = MongoJSONEncoder.encode_mongo_data(achievement_dict)
        
        logger.info(f"Achievement {achievement_id} updated successfully")
        return achievement_dict
    except HTTPException:
        # Re-raise HTTP exceptions
        raise
    except Exception as e:
        logger.error(f"Error updating achievement: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update achievement: {str(e)}"
        )

@router.post("/reinitialize")
async def reinitialize_achievements(
    current_user: User = Depends(get_current_user)
):
    """Reinitialize user achievements with latest definitions (fixes lowercase text)"""
    try:
        logger.info(f"Reinitializing achievements for user: {current_user.id}")
        
        # Delete existing achievements for the user
        await Achievement.find(Achievement.user_id == str(current_user.id)).delete()
        logger.info(f"Deleted existing achievements for user {current_user.id}")
        
        # Initialize with latest definitions
        await AchievementService.initialize_user_achievements(str(current_user.id))
        logger.info(f"Reinitialized achievements for user {current_user.id}")
        
        # Get the new achievements
        achievements = await AchievementService.get_user_achievements(current_user)
        
        return {
            "message": "Achievements reinitialized successfully",
            "count": len(achievements)
        }
        
    except Exception as e:
        logger.error(f"Error reinitializing achievements: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to reinitialize achievements: {str(e)}"
        )

