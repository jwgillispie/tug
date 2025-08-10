# app/api/endpoints/habit_suggestions.py
from fastapi import APIRouter, Depends, HTTPException, Query, status
from typing import Any, Dict, List, Optional
from datetime import datetime
import logging

from ...models.user import User
from ...models.habit_suggestion import (
    HabitTemplate, PersonalizedSuggestion, SuggestionFeedback,
    SuggestionType, SuggestionCategory, DifficultyLevel
)
from ...services.habit_suggestion_service import HabitSuggestionService
from ...core.auth import get_current_user
from ...utils.json_utils import MongoJSONEncoder

router = APIRouter()
logger = logging.getLogger(__name__)

@router.get("/", status_code=status.HTTP_200_OK)
async def get_habit_suggestions(
    current_user: User = Depends(get_current_user),
    limit: Optional[int] = Query(10, ge=1, le=20),
    suggestion_types: Optional[List[SuggestionType]] = Query(None),
    refresh: bool = Query(False)
):
    """Get personalized habit suggestions for the current user"""
    
    try:
        logger.info(f"Getting habit suggestions for user: {current_user.id}")
        
        service = HabitSuggestionService()
        
        # Refresh suggestions if requested or needed
        if refresh or await service.refresh_suggestions_if_needed(current_user):
            logger.info(f"Refreshing suggestions for user: {current_user.id}")
        
        # Get current suggestions
        suggestions = await service.get_user_suggestions(
            current_user, 
            limit=limit, 
            suggestion_types=suggestion_types
        )
        
        # Convert to response format
        suggestion_list = []
        for suggestion in suggestions:
            # Get the habit template
            template = await HabitTemplate.get(suggestion.habit_template_id)
            
            suggestion_dict = {
                "id": str(suggestion.id),
                "suggestion_type": suggestion.suggestion_type,
                "template": {
                    "id": str(template.id),
                    "name": template.name,
                    "description": template.description,
                    "category": template.category,
                    "difficulty_level": template.difficulty_level,
                    "estimated_duration": template.estimated_duration,
                    "tags": template.tags
                } if template else None,
                "customized_name": suggestion.customized_name,
                "customized_description": suggestion.customized_description,
                "suggested_duration": suggestion.suggested_duration,
                "suggested_frequency": suggestion.suggested_frequency,
                "suggested_times": suggestion.suggested_times,
                "context_tags": suggestion.context_tags,
                "related_value_ids": suggestion.related_value_ids,
                "compatibility_score": suggestion.compatibility_score,
                "success_probability": suggestion.success_probability,
                "urgency_score": suggestion.urgency_score,
                "reasons": suggestion.reasons,
                "personalization_factors": suggestion.personalization_factors,
                "shown_count": suggestion.shown_count,
                "created_at": suggestion.created_at,
                "expires_at": suggestion.expires_at
            }
            
            suggestion_list.append(suggestion_dict)
        
        # Encode for JSON response
        suggestion_list = MongoJSONEncoder.encode_mongo_data(suggestion_list)
        
        logger.info(f"Successfully retrieved {len(suggestion_list)} suggestions for user: {current_user.id}")
        return {
            "success": True,
            "data": suggestion_list,
            "meta": {
                "user_id": str(current_user.id),
                "count": len(suggestion_list),
                "generated_at": datetime.utcnow()
            }
        }
        
    except Exception as e:
        logger.error(f"Error getting habit suggestions: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get habit suggestions"
        )

