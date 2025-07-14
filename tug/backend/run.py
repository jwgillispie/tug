# run.py
import os
import uvicorn
import asyncio
from app.main import app

async def fix_indexes_if_needed():
    """Fix index conflicts before starting the server"""
    try:
        from pymongo import MongoClient
        
        MONGODB_URL = os.environ.get("MONGODB_URL", "mongodb://localhost:27017")
        DATABASE_NAME = os.environ.get("MONGODB_DB_NAME", "tug")
        
        client = MongoClient(MONGODB_URL)
        db = client[DATABASE_NAME]
        mood_collection = db.mood_entries
        
        # Check if the conflicting indexes exist
        existing_indexes = list(mood_collection.list_indexes())
        conflicting_indexes = ['user_mood_history', 'activity_mood_correlation', 'indulgence_mood_correlation', 'mood_date_range']
        
        for index in existing_indexes:
            index_name = index.get('name')
            if index_name in conflicting_indexes:
                print(f"Removing conflicting index: {index_name}")
                mood_collection.drop_index(index_name)
        
        client.close()
        print("Index cleanup completed")
        
    except Exception as e:
        print(f"Index cleanup failed (this may be normal on first run): {e}")

if __name__ == "__main__":
    # Fix indexes before starting
    print("Checking for index conflicts...")
    asyncio.run(fix_indexes_if_needed())
    
    # Get port from environment variable (Render provides this)
    port = int(os.environ.get("PORT", 8000))
    
    # Run the FastAPI app with uvicorn
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=port,
        reload=False,  # Don't use reload in production
        log_level="info"
    )