#!/usr/bin/env python3
"""
Migration script to update activities from single value_id to multiple value_ids
Run this script to migrate existing data.
"""

import asyncio
import sys
import os
from pathlib import Path

# Add the parent directory to Python path
sys.path.insert(0, str(Path(__file__).parent.parent))

from motor.motor_asyncio import AsyncIOMotorClient
from pymongo import UpdateOne
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

async def migrate_activities():
    """Migrate activities from value_id to value_ids format"""
    
    # Connect to MongoDB (adjust connection string as needed)
    client = AsyncIOMotorClient("mongodb://localhost:27017")
    db = client.tug_db  # Adjust database name as needed
    collection = db.activities
    
    logger.info("Starting activity migration...")
    
    # Find all activities that have value_id but not value_ids
    cursor = collection.find({
        "value_id": {"$exists": True},
        "value_ids": {"$exists": False}
    })
    
    updates = []
    count = 0
    
    async for doc in cursor:
        value_id = doc.get("value_id")
        if value_id:
            updates.append(
                UpdateOne(
                    {"_id": doc["_id"]},
                    {
                        "$set": {"value_ids": [value_id]},
                        "$unset": {"value_id": ""}  # Remove old field
                    }
                )
            )
            count += 1
    
    if updates:
        logger.info(f"Migrating {len(updates)} activities...")
        result = await collection.bulk_write(updates)
        logger.info(f"Migration completed: {result.modified_count} activities updated")
    else:
        logger.info("No activities need migration")
    
    # Verify migration
    old_format_count = await collection.count_documents({
        "value_id": {"$exists": True},
        "value_ids": {"$exists": False}
    })
    
    new_format_count = await collection.count_documents({
        "value_ids": {"$exists": True}
    })
    
    logger.info(f"Migration verification:")
    logger.info(f"  Activities with old format: {old_format_count}")
    logger.info(f"  Activities with new format: {new_format_count}")
    
    client.close()

if __name__ == "__main__":
    asyncio.run(migrate_activities())