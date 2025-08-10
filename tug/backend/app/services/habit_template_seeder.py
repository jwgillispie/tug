# app/services/habit_template_seeder.py
import asyncio
import logging
from typing import List, Dict, Any
from datetime import datetime

from ..models.habit_suggestion import (
    HabitTemplate, HabitRecommendationConfig,
    SuggestionCategory, DifficultyLevel
)

logger = logging.getLogger(__name__)

class HabitTemplateSeeder:
    """Service to seed the database with habit templates"""
    
    @classmethod
    async def seed_habit_templates(cls) -> int:
        """Seed the database with habit templates"""
        
        try:
            # Check if templates already exist
            existing_count = await HabitTemplate.count()
            if existing_count > 0:
                logger.info(f"Found {existing_count} existing habit templates, skipping seed")
                return existing_count
            
            templates = cls._get_template_data()
            
            # Insert all templates
            inserted_templates = []
            for template_data in templates:
                template = HabitTemplate(**template_data)
                await template.insert()
                inserted_templates.append(template)
            
            logger.info(f"Successfully seeded {len(inserted_templates)} habit templates")
            return len(inserted_templates)
            
        except Exception as e:
            logger.error(f"Error seeding habit templates: {e}", exc_info=True)
            return 0
    
    @classmethod
    def _get_template_data(cls) -> List[Dict[str, Any]]:
        """Get the habit template data to seed"""
        
        return [
            # Health & Fitness Templates
            {
                "name": "2-Minute Morning Stretch",
                "description": "Simple stretching routine to wake up your body and improve flexibility",
                "category": SuggestionCategory.HEALTH_FITNESS,
                "difficulty_level": DifficultyLevel.VERY_EASY,
                "estimated_duration": 2,
                "tags": ["stretching", "morning", "flexibility", "wake-up"],
                "value_categories": ["health", "physical", "wellness"],
                "requires_equipment": False,
                "requires_outdoors": False,
                "requires_quiet": False,
                "optimal_time_of_day": ["morning"],
                "success_indicators": ["Improved flexibility", "Better morning energy", "Reduced stiffness"],
                "common_obstacles": ["Forgetting routine", "Being too tired", "Lack of space"],
                "tips_for_success": ["Put stretching mat by bed", "Start with just neck rolls", "Focus on major muscle groups"],
                "good_before_habits": ["coffee", "shower", "breakfast"],
                "good_after_habits": ["meditation", "planning", "exercise"],
                "popularity_score": 0.85,
                "effectiveness_rating": 4.2
            },
            {
                "name": "10,000 Steps Daily",
                "description": "Walk 10,000 steps throughout the day to improve cardiovascular health",
                "category": SuggestionCategory.HEALTH_FITNESS,
                "difficulty_level": DifficultyLevel.MEDIUM,
                "estimated_duration": 60,
                "tags": ["walking", "cardio", "steps", "movement"],
                "value_categories": ["health", "fitness", "energy"],
                "requires_equipment": False,
                "requires_outdoors": False,
                "requires_quiet": False,
                "optimal_time_of_day": ["morning", "afternoon", "evening"],
                "success_indicators": ["Improved energy", "Better sleep", "Weight management"],
                "common_obstacles": ["Weather", "Time constraints", "Motivation"],
                "tips_for_success": ["Use step tracking app", "Take stairs", "Park farther away"],
                "popularity_score": 0.92,
                "effectiveness_rating": 4.5
            },
            {
                "name": "5-Minute Bodyweight Workout",
                "description": "Quick bodyweight exercises: push-ups, squats, planks",
                "category": SuggestionCategory.HEALTH_FITNESS,
                "difficulty_level": DifficultyLevel.EASY,
                "estimated_duration": 5,
                "tags": ["strength", "bodyweight", "quick", "exercise"],
                "value_categories": ["fitness", "strength", "health"],
                "requires_equipment": False,
                "requires_outdoors": False,
                "requires_quiet": False,
                "optimal_time_of_day": ["morning", "afternoon"],
                "success_indicators": ["Increased strength", "Better muscle tone", "Higher energy"],
                "tips_for_success": ["Start with modified versions", "Focus on form", "Track repetitions"],
                "popularity_score": 0.78,
                "effectiveness_rating": 4.3
            },
            
            # Mindfulness Templates
            {
                "name": "3-Minute Breathing Exercise",
                "description": "Simple breathing technique to reduce stress and increase focus",
                "category": SuggestionCategory.MINDFULNESS,
                "difficulty_level": DifficultyLevel.VERY_EASY,
                "estimated_duration": 3,
                "tags": ["breathing", "meditation", "stress-relief", "focus"],
                "value_categories": ["mindfulness", "peace", "calm", "wellness"],
                "requires_equipment": False,
                "requires_outdoors": False,
                "requires_quiet": True,
                "optimal_time_of_day": ["morning", "afternoon", "evening"],
                "success_indicators": ["Reduced stress", "Better focus", "Improved mood"],
                "tips_for_success": ["Use guided apps", "Focus on exhale", "Don't judge thoughts"],
                "good_before_habits": ["work", "meals", "difficult conversations"],
                "good_after_habits": ["journaling", "planning", "sleep"],
                "popularity_score": 0.88,
                "effectiveness_rating": 4.4
            },
            {
                "name": "Gratitude Journaling",
                "description": "Write down three things you're grateful for each day",
                "category": SuggestionCategory.MINDFULNESS,
                "difficulty_level": DifficultyLevel.EASY,
                "estimated_duration": 5,
                "tags": ["gratitude", "journaling", "positivity", "reflection"],
                "value_categories": ["mindfulness", "happiness", "reflection"],
                "requires_equipment": False,
                "requires_outdoors": False,
                "requires_quiet": True,
                "optimal_time_of_day": ["morning", "evening"],
                "success_indicators": ["Improved mood", "Better perspective", "Increased positivity"],
                "tips_for_success": ["Keep journal by bed", "Be specific", "Include small things"],
                "popularity_score": 0.81,
                "effectiveness_rating": 4.6
            },
            {
                "name": "Mindful Walking",
                "description": "Take a 10-minute walk focusing on your surroundings and breathing",
                "category": SuggestionCategory.MINDFULNESS,
                "difficulty_level": DifficultyLevel.EASY,
                "estimated_duration": 10,
                "tags": ["walking", "mindfulness", "nature", "awareness"],
                "value_categories": ["mindfulness", "health", "nature"],
                "requires_equipment": False,
                "requires_outdoors": True,
                "requires_quiet": False,
                "optimal_time_of_day": ["morning", "afternoon", "evening"],
                "success_indicators": ["Reduced stress", "Improved focus", "Better mood"],
                "tips_for_success": ["Leave phone behind", "Focus on senses", "Walk slowly"],
                "popularity_score": 0.75,
                "effectiveness_rating": 4.1
            },
            
            # Productivity Templates
            {
                "name": "Daily Priority Setting",
                "description": "Spend 5 minutes each morning identifying your top 3 priorities",
                "category": SuggestionCategory.PRODUCTIVITY,
                "difficulty_level": DifficultyLevel.EASY,
                "estimated_duration": 5,
                "tags": ["planning", "priorities", "organization", "focus"],
                "value_categories": ["productivity", "work", "efficiency"],
                "requires_equipment": False,
                "requires_outdoors": False,
                "requires_quiet": True,
                "optimal_time_of_day": ["morning"],
                "success_indicators": ["Clearer focus", "Better time management", "Reduced overwhelm"],
                "tips_for_success": ["Use same format daily", "Be realistic", "Review at end of day"],
                "good_before_habits": ["work", "emails", "meetings"],
                "popularity_score": 0.79,
                "effectiveness_rating": 4.3
            },
            {
                "name": "Inbox Zero Check",
                "description": "Process all emails in your inbox to zero or organized folders",
                "category": SuggestionCategory.PRODUCTIVITY,
                "difficulty_level": DifficultyLevel.MEDIUM,
                "estimated_duration": 15,
                "tags": ["email", "organization", "productivity", "communication"],
                "value_categories": ["productivity", "organization", "efficiency"],
                "requires_equipment": False,
                "requires_outdoors": False,
                "requires_quiet": False,
                "optimal_time_of_day": ["morning", "afternoon"],
                "success_indicators": ["Reduced email stress", "Better organization", "Faster responses"],
                "tips_for_success": ["Use 2-minute rule", "Create folders", "Unsubscribe regularly"],
                "popularity_score": 0.68,
                "effectiveness_rating": 3.9
            },
            {
                "name": "Pomodoro Focus Session",
                "description": "25 minutes of focused work followed by a 5-minute break",
                "category": SuggestionCategory.PRODUCTIVITY,
                "difficulty_level": DifficultyLevel.MEDIUM,
                "estimated_duration": 30,
                "tags": ["focus", "productivity", "time-management", "deep-work"],
                "value_categories": ["productivity", "focus", "work"],
                "requires_equipment": False,
                "requires_outdoors": False,
                "requires_quiet": True,
                "optimal_time_of_day": ["morning", "afternoon"],
                "success_indicators": ["Better focus", "Increased productivity", "Less procrastination"],
                "tips_for_success": ["Remove distractions", "Choose specific task", "Honor the break"],
                "popularity_score": 0.82,
                "effectiveness_rating": 4.4
            },
            
            # Learning Templates
            {
                "name": "Read for 15 Minutes",
                "description": "Read books, articles, or educational content for personal growth",
                "category": SuggestionCategory.LEARNING,
                "difficulty_level": DifficultyLevel.EASY,
                "estimated_duration": 15,
                "tags": ["reading", "learning", "knowledge", "growth"],
                "value_categories": ["learning", "growth", "knowledge"],
                "requires_equipment": False,
                "requires_outdoors": False,
                "requires_quiet": True,
                "optimal_time_of_day": ["morning", "evening"],
                "success_indicators": ["Increased knowledge", "Better vocabulary", "Expanded perspective"],
                "tips_for_success": ["Keep book visible", "Set specific time", "Take notes"],
                "popularity_score": 0.86,
                "effectiveness_rating": 4.5
            },
            {
                "name": "Language Learning Practice",
                "description": "Practice a new language using apps or flashcards for 10 minutes",
                "category": SuggestionCategory.LEARNING,
                "difficulty_level": DifficultyLevel.MEDIUM,
                "estimated_duration": 10,
                "tags": ["language", "learning", "practice", "skill-building"],
                "value_categories": ["learning", "skill", "growth"],
                "requires_equipment": False,
                "requires_outdoors": False,
                "requires_quiet": False,
                "optimal_time_of_day": ["morning", "evening"],
                "success_indicators": ["Vocabulary growth", "Better pronunciation", "Increased confidence"],
                "tips_for_success": ["Use spaced repetition", "Practice speaking", "Set small goals"],
                "popularity_score": 0.73,
                "effectiveness_rating": 4.2
            },
            {
                "name": "Learn One New Thing",
                "description": "Spend 10 minutes learning about a topic that interests you",
                "category": SuggestionCategory.LEARNING,
                "difficulty_level": DifficultyLevel.EASY,
                "estimated_duration": 10,
                "tags": ["learning", "curiosity", "knowledge", "exploration"],
                "value_categories": ["learning", "curiosity", "growth"],
                "requires_equipment": False,
                "requires_outdoors": False,
                "requires_quiet": False,
                "optimal_time_of_day": ["afternoon", "evening"],
                "success_indicators": ["Expanded knowledge", "Satisfied curiosity", "New perspectives"],
                "tips_for_success": ["Use reliable sources", "Take notes", "Share what you learned"],
                "popularity_score": 0.71,
                "effectiveness_rating": 3.8
            },
            
            # Relationships Templates
            {
                "name": "Text a Friend",
                "description": "Send a thoughtful message to a friend or family member",
                "category": SuggestionCategory.RELATIONSHIPS,
                "difficulty_level": DifficultyLevel.VERY_EASY,
                "estimated_duration": 2,
                "tags": ["friendship", "communication", "connection", "relationships"],
                "value_categories": ["relationships", "family", "friends", "social"],
                "requires_equipment": False,
                "requires_outdoors": False,
                "requires_quiet": False,
                "optimal_time_of_day": ["afternoon", "evening"],
                "success_indicators": ["Stronger relationships", "Better connections", "Increased support"],
                "tips_for_success": ["Be genuine", "Ask questions", "Share something personal"],
                "popularity_score": 0.84,
                "effectiveness_rating": 4.1
            },
            {
                "name": "Call Someone You Care About",
                "description": "Make a 10-minute phone call to connect with someone important",
                "category": SuggestionCategory.RELATIONSHIPS,
                "difficulty_level": DifficultyLevel.EASY,
                "estimated_duration": 10,
                "tags": ["phone-call", "connection", "relationships", "communication"],
                "value_categories": ["relationships", "family", "friends"],
                "requires_equipment": False,
                "requires_outdoors": False,
                "requires_quiet": True,
                "optimal_time_of_day": ["afternoon", "evening"],
                "success_indicators": ["Deeper connections", "Better relationships", "Emotional support"],
                "tips_for_success": ["Schedule regular calls", "Listen actively", "Be present"],
                "popularity_score": 0.76,
                "effectiveness_rating": 4.3
            },
            {
                "name": "Practice Active Listening",
                "description": "Focus completely on listening during one conversation today",
                "category": SuggestionCategory.RELATIONSHIPS,
                "difficulty_level": DifficultyLevel.MEDIUM,
                "estimated_duration": 15,
                "tags": ["listening", "communication", "empathy", "relationships"],
                "value_categories": ["relationships", "communication", "empathy"],
                "requires_equipment": False,
                "requires_outdoors": False,
                "requires_quiet": False,
                "optimal_time_of_day": ["morning", "afternoon", "evening"],
                "success_indicators": ["Better understanding", "Improved relationships", "Increased empathy"],
                "tips_for_success": ["Put away distractions", "Ask clarifying questions", "Reflect back"],
                "popularity_score": 0.69,
                "effectiveness_rating": 4.2
            },
            
            # Self-Care Templates
            {
                "name": "Take a Relaxing Bath",
                "description": "Enjoy a 20-minute bath to unwind and practice self-care",
                "category": SuggestionCategory.SELF_CARE,
                "difficulty_level": DifficultyLevel.EASY,
                "estimated_duration": 20,
                "tags": ["relaxation", "self-care", "bath", "unwind"],
                "value_categories": ["self-care", "relaxation", "wellness"],
                "requires_equipment": True,
                "requires_outdoors": False,
                "requires_quiet": True,
                "optimal_time_of_day": ["evening"],
                "success_indicators": ["Reduced stress", "Better relaxation", "Improved mood"],
                "tips_for_success": ["Add bath salts", "Play soft music", "No phone allowed"],
                "popularity_score": 0.77,
                "effectiveness_rating": 4.0
            },
            {
                "name": "Skincare Routine",
                "description": "Complete your morning or evening skincare routine mindfully",
                "category": SuggestionCategory.SELF_CARE,
                "difficulty_level": DifficultyLevel.EASY,
                "estimated_duration": 8,
                "tags": ["skincare", "self-care", "routine", "health"],
                "value_categories": ["self-care", "health", "appearance"],
                "requires_equipment": True,
                "requires_outdoors": False,
                "requires_quiet": False,
                "optimal_time_of_day": ["morning", "evening"],
                "success_indicators": ["Better skin health", "Improved routine", "Self-care practice"],
                "tips_for_success": ["Be consistent", "Use quality products", "Take your time"],
                "popularity_score": 0.82,
                "effectiveness_rating": 3.9
            },
            {
                "name": "Digital Detox Hour",
                "description": "Spend one hour without any digital devices or screens",
                "category": SuggestionCategory.SELF_CARE,
                "difficulty_level": DifficultyLevel.HARD,
                "estimated_duration": 60,
                "tags": ["digital-detox", "mindfulness", "offline", "presence"],
                "value_categories": ["self-care", "mindfulness", "balance"],
                "requires_equipment": False,
                "requires_outdoors": False,
                "requires_quiet": False,
                "optimal_time_of_day": ["evening"],
                "success_indicators": ["Better presence", "Reduced screen time", "Improved relationships"],
                "tips_for_success": ["Plan activities", "Inform others", "Start small"],
                "popularity_score": 0.64,
                "effectiveness_rating": 4.1
            },
            
            # Creativity Templates
            {
                "name": "Free Writing",
                "description": "Write continuously for 10 minutes without stopping or editing",
                "category": SuggestionCategory.CREATIVITY,
                "difficulty_level": DifficultyLevel.EASY,
                "estimated_duration": 10,
                "tags": ["writing", "creativity", "expression", "journaling"],
                "value_categories": ["creativity", "expression", "reflection"],
                "requires_equipment": False,
                "requires_outdoors": False,
                "requires_quiet": True,
                "optimal_time_of_day": ["morning", "evening"],
                "success_indicators": ["Improved creativity", "Better self-expression", "Clearer thinking"],
                "tips_for_success": ["Don't edit", "Keep pen moving", "Don't judge content"],
                "popularity_score": 0.71,
                "effectiveness_rating": 4.0
            },
            {
                "name": "Sketch or Doodle",
                "description": "Spend 15 minutes drawing, sketching, or doodling freely",
                "category": SuggestionCategory.CREATIVITY,
                "difficulty_level": DifficultyLevel.EASY,
                "estimated_duration": 15,
                "tags": ["drawing", "art", "creativity", "expression"],
                "value_categories": ["creativity", "art", "expression"],
                "requires_equipment": True,
                "requires_outdoors": False,
                "requires_quiet": False,
                "optimal_time_of_day": ["afternoon", "evening"],
                "success_indicators": ["Enhanced creativity", "Stress relief", "Artistic development"],
                "tips_for_success": ["No pressure for perfection", "Experiment freely", "Focus on enjoyment"],
                "popularity_score": 0.68,
                "effectiveness_rating": 3.8
            },
            {
                "name": "Creative Problem Solving",
                "description": "Approach one challenge in your life with creative thinking techniques",
                "category": SuggestionCategory.CREATIVITY,
                "difficulty_level": DifficultyLevel.MEDIUM,
                "estimated_duration": 20,
                "tags": ["problem-solving", "creativity", "innovation", "thinking"],
                "value_categories": ["creativity", "problem-solving", "growth"],
                "requires_equipment": False,
                "requires_outdoors": False,
                "requires_quiet": True,
                "optimal_time_of_day": ["morning", "afternoon"],
                "success_indicators": ["New perspectives", "Better solutions", "Increased innovation"],
                "tips_for_success": ["Brainstorm freely", "Challenge assumptions", "Think outside the box"],
                "popularity_score": 0.65,
                "effectiveness_rating": 4.1
            },
            
            # Environment Templates
            {
                "name": "Tidy One Space",
                "description": "Organize and clean one small area of your living or work space",
                "category": SuggestionCategory.ENVIRONMENT,
                "difficulty_level": DifficultyLevel.EASY,
                "estimated_duration": 10,
                "tags": ["organizing", "cleaning", "environment", "decluttering"],
                "value_categories": ["environment", "organization", "clarity"],
                "requires_equipment": False,
                "requires_outdoors": False,
                "requires_quiet": False,
                "optimal_time_of_day": ["morning", "afternoon", "evening"],
                "success_indicators": ["Cleaner environment", "Better organization", "Reduced stress"],
                "tips_for_success": ["Start small", "Have designated places", "Do it regularly"],
                "popularity_score": 0.79,
                "effectiveness_rating": 4.0
            },
            {
                "name": "Water a Plant",
                "description": "Check and water your plants, connecting with nature indoors",
                "category": SuggestionCategory.ENVIRONMENT,
                "difficulty_level": DifficultyLevel.VERY_EASY,
                "estimated_duration": 3,
                "tags": ["plants", "nature", "care", "environment"],
                "value_categories": ["environment", "nature", "care"],
                "requires_equipment": True,
                "requires_outdoors": False,
                "requires_quiet": False,
                "optimal_time_of_day": ["morning", "afternoon"],
                "success_indicators": ["Healthier plants", "Connection to nature", "Sense of nurturing"],
                "tips_for_success": ["Check soil moisture", "Use proper amount", "Observe plant health"],
                "popularity_score": 0.74,
                "effectiveness_rating": 3.7
            },
            {
                "name": "Sustainable Action",
                "description": "Take one small action to reduce your environmental impact today",
                "category": SuggestionCategory.ENVIRONMENT,
                "difficulty_level": DifficultyLevel.EASY,
                "estimated_duration": 5,
                "tags": ["sustainability", "environment", "eco-friendly", "conservation"],
                "value_categories": ["environment", "sustainability", "responsibility"],
                "requires_equipment": False,
                "requires_outdoors": False,
                "requires_quiet": False,
                "optimal_time_of_day": ["morning", "afternoon", "evening"],
                "success_indicators": ["Reduced environmental impact", "Increased awareness", "Better habits"],
                "tips_for_success": ["Start with small changes", "Be consistent", "Track your impact"],
                "popularity_score": 0.70,
                "effectiveness_rating": 3.9
            }
        ]
    
    @classmethod
    async def ensure_config_exists(cls) -> HabitRecommendationConfig:
        """Ensure that a habit recommendation config exists"""
        
        try:
            config = await HabitRecommendationConfig.find_one(
                HabitRecommendationConfig.is_active == True
            )
            
            if not config:
                logger.info("Creating default habit recommendation config")
                config = HabitRecommendationConfig()
                await config.insert()
                logger.info("Default habit recommendation config created")
            
            return config
            
        except Exception as e:
            logger.error(f"Error ensuring config exists: {e}", exc_info=True)
            # Create a basic config if there's an error
            config = HabitRecommendationConfig()
            await config.insert()
            return config

# Convenience function to run seeding
async def seed_habit_data():
    """Seed all habit-related data"""
    
    logger.info("Starting habit data seeding...")
    
    # Seed templates
    template_count = await HabitTemplateSeeder.seed_habit_templates()
    
    # Ensure config exists
    config = await HabitTemplateSeeder.ensure_config_exists()
    
    logger.info(f"Habit data seeding complete. Templates: {template_count}, Config: {config.version}")
    
    return {
        "templates_seeded": template_count,
        "config_version": config.version
    }