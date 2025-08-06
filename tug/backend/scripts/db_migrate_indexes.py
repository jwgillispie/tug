#!/usr/bin/env python3
"""
Database Migration Script: Create Optimized Indexes

This script creates all the performance-critical indexes for the Tug application.
Run this script to ensure optimal database performance for production workloads.

Usage:
    python scripts/db_migrate_indexes.py

Environment Variables:
    MONGODB_URL: MongoDB connection URL
    MONGODB_DB_NAME: Database name
"""

import asyncio
import os
import sys
import logging
from datetime import datetime
from motor.motor_asyncio import AsyncIOMotorClient
from pymongo.errors import OperationFailure

# Add the parent directory to the path to import app modules
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Database configuration
MONGODB_URL = os.environ.get("MONGODB_URL", "mongodb://localhost:27017")
MONGODB_DB_NAME = os.environ.get("MONGODB_DB_NAME", "tug")

# Index definitions for each collection
INDEX_DEFINITIONS = {
    "users": [
        # Authentication and lookup indexes - high priority
        {"keys": [("firebase_uid", 1)], "name": "firebase_uid_1", "unique": True},
        {"keys": [("email", 1)], "name": "email_1", "unique": True},
        {"keys": [("username", 1)], "name": "username_1", "unique": True, "sparse": True},
        
        # Compound indexes for common query patterns
        {"keys": [("firebase_uid", 1), ("email", 1)], "name": "firebase_uid_1_email_1"},
        {"keys": [("onboarding_completed", 1), ("created_at", -1)], "name": "onboarding_completed_1_created_at_-1"},
        {"keys": [("last_login", -1)], "name": "last_login_-1"},
        {"keys": [("created_at", -1)], "name": "created_at_-1"},
        
        # Performance indexes for user discovery
        {"keys": [("username", 1), ("display_name", 1)], "name": "username_1_display_name_1"},
        {"keys": [("created_at", -1), ("onboarding_completed", 1)], "name": "created_at_-1_onboarding_completed_1"},
    ],
    
    "activities": [
        # Core query patterns - high priority
        {"keys": [("user_id", 1), ("date", -1)], "name": "user_id_1_date_-1"},
        {"keys": [("user_id", 1), ("value_ids", 1), ("date", -1)], "name": "user_id_1_value_ids_1_date_-1"},
        {"keys": [("value_ids", 1), ("date", -1)], "name": "value_ids_1_date_-1"},
        
        # Analytics and aggregation optimization
        {"keys": [("user_id", 1), ("date", -1), ("duration", 1)], "name": "user_id_1_date_-1_duration_1"},
        {"keys": [("date", -1), ("user_id", 1)], "name": "date_-1_user_id_1"},
        {"keys": [("user_id", 1), ("created_at", -1)], "name": "user_id_1_created_at_-1"},
        
        # Public/privacy queries
        {"keys": [("is_public", 1), ("date", -1)], "name": "is_public_1_date_-1"},
        {"keys": [("user_id", 1), ("is_public", 1), ("date", -1)], "name": "user_id_1_is_public_1_date_-1"},
        
        # Analytics support indexes
        {"keys": [("date", -1), ("duration", 1)], "name": "date_-1_duration_1"},
        {"keys": [("user_id", 1), ("date", 1)], "name": "user_id_1_date_1"},
        {"keys": [("value_ids", 1), ("user_id", 1), ("date", -1)], "name": "value_ids_1_user_id_1_date_-1"},
    ],
    
    "values": [
        # Core user queries - high priority
        {"keys": [("user_id", 1), ("active", 1)], "name": "user_id_1_active_1"},
        {"keys": [("user_id", 1), ("created_at", -1)], "name": "user_id_1_created_at_-1"},
        {"keys": [("user_id", 1), ("importance", -1)], "name": "user_id_1_importance_-1"},
        
        # Compound indexes for common patterns
        {"keys": [("user_id", 1), ("active", 1), ("importance", -1)], "name": "user_id_1_active_1_importance_-1"},
        {"keys": [("user_id", 1), ("active", 1), ("created_at", -1)], "name": "user_id_1_active_1_created_at_-1"},
        
        # Analytics support
        {"keys": [("user_id", 1), ("current_streak", -1)], "name": "user_id_1_current_streak_-1"},
        {"keys": [("user_id", 1), ("longest_streak", -1)], "name": "user_id_1_longest_streak_-1"},
        {"keys": [("user_id", 1), ("last_activity_date", -1)], "name": "user_id_1_last_activity_date_-1"},
        
        # Global analytics
        {"keys": [("active", 1), ("importance", -1)], "name": "active_1_importance_-1"},
    ],
    
    "vices": [
        # Core user queries - high priority
        {"keys": [("user_id", 1), ("active", 1)], "name": "user_id_1_active_1"},
        {"keys": [("user_id", 1), ("created_at", -1)], "name": "user_id_1_created_at_-1"},
        {"keys": [("user_id", 1), ("severity", -1)], "name": "user_id_1_severity_-1"},
        
        # Streak and progress analytics
        {"keys": [("user_id", 1), ("current_streak", -1)], "name": "user_id_1_current_streak_-1"},
        {"keys": [("user_id", 1), ("longest_streak", -1)], "name": "user_id_1_longest_streak_-1"},
        {"keys": [("user_id", 1), ("last_indulgence_date", -1)], "name": "user_id_1_last_indulgence_date_-1"},
        {"keys": [("user_id", 1), ("total_indulgences", -1)], "name": "user_id_1_total_indulgences_-1"},
        
        # Compound indexes for common patterns
        {"keys": [("user_id", 1), ("active", 1), ("severity", -1)], "name": "user_id_1_active_1_severity_-1"},
        {"keys": [("user_id", 1), ("active", 1), ("current_streak", -1)], "name": "user_id_1_active_1_current_streak_-1"},
        {"keys": [("user_id", 1), ("active", 1), ("created_at", -1)], "name": "user_id_1_active_1_created_at_-1"},
        
        # Analytics support
        {"keys": [("severity", -1), ("current_streak", -1)], "name": "severity_-1_current_streak_-1"},
        {"keys": [("active", 1), ("severity", -1)], "name": "active_1_severity_-1"},
        {"keys": [("last_indulgence_date", -1)], "name": "last_indulgence_date_-1"},
        
        # Milestone tracking
        {"keys": [("user_id", 1), ("milestone_achievements", 1)], "name": "user_id_1_milestone_achievements_1"},
    ],
    
    "indulgences": [
        # Core query patterns - high priority
        {"keys": [("user_id", 1), ("date", -1)], "name": "user_id_1_date_-1"},
        {"keys": [("vice_ids", 1), ("date", -1)], "name": "vice_ids_1_date_-1"},
        {"keys": [("user_id", 1), ("vice_ids", 1), ("date", -1)], "name": "user_id_1_vice_ids_1_date_-1"},
        
        # Analytics and trend analysis
        {"keys": [("user_id", 1), ("date", -1), ("severity_at_time", -1)], "name": "user_id_1_date_-1_severity_at_time_-1"},
        {"keys": [("user_id", 1), ("emotional_state", 1), ("date", -1)], "name": "user_id_1_emotional_state_1_date_-1"},
        {"keys": [("date", -1), ("severity_at_time", -1)], "name": "date_-1_severity_at_time_-1"},
        {"keys": [("date", -1), ("emotional_state", 1)], "name": "date_-1_emotional_state_1"},
        
        # Public/privacy queries
        {"keys": [("is_public", 1), ("date", -1)], "name": "is_public_1_date_-1"},
        {"keys": [("user_id", 1), ("is_public", 1), ("date", -1)], "name": "user_id_1_is_public_1_date_-1"},
        
        # Trigger and pattern analysis
        {"keys": [("user_id", 1), ("triggers", 1), ("date", -1)], "name": "user_id_1_triggers_1_date_-1"},
        {"keys": [("triggers", 1), ("date", -1)], "name": "triggers_1_date_-1"},
        {"keys": [("emotional_state", 1), ("severity_at_time", -1)], "name": "emotional_state_1_severity_at_time_-1"},
        
        # Duration analytics
        {"keys": [("user_id", 1), ("duration", 1), ("date", -1)], "name": "user_id_1_duration_1_date_-1"},
        {"keys": [("vice_ids", 1), ("duration", 1)], "name": "vice_ids_1_duration_1"},
        
        # Time-based analytics
        {"keys": [("date", -1), ("duration", 1)], "name": "date_-1_duration_1"},
        {"keys": [("user_id", 1), ("created_at", -1)], "name": "user_id_1_created_at_-1"},
    ],
    
    "social_posts": [
        # Core query patterns - high priority
        {"keys": [("user_id", 1), ("created_at", -1)], "name": "user_id_1_created_at_-1"},
        {"keys": [("is_public", 1), ("created_at", -1)], "name": "is_public_1_created_at_-1"},
        {"keys": [("post_type", 1), ("created_at", -1)], "name": "post_type_1_created_at_-1"},
        
        # Feed and discovery queries
        {"keys": [("is_public", 1), ("post_type", 1), ("created_at", -1)], "name": "is_public_1_post_type_1_created_at_-1"},
        {"keys": [("user_id", 1), ("is_public", 1), ("created_at", -1)], "name": "user_id_1_is_public_1_created_at_-1"},
        {"keys": [("user_id", 1), ("post_type", 1), ("created_at", -1)], "name": "user_id_1_post_type_1_created_at_-1"},
        
        # Engagement analytics
        {"keys": [("comments_count", -1), ("created_at", -1)], "name": "comments_count_-1_created_at_-1"},
        {"keys": [("user_id", 1), ("comments_count", -1)], "name": "user_id_1_comments_count_-1"},
        
        # Reference lookups
        {"keys": [("activity_id", 1)], "name": "activity_id_1", "sparse": True},
        {"keys": [("vice_id", 1)], "name": "vice_id_1", "sparse": True},
        {"keys": [("achievement_id", 1)], "name": "achievement_id_1", "sparse": True},
        
        # Compound reference queries
        {"keys": [("user_id", 1), ("activity_id", 1)], "name": "user_id_1_activity_id_1", "sparse": True},
        {"keys": [("user_id", 1), ("vice_id", 1)], "name": "user_id_1_vice_id_1", "sparse": True},
    ],
    
    "friendships": [
        # Core relationship queries - high priority
        {"keys": [("requester_id", 1), ("addressee_id", 1)], "name": "requester_id_1_addressee_id_1", "unique": True},
        {"keys": [("requester_id", 1), ("status", 1)], "name": "requester_id_1_status_1"},
        {"keys": [("addressee_id", 1), ("status", 1)], "name": "addressee_id_1_status_1"},
        
        # Friend discovery and management
        {"keys": [("status", 1), ("created_at", -1)], "name": "status_1_created_at_-1"},
        {"keys": [("requester_id", 1), ("status", 1), ("created_at", -1)], "name": "requester_id_1_status_1_created_at_-1"},
        {"keys": [("addressee_id", 1), ("status", 1), ("created_at", -1)], "name": "addressee_id_1_status_1_created_at_-1"},
        
        # Analytics queries
        {"keys": [("status", 1), ("updated_at", -1)], "name": "status_1_updated_at_-1"},
        {"keys": [("created_at", -1)], "name": "created_at_-1"},
        
        # Bidirectional friendship queries
        {"keys": [("requester_id", 1), ("status", 1), ("updated_at", -1)], "name": "requester_id_1_status_1_updated_at_-1"},
        {"keys": [("addressee_id", 1), ("status", 1), ("updated_at", -1)], "name": "addressee_id_1_status_1_updated_at_-1"},
    ],
    
    "mood_entries": [
        # Core query patterns - high priority
        {"keys": [("user_id", 1), ("recorded_at", -1)], "name": "user_id_1_recorded_at_-1"},
        {"keys": [("user_id", 1), ("mood_type", 1), ("recorded_at", -1)], "name": "user_id_1_mood_type_1_recorded_at_-1"},
        {"keys": [("user_id", 1), ("positivity_score", -1), ("recorded_at", -1)], "name": "user_id_1_positivity_score_-1_recorded_at_-1"},
        
        # Activity and indulgence correlation
        {"keys": [("activity_id", 1)], "name": "activity_id_1", "sparse": True},
        {"keys": [("indulgence_id", 1)], "name": "indulgence_id_1", "sparse": True},
        {"keys": [("user_id", 1), ("activity_id", 1)], "name": "user_id_1_activity_id_1", "sparse": True},
        {"keys": [("user_id", 1), ("indulgence_id", 1)], "name": "user_id_1_indulgence_id_1", "sparse": True},
        
        # Analytics and insights
        {"keys": [("mood_type", 1), ("recorded_at", -1)], "name": "mood_type_1_recorded_at_-1"},
        {"keys": [("positivity_score", -1), ("recorded_at", -1)], "name": "positivity_score_-1_recorded_at_-1"},
        {"keys": [("user_id", 1), ("positivity_score", -1)], "name": "user_id_1_positivity_score_-1"},
        
        # Time-based analytics
        {"keys": [("recorded_at", -1)], "name": "recorded_at_-1"},
        {"keys": [("user_id", 1), ("created_at", -1)], "name": "user_id_1_created_at_-1"},
        {"keys": [("updated_at", -1)], "name": "updated_at_-1"},
        
        # Correlation analysis indexes
        {"keys": [("activity_id", 1), ("mood_type", 1)], "name": "activity_id_1_mood_type_1", "sparse": True},
        {"keys": [("indulgence_id", 1), ("mood_type", 1)], "name": "indulgence_id_1_mood_type_1", "sparse": True},
        {"keys": [("activity_id", 1), ("positivity_score", -1)], "name": "activity_id_1_positivity_score_-1", "sparse": True},
        {"keys": [("indulgence_id", 1), ("positivity_score", -1)], "name": "indulgence_id_1_positivity_score_-1", "sparse": True},
    ]
}

