# app/services/ml_background_service.py
import asyncio
import logging
from datetime import datetime, timedelta, timezone
from typing import Dict, Any
import schedule
import threading

from .ml_training_service import MLTrainingService
from .prediction_cache_service import PredictionCacheService

logger = logging.getLogger(__name__)


class MLBackgroundService:
    """Background service for ML model training, cache management, and maintenance"""
    
    def __init__(self):
        self.training_service = MLTrainingService()
        self.cache_service = PredictionCacheService()
        self.is_running = False
        self._background_thread = None
        
        # Task scheduling configuration
        self.schedule_config = {
            "model_training": "daily",      # Train models daily
            "cache_cleanup": "hourly",      # Clean expired cache hourly
            "cache_warming": "every_4_hours", # Warm cache every 4 hours
            "model_evaluation": "weekly"    # Evaluate models weekly
        }

    def start_background_tasks(self):
        """Start the background task scheduler"""
        
        if self.is_running:
            logger.warning("Background tasks already running")
            return
        
        logger.info("Starting ML background tasks")
        
        # Schedule tasks
        self._schedule_tasks()
        
        # Start background thread
        self.is_running = True
        self._background_thread = threading.Thread(target=self._run_scheduler)
        self._background_thread.daemon = True
        self._background_thread.start()
        
        logger.info("ML background tasks started successfully")

    def stop_background_tasks(self):
        """Stop the background task scheduler"""
        
        if not self.is_running:
            logger.warning("Background tasks not running")
            return
        
        logger.info("Stopping ML background tasks")
        
        self.is_running = False
        schedule.clear()
        
        if self._background_thread and self._background_thread.is_alive():
            self._background_thread.join(timeout=30)
        
        logger.info("ML background tasks stopped")

    def _schedule_tasks(self):
        """Configure task scheduling"""
        
        # Model training - daily at 2 AM
        schedule.every().day.at("02:00").do(self._run_async_task, self._train_models_task)
        
        # Cache cleanup - every hour
        schedule.every().hour.do(self._run_async_task, self._cache_cleanup_task)
        
        # Cache warming - every 4 hours
        schedule.every(4).hours.do(self._run_async_task, self._cache_warming_task)
        
        # Model evaluation - weekly on Sunday at 3 AM
        schedule.every().sunday.at("03:00").do(self._run_async_task, self._model_evaluation_task)
        
        # Health check - every 30 minutes
        schedule.every(30).minutes.do(self._run_async_task, self._health_check_task)
        
        logger.info("Background tasks scheduled successfully")

    def _run_scheduler(self):
        """Run the task scheduler in background thread"""
        
        while self.is_running:
            try:
                schedule.run_pending()
                threading.Event().wait(60)  # Check every minute
            except Exception as e:
                logger.error(f"Error in background scheduler: {e}", exc_info=True)
                threading.Event().wait(300)  # Wait 5 minutes before retrying

    def _run_async_task(self, task_func):
        """Wrapper to run async tasks in the background thread"""
        
        try:
            # Create new event loop for this thread
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)
            
            # Run the async task
            loop.run_until_complete(task_func())
            
        except Exception as e:
            logger.error(f"Error running async task {task_func.__name__}: {e}", exc_info=True)
        finally:
            try:
                loop.close()
            except:
                pass

    async def _train_models_task(self):
        """Background task for model training"""
        
        logger.info("Starting background model training task")
        
        try:
            # Check if retraining is needed
            retrain_result = await self.training_service.retrain_models_if_needed()
            
            if retrain_result.get("status") == "retrained":
                logger.info(f"Models retrained successfully: {retrain_result.get('reason', 'Unknown reason')}")
            elif retrain_result.get("status") == "no_retraining_needed":
                logger.info("Models are up to date, no retraining needed")
            else:
                logger.warning(f"Model retraining completed with status: {retrain_result.get('status')}")
            
            return retrain_result
            
        except Exception as e:
            logger.error(f"Error in model training task: {e}", exc_info=True)
            return {"error": str(e)}

    async def _cache_cleanup_task(self):
        """Background task for cache cleanup"""
        
        logger.info("Starting background cache cleanup task")
        
        try:
            cleanup_result = await self.cache_service.cleanup_expired_cache()
            
            logger.info(f"Cache cleanup completed: {cleanup_result}")
            return cleanup_result
            
        except Exception as e:
            logger.error(f"Error in cache cleanup task: {e}", exc_info=True)
            return {"error": str(e)}

    async def _cache_warming_task(self):
        """Background task for cache warming"""
        
        logger.info("Starting background cache warming task")
        
        try:
            warming_result = await self.cache_service.warm_cache_for_active_users()
            
            logger.info(f"Cache warming completed: {warming_result}")
            return warming_result
            
        except Exception as e:
            logger.error(f"Error in cache warming task: {e}", exc_info=True)
            return {"error": str(e)}

    async def _model_evaluation_task(self):
        """Background task for model evaluation"""
        
        logger.info("Starting background model evaluation task")
        
        try:
            evaluation_result = await self.training_service.evaluate_models()
            
            logger.info(f"Model evaluation completed: {evaluation_result}")
            
            # Log model performance metrics
            if "results" in evaluation_result:
                for model_name, metrics in evaluation_result["results"].items():
                    if "error" not in metrics:
                        logger.info(f"Model {model_name} performance: {metrics}")
            
            return evaluation_result
            
        except Exception as e:
            logger.error(f"Error in model evaluation task: {e}", exc_info=True)
            return {"error": str(e)}

    async def _health_check_task(self):
        """Background task for health monitoring"""
        
        try:
            # Check model availability
            model_info = await self.training_service.get_model_info()
            
            # Check cache stats
            cache_stats = await self.cache_service.get_cache_stats()
            
            # Log health metrics
            available_models = sum(1 for info in model_info.get("models", {}).values() if info.get("available"))
            total_models = len(model_info.get("models", {}))
            
            cache_utilization = cache_stats.get("memory_cache", {}).get("utilization", 0)
            disk_size_mb = cache_stats.get("disk_cache", {}).get("directory_size_mb", 0)
            
            logger.info(f"ML Health Check - Models: {available_models}/{total_models}, Cache: {cache_utilization}% memory, {disk_size_mb}MB disk")
            
            # Alert on issues
            if available_models < total_models * 0.5:  # Less than 50% models available
                logger.warning(f"Low model availability: {available_models}/{total_models}")
            
            if cache_utilization > 90:  # High memory cache utilization
                logger.warning(f"High cache utilization: {cache_utilization}%")
            
            if disk_size_mb > 500:  # Large disk cache
                logger.warning(f"Large disk cache: {disk_size_mb}MB")
            
            return {
                "status": "healthy",
                "models_available": available_models,
                "total_models": total_models,
                "cache_utilization": cache_utilization,
                "disk_cache_mb": disk_size_mb
            }
            
        except Exception as e:
            logger.error(f"Error in health check task: {e}", exc_info=True)
            return {"error": str(e)}

    async def run_immediate_tasks(self) -> Dict[str, Any]:
        """Run all background tasks immediately (for testing/debugging)"""
        
        logger.info("Running all background tasks immediately")
        
        results = {}
        
        # Run each task
        tasks = [
            ("model_training", self._train_models_task),
            ("cache_cleanup", self._cache_cleanup_task),
            ("cache_warming", self._cache_warming_task),
            ("model_evaluation", self._model_evaluation_task),
            ("health_check", self._health_check_task)
        ]
        
        for task_name, task_func in tasks:
            try:
                logger.info(f"Running immediate task: {task_name}")
                result = await task_func()
                results[task_name] = result
                
            except Exception as e:
                logger.error(f"Error in immediate task {task_name}: {e}", exc_info=True)
                results[task_name] = {"error": str(e)}
        
        return results

    def get_task_status(self) -> Dict[str, Any]:
        """Get status of background tasks"""
        
        return {
            "is_running": self.is_running,
            "background_thread_alive": self._background_thread.is_alive() if self._background_thread else False,
            "scheduled_jobs": len(schedule.jobs),
            "schedule_config": self.schedule_config,
            "next_run_times": {
                job.tags[0] if job.tags else f"job_{i}": job.next_run.isoformat() if job.next_run else None
                for i, job in enumerate(schedule.jobs)
            }
        }

    async def force_model_training(self) -> Dict[str, Any]:
        """Force immediate model training"""
        
        logger.info("Forcing immediate model training")
        
        try:
            result = await self.training_service.train_global_models()
            logger.info(f"Forced model training completed: {result}")
            return result
            
        except Exception as e:
            logger.error(f"Error in forced model training: {e}", exc_info=True)
            return {"error": str(e)}

    async def force_cache_refresh(self) -> Dict[str, Any]:
        """Force immediate cache refresh"""
        
        logger.info("Forcing immediate cache refresh")
        
        try:
            # Cleanup old cache
            cleanup_result = await self.cache_service.cleanup_expired_cache()
            
            # Warm new cache
            warming_result = await self.cache_service.warm_cache_for_active_users()
            
            return {
                "cleanup": cleanup_result,
                "warming": warming_result
            }
            
        except Exception as e:
            logger.error(f"Error in forced cache refresh: {e}", exc_info=True)
            return {"error": str(e)}


# Global background service instance
ml_background_service = MLBackgroundService()


def start_ml_background_tasks():
    """Start ML background tasks (called during app startup)"""
    ml_background_service.start_background_tasks()


def stop_ml_background_tasks():
    """Stop ML background tasks (called during app shutdown)"""
    ml_background_service.stop_background_tasks()


async def get_ml_service_status() -> Dict[str, Any]:
    """Get status of ML background services"""
    return ml_background_service.get_task_status()