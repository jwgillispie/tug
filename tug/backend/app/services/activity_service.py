# app/services/activity_service.py
from datetime import datetime, timedelta
from bson import ObjectId
from typing import List, Optional, Dict, Any
from fastapi import HTTPException, status
import logging 

from ..models.user import User
from ..models.value import Value
from ..models.activity import Activity
from ..schemas.activity import ActivityCreate, ActivityUpdate, ActivityStatistics


logger = logging.getLogger(__name__)

class ActivityService:
    """Service for handling activity-related operations"""

    @staticmethod
    async def create_activity(user: User, activity_data: ActivityCreate) -> Activity:
        """Create a new activity for a user"""
        # Check if value exists and belongs to user
        logger.info(f"Attempting to find value with ID: {activity_data.value_id} for user: {user.id}")

        value = await Value.find_one(
            Value.id == ObjectId(activity_data.value_id) if not isinstance(activity_data.value_id, ObjectId) else activity_data.value_id,
            Value.user_id == str(user.id)
        )
        
        if not value:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Value not found"
            )
        
        # Check if date is not in future
        if activity_data.date > datetime.utcnow():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Cannot log future activities"
            )
        
        # Create new activity
        new_activity = Activity(
            user_id=str(user.id),
            value_id=activity_data.value_id,
            name=activity_data.name,
            duration=activity_data.duration,
            date=activity_data.date,
            notes=activity_data.notes
        )
        
        await new_activity.insert()
        return new_activity

    @staticmethod
    async def get_activities(
        user: User,
        value_id: Optional[str] = None,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
        limit: int = 50,
        skip: int = 0
    ) -> List[Activity]:
        """Get activities for a user with optional filtering"""
        # Build query
        query = {Activity.user_id: str(user.id)}
        
        if value_id:
            query[Activity.value_id] = value_id
        
        if start_date:
            query[Activity.date] = {"$gte": start_date}
        
        if end_date:
            if Activity.date in query:
                query[Activity.date]["$lte"] = end_date
            else:
                query[Activity.date] = {"$lte": end_date}
        
        # Get activities
        activities = await Activity.find(
            query
        ).sort(-Activity.date).skip(skip).limit(limit).to_list()
        
        return activities

    @staticmethod
    async def get_activity(user: User, activity_id: str) -> Activity:
        """Get a specific activity by ID"""
        activity = await Activity.find_one(
            Activity.id == activity_id,
            Activity.user_id == str(user.id)
        )
        
        if not activity:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Activity not found"
            )
        
        return activity

    @staticmethod
    async def update_activity(user: User, activity_id: str, activity_data: ActivityUpdate) -> Activity:
        """Update a specific activity"""
        # Find activity
        activity = await Activity.find_one(
            Activity.id == activity_id,
            Activity.user_id == str(user.id)
        )
        
        if not activity:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Activity not found"
            )
        
        # Check if value_id is being updated and if it exists
        update_data = activity_data.model_dump(exclude_unset=True)
        if "value_id" in update_data:
            value = await Value.find_one(
                Value.id == ObjectId(activity_data.value_id) if not isinstance(activity_data.value_id, ObjectId) else activity_data.value_id,
                Value.user_id == str(user.id)
            )
                        
            if not value:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Value not found"
                )
        
        # Check if date is not in future if it's being updated
        if "date" in update_data and update_data["date"] > datetime.utcnow():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Cannot log future activities"
            )
        
        # Update activity
        for field, field_value in update_data.items():
            setattr(activity, field, field_value)
        
        await activity.save()
        return activity

    @staticmethod
    async def delete_activity(user: User, activity_id: str) -> None:
        """Delete an activity"""
        # Find activity
        activity = await Activity.find_one(
            Activity.id == activity_id,
            Activity.user_id == str(user.id)
        )
        
        if not activity:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Activity not found"
            )
        
        # Delete activity
        await activity.delete()
        return None

    @staticmethod
    async def get_activity_statistics(
        user: User,
        value_id: Optional[str] = None,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None
    ) -> ActivityStatistics:
        """Get activity statistics"""
        # If no dates provided, use last 30 days
        if start_date is None:
            start_date = datetime.utcnow() - timedelta(days=30)
        
        # If no end date, use current date
        if end_date is None:
            end_date = datetime.utcnow()
        
        # Build query
        query = {
            Activity.user_id: str(user.id),
            Activity.date: {"$gte": start_date, "$lte": end_date}
        }
        
        # Add value_id to query if provided
        if value_id:
            query[Activity.value_id] = value_id
        
        # Count activities
        total_activities = await Activity.find(query).count()
        
        # Get total duration
        total_duration = await Activity.find(query).sum("duration") or 0
        
        # Calculate statistics
        return ActivityStatistics(
            total_activities=total_activities,
            total_duration_minutes=total_duration,
            total_duration_hours=round(total_duration / 60, 2) if total_duration else 0,
            average_duration_minutes=round(total_duration / total_activities, 2) if total_activities > 0 else 0
        )

    @staticmethod
    async def get_value_activity_summary(
        user: User, 
        start_date: Optional[datetime] = None, 
        end_date: Optional[datetime] = None
    ) -> Dict[str, Any]:
        """Get summary of activities by value"""
        # If no dates provided, use last 30 days
        if start_date is None:
            start_date = datetime.utcnow() - timedelta(days=30)
        
        # If no end date, use current date
        if end_date is None:
            end_date = datetime.utcnow()
        
        # Get all user values
        values = await Value.find(
            Value.user_id == str(user.id)
        ).to_list()
        
        result = []
        
        for value in values:
            # Query for activities for this value within the date range
            activities = await Activity.find(
                Activity.user_id == str(user.id),
                Activity.value_id == str(value.id),
                Activity.date >= start_date,
                Activity.date <= end_date
            ).to_list()
            
            # Calculate total time
            total_minutes = sum(activity.duration for activity in activities)
            
            # Calculate period in days
            period_days = (end_date - start_date).days + 1
            
            # Calculate daily average (avoid division by zero)
            daily_average = round(total_minutes / period_days, 2) if period_days > 0 else 0
            
            # Add to result
            result.append({
                "value_id": str(value.id),
                "value_name": value.name,
                "value_color": value.color,
                "value_importance": value.importance,
                "total_minutes": total_minutes,
                "activity_count": len(activities),
                "daily_average": daily_average,
                # Add community average calculation if needed
                "community_avg": 60  # Placeholder - replace with actual community average calculation
            })
        
        return {
            "period_start": start_date,
            "period_end": end_date,
            "period_days": (end_date - start_date).days + 1,
            "values": result
        }