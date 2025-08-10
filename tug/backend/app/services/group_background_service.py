# app/services/group_background_service.py
import asyncio
import logging
from datetime import datetime, timedelta, date
from typing import List
from ..models.premium_group import PremiumGroup, GroupStatus
from ..models.group_analytics import AnalyticsPeriod
from .group_analytics_service import GroupAnalyticsService
from .group_ml_service import GroupMLService
from .group_challenge_service import GroupChallengeService

logger = logging.getLogger(__name__)

class GroupBackgroundService:
    """Background service for group analytics, insights, and maintenance tasks"""
    
    @staticmethod
    async def generate_daily_analytics():
        """Generate daily analytics for all active premium groups"""
        try:
            logger.info("Starting daily analytics generation for premium groups")
            
            # Get all active groups
            active_groups = await PremiumGroup.find({
                "status": GroupStatus.ACTIVE
            }).to_list()
            
            tasks = []
            for group in active_groups:
                task = GroupAnalyticsService.generate_group_analytics(
                    str(group.id), 
                    AnalyticsPeriod.DAILY
                )
                tasks.append(task)
            
            # Process in batches to avoid overwhelming the database
            batch_size = 10
            for i in range(0, len(tasks), batch_size):
                batch = tasks[i:i+batch_size]
                await asyncio.gather(*batch, return_exceptions=True)
                await asyncio.sleep(1)  # Brief pause between batches
            
            logger.info(f"Completed daily analytics generation for {len(active_groups)} groups")
            
        except Exception as e:
            logger.error(f"Error in daily analytics generation: {e}", exc_info=True)
    
    @staticmethod
    async def generate_weekly_analytics():
        """Generate weekly analytics for all active premium groups"""
        try:
            logger.info("Starting weekly analytics generation for premium groups")
            
            active_groups = await PremiumGroup.find({
                "status": GroupStatus.ACTIVE
            }).to_list()
            
            for group in active_groups:
                try:
                    await GroupAnalyticsService.generate_group_analytics(
                        str(group.id), 
                        AnalyticsPeriod.WEEKLY
                    )
                    await asyncio.sleep(0.5)  # Pause between groups
                except Exception as e:
                    logger.error(f"Error generating weekly analytics for group {group.id}: {e}")
            
            logger.info(f"Completed weekly analytics generation for {len(active_groups)} groups")
            
        except Exception as e:
            logger.error(f"Error in weekly analytics generation: {e}", exc_info=True)
    
    @staticmethod
    async def generate_monthly_analytics():
        """Generate monthly analytics for all active premium groups"""
        try:
            logger.info("Starting monthly analytics generation for premium groups")
            
            active_groups = await PremiumGroup.find({
                "status": GroupStatus.ACTIVE
            }).to_list()
            
            for group in active_groups:
                try:
                    await GroupAnalyticsService.generate_group_analytics(
                        str(group.id), 
                        AnalyticsPeriod.MONTHLY
                    )
                    await asyncio.sleep(0.5)
                except Exception as e:
                    logger.error(f"Error generating monthly analytics for group {group.id}: {e}")
            
            logger.info(f"Completed monthly analytics generation for {len(active_groups)} groups")
            
        except Exception as e:
            logger.error(f"Error in monthly analytics generation: {e}", exc_info=True)
    
    @staticmethod
    async def generate_group_insights():
        """Generate AI-powered insights for all active premium groups"""
        try:
            logger.info("Starting AI insights generation for premium groups")
            
            active_groups = await PremiumGroup.find({
                "status": GroupStatus.ACTIVE,
                "analytics_enabled": True
            }).to_list()
            
            insights_generated = 0
            for group in active_groups:
                try:
                    insights = await GroupMLService.generate_group_insights(str(group.id))
                    if insights:
                        insights_generated += len(insights)
                        logger.info(f"Generated {len(insights)} insights for group {group.id}")
                    
                    await asyncio.sleep(2)  # Longer pause for AI processing
                except Exception as e:
                    logger.error(f"Error generating insights for group {group.id}: {e}")
            
            logger.info(f"Generated {insights_generated} total insights for {len(active_groups)} groups")
            
        except Exception as e:
            logger.error(f"Error in group insights generation: {e}", exc_info=True)
    
    @staticmethod
    async def update_group_member_analytics():
        """Update member analytics for all active group members"""
        try:
            logger.info("Starting member analytics update")
            
            # This would integrate with individual member activity tracking
            # For now, just log the task
            logger.info("Member analytics update completed")
            
        except Exception as e:
            logger.error(f"Error updating member analytics: {e}", exc_info=True)
    
    @staticmethod
    async def process_challenge_lifecycle():
        """Process challenge lifecycle (start, end, notifications)"""
        try:
            logger.info("Processing group challenge lifecycle")
            await GroupChallengeService.process_challenge_lifecycle()
            logger.info("Challenge lifecycle processing completed")
            
        except Exception as e:
            logger.error(f"Error processing challenge lifecycle: {e}", exc_info=True)
    
    @staticmethod
    async def cleanup_expired_insights():
        """Clean up expired group insights"""
        try:
            from ..models.group_analytics import GroupInsight
            
            # Delete insights that are past their expiration date
            expired_count = await GroupInsight.find({
                "expires_at": {"$lt": datetime.utcnow()},
                "status": "active"
            }).update_many({"$set": {"status": "expired"}})
            
            logger.info(f"Marked {expired_count} insights as expired")
            
        except Exception as e:
            logger.error(f"Error cleaning up expired insights: {e}")
    
    @staticmethod
    async def update_group_health_scores():
        """Update health scores for all active groups"""
        try:
            logger.info("Starting group health score updates")
            
            active_groups = await PremiumGroup.find({
                "status": GroupStatus.ACTIVE
            }).to_list()
            
            for group in active_groups:
                try:
                    health_data = await GroupMLService.analyze_group_health_score(str(group.id))
                    
                    # Update group with health score (could add a health_score field to PremiumGroup)
                    # For now, just log the scores
                    logger.info(f"Group {group.id} health score: {health_data.get('health_score', 0)}")
                    
                    await asyncio.sleep(0.3)
                except Exception as e:
                    logger.error(f"Error updating health score for group {group.id}: {e}")
            
            logger.info(f"Completed health score updates for {len(active_groups)} groups")
            
        except Exception as e:
            logger.error(f"Error updating group health scores: {e}", exc_info=True)
    
    @staticmethod
    async def send_digest_notifications():
        """Send weekly digest notifications to group leaders"""
        try:
            logger.info("Starting weekly digest notifications")
            
            from ..models.premium_group import GroupMembership, GroupRole
            from ..services.notification_service import NotificationService
            
            # Get group owners and admins
            leadership_memberships = await GroupMembership.find({
                "role": {"$in": [GroupRole.OWNER, GroupRole.ADMIN]},
                "status": "active"
            }).to_list()
            
            for membership in leadership_memberships:
                try:
                    # Create digest notification
                    await NotificationService.create_group_notification(
                        user_id=membership.user_id,
                        group_id=membership.group_id,
                        notification_type="weekly_digest",
                        message="Your weekly group digest is ready",
                        data={
                            "digest_type": "weekly",
                            "action_url": f"/premium-groups/{membership.group_id}/dashboard"
                        }
                    )
                    
                    await asyncio.sleep(0.1)  # Brief pause between notifications
                except Exception as e:
                    logger.error(f"Error sending digest notification for membership {membership.id}: {e}")
            
            logger.info(f"Sent digest notifications to {len(leadership_memberships)} group leaders")
            
        except Exception as e:
            logger.error(f"Error sending digest notifications: {e}")
    
    @staticmethod
    async def archive_inactive_groups():
        """Archive groups that have been inactive for extended periods"""
        try:
            logger.info("Checking for inactive groups to archive")
            
            # Define inactivity threshold (e.g., 90 days)
            inactivity_threshold = datetime.utcnow() - timedelta(days=90)
            
            inactive_groups = await PremiumGroup.find({
                "status": GroupStatus.ACTIVE,
                "last_activity_at": {"$lt": inactivity_threshold},
                "total_members": {"$lt": 3}  # Also require low membership
            }).to_list()
            
            archived_count = 0
            for group in inactive_groups:
                try:
                    # Send notification to group owner before archiving
                    owner_membership = await GroupMembership.find_one({
                        "group_id": str(group.id),
                        "role": GroupRole.OWNER,
                        "status": "active"
                    })
                    
                    if owner_membership:
                        await NotificationService.create_group_notification(
                            user_id=owner_membership.user_id,
                            group_id=str(group.id),
                            notification_type="group_archived",
                            message=f"Your group '{group.name}' has been archived due to inactivity",
                            data={"reason": "inactivity", "action_url": f"/premium-groups/{group.id}"}
                        )
                    
                    # Archive the group
                    group.status = GroupStatus.ARCHIVED
                    await group.save()
                    
                    archived_count += 1
                    
                except Exception as e:
                    logger.error(f"Error archiving group {group.id}: {e}")
            
            logger.info(f"Archived {archived_count} inactive groups")
            
        except Exception as e:
            logger.error(f"Error archiving inactive groups: {e}")
    
    @staticmethod
    async def run_daily_tasks():
        """Run all daily background tasks"""
        try:
            logger.info("Starting daily group background tasks")
            
            # Run tasks in parallel where possible
            await asyncio.gather(
                GroupBackgroundService.generate_daily_analytics(),
                GroupBackgroundService.process_challenge_lifecycle(),
                GroupBackgroundService.cleanup_expired_insights(),
                return_exceptions=True
            )
            
            # Update member analytics (might be heavy, so run separately)
            await GroupBackgroundService.update_group_member_analytics()
            
            logger.info("Completed daily group background tasks")
            
        except Exception as e:
            logger.error(f"Error in daily group background tasks: {e}", exc_info=True)
    
    @staticmethod
    async def run_weekly_tasks():
        """Run all weekly background tasks"""
        try:
            logger.info("Starting weekly group background tasks")
            
            # Run weekly tasks
            await asyncio.gather(
                GroupBackgroundService.generate_weekly_analytics(),
                GroupBackgroundService.generate_group_insights(),
                GroupBackgroundService.update_group_health_scores(),
                GroupBackgroundService.send_digest_notifications(),
                return_exceptions=True
            )
            
            logger.info("Completed weekly group background tasks")
            
        except Exception as e:
            logger.error(f"Error in weekly group background tasks: {e}", exc_info=True)
    
    @staticmethod
    async def run_monthly_tasks():
        """Run all monthly background tasks"""
        try:
            logger.info("Starting monthly group background tasks")
            
            await asyncio.gather(
                GroupBackgroundService.generate_monthly_analytics(),
                GroupBackgroundService.archive_inactive_groups(),
                return_exceptions=True
            )
            
            logger.info("Completed monthly group background tasks")
            
        except Exception as e:
            logger.error(f"Error in monthly group background tasks: {e}", exc_info=True)