# app/services/habit_suggestion_service.py
import asyncio
import logging
import random
from datetime import datetime, timedelta, timezone
from typing import Dict, List, Any, Optional, Tuple
from collections import defaultdict, Counter
import numpy as np

from ..models.user import User
from ..models.activity import Activity
from ..models.value import Value
from ..models.habit_suggestion import (
    HabitTemplate, PersonalizedSuggestion, SuggestionFeedback, 
    HabitRecommendationConfig, SuggestionType, SuggestionCategory, 
    DifficultyLevel
)
from ..services.ml_prediction_service import MLPredictionService

logger = logging.getLogger(__name__)

class HabitSuggestionService:
    """Intelligent habit suggestion service using ML and behavioral analysis"""
    
    def __init__(self):
        self.config = None
        self._config_cache_time = None
        self._config_cache_duration = timedelta(minutes=30)
    
    async def get_config(self) -> HabitRecommendationConfig:
        """Get current configuration with caching"""
        now = datetime.utcnow()
        
        if (self.config is None or 
            self._config_cache_time is None or 
            now - self._config_cache_time > self._config_cache_duration):
            
            config = await HabitRecommendationConfig.find_one(
                HabitRecommendationConfig.is_active == True
            )
            
            if not config:
                # Create default config
                config = await self._create_default_config()
            
            self.config = config
            self._config_cache_time = now
        
        return self.config
    
    async def _create_default_config(self) -> HabitRecommendationConfig:
        """Create default configuration if none exists"""
        config = HabitRecommendationConfig()
        await config.insert()
        return config
    
    async def generate_personalized_suggestions(
        self, 
        user: User, 
        max_suggestions: Optional[int] = None,
        suggestion_types: Optional[List[SuggestionType]] = None
    ) -> List[PersonalizedSuggestion]:
        """Generate personalized habit suggestions for a user"""
        
        try:
            config = await self.get_config()
            max_suggestions = max_suggestions or config.max_suggestions_per_user
            
            logger.info(f"Generating habit suggestions for user {user.id}")
            
            # Get user data for analysis
            user_data = await self._analyze_user_profile(user)
            
            # Get existing suggestions to avoid duplicates
            existing_suggestions = await PersonalizedSuggestion.find(
                PersonalizedSuggestion.user_id == str(user.id),
                PersonalizedSuggestion.dismissed == False,
                PersonalizedSuggestion.adopted == False
            ).to_list()
            
            existing_template_ids = {s.habit_template_id for s in existing_suggestions}
            
            # Generate different types of suggestions
            suggestion_generators = {
                SuggestionType.MICRO_HABIT: self._generate_micro_habit_suggestions,
                SuggestionType.COMPLEMENTARY: self._generate_complementary_suggestions,
                SuggestionType.GOAL_ORIENTED: self._generate_goal_oriented_suggestions,
                SuggestionType.HABIT_STACK: self._generate_habit_stack_suggestions,
                SuggestionType.TIMING_OPTIMIZED: self._generate_timing_optimized_suggestions,
                SuggestionType.RECOVERY: self._generate_recovery_suggestions,
                SuggestionType.PROGRESSIVE: self._generate_progressive_suggestions
            }
            
            # Filter generators based on requested types
            if suggestion_types:
                suggestion_generators = {
                    k: v for k, v in suggestion_generators.items() 
                    if k in suggestion_types
                }
            
            all_suggestions = []
            
            # Generate suggestions from each type
            for suggestion_type, generator in suggestion_generators.items():
                try:
                    suggestions = await generator(user, user_data, existing_template_ids)
                    all_suggestions.extend(suggestions)
                except Exception as e:
                    logger.error(f"Error generating {suggestion_type} suggestions: {e}")
                    continue
            
            # Score and rank all suggestions
            scored_suggestions = await self._score_suggestions(user, user_data, all_suggestions)
            
            # Select top suggestions with diversity
            final_suggestions = await self._select_diverse_suggestions(
                scored_suggestions, max_suggestions
            )
            
            # Save suggestions to database
            for suggestion in final_suggestions:
                suggestion.user_id = str(user.id)
                suggestion.created_at = datetime.utcnow()
                suggestion.expires_at = datetime.utcnow() + timedelta(
                    days=config.max_suggestion_lifetime_days
                )
                await suggestion.insert()
            
            logger.info(f"Generated {len(final_suggestions)} suggestions for user {user.id}")
            return final_suggestions
            
        except Exception as e:
            logger.error(f"Error generating suggestions for user {user.id}: {e}", exc_info=True)
            return []
    
    async def _analyze_user_profile(self, user: User) -> Dict[str, Any]:
        """Analyze user profile to extract preferences and patterns"""
        
        # Get user activities and values
        activities = await Activity.find(
            Activity.user_id == str(user.id)
        ).sort([("date", -1)]).limit(100).to_list()
        
        values = await Value.find(
            Value.user_id == str(user.id),
            Value.active == True
        ).to_list()
        
        # Get ML predictions if available
        ml_predictions = None
        if len(activities) >= 7:
            try:
                ml_predictions = await MLPredictionService.generate_comprehensive_predictions(
                    user, activities, values
                )
            except Exception as e:
                logger.warning(f"Could not get ML predictions for user {user.id}: {e}")
        
        # Analyze activity patterns
        activity_patterns = self._analyze_activity_patterns(activities)
        value_preferences = self._analyze_value_preferences(values, activities)
        
        # Determine user segment and preferences
        user_segment = ml_predictions.get("user_segmentation", {}) if ml_predictions else {}
        timing_preferences = ml_predictions.get("optimal_timing", {}) if ml_predictions else {}
        
        # Calculate user metrics
        metrics = {
            "total_activities": len(activities),
            "avg_session_duration": np.mean([a.duration for a in activities]) if activities else 15,
            "consistency_score": self._calculate_consistency_score(activities),
            "preferred_difficulty": self._infer_preferred_difficulty(activities),
            "time_availability": self._estimate_time_availability(user, activities),
            "motivation_level": self._assess_motivation_level(activities, user),
        }
        
        return {
            "activities": activities,
            "values": values,
            "activity_patterns": activity_patterns,
            "value_preferences": value_preferences,
            "user_segment": user_segment,
            "timing_preferences": timing_preferences,
            "ml_predictions": ml_predictions,
            "metrics": metrics,
            "user_age_days": (datetime.utcnow() - user.created_at).days
        }
    
    def _analyze_activity_patterns(self, activities: List[Activity]) -> Dict[str, Any]:
        """Analyze patterns in user's activities"""
        
        if not activities:
            return {"has_patterns": False}
        
        # Time patterns
        hours = [a.date.hour for a in activities]
        days_of_week = [a.date.weekday() for a in activities]
        durations = [a.duration for a in activities]
        
        # Calculate patterns
        patterns = {
            "has_patterns": True,
            "preferred_hours": Counter(hours).most_common(3),
            "preferred_days": Counter(days_of_week).most_common(3),
            "avg_duration": np.mean(durations),
            "duration_variance": np.var(durations),
            "total_unique_days": len(set(a.date.date() for a in activities)),
            "recent_activity_count": len([a for a in activities if (datetime.utcnow() - a.date).days <= 7]),
        }
        
        return patterns
    
    def _analyze_value_preferences(self, values: List[Value], activities: List[Activity]) -> Dict[str, Any]:
        """Analyze user's value preferences and activity alignment"""
        
        if not values:
            return {"has_values": False}
        
        # Create value map
        value_map = {str(v.id): v for v in values}
        
        # Analyze value usage
        value_activity_counts = defaultdict(int)
        value_durations = defaultdict(list)
        
        for activity in activities:
            for value_id in activity.effective_value_ids:
                if value_id in value_map:
                    value_activity_counts[value_id] += 1
                    value_durations[value_id].append(activity.duration)
        
        # Calculate value preferences
        preferences = {
            "has_values": True,
            "total_values": len(values),
            "high_importance_values": [v for v in values if v.importance >= 4],
            "most_active_values": sorted(
                value_activity_counts.items(), 
                key=lambda x: x[1], 
                reverse=True
            )[:3],
            "underused_values": [
                str(v.id) for v in values 
                if v.importance >= 4 and value_activity_counts.get(str(v.id), 0) < 3
            ],
            "value_categories": self._categorize_values(values)
        }
        
        return preferences
    
    def _categorize_values(self, values: List[Value]) -> Dict[str, int]:
        """Categorize values into habit categories"""
        
        category_keywords = {
            SuggestionCategory.HEALTH_FITNESS: ["health", "fitness", "exercise", "wellness", "physical"],
            SuggestionCategory.MINDFULNESS: ["mindfulness", "meditation", "peace", "calm", "spiritual"],
            SuggestionCategory.PRODUCTIVITY: ["productivity", "work", "efficiency", "focus", "achievement"],
            SuggestionCategory.RELATIONSHIPS: ["family", "friends", "relationship", "social", "love"],
            SuggestionCategory.LEARNING: ["learning", "education", "growth", "knowledge", "skill"],
            SuggestionCategory.CREATIVITY: ["creativity", "art", "music", "writing", "imagination"],
            SuggestionCategory.SELF_CARE: ["self-care", "relaxation", "rest", "personal", "comfort"],
            SuggestionCategory.CAREER: ["career", "professional", "business", "success", "leadership"],
            SuggestionCategory.FINANCE: ["money", "finance", "saving", "investment", "financial"],
            SuggestionCategory.ENVIRONMENT: ["environment", "nature", "green", "sustainability", "earth"]
        }
        
        category_counts = defaultdict(int)
        
        for value in values:
            value_text = f"{value.name} {value.description or ''}".lower()
            
            for category, keywords in category_keywords.items():
                if any(keyword in value_text for keyword in keywords):
                    category_counts[category.value] += value.importance
        
        return dict(category_counts)
    
    def _calculate_consistency_score(self, activities: List[Activity]) -> float:
        """Calculate consistency score from 0 to 1"""
        
        if not activities:
            return 0.0
        
        # Get unique dates in last 30 days
        now = datetime.utcnow()
        recent_activities = [
            a for a in activities 
            if (now - a.date).days <= 30
        ]
        
        if not recent_activities:
            return 0.0
        
        unique_dates = len(set(a.date.date() for a in recent_activities))
        possible_days = min(30, (now - min(recent_activities, key=lambda x: x.date).date).days + 1)
        
        return min(unique_dates / possible_days, 1.0)
    
    def _infer_preferred_difficulty(self, activities: List[Activity]) -> DifficultyLevel:
        """Infer user's preferred difficulty level based on activity durations"""
        
        if not activities:
            return DifficultyLevel.EASY
        
        avg_duration = np.mean([a.duration for a in activities])
        
        if avg_duration <= 2:
            return DifficultyLevel.VERY_EASY
        elif avg_duration <= 10:
            return DifficultyLevel.EASY
        elif avg_duration <= 30:
            return DifficultyLevel.MEDIUM
        elif avg_duration <= 60:
            return DifficultyLevel.HARD
        else:
            return DifficultyLevel.VERY_HARD
    
    def _estimate_time_availability(self, user: User, activities: List[Activity]) -> Dict[str, int]:
        """Estimate user's time availability in different periods"""
        
        if not activities:
            return {"morning": 30, "afternoon": 30, "evening": 30}
        
        # Analyze activity timing patterns
        time_slots = {"morning": [], "afternoon": [], "evening": []}
        
        for activity in activities:
            hour = activity.date.hour
            duration = activity.duration
            
            if 5 <= hour < 12:
                time_slots["morning"].append(duration)
            elif 12 <= hour < 18:
                time_slots["afternoon"].append(duration)
            else:
                time_slots["evening"].append(duration)
        
        # Estimate availability based on patterns
        availability = {}
        for period, durations in time_slots.items():
            if durations:
                # Use 80th percentile of durations as availability estimate
                availability[period] = int(np.percentile(durations, 80))
            else:
                availability[period] = 30  # Default 30 minutes
        
        return availability
    
    def _assess_motivation_level(self, activities: List[Activity], user: User) -> float:
        """Assess user's current motivation level from 0 to 1"""
        
        if not activities:
            return 0.5
        
        recent_activities = [
            a for a in activities 
            if (datetime.utcnow() - a.date).days <= 7
        ]
        
        factors = []
        
        # Recent activity frequency
        factors.append(min(len(recent_activities) / 7, 1.0))
        
        # Account age impact (newer users might be more motivated)
        days_since_signup = (datetime.utcnow() - user.created_at).days
        novelty_factor = max(0.2, 1.0 - (days_since_signup / 90))  # Decreases over 90 days
        factors.append(novelty_factor)
        
        # Consistency factor
        if len(activities) >= 14:
            consistency = self._calculate_consistency_score(activities)
            factors.append(consistency)
        
        return np.mean(factors)
    
    async def _generate_micro_habit_suggestions(
        self, 
        user: User, 
        user_data: Dict[str, Any], 
        existing_template_ids: set
    ) -> List[PersonalizedSuggestion]:
        """Generate micro-habit suggestions (1-5 minute habits)"""
        
        suggestions = []
        
        # Find very easy templates that match user's values
        templates = await HabitTemplate.find(
            HabitTemplate.difficulty_level == DifficultyLevel.VERY_EASY,
            HabitTemplate.is_active == True
        ).to_list()
        
        # Filter based on user preferences
        user_categories = user_data["value_preferences"].get("value_categories", {})
        
        for template in templates:
            if str(template.id) in existing_template_ids:
                continue
            
            # Check if template category aligns with user values
            category_score = user_categories.get(template.category.value, 0)
            
            if category_score > 0 or template.popularity_score > 0.7:
                suggestion = PersonalizedSuggestion(
                    habit_template_id=str(template.id),
                    suggestion_type=SuggestionType.MICRO_HABIT,
                    suggested_duration=min(template.estimated_duration, 5),  # Cap at 5 minutes
                    compatibility_score=min(category_score / 10, 1.0),
                    success_probability=0.8,  # Micro habits have high success rate
                    reasons=[
                        "Start small to build momentum",
                        "Perfect for beginners or busy schedules",
                        "Easy to maintain consistency"
                    ]
                )
                
                suggestions.append(suggestion)
        
        return suggestions[:3]  # Limit to top 3
    
    async def _generate_complementary_suggestions(
        self, 
        user: User, 
        user_data: Dict[str, Any], 
        existing_template_ids: set
    ) -> List[PersonalizedSuggestion]:
        """Generate suggestions that complement existing habits"""
        
        suggestions = []
        
        # Analyze user's current activity categories
        activities = user_data["activities"]
        if not activities:
            return suggestions
        
        current_categories = set()
        value_map = {str(v.id): v for v in user_data["values"]}
        
        # Determine what categories user is already active in
        for activity in activities:
            for value_id in activity.effective_value_ids:
                if value_id in value_map:
                    value = value_map[value_id]
                    # Simple category mapping based on value name
                    category = self._map_value_to_category(value)
                    if category:
                        current_categories.add(category)
        
        # Find templates in categories user isn't active in
        all_categories = set(SuggestionCategory)
        missing_categories = all_categories - current_categories
        
        for missing_category in missing_categories:
            templates = await HabitTemplate.find(
                HabitTemplate.category == missing_category,
                HabitTemplate.is_active == True
            ).sort([("popularity_score", -1)]).limit(2).to_list()
            
            for template in templates:
                if str(template.id) in existing_template_ids:
                    continue
                
                suggestion = PersonalizedSuggestion(
                    habit_template_id=str(template.id),
                    suggestion_type=SuggestionType.COMPLEMENTARY,
                    suggested_duration=template.estimated_duration,
                    compatibility_score=0.6,  # Moderate since it's new territory
                    success_probability=0.5,
                    reasons=[
                        f"Expand into {missing_category.value.replace('_', ' ')} for balanced growth",
                        "Complement your existing habits",
                        "Diversify your personal development"
                    ]
                )
                
                suggestions.append(suggestion)
        
        return suggestions[:4]  # Limit to top 4
    
    def _map_value_to_category(self, value: Value) -> Optional[SuggestionCategory]:
        """Map a value to a suggestion category"""
        
        value_text = f"{value.name} {value.description or ''}".lower()
        
        category_keywords = {
            SuggestionCategory.HEALTH_FITNESS: ["health", "fitness", "exercise", "wellness"],
            SuggestionCategory.MINDFULNESS: ["mindfulness", "meditation", "peace", "calm"],
            SuggestionCategory.PRODUCTIVITY: ["productivity", "work", "efficiency", "focus"],
            SuggestionCategory.RELATIONSHIPS: ["family", "friends", "relationship", "social"],
            SuggestionCategory.LEARNING: ["learning", "education", "growth", "knowledge"],
        }
        
        for category, keywords in category_keywords.items():
            if any(keyword in value_text for keyword in keywords):
                return category
        
        return None
    
    async def _generate_goal_oriented_suggestions(
        self, 
        user: User, 
        user_data: Dict[str, Any], 
        existing_template_ids: set
    ) -> List[PersonalizedSuggestion]:
        """Generate suggestions based on user's goals and high-importance values"""
        
        suggestions = []
        
        # Focus on high-importance values that are underused
        high_importance_values = user_data["value_preferences"].get("high_importance_values", [])
        underused_values = set(user_data["value_preferences"].get("underused_values", []))
        
        target_values = [v for v in high_importance_values if str(v.id) in underused_values]
        
        for value in target_values:
            # Find templates that align with this value
            category = self._map_value_to_category(value)
            if not category:
                continue
            
            templates = await HabitTemplate.find(
                HabitTemplate.category == category,
                HabitTemplate.is_active == True
            ).sort([("effectiveness_rating", -1)]).limit(2).to_list()
            
            for template in templates:
                if str(template.id) in existing_template_ids:
                    continue
                
                suggestion = PersonalizedSuggestion(
                    habit_template_id=str(template.id),
                    suggestion_type=SuggestionType.GOAL_ORIENTED,
                    suggested_duration=template.estimated_duration,
                    related_value_ids=[str(value.id)],
                    compatibility_score=0.8,  # High since it matches important values
                    success_probability=0.7,
                    urgency_score=0.6,  # Higher urgency for important underused values
                    reasons=[
                        f"Align with your important value: {value.name}",
                        "Focus on areas that matter most to you",
                        "Build habits that support your core priorities"
                    ]
                )
                
                suggestions.append(suggestion)
        
        return suggestions[:3]
    
    async def _generate_habit_stack_suggestions(
        self, 
        user: User, 
        user_data: Dict[str, Any], 
        existing_template_ids: set
    ) -> List[PersonalizedSuggestion]:
        """Generate habit stacking suggestions based on existing patterns"""
        
        suggestions = []
        
        # Analyze existing activity patterns for stacking opportunities
        activities = user_data["activities"]
        if len(activities) < 5:
            return suggestions
        
        # Find the most consistent existing habits (by time/pattern)
        time_patterns = defaultdict(list)
        for activity in activities[-30:]:  # Last 30 activities
            hour_slot = activity.date.hour // 2 * 2  # Group into 2-hour slots
            time_patterns[hour_slot].append(activity)
        
        # Find strong time patterns (3+ activities in same time slot)
        strong_patterns = {
            time_slot: activities_list 
            for time_slot, activities_list in time_patterns.items() 
            if len(activities_list) >= 3
        }
        
        for time_slot, pattern_activities in strong_patterns.items():
            # Get common duration for this time slot
            avg_duration = np.mean([a.duration for a in pattern_activities])
            
            # Find short templates that could stack with this pattern
            suitable_duration = min(avg_duration // 2, 15)  # Half the usual time or max 15 min
            
            templates = await HabitTemplate.find(
                HabitTemplate.estimated_duration <= suitable_duration,
                HabitTemplate.is_active == True
            ).sort([("popularity_score", -1)]).limit(3).to_list()
            
            for template in templates:
                if str(template.id) in existing_template_ids:
                    continue
                
                time_label = f"{time_slot:02d}:00-{(time_slot+2):02d}:00"
                
                suggestion = PersonalizedSuggestion(
                    habit_template_id=str(template.id),
                    suggestion_type=SuggestionType.HABIT_STACK,
                    suggested_duration=template.estimated_duration,
                    suggested_times=[time_label],
                    compatibility_score=0.7,
                    success_probability=0.75,  # Higher success with stacking
                    reasons=[
                        f"Stack with your existing {time_label} routine",
                        "Use established habits as triggers",
                        "Maximize your existing momentum"
                    ]
                )
                
                suggestions.append(suggestion)
        
        return suggestions[:2]  # Limit to top 2
    
    async def _generate_timing_optimized_suggestions(
        self, 
        user: User, 
        user_data: Dict[str, Any], 
        existing_template_ids: set
    ) -> List[PersonalizedSuggestion]:
        """Generate suggestions optimized for user's best performing times"""
        
        suggestions = []
        
        timing_prefs = user_data.get("timing_preferences", {})
        if not timing_prefs:
            return suggestions
        
        optimal_hours = timing_prefs.get("optimal_hours", [])
        if not optimal_hours:
            return suggestions
        
        # Get the best performing hour
        best_hour = optimal_hours[0] if optimal_hours else {"hour": 9}
        time_availability = user_data["metrics"]["time_availability"]
        
        # Determine time period
        hour = best_hour.get("hour", 9)
        if 5 <= hour < 12:
            period = "morning"
            period_templates = ["morning_routine", "energy_boosting"]
        elif 12 <= hour < 18:
            period = "afternoon"
            period_templates = ["productivity", "focus"]
        else:
            period = "evening"
            period_templates = ["relaxation", "reflection"]
        
        available_time = time_availability.get(period, 30)
        
        # Find templates suitable for this time period and duration
        templates = await HabitTemplate.find(
            HabitTemplate.estimated_duration <= available_time,
            HabitTemplate.is_active == True
        ).to_list()
        
        # Filter templates that work well in this time period
        suitable_templates = [
            t for t in templates 
            if period in t.optimal_time_of_day or not t.optimal_time_of_day
        ]
        
        for template in suitable_templates[:3]:
            if str(template.id) in existing_template_ids:
                continue
            
            suggestion = PersonalizedSuggestion(
                habit_template_id=str(template.id),
                suggestion_type=SuggestionType.TIMING_OPTIMIZED,
                suggested_duration=min(template.estimated_duration, available_time),
                suggested_times=[f"{hour:02d}:00"],
                compatibility_score=0.8,  # High since it's optimized timing
                success_probability=0.8,
                reasons=[
                    f"Optimized for your peak {period} performance",
                    f"Fits your available {available_time}-minute window",
                    "Schedule when you're most likely to succeed"
                ]
            )
            
            suggestions.append(suggestion)
        
        return suggestions
    
    async def _generate_recovery_suggestions(
        self, 
        user: User, 
        user_data: Dict[str, Any], 
        existing_template_ids: set
    ) -> List[PersonalizedSuggestion]:
        """Generate suggestions for users recovering from broken streaks"""
        
        suggestions = []
        
        # Check if user has recent broken streaks or low motivation
        motivation_level = user_data["metrics"]["motivation_level"]
        consistency_score = user_data["metrics"]["consistency_score"]
        
        # Only suggest recovery habits if user seems to be struggling
        if motivation_level > 0.7 and consistency_score > 0.5:
            return suggestions
        
        # Find recovery-friendly templates (easy, short, proven)
        templates = await HabitTemplate.find(
            HabitTemplate.difficulty_level.in_([DifficultyLevel.VERY_EASY, DifficultyLevel.EASY]),
            HabitTemplate.estimated_duration <= 10,
            HabitTemplate.effectiveness_rating >= 3.5,
            HabitTemplate.is_active == True
        ).sort([("success_rate", -1)]).limit(5).to_list()
        
        for template in templates:
            if str(template.id) in existing_template_ids:
                continue
            
            suggestion = PersonalizedSuggestion(
                habit_template_id=str(template.id),
                suggestion_type=SuggestionType.RECOVERY,
                suggested_duration=min(template.estimated_duration, 5),  # Extra short
                suggested_frequency="3-4 times per week",  # Gentler frequency
                compatibility_score=0.6,
                success_probability=0.9,  # Very high for recovery
                urgency_score=0.8,  # High urgency for recovery
                reasons=[
                    "Gentle restart to rebuild momentum",
                    "Designed for consistency over intensity",
                    "Get back on track with small wins"
                ]
            )
            
            suggestions.append(suggestion)
        
        return suggestions[:2]
    
    async def _generate_progressive_suggestions(
        self, 
        user: User, 
        user_data: Dict[str, Any], 
        existing_template_ids: set
    ) -> List[PersonalizedSuggestion]:
        """Generate progressive suggestions for advancing users"""
        
        suggestions = []
        
        # Only for users with good consistency and motivation
        consistency_score = user_data["metrics"]["consistency_score"]
        motivation_level = user_data["metrics"]["motivation_level"]
        
        if consistency_score < 0.6 or motivation_level < 0.6:
            return suggestions
        
        # Find more challenging templates in user's active categories
        current_difficulty = user_data["metrics"]["preferred_difficulty"]
        
        # Suggest one level higher difficulty
        next_difficulty = self._get_next_difficulty_level(current_difficulty)
        if not next_difficulty:
            return suggestions
        
        templates = await HabitTemplate.find(
            HabitTemplate.difficulty_level == next_difficulty,
            HabitTemplate.is_active == True
        ).sort([("effectiveness_rating", -1)]).limit(4).to_list()
        
        for template in templates:
            if str(template.id) in existing_template_ids:
                continue
            
            suggestion = PersonalizedSuggestion(
                habit_template_id=str(template.id),
                suggestion_type=SuggestionType.PROGRESSIVE,
                suggested_duration=template.estimated_duration,
                compatibility_score=0.7,
                success_probability=0.6,  # Lower since it's more challenging
                reasons=[
                    "Challenge yourself with the next level",
                    f"Progress from {current_difficulty.value} to {next_difficulty.value}",
                    "Build on your consistent foundation"
                ]
            )
            
            suggestions.append(suggestion)
        
        return suggestions[:2]
    
    def _get_next_difficulty_level(self, current: DifficultyLevel) -> Optional[DifficultyLevel]:
        """Get the next difficulty level"""
        
        progression = {
            DifficultyLevel.VERY_EASY: DifficultyLevel.EASY,
            DifficultyLevel.EASY: DifficultyLevel.MEDIUM,
            DifficultyLevel.MEDIUM: DifficultyLevel.HARD,
            DifficultyLevel.HARD: DifficultyLevel.VERY_HARD,
            DifficultyLevel.VERY_HARD: None
        }
        
        return progression.get(current)
    
    async def _score_suggestions(
        self, 
        user: User, 
        user_data: Dict[str, Any], 
        suggestions: List[PersonalizedSuggestion]
    ) -> List[PersonalizedSuggestion]:
        """Score and rank all suggestions"""
        
        config = await self.get_config()
        
        for suggestion in suggestions:
            # Get template for additional scoring
            template = await HabitTemplate.get(suggestion.habit_template_id)
            if not template:
                suggestion.compatibility_score = 0.0
                continue
            
            # Calculate composite score
            scores = {
                "compatibility": suggestion.compatibility_score * config.compatibility_weight,
                "success_probability": suggestion.success_probability * config.success_probability_weight,
                "urgency": suggestion.urgency_score * config.urgency_weight,
                "popularity": template.popularity_score * config.popularity_weight,
                "novelty": self._calculate_novelty_score(template, user_data) * config.novelty_weight
            }
            
            # Store scoring details
            suggestion.personalization_factors = scores
            
            # Calculate final composite score
            final_score = sum(scores.values())
            suggestion.compatibility_score = min(final_score, 1.0)
        
        # Sort by score
        return sorted(suggestions, key=lambda x: x.compatibility_score, reverse=True)
    
    def _calculate_novelty_score(self, template: HabitTemplate, user_data: Dict[str, Any]) -> float:
        """Calculate how novel/fresh this suggestion is for the user"""
        
        # Check if user has done similar activities
        activities = user_data["activities"]
        template_tags = set(template.tags)
        
        if not activities or not template_tags:
            return 0.7  # Moderate novelty by default
        
        # Check overlap with user's activity patterns
        user_patterns = set()
        for activity in activities:
            # Simple keyword extraction from activity names
            keywords = activity.name.lower().split()
            user_patterns.update(keywords)
        
        overlap = len(template_tags.intersection(user_patterns))
        max_overlap = max(len(template_tags), len(user_patterns))
        
        if max_overlap == 0:
            return 0.7
        
        # Higher novelty for less overlap
        novelty = 1.0 - (overlap / max_overlap)
        return max(0.1, novelty)  # Minimum novelty of 0.1
    
    async def _select_diverse_suggestions(
        self, 
        scored_suggestions: List[PersonalizedSuggestion], 
        max_suggestions: int
    ) -> List[PersonalizedSuggestion]:
        """Select diverse suggestions to avoid too much similarity"""
        
        if len(scored_suggestions) <= max_suggestions:
            return scored_suggestions
        
        selected = []
        used_types = set()
        used_categories = set()
        
        # First pass: select top suggestions with type diversity
        for suggestion in scored_suggestions:
            if len(selected) >= max_suggestions:
                break
            
            template = await HabitTemplate.get(suggestion.habit_template_id)
            if not template:
                continue
            
            # Prefer diverse types and categories
            type_penalty = 0.1 if suggestion.suggestion_type in used_types else 0
            category_penalty = 0.1 if template.category in used_categories else 0
            
            adjusted_score = suggestion.compatibility_score - type_penalty - category_penalty
            
            if adjusted_score >= 0.3:  # Minimum threshold
                selected.append(suggestion)
                used_types.add(suggestion.suggestion_type)
                used_categories.add(template.category)
        
        # Fill remaining slots with highest scoring
        if len(selected) < max_suggestions:
            remaining = max_suggestions - len(selected)
            for suggestion in scored_suggestions:
                if suggestion not in selected:
                    selected.append(suggestion)
                    remaining -= 1
                    if remaining <= 0:
                        break
        
        return selected[:max_suggestions]
    
    async def track_suggestion_interaction(
        self, 
        user: User, 
        suggestion_id: str, 
        action: str,
        context: Optional[Dict[str, Any]] = None
    ) -> bool:
        """Track user interaction with suggestions for learning"""
        
        try:
            suggestion = await PersonalizedSuggestion.get(suggestion_id)
            if not suggestion or suggestion.user_id != str(user.id):
                logger.warning(f"Invalid suggestion {suggestion_id} for user {user.id}")
                return False
            
            # Update suggestion based on action
            now = datetime.utcnow()
            
            if action == "viewed":
                suggestion.shown_count += 1
                suggestion.last_shown = now
                
            elif action == "clicked":
                suggestion.clicked = True
                
            elif action == "dismissed":
                suggestion.dismissed = True
                
            elif action == "adopted":
                suggestion.adopted = True
                suggestion.adopted_date = now
            
            await suggestion.save()
            
            # Record feedback for ML training
            feedback = SuggestionFeedback(
                user_id=str(user.id),
                suggestion_id=suggestion_id,
                habit_template_id=suggestion.habit_template_id,
                action=action,
                user_context=context or {},
                suggestion_context={
                    "suggestion_type": suggestion.suggestion_type,
                    "compatibility_score": suggestion.compatibility_score,
                    "success_probability": suggestion.success_probability
                }
            )
            await feedback.insert()
            
            logger.info(f"Tracked {action} for suggestion {suggestion_id} by user {user.id}")
            return True
            
        except Exception as e:
            logger.error(f"Error tracking suggestion interaction: {e}", exc_info=True)
            return False
    
    async def get_user_suggestions(
        self, 
        user: User, 
        limit: Optional[int] = None,
        suggestion_types: Optional[List[SuggestionType]] = None
    ) -> List[PersonalizedSuggestion]:
        """Get active suggestions for a user"""
        
        try:
            query = PersonalizedSuggestion.find(
                PersonalizedSuggestion.user_id == str(user.id),
                PersonalizedSuggestion.dismissed == False,
                PersonalizedSuggestion.adopted == False
            )
            
            # Filter by suggestion types if specified
            if suggestion_types:
                query = query.find(PersonalizedSuggestion.suggestion_type.in_(suggestion_types))
            
            # Filter out expired suggestions
            now = datetime.utcnow()
            query = query.find(
                {"$or": [
                    {"expires_at": {"$exists": False}},
                    {"expires_at": None},
                    {"expires_at": {"$gte": now}}
                ]}
            )
            
            suggestions = await query.sort([
                ("urgency_score", -1),
                ("compatibility_score", -1)
            ]).limit(limit or 20).to_list()
            
            return suggestions
            
        except Exception as e:
            logger.error(f"Error getting user suggestions: {e}", exc_info=True)
            return []
    
    async def refresh_suggestions_if_needed(self, user: User) -> bool:
        """Refresh suggestions if they're stale or user has few active suggestions"""
        
        try:
            # Get current active suggestions
            current_suggestions = await self.get_user_suggestions(user)
            
            config = await self.get_config()
            
            # Check if refresh is needed
            needs_refresh = False
            
            # Not enough active suggestions
            if len(current_suggestions) < config.max_suggestions_per_user // 2:
                needs_refresh = True
                logger.info(f"Refreshing suggestions for user {user.id}: not enough active suggestions")
            
            # Check if suggestions are stale
            if current_suggestions:
                oldest_suggestion = min(current_suggestions, key=lambda x: x.created_at)
                hours_since_oldest = (datetime.utcnow() - oldest_suggestion.created_at).total_seconds() / 3600
                
                if hours_since_oldest > config.suggestion_refresh_hours:
                    needs_refresh = True
                    logger.info(f"Refreshing suggestions for user {user.id}: suggestions are stale")
            
            if needs_refresh:
                await self.generate_personalized_suggestions(user)
                return True
            
            return False
            
        except Exception as e:
            logger.error(f"Error checking if suggestions need refresh for user {user.id}: {e}")
            return False