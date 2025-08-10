# app/api/endpoints/analytics.py
from fastapi import APIRouter, Depends, HTTPException, Query, status
from typing import Any, Dict, List, Optional
from datetime import datetime, timedelta
import logging

from ...models.user import User
from ...models.analytics import AnalyticsType, UserAnalytics, ValueInsights
from ...services.analytics_service import AnalyticsService
from ...core.auth import get_current_user
from ...utils.json_utils import MongoJSONEncoder

router = APIRouter()
logger = logging.getLogger(__name__)


async def check_premium_access(user: User) -> bool:
    """Check if user has premium access"""
    from ...services.subscription_service import SubscriptionService
    
    # Validate subscription status and get current premium status
    return await SubscriptionService.validate_subscription_status(user)


@router.get("/dashboard", status_code=status.HTTP_200_OK)
async def get_analytics_dashboard(
    days_back: int = Query(30, ge=7, le=365, description="Number of days to analyze"),
    analytics_type: AnalyticsType = Query(AnalyticsType.MONTHLY, description="Type of analytics aggregation"),
    current_user: User = Depends(get_current_user)
):
    """Get comprehensive analytics dashboard (Premium Feature)"""
    
    # Check premium access
    if not check_premium_access(current_user):
        raise HTTPException(
            status_code=status.HTTP_402_PAYMENT_REQUIRED,
            detail="Premium subscription required for advanced analytics"
        )
    
    try:
        logger.info(f"Generating analytics dashboard for user: {current_user.id}")
        
        analytics = await AnalyticsService.generate_user_analytics(
            user=current_user,
            analytics_type=analytics_type,
            days_back=days_back
        )
        
        # Encode MongoDB data for JSON response
        analytics = MongoJSONEncoder.encode_mongo_data(analytics)
        
        logger.info(f"Analytics dashboard generated successfully for user: {current_user.id}")
        return {
            "success": True,
            "data": analytics,
            "meta": {
                "days_analyzed": days_back,
                "analytics_type": analytics_type,
                "generated_at": datetime.utcnow()
            }
        }
        
    except Exception as e:
        logger.error(f"Error generating analytics dashboard: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to generate analytics dashboard"
        )


@router.get("/insights/value/{value_id}", status_code=status.HTTP_200_OK)
async def get_value_insights(
    value_id: str,
    days_back: int = Query(90, ge=14, le=365, description="Number of days to analyze"),
    current_user: User = Depends(get_current_user)
):
    """Get detailed insights for a specific value (Premium Feature)"""
    
    # Check premium access
    if not check_premium_access(current_user):
        raise HTTPException(
            status_code=status.HTTP_402_PAYMENT_REQUIRED,
            detail="Premium subscription required for value insights"
        )
    
    try:
        logger.info(f"Generating value insights for value: {value_id}, user: {current_user.id}")
        
        insights = await AnalyticsService.get_value_insights(
            user=current_user,
            value_id=value_id,
            days_back=days_back
        )
        
        if "error" in insights:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=insights["error"]
            )
        
        # Encode MongoDB data for JSON response
        insights = MongoJSONEncoder.encode_mongo_data(insights)
        
        logger.info(f"Value insights generated successfully for value: {value_id}")
        return {
            "success": True,
            "data": insights,
            "meta": {
                "value_id": value_id,
                "days_analyzed": days_back,
                "generated_at": datetime.utcnow()
            }
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error generating value insights: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to generate value insights"
        )


@router.get("/trends", status_code=status.HTTP_200_OK)
async def get_activity_trends(
    days_back: int = Query(30, ge=7, le=365, description="Number of days to analyze"),
    analytics_type: AnalyticsType = Query(AnalyticsType.DAILY, description="Trend granularity"),
    current_user: User = Depends(get_current_user)
):
    """Get activity trends over time (Premium Feature)"""
    
    # Check premium access
    if not check_premium_access(current_user):
        raise HTTPException(
            status_code=status.HTTP_402_PAYMENT_REQUIRED,
            detail="Premium subscription required for trend analysis"
        )
    
    try:
        logger.info(f"Generating activity trends for user: {current_user.id}")
        
        # Get full analytics and extract trends
        analytics = await AnalyticsService.generate_user_analytics(
            user=current_user,
            analytics_type=analytics_type,
            days_back=days_back
        )
        
        trends_data = {
            "trends": analytics.get("trends", []),
            "patterns": analytics.get("patterns", {}),
            "overview": analytics.get("overview", {})
        }
        
        # Encode MongoDB data for JSON response
        trends_data = MongoJSONEncoder.encode_mongo_data(trends_data)
        
        logger.info(f"Activity trends generated successfully for user: {current_user.id}")
        return {
            "success": True,
            "data": trends_data,
            "meta": {
                "days_analyzed": days_back,
                "analytics_type": analytics_type,
                "generated_at": datetime.utcnow()
            }
        }
        
    except Exception as e:
        logger.error(f"Error generating activity trends: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to generate activity trends"
        )


