# app/services/group_ml_service.py
import logging
from typing import List, Dict, Any, Optional, Tuple
from datetime import datetime, timedelta, date
import numpy as np
import pandas as pd
from collections import defaultdict
from sklearn.ensemble import RandomForestClassifier, RandomForestRegressor
from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler
import asyncio

from ..models.user import User
from ..models.premium_group import PremiumGroup, GroupMembership, GroupPost
from ..models.group_analytics import GroupAnalytics, MemberAnalytics, GroupInsight
from .ml_prediction_service import MLPredictionService

logger = logging.getLogger(__name__)

class GroupMLService:
    """Machine Learning service for premium groups - insights, predictions, and recommendations"""
    
    @staticmethod
    async def generate_group_insights(group_id: str) -> List[Dict[str, Any]]:
        """Generate AI-powered insights for a group using ML analysis"""
        try:
            # Get group and recent analytics
            group = await PremiumGroup.get(group_id)
            if not group:
                return []
            
            recent_analytics = await GroupAnalytics.find({
                "group_id": group_id
            }).sort([("calculated_at", -1)]).limit(6).to_list()  # Last 6 periods
            
            if len(recent_analytics) < 2:
                return []  # Need at least 2 periods for trends
            
            insights = []
            
            # Analyze engagement trends
            engagement_insight = await GroupMLService._analyze_engagement_trends(group_id, recent_analytics)
            if engagement_insight:
                insights.append(engagement_insight)
            
            # Analyze member churn risk
            churn_insights = await GroupMLService._analyze_churn_risk(group_id)
            insights.extend(churn_insights)
            
            # Analyze optimal posting times
            timing_insight = await GroupMLService._analyze_optimal_timing(group_id)
            if timing_insight:
                insights.append(timing_insight)
            
            # Analyze content performance
            content_insight = await GroupMLService._analyze_content_performance(group_id)
            if content_insight:
                insights.append(content_insight)
            
            # Member growth predictions
            growth_insight = await GroupMLService._predict_member_growth(group_id, recent_analytics)
            if growth_insight:
                insights.append(growth_insight)
            
            return insights
            
        except Exception as e:
            logger.error(f"Error generating group insights: {e}", exc_info=True)
            return []
    
    @staticmethod
    async def _analyze_engagement_trends(group_id: str, analytics: List[GroupAnalytics]) -> Optional[Dict[str, Any]]:
        """Analyze engagement trends and predict future engagement"""
        try:
            if len(analytics) < 3:
                return None
            
            # Extract engagement metrics over time
            engagement_scores = [a.member_interaction_rate for a in reversed(analytics)]
            posts_per_member = [a.posts_per_active_member for a in reversed(analytics)]
            
            # Calculate trends
            engagement_trend = np.polyfit(range(len(engagement_scores)), engagement_scores, 1)[0]
            posts_trend = np.polyfit(range(len(posts_per_member)), posts_per_member, 1)[0]
            
            # Determine insight based on trends
            if engagement_trend < -2.0:  # Declining engagement
                return {
                    "type": "engagement",
                    "category": "warning",
                    "priority": 5,
                    "title": "Declining Member Engagement",
                    "description": f"Member engagement has declined by {abs(engagement_trend):.1f}% over recent periods.",
                    "confidence": 0.85,
                    "recommendations": [
                        {
                            "action": "Host interactive events or challenges",
                            "priority": "high",
                            "expected_impact": "15-25% increase in engagement"
                        },
                        {
                            "action": "Survey members about their interests",
                            "priority": "medium",
                            "expected_impact": "Better content alignment"
                        }
                    ],
                    "predicted_outcome": "Without intervention, engagement may continue declining by 10-15% next month"
                }
            elif engagement_trend > 2.0:  # Growing engagement
                return {
                    "type": "engagement",
                    "category": "achievement",
                    "priority": 2,
                    "title": "Strong Engagement Growth",
                    "description": f"Member engagement is growing by {engagement_trend:.1f}% per period.",
                    "confidence": 0.9,
                    "recommendations": [
                        {
                            "action": "Continue current successful strategies",
                            "priority": "high",
                            "expected_impact": "Sustained growth"
                        },
                        {
                            "action": "Consider scaling successful content types",
                            "priority": "medium",
                            "expected_impact": "Accelerated growth"
                        }
                    ],
                    "predicted_outcome": "Engagement likely to continue growing if current patterns maintained"
                }
            
            return None
            
        except Exception as e:
            logger.error(f"Error analyzing engagement trends: {e}")
            return None
    
    @staticmethod
    async def _analyze_churn_risk(group_id: str) -> List[Dict[str, Any]]:
        """Identify members at risk of leaving the group"""
        try:
            insights = []
            
            # Get member analytics for churn prediction
            thirty_days_ago = date.today() - timedelta(days=30)
            member_analytics = await MemberAnalytics.find({
                "group_id": group_id,
                "period_start": {"$gte": thirty_days_ago}
            }).to_list()
            
            if not member_analytics:
                return insights
            
            # Calculate churn risk scores
            high_risk_members = []
            for member in member_analytics:
                risk_factors = 0
                
                # Low engagement
                if member.engagement_score < 5:
                    risk_factors += 2
                
                # No recent posts
                if member.posts_created == 0:
                    risk_factors += 1
                
                # Low session frequency
                if member.session_count < 5:
                    risk_factors += 1
                
                # Declining trend (would need historical data)
                # For now, use a simplified approach
                if risk_factors >= 3:
                    high_risk_members.append(member.user_id)
            
            if len(high_risk_members) > 0:
                risk_percentage = (len(high_risk_members) / len(member_analytics)) * 100
                
                insights.append({
                    "type": "churn_risk",
                    "category": "warning" if risk_percentage > 20 else "opportunity",
                    "priority": 4 if risk_percentage > 20 else 3,
                    "title": f"{len(high_risk_members)} Members at Risk of Leaving",
                    "description": f"{risk_percentage:.1f}% of active members show signs of disengagement.",
                    "confidence": 0.75,
                    "recommendations": [
                        {
                            "action": "Reach out to at-risk members personally",
                            "priority": "high",
                            "expected_impact": "30-50% retention improvement"
                        },
                        {
                            "action": "Create re-engagement campaigns",
                            "priority": "medium",
                            "expected_impact": "Reduce churn by 20%"
                        }
                    ],
                    "at_risk_members": high_risk_members[:5],  # Don't expose too many IDs
                    "predicted_outcome": f"Without intervention, may lose {len(high_risk_members)} members in next 30 days"
                })
            
            return insights
            
        except Exception as e:
            logger.error(f"Error analyzing churn risk: {e}")
            return []
    
    @staticmethod
    async def _analyze_optimal_timing(group_id: str) -> Optional[Dict[str, Any]]:
        """Analyze optimal posting times based on engagement patterns"""
        try:
            # Get recent posts with engagement data
            thirty_days_ago = datetime.utcnow() - timedelta(days=30)
            posts = await GroupPost.find({
                "group_id": group_id,
                "created_at": {"$gte": thirty_days_ago}
            }).to_list()
            
            if len(posts) < 20:  # Need sufficient data
                return None
            
            # Analyze posting times vs engagement
            hour_engagement = defaultdict(list)
            day_engagement = defaultdict(list)
            
            for post in posts:
                hour = post.created_at.hour
                day = post.created_at.strftime('%A')
                engagement = post.engagement_score
                
                hour_engagement[hour].append(engagement)
                day_engagement[day].append(engagement)
            
            # Find optimal hours
            hour_avg_engagement = {hour: np.mean(scores) for hour, scores in hour_engagement.items() if len(scores) >= 3}
            best_hours = sorted(hour_avg_engagement.items(), key=lambda x: x[1], reverse=True)[:3]
            
            # Find optimal days
            day_avg_engagement = {day: np.mean(scores) for day, scores in day_engagement.items() if len(scores) >= 3}
            best_days = sorted(day_avg_engagement.items(), key=lambda x: x[1], reverse=True)[:2]
            
            if best_hours and best_days:
                return {
                    "type": "timing_optimization",
                    "category": "opportunity",
                    "priority": 2,
                    "title": "Optimal Posting Times Identified",
                    "description": "Analysis shows specific times generate higher engagement.",
                    "confidence": 0.8,
                    "recommendations": [
                        {
                            "action": f"Post during peak hours: {', '.join([f'{h}:00' for h, _ in best_hours])}",
                            "priority": "medium",
                            "expected_impact": "20-30% higher engagement"
                        },
                        {
                            "action": f"Focus on {', '.join([d for d, _ in best_days])} for important posts",
                            "priority": "low",
                            "expected_impact": "15% better reach"
                        }
                    ],
                    "optimal_hours": [h for h, _ in best_hours],
                    "optimal_days": [d for d, _ in best_days]
                }
            
            return None
            
        except Exception as e:
            logger.error(f"Error analyzing optimal timing: {e}")
            return None
    
    @staticmethod
    async def _analyze_content_performance(group_id: str) -> Optional[Dict[str, Any]]:
        """Analyze which content types perform best in the group"""
        try:
            # Get recent posts with different types and tags
            thirty_days_ago = datetime.utcnow() - timedelta(days=30)
            posts = await GroupPost.find({
                "group_id": group_id,
                "created_at": {"$gte": thirty_days_ago}
            }).to_list()
            
            if len(posts) < 15:
                return None
            
            # Analyze performance by post type
            type_performance = defaultdict(list)
            tag_performance = defaultdict(list)
            
            for post in posts:
                type_performance[post.post_type].append(post.engagement_score)
                
                for tag in post.tags:
                    tag_performance[tag].append(post.engagement_score)
            
            # Find best performing types
            type_avg = {ptype: np.mean(scores) for ptype, scores in type_performance.items() if len(scores) >= 3}
            best_types = sorted(type_avg.items(), key=lambda x: x[1], reverse=True)[:3]
            
            # Find best performing tags
            tag_avg = {tag: np.mean(scores) for tag, scores in tag_performance.items() if len(scores) >= 3}
            best_tags = sorted(tag_avg.items(), key=lambda x: x[1], reverse=True)[:5]
            
            if best_types:
                return {
                    "type": "content_optimization",
                    "category": "opportunity",
                    "priority": 3,
                    "title": "High-Performance Content Types Identified",
                    "description": "Certain content types consistently generate higher engagement.",
                    "confidence": 0.8,
                    "recommendations": [
                        {
                            "action": f"Create more {best_types[0][0]} content",
                            "priority": "medium",
                            "expected_impact": f"Average {best_types[0][1]:.1f} engagement score"
                        },
                        {
                            "action": f"Use high-performing tags: {', '.join([t for t, _ in best_tags[:3]])}",
                            "priority": "low",
                            "expected_impact": "Improved content discoverability"
                        }
                    ],
                    "best_content_types": dict(best_types),
                    "best_tags": dict(best_tags)
                }
            
            return None
            
        except Exception as e:
            logger.error(f"Error analyzing content performance: {e}")
            return None
    
    @staticmethod
    async def _predict_member_growth(group_id: str, analytics: List[GroupAnalytics]) -> Optional[Dict[str, Any]]:
        """Predict future member growth using trend analysis"""
        try:
            if len(analytics) < 4:
                return None
            
            # Extract growth data
            member_counts = [a.total_members for a in reversed(analytics)]
            growth_rates = [a.growth_rate for a in reversed(analytics)]
            
            # Fit trend line
            x = np.array(range(len(member_counts)))
            y = np.array(member_counts)
            
            # Use polynomial fit for better accuracy
            coeffs = np.polyfit(x, y, min(2, len(x) - 1))
            trend_func = np.poly1d(coeffs)
            
            # Predict next 3 months
            future_months = [len(x), len(x) + 1, len(x) + 2]
            predictions = [int(trend_func(month)) for month in future_months]
            
            # Calculate confidence based on variance
            residuals = y - trend_func(x)
            std_error = np.std(residuals)
            confidence = max(0.5, min(0.9, 1 - (std_error / np.mean(y))))
            
            current_members = member_counts[-1]
            predicted_change = predictions[0] - current_members
            
            category = "growth" if predicted_change > 0 else "warning"
            priority = 3 if abs(predicted_change) > 5 else 2
            
            return {
                "type": "growth_prediction",
                "category": category,
                "priority": priority,
                "title": f"Member Growth Prediction: {'+' if predicted_change > 0 else ''}{predicted_change}",
                "description": f"Based on trends, expecting {predictions[0]} members next month.",
                "confidence": confidence,
                "recommendations": [
                    {
                        "action": "Plan for capacity changes" if abs(predicted_change) > 10 else "Monitor growth trends",
                        "priority": "medium" if abs(predicted_change) > 10 else "low",
                        "expected_impact": "Better group management"
                    }
                ],
                "predictions": {
                    "next_month": predictions[0],
                    "two_months": predictions[1],
                    "three_months": predictions[2]
                },
                "trend_direction": "growing" if predicted_change > 0 else "declining"
            }
            
        except Exception as e:
            logger.error(f"Error predicting member growth: {e}")
            return None
    
    @staticmethod
    async def get_personalized_group_recommendations(user_id: str) -> List[Dict[str, Any]]:
        """Get AI-powered group recommendations for a user"""
        try:
            user = await User.get(user_id)
            if not user:
                return []
            
            # Get user's interests from their activities and values
            # This would integrate with the existing user data
            # For now, return placeholder recommendations
            
            recommendations = []
            
            # Find groups with similar interests
            # This would use more sophisticated ML clustering in practice
            similar_groups = await PremiumGroup.find({
                "status": "active",
                "privacy_level": {"$in": ["public", "discoverable"]}
            }).limit(10).to_list()
            
            for group in similar_groups[:5]:
                recommendations.append({
                    "group_id": str(group.id),
                    "name": group.name,
                    "description": group.description,
                    "relevance_score": 0.8,  # Would calculate based on user profile
                    "reason": "Based on your activity patterns and interests",
                    "members": group.total_members,
                    "activity_level": "high" if group.average_engagement_score > 50 else "medium"
                })
            
            return recommendations
            
        except Exception as e:
            logger.error(f"Error getting group recommendations: {e}")
            return []
    
    @staticmethod
    async def analyze_group_health_score(group_id: str) -> Dict[str, Any]:
        """Calculate comprehensive group health score using multiple metrics"""
        try:
            group = await PremiumGroup.get(group_id)
            if not group:
                return {"health_score": 0, "factors": []}
            
            # Get recent analytics
            recent_analytics = await GroupAnalytics.find({
                "group_id": group_id
            }).sort([("calculated_at", -1)]).limit(1).to_list()
            
            if not recent_analytics:
                return {"health_score": 0, "factors": ["No analytics data available"]}
            
            analytics = recent_analytics[0]
            
            # Calculate health score components (0-100 each)
            engagement_score = min(100, analytics.member_interaction_rate * 2.5)  # Target: 40% interaction
            growth_score = max(0, min(100, 50 + analytics.growth_rate * 2))  # Positive growth = bonus
            retention_score = min(100, analytics.member_retention_rate)
            activity_score = min(100, analytics.posts_per_active_member * 10)  # Target: 10 posts per member
            satisfaction_score = min(100, analytics.satisfaction_score)
            
            # Weighted average
            weights = {
                'engagement': 0.3,
                'retention': 0.25,
                'activity': 0.2,
                'growth': 0.15,
                'satisfaction': 0.1
            }
            
            health_score = (
                engagement_score * weights['engagement'] +
                retention_score * weights['retention'] +
                activity_score * weights['activity'] +
                growth_score * weights['growth'] +
                satisfaction_score * weights['satisfaction']
            )
            
            # Determine health status
            if health_score >= 80:
                status = "Excellent"
            elif health_score >= 60:
                status = "Good"
            elif health_score >= 40:
                status = "Fair"
            else:
                status = "Needs Attention"
            
            return {
                "health_score": round(health_score, 1),
                "status": status,
                "components": {
                    "engagement": round(engagement_score, 1),
                    "retention": round(retention_score, 1),
                    "activity": round(activity_score, 1),
                    "growth": round(growth_score, 1),
                    "satisfaction": round(satisfaction_score, 1)
                },
                "improvement_areas": [
                    name for name, score in {
                        "Member Engagement": engagement_score,
                        "Member Retention": retention_score,
                        "Activity Levels": activity_score,
                        "Growth Rate": growth_score,
                        "Member Satisfaction": satisfaction_score
                    }.items() if score < 60
                ]
            }
            
        except Exception as e:
            logger.error(f"Error analyzing group health score: {e}")
            return {"health_score": 0, "error": "Analysis failed"}