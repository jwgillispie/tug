# app/services/gamification_service.py
import logging
from typing import List, Optional, Dict, Any, Tuple
from datetime import datetime, timedelta
from fastapi import HTTPException, status
from bson import ObjectId
import asyncio

from ..models.user import User
from ..models.gamification import (
    Badge, UserBadge, UserProgression, Reward, UserReward, Leaderboard,
    BadgeCategory, BadgeRarity, UserLevel, RewardStatus
)
from ..models.challenge import Challenge, ChallengeParticipation
from ..models.seasonal_event import SeasonalEvent, EventParticipation
from ..models.activity import Activity
from ..models.value import Value
from ..services.notification_service import NotificationService

logger = logging.getLogger(__name__)

class GamificationService:
    """Comprehensive gamification service managing XP, levels, badges, and rewards"""
    
    @staticmethod
    async def initialize_user_gamification(user: User) -> UserProgression:
        """Initialize gamification system for new user"""
        try:
            # Check if already initialized
            existing = await UserProgression.find_one({"user_id": str(user.id)})
            if existing:
                return existing
            
            # Create initial progression
            progression = UserProgression(
                user_id=str(user.id),
                total_xp=0,
                current_level=1,
                xp_to_next_level=100,
                level_tier=UserLevel.NOVICE
            )
            
            await progression.save()
            
            # Award welcome badge
            await GamificationService._award_badge(str(user.id), "welcome_aboard", "system_init")
            
            logger.info(f"Gamification initialized for user {user.id}")
            return progression
            
        except Exception as e:
            logger.error(f"Error initializing user gamification: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to initialize gamification"
            )
    
    @staticmethod
    async def award_activity_xp(user: User, activity_data: Dict[str, Any]) -> Dict[str, Any]:
        """Award XP for logging activities with comprehensive calculations"""
        try:
            progression = await UserProgression.find_one({"user_id": str(user.id)})
            if not progression:
                progression = await GamificationService.initialize_user_gamification(user)
            
            # Calculate XP based on activity
            base_xp = 10  # Base XP for any activity
            duration_bonus = min(50, (activity_data.get("duration", 0) // 10))  # 1 XP per 10 minutes, max 50
            
            # Streak multiplier
            streak_multiplier = min(3.0, 1.0 + (progression.current_streak * 0.1))
            
            # Value diversity bonus (practicing different values)
            value_diversity_bonus = 0
            if len(progression.favorite_categories) >= 3:
                value_diversity_bonus = 5
            
            # Premium bonus
            premium_bonus = 5 if getattr(user, "is_premium", False) else 0
            
            total_xp = int((base_xp + duration_bonus + value_diversity_bonus + premium_bonus) * streak_multiplier)
            
            # Store level before adding XP
            old_level = progression.current_level
            
            # Add XP and handle level ups
            progression.add_xp(total_xp, "activity")
            progression.total_activities_logged += 1
            progression.total_time_tracked += activity_data.get("duration", 0)
            
            # Update streak
            progression.update_streak(True)
            
            await progression.save()
            
            # Check for level up rewards
            level_up_rewards = []
            if progression.current_level > old_level:
                level_up_rewards = await GamificationService._handle_level_up(user, progression, old_level)
            
            # Check for activity-based achievements
            await GamificationService._check_activity_achievements(user, progression, activity_data)
            
            return {
                "xp_awarded": total_xp,
                "total_xp": progression.total_xp,
                "level": progression.current_level,
                "level_tier": progression.level_tier,
                "leveled_up": progression.current_level > old_level,
                "level_up_rewards": level_up_rewards,
                "streak": progression.current_streak,
                "streak_multiplier": progression.streak_multiplier
            }
            
        except Exception as e:
            logger.error(f"Error awarding activity XP: {e}", exc_info=True)
            return {"xp_awarded": 0, "error": "Failed to award XP"}
    
    @staticmethod
    async def get_user_progression(user: User) -> Dict[str, Any]:
        """Get comprehensive user progression data"""
        try:
            progression = await UserProgression.find_one({"user_id": str(user.id)})
            if not progression:
                progression = await GamificationService.initialize_user_gamification(user)
            
            # Get user's badges
            user_badges = await UserBadge.find({"user_id": str(user.id)})\
                .sort([("earned_at", -1)])\
                .to_list()
            
            # Get badge details
            badge_ids = [ub.badge_id for ub in user_badges]
            badges = await Badge.find({"badge_id": {"$in": badge_ids}}).to_list()
            badge_map = {b.badge_id: b for b in badges}
            
            # Format badges with details
            formatted_badges = []
            showcased_badges = []
            
            for user_badge in user_badges:
                badge = badge_map.get(user_badge.badge_id)
                if badge:
                    badge_data = {
                        "id": user_badge.badge_id,
                        "name": badge.name,
                        "description": badge.description,
                        "icon": badge.icon,
                        "rarity": badge.rarity,
                        "category": badge.category,
                        "earned_at": user_badge.earned_at,
                        "stack_count": user_badge.stack_count,
                        "is_showcased": user_badge.is_showcased
                    }
                    formatted_badges.append(badge_data)
                    
                    if user_badge.is_showcased:
                        showcased_badges.append(badge_data)
            
            # Get recent achievements
            recent_badges = sorted(formatted_badges, key=lambda x: x["earned_at"], reverse=True)[:5]
            
            # Calculate level progress
            level_progress = progression.get_level_progress_percentage()
            
            # Get rank in global leaderboard
            global_rank = await GamificationService._get_user_global_rank(user)
            
            return {
                "user_id": str(user.id),
                "progression": {
                    "level": progression.current_level,
                    "level_tier": progression.level_tier,
                    "total_xp": progression.total_xp,
                    "xp_to_next_level": progression.xp_to_next_level,
                    "level_progress_percentage": level_progress,
                    "lifetime_points": progression.lifetime_points,
                    "current_points": progression.current_points,
                    "points_spent": progression.points_spent
                },
                "streaks": {
                    "current_streak": progression.current_streak,
                    "longest_streak": progression.longest_streak,
                    "streak_multiplier": progression.streak_multiplier
                },
                "achievements": {
                    "challenges_completed": progression.challenges_completed,
                    "badges_earned": len(formatted_badges),
                    "achievements_unlocked": progression.achievements_unlocked,
                    "total_activities": progression.total_activities_logged,
                    "total_time_tracked": progression.total_time_tracked
                },
                "social": {
                    "friends_helped": progression.friends_helped,
                    "community_contributions": progression.community_contributions,
                    "global_rank": global_rank
                },
                "badges": {
                    "total": len(formatted_badges),
                    "showcased": showcased_badges,
                    "recent": recent_badges,
                    "by_rarity": GamificationService._group_badges_by_rarity(formatted_badges)
                }
            }
            
        except Exception as e:
            logger.error(f"Error getting user progression: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to get user progression"
            )
    
    @staticmethod
    async def get_available_rewards(user: User, category: Optional[str] = None) -> List[Dict[str, Any]]:
        """Get rewards available to user based on level and points"""
        try:
            progression = await UserProgression.find_one({"user_id": str(user.id)})
            if not progression:
                return []
            
            user_premium = getattr(user, "is_premium", False)
            current_time = datetime.utcnow()
            
            # Build query for available rewards
            query = {
                "is_active": True,
                "level_requirement": {"$lte": progression.current_level}
            }
            
            if category:
                query["reward_type"] = category
            
            # Get rewards
            rewards = await Reward.find(query).sort([("points_cost", 1)]).to_list()
            
            # Filter and format rewards
            available_rewards = []
            for reward in rewards:
                if reward.is_available(progression.current_level, user_premium, current_time):
                    # Check if user can afford it
                    can_afford = progression.current_points >= reward.points_cost
                    
                    # Check if already claimed (for limited rewards)
                    already_claimed = False
                    if reward.stock_limit:
                        existing_claim = await UserReward.find_one({
                            "user_id": str(user.id),
                            "reward_id": reward.reward_id
                        })
                        already_claimed = existing_claim is not None
                    
                    reward_data = {
                        "id": reward.reward_id,
                        "name": reward.name,
                        "description": reward.description,
                        "icon": reward.icon,
                        "type": reward.reward_type,
                        "cost": reward.points_cost,
                        "level_requirement": reward.level_requirement,
                        "premium_required": reward.premium_required,
                        "can_afford": can_afford,
                        "already_claimed": already_claimed,
                        "stock_remaining": reward.stock_remaining,
                        "available_until": reward.available_until
                    }
                    available_rewards.append(reward_data)
            
            return available_rewards
            
        except Exception as e:
            logger.error(f"Error getting available rewards: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to get available rewards"
            )
    
    @staticmethod
    async def claim_reward(user: User, reward_id: str) -> Dict[str, Any]:
        """Claim a reward for user"""
        try:
            # Get reward
            reward = await Reward.find_one({"reward_id": reward_id})
            if not reward:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Reward not found"
                )
            
            # Get user progression
            progression = await UserProgression.find_one({"user_id": str(user.id)})
            if not progression:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="User progression not found"
                )
            
            user_premium = getattr(user, "is_premium", False)
            
            # Check if reward is available
            if not reward.is_available(progression.current_level, user_premium):
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Reward not available"
                )
            
            # Check if user can afford it
            if progression.current_points < reward.points_cost:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Insufficient points"
                )
            
            # Check if already claimed (for limited rewards)
            if reward.stock_limit:
                existing = await UserReward.find_one({
                    "user_id": str(user.id),
                    "reward_id": reward_id
                })
                if existing:
                    raise HTTPException(
                        status_code=status.HTTP_400_BAD_REQUEST,
                        detail="Reward already claimed"
                    )
            
            # Attempt to claim reward (handles stock)
            if not reward.claim_reward():
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Reward out of stock"
                )
            
            # Deduct points
            progression.spend_points(reward.points_cost)
            await progression.save()
            
            # Create user reward record
            user_reward = UserReward(
                user_id=str(user.id),
                reward_id=reward_id,
                status=RewardStatus.CLAIMED
            )
            
            # Set expiration if applicable
            if reward.reward_data.get("expires_in_days"):
                user_reward.expires_at = datetime.utcnow() + timedelta(
                    days=reward.reward_data["expires_in_days"]
                )
            
            await user_reward.save()
            await reward.save()  # Save updated stock
            
            # Apply reward effects
            reward_effects = await GamificationService._apply_reward_effects(user, reward, user_reward)
            
            logger.info(f"User {user.id} claimed reward {reward_id}")
            
            return {
                "reward_id": reward_id,
                "reward_name": reward.name,
                "points_spent": reward.points_cost,
                "remaining_points": progression.current_points,
                "effects": reward_effects,
                "expires_at": user_reward.expires_at
            }
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error claiming reward: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to claim reward"
            )
    
    @staticmethod
    async def showcase_badges(user: User, badge_ids: List[str]) -> Dict[str, Any]:
        """Set which badges user wants to showcase"""
        try:
            # Limit to max 5 showcased badges
            if len(badge_ids) > 5:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Maximum 5 badges can be showcased"
                )
            
            # Reset all badges to not showcased
            await UserBadge.update_many(
                {"user_id": str(user.id)},
                {"$set": {"is_showcased": False, "showcase_order": None}}
            )
            
            # Set selected badges as showcased
            for index, badge_id in enumerate(badge_ids):
                user_badge = await UserBadge.find_one({
                    "user_id": str(user.id),
                    "badge_id": badge_id
                })
                
                if user_badge:
                    user_badge.is_showcased = True
                    user_badge.showcase_order = index + 1
                    await user_badge.save()
            
            return {
                "showcased_badges": badge_ids,
                "message": f"Successfully showcasing {len(badge_ids)} badges"
            }
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error showcasing badges: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to showcase badges"
            )
    
    @staticmethod
    async def get_leaderboards(
        leaderboard_type: str = "global",
        metric: str = "xp",
        time_period: str = "all_time",
        limit: int = 50,
        user_id: Optional[str] = None
    ) -> Dict[str, Any]:
        """Get leaderboard data with caching"""
        try:
            # Check for cached leaderboard
            leaderboard = await Leaderboard.find_one({
                "leaderboard_type": leaderboard_type,
                "metric": metric,
                "time_period": time_period
            })
            
            # Use cache if valid
            if leaderboard and leaderboard.is_cache_valid():
                results = leaderboard.cached_results[:limit]
                leaderboard.increment_views()
                await leaderboard.save()
            else:
                # Generate new leaderboard
                results = await GamificationService._generate_leaderboard(
                    leaderboard_type, metric, time_period, limit
                )
                
                # Update or create cache
                if leaderboard:
                    leaderboard.update_cache(results)
                    await leaderboard.save()
                else:
                    new_leaderboard = Leaderboard(
                        leaderboard_id=f"{leaderboard_type}_{metric}_{time_period}",
                        name=f"{leaderboard_type.title()} {metric.upper()} Leaderboard",
                        description=f"Top users by {metric} ({time_period})",
                        leaderboard_type=leaderboard_type,
                        metric=metric,
                        time_period=time_period,
                        cached_results=results
                    )
                    await new_leaderboard.save()
            
            # Find user's position if requested
            user_position = None
            if user_id:
                for index, entry in enumerate(results):
                    if entry.get("user_id") == user_id:
                        user_position = index + 1
                        break
            
            return {
                "leaderboard_type": leaderboard_type,
                "metric": metric,
                "time_period": time_period,
                "entries": results,
                "user_position": user_position,
                "total_entries": len(results),
                "generated_at": datetime.utcnow()
            }
            
        except Exception as e:
            logger.error(f"Error getting leaderboards: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to get leaderboards"
            )
    
    @staticmethod
    async def _award_badge(user_id: str, badge_id: str, earned_from: str) -> bool:
        """Internal method to award badges"""
        try:
            # Check if badge exists
            badge = await Badge.find_one({"badge_id": badge_id})
            if not badge:
                logger.warning(f"Badge {badge_id} not found")
                return False
            
            # Check if user already has this badge
            existing = await UserBadge.find_one({
                "user_id": user_id,
                "badge_id": badge_id
            })
            
            if existing:
                # Handle stackable badges
                if badge.is_stackable:
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
            badge.total_earned += 1
            await badge.save()
            
            # Send notification
            user = await User.get(user_id)
            if user:
                await NotificationService.create_achievement_notification(
                    user_id=user_id,
                    notification_type="badge_earned",
                    message=f"Congratulations! You've earned the '{badge.name}' badge!",
                    data={"badge_id": badge_id, "badge_name": badge.name}
                )
            
            return True
            
        except Exception as e:
            logger.error(f"Error awarding badge {badge_id} to user {user_id}: {e}")
            return False
    
    @staticmethod
    async def _handle_level_up(user: User, progression: UserProgression, old_level: int) -> List[Dict[str, Any]]:
        """Handle level up rewards and notifications"""
        rewards = []
        
        try:
            # Level up points reward
            level_bonus_points = progression.current_level * 50
            progression.add_points(level_bonus_points, "level_up")
            
            rewards.append({
                "type": "points",
                "amount": level_bonus_points,
                "description": f"Level {progression.current_level} bonus"
            })
            
            # Special level milestone rewards
            level_milestones = {
                5: {"badge": "rising_star", "points": 500},
                10: {"badge": "dedicated_learner", "points": 1000},
                25: {"badge": "seasoned_practitioner", "points": 2500},
                50: {"badge": "master_of_values", "points": 5000},
                100: {"badge": "legendary_achiever", "points": 10000}
            }
            
            if progression.current_level in level_milestones:
                milestone = level_milestones[progression.current_level]
                
                # Award milestone badge
                if await GamificationService._award_badge(str(user.id), milestone["badge"], f"level_{progression.current_level}"):
                    rewards.append({
                        "type": "badge",
                        "badge_id": milestone["badge"],
                        "description": f"Level {progression.current_level} milestone badge"
                    })
                
                # Award milestone points
                progression.add_points(milestone["points"], "milestone")
                rewards.append({
                    "type": "points",
                    "amount": milestone["points"],
                    "description": f"Level {progression.current_level} milestone bonus"
                })
            
            # Send level up notification
            await NotificationService.create_achievement_notification(
                user_id=str(user.id),
                notification_type="level_up",
                message=f"Level up! You've reached level {progression.current_level}!",
                data={"new_level": progression.current_level, "rewards": rewards}
            )
            
            return rewards
            
        except Exception as e:
            logger.error(f"Error handling level up for user {user.id}: {e}")
            return rewards
    
    @staticmethod
    async def _check_activity_achievements(user: User, progression: UserProgression, activity_data: Dict[str, Any]):
        """Check and award activity-based achievements"""
        try:
            # Check for activity count milestones
            activity_milestones = {
                1: "first_step",
                10: "getting_started",
                50: "regular_tracker",
                100: "century_club",
                500: "activity_master",
                1000: "thousand_strong"
            }
            
            if progression.total_activities_logged in activity_milestones:
                badge_id = activity_milestones[progression.total_activities_logged]
                await GamificationService._award_badge(str(user.id), badge_id, "activity_count")
            
            # Check for time tracking milestones (in hours)
            hours_tracked = progression.total_time_tracked // 60
            time_milestones = {
                5: "time_investment",    # 5 hours
                20: "dedicated_day",     # 20 hours
                50: "value_maven",       # 50 hours
                100: "time_master",      # 100 hours
                500: "lifetime_dedicator" # 500 hours
            }
            
            if hours_tracked in time_milestones:
                badge_id = time_milestones[hours_tracked]
                await GamificationService._award_badge(str(user.id), badge_id, "time_tracked")
            
            # Check for streak achievements
            streak_milestones = {
                3: "streak_starter",
                7: "week_warrior",
                14: "fortnight_force",
                30: "monthly_master",
                100: "streak_legend"
            }
            
            if progression.current_streak in streak_milestones:
                badge_id = streak_milestones[progression.current_streak]
                await GamificationService._award_badge(str(user.id), badge_id, "streak_achievement")
            
        except Exception as e:
            logger.error(f"Error checking activity achievements: {e}")
    
    @staticmethod
    async def _apply_reward_effects(user: User, reward: Reward, user_reward: UserReward) -> Dict[str, Any]:
        """Apply reward effects to user account"""
        effects = {}
        
        try:
            reward_data = reward.reward_data
            
            # Handle different reward types
            if reward.reward_type == "premium_benefit":
                benefit_type = reward_data.get("benefit")
                
                if benefit_type == "double_xp_24h":
                    # This would integrate with XP calculation system
                    effects["double_xp_until"] = datetime.utcnow() + timedelta(hours=24)
                
                elif benefit_type == "streak_freeze":
                    # This would integrate with streak system
                    effects["streak_freeze_count"] = reward_data.get("count", 1)
                
                elif benefit_type == "bonus_challenge_points":
                    effects["challenge_points_multiplier"] = reward_data.get("multiplier", 1.5)
                    effects["multiplier_duration_days"] = reward_data.get("duration_days", 7)
            
            elif reward.reward_type == "virtual_item":
                effects["item_granted"] = reward_data.get("item_id")
                effects["item_quantity"] = reward_data.get("quantity", 1)
            
            elif reward.reward_type == "custom":
                # Handle custom reward types
                effects.update(reward_data)
            
            # Store effects in user_reward for future reference
            user_reward.usage_data = effects
            await user_reward.save()
            
            return effects
            
        except Exception as e:
            logger.error(f"Error applying reward effects: {e}")
            return {}
    
    @staticmethod
    async def _get_user_global_rank(user: User) -> Optional[int]:
        """Get user's rank in global XP leaderboard"""
        try:
            progression = await UserProgression.find_one({"user_id": str(user.id)})
            if not progression:
                return None
            
            # Count users with higher XP
            higher_count = await UserProgression.count_documents({
                "total_xp": {"$gt": progression.total_xp}
            })
            
            return higher_count + 1
            
        except Exception as e:
            logger.error(f"Error getting user global rank: {e}")
            return None
    
    @staticmethod
    def _group_badges_by_rarity(badges: List[Dict[str, Any]]) -> Dict[str, List[Dict[str, Any]]]:
        """Group badges by rarity"""
        grouped = {rarity.value: [] for rarity in BadgeRarity}
        
        for badge in badges:
            rarity = badge.get("rarity", "common")
            if rarity in grouped:
                grouped[rarity].append(badge)
        
        return grouped
    
    @staticmethod
    async def _generate_leaderboard(
        leaderboard_type: str,
        metric: str,
        time_period: str,
        limit: int
    ) -> List[Dict[str, Any]]:
        """Generate fresh leaderboard data"""
        try:
            # Define sort criteria based on metric
            sort_criteria = {
                "xp": [("total_xp", -1)],
                "level": [("current_level", -1), ("total_xp", -1)],
                "points": [("lifetime_points", -1)],
                "streak": [("longest_streak", -1), ("current_streak", -1)],
                "challenges": [("challenges_completed", -1)]
            }
            
            sort_field = sort_criteria.get(metric, sort_criteria["xp"])
            
            # Apply time filtering for non-all-time periods
            query = {}
            if time_period != "all_time":
                time_filter = GamificationService._get_time_filter(time_period)
                if time_filter:
                    query.update(time_filter)
            
            # Get top users
            progressions = await UserProgression.find(query)\
                .sort(sort_field)\
                .limit(limit)\
                .to_list()
            
            # Get user details
            user_ids = [p.user_id for p in progressions]
            users = await User.find({"_id": {"$in": [ObjectId(uid) for uid in user_ids]}}).to_list()
            user_map = {str(u.id): u for u in users}
            
            # Build leaderboard entries
            entries = []
            for rank, progression in enumerate(progressions, 1):
                user = user_map.get(progression.user_id)
                if user:
                    entry = {
                        "rank": rank,
                        "user_id": progression.user_id,
                        "display_name": getattr(user, "display_name", "Unknown"),
                        "username": getattr(user, "username", None),
                        "level": progression.current_level,
                        "level_tier": progression.level_tier,
                        "total_xp": progression.total_xp,
                        "lifetime_points": progression.lifetime_points,
                        "current_streak": progression.current_streak,
                        "longest_streak": progression.longest_streak,
                        "challenges_completed": progression.challenges_completed,
                        "badges_count": 0  # Would need to count badges
                    }
                    entries.append(entry)
            
            return entries
            
        except Exception as e:
            logger.error(f"Error generating leaderboard: {e}")
            return []
    
    @staticmethod
    def _get_time_filter(time_period: str) -> Optional[Dict[str, Any]]:
        """Get time filter for leaderboard queries"""
        now = datetime.utcnow()
        
        if time_period == "daily":
            start_of_day = now.replace(hour=0, minute=0, second=0, microsecond=0)
            return {"updated_at": {"$gte": start_of_day}}
        
        elif time_period == "weekly":
            start_of_week = now - timedelta(days=now.weekday())
            start_of_week = start_of_week.replace(hour=0, minute=0, second=0, microsecond=0)
            return {"updated_at": {"$gte": start_of_week}}
        
        elif time_period == "monthly":
            start_of_month = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
            return {"updated_at": {"$gte": start_of_month}}
        
        return None