@router.get("/streaks", status_code=status.HTTP_200_OK)
async def get_streak_analytics(
    current_user: User = Depends(get_current_user)
):
    """Get detailed streak analytics for all values (Premium Feature)"""
    
    # Check premium access
    if not check_premium_access(current_user):
        raise HTTPException(
            status_code=status.HTTP_402_PAYMENT_REQUIRED,
            detail="Premium subscription required for streak analytics"
        )
    
    try:
        logger.info(f"Generating streak analytics for user: {current_user.id}")
        
        # Get full analytics and extract streak data
        analytics = await AnalyticsService.generate_user_analytics(
            user=current_user,
            analytics_type=AnalyticsType.MONTHLY,
            days_back=90
        )
        
        streak_data = analytics.get("streaks", {})
        
        # Encode MongoDB data for JSON response
        streak_data = MongoJSONEncoder.encode_mongo_data(streak_data)
        
        logger.info(f"Streak analytics generated successfully for user: {current_user.id}")
        return {
            "success": True,
            "data": streak_data,
            "meta": {
                "generated_at": datetime.utcnow()
            }
        }
        
    except Exception as e:
        logger.error(f"Error generating streak analytics: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to generate streak analytics"
        )


@router.get("/predictions", status_code=status.HTTP_200_OK)
async def get_predictions(
    current_user: User = Depends(get_current_user)
):
    """Get AI-powered predictions and recommendations (Premium Feature)"""
    
    # Check premium access
    if not check_premium_access(current_user):
        raise HTTPException(
            status_code=status.HTTP_402_PAYMENT_REQUIRED,
            detail="Premium subscription required for AI predictions"
        )
    
    try:
        logger.info(f"Generating predictions for user: {current_user.id}")
        
        # Get full analytics and extract predictions
        analytics = await AnalyticsService.generate_user_analytics(
            user=current_user,
            analytics_type=AnalyticsType.WEEKLY,
            days_back=60
        )
        
        predictions_data = analytics.get("predictions", {})
        
        # Encode MongoDB data for JSON response
        predictions_data = MongoJSONEncoder.encode_mongo_data(predictions_data)
        
        logger.info(f"Predictions generated successfully for user: {current_user.id}")
        return {
            "success": True,
            "data": predictions_data,
            "meta": {
                "generated_at": datetime.utcnow()
            }
        }
        
    except Exception as e:
        logger.error(f"Error generating predictions: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to generate predictions"
        )


@router.get("/value-breakdown", status_code=status.HTTP_200_OK)
async def get_value_breakdown(
    days_back: int = Query(30, ge=7, le=365, description="Number of days to analyze"),
    current_user: User = Depends(get_current_user)
):
    """Get detailed breakdown of activities by value (Premium Feature)"""
    
    # Check premium access
    if not check_premium_access(current_user):
        raise HTTPException(
            status_code=status.HTTP_402_PAYMENT_REQUIRED,
            detail="Premium subscription required for value breakdown"
        )
    
    try:
        logger.info(f"Generating value breakdown for user: {current_user.id}")
        
        # Get full analytics and extract value breakdown
        analytics = await AnalyticsService.generate_user_analytics(
            user=current_user,
            analytics_type=AnalyticsType.MONTHLY,
            days_back=days_back
        )
        
        breakdown_data = analytics.get("value_breakdown", [])
        
        # Encode MongoDB data for JSON response
        breakdown_data = MongoJSONEncoder.encode_mongo_data(breakdown_data)
        
        logger.info(f"Value breakdown generated successfully for user: {current_user.id}")
        return {
            "success": True,
            "data": breakdown_data,
            "meta": {
                "days_analyzed": days_back,
                "generated_at": datetime.utcnow()
            }
        }
        
    except Exception as e:
        logger.error(f"Error generating value breakdown: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to generate value breakdown"
        )


