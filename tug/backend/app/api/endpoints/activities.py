# app/api/endpoints/activities.py
from bson import ObjectId
from fastapi import APIRouter, Depends, HTTPException, Query, status
from typing import Any, Dict, List, Optional
from datetime import datetime, timedelta
import logging

from ...models.user import User
from ...models.value import Value
from ...models.activity import Activity
from ...schemas.activity import (
    ActivityCreate, 
    ActivityUpdate, 
    ActivityResponse,
    ActivityStatistics
)
from ...services.activity_service import ActivityService
from ...services.value_service import ValueService
from ...core.auth import get_current_user
from ...utils.json_utils import MongoJSONEncoder

router = APIRouter()
logger = logging.getLogger(__name__)

@router.post("/", response_model=ActivityResponse, status_code=status.HTTP_201_CREATED)
async def create_activity(
    activity: ActivityCreate,
    current_user: User = Depends(get_current_user)
):
    """Create a new activity for the current user"""
    try:
        logger.info(f"Creating activity for user: {current_user.id}")
        new_activity = await ActivityService.create_activity(current_user, activity)
        
        # Update the streak for all associated values
        effective_value_ids = new_activity.effective_value_ids
        if new_activity and effective_value_ids:
            for value_id in effective_value_ids:
                try:
                    await ValueService.update_streak(value_id, new_activity.date)
                    logger.info(f"Streak updated for value {value_id}")
                except Exception as streak_error:
                    logger.error(f"Error updating streak for value {value_id}: {streak_error}", exc_info=True)
                    # Continue even if streak update fails for one value
        
        # Convert to dictionary and encode MongoDB types
        activity_dict = new_activity.dict()
        activity_dict = MongoJSONEncoder.encode_mongo_data(activity_dict)
        
        logger.info(f"Activity created successfully: {activity_dict.get('id')}")
        return activity_dict
    except HTTPException:
        # Re-raise HTTP exceptions
        raise
    except Exception as e:
        logger.error(f"Error creating activity: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create activity: {str(e)}"
        )

@router.get("/", response_model=List[ActivityResponse])
async def get_activities(
    current_user: User = Depends(get_current_user),
    value_id: Optional[str] = None,
    start_date: Optional[datetime] = None,
    end_date: Optional[datetime] = None,
    limit: int = Query(1000, ge=1, le=5000),
    skip: int = Query(0, ge=0)
):
    """Get activities for the current user with optional filtering"""
    try:
        logger.info(f"Getting activities for user: {current_user.id}")
        
        activities = await ActivityService.get_activities(
            current_user,
            value_id=value_id,
            start_date=start_date,
            end_date=end_date,
            limit=limit,
            skip=skip
        )
        
        # Convert to dictionary and encode MongoDB types
        activities_list = []
        for activity in activities:
            activity_dict = activity.dict()
            activity_dict = MongoJSONEncoder.encode_mongo_data(activity_dict)
            activities_list.append(activity_dict)
        
        logger.info(f"Retrieved {len(activities)} activities")
        return activities_list
    except Exception as e:
        logger.error(f"Error getting activities: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get activities: {str(e)}"
        )

@router.get("/statistics")
async def get_activity_statistics(
    current_user: User = Depends(get_current_user),
    value_id: Optional[str] = None,
    start_date: Optional[datetime] = None,
    end_date: Optional[datetime] = None
):
    """Get activity statistics for the current user"""
    try:
        logger.info(f"Getting activity statistics for user: {current_user.id}")
        
        statistics = await ActivityService.get_activity_statistics(
            current_user,
            value_id=value_id,
            start_date=start_date,
            end_date=end_date
        )
        
        logger.info(f"Statistics retrieved successfully")
        return statistics
    except Exception as e:
        logger.error(f"Error getting activity statistics: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get activity statistics: {str(e)}"
        )

