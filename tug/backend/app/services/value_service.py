# app/services/value_service.py
from datetime import datetime
from typing import List, Optional
from bson import ObjectId
from fastapi import HTTPException, status
import logging

from ..models.user import User
from ..models.value import Value
from ..schemas.value import ValueCreate, ValueUpdate, ValueResponse

logger = logging.getLogger(__name__)

class ValueService:
    """Service for handling value-related operations"""

    @staticmethod
    async def create_value(user: User, value_data: ValueCreate) -> Value:
        """Create a new value for a user"""
        # Check if user has less than 5 active values
        active_values_count = await Value.find(
            Value.user_id == str(user.id),
            Value.active == True
        ).count()
        
        if active_values_count >= 5:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Maximum 5 active values allowed"
            )
        
        # Create new value
        new_value = Value(
            user_id=str(user.id),
            name=value_data.name,
            importance=value_data.importance,
            description=value_data.description,
            color=value_data.color
        )
        
        await new_value.insert()
        return new_value

    @staticmethod
    async def get_values(user: User, include_inactive: bool = False) -> List[Value]:
        """Get all values for a user"""
        query = {Value.user_id: str(user.id)}
        
        if not include_inactive:
            query[Value.active] = True
        
        values = await Value.find(
            query
        ).sort(-Value.importance).to_list()
        
        return values

    @staticmethod
    async def get_value(user: User, value_id: str) -> Value:
        """Get a specific value by ID"""
        try:
            logger.info(f"Getting value with ID: {value_id}")
            # Convert string ID to ObjectId
            object_id = ObjectId(value_id)
            logger.info(f"Converted to ObjectId: {object_id}")
            
            value = await Value.find_one(
                Value.id == object_id,
                Value.user_id == str(user.id)
            )
            
            if not value:
                logger.warning(f"Value not found: {value_id} for user {user.id}")
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Value not found"
                )
            return value
        except Exception as e:
            # Log the error
            logger.error(f"Error in get_value: {e}")
            # Re-raise as HTTP exception
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Value not found: {str(e)}"
            )

    @staticmethod
    async def update_value(user: User, value_id: str, value_data: ValueUpdate) -> Value:
        """Update a specific value"""
        try:
            logger.info(f"Updating value with ID: {value_id}")
            # Convert string ID to ObjectId
            object_id = ObjectId(value_id)
            logger.info(f"Converted to ObjectId: {object_id}")
            
            # Explicitly log the query we're about to make
            logger.info(f"Looking for value with id={object_id} and user_id={str(user.id)}")
            
            value = await Value.find_one(
                Value.id == object_id,
                Value.user_id == str(user.id)
            )
            
            if not value:
                logger.warning(f"Value not found: {value_id} for user {user.id}")
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Value not found"
                )
            
            # Update value with provided data
            update_data = value_data.model_dump(exclude_unset=True)
            logger.info(f"Update data: {update_data}")
            
            if update_data:
                for field, field_value in update_data.items():
                    setattr(value, field, field_value)
                
                value.updated_at = datetime.utcnow()
                await value.save()
                logger.info(f"Value updated successfully: {value_id}")
            
            return value
        except Exception as e:
            # Log the error
            logger.error(f"Error in update_value: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Failed to update value: {str(e)}"
            )
    
    @staticmethod
    async def check_value_exists(user: User, value_id: str) -> bool:
        """Check if a value exists and belongs to the user"""
        try:
            # Convert string ID to ObjectId
            object_id = ObjectId(value_id)
            
            value = await Value.find_one(
                Value.id == object_id,
                Value.user_id == str(user.id)
            )
            return value is not None
        except:
            return False
    
    @staticmethod
    async def get_value_counts_by_user(user: User) -> dict:
        """Get count of active and total values for a user"""
        total_count = await Value.find(
            Value.user_id == str(user.id)
        ).count()
        
        active_count = await Value.find(
            Value.user_id == str(user.id),
            Value.active == True
        ).count()
        
        return {
            "total": total_count,
            "active": active_count
        }