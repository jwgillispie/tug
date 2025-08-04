#!/usr/bin/env python3
"""
Migration script to update all existing achievement records to lowercase text.
This ensures existing user achievements match the new lowercase definitions.
"""

import logging
from datetime import datetime
from pymongo import MongoClient
import os

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# MongoDB connection
MONGODB_URL = os.getenv("MONGODB_URL", "mongodb://localhost:27017")
DATABASE_NAME = os.getenv("MONGODB_DB_NAME", "tug")

# Achievement text mappings from old (uppercase) to new (lowercase)
ACHIEVEMENT_UPDATES = {
    # Streak achievements
    "3-Day Streak": "3-day streak",
    "Week Warrior": "week warrior", 
    "Fortnight Force": "fortnight force",
    "Monthly Master": "monthly master",
    
    # Balance achievements
    "Balanced Beginner": "balanced beginner",
    "Harmony Keeper": "harmony keeper",
    "Life Balancer": "life balancer",
    
    # Frequency achievements
    "Getting Started": "getting started",
    "Regular Tracker": "regular tracker",
    "Century Club": "century club", 
    "Year of Growth": "year of growth",
    
    # Milestone achievements
    "Time Investment": "time investment",
    "Dedicated Day": "dedicated day",
    "Value Maven": "value maven",
    
    # Special achievements
    "Perfect Harmony": "perfect harmony",
    "Comeback Kid": "comeback kid",
}

DESCRIPTION_UPDATES = {
    # Streak descriptions
    "Complete activities for the same value 3 days in a row": "complete activities for the same value 3 days in a row",
    "Complete activities for the same value 7 days in a row": "complete activities for the same value 7 days in a row",
    "Complete activities for the same value 14 days in a row": "complete activities for the same value 14 days in a row",
    "Complete activities for the same value 30 days in a row": "complete activities for the same value 30 days in a row",
    
    # Balance descriptions
    "Maintain a balanced distribution across your values for 3 days": "maintain a balanced distribution across your values for 3 days",
    "Maintain a balanced distribution across your values for 7 days": "maintain a balanced distribution across your values for 7 days", 
    "Maintain a balanced distribution across your values for 30 days": "maintain a balanced distribution across your values for 30 days",
    
    # Frequency descriptions
    "Log 10 activities": "log 10 activities",
    "Log 50 activities": "log 50 activities",
    "Log 100 activities": "log 100 activities",
    "Log 365 activities": "log 365 activities",
    
    # Milestone descriptions
    "Spend 5 hours on value-aligned activities": "spend 5 hours on value-aligned activities",
    "Spend 20 hours on value-aligned activities": "spend 20 hours on value-aligned activities",
    "Spend 50 hours on value-aligned activities": "spend 50 hours on value-aligned activities",
    
    # Special descriptions
    "Log at least one activity for each of your values": "log at least one activity for each of your values",
    "Return to logging activities after a 2-week break": "return to logging activities after a 2-week break",
}

def update_achievements_to_lowercase():
    """Update all existing achievement records to use lowercase text"""
    
    client = None
    try:
        # Connect to MongoDB
        client = MongoClient(MONGODB_URL)
        db = client[DATABASE_NAME]
        achievements_collection = db.achievements
        
        logger.info("Connected to MongoDB")
        
        # Count total achievements before update
        total_achievements = achievements_collection.count_documents({})
        logger.info(f"Found {total_achievements} achievement records")
        
        if total_achievements == 0:
            logger.info("No achievements found to update")
            return True
        
        # Update titles
        title_updates = 0
        for old_title, new_title in ACHIEVEMENT_UPDATES.items():
            result = achievements_collection.update_many(
                {"title": old_title},
                {
                    "$set": {
                        "title": new_title,
                        "updated_at": datetime.utcnow()
                    }
                }
            )
            if result.modified_count > 0:
                logger.info(f"Updated {result.modified_count} achievements: '{old_title}' -> '{new_title}'")
                title_updates += result.modified_count
        
        # Update descriptions  
        description_updates = 0
        for old_desc, new_desc in DESCRIPTION_UPDATES.items():
            result = achievements_collection.update_many(
                {"description": old_desc},
                {
                    "$set": {
                        "description": new_desc,
                        "updated_at": datetime.utcnow()
                    }
                }
            )
            if result.modified_count > 0:
                logger.info(f"Updated {result.modified_count} achievement descriptions")
                description_updates += result.modified_count
        
        logger.info(f"Migration completed successfully!")
        logger.info(f"Total title updates: {title_updates}")
        logger.info(f"Total description updates: {description_updates}")
        
        return True
        
    except Exception as e:
        logger.error(f"Error during migration: {e}")
        return False
        
    finally:
        if client:
            client.close()
            logger.info("Database connection closed")

def main():
    """Main function to run the migration"""
    logger.info("Starting achievement lowercase migration...")
    success = update_achievements_to_lowercase()
    
    if success:
        logger.info("✅ Migration completed successfully!")
        exit(0)
    else:
        logger.error("❌ Migration failed!")
        exit(1)

if __name__ == "__main__":
    main()