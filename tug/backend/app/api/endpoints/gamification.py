# app/api/endpoints/gamification.py
from typing import List, Optional, Dict, Any
from fastapi import APIRouter, Depends, HTTPException, Query, status
from datetime import datetime

from ...models.user import User
from ...services.gamification_service import GamificationService
from ...api.deps import get_current_user
from pydantic import BaseModel, Field

router = APIRouter()

class BadgeShowcaseRequest(BaseModel):
    badge_ids: List[str] = Field(..., max_items=5)

class RewardClaimRequest(BaseModel):
    reward_id: str

class UserProgressionResponse(BaseModel):
    user_id: str
    progression: Dict[str, Any]
    streaks: Dict[str, Any]
    achievements: Dict[str, Any]
    social: Dict[str, Any]
    badges: Dict[str, Any]

class LeaderboardResponse(BaseModel):
    leaderboard_type: str
    metric: str
    time_period: str
    entries: List[Dict[str, Any]]
    user_position: Optional[int]
    total_entries: int
    generated_at: datetime

@router.get("/progression", response_model=UserProgressionResponse)
async def get_user_progression(
    current_user: User = Depends(get_current_user)
):
    """Get comprehensive user progression data"""
    
    progression_data = await GamificationService.get_user_progression(current_user)
    return UserProgressionResponse(**progression_data)

@router.get("/rewards", response_model=List[Dict[str, Any]])
async def get_available_rewards(
    category: Optional[str] = Query(None),
    current_user: User = Depends(get_current_user)
):
    """Get rewards available to user"""
    
    rewards = await GamificationService.get_available_rewards(
        user=current_user,
        category=category
    )
    
    return rewards

@router.post("/rewards/claim", response_model=Dict[str, Any])
async def claim_reward(
    request: RewardClaimRequest,
    current_user: User = Depends(get_current_user)
):
    """Claim a reward"""
    
    result = await GamificationService.claim_reward(
        user=current_user,
        reward_id=request.reward_id
    )
    
    return result

@router.post("/badges/showcase", response_model=Dict[str, Any])
async def showcase_badges(
    request: BadgeShowcaseRequest,
    current_user: User = Depends(get_current_user)
):
    """Set which badges to showcase"""
    
    result = await GamificationService.showcase_badges(
        user=current_user,
        badge_ids=request.badge_ids
    )
    
    return result

@router.get("/leaderboards", response_model=LeaderboardResponse)
async def get_leaderboards(
    leaderboard_type: str = Query("global", regex="^(global|friends|group)$"),
    metric: str = Query("xp", regex="^(xp|level|points|streak|challenges)$"),
    time_period: str = Query("all_time", regex="^(daily|weekly|monthly|all_time)$"),
    limit: int = Query(50, ge=1, le=100),
    current_user: User = Depends(get_current_user)
):
    """Get leaderboard data"""
    
    leaderboard = await GamificationService.get_leaderboards(
        leaderboard_type=leaderboard_type,
        metric=metric,
        time_period=time_period,
        limit=limit,
        user_id=str(current_user.id)
    )
    
    return LeaderboardResponse(**leaderboard)

@router.post("/activity/xp", response_model=Dict[str, Any])
async def award_activity_xp(
    activity_data: Dict[str, Any],
    current_user: User = Depends(get_current_user)
):
    """Award XP for logging an activity"""
    
    result = await GamificationService.award_activity_xp(
        user=current_user,
        activity_data=activity_data
    )
    
    return result

@router.get("/stats/summary", response_model=Dict[str, Any])
async def get_gamification_summary(
    current_user: User = Depends(get_current_user)
):
    """Get a summary of user's gamification stats"""
    
    progression_data = await GamificationService.get_user_progression(current_user)
    
    # Extract key stats for summary
    summary = {
        "level": progression_data["progression"]["level"],
        "level_tier": progression_data["progression"]["level_tier"],
        "total_xp": progression_data["progression"]["total_xp"],
        "level_progress": progression_data["progression"]["level_progress_percentage"],
        "current_points": progression_data["progression"]["current_points"],
        "current_streak": progression_data["streaks"]["current_streak"],
        "longest_streak": progression_data["streaks"]["longest_streak"],
        "challenges_completed": progression_data["achievements"]["challenges_completed"],
        "badges_earned": progression_data["badges"]["total"],
        "global_rank": progression_data["social"]["global_rank"],
        "recent_badges": progression_data["badges"]["recent"][:3],  # Last 3 badges
        "next_level_xp": progression_data["progression"]["xp_to_next_level"]
    }
    
    return summary

