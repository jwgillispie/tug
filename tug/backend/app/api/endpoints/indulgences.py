# app/api/endpoints/indulgences.py
from fastapi import APIRouter, Depends, HTTPException, status
from typing import List, Optional
from datetime import datetime
import logging
from bson import ObjectId

from ...models.user import User
from ...schemas.indulgence import IndulgenceCreate, IndulgenceUpdate
from ...services.vice_service import ViceService
from ...core.auth import get_current_user
from ...utils.json_utils import MongoJSONEncoder

router = APIRouter()
logger = logging.getLogger(__name__)

@router.post("/", status_code=status.HTTP_201_CREATED)
async def create_indulgence(
    indulgence: IndulgenceCreate,
    current_user: User = Depends(get_current_user)
):
    """Record a new indulgence for multiple vices"""
    try:
        logger.info(f"Recording indulgence for vices {indulgence.vice_ids}, user: {current_user.id}")
        
        # Validate that all vice_ids belong to the current user
        for vice_id in indulgence.vice_ids:
            if not await ViceService.vice_belongs_to_user(current_user, vice_id):
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail=f"Vice {vice_id} does not belong to current user"
                )
        
        new_indulgence = await ViceService.record_multi_vice_indulgence(current_user, indulgence)
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

@router.get("/")
async def get_all_indulgences(
    current_user: User = Depends(get_current_user),
    limit: Optional[int] = None,
    vice_id: Optional[str] = None
):
    """Get all indulgences for the current user, optionally filtered by vice"""
    try:
        logger.info(f"Getting indulgences for user: {current_user.id}")
        
        if vice_id:
            # Get indulgences for a specific vice
            indulgences = await ViceService.get_indulgences(current_user, vice_id, limit)
            logger.info(f"Retrieved {len(indulgences)} indulgences for vice {vice_id}")
        else:
            # Get all indulgences for the user
            indulgences = await ViceService.get_all_user_indulgences(current_user, limit)
            logger.info(f"Retrieved {len(indulgences)} indulgences for user")
        
        # Convert the indulgences to dictionaries and serialize MongoDB types
        indulgences_list = []
        for indulgence in indulgences:
            indulgence_dict = indulgence.dict()
            indulgence_dict = MongoJSONEncoder.encode_mongo_data(indulgence_dict)
            indulgences_list.append(indulgence_dict)
        
        return {"indulgences": indulgences_list}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting indulgences: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error retrieving indulgences: {str(e)}"
        )

@router.get("/{indulgence_id}")
async def get_indulgence(
    indulgence_id: str,
    current_user: User = Depends(get_current_user)
):
    """Get a specific indulgence by ID"""
    try:
        logger.info(f"Getting indulgence {indulgence_id} for user: {current_user.id}")
        
        indulgence = await ViceService.get_indulgence_by_id(current_user, indulgence_id)
        
        # Convert the indulgence to a dictionary and serialize MongoDB types
        indulgence_dict = indulgence.dict()
        indulgence_dict = MongoJSONEncoder.encode_mongo_data(indulgence_dict)
        
        return {"indulgence": indulgence_dict}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting indulgence: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error retrieving indulgence: {str(e)}"
        )

@router.put("/{indulgence_id}")
async def update_indulgence(
    indulgence_id: str,
    indulgence_update: IndulgenceUpdate,
    current_user: User = Depends(get_current_user)
):
    """Update an existing indulgence"""
    try:
        logger.info(f"Updating indulgence {indulgence_id} for user: {current_user.id}")
        
        updated_indulgence = await ViceService.update_indulgence(
            current_user, indulgence_id, indulgence_update
        )
        logger.info(f"Indulgence updated successfully: {updated_indulgence.id}")
        
        # Convert the indulgence to a dictionary and serialize MongoDB types
        indulgence_dict = updated_indulgence.dict()
        indulgence_dict = MongoJSONEncoder.encode_mongo_data(indulgence_dict)
        
        return {"indulgence": indulgence_dict}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating indulgence: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error updating indulgence: {str(e)}"
        )

@router.delete("/{indulgence_id}")
async def delete_indulgence(
    indulgence_id: str,
    current_user: User = Depends(get_current_user)
):
    """Delete an indulgence"""
    try:
        logger.info(f"Deleting indulgence {indulgence_id} for user: {current_user.id}")
        
        await ViceService.delete_indulgence(current_user, indulgence_id)
        logger.info(f"Indulgence deleted successfully: {indulgence_id}")
        
        return {"message": "Indulgence deleted successfully"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting indulgence: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error deleting indulgence: {str(e)}"
        )