async def create_index_safe(collection, index_spec):
    """Safely create an index, handling duplicates and errors"""
    try:
        index_name = index_spec.get("name")
        keys = index_spec["keys"]
        options = {k: v for k, v in index_spec.items() if k not in ["keys", "name"]}
        
        # Check if index already exists
        existing_indexes = await collection.list_indexes().to_list(length=None)
        existing_names = [idx.get("name") for idx in existing_indexes]
        
        if index_name in existing_names:
            logger.info(f"  ✓ Index '{index_name}' already exists")
            return True
            
        # Create the index
        result = await collection.create_index(keys, name=index_name, **options)
        logger.info(f"  ✓ Created index '{index_name}': {result}")
        return True
        
    except OperationFailure as e:
        if "already exists" in str(e):
            logger.info(f"  ✓ Index '{index_name}' already exists")
            return True
        else:
            logger.error(f"  ✗ Failed to create index '{index_name}': {e}")
            return False
    except Exception as e:
        logger.error(f"  ✗ Unexpected error creating index '{index_name}': {e}")
        return False

async def migrate_collection_indexes(db, collection_name, indexes):
    """Migrate all indexes for a specific collection"""
    logger.info(f"\n📚 Migrating indexes for collection: {collection_name}")
    
    collection = db[collection_name]
    success_count = 0
    total_count = len(indexes)
    
    for index_spec in indexes:
        success = await create_index_safe(collection, index_spec)
        if success:
            success_count += 1
        
        # Small delay to prevent overwhelming the database
        await asyncio.sleep(0.1)
    
    logger.info(f"✅ Collection '{collection_name}': {success_count}/{total_count} indexes created successfully")
    return success_count == total_count