@router.get("/export/csv", status_code=status.HTTP_200_OK)
async def export_analytics_csv(
    days_back: int = Query(90, ge=7, le=365, description="Number of days to export"),
    data_types: str = Query("all", description="Comma-separated data types to include: activities,streaks,trends,insights,breakdown"),
    start_date: Optional[str] = Query(None, description="Start date (YYYY-MM-DD) - overrides days_back"),
    end_date: Optional[str] = Query(None, description="End date (YYYY-MM-DD) - overrides days_back"),
    current_user: User = Depends(get_current_user)
):
    """Export analytics data as CSV files (Premium Feature)"""
    
    # Check premium access
    if not check_premium_access(current_user):
        raise HTTPException(
            status_code=status.HTTP_402_PAYMENT_REQUIRED,
            detail="Premium subscription required for CSV export"
        )
    
    try:
        logger.info(f"Exporting CSV analytics data for user: {current_user.id}")
        
        # Parse date range if provided
        export_start_date = None
        export_end_date = None
        
        if start_date and end_date:
            try:
                export_start_date = datetime.strptime(start_date, "%Y-%m-%d")
                export_end_date = datetime.strptime(end_date, "%Y-%m-%d")
                days_back = (export_end_date - export_start_date).days
            except ValueError:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Invalid date format. Use YYYY-MM-DD"
                )
        
        # Get comprehensive analytics data
        analytics = await AnalyticsService.generate_user_analytics(
            user=current_user,
            analytics_type=AnalyticsType.DAILY,
            days_back=days_back
        )
        
        # Parse data types to include
        requested_types = [t.strip().lower() for t in data_types.split(',')]
        if 'all' in requested_types:
            requested_types = ['activities', 'streaks', 'trends', 'insights', 'breakdown']
        
        # Generate CSV export
        csv_files = await AnalyticsService.export_to_csv(
            analytics=analytics,
            user=current_user,
            requested_types=requested_types,
            days_back=days_back,
            start_date=export_start_date,
            end_date=export_end_date
        )
        
        logger.info(f"CSV analytics exported successfully for user: {current_user.id}")
        return {
            "success": True,
            "data": csv_files,
            "format": "csv",
            "meta": {
                "days_exported": days_back,
                "data_types": requested_types,
                "date_range": {
                    "start": export_start_date.isoformat() if export_start_date else None,
                    "end": export_end_date.isoformat() if export_end_date else None
                },
                "generated_at": datetime.utcnow(),
                "file_count": len(csv_files)
            }
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error exporting CSV analytics data: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to export CSV analytics data"
        )


@router.get("/export/pdf", status_code=status.HTTP_200_OK)
async def export_analytics_pdf(
    days_back: int = Query(90, ge=7, le=365, description="Number of days to export"),
    data_types: str = Query("all", description="Comma-separated data types to include: activities,streaks,trends,insights,breakdown"),
    start_date: Optional[str] = Query(None, description="Start date (YYYY-MM-DD) - overrides days_back"),
    end_date: Optional[str] = Query(None, description="End date (YYYY-MM-DD) - overrides days_back"),
    include_charts: bool = Query(True, description="Include charts and visualizations in PDF"),
    current_user: User = Depends(get_current_user)
):
    """Export analytics data as PDF report (Premium Feature)"""
    
    # Check premium access
    if not check_premium_access(current_user):
        raise HTTPException(
            status_code=status.HTTP_402_PAYMENT_REQUIRED,
            detail="Premium subscription required for PDF export"
        )
    
    try:
        logger.info(f"Exporting PDF analytics data for user: {current_user.id}")
        
        # Parse date range if provided
        export_start_date = None
        export_end_date = None
        
        if start_date and end_date:
            try:
                export_start_date = datetime.strptime(start_date, "%Y-%m-%d")
                export_end_date = datetime.strptime(end_date, "%Y-%m-%d")
                days_back = (export_end_date - export_start_date).days
            except ValueError:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Invalid date format. Use YYYY-MM-DD"
                )
        
        # Get comprehensive analytics data
        analytics = await AnalyticsService.generate_user_analytics(
            user=current_user,
            analytics_type=AnalyticsType.DAILY,
            days_back=days_back
        )
        
        # Parse data types to include
        requested_types = [t.strip().lower() for t in data_types.split(',')]
        if 'all' in requested_types:
            requested_types = ['activities', 'streaks', 'trends', 'insights', 'breakdown']
        
        # Generate PDF export
        pdf_data = await AnalyticsService.export_to_pdf(
            analytics=analytics,
            user=current_user,
            requested_types=requested_types,
            days_back=days_back,
            start_date=export_start_date,
            end_date=export_end_date,
            include_charts=include_charts
        )
        
        logger.info(f"PDF analytics exported successfully for user: {current_user.id}")
        return {
            "success": True,
            "data": pdf_data,
            "format": "pdf",
            "meta": {
                "days_exported": days_back,
                "data_types": requested_types,
                "date_range": {
                    "start": export_start_date.isoformat() if export_start_date else None,
                    "end": export_end_date.isoformat() if export_end_date else None
                },
                "generated_at": datetime.utcnow(),
                "include_charts": include_charts
            }
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error exporting PDF analytics data: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to export PDF analytics data"
        )


