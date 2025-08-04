# app/services/activity_service.py
from datetime import datetime, timedelta
from bson import ObjectId
from typing import List, Optional, Dict, Any
from fastapi import HTTPException, status
import logging 

from ..models.user import User
from ..models.value import Value
from ..models.activity import Activity
from ..models.social_post import SocialPost, PostType
from ..schemas.activity import ActivityCreate, ActivityUpdate, ActivityStatistics


logger = logging.getLogger(__name__)

class ActivityService:
    """Service for handling activity-related operations"""

    @staticmethod
    async def create_activity(user: User, activity_data: ActivityCreate) -> Activity:
        """Create a new activity for a user"""
        # Check if all values exist and belong to user
        logger.info(f"Attempting to find values with IDs: {activity_data.value_ids} for user: {user.id}")

        values = []
        for value_id in activity_data.value_ids:
            value = await Value.find_one(
                Value.id == ObjectId(value_id) if not isinstance(value_id, ObjectId) else value_id,
                Value.user_id == str(user.id)
            )
            
            if not value:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=f"Value {value_id} not found"
                )
            values.append(value)
        
        # Check if date is not in future
        if activity_data.date > datetime.utcnow():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Cannot log future activities"
            )
        
        # Create new activity with multiple values
        new_activity = Activity(
            user_id=str(user.id),
            value_ids=activity_data.value_ids,
            value_id=activity_data.value_ids[0] if activity_data.value_ids else None,  # For backward compatibility
            name=activity_data.name,
            duration=activity_data.duration,
            date=activity_data.date,
            notes=activity_data.notes,
            is_public=activity_data.is_public,
            notes_public=activity_data.notes_public
        )
        
        await new_activity.insert()
        
        # Create social post if activity is public and has user-provided notes
        # Use the primary (first) value for social post
        if activity_data.is_public and activity_data.notes_public and activity_data.notes and values:
            await ActivityService._create_activity_social_post(user, new_activity, values[0])
        
        return new_activity

    @staticmethod
    async def get_activities(
        user: User,
        value_id: Optional[str] = None,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
        limit: int = 1000,
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
        ).sort(-Activity.date).skip(skip).limit(limit).to_list(length=None)
        
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
        """Delete an activity after validating ownership"""
        activity = await Activity.get_by_id(activity_id, user.id)
        if not activity:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Activity not found"
            )
        await activity.delete()

    @staticmethod
    async def get_activity_statistics(
        user: User,
        value_id: Optional[str] = None,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None
    ) -> Dict[str, Any]:
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
        
        # Get total duration by fetching all activities and summing manually
        activities = await Activity.find(query).to_list(length=None)
        total_duration = sum(activity.duration for activity in activities if activity.duration)
        
        # Calculate statistics
        return {
            "total_activities": total_activities,
            "total_duration_minutes": total_duration,
            "total_duration_hours": round(total_duration / 60, 2) if total_duration else 0,
            "average_duration_minutes": round(total_duration / total_activities, 2) if total_activities > 0 else 0
        }

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
            Value.user_id == str(user.id),
            Value.active == True
        ).to_list(length=None)
        
        result = []
        
        for value in values:
            # Query for activities for this value within the date range
            activities = await Activity.find(
                Activity.user_id == str(user.id),
                Activity.value_id == str(value.id),
                Activity.date >= start_date,
                Activity.date <= end_date
            ).to_list(length=None)
            
            # Calculate total time
            total_minutes = sum(activity.duration for activity in activities)
            
            # Calculate period in days
            period_days = (end_date - start_date).days + 1
            
            # Calculate daily average (avoid division by zero)
            daily_average = round(total_minutes / period_days, 2) if period_days > 0 else 0
            
            # Add to result
            result.append({
                "id": str(value.id),
                "name": value.name,
                "color": value.color,
                "importance": value.importance,
                "minutes": total_minutes,
                "count": len(activities),
                "daily_average": daily_average,
                # For demo purposes, set community average as a function of importance
                # In a real app, this would come from actual community data
                "community_avg": value.importance * 20  # Simple placeholder calculation
            })
        
        return {
            "period_start": start_date,
            "period_end": end_date,
            "period_days": (end_date - start_date).days + 1,
            "values": result
        }
    
    @staticmethod
    async def _create_activity_social_post(user: User, activity: Activity, value: Value) -> None:
        """Create a social post for a public activity with user-provided content"""
        try:
            # Only use user-provided notes as the content
            content = activity.notes
            
            # Create the social post with user's own words
            social_post = SocialPost(
                user_id=str(user.id),
                content=content,
                post_type=PostType.ACTIVITY_UPDATE,
                activity_id=str(activity.id),
                is_public=True
            )
            
            await social_post.save()
            logger.info(f"Created social post for activity {activity.id} by user {user.id}")
            
        except Exception as e:
            logger.error(f"Failed to create social post for activity {activity.id}: {e}")
            # Don't raise exception to avoid breaking activity creation