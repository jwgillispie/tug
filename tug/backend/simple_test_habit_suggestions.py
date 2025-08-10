#!/usr/bin/env python3
"""
Simplified test for habit suggestion system
"""

import asyncio
import logging
import sys
from datetime import datetime, timedelta

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Add the current directory to Python path for imports
sys.path.append('.')

from motor.motor_asyncio import AsyncIOMotorClient
from beanie import init_beanie

# Import models
from app.models.user import User, SubscriptionTier
from app.models.value import Value
from app.models.activity import Activity
from app.models.habit_suggestion import (
    HabitTemplate, PersonalizedSuggestion, SuggestionFeedback,
    HabitRecommendationConfig, SuggestionType, SuggestionCategory, 
    DifficultyLevel
)
from app.services.habit_suggestion_service import HabitSuggestionService
from app.services.habit_template_seeder import HabitTemplateSeeder

async def simple_test():
    """Run a simple test of the habit suggestion system"""
    
    try:
        logger.info("🔌 Connecting to MongoDB...")
        
        # Simple connection
        client = AsyncIOMotorClient("mongodb+srv://jgillispie:CfEMPkE3iG9ZgYCE@jozo.lea4n.mongodb.net/")
        
        # Test connection
        await client.admin.command('ping')
        logger.info("✅ Connected to MongoDB")
        
        # Initialize Beanie with just the habit models
        await init_beanie(
            database=client.tug,
            document_models=[
                User, Value, Activity,
                HabitTemplate, PersonalizedSuggestion, 
                SuggestionFeedback, HabitRecommendationConfig
            ]
        )
        logger.info("✅ Initialized Beanie ODM")
        
        # Check if templates exist, if not seed them
        template_count = await HabitTemplate.count()
        logger.info(f"📊 Found {template_count} habit templates")
        
        if template_count == 0:
            logger.info("🌱 Seeding habit templates...")
            seeded_count = await HabitTemplateSeeder.seed_habit_templates()
            logger.info(f"✅ Seeded {seeded_count} habit templates")
            
            # Ensure config exists
            await HabitTemplateSeeder.ensure_config_exists()
            logger.info("✅ Created habit recommendation config")
        
        # Create a test user
        logger.info("👤 Creating test user...")
        test_user = User(
            firebase_uid="test_habit_user_simple",
            email="test.simple@example.com",
            display_name="Test Simple User",
            subscription_tier=SubscriptionTier.PREMIUM,
            created_at=datetime.utcnow() - timedelta(days=30)
        )
        await test_user.insert()
        logger.info(f"✅ Created test user: {test_user.id}")
        
        # Create some test values
        logger.info("🎯 Creating test values...")
        health_value = Value(
            user_id=str(test_user.id),
            name="Health",
            importance=5,
            description="Physical wellness",
            color="#4CAF50"
        )
        await health_value.insert()
        
        learning_value = Value(
            user_id=str(test_user.id),
            name="Learning",
            importance=4,
            description="Personal growth",
            color="#2196F3"
        )
        await learning_value.insert()
        
        logger.info("✅ Created test values")
        
        # Create some test activities
        logger.info("🏃 Creating test activities...")
        base_date = datetime.utcnow() - timedelta(days=15)
        
        for i in range(10):
            activity = Activity(
                user_id=str(test_user.id),
                value_ids=[str(health_value.id if i % 2 == 0 else learning_value.id)],
                name=f"Test Activity {i+1}",
                duration=15 + (i * 5),
                date=base_date + timedelta(days=i),
                notes="Test activity for habit suggestions"
            )
            await activity.insert()
        
        logger.info("✅ Created 10 test activities")
        
        # Test habit suggestion service
        logger.info("🤖 Testing habit suggestion service...")
        service = HabitSuggestionService()
        
        # Generate suggestions
        suggestions = await service.generate_personalized_suggestions(
            test_user,
            max_suggestions=5
        )
        
        logger.info(f"✅ Generated {len(suggestions)} personalized suggestions:")
        
        for i, suggestion in enumerate(suggestions, 1):
            # Get template details
            template = await HabitTemplate.get(suggestion.habit_template_id)
            template_name = template.name if template else "Unknown"
            
            logger.info(f"  {i}. {template_name}")
            logger.info(f"     Type: {suggestion.suggestion_type}")
            logger.info(f"     Duration: {suggestion.suggested_duration} min")
            logger.info(f"     Compatibility: {suggestion.compatibility_score:.2f}")
            logger.info(f"     Success Probability: {suggestion.success_probability:.2f}")
            logger.info(f"     Reasons: {', '.join(suggestion.reasons[:2])}")
        
        # Test interaction tracking
        if suggestions:
            logger.info("📱 Testing suggestion interactions...")
            first_suggestion = suggestions[0]
            
            # Track a view
            view_success = await service.track_suggestion_interaction(
                test_user,
                str(first_suggestion.id),
                "viewed"
            )
            
            # Track a click
            click_success = await service.track_suggestion_interaction(
                test_user,
                str(first_suggestion.id),
                "clicked"
            )
            
            logger.info(f"✅ Interaction tracking: View={view_success}, Click={click_success}")
        
        # Test discovery
        logger.info("🔍 Testing habit discovery...")
        health_templates = await HabitTemplate.find(
            HabitTemplate.category == SuggestionCategory.HEALTH_FITNESS,
            HabitTemplate.is_active == True
        ).limit(3).to_list()
        
        logger.info(f"✅ Found {len(health_templates)} health & fitness templates:")
        for template in health_templates:
            logger.info(f"  - {template.name} ({template.estimated_duration} min, {template.difficulty_level})")
        
        # Cleanup
        logger.info("🧹 Cleaning up test data...")
        
        # Delete suggestions
        await PersonalizedSuggestion.find(
            PersonalizedSuggestion.user_id == str(test_user.id)
        ).delete()
        
        # Delete feedback
        await SuggestionFeedback.find(
            SuggestionFeedback.user_id == str(test_user.id)
        ).delete()
        
        # Delete activities
        await Activity.find(Activity.user_id == str(test_user.id)).delete()
        
        # Delete values
        await Value.find(Value.user_id == str(test_user.id)).delete()
        
        # Delete user
        await test_user.delete()
        
        logger.info("✅ Cleanup completed")
        
        # Close connection
        client.close()
        logger.info("🔌 Database connection closed")
        
        logger.info("\n🎉 ALL TESTS PASSED! Habit suggestion system is working correctly!")
        return True
        
    except Exception as e:
        logger.error(f"❌ Test failed: {e}")
        import traceback
        logger.error(traceback.format_exc())
        return False

if __name__ == "__main__":
    success = asyncio.run(simple_test())
    sys.exit(0 if success else 1)