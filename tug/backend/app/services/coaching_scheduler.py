# app/services/coaching_scheduler.py
import asyncio
import logging
from typing import Dict, Any
from datetime import datetime, timedelta
import schedule
import threading

from ..services.coaching_background_service import CoachingBackgroundService
from ..services.coaching_template_service import CoachingTemplateService

logger = logging.getLogger(__name__)

class CoachingScheduler:
    """Scheduler for automated coaching message tasks"""
    
    def __init__(self):
        self.background_service = CoachingBackgroundService()
        self.template_service = CoachingTemplateService()
        self.scheduler_thread = None
        self.is_running = False
        
    async def start_scheduler(self):
        """Start the coaching scheduler"""
        
        if self.is_running:
            logger.warning("Coaching scheduler is already running")
            return
        
        logger.info("Starting coaching scheduler...")
        
        # Seed default templates on startup
        try:
            await self.template_service.seed_default_templates()
        except Exception as e:
            logger.error(f"Error seeding templates on startup: {e}")
        
        # Set up scheduled tasks
        self._setup_schedule()
        
        # Start scheduler in background thread
        self.is_running = True
        self.scheduler_thread = threading.Thread(target=self._run_scheduler)
        self.scheduler_thread.daemon = True
        self.scheduler_thread.start()
        
        logger.info("Coaching scheduler started successfully")
    
    def stop_scheduler(self):
        """Stop the coaching scheduler"""
        
        if not self.is_running:
            return
        
        logger.info("Stopping coaching scheduler...")
        self.is_running = False
        
        if self.scheduler_thread:
            self.scheduler_thread.join(timeout=5.0)
        
        schedule.clear()
        logger.info("Coaching scheduler stopped")
    
    def _setup_schedule(self):
        """Set up the scheduled tasks"""
        
        # Message delivery - every 5 minutes during active hours
        schedule.every(5).minutes.do(self._schedule_message_delivery)
        
        # Message generation - every 2 hours during active hours
        schedule.every(2).hours.do(self._schedule_message_generation)
        
        # Analytics generation - daily at 2 AM
        schedule.every().day.at("02:00").do(self._schedule_analytics_generation)
        
        # Cleanup old messages - weekly on Sunday at 3 AM
        schedule.every().sunday.at("03:00").do(self._schedule_cleanup)
        
        # Health check - every hour
        schedule.every().hour.do(self._schedule_health_check)
        
        logger.info("Scheduled tasks configured")
    
    def _run_scheduler(self):
        """Run the scheduler in a background thread"""
        
        while self.is_running:
            try:
                schedule.run_pending()
                # Sleep for 1 minute between checks
                for _ in range(60):
                    if not self.is_running:
                        break
                    threading.Event().wait(1.0)
            except Exception as e:
                logger.error(f"Error in scheduler loop: {e}")
                # Continue running even if there's an error
                threading.Event().wait(60.0)
    
    def _schedule_message_delivery(self):
        """Schedule message delivery task"""
        
        try:
            # Only run during reasonable hours (6 AM - 11 PM)
            current_hour = datetime.now().hour
            if 6 <= current_hour <= 23:
                asyncio.run(self._deliver_messages_task())
        except Exception as e:
            logger.error(f"Error in scheduled message delivery: {e}")
    
    def _schedule_message_generation(self):
        """Schedule message generation task"""
        
        try:
            # Only run during reasonable hours (7 AM - 10 PM)
            current_hour = datetime.now().hour
            if 7 <= current_hour <= 22:
                asyncio.run(self._generate_messages_task())
        except Exception as e:
            logger.error(f"Error in scheduled message generation: {e}")
    
    def _schedule_analytics_generation(self):
        """Schedule analytics generation task"""
        
        try:
            asyncio.run(self._analytics_task())
        except Exception as e:
            logger.error(f"Error in scheduled analytics generation: {e}")
    
    def _schedule_cleanup(self):
        """Schedule cleanup task"""
        
        try:
            asyncio.run(self._cleanup_task())
        except Exception as e:
            logger.error(f"Error in scheduled cleanup: {e}")
    
    def _schedule_health_check(self):
        """Schedule health check task"""
        
        try:
            asyncio.run(self._health_check_task())
        except Exception as e:
            logger.error(f"Error in scheduled health check: {e}")
    
    async def _deliver_messages_task(self):
        """Deliver scheduled messages"""
        
        logger.info("Running scheduled message delivery task")
        
        try:
            stats = await self.background_service.deliver_scheduled_messages()
            
            if stats["messages_delivered"] > 0:
                logger.info(
                    f"Delivered {stats['messages_delivered']} coaching messages "
                    f"in {stats['processing_time_seconds']:.1f} seconds"
                )
            
            # Log any delivery errors
            if stats["delivery_errors"] > 0:
                logger.warning(f"Delivery errors: {stats['delivery_errors']}")
                
        except Exception as e:
            logger.error(f"Error in message delivery task: {e}")
    
    async def _generate_messages_task(self):
        """Generate messages for active users"""
        
        logger.info("Running scheduled message generation task")
        
        try:
            stats = await self.background_service.process_all_users_for_coaching_messages()
            
            if stats["messages_generated"] > 0:
                logger.info(
                    f"Generated {stats['messages_generated']} coaching messages "
                    f"for {stats['users_processed']} users "
                    f"in {stats['processing_time_seconds']:.1f} seconds"
                )
            
            # Log any errors
            if stats["errors"] > 0:
                logger.warning(f"Generation errors: {stats['errors']}")
                
        except Exception as e:
            logger.error(f"Error in message generation task: {e}")
    
    async def _analytics_task(self):
        """Generate and log analytics"""
        
        logger.info("Running scheduled analytics generation task")
        
        try:
            analytics = await self.background_service.generate_coaching_analytics()
            
            system_overview = analytics.get("system_overview", {})
            message_queue = analytics.get("message_queue", {})
            
            logger.info(
                f"Coaching Analytics Summary: "
                f"Total messages (all time): {system_overview.get('total_messages_all_time', 0)}, "
                f"This week: {system_overview.get('messages_this_week', 0)}, "
                f"Active users: {system_overview.get('active_users_this_month', 0)}, "
                f"Read rate: {system_overview.get('overall_read_rate', 0):.1f}%, "
                f"Action rate: {system_overview.get('overall_action_rate', 0):.1f}%, "
                f"Pending: {message_queue.get('pending_messages', 0)}, "
                f"Scheduled: {message_queue.get('scheduled_messages', 0)}"
            )
            
        except Exception as e:
            logger.error(f"Error in analytics task: {e}")
    
    async def _cleanup_task(self):
        """Clean up old messages and data"""
        
        logger.info("Running scheduled cleanup task")
        
        try:
            # Clean up messages older than 90 days
            result = await self.background_service.cleanup_old_messages(90)
            
            if result["deleted_count"] > 0:
                logger.info(f"Cleaned up {result['deleted_count']} old coaching messages")
                
        except Exception as e:
            logger.error(f"Error in cleanup task: {e}")
    
    async def _health_check_task(self):
        """Perform health checks on the coaching system"""
        
        logger.debug("Running scheduled health check")
        
        try:
            from ..models.coaching_message import CoachingMessage
            
            # Check for stuck messages (pending for too long)
            stuck_cutoff = datetime.now() - timedelta(hours=6)
            stuck_messages = await CoachingMessage.find({
                "status": "pending",
                "created_at": {"$lt": stuck_cutoff}
            }).count()
            
            if stuck_messages > 0:
                logger.warning(f"Found {stuck_messages} messages stuck in pending state")
            
            # Check message queue depth
            pending_count = await CoachingMessage.find({"status": "pending"}).count()
            scheduled_count = await CoachingMessage.find({"status": "scheduled"}).count()
            
            total_queue_depth = pending_count + scheduled_count
            
            if total_queue_depth > 10000:
                logger.warning(f"High message queue depth: {total_queue_depth}")
            elif total_queue_depth > 5000:
                logger.info(f"Moderate message queue depth: {total_queue_depth}")
            
            # Check for recent delivery errors (would need error tracking)
            # This is a placeholder for more sophisticated error monitoring
            
        except Exception as e:
            logger.error(f"Error in health check task: {e}")

# Global scheduler instance
coaching_scheduler = CoachingScheduler()

async def start_coaching_scheduler():
    """Start the global coaching scheduler"""
    await coaching_scheduler.start_scheduler()

def stop_coaching_scheduler():
    """Stop the global coaching scheduler"""
    coaching_scheduler.stop_scheduler()