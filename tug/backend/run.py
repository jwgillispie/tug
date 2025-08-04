# run.py
import os
import uvicorn

def fix_mood_indexes():
    """Drop the specific conflicting indexes"""
    try:
        import pymongo
        
        MONGODB_URL = os.environ.get("MONGODB_URL", "mongodb://localhost:27017") 
        DATABASE_NAME = os.environ.get("MONGODB_DB_NAME", "tug")
        
        print("🔧 Fixing mood index conflicts...")
        
        # Connect to MongoDB
        client = pymongo.MongoClient(MONGODB_URL)
        db = client[DATABASE_NAME]
        
        # Drop the conflicting indexes from mood_entries collection
        collection = db.mood_entries
        
        conflicting_indexes = [
            'user_mood_history',
            'activity_mood_correlation', 
            'indulgence_mood_correlation',
            'mood_date_range'
        ]
        
        for index_name in conflicting_indexes:
            try:
                collection.drop_index(index_name)
                print(f"✅ Dropped conflicting index: {index_name}")
            except pymongo.errors.OperationFailure as e:
                if "index not found" in str(e).lower():
                    print(f"⏭️  Index {index_name} not found (already dropped)")
                else:
                    print(f"❌ Error dropping index {index_name}: {e}")
            except Exception as e:
                print(f"❌ Unexpected error with index {index_name}: {e}")
        
        client.close()
        print("✅ Index conflict resolution completed")
        
    except Exception as e:
        print(f"⚠️  Index fix failed: {e}")
        print("🚀 Continuing with startup anyway...")

if __name__ == "__main__":
    print("🚀 Starting TUG Backend v2...")
    
    # Fix indexes first
    fix_mood_indexes()
    
    # Get port from environment 
    port = int(os.environ.get("PORT", 8000))
    
    print(f"🌐 Starting server on 0.0.0.0:{port}")
    
    # Start the FastAPI application
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0", 
        port=port,
        reload=False,
        log_level="info"
    )