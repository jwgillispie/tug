# app/services/mood_service.py
import logging
from typing import List, Optional, Dict, Any
from datetime import datetime, timedelta
from fastapi import HTTPException, status
from bson import ObjectId

from ..models.user import User
from ..models.mood import MoodEntry, MoodType, MOOD_POSITIVITY_SCORES
from ..models.activity import Activity
from ..models.indulgence import Indulgence
from ..models.value import Value
from ..schemas.mood import (
    MoodEntryCreate, MoodEntryUpdate, MoodEntryResponse,
    MoodOption, MoodOptionsResponse, MoodStatistics,
    MoodAnalyticsResponse, MoodChartData, MoodChartResponse
)

logger = logging.getLogger(__name__)

class MoodService:
    """Service for handling mood-related operations"""

    @staticmethod
    def get_mood_options() -> MoodOptionsResponse:
        """Get all available mood options with details"""
        mood_options = [
            MoodOption(
                mood_type=MoodType.ECSTATIC,
                display_name="Ecstatic",
                positivity_score=10,
                description="Peak positive energy, euphoric",
                emoji="🤩"
            ),
            MoodOption(
                mood_type=MoodType.JOYFUL,
                display_name="Joyful",
                positivity_score=9,
                description="Very happy, delighted",
                emoji="😊"
            ),
            MoodOption(
                mood_type=MoodType.CONFIDENT,
                display_name="Confident",
                positivity_score=8,
                description="Self-assured, empowered",
                emoji="💪"
            ),
            MoodOption(
                mood_type=MoodType.CONTENT,
                display_name="Content",
                positivity_score=7,
                description="Satisfied, peaceful",
                emoji="😌"
            ),
            MoodOption(
                mood_type=MoodType.FOCUSED,
                display_name="Focused",
                positivity_score=6,
                description="Clear-minded, determined",
                emoji="🎯"
            ),
            MoodOption(
                mood_type=MoodType.NEUTRAL,
                display_name="Neutral",
                positivity_score=5,
                description="Balanced, neither positive nor negative",
                emoji="😐"
            ),
            MoodOption(
                mood_type=MoodType.RESTLESS,
                display_name="Restless",
                positivity_score=4,
                description="Agitated, unsettled",
                emoji="😣"
            ),
            MoodOption(
                mood_type=MoodType.TIRED,
                display_name="Tired",
                positivity_score=3,
                description="Fatigued, low energy",
                emoji="😴"
            ),
            MoodOption(
                mood_type=MoodType.FRUSTRATED,
                display_name="Frustrated",
                positivity_score=2,
                description="Annoyed, blocked",
                emoji="😤"
            ),
            MoodOption(
                mood_type=MoodType.ANXIOUS,
                display_name="Anxious",
                positivity_score=2,
                description="Worried, stressed",
                emoji="😰"
            ),
            MoodOption(
                mood_type=MoodType.SAD,
                display_name="Sad",
                positivity_score=1,
                description="Down, melancholy",
                emoji="😢"
            ),
            MoodOption(
                mood_type=MoodType.OVERWHELMED,
                display_name="Overwhelmed",
                positivity_score=1,
                description="Too much to handle",
                emoji="😵"
            ),
            MoodOption(
                mood_type=MoodType.ANGRY,
                display_name="Angry",
                positivity_score=1,
                description="Mad, irritated",
                emoji="😠"
            ),
            MoodOption(
                mood_type=MoodType.DEFEATED,
                display_name="Defeated",
                positivity_score=0,
                description="Hopeless, giving up",
                emoji="😞"
            ),
            MoodOption(
                mood_type=MoodType.DEPRESSED,
                display_name="Depressed",
                positivity_score=0,
                description="Very low, heavy sadness",
                emoji="😔"
            ),
        ]
        
        return MoodOptionsResponse(moods=mood_options)

    @staticmethod
    async def create_mood_entry(user: User, mood_data: MoodEntryCreate) -> MoodEntryResponse:
        """Create a new mood entry"""
        try:
            # Validate activity/indulgence exists if provided (skip temporary IDs)
            if mood_data.activity_id and not mood_data.activity_id.startswith('temp_'):
                try:
                    activity = await Activity.find_one(
                        Activity.id == ObjectId(mood_data.activity_id),
                        Activity.user_id == str(user.id)
                    )
                    if not activity:
                        raise HTTPException(
                            status_code=status.HTTP_404_NOT_FOUND,
                            detail="Activity not found"
                        )
                except Exception as e:
                    if "not a valid ObjectId" in str(e):
                        logger.warning(f"Invalid activity_id format: {mood_data.activity_id}")
                        # Allow mood entry creation without activity validation
                    else:
                        raise
            
            if mood_data.indulgence_id and not mood_data.indulgence_id.startswith('temp_'):
                try:
                    indulgence = await Indulgence.find_one(
                        Indulgence.id == ObjectId(mood_data.indulgence_id),
                        Indulgence.user_id == str(user.id)
                    )
                    if not indulgence:
                        raise HTTPException(
                            status_code=status.HTTP_404_NOT_FOUND,
                            detail="Indulgence not found"
                        )
                except Exception as e:
                    if "not a valid ObjectId" in str(e):
                        logger.warning(f"Invalid indulgence_id format: {mood_data.indulgence_id}")
                        # Allow mood entry creation without indulgence validation
                    else:
                        raise

            # Create mood entry
            mood_entry = MoodEntry.create_mood_entry(
                user_id=str(user.id),
                mood_type=mood_data.mood_type,
                notes=mood_data.notes,
                activity_id=mood_data.activity_id,
                indulgence_id=mood_data.indulgence_id
            )
            
            await mood_entry.insert()
            logger.info(f"Created mood entry {mood_entry.id} for user {user.id}")
            
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
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error creating mood entry: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create mood entry"
            )

    @staticmethod
    async def get_mood_entries(
        user: User,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
        limit: int = 100,
        skip: int = 0
    ) -> List[MoodEntryResponse]:
        """Get mood entries for a user"""
        try:
            # Build query
            query = {"user_id": str(user.id)}
            
            if start_date or end_date:
                date_filter = {}
                if start_date:
                    date_filter["$gte"] = start_date
                if end_date:
                    date_filter["$lte"] = end_date
                query["recorded_at"] = date_filter
            
            # Get mood entries
            mood_entries = await MoodEntry.find(query).sort(-MoodEntry.recorded_at).skip(skip).limit(limit).to_list()
            
            # Convert to response format
            return [
                MoodEntryResponse(
                    id=str(entry.id),
                    user_id=entry.user_id,
                    mood_type=entry.mood_type,
                    positivity_score=entry.positivity_score,
                    notes=entry.notes,
                    activity_id=entry.activity_id,
                    indulgence_id=entry.indulgence_id,
                    recorded_at=entry.recorded_at,
                    created_at=entry.created_at,
                    updated_at=entry.updated_at
                )
                for entry in mood_entries
            ]
            
        except Exception as e:
            logger.error(f"Error getting mood entries: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to get mood entries"
            )

    @staticmethod
    async def get_mood_chart_data(
        user: User,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None
    ) -> MoodChartResponse:
        """Get mood data formatted for chart overlay"""
        try:
            # Default to last 30 days if no dates provided
            if not end_date:
                end_date = datetime.utcnow()
            if not start_date:
                start_date = end_date - timedelta(days=30)
            
            # Get mood entries in date range
            mood_entries = await MoodEntry.find({
                "user_id": str(user.id),
                "recorded_at": {"$gte": start_date, "$lte": end_date}
            }).sort(MoodEntry.recorded_at).to_list()
            
            # Get related activities for context (skip temporary IDs)
            activity_ids = [entry.activity_id for entry in mood_entries 
                          if entry.activity_id and not entry.activity_id.startswith('temp_')]
            activities = {}
            if activity_ids:
                valid_object_ids = []
                for aid in activity_ids:
                    try:
                        valid_object_ids.append(ObjectId(aid))
                    except Exception:
                        logger.warning(f"Skipping invalid activity_id: {aid}")
                        continue
                
                if valid_object_ids:
                    activity_list = await Activity.find({
                        "_id": {"$in": valid_object_ids}
                    }).to_list()
                    activities = {str(act.id): act for act in activity_list}
            
            # Get related values for context (handle multi-value activities)
            value_ids = []
            for act in activities.values():
                if hasattr(act, 'value_ids') and act.value_ids:
                    value_ids.extend(act.value_ids)
                elif hasattr(act, 'value_id') and act.value_id:
                    value_ids.append(act.value_id)
            
            # Remove duplicates
            value_ids = list(set(value_ids))
            
            values = {}
            if value_ids:
                valid_value_ids = []
                for vid in value_ids:
                    try:
                        valid_value_ids.append(ObjectId(vid))
                    except Exception:
                        logger.warning(f"Skipping invalid value_id: {vid}")
                        continue
                
                if valid_value_ids:
                    value_list = await Value.find({
                        "_id": {"$in": valid_value_ids}
                    }).to_list()
                    values = {str(val.id): val for val in value_list}
            
            # Build chart data
            mood_data = []
            total_positivity = 0
            
            for entry in mood_entries:
                activity = activities.get(entry.activity_id) if entry.activity_id else None
                
                # Handle multi-value activities - use primary value for display
                value = None
                if activity:
                    if hasattr(activity, 'value_ids') and activity.value_ids:
                        primary_value_id = activity.value_ids[0]
                        value = values.get(primary_value_id)
                    elif hasattr(activity, 'value_id') and activity.value_id:
                        value = values.get(activity.value_id)
                
                mood_data.append(MoodChartData(
                    date=entry.recorded_at,
                    mood_score=float(entry.positivity_score),
                    mood_type=entry.mood_type,
                    activity_name=activity.name if activity else None,
                    value_name=value.name if value else None
                ))
                total_positivity += entry.positivity_score
            
            average_mood = total_positivity / len(mood_entries) if mood_entries else 5.0
            
            return MoodChartResponse(
                mood_data=mood_data,
                date_range={
                    "start_date": start_date,
                    "end_date": end_date
                },
                average_mood=round(average_mood, 2)
            )
            
        except Exception as e:
            logger.error(f"Error getting mood chart data: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to get mood chart data"
            )