@router.post("/generate", status_code=status.HTTP_200_OK)
async def generate_fresh_suggestions(
    current_user: User = Depends(get_current_user),
    max_suggestions: Optional[int] = Query(10, ge=1, le=20),
    suggestion_types: Optional[List[SuggestionType]] = Query(None)
):
    """Generate fresh habit suggestions for the current user"""
    
    try:
        logger.info(f"Generating fresh habit suggestions for user: {current_user.id}")
        
        service = HabitSuggestionService()
        
        # Generate new suggestions
        suggestions = await service.generate_personalized_suggestions(
            current_user,
            max_suggestions=max_suggestions,
            suggestion_types=suggestion_types
        )
        
        # Convert to response format
        suggestion_list = []
        for suggestion in suggestions:
            template = await HabitTemplate.get(suggestion.habit_template_id)
            
            suggestion_dict = {
                "id": str(suggestion.id),
                "suggestion_type": suggestion.suggestion_type,
                "template": {
                    "id": str(template.id),
                    "name": template.name,
                    "description": template.description,
                    "category": template.category,
                    "difficulty_level": template.difficulty_level,
                    "estimated_duration": template.estimated_duration,
                    "tags": template.tags
                } if template else None,
                "suggested_duration": suggestion.suggested_duration,
                "suggested_frequency": suggestion.suggested_frequency,
                "compatibility_score": suggestion.compatibility_score,
                "success_probability": suggestion.success_probability,
                "urgency_score": suggestion.urgency_score,
                "reasons": suggestion.reasons,
                "created_at": suggestion.created_at
            }
            
            suggestion_list.append(suggestion_dict)
        
        # Encode for JSON response
        suggestion_list = MongoJSONEncoder.encode_mongo_data(suggestion_list)
        
        logger.info(f"Successfully generated {len(suggestion_list)} fresh suggestions for user: {current_user.id}")
        return {
            "success": True,
            "data": suggestion_list,
            "meta": {
                "user_id": str(current_user.id),
                "count": len(suggestion_list),
                "generated_at": datetime.utcnow()
            }
        }
        
    except Exception as e:
        logger.error(f"Error generating fresh suggestions: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to generate fresh suggestions"
        )

@router.post("/{suggestion_id}/interact", status_code=status.HTTP_200_OK)
async def track_suggestion_interaction(
    suggestion_id: str,
    action: str = Query(..., pattern="^(viewed|clicked|dismissed|adopted)$"),
    current_user: User = Depends(get_current_user),
    context: Optional[Dict[str, Any]] = None
):
    """Track user interaction with a habit suggestion"""
    
    try:
        logger.info(f"Tracking {action} for suggestion {suggestion_id} by user: {current_user.id}")
        
        service = HabitSuggestionService()
        
        success = await service.track_suggestion_interaction(
            current_user,
            suggestion_id,
            action,
            context
        )
        
        if success:
            return {
                "success": True,
                "message": f"Successfully tracked {action} interaction",
                "meta": {
                    "suggestion_id": suggestion_id,
                    "action": action,
                    "user_id": str(current_user.id),
                    "tracked_at": datetime.utcnow()
                }
            }
        else:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Suggestion not found or access denied"
            )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error tracking suggestion interaction: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to track suggestion interaction"
        )

@router.post("/{suggestion_id}/feedback", status_code=status.HTTP_200_OK)
async def submit_suggestion_feedback(
    suggestion_id: str,
    current_user: User = Depends(get_current_user),
    rating: Optional[int] = Query(None, ge=1, le=5),
    feedback_text: Optional[str] = Query(None, max_length=500)
):
    """Submit feedback for a habit suggestion"""
    
    try:
        logger.info(f"Submitting feedback for suggestion {suggestion_id} by user: {current_user.id}")
        
        # Verify suggestion exists and belongs to user
        suggestion = await PersonalizedSuggestion.get(suggestion_id)
        if not suggestion or suggestion.user_id != str(current_user.id):
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Suggestion not found or access denied"
            )
        
        # Update suggestion with feedback
        if rating:
            suggestion.feedback_rating = rating
        
        await suggestion.save()
        
        # Create feedback record
        feedback = SuggestionFeedback(
            user_id=str(current_user.id),
            suggestion_id=suggestion_id,
            habit_template_id=suggestion.habit_template_id,
            action="rated",
            rating=rating,
            feedback_text=feedback_text,
            suggestion_context={
                "suggestion_type": suggestion.suggestion_type,
                "compatibility_score": suggestion.compatibility_score,
                "success_probability": suggestion.success_probability
            }
        )
        await feedback.insert()
        
        logger.info(f"Successfully submitted feedback for suggestion {suggestion_id}")
        return {
            "success": True,
            "message": "Feedback submitted successfully",
            "meta": {
                "suggestion_id": suggestion_id,
                "rating": rating,
                "user_id": str(current_user.id),
                "submitted_at": datetime.utcnow()
            }
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error submitting suggestion feedback: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to submit suggestion feedback"
        )

