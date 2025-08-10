# app/services/group_analytics_service.py
import logging
from typing import List, Dict, Any, Optional
from datetime import datetime, timedelta, date
from fastapi import HTTPException, status
from bson import ObjectId
import asyncio
from collections import defaultdict

from ..models.user import User
from ..models.premium_group import PremiumGroup, GroupMembership, GroupPost, GroupRole
from ..models.group_analytics import GroupAnalytics, MemberAnalytics, GroupInsight, AnalyticsPeriod
from ..schemas.premium_group import (
    GroupAnalyticsData, MemberAnalyticsData, GroupInsightData,
    GroupLeaderboardEntry
)
from .ml_prediction_service import MLPredictionService

logger = logging.getLogger(__name__)

class GroupAnalyticsService:
    """Service for generating and managing group analytics and insights"""
    
    @staticmethod
    async def generate_group_analytics(group_id: str, period: AnalyticsPeriod = AnalyticsPeriod.MONTHLY) -> GroupAnalytics:
        """Generate comprehensive analytics for a group"""
        try:
            group = await PremiumGroup.get(group_id)
            if not group:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Group not found"
                )
            
            # Determine date range
            today = date.today()
            if period == AnalyticsPeriod.DAILY:
                period_start = today
                period_end = today
            elif period == AnalyticsPeriod.WEEKLY:
                period_start = today - timedelta(days=today.weekday())
                period_end = period_start + timedelta(days=6)
            elif period == AnalyticsPeriod.MONTHLY:
                period_start = today.replace(day=1)
                # Get last day of month
                if today.month == 12:
                    period_end = date(today.year + 1, 1, 1) - timedelta(days=1)
                else:
                    period_end = date(today.year, today.month + 1, 1) - timedelta(days=1)
            else:  # QUARTERLY
                quarter = (today.month - 1) // 3 + 1
                period_start = date(today.year, (quarter - 1) * 3 + 1, 1)
                period_end = date(today.year, quarter * 3 + 1, 1) - timedelta(days=1) if quarter < 4 else date(today.year, 12, 31)
            
            # Get period datetime range for queries
            period_start_dt = datetime.combine(period_start, datetime.min.time())
            period_end_dt = datetime.combine(period_end, datetime.max.time())
            
            # Calculate member metrics
            total_members = await GroupMembership.find({
                "group_id": group_id,
                "status": "active",
                "join_date": {"$lte": period_end_dt}
            }).count()
            
            active_members = await GroupMembership.find({
                "group_id": group_id,
                "status": "active",
                "last_active_at": {"$gte": period_start_dt}
            }).count()
            
            new_members = await GroupMembership.find({
                "group_id": group_id,
                "status": "active",
                "join_date": {"$gte": period_start_dt, "$lte": period_end_dt}
            }).count()
            
            departed_members = await GroupMembership.find({
                "group_id": group_id,
                "status": "removed",
                "updated_at": {"$gte": period_start_dt, "$lte": period_end_dt}
            }).count()
            
            # Calculate retention rate
            member_retention_rate = 0.0
            if total_members > 0:
                member_retention_rate = ((total_members - departed_members) / total_members) * 100
            
            # Calculate activity metrics
            total_posts = await GroupPost.find({
                "group_id": group_id,
                "created_at": {"$gte": period_start_dt, "$lte": period_end_dt}
            }).count()
            
            # Get posts for comment counting
            posts = await GroupPost.find({
                "group_id": group_id,
                "created_at": {"$gte": period_start_dt, "$lte": period_end_dt}
            }).to_list()
            
            total_comments = sum(post.comments_count for post in posts)
            
            # Calculate engagement ratios
            posts_per_active_member = total_posts / active_members if active_members > 0 else 0.0
            comments_per_post = total_comments / total_posts if total_posts > 0 else 0.0
            
            # Calculate interaction rate (members who posted or commented)
            interacting_members = len(set([post.user_id for post in posts]))
            member_interaction_rate = (interacting_members / total_members) * 100 if total_members > 0 else 0.0
            
            # Calculate growth rate
            previous_period_members = total_members - new_members
            growth_rate = (new_members / previous_period_members) * 100 if previous_period_members > 0 else 0.0
            
            # Calculate engagement trend (simplified)
            engagement_trend = 0.0  # Would need historical data for proper calculation
            
            # Calculate satisfaction score (simplified based on engagement)
            satisfaction_score = min(100.0, (member_interaction_rate + (posts_per_active_member * 10)) / 2)
            
            # Get top contributors
            post_counts = defaultdict(int)
            comment_counts = defaultdict(int)
            for post in posts:
                post_counts[post.user_id] += 1
                comment_counts[post.user_id] += post.comments_count
            
            # Combine and rank contributors
            contributor_scores = {}
            for user_id in set(list(post_counts.keys()) + list(comment_counts.keys())):
                score = post_counts[user_id] * 2 + comment_counts[user_id]  # Posts worth more
                contributor_scores[user_id] = score
            
            top_contributor_ids = sorted(contributor_scores.keys(), 
                                       key=lambda x: contributor_scores[x], 
                                       reverse=True)[:10]
            
            # Get user info for top contributors
            top_contributors = []
            if top_contributor_ids:
                users = await User.find({"_id": {"$in": [ObjectId(uid) for uid in top_contributor_ids]}}).to_list()
                user_map = {str(user.id): user for user in users}
                
                for user_id in top_contributor_ids:
                    user = user_map.get(user_id)
                    if user:
                        top_contributors.append({
                            "user_id": user_id,
                            "username": user.username or user.effective_username,
                            "display_name": user.display_name,
                            "posts": post_counts[user_id],
                            "comments": comment_counts[user_id],
                            "score": contributor_scores[user_id]
                        })
            
            # Get popular topics (simplified - based on post tags)
            tag_counts = defaultdict(int)
            for post in posts:
                for tag in post.tags:
                    tag_counts[tag] += 1
            
            popular_topics = [
                {"topic": tag, "count": count, "engagement": count * 1.5}
                for tag, count in sorted(tag_counts.items(), key=lambda x: x[1], reverse=True)[:10]
            ]
            
            # Calculate peak activity hours
            hour_counts = defaultdict(int)
            for post in posts:
                hour_counts[post.created_at.hour] += 1
            
            peak_activity_hours = sorted(hour_counts.keys(), key=lambda x: hour_counts[x], reverse=True)[:5]
            
            # Create analytics record
            analytics = GroupAnalytics(
                group_id=group_id,
                period=period,
                period_start=period_start,
                period_end=period_end,
                total_members=total_members,
                active_members=active_members,
                new_members=new_members,
                departed_members=departed_members,
                member_retention_rate=member_retention_rate,
                total_posts=total_posts,
                total_comments=total_comments,
                total_activities_shared=0,  # Would integrate with activity tracking
                posts_per_active_member=posts_per_active_member,
                comments_per_post=comments_per_post,
                member_interaction_rate=member_interaction_rate,
                growth_rate=growth_rate,
                engagement_trend=engagement_trend,
                satisfaction_score=satisfaction_score,
                top_contributors=top_contributors,
                popular_topics=popular_topics,
                peak_activity_hours=peak_activity_hours
            )
            
            await analytics.save()
            logger.info(f"Generated analytics for group {group_id}, period {period}")
            
            return analytics
            
        except Exception as e:
            logger.error(f"Error generating group analytics: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to generate group analytics"
            )
    
    @staticmethod
    async def generate_member_analytics(group_id: str, user_id: str, period: AnalyticsPeriod = AnalyticsPeriod.MONTHLY) -> MemberAnalytics:
        """Generate analytics for a specific member within a group"""
        try:
            # Determine date range (same logic as group analytics)
            today = date.today()
            if period == AnalyticsPeriod.DAILY:
                period_start = today
                period_end = today
            elif period == AnalyticsPeriod.WEEKLY:
                period_start = today - timedelta(days=today.weekday())
                period_end = period_start + timedelta(days=6)
            elif period == AnalyticsPeriod.MONTHLY:
                period_start = today.replace(day=1)
                if today.month == 12:
                    period_end = date(today.year + 1, 1, 1) - timedelta(days=1)
                else:
                    period_end = date(today.year, today.month + 1, 1) - timedelta(days=1)
            else:  # QUARTERLY
                quarter = (today.month - 1) // 3 + 1
                period_start = date(today.year, (quarter - 1) * 3 + 1, 1)
                period_end = date(today.year, quarter * 3 + 1, 1) - timedelta(days=1) if quarter < 4 else date(today.year, 12, 31)
            
            period_start_dt = datetime.combine(period_start, datetime.min.time())
            period_end_dt = datetime.combine(period_end, datetime.max.time())
            
            # Get member's posts in the period
            posts = await GroupPost.find({
                "group_id": group_id,
                "user_id": user_id,
                "created_at": {"$gte": period_start_dt, "$lte": period_end_dt}
            }).to_list()
            
            posts_created = len(posts)
            comments_made = 0  # Would need to implement comment tracking
            likes_received = sum(post.likes_count for post in posts)
            
            # Calculate engagement score
            engagement_score = posts_created * 2 + comments_made + likes_received * 0.5
            
            # Get membership info for additional metrics
            membership = await GroupMembership.find_one({
                "group_id": group_id,
                "user_id": user_id
            })
            
            # Create member analytics
            member_analytics = MemberAnalytics(
                group_id=group_id,
                user_id=user_id,
                period=period,
                period_start=period_start,
                period_end=period_end,
                posts_created=posts_created,
                comments_made=comments_made,
                engagement_score=engagement_score,
                likes_received=likes_received,
                participation_streak=membership.participation_streak if membership else 0
            )
            
            await member_analytics.save()
            return member_analytics
            
        except Exception as e:
            logger.error(f"Error generating member analytics: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to generate member analytics"
            )
    
    @staticmethod
    async def get_group_insights(current_user: User, group_id: str, limit: int = 10) -> List[GroupInsightData]:
        """Get AI-generated insights for a group"""
        try:
            # Check permissions
            membership = await GroupMembership.find_one({
                "group_id": group_id,
                "user_id": str(current_user.id),
                "role": {"$in": [GroupRole.OWNER, GroupRole.ADMIN]}
            })
            
            if not membership:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Insufficient permissions to view insights"
                )
            
            # Get recent insights
            insights = await GroupInsight.find({
                "group_id": group_id,
                "status": "active"
            }).sort([("priority", -1), ("generated_at", -1)]).limit(limit).to_list()
            
            insight_data_list = []
            for insight in insights:
                insight_data = GroupInsightData(
                    id=str(insight.id),
                    insight_type=insight.insight_type,
                    category=insight.category,
                    priority=insight.priority,
                    title=insight.title,
                    description=insight.description,
                    recommended_actions=insight.recommended_actions,
                    potential_impact=insight.potential_impact,
                    difficulty_level=insight.difficulty_level,
                    confidence_score=insight.confidence_score,
                    status=insight.status,
                    generated_at=insight.generated_at,
                    expires_at=insight.expires_at
                )
                insight_data_list.append(insight_data)
            
            return insight_data_list
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error getting group insights: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to get group insights"
            )
    
    @staticmethod
    async def get_group_leaderboard(current_user: User, group_id: str, metric: str, limit: int = 20) -> List[GroupLeaderboardEntry]:
        """Get group leaderboard based on specified metric"""
        try:
            # Check if user can view leaderboard
            membership = await GroupMembership.find_one({
                "group_id": group_id,
                "user_id": str(current_user.id),
                "status": "active"
            })
            
            if not membership:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Must be a group member to view leaderboard"
                )
            
            # Get group to check if leaderboard is enabled
            group = await PremiumGroup.get(group_id)
            if not group or not group.leaderboard_enabled:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Leaderboard is not enabled for this group"
                )
            
            # Define sorting criteria based on metric
            sort_field = "engagement_score"
            if metric == "posts":
                sort_field = "total_posts"
            elif metric == "activities":
                sort_field = "total_activities_shared"
            elif metric == "streak":
                sort_field = "participation_streak"
            
            # Get top members
            memberships = await GroupMembership.find({
                "group_id": group_id,
                "status": "active"
            }).sort([(sort_field, -1)]).limit(limit).to_list()
            
            # Get user info
            user_ids = [m.user_id for m in memberships]
            users = await User.find({"_id": {"$in": [ObjectId(uid) for uid in user_ids]}}).to_list()
            user_map = {str(user.id): user for user in users}
            
            # Build leaderboard entries
            leaderboard = []
            for i, membership in enumerate(memberships):
                user = user_map.get(membership.user_id)
                if user:
                    score = getattr(membership, sort_field, 0)
                    entry = GroupLeaderboardEntry(
                        user_id=membership.user_id,
                        username=user.username or user.effective_username,
                        display_name=user.display_name,
                        rank=i + 1,
                        score=float(score),
                        metric_name=metric,
                        achievement_badges=membership.group_achievements,
                        trend="stable"  # Would need historical data for trends
                    )
                    leaderboard.append(entry)
            
            return leaderboard
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error getting group leaderboard: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to get group leaderboard"
            )
    
    @staticmethod
    async def generate_ai_insights(group_id: str) -> List[GroupInsight]:
        """Generate AI-powered insights for a group"""
        try:
            # Get recent analytics
            recent_analytics = await GroupAnalytics.find({
                "group_id": group_id
            }).sort([("calculated_at", -1)]).limit(3).to_list()
            
            if not recent_analytics:
                return []
            
            insights = []
            latest_analytics = recent_analytics[0]
            
            # Growth insight
            if latest_analytics.growth_rate > 20:
                insight = GroupInsight(
                    group_id=group_id,
                    insight_type="growth",
                    category="achievement",
                    priority=3,
                    title="Strong Member Growth",
                    description=f"Your group is experiencing excellent growth with a {latest_analytics.growth_rate:.1f}% increase in members this period.",
                    recommended_actions=[
                        {
                            "action": "Create welcome content for new members",
                            "priority": "high",
                            "effort": "medium"
                        }
                    ],
                    potential_impact="Maintaining this growth could establish your group as a leading community",
                    confidence_score=0.9
                )
                insights.append(insight)
            
            # Engagement insight
            if latest_analytics.member_interaction_rate < 30:
                insight = GroupInsight(
                    group_id=group_id,
                    insight_type="engagement",
                    category="opportunity",
                    priority=4,
                    title="Low Member Engagement",
                    description=f"Only {latest_analytics.member_interaction_rate:.1f}% of members are actively participating. This indicates potential engagement issues.",
                    recommended_actions=[
                        {
                            "action": "Start weekly discussion topics",
                            "priority": "high",
                            "effort": "low"
                        },
                        {
                            "action": "Create member spotlight posts",
                            "priority": "medium",
                            "effort": "medium"
                        }
                    ],
                    potential_impact="Improving engagement could double active participation rates",
                    confidence_score=0.8
                )
                insights.append(insight)
            
            # Save insights
            for insight in insights:
                await insight.save()
            
            logger.info(f"Generated {len(insights)} AI insights for group {group_id}")
            return insights
            
        except Exception as e:
            logger.error(f"Error generating AI insights: {e}", exc_info=True)
            return []