@router.get("/export", status_code=status.HTTP_200_OK)
async def export_analytics_data(
    format: str = Query("json", regex="^(json|csv|pdf)$", description="Export format"),
    days_back: int = Query(90, ge=7, le=365, description="Number of days to export"),
    data_types: str = Query("all", description="Comma-separated data types to include: activities,streaks,trends,insights,breakdown"),
    start_date: Optional[str] = Query(None, description="Start date (YYYY-MM-DD) - overrides days_back"),
    end_date: Optional[str] = Query(None, description="End date (YYYY-MM-DD) - overrides days_back"),
    current_user: User = Depends(get_current_user)
):
    """Export analytics data in various formats (Premium Feature)"""
    
    # Check premium access
    if not check_premium_access(current_user):
        raise HTTPException(
            status_code=status.HTTP_402_PAYMENT_REQUIRED,
            detail="Premium subscription required for data export"
        )
    
    try:
        logger.info(f"Exporting analytics data for user: {current_user.id}, format: {format}")
        
        # Parse date range if provided
        export_start_date = None
        export_end_date = None
        
        if start_date and end_date:
            try:
                export_start_date = datetime.strptime(start_date, "%Y-%m-%d")
                export_end_date = datetime.strptime(end_date, "%Y-%m-%d")
                days_back = (export_end_date - export_start_date).days
            except ValueError:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Invalid date format. Use YYYY-MM-DD"
                )
        
        # Get comprehensive analytics data
        analytics = await AnalyticsService.generate_user_analytics(
            user=current_user,
            analytics_type=AnalyticsType.DAILY,
            days_back=days_back
        )
        
        # Parse data types to include
        requested_types = [t.strip().lower() for t in data_types.split(',')]
        if 'all' in requested_types:
            requested_types = ['activities', 'streaks', 'trends', 'insights', 'breakdown']
        
        if format == "json":
            # Return JSON format
            export_data = MongoJSONEncoder.encode_mongo_data(analytics)
            
            # Filter data based on requested types
            if 'all' not in data_types.split(','):
                filtered_data = {}
                if 'activities' in requested_types:
                    filtered_data['overview'] = export_data.get('overview', {})
                if 'streaks' in requested_types:
                    filtered_data['streaks'] = export_data.get('streaks', {})
                if 'trends' in requested_types:
                    filtered_data['trends'] = export_data.get('trends', [])
                if 'insights' in requested_types:
                    filtered_data['predictions'] = export_data.get('predictions', {})
                    filtered_data['patterns'] = export_data.get('patterns', {})
                if 'breakdown' in requested_types:
                    filtered_data['value_breakdown'] = export_data.get('value_breakdown', [])
                export_data = filtered_data
            
            return {
                "success": True,
                "data": export_data,
                "format": "json",
                "meta": {
                    "days_exported": days_back,
                    "data_types": requested_types,
                    "date_range": {
                        "start": export_start_date.isoformat() if export_start_date else None,
                        "end": export_end_date.isoformat() if export_end_date else None
                    },
                    "generated_at": datetime.utcnow()
                }
            }
        
        elif format == "csv":
            # Generate CSV export
            csv_data = await AnalyticsService.export_to_csv(
                analytics=analytics,
                user=current_user,
                requested_types=requested_types,
                days_back=days_back
            )
            
            return {
                "success": True,
                "data": csv_data,
                "format": "csv",
                "meta": {
                    "days_exported": days_back,
                    "data_types": requested_types,
                    "generated_at": datetime.utcnow()
                }
            }
        
        elif format == "pdf":
            # Generate PDF export
            pdf_data = await AnalyticsService.export_to_pdf(
                analytics=analytics,
                user=current_user,
                requested_types=requested_types,
                days_back=days_back
            )
            
            return {
                "success": True,
                "data": pdf_data,
                "format": "pdf",
                "meta": {
                    "days_exported": days_back,
                    "data_types": requested_types,
                    "generated_at": datetime.utcnow()
                }
            }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error exporting analytics data: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to export analytics data"
        )