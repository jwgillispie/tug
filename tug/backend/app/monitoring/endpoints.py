# app/monitoring/endpoints.py
from fastapi import APIRouter, Query, HTTPException, Depends
from fastapi.responses import PlainTextResponse, JSONResponse
from typing import Optional, Dict, Any
import time
from datetime import datetime

from .health import health_checker, HealthStatus
from .metrics import metrics_collector
from ..core.logging_config import get_logger

logger = get_logger(__name__)

# Create monitoring router
monitoring_router = APIRouter(prefix="/monitoring", tags=["monitoring"])

@monitoring_router.get("/health")
async def health_check_endpoint(
    detailed: bool = Query(False, description="Include detailed health check information"),
    include_system_info: bool = Query(True, description="Include system information")
):
    """
    Comprehensive health check endpoint
    
    - **detailed**: Include detailed information about each health check
    - **include_system_info**: Include system resource information
    
    Returns:
    - 200: System is healthy
    - 503: System is degraded or unhealthy
    """
    try:
        health_report = await health_checker.run_all_checks(include_details=detailed)
        
        # Determine HTTP status code based on health
        if health_report.overall_status == HealthStatus.HEALTHY:
            status_code = 200
        elif health_report.overall_status == HealthStatus.DEGRADED:
            status_code = 503  # Service Unavailable but may recover
        else:  # UNHEALTHY
            status_code = 503
        
        response_data = health_report.to_dict()
        
        # Remove system info if not requested
        if not include_system_info:
            response_data.pop('system_info', None)
        
        return JSONResponse(content=response_data, status_code=status_code)
        
    except Exception as e:
        logger.error(f"Health check endpoint failed: {str(e)}", exc_info=True)
        return JSONResponse(
            content={
                "overall_status": "unhealthy",
                "error": str(e),
                "timestamp": datetime.utcnow().isoformat() + 'Z'
            },
            status_code=503
        )

@monitoring_router.get("/health/live")
async def liveness_probe():
    """
    Kubernetes-style liveness probe - basic application responsiveness
    
    Returns 200 if the application is running and can accept requests
    """
    return {"status": "alive", "timestamp": datetime.utcnow().isoformat() + 'Z'}

@monitoring_router.get("/health/ready")
async def readiness_probe():
    """
    Kubernetes-style readiness probe - application ready to serve traffic
    
    Returns:
    - 200: Application is ready to serve requests
    - 503: Application is not ready (database connection issues, etc.)
    """
    try:
        # Run critical health checks only
        health_report = await health_checker.run_all_checks(include_details=False)
        
        # Check if critical components are healthy
        critical_checks = ['database', 'memory', 'disk']
        critical_failures = [
            check for check in health_report.checks
            if check.name in critical_checks and check.status == HealthStatus.UNHEALTHY
        ]
        
        if critical_failures:
            return JSONResponse(
                content={
                    "status": "not_ready",
                    "failed_checks": [check.name for check in critical_failures],
                    "timestamp": datetime.utcnow().isoformat() + 'Z'
                },
                status_code=503
            )
        
        return {
            "status": "ready",
            "timestamp": datetime.utcnow().isoformat() + 'Z'
        }
        
    except Exception as e:
        logger.error(f"Readiness probe failed: {str(e)}", exc_info=True)
        return JSONResponse(
            content={
                "status": "not_ready",
                "error": str(e),
                "timestamp": datetime.utcnow().isoformat() + 'Z'
            },
            status_code=503
        )

@monitoring_router.get("/metrics", response_class=PlainTextResponse)
async def prometheus_metrics():
    """
    Prometheus metrics endpoint
    
    Returns metrics in Prometheus format for scraping
    """
    try:
        prometheus_data = metrics_collector.get_prometheus_format()
        
        # Add some basic application info
        app_info_lines = [
            "# HELP tug_app_info Application information",
            "# TYPE tug_app_info gauge",
            'tug_app_info{version="3.0.0",service="tug-api"} 1',
            ""
        ]
        
        return "\n".join(app_info_lines) + prometheus_data
        
    except Exception as e:
        logger.error(f"Metrics endpoint failed: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Failed to generate metrics: {str(e)}")

