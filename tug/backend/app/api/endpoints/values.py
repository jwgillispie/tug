# app/api/endpoints/values.py
from fastapi import APIRouter, Depends, HTTPException, status
from typing import List, Dict, Any
from datetime import datetime
import logging
from bson import ObjectId

from ...models.user import User
from ...schemas.value import ValueCreate, ValueUpdate
from ...services.value_service import ValueService
from ...core.auth import get_current_user

router = APIRouter()
logger = logging.getLogger(__name__)

# Helper function to convert MongoDB data to JSON-serializable format
def serialize_mongo_doc(obj: Any) -> Any:
    if isinstance(obj, ObjectId):
        return str(obj)
    elif isinstance(obj, datetime):
        return obj.isoformat()
    elif isinstance(obj, dict):
        return {k: serialize_mongo_doc(v) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [serialize_mongo_doc(item) for item in obj]
    return obj

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
        value_dict = serialize_mongo_doc(value_dict)
        
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
        values = await ValueService.get_values(current_user, include_inactive)
        
        # Convert the values to dictionaries and serialize MongoDB types
        values_list = []
        for value in values:
            value_dict = value.dict()
            value_dict = serialize_mongo_doc(value_dict)
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
        value_dict = serialize_mongo_doc(value_dict)
        
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
        updated_value = await ValueService.update_value(current_user, value_id, value_update)
        logger.info(f"Value updated successfully: {value_id}")
        
        # Convert the value to a dictionary and serialize MongoDB types
        value_dict = updated_value.dict()
        value_dict = serialize_mongo_doc(value_dict)
        
        return value_dict
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating value: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error updating value: {str(e)}"
        )

@router.delete("/{value_id}")
async def delete_value(
    value_id: str,
    current_user: User = Depends(get_current_user)
):
    """Delete (deactivate) a value"""
    try:
        logger.info(f"Deleting value {value_id} for user: {current_user.id}")
        
        # First check if the value exists
        try:
            value = await ValueService.get_value(current_user, value_id)
            if not value:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=f"Value with ID {value_id} not found"
                )
        except Exception as e:
            logger.error(f"Error finding value to delete: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Value with ID {value_id} not found"
            )
        
        # Now delete it
        await ValueService.delete_value(current_user, value_id)
        logger.info(f"Value deleted successfully: {value_id}")
        
        # Return success response
        return {"status": "success", "message": f"Value {value_id} deleted successfully"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting value: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error deleting value: {str(e)}"
        )
        
        
@router.get("/stats/count")
async def get_value_counts(
    current_user: User = Depends(get_current_user)
):
    """Get counts of values for the current user"""
    try:
        counts = await ValueService.get_value_counts_by_user(current_user)
        return counts
    except Exception as e:
        logger.error(f"Error getting value counts: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error getting value counts: {str(e)}"
        )