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

        # Convert value_ids to ObjectIds for batch query
        object_ids = []
        for value_id in activity_data.value_ids:
            if isinstance(value_id, ObjectId):
                object_ids.append(value_id)
            else:
                object_ids.append(ObjectId(value_id))
        
        # Batch query to fetch all values at once
        values = await Value.find(
            {"_id": {"$in": object_ids}, "user_id": str(user.id)}
        ).to_list()
        
        # Check if all requested values were found
        if len(values) != len(activity_data.value_ids):
            found_ids = {str(value.id) for value in values}
            missing_ids = set(str(vid) for vid in activity_data.value_ids) - found_ids
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Values not found: {', '.join(missing_ids)}"
            )
        
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
        
        # Use aggregation pipeline for efficient statistics calculation
        pipeline = [
            {"$match": query},
            {
                "$group": {
                    "_id": None,
                    "total_activities": {"$sum": 1},
                    "total_duration": {"$sum": "$duration"}
                }
            }
        ]
        
        # Execute aggregation
        result = await Activity.aggregate(pipeline).to_list()
        
        if result:
            stats = result[0]
            total_activities = stats["total_activities"]
            total_duration = stats["total_duration"] or 0
        else:
            total_activities = 0
            total_duration = 0
        
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
        
        # Calculate period in days
        period_days = (end_date - start_date).days + 1
        
        # Use aggregation pipeline to efficiently get activity summary by value
        # First, get all user values and their activity statistics in a single query
        pipeline = [
            {
                "$lookup": {
                    "from": "activities",
                    "let": {"value_id": {"$toString": "$_id"}, "user_id": "$user_id"},
                    "pipeline": [
                        {
                            "$match": {
                                "$expr": {
                                    "$and": [
                                        {"$eq": ["$user_id", "$$user_id"]},
                                        {"$eq": ["$value_id", "$$value_id"]},
                                        {"$gte": ["$date", start_date]},
                                        {"$lte": ["$date", end_date]}
                                    ]
                                }
                            }
                        },
                        {
                            "$group": {
                                "_id": None,
                                "total_minutes": {"$sum": "$duration"},
                                "count": {"$sum": 1}
                            }
                        }
                    ],
                    "as": "activity_stats"
                }
            },
            {
                "$match": {
                    "user_id": str(user.id),
                    "active": True
                }
            },
            {
                "$project": {
                    "_id": 1,
                    "name": 1,
                    "color": 1,
                    "importance": 1,
                    "minutes": {
                        "$ifNull": [
                            {"$arrayElemAt": ["$activity_stats.total_minutes", 0]},
                            0
                        ]
                    },
                    "count": {
                        "$ifNull": [
                            {"$arrayElemAt": ["$activity_stats.count", 0]},
                            0
                        ]
                    }
                }
            }
        ]
        
        # Execute the aggregation on Value collection
        values_with_stats = await Value.aggregate(pipeline).to_list()
        
        # Format the results
        result = []
        for value_data in values_with_stats:
            daily_average = round(value_data["minutes"] / period_days, 2) if period_days > 0 else 0
            
            result.append({
                "id": str(value_data["_id"]),
                "name": value_data["name"],
                "color": value_data["color"],
                "importance": value_data["importance"],
                "minutes": value_data["minutes"],
                "count": value_data["count"],
                "daily_average": daily_average,
                # For demo purposes, set community average as a function of importance
                # In a real app, this would come from actual community data
                "community_avg": value_data["importance"] * 20  # Simple placeholder calculation
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