@monitoring_router.get("/metrics/json")
async def metrics_json():
    """
    JSON metrics endpoint for custom monitoring tools
    
    Returns comprehensive metrics in JSON format
    """
    try:
        metrics_summary = metrics_collector.get_metrics_summary()
        performance_summary = metrics_collector.get_performance_summary()
        
        return {
            "metrics": metrics_summary,
            "performance": performance_summary,
            "timestamp": datetime.utcnow().isoformat() + 'Z'
        }
        
    except Exception as e:
        logger.error(f"JSON metrics endpoint failed: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Failed to generate metrics: {str(e)}")

@monitoring_router.get("/debug/info")
async def debug_info():
    """
    Debug information endpoint (should be disabled in production)
    
    Returns detailed system and application debug information
    """
    try:
        import sys
        import os
        import psutil
        
        process = psutil.Process()
        
        debug_data = {
            "python_version": sys.version,
            "platform": sys.platform,
            "process_info": {
                "pid": process.pid,
                "memory_info": process.memory_info()._asdict(),
                "cpu_percent": process.cpu_percent(),
                "create_time": datetime.fromtimestamp(process.create_time()).isoformat(),
                "status": process.status()
            },
            "environment": {
                "debug_mode": os.environ.get("DEBUG", "False"),
                "log_level": os.environ.get("LOG_LEVEL", "INFO"),
                "environment": os.environ.get("ENVIRONMENT", "production")
            },
            "metrics_summary": metrics_collector.get_metrics_summary(),
            "performance_summary": metrics_collector.get_performance_summary(),
            "timestamp": datetime.utcnow().isoformat() + 'Z'
        }
        
        return debug_data
        
    except Exception as e:
        logger.error(f"Debug info endpoint failed: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Failed to generate debug info: {str(e)}")

@monitoring_router.get("/status")
async def application_status():
    """
    High-level application status endpoint
    
    Returns summary of application health and performance
    """
    try:
        # Get basic health check
        health_report = await health_checker.run_all_checks(include_details=False)
        
        # Get performance metrics
        performance = metrics_collector.get_performance_summary()
        
        # Calculate application health score (0-100)
        healthy_checks = sum(1 for check in health_report.checks if check.status == HealthStatus.HEALTHY)
        total_checks = len(health_report.checks)
        health_score = (healthy_checks / max(total_checks, 1)) * 100
        
        status_data = {
            "status": health_report.overall_status.value,
            "health_score": round(health_score, 1),
            "uptime_seconds": performance['system']['uptime_seconds'],
            "total_requests": performance['requests']['total'],
            "error_rate_percent": round(performance['requests']['error_rate'], 2),
            "avg_response_time_ms": round(performance['requests']['avg_duration_ms'], 2),
            "active_connections": performance['system']['active_connections'],
            "checks_summary": {
                "total": total_checks,
                "healthy": healthy_checks,
                "degraded": sum(1 for check in health_report.checks if check.status == HealthStatus.DEGRADED),
                "unhealthy": sum(1 for check in health_report.checks if check.status == HealthStatus.UNHEALTHY)
            },
            "timestamp": datetime.utcnow().isoformat() + 'Z'
        }
        
        return status_data
        
    except Exception as e:
        logger.error(f"Status endpoint failed: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Failed to get application status: {str(e)}")

@monitoring_router.post("/reset-metrics")
async def reset_metrics():
    """
    Reset all metrics (useful for testing and debugging)
    
    WARNING: This will clear all collected metrics data
    """
    try:
        # This is a destructive operation, so we'll log it
        logger.warning("Metrics reset requested - clearing all metrics data")
        
        # Clear all metrics
        with metrics_collector._lock:
            for metric in metrics_collector.metrics.values():
                metric.samples.clear()
        
        return {
            "status": "success",
            "message": "All metrics have been reset",
            "timestamp": datetime.utcnow().isoformat() + 'Z'
        }
        
    except Exception as e:
        logger.error(f"Metrics reset failed: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Failed to reset metrics: {str(e)}")

# Export the router
__all__ = ['monitoring_router']