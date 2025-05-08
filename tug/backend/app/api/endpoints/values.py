# app/api/endpoints/values.py
from fastapi import APIRouter, Depends, HTTPException, status
from typing import List, Dict, Any
from datetime import datetime
import logging
from bson import ObjectId

from ...models.activity import Activity

from ...models.user import User
from ...schemas.value import ValueCreate, ValueUpdate
from ...services.value_service import ValueService
from ...core.auth import get_current_user
from ...utils.json_utils import MongoJSONEncoder

router = APIRouter()
logger = logging.getLogger(__name__)

@router.post("/", status_code=status.HTTP_201_CREATED)
async def create_value(
    value: ValueCreate,
    current_user: User = Depends(get_current_user)
):
    """Create a new value for the current user"""
    try:
        logger.info(f"Creating new value for user: {current_user.id}")
        new_value = await ValueService.create_value(current_user, value)
        logger.info(f"Value created successfully: {new_value.id}")
        
        # Convert the value to a dictionary and serialize MongoDB types
        value_dict = new_value.dict()
        value_dict = MongoJSONEncoder.encode_mongo_data(value_dict)
        
        return value_dict
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error creating value: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error creating value: {str(e)}"
        )

@router.get("/")
async def get_values(
    current_user: User = Depends(get_current_user),
    include_inactive: bool = False
):
    """Get all values for the current user"""
    try:
        logger.info(f"Getting values for user: {current_user.id}")
        
        # Check and reset streaks if needed
        await ValueService.check_and_reset_streaks(current_user)
        
        values = await ValueService.get_values(current_user, include_inactive)
        
        # Convert the values to dictionaries and serialize MongoDB types
        values_list = []
        for value in values:
            value_dict = value.dict()
            value_dict = MongoJSONEncoder.encode_mongo_data(value_dict)
            values_list.append(value_dict)
        
        logger.info(f"Retrieved {len(values)} values")
        return values_list
    except Exception as e:
        logger.error(f"Error getting values: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error retrieving values: {str(e)}"
        )

@router.get("/{value_id}")
async def get_value(
    value_id: str,
    current_user: User = Depends(get_current_user)
):
    """Get a specific value by ID"""
    try:
        logger.info(f"Getting value {value_id} for user: {current_user.id}")
        value = await ValueService.get_value(current_user, value_id)
        
        # Convert the value to a dictionary and serialize MongoDB types
        value_dict = value.dict()
        value_dict = MongoJSONEncoder.encode_mongo_data(value_dict)
        
        return value_dict
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting value: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error retrieving value: {str(e)}"
        )

@router.patch("/{value_id}")
async def update_value(
    value_id: str,
    value_update: ValueUpdate,
    current_user: User = Depends(get_current_user)
):
    """Update a specific value"""
    try:
        logger.info(f"Updating value {value_id} for user: {current_user.id}")
        
        # Log the value_update content for debugging
        update_data = value_update.model_dump(exclude_unset=True)
        logger.info(f"Update data received: {update_data}")
        
        updated_value = await ValueService.update_value(current_user, value_id, value_update)
        
        logger.info(f"Value updated successfully: {value_id}")
        
        # Convert the value to a dictionary and serialize MongoDB types
        value_dict = updated_value.dict()
        value_dict = MongoJSONEncoder.encode_mongo_data(value_dict)
        
        return value_dict
    except HTTPException as he:
        # Explicitly log and re-raise HTTP exceptions
        logger.error(f"HTTP exception in update_value: {he.detail} (status: {he.status_code})")
        raise
    except Exception as e:
        logger.error(f"Error updating value: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error updating value: {str(e)}"
        )

@router.get("/stats/streaks")
async def get_streaks(
    current_user: User = Depends(get_current_user),
    value_id: Optional[str] = None
):
    """Get streak information for values"""
    try:
        logger.info(f"Getting streak information for user: {current_user.id}")
        
        # Check and reset streaks if needed
        await ValueService.check_and_reset_streaks(current_user)
        
        streak_stats = await ValueService.get_streak_stats(current_user, value_id)
        return streak_stats
    except Exception as e:
        logger.error(f"Error getting streak information: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error retrieving streak information: {str(e)}"
        )

@router.delete("/{value_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_value(
    value_id: str,
    current_user: User = Depends(get_current_user)
):
    """Delete a value"""
    logger.info(f"Deleting value {value_id} for user: {current_user.id}")
    
    try:
        # First, convert the string ID to ObjectId for proper MongoDB querying
        object_id = ObjectId(value_id)
        
        # Verify the value exists and belongs to this user
        value = await ValueService.get_value(current_user, value_id)
        if not value:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Value not found"
            )
        
        # Delete all activities associated with this value
        await Activity.find({
            "value_id": value_id,
            "user_id": str(current_user.id)
        }).delete()
        
        # Delete the value itself
        await value.delete()
        
        logger.info(f"Value {value_id} deleted successfully")
        return None
    except HTTPException as e:
        logger.error(f"Error in delete_value: {e}", exc_info=True)
        raise
    except Exception as e:
        logger.error(f"Error deleting value: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete value: {str(e)}"
        )