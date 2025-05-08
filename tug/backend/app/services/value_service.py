# app/services/value_service.py
from datetime import datetime, date, timedelta
from typing import List, Optional
from bson import ObjectId
from fastapi import HTTPException, status
import logging

from ..models.user import User
from ..models.value import Value
from ..models.activity import Activity
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
    
    @staticmethod
    async def update_streak(value_id: str, activity_date: datetime) -> Value:
        """Update streak information for a value based on a new activity date"""
        try:
            # Find the value by ID
            object_id = ObjectId(value_id)
            value = await Value.find_one(Value.id == object_id)
            
            if not value:
                logger.warning(f"Value not found for streak update: {value_id}")
                return None
                
            today = activity_date.date()
            
            # Initialize streak_dates if it doesn't exist
            if not hasattr(value, 'streak_dates') or value.streak_dates is None:
                value.streak_dates = []
                
            # If the date is already in streak_dates, no need to update
            if today in value.streak_dates:
                return value
                
            # Get the last activity date
            last_date = value.last_activity_date
            
            # Add today to streak dates
            value.streak_dates.append(today)
            value.last_activity_date = today
            
            # Check if we have a continuous streak
            if last_date and (today - last_date) <= timedelta(days=1):
                # Increment current streak because it's consecutive
                value.current_streak += 1
            else:
                # Reset streak to 1 if it's not consecutive
                value.current_streak = 1
                
            # Update longest streak if needed
            if value.current_streak > value.longest_streak:
                value.longest_streak = value.current_streak
                
            # Update the value in the database
            await value.save()
            logger.info(f"Updated streak for value {value_id}: current={value.current_streak}, longest={value.longest_streak}")
            return value
            
        except Exception as e:
            logger.error(f"Error updating streak: {e}")
            return None
            
    @staticmethod
    async def check_and_reset_streaks(user: User) -> None:
        """Check all values for the user and reset streaks if needed"""
        try:
            today = date.today()
            values = await Value.find(
                Value.user_id == str(user.id),
                Value.active == True
            ).to_list()
            
            for value in values:
                if value.last_activity_date:
                    days_since_last = (today - value.last_activity_date).days
                    
                    # If it's been more than 1 day, reset the streak
                    if days_since_last > 1:
                        value.current_streak = 0
                        await value.save()
                        logger.info(f"Reset streak for value {value.id} - {days_since_last} days since last activity")
                        
        except Exception as e:
            logger.error(f"Error checking and resetting streaks: {e}")
            
    @staticmethod
    async def get_streak_stats(user: User, value_id: str = None) -> dict:
        """Get streak statistics for a specific value or all values"""
        try:
            if value_id:
                # Get stats for a specific value
                object_id = ObjectId(value_id)
                value = await Value.find_one(
                    Value.id == object_id,
                    Value.user_id == str(user.id)
                )
                
                if not value:
                    return {
                        "current_streak": 0,
                        "longest_streak": 0,
                        "streak_active": False
                    }
                    
                today = date.today()
                streak_active = value.last_activity_date and (today - value.last_activity_date).days <= 1
                
                return {
                    "current_streak": value.current_streak,
                    "longest_streak": value.longest_streak,
                    "streak_active": streak_active
                }
            else:
                # Get stats for all values
                values = await Value.find(
                    Value.user_id == str(user.id),
                    Value.active == True
                ).to_list()
                
                stats = {}
                for value in values:
                    today = date.today()
                    streak_active = value.last_activity_date and (today - value.last_activity_date).days <= 1
                    
                    stats[str(value.id)] = {
                        "name": value.name,
                        "current_streak": value.current_streak,
                        "longest_streak": value.longest_streak,
                        "streak_active": streak_active
                    }
                
                return stats
                
        except Exception as e:
            logger.error(f"Error getting streak stats: {e}")
            return {}