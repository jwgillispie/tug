# app/services/ml_prediction_service.py
import asyncio
import logging
import pickle
from datetime import datetime, timedelta, timezone
from typing import Dict, List, Any, Optional, Tuple
from collections import defaultdict, Counter
import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestRegressor, RandomForestClassifier
from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler, LabelEncoder
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_absolute_error, accuracy_score
from sklearn.pipeline import Pipeline
from sklearn.compose import ColumnTransformer
from sklearn.preprocessing import StandardScaler, OneHotEncoder
from joblib import dump, load
import tempfile
import os
from pathlib import Path

from ..models.user import User
from ..models.activity import Activity
from ..models.value import Value
from ..models.analytics import UserAnalytics, ValueInsights, ActivityPattern

logger = logging.getLogger(__name__)


class MLPredictionService:
    """Machine Learning-powered prediction and recommendation service"""
    
    # Class-level model cache to avoid reloading models
    _models_cache = {}
    _scalers_cache = {}
    _encoders_cache = {}
    
    def __init__(self):
        self.models_dir = Path("/tmp/tug_ml_models")
        self.models_dir.mkdir(exist_ok=True)
        
        # Feature configuration
        self.time_features = [
            'hour', 'day_of_week', 'month', 'is_weekend',
            'time_since_last_activity', 'days_since_start'
        ]
        
        self.behavioral_features = [
            'avg_session_duration', 'total_activities', 'consistency_score',
            'streak_length', 'value_importance', 'preferred_duration'
        ]
        
        self.interaction_features = [
            'activity_frequency', 'value_diversity', 'session_regularity'
        ]

    @classmethod
    async def generate_comprehensive_predictions(
        cls, 
        user: User, 
        activities: List[Activity], 
        values: List[Value]
    ) -> Dict[str, Any]:
        """Generate comprehensive ML-powered predictions and recommendations"""
        
        service = cls()
        
        if len(activities) < 7:
            return await service._generate_fallback_predictions(user, activities, values)
        
        try:
            # Create feature datasets
            features_df = await service._extract_features(user, activities, values)
            
            if features_df.empty:
                return await service._generate_fallback_predictions(user, activities, values)
            
            # Generate different types of predictions
            predictions = {
                "habit_formation": await service._predict_habit_formation(user, features_df),
                "optimal_timing": await service._predict_optimal_timing(user, features_df),
                "streak_risk": await service._assess_streak_risk(user, features_df),
                "goal_recommendations": await service._recommend_goals(user, features_df, values),
                "motivation_timing": await service._predict_motivation_timing(user, features_df),
                "user_segmentation": await service._perform_user_segmentation(user, features_df),
                "activity_forecasting": await service._forecast_activities(user, features_df),
                "confidence_metrics": await service._calculate_confidence_scores(user, features_df)
            }
            
            return predictions
            
        except Exception as e:
            logger.error(f"Error in ML predictions for user {user.id}: {e}", exc_info=True)
            return await service._generate_fallback_predictions(user, activities, values)

    async def _extract_features(
        self, 
        user: User, 
        activities: List[Activity], 
        values: List[Value]
    ) -> pd.DataFrame:
        """Extract comprehensive features for ML models"""
        
        features = []
        value_map = {str(v.id): v for v in values}
        
        # Sort activities by date
        activities.sort(key=lambda x: x.date)
        
        # Calculate user baseline metrics
        total_activities = len(activities)
        if total_activities == 0:
            return pd.DataFrame()
            
        start_date = activities[0].date
        end_date = activities[-1].date
        total_days = max((end_date - start_date).days + 1, 1)
        
        # User-level features
        user_features = {
            'user_age_days': (datetime.now(timezone.utc) - user.created_at).days,
            'total_activities': total_activities,
            'avg_daily_activities': total_activities / total_days,
            'total_values': len(values),
            'is_premium': user.is_premium,
            'days_since_signup': (datetime.now(timezone.utc) - user.created_at).days
        }
        
        # Activity-level features
        for i, activity in enumerate(activities):
            feature_row = user_features.copy()
            
            # Time-based features
            feature_row.update({
                'hour': activity.date.hour,
                'day_of_week': activity.date.weekday(),
                'month': activity.date.month,
                'is_weekend': 1 if activity.date.weekday() >= 5 else 0,
                'days_since_start': (activity.date - start_date).days,
            })
            
            # Activity-specific features
            feature_row.update({
                'duration': activity.duration,
                'activity_sequence': i,
                'has_notes': 1 if activity.notes else 0,
                'is_public': 1 if activity.is_public else 0,
                'value_count': len(activity.effective_value_ids)
            })
            
            # Calculate time since last activity
            if i > 0:
                time_diff = (activity.date - activities[i-1].date).total_seconds() / 3600
                feature_row['time_since_last_activity'] = time_diff
            else:
                feature_row['time_since_last_activity'] = 0
            
            # Value-related features
            primary_value_id = activity.effective_value_ids[0] if activity.effective_value_ids else None
            if primary_value_id and primary_value_id in value_map:
                value = value_map[primary_value_id]
                feature_row.update({
                    'value_importance': value.importance,
                    'value_age_days': (activity.date - value.created_at).days
                })
            else:
                feature_row.update({
                    'value_importance': 3,  # Default middle importance
                    'value_age_days': 0
                })
            
            # Behavioral patterns (calculated from previous activities)
            if i > 0:
                prev_activities = activities[:i]
                
                # Calculate streak at this point
                current_streak = self._calculate_streak_at_point(prev_activities, activity.date.date())
                feature_row['current_streak'] = current_streak
                
                # Calculate consistency metrics
                if len(prev_activities) >= 7:
                    recent_week = prev_activities[-7:]
                    feature_row['week_consistency'] = len(set(a.date.date() for a in recent_week))
                    feature_row['avg_duration_week'] = np.mean([a.duration for a in recent_week])
                else:
                    feature_row['week_consistency'] = len(set(a.date.date() for a in prev_activities))
                    feature_row['avg_duration_week'] = np.mean([a.duration for a in prev_activities])
            else:
                feature_row.update({
                    'current_streak': 0,
                    'week_consistency': 0,
                    'avg_duration_week': activity.duration
                })
            
            features.append(feature_row)
        
        return pd.DataFrame(features)

    def _calculate_streak_at_point(self, activities: List[Activity], target_date) -> int:
        """Calculate streak length at a specific point in time"""
        if not activities:
            return 0
            
        # Get activity dates before target date
        activity_dates = sorted(set(a.date.date() for a in activities if a.date.date() <= target_date))
        
        if not activity_dates:
            return 0
        
        # Calculate streak backwards from target date
        streak = 0
        current_date = target_date
        
        for date in reversed(activity_dates):
            if date == current_date:
                streak += 1
                current_date -= timedelta(days=1)
            elif (current_date - date).days == 1:
                streak += 1
                current_date = date - timedelta(days=1)
            else:
                break
                
        return streak

    async def _predict_habit_formation(self, user: User, features_df: pd.DataFrame) -> Dict[str, Any]:
        """Predict likelihood of successful habit formation"""
        
        try:
            # Prepare features for habit formation prediction
            habit_features = [
                'hour', 'day_of_week', 'is_weekend', 'duration', 
                'value_importance', 'current_streak', 'week_consistency',
                'avg_duration_week', 'time_since_last_activity'
            ]
            
            available_features = [f for f in habit_features if f in features_df.columns]
            
            if not available_features:
                return {"error": "Insufficient features for habit formation prediction"}
            
            X = features_df[available_features].fillna(0)
            
            # Create target variable: successful habit formation 
            # (defined as maintaining 7+ day streaks)
            y = (features_df['current_streak'] >= 7).astype(int)
            
            if len(X) < 10 or y.sum() == 0:  # Need minimum data and positive examples
                return self._generate_habit_formation_heuristics(features_df)
            
            # Train model
            model = RandomForestClassifier(n_estimators=50, random_state=42, max_depth=10)
            scaler = StandardScaler()
            
            X_scaled = scaler.fit_transform(X)
            
            # Split for validation
            if len(X) >= 20:
                X_train, X_test, y_train, y_test = train_test_split(
                    X_scaled, y, test_size=0.3, random_state=42, stratify=y if y.sum() > 1 else None
                )
                model.fit(X_train, y_train)
                accuracy = accuracy_score(y_test, model.predict(X_test))
            else:
                model.fit(X_scaled, y)
                accuracy = 0.8  # Conservative estimate for small datasets
            
            # Get feature importance
            feature_importance = dict(zip(available_features, model.feature_importances_))
            
            # Predict for current user state
            current_features = X.iloc[-1:] if len(X) > 0 else X
            current_scaled = scaler.transform(current_features)
            
            habit_probability = model.predict_proba(current_scaled)[0][1] if len(current_scaled) > 0 else 0.5
            
            # Generate recommendations based on feature importance
            recommendations = self._generate_habit_recommendations(feature_importance, features_df)
            
            return {
                "formation_probability": round(habit_probability * 100, 1),
                "confidence_score": round(accuracy * 100, 1),
                "key_factors": sorted(feature_importance.items(), key=lambda x: x[1], reverse=True)[:3],
                "recommendations": recommendations,
                "model_type": "random_forest_classifier"
            }
            
        except Exception as e:
            logger.error(f"Error in habit formation prediction: {e}")
            return self._generate_habit_formation_heuristics(features_df)

    def _generate_habit_formation_heuristics(self, features_df: pd.DataFrame) -> Dict[str, Any]:
        """Generate habit formation predictions using heuristic methods"""
        
        if features_df.empty:
            return {
                "formation_probability": 50.0,
                "confidence_score": 30.0,
                "key_factors": [],
                "recommendations": ["Start with small, consistent activities", "Choose a specific time each day", "Focus on one habit at a time"],
                "model_type": "heuristic"
            }
        
        # Calculate heuristic probability based on patterns
        consistency = features_df['week_consistency'].mean() if 'week_consistency' in features_df else 0
        avg_streak = features_df['current_streak'].mean() if 'current_streak' in features_df else 0
        regularity = len(set(features_df['hour'])) if 'hour' in features_df else 24
        
        # Normalize scores
        consistency_score = min(consistency / 7, 1.0) * 0.4
        streak_score = min(avg_streak / 14, 1.0) * 0.3
        regularity_score = max((24 - regularity) / 24, 0) * 0.3
        
        probability = (consistency_score + streak_score + regularity_score) * 100
        
        return {
            "formation_probability": round(max(probability, 20.0), 1),
            "confidence_score": 60.0,
            "key_factors": [
                ("consistency", consistency_score),
                ("streak_history", streak_score),
                ("time_regularity", regularity_score)
            ],
            "recommendations": [
                "Maintain consistent daily practice",
                "Track your progress regularly",
                "Set specific times for activities"
            ],
            "model_type": "heuristic"
        }

    def _generate_habit_recommendations(
        self, 
        feature_importance: Dict[str, float], 
        features_df: pd.DataFrame
    ) -> List[str]:
        """Generate personalized habit formation recommendations"""
        
        recommendations = []
        
        # Time-based recommendations
        if 'hour' in feature_importance and feature_importance['hour'] > 0.1:
            most_common_hour = features_df['hour'].mode().iloc[0] if len(features_df) > 0 else 9
            recommendations.append(f"Your most productive time appears to be {most_common_hour}:00. Stick to this schedule!")
        
        # Consistency recommendations
        if 'week_consistency' in feature_importance and feature_importance['week_consistency'] > 0.1:
            avg_consistency = features_df['week_consistency'].mean() if len(features_df) > 0 else 0
            if avg_consistency < 5:
                recommendations.append("Focus on increasing weekly consistency - aim for 5+ days per week")
        
        # Duration recommendations
        if 'duration' in feature_importance and feature_importance['duration'] > 0.1:
            avg_duration = features_df['duration'].mean() if len(features_df) > 0 else 0
            if avg_duration < 15:
                recommendations.append("Consider slightly longer sessions (15-30 minutes) for better habit formation")
            elif avg_duration > 90:
                recommendations.append("Try shorter, more frequent sessions to maintain consistency")
        
        # Default recommendations if none generated
        if not recommendations:
            recommendations = [
                "Start small and build gradually",
                "Focus on consistency over intensity",
                "Set specific times for your activities"
            ]
        
        return recommendations[:3]  # Limit to top 3 recommendations

    async def _predict_optimal_timing(self, user: User, features_df: pd.DataFrame) -> Dict[str, Any]:
        """Predict optimal timing for activities"""
        
        try:
            if features_df.empty:
                return self._generate_default_timing_recommendations()
            
            # Analyze successful activity patterns
            success_metric = features_df['duration'] * features_df.get('current_streak', 1)
            
            # Group by time periods and calculate success rates
            hourly_performance = features_df.groupby('hour').agg({
                'duration': 'mean',
                'current_streak': 'mean'
            }).reset_index()
            
            daily_performance = features_df.groupby('day_of_week').agg({
                'duration': 'mean',
                'current_streak': 'mean',
                'week_consistency': 'mean'
            }).reset_index()
            
            # Calculate composite performance scores
            hourly_performance['performance_score'] = (
                hourly_performance['duration'] * 0.6 + 
                hourly_performance['current_streak'] * 0.4
            )
            
            daily_performance['performance_score'] = (
                daily_performance['duration'] * 0.4 + 
                daily_performance['current_streak'] * 0.3 +
                daily_performance['week_consistency'] * 0.3
            )
            
            # Get top recommendations
            best_hours = hourly_performance.nlargest(3, 'performance_score')
            best_days = daily_performance.nlargest(3, 'performance_score')
            
            # Day names mapping
            day_names = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
            
            return {
                "optimal_hours": [
                    {
                        "hour": int(row['hour']),
                        "time_label": f"{int(row['hour']):02d}:00",
                        "performance_score": round(row['performance_score'], 2),
                        "avg_duration": round(row['duration'], 1)
                    }
                    for _, row in best_hours.iterrows()
                ],
                "optimal_days": [
                    {
                        "day_of_week": int(row['day_of_week']),
                        "day_name": day_names[int(row['day_of_week'])],
                        "performance_score": round(row['performance_score'], 2),
                        "avg_duration": round(row['duration'], 1)
                    }
                    for _, row in best_days.iterrows()
                ],
                "peak_performance_time": f"{int(best_hours.iloc[0]['hour']):02d}:00" if len(best_hours) > 0 else "09:00",
                "peak_performance_day": day_names[int(best_days.iloc[0]['day_of_week'])] if len(best_days) > 0 else "Monday",
                "confidence_score": min(85.0, len(features_df) * 2),  # Higher confidence with more data
                "recommendations": self._generate_timing_recommendations(hourly_performance, daily_performance)
            }
            
        except Exception as e:
            logger.error(f"Error in optimal timing prediction: {e}")
            return self._generate_default_timing_recommendations()

    def _generate_default_timing_recommendations(self) -> Dict[str, Any]:
        """Generate default timing recommendations for new users"""
        return {
            "optimal_hours": [
                {"hour": 9, "time_label": "09:00", "performance_score": 0.8, "avg_duration": 30},
                {"hour": 18, "time_label": "18:00", "performance_score": 0.75, "avg_duration": 25},
                {"hour": 7, "time_label": "07:00", "performance_score": 0.7, "avg_duration": 20}
            ],
            "optimal_days": [
                {"day_of_week": 0, "day_name": "Monday", "performance_score": 0.8, "avg_duration": 30},
                {"day_of_week": 2, "day_name": "Wednesday", "performance_score": 0.75, "avg_duration": 28},
                {"day_of_week": 5, "day_name": "Saturday", "performance_score": 0.7, "avg_duration": 35}
            ],
            "peak_performance_time": "09:00",
            "peak_performance_day": "Monday", 
            "confidence_score": 40.0,
            "recommendations": [
                "Morning hours (7-9 AM) are typically most productive",
                "Weekday mornings often work best for habit building", 
                "Start with your proposed schedule and adjust based on results"
            ]
        }

    def _generate_timing_recommendations(
        self, 
        hourly_performance: pd.DataFrame, 
        daily_performance: pd.DataFrame
    ) -> List[str]:
        """Generate timing-specific recommendations"""
        
        recommendations = []
        
        if not hourly_performance.empty:
            best_hour = hourly_performance.loc[hourly_performance['performance_score'].idxmax()]
            recommendations.append(f"Your peak performance time is {int(best_hour['hour']):02d}:00 - schedule important activities then")
            
            # Check for consistency in timing
            hour_std = hourly_performance['performance_score'].std()
            if hour_std < 0.2:  # Very consistent performance
                recommendations.append("You maintain consistent performance throughout the day - flexibility is your strength")
            else:
                recommendations.append("Your performance varies by time - stick to your peak hours for best results")
        
        if not daily_performance.empty:
            best_day_idx = int(daily_performance.loc[daily_performance['performance_score'].idxmax()]['day_of_week'])
            day_names = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
            recommendations.append(f"{day_names[best_day_idx]} is your strongest day - use it to build momentum")
        
        return recommendations[:3]

    async def _assess_streak_risk(self, user: User, features_df: pd.DataFrame) -> Dict[str, Any]:
        """Assess risk of breaking current streaks"""
        
        try:
            if features_df.empty:
                return {"risk_level": "medium", "risk_score": 50, "recommendations": ["Maintain regular activity"]}
            
            # Calculate risk factors
            current_streak = features_df['current_streak'].iloc[-1] if 'current_streak' in features_df else 0
            time_since_last = features_df['time_since_last_activity'].iloc[-1] if 'time_since_last_activity' in features_df else 0
            recent_consistency = features_df['week_consistency'].tail(7).mean() if 'week_consistency' in features_df else 0
            avg_duration_trend = features_df['duration'].tail(7).mean() / features_df['duration'].mean() if len(features_df) > 7 else 1.0
            
            # Risk scoring (0-100, higher = more risk)
            risk_score = 0
            
            # Time-based risk
            if time_since_last > 24:  # More than 24 hours
                risk_score += 30
            elif time_since_last > 48:  # More than 48 hours
                risk_score += 50
                
            # Consistency risk
            if recent_consistency < 3:  # Less than 3 days per week
                risk_score += 25
                
            # Duration trend risk
            if avg_duration_trend < 0.7:  # Declining duration
                risk_score += 20
                
            # Streak length risk (longer streaks have higher stakes)
            if current_streak > 14:
                risk_score += 10  # Higher stakes
            elif current_streak < 3:
                risk_score += 15  # Vulnerable new streak
            
            risk_score = min(risk_score, 100)
            
            # Determine risk level
            if risk_score < 30:
                risk_level = "low"
            elif risk_score < 60:
                risk_level = "medium"  
            else:
                risk_level = "high"
                
            # Generate risk-specific recommendations
            recommendations = self._generate_streak_risk_recommendations(
                risk_level, time_since_last, recent_consistency, current_streak
            )
            
            return {
                "risk_level": risk_level,
                "risk_score": risk_score,
                "current_streak": int(current_streak),
                "time_since_last_activity_hours": round(time_since_last, 1),
                "recent_consistency_score": round(recent_consistency, 1),
                "recommendations": recommendations,
                "urgency_level": "high" if time_since_last > 36 else "medium" if time_since_last > 18 else "low"
            }
            
        except Exception as e:
            logger.error(f"Error in streak risk assessment: {e}")
            return {
                "risk_level": "medium",
                "risk_score": 50,
                "current_streak": 0,
                "recommendations": ["Maintain regular activity to build consistency"]
            }

    def _generate_streak_risk_recommendations(
        self, 
        risk_level: str, 
        time_since_last: float, 
        recent_consistency: float, 
        current_streak: float
    ) -> List[str]:
        """Generate recommendations based on streak risk assessment"""
        
        recommendations = []
        
        if risk_level == "high":
            if time_since_last > 36:
                recommendations.append("⚠️ Act now! It's been over 36 hours - do a quick 5-minute session to save your streak")
            if recent_consistency < 2:
                recommendations.append("🎯 Your consistency needs immediate attention - aim for daily practice")
            recommendations.append("🚀 Start with the smallest possible version of your activity today")
            
        elif risk_level == "medium":
            if time_since_last > 18:
                recommendations.append("⏰ Plan your next activity within the next 6 hours")
            if recent_consistency < 4:
                recommendations.append("📈 Boost your weekly consistency - aim for 5+ days this week")
            recommendations.append("💪 Maintain momentum with your regular routine")
            
        else:  # low risk
            recommendations.append("✅ Great job maintaining consistency!")
            recommendations.append("🎯 Consider extending your streak with additional values")
            if current_streak > 7:
                recommendations.append("🏆 You're building a strong habit - keep up the excellent work!")
        
        return recommendations

    async def _recommend_goals(
        self, 
        user: User, 
        features_df: pd.DataFrame, 
        values: List[Value]
    ) -> Dict[str, Any]:
        """Generate personalized goal recommendations using collaborative filtering"""
        
        try:
            if features_df.empty or not values:
                return self._generate_default_goal_recommendations()
            
            # Analyze current patterns
            user_patterns = self._analyze_user_patterns(features_df)
            
            # Generate recommendations based on successful patterns
            value_map = {str(v.id): v for v in values}
            value_performance = {}
            
            for value_id, value in value_map.items():
                # Calculate performance metrics for each value
                value_activities = features_df[
                    features_df.index.isin([i for i, activity_values in enumerate(features_df.index) 
                                          if value_id in str(activity_values)])
                ] if 'value_id' in features_df.columns else features_df
                
                if len(value_activities) > 0:
                    avg_duration = value_activities['duration'].mean()
                    consistency = len(set(value_activities.index)) / len(features_df)
                    streak_performance = value_activities['current_streak'].mean() if 'current_streak' in value_activities else 0
                    
                    value_performance[value_id] = {
                        "name": value.name,
                        "performance_score": avg_duration * 0.3 + consistency * 0.4 + streak_performance * 0.3,
                        "avg_duration": avg_duration,
                        "consistency": consistency,
                        "importance": value.importance,
                        "color": value.color
                    }
            
            # Sort values by performance
            top_values = sorted(
                value_performance.items(), 
                key=lambda x: x[1]["performance_score"], 
                reverse=True
            )
            
            # Generate goal recommendations
            recommended_goals = []
            
            # 1. Improve underperforming important values
            for value_id, perf in value_performance.items():
                if perf["importance"] >= 4 and perf["consistency"] < 0.3:
                    recommended_goals.append({
                        "type": "consistency_improvement",
                        "value_id": value_id,
                        "value_name": perf["name"],
                        "goal": f"Increase {perf['name']} consistency to 4+ days per week",
                        "current_rate": f"{perf['consistency']*7:.1f} days/week",
                        "target_rate": "4+ days/week",
                        "priority": "high",
                        "estimated_difficulty": "medium"
                    })
            
            # 2. Duration optimization goals
            overall_avg_duration = features_df['duration'].mean()
            for value_id, perf in value_performance.items():
                if perf["avg_duration"] < overall_avg_duration * 0.7:
                    recommended_goals.append({
                        "type": "duration_optimization",
                        "value_id": value_id,
                        "value_name": perf["name"],
                        "goal": f"Extend {perf['name']} sessions to {overall_avg_duration:.0f}+ minutes",
                        "current_duration": f"{perf['avg_duration']:.1f} min",
                        "target_duration": f"{overall_avg_duration:.0f}+ min",
                        "priority": "medium",
                        "estimated_difficulty": "easy"
                    })
            
            # 3. New habit formation (for less active values)
            inactive_values = [v for v in values if str(v.id) not in value_performance]
            for value in inactive_values[:2]:  # Limit to 2 suggestions
                recommended_goals.append({
                    "type": "new_habit",
                    "value_id": str(value.id),
                    "value_name": value.name,
                    "goal": f"Start a daily {value.name} practice",
                    "target_rate": "3+ days/week",
                    "priority": "low" if value.importance < 4 else "medium",
                    "estimated_difficulty": "medium"
                })
            
            # Limit and prioritize recommendations
            prioritized_goals = sorted(recommended_goals, key=lambda x: {
                "high": 3, "medium": 2, "low": 1
            }[x["priority"]], reverse=True)[:5]
            
            return {
                "recommended_goals": prioritized_goals,
                "top_performing_values": [
                    {"value_id": vid, "name": perf["name"], "score": round(perf["performance_score"], 2)}
                    for vid, perf in top_values[:3]
                ],
                "improvement_opportunities": len([g for g in recommended_goals if g["type"] == "consistency_improvement"]),
                "confidence_score": min(80.0, len(features_df) * 1.5)
            }
            
        except Exception as e:
            logger.error(f"Error in goal recommendations: {e}")
            return self._generate_default_goal_recommendations()

    def _analyze_user_patterns(self, features_df: pd.DataFrame) -> Dict[str, Any]:
        """Analyze user behavioral patterns from features"""
        
        patterns = {}
        
        if 'hour' in features_df.columns:
            patterns['preferred_hours'] = features_df['hour'].value_counts().head(3).to_dict()
        
        if 'day_of_week' in features_df.columns:
            patterns['preferred_days'] = features_df['day_of_week'].value_counts().head(3).to_dict()
            
        if 'duration' in features_df.columns:
            patterns['avg_duration'] = features_df['duration'].mean()
            patterns['duration_consistency'] = features_df['duration'].std()
            
        return patterns

    def _generate_default_goal_recommendations(self) -> Dict[str, Any]:
        """Generate default goal recommendations for new users"""
        return {
            "recommended_goals": [
                {
                    "type": "consistency_building",
                    "goal": "Build a daily activity habit",
                    "target_rate": "5+ days/week",
                    "priority": "high",
                    "estimated_difficulty": "medium"
                },
                {
                    "type": "duration_building",
                    "goal": "Gradually increase session length",
                    "target_duration": "20-30 minutes",
                    "priority": "medium",
                    "estimated_difficulty": "easy"
                }
            ],
            "improvement_opportunities": 2,
            "confidence_score": 40.0
        }

    async def _predict_motivation_timing(self, user: User, features_df: pd.DataFrame) -> Dict[str, Any]:
        """Predict when user needs motivation most"""
        
        try:
            if features_df.empty:
                return self._generate_default_motivation_timing()
            
            # Analyze drop-off patterns
            features_df['motivation_need'] = 0
            
            # High motivation need indicators
            if 'time_since_last_activity' in features_df.columns:
                features_df.loc[features_df['time_since_last_activity'] > 24, 'motivation_need'] += 3
                features_df.loc[features_df['time_since_last_activity'] > 48, 'motivation_need'] += 2
            
            if 'current_streak' in features_df.columns:
                # High stakes streaks need more motivation
                features_df.loc[features_df['current_streak'] > 10, 'motivation_need'] += 2
                # Vulnerable new streaks need support
                features_df.loc[(features_df['current_streak'] > 0) & (features_df['current_streak'] < 5), 'motivation_need'] += 1
            
            if 'week_consistency' in features_df.columns:
                # Low consistency indicates need for motivation
                features_df.loc[features_df['week_consistency'] < 3, 'motivation_need'] += 2
            
            # Identify high-risk periods
            high_risk_hours = features_df.groupby('hour')['motivation_need'].mean().sort_values(ascending=False).head(3)
            high_risk_days = features_df.groupby('day_of_week')['motivation_need'].mean().sort_values(ascending=False).head(3)
            
            # Calculate next motivation intervention time
            current_time = datetime.now(timezone.utc)
            last_activity_time = current_time - timedelta(hours=features_df['time_since_last_activity'].iloc[-1])
            
            # Predict next intervention time
            if features_df['time_since_last_activity'].iloc[-1] > 18:
                next_intervention = "within_2_hours"
            elif features_df['week_consistency'].iloc[-1] < 3:
                next_intervention = "within_6_hours"
            else:
                next_intervention = "within_24_hours"
            
            day_names = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
            
            return {
                "next_intervention_timing": next_intervention,
                "high_risk_hours": [
                    {"hour": int(hour), "time_label": f"{int(hour):02d}:00", "risk_score": round(score, 2)}
                    for hour, score in high_risk_hours.items()
                ],
                "high_risk_days": [
                    {"day": int(day), "day_name": day_names[int(day)], "risk_score": round(score, 2)}
                    for day, score in high_risk_days.items()
                ],
                "motivation_messages": self._generate_motivation_messages(features_df),
                "intervention_type": self._determine_intervention_type(features_df)
            }
            
        except Exception as e:
            logger.error(f"Error in motivation timing prediction: {e}")
            return self._generate_default_motivation_timing()

    def _generate_default_motivation_timing(self) -> Dict[str, Any]:
        """Generate default motivation timing for new users"""
        return {
            "next_intervention_timing": "within_12_hours",
            "high_risk_hours": [
                {"hour": 15, "time_label": "15:00", "risk_score": 0.7},
                {"hour": 20, "time_label": "20:00", "risk_score": 0.6}
            ],
            "high_risk_days": [
                {"day": 6, "day_name": "Sunday", "risk_score": 0.8},
                {"day": 0, "day_name": "Monday", "risk_score": 0.7}
            ],
            "motivation_messages": [
                "You're building something great - keep going!",
                "Small steps lead to big changes",
                "Your consistency is your superpower"
            ],
            "intervention_type": "encouragement"
        }

    def _generate_motivation_messages(self, features_df: pd.DataFrame) -> List[str]:
        """Generate personalized motivation messages"""
        
        messages = []
        
        if 'current_streak' in features_df.columns:
            current_streak = features_df['current_streak'].iloc[-1]
            if current_streak > 7:
                messages.append(f"🔥 Amazing! You're on a {int(current_streak)}-day streak!")
            elif current_streak > 0:
                messages.append(f"💪 You're {int(current_streak)} days in - keep building!")
                
        if 'week_consistency' in features_df.columns:
            consistency = features_df['week_consistency'].iloc[-1]
            if consistency >= 5:
                messages.append("⭐ Your consistency is inspiring!")
            else:
                messages.append("🎯 Let's boost that weekly consistency!")
        
        # Default motivational messages
        default_messages = [
            "Every small step counts toward your bigger goals",
            "Progress isn't always visible, but it's always happening",
            "You're stronger than your excuses"
        ]
        
        if not messages:
            messages = default_messages
        
        return messages[:3]

    def _determine_intervention_type(self, features_df: pd.DataFrame) -> str:
        """Determine the type of motivation intervention needed"""
        
        if features_df.empty:
            return "encouragement"
        
        time_since_last = features_df['time_since_last_activity'].iloc[-1] if 'time_since_last_activity' in features_df else 0
        current_streak = features_df['current_streak'].iloc[-1] if 'current_streak' in features_df else 0
        
        if time_since_last > 48:
            return "urgent_reminder"
        elif time_since_last > 24:
            return "gentle_reminder"
        elif current_streak > 10:
            return "streak_celebration"
        elif current_streak > 0:
            return "encouragement"
        else:
            return "activation"

    async def _perform_user_segmentation(self, user: User, features_df: pd.DataFrame) -> Dict[str, Any]:
        """Perform ML-based user segmentation"""
        
        try:
            if features_df.empty or len(features_df) < 10:
                return self._generate_heuristic_segmentation(features_df)
            
            # Prepare features for clustering
            cluster_features = []
            feature_names = []
            
            # Behavioral features
            if 'duration' in features_df.columns:
                cluster_features.append(features_df['duration'].mean())
                feature_names.append('avg_duration')
            
            if 'current_streak' in features_df.columns:
                cluster_features.append(features_df['current_streak'].max())
                feature_names.append('max_streak')
            
            if 'week_consistency' in features_df.columns:
                cluster_features.append(features_df['week_consistency'].mean())
                feature_names.append('consistency')
            
            if 'hour' in features_df.columns:
                cluster_features.append(len(features_df['hour'].unique()))
                feature_names.append('time_diversity')
            
            if 'value_importance' in features_df.columns:
                cluster_features.append(features_df['value_importance'].mean())
                feature_names.append('avg_importance')
            
            if len(cluster_features) < 3:
                return self._generate_heuristic_segmentation(features_df)
            
            # Simple rule-based segmentation (more reliable than clustering with limited data)
            segment = self._classify_user_segment(cluster_features, feature_names)
            
            return {
                "user_segment": segment["name"],
                "segment_description": segment["description"],
                "segment_characteristics": segment["characteristics"],
                "personalized_strategies": segment["strategies"],
                "confidence_score": segment["confidence"]
            }
            
        except Exception as e:
            logger.error(f"Error in user segmentation: {e}")
            return self._generate_heuristic_segmentation(features_df)

    def _classify_user_segment(self, features: List[float], feature_names: List[str]) -> Dict[str, Any]:
        """Classify user into behavioral segments using rule-based approach"""
        
        # Create feature dictionary
        feat_dict = dict(zip(feature_names, features))
        
        avg_duration = feat_dict.get('avg_duration', 20)
        max_streak = feat_dict.get('max_streak', 0)
        consistency = feat_dict.get('consistency', 0)
        
        # Segment classification
        if consistency >= 5 and max_streak >= 14:
            return {
                "name": "Habit Master",
                "description": "Highly consistent with strong streak maintenance",
                "characteristics": ["High consistency", "Long streaks", "Disciplined approach"],
                "strategies": ["Challenge yourself with advanced goals", "Mentor others", "Explore new value areas"],
                "confidence": 90
            }
        elif consistency >= 3 and avg_duration >= 25:
            return {
                "name": "Quality Focused",
                "description": "Prefers longer, meaningful sessions",
                "characteristics": ["Quality over quantity", "Deeper sessions", "Thoughtful approach"],
                "strategies": ["Maintain your quality focus", "Work on consistency", "Set intensity goals"],
                "confidence": 85
            }
        elif consistency >= 4 and avg_duration < 20:
            return {
                "name": "Consistency Builder",
                "description": "Regular practice with shorter sessions",
                "characteristics": ["Regular daily practice", "Quick sessions", "Building momentum"],
                "strategies": ["Gradually extend session length", "Maintain your rhythm", "Focus on habit stacking"],
                "confidence": 85
            }
        elif max_streak >= 7 and consistency < 3:
            return {
                "name": "Streak Enthusiast",
                "description": "Capable of long streaks but inconsistent overall",
                "characteristics": ["Burst of activity", "Strong motivation periods", "Irregular patterns"],
                "strategies": ["Focus on sustainable pace", "Plan for consistency", "Use streak momentum wisely"],
                "confidence": 80
            }
        else:
            return {
                "name": "Getting Started",
                "description": "Building foundations and finding rhythm",
                "characteristics": ["Exploring patterns", "Developing habits", "Learning preferences"],
                "strategies": ["Start small and consistent", "Experiment with timing", "Focus on one habit"],
                "confidence": 70
            }

    def _generate_heuristic_segmentation(self, features_df: pd.DataFrame) -> Dict[str, Any]:
        """Generate segmentation using simple heuristics for limited data"""
        
        if features_df.empty:
            return {
                "user_segment": "New User",
                "segment_description": "Just getting started with tracking",
                "segment_characteristics": ["Fresh start", "Learning phase", "Establishing patterns"],
                "personalized_strategies": ["Start with small daily habits", "Focus on consistency", "Track your progress"],
                "confidence_score": 50
            }
        
        total_activities = len(features_df)
        avg_duration = features_df['duration'].mean() if 'duration' in features_df else 20
        
        if total_activities < 10:
            segment_name = "Getting Started"
        elif avg_duration > 30:
            segment_name = "Quality Focused"
        else:
            segment_name = "Consistency Builder"
        
        return {
            "user_segment": segment_name,
            "segment_description": f"Based on {total_activities} activities with {avg_duration:.1f}min average",
            "segment_characteristics": ["Developing patterns", "Building momentum"],
            "personalized_strategies": ["Continue tracking", "Maintain regular schedule"],
            "confidence_score": 60
        }

    async def _forecast_activities(self, user: User, features_df: pd.DataFrame) -> Dict[str, Any]:
        """Forecast future activity patterns"""
        
        try:
            if features_df.empty or len(features_df) < 14:
                return self._generate_simple_forecast(features_df)
            
            # Prepare time series data
            if 'days_since_start' not in features_df.columns:
                return self._generate_simple_forecast(features_df)
                
            # Simple trend analysis
            recent_period = features_df.tail(7)
            previous_period = features_df.tail(14).head(7)
            
            recent_avg = recent_period['duration'].mean() if len(recent_period) > 0 else 0
            previous_avg = previous_period['duration'].mean() if len(previous_period) > 0 else recent_avg
            
            trend = (recent_avg - previous_avg) / previous_avg if previous_avg > 0 else 0
            
            # Forecast next week
            next_week_forecast = []
            for day in range(7):
                base_duration = recent_avg
                trend_adjustment = base_duration * trend * (day / 7)  # Gradual trend application
                forecasted_duration = max(5, base_duration + trend_adjustment)  # Minimum 5 minutes
                
                next_week_forecast.append({
                    "day": day + 1,
                    "forecasted_duration": round(forecasted_duration, 1),
                    "confidence": max(30, 80 - (day * 10))  # Decreasing confidence over time
                })
            
            # Weekly summary
            total_forecasted = sum([f["forecasted_duration"] for f in next_week_forecast])
            
            return {
                "next_week_forecast": next_week_forecast,
                "weekly_total_forecast": round(total_forecasted, 1),
                "trend_direction": "increasing" if trend > 0.05 else "decreasing" if trend < -0.05 else "stable",
                "trend_percentage": round(trend * 100, 1),
                "forecast_confidence": round(min(80, len(features_df) * 2), 1),
                "model_type": "trend_analysis"
            }
            
        except Exception as e:
            logger.error(f"Error in activity forecasting: {e}")
            return self._generate_simple_forecast(features_df)

    def _generate_simple_forecast(self, features_df: pd.DataFrame) -> Dict[str, Any]:
        """Generate simple forecast for limited data"""
        
        if features_df.empty:
            avg_duration = 20  # Default
        else:
            avg_duration = features_df['duration'].mean()
        
        next_week_forecast = [
            {"day": day + 1, "forecasted_duration": round(avg_duration, 1), "confidence": 50}
            for day in range(7)
        ]
        
        return {
            "next_week_forecast": next_week_forecast,
            "weekly_total_forecast": round(avg_duration * 7, 1),
            "trend_direction": "stable",
            "trend_percentage": 0,
            "forecast_confidence": 40,
            "model_type": "simple_average"
        }

    async def _calculate_confidence_scores(self, user: User, features_df: pd.DataFrame) -> Dict[str, Any]:
        """Calculate confidence scores for all predictions"""
        
        data_points = len(features_df)
        time_span_days = (datetime.now(timezone.utc) - user.created_at).days
        
        # Base confidence factors
        data_sufficiency = min(100, (data_points / 50) * 100)  # 50+ activities = 100% data confidence
        time_sufficiency = min(100, (time_span_days / 30) * 100)  # 30+ days = 100% time confidence
        
        # Activity diversity (different times, durations, etc.)
        diversity_score = 100
        if not features_df.empty:
            if 'hour' in features_df.columns:
                hour_diversity = len(features_df['hour'].unique()) / 24 * 100
                diversity_score = min(diversity_score, hour_diversity * 4)  # Scale up hour diversity
            
        overall_confidence = (data_sufficiency * 0.4 + time_sufficiency * 0.3 + diversity_score * 0.3)
        
        return {
            "overall_confidence": round(overall_confidence, 1),
            "data_points": data_points,
            "time_span_days": time_span_days,
            "factors": {
                "data_sufficiency": round(data_sufficiency, 1),
                "time_sufficiency": round(time_sufficiency, 1),
                "diversity_score": round(diversity_score, 1)
            },
            "recommendations": self._generate_confidence_recommendations(data_sufficiency, time_sufficiency)
        }

    def _generate_confidence_recommendations(
        self, 
        data_sufficiency: float, 
        time_sufficiency: float
    ) -> List[str]:
        """Generate recommendations to improve prediction confidence"""
        
        recommendations = []
        
        if data_sufficiency < 50:
            recommendations.append("Log more activities to improve prediction accuracy")
        
        if time_sufficiency < 50:
            recommendations.append("Continue tracking for more reliable patterns")
        
        if data_sufficiency >= 80 and time_sufficiency >= 80:
            recommendations.append("Great data foundation for accurate predictions!")
        
        return recommendations

    async def _generate_fallback_predictions(
        self, 
        user: User, 
        activities: List[Activity], 
        values: List[Value]
    ) -> Dict[str, Any]:
        """Generate fallback predictions when ML models can't be used"""
        
        return {
            "habit_formation": {
                "formation_probability": 60.0,
                "confidence_score": 40.0,
                "recommendations": ["Start with small, daily habits", "Focus on consistency over intensity"],
                "model_type": "fallback"
            },
            "optimal_timing": {
                "optimal_hours": [{"hour": 9, "time_label": "09:00"}, {"hour": 18, "time_label": "18:00"}],
                "optimal_days": [{"day_of_week": 0, "day_name": "Monday"}],
                "peak_performance_time": "09:00",
                "recommendations": ["Try morning or evening sessions"],
                "model_type": "fallback"
            },
            "streak_risk": {
                "risk_level": "medium",
                "risk_score": 50,
                "recommendations": ["Maintain regular activity schedule"],
                "model_type": "fallback"
            },
            "goal_recommendations": {
                "recommended_goals": [
                    {"type": "consistency", "goal": "Build daily activity habit", "priority": "high"}
                ],
                "confidence_score": 30.0,
                "model_type": "fallback"
            },
            "motivation_timing": {
                "next_intervention_timing": "within_12_hours",
                "motivation_messages": ["You're building something great!", "Every small step counts"],
                "model_type": "fallback"
            },
            "user_segmentation": {
                "user_segment": "Getting Started",
                "segment_description": "Building foundation habits",
                "personalized_strategies": ["Focus on consistency", "Start small"],
                "confidence_score": 30
            },
            "activity_forecasting": {
                "weekly_total_forecast": 140,  # 20 min * 7 days
                "trend_direction": "stable",
                "forecast_confidence": 30,
                "model_type": "fallback"
            },
            "confidence_metrics": {
                "overall_confidence": 30.0,
                "data_points": len(activities),
                "recommendations": ["Continue tracking for better predictions"]
            }
        }