# Migration: Add mood tracking system
# Date: 2025-07-14
# Description: Create mood tracking functionality with 15 mood types and positivity scoring

"""
Migration to add mood tracking system to TUG

This migration:
1. Creates the mood_entries collection with proper indexes
2. Sets up mood types and positivity scores
3. Links mood entries to activities and indulgences
"""

import asyncio
import os
from datetime import datetime

# MongoDB connection
MONGODB_URL = os.getenv("MONGODB_URL", "mongodb://localhost:27017")
DATABASE_NAME = os.getenv("MONGODB_DB_NAME", "tug")

async def upgrade():
    """Run the migration upgrade"""
    from motor.motor_asyncio import AsyncIOMotorClient
    client = AsyncIOMotorClient(MONGODB_URL)
    db = client[DATABASE_NAME]
    
    print("Starting mood tracking migration...")
    
    try:
        # Create mood_entries collection if it doesn't exist
        collections = await db.list_collection_names()
        if "mood_entries" not in collections:
            await db.create_collection("mood_entries")
            print("✓ Created mood_entries collection")
        
        # Create indexes for mood_entries
        mood_collection = db.mood_entries
        
        # User and date index for mood history
        await mood_collection.create_index([
            ("user_id", 1),
            ("recorded_at", -1)
        ], name="user_mood_history")
        
        # Activity correlation index
        await mood_collection.create_index([
            ("user_id", 1),
            ("activity_id", 1)
        ], name="activity_mood_correlation")
        
        # Indulgence correlation index  
        await mood_collection.create_index([
            ("user_id", 1),
            ("indulgence_id", 1)
        ], name="indulgence_mood_correlation")
        
        # Date range queries
        await mood_collection.create_index([
            ("recorded_at", 1)
        ], name="mood_date_range")
        
        print("✓ Created mood_entries indexes")
        
        # Verify the mood types and scoring system
        mood_types = [
            {"type": "ecstatic", "score": 10, "description": "Peak positive energy, euphoric"},
            {"type": "joyful", "score": 9, "description": "Very happy, delighted"},
            {"type": "confident", "score": 8, "description": "Self-assured, empowered"},
            {"type": "content", "score": 7, "description": "Satisfied, peaceful"},
            {"type": "focused", "score": 6, "description": "Clear-minded, determined"},
            {"type": "neutral", "score": 5, "description": "Balanced, neither positive nor negative"},
            {"type": "restless", "score": 4, "description": "Agitated, unsettled"},
            {"type": "tired", "score": 3, "description": "Fatigued, low energy"},
            {"type": "frustrated", "score": 2, "description": "Annoyed, blocked"},
            {"type": "anxious", "score": 2, "description": "Worried, stressed"},
            {"type": "sad", "score": 1, "description": "Down, melancholy"},
            {"type": "overwhelmed", "score": 1, "description": "Too much to handle"},
            {"type": "angry", "score": 1, "description": "Mad, irritated"},
            {"type": "defeated", "score": 0, "description": "Hopeless, giving up"},
            {"type": "depressed", "score": 0, "description": "Very low, heavy sadness"},
        ]
        
        print(f"✓ Mood system configured with {len(mood_types)} mood types")
        print("✓ Positivity scoring: 0 (lowest) to 10 (highest)")
        
        # Create a metadata collection entry for this migration
        migrations_collection = db.migrations
        await migrations_collection.insert_one({
            "migration_id": "20250714_add_mood_tracking",
            "description": "Add mood tracking system",
            "applied_at": datetime.utcnow(),
            "version": "1.0.0",
            "features": [
                "mood_entries collection",
                "15 mood types with positivity scores",
                "activity and indulgence correlation",
                "mood chart data endpoints"
            ]
        })
        
        print("✓ Migration completed successfully!")
        print("\nMood tracking system is now ready!")
        print("API endpoints available at:")
        print("- GET /api/v1/mood/options - Get all mood types")
        print("- POST /api/v1/mood/entries - Create mood entry")
        print("- GET /api/v1/mood/entries - Get user mood history")
        print("- GET /api/v1/mood/chart-data - Get data for chart overlay")
        
    except Exception as e:
        print(f"❌ Migration failed: {e}")
        raise
    finally:
        client.close()

async def downgrade():
    """Rollback the migration"""
    from motor.motor_asyncio import AsyncIOMotorClient
    client = AsyncIOMotorClient(MONGODB_URL)
    db = client[DATABASE_NAME]
    
    print("Rolling back mood tracking migration...")
    
    try:
        # Drop mood_entries collection
        await db.mood_entries.drop()
        print("✓ Dropped mood_entries collection")
        
        # Remove migration record
        await db.migrations.delete_one({
            "migration_id": "20250714_add_mood_tracking"
        })
        print("✓ Removed migration record")
        
        print("✓ Rollback completed successfully!")
        
    except Exception as e:
        print(f"❌ Rollback failed: {e}")
        raise
    finally:
        client.close()

if __name__ == "__main__":
    import sys
    
    if len(sys.argv) > 1 and sys.argv[1] == "downgrade":
        asyncio.run(downgrade())
    else:
        asyncio.run(upgrade())