@router.get("/discover", status_code=status.HTTP_200_OK)
async def discover_habit_categories(
    current_user: User = Depends(get_current_user),
    category: Optional[SuggestionCategory] = Query(None),
    difficulty: Optional[DifficultyLevel] = Query(None),
    max_duration: Optional[int] = Query(None, ge=1, le=180)
):
    """Discover habit templates by category and preferences"""
    
    try:
        logger.info(f"Discovering habits for user: {current_user.id}")
        
        # Build query
        query = {"is_active": True}
        
        if category:
            query["category"] = category
        
        if difficulty:
            query["difficulty_level"] = difficulty
            
        if max_duration:
            query["estimated_duration"] = {"$lte": max_duration}
        
        # Get habit templates
        templates = await HabitTemplate.find(query).sort([
            ("popularity_score", -1),
            ("effectiveness_rating", -1)
        ]).limit(20).to_list()
        
        # Convert to response format
        template_list = []
        for template in templates:
            template_dict = {
                "id": str(template.id),
                "name": template.name,
                "description": template.description,
                "category": template.category,
                "difficulty_level": template.difficulty_level,
                "estimated_duration": template.estimated_duration,
                "tags": template.tags,
                "value_categories": template.value_categories,
                "requires_equipment": template.requires_equipment,
                "requires_outdoors": template.requires_outdoors,
                "requires_quiet": template.requires_quiet,
                "optimal_time_of_day": template.optimal_time_of_day,
                "success_indicators": template.success_indicators,
                "tips_for_success": template.tips_for_success,
                "popularity_score": template.popularity_score,
                "effectiveness_rating": template.effectiveness_rating
            }
            template_list.append(template_dict)
        
        # Encode for JSON response
        template_list = MongoJSONEncoder.encode_mongo_data(template_list)
        
        logger.info(f"Retrieved {len(template_list)} habit templates for discovery")
        return {
            "success": True,
            "data": template_list,
            "meta": {
                "category": category,
                "difficulty": difficulty,
                "max_duration": max_duration,
                "count": len(template_list),
                "retrieved_at": datetime.utcnow()
            }
        }
        
    except Exception as e:
        logger.error(f"Error discovering habit categories: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to discover habit categories"
        )

@router.get("/categories", status_code=status.HTTP_200_OK)
async def get_suggestion_categories(
    current_user: User = Depends(get_current_user)
):
    """Get available suggestion categories with counts"""
    
    try:
        logger.info(f"Getting suggestion categories for user: {current_user.id}")
        
        # Get category counts
        pipeline = [
            {"$match": {"is_active": True}},
            {"$group": {
                "_id": "$category",
                "count": {"$sum": 1},
                "avg_popularity": {"$avg": "$popularity_score"},
                "avg_effectiveness": {"$avg": "$effectiveness_rating"}
            }},
            {"$sort": {"count": -1}}
        ]
        
        category_stats = await HabitTemplate.aggregate(pipeline).to_list()
        
        # Format response
        categories = []
        for stat in category_stats:
            categories.append({
                "category": stat["_id"],
                "count": stat["count"],
                "avg_popularity": round(stat["avg_popularity"], 2),
                "avg_effectiveness": round(stat["avg_effectiveness"], 2)
            })
        
        return {
            "success": True,
            "data": categories,
            "meta": {
                "total_categories": len(categories),
                "retrieved_at": datetime.utcnow()
            }
        }
        
    except Exception as e:
        logger.error(f"Error getting suggestion categories: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get suggestion categories"
        )

