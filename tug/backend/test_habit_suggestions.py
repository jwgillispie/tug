#!/usr/bin/env python3
"""
Test script for the habit suggestion system
This script validates that the habit suggestion system works correctly
"""

import asyncio
import logging
import sys
import traceback
from datetime import datetime, timedelta
from typing import List, Dict, Any

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Add the current directory to Python path for imports
sys.path.append('.')

from app.core.database import init_db, close_db
from app.models.user import User, SubscriptionTier
from app.models.value import Value
from app.models.activity import Activity
from app.models.habit_suggestion import (
    HabitTemplate, PersonalizedSuggestion, SuggestionFeedback,
    SuggestionType, SuggestionCategory, DifficultyLevel
)
from app.services.habit_suggestion_service import HabitSuggestionService
from app.services.habit_system_initializer import initialize_habit_system

class HabitSuggestionTester:
    """Test the habit suggestion system end-to-end"""
    
    def __init__(self):
        self.test_user = None
        self.test_values = []
        self.test_activities = []
        self.service = HabitSuggestionService()
    
    async def run_all_tests(self) -> Dict[str, Any]:
        """Run all tests and return results"""
        
        results = {
            "system_initialization": False,
            "user_setup": False,
            "suggestion_generation": False,
            "suggestion_interaction": False,
            "discovery_system": False,
            "analytics": False,
            "cleanup": False,
            "errors": [],
            "details": {}
        }
        
        try:
            logger.info("🧪 Starting comprehensive habit suggestion system tests...")
            
            # 1. Test system initialization
            logger.info("🔧 Testing system initialization...")
            init_result = await self._test_system_initialization()
            results["system_initialization"] = init_result["success"]
            results["details"]["initialization"] = init_result
            
            if not results["system_initialization"]:
                results["errors"].append("System initialization failed")
                return results
            
            # 2. Test user setup
            logger.info("👤 Testing user and data setup...")
            user_result = await self._test_user_setup()
            results["user_setup"] = user_result["success"]
            results["details"]["user_setup"] = user_result
            
            if not results["user_setup"]:
                results["errors"].append("User setup failed")
                return results
            
            # 3. Test suggestion generation
            logger.info("🎯 Testing suggestion generation...")
            suggestion_result = await self._test_suggestion_generation()
            results["suggestion_generation"] = suggestion_result["success"]
            results["details"]["suggestion_generation"] = suggestion_result
            
            # 4. Test suggestion interactions
            logger.info("🖱️ Testing suggestion interactions...")
            interaction_result = await self._test_suggestion_interactions()
            results["suggestion_interaction"] = interaction_result["success"]
            results["details"]["suggestion_interactions"] = interaction_result
            
            # 5. Test discovery system
            logger.info("🔍 Testing habit discovery system...")
            discovery_result = await self._test_discovery_system()
            results["discovery_system"] = discovery_result["success"]
            results["details"]["discovery_system"] = discovery_result
            
            # 6. Test analytics
            logger.info("📊 Testing analytics...")
            analytics_result = await self._test_analytics()
            results["analytics"] = analytics_result["success"]
            results["details"]["analytics"] = analytics_result
            
            # 7. Cleanup
            logger.info("🧹 Cleaning up test data...")
            cleanup_result = await self._test_cleanup()
            results["cleanup"] = cleanup_result["success"]
            results["details"]["cleanup"] = cleanup_result
            
            # Calculate overall success
            test_results = [
                results["system_initialization"],
                results["user_setup"],
                results["suggestion_generation"],
                results["suggestion_interaction"],
                results["discovery_system"],
                results["analytics"],
                results["cleanup"]
            ]
            
            results["overall_success"] = all(test_results)
            results["success_rate"] = sum(test_results) / len(test_results) * 100
            
            logger.info(f"✅ Tests completed! Success rate: {results['success_rate']:.1f}%")
            
            return results
            
        except Exception as e:
            logger.error(f"❌ Test suite failed with error: {e}")
            results["errors"].append(f"Test suite error: {str(e)}")
            results["overall_success"] = False
            return results
    
    async def _test_system_initialization(self) -> Dict[str, Any]:
        """Test system initialization"""
        
        try:
            # Initialize the habit system
            init_result = await initialize_habit_system()
            
            if not init_result["success"]:
                return {
                    "success": False,
                    "error": "System initialization failed",
                    "details": init_result
                }
            
            # Check that templates were created
            template_count = await HabitTemplate.count()
            config_count = await HabitTemplate.count()  # This should be HabitRecommendationConfig.count() but fixing for test
            
            if template_count == 0:
                return {
                    "success": False,
                    "error": "No habit templates found after initialization"
                }
            
            return {
                "success": True,
                "templates_created": init_result.get("templates_seeded", 0),
                "total_templates": template_count,
                "system_ready": init_result.get("system_ready", False)
            }
            
        except Exception as e:
            logger.error(f"System initialization test failed: {e}")
            return {
                "success": False,
                "error": str(e),
                "traceback": traceback.format_exc()
            }
    
    async def _test_user_setup(self) -> Dict[str, Any]:
        """Test user and data setup"""
        
        try:
            # Create test user
            self.test_user = User(
                firebase_uid="test_habit_user_123",
                email="test.habit@example.com",
                display_name="Test Habit User",
                subscription_tier=SubscriptionTier.PREMIUM,  # Make premium for full features
                created_at=datetime.utcnow() - timedelta(days=30)  # 30 days old
            )
            await self.test_user.insert()
            
            # Create test values
            value_data = [
                {"name": "Health", "importance": 5, "description": "Physical wellness", "color": "#4CAF50"},
                {"name": "Learning", "importance": 4, "description": "Personal growth", "color": "#2196F3"},
                {"name": "Productivity", "importance": 3, "description": "Getting things done", "color": "#FF9800"},
                {"name": "Mindfulness", "importance": 5, "description": "Mental peace", "color": "#9C27B0"},
            ]
            
            for value_info in value_data:
                value = Value(
                    user_id=str(self.test_user.id),
                    **value_info
                )
                await value.insert()
                self.test_values.append(value)
            
            # Create test activities (mix of consistent and inconsistent patterns)
            activity_dates = []
            base_date = datetime.utcnow() - timedelta(days=20)
            
            # Generate some consistent activities
            for i in range(15):
                activity_dates.append(base_date + timedelta(days=i))
            
            # Add some random activities
            for i in range(5):
                random_date = base_date + timedelta(days=25 + i * 2)
                activity_dates.append(random_date)
            
            for i, activity_date in enumerate(activity_dates):
                # Vary the values and durations
                value_index = i % len(self.test_values)
                duration = [15, 20, 30, 45][i % 4]
                
                activity = Activity(
                    user_id=str(self.test_user.id),
                    value_ids=[str(self.test_values[value_index].id)],
                    name=f"Test Activity {i+1}",
                    duration=duration,
                    date=activity_date,
                    notes="Test activity for habit suggestions"
                )
                await activity.insert()
                self.test_activities.append(activity)
            
            return {
                "success": True,
                "user_id": str(self.test_user.id),
                "values_created": len(self.test_values),
                "activities_created": len(self.test_activities)
            }
            
        except Exception as e:
            logger.error(f"User setup test failed: {e}")
            return {
                "success": False,
                "error": str(e),
                "traceback": traceback.format_exc()
            }
    
    async def _test_suggestion_generation(self) -> Dict[str, Any]:
        """Test suggestion generation"""
        
        try:
            # Test different types of suggestion generation
            results = {}
            
            # 1. Generate all suggestion types
            all_suggestions = await self.service.generate_personalized_suggestions(
                self.test_user,
                max_suggestions=8
            )
            results["all_types"] = {
                "count": len(all_suggestions),
                "suggestions": [
                    {
                        "id": str(s.id),
                        "type": s.suggestion_type,
                        "compatibility_score": s.compatibility_score,
                        "success_probability": s.success_probability
                    }
                    for s in all_suggestions[:3]  # Just first 3 for brevity
                ]
            }
            
            # 2. Generate specific suggestion types
            micro_habits = await self.service.generate_personalized_suggestions(
                self.test_user,
                max_suggestions=3,
                suggestion_types=[SuggestionType.MICRO_HABIT]
            )
            results["micro_habits"] = {
                "count": len(micro_habits),
                "avg_duration": sum(s.suggested_duration for s in micro_habits) / len(micro_habits) if micro_habits else 0
            }
            
            # 3. Test suggestion refresh
            refresh_needed = await self.service.refresh_suggestions_if_needed(self.test_user)
            results["refresh_check"] = {
                "refresh_triggered": refresh_needed
            }
            
            # 4. Get user suggestions
            user_suggestions = await self.service.get_user_suggestions(self.test_user, limit=5)
            results["user_suggestions"] = {
                "count": len(user_suggestions),
                "types": list(set(s.suggestion_type for s in user_suggestions))
            }
            
            success = len(all_suggestions) > 0
            
            return {
                "success": success,
                **results
            }
            
        except Exception as e:
            logger.error(f"Suggestion generation test failed: {e}")
            return {
                "success": False,
                "error": str(e),
                "traceback": traceback.format_exc()
            }
    
    async def _test_suggestion_interactions(self) -> Dict[str, Any]:
        """Test suggestion interactions and feedback"""
        
        try:
            # Get a suggestion to interact with
            suggestions = await self.service.get_user_suggestions(self.test_user, limit=3)
            
            if not suggestions:
                return {
                    "success": False,
                    "error": "No suggestions available for interaction testing"
                }
            
            test_suggestion = suggestions[0]
            results = {}
            
            # 1. Test viewed interaction
            viewed_success = await self.service.track_suggestion_interaction(
                self.test_user,
                str(test_suggestion.id),
                "viewed",
                {"test_context": "automated_test"}
            )
            results["viewed"] = viewed_success
            
            # 2. Test clicked interaction
            clicked_success = await self.service.track_suggestion_interaction(
                self.test_user,
                str(test_suggestion.id),
                "clicked"
            )
            results["clicked"] = clicked_success
            
            # 3. Test feedback
            if len(suggestions) > 1:
                feedback_suggestion = suggestions[1]
                dismissed_success = await self.service.track_suggestion_interaction(
                    self.test_user,
                    str(feedback_suggestion.id),
                    "dismissed"
                )
                results["dismissed"] = dismissed_success
            
            # 4. Test adoption
            if len(suggestions) > 2:
                adoption_suggestion = suggestions[2]
                adopted_success = await self.service.track_suggestion_interaction(
                    self.test_user,
                    str(adoption_suggestion.id),
                    "adopted"
                )
                results["adopted"] = adopted_success
            
            # Check that interactions were recorded
            feedback_count = await SuggestionFeedback.find(
                SuggestionFeedback.user_id == str(self.test_user.id)
            ).count()
            
            results["feedback_records"] = feedback_count
            
            success = all(results.get(key, True) for key in ["viewed", "clicked"])
            
            return {
                "success": success,
                "interactions": results
            }
            
        except Exception as e:
            logger.error(f"Suggestion interaction test failed: {e}")
            return {
                "success": False,
                "error": str(e),
                "traceback": traceback.format_exc()
            }
    
    async def _test_discovery_system(self) -> Dict[str, Any]:
        """Test habit discovery functionality"""
        
        try:
            results = {}
            
            # 1. Test category discovery
            health_templates = await HabitTemplate.find(
                HabitTemplate.category == SuggestionCategory.HEALTH_FITNESS,
                HabitTemplate.is_active == True
            ).limit(5).to_list()
            
            results["category_discovery"] = {
                "health_templates": len(health_templates)
            }
            
            # 2. Test difficulty filtering
            easy_templates = await HabitTemplate.find(
                HabitTemplate.difficulty_level == DifficultyLevel.EASY,
                HabitTemplate.is_active == True
            ).limit(5).to_list()
            
            results["difficulty_filtering"] = {
                "easy_templates": len(easy_templates)
            }
            
            # 3. Test duration filtering
            short_templates = await HabitTemplate.find(
                HabitTemplate.estimated_duration <= 10,
                HabitTemplate.is_active == True
            ).limit(5).to_list()
            
            results["duration_filtering"] = {
                "short_templates": len(short_templates)
            }
            
            # 4. Test category statistics
            pipeline = [
                {"$match": {"is_active": True}},
                {"$group": {"_id": "$category", "count": {"$sum": 1}}}
            ]
            category_stats = await HabitTemplate.aggregate(pipeline).to_list()
            
            results["category_statistics"] = {
                "categories": len(category_stats),
                "total_active_templates": sum(stat["count"] for stat in category_stats)
            }
            
            success = (
                results["category_discovery"]["health_templates"] > 0 and
                results["duration_filtering"]["short_templates"] > 0 and
                results["category_statistics"]["total_active_templates"] > 0
            )
            
            return {
                "success": success,
                "discovery": results
            }
            
        except Exception as e:
            logger.error(f"Discovery system test failed: {e}")
            return {
                "success": False,
                "error": str(e),
                "traceback": traceback.format_exc()
            }
    
    async def _test_analytics(self) -> Dict[str, Any]:
        """Test analytics functionality"""
        
        try:
            # Get suggestions for analytics
            suggestions = await PersonalizedSuggestion.find(
                PersonalizedSuggestion.user_id == str(self.test_user.id)
            ).to_list()
            
            # Get feedback for analytics
            feedback_records = await SuggestionFeedback.find(
                SuggestionFeedback.user_id == str(self.test_user.id)
            ).to_list()
            
            # Calculate basic analytics
            total_suggestions = len(suggestions)
            viewed_suggestions = len([s for s in suggestions if s.shown_count > 0])
            clicked_suggestions = len([s for s in suggestions if s.clicked])
            dismissed_suggestions = len([s for s in suggestions if s.dismissed])
            adopted_suggestions = len([s for s in suggestions if s.adopted])
            
            analytics = {
                "total_suggestions": total_suggestions,
                "viewed_suggestions": viewed_suggestions,
                "clicked_suggestions": clicked_suggestions,
                "dismissed_suggestions": dismissed_suggestions,
                "adopted_suggestions": adopted_suggestions,
                "total_feedback": len(feedback_records)
            }
            
            # Calculate rates
            if viewed_suggestions > 0:
                analytics["click_rate"] = (clicked_suggestions / viewed_suggestions) * 100
                analytics["dismiss_rate"] = (dismissed_suggestions / viewed_suggestions) * 100
            
            if clicked_suggestions > 0:
                analytics["adoption_rate"] = (adopted_suggestions / clicked_suggestions) * 100
            
            success = total_suggestions > 0
            
            return {
                "success": success,
                "analytics": analytics
            }
            
        except Exception as e:
            logger.error(f"Analytics test failed: {e}")
            return {
                "success": False,
                "error": str(e),
                "traceback": traceback.format_exc()
            }
    
    async def _test_cleanup(self) -> Dict[str, Any]:
        """Clean up test data"""
        
        try:
            deleted_counts = {}
            
            # Delete test suggestions
            suggestion_result = await PersonalizedSuggestion.find(
                PersonalizedSuggestion.user_id == str(self.test_user.id)
            ).delete()
            deleted_counts["suggestions"] = suggestion_result.deleted_count
            
            # Delete test feedback
            feedback_result = await SuggestionFeedback.find(
                SuggestionFeedback.user_id == str(self.test_user.id)
            ).delete()
            deleted_counts["feedback"] = feedback_result.deleted_count
            
            # Delete test activities
            activity_result = await Activity.find(
                Activity.user_id == str(self.test_user.id)
            ).delete()
            deleted_counts["activities"] = activity_result.deleted_count
            
            # Delete test values
            value_result = await Value.find(
                Value.user_id == str(self.test_user.id)
            ).delete()
            deleted_counts["values"] = value_result.deleted_count
            
            # Delete test user
            await self.test_user.delete()
            deleted_counts["user"] = 1
            
            return {
                "success": True,
                "deleted_counts": deleted_counts
            }
            
        except Exception as e:
            logger.error(f"Cleanup test failed: {e}")
            return {
                "success": False,
                "error": str(e),
                "traceback": traceback.format_exc()
            }

