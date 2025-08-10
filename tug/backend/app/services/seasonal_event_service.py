# app/services/seasonal_event_service.py
import logging
from typing import List, Optional, Dict, Any
from datetime import datetime, timedelta
from fastapi import HTTPException, status
from bson import ObjectId
import asyncio

from ..models.user import User
from ..models.seasonal_event import SeasonalEvent, EventParticipation, EventTeam, EventType, EventStatus, ParticipationLevel
from ..models.challenge import Challenge, ChallengeParticipation
from ..models.gamification import UserProgression, Badge, UserBadge
from ..services.notification_service import NotificationService
from ..services.gamification_service import GamificationService
from ..services.enhanced_challenge_service import EnhancedChallengeService

logger = logging.getLogger(__name__)

class SeasonalEventService:
    """Service for managing seasonal events and time-limited challenges"""
    
    @staticmethod
    async def create_seasonal_event(
        current_user: User,
        event_data: Dict[str, Any]
    ) -> SeasonalEvent:
        """Create a new seasonal event"""
        try:
            # Validate event data
            name = event_data.get("name", "").strip()
            if not name or len(name) > 100:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Event name must be 1-100 characters"
                )
            
            # Parse dates
            start_date = event_data.get("start_date")
            end_date = event_data.get("end_date")
            
            if isinstance(start_date, str):
                start_date = datetime.fromisoformat(start_date.replace('Z', '+00:00'))
            if isinstance(end_date, str):
                end_date = datetime.fromisoformat(end_date.replace('Z', '+00:00'))
            
            if start_date >= end_date:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Start date must be before end date"
                )
            
            # Create event
            event = SeasonalEvent(
                event_id=f"event_{int(datetime.utcnow().timestamp())}",
                name=name,
                description=event_data.get("description", ""),
                theme=event_data.get("theme", "general"),
                event_type=EventType(event_data.get("event_type", "seasonal")),
                start_date=start_date,
                end_date=end_date,
                early_access_date=event_data.get("early_access_date"),
                requires_premium=event_data.get("requires_premium", False),
                max_participants=event_data.get("max_participants"),
                point_multiplier=float(event_data.get("point_multiplier", 2.0)),
                enable_team_competitions=event_data.get("enable_team_competitions", False),
                color_theme=event_data.get("color_theme", {
                    "primary": "#FF6B35", 
                    "secondary": "#F7931E", 
                    "accent": "#FFD23F"
                }),
                icon=event_data.get("icon", "🎉")
            )
            
            # Setup participation levels
            if "participation_levels" in event_data:
                event.participation_levels = event_data["participation_levels"]
            
            # Setup milestone rewards
            event.milestone_rewards = event_data.get("milestone_rewards", [
                {"points": 100, "reward": {"type": "badge", "badge_id": "event_participant"}},
                {"points": 500, "reward": {"type": "points", "amount": 250}},
                {"points": 1000, "reward": {"type": "badge", "badge_id": "event_achiever"}},
                {"points": 2500, "reward": {"type": "premium_benefit", "benefit": "double_xp_24h"}},
                {"points": 5000, "reward": {"type": "badge", "badge_id": "event_champion"}}
            ])
            
            await event.save()
            
            # Create featured challenges if specified
            if event_data.get("create_featured_challenges", True):
                featured_challenges = await SeasonalEventService._create_featured_challenges(event)
                event.featured_challenges = [str(c.id) for c in featured_challenges]
                await event.save()
            
            logger.info(f"Seasonal event created: {event.event_id}")
            return event
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error creating seasonal event: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create seasonal event"
            )
    
    @staticmethod
    async def join_event(current_user: User, event_id: str, team_id: Optional[str] = None) -> EventParticipation:
        """Join a seasonal event"""
        try:
            event = await SeasonalEvent.find_one({"event_id": event_id})
            if not event:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Event not found"
                )
            
            # Check if user can participate
            user_premium = getattr(current_user, "is_premium", False)
            if not event.can_participate(user_premium):
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Cannot participate in this event"
                )
            
            # Check if already participating
            existing = await EventParticipation.find_one({
                "event_id": event_id,
                "user_id": str(current_user.id)
            })
            
            if existing:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Already participating in this event"
                )
            
            # Handle team participation
            if team_id:
                team = await EventTeam.find_one({
                    "event_id": event_id,
                    "team_id": team_id
                })
                if not team:
                    raise HTTPException(
                        status_code=status.HTTP_404_NOT_FOUND,
                        detail="Team not found"
                    )
                
                # Check if team has space
                if len(team.member_ids) >= team.max_members:
                    raise HTTPException(
                        status_code=status.HTTP_400_BAD_REQUEST,
                        detail="Team is full"
                    )
                
                # Add to team
                team.add_member(str(current_user.id))
                await team.save()
            
            # Create participation record
            participation = EventParticipation(
                event_id=event_id,
                user_id=str(current_user.id),
                team_id=team_id
            )
            
            await participation.save()
            
            # Update event participant count
            event.total_participants += 1
            event.active_participants += 1
            await event.save()
            
            # Auto-join featured challenges if enabled
            if event.auto_enroll_eligible:
                await SeasonalEventService._auto_join_featured_challenges(current_user, event)
            
            # Award participation XP
            user_progression = await GamificationService._get_or_create_user_progression(current_user)
            if not user_progression:
                user_progression = await GamificationService.initialize_user_gamification(current_user)
            
            user_progression.add_xp(50, "event_join")
            await user_progression.save()
            
            logger.info(f"User {current_user.id} joined event {event_id}")
            return participation
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error joining event: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to join event"
            )
    
    @staticmethod
    async def update_event_progress(
        user_id: str,
        event_id: str,
        points_to_add: int,
        source: str = "challenge"
    ) -> Dict[str, Any]:
        """Update user's progress in a seasonal event"""
        try:
            participation = await EventParticipation.find_one({
                "event_id": event_id,
                "user_id": user_id
            })
            
            if not participation:
                return {"error": "Participation not found"}
            
            event = await SeasonalEvent.find_one({"event_id": event_id})
            if not event or not event.is_active():
                return {"error": "Event not active"}
            
            # Apply event point multiplier
            multiplied_points = int(points_to_add * event.point_multiplier)
            old_level = participation.current_level
            
            # Add points and update level
            participation.add_points(multiplied_points, source)
            new_level = event.get_participation_level(participation.points_earned)
            participation.current_level = new_level
            
            rewards_earned = []
            
            # Check for level up rewards
            if new_level != old_level:
                level_rewards = await SeasonalEventService._award_level_up_rewards(
                    user_id, event, participation, new_level
                )
                rewards_earned.extend(level_rewards)
            
            # Check for milestone rewards
            milestone_rewards = await SeasonalEventService._check_milestone_rewards(
                user_id, event, participation, multiplied_points
            )
            rewards_earned.extend(milestone_rewards)
            
            await participation.save()
            
            # Update user's regular progression
            user = await User.get(user_id)
            if user:
                user_progression = await GamificationService._get_or_create_user_progression(user)
                if not user_progression:
                    user_progression = await GamificationService.initialize_user_gamification(user)
                
                # Award XP for event participation
                event_xp = multiplied_points // 5  # XP = points / 5
                user_progression.add_xp(event_xp, f"seasonal_event_{source}")
                await user_progression.save()
            
            # Update team progress if in a team
            if participation.team_id:
                await SeasonalEventService._update_team_progress(participation.team_id, event_id)
            
            return {
                "points_added": multiplied_points,
                "total_points": participation.points_earned,
                "current_level": new_level,
                "level_up": new_level != old_level,
                "rewards_earned": rewards_earned
            }
            
        except Exception as e:
            logger.error(f"Error updating event progress: {e}", exc_info=True)
            return {"error": "Failed to update progress"}
    
    @staticmethod
    async def get_active_events(user: User) -> List[Dict[str, Any]]:
        """Get all active seasonal events"""
        try:
            now = datetime.utcnow()
            user_premium = getattr(user, "is_premium", False)
            
            # Get active events
            events = await SeasonalEvent.find({
                "status": {"$in": [EventStatus.ACTIVE, EventStatus.ENDING_SOON]},
                "start_date": {"$lte": now},
                "end_date": {"$gte": now}
            }).sort([("start_date", 1)]).to_list()
            
            # Get user participations
            event_ids = [e.event_id for e in events]
            participations = await EventParticipation.find({
                "event_id": {"$in": event_ids},
                "user_id": str(user.id)
            }).to_list()
            participation_map = {p.event_id: p for p in participations}
            
            # Format response
            active_events = []
            for event in events:
                # Check if user can participate
                can_participate = event.can_participate(user_premium)
                participation = participation_map.get(event.event_id)
                
                event_data = {
                    "event_id": event.event_id,
                    "name": event.name,
                    "description": event.description,
                    "theme": event.theme,
                    "event_type": event.event_type,
                    "status": event.status,
                    "start_date": event.start_date,
                    "end_date": event.end_date,
                    "point_multiplier": event.point_multiplier,
                    "total_participants": event.total_participants,
                    "color_theme": event.color_theme,
                    "icon": event.icon,
                    "can_participate": can_participate,
                    "is_participating": participation is not None,
                    "requires_premium": event.requires_premium,
                    "enable_team_competitions": event.enable_team_competitions,
                    "time_remaining": (event.end_date - now).total_seconds() if event.end_date > now else 0
                }
                
                # Add participation data if participating
                if participation:
                    event_data["participation"] = {
                        "points_earned": participation.points_earned,
                        "current_level": participation.current_level,
                        "challenges_completed": len(participation.challenges_completed),
                        "team_id": participation.team_id,
                        "rank": await SeasonalEventService._get_user_event_rank(participation)
                    }
                
                active_events.append(event_data)
            
            return active_events
            
        except Exception as e:
            logger.error(f"Error getting active events: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to get active events"
            )
    
    @staticmethod
    async def get_event_leaderboard(
        event_id: str,
        leaderboard_type: str = "individual",
        limit: int = 50
    ) -> Dict[str, Any]:
        """Get event leaderboard"""
        try:
            event = await SeasonalEvent.find_one({"event_id": event_id})
            if not event:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Event not found"
                )
            
            if leaderboard_type == "team" and event.enable_team_competitions:
                return await SeasonalEventService._get_team_leaderboard(event_id, limit)
            else:
                return await SeasonalEventService._get_individual_leaderboard(event_id, limit)
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error getting event leaderboard: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to get event leaderboard"
            )
    
    @staticmethod
    async def create_event_team(
        current_user: User,
        event_id: str,
        team_data: Dict[str, Any]
    ) -> EventTeam:
        """Create a team for an event"""
        try:
            event = await SeasonalEvent.find_one({"event_id": event_id})
            if not event:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Event not found"
                )
            
            if not event.enable_team_competitions:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Teams not enabled for this event"
                )
            
            # Validate team data
            name = team_data.get("name", "").strip()
            if not name or len(name) > 50:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Team name must be 1-50 characters"
                )
            
            # Check if user already has a team in this event
            existing_team = await EventTeam.find_one({
                "$or": [
                    {"event_id": event_id, "leader_id": str(current_user.id)},
                    {"event_id": event_id, "member_ids": str(current_user.id)}
                ]
            })
            
            if existing_team:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Already part of a team in this event"
                )
            
            # Create team
            team = EventTeam(
                event_id=event_id,
                team_id=f"team_{int(datetime.utcnow().timestamp())}_{str(current_user.id)[-4:]}",
                name=name,
                description=team_data.get("description", ""),
                leader_id=str(current_user.id),
                max_members=min(team_data.get("max_members", 5), 10),  # Cap at 10
                is_public=team_data.get("is_public", True),
                requires_approval=team_data.get("requires_approval", False),
                team_color=team_data.get("team_color", "#3B82F6"),
                team_emoji=team_data.get("team_emoji", "⭐"),
                team_motto=team_data.get("team_motto", "")
            )
            
            await team.save()
            
            logger.info(f"Event team created: {team.team_id} for event {event_id}")
            return team
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error creating event team: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create event team"
            )
    
    @staticmethod
    async def _create_featured_challenges(event: SeasonalEvent) -> List[Challenge]:
        """Create featured challenges for a seasonal event"""
        challenges = []
        
        try:
            # Define challenge templates based on event theme
            challenge_templates = SeasonalEventService._get_theme_challenges(event.theme)
            
            for template in challenge_templates:
                # Customize challenge for the event
                challenge_data = {
                    **template,
                    "title": f"{event.name}: {template['title']}",
                    "start_date": event.start_date + timedelta(hours=1),  # Start 1 hour after event
                    "requires_premium": event.requires_premium,
                    "is_seasonal": True,
                    "seasonal_theme": event.theme,
                    "tags": template.get("tags", []) + [event.theme, "seasonal"]
                }
                
                # Create system user for challenge creation (would need proper implementation)
                system_user = await User.find_one({"username": "system"})  # Placeholder
                if system_user:
                    challenge = await EnhancedChallengeService.create_challenge(
                        system_user, challenge_data, is_ai_generated=False
                    )
                    challenges.append(challenge)
            
            return challenges
            
        except Exception as e:
            logger.error(f"Error creating featured challenges: {e}")
            return []
    
    @staticmethod
    def _get_theme_challenges(theme: str) -> List[Dict[str, Any]]:
        """Get challenge templates based on event theme"""
        
        theme_challenges = {
            "summer": [
                {
                    "title": "Summer Wellness Challenge",
                    "description": "Focus on outdoor activities and wellness this summer",
                    "challenge_type": "individual",
                    "category": "health",
                    "difficulty": "medium",
                    "target_metric": "activities",
                    "target_value": 21,
                    "duration_days": 21,
                    "tags": ["outdoor", "wellness", "summer"]
                },
                {
                    "title": "Hydration Hero",
                    "description": "Track your water intake daily",
                    "challenge_type": "individual",
                    "category": "health",
                    "difficulty": "easy",
                    "target_metric": "days",
                    "target_value": 14,
                    "duration_days": 14,
                    "tags": ["hydration", "health"]
                }
            ],
            "winter": [
                {
                    "title": "Winter Mindfulness",
                    "description": "Practice mindfulness during the winter season",
                    "challenge_type": "individual",
                    "category": "mindfulness",
                    "difficulty": "medium",
                    "target_metric": "sessions",
                    "target_value": 30,
                    "duration_days": 30,
                    "tags": ["mindfulness", "meditation", "winter"]
                }
            ],
            "new_year": [
                {
                    "title": "New Year, New Habits",
                    "description": "Build positive habits for the new year",
                    "challenge_type": "individual",
                    "category": "personal_growth",
                    "difficulty": "hard",
                    "target_metric": "habits",
                    "target_value": 3,
                    "duration_days": 30,
                    "tags": ["habits", "new_year", "growth"]
                }
            ]
        }
        
        return theme_challenges.get(theme, [
            {
                "title": "Seasonal Challenge",
                "description": "A general seasonal challenge",
                "challenge_type": "individual",
                "category": "personal_growth",
                "difficulty": "medium",
                "target_metric": "activities",
                "target_value": 14,
                "duration_days": 14,
                "tags": ["seasonal"]
            }
        ])
    
    @staticmethod
    async def _auto_join_featured_challenges(user: User, event: SeasonalEvent):
        """Auto-join user to featured challenges"""
        try:
            for challenge_id in event.featured_challenges:
                try:
                    await EnhancedChallengeService.join_challenge(user, challenge_id)
                except Exception as e:
                    logger.warning(f"Failed to auto-join challenge {challenge_id}: {e}")
                    continue
        except Exception as e:
            logger.error(f"Error auto-joining featured challenges: {e}")
    
    @staticmethod
    async def _award_level_up_rewards(
        user_id: str,
        event: SeasonalEvent,
        participation: EventParticipation,
        new_level: ParticipationLevel
    ) -> List[Dict[str, Any]]:
        """Award rewards for leveling up in event"""
        rewards = []
        
        try:
            level_config = event.participation_levels.get(new_level)
            if not level_config:
                return rewards
            
            level_rewards = level_config.get("rewards", [])
            
            for reward_config in level_rewards:
                reward_type = reward_config.get("type")
                
                if reward_type == "badge":
                    badge_id = reward_config.get("badge_id", f"event_{event.theme}_{new_level.value}")
                    if await GamificationService._award_badge(user_id, badge_id, f"event_{event.event_id}"):
                        rewards.append({
                            "type": "badge",
                            "badge_id": badge_id,
                            "level": new_level.value
                        })
                
                elif reward_type == "points":
                    points = reward_config.get("amount", 100)
                    user = await User.get(user_id)
                    if user:
                        user_progression = await GamificationService._get_or_create_user_progression(user)
                        if user_progression:
                            user_progression.add_points(points, f"event_level_{new_level.value}")
                            await user_progression.save()
                    
                    rewards.append({
                        "type": "points",
                        "amount": points,
                        "level": new_level.value
                    })
            
            return rewards
            
        except Exception as e:
            logger.error(f"Error awarding level up rewards: {e}")
            return rewards
    
    @staticmethod
    async def _check_milestone_rewards(
        user_id: str,
        event: SeasonalEvent,
        participation: EventParticipation,
        points_added: int
    ) -> List[Dict[str, Any]]:
        """Check and award milestone rewards"""
        rewards = []
        
        try:
            old_points = participation.points_earned - points_added
            
            for milestone in event.milestone_rewards:
                milestone_points = milestone.get("points", 0)
                
                # Check if milestone was just reached
                if old_points < milestone_points <= participation.points_earned:
                    milestone_id = f"milestone_{milestone_points}"
                    
                    if milestone_id not in participation.milestones_achieved:
                        reward_data = milestone.get("reward", {})
                        participation.achieve_milestone(milestone_id, reward_data)
                        
                        # Apply reward
                        if reward_data.get("type") == "badge":
                            badge_id = reward_data.get("badge_id", f"event_milestone_{milestone_points}")
                            if await GamificationService._award_badge(user_id, badge_id, f"event_{event.event_id}"):
                                rewards.append({
                                    "type": "badge",
                                    "badge_id": badge_id,
                                    "milestone": milestone_points
                                })
                        
                        elif reward_data.get("type") == "points":
                            bonus_points = reward_data.get("amount", 50)
                            user = await User.get(user_id)
                            if user:
                                user_progression = await GamificationService._get_or_create_user_progression(user)
                                if user_progression:
                                    user_progression.add_points(bonus_points, f"event_milestone_{milestone_points}")
                                    await user_progression.save()
                            
                            rewards.append({
                                "type": "points",
                                "amount": bonus_points,
                                "milestone": milestone_points
                            })
            
            return rewards
            
        except Exception as e:
            logger.error(f"Error checking milestone rewards: {e}")
            return rewards
    
    @staticmethod
    async def _get_individual_leaderboard(event_id: str, limit: int) -> Dict[str, Any]:
        """Get individual participant leaderboard for event"""
        try:
            # Get top participants
            participations = await EventParticipation.find({"event_id": event_id})\
                .sort([("points_earned", -1), ("joined_at", 1)])\
                .limit(limit)\
                .to_list()
            
            # Get user details
            user_ids = [p.user_id for p in participations]
            users = await User.find({"_id": {"$in": [ObjectId(uid) for uid in user_ids]}}).to_list()
            user_map = {str(u.id): u for u in users}
            
            # Build leaderboard
            entries = []
            for rank, participation in enumerate(participations, 1):
                user = user_map.get(participation.user_id)
                if user:
                    entry = {
                        "rank": rank,
                        "user": {
                            "id": participation.user_id,
                            "display_name": getattr(user, "display_name", "Unknown"),
                            "username": getattr(user, "username", None)
                        },
                        "points": participation.points_earned,
                        "level": participation.current_level,
                        "challenges_completed": len(participation.challenges_completed),
                        "consistency_score": participation.consistency_score,
                        "team_id": participation.team_id
                    }
                    entries.append(entry)
            
            return {
                "type": "individual",
                "event_id": event_id,
                "entries": entries,
                "total_participants": len(entries)
            }
            
        except Exception as e:
            logger.error(f"Error getting individual leaderboard: {e}")
            return {"type": "individual", "entries": [], "error": "Failed to load leaderboard"}
    
    @staticmethod
    async def _get_team_leaderboard(event_id: str, limit: int) -> Dict[str, Any]:
        """Get team leaderboard for event"""
        try:
            # Get teams
            teams = await EventTeam.find({"event_id": event_id})\
                .sort([("total_points", -1), ("created_at", 1)])\
                .limit(limit)\
                .to_list()
            
            # Build leaderboard
            entries = []
            for rank, team in enumerate(teams, 1):
                entry = {
                    "rank": rank,
                    "team": {
                        "id": team.team_id,
                        "name": team.name,
                        "emoji": team.team_emoji,
                        "color": team.team_color
                    },
                    "total_points": team.total_points,
                    "average_points": team.average_points,
                    "member_count": team.get_member_count(),
                    "challenges_completed": team.challenges_completed
                }
                entries.append(entry)
            
            return {
                "type": "team",
                "event_id": event_id,
                "entries": entries,
                "total_teams": len(entries)
            }
            
        except Exception as e:
            logger.error(f"Error getting team leaderboard: {e}")
            return {"type": "team", "entries": [], "error": "Failed to load leaderboard"}
    
    @staticmethod
    async def _get_user_event_rank(participation: EventParticipation) -> Optional[int]:
        """Get user's rank in event"""
        try:
            # Count participants with higher points
            higher_count = await EventParticipation.count_documents({
                "event_id": participation.event_id,
                "points_earned": {"$gt": participation.points_earned}
            })
            
            return higher_count + 1
            
        except Exception as e:
            logger.error(f"Error getting user event rank: {e}")
            return None
    
    @staticmethod
    async def _update_team_progress(team_id: str, event_id: str):
        """Update team progress based on member participations"""
        try:
            team = await EventTeam.find_one({"team_id": team_id, "event_id": event_id})
            if not team:
                return
            
            # Get all member participations
            all_member_ids = [team.leader_id] + team.member_ids
            participations = await EventParticipation.find({
                "event_id": event_id,
                "user_id": {"$in": all_member_ids}
            }).to_list()
            
            # Calculate team metrics
            team.calculate_team_metrics(participations)
            await team.save()
            
        except Exception as e:
            logger.error(f"Error updating team progress: {e}")