# migrations/20250510_add_achievements_table.py
from pymongo import MongoClient
from datetime import datetime
import os
import logging

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def get_database_url():
    """Get the database URL from environment or use default"""
    return os.environ.get("DATABASE_URL", "mongodb://localhost:27017/tug")

def run_migration():
    """
    Add achievements collection and indexes.
    """
    client = MongoClient(get_database_url())
    db = client.get_default_database()
    
    logger.info("Starting migration: add_achievements_table")
    
    # Create achievements collection if it doesn't exist
    if "achievements" not in db.list_collection_names():
        logger.info("Creating achievements collection")
        db.create_collection("achievements")
    
    # Add indexes
    logger.info("Adding indexes to achievements collection")
    db.achievements.create_index([("user_id", 1)])
    db.achievements.create_index([("user_id", 1), ("achievement_id", 1)], unique=True)
    db.achievements.create_index([("is_unlocked", 1)])
    
    # Add metadata about this migration
    migration_id = "20250510_add_achievements_table"
    if db.migrations.find_one({"migration_id": migration_id}) is None:
        db.migrations.insert_one({
            "migration_id": migration_id,
            "applied_at": datetime.utcnow(),
            "description": "Add achievements table with indexes"
        })
        logger.info(f"Migration {migration_id} completed successfully")
    else:
        logger.info(f"Migration {migration_id} already applied, skipping")

if __name__ == "__main__":
    run_migration()