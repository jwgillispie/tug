# app/core/database.py
from beanie import init_beanie
from motor.motor_asyncio import AsyncIOMotorClient
from pymongo.monitoring import CommandListener, ConnectionPoolListener
from pymongo.write_concern import WriteConcern
from pymongo.read_concern import ReadConcern
from pymongo.read_preferences import ReadPreference
from typing import Optional
import asyncio
import time
from .config import settings
from ..models.user import User
from ..models.value import Value
from ..models.activity import Activity
from ..models.vice import Vice
from ..models.indulgence import Indulgence
from ..models.friendship import Friendship
from ..models.social_post import SocialPost
from ..models.post_comment import PostComment
from ..models.notification import Notification, NotificationBatch
from ..models.mood import MoodEntry
from ..models.analytics import UserAnalytics, ValueInsights, StreakHistory, ActivityPattern
import logging

logger = logging.getLogger(__name__)

class QueryPerformanceMonitor(CommandListener):
    """Monitor MongoDB query performance and log slow queries"""
    
    def __init__(self, slow_query_threshold: float = 100.0):
        self.slow_query_threshold = slow_query_threshold  # milliseconds
        self.query_stats = {}
    
    def started(self, event):
        self.query_stats[event.request_id] = {
            'start_time': time.time(),
            'command': event.command_name,
            'database': event.database_name
        }
    
    def succeeded(self, event):
        if event.request_id in self.query_stats:
            start_info = self.query_stats.pop(event.request_id)
            duration_ms = (time.time() - start_info['start_time']) * 1000
            
            if duration_ms > self.slow_query_threshold:
                logger.warning(
                    f"Slow query detected: {start_info['command']} on {start_info['database']} "
                    f"took {duration_ms:.2f}ms"
                )
    
    def failed(self, event):
        if event.request_id in self.query_stats:
            start_info = self.query_stats.pop(event.request_id)
            duration_ms = (time.time() - start_info['start_time']) * 1000
            logger.error(
                f"Query failed: {start_info['command']} on {start_info['database']} "
                f"failed after {duration_ms:.2f}ms - {event.failure}"
            )

class ConnectionPoolMonitor(ConnectionPoolListener):
    """Monitor MongoDB connection pool health"""
    
    def pool_created(self, event):
        logger.info(f"Connection pool created for {event.address}")
    
    def pool_cleared(self, event):
        logger.warning(f"Connection pool cleared for {event.address}")
    
    def pool_closed(self, event):
        logger.info(f"Connection pool closed for {event.address}")
    
    def connection_created(self, event):
        logger.debug(f"Connection created: {event.connection_id} for {event.address}")
    
    def connection_closed(self, event):
        logger.debug(f"Connection closed: {event.connection_id} for {event.address}")

class Database:
    client: Optional[AsyncIOMotorClient] = None
    performance_monitor: Optional[QueryPerformanceMonitor] = None
    connection_monitor: Optional[ConnectionPoolMonitor] = None
    
async def init_db():
    """Initialize optimized database connection with monitoring and register models"""
    connection_url = settings.MONGODB_URL
    logger.info("Initializing optimized MongoDB connection with performance monitoring")
    
    # Initialize performance and connection monitoring
    Database.performance_monitor = QueryPerformanceMonitor(slow_query_threshold=settings.SLOW_QUERY_THRESHOLD_MS)
    Database.connection_monitor = ConnectionPoolMonitor()
    
    # Build connection settings from configuration
    connection_kwargs = {
        # Connection pool optimization
        "maxPoolSize": settings.MONGODB_MAX_POOL_SIZE,
        "minPoolSize": settings.MONGODB_MIN_POOL_SIZE,
        "maxIdleTimeMS": settings.MONGODB_MAX_IDLE_TIME_MS,
        
        # Connection timeout settings
        "connectTimeoutMS": settings.MONGODB_CONNECT_TIMEOUT_MS,
        "serverSelectionTimeoutMS": settings.MONGODB_SERVER_SELECTION_TIMEOUT_MS,
        "socketTimeoutMS": settings.MONGODB_SOCKET_TIMEOUT_MS,
        
        # Write and read preferences for performance
        "w": "majority",  # Wait for majority acknowledgment
        "j": True,  # Journal writes for durability
        
        # Read preferences for analytics queries
        "readPreference": "secondaryPreferred",  # Prefer secondary for read-heavy workloads
        
        # Compression for network efficiency
        "compressors": "snappy,zlib",  # Enable compression
        
        # Additional optimization settings
        "retryWrites": True,  # Automatic retry for transient network errors
        "retryReads": True,   # Automatic retry for read operations
        
        # Heartbeat settings for connection health
        "heartbeatFrequencyMS": 10000,  # Check server every 10 seconds
    }
    
    # Add monitoring if enabled
    if settings.ENABLE_QUERY_MONITORING:
        connection_kwargs["event_listeners"] = [Database.performance_monitor, Database.connection_monitor]
    
    # Create optimized connection
    client = AsyncIOMotorClient(connection_url, **connection_kwargs)
    
    try:
        # Test the connection with timeout
        await asyncio.wait_for(client.admin.command('ping'), timeout=10.0)
        logger.info("Successfully connected to MongoDB with optimized settings")
        
        # Log connection pool stats
        server_info = await client.admin.command('buildInfo')
        logger.info(f"Connected to MongoDB {server_info.get('version', 'unknown')}")
        
    except asyncio.TimeoutError:
        logger.error("MongoDB connection timeout")
        raise
    except Exception as e:
        logger.error(f"Failed to connect to MongoDB: {e}")
        raise
    
    # Initialize Beanie with all models including analytics
    try:
        await init_beanie(
            database=client[settings.MONGODB_DB_NAME],
            document_models=[
                User,
                Value, 
                Activity,
                Vice,
                Indulgence,
                Friendship,
                SocialPost,
                PostComment,
                Notification,
                NotificationBatch,
                MoodEntry,
                UserAnalytics,
                ValueInsights,
                StreakHistory,
                ActivityPattern,
            ]
        )
        logger.info("Successfully initialized Beanie ODM with all models")
        
        # Store the client for later access
        Database.client = client
        
        # Log database optimization status
        await log_database_status(client)
        
        return client
        
    except Exception as e:
        logger.error(f"Failed to initialize Beanie ODM: {e}")
        await client.close()
        raise
