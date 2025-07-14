# Migration: Fix mood tracking index conflicts
# Date: 2025-07-14
# Description: Remove conflicting indexes and let Beanie handle them

import os
from pymongo import MongoClient

# MongoDB connection
MONGODB_URL = os.getenv("MONGODB_URL", "mongodb://localhost:27017")
DATABASE_NAME = os.getenv("MONGODB_DB_NAME", "tug")

def upgrade():
    """Fix the index conflicts"""
    client = MongoClient(MONGODB_URL)
    db = client[DATABASE_NAME]
    
    print("Fixing mood tracking index conflicts...")
    
    try:
        mood_collection = db.mood_entries
        
        # Drop all existing indexes except _id
        print("Dropping existing mood_entries indexes...")
        existing_indexes = mood_collection.list_indexes()
        for index in existing_indexes:
            index_name = index.get('name')
            if index_name and index_name != '_id_':
                try:
                    mood_collection.drop_index(index_name)
                    print(f"✓ Dropped index: {index_name}")
                except Exception as e:
                    print(f"⚠ Could not drop index {index_name}: {e}")
        
        print("✓ Index cleanup completed")
        print("Beanie will now create the appropriate indexes automatically")
        
    except Exception as e:
        print(f"❌ Migration failed: {e}")
        raise
    finally:
        client.close()

def downgrade():
    """Rollback - recreate the original indexes"""
    client = MongoClient(MONGODB_URL)
    db = client[DATABASE_NAME]
    
    print("Recreating original mood indexes...")
    
    try:
        mood_collection = db.mood_entries
        
        # Recreate the original indexes
        mood_collection.create_index([
            ("user_id", 1),
            ("recorded_at", -1)
        ], name="user_mood_history")
        
        mood_collection.create_index([
            ("user_id", 1),
            ("activity_id", 1)
        ], name="activity_mood_correlation")
        
        mood_collection.create_index([
            ("user_id", 1),
            ("indulgence_id", 1)
        ], name="indulgence_mood_correlation")
        
        mood_collection.create_index([
            ("recorded_at", 1)
        ], name="mood_date_range")
        
        print("✓ Recreated original indexes")
        
    except Exception as e:
        print(f"❌ Rollback failed: {e}")
        raise
    finally:
        client.close()

if __name__ == "__main__":
    import sys
    
    if len(sys.argv) > 1 and sys.argv[1] == "downgrade":
        downgrade()
    else:
        upgrade()