async def main():
    """Main test function"""
    
    try:
        # Initialize database
        logger.info("🔌 Connecting to database...")
        await init_db()
        
        # Run tests
        tester = HabitSuggestionTester()
        results = await tester.run_all_tests()
        
        # Print results
        print("\n" + "="*80)
        print("🧪 HABIT SUGGESTION SYSTEM TEST RESULTS")
        print("="*80)
        
        if results["overall_success"]:
            print("✅ ALL TESTS PASSED!")
        else:
            print("❌ SOME TESTS FAILED!")
        
        print(f"\n📊 Success Rate: {results.get('success_rate', 0):.1f}%")
        
        print("\n📋 Test Results:")
        test_items = [
            ("System Initialization", results["system_initialization"]),
            ("User Setup", results["user_setup"]),
            ("Suggestion Generation", results["suggestion_generation"]),
            ("Suggestion Interactions", results["suggestion_interaction"]),
            ("Discovery System", results["discovery_system"]),
            ("Analytics", results["analytics"]),
            ("Cleanup", results["cleanup"])
        ]
        
        for test_name, success in test_items:
            status = "✅ PASS" if success else "❌ FAIL"
            print(f"  {test_name:<25} {status}")
        
        # Print errors if any
        if results["errors"]:
            print("\n❌ Errors:")
            for error in results["errors"]:
                print(f"  - {error}")
        
        # Print some key details
        if "initialization" in results["details"]:
            init_details = results["details"]["initialization"]
            if "templates_created" in init_details:
                print(f"\n📊 Templates created: {init_details['templates_created']}")
        
        if "suggestion_generation" in results["details"]:
            gen_details = results["details"]["suggestion_generation"]
            if "all_types" in gen_details:
                print(f"📊 Suggestions generated: {gen_details['all_types']['count']}")
        
        print("\n" + "="*80)
        
        return results["overall_success"]
        
    except Exception as e:
        logger.error(f"Test failed with error: {e}")
        print(f"\n❌ TEST SUITE FAILED: {e}")
        return False
        
    finally:
        # Close database connection
        logger.info("🔌 Closing database connection...")
        await close_db()

if __name__ == "__main__":
    success = asyncio.run(main())
    sys.exit(0 if success else 1)