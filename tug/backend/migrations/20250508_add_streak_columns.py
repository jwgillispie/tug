"""
Migration script to add streak tracking columns to the values collection.
"""

import asyncio
from motor.motor_asyncio import AsyncIOMotorClient
from datetime import datetime

# MongoDB connection settings
MONGODB_URL = "mongodb://localhost:27017"
DB_NAME = "tug_db"

async def migrate():
    """
    Add streak columns to the values collection:
    - current_streak: Tracks the current streak count
    - longest_streak: Tracks the longest streak achieved
    - last_activity_date: The last date an activity was logged for this value
    - streak_dates: List of dates for which activities were logged
    """
    print("Starting migration: Adding streak columns to values collection")
    
    # Connect to MongoDB
    client = AsyncIOMotorClient(MONGODB_URL)
    db = client[DB_NAME]
    
    # Update all values to add the new fields with default values
    update_result = await db.values.update_many(
        {},  # Match all documents
        {
            "$set": {
                "current_streak": 0,
                "longest_streak": 0,
                "last_activity_date": None,
                "streak_dates": []
            }
        }
    )
    
    print(f"Updated {update_result.modified_count} value documents")
    
    # Initialize streak data based on existing activities
    print("Initializing streak data from existing activities...")
    
    # Get all values
    values = await db.values.find({}).to_list(length=None)
    
    for value in values:
        value_id = str(value["_id"])
        user_id = value["user_id"]
        
        # Get all activities for this value
        activities = await db.activities.find({
            "value_id": value_id,
            "user_id": user_id
        }).sort("date", 1).to_list(length=None)
        
        if not activities:
            continue
            
        # Extract dates from activities and convert to date objects
        activity_dates = []
        for activity in activities:
            # MongoDB dates are already datetime objects
            activity_date = activity["date"].date()
            activity_dates.append(activity_date)
            
        # Remove duplicates and sort
        unique_dates = sorted(set(activity_dates))
        
        # Calculate streak
        current_streak = 1
        longest_streak = 1
        streak_start = 0
        
        for i in range(1, len(unique_dates)):
            days_diff = (unique_dates[i] - unique_dates[i-1]).days
            
            if days_diff == 1:
                # Consecutive day, increment current streak
                current_streak += 1
                if current_streak > longest_streak:
                    longest_streak = current_streak
            elif days_diff > 1:
                # Streak broken, reset current streak
                current_streak = 1
                streak_start = i
        
        # Update the value with streak data
        last_activity_date = unique_dates[-1] if unique_dates else None
        
        await db.values.update_one(
            {"_id": value["_id"]},
            {
                "$set": {
                    "current_streak": current_streak,
                    "longest_streak": longest_streak,
                    "last_activity_date": last_activity_date,
                    "streak_dates": unique_dates
                }
            }
        )
        
        print(f"Updated value {value_id}: current_streak={current_streak}, longest_streak={longest_streak}")
    
    print("Migration completed successfully")

if __name__ == "__main__":
    asyncio.run(migrate())