@router.get("/summary")
async def get_value_activity_summary(
    current_user: User = Depends(get_current_user),
    start_date: Optional[datetime] = None,
    end_date: Optional[datetime] = None
):
    """Get summary of activities by value"""
    try:
        logger.info(f"Getting activity summary for user: {current_user.id}")
        
        summary = await ActivityService.get_value_activity_summary(
            current_user, 
            start_date=start_date, 
            end_date=end_date
        )
        
        # Convert to dictionary and encode MongoDB types
        summary = MongoJSONEncoder.encode_mongo_data(summary)
        
        logger.info(f"Summary retrieved successfully")
        return summary
    except Exception as e:
        logger.error(f"Error getting activity summary: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get activity summary: {str(e)}"
        )

@router.get("/{activity_id}", response_model=ActivityResponse)
async def get_activity(
    activity_id: str,
    current_user: User = Depends(get_current_user)
):
    """Get a specific activity by ID"""
    try:
        logger.info(f"Getting activity {activity_id} for user: {current_user.id}")
        
        activity = await ActivityService.get_activity(current_user, activity_id)
        
        # Convert to dictionary and encode MongoDB types
        activity_dict = activity.dict()
        activity_dict = MongoJSONEncoder.encode_mongo_data(activity_dict)
        
        return activity_dict
    except HTTPException:
        # Re-raise HTTP exceptions
        raise
    except Exception as e:
        logger.error(f"Error getting activity: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get activity: {str(e)}"
        )

# Fix for PATCH endpoint in app/api/endpoints/activities.py

@router.patch("/{activity_id}")
async def update_activity(
    activity_id: str,
    activity_update: ActivityUpdate,
    current_user: User = Depends(get_current_user)
):
    """Update a specific activity"""
    try:
        logger.info(f"Updating activity {activity_id} for user: {current_user.id}")
        
        # Log the value_update content for debugging
        update_data = activity_update.model_dump(exclude_unset=True)
        logger.info(f"Update data received: {update_data}")
        
        # First, try to convert the string ID to ObjectId
        try:
            object_id = ObjectId(activity_id)
        except:
            logger.error(f"Invalid ObjectId format: {activity_id}")
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid activity ID format"
            )
            
        # Verify the activity exists and belongs to this user
        activity = await Activity.find_one(
            Activity.id == object_id,
            Activity.user_id == str(current_user.id)
        )
        
        if not activity:
            logger.warning(f"Activity not found: {activity_id} for user {current_user.id}")
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Activity not found"
            )
        
        # Update fields from request data
        for field, value in update_data.items():
            setattr(activity, field, value)
        
        # Save the updated activity
        await activity.save()
        logger.info(f"Activity updated successfully: {activity_id}")
        
        # Convert the activity to a dictionary and serialize MongoDB types
        activity_dict = activity.dict()
        activity_dict = MongoJSONEncoder.encode_mongo_data(activity_dict)
        
        return activity_dict
    except HTTPException as he:
        # Explicitly log and re-raise HTTP exceptions
        logger.error(f"HTTP exception in update_activity: {he.detail} (status: {he.status_code})")
        raise
    except Exception as e:
        logger.error(f"Error updating activity: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error updating activity: {str(e)}"
        )

@router.delete("/{activity_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_activity(
    activity_id: str,
    current_user: User = Depends(get_current_user)
):
    try:
        # Convert string ID to ObjectId
        object_id = ObjectId(activity_id)
    except:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid activity ID format"
        )

    logger.info(f"Deleting activity {activity_id} for user: {current_user.id}")
    
    # Find the activity with proper ObjectId conversion
    activity = await Activity.find_one(
        Activity.id == object_id,
        Activity.user_id == str(current_user.id)
    )
    
    if not activity:
        logger.warning(f"Activity {activity_id} not found for user {current_user.id}")
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Activity not found"
        )
    
    try:
        await activity.delete()
        logger.info(f"Activity {activity_id} deleted successfully")
        return None
    except Exception as e:
        logger.error(f"Error deleting activity: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete activity: {str(e)}"
        )