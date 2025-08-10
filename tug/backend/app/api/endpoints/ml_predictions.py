# app/api/endpoints/ml_predictions.py
from fastapi import APIRouter, Depends, HTTPException, Query, status
from typing import Any, Dict, List, Optional
from datetime import datetime
import logging

from ...models.user import User
from ...services.ml_prediction_service import MLPredictionService
from ...services.ml_training_service import MLTrainingService
from ...services.prediction_cache_service import PredictionCacheService
from ...core.auth import get_current_user
from ...utils.json_utils import MongoJSONEncoder

router = APIRouter()
logger = logging.getLogger(__name__)


@router.get("/comprehensive", status_code=status.HTTP_200_OK)
async def get_comprehensive_predictions(
    current_user: User = Depends(get_current_user)
):
    """Get comprehensive ML-powered predictions for the current user"""
    
    try:
        logger.info(f"Getting comprehensive ML predictions for user: {current_user.id}")
        
        # Import required models
        from ...models.activity import Activity
        from ...models.value import Value
        
        # Get user data
        activities = await Activity.find(
            Activity.user_id == str(current_user.id)
        ).sort([("date", -1)]).limit(200).to_list()
        
        values = await Value.find(Value.user_id == str(current_user.id)).to_list()
        
        # Generate predictions
        predictions = await MLPredictionService.generate_comprehensive_predictions(
            current_user, activities, values
        )
        
        # Encode for JSON response
        predictions = MongoJSONEncoder.encode_mongo_data(predictions)
        
        logger.info(f"Successfully generated comprehensive predictions for user: {current_user.id}")
        return {
            "success": True,
            "data": predictions,
            "meta": {
                "user_id": str(current_user.id),
                "activities_analyzed": len(activities),
                "values_analyzed": len(values),
                "generated_at": datetime.utcnow()
            }
        }
        
    except Exception as e:
        logger.error(f"Error getting comprehensive predictions: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to generate predictions"
        )


@router.get("/habit-formation", status_code=status.HTTP_200_OK)
async def get_habit_formation_predictions(
    current_user: User = Depends(get_current_user)
):
    """Get detailed habit formation predictions"""
    
    try:
        # Get comprehensive predictions and extract habit formation data
        from ...models.activity import Activity
        from ...models.value import Value
        
        activities = await Activity.find(
            Activity.user_id == str(current_user.id)
        ).sort([("date", -1)]).limit(100).to_list()
        
        values = await Value.find(Value.user_id == str(current_user.id)).to_list()
        
        predictions = await MLPredictionService.generate_comprehensive_predictions(
            current_user, activities, values
        )
        
        habit_data = predictions.get("habit_formation", {})
        
        return {
            "success": True,
            "data": habit_data,
            "meta": {
                "prediction_type": "habit_formation",
                "generated_at": datetime.utcnow()
            }
        }
        
    except Exception as e:
        logger.error(f"Error getting habit formation predictions: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to generate habit formation predictions"
        )


@router.get("/streak-risk", status_code=status.HTTP_200_OK)
async def get_streak_risk_assessment(
    current_user: User = Depends(get_current_user)
):
    """Get streak risk assessment and recommendations"""
    
    try:
        from ...models.activity import Activity
        from ...models.value import Value
        
        activities = await Activity.find(
            Activity.user_id == str(current_user.id)
        ).sort([("date", -1)]).limit(50).to_list()
        
        values = await Value.find(Value.user_id == str(current_user.id)).to_list()
        
        predictions = await MLPredictionService.generate_comprehensive_predictions(
            current_user, activities, values
        )
        
        risk_data = predictions.get("streak_risk", {})
        
        return {
            "success": True,
            "data": risk_data,
            "meta": {
                "prediction_type": "streak_risk",
                "urgency": risk_data.get("urgency_level", "medium"),
                "generated_at": datetime.utcnow()
            }
        }
        
    except Exception as e:
        logger.error(f"Error getting streak risk assessment: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to generate streak risk assessment"
        )


