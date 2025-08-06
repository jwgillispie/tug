# app/services/analytics_service.py
from datetime import datetime, timedelta, timezone
from typing import List, Dict, Any, Optional
from bson import ObjectId
import logging
from collections import defaultdict, Counter
import statistics

from ..models.user import User
from ..models.activity import Activity
from ..models.value import Value
from ..models.analytics import (
    UserAnalytics, ValueInsights, StreakHistory, ActivityPattern,
    AnalyticsType, MetricType
)

logger = logging.getLogger(__name__)


class AnalyticsService:
    """Service for advanced analytics and insights - Premium Feature"""

    @staticmethod
    async def generate_user_analytics(
        user: User, 
        analytics_type: AnalyticsType = AnalyticsType.MONTHLY,
        days_back: int = 30
    ) -> Dict[str, Any]:
        """Generate comprehensive analytics for a user (Premium Feature)"""
        
        # Calculate date ranges
        end_date = datetime.now(timezone.utc)
        start_date = end_date - timedelta(days=days_back)
        
        # Get user activities in the period
        activities = await Activity.find(
            Activity.user_id == str(user.id),
            Activity.date >= start_date,
            Activity.date <= end_date
        ).sort([("date", -1)]).to_list()
        
        # Get all user values for context
        values = await Value.find(Value.user_id == str(user.id)).to_list()
        value_map = {str(v.id): v for v in values}
        
        # Calculate comprehensive metrics
        analytics = {
            "overview": await AnalyticsService._calculate_overview_metrics(activities, start_date, end_date),
            "value_breakdown": await AnalyticsService._calculate_value_breakdown(activities, value_map),
            "trends": await AnalyticsService._calculate_trends(activities, analytics_type),
            "patterns": await AnalyticsService._calculate_activity_patterns(activities),
            "streaks": await AnalyticsService._calculate_streak_analytics(user, activities, value_map),
            "predictions": await AnalyticsService._generate_predictions(user, activities),
            "generated_at": datetime.now(timezone.utc)
        }
        
        # Store analytics for faster future access
        await AnalyticsService._store_analytics_cache(user, analytics, analytics_type)
        
        return analytics

    @staticmethod
    async def _calculate_overview_metrics(
        activities: List[Activity], 
        start_date: datetime, 
        end_date: datetime
    ) -> Dict[str, Any]:
        """Calculate high-level overview metrics"""
        
        total_activities = len(activities)
        total_duration = sum(a.duration for a in activities)
        
        # Calculate daily averages
        total_days = (end_date - start_date).days + 1
        avg_daily_activities = round(total_activities / total_days, 2) if total_days > 0 else 0
        avg_daily_duration = round(total_duration / total_days, 2) if total_days > 0 else 0
        
        # Calculate active days
        active_days = len(set(a.date.date() for a in activities))
        consistency_percentage = round((active_days / total_days) * 100, 1) if total_days > 0 else 0
        
        # Calculate productivity score (activities per hour of total duration)
        productivity_score = round(total_activities / (total_duration / 60), 2) if total_duration > 0 else 0
        
        return {
            "total_activities": total_activities,
            "total_duration_minutes": total_duration,
            "total_duration_hours": round(total_duration / 60, 2),
            "avg_daily_activities": avg_daily_activities,
            "avg_daily_duration_minutes": avg_daily_duration,
            "active_days": active_days,
            "total_days": total_days,
            "consistency_percentage": consistency_percentage,
            "productivity_score": productivity_score,
            "avg_session_duration": round(total_duration / total_activities, 2) if total_activities > 0 else 0
        }

    @staticmethod
    async def _calculate_value_breakdown(
        activities: List[Activity], 
        value_map: Dict[str, Value]
    ) -> List[Dict[str, Any]]:
        """Break down activities by value with detailed metrics"""
        
        value_stats = defaultdict(lambda: {
            "activity_count": 0,
            "total_duration": 0,
            "sessions": [],
            "days_active": set()
        })
        
        for activity in activities:
            for value_id in activity.effective_value_ids:
                if value_id in value_map:
                    value_stats[value_id]["activity_count"] += 1
                    value_stats[value_id]["total_duration"] += activity.duration
                    value_stats[value_id]["sessions"].append(activity.duration)
                    value_stats[value_id]["days_active"].add(activity.date.date())
        
        breakdown = []
        for value_id, stats in value_stats.items():
            if value_id in value_map:
                value = value_map[value_id]
                sessions = stats["sessions"]
                
                breakdown.append({
                    "value_id": value_id,
                    "value_name": value.name,
                    "value_color": getattr(value, 'color', '#3B82F6'),
                    "activity_count": stats["activity_count"],
                    "total_duration": stats["total_duration"],
                    "avg_session_duration": round(sum(sessions) / len(sessions), 2) if sessions else 0,
                    "min_session_duration": min(sessions) if sessions else 0,
                    "max_session_duration": max(sessions) if sessions else 0,
                    "days_active": len(stats["days_active"]),
                    "consistency_score": round((len(stats["days_active"]) / 30) * 100, 1)  # Assuming 30-day period
                })
        
        return sorted(breakdown, key=lambda x: x["total_duration"], reverse=True)

    @staticmethod
    async def _calculate_trends(
        activities: List[Activity], 
        analytics_type: AnalyticsType
    ) -> List[Dict[str, Any]]:
        """Calculate trend data for charts"""
        
        # Group activities by time period
        if analytics_type == AnalyticsType.DAILY:
            time_groups = defaultdict(lambda: {"count": 0, "duration": 0})
            for activity in activities:
                day_key = activity.date.strftime("%Y-%m-%d")
                time_groups[day_key]["count"] += 1
                time_groups[day_key]["duration"] += activity.duration
        
        elif analytics_type == AnalyticsType.WEEKLY:
            time_groups = defaultdict(lambda: {"count": 0, "duration": 0})
            for activity in activities:
                week_start = activity.date - timedelta(days=activity.date.weekday())
                week_key = week_start.strftime("%Y-W%U")
                time_groups[week_key]["count"] += 1
                time_groups[week_key]["duration"] += activity.duration
        
        else:  # MONTHLY
            time_groups = defaultdict(lambda: {"count": 0, "duration": 0})
            for activity in activities:
                month_key = activity.date.strftime("%Y-%m")
                time_groups[month_key]["count"] += 1
                time_groups[month_key]["duration"] += activity.duration
        
        # Convert to trend format
        trends = [
            {
                "period": period,
                "activity_count": data["count"],
                "total_duration": data["duration"],
                "avg_duration": round(data["duration"] / data["count"], 2) if data["count"] > 0 else 0
            }
            for period, data in sorted(time_groups.items())
        ]
        
        return trends

    @staticmethod
    async def _calculate_activity_patterns(activities: List[Activity]) -> Dict[str, Any]:
        """Analyze user activity patterns for optimization suggestions"""
        
        if not activities:
            return {}
        
        # Day of week analysis (0=Sunday, 6=Saturday)
        day_counts = Counter(activity.date.weekday() for activity in activities)
        day_names = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        
        # Hour of day analysis
        hour_counts = Counter(activity.date.hour for activity in activities)
        
        # Duration patterns
        durations = [activity.duration for activity in activities]
        
        return {
            "best_days_of_week": [
                {"day": day_names[day], "count": count, "percentage": round((count / len(activities)) * 100, 1)}
                for day, count in day_counts.most_common(3)
            ],
            "best_hours": [
                {"hour": hour, "count": count, "time_label": f"{hour:02d}:00"}
                for hour, count in hour_counts.most_common(3)
            ],
            "duration_stats": {
                "average": round(statistics.mean(durations), 2),
                "median": round(statistics.median(durations), 2),
                "mode": statistics.mode(durations) if durations else 0,
                "std_dev": round(statistics.stdev(durations), 2) if len(durations) > 1 else 0
            }
        }

    @staticmethod
    async def _calculate_streak_analytics(
        user: User, 
        activities: List[Activity], 
        value_map: Dict[str, Value]
    ) -> Dict[str, Any]:
        """Calculate detailed streak information for all values"""
        
        streak_data = {}
        
        for value_id, value in value_map.items():
            value_activities = [a for a in activities if value_id in a.effective_value_ids]
            
            if not value_activities:
                continue
            
            # Sort activities by date
            value_activities.sort(key=lambda x: x.date)
            
            # Calculate current streak
            current_streak = await AnalyticsService._calculate_current_streak(value_activities)
            
            # Calculate all streaks
            all_streaks = await AnalyticsService._calculate_all_streaks(value_activities)
            
            streak_data[value_id] = {
                "value_name": value.name,
                "current_streak": current_streak,
                "longest_streak": max(all_streaks) if all_streaks else 0,
                "total_streaks": len(all_streaks),
                "avg_streak_length": round(sum(all_streaks) / len(all_streaks), 2) if all_streaks else 0,
                "streak_distribution": Counter(all_streaks)
            }
        
        return streak_data

    @staticmethod
    async def _calculate_current_streak(activities: List[Activity]) -> int:
        """Calculate current active streak for a value"""
        if not activities:
            return 0
        
        # Sort by date, most recent first
        activities.sort(key=lambda x: x.date, reverse=True)
        
        today = datetime.now(timezone.utc).date()
        streak = 0
        current_date = today
        
        # Check if we have activity today or yesterday (to account for timezone/timing)
        activity_dates = set(a.date.date() for a in activities)
        
        # Start streak calculation
        while current_date in activity_dates:
            streak += 1
            current_date -= timedelta(days=1)
        
        return streak

    @staticmethod
    async def _calculate_all_streaks(activities: List[Activity]) -> List[int]:
        """Calculate all historical streak lengths"""
        if not activities:
            return []
        
        activity_dates = sorted(set(a.date.date() for a in activities))
        streaks = []
        current_streak = 1
        
        for i in range(1, len(activity_dates)):
            if (activity_dates[i] - activity_dates[i-1]).days == 1:
                current_streak += 1
            else:
                streaks.append(current_streak)
                current_streak = 1
        
        streaks.append(current_streak)  # Add the last streak
        return streaks

    @staticmethod
    async def _generate_predictions(user: User, activities: List[Activity]) -> Dict[str, Any]:
        """Generate AI-powered predictions and recommendations"""
        
        if len(activities) < 7:  # Need at least a week of data
            return {"insufficient_data": True}
        
        # Analyze recent trends
        recent_activities = activities[-14:]  # Last 2 weeks
        older_activities = activities[:-14] if len(activities) > 14 else []
        
        recent_avg = len(recent_activities) / 14
        older_avg = len(older_activities) / 14 if older_activities else recent_avg
        
        trend_direction = "increasing" if recent_avg > older_avg else "decreasing" if recent_avg < older_avg else "stable"
        trend_percentage = round(((recent_avg - older_avg) / older_avg) * 100, 1) if older_avg > 0 else 0
        
        # Predict optimal activity times based on historical data
        hour_success = Counter(a.date.hour for a in activities)
        best_hours = [hour for hour, _ in hour_success.most_common(3)]
        
        return {
            "trend_direction": trend_direction,
            "trend_percentage": trend_percentage,
            "recommended_activity_hours": best_hours,
            "weekly_goal_probability": min(95, max(20, recent_avg * 7 + trend_percentage)),
            "consistency_improvement_tips": [
                "Try scheduling activities during your peak hours",
                "Set up reminders for your most successful days",
                "Start with shorter sessions to build consistency"
            ]
        }

    @staticmethod
    async def _store_analytics_cache(
        user: User, 
        analytics: Dict[str, Any], 
        analytics_type: AnalyticsType
    ) -> None:
        """Store analytics in cache for faster future access"""
        
        # Store key metrics as UserAnalytics documents
        overview = analytics.get("overview", {})
        
        metrics_to_store = [
            (MetricType.ACTIVITY_COUNT, overview.get("total_activities", 0)),
            (MetricType.DURATION_TOTAL, overview.get("total_duration_minutes", 0)),
            (MetricType.CONSISTENCY_SCORE, overview.get("consistency_percentage", 0))
        ]
        
        for metric_type, value in metrics_to_store:
            analytics_doc = UserAnalytics(
                user_id=str(user.id),
                analytics_type=analytics_type,
                metric_type=metric_type,
                date_range_start=datetime.now(timezone.utc) - timedelta(days=30),
                date_range_end=datetime.now(timezone.utc),
                value=float(value),
                metadata={"generated_by": "analytics_service"}
            )
            await analytics_doc.save()

    @staticmethod
    async def get_value_insights(user: User, value_id: str, days_back: int = 90) -> Dict[str, Any]:
        """Get detailed insights for a specific value (Premium Feature)"""
        
        # Verify value belongs to user
        value = await Value.find_one(Value.id == ObjectId(value_id), Value.user_id == str(user.id))
        if not value:
            return {"error": "Value not found"}
        
        # Get activities for this value
        end_date = datetime.now(timezone.utc)
        start_date = end_date - timedelta(days=days_back)
        
        activities = await Activity.find(
            Activity.user_id == str(user.id),
            Activity.date >= start_date,
            Activity.date <= end_date
        ).to_list()
        
        # Filter activities for this specific value
        value_activities = [a for a in activities if value_id in a.effective_value_ids]
        
        if not value_activities:
            return {"error": "No activities found for this value"}
        
        # Generate comprehensive insights
        insights = {
            "value_name": value.name,
            "total_activities": len(value_activities),
            "date_range": {"start": start_date, "end": end_date},
            "patterns": await AnalyticsService._calculate_activity_patterns(value_activities),
            "streaks": await AnalyticsService._calculate_current_streak(value_activities),
            "optimization_suggestions": await AnalyticsService._generate_optimization_suggestions(value_activities),
            "progress_forecast": await AnalyticsService._forecast_progress(value_activities)
        }
        
        return insights

    @staticmethod
    async def _generate_optimization_suggestions(activities: List[Activity]) -> List[str]:
        """Generate personalized optimization suggestions"""
        suggestions = []
        
        if not activities:
            return suggestions
        
        # Analyze patterns and generate suggestions
        durations = [a.duration for a in activities]
        avg_duration = sum(durations) / len(durations)
        
        if avg_duration < 15:
            suggestions.append("Consider longer sessions (15-30 minutes) for better habit formation")
        elif avg_duration > 120:
            suggestions.append("Try shorter, more frequent sessions to maintain consistency")
        
        # Day pattern analysis
        day_counts = Counter(a.date.weekday() for a in activities)
        if len(day_counts) < 3:
            suggestions.append("Try spreading activities across more days of the week")
        
        # Time consistency
        hour_counts = Counter(a.date.hour for a in activities)
        if len(hour_counts) > 12:  # Very scattered times
            suggestions.append("Try to establish a consistent time for this activity")
        
        return suggestions

    @staticmethod
    async def _forecast_progress(activities: List[Activity]) -> Dict[str, Any]:
        """Forecast future progress based on current trends"""
        
        if len(activities) < 14:
            return {"insufficient_data": True}
        
        # Simple linear trend analysis
        recent_week = activities[-7:]
        previous_week = activities[-14:-7]
        
        recent_count = len(recent_week)
        previous_count = len(previous_week)
        
        weekly_change = recent_count - previous_count
        projected_next_week = max(0, recent_count + weekly_change)
        
        return {
            "current_weekly_average": recent_count,
            "trend": "improving" if weekly_change > 0 else "declining" if weekly_change < 0 else "stable",
            "projected_next_week": projected_next_week,
            "confidence": min(90, max(30, (len(activities) / 30) * 100))  # Confidence based on data amount
        }