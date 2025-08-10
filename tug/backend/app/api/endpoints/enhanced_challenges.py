# app/api/endpoints/enhanced_challenges.py
from typing import List, Optional, Dict, Any
from fastapi import APIRouter, Depends, HTTPException, Query, status
from datetime import datetime

from ...models.user import User
from ...models.challenge import Challenge, ChallengeParticipation, ChallengeTeam
from ...services.enhanced_challenge_service import EnhancedChallengeService
from ...api.deps import get_current_user, get_db
from ...core.database import get_database
from pydantic import BaseModel, Field

router = APIRouter()

class ChallengeCreateRequest(BaseModel):
    title: str = Field(..., min_length=1, max_length=100)
    description: str = Field(..., min_length=1, max_length=1000)
    short_description: Optional[str] = Field(None, max_length=200)
    challenge_type: str = Field(default="individual")
    category: str = Field(default="health")
    difficulty: str = Field(default="medium")
    mechanic: str = Field(default="daily_streak")
    target_metric: str = Field(default="days")
    target_value: float = Field(..., gt=0)
    duration_days: int = Field(..., gt=0, le=365)
    start_date: Optional[datetime] = None
    requires_premium: bool = False
    is_multi_stage: bool = False
    stages: List[Dict[str, Any]] = Field(default_factory=list)
    tags: List[str] = Field(default_factory=list)
    icon: str = Field(default="🏆")
    allow_teams: bool = False
    max_participants: Optional[int] = None

class ChallengeResponse(BaseModel):
    id: str
    title: str
    description: str
    difficulty: str
    category: str
    status: str
    start_date: datetime
    end_date: datetime
    total_participants: int
    base_points: int
    icon: str
    is_participating: bool = False
    user_progress: Optional[Dict[str, Any]] = None

class LeaderboardResponse(BaseModel):
    challenge_id: str
    challenge_title: str
    leaderboard_type: str
    total_participants: int
    entries: List[Dict[str, Any]]
    generated_at: datetime

@router.post("/challenges", response_model=Dict[str, Any])
async def create_challenge(
    challenge_data: ChallengeCreateRequest,
    current_user: User = Depends(get_current_user)
):
    """Create a new enhanced challenge"""
    
    challenge = await EnhancedChallengeService.create_challenge(
        current_user=current_user,
        challenge_data=challenge_data.model_dump(),
        is_ai_generated=False
    )
    
    return {
        "challenge_id": str(challenge.id),
        "title": challenge.title,
        "message": "Challenge created successfully"
    }

@router.get("/challenges", response_model=List[ChallengeResponse])
async def get_challenges(
    challenge_type: Optional[str] = Query(None),
    category: Optional[str] = Query(None),
    difficulty: Optional[str] = Query(None),
    status: Optional[str] = Query("active"),
    limit: int = Query(20, ge=1, le=100),
    skip: int = Query(0, ge=0),
    current_user: User = Depends(get_current_user)
):
    """Get available challenges with filters"""
    
    # Build query
    query = {}
    if challenge_type:
        query["challenge_type"] = challenge_type
    if category:
        query["category"] = category
    if difficulty:
        query["difficulty"] = difficulty
    if status:
        query["status"] = status
    
    # Get challenges
    challenges = await Challenge.find(query)\
        .sort([("featured", -1), ("start_date", -1)])\
        .skip(skip)\
        .limit(limit)\
        .to_list()
    
    # Check user participation
    challenge_ids = [str(c.id) for c in challenges]
    user_participations = await ChallengeParticipation.find({
        "challenge_id": {"$in": challenge_ids},
        "user_id": str(current_user.id)
    }).to_list()
    
    participation_map = {p.challenge_id: p for p in user_participations}
    
    # Format response
    response = []
    for challenge in challenges:
        participation = participation_map.get(str(challenge.id))
        
        challenge_response = ChallengeResponse(
            id=str(challenge.id),
            title=challenge.title,
            description=challenge.description,
            difficulty=challenge.difficulty,
            category=challenge.category,
            status=challenge.status,
            start_date=challenge.start_date,
            end_date=challenge.end_date,
            total_participants=challenge.total_participants,
            base_points=challenge.base_points,
            icon=challenge.icon,
            is_participating=participation is not None
        )
        
        if participation:
            challenge_response.user_progress = {
                "progress": participation.current_progress,
                "progress_percentage": participation.progress_percentage,
                "streak": participation.current_streak,
                "points_earned": participation.points_earned
            }
        
        response.append(challenge_response)
    
    return response

