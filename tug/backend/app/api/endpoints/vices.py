# app/api/endpoints/vices.py
from fastapi import APIRouter, Depends, HTTPException, status
from typing import List, Optional
from datetime import datetime
import logging
from bson import ObjectId

from ...models.user import User
from ...schemas.vice import ViceCreate, ViceUpdate, StreakUpdate, CleanDay
from ...schemas.indulgence import IndulgenceCreate
from ...services.vice_service import ViceService
from ...core.auth import get_current_user
from ...utils.json_utils import MongoJSONEncoder

router = APIRouter()
logger = logging.getLogger(__name__)

@router.post("/", status_code=status.HTTP_201_CREATED)
async def create_vice(
    vice: ViceCreate,
    current_user: User = Depends(get_current_user)
):
    """Create a new vice for the current user"""
    try:
        logger.info(f"Creating new vice for user: {current_user.id}")
        new_vice = await ViceService.create_vice(current_user, vice)
        logger.info(f"Vice created successfully: {new_vice.id}")
        
        # Convert the vice to a dictionary and serialize MongoDB types
        vice_dict = new_vice.dict()
        vice_dict = MongoJSONEncoder.encode_mongo_data(vice_dict)
        
        return {"vice": vice_dict}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error creating vice: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error creating vice: {str(e)}"
        )

@router.get("/")
async def get_vices(
    current_user: User = Depends(get_current_user),
    include_inactive: bool = False
):
    """Get all vices for the current user"""
    try:
        logger.info(f"Getting vices for user: {current_user.id}")
        
        vices = await ViceService.get_vices(current_user, include_inactive)
        
        # Convert the vices to dictionaries and serialize MongoDB types
        vices_list = []
        for vice in vices:
            vice_dict = vice.dict()
            vice_dict = MongoJSONEncoder.encode_mongo_data(vice_dict)
            vices_list.append(vice_dict)
        
        logger.info(f"Retrieved {len(vices)} vices")
        return {"vices": vices_list}
    except Exception as e:
        logger.error(f"Error getting vices: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error retrieving vices: {str(e)}"
        )

@router.get("/stats")
async def get_vice_stats(
    current_user: User = Depends(get_current_user),
    vice_id: Optional[str] = None
):
    """Get statistics for vices"""
    try:
        logger.info(f"Getting vice statistics for user: {current_user.id}")
        
        stats = await ViceService.get_vice_stats(current_user, vice_id)
        return stats
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting vice statistics: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error retrieving vice statistics: {str(e)}"
        )

@router.get("/{vice_id}")
async def get_vice(
    vice_id: str,
    current_user: User = Depends(get_current_user)
):
    """Get a specific vice by ID"""
    try:
        logger.info(f"Getting vice {vice_id} for user: {current_user.id}")
        vice = await ViceService.get_vice(current_user, vice_id)
        
        # Convert the vice to a dictionary and serialize MongoDB types
        vice_dict = vice.dict()
        vice_dict = MongoJSONEncoder.encode_mongo_data(vice_dict)
        
        return {"vice": vice_dict}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting vice: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error retrieving vice: {str(e)}"
        )

@router.put("/{vice_id}")
async def update_vice(
    vice_id: str,
    vice_update: ViceUpdate,
    current_user: User = Depends(get_current_user)
):
    """Update a specific vice"""
    try:
        logger.info(f"Updating vice {vice_id} for user: {current_user.id}")
        
        # Log the vice_update content for debugging
        update_data = vice_update.model_dump(exclude_unset=True)
        logger.info(f"Update data received: {update_data}")
        
        updated_vice = await ViceService.update_vice(current_user, vice_id, vice_update)
        
        logger.info(f"Vice updated successfully: {vice_id}")
        
        # Convert the vice to a dictionary and serialize MongoDB types
        vice_dict = updated_vice.dict()
        vice_dict = MongoJSONEncoder.encode_mongo_data(vice_dict)
        
        return {"vice": vice_dict}
    except HTTPException as he:
        # Explicitly log and re-raise HTTP exceptions
        logger.error(f"HTTP exception in update_vice: {he.detail} (status: {he.status_code})")
        raise
    except Exception as e:
        logger.error(f"Error updating vice: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error updating vice: {str(e)}"
        )

