# app/services/rankings_service.py
from datetime import datetime, timedelta, timezone
from bson import ObjectId
from typing import List, Dict, Any, Optional
import logging
import asyncio

from ..models.user import User
from ..models.activity import Activity

logger = logging.getLogger(__name__)

class RankingsService:
    """Optimized service for handling user rankings and leaderboards with performance enhancements"""

    @staticmethod
    async def get_user_rankings(days: int = 30, limit: int = 20, rank_by: str = "activities") -> List[Dict[str, Any]]:
        """
        Get a ranking of users with the most activities over a specified period.
        Optimized with better aggregation pipeline and parallel processing.
        
        Args:
            days: Number of days to look back for activities
            limit: Maximum number of users to return
            rank_by: Field to rank users by ('activities' or 'streak')
            
        Returns:
            List of user rankings with activity stats
        """
        # Calculate the start date
        start_date = datetime.now(timezone.utc) - timedelta(days=days)
        
        logger.info(f"Calculating optimized rankings from {start_date} to now (rank_by: {rank_by})")
        
        # Optimized aggregation pipeline with better index usage
        base_pipeline = [
            {
                # Filter by date range - uses date_-1_user_id_1 index
                "$match": {
                    "date": {"$gte": start_date}
                }
            },
            {
                # Group by user_id and calculate comprehensive stats
                "$group": {
                    "_id": "$user_id",
                    "total_activities": {"$sum": 1},
                    "total_duration": {"$sum": "$duration"},
                    "avg_duration": {"$avg": "$duration"},
                    "max_duration": {"$max": "$duration"},
                    "min_duration": {"$min": "$duration"},
                    "activity_dates": {
                        "$addToSet": {
                            "$dateToString": {"format": "%Y-%m-%d", "date": "$date"}
                        }
                    },
                    "value_ids": {"$addToSet": "$value_ids"},
                }
            },
            {
                # Calculate derived metrics in a single stage
                "$addFields": {
                    "unique_activity_days": {"$size": "$activity_dates"},
                    "unique_values_count": {"$size": {"$reduce": {
                        "input": "$value_ids",
                        "initialValue": [],
                        "in": {"$setUnion": ["$$value", "$$this"]}
                    }}},
                    # Calculate consistency score (activities per unique day)
                    "consistency_score": {
                        "$cond": {
                            "if": {"$gt": [{"$size": "$activity_dates"}, 0]},
                            "then": {"$divide": ["$total_activities", {"$size": "$activity_dates"}]},
                            "else": 0
                        }
                    }
                }
            }
        ]
        
        # Add sorting based on rank_by parameter
        if rank_by == "streak":
            # For streak ranking, we'll handle this separately due to complexity
            base_pipeline.extend([
                {
                    "$sort": {
                        "total_activities": -1,
                        "consistency_score": -1,
                        "total_duration": -1
                    }
                },
                {"$limit": limit * 2}  # Get more results for streak filtering
            ])
        else:
            # Default activity-based ranking with multiple criteria
            base_pipeline.extend([
                {
                    "$sort": {
                        "total_activities": -1,
                        "unique_activity_days": -1,
                        "total_duration": -1,
                        "consistency_score": -1
                    }
                },
                {"$limit": limit}
            ])
        
        # Execute the optimized aggregation pipeline
        try:
            collection = Activity.get_motor_collection()
            
            # Use allowDiskUse for large datasets and set maxTimeMS for timeout
            cursor = collection.aggregate(
                base_pipeline, 
                allowDiskUse=True,
                maxTimeMS=30000  # 30 second timeout
            )
            user_stats = await cursor.to_list(length=None)
            
            logger.info(f"Base aggregation returned {len(user_stats)} user stats")
            
        except Exception as e:
            logger.error(f"Rankings aggregation failed: {str(e)}")
            return []
        
        # Handle streak-based ranking with optimized user data fetching
        if rank_by == "streak":
            try:
                # Get user streak data efficiently - only fetch users that have activity stats
                user_ids = [stats["_id"] for stats in user_stats]
                
                if user_ids:
                    # Batch fetch user data for users with activity stats
                    user_collection = User.get_motor_collection()
                    users_with_streaks = await user_collection.find(
                        {"_id": {"$in": [ObjectId(uid) for uid in user_ids]}},
                        {"_id": 1, "streak": 1}  # Only fetch necessary fields
                    ).to_list(length=None)
                    
                    # Create efficient lookup map
                    user_streaks = {
                        str(u["_id"]): u.get("streak", 0) or 0 
                        for u in users_with_streaks
                    }
                    
                    # Enhance stats with streak data
                    for stats in user_stats:
                        user_id = stats["_id"]
                        stats["streak"] = user_streaks.get(user_id, 0)
                    
                    # Sort by streak, then by activity metrics
                    user_stats.sort(
                        key=lambda x: (
                            x.get("streak", 0),
                            x.get("total_activities", 0),
                            x.get("consistency_score", 0)
                        ), 
                        reverse=True
                    )
                    
                    # Limit to requested number
                    user_stats = user_stats[:limit]
                    
                    logger.info(f"Streak ranking processed {len(user_stats)} users")
                else:
                    logger.warning("No users found with activity stats for streak ranking")
                    
            except Exception as e:
                logger.error(f"Failed to process streak ranking: {e}")
                # Fall back to activity-based ranking
                user_stats = user_stats[:limit]
        
        # Optimized user details fetching with batch query
        if not user_stats:
            logger.info("No user stats found for ranking")
            return []
        
        # Batch fetch all user details at once
        user_ids_for_details = [stats["_id"] for stats in user_stats]
        try:
            user_collection = User.get_motor_collection()
            users_details = await user_collection.find(
                {"_id": {"$in": [ObjectId(uid) for uid in user_ids_for_details]}},
                {"_id": 1, "display_name": 1, "username": 1, "streak": 1}  # Only fetch necessary fields
            ).to_list(length=None)
            
            # Create efficient user lookup map
            users_map = {str(u["_id"]): u for u in users_details}
            
            logger.info(f"Fetched details for {len(users_details)} users")
            
        except Exception as e:
            logger.error(f"Failed to fetch user details: {e}")
            return []
        
        # Build final results with enhanced metrics
        results = []
        rank = 1
        
        for stats in user_stats:
            user_id = stats["_id"]
            user_data = users_map.get(user_id)
            
            if user_data:
                # Calculate additional metrics
                total_activities = stats.get("total_activities", 0)
                total_duration = stats.get("total_duration", 0)
                unique_days = stats.get("unique_activity_days", 0)
                
                avg_duration_per_activity = (
                    round(total_duration / total_activities, 2) 
                    if total_activities > 0 else 0
                )
                
                avg_duration_per_day = (
                    round(total_duration / unique_days, 2) 
                    if unique_days > 0 else 0
                )
                
                results.append({
                    "rank": rank,
                    "user_id": user_id,
                    "display_name": user_data.get("display_name", "Unknown"),
                    "username": user_data.get("username"),
                    
                    # Core activity metrics
                    "total_activities": total_activities,
                    "total_duration": total_duration,
                    "unique_activity_days": unique_days,
                    "unique_values_count": stats.get("unique_values_count", 0),
                    
                    # Calculated metrics
                    "avg_duration_per_activity": avg_duration_per_activity,
                    "avg_duration_per_day": avg_duration_per_day,
                    "consistency_score": round(stats.get("consistency_score", 0), 2),
                    
                    # Duration range
                    "max_duration": stats.get("max_duration", 0),
                    "min_duration": stats.get("min_duration", 0),
                    "avg_duration": round(stats.get("avg_duration", 0), 2),
                    
                    # Streak information
                    "streak": stats.get("streak", user_data.get("streak", 0)) or 0,
                    
                    # Metadata
                    "ranking_type": rank_by,
                    "ranking_period_days": days,
                })
                rank += 1
            else:
                logger.warning(f"User details not found for user_id: {user_id}")
        
        logger.info(f"Generated {len(results)} ranking results")
        return results

    @staticmethod
    async def get_user_rank(user: User, days: int = 30) -> Optional[Dict[str, Any]]:
        """
        Get a specific user's ranking and activity stats with optimized performance.
        
        Args:
            user: The user to get the rank for
            days: Number of days to look back for activities
            
        Returns:
            User's rank and activity stats
        """
        start_date = datetime.now(timezone.utc) - timedelta(days=days)
        user_id_str = str(user.id)
        
        logger.info(f"Calculating optimized rank for user {user_id_str} from {start_date}")
        
        try:
            collection = Activity.get_motor_collection()
            
            # Single optimized pipeline to get both user stats and rank calculation
            # This approach is more efficient than separate queries
            combined_pipeline = [
                {
                    # Filter by date range - uses date_-1_user_id_1 index
                    "$match": {
                        "date": {"$gte": start_date}
                    }
                },
                {
                    # Group all users to get their stats
                    "$group": {
                        "_id": "$user_id",
                        "total_activities": {"$sum": 1},
                        "total_duration": {"$sum": "$duration"},
                        "avg_duration": {"$avg": "$duration"},
                        "max_duration": {"$max": "$duration"},
                        "min_duration": {"$min": "$duration"},
                        "activity_dates": {
                            "$addToSet": {
                                "$dateToString": {"format": "%Y-%m-%d", "date": "$date"}
                            }
                        },
                        "value_ids": {"$addToSet": "$value_ids"}
                    }
                },
                {
                    # Calculate derived metrics
                    "$addFields": {
                        "unique_activity_days": {"$size": "$activity_dates"},
                        "unique_values_count": {"$size": {"$reduce": {
                            "input": "$value_ids",
                            "initialValue": [],
                            "in": {"$setUnion": ["$$value", "$$this"]}
                        }}},
                        "consistency_score": {
                            "$cond": {
                                "if": {"$gt": [{"$size": "$activity_dates"}, 0]},
                                "then": {"$divide": ["$total_activities", {"$size": "$activity_dates"}]},
                                "else": 0
                            }
                        },
                        "is_target_user": {"$eq": ["$_id", user_id_str]}
                    }
                },
                {
                    # Sort by ranking criteria
                    "$sort": {
                        "total_activities": -1,
                        "unique_activity_days": -1,
                        "total_duration": -1,
                        "consistency_score": -1
                    }
                },
                {
                    # Add rank field using $setWindowFields (MongoDB 5.0+) or simulate with group
                    "$group": {
                        "_id": None,
                        "all_users": {"$push": "$$ROOT"},
                        "target_user": {
                            "$first": {
                                "$cond": {
                                    "if": "$is_target_user",
                                    "then": "$$ROOT",
                                    "else": None
                                }
                            }
                        }
                    }
                },
                {
                    "$project": {
                        "target_user_stats": {
                            "$let": {
                                "vars": {
                                    "target_index": {
                                        "$indexOfArray": ["$all_users._id", user_id_str]
                                    }
                                },
                                "in": {
                                    "$cond": {
                                        "if": {"$gte": ["$$target_index", 0]},
                                        "then": {
                                            "$mergeObjects": [
                                                {"$arrayElemAt": ["$all_users", "$$target_index"]},
                                                {"rank": {"$add": ["$$target_index", 1]}}
                                            ]
                                        },
                                        "else": None
                                    }
                                }
                            }
                        },
                        "total_users_with_activities": {"$size": "$all_users"}
                    }
                }
            ]
            
            # Execute the combined pipeline
            cursor = collection.aggregate(
                combined_pipeline, 
                allowDiskUse=True,
                maxTimeMS=15000  # 15 second timeout for individual user rank
            )
            results = await cursor.to_list(length=None)
            
            if not results or not results[0].get("target_user_stats"):
                # User has no activities in the specified period
                logger.info(f"User {user_id_str} has no activities in the last {days} days")
                return {
                    "rank": None,
                    "user_id": user_id_str,
                    "display_name": user.display_name,
                    "username": getattr(user, "username", None),
                    "total_activities": 0,
                    "total_duration": 0,
                    "unique_activity_days": 0,
                    "unique_values_count": 0,
                    "avg_duration_per_activity": 0,
                    "avg_duration_per_day": 0,
                    "consistency_score": 0,
                    "max_duration": 0,
                    "min_duration": 0,
                    "avg_duration": 0,
                    "streak": getattr(user, "streak", 0) or 0,
                    "total_users_with_activities": results[0].get("total_users_with_activities", 0) if results else 0,
                    "ranking_period_days": days,
                }
            
            # Extract user stats and rank
            user_stats = results[0]["target_user_stats"]
            total_users = results[0].get("total_users_with_activities", 0)
            
            # Calculate additional metrics
            total_activities = user_stats.get("total_activities", 0)
            total_duration = user_stats.get("total_duration", 0)
            unique_days = user_stats.get("unique_activity_days", 0)
            
            avg_duration_per_activity = (
                round(total_duration / total_activities, 2) 
                if total_activities > 0 else 0
            )
            
            avg_duration_per_day = (
                round(total_duration / unique_days, 2) 
                if unique_days > 0 else 0
            )
            
            return {
                "rank": user_stats.get("rank"),
                "user_id": user_id_str,
                "display_name": user.display_name,
                "username": getattr(user, "username", None),
                
                # Core activity metrics
                "total_activities": total_activities,
                "total_duration": total_duration,
                "unique_activity_days": unique_days,
                "unique_values_count": user_stats.get("unique_values_count", 0),
                
                # Calculated metrics
                "avg_duration_per_activity": avg_duration_per_activity,
                "avg_duration_per_day": avg_duration_per_day,
                "consistency_score": round(user_stats.get("consistency_score", 0), 2),
                
                # Duration range
                "max_duration": user_stats.get("max_duration", 0),
                "min_duration": user_stats.get("min_duration", 0),
                "avg_duration": round(user_stats.get("avg_duration", 0), 2),
                
                # Streak and context
                "streak": getattr(user, "streak", 0) or 0,
                "total_users_with_activities": total_users,
                "ranking_period_days": days,
            }
            
        except Exception as e:
            logger.error(f"User rank calculation failed for user {user_id_str}: {str(e)}")
            return None
    
    @staticmethod
    async def get_rankings_summary(days: int = 30) -> Dict[str, Any]:
        """
        Get summary statistics for rankings performance monitoring.
        
        Args:
            days: Number of days to analyze
            
        Returns:
            Summary statistics about rankings data
        """
        start_date = datetime.now(timezone.utc) - timedelta(days=days)
        
        try:
            collection = Activity.get_motor_collection()
            
            summary_pipeline = [
                {
                    "$match": {
                        "date": {"$gte": start_date}
                    }
                },
                {
                    "$group": {
                        "_id": None,
                        "total_activities": {"$sum": 1},
                        "unique_users": {"$addToSet": "$user_id"},
                        "total_duration": {"$sum": "$duration"},
                        "avg_duration": {"$avg": "$duration"},
                        "max_duration": {"$max": "$duration"},
                        "min_duration": {"$min": "$duration"},
                        "activity_dates": {
                            "$addToSet": {
                                "$dateToString": {"format": "%Y-%m-%d", "date": "$date"}
                            }
                        }
                    }
                },
                {
                    "$project": {
                        "total_activities": 1,
                        "unique_users_count": {"$size": "$unique_users"},
                        "unique_days": {"$size": "$activity_dates"},
                        "total_duration": 1,
                        "avg_duration": {"$round": ["$avg_duration", 2]},
                        "max_duration": 1,
                        "min_duration": 1,
                        "avg_activities_per_user": {
                            "$round": [
                                {"$divide": ["$total_activities", {"$size": "$unique_users"}]}, 
                                2
                            ]
                        },
                        "avg_activities_per_day": {
                            "$round": [
                                {"$divide": ["$total_activities", {"$size": "$activity_dates"}]}, 
                                2
                            ]
                        }
                    }
                }
            ]
            
            cursor = collection.aggregate(summary_pipeline, maxTimeMS=10000)
            results = await cursor.to_list(length=None)
            
            if results:
                summary = results[0]
                summary["period_days"] = days
                summary["start_date"] = start_date.isoformat()
                summary["generated_at"] = datetime.now(timezone.utc).isoformat()
                return summary
            else:
                return {
                    "period_days": days,
                    "start_date": start_date.isoformat(),
                    "generated_at": datetime.now(timezone.utc).isoformat(),
                    "total_activities": 0,
                    "unique_users_count": 0,
                    "unique_days": 0,
                    "message": "No activity data found for the specified period"
                }
                
        except Exception as e:
            logger.error(f"Rankings summary calculation failed: {str(e)}")
            return {
                "error": str(e),
                "period_days": days,
                "generated_at": datetime.now(timezone.utc).isoformat()
            }