@router.get("/optimal-timing", status_code=status.HTTP_200_OK)
async def get_optimal_timing_recommendations(
    current_user: User = Depends(get_current_user)
):
    """Get optimal timing recommendations for activities"""
    
    try:
        from ...models.activity import Activity
        from ...models.value import Value
        
        activities = await Activity.find(
            Activity.user_id == str(current_user.id)
        ).sort([("date", -1)]).limit(100).to_list()
        
        values = await Value.find(Value.user_id == str(current_user.id)).to_list()
        
        predictions = await MLPredictionService.generate_comprehensive_predictions(
            current_user, activities, values
        )
        
        timing_data = predictions.get("optimal_timing", {})
        
        return {
            "success": True,
            "data": timing_data,
            "meta": {
                "prediction_type": "optimal_timing",
                "generated_at": datetime.utcnow()
            }
        }
        
    except Exception as e:
        logger.error(f"Error getting optimal timing recommendations: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to generate timing recommendations"
        )


@router.get("/goal-recommendations", status_code=status.HTTP_200_OK)
async def get_goal_recommendations(
    current_user: User = Depends(get_current_user)
):
    """Get personalized goal recommendations"""
    
    try:
        from ...models.activity import Activity
        from ...models.value import Value
        
        activities = await Activity.find(
            Activity.user_id == str(current_user.id)
        ).sort([("date", -1)]).limit(150).to_list()
        
        values = await Value.find(Value.user_id == str(current_user.id)).to_list()
        
        predictions = await MLPredictionService.generate_comprehensive_predictions(
            current_user, activities, values
        )
        
        goals_data = predictions.get("goal_recommendations", {})
        
        return {
            "success": True,
            "data": goals_data,
            "meta": {
                "prediction_type": "goal_recommendations",
                "generated_at": datetime.utcnow()
            }
        }
        
    except Exception as e:
        logger.error(f"Error getting goal recommendations: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to generate goal recommendations"
        )


@router.get("/user-segment", status_code=status.HTTP_200_OK)
async def get_user_segmentation(
    current_user: User = Depends(get_current_user)
):
    """Get user behavioral segmentation and personalized strategies"""
    
    try:
        from ...models.activity import Activity
        from ...models.value import Value
        
        activities = await Activity.find(
            Activity.user_id == str(current_user.id)
        ).sort([("date", -1)]).limit(100).to_list()
        
        values = await Value.find(Value.user_id == str(current_user.id)).to_list()
        
        predictions = await MLPredictionService.generate_comprehensive_predictions(
            current_user, activities, values
        )
        
        segment_data = predictions.get("user_segmentation", {})
        
        return {
            "success": True,
            "data": segment_data,
            "meta": {
                "prediction_type": "user_segmentation",
                "generated_at": datetime.utcnow()
            }
        }
        
    except Exception as e:
        logger.error(f"Error getting user segmentation: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to generate user segmentation"
        )


@router.post("/invalidate-cache", status_code=status.HTTP_200_OK)
async def invalidate_prediction_cache(
    current_user: User = Depends(get_current_user)
):
    """Invalidate cached predictions for the current user"""
    
    try:
        cache_service = PredictionCacheService()
        success = await cache_service.invalidate_user_cache(current_user)
        
        if success:
            logger.info(f"Successfully invalidated cache for user: {current_user.id}")
            return {
                "success": True,
                "message": "Prediction cache invalidated successfully"
            }
        else:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to invalidate cache"
            )
            
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error invalidating prediction cache: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to invalidate prediction cache"
        )


# Admin endpoints (require premium access or admin role)

