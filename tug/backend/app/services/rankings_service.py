# app/services/rankings_service.py
from datetime import datetime, timedelta
from bson import ObjectId
from typing import List, Dict, Any, Optional
import logging

from ..models.user import User
from ..models.activity import Activity

logger = logging.getLogger(__name__)

class RankingsService:
    """Service for handling user rankings and leaderboards"""

    @staticmethod
    async def get_user_rankings(days: int = 30, limit: int = 20, rank_by: str = "activities") -> List[Dict[str, Any]]:
        """
        Get a ranking of users with the most activities over a specified period.
        
        Args:
            days: Number of days to look back for activities
            limit: Maximum number of users to return
            rank_by: Field to rank users by ('activities' or 'streak')
            
        Returns:
            List of user rankings with activity stats
        """
        # Calculate the start date
        start_date = datetime.utcnow() - timedelta(days=days)
        
        logger.info(f"Calculating rankings from {start_date} to now")
        
        # Aggregate activities grouped by user to get totals
        pipeline = [
            {
                # Filter by date range
                "$match": {
                    "date": {"$gte": start_date}
                }
            },
            {
                # Group by user_id and calculate stats
                "$group": {
                    "_id": "$user_id",
                    "total_activities": {"$sum": 1},
                    "total_duration": {"$sum": "$duration"},
                    "activity_dates": {"$addToSet": {"$dateToString": {"format": "%Y-%m-%d", "date": "$date"}}},
                }
            },
            {
                # Calculate streak information
                "$addFields": {
                    "unique_activity_days": {"$size": "$activity_dates"},
                }
            },
            {
                # Sort by total_activities descending
                "$sort": {
                    "total_activities": -1,
                    "total_duration": -1
                }
            },
            {
                # Limit results
                "$limit": limit
            },
        ]
        
        # FIX: Execute the aggregation pipeline properly
        # OLD (BROKEN): user_stats = await Activity.aggregate(pipeline).to_list()
        # NEW (FIXED): Get cursor first, then convert to list
        cursor = Activity.aggregate(pipeline)
        user_stats = await cursor.to_list(length=None)
        
        # If ranking by streak, change the sorting
        if rank_by == "streak":
            pipeline[-2] = {
                # Sort by streak descending, then by total_activities
                "$sort": {
                    "streak": -1,
                    "total_activities": -1
                }
            }
            
            # Get all users with their streaks
            all_users = await User.find_all().to_list()
            user_streaks = {str(u.id): getattr(u, "streak", 0) or 0 for u in all_users}
            
            # Create a map of user activities
            user_activities = {stats["_id"]: stats for stats in user_stats}
            
            # Combine users with their activity stats
            combined_stats = []
            for user_id, streak in user_streaks.items():
                if streak > 0:  # Only include users with a streak
                    stats = user_activities.get(user_id, {"total_activities": 0, "total_duration": 0, "unique_activity_days": 0})
                    stats["_id"] = user_id
                    stats["streak"] = streak
                    combined_stats.append(stats)
            
            # Sort by streak
            combined_stats.sort(key=lambda x: (x.get("streak", 0), x.get("total_activities", 0)), reverse=True)
            
            # Limit to requested number
            user_stats = combined_stats[:limit]
        
        # Fetch user details for each result
        results = []
        rank = 1
        
        for stats in user_stats:
            user_id = stats["_id"]
            
            # Find user by ID to get their display name
            user = await User.find_one(User.id == ObjectId(user_id))
            
            if user:
                avg_duration = 0
                if stats.get("total_activities", 0) > 0:
                    avg_duration = round(stats.get("total_duration", 0) / stats["total_activities"], 2)
                
                results.append({
                    "rank": rank,
                    "user_id": user_id,
                    "display_name": user.display_name,
                    "total_activities": stats.get("total_activities", 0),
                    "total_duration": stats.get("total_duration", 0),
                    "unique_activity_days": stats.get("unique_activity_days", 0),
                    "avg_duration_per_activity": avg_duration,
                    "streak": getattr(user, "streak", 0) or 0,
                    "ranking_type": rank_by
                })
                rank += 1
        
        return results

    @staticmethod
    async def get_user_rank(user: User, days: int = 30) -> Optional[Dict[str, Any]]:
        """
        Get a specific user's ranking and activity stats.
        
        Args:
            user: The user to get the rank for
            days: Number of days to look back for activities
            
        Returns:
            User's rank and activity stats
        """
        # Calculate the start date
        start_date = datetime.utcnow() - timedelta(days=days)
        
        logger.info(f"Calculating rank for user {user.id} from {start_date} to now")
        
        user_id_str = str(user.id)
        
        # First get the user's stats
        user_stats_pipeline = [
            {
                # Filter by user and date range
                "$match": {
                    "user_id": user_id_str,
                    "date": {"$gte": start_date}
                }
            },
            {
                # Group to calculate stats
                "$group": {
                    "_id": "$user_id",
                    "total_activities": {"$sum": 1},
                    "total_duration": {"$sum": "$duration"},
                    "activity_dates": {"$addToSet": {"$dateToString": {"format": "%Y-%m-%d", "date": "$date"}}},
                }
            },
            {
                # Calculate streak information
                "$addFields": {
                    "unique_activity_days": {"$size": "$activity_dates"},
                }
            },
        ]
        
        # FIX: Execute the aggregation pipeline properly
        # OLD (BROKEN): user_stats_result = await Activity.aggregate(user_stats_pipeline).to_list()
        # NEW (FIXED): Get cursor first, then convert to list
        cursor = Activity.aggregate(user_stats_pipeline)
        user_stats_result = await cursor.to_list(length=None)
        
        # If user has no activities, return None or a default rank
        if not user_stats_result:
            return {
                "rank": None,
                "user_id": user_id_str,
                "display_name": user.display_name,
                "total_activities": 0,
                "total_duration": 0,
                "unique_activity_days": 0,
                "avg_duration_per_activity": 0,
                "streak": getattr(user, "streak", 0) or 0,
            }
        
        user_stats = user_stats_result[0]
        
        # Now count how many users have more activities than this user
        higher_rank_pipeline = [
            {
                # Filter by date range
                "$match": {
                    "date": {"$gte": start_date}
                }
            },
            {
                # Group by user_id and calculate stats
                "$group": {
                    "_id": "$user_id",
                    "total_activities": {"$sum": 1},
                    "total_duration": {"$sum": "$duration"},
                }
            },
            {
                # Filter users with more activities
                "$match": {
                    "$or": [
                        {"total_activities": {"$gt": user_stats["total_activities"]}},
                        {
                            "$and": [
                                {"total_activities": {"$eq": user_stats["total_activities"]}},
                                {"total_duration": {"$gt": user_stats["total_duration"]}},
                            ]
                        }
                    ]
                }
            },
            {
                # Count the users
                "$count": "higher_rank_count"
            }
        ]
        
        # FIX: Execute the aggregation pipeline properly
        # OLD (BROKEN): higher_rank_result = await Activity.aggregate(higher_rank_pipeline).to_list()
        # NEW (FIXED): Get cursor first, then convert to list
        cursor = Activity.aggregate(higher_rank_pipeline)
        higher_rank_result = await cursor.to_list(length=None)
        higher_rank_count = higher_rank_result[0]["higher_rank_count"] if higher_rank_result else 0
        
        # The user's rank is the number of users with more activities plus 1
        user_rank = higher_rank_count + 1
        
        return {
            "rank": user_rank,
            "user_id": user_id_str,
            "display_name": user.display_name,
            "total_activities": user_stats["total_activities"],
            "total_duration": user_stats["total_duration"],
            "unique_activity_days": user_stats["unique_activity_days"],
            "avg_duration_per_activity": round(user_stats["total_duration"] / user_stats["total_activities"], 2),
            "streak": getattr(user, "streak", 0) or 0,
        }