@router.get("/analytics", status_code=status.HTTP_200_OK)
async def get_suggestion_analytics(
    current_user: User = Depends(get_current_user)
):
    """Get user's suggestion interaction analytics"""
    
    try:
        logger.info(f"Getting suggestion analytics for user: {current_user.id}")
        
        # Get user's suggestion history
        suggestions = await PersonalizedSuggestion.find(
            PersonalizedSuggestion.user_id == str(current_user.id)
        ).to_list()
        
        # Calculate analytics
        total_suggestions = len(suggestions)
        viewed_suggestions = len([s for s in suggestions if s.shown_count > 0])
        clicked_suggestions = len([s for s in suggestions if s.clicked])
        dismissed_suggestions = len([s for s in suggestions if s.dismissed])
        adopted_suggestions = len([s for s in suggestions if s.adopted])
        
        # Calculate rates
        view_rate = (viewed_suggestions / total_suggestions * 100) if total_suggestions > 0 else 0
        click_rate = (clicked_suggestions / viewed_suggestions * 100) if viewed_suggestions > 0 else 0
        adoption_rate = (adopted_suggestions / clicked_suggestions * 100) if clicked_suggestions > 0 else 0
        dismiss_rate = (dismissed_suggestions / viewed_suggestions * 100) if viewed_suggestions > 0 else 0
        
        # Get feedback stats
        feedback_records = await SuggestionFeedback.find(
            SuggestionFeedback.user_id == str(current_user.id)
        ).to_list()
        
        ratings = [f.rating for f in feedback_records if f.rating]
        avg_rating = sum(ratings) / len(ratings) if ratings else 0
        
        # Popular suggestion types
        type_counts = {}
        for suggestion in suggestions:
            suggestion_type = suggestion.suggestion_type
            type_counts[suggestion_type] = type_counts.get(suggestion_type, 0) + 1
        
        analytics_data = {
            "total_suggestions": total_suggestions,
            "viewed_suggestions": viewed_suggestions,
            "clicked_suggestions": clicked_suggestions,
            "dismissed_suggestions": dismissed_suggestions,
            "adopted_suggestions": adopted_suggestions,
            "view_rate": round(view_rate, 1),
            "click_rate": round(click_rate, 1),
            "adoption_rate": round(adoption_rate, 1),
            "dismiss_rate": round(dismiss_rate, 1),
            "avg_rating": round(avg_rating, 2),
            "total_feedback": len(feedback_records),
            "popular_suggestion_types": sorted(
                type_counts.items(), 
                key=lambda x: x[1], 
                reverse=True
            )[:5]
        }
        
        return {
            "success": True,
            "data": analytics_data,
            "meta": {
                "user_id": str(current_user.id),
                "period": "all_time",
                "generated_at": datetime.utcnow()
            }
        }
        
    except Exception as e:
        logger.error(f"Error getting suggestion analytics: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get suggestion analytics"
        )

# Admin endpoints for system management

@router.post("/admin/initialize-system", status_code=status.HTTP_200_OK)
async def initialize_habit_system(
    current_user: User = Depends(get_current_user)
):
    """Initialize the habit suggestion system (Admin only)"""
    
    if not current_user.is_premium:  # Using premium as admin check for now
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required"
        )
    
    try:
        logger.info(f"Initializing habit system requested by user: {current_user.id}")
        
        from ...services.habit_system_initializer import HabitSystemInitializer
        
        result = await HabitSystemInitializer.initialize_system()
        
        if result["success"]:
            return {
                "success": True,
                "data": result,
                "message": "Habit suggestion system initialized successfully"
            }
        else:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"System initialization failed: {result.get('error', 'Unknown error')}"
            )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error initializing habit system: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to initialize habit system"
        )

@router.get("/admin/system-health", status_code=status.HTTP_200_OK)
async def check_system_health(
    current_user: User = Depends(get_current_user)
):
    """Check habit suggestion system health (Admin only)"""
    
    if not current_user.is_premium:  # Using premium as admin check for now
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required"
        )
    
    try:
        logger.info(f"System health check requested by user: {current_user.id}")
        
        from ...services.habit_system_initializer import HabitSystemInitializer
        
        health_status = await HabitSystemInitializer.check_system_health()
        
        return {
            "success": True,
            "data": health_status,
            "checked_at": datetime.utcnow()
        }
        
    except Exception as e:
        logger.error(f"Error checking system health: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to check system health"
        )