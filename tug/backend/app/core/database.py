# app/core/database.py
from motor.motor_asyncio import AsyncIOMotorClient
from .config import settings

class Database:
    client: AsyncIOMotorClient = None
    db = None

db = Database()

async def connect_to_mongodb():
    """Create database connection."""
    db.client = AsyncIOMotorClient(settings.MONGODB_URL)
    db.db = db.client[settings.MONGODB_DB_NAME]
    
    # Verify connection
    try:
        await db.client.admin.command('ping')
        print("Successfully connected to MongoDB")
    except Exception as e:
        print(f"Failed to connect to MongoDB: {e}")
        raise e

async def close_mongodb_connection():
    """Close database connection."""
    if db.client:
        db.client.close()
        print("MongoDB connection closed")

def get_database():
    """Get database instance."""
    if not db.db:
        raise RuntimeError("Database not initialized. Call connect_to_mongodb() first.")
    return db.db

def get_collection(collection_name: str):
    """Get a specific collection."""
    database = get_database()
    return database[collection_name]