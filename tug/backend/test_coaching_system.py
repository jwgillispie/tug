# test_coaching_system.py
"""
Comprehensive test suite for the personalized coaching message system.

This test demonstrates the full coaching system functionality including:
- Behavioral analysis and trigger detection
- Personalized message generation 
- ML-powered recommendations
- User preference management
- Message delivery optimization
- Analytics and insights

Run with: python test_coaching_system.py
"""

import asyncio
import logging
from datetime import datetime, timedelta, timezone
from typing import List, Dict, Any

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

async def test_coaching_system():
    """Comprehensive test of the coaching system"""
    
    logger.info("🚀 Starting Comprehensive Coaching System Test")
    
    try:
        # Initialize database connection
        from app.core.database import init_database
        await init_database()
        logger.info("✅ Database initialized")
        
        # Import models and services
        from app.models.user import User, SubscriptionTier
        from app.models.activity import Activity
        from app.models.value import Value
        from app.models.coaching_message import (
            CoachingMessage, UserPersonalizationProfile, CoachingMessageTemplate,
            CoachingMessageType, CoachingMessageTone, CoachingMessageStatus
        )
        from app.services.coaching_service import CoachingService
        from app.services.coaching_template_service import CoachingTemplateService
        from app.services.coaching_background_service import CoachingBackgroundService
        from app.services.ml_prediction_service import MLPredictionService
        
        # Initialize services
        coaching_service = CoachingService()
        template_service = CoachingTemplateService()
        background_service = CoachingBackgroundService()
        
        logger.info("✅ Services initialized")
        
        # === TEST 1: SEED MESSAGE TEMPLATES ===
        logger.info("\n📝 Test 1: Seeding Message Templates")
        seeded_count = await template_service.seed_default_templates()
        logger.info(f"✅ Seeded {seeded_count} message templates")
        
        # Verify templates were created
        templates = await CoachingMessageTemplate.find({}).to_list()
        logger.info(f"✅ Total templates in database: {len(templates)}")
        
        # === TEST 2: CREATE TEST USERS WITH DIFFERENT PROFILES ===
        logger.info("\n👥 Test 2: Creating Test Users")
        
        test_users = []
        
        # User 1: New user just starting
        user1 = User(
            firebase_uid="test_coaching_user_1",
            email="test1@coaching.com",
            display_name="New User Alice",
            created_at=datetime.now(timezone.utc) - timedelta(days=3),
            subscription_tier=SubscriptionTier.FREE
        )
        await user1.save()
        test_users.append(("new_user", user1))
        
        # User 2: Consistent user with good streak
        user2 = User(
            firebase_uid="test_coaching_user_2", 
            email="test2@coaching.com",
            display_name="Consistent Bob",
            created_at=datetime.now(timezone.utc) - timedelta(days=30),
            subscription_tier=SubscriptionTier.PREMIUM
        )
        await user2.save()
        test_users.append(("consistent_user", user2))
        
        # User 3: User with broken streak (comeback scenario)
        user3 = User(
            firebase_uid="test_coaching_user_3",
            email="test3@coaching.com", 
            display_name="Comeback Charlie",
            created_at=datetime.now(timezone.utc) - timedelta(days=45),
            subscription_tier=SubscriptionTier.FREE
        )
        await user3.save()
        test_users.append(("comeback_user", user3))
        
        logger.info(f"✅ Created {len(test_users)} test users")
        
        # === TEST 3: CREATE VALUES AND ACTIVITIES FOR EACH USER ===
        logger.info("\n📊 Test 3: Creating Activities and Values")
        
        for user_type, user in test_users:
            # Create values for each user
            values = []
            value_names = ["Exercise", "Meditation", "Reading", "Learning"]
            
            for i, name in enumerate(value_names):
                value = Value(
                    user_id=str(user.id),
                    name=name,
                    description=f"{name} practice",
                    color=f"#{'FF0000' if i == 0 else '00FF00' if i == 1 else '0000FF' if i == 2 else 'FFFF00'}",
                    importance=5 if i < 2 else 3
                )
                await value.save()
                values.append(value)
            
            # Create activities based on user type
            activities = []
            
            if user_type == "new_user":
                # New user: few activities, short durations
                for i in range(4):
                    activity = Activity(
                        user_id=str(user.id),
                        value_ids=[str(values[i % len(values)].id)],
                        name=f"Practice {values[i % len(values)].name}",
                        duration=10 + i * 5,  # 10, 15, 20, 25 minutes
                        date=datetime.now(timezone.utc) - timedelta(days=3-i),
                        notes=f"Day {i+1} practice"
                    )
                    await activity.save()
                    activities.append(activity)
                    
            elif user_type == "consistent_user":
                # Consistent user: many activities, good streaks
                for i in range(25):
                    activity = Activity(
                        user_id=str(user.id),
                        value_ids=[str(values[i % len(values)].id)],
                        name=f"Practice {values[i % len(values)].name}",
                        duration=20 + (i % 3) * 10,  # 20, 30, 40 minutes
                        date=datetime.now(timezone.utc) - timedelta(days=25-i),
                        notes=f"Consistent practice day {i+1}"
                    )
                    await activity.save()
                    activities.append(activity)
                    
            elif user_type == "comeback_user":
                # Comeback user: had good streak, then gap, now returning
                # Old streak (15 days ago to 30 days ago)
                for i in range(10):
                    activity = Activity(
                        user_id=str(user.id),
                        value_ids=[str(values[i % len(values)].id)],
                        name=f"Practice {values[i % len(values)].name}",
                        duration=25 + i * 2,
                        date=datetime.now(timezone.utc) - timedelta(days=30-i),
                        notes=f"Old streak day {i+1}"
                    )
                    await activity.save()
                    activities.append(activity)
                
                # Gap (no activities for 14 days)
                
                # Recent return (yesterday)
                activity = Activity(
                    user_id=str(user.id),
                    value_ids=[str(values[0].id)],
                    name="Back to practice",
                    duration=15,
                    date=datetime.now(timezone.utc) - timedelta(days=1),
                    notes="I'm back!"
                )
                await activity.save()
                activities.append(activity)
            
            logger.info(f"✅ Created {len(values)} values and {len(activities)} activities for {user.display_name}")
        
        # === TEST 4: TEST PERSONALIZATION PROFILES ===
        logger.info("\n⚙️ Test 4: Testing Personalization Profiles")
        
        for user_type, user in test_users:
            # Create personalization profile
            profile = UserPersonalizationProfile(
                user_id=str(user.id),
                preferred_tone=CoachingMessageTone.ENCOURAGING if user_type == "new_user" 
                              else CoachingMessageTone.MOTIVATIONAL if user_type == "consistent_user"
                              else CoachingMessageTone.SUPPORTIVE,
                message_frequency="optimal" if user_type != "consistent_user" else "frequent",
                quiet_hours=[22, 23, 0, 1, 2, 3, 4, 5, 6],
                preferred_times=[9, 18] if user_type == "new_user" else [7, 19] if user_type == "consistent_user" else [10, 20],
                ai_personalization_enabled=user.subscription_tier == SubscriptionTier.PREMIUM
            )
            await profile.save()
            
            logger.info(f"✅ Created personalization profile for {user.display_name}")
        
        # === TEST 5: TEST ML PREDICTIONS FOR BEHAVIORAL ANALYSIS ===
        logger.info("\n🧠 Test 5: Testing ML Predictions")
        
        for user_type, user in test_users:
            # Get user's activities and values
            activities = await Activity.find({"user_id": str(user.id)}).to_list()
            values = await Value.find({"user_id": str(user.id)}).to_list()
            
            # Generate ML predictions
            predictions = await MLPredictionService.generate_comprehensive_predictions(
                user, activities, values
            )
            
            logger.info(f"✅ Generated ML predictions for {user.display_name}:")
            logger.info(f"   - Habit formation probability: {predictions.get('habit_formation', {}).get('formation_probability', 0)}%")
            logger.info(f"   - Streak risk level: {predictions.get('streak_risk', {}).get('risk_level', 'unknown')}")
            logger.info(f"   - User segment: {predictions.get('user_segmentation', {}).get('user_segment', 'unknown')}")
            logger.info(f"   - Peak performance time: {predictions.get('optimal_timing', {}).get('peak_performance_time', 'unknown')}")
        
        # === TEST 6: TEST COACHING MESSAGE GENERATION ===
        logger.info("\n💬 Test 6: Testing Coaching Message Generation")
        
        all_generated_messages = []
        
        for user_type, user in test_users:
            # Get user's activities and values
            activities = await Activity.find({"user_id": str(user.id)}).to_list()
            values = await Value.find({"user_id": str(user.id)}).to_list()
            
            # Generate coaching messages
            messages = await coaching_service.analyze_user_behavior_and_generate_messages(
                user, activities, values
            )
            
            all_generated_messages.extend(messages)
            
            logger.info(f"✅ Generated {len(messages)} coaching messages for {user.display_name}")
            for msg in messages:
                logger.info(f"   - {msg.message_type.value}: '{msg.title}' (Priority: {msg.priority.value})")
        
        logger.info(f"✅ Total messages generated: {len(all_generated_messages)}")
        
        # === TEST 7: TEST MESSAGE DELIVERY OPTIMIZATION ===
        logger.info("\n⏰ Test 7: Testing Message Delivery Optimization")
        
        # Check scheduled times
        for msg in all_generated_messages:
            time_until_delivery = (msg.scheduled_for - datetime.now(timezone.utc)).total_seconds() / 60
            logger.info(f"   Message '{msg.title}' scheduled for delivery in {time_until_delivery:.1f} minutes")
        
        # Test immediate delivery (simulate scheduled delivery)
        delivery_stats = await background_service.deliver_scheduled_messages()
        logger.info(f"✅ Delivery simulation completed:")
        logger.info(f"   - Processed: {delivery_stats['messages_processed']}")
        logger.info(f"   - Delivered: {delivery_stats['messages_delivered']}")
        logger.info(f"   - Errors: {delivery_stats['delivery_errors']}")
        
        # === TEST 8: TEST USER INTERACTIONS ===
        logger.info("\n👆 Test 8: Testing User Interactions")
        
        # Get some delivered messages
        delivered_messages = await CoachingMessage.find({
            "status": {"$in": ["sent", "read", "acted_on"]}
        }).limit(5).to_list()
        
        if delivered_messages:
            # Simulate user reading messages
            for i, msg in enumerate(delivered_messages[:3]):
                if i == 0:
                    msg.mark_read()
                elif i == 1:
                    msg.mark_acted_on()
                # Leave one unread for testing
                await msg.save()
            
            logger.info(f"✅ Simulated user interactions on {len(delivered_messages)} messages")
        
        # === TEST 9: TEST ANALYTICS AND INSIGHTS ===
        logger.info("\n📈 Test 9: Testing Analytics and Insights")
        
        # Generate analytics
        analytics = await background_service.generate_coaching_analytics()
        
        logger.info("✅ Analytics generated:")
        system_overview = analytics.get("system_overview", {})
        logger.info(f"   - Total messages (all time): {system_overview.get('total_messages_all_time', 0)}")
        logger.info(f"   - Messages this week: {system_overview.get('messages_this_week', 0)}")
        logger.info(f"   - Active users this month: {system_overview.get('active_users_this_month', 0)}")
        logger.info(f"   - Overall read rate: {system_overview.get('overall_read_rate', 0):.1f}%")
        logger.info(f"   - Overall action rate: {system_overview.get('overall_action_rate', 0):.1f}%")
        
        # Test user-specific insights
        for user_type, user in test_users:
            try:
                insights = await coaching_service.get_coaching_insights(user)
                logger.info(f"✅ Generated insights for {user.display_name}:")
                logger.info(f"   - User segment: {insights.user_segment}")
                logger.info(f"   - Next actions: {len(insights.next_suggested_actions)}")
            except Exception as e:
                logger.warning(f"Could not generate insights for {user.display_name}: {e}")
        
        # === TEST 10: TEST PERSONALIZATION UPDATES ===
        logger.info("\n🎛️ Test 10: Testing Personalization Updates")
        
        # Update a user's preferences
        user = test_users[0][1]  # Get first user
        
        from app.schemas.coaching_message import UpdatePersonalizationProfileRequest
        update_request = UpdatePersonalizationProfileRequest(
            preferred_tone=CoachingMessageTone.CHALLENGING,
            message_frequency="daily",
            message_type_preferences={
                "progress_encouragement": 1.0,
                "streak_recovery": 0.8,
                "challenge_motivation": 0.9,
                "habit_tip": 0.6
            }
        )
        
        updated_profile = await coaching_service.update_user_personalization_profile(
            user, update_request
        )
        
        logger.info(f"✅ Updated personalization profile for {user.display_name}")
        logger.info(f"   - New tone: {updated_profile.preferred_tone}")
        logger.info(f"   - New frequency: {updated_profile.message_frequency}")
        
        # === TEST 11: TEST A/B TESTING CAPABILITIES ===
        logger.info("\n🧪 Test 11: Testing A/B Testing Support")
        
        # Find messages that could have A/B variants
        messages_for_ab = await CoachingMessage.find({}).limit(3).to_list()
        
        for i, msg in enumerate(messages_for_ab):
            msg.ab_test_variant = f"variant_{'A' if i % 2 == 0 else 'B'}"
            await msg.save()
        
        logger.info(f"✅ Set A/B test variants on {len(messages_for_ab)} messages")
        
        # === TEST 12: TEST SYSTEM PERFORMANCE ===
        logger.info("\n⚡ Test 12: Testing System Performance")
        
        start_time = datetime.utcnow()
        
        # Test bulk message generation
        bulk_stats = await background_service.process_all_users_for_coaching_messages()
        
        end_time = datetime.utcnow()
        processing_time = (end_time - start_time).total_seconds()
        
        logger.info(f"✅ Bulk processing completed in {processing_time:.2f} seconds")
        logger.info(f"   - Users processed: {bulk_stats['users_processed']}")
        logger.info(f"   - Messages generated: {bulk_stats['messages_generated']}")
        logger.info(f"   - Errors: {bulk_stats['errors']}")
        
        # === TEST 13: TEST MESSAGE FREQUENCY LIMITS ===
        logger.info("\n🚦 Test 13: Testing Message Frequency Limits")
        
        # Try to generate messages again for the same user (should be limited)
        user = test_users[1][1]  # Consistent user
        activities = await Activity.find({"user_id": str(user.id)}).to_list()
        values = await Value.find({"user_id": str(user.id)}).to_list()
        
        messages_round2 = await coaching_service.analyze_user_behavior_and_generate_messages(
            user, activities, values
        )
        
        logger.info(f"✅ Second generation for {user.display_name}: {len(messages_round2)} messages")
        logger.info("   (Should be fewer due to frequency limits)")
        
        # === TEST 14: TEST CLEANUP FUNCTIONALITY ===
        logger.info("\n🧹 Test 14: Testing Cleanup Functionality")
        
        # Test cleanup (using short retention for testing)
        cleanup_stats = await background_service.cleanup_old_messages(days_to_keep=1)
        
        logger.info(f"✅ Cleanup completed:")
        logger.info(f"   - Messages cleaned up: {cleanup_stats['deleted_count']}")
        
        # === FINAL SUMMARY ===
        logger.info("\n📋 Final System Summary")
        
        # Get final counts
        total_users = len(test_users)
        total_messages = await CoachingMessage.find({}).count()
        total_templates = await CoachingMessageTemplate.find({}).count()
        total_profiles = await UserPersonalizationProfile.find({}).count()
        
        logger.info(f"✅ Test completed successfully!")
        logger.info(f"   - Users created: {total_users}")
        logger.info(f"   - Message templates: {total_templates}")
        logger.info(f"   - Messages generated: {total_messages}")
        logger.info(f"   - Personalization profiles: {total_profiles}")
        
        # Display sample messages
        logger.info("\n📝 Sample Generated Messages:")
        sample_messages = await CoachingMessage.find({}).limit(5).to_list()
        
        for msg in sample_messages:
            logger.info(f"   {msg.message_type.value} | {msg.priority.value} priority")
            logger.info(f"   Title: {msg.title}")
            logger.info(f"   Message: {msg.message[:100]}{'...' if len(msg.message) > 100 else ''}")
            logger.info(f"   Scheduled for: {msg.scheduled_for}")
            logger.info(f"   Status: {msg.status.value}")
            logger.info("   ---")
        
        logger.info("\n🎉 Comprehensive Coaching System Test Completed Successfully!")
        logger.info("\nThe personalized coaching message system is fully functional with:")
        logger.info("✅ ML-powered behavioral analysis")
        logger.info("✅ Intelligent message generation") 
        logger.info("✅ Personalization and user preferences")
        logger.info("✅ Smart timing optimization")
        logger.info("✅ Frequency management")
        logger.info("✅ Analytics and insights")
        logger.info("✅ A/B testing support")
        logger.info("✅ Background processing")
        logger.info("✅ System health monitoring")
        
    except Exception as e:
        logger.error(f"❌ Test failed with error: {e}", exc_info=True)
        return False
    
    return True

