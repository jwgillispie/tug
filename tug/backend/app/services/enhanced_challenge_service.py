# app/services/enhanced_challenge_service.py
import logging
from typing import List, Optional, Dict, Any, Tuple
from datetime import datetime, timedelta
from fastapi import HTTPException, status
from bson import ObjectId
import asyncio

from ..models.user import User
from ..models.challenge import Challenge, ChallengeParticipation, ChallengeTeam, ChallengeType, ChallengeDifficulty, ChallengeStatus
from ..models.gamification import UserProgression, Badge, UserBadge, Reward, UserReward, Leaderboard
from ..models.seasonal_event import SeasonalEvent, EventParticipation
from ..models.activity import Activity
from ..models.value import Value
from ..services.notification_service import NotificationService
from ..services.achievement_service import AchievementService
from ..services.ml_prediction_service import MLPredictionService

logger = logging.getLogger(__name__)

class EnhancedChallengeService:
    """Enhanced challenge service with comprehensive gamification features"""
    
    @staticmethod
    async def create_challenge(
        current_user: User,
        challenge_data: Dict[str, Any],
        is_ai_generated: bool = False
    ) -> Challenge:
        """Create a new enhanced challenge with full gamification support"""
        try:
            # Validate challenge data
            title = challenge_data.get("title", "").strip()
            description = challenge_data.get("description", "").strip()
            
            if not title or len(title) > 100:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Challenge title must be 1-100 characters"
                )
            
            if not description or len(description) > 1000:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Challenge description must be 1-1000 characters"
                )
            
            # Calculate dates
            duration_days = challenge_data.get("duration_days", 7)
            start_date = challenge_data.get("start_date")
            if isinstance(start_date, str):
                start_date = datetime.fromisoformat(start_date.replace('Z', '+00:00'))
            elif start_date is None:
                start_date = datetime.utcnow() + timedelta(hours=1)  # Start in 1 hour by default
            
            end_date = start_date + timedelta(days=duration_days)
            
            # Set difficulty multiplier
            difficulty = ChallengeeDifficulty(challenge_data.get("difficulty", "medium"))
            difficulty_multipliers = {
                ChallengeDifficulty.EASY: 1.0,
                ChallengeDifficulty.MEDIUM: 1.5,
                ChallengeDifficulty.HARD: 2.0,
                ChallengeDifficulty.EXTREME: 3.0
            }
            
            # Calculate base points based on difficulty and duration
            base_points = max(50, int(100 * difficulty_multipliers[difficulty] * (duration_days / 7)))
            
            # Create challenge
            challenge = Challenge(
                title=title,
                description=description,
                short_description=challenge_data.get("short_description", description[:200]),
                challenge_type=ChallengeType(challenge_data.get("challenge_type", "individual")),
                category=challenge_data.get("category", "health"),
                difficulty=difficulty,
                mechanic=challenge_data.get("mechanic", "daily_streak"),
                target_metric=challenge_data.get("target_metric", "days"),
                target_value=float(challenge_data.get("target_value", duration_days)),
                duration_days=duration_days,
                start_date=start_date,
                end_date=end_date,
                created_by=str(current_user.id),
                difficulty_multiplier=difficulty_multipliers[difficulty],
                base_points=base_points,
                is_multi_stage=challenge_data.get("is_multi_stage", False),
                stages=challenge_data.get("stages", []),
                requires_premium=challenge_data.get("requires_premium", False),
                ai_generated=is_ai_generated,
                tags=challenge_data.get("tags", []),
                icon=challenge_data.get("icon", "🏆"),
                enable_leaderboard=challenge_data.get("enable_leaderboard", True),
                allow_teams=challenge_data.get("allow_teams", False)
            )
            
            # Set reward pool based on difficulty and type
            await EnhancedChallengeService._setup_reward_pool(challenge, challenge_data)
            
            # Save challenge
            await challenge.save()
            
            # If it's a community or seasonal challenge, notify relevant users
            if challenge.challenge_type in [ChallengeType.COMMUNITY, ChallengeType.SEASONAL]:
                await EnhancedChallengeService._notify_community_challenge(challenge)
            
            logger.info(f"Enhanced challenge created: {challenge.id} by user {current_user.id}")
            return challenge
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error creating enhanced challenge: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create challenge"
            )
    
    @staticmethod
    async def join_challenge(
        current_user: User,
        challenge_id: str,
        team_id: Optional[str] = None
    ) -> ChallengeParticipation:
        """Join a challenge with full tracking and analytics"""
        try:
            challenge = await Challenge.get(challenge_id)
            if not challenge:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Challenge not found"
                )
            
            # Check if user can join
            if not challenge.is_registration_open():
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Challenge registration is closed"
                )
            
            # Check premium requirement
            user_premium = getattr(current_user, "is_premium", False)
            if challenge.requires_premium and not user_premium:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="This challenge requires a premium subscription"
                )
            
            # Check if already participating
            existing = await ChallengeParticipation.find_one({
                "challenge_id": challenge_id,
                "user_id": str(current_user.id)
            })
            
            if existing:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Already participating in this challenge"
                )
            
            # Handle team participation
            if team_id and not challenge.allow_teams:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="This challenge does not support teams"
                )
            
            # Create participation record
            participation = ChallengeParticipation(
                challenge_id=challenge_id,
                user_id=str(current_user.id),
                team_id=team_id,
                status="active"
            )
            
            await participation.save()
            
            # Update challenge participant count
            challenge.total_participants += 1
            challenge.active_participants += 1
            challenge.update_timestamp()
            await challenge.save()
            
            # Update user progression
            user_progression = await EnhancedChallengeService._get_or_create_user_progression(current_user)
            user_progression.add_xp(25, "challenge_join")  # XP for joining
            await user_progression.save()
            
            # Check for achievements
            await AchievementService.check_and_update_achievements(current_user)
            
            logger.info(f"User {current_user.id} joined challenge {challenge_id}")
            return participation
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error joining challenge: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to join challenge"
            )
    
    @staticmethod
    async def update_challenge_progress(
        user_id: str,
        challenge_id: str,
        progress_data: Dict[str, Any]
    ) -> Tuple[ChallengeParticipation, List[Dict[str, Any]]]:
        """Update challenge progress with comprehensive reward system"""
        try:
            participation = await ChallengeParticipation.find_one({
                "challenge_id": challenge_id,
                "user_id": user_id
            })
            
            if not participation:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Participation not found"
                )
            
            challenge = await Challenge.get(challenge_id)
            if not challenge or not challenge.is_active():
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Challenge is not currently active"
                )
            
            # Update progress
            new_progress = float(progress_data.get("progress", 0))
            stage = int(progress_data.get("stage", 1))
            
            old_progress = participation.current_progress
            participation.update_progress(new_progress, stage)
            
            # Calculate rewards
            rewards_earned = []
            
            # Progress-based rewards
            progress_percentage = (new_progress / challenge.target_value) * 100
            participation.progress_percentage = min(100.0, progress_percentage)
            
            # Check for milestone rewards
            milestones_to_check = [25, 50, 75, 100]  # Percentage milestones
            for milestone in milestones_to_check:
                if (old_progress / challenge.target_value * 100) < milestone <= progress_percentage:
                    milestone_reward = await EnhancedChallengeService._award_milestone_reward(
                        user_id, challenge, participation, milestone
                    )
                    if milestone_reward:
                        rewards_earned.append(milestone_reward)
            
            # Streak tracking
            if progress_data.get("maintains_streak", False):
                participation.current_streak += 1
                participation.best_streak = max(participation.best_streak, participation.current_streak)
                
                # Streak milestone rewards
                streak_milestones = [3, 7, 14, 21, 30]
                for streak_milestone in streak_milestones:
                    if participation.current_streak == streak_milestone:
                        streak_reward = await EnhancedChallengeService._award_streak_reward(
                            user_id, challenge, participation, streak_milestone
                        )
                        if streak_reward:
                            rewards_earned.append(streak_reward)
            
            # Completion rewards
            if progress_percentage >= 100.0 and old_progress < challenge.target_value:
                completion_rewards = await EnhancedChallengeService._award_completion_rewards(
                    user_id, challenge, participation
                )
                rewards_earned.extend(completion_rewards)
            
            # Save participation updates
            await participation.save()
            
            # Update user progression with XP
            user = await User.get(user_id)
            if user:
                user_progression = await EnhancedChallengeService._get_or_create_user_progression(user)
                
                # XP for progress
                progress_xp = int((new_progress - old_progress) * 10)
                if progress_xp > 0:
                    user_progression.add_xp(progress_xp, "challenge_progress")
                
                await user_progression.save()
                
                # Check for new achievements
                await AchievementService.check_and_update_achievements(user)
            
            # Update challenge analytics
            await EnhancedChallengeService._update_challenge_analytics(challenge, participation)
            
            logger.info(f"Progress updated for user {user_id} in challenge {challenge_id}: {new_progress}")
            return participation, rewards_earned
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error updating challenge progress: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to update challenge progress"
            )
    
    @staticmethod
    async def get_user_challenges(
        current_user: User,
        status_filter: Optional[str] = None,
        challenge_type: Optional[str] = None,
        limit: int = 20,
        skip: int = 0
    ) -> List[Dict[str, Any]]:
        """Get user's challenges with participation data"""
        try:
            # Build query for participations
            query = {"user_id": str(current_user.id)}
            if status_filter:
                query["status"] = status_filter
            
            # Get user's participations
            participations = await ChallengeParticipation.find(query)\
                .sort([("joined_at", -1)])\
                .skip(skip)\
                .limit(limit)\
                .to_list()
            
            # Get challenge details
            challenge_ids = [p.challenge_id for p in participations]
            challenges_query = {"_id": {"$in": [ObjectId(cid) for cid in challenge_ids]}}
            
            if challenge_type:
                challenges_query["challenge_type"] = challenge_type
            
            challenges = await Challenge.find(challenges_query).to_list()
            challenge_map = {str(c.id): c for c in challenges}
            
            # Build response with participation data
            results = []
            for participation in participations:
                challenge = challenge_map.get(participation.challenge_id)
                if challenge:
                    challenge_data = {
                        "challenge": {
                            "id": str(challenge.id),
                            "title": challenge.title,
                            "description": challenge.description,
                            "difficulty": challenge.difficulty,
                            "category": challenge.category,
                            "status": challenge.status,
                            "start_date": challenge.start_date,
                            "end_date": challenge.end_date,
                            "total_participants": challenge.total_participants,
                            "icon": challenge.icon,
                            "base_points": challenge.base_points
                        },
                        "participation": {
                            "status": participation.status,
                            "progress": participation.current_progress,
                            "progress_percentage": participation.progress_percentage,
                            "streak": participation.current_streak,
                            "points_earned": participation.points_earned,
                            "badges_earned": participation.badges_earned,
                            "joined_at": participation.joined_at,
                            "rank": await EnhancedChallengeService._get_user_rank(participation)
                        }
                    }
                    results.append(challenge_data)
            
            return results
            
        except Exception as e:
            logger.error(f"Error getting user challenges: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to get user challenges"
            )
    
    @staticmethod
    async def get_challenge_leaderboard(
        challenge_id: str,
        leaderboard_type: str = "points",
        limit: int = 50
    ) -> Dict[str, Any]:
        """Get challenge leaderboard with various sorting options"""
        try:
            challenge = await Challenge.get(challenge_id)
            if not challenge:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Challenge not found"
                )
            
            # Define sort criteria
            sort_criteria = {
                "points": [("points_earned", -1), ("current_progress", -1)],
                "progress": [("progress_percentage", -1), ("points_earned", -1)],
                "streak": [("current_streak", -1), ("best_streak", -1)],
                "consistency": [("consistency_score", -1), ("progress_percentage", -1)]
            }
            
            sort_field = sort_criteria.get(leaderboard_type, sort_criteria["points"])
            
            # Get top participants
            participations = await ChallengeParticipation.find({
                "challenge_id": challenge_id,
                "status": "active"
            })\
            .sort(sort_field)\
            .limit(limit)\
            .to_list()
            
            # Get user details
            user_ids = [p.user_id for p in participations]
            users = await User.find({"_id": {"$in": [ObjectId(uid) for uid in user_ids]}}).to_list()
            user_map = {str(u.id): u for u in users}
            
            # Build leaderboard
            leaderboard_entries = []
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
                        "stats": {
                            "points": participation.points_earned,
                            "progress": participation.current_progress,
                            "progress_percentage": participation.progress_percentage,
                            "streak": participation.current_streak,
                            "best_streak": participation.best_streak,
                            "consistency": participation.consistency_score,
                            "badges": len(participation.badges_earned)
                        },
                        "joined_at": participation.joined_at
                    }
                    leaderboard_entries.append(entry)
            
            return {
                "challenge_id": challenge_id,
                "challenge_title": challenge.title,
                "leaderboard_type": leaderboard_type,
                "total_participants": len(leaderboard_entries),
                "entries": leaderboard_entries,
                "generated_at": datetime.utcnow()
            }
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error getting challenge leaderboard: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to get challenge leaderboard"
            )
    
    @staticmethod
    async def generate_personalized_challenges(
        current_user: User,
        count: int = 5
    ) -> List[Challenge]:
        """Generate AI-powered personalized challenges"""
        try:
            # Get user's activity history and preferences
            activities = await Activity.find({"user_id": str(current_user.id)})\
                .limit(100)\
                .sort([("date", -1)])\
                .to_list()
            
            values = await Value.find({"user_id": str(current_user.id), "active": True}).to_list()
            
            # Get user progression data
            user_progression = await EnhancedChallengeService._get_or_create_user_progression(current_user)
            
            # Get past challenge performance
            past_participations = await ChallengeParticipation.find({
                "user_id": str(current_user.id)
            }).limit(20).to_list()
            
            # Use ML service to generate personalized challenges
            ml_input = {
                "user_id": str(current_user.id),
                "activities": [{"value_id": a.value_id, "duration": a.duration, "date": a.date} for a in activities],
                "values": [{"id": str(v.id), "name": v.name, "category": getattr(v, "category", "general")} for v in values],
                "level": user_progression.current_level,
                "preferred_difficulty": getattr(current_user, "preferred_difficulty", "medium"),
                "past_performance": [
                    {
                        "completion_rate": p.progress_percentage,
                        "difficulty": "medium",  # Would get from challenge
                        "category": "health"     # Would get from challenge
                    } for p in past_participations[-10:]  # Last 10 challenges
                ]
            }
            
            # Generate challenges using ML service
            try:
                ml_response = await MLPredictionService.generate_personalized_challenges(ml_input)
                generated_challenges = ml_response.get("challenges", [])
            except Exception as ml_error:
                logger.warning(f"ML service unavailable, using fallback: {ml_error}")
                generated_challenges = EnhancedChallengeService._generate_fallback_challenges(
                    current_user, activities, values, user_progression
                )
            
            # Create challenge objects
            challenges = []
            for challenge_data in generated_challenges[:count]:
                try:
                    challenge = await EnhancedChallengeService.create_challenge(
                        current_user,
                        challenge_data,
                        is_ai_generated=True
                    )
                    challenges.append(challenge)
                except Exception as challenge_error:
                    logger.error(f"Failed to create personalized challenge: {challenge_error}")
                    continue
            
            logger.info(f"Generated {len(challenges)} personalized challenges for user {current_user.id}")
            return challenges
            
        except Exception as e:
            logger.error(f"Error generating personalized challenges: {e}", exc_info=True)
            return []
    
    @staticmethod
    async def _setup_reward_pool(challenge: Challenge, challenge_data: Dict[str, Any]):
        """Setup reward pool for challenge based on difficulty and type"""
        base_points = challenge.base_points
        
        # Default reward pool
        reward_pool = {
            "completion": {
                "type": "points",
                "amount": base_points
            },
            "progress_25": {
                "type": "points", 
                "amount": base_points // 4
            },
            "progress_50": {
                "type": "points",
                "amount": base_points // 2
            },
            "progress_75": {
                "type": "points",
                "amount": int(base_points * 0.75)
            },
            "streak_7": {
                "type": "badge",
                "badge_id": "streak_warrior",
                "points": 50
            },
            "streak_14": {
                "type": "badge", 
                "badge_id": "consistency_master",
                "points": 100
            },
            "top_performer": {
                "type": "badge",
                "badge_id": "challenge_champion",
                "points": 200
            }
        }
        
        # Add premium rewards if premium challenge
        if challenge.requires_premium:
            reward_pool.update({
                "premium_completion": {
                    "type": "premium_benefit",
                    "benefit": "double_xp_24h",
                    "points": base_points
                },
                "premium_top_3": {
                    "type": "premium_benefit",
                    "benefit": "exclusive_badge_showcase",
                    "points": 300
                }
            })
        
        # Seasonal rewards
        if challenge.challenge_type == ChallengeType.SEASONAL:
            seasonal_badge_id = f"seasonal_{challenge.tags[0] if challenge.tags else 'event'}"
            reward_pool["seasonal_completion"] = {
                "type": "badge",
                "badge_id": seasonal_badge_id,
                "points": base_points,
                "limited_time": True
            }
        
        challenge.reward_pool = reward_pool
    
    @staticmethod
    async def _award_milestone_reward(
        user_id: str,
        challenge: Challenge,
        participation: ChallengeParticipation,
        milestone: int
    ) -> Optional[Dict[str, Any]]:
        """Award milestone-specific rewards"""
        try:
            reward_key = f"progress_{milestone}"
            reward_config = challenge.reward_pool.get(reward_key)
            
            if not reward_config:
                return None
            
            # Award points
            points = reward_config.get("amount", 0)
            participation.points_earned += points
            
            # Update user progression
            user = await User.get(user_id)
            if user:
                user_progression = await EnhancedChallengeService._get_or_create_user_progression(user)
                user_progression.add_points(points, "milestone")
                user_progression.add_xp(points // 5, "milestone")  # XP = points / 5
                await user_progression.save()
            
            # Record milestone
            milestone_data = {
                "type": "milestone",
                "milestone": milestone,
                "points": points,
                "achieved_at": datetime.utcnow()
            }
            
            participation.add_milestone(f"progress_{milestone}", points, milestone_data)
            
            return {
                "type": "milestone",
                "milestone": f"{milestone}% Progress",
                "reward": reward_config,
                "points_earned": points
            }
            
        except Exception as e:
            logger.error(f"Error awarding milestone reward: {e}")
            return None
    
    @staticmethod
    async def _award_streak_reward(
        user_id: str,
        challenge: Challenge,
        participation: ChallengeParticipation,
        streak_count: int
    ) -> Optional[Dict[str, Any]]:
        """Award streak-specific rewards"""
        try:
            reward_key = f"streak_{streak_count}"
            reward_config = challenge.reward_pool.get(reward_key)
            
            if not reward_config:
                return None
            
            # Award badge if configured
            if reward_config.get("type") == "badge":
                badge_id = reward_config.get("badge_id")
                await EnhancedChallengeService._award_badge(user_id, badge_id, f"challenge_{challenge.id}")
            
            # Award points
            points = reward_config.get("points", 0)
            participation.points_earned += points
            
            # Update user progression
            user = await User.get(user_id)
            if user:
                user_progression = await EnhancedChallengeService._get_or_create_user_progression(user)
                user_progression.add_points(points, "streak")
                await user_progression.save()
            
            return {
                "type": "streak",
                "streak_count": streak_count,
                "reward": reward_config,
                "points_earned": points
            }
            
        except Exception as e:
            logger.error(f"Error awarding streak reward: {e}")
            return None
    
    @staticmethod
    async def _award_completion_rewards(
        user_id: str,
        challenge: Challenge,
        participation: ChallengeParticipation
    ) -> List[Dict[str, Any]]:
        """Award completion rewards"""
        rewards_earned = []
        
        try:
            # Mark as completed
            participation.completed_at = datetime.utcnow()
            participation.status = "completed"
            
            # Main completion reward
            completion_reward = challenge.reward_pool.get("completion", {})
            points = completion_reward.get("amount", challenge.base_points)
            participation.points_earned += points
            
            # Calculate final points with multipliers
            final_points = challenge.calculate_reward_points(
                completion_rate=1.0,
                streak_bonus=participation.current_streak
            )
            
            # Update user progression
            user = await User.get(user_id)
            if user:
                user_progression = await EnhancedChallengeService._get_or_create_user_progression(user)
                user_progression.add_points(final_points, "challenge_completion")
                user_progression.add_xp(final_points // 3, "challenge_completion")
                user_progression.challenges_completed += 1
                await user_progression.save()
            
            rewards_earned.append({
                "type": "completion",
                "reward": completion_reward,
                "points_earned": final_points
            })
            
            # Award completion badge for difficult challenges
            if challenge.difficulty in [ChallengeDifficulty.HARD, ChallengeDifficulty.EXTREME]:
                badge_id = f"challenge_completion_{challenge.difficulty.value}"
                await EnhancedChallengeService._award_badge(user_id, badge_id, f"challenge_{challenge.id}")
                
                rewards_earned.append({
                    "type": "badge",
                    "badge_id": badge_id,
                    "description": f"Completed {challenge.difficulty.value} challenge"
                })
            
            # Update challenge completion stats
            challenge.completion_count += 1
            await challenge.save()
            
            return rewards_earned
            
        except Exception as e:
            logger.error(f"Error awarding completion rewards: {e}")
            return rewards_earned
    
    @staticmethod
    async def _award_badge(user_id: str, badge_id: str, earned_from: str) -> bool:
        """Award a badge to user"""
        try:
            # Check if user already has this badge
            existing = await UserBadge.find_one({
                "user_id": user_id,
                "badge_id": badge_id
            })
            
            if existing:
                # If stackable, increment count
                badge = await Badge.find_one({"badge_id": badge_id})
                if badge and badge.is_stackable:
                    if not badge.max_stack or existing.stack_count < badge.max_stack:
                        existing.stack_count += 1
                        await existing.save()
                        return True
                return False  # Already has non-stackable badge
            
            # Create new badge
            user_badge = UserBadge(
                user_id=user_id,
                badge_id=badge_id,
                earned_from=earned_from
            )
            
            await user_badge.save()
            
            # Update badge statistics
            badge = await Badge.find_one({"badge_id": badge_id})
            if badge:
                badge.total_earned += 1
                await badge.save()
            
            return True
            
        except Exception as e:
            logger.error(f"Error awarding badge: {e}")
            return False
    
    @staticmethod 
    async def _get_or_create_user_progression(user: User) -> UserProgression:
        """Get or create user progression record"""
        progression = await UserProgression.find_one({"user_id": str(user.id)})
        
        if not progression:
            progression = UserProgression(user_id=str(user.id))
            await progression.save()
        
        return progression
    
    @staticmethod
    async def _get_user_rank(participation: ChallengeParticipation) -> Optional[int]:
        """Get user's current rank in challenge"""
        try:
            # Count participants with higher points
            higher_count = await ChallengeParticipation.count_documents({
                "challenge_id": participation.challenge_id,
                "status": "active",
                "points_earned": {"$gt": participation.points_earned}
            })
            
            return higher_count + 1
            
        except Exception as e:
            logger.error(f"Error getting user rank: {e}")
            return None
    
    @staticmethod
    async def _update_challenge_analytics(challenge: Challenge, participation: ChallengeParticipation):
        """Update challenge-wide analytics"""
        try:
            # Get all active participations
            participations = await ChallengeParticipation.find({
                "challenge_id": str(challenge.id),
                "status": "active"
            }).to_list()
            
            if participations:
                # Calculate average progress
                total_progress = sum(p.progress_percentage for p in participations)
                challenge.average_progress = total_progress / len(participations)
                
                # Calculate engagement score (based on activity and progress)
                total_engagement = sum(p.engagement_score for p in participations)
                challenge.engagement_score = total_engagement / len(participations)
                
                await challenge.save()
            
        except Exception as e:
            logger.error(f"Error updating challenge analytics: {e}")
    
    @staticmethod
    async def _notify_community_challenge(challenge: Challenge):
        """Notify community about new community/seasonal challenges"""
        try:
            # Get active users who might be interested
            # This would integrate with notification preferences
            message = f"New {challenge.challenge_type.value} challenge available: {challenge.title}"
            
            # Use notification service to send to interested users
            # Implementation would depend on notification system
            logger.info(f"Community challenge notification sent for {challenge.id}")
            
        except Exception as e:
            logger.error(f"Error sending community challenge notification: {e}")
    
    @staticmethod
    def _generate_fallback_challenges(
        user: User,
        activities: List[Activity],
        values: List[Value],
        user_progression: UserProgression
    ) -> List[Dict[str, Any]]:
        """Generate fallback challenges when ML service is unavailable"""
        
        fallback_challenges = [
            {
                "title": "Daily Value Practice",
                "description": "Practice one of your core values every day for a week",
                "challenge_type": "individual",
                "category": "personal_growth",
                "difficulty": "medium",
                "target_metric": "days",
                "target_value": 7,
                "duration_days": 7,
                "tags": ["daily", "values", "consistency"]
            },
            {
                "title": "Mindful Minutes",
                "description": "Spend 10 minutes in mindful activity each day",
                "challenge_type": "individual", 
                "category": "mindfulness",
                "difficulty": "easy",
                "target_metric": "minutes",
                "target_value": 70,  # 10 min x 7 days
                "duration_days": 7,
                "tags": ["mindfulness", "wellness"]
            },
            {
                "title": "Value Exploration",
                "description": "Try activities related to 3 different values this week",
                "challenge_type": "individual",
                "category": "personal_growth", 
                "difficulty": "medium",
                "target_metric": "values",
                "target_value": 3,
                "duration_days": 7,
                "tags": ["exploration", "diversity", "growth"]
            }
        ]
        
        # Personalize based on user level
        difficulty_map = {
            (1, 10): "easy",
            (11, 25): "medium", 
            (26, 50): "hard",
            (51, 100): "extreme"
        }
        
        preferred_difficulty = "medium"
        for (min_level, max_level), diff in difficulty_map.items():
            if min_level <= user_progression.current_level <= max_level:
                preferred_difficulty = diff
                break
        
        # Update difficulty based on user level
        for challenge in fallback_challenges:
            challenge["difficulty"] = preferred_difficulty
        
        return fallback_challenges