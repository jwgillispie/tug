# app/api/endpoints/seasonal_events.py
from typing import List, Optional, Dict, Any
from fastapi import APIRouter, Depends, HTTPException, Query, status
from datetime import datetime

from ...models.user import User
from ...models.seasonal_event import SeasonalEvent, EventParticipation, EventTeam
from ...services.seasonal_event_service import SeasonalEventService
from ...api.deps import get_current_user
from pydantic import BaseModel, Field

router = APIRouter()

class EventCreateRequest(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    description: str = Field(..., min_length=1, max_length=1000)
    theme: str = Field(default="general")
    event_type: str = Field(default="seasonal")
    start_date: datetime
    end_date: datetime
    early_access_date: Optional[datetime] = None
    requires_premium: bool = False
    max_participants: Optional[int] = None
    point_multiplier: float = Field(default=2.0, ge=1.0, le=5.0)
    enable_team_competitions: bool = False
    color_theme: Optional[Dict[str, str]] = None
    icon: str = Field(default="🎉")
    create_featured_challenges: bool = True

class EventResponse(BaseModel):
    event_id: str
    name: str
    description: str
    theme: str
    event_type: str
    status: str
    start_date: datetime
    end_date: datetime
    point_multiplier: float
    total_participants: int
    color_theme: Dict[str, str]
    icon: str
    can_participate: bool
    is_participating: bool
    requires_premium: bool
    enable_team_competitions: bool
    time_remaining: float
    participation: Optional[Dict[str, Any]] = None

class TeamCreateRequest(BaseModel):
    name: str = Field(..., min_length=1, max_length=50)
    description: str = Field(default="", max_length=200)
    max_members: int = Field(default=5, ge=2, le=10)
    is_public: bool = True
    requires_approval: bool = False
    team_color: str = Field(default="#3B82F6")
    team_emoji: str = Field(default="⭐")
    team_motto: str = Field(default="", max_length=100)

@router.post("/events", response_model=Dict[str, Any])
async def create_seasonal_event(
    event_data: EventCreateRequest,
    current_user: User = Depends(get_current_user)
):
    """Create a new seasonal event (admin only)"""
    
    # Check if user is admin (would need proper role checking)
    if not getattr(current_user, "is_admin", False):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only administrators can create events"
        )
    
    event = await SeasonalEventService.create_seasonal_event(
        current_user=current_user,
        event_data=event_data.model_dump()
    )
    
    return {
        "event_id": event.event_id,
        "name": event.name,
        "message": "Seasonal event created successfully"
    }

@router.get("/events", response_model=List[EventResponse])
async def get_active_events(
    current_user: User = Depends(get_current_user)
):
    """Get all active seasonal events"""
    
    events = await SeasonalEventService.get_active_events(current_user)
    
    return [EventResponse(**event) for event in events]

@router.post("/events/{event_id}/join", response_model=Dict[str, Any])
async def join_event(
    event_id: str,
    team_id: Optional[str] = Query(None),
    current_user: User = Depends(get_current_user)
):
    """Join a seasonal event"""
    
    participation = await SeasonalEventService.join_event(
        current_user=current_user,
        event_id=event_id,
        team_id=team_id
    )
    
    return {
        "event_id": event_id,
        "participation_id": str(participation.id),
        "joined_at": participation.joined_at,
        "team_id": participation.team_id,
        "message": "Successfully joined event"
    }

@router.get("/events/{event_id}/details", response_model=Dict[str, Any])
async def get_event_details(
    event_id: str,
    current_user: User = Depends(get_current_user)
):
    """Get detailed event information"""
    
    event = await SeasonalEvent.find_one({"event_id": event_id})
    if not event:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Event not found"
        )
    
    # Get user participation
    participation = await EventParticipation.find_one({
        "event_id": event_id,
        "user_id": str(current_user.id)
    })
    
    # Get event statistics
    total_participants = await EventParticipation.count_documents({"event_id": event_id})
    total_points_awarded = await EventParticipation.aggregate([
        {"$match": {"event_id": event_id}},
        {"$group": {"_id": None, "total": {"$sum": "$points_earned"}}}
    ]).to_list(1)
    
    total_points = total_points_awarded[0]["total"] if total_points_awarded else 0
    
    response = {
        "event": {
            "id": event.event_id,
            "name": event.name,
            "description": event.description,
            "theme": event.theme,
            "event_type": event.event_type,
            "status": event.status,
            "start_date": event.start_date,
            "end_date": event.end_date,
            "point_multiplier": event.point_multiplier,
            "color_theme": event.color_theme,
            "icon": event.icon,
            "enable_team_competitions": event.enable_team_competitions,
            "participation_levels": event.participation_levels,
            "milestone_rewards": event.milestone_rewards
        },
        "stats": {
            "total_participants": total_participants,
            "total_points_awarded": total_points,
            "average_points_per_user": total_points / total_participants if total_participants > 0 else 0
        },
        "user_participation": None,
        "can_participate": event.can_participate(getattr(current_user, "is_premium", False)),
        "time_remaining": (event.end_date - datetime.utcnow()).total_seconds() if event.end_date > datetime.utcnow() else 0
    }
    
    if participation:
        user_rank = await SeasonalEventService._get_user_event_rank(participation)
        next_milestone = event.get_next_milestone(participation.points_earned)
        
        response["user_participation"] = {
            "joined_at": participation.joined_at,
            "points_earned": participation.points_earned,
            "current_level": participation.current_level,
            "challenges_completed": len(participation.challenges_completed),
            "milestones_achieved": participation.milestones_achieved,
            "badges_earned": participation.badges_earned,
            "rank": user_rank,
            "team_id": participation.team_id,
            "consistency_score": participation.consistency_score,
            "next_milestone": next_milestone
        }
    
    return response