@router.delete("/{vice_id}", status_code=status.HTTP_200_OK)
async def delete_vice(
    vice_id: str,
    current_user: User = Depends(get_current_user)
):
    """Delete a vice"""
    logger.info(f"Deleting vice {vice_id} for user: {current_user.id}")
    
    try:
        await ViceService.delete_vice(current_user, vice_id)
        
        logger.info(f"Vice {vice_id} deleted successfully")
        return {"message": "Vice deleted successfully"}
    except HTTPException as e:
        logger.error(f"Error in delete_vice: {e}", exc_info=True)
        raise
    except Exception as e:
        logger.error(f"Error deleting vice: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete vice: {str(e)}"
        )

# Indulgence endpoints

@router.post("/{vice_id}/indulge", status_code=status.HTTP_201_CREATED)
async def record_indulgence(
    vice_id: str,
    indulgence: IndulgenceCreate,
    current_user: User = Depends(get_current_user)
):
    """Record an indulgence for a specific vice"""
    try:
        logger.info(f"Recording indulgence for vice {vice_id}, user: {current_user.id}")
        
        # Ensure the indulgence vice_id matches the URL parameter
        indulgence.vice_id = vice_id
        
        new_indulgence = await ViceService.record_indulgence(current_user, indulgence)
        logger.info(f"Indulgence recorded successfully: {new_indulgence.id}")
        
        # Convert the indulgence to a dictionary and serialize MongoDB types
        indulgence_dict = new_indulgence.dict()
        indulgence_dict = MongoJSONEncoder.encode_mongo_data(indulgence_dict)
        
        return {"indulgence": indulgence_dict}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error recording indulgence: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error recording indulgence: {str(e)}"
        )

@router.get("/{vice_id}/indulgences")
async def get_indulgences(
    vice_id: str,
    current_user: User = Depends(get_current_user),
    limit: Optional[int] = None
):
    """Get indulgences for a specific vice"""
    try:
        logger.info(f"Getting indulgences for vice {vice_id}, user: {current_user.id}")
        
        indulgences = await ViceService.get_indulgences(current_user, vice_id, limit)
        
        # Convert the indulgences to dictionaries and serialize MongoDB types
        indulgences_list = []
        for indulgence in indulgences:
            indulgence_dict = indulgence.dict()
            indulgence_dict = MongoJSONEncoder.encode_mongo_data(indulgence_dict)
            indulgences_list.append(indulgence_dict)
        
        logger.info(f"Retrieved {len(indulgences)} indulgences")
        return {"indulgences": indulgences_list}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting indulgences: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error retrieving indulgences: {str(e)}"
        )

# Streak management endpoints

@router.patch("/{vice_id}/streak")
async def update_vice_streak(
    vice_id: str,
    streak_update: StreakUpdate,
    current_user: User = Depends(get_current_user)
):
    """Update the current streak for a vice"""
    try:
        logger.info(f"Updating streak for vice {vice_id} to {streak_update.current_streak}")
        
        updated_vice = await ViceService.update_vice_streak(
            current_user, 
            vice_id, 
            streak_update.current_streak
        )
        
        # Convert the vice to a dictionary and serialize MongoDB types
        vice_dict = updated_vice.dict()
        vice_dict = MongoJSONEncoder.encode_mongo_data(vice_dict)
        
        return {"vice": vice_dict}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating vice streak: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error updating vice streak: {str(e)}"
        )

@router.post("/{vice_id}/clean-day", status_code=status.HTTP_201_CREATED)
async def mark_clean_day(
    vice_id: str,
    clean_day: CleanDay,
    current_user: User = Depends(get_current_user)
):
    """Mark a clean day for a vice"""
    try:
        logger.info(f"Marking clean day for vice {vice_id} on {clean_day.date}")
        
        updated_vice = await ViceService.mark_clean_day(
            current_user, 
            vice_id, 
            clean_day.date
        )
        
        # Convert the vice to a dictionary and serialize MongoDB types
        vice_dict = updated_vice.dict()
        vice_dict = MongoJSONEncoder.encode_mongo_data(vice_dict)
        
        return {"vice": vice_dict}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error marking clean day: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error marking clean day: {str(e)}"
        )