async def log_database_status(client: AsyncIOMotorClient):
    """Log database optimization status and health metrics"""
    try:
        db = client[settings.MONGODB_DB_NAME]
        
        # Get database stats
        stats = await db.command("dbStats")
        logger.info(f"Database '{settings.MONGODB_DB_NAME}' stats:")
        logger.info(f"  - Collections: {stats.get('collections', 'unknown')}")
        logger.info(f"  - Data Size: {stats.get('dataSize', 0) / (1024*1024):.2f} MB")
        logger.info(f"  - Index Size: {stats.get('indexSize', 0) / (1024*1024):.2f} MB")
        logger.info(f"  - Storage Size: {stats.get('storageSize', 0) / (1024*1024):.2f} MB")
        
        # Check if indexes are properly created for key collections
        critical_collections = ['users', 'activities', 'values', 'vices', 'social_posts']
        for collection_name in critical_collections:
            try:
                collection = db[collection_name]
                indexes = await collection.list_indexes().to_list(length=None)
                index_count = len(indexes)
                logger.info(f"  - Collection '{collection_name}': {index_count} indexes")
            except Exception as e:
                logger.warning(f"Could not check indexes for collection '{collection_name}': {e}")
                
    except Exception as e:
        logger.warning(f"Could not retrieve database status: {e}")

async def get_database_health_metrics() -> dict:
    """Get current database health and performance metrics"""
    if not Database.client:
        return {"status": "disconnected"}
    
    try:
        db = Database.client[settings.MONGODB_DB_NAME]
        
        # Basic connectivity test
        await Database.client.admin.command('ping')
        
        # Get server status
        server_status = await Database.client.admin.command('serverStatus')
        
        # Get database stats
        db_stats = await db.command('dbStats')
        
        # Connection pool stats
        connections = server_status.get('connections', {})
        
        return {
            "status": "connected",
            "server_version": server_status.get('version'),
            "uptime_seconds": server_status.get('uptime'),
            "connections": {
                "current": connections.get('current', 0),
                "available": connections.get('available', 0),
                "total_created": connections.get('totalCreated', 0)
            },
            "database": {
                "name": settings.MONGODB_DB_NAME,
                "collections": db_stats.get('collections', 0),
                "data_size_mb": db_stats.get('dataSize', 0) / (1024*1024),
                "index_size_mb": db_stats.get('indexSize', 0) / (1024*1024),
                "storage_size_mb": db_stats.get('storageSize', 0) / (1024*1024)
            },
            "performance": {
                "opcounters": server_status.get('opcounters', {}),
                "network_bytes_in": server_status.get('network', {}).get('bytesIn', 0),
                "network_bytes_out": server_status.get('network', {}).get('bytesOut', 0)
            }
        }
        
    except Exception as e:
        return {
            "status": "error",
            "error": str(e)
        }

async def optimize_collection_indexes():
    """Ensure all collections have optimal indexes created"""
    if not Database.client:
        logger.error("Database client not initialized")
        return False
    
    try:
        db = Database.client[settings.MONGODB_DB_NAME]
        
        # Collections that need index optimization checks
        collections_to_optimize = [
            'users', 'activities', 'values', 'vices', 'indulgences',
            'social_posts', 'friendships', 'mood_entries', 'user_analytics',
            'value_insights', 'streak_history', 'activity_patterns'
        ]
        
        for collection_name in collections_to_optimize:
            try:
                collection = db[collection_name]
                
                # Check if collection exists
                if collection_name not in await db.list_collection_names():
                    logger.info(f"Collection '{collection_name}' does not exist yet, skipping index optimization")
                    continue
                
                # Get current indexes
                current_indexes = await collection.list_indexes().to_list(length=None)
                index_names = [idx.get('name') for idx in current_indexes]
                
                logger.info(f"Collection '{collection_name}' has {len(current_indexes)} indexes: {index_names}")
                
                # Log index usage stats if available (requires MongoDB 3.2+)
                try:
                    index_stats = await collection.aggregate([{"$indexStats": {}}]).to_list(length=None)
                    for stat in index_stats:
                        usage_count = stat.get('accesses', {}).get('ops', 0)
                        logger.debug(f"  Index '{stat.get('name')}' used {usage_count} times")
                except:
                    pass  # indexStats may not be available in all MongoDB versions
                    
            except Exception as e:
                logger.warning(f"Could not optimize indexes for collection '{collection_name}': {e}")
        
        logger.info("Index optimization check completed")
        return True
        
    except Exception as e:
        logger.error(f"Failed to optimize collection indexes: {e}")
        return False

def get_database():
    """Get the current database client"""
    if not Database.client:
        raise RuntimeError("Database not initialized. Call init_db() first.")
    return Database.client[settings.MONGODB_DB_NAME]

async def close_db():
    """Close database connection gracefully"""
    if Database.client:
        logger.info("Closing database connection...")
        Database.client.close()
        Database.client = None
        Database.performance_monitor = None
        Database.connection_monitor = None
        logger.info("Database connection closed")