@router.get("/badges/all", response_model=Dict[str, Any])
async def get_all_user_badges(
    current_user: User = Depends(get_current_user)
):
    """Get all badges earned by user, grouped by category"""
    
    from ...models.gamification import UserBadge, Badge
    
    # Get user's badges
    user_badges = await UserBadge.find({"user_id": str(current_user.id)})\
        .sort([("earned_at", -1)])\
        .to_list()
    
    # Get badge details
    badge_ids = [ub.badge_id for ub in user_badges]
    badges = await Badge.find({"badge_id": {"$in": badge_ids}}).to_list()
    badge_map = {b.badge_id: b for b in badges}
    
    # Group by category
    badges_by_category = {}
    showcase_badges = []
    
    for user_badge in user_badges:
        badge = badge_map.get(user_badge.badge_id)
        if badge:
            category = badge.category.value
            if category not in badges_by_category:
                badges_by_category[category] = []
            
            badge_data = {
                "id": user_badge.badge_id,
                "name": badge.name,
                "description": badge.description,
                "icon": badge.icon,
                "rarity": badge.rarity,
                "earned_at": user_badge.earned_at,
                "stack_count": user_badge.stack_count,
                "is_showcased": user_badge.is_showcased,
                "points_value": badge.points_value
            }
            
            badges_by_category[category].append(badge_data)
            
            if user_badge.is_showcased:
                showcase_badges.append(badge_data)
    
    return {
        "total_badges": len(user_badges),
        "badges_by_category": badges_by_category,
        "showcased_badges": sorted(showcase_badges, key=lambda x: x.get("showcase_order", 0)),
        "rarest_badge": max([badge_map[ub.badge_id] for ub in user_badges if ub.badge_id in badge_map], 
                           key=lambda b: {"legendary": 5, "epic": 4, "rare": 3, "uncommon": 2, "common": 1}[b.rarity.value], 
                           default=None)
    }

@router.get("/achievements/progress", response_model=Dict[str, Any])
async def get_achievement_progress(
    current_user: User = Depends(get_current_user)
):
    """Get progress toward various achievements"""
    
    from ...models.gamification import UserProgression
    from ...models.challenge import ChallengeParticipation
    from ...models.activity import Activity
    
    # Get user progression
    progression = await UserProgression.find_one({"user_id": str(current_user.id)})
    if not progression:
        progression = await GamificationService.initialize_user_gamification(current_user)
    
    # Get activity stats
    total_activities = await Activity.count_documents({"user_id": str(current_user.id)})
    
    # Get challenge stats
    challenges_completed = await ChallengeParticipation.count_documents({
        "user_id": str(current_user.id),
        "status": "completed"
    })
    
    # Define achievement progress
    achievements_progress = {
        "level_milestones": {
            "current": progression.current_level,
            "next_milestone": 50 if progression.current_level < 50 else 100,
            "progress": progression.current_level / (50 if progression.current_level < 50 else 100) * 100
        },
        "streak_achievements": {
            "current": progression.current_streak,
            "longest": progression.longest_streak,
            "next_milestone": 30 if progression.longest_streak < 30 else 100,
            "progress": progression.longest_streak / (30 if progression.longest_streak < 30 else 100) * 100
        },
        "activity_milestones": {
            "current": total_activities,
            "next_milestone": 100 if total_activities < 100 else 1000,
            "progress": total_activities / (100 if total_activities < 100 else 1000) * 100
        },
        "challenge_milestones": {
            "current": challenges_completed,
            "next_milestone": 10 if challenges_completed < 10 else 50,
            "progress": challenges_completed / (10 if challenges_completed < 10 else 50) * 100
        },
        "points_milestones": {
            "current": progression.lifetime_points,
            "next_milestone": 10000 if progression.lifetime_points < 10000 else 50000,
            "progress": progression.lifetime_points / (10000 if progression.lifetime_points < 10000 else 50000) * 100
        }
    }
    
    return {
        "achievements_progress": achievements_progress,
        "overall_completion": sum(a["progress"] for a in achievements_progress.values()) / len(achievements_progress),
        "strongest_area": max(achievements_progress.keys(), key=lambda k: achievements_progress[k]["progress"]),
        "improvement_area": min(achievements_progress.keys(), key=lambda k: achievements_progress[k]["progress"])
    }