# app/services/achievement_service.py
from datetime import datetime
from typing import List, Optional, Dict, Any
from fastapi import HTTPException, status
from bson import ObjectId
import logging

from ..models.user import User
from ..models.achievement import Achievement, AchievementType
from ..models.activity import Activity
from ..models.value import Value
from ..schemas.achievement import AchievementCreate, AchievementUpdate, PredefinedAchievement

logger = logging.getLogger(__name__)

class AchievementService:
    """Service for managing achievements"""
    
    # Predefined achievements for the application
    @staticmethod
    def get_predefined_achievements() -> List[PredefinedAchievement]:
        """Return all predefined achievement templates"""
        return [
            # Streak achievements
            PredefinedAchievement(
                achievement_id="streak_3",
                type=AchievementType.streak,
                title="3-day streak",
                description="complete activities for the same value 3 days in a row",
                icon="🔥",
                required_value=3,
            ),
            PredefinedAchievement(
                achievement_id="streak_7",
                type=AchievementType.streak,
                title="week warrior",
                description="complete activities for the same value 7 days in a row",
                icon="📅",
                required_value=7,
            ),
            PredefinedAchievement(
                achievement_id="streak_14",
                type=AchievementType.streak,
                title="fortnight force",
                description="complete activities for the same value 14 days in a row",
                icon="🧠",
                required_value=14,
            ),
            PredefinedAchievement(
                achievement_id="streak_30",
                type=AchievementType.streak,
                title="monthly master",
                description="complete activities for the same value 30 days in a row",
                icon="🏆",
                required_value=30,
            ),
            
            # Balance achievements
            PredefinedAchievement(
                achievement_id="balance_3",
                type=AchievementType.balance,
                title="balanced beginner",
                description="maintain a balanced distribution across your values for 3 days",
                icon="⚖️",
                required_value=3,
            ),
            PredefinedAchievement(
                achievement_id="balance_7",
                type=AchievementType.balance,
                title="harmony keeper",
                description="maintain a balanced distribution across your values for 7 days",
                icon="☯️",
                required_value=7,
            ),
            PredefinedAchievement(
                achievement_id="balance_30",
                type=AchievementType.balance,
                title="life balancer",
                description="maintain a balanced distribution across your values for 30 days",
                icon="🧘",
                required_value=30,
            ),
            
            # Frequency achievements
            PredefinedAchievement(
                achievement_id="frequency_10",
                type=AchievementType.frequency,
                title="getting started",
                description="log 10 activities",
                icon="🏁",
                required_value=10,
            ),
            PredefinedAchievement(
                achievement_id="frequency_50",
                type=AchievementType.frequency,
                title="regular tracker",
                description="log 50 activities",
                icon="📝",
                required_value=50,
            ),
            PredefinedAchievement(
                achievement_id="frequency_100",
                type=AchievementType.frequency,
                title="century club",
                description="log 100 activities",
                icon="💯",
                required_value=100,
            ),
            PredefinedAchievement(
                achievement_id="frequency_365",
                type=AchievementType.frequency,
                title="year of growth",
                description="log 365 activities",
                icon="📊",
                required_value=365,
            ),
            
            # Milestone achievements
            PredefinedAchievement(
                achievement_id="milestone_300",
                type=AchievementType.milestone,
                title="time investment",
                description="spend 5 hours on value-aligned activities",
                icon="⏱️",
                required_value=300,  # minutes
            ),
            PredefinedAchievement(
                achievement_id="milestone_1200",
                type=AchievementType.milestone,
                title="dedicated day",
                description="spend 20 hours on value-aligned activities",
                icon="⌛",
                required_value=1200,  # minutes
            ),
            PredefinedAchievement(
                achievement_id="milestone_3000",
                type=AchievementType.milestone,
                title="value maven",
                description="spend 50 hours on value-aligned activities",
                icon="🕰️",
                required_value=3000,  # minutes
            ),
            
            # Special achievements
            PredefinedAchievement(
                achievement_id="special_balanced_all",
                type=AchievementType.special,
                title="perfect harmony",
                description="log at least one activity for each of your values",
                icon="🌈",
                required_value=1,
            ),
            PredefinedAchievement(
                achievement_id="special_comeback",
                type=AchievementType.special,
                title="comeback kid",
                description="return to logging activities after a 2-week break",
                icon="🔄",
                required_value=1,
            ),
        ]
    
    @classmethod
    async def initialize_user_achievements(cls, user_id: str) -> None:
        """Initialize achievements for a new user"""
        logger.info(f"Initializing achievements for user: {user_id}")
        
        # Get predefined achievements
        predefined = cls.get_predefined_achievements()
        
        # Check if user already has achievements initialized
        existing = await Achievement.find(Achievement.user_id == user_id).to_list(length=None)
        if existing:
            logger.info(f"User {user_id} already has {len(existing)} achievements initialized")
            return
        
        # Create achievement records for the user
        for achievement in predefined:
            new_achievement = Achievement(
                user_id=user_id,
                achievement_id=achievement.achievement_id,
                type=achievement.type,
                title=achievement.title,
                description=achievement.description,
                icon=achievement.icon,
                required_value=achievement.required_value,
                progress=0.0,
                is_unlocked=False,
                unlocked_at=None
            )
            await new_achievement.save()
        
        logger.info(f"Initialized {len(predefined)} achievements for user {user_id}")
    
    @classmethod
    async def get_user_achievements(cls, user: User) -> List[Achievement]:
        """Get all achievements for a user"""
        logger.info(f"Getting achievements for user: {user.id}")
        
        # Ensure user has achievements initialized
        await cls.initialize_user_achievements(str(user.id))
        
        # Get the user's achievements
        achievements = await Achievement.get_user_achievements(str(user.id))
        
        # Calculate current progress for achievements
        achievements = await cls.calculate_achievement_progress(user, achievements)
        
        return achievements
    
    @classmethod
    async def get_achievement(cls, user: User, achievement_id: str) -> Achievement:
        """Get a specific achievement for a user"""
        logger.info(f"Getting achievement {achievement_id} for user: {user.id}")
        
        # Ensure user has achievements initialized
        await cls.initialize_user_achievements(str(user.id))
        
        # Find the specific achievement
        achievement = await Achievement.get_achievement(str(user.id), achievement_id)
        
        if not achievement:
            logger.warning(f"Achievement {achievement_id} not found for user {user.id}")
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Achievement not found"
            )
        
        # Calculate current progress for this achievement
        achievements = await cls.calculate_achievement_progress(user, [achievement])
        return achievements[0]
    
    @classmethod
    async def update_achievement(
        cls, 
        user: User, 
        achievement_id: str, 
        updates: AchievementUpdate
    ) -> Achievement:
        """Update an achievement manually (admin functionality)"""
        logger.info(f"Updating achievement {achievement_id} for user: {user.id}")
        
        # Find the specific achievement
        achievement = await Achievement.get_achievement(str(user.id), achievement_id)
        
        if not achievement:
            logger.warning(f"Achievement {achievement_id} not found for user {user.id}")
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Achievement not found"
            )
        
        # Update the fields provided
        update_data = updates.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            setattr(achievement, field, value)
        
        # If marking as unlocked with no date, set date to now
        if updates.is_unlocked and not achievement.unlocked_at:
            achievement.unlocked_at = datetime.utcnow()
        
        # Update last modified timestamp
        achievement.updated_at = datetime.utcnow()
        
        # Save the updated achievement
        await achievement.save()
        logger.info(f"Achievement {achievement_id} updated successfully")
        
        return achievement
    
    @classmethod
    async def check_and_update_achievements(cls, user: User) -> List[Achievement]:
        """Check and update all achievements for a user, return newly unlocked achievements"""
        logger.info(f"Checking achievements for user: {user.id}")
        
        # Ensure user has achievements initialized
        await cls.initialize_user_achievements(str(user.id))
        
        # Get user's current achievements
        achievements = await Achievement.get_user_achievements(str(user.id))
        
        # Filter for only unlocked achievements before the update
        previously_unlocked = {a.achievement_id for a in achievements if a.is_unlocked}
        
        # Calculate current progress for achievements
        updated_achievements = await cls.calculate_achievement_progress(user, achievements)
        
        # Save all updated achievements
        for achievement in updated_achievements:
            # Only save if the achievement was modified
            # (is_unlocked changed or progress changed)
            old_achievement = next((a for a in achievements if a.id == achievement.id), None)
            if (old_achievement and 
                (old_achievement.is_unlocked != achievement.is_unlocked or 
                 abs(old_achievement.progress - achievement.progress) > 0.001)):
                
                # If newly unlocked, set the unlocked_at timestamp
                if achievement.is_unlocked and not achievement.unlocked_at:
                    achievement.unlocked_at = datetime.utcnow()
                
                # Update last modified timestamp
                achievement.updated_at = datetime.utcnow()
                
                # Save the updated achievement
                await achievement.save()
        
        # Filter for newly unlocked achievements
        newly_unlocked = [
            a for a in updated_achievements 
            if a.is_unlocked and a.achievement_id not in previously_unlocked
        ]
        
        if newly_unlocked:
            logger.info(f"User {user.id} unlocked {len(newly_unlocked)} new achievements")
        
        return newly_unlocked
    
    @classmethod
    async def calculate_achievement_progress(
        cls, 
        user: User,
        achievements: List[Achievement]
    ) -> List[Achievement]:
        """Calculate current progress for a list of achievements"""
        if not achievements:
            return []
        
        # Get the data needed for calculations
        activities = await Activity.find(Activity.user_id == str(user.id)).to_list(length=None)
        values = await Value.find(Value.user_id == str(user.id)).to_list(length=None)
        
        # Create a copy of achievements to modify
        updated_achievements = []
        
        # Calculate progress for each achievement
        for achievement in achievements:
            updated = await cls._calculate_single_achievement(achievement, activities, values)
            updated_achievements.append(updated)
        
        return updated_achievements
    
    @classmethod
    async def _calculate_single_achievement(
        cls,
        achievement: Achievement,
        activities: List[Activity],
        values: List[Value]
    ) -> Achievement:
        """Calculate progress for a single achievement"""
        try:
            # Check if already unlocked
            if achievement.is_unlocked:
                return achievement
            
            # Calculate based on achievement type
            if achievement.type == AchievementType.streak:
                return cls._calculate_streak_achievement(achievement, values)
            
            elif achievement.type == AchievementType.balance:
                return cls._calculate_balance_achievement(achievement, activities, values)
            
            elif achievement.type == AchievementType.frequency:
                return cls._calculate_frequency_achievement(achievement, activities)
            
            elif achievement.type == AchievementType.milestone:
                return cls._calculate_milestone_achievement(achievement, activities)
            
            elif achievement.type == AchievementType.special:
                return cls._calculate_special_achievement(achievement, activities, values)
            
            # Unknown achievement type
            else:
                logger.warning(f"Unknown achievement type: {achievement.type}")
                return achievement
        
        except Exception as e:
            # Log the error but don't fail the entire calculation
            logger.error(f"Error calculating achievement {achievement.achievement_id}: {str(e)}")
            return achievement
    
    @staticmethod
    def _calculate_streak_achievement(
        achievement: Achievement,
        values: List[Value]
    ) -> Achievement:
        """Calculate progress for streak-based achievements"""
        # Find the maximum streak among all values (considering both current and historical)
        max_streak = 0
        for value in values:
            # Use the highest streak ever achieved for this value
            value_best_streak = max(
                value.current_streak or 0,
                value.longest_streak or 0
            )
            if value_best_streak > max_streak:
                max_streak = value_best_streak
        
        # Check if we've achieved the required streak (once achieved, stays unlocked)
        is_unlocked = achievement.is_unlocked or max_streak >= achievement.required_value
        
        # Calculate progress - cap at 1.0
        progress = min(1.0, max_streak / achievement.required_value) if achievement.required_value > 0 else 0.0
        
        # Return updated achievement (create a modified copy)
        updated = Achievement(
            **achievement.model_dump(),
            progress=progress,
            is_unlocked=is_unlocked,
            unlocked_at=datetime.utcnow() if is_unlocked and not achievement.unlocked_at else achievement.unlocked_at
        )
        
        # Preserve the ID
        updated.id = achievement.id
        
        return updated
    
    @staticmethod
    def _calculate_balance_achievement(
        achievement: Achievement,
        activities: List[Activity],
        values: List[Value]
    ) -> Achievement:
        """Calculate progress for balance-based achievements"""
        # For balance achievements, we check how long the user
        # has maintained balanced values
        
        if not values or not activities:
            return achievement
        
        # Calculate activity counts per value
        activity_counts = {}
        for activity in activities:
            value_id = activity.value_id
            activity_counts[value_id] = activity_counts.get(value_id, 0) + 1
        
        # Calculate average activity count
        active_values = [v for v in values if v.active]
        if not active_values:
            return achievement
        
        avg_activities = sum(activity_counts.get(str(v.id), 0) for v in active_values) / len(active_values)
        
        # Calculate standard deviation as a measure of imbalance
        sum_squared_diff = 0
        for value in active_values:
            count = activity_counts.get(str(value.id), 0)
            sum_squared_diff += (count - avg_activities) ** 2
        
        std_dev = (sum_squared_diff / len(active_values)) if active_values else 0
        
        # Lower stdDev means better balance. Convert to a 0-1 score
        balance_score = 1.0 - min(1.0, std_dev / (avg_activities * 2)) if avg_activities > 0 else 0.0
        
        # For days maintained, use a rough estimate based on activity dates
        days_with_activities = 0
        if activities:
            # Get unique dates
            activity_dates = {
                datetime(a.date.year, a.date.month, a.date.day)
                for a in activities
            }
            days_with_activities = len(activity_dates)
        
        # Combine balance score with duration
        balance_days = int(days_with_activities * balance_score)
        
        # Check if the achievement is unlocked
        is_unlocked = achievement.is_unlocked or balance_days >= achievement.required_value
        
        # Calculate progress
        progress = min(1.0, balance_days / achievement.required_value) if achievement.required_value > 0 else 0.0
        
        # Return updated achievement
        updated = Achievement(
            **achievement.model_dump(),
            progress=progress,
            is_unlocked=is_unlocked,
            unlocked_at=datetime.utcnow() if is_unlocked and not achievement.unlocked_at else achievement.unlocked_at
        )
        
        # Preserve the ID
        updated.id = achievement.id
        
        return updated
    
    @staticmethod
    def _calculate_frequency_achievement(
        achievement: Achievement,
        activities: List[Activity]
    ) -> Achievement:
        """Calculate progress for frequency-based achievements"""
        # Frequency achievements are based on total number of activities logged
        activity_count = len(activities)
        
        # Check if the achievement is unlocked
        is_unlocked = achievement.is_unlocked or activity_count >= achievement.required_value
        
        # Calculate progress
        progress = min(1.0, activity_count / achievement.required_value) if achievement.required_value > 0 else 0.0
        
        # Return updated achievement
        updated = Achievement(
            **achievement.model_dump(),
            progress=progress,
            is_unlocked=is_unlocked,
            unlocked_at=datetime.utcnow() if is_unlocked and not achievement.unlocked_at else achievement.unlocked_at
        )
        
        # Preserve the ID
        updated.id = achievement.id
        
        return updated
    
    @staticmethod
    def _calculate_milestone_achievement(
        achievement: Achievement,
        activities: List[Activity]
    ) -> Achievement:
        """Calculate progress for milestone-based achievements"""
        # Milestone achievements are based on total time spent
        total_minutes = sum(a.duration for a in activities)
        
        # Check if the achievement is unlocked
        is_unlocked = achievement.is_unlocked or total_minutes >= achievement.required_value
        
        # Calculate progress
        progress = min(1.0, total_minutes / achievement.required_value) if achievement.required_value > 0 else 0.0
        
        # Return updated achievement
        updated = Achievement(
            **achievement.model_dump(),
            progress=progress,
            is_unlocked=is_unlocked,
            unlocked_at=datetime.utcnow() if is_unlocked and not achievement.unlocked_at else achievement.unlocked_at
        )
        
        # Preserve the ID
        updated.id = achievement.id
        
        return updated
    
    @classmethod
    def _calculate_special_achievement(
        cls,
        achievement: Achievement,
        activities: List[Activity],
        values: List[Value]
    ) -> Achievement:
        """Calculate progress for special achievements"""
        if achievement.achievement_id == "special_balanced_all":
            return cls._calculate_perfect_harmony_achievement(achievement, activities, values)
        
        elif achievement.achievement_id == "special_comeback":
            return cls._calculate_comeback_achievement(achievement, activities)
        
        # Unknown special achievement
        else:
            logger.warning(f"Unknown special achievement: {achievement.achievement_id}")
            return achievement
    
    @staticmethod
    def _calculate_perfect_harmony_achievement(
        achievement: Achievement,
        activities: List[Activity],
        values: List[Value]
    ) -> Achievement:
        """Calculate the 'Perfect Harmony' achievement - at least one activity for each value"""
        if not values or not activities:
            return achievement
        
        # Get values that have activities
        value_ids_with_activities = {a.value_id for a in activities}
        
        # Count active values with activities
        active_values = [v for v in values if v.active]
        values_with_activities = sum(1 for v in active_values if str(v.id) in value_ids_with_activities)
        total_active_values = len(active_values)
        
        if total_active_values == 0:
            return achievement
        
        # Perfect harmony achieved when all active values have activities
        is_unlocked = achievement.is_unlocked or (values_with_activities == total_active_values and total_active_values >= 3)
        
        # Calculate progress
        progress = values_with_activities / total_active_values if total_active_values > 0 else 0.0
        
        # Return updated achievement
        updated = Achievement(
            **achievement.model_dump(),
            progress=progress,
            is_unlocked=is_unlocked,
            unlocked_at=datetime.utcnow() if is_unlocked and not achievement.unlocked_at else achievement.unlocked_at
        )
        
        # Preserve the ID
        updated.id = achievement.id
        
        return updated
    
    @staticmethod
    def _calculate_comeback_achievement(
        achievement: Achievement,
        activities: List[Activity]
    ) -> Achievement:
        """Calculate the 'Comeback Kid' achievement - return after 2-week break"""
        if not activities or len(activities) < 2:
            return achievement
        
        # Sort activities by date
        sorted_activities = sorted(activities, key=lambda a: a.date)
        
        # Check for gaps of at least 14 days followed by new activity
        found_comeback = False
        longest_break_progress = 0.0
        
        last_activity_date = None
        for activity in sorted_activities:
            current_date = activity.date
            
            if last_activity_date:
                gap = (current_date - last_activity_date).days
                
                # Update longest break progress
                gap_progress = min(1.0, gap / 14)
                if gap_progress > longest_break_progress:
                    longest_break_progress = gap_progress
                
                # Check if this is a comeback (gap of 14+ days)
                if gap >= 14:
                    found_comeback = True
            
            last_activity_date = current_date
        
        # Return updated achievement
        updated = Achievement(
            **achievement.model_dump(),
            progress=longest_break_progress,
            is_unlocked=achievement.is_unlocked or found_comeback,
            unlocked_at=datetime.utcnow() if found_comeback and not achievement.unlocked_at else achievement.unlocked_at
        )
        
        # Preserve the ID
        updated.id = achievement.id
        
        return updated