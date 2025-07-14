# app/api/endpoints/mood.py
from fastapi import APIRouter, Depends, HTTPException, Query
from typing import List, Optional
from datetime import datetime

from ...models.user import User
from ...services.mood_service import MoodService
from ...schemas.mood import (
    MoodEntryCreate, MoodEntryUpdate, MoodEntryResponse,
    MoodOptionsResponse, MoodChartResponse
)
from ...core.auth import get_current_user

router = APIRouter()

@router.get("/options", response_model=MoodOptionsResponse)
async def get_mood_options():
    """Get all available mood options with their positivity scores and descriptions"""
    return MoodService.get_mood_options()

@router.post("/entries", response_model=MoodEntryResponse)
async def create_mood_entry(
    mood_data: MoodEntryCreate,
    current_user: User = Depends(get_current_user)
):
    """Create a new mood entry"""
    return await MoodService.create_mood_entry(current_user, mood_data)

@router.get("/entries", response_model=List[MoodEntryResponse])
async def get_mood_entries(
    start_date: Optional[datetime] = Query(None, description="Start date for mood entries"),
    end_date: Optional[datetime] = Query(None, description="End date for mood entries"),
    limit: int = Query(100, ge=1, le=1000, description="Number of entries to return"),
    skip: int = Query(0, ge=0, description="Number of entries to skip"),
    current_user: User = Depends(get_current_user)
):
    """Get mood entries for the current user"""
    return await MoodService.get_mood_entries(
        current_user, start_date, end_date, limit, skip
    )

@router.get("/entries/{entry_id}", response_model=MoodEntryResponse)
async def get_mood_entry(
    entry_id: str,
    current_user: User = Depends(get_current_user)
):
    """Get a specific mood entry"""
    try:
        from bson import ObjectId
        from ...models.mood import MoodEntry
        
        mood_entry = await MoodEntry.find_one(
            MoodEntry.id == ObjectId(entry_id),
            MoodEntry.user_id == str(current_user.id)
        )
        
        if not mood_entry:
            raise HTTPException(status_code=404, detail="Mood entry not found")
        
        return MoodEntryResponse(
            id=str(mood_entry.id),
            user_id=mood_entry.user_id,
            mood_type=mood_entry.mood_type,
            positivity_score=mood_entry.positivity_score,
            notes=mood_entry.notes,
            activity_id=mood_entry.activity_id,
            indulgence_id=mood_entry.indulgence_id,
            recorded_at=mood_entry.recorded_at,
            created_at=mood_entry.created_at,
            updated_at=mood_entry.updated_at
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail="Failed to get mood entry")

@router.put("/entries/{entry_id}", response_model=MoodEntryResponse)
async def update_mood_entry(
    entry_id: str,
    mood_data: MoodEntryUpdate,
    current_user: User = Depends(get_current_user)
):
    """Update a mood entry"""
    try:
        from bson import ObjectId
        from ...models.mood import MoodEntry
        
        mood_entry = await MoodEntry.find_one(
            MoodEntry.id == ObjectId(entry_id),
            MoodEntry.user_id == str(current_user.id)
        )
        
        if not mood_entry:
            raise HTTPException(status_code=404, detail="Mood entry not found")
        
        # Update fields
        update_data = mood_data.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            setattr(mood_entry, field, value)
        
        # Update positivity score if mood type changed
        if mood_data.mood_type:
            mood_entry.positivity_score = MoodEntry.get_positivity_score(mood_data.mood_type)
        
        mood_entry.update_timestamp()
        await mood_entry.save()
        
        return MoodEntryResponse(
            id=str(mood_entry.id),
            user_id=mood_entry.user_id,
            mood_type=mood_entry.mood_type,
            positivity_score=mood_entry.positivity_score,
            notes=mood_entry.notes,
            activity_id=mood_entry.activity_id,
            indulgence_id=mood_entry.indulgence_id,
            recorded_at=mood_entry.recorded_at,
            created_at=mood_entry.created_at,
            updated_at=mood_entry.updated_at
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail="Failed to update mood entry")

@router.delete("/entries/{entry_id}")
async def delete_mood_entry(
    entry_id: str,
    current_user: User = Depends(get_current_user)
):
    """Delete a mood entry"""
    try:
        from bson import ObjectId
        from ...models.mood import MoodEntry
        
        mood_entry = await MoodEntry.find_one(
            MoodEntry.id == ObjectId(entry_id),
            MoodEntry.user_id == str(current_user.id)
        )
        
        if not mood_entry:
            raise HTTPException(status_code=404, detail="Mood entry not found")
        
        await mood_entry.delete()
        return {"message": "Mood entry deleted successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail="Failed to delete mood entry")

@router.get("/chart-data", response_model=MoodChartResponse)
async def get_mood_chart_data(
    start_date: Optional[datetime] = Query(None, description="Start date for chart data"),
    end_date: Optional[datetime] = Query(None, description="End date for chart data"),
    current_user: User = Depends(get_current_user)
):
    """Get mood data formatted for chart overlay on activity charts"""
    return await MoodService.get_mood_chart_data(current_user, start_date, end_date)