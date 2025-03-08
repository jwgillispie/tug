# app/services/value_service.py
from datetime import datetime
from typing import List, Optional
from fastapi import HTTPException, status

from ..models.user import User
from ..models.value import Value
from ..schemas.value import ValueCreate, ValueUpdate, ValueResponse


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
    async def get_value(user: User, value_id: str) -> Optional[Value]:
        """Get a specific value by ID"""
        value = await Value.find_one(
            Value.id == value_id,
            Value.user_id == str(user.id)
        )
        
        if not value:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Value not found"
            )
        
        return value

    @staticmethod
    async def update_value(user: User, value_id: str, value_data: ValueUpdate) -> Value:
        """Update a specific value"""
        value = await Value.find_one(
            Value.id == value_id,
            Value.user_id == str(user.id)
        )
        
        if not value:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Value not found"
            )
        
        # Update value with provided data
        update_data = value_data.model_dump(exclude_unset=True)
        
        if update_data:
            for field, field_value in update_data.items():
                setattr(value, field, field_value)
            
            value.updated_at = datetime.utcnow()
            await value.save()
        
        return value

    @staticmethod
    async def delete_value(user: User, value_id: str) -> None:
        """Delete (deactivate) a value"""
        try:
            # Try to find the value first
            value = await Value.find_one(
                Value.id == value_id,
                Value.user_id == str(user.id)
            )
            
            if not value:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=f"Value not found"
                )
            
            # Soft delete (deactivate)
            value.active = False
            value.updated_at = datetime.utcnow()
            await value.save()
            
            return None
        except Exception as e:
            # Log the error for debugging
            print(f"Error in delete_value: {e}")
            # Re-raise to be handled by the caller
            raise
    
    @staticmethod
    async def check_value_exists(user: User, value_id: str) -> bool:
        """Check if a value exists and belongs to the user"""
        value = await Value.find_one(
            Value.id == value_id,
            Value.user_id == str(user.id)
        )
        return value is not None
    
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