@router.get("/events/{event_id}/leaderboard", response_model=Dict[str, Any])
async def get_event_leaderboard(
    event_id: str,
    leaderboard_type: str = Query("individual", regex="^(individual|team)$"),
    limit: int = Query(50, ge=1, le=100)
):
    """Get event leaderboard"""
    
    leaderboard = await SeasonalEventService.get_event_leaderboard(
        event_id=event_id,
        leaderboard_type=leaderboard_type,
        limit=limit
    )
    
    return leaderboard

@router.post("/events/{event_id}/progress", response_model=Dict[str, Any])
async def update_event_progress(
    event_id: str,
    progress_data: Dict[str, Any],
    current_user: User = Depends(get_current_user)
):
    """Update user's progress in an event (typically called by challenge completion)"""
    
    result = await SeasonalEventService.update_event_progress(
        user_id=str(current_user.id),
        event_id=event_id,
        points_to_add=progress_data.get("points", 0),
        source=progress_data.get("source", "manual")
    )
    
    return result

# Team endpoints for events that support teams
@router.post("/events/{event_id}/teams", response_model=Dict[str, Any])
async def create_event_team(
    event_id: str,
    team_data: TeamCreateRequest,
    current_user: User = Depends(get_current_user)
):
    """Create a team for an event"""
    
    team = await SeasonalEventService.create_event_team(
        current_user=current_user,
        event_id=event_id,
        team_data=team_data.model_dump()
    )
    
    return {
        "team_id": team.team_id,
        "name": team.name,
        "event_id": event_id,
        "message": "Team created successfully"
    }

@router.get("/events/{event_id}/teams", response_model=List[Dict[str, Any]])
async def get_event_teams(
    event_id: str,
    limit: int = Query(20, ge=1, le=100),
    skip: int = Query(0, ge=0)
):
    """Get teams for an event"""
    
    teams = await EventTeam.find({"event_id": event_id})\
        .sort([("total_points", -1), ("created_at", -1)])\
        .skip(skip)\
        .limit(limit)\
        .to_list()
    
    return [
        {
            "id": team.team_id,
            "name": team.name,
            "description": team.description,
            "leader_id": team.leader_id,
            "member_count": len(team.member_ids) + 1,  # +1 for leader
            "max_members": team.max_members,
            "total_points": team.total_points,
            "average_points": team.average_points,
            "team_color": team.team_color,
            "team_emoji": team.team_emoji,
            "team_motto": team.team_motto,
            "is_public": team.is_public,
            "requires_approval": team.requires_approval,
            "created_at": team.created_at
        }
        for team in teams
    ]

@router.post("/teams/{team_id}/join", response_model=Dict[str, Any])
async def join_event_team(
    team_id: str,
    current_user: User = Depends(get_current_user)
):
    """Join an event team"""
    
    team = await EventTeam.find_one({"team_id": team_id})
    if not team:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Team not found"
        )
    
    # Check if user is already in a team for this event
    existing_team = await EventTeam.find_one({
        "$or": [
            {"event_id": team.event_id, "leader_id": str(current_user.id)},
            {"event_id": team.event_id, "member_ids": str(current_user.id)}
        ]
    })
    
    if existing_team:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Already part of a team in this event"
        )
    
    if team.add_member(str(current_user.id)):
        await team.save()
        
        # Update user's participation to include team
        participation = await EventParticipation.find_one({
            "event_id": team.event_id,
            "user_id": str(current_user.id)
        })
        
        if participation:
            participation.team_id = team_id
            await participation.save()
        
        return {
            "team_id": team_id,
            "team_name": team.name,
            "message": "Successfully joined team"
        }
    else:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot join team - may be full or require approval"
        )

@router.get("/events/{event_id}/my-progress", response_model=Dict[str, Any])
async def get_my_event_progress(
    event_id: str,
    current_user: User = Depends(get_current_user)
):
    """Get detailed progress for user in a specific event"""
    
    participation = await EventParticipation.find_one({
        "event_id": event_id,
        "user_id": str(current_user.id)
    })
    
    if not participation:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Not participating in this event"
        )
    
    event = await SeasonalEvent.find_one({"event_id": event_id})
    if not event:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Event not found"
        )
    
    # Calculate progress analytics
    total_days = (event.end_date - event.start_date).days
    days_participated = len(participation.daily_challenges_completed)
    participation_rate = (days_participated / total_days * 100) if total_days > 0 else 0
    
    # Get rank
    user_rank = await SeasonalEventService._get_user_event_rank(participation)
    
    # Get next milestone
    next_milestone = event.get_next_milestone(participation.points_earned)
    
    return {
        "event_id": event_id,
        "event_name": event.name,
        "participation": {
            "joined_at": participation.joined_at,
            "points_earned": participation.points_earned,
            "current_level": participation.current_level,
            "rank": user_rank,
            "team_id": participation.team_id
        },
        "progress": {
            "challenges_completed": len(participation.challenges_completed),
            "daily_challenges_by_date": participation.daily_challenges_completed,
            "milestones_achieved": participation.milestones_achieved,
            "badges_earned": participation.badges_earned,
            "consistency_score": participation.consistency_score,
            "participation_rate": participation_rate,
            "streak_during_event": participation.streak_during_event,
            "best_daily_score": participation.best_daily_score
        },
        "next_milestone": next_milestone,
        "social": {
            "social_shares": participation.social_shares,
            "encouragements_given": participation.encouragements_given,
            "encouragements_received": participation.encouragements_received
        }
    }