# app/monitoring/__init__.py
"""
Production monitoring and observability system for TUG API

This package provides comprehensive monitoring capabilities including:
- Health checks and system monitoring
- Metrics collection and Prometheus integration
- Real-time alerting system
- Log aggregation and analysis
- Monitoring dashboards
- Deployment monitoring and rollback triggers
"""

from .health import health_checker, HealthChecker, HealthStatus
from .metrics import metrics_collector, MetricsCollector, MetricType
from .alerts import alert_manager, AlertManager, AlertSeverity
from .log_aggregation import log_aggregator, LogAggregator
from .dashboard import monitoring_dashboard, MonitoringDashboard
from .deployment_monitor import deployment_monitor, DeploymentMonitor, DeploymentConfig
from .middleware import (
    MonitoringMiddleware,
    DatabaseMonitoringMiddleware, 
    UserActivityMonitoringMiddleware,
    ErrorTrackingMiddleware,
    db_monitor,
    user_activity_monitor,
    error_tracker
)
from .endpoints import monitoring_router

__all__ = [
    # Core monitoring components
    'health_checker',
    'metrics_collector', 
    'alert_manager',
    'log_aggregator',
    'monitoring_dashboard',
    'deployment_monitor',
    
    # Middleware components
    'MonitoringMiddleware',
    'DatabaseMonitoringMiddleware',
    'UserActivityMonitoringMiddleware', 
    'ErrorTrackingMiddleware',
    'db_monitor',
    'user_activity_monitor',
    'error_tracker',
    
    # Router
    'monitoring_router',
    
    # Classes for type hints
    'HealthChecker',
    'MetricsCollector',
    'AlertManager',
    'LogAggregator',
    'MonitoringDashboard',
    'DeploymentMonitor',
    
    # Configuration classes
    'DeploymentConfig',
    
    # Enums
    'HealthStatus',
    'MetricType',
    'AlertSeverity'
]

# Version info
__version__ = '1.0.0'
__author__ = 'TUG Development Team'
__description__ = 'Production monitoring and observability system'