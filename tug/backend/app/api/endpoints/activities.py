# app/api/endpoints/activities.py
from fastapi import APIRouter, Depends, HTTPException, Query, status
from typing import List, Optional
from datetime import datetime, timedelta
from ...models.user import User
from ...models.value import Value
from ...models.activity import Activity
from ...schemas.activity import (
    ActivityCreate, 
    ActivityUpdate, 
    ActivityResponse,
    ActivityStatistics
)
from ...core.auth import get_current_user

router = APIRouter()

@router.post("/", response_model=ActivityResponse, status_code=status.HTTP_201_CREATED)
async def create_activity(
    activity: ActivityCreate,
    current_user: User = Depends(get_current_user)
):
    """Create a new activity for the current user"""
    # Check if value exists and belongs to user
    value = await Value.find_one(
        Value.id == activity.value_id,
        Value.user_id == str(current_user.id)
    )
    
    if not value:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Value not found"
        )
    
    # Check if date is not in future
    if activity.date > datetime.utcnow():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot log future activities"
        )
    
    # Create new activity
    new_activity = Activity(
        user_id=str(current_user.id),
        value_id=activity.value_id,
        name=activity.name,
        duration=activity.duration,
        date=activity.date,
        notes=activity.notes
    )
    
    await new_activity.insert()
    return new_activity

@router.get("/", response_model=List[ActivityResponse])
async def get_activities(
    current_user: User = Depends(get_current_user),
    value_id: Optional[str] = None,
    start_date: Optional[datetime] = None,
    end_date: Optional[datetime] = None,
    limit: int = Query(50, ge=1, le=100),
    skip: int = Query(0, ge=0)
):
    """Get activities for the current user with optional filtering"""
    query = {Activity.user_id: str(current_user.id)}
    
    if value_id:
        query[Activity.value_id] = value_id
    
    if start_date:
        query[Activity.date] = {"$gte": start_date}
    
    if end_date:
        if Activity.date in query:
            query[Activity.date]["$lte"] = end_date
        else:
            query[Activity.date] = {"$lte": end_date}
    
    activities = await Activity.find(
        query
    ).sort(-Activity.date).skip(skip).limit(limit).to_list()
    
    return activities

@router.get("/statistics", response_model=ActivityStatistics)
async def get_activity_statistics(
    current_user: User = Depends(get_current_user),
    value_id: Optional[str] = None,
    start_date: Optional[datetime] = None,
    end_date: Optional[datetime] = None
):
    """Get activity statistics for the current user"""
    query = {Activity.user_id: str(current_user.id)}
    
    if value_id:
        query[Activity.value_id] = value_id
    
    if start_date:
        query[Activity.date] = {"$gte": start_date}
    
    if end_date:
        if Activity.date in query:
            query[Activity.date]["$lte"] = end_date
        else:
            query[Activity.date] = {"$lte": end_date}
    
    # Count activities
    total_activities = await Activity.find(query).count()
    
    # Get total duration
    total_duration = await Activity.find(query).sum("duration") or 0
    
    # Calculate statistics
    return ActivityStatistics(
        total_activities=total_activities,
        total_duration_minutes=total_duration,
        total_duration_hours=round(total_duration / 60, 2),
        average_duration_minutes=round(total_duration / total_activities, 2) if total_activities > 0 else 0
    )

@router.get("/{activity_id}", response_model=ActivityResponse)
async def get_activity(
    activity_id: str,
    current_user: User = Depends(get_current_user)
):
    """Get a specific activity by ID"""
    activity = await Activity.find_one(
        Activity.id == activity_id,
        Activity.user_id == str(current_user.id)
    )
    
    if not activity:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Activity not found"
        )
    
    return activity

@router.patch("/{activity_id}", response_model=ActivityResponse)
async def update_activity(
    activity_id: str,
    activity_update: ActivityUpdate,
    current_user: User = Depends(get_current_user)
):
    """Update a specific activity"""
    # Find the activity
    activity = await Activity.find_one(
        Activity.id == activity_id,
        Activity.user_id == str(current_user.id)
    )
    
    if not activity:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Activity not found"
        )
    
    # Check if value_id is being updated and if it exists
    update_data = activity_update.model_dump(exclude_unset=True)
    if "value_id" in update_data:
        value = await Value.find_one(
            Value.id == update_data["value_id"],
            Value.user_id == str(current_user.id)
        )
        
        if not value:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Value not found"
            )
    
    # Check if date is not in future
    if "date" in update_data and update_data["date"] > datetime.utcnow():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot log future activities"
        )
    
    # Update activity with provided data
    if update_data:
        for field, value in update_data.items():
            setattr(activity, field, value)
        
        await activity.save()
    
    return activity

@router.delete("/{activity_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_activity(
    activity_id: str,
    current_user: User = Depends(get_current_user)
):
    """Delete an activity"""
    activity = await Activity.find_one(
        Activity.id == activity_id,
        Activity.user_id == str(current_user.id)
    )
    
    if not activity:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Activity not found"
        )
    
    # Delete the activity
    await activity.delete()