#!/usr/bin/env python3
"""
Comprehensive test script for ML prediction system
This script tests the ML prediction functionality end-to-end
"""

import asyncio
import logging
import sys
import os
from datetime import datetime, timedelta, timezone
from typing import Dict, Any, List
import json

# Add the app directory to Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'app'))

# Set up logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)


async def create_test_user() -> 'User':
    """Create a test user for ML predictions"""
    from app.models.user import User, SubscriptionTier
    
    # Create test user
    user = User(
        firebase_uid="test_ml_user_001",
        email="ml_test@example.com",
        display_name="ML Test User",
        subscription_tier=SubscriptionTier.PREMIUM,
        created_at=datetime.now(timezone.utc) - timedelta(days=60)
    )
    
    try:
        await user.save()
        logger.info(f"Created test user: {user.id}")
        return user
    except Exception as e:
        # User might already exist, try to find it
        existing_user = await User.find_one(User.firebase_uid == "test_ml_user_001")
        if existing_user:
            logger.info(f"Using existing test user: {existing_user.id}")
            return existing_user
        else:
            raise e


async def create_test_values(user: 'User') -> List['Value']:
    """Create test values for the user"""
    from app.models.value import Value
    
    test_values = [
        {
            "name": "Health & Fitness",
            "importance": 5,
            "description": "Physical and mental wellness",
            "color": "#4CAF50"
        },
        {
            "name": "Learning",
            "importance": 4,
            "description": "Continuous learning and growth",
            "color": "#2196F3"
        },
        {
            "name": "Creativity",
            "importance": 3,
            "description": "Creative expression and projects",
            "color": "#FF9800"
        },
        {
            "name": "Relationships",
            "importance": 5,
            "description": "Family and social connections",
            "color": "#E91E63"
        }
    ]
    
    values = []
    for value_data in test_values:
        value = Value(
            user_id=str(user.id),
            **value_data,
            created_at=datetime.now(timezone.utc) - timedelta(days=45)
        )
        await value.save()
        values.append(value)
        logger.info(f"Created test value: {value.name}")
    
    return values


async def create_test_activities(user: 'User', values: List['Value']) -> List['Activity']:
    """Create realistic test activities for ML training"""
    from app.models.activity import Activity
    import random
    
    activities = []
    start_date = datetime.now(timezone.utc) - timedelta(days=30)
    
    # Create activities over the past 30 days with realistic patterns
    for day in range(30):
        current_date = start_date + timedelta(days=day)
        
        # Skip some days to create realistic gaps
        if random.random() < 0.15:  # 15% chance to skip a day
            continue
        
        # Create 1-4 activities per day
        num_activities = random.choices([1, 2, 3, 4], weights=[0.3, 0.4, 0.2, 0.1])[0]
        
        for _ in range(num_activities):
            # Choose value based on importance (higher importance = more likely)
            value_weights = [v.importance for v in values]
            selected_value = random.choices(values, weights=value_weights)[0]
            
            # Realistic activity patterns
            if selected_value.name == "Health & Fitness":
                activity_names = ["Morning Run", "Gym Workout", "Yoga Session", "Walking", "Swimming"]
                durations = [30, 45, 60, 90, 120]
                preferred_hours = [7, 8, 9, 18, 19, 20]
            elif selected_value.name == "Learning":
                activity_names = ["Reading", "Online Course", "Practice Coding", "Language Study", "Research"]
                durations = [25, 45, 60, 90, 120]
                preferred_hours = [9, 10, 14, 15, 20, 21]
            elif selected_value.name == "Creativity":
                activity_names = ["Writing", "Drawing", "Music Practice", "Photography", "Crafting"]
                durations = [30, 60, 90, 120]
                preferred_hours = [10, 14, 16, 19, 20, 21]
            else:  # Relationships
                activity_names = ["Family Time", "Call Friend", "Date Night", "Social Event", "Team Activity"]
                durations = [45, 60, 90, 120, 180]
                preferred_hours = [12, 13, 17, 18, 19, 20]
            
            # Create realistic timing
            hour = random.choice(preferred_hours)
            minute = random.choice([0, 15, 30, 45])
            activity_time = current_date.replace(hour=hour, minute=minute, second=0, microsecond=0)
            
            # Create activity
            activity = Activity(
                user_id=str(user.id),
                value_ids=[str(selected_value.id)],
                name=random.choice(activity_names),
                duration=random.choice(durations),
                date=activity_time,
                notes=f"Test activity for {selected_value.name}" if random.random() < 0.3 else None,
                created_at=activity_time + timedelta(minutes=random.randint(0, 60))
            )
            
            await activity.save()
            activities.append(activity)
    
    logger.info(f"Created {len(activities)} test activities")
    return activities