@router.post("/admin/train-models", status_code=status.HTTP_200_OK)
async def train_ml_models(
    current_user: User = Depends(get_current_user)
):
    """Train ML models with latest data (Admin/Premium feature)"""
    
    # Check if user has premium access (simplified check)
    if not current_user.is_premium:
        raise HTTPException(
            status_code=status.HTTP_402_PAYMENT_REQUIRED,
            detail="Premium subscription required for model training"
        )
    
    try:
        training_service = MLTrainingService()
        result = await training_service.train_global_models()
        
        logger.info(f"Model training initiated by user: {current_user.id}")
        return {
            "success": True,
            "data": result,
            "meta": {
                "initiated_by": str(current_user.id),
                "initiated_at": datetime.utcnow()
            }
        }
        
    except Exception as e:
        logger.error(f"Error training ML models: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to train ML models"
        )


@router.get("/admin/model-info", status_code=status.HTTP_200_OK)
async def get_model_information(
    current_user: User = Depends(get_current_user)
):
    """Get information about ML models (Admin/Premium feature)"""
    
    if not current_user.is_premium:
        raise HTTPException(
            status_code=status.HTTP_402_PAYMENT_REQUIRED,
            detail="Premium subscription required for model information"
        )
    
    try:
        training_service = MLTrainingService()
        model_info = await training_service.get_model_info()
        
        return {
            "success": True,
            "data": model_info,
            "meta": {
                "requested_by": str(current_user.id),
                "requested_at": datetime.utcnow()
            }
        }
        
    except Exception as e:
        logger.error(f"Error getting model information: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get model information"
        )


@router.post("/admin/evaluate-models", status_code=status.HTTP_200_OK)
async def evaluate_ml_models(
    current_user: User = Depends(get_current_user)
):
    """Evaluate ML model performance (Admin/Premium feature)"""
    
    if not current_user.is_premium:
        raise HTTPException(
            status_code=status.HTTP_402_PAYMENT_REQUIRED,
            detail="Premium subscription required for model evaluation"
        )
    
    try:
        training_service = MLTrainingService()
        evaluation_result = await training_service.evaluate_models()
        
        logger.info(f"Model evaluation initiated by user: {current_user.id}")
        return {
            "success": True,
            "data": evaluation_result,
            "meta": {
                "initiated_by": str(current_user.id),
                "initiated_at": datetime.utcnow()
            }
        }
        
    except Exception as e:
        logger.error(f"Error evaluating ML models: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to evaluate ML models"
        )


@router.get("/admin/cache-stats", status_code=status.HTTP_200_OK)
async def get_cache_statistics(
    current_user: User = Depends(get_current_user)
):
    """Get prediction cache statistics (Admin/Premium feature)"""
    
    if not current_user.is_premium:
        raise HTTPException(
            status_code=status.HTTP_402_PAYMENT_REQUIRED,
            detail="Premium subscription required for cache statistics"
        )
    
    try:
        cache_service = PredictionCacheService()
        cache_stats = await cache_service.get_cache_stats()
        
        return {
            "success": True,
            "data": cache_stats,
            "meta": {
                "requested_by": str(current_user.id),
                "requested_at": datetime.utcnow()
            }
        }
        
    except Exception as e:
        logger.error(f"Error getting cache statistics: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get cache statistics"
        )


@router.post("/admin/warm-cache", status_code=status.HTTP_200_OK)
async def warm_prediction_cache(
    current_user: User = Depends(get_current_user)
):
    """Pre-warm prediction cache for active users (Admin/Premium feature)"""
    
    if not current_user.is_premium:
        raise HTTPException(
            status_code=status.HTTP_402_PAYMENT_REQUIRED,
            detail="Premium subscription required for cache warming"
        )
    
    try:
        cache_service = PredictionCacheService()
        warming_result = await cache_service.warm_cache_for_active_users()
        
        logger.info(f"Cache warming initiated by user: {current_user.id}")
        return {
            "success": True,
            "data": warming_result,
            "meta": {
                "initiated_by": str(current_user.id),
                "initiated_at": datetime.utcnow()
            }
        }
        
    except Exception as e:
        logger.error(f"Error warming prediction cache: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to warm prediction cache"
        )