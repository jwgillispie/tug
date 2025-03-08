# app/core/database.py
from beanie import init_beanie
from motor.motor_asyncio import AsyncIOMotorClient
from typing import Optional
from .config import settings
from ..models.user import User
from ..models.value import Value
from ..models.activity import Activity
import logging

logger = logging.getLogger(__name__)

class Database:
    client: Optional[AsyncIOMotorClient] = None
    
async def init_db():
    """Initialize database connection and register models"""
    # Log the MongoDB URL we're trying to connect to (without credentials)
    connection_url = settings.MONGODB_URL
    safe_url = connection_url.split('@')[-1] if '@' in connection_url else connection_url
    logger.info(f"Connecting to MongoDB: {safe_url}")
    
    client = AsyncIOMotorClient(connection_url)
    
    try:
        # Test the connection
        await client.admin.command('ping')
        logger.info("Successfully connected to MongoDB")
    except Exception as e:
        logger.error(f"Failed to connect to MongoDB: {e}")
        raise
    
    await init_beanie(
        database=client[settings.MONGODB_DB_NAME],
        document_models=[
            User,
            Value,
            Activity,
        ]
    )
    
    # Store the client for later access if needed
    Database.client = client
    
    return client

async def close_db():
    """Close database connection"""
    if Database.client:
        Database.client.close()