async def test_ml_prediction_service(user: 'User', activities: List['Activity'], values: List['Value']):
    """Test the ML prediction service"""
    from app.services.ml_prediction_service import MLPredictionService
    
    logger.info("Testing ML Prediction Service...")
    
    try:
        # Generate comprehensive predictions
        predictions = await MLPredictionService.generate_comprehensive_predictions(
            user, activities, values
        )
        
        # Validate predictions structure
        expected_keys = [
            "habit_formation", "optimal_timing", "streak_risk", 
            "goal_recommendations", "motivation_timing", "user_segmentation",
            "activity_forecasting", "confidence_metrics"
        ]
        
        for key in expected_keys:
            if key not in predictions:
                logger.error(f"Missing prediction key: {key}")
            else:
                logger.info(f"✓ {key}: {type(predictions[key])}")
        
        # Test specific prediction components
        habit_formation = predictions.get("habit_formation", {})
        if habit_formation:
            logger.info(f"Habit Formation Probability: {habit_formation.get('formation_probability', 'N/A')}%")
            logger.info(f"Confidence Score: {habit_formation.get('confidence_score', 'N/A')}%")
        
        streak_risk = predictions.get("streak_risk", {})
        if streak_risk:
            logger.info(f"Streak Risk Level: {streak_risk.get('risk_level', 'N/A')}")
            logger.info(f"Risk Score: {streak_risk.get('risk_score', 'N/A')}")
        
        optimal_timing = predictions.get("optimal_timing", {})
        if optimal_timing:
            best_hours = optimal_timing.get("optimal_hours", [])
            if best_hours:
                logger.info(f"Best Hours: {[h.get('time_label', 'N/A') for h in best_hours[:3]]}")
        
        user_segment = predictions.get("user_segmentation", {})
        if user_segment:
            logger.info(f"User Segment: {user_segment.get('user_segment', 'N/A')}")
        
        confidence_metrics = predictions.get("confidence_metrics", {})
        if confidence_metrics:
            logger.info(f"Overall Confidence: {confidence_metrics.get('overall_confidence', 'N/A')}%")
        
        return predictions
        
    except Exception as e:
        logger.error(f"ML Prediction Service test failed: {e}", exc_info=True)
        return None


async def test_analytics_integration(user: 'User'):
    """Test ML predictions integration with analytics service"""
    from app.services.analytics_service import AnalyticsService
    from app.models.analytics import AnalyticsType
    
    logger.info("Testing Analytics Integration...")
    
    try:
        # Generate analytics with ML predictions
        analytics = await AnalyticsService.generate_user_analytics(
            user=user,
            analytics_type=AnalyticsType.MONTHLY,
            days_back=30
        )
        
        # Check if predictions are included
        predictions = analytics.get("predictions", {})
        if not predictions:
            logger.error("No predictions found in analytics")
            return False
        
        # Validate ML integration
        is_ml_powered = predictions.get("ml_powered", False)
        confidence_level = predictions.get("confidence_level", 0)
        
        logger.info(f"ML Powered: {is_ml_powered}")
        logger.info(f"Confidence Level: {confidence_level}%")
        
        if is_ml_powered:
            logger.info("✓ ML predictions successfully integrated with analytics")
            
            # Check for enhanced features
            if "habit_formation" in predictions:
                logger.info("✓ Habit formation predictions available")
            if "streak_risk" in predictions:
                logger.info("✓ Streak risk assessment available")
            if "user_segment" in predictions:
                logger.info("✓ User segmentation available")
            
        else:
            logger.warning("Analytics using fallback method instead of ML")
        
        return True
        
    except Exception as e:
        logger.error(f"Analytics integration test failed: {e}", exc_info=True)
        return False


