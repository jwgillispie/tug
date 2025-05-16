# app/api/endpoints/rankings.py
from bson import ObjectId
from fastapi import APIRouter, Depends, HTTPException, Query, status
from typing import Any, Dict, List, Optional
from datetime import datetime, timedelta
import logging

from ...models.user import User
from ...models.activity import Activity
from ...core.auth import get_current_user
from ...services.rankings_service import RankingsService
from ...utils.json_utils import MongoJSONEncoder

router = APIRouter()
logger = logging.getLogger(__name__)

@router.get("/")
async def get_top_users(
    current_user: User = Depends(get_current_user),
    days: int = Query(30, ge=1, le=365, description="Number of days to consider for the ranking"),
    limit: int = Query(20, ge=1, le=100, description="Maximum number of users to return"),
    rank_by: str = Query("activities", description="Field to rank users by (activities or streak)"),
):
    """Get a ranking of users with the most activities"""
    try:
        logger.info(f"Getting top users for last {days} days, limit {limit}")
        
        rankings = await RankingsService.get_user_rankings(
            days=days,
            limit=limit,
            rank_by=rank_by
        )
        
        # Add info if current user is in the rankings
        user_id_str = str(current_user.id)
        current_user_rank = next(
            (index + 1 for index, user in enumerate(rankings) if user["user_id"] == user_id_str), 
            None
        )
        
        # If current user is not in the rankings, get their rank separately
        if current_user_rank is None:
            current_user_data = await RankingsService.get_user_rank(current_user, days)
            current_user_rank = current_user_data.get("rank") if current_user_data else None
        
        # Convert to dictionary and encode MongoDB types
        rankings_list = MongoJSONEncoder.encode_mongo_data(rankings)
        
        logger.info(f"Retrieved {len(rankings)} top users")
        return {
            "rankings": rankings_list,
            "current_user_rank": current_user_rank,
            "period_days": days,
        }
    except Exception as e:
        logger.error(f"Error getting user rankings: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get user rankings: {str(e)}"
        )

@router.get("/me")
async def get_current_user_rank(
    current_user: User = Depends(get_current_user),
    days: int = Query(30, ge=1, le=365, description="Number of days to consider for the ranking"),
):
    """Get the current user's rank"""
    try:
        logger.info(f"Getting rank for user {current_user.id} for last {days} days")
        
        user_rank = await RankingsService.get_user_rank(current_user, days)
        
        # Convert to dictionary and encode MongoDB types
        user_rank = MongoJSONEncoder.encode_mongo_data(user_rank)
        
        logger.info(f"Retrieved user rank: {user_rank.get('rank') if user_rank else None}")
        return user_rank
    except Exception as e:
        logger.error(f"Error getting user rank: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get user rank: {str(e)}"
        )