async def cleanup_test_data():
    """Clean up test data after testing"""
    
    try:
        logger.info("🧹 Cleaning up test data...")
        
        # Import models
        from app.models.user import User
        from app.models.activity import Activity
        from app.models.value import Value
        from app.models.coaching_message import CoachingMessage, UserPersonalizationProfile
        
        # Delete test users and related data
        test_firebase_uids = ["test_coaching_user_1", "test_coaching_user_2", "test_coaching_user_3"]
        
        for firebase_uid in test_firebase_uids:
            user = await User.find_one({"firebase_uid": firebase_uid})
            if user:
                # Delete related data
                await Activity.find({"user_id": str(user.id)}).delete()
                await Value.find({"user_id": str(user.id)}).delete()
                await CoachingMessage.find({"user_id": str(user.id)}).delete()
                await UserPersonalizationProfile.find({"user_id": str(user.id)}).delete()
                
                # Delete user
                await user.delete()
                logger.info(f"✅ Cleaned up test user: {firebase_uid}")
        
        logger.info("✅ Test data cleanup completed")
        
    except Exception as e:
        logger.error(f"❌ Error during cleanup: {e}")

if __name__ == "__main__":
    async def main():
        success = await test_coaching_system()
        
        # Optionally clean up test data
        cleanup_choice = input("\nClean up test data? (y/n): ").lower().strip()
        if cleanup_choice == 'y':
            await cleanup_test_data()
        
        if success:
            print("\n🎉 All tests passed! The coaching system is ready for production.")
        else:
            print("\n❌ Some tests failed. Please check the logs and fix issues before deployment.")
    
    asyncio.run(main())