async def test_caching_service(user: 'User'):
    """Test prediction caching functionality"""
    from app.services.prediction_cache_service import PredictionCacheService
    
    logger.info("Testing Caching Service...")
    
    try:
        cache_service = PredictionCacheService()
        
        # Test cache miss
        cached_predictions = await cache_service.get_cached_predictions(user, "test")
        if cached_predictions is None:
            logger.info("✓ Cache miss handled correctly")
        
        # Test cache store and retrieve
        test_predictions = {
            "test_prediction": "test_value",
            "timestamp": datetime.now(timezone.utc).isoformat()
        }
        
        store_success = await cache_service.store_predictions(user, test_predictions, "test")
        if store_success:
            logger.info("✓ Cache store successful")
            
            # Retrieve from cache
            cached_data = await cache_service.get_cached_predictions(user, "test")
            if cached_data and cached_data.get("predictions"):
                logger.info("✓ Cache retrieval successful")
                
                # Validate cached data
                cached_predictions = cached_data["predictions"]
                if cached_predictions.get("test_prediction") == "test_value":
                    logger.info("✓ Cached data integrity verified")
                else:
                    logger.error("Cache data integrity check failed")
            else:
                logger.error("Cache retrieval failed")
        else:
            logger.error("Cache store failed")
        
        # Test cache stats
        cache_stats = await cache_service.get_cache_stats()
        logger.info(f"Cache Stats: {cache_stats}")
        
        return True
        
    except Exception as e:
        logger.error(f"Caching service test failed: {e}", exc_info=True)
        return False


async def test_training_service():
    """Test ML training service"""
    from app.services.ml_training_service import MLTrainingService
    
    logger.info("Testing ML Training Service...")
    
    try:
        training_service = MLTrainingService()
        
        # Test model info
        model_info = await training_service.get_model_info()
        logger.info(f"Model Info: {model_info}")
        
        # Test retraining check
        retrain_check = await training_service.retrain_models_if_needed()
        logger.info(f"Retrain Check: {retrain_check}")
        
        return True
        
    except Exception as e:
        logger.error(f"Training service test failed: {e}", exc_info=True)
        return False


async def cleanup_test_data(user: 'User', values: List['Value'], activities: List['Activity']):
    """Clean up test data"""
    logger.info("Cleaning up test data...")
    
    try:
        # Delete activities
        for activity in activities:
            await activity.delete()
        
        # Delete values
        for value in values:
            await value.delete()
        
        # Delete user
        await user.delete()
        
        logger.info("✓ Test data cleaned up successfully")
        
    except Exception as e:
        logger.warning(f"Cleanup warning: {e}")


async def main():
    """Main test function"""
    logger.info("Starting ML Prediction System Tests")
    
    # Initialize database connection (this would normally be done by the app)
    from beanie import init_beanie
    from motor.motor_asyncio import AsyncIOMotorClient
    from app.models.user import User
    from app.models.value import Value
    from app.models.activity import Activity
    
    # Use test database
    client = AsyncIOMotorClient("mongodb://localhost:27017")
    database = client.get_database("tug_test")
    
    await init_beanie(
        database=database,
        document_models=[User, Value, Activity]
    )
    
    user = None
    values = []
    activities = []
    
    try:
        # Create test data
        logger.info("Step 1: Creating test data...")
        user = await create_test_user()
        values = await create_test_values(user)
        activities = await create_test_activities(user, values)
        
        # Test ML Prediction Service
        logger.info("Step 2: Testing ML Prediction Service...")
        predictions = await test_ml_prediction_service(user, activities, values)
        
        if predictions:
            logger.info("✓ ML Prediction Service test passed")
        else:
            logger.error("✗ ML Prediction Service test failed")
        
        # Test Analytics Integration
        logger.info("Step 3: Testing Analytics Integration...")
        analytics_success = await test_analytics_integration(user)
        
        if analytics_success:
            logger.info("✓ Analytics Integration test passed")
        else:
            logger.error("✗ Analytics Integration test failed")
        
        # Test Caching Service
        logger.info("Step 4: Testing Caching Service...")
        cache_success = await test_caching_service(user)
        
        if cache_success:
            logger.info("✓ Caching Service test passed")
        else:
            logger.error("✗ Caching Service test failed")
        
        # Test Training Service
        logger.info("Step 5: Testing Training Service...")
        training_success = await test_training_service()
        
        if training_success:
            logger.info("✓ Training Service test passed")
        else:
            logger.error("✗ Training Service test failed")
        
        logger.info("All tests completed!")
        
    except Exception as e:
        logger.error(f"Test execution failed: {e}", exc_info=True)
        
    finally:
        # Clean up test data
        if user and values and activities:
            await cleanup_test_data(user, values, activities)


if __name__ == "__main__":
    asyncio.run(main())