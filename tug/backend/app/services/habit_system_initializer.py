# app/services/habit_system_initializer.py
import asyncio
import logging
from typing import Dict, Any

from ..services.habit_template_seeder import seed_habit_data
from ..models.habit_suggestion import HabitTemplate, HabitRecommendationConfig

logger = logging.getLogger(__name__)

class HabitSystemInitializer:
    """Initialize the habit suggestion system"""
    
    @classmethod
    async def initialize_system(cls) -> Dict[str, Any]:
        """Initialize the entire habit suggestion system"""
        
        try:
            logger.info("Starting habit suggestion system initialization...")
            
            # Seed habit templates and configuration
            seed_result = await seed_habit_data()
            
            # Verify system is ready
            template_count = await HabitTemplate.count()
            config_count = await HabitRecommendationConfig.find(
                HabitRecommendationConfig.is_active == True
            ).count()
            
            if template_count == 0:
                logger.error("No habit templates found after seeding!")
                return {
                    "success": False,
                    "error": "Failed to seed habit templates"
                }
            
            if config_count == 0:
                logger.error("No active configuration found after seeding!")
                return {
                    "success": False,
                    "error": "Failed to create configuration"
                }
            
            # Log statistics
            category_stats = await cls._get_category_statistics()
            difficulty_stats = await cls._get_difficulty_statistics()
            
            result = {
                "success": True,
                "templates_seeded": seed_result["templates_seeded"],
                "config_version": seed_result["config_version"],
                "total_templates": template_count,
                "category_distribution": category_stats,
                "difficulty_distribution": difficulty_stats,
                "system_ready": True
            }
            
            logger.info(f"Habit suggestion system initialized successfully: {result}")
            return result
            
        except Exception as e:
            logger.error(f"Error initializing habit system: {e}", exc_info=True)
            return {
                "success": False,
                "error": str(e),
                "system_ready": False
            }
    
    @classmethod
    async def _get_category_statistics(cls) -> Dict[str, int]:
        """Get template count by category"""
        
        try:
            pipeline = [
                {"$match": {"is_active": True}},
                {"$group": {"_id": "$category", "count": {"$sum": 1}}},
                {"$sort": {"count": -1}}
            ]
            
            results = await HabitTemplate.aggregate(pipeline).to_list()
            return {result["_id"]: result["count"] for result in results}
            
        except Exception as e:
            logger.error(f"Error getting category statistics: {e}")
            return {}
    
    @classmethod
    async def _get_difficulty_statistics(cls) -> Dict[str, int]:
        """Get template count by difficulty level"""
        
        try:
            pipeline = [
                {"$match": {"is_active": True}},
                {"$group": {"_id": "$difficulty_level", "count": {"$sum": 1}}},
                {"$sort": {"count": -1}}
            ]
            
            results = await HabitTemplate.aggregate(pipeline).to_list()
            return {result["_id"]: result["count"] for result in results}
            
        except Exception as e:
            logger.error(f"Error getting difficulty statistics: {e}")
            return {}
    
    @classmethod
    async def check_system_health(cls) -> Dict[str, Any]:
        """Check if the habit suggestion system is healthy"""
        
        try:
            # Check template availability
            template_count = await HabitTemplate.find(
                HabitTemplate.is_active == True
            ).count()
            
            # Check configuration
            config = await HabitRecommendationConfig.find_one(
                HabitRecommendationConfig.is_active == True
            )
            
            # Check template distribution
            category_stats = await cls._get_category_statistics()
            min_category_count = min(category_stats.values()) if category_stats else 0
            
            health_status = {
                "system_healthy": True,
                "issues": [],
                "template_count": template_count,
                "config_exists": config is not None,
                "category_distribution": category_stats,
                "min_category_templates": min_category_count
            }
            
            # Check for issues
            if template_count < 20:
                health_status["issues"].append("Low template count")
                health_status["system_healthy"] = False
            
            if not config:
                health_status["issues"].append("No active configuration")
                health_status["system_healthy"] = False
            
            if min_category_count < 2:
                health_status["issues"].append("Some categories have few templates")
                health_status["system_healthy"] = False
            
            return health_status
            
        except Exception as e:
            logger.error(f"Error checking system health: {e}", exc_info=True)
            return {
                "system_healthy": False,
                "issues": [f"Health check failed: {str(e)}"],
                "error": str(e)
            }

# Convenience function for startup
async def initialize_habit_system():
    """Initialize habit system on startup"""
    return await HabitSystemInitializer.initialize_system()