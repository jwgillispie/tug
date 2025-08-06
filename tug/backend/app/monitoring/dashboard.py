# app/monitoring/dashboard.py
import json
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any
from dataclasses import dataclass, asdict
import asyncio

from .health import health_checker
from .metrics import metrics_collector
from .alerts import alert_manager
from .log_aggregation import log_aggregator
from ..core.logging_config import get_logger

logger = get_logger(__name__)

@dataclass
class DashboardMetric:
    """Dashboard metric representation"""
    name: str
    value: Any
    unit: str
    trend: Optional[str] = None  # "up", "down", "stable"
    status: Optional[str] = None  # "good", "warning", "critical"
    description: Optional[str] = None

@dataclass
class DashboardWidget:
    """Dashboard widget configuration"""
    widget_id: str
    title: str
    widget_type: str  # "metric", "chart", "table", "status"
    data: Any
    config: Dict[str, Any]
    last_updated: datetime

class MonitoringDashboard:
    """Production monitoring dashboard system"""
    
    def __init__(self):
        self.widgets = {}
        self.refresh_intervals = {
            'health': 30,      # 30 seconds
            'metrics': 60,     # 1 minute  
            'alerts': 30,      # 30 seconds
            'performance': 60, # 1 minute
            'logs': 300        # 5 minutes
        }
        
        # Start background refresh tasks
        asyncio.create_task(self._start_refresh_tasks())
    
    async def _start_refresh_tasks(self):
        """Start background tasks to refresh dashboard data"""
        tasks = []
        for category, interval in self.refresh_intervals.items():
            task = asyncio.create_task(self._refresh_category_loop(category, interval))
            tasks.append(task)
        
        await asyncio.gather(*tasks)
    
    async def _refresh_category_loop(self, category: str, interval: int):
        """Background loop to refresh a specific category of dashboard data"""
        while True:
            try:
                await self._refresh_category(category)
                await asyncio.sleep(interval)
            except Exception as e:
                logger.error(f"Error refreshing dashboard category {category}: {str(e)}")
                await asyncio.sleep(interval)
    
    async def _refresh_category(self, category: str):
        """Refresh dashboard data for a specific category"""
        try:
            if category == 'health':
                await self._refresh_health_widgets()
            elif category == 'metrics':
                await self._refresh_metrics_widgets()
            elif category == 'alerts':
                await self._refresh_alerts_widgets()
            elif category == 'performance':
                await self._refresh_performance_widgets()
            elif category == 'logs':
                await self._refresh_logs_widgets()
                
        except Exception as e:
            logger.error(f"Failed to refresh {category} widgets: {str(e)}")
    
    async def _refresh_health_widgets(self):
        """Refresh health-related dashboard widgets"""
        try:
            health_report = await health_checker.run_all_checks(include_details=False)
            
            # Overall health status widget
            self.widgets['health_status'] = DashboardWidget(
                widget_id='health_status',
                title='System Health',
                widget_type='status',
                data={
                    'status': health_report.overall_status.value,
                    'total_checks': len(health_report.checks),
                    'healthy_checks': sum(1 for check in health_report.checks 
                                        if check.status.value == 'healthy'),
                    'response_time_ms': health_report.response_time_ms
                },
                config={'colors': {'healthy': 'green', 'degraded': 'yellow', 'unhealthy': 'red'}},
                last_updated=datetime.utcnow()
            )
            
            # Individual health checks widget
            health_checks_data = []
            for check in health_report.checks:
                health_checks_data.append({
                    'name': check.name,
                    'status': check.status.value,
                    'response_time_ms': check.response_time_ms,
                    'message': check.message
                })
            
            self.widgets['health_checks'] = DashboardWidget(
                widget_id='health_checks',
                title='Health Checks Detail',
                widget_type='table',
                data=health_checks_data,
                config={'columns': ['name', 'status', 'response_time_ms', 'message']},
                last_updated=datetime.utcnow()
            )
            
        except Exception as e:
            logger.error(f"Failed to refresh health widgets: {str(e)}")
    
    async def _refresh_metrics_widgets(self):
        """Refresh metrics-related dashboard widgets"""
        try:
            # Key performance metrics
            perf_summary = metrics_collector.get_performance_summary()
            
            # Request metrics
            self.widgets['request_metrics'] = DashboardWidget(
                widget_id='request_metrics',
                title='Request Metrics',
                widget_type='metric',
                data=[
                    DashboardMetric(
                        name='Total Requests',
                        value=perf_summary['requests']['total'],
                        unit='requests',
                        status='good'
                    ),
                    DashboardMetric(
                        name='Error Rate',
                        value=round(perf_summary['requests']['error_rate'], 2),
                        unit='%',
                        status='critical' if perf_summary['requests']['error_rate'] > 5 else 'good'
                    ),
                    DashboardMetric(
                        name='Avg Response Time',
                        value=round(perf_summary['requests']['avg_duration_ms'], 2),
                        unit='ms',
                        status='warning' if perf_summary['requests']['avg_duration_ms'] > 1000 else 'good'
                    ),
                    DashboardMetric(
                        name='Active Connections',
                        value=perf_summary['system']['active_connections'],
                        unit='connections',
                        status='good'
                    )
                ],
                config={},
                last_updated=datetime.utcnow()
            )
            
            # System metrics
            memory_usage = metrics_collector.get_metric_value("system_memory_usage_bytes")
            cpu_usage = metrics_collector.get_metric_value("system_cpu_usage_percent")
            
            system_metrics = []
            if memory_usage:
                import psutil
                total_memory = psutil.virtual_memory().total
                memory_percent = (memory_usage / total_memory) * 100
                system_metrics.append(DashboardMetric(
                    name='Memory Usage',
                    value=round(memory_percent, 1),
                    unit='%',
                    status='critical' if memory_percent > 85 else 'warning' if memory_percent > 70 else 'good'
                ))
            
            if cpu_usage:
                system_metrics.append(DashboardMetric(
                    name='CPU Usage',
                    value=round(cpu_usage, 1),
                    unit='%',
                    status='critical' if cpu_usage > 80 else 'warning' if cpu_usage > 60 else 'good'
                ))
            
            self.widgets['system_metrics'] = DashboardWidget(
                widget_id='system_metrics',
                title='System Resources',
                widget_type='metric',
                data=system_metrics,
                config={},
                last_updated=datetime.utcnow()
            )
            
            # Database metrics
            db_active_connections = metrics_collector.get_metric_value("database_connections_active") or 0
            
            self.widgets['database_metrics'] = DashboardWidget(
                widget_id='database_metrics',
                title='Database Metrics',
                widget_type='metric',
                data=[
                    DashboardMetric(
                        name='Active Connections',
                        value=db_active_connections,
                        unit='connections',
                        status='warning' if db_active_connections > 40 else 'good'
                    )
                ],
                config={},
                last_updated=datetime.utcnow()
            )
            
        except Exception as e:
            logger.error(f"Failed to refresh metrics widgets: {str(e)}")
    
    async def _refresh_alerts_widgets(self):
        """Refresh alerts-related dashboard widgets"""
        try:
            alert_status = alert_manager.get_alert_status()
            
            # Alert summary widget
            self.widgets['alert_summary'] = DashboardWidget(
                widget_id='alert_summary',
                title='Alert Summary',
                widget_type='metric',
                data=[
                    DashboardMetric(
                        name='Active Alerts',
                        value=alert_status['active_alerts'],
                        unit='alerts',
                        status='critical' if alert_status['active_alerts'] > 0 else 'good'
                    ),
                    DashboardMetric(
                        name='Total Rules',
                        value=alert_status['total_rules'],
                        unit='rules',
                        status='good'
                    ),
                    DashboardMetric(
                        name='Enabled Rules',
                        value=alert_status['enabled_rules'],
                        unit='rules',
                        status='good'
                    )
                ],
                config={},
                last_updated=datetime.utcnow()
            )
            
            # Active alerts table
            active_alerts_data = []
            for alert_data in alert_status['alerts']:
                active_alerts_data.append({
                    'name': alert_data['name'],
                    'severity': alert_data['severity'],
                    'status': alert_data['status'],
                    'created_at': alert_data['created_at']
                })
            
            self.widgets['active_alerts'] = DashboardWidget(
                widget_id='active_alerts',
                title='Active Alerts',
                widget_type='table',
                data=active_alerts_data,
                config={'columns': ['name', 'severity', 'status', 'created_at']},
                last_updated=datetime.utcnow()
            )
            
        except Exception as e:
            logger.error(f"Failed to refresh alerts widgets: {str(e)}")
    
    async def _refresh_performance_widgets(self):
        """Refresh performance-related dashboard widgets"""
        try:
            # Get recent slow requests
            slow_requests = log_aggregator.get_slow_requests(limit=20)
            
            # Format slow requests data
            slow_requests_data = []
            for req in slow_requests:
                slow_requests_data.append({
                    'timestamp': req.get('timestamp', ''),
                    'endpoint': req.get('endpoint', 'unknown'),
                    'method': req.get('method', 'unknown'),
                    'response_time_ms': req.get('response_time_ms', 0),
                    'status_code': req.get('status_code', '')
                })
            
            self.widgets['slow_requests'] = DashboardWidget(
                widget_id='slow_requests',
                title='Recent Slow Requests',
                widget_type='table',
                data=slow_requests_data,
                config={'columns': ['timestamp', 'endpoint', 'method', 'response_time_ms', 'status_code']},
                last_updated=datetime.utcnow()
            )
            
            # Response time distribution (mock data - would need real time series data)
            self.widgets['response_time_chart'] = DashboardWidget(
                widget_id='response_time_chart',
                title='Response Time Distribution',
                widget_type='chart',
                data={
                    'type': 'histogram',
                    'labels': ['<100ms', '100-500ms', '500ms-1s', '1s-2s', '2s+'],
                    'values': [85, 12, 2, 1, 0]  # Percentage distribution
                },
                config={'chart_type': 'bar'},
                last_updated=datetime.utcnow()
            )
            
        except Exception as e:
            logger.error(f"Failed to refresh performance widgets: {str(e)}")
    
    async def _refresh_logs_widgets(self):
        """Refresh logs-related dashboard widgets"""
        try:
            # Log aggregation stats
            log_stats = log_aggregator.get_aggregation_stats()
            
            # Log level distribution
            log_level_data = []
            for level, count in log_stats['logs_by_level'].items():
                log_level_data.append({
                    'level': level,
                    'count': count,
                    'percentage': round((count / max(log_stats['total_logs_processed'], 1)) * 100, 2)
                })
            
            self.widgets['log_levels'] = DashboardWidget(
                widget_id='log_levels',
                title='Log Level Distribution',
                widget_type='chart',
                data={
                    'type': 'pie',
                    'data': log_level_data
                },
                config={'chart_type': 'pie'},
                last_updated=datetime.utcnow()
            )
            
            # Recent errors
            recent_errors = log_aggregator.get_recent_errors(limit=10)
            errors_data = []
            for error in recent_errors:
                errors_data.append({
                    'timestamp': error.get('timestamp', ''),
                    'error_type': error.get('error_type', 'unknown'),
                    'endpoint': error.get('endpoint', 'unknown'),
                    'message': error.get('message', '')[:100] + '...' if len(error.get('message', '')) > 100 else error.get('message', '')
                })
            
            self.widgets['recent_errors'] = DashboardWidget(
                widget_id='recent_errors',
                title='Recent Errors',
                widget_type='table',
                data=errors_data,
                config={'columns': ['timestamp', 'error_type', 'endpoint', 'message']},
                last_updated=datetime.utcnow()
            )
            
            # Log statistics
            self.widgets['log_stats'] = DashboardWidget(
                widget_id='log_stats',
                title='Log Statistics',
                widget_type='metric',
                data=[
                    DashboardMetric(
                        name='Total Logs Processed',
                        value=log_stats['total_logs_processed'],
                        unit='logs',
                        status='good'
                    ),
                    DashboardMetric(
                        name='Recent Errors',
                        value=log_stats['recent_errors_count'],
                        unit='errors',
                        status='critical' if log_stats['recent_errors_count'] > 10 else 'good'
                    ),
                    DashboardMetric(
                        name='Slow Requests',
                        value=log_stats['slow_requests_count'],
                        unit='requests',
                        status='warning' if log_stats['slow_requests_count'] > 5 else 'good'
                    )
                ],
                config={},
                last_updated=datetime.utcnow()
            )
            
        except Exception as e:
            logger.error(f"Failed to refresh logs widgets: {str(e)}")
    
    def get_dashboard_data(self) -> Dict[str, Any]:
        """Get complete dashboard data"""
        dashboard_data = {
            'timestamp': datetime.utcnow().isoformat() + 'Z',
            'widgets': {}
        }
        
        for widget_id, widget in self.widgets.items():
            dashboard_data['widgets'][widget_id] = {
                'widget_id': widget.widget_id,
                'title': widget.title,
                'widget_type': widget.widget_type,
                'data': self._serialize_widget_data(widget.data),
                'config': widget.config,
                'last_updated': widget.last_updated.isoformat() + 'Z'
            }
        
        return dashboard_data
    
    def _serialize_widget_data(self, data: Any) -> Any:
        """Serialize widget data for JSON output"""
        if isinstance(data, list) and len(data) > 0 and isinstance(data[0], DashboardMetric):
            return [asdict(metric) for metric in data]
        elif hasattr(data, '__dict__'):
            return asdict(data)
        else:
            return data
    
    def get_widget_data(self, widget_id: str) -> Optional[Dict[str, Any]]:
        """Get data for a specific widget"""
        if widget_id not in self.widgets:
            return None
        
        widget = self.widgets[widget_id]
        return {
            'widget_id': widget.widget_id,
            'title': widget.title,
            'widget_type': widget.widget_type,
            'data': self._serialize_widget_data(widget.data),
            'config': widget.config,
            'last_updated': widget.last_updated.isoformat() + 'Z'
        }
    
    async def get_dashboard_summary(self) -> Dict[str, Any]:
        """Get high-level dashboard summary"""
        try:
            # Get latest data
            health_report = await health_checker.run_all_checks(include_details=False)
            perf_summary = metrics_collector.get_performance_summary()
            alert_status = alert_manager.get_alert_status()
            log_stats = log_aggregator.get_aggregation_stats()
            
            return {
                'timestamp': datetime.utcnow().isoformat() + 'Z',
                'overall_status': health_report.overall_status.value,
                'summary': {
                    'health': {
                        'status': health_report.overall_status.value,
                        'checks_total': len(health_report.checks),
                        'checks_healthy': sum(1 for check in health_report.checks 
                                            if check.status.value == 'healthy')
                    },
                    'performance': {
                        'total_requests': perf_summary['requests']['total'],
                        'error_rate_percent': round(perf_summary['requests']['error_rate'], 2),
                        'avg_response_time_ms': round(perf_summary['requests']['avg_duration_ms'], 2),
                        'active_connections': perf_summary['system']['active_connections']
                    },
                    'alerts': {
                        'active_alerts': alert_status['active_alerts'],
                        'total_rules': alert_status['total_rules'],
                        'enabled_rules': alert_status['enabled_rules']
                    },
                    'logs': {
                        'total_processed': log_stats['total_logs_processed'],
                        'recent_errors': log_stats['recent_errors_count'],
                        'slow_requests': log_stats['slow_requests_count']
                    }
                }
            }
            
        except Exception as e:
            logger.error(f"Failed to get dashboard summary: {str(e)}")
            return {
                'timestamp': datetime.utcnow().isoformat() + 'Z',
                'overall_status': 'error',
                'error': str(e)
            }

# Global dashboard instance
monitoring_dashboard = MonitoringDashboard()