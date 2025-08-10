# app/services/prediction_cache_service.py
import asyncio
import logging
import json
import hashlib
from datetime import datetime, timedelta, timezone
from typing import Dict, Any, Optional, List
from pathlib import Path
import tempfile
import pickle

from ..models.user import User

logger = logging.getLogger(__name__)


class PredictionCacheService:
    """Service for caching ML predictions to improve performance"""
    
    def __init__(self):
        self.cache_dir = Path("/tmp/tug_prediction_cache")
        self.cache_dir.mkdir(exist_ok=True)
        
        # Cache configuration
        self.cache_ttl_hours = {
            "habit_formation": 12,      # Habit predictions change slowly
            "optimal_timing": 6,        # Timing patterns more dynamic  
            "streak_risk": 2,           # Risk needs frequent updates
            "goal_recommendations": 24, # Goals change less frequently
            "motivation_timing": 1,     # Motivation very dynamic
            "user_segmentation": 48,    # User segments stable
            "activity_forecasting": 8,  # Forecasts need regular updates
            "confidence_metrics": 6     # Confidence updates moderately
        }
        
        # Memory cache for frequently accessed predictions
        self._memory_cache = {}
        self._memory_cache_timestamps = {}
        self._max_memory_cache_size = 100  # Max users to keep in memory

    async def get_cached_predictions(
        self, 
        user: User, 
        cache_key_suffix: str = ""
    ) -> Optional[Dict[str, Any]]:
        """Get cached predictions for a user"""
        
        try:
            cache_key = self._generate_cache_key(user, cache_key_suffix)
            
            # Check memory cache first
            memory_result = self._get_from_memory_cache(cache_key)
            if memory_result:
                return memory_result
            
            # Check disk cache
            disk_result = await self._get_from_disk_cache(cache_key)
            if disk_result:
                # Store in memory cache for faster future access
                self._store_in_memory_cache(cache_key, disk_result)
                return disk_result
            
            return None
            
        except Exception as e:
            logger.error(f"Error getting cached predictions for user {user.id}: {e}")
            return None

    async def store_predictions(
        self, 
        user: User, 
        predictions: Dict[str, Any],
        cache_key_suffix: str = ""
    ) -> bool:
        """Store predictions in cache"""
        
        try:
            cache_key = self._generate_cache_key(user, cache_key_suffix)
            
            # Add timestamp and metadata
            cached_data = {
                "predictions": predictions,
                "cached_at": datetime.now(timezone.utc),
                "user_id": str(user.id),
                "cache_key": cache_key,
                "ttl_hours": self._calculate_adaptive_ttl(predictions)
            }
            
            # Store in memory cache
            self._store_in_memory_cache(cache_key, cached_data)
            
            # Store in disk cache asynchronously
            await self._store_in_disk_cache(cache_key, cached_data)
            
            return True
            
        except Exception as e:
            logger.error(f"Error storing predictions for user {user.id}: {e}")
            return False

    def _generate_cache_key(self, user: User, suffix: str = "") -> str:
        """Generate a unique cache key for a user"""
        
        # Include factors that might affect predictions
        key_components = [
            str(user.id),
            user.last_login.strftime("%Y%m%d") if user.last_login else "never",
            str(user.is_premium),
            suffix
        ]
        
        # Create hash for compact key
        key_string = "_".join(filter(None, key_components))
        return hashlib.md5(key_string.encode()).hexdigest()

    def _get_from_memory_cache(self, cache_key: str) -> Optional[Dict[str, Any]]:
        """Get predictions from memory cache"""
        
        if cache_key not in self._memory_cache:
            return None
        
        cached_data = self._memory_cache[cache_key]
        cached_at = cached_data.get("cached_at")
        ttl_hours = cached_data.get("ttl_hours", 6)
        
        if not cached_at:
            # Invalid cache entry
            del self._memory_cache[cache_key]
            return None
        
        # Check if expired
        if datetime.now(timezone.utc) - cached_at > timedelta(hours=ttl_hours):
            del self._memory_cache[cache_key]
            if cache_key in self._memory_cache_timestamps:
                del self._memory_cache_timestamps[cache_key]
            return None
        
        # Update access timestamp
        self._memory_cache_timestamps[cache_key] = datetime.now(timezone.utc)
        
        return cached_data

    def _store_in_memory_cache(self, cache_key: str, data: Dict[str, Any]) -> None:
        """Store predictions in memory cache"""
        
        # Manage cache size
        if len(self._memory_cache) >= self._max_memory_cache_size:
            self._evict_old_memory_cache_entries()
        
        self._memory_cache[cache_key] = data
        self._memory_cache_timestamps[cache_key] = datetime.now(timezone.utc)

    def _evict_old_memory_cache_entries(self) -> None:
        """Remove old entries from memory cache"""
        
        if not self._memory_cache_timestamps:
            return
        
        # Remove 20% of oldest entries
        sorted_keys = sorted(
            self._memory_cache_timestamps.items(), 
            key=lambda x: x[1]
        )
        
        num_to_remove = max(1, len(sorted_keys) // 5)
        
        for cache_key, _ in sorted_keys[:num_to_remove]:
            if cache_key in self._memory_cache:
                del self._memory_cache[cache_key]
            if cache_key in self._memory_cache_timestamps:
                del self._memory_cache_timestamps[cache_key]

    async def _get_from_disk_cache(self, cache_key: str) -> Optional[Dict[str, Any]]:
        """Get predictions from disk cache"""
        
        cache_file = self.cache_dir / f"{cache_key}.pkl"
        
        if not cache_file.exists():
            return None
        
        try:
            with open(cache_file, 'rb') as f:
                cached_data = pickle.load(f)
            
            cached_at = cached_data.get("cached_at")
            ttl_hours = cached_data.get("ttl_hours", 6)
            
            if not cached_at:
                # Invalid cache file
                cache_file.unlink(missing_ok=True)
                return None
            
            # Check if expired
            if datetime.now(timezone.utc) - cached_at > timedelta(hours=ttl_hours):
                cache_file.unlink(missing_ok=True)
                return None
            
            return cached_data
            
        except Exception as e:
            logger.warning(f"Error reading disk cache {cache_key}: {e}")
            cache_file.unlink(missing_ok=True)  # Remove corrupted file
            return None

    async def _store_in_disk_cache(self, cache_key: str, data: Dict[str, Any]) -> None:
        """Store predictions in disk cache"""
        
        cache_file = self.cache_dir / f"{cache_key}.pkl"
        
        try:
            # Use temporary file for atomic write
            with tempfile.NamedTemporaryFile(dir=self.cache_dir, delete=False, suffix='.tmp') as temp_file:
                pickle.dump(data, temp_file)
                temp_file.flush()
                
                # Atomic rename
                temp_path = Path(temp_file.name)
                temp_path.rename(cache_file)
                
        except Exception as e:
            logger.error(f"Error storing disk cache {cache_key}: {e}")

    def _calculate_adaptive_ttl(self, predictions: Dict[str, Any]) -> float:
        """Calculate adaptive TTL based on prediction confidence and type"""
        
        # Get confidence metrics
        confidence = predictions.get("confidence_metrics", {}).get("overall_confidence", 50.0)
        
        # Base TTL calculation
        if confidence > 80:
            base_ttl = 8  # High confidence predictions last longer
        elif confidence > 60:
            base_ttl = 4  # Medium confidence
        else:
            base_ttl = 2  # Low confidence predictions expire quickly
        
        # Adjust based on prediction types present
        if "streak_risk" in predictions and predictions["streak_risk"].get("risk_level") == "high":
            base_ttl = min(base_ttl, 1)  # High risk needs frequent updates
        
        if "motivation_timing" in predictions:
            intervention_timing = predictions["motivation_timing"].get("next_intervention_timing", "")
            if "within" in intervention_timing.lower():
                base_ttl = min(base_ttl, 2)  # Urgent interventions need fresh data
        
        return base_ttl

    async def invalidate_user_cache(self, user: User) -> bool:
        """Invalidate all cached predictions for a user"""
        
        try:
            # Generate possible cache keys (we don't know all suffixes)
            base_cache_key = self._generate_cache_key(user, "")
            
            # Remove from memory cache
            keys_to_remove = [key for key in self._memory_cache.keys() if key.startswith(base_cache_key[:16])]
            for key in keys_to_remove:
                if key in self._memory_cache:
                    del self._memory_cache[key]
                if key in self._memory_cache_timestamps:
                    del self._memory_cache_timestamps[key]
            
            # Remove from disk cache
            cache_files = list(self.cache_dir.glob(f"{base_cache_key[:16]}*.pkl"))
            for cache_file in cache_files:
                try:
                    cache_file.unlink()
                except Exception as e:
                    logger.warning(f"Failed to remove cache file {cache_file}: {e}")
            
            logger.info(f"Invalidated cache for user {user.id}")
            return True
            
        except Exception as e:
            logger.error(f"Error invalidating cache for user {user.id}: {e}")
            return False

    async def warm_cache_for_active_users(self) -> Dict[str, Any]:
        """Pre-warm cache for recently active users"""
        
        try:
            # Get recently active users
            cutoff_date = datetime.now(timezone.utc) - timedelta(hours=24)
            
            users = await User.find(
                User.last_login >= cutoff_date
            ).limit(50).to_list()  # Limit to most recent users
            
            warming_results = {
                "users_processed": 0,
                "predictions_cached": 0,
                "errors": 0
            }
            
            # Import services (avoid circular imports)
            from .analytics_service import AnalyticsService
            from ..models.activity import Activity
            
            for user in users:
                try:
                    # Check if cache already exists and is fresh
                    cache_key = self._generate_cache_key(user)
                    existing_cache = await self.get_cached_predictions(user)
                    
                    if existing_cache:
                        continue  # Already cached
                    
                    # Generate fresh predictions
                    activities = await Activity.find(
                        Activity.user_id == str(user.id)
                    ).sort([("date", -1)]).limit(100).to_list()
                    
                    if len(activities) < 5:
                        continue  # Skip users with insufficient data
                    
                    analytics = await AnalyticsService.generate_user_analytics(
                        user=user,
                        days_back=30
                    )
                    
                    predictions = analytics.get("predictions", {})
                    
                    if predictions:
                        await self.store_predictions(user, predictions, "warm_cache")
                        warming_results["predictions_cached"] += 1
                    
                    warming_results["users_processed"] += 1
                    
                except Exception as e:
                    logger.warning(f"Failed to warm cache for user {user.id}: {e}")
                    warming_results["errors"] += 1
                    continue
            
            logger.info(f"Cache warming completed: {warming_results}")
            return warming_results
            
        except Exception as e:
            logger.error(f"Error in cache warming: {e}", exc_info=True)
            return {"error": str(e)}

    async def cleanup_expired_cache(self) -> Dict[str, Any]:
        """Clean up expired cache entries"""
        
        try:
            cleanup_results = {
                "memory_entries_removed": 0,
                "disk_files_removed": 0,
                "errors": 0
            }
            
            # Clean up memory cache
            current_time = datetime.now(timezone.utc)
            expired_keys = []
            
            for cache_key, cached_data in self._memory_cache.items():
                cached_at = cached_data.get("cached_at")
                ttl_hours = cached_data.get("ttl_hours", 6)
                
                if not cached_at or current_time - cached_at > timedelta(hours=ttl_hours):
                    expired_keys.append(cache_key)
            
            for key in expired_keys:
                if key in self._memory_cache:
                    del self._memory_cache[key]
                if key in self._memory_cache_timestamps:
                    del self._memory_cache_timestamps[key]
                cleanup_results["memory_entries_removed"] += 1
            
            # Clean up disk cache
            cache_files = list(self.cache_dir.glob("*.pkl"))
            
            for cache_file in cache_files:
                try:
                    with open(cache_file, 'rb') as f:
                        cached_data = pickle.load(f)
                    
                    cached_at = cached_data.get("cached_at")
                    ttl_hours = cached_data.get("ttl_hours", 6)
                    
                    if not cached_at or current_time - cached_at > timedelta(hours=ttl_hours):
                        cache_file.unlink()
                        cleanup_results["disk_files_removed"] += 1
                        
                except Exception as e:
                    logger.warning(f"Error checking cache file {cache_file}: {e}")
                    cleanup_results["errors"] += 1
                    # Remove corrupted files
                    try:
                        cache_file.unlink()
                        cleanup_results["disk_files_removed"] += 1
                    except:
                        pass
            
            logger.info(f"Cache cleanup completed: {cleanup_results}")
            return cleanup_results
            
        except Exception as e:
            logger.error(f"Error in cache cleanup: {e}", exc_info=True)
            return {"error": str(e)}

    async def get_cache_stats(self) -> Dict[str, Any]:
        """Get statistics about the prediction cache"""
        
        try:
            stats = {
                "memory_cache": {
                    "entries": len(self._memory_cache),
                    "max_size": self._max_memory_cache_size,
                    "utilization": round(len(self._memory_cache) / self._max_memory_cache_size * 100, 1)
                },
                "disk_cache": {
                    "files": len(list(self.cache_dir.glob("*.pkl"))),
                    "directory_size_mb": 0
                },
                "cache_directory": str(self.cache_dir)
            }
            
            # Calculate disk cache size
            total_size = sum(f.stat().st_size for f in self.cache_dir.glob("*.pkl"))
            stats["disk_cache"]["directory_size_mb"] = round(total_size / 1024 / 1024, 2)
            
            # TTL configuration
            stats["ttl_configuration"] = self.cache_ttl_hours
            
            return stats
            
        except Exception as e:
            logger.error(f"Error getting cache stats: {e}")
            return {"error": str(e)}

    async def preload_critical_predictions(self, user: User) -> bool:
        """Preload critical predictions for a user to reduce latency"""
        
        try:
            # Check if we already have fresh cache
            existing_cache = await self.get_cached_predictions(user, "critical")
            if existing_cache:
                return True
            
            # Import required services
            from .ml_prediction_service import MLPredictionService
            from ..models.activity import Activity
            from ..models.value import Value
            
            # Get recent user data
            activities = await Activity.find(
                Activity.user_id == str(user.id)
            ).sort([("date", -1)]).limit(50).to_list()
            
            values = await Value.find(Value.user_id == str(user.id)).to_list()
            
            if len(activities) < 3:
                return False  # Not enough data
            
            # Generate critical predictions only (faster subset)
            critical_predictions = {
                "streak_risk": await MLPredictionService()._assess_streak_risk(
                    user, 
                    await MLPredictionService()._extract_features(user, activities, values)
                ),
                "motivation_timing": await MLPredictionService()._predict_motivation_timing(
                    user,
                    await MLPredictionService()._extract_features(user, activities, values)
                )
            }
            
            # Store with shorter TTL for critical data
            await self.store_predictions(user, critical_predictions, "critical")
            
            return True
            
        except Exception as e:
            logger.error(f"Error preloading critical predictions for user {user.id}: {e}")
            return False