async def main():
    """Main migration function"""
    logger.info("🚀 Starting database index migration")
    logger.info(f"📡 Connecting to MongoDB: {MONGODB_URL}")
    logger.info(f"🗄️  Database: {MONGODB_DB_NAME}")
    
    # Connect to MongoDB
    try:
        client = AsyncIOMotorClient(MONGODB_URL)
        await client.admin.command('ping')
        logger.info("✅ Successfully connected to MongoDB")
    except Exception as e:
        logger.error(f"❌ Failed to connect to MongoDB: {e}")
        return False
    
    db = client[MONGODB_DB_NAME]
    
    # Get database stats before migration
    try:
        stats_before = await db.command("dbStats")
        logger.info(f"📊 Database stats before migration:")
        logger.info(f"   - Collections: {stats_before.get('collections', 0)}")
        logger.info(f"   - Index Size: {stats_before.get('indexSize', 0) / (1024*1024):.2f} MB")
    except Exception as e:
        logger.warning(f"Could not get database stats: {e}")
    
    # Migrate indexes for each collection
    migration_results = {}
    start_time = datetime.utcnow()
    
    for collection_name, indexes in INDEX_DEFINITIONS.items():
        try:
            success = await migrate_collection_indexes(db, collection_name, indexes)
            migration_results[collection_name] = success
        except Exception as e:
            logger.error(f"❌ Failed to migrate collection '{collection_name}': {e}")
            migration_results[collection_name] = False
    
    # Get database stats after migration
    try:
        stats_after = await db.command("dbStats")
        logger.info(f"\n📊 Database stats after migration:")
        logger.info(f"   - Collections: {stats_after.get('collections', 0)}")
        logger.info(f"   - Index Size: {stats_after.get('indexSize', 0) / (1024*1024):.2f} MB")
        
        size_increase = (stats_after.get('indexSize', 0) - stats_before.get('indexSize', 0)) / (1024*1024)
        logger.info(f"   - Index Size Increase: +{size_increase:.2f} MB")
    except Exception as e:
        logger.warning(f"Could not get post-migration database stats: {e}")
    
    # Report results
    end_time = datetime.utcnow()
    duration = (end_time - start_time).total_seconds()
    
    successful_collections = sum(1 for success in migration_results.values() if success)
    total_collections = len(migration_results)
    
    logger.info(f"\n🎯 Migration Summary:")
    logger.info(f"   - Duration: {duration:.2f} seconds")
    logger.info(f"   - Collections: {successful_collections}/{total_collections} successful")
    
    for collection_name, success in migration_results.items():
        status = "✅" if success else "❌"
        logger.info(f"   - {status} {collection_name}")
    
    if successful_collections == total_collections:
        logger.info("🎉 All index migrations completed successfully!")
        logger.info("\n💡 Next Steps:")
        logger.info("   1. Monitor query performance using the built-in performance monitoring")
        logger.info("   2. Use db.collection.getIndexes() to verify index creation")
        logger.info("   3. Monitor index usage with db.collection.aggregate([{$indexStats: {}}])")
        logger.info("   4. Consider running db.collection.reIndex() if needed for existing data")
    else:
        logger.warning("⚠️  Some index migrations failed. Check the logs above for details.")
    
    # Close connection
    client.close()
    return successful_collections == total_collections

if __name__ == "__main__":
    try:
        success = asyncio.run(main())
        exit_code = 0 if success else 1
        sys.exit(exit_code)
    except KeyboardInterrupt:
        logger.info("\n🛑 Migration interrupted by user")
        sys.exit(1)
    except Exception as e:
        logger.error(f"❌ Migration failed with error: {e}")
        sys.exit(1)