@router.get("/challenges/personalized", response_model=List[Dict[str, Any]])
async def get_personalized_challenges(
    count: int = Query(5, ge=1, le=10),
    current_user: User = Depends(get_current_user)
):
    """Get AI-generated personalized challenges"""
    
    challenges = await EnhancedChallengeService.generate_personalized_challenges(
        current_user=current_user,
        count=count
    )
    
    return [
        {
            "id": str(c.id),
            "title": c.title,
            "description": c.description,
            "difficulty": c.difficulty,
            "category": c.category,
            "base_points": c.base_points,
            "duration_days": c.duration_days,
            "ai_generated": c.ai_generated,
            "recommended": True
        }
        for c in challenges
    ]

@router.post("/challenges/{challenge_id}/join", response_model=Dict[str, Any])
async def join_challenge(
    challenge_id: str,
    team_id: Optional[str] = None,
    current_user: User = Depends(get_current_user)
):
    """Join a challenge"""
    
    participation = await EnhancedChallengeService.join_challenge(
        current_user=current_user,
        challenge_id=challenge_id,
        team_id=team_id
    )
    
    return {
        "participation_id": str(participation.id),
        "challenge_id": challenge_id,
        "joined_at": participation.joined_at,
        "message": "Successfully joined challenge"
    }

@router.put("/challenges/{challenge_id}/progress", response_model=Dict[str, Any])
async def update_challenge_progress(
    challenge_id: str,
    progress_data: Dict[str, Any],
    current_user: User = Depends(get_current_user)
):
    """Update progress in a challenge"""
    
    participation, rewards = await EnhancedChallengeService.update_challenge_progress(
        user_id=str(current_user.id),
        challenge_id=challenge_id,
        progress_data=progress_data
    )
    
    return {
        "participation": {
            "progress": participation.current_progress,
            "progress_percentage": participation.progress_percentage,
            "streak": participation.current_streak,
            "points_earned": participation.points_earned,
            "status": participation.status
        },
        "rewards_earned": rewards,
        "message": "Progress updated successfully"
    }

@router.get("/challenges/{challenge_id}/leaderboard", response_model=LeaderboardResponse)
async def get_challenge_leaderboard(
    challenge_id: str,
    leaderboard_type: str = Query("points", regex="^(points|progress|streak|consistency)$"),
    limit: int = Query(50, ge=1, le=100)
):
    """Get challenge leaderboard"""
    
    leaderboard = await EnhancedChallengeService.get_challenge_leaderboard(
        challenge_id=challenge_id,
        leaderboard_type=leaderboard_type,
        limit=limit
    )
    
    return LeaderboardResponse(**leaderboard)

@router.get("/challenges/my", response_model=List[Dict[str, Any]])
async def get_my_challenges(
    status_filter: Optional[str] = Query(None),
    challenge_type: Optional[str] = Query(None),
    limit: int = Query(20, ge=1, le=100),
    skip: int = Query(0, ge=0),
    current_user: User = Depends(get_current_user)
):
    """Get user's challenges"""
    
    challenges = await EnhancedChallengeService.get_user_challenges(
        current_user=current_user,
        status_filter=status_filter,
        challenge_type=challenge_type,
        limit=limit,
        skip=skip
    )
    
    return challenges

@router.get("/challenges/{challenge_id}/details", response_model=Dict[str, Any])
async def get_challenge_details(
    challenge_id: str,
    current_user: User = Depends(get_current_user)
):
    """Get detailed challenge information"""
    
    challenge = await Challenge.get(challenge_id)
    if not challenge:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Challenge not found"
        )
    
    # Get user participation if exists
    participation = await ChallengeParticipation.find_one({
        "challenge_id": challenge_id,
        "user_id": str(current_user.id)
    })
    
    # Get basic stats
    total_participations = await ChallengeParticipation.count_documents({
        "challenge_id": challenge_id
    })
    
    completed_participations = await ChallengeParticipation.count_documents({
        "challenge_id": challenge_id,
        "progress_percentage": {"$gte": 100}
    })
    
    response = {
        "challenge": {
            "id": str(challenge.id),
            "title": challenge.title,
            "description": challenge.description,
            "short_description": challenge.short_description,
            "challenge_type": challenge.challenge_type,
            "category": challenge.category,
            "difficulty": challenge.difficulty,
            "mechanic": challenge.mechanic,
            "target_metric": challenge.target_metric,
            "target_value": challenge.target_value,
            "duration_days": challenge.duration_days,
            "start_date": challenge.start_date,
            "end_date": challenge.end_date,
            "status": challenge.status,
            "base_points": challenge.base_points,
            "difficulty_multiplier": challenge.difficulty_multiplier,
            "icon": challenge.icon,
            "tags": challenge.tags,
            "is_multi_stage": challenge.is_multi_stage,
            "stages": challenge.stages,
            "allow_teams": challenge.allow_teams,
            "enable_leaderboard": challenge.enable_leaderboard,
            "reward_pool": challenge.reward_pool
        },
        "stats": {
            "total_participants": total_participations,
            "completed_participants": completed_participations,
            "completion_rate": (completed_participations / total_participations * 100) if total_participations > 0 else 0,
            "average_progress": challenge.average_progress,
            "engagement_score": challenge.engagement_score
        },
        "user_participation": None,
        "can_join": challenge.is_registration_open() and not participation,
        "time_remaining": (challenge.end_date - datetime.utcnow()).total_seconds() if challenge.end_date > datetime.utcnow() else 0
    }
    
    if participation:
        user_rank = await EnhancedChallengeService._get_user_rank(participation)
        response["user_participation"] = {
            "status": participation.status,
            "joined_at": participation.joined_at,
            "progress": participation.current_progress,
            "progress_percentage": participation.progress_percentage,
            "current_streak": participation.current_streak,
            "best_streak": participation.best_streak,
            "points_earned": participation.points_earned,
            "badges_earned": participation.badges_earned,
            "milestones_achieved": participation.milestone_achievements,
            "rank": user_rank,
            "team_id": participation.team_id
        }
    
    return response

# Team endpoints for team-based challenges
@router.post("/challenges/{challenge_id}/teams", response_model=Dict[str, Any])
async def create_challenge_team(
    challenge_id: str,
    team_data: Dict[str, Any],
    current_user: User = Depends(get_current_user)
):
    """Create a team for a challenge"""
    
    challenge = await Challenge.get(challenge_id)
    if not challenge:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Challenge not found"
        )
    
    if not challenge.allow_teams:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Teams not allowed for this challenge"
        )
    
    team = ChallengeTeam(
        challenge_id=challenge_id,
        name=team_data.get("name"),
        description=team_data.get("description", ""),
        leader_id=str(current_user.id),
        max_members=min(team_data.get("max_members", 5), 10),
        is_public=team_data.get("is_public", True),
        team_color=team_data.get("team_color", "#3B82F6"),
        team_emoji=team_data.get("team_emoji", "⭐")
    )
    
    await team.save()
    
    return {
        "team_id": str(team.id),
        "name": team.name,
        "challenge_id": challenge_id,
        "message": "Team created successfully"
    }

@router.get("/challenges/{challenge_id}/teams", response_model=List[Dict[str, Any]])
async def get_challenge_teams(
    challenge_id: str,
    limit: int = Query(20, ge=1, le=100),
    skip: int = Query(0, ge=0)
):
    """Get teams for a challenge"""
    
    teams = await ChallengeTeam.find({"challenge_id": challenge_id})\
        .sort([("total_progress", -1), ("created_at", -1)])\
        .skip(skip)\
        .limit(limit)\
        .to_list()
    
    return [
        {
            "id": str(team.id),
            "name": team.name,
            "description": team.description,
            "leader_id": team.leader_id,
            "member_count": len(team.member_ids) + 1,  # +1 for leader
            "max_members": team.max_members,
            "total_progress": team.total_progress,
            "average_progress": team.average_progress,
            "team_color": team.team_color,
            "team_emoji": team.team_emoji,
            "is_public": team.is_public,
            "created_at": team.created_at
        }
        for team in teams
    ]

@router.post("/teams/{team_id}/join", response_model=Dict[str, Any])
async def join_team(
    team_id: str,
    current_user: User = Depends(get_current_user)
):
    """Join a challenge team"""
    
    team = await ChallengeTeam.get(team_id)
    if not team:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Team not found"
        )
    
    if team.add_member(str(current_user.id)):
        await team.save()
        return {
            "team_id": str(team.id),
            "message": "Successfully joined team"
        }
    else:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot join team - may be full or you're already a member"
        )