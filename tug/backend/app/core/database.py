# app/core/database.py
from beanie import init_beanie
from motor.motor_asyncio import AsyncIOMotorClient
from typing import Optional
from .config import settings
from ..models.user import User
from ..models.value import Value
from ..models.activity import Activity

class Database:
    client: Optional[AsyncIOMotorClient] = None
    
async def init_db():
    """Initialize database connection and register models"""
    client = AsyncIOMotorClient(settings.MONGODB_URL)
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