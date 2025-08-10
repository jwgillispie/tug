# app/services/analytics_service.py
from datetime import datetime, timedelta, timezone
from typing import List, Dict, Any, Optional
from bson import ObjectId
import logging
from collections import defaultdict, Counter
import statistics
import csv
import io
import base64
from typing import TextIO
import asyncio
import tempfile
import os

# PDF generation libraries
from reportlab.lib.pagesizes import letter, A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.lib.colors import HexColor, black, white
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak, Image
from reportlab.platypus.flowables import KeepTogether
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_RIGHT
from reportlab.graphics.shapes import Drawing, Rect, String, Line
from reportlab.graphics.charts.lineplots import LinePlot
from reportlab.graphics.charts.piecharts import Pie
from reportlab.graphics.charts.barcharts import VerticalBarChart
from reportlab.graphics.widgetbase import Widget

# Chart generation
import matplotlib
matplotlib.use('Agg')  # Use non-interactive backend
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
from matplotlib.backends.backend_pdf import PdfPages
import pandas as pd
from PIL import Image as PILImage

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
        """Generate AI-powered predictions and recommendations using ML models with caching"""
        
        try:
            # Import services
            from .ml_prediction_service import MLPredictionService
            from .prediction_cache_service import PredictionCacheService
            
            # Initialize cache service
            cache_service = PredictionCacheService()
            
            # Try to get cached predictions first
            cached_predictions = await cache_service.get_cached_predictions(user, "analytics")
            
            if cached_predictions and cached_predictions.get("predictions"):
                logger.info(f"Using cached predictions for user {user.id}")
                return cached_predictions["predictions"]
            
            logger.info(f"Generating fresh predictions for user {user.id}")
            
            # Get user values for context
            values = await Value.find(Value.user_id == str(user.id)).to_list()
            
            # Use ML prediction service for comprehensive predictions
            ml_predictions = await MLPredictionService.generate_comprehensive_predictions(
                user, activities, values
            )
            
            # Transform ML predictions to match expected analytics format
            analytics_predictions = {
                "ml_powered": True,
                "confidence_level": ml_predictions.get("confidence_metrics", {}).get("overall_confidence", 50.0),
                
                # Habit formation insights
                "habit_formation": ml_predictions.get("habit_formation", {}),
                
                # Optimal timing recommendations  
                "optimal_timing": ml_predictions.get("optimal_timing", {}),
                "recommended_activity_hours": [
                    h["hour"] for h in ml_predictions.get("optimal_timing", {}).get("optimal_hours", [])[:3]
                ],
                
                # Streak and risk assessment
                "streak_risk": ml_predictions.get("streak_risk", {}),
                
                # Trend analysis (enhanced with ML)
                "trend_direction": ml_predictions.get("activity_forecasting", {}).get("trend_direction", "stable"),
                "trend_percentage": ml_predictions.get("activity_forecasting", {}).get("trend_percentage", 0),
                "weekly_goal_probability": ml_predictions.get("habit_formation", {}).get("formation_probability", 50.0),
                
                # Goal recommendations
                "goal_recommendations": ml_predictions.get("goal_recommendations", {}),
                
                # Motivation and timing
                "motivation_timing": ml_predictions.get("motivation_timing", {}),
                
                # User insights
                "user_segment": ml_predictions.get("user_segmentation", {}).get("user_segment", "Getting Started"),
                "personalized_strategies": ml_predictions.get("user_segmentation", {}).get("personalized_strategies", []),
                
                # Activity forecasting
                "activity_forecast": ml_predictions.get("activity_forecasting", {}),
                
                # Enhanced consistency tips using ML insights
                "consistency_improvement_tips": AnalyticsService._generate_ml_enhanced_tips(ml_predictions),
                
                # Additional ML insights
                "success_factors": ml_predictions.get("habit_formation", {}).get("key_factors", []),
                "risk_factors": ml_predictions.get("streak_risk", {}).get("recommendations", []),
                
                # Model metadata
                "prediction_metadata": {
                    "data_points": len(activities),
                    "models_used": list(ml_predictions.keys()),
                    "generated_at": datetime.now(timezone.utc),
                    "confidence_breakdown": ml_predictions.get("confidence_metrics", {}).get("factors", {})
                }
            }
            
            # Cache the predictions for future requests
            try:
                await cache_service.store_predictions(user, analytics_predictions, "analytics")
                logger.info(f"Cached fresh predictions for user {user.id}")
            except Exception as cache_error:
                logger.warning(f"Failed to cache predictions for user {user.id}: {cache_error}")
            
            return analytics_predictions
            
        except Exception as e:
            logger.error(f"ML prediction failed, falling back to heuristic method: {e}")
            # Fallback to original heuristic method
            return await AnalyticsService._generate_heuristic_predictions(user, activities)

    @staticmethod
    async def _generate_heuristic_predictions(user: User, activities: List[Activity]) -> Dict[str, Any]:
        """Generate predictions using original heuristic methods (fallback)"""
        
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
            "ml_powered": False,
            "confidence_level": 60.0,
            "trend_direction": trend_direction,
            "trend_percentage": trend_percentage,
            "recommended_activity_hours": best_hours,
            "weekly_goal_probability": min(95, max(20, recent_avg * 7 + trend_percentage)),
            "consistency_improvement_tips": [
                "Try scheduling activities during your peak hours",
                "Set up reminders for your most successful days",
                "Start with shorter sessions to build consistency"
            ],
            "prediction_metadata": {
                "method": "heuristic_fallback",
                "data_points": len(activities),
                "generated_at": datetime.now(timezone.utc)
            }
        }

    @staticmethod
    def _generate_ml_enhanced_tips(ml_predictions: Dict[str, Any]) -> List[str]:
        """Generate enhanced tips based on ML predictions"""
        
        tips = []
        
        # From habit formation predictions
        habit_recs = ml_predictions.get("habit_formation", {}).get("recommendations", [])
        tips.extend(habit_recs[:2])
        
        # From streak risk assessment
        risk_recs = ml_predictions.get("streak_risk", {}).get("recommendations", [])
        tips.extend([r for r in risk_recs if "⚠️" not in r and "🚀" not in r][:1])  # Clean up emojis for consistency
        
        # From optimal timing
        timing_recs = ml_predictions.get("optimal_timing", {}).get("recommendations", [])
        tips.extend(timing_recs[:1])
        
        # From user segmentation
        segment_strategies = ml_predictions.get("user_segmentation", {}).get("personalized_strategies", [])
        tips.extend(segment_strategies[:1])
        
        # Remove duplicates and limit
        unique_tips = []
        seen = set()
        for tip in tips:
            clean_tip = tip.replace("⚠️", "").replace("🚀", "").replace("🎯", "").replace("✅", "").replace("💪", "").replace("🏆", "").replace("⏰", "").replace("📈", "").strip()
            if clean_tip not in seen and clean_tip:
                unique_tips.append(clean_tip)
                seen.add(clean_tip)
        
        # Add default tips if not enough
        default_tips = [
            "Focus on consistency over perfection",
            "Start with small, achievable goals",
            "Track your progress to stay motivated",
            "Celebrate small wins along the way"
        ]
        
        for default_tip in default_tips:
            if len(unique_tips) >= 5:
                break
            if default_tip not in seen:
                unique_tips.append(default_tip)
                seen.add(default_tip)
        
        return unique_tips[:5]

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

    @staticmethod
    async def export_to_csv(
        analytics: Dict[str, Any], 
        user: User, 
        requested_types: List[str], 
        days_back: int,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None
    ) -> Dict[str, str]:
        """Export analytics data to CSV format"""
        
        csv_files = {}
        
        try:
            # Export activities overview
            if 'activities' in requested_types:
                overview_csv = await AnalyticsService._create_overview_csv(analytics.get('overview', {}))
                csv_files['overview'] = overview_csv
            
            # Export value breakdown
            if 'breakdown' in requested_types:
                breakdown_csv = await AnalyticsService._create_breakdown_csv(analytics.get('value_breakdown', []))
                csv_files['value_breakdown'] = breakdown_csv
            
            # Export trends
            if 'trends' in requested_types:
                trends_csv = await AnalyticsService._create_trends_csv(analytics.get('trends', []))
                csv_files['trends'] = trends_csv
            
            # Export streaks
            if 'streaks' in requested_types:
                streaks_csv = await AnalyticsService._create_streaks_csv(analytics.get('streaks', {}))
                csv_files['streaks'] = streaks_csv
            
            # Export insights/patterns
            if 'insights' in requested_types:
                patterns_csv = await AnalyticsService._create_patterns_csv(analytics.get('patterns', {}))
                csv_files['patterns'] = patterns_csv
                
                predictions_csv = await AnalyticsService._create_predictions_csv(analytics.get('predictions', {}))
                csv_files['predictions'] = predictions_csv
            
            # Create metadata file
            metadata_csv = await AnalyticsService._create_metadata_csv(user, days_back, requested_types, start_date, end_date)
            csv_files['metadata'] = metadata_csv
            
            logger.info(f"Generated {len(csv_files)} CSV files for user {user.id}")
            return csv_files
            
        except Exception as e:
            logger.error(f"Error creating CSV export: {e}", exc_info=True)
            raise

    @staticmethod
    async def _create_overview_csv(overview: Dict[str, Any]) -> str:
        """Create CSV for overview metrics"""
        output = io.StringIO()
        writer = csv.writer(output)
        
        writer.writerow(['Metric', 'Value', 'Unit'])
        writer.writerow(['Total Activities', overview.get('total_activities', 0), 'count'])
        writer.writerow(['Total Duration', overview.get('total_duration_minutes', 0), 'minutes'])
        writer.writerow(['Total Duration', overview.get('total_duration_hours', 0), 'hours'])
        writer.writerow(['Average Daily Activities', overview.get('avg_daily_activities', 0), 'count/day'])
        writer.writerow(['Average Daily Duration', overview.get('avg_daily_duration_minutes', 0), 'minutes/day'])
        writer.writerow(['Active Days', overview.get('active_days', 0), 'days'])
        writer.writerow(['Total Days Analyzed', overview.get('total_days', 0), 'days'])
        writer.writerow(['Consistency Percentage', overview.get('consistency_percentage', 0), '%'])
        writer.writerow(['Productivity Score', overview.get('productivity_score', 0), 'score'])
        writer.writerow(['Average Session Duration', overview.get('avg_session_duration', 0), 'minutes'])
        
        return output.getvalue()

    @staticmethod
    async def _create_breakdown_csv(breakdown: List[Dict[str, Any]]) -> str:
        """Create CSV for value breakdown"""
        output = io.StringIO()
        writer = csv.writer(output)
        
        writer.writerow([
            'Value ID', 'Value Name', 'Color', 'Activity Count', 'Total Duration (min)',
            'Avg Session Duration (min)', 'Min Session Duration (min)', 'Max Session Duration (min)',
            'Days Active', 'Consistency Score (%)'
        ])
        
        for item in breakdown:
            writer.writerow([
                item.get('value_id', ''),
                item.get('value_name', ''),
                item.get('value_color', ''),
                item.get('activity_count', 0),
                item.get('total_duration', 0),
                item.get('avg_session_duration', 0),
                item.get('min_session_duration', 0),
                item.get('max_session_duration', 0),
                item.get('days_active', 0),
                item.get('consistency_score', 0)
            ])
        
        return output.getvalue()

    @staticmethod
    async def _create_trends_csv(trends: List[Dict[str, Any]]) -> str:
        """Create CSV for trends data"""
        output = io.StringIO()
        writer = csv.writer(output)
        
        writer.writerow(['Period', 'Activity Count', 'Total Duration (min)', 'Average Duration (min)'])
        
        for trend in trends:
            writer.writerow([
                trend.get('period', ''),
                trend.get('activity_count', 0),
                trend.get('total_duration', 0),
                trend.get('avg_duration', 0)
            ])
        
        return output.getvalue()

    @staticmethod
    async def _create_streaks_csv(streaks: Dict[str, Any]) -> str:
        """Create CSV for streak analytics"""
        output = io.StringIO()
        writer = csv.writer(output)
        
        writer.writerow([
            'Value ID', 'Value Name', 'Current Streak', 'Longest Streak',
            'Total Streaks', 'Average Streak Length'
        ])
        
        for value_id, streak_data in streaks.items():
            writer.writerow([
                value_id,
                streak_data.get('value_name', ''),
                streak_data.get('current_streak', 0),
                streak_data.get('longest_streak', 0),
                streak_data.get('total_streaks', 0),
                streak_data.get('avg_streak_length', 0)
            ])
        
        return output.getvalue()

    @staticmethod
    async def _create_patterns_csv(patterns: Dict[str, Any]) -> str:
        """Create CSV for activity patterns"""
        output = io.StringIO()
        writer = csv.writer(output)
        
        # Best days section
        writer.writerow(['Activity Patterns - Best Days of Week'])
        writer.writerow(['Day', 'Count', 'Percentage'])
        
        for day_pattern in patterns.get('best_days_of_week', []):
            writer.writerow([
                day_pattern.get('day', ''),
                day_pattern.get('count', 0),
                day_pattern.get('percentage', 0)
            ])
        
        writer.writerow([])  # Empty row
        
        # Best hours section
        writer.writerow(['Activity Patterns - Best Hours'])
        writer.writerow(['Hour', 'Time Label', 'Count'])
        
        for hour_pattern in patterns.get('best_hours', []):
            writer.writerow([
                hour_pattern.get('hour', 0),
                hour_pattern.get('time_label', ''),
                hour_pattern.get('count', 0)
            ])
        
        writer.writerow([])  # Empty row
        
        # Duration statistics
        writer.writerow(['Duration Statistics'])
        writer.writerow(['Statistic', 'Value (minutes)'])
        duration_stats = patterns.get('duration_stats', {})
        writer.writerow(['Average', duration_stats.get('average', 0)])
        writer.writerow(['Median', duration_stats.get('median', 0)])
        writer.writerow(['Mode', duration_stats.get('mode', 0)])
        writer.writerow(['Standard Deviation', duration_stats.get('std_dev', 0)])
        
        return output.getvalue()

    @staticmethod
    async def _create_predictions_csv(predictions: Dict[str, Any]) -> str:
        """Create CSV for predictions and recommendations"""
        output = io.StringIO()
        writer = csv.writer(output)
        
        if predictions.get('insufficient_data'):
            writer.writerow(['Insufficient data for predictions'])
            return output.getvalue()
        
        writer.writerow(['AI Predictions and Recommendations'])
        writer.writerow(['Metric', 'Value'])
        writer.writerow(['Trend Direction', predictions.get('trend_direction', 'stable')])
        writer.writerow(['Trend Percentage', predictions.get('trend_percentage', 0)])
        writer.writerow(['Weekly Goal Probability (%)', predictions.get('weekly_goal_probability', 0)])
        
        writer.writerow([])
        writer.writerow(['Recommended Activity Hours'])
        for hour in predictions.get('recommended_activity_hours', []):
            writer.writerow([f'{hour:02d}:00'])
        
        writer.writerow([])
        writer.writerow(['Improvement Tips'])
        for tip in predictions.get('consistency_improvement_tips', []):
            writer.writerow([tip])
        
        return output.getvalue()

    @staticmethod
    async def _create_metadata_csv(user: User, days_back: int, requested_types: List[str], start_date: Optional[datetime] = None, end_date: Optional[datetime] = None) -> str:
        """Create CSV with export metadata"""
        output = io.StringIO()
        writer = csv.writer(output)
        
        writer.writerow(['Export Metadata'])
        writer.writerow(['Field', 'Value'])
        writer.writerow(['User ID', str(user.id)])
        writer.writerow(['Export Date', datetime.now(timezone.utc).isoformat()])
        writer.writerow(['Days Analyzed', days_back])
        writer.writerow(['Data Types', ', '.join(requested_types)])
        writer.writerow(['Export Format', 'CSV'])
        if start_date:
            writer.writerow(['Start Date', start_date.isoformat()])
        if end_date:
            writer.writerow(['End Date', end_date.isoformat()])
        
        return output.getvalue()

    @staticmethod
    async def export_to_pdf(
        analytics: Dict[str, Any], 
        user: User, 
        requested_types: List[str], 
        days_back: int,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
        include_charts: bool = True
    ) -> Dict[str, Any]:
        """Export analytics data to PDF format with charts and visualizations"""
        
        try:
            logger.info(f"Creating PDF report for user {user.id}")
            
            # Create PDF content
            pdf_buffer, chart_paths = await AnalyticsService._create_comprehensive_pdf_report(
                analytics=analytics, 
                user=user, 
                requested_types=requested_types, 
                days_back=days_back,
                start_date=start_date,
                end_date=end_date,
                include_charts=include_charts
            )
            
            # Convert to base64
            pdf_content = base64.b64encode(pdf_buffer.getvalue()).decode('utf-8')
            
            # Clean up temporary chart files
            for chart_path in chart_paths:
                try:
                    if os.path.exists(chart_path):
                        os.remove(chart_path)
                except Exception:
                    pass  # Ignore cleanup errors
            
            return {
                "pdf_base64": pdf_content,
                "filename": f"tug_analytics_{user.id}_{datetime.now(timezone.utc).strftime('%Y%m%d_%H%M%S')}.pdf",
                "content_type": "application/pdf",
                "size_bytes": len(pdf_buffer.getvalue())
            }
            
        except Exception as e:
            logger.error(f"Error creating PDF export: {e}", exc_info=True)
            raise

    @staticmethod
    async def _create_comprehensive_pdf_report(
        analytics: Dict[str, Any], 
        user: User, 
        requested_types: List[str], 
        days_back: int,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
        include_charts: bool = True
    ) -> tuple[io.BytesIO, List[str]]:
        """Create a comprehensive PDF report with charts and visualizations"""
        
        # Create PDF buffer
        buffer = io.BytesIO()
        chart_paths = []
        
        # Create PDF document
        doc = SimpleDocTemplate(
            buffer,
            pagesize=A4,
            rightMargin=72,
            leftMargin=72,
            topMargin=72,
            bottomMargin=18
        )
        
        # Get styles
        styles = getSampleStyleSheet()
        title_style = ParagraphStyle(
            'CustomTitle',
            parent=styles['Heading1'],
            fontSize=24,
            spaceAfter=30,
            alignment=TA_CENTER,
            textColor=HexColor('#6366F1')
        )
        
        heading_style = ParagraphStyle(
            'CustomHeading',
            parent=styles['Heading2'],
            fontSize=16,
            spaceAfter=12,
            spaceBefore=20,
            textColor=HexColor('#374151')
        )
        
        # Story for PDF content
        story = []
        
        # Title page
        story.append(Paragraph("TUG ANALYTICS REPORT", title_style))
        story.append(Spacer(1, 20))
        
        # User info and metadata
        metadata_data = [
            ['Report For:', user.email or f'User {user.id}'],
            ['Generated:', datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M:%S UTC')],
            ['Period:', f'{days_back} days'],
            ['Data Types:', ', '.join(requested_types)]
        ]
        
        if start_date and end_date:
            metadata_data.extend([
                ['Start Date:', start_date.strftime('%Y-%m-%d')],
                ['End Date:', end_date.strftime('%Y-%m-%d')]
            ])
        
        metadata_table = Table(metadata_data, colWidths=[2*inch, 4*inch])
        metadata_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, -1), HexColor('#F9FAFB')),
            ('TEXTCOLOR', (0, 0), (0, -1), HexColor('#374151')),
            ('TEXTCOLOR', (1, 0), (1, -1), HexColor('#111827')),
            ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
            ('FONTNAME', (0, 0), (0, -1), 'Helvetica-Bold'),
            ('FONTNAME', (1, 0), (1, -1), 'Helvetica'),
            ('FONTSIZE', (0, 0), (-1, -1), 10),
            ('GRID', (0, 0), (-1, -1), 1, HexColor('#E5E7EB')),
            ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
            ('LEFTPADDING', (0, 0), (-1, -1), 12),
            ('RIGHTPADDING', (0, 0), (-1, -1), 12),
            ('TOPPADDING', (0, 0), (-1, -1), 8),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 8),
        ]))
        
        story.append(metadata_table)
        story.append(PageBreak())
        
        # Overview section
        if 'activities' in requested_types:
            overview = analytics.get('overview', {})
            story.append(Paragraph("OVERVIEW", heading_style))
            
            overview_data = [
                ['Total Activities', str(overview.get('total_activities', 0))],
                ['Total Duration', f"{overview.get('total_duration_hours', 0):.1f} hours"],
                ['Active Days', f"{overview.get('active_days', 0)} / {overview.get('total_days', 0)}"],
                ['Consistency', f"{overview.get('consistency_percentage', 0):.1f}%"],
                ['Productivity Score', f"{overview.get('productivity_score', 0):.2f}"],
                ['Avg Daily Activities', f"{overview.get('avg_daily_activities', 0):.1f}"],
                ['Avg Session Duration', f"{overview.get('avg_session_duration', 0):.1f} minutes"]
            ]
            
            overview_table = Table(overview_data, colWidths=[3*inch, 2*inch])
            overview_table.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (-1, 0), HexColor('#6366F1')),
                ('TEXTCOLOR', (0, 0), (-1, 0), white),
                ('BACKGROUND', (0, 1), (-1, -1), HexColor('#F8FAFC')),
                ('TEXTCOLOR', (0, 1), (-1, -1), HexColor('#374151')),
                ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
                ('ALIGN', (1, 0), (1, -1), 'RIGHT'),
                ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
                ('FONTNAME', (0, 1), (-1, -1), 'Helvetica'),
                ('FONTSIZE', (0, 0), (-1, -1), 11),
                ('GRID', (0, 0), (-1, -1), 1, HexColor('#E5E7EB')),
                ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
                ('LEFTPADDING', (0, 0), (-1, -1), 12),
                ('RIGHTPADDING', (0, 0), (-1, -1), 12),
                ('TOPPADDING', (0, 0), (-1, -1), 10),
                ('BOTTOMPADDING', (0, 0), (-1, -1), 10),
            ]))
            
            story.append(overview_table)
            story.append(Spacer(1, 20))
        
        # Value breakdown section
        if 'breakdown' in requested_types:
            story.append(Paragraph("VALUE BREAKDOWN", heading_style))
            
            breakdown = analytics.get('value_breakdown', [])
            if breakdown:
                breakdown_data = [['Value', 'Activities', 'Duration (min)', 'Avg Session', 'Consistency']]
                
                for item in breakdown[:10]:  # Limit to top 10 values
                    breakdown_data.append([
                        item.get('value_name', 'Unknown')[:20],  # Truncate long names
                        str(item.get('activity_count', 0)),
                        str(item.get('total_duration', 0)),
                        f"{item.get('avg_session_duration', 0):.1f}",
                        f"{item.get('consistency_score', 0):.1f}%"
                    ])
                
                breakdown_table = Table(breakdown_data, colWidths=[2*inch, 1*inch, 1.2*inch, 1*inch, 1*inch])
                breakdown_table.setStyle(TableStyle([
                    ('BACKGROUND', (0, 0), (-1, 0), HexColor('#10B981')),
                    ('TEXTCOLOR', (0, 0), (-1, 0), white),
                    ('BACKGROUND', (0, 1), (-1, -1), HexColor('#F0FDF4')),
                    ('TEXTCOLOR', (0, 1), (-1, -1), HexColor('#374151')),
                    ('ALIGN', (0, 0), (0, -1), 'LEFT'),
                    ('ALIGN', (1, 0), (-1, -1), 'CENTER'),
                    ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
                    ('FONTNAME', (0, 1), (-1, -1), 'Helvetica'),
                    ('FONTSIZE', (0, 0), (-1, -1), 9),
                    ('GRID', (0, 0), (-1, -1), 1, HexColor('#E5E7EB')),
                    ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
                    ('LEFTPADDING', (0, 0), (-1, -1), 8),
                    ('RIGHTPADDING', (0, 0), (-1, -1), 8),
                    ('TOPPADDING', (0, 0), (-1, -1), 6),
                    ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
                ]))
                
                story.append(breakdown_table)
                story.append(Spacer(1, 20))
                
                # Add pie chart for value breakdown if charts are enabled
                if include_charts and len(breakdown) > 1:
                    chart_path = await AnalyticsService._create_value_breakdown_chart(breakdown)
                    if chart_path:
                        chart_paths.append(chart_path)
                        chart_image = Image(chart_path, width=5*inch, height=3*inch)
                        story.append(chart_image)
                        story.append(Spacer(1, 20))
        
        # Trends section with chart
        if 'trends' in requested_types:
            story.append(Paragraph("ACTIVITY TRENDS", heading_style))
            
            trends = analytics.get('trends', [])
            if trends and include_charts:
                chart_path = await AnalyticsService._create_trends_chart(trends)
                if chart_path:
                    chart_paths.append(chart_path)
                    chart_image = Image(chart_path, width=6*inch, height=3*inch)
                    story.append(chart_image)
                    story.append(Spacer(1, 20))
        
        # Streaks section
        if 'streaks' in requested_types:
            story.append(Paragraph("STREAK ANALYTICS", heading_style))
            
            streaks = analytics.get('streaks', {})
            if streaks:
                streak_data = [['Value', 'Current Streak', 'Longest Streak', 'Avg Streak']]
                
                for value_id, streak_info in list(streaks.items())[:10]:
                    streak_data.append([
                        streak_info.get('value_name', 'Unknown')[:20],
                        f"{streak_info.get('current_streak', 0)} days",
                        f"{streak_info.get('longest_streak', 0)} days",
                        f"{streak_info.get('avg_streak_length', 0):.1f} days"
                    ])
                
                streak_table = Table(streak_data, colWidths=[2.5*inch, 1.5*inch, 1.5*inch, 1.5*inch])
                streak_table.setStyle(TableStyle([
                    ('BACKGROUND', (0, 0), (-1, 0), HexColor('#F59E0B')),
                    ('TEXTCOLOR', (0, 0), (-1, 0), white),
                    ('BACKGROUND', (0, 1), (-1, -1), HexColor('#FFFBEB')),
                    ('TEXTCOLOR', (0, 1), (-1, -1), HexColor('#374151')),
                    ('ALIGN', (0, 0), (0, -1), 'LEFT'),
                    ('ALIGN', (1, 0), (-1, -1), 'CENTER'),
                    ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
                    ('FONTNAME', (0, 1), (-1, -1), 'Helvetica'),
                    ('FONTSIZE', (0, 0), (-1, -1), 10),
                    ('GRID', (0, 0), (-1, -1), 1, HexColor('#E5E7EB')),
                    ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
                    ('LEFTPADDING', (0, 0), (-1, -1), 10),
                    ('RIGHTPADDING', (0, 0), (-1, -1), 10),
                    ('TOPPADDING', (0, 0), (-1, -1), 8),
                    ('BOTTOMPADDING', (0, 0), (-1, -1), 8),
                ]))
                
                story.append(streak_table)
                story.append(Spacer(1, 20))
        
        # Insights and patterns section
        if 'insights' in requested_types:
            story.append(Paragraph("INSIGHTS & PATTERNS", heading_style))
            
            patterns = analytics.get('patterns', {})
            predictions = analytics.get('predictions', {})
            
            # Activity patterns
            if patterns:
                story.append(Paragraph("Activity Patterns", styles['Heading3']))
                
                # Best days of week
                best_days = patterns.get('best_days_of_week', [])
                if best_days:
                    story.append(Paragraph("Most Active Days:", styles['Heading4']))
                    for day_pattern in best_days[:3]:
                        story.append(Paragraph(
                            f"• {day_pattern.get('day', 'Unknown')}: {day_pattern.get('count', 0)} activities ({day_pattern.get('percentage', 0):.1f}%)",
                            styles['Normal']
                        ))
                    story.append(Spacer(1, 10))
                
                # Best hours
                best_hours = patterns.get('best_hours', [])
                if best_hours:
                    story.append(Paragraph("Most Active Hours:", styles['Heading4']))
                    for hour_pattern in best_hours[:3]:
                        story.append(Paragraph(
                            f"• {hour_pattern.get('time_label', 'Unknown')}: {hour_pattern.get('count', 0)} activities",
                            styles['Normal']
                        ))
                    story.append(Spacer(1, 10))
            
            # Predictions and recommendations
            if predictions and not predictions.get('insufficient_data'):
                story.append(Paragraph("AI Predictions & Recommendations", styles['Heading3']))
                
                story.append(Paragraph(f"Trend Direction: {predictions.get('trend_direction', 'stable').title()}", styles['Normal']))
                story.append(Paragraph(f"Weekly Goal Probability: {predictions.get('weekly_goal_probability', 0):.1f}%", styles['Normal']))
                
                tips = predictions.get('consistency_improvement_tips', [])
                if tips:
                    story.append(Paragraph("Recommendations:", styles['Heading4']))
                    for tip in tips:
                        story.append(Paragraph(f"• {tip}", styles['Normal']))
        
        # Build PDF
        doc.build(story)
        buffer.seek(0)
        
        return buffer, chart_paths

    @staticmethod
    async def _create_value_breakdown_chart(breakdown: List[Dict[str, Any]]) -> Optional[str]:
        """Create a pie chart for value breakdown"""
        try:
            # Prepare data for pie chart
            values = []
            labels = []
            colors = []
            
            for item in breakdown[:8]:  # Limit to top 8 values
                values.append(item.get('total_duration', 0))
                labels.append(item.get('value_name', 'Unknown')[:15])  # Truncate labels
                # Use value color if available, otherwise default colors
                color = item.get('value_color', '#6366F1')
                if color.startswith('#'):
                    color = color[1:]
                colors.append(f'#{color}')
            
            if not values:
                return None
            
            # Create chart
            plt.figure(figsize=(10, 6))
            plt.pie(values, labels=labels, colors=colors, autopct='%1.1f%%', startangle=90)
            plt.title('Activity Duration by Value', fontsize=16, fontweight='bold', pad=20)
            plt.axis('equal')
            
            # Save to temporary file
            temp_path = tempfile.mktemp(suffix='.png')
            plt.savefig(temp_path, dpi=150, bbox_inches='tight', facecolor='white')
            plt.close()
            
            return temp_path
            
        except Exception as e:
            logger.error(f"Error creating value breakdown chart: {e}")
            return None

    @staticmethod
    async def _create_trends_chart(trends: List[Dict[str, Any]]) -> Optional[str]:
        """Create a line chart for activity trends"""
        try:
            if not trends:
                return None
            
            # Prepare data
            periods = [trend.get('period', '') for trend in trends]
            activity_counts = [trend.get('activity_count', 0) for trend in trends]
            durations = [trend.get('total_duration', 0) / 60 for trend in trends]  # Convert to hours
            
            # Create chart
            fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(12, 8))
            
            # Activity count trend
            ax1.plot(periods, activity_counts, marker='o', linewidth=2, color='#6366F1')
            ax1.set_title('Activity Count Over Time', fontsize=14, fontweight='bold')
            ax1.set_ylabel('Number of Activities')
            ax1.grid(True, alpha=0.3)
            ax1.tick_params(axis='x', rotation=45)
            
            # Duration trend
            ax2.plot(periods, durations, marker='s', linewidth=2, color='#10B981')
            ax2.set_title('Activity Duration Over Time', fontsize=14, fontweight='bold')
            ax2.set_ylabel('Duration (Hours)')
            ax2.set_xlabel('Time Period')
            ax2.grid(True, alpha=0.3)
            ax2.tick_params(axis='x', rotation=45)
            
            plt.tight_layout()
            
            # Save to temporary file
            temp_path = tempfile.mktemp(suffix='.png')
            plt.savefig(temp_path, dpi=150, bbox_inches='tight', facecolor='white')
            plt.close()
            
            return temp_path
            
        except Exception as e:
            logger.error(f"Error creating trends chart: {e}")
            return None