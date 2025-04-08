# app/api/endpoints/activities.py
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
    limit: int = Query(50, ge=1, le=100),
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

@router.get("/statistics", response_model=ActivityStatistics)
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

@router.patch("/{activity_id}", response_model=ActivityResponse)
async def update_activity(
    activity_id: str,
    activity_update: ActivityUpdate,
    current_user: User = Depends(get_current_user)
):
    """Update a specific activity"""
    try:
        logger.info(f"Updating activity {activity_id} for user: {current_user.id}")
        
        updated_activity = await ActivityService.update_activity(
            current_user,
            activity_id,
            activity_update
        )
        
        # Convert to dictionary and encode MongoDB types
        activity_dict = updated_activity.dict()
        activity_dict = MongoJSONEncoder.encode_mongo_data(activity_dict)
        
        logger.info(f"Activity updated successfully")
        return activity_dict
    except HTTPException:
        # Re-raise HTTP exceptions
        raise
    except Exception as e:
        logger.error(f"Error updating activity: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update activity: {str(e)}"
        )

@router.delete("/{activity_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_activity(
    activity_id: str,
    current_user: User = Depends(get_current_user)
):
    """Delete an activity"""
    try:
        logger.info(f"Deleting activity {activity_id} for user: {current_user.id}")
        
        await ActivityService.delete_activity(current_user, activity_id)
        
        logger.info(f"Activity deleted successfully")
        return None
    except HTTPException:
        # Re-raise HTTP exceptions
        raise
    except Exception as e:
        logger.error(f"Error deleting activity: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete activity: {str(e)}"
        )