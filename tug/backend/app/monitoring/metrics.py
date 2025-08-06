# app/monitoring/metrics.py
import time
import threading
from collections import defaultdict, deque
from typing import Dict, List, Optional, Any
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from enum import Enum
import asyncio
import json

from ..core.logging_config import get_logger

logger = get_logger(__name__)

class MetricType(Enum):
    COUNTER = "counter"
    GAUGE = "gauge"
    HISTOGRAM = "histogram"
    SUMMARY = "summary"

@dataclass
class MetricSample:
    """Individual metric sample"""
    value: float
    timestamp: datetime
    labels: Dict[str, str] = field(default_factory=dict)

@dataclass
class Metric:
    """Metric definition and storage"""
    name: str
    metric_type: MetricType
    help_text: str
    samples: deque = field(default_factory=lambda: deque(maxlen=1000))
    labels: Dict[str, str] = field(default_factory=dict)

class MetricsCollector:
    """Production-ready metrics collection system"""
    
    def __init__(self, retention_hours: int = 24):
        self.metrics: Dict[str, Metric] = {}
        self.retention_hours = retention_hours
        self._lock = threading.RLock()
        self.start_time = datetime.utcnow()
        
        # Performance tracking
        self.request_durations = defaultdict(lambda: deque(maxlen=1000))
        self.error_counts = defaultdict(int)
        self.request_counts = defaultdict(int)
        
        # System metrics
        self.active_connections = 0
        self.database_pool_stats = {}
        
        # Initialize default metrics
        self._initialize_default_metrics()
        
        # Start cleanup task
        asyncio.create_task(self._cleanup_task())
    
    def _initialize_default_metrics(self):
        """Initialize default application metrics"""
        
        # HTTP Request metrics
        self.register_metric(
            "http_requests_total",
            MetricType.COUNTER,
            "Total HTTP requests processed"
        )
        
        self.register_metric(
            "http_request_duration_seconds",
            MetricType.HISTOGRAM,
            "HTTP request duration in seconds"
        )
        
        self.register_metric(
            "http_requests_in_flight",
            MetricType.GAUGE,
            "Current number of HTTP requests being processed"
        )
        
        # Database metrics
        self.register_metric(
            "database_queries_total",
            MetricType.COUNTER,
            "Total database queries executed"
        )
        
        self.register_metric(
            "database_query_duration_seconds",
            MetricType.HISTOGRAM,
            "Database query duration in seconds"
        )
        
        self.register_metric(
            "database_connections_active",
            MetricType.GAUGE,
            "Current number of active database connections"
        )
        
        # Application metrics
        self.register_metric(
            "user_registrations_total",
            MetricType.COUNTER,
            "Total user registrations"
        )
        
        self.register_metric(
            "user_logins_total",
            MetricType.COUNTER,
            "Total user login attempts"
        )
        
        self.register_metric(
            "activities_created_total",
            MetricType.COUNTER,
            "Total activities created"
        )
        
        self.register_metric(
            "errors_total",
            MetricType.COUNTER,
            "Total application errors"
        )
        
        # System metrics
        self.register_metric(
            "system_memory_usage_bytes",
            MetricType.GAUGE,
            "System memory usage in bytes"
        )
        
        self.register_metric(
            "system_cpu_usage_percent",
            MetricType.GAUGE,
            "System CPU usage percentage"
        )
    
    def register_metric(self, name: str, metric_type: MetricType, help_text: str, labels: Optional[Dict[str, str]] = None):
        """Register a new metric"""
        with self._lock:
            if name not in self.metrics:
                self.metrics[name] = Metric(
                    name=name,
                    metric_type=metric_type,
                    help_text=help_text,
                    labels=labels or {}
                )
                logger.info(f"Registered metric: {name} ({metric_type.value})")
    
    def increment_counter(self, name: str, value: float = 1.0, labels: Optional[Dict[str, str]] = None):
        """Increment a counter metric"""
        self._record_sample(name, value, labels, expected_type=MetricType.COUNTER)
    
    def set_gauge(self, name: str, value: float, labels: Optional[Dict[str, str]] = None):
        """Set a gauge metric value"""
        self._record_sample(name, value, labels, expected_type=MetricType.GAUGE)
    
    def observe_histogram(self, name: str, value: float, labels: Optional[Dict[str, str]] = None):
        """Record a histogram observation"""
        self._record_sample(name, value, labels, expected_type=MetricType.HISTOGRAM)
    
    def observe_summary(self, name: str, value: float, labels: Optional[Dict[str, str]] = None):
        """Record a summary observation"""
        self._record_sample(name, value, labels, expected_type=MetricType.SUMMARY)
    
    def _record_sample(self, name: str, value: float, labels: Optional[Dict[str, str]], expected_type: MetricType):
        """Record a metric sample"""
        with self._lock:
            if name not in self.metrics:
                logger.warning(f"Metric {name} not registered, auto-registering as {expected_type.value}")
                self.register_metric(name, expected_type, f"Auto-registered metric: {name}")
            
            metric = self.metrics[name]
            if metric.metric_type != expected_type:
                logger.error(f"Metric type mismatch for {name}: expected {expected_type.value}, got {metric.metric_type.value}")
                return
            
            sample = MetricSample(
                value=value,
                timestamp=datetime.utcnow(),
                labels=labels or {}
            )
            
            metric.samples.append(sample)
    
    def get_metric_value(self, name: str, labels: Optional[Dict[str, str]] = None) -> Optional[float]:
        """Get current metric value"""
        with self._lock:
            if name not in self.metrics:
                return None
            
            metric = self.metrics[name]
            if not metric.samples:
                return None
            
            # For counters, return sum
            if metric.metric_type == MetricType.COUNTER:
                return sum(sample.value for sample in metric.samples 
                          if not labels or sample.labels == labels)
            
            # For gauges, return latest value
            elif metric.metric_type == MetricType.GAUGE:
                for sample in reversed(metric.samples):
                    if not labels or sample.labels == labels:
                        return sample.value
                return None
            
            # For histograms and summaries, return latest value
            else:
                for sample in reversed(metric.samples):
                    if not labels or sample.labels == labels:
                        return sample.value
                return None
    
    def get_metrics_summary(self) -> Dict[str, Any]:
        """Get summary of all metrics"""
        with self._lock:
            summary = {
                'timestamp': datetime.utcnow().isoformat() + 'Z',
                'uptime_seconds': (datetime.utcnow() - self.start_time).total_seconds(),
                'metrics_count': len(self.metrics),
                'metrics': {}
            }
            
            for name, metric in self.metrics.items():
                latest_value = self.get_metric_value(name)
                sample_count = len(metric.samples)
                
                summary['metrics'][name] = {
                    'type': metric.metric_type.value,
                    'help': metric.help_text,
                    'value': latest_value,
                    'sample_count': sample_count,
                    'labels': metric.labels
                }
                
                # Add additional statistics for histograms
                if metric.metric_type in [MetricType.HISTOGRAM, MetricType.SUMMARY]:
                    if metric.samples:
                        values = [s.value for s in metric.samples]
                        summary['metrics'][name].update({
                            'min': min(values),
                            'max': max(values),
                            'avg': sum(values) / len(values),
                            'p50': self._percentile(values, 50),
                            'p95': self._percentile(values, 95),
                            'p99': self._percentile(values, 99)
                        })
            
            return summary
    
    def get_prometheus_format(self) -> str:
        """Export metrics in Prometheus format"""
        with self._lock:
            lines = []
            
            for name, metric in self.metrics.items():
                # Add help text
                lines.append(f"# HELP {name} {metric.help_text}")
                lines.append(f"# TYPE {name} {metric.metric_type.value}")
                
                if metric.metric_type == MetricType.COUNTER:
                    # For counters, sum all samples
                    total = sum(sample.value for sample in metric.samples)
                    lines.append(f"{name} {total}")
                
                elif metric.metric_type == MetricType.GAUGE:
                    # For gauges, use latest value
                    if metric.samples:
                        latest = metric.samples[-1]
                        label_str = self._format_labels(latest.labels)
                        lines.append(f"{name}{label_str} {latest.value}")
                
                elif metric.metric_type in [MetricType.HISTOGRAM, MetricType.SUMMARY]:
                    # For histograms, provide basic statistics
                    if metric.samples:
                        values = [s.value for s in metric.samples]
                        lines.append(f"{name}_count {len(values)}")
                        lines.append(f"{name}_sum {sum(values)}")
                        if values:
                            lines.append(f"{name}_bucket{{le=\"0.1\"}} {len([v for v in values if v <= 0.1])}")
                            lines.append(f"{name}_bucket{{le=\"0.5\"}} {len([v for v in values if v <= 0.5])}")
                            lines.append(f"{name}_bucket{{le=\"1.0\"}} {len([v for v in values if v <= 1.0])}")
                            lines.append(f"{name}_bucket{{le=\"5.0\"}} {len([v for v in values if v <= 5.0])}")
                            lines.append(f"{name}_bucket{{le=\"+Inf\"}} {len(values)}")
                
                lines.append("")  # Empty line between metrics
            
            return "\n".join(lines)
    
    def _format_labels(self, labels: Dict[str, str]) -> str:
        """Format labels for Prometheus format"""
        if not labels:
            return ""
        
        label_parts = [f'{k}="{v}"' for k, v in labels.items()]
        return "{" + ",".join(label_parts) + "}"
    
    def _percentile(self, values: List[float], percentile: int) -> float:
        """Calculate percentile"""
        if not values:
            return 0.0
        
        sorted_values = sorted(values)
        index = int((percentile / 100.0) * len(sorted_values))
        if index >= len(sorted_values):
            index = len(sorted_values) - 1
        return sorted_values[index]
    
    async def _cleanup_task(self):
        """Periodic cleanup of old metric samples"""
        while True:
            try:
                await asyncio.sleep(3600)  # Run every hour
                await self._cleanup_old_samples()
            except Exception as e:
                logger.error(f"Error in metrics cleanup task: {str(e)}")
    
    async def _cleanup_old_samples(self):
        """Remove old metric samples beyond retention period"""
        cutoff_time = datetime.utcnow() - timedelta(hours=self.retention_hours)
        
        with self._lock:
            for metric in self.metrics.values():
                # Convert deque to list, filter, and convert back
                samples = list(metric.samples)
                recent_samples = [s for s in samples if s.timestamp > cutoff_time]
                
                metric.samples.clear()
                metric.samples.extend(recent_samples)
        
        logger.info(f"Cleaned up metric samples older than {self.retention_hours} hours")
    
    # Performance tracking helpers
    def track_request_duration(self, endpoint: str, method: str, duration_ms: float, status_code: int):
        """Track HTTP request performance"""
        labels = {
            'endpoint': endpoint,
            'method': method,
            'status_code': str(status_code)
        }
        
        # Record metrics
        self.increment_counter("http_requests_total", labels=labels)
        self.observe_histogram("http_request_duration_seconds", duration_ms / 1000.0, labels=labels)
        
        # Track in internal structures for quick access
        key = f"{method}:{endpoint}"
        self.request_durations[key].append(duration_ms)
        self.request_counts[key] += 1
        
        if status_code >= 400:
            self.error_counts[key] += 1
    
    def track_database_query(self, operation: str, collection: str, duration_ms: float, success: bool):
        """Track database query performance"""
        labels = {
            'operation': operation,
            'collection': collection,
            'success': str(success).lower()
        }
        
        self.increment_counter("database_queries_total", labels=labels)
        self.observe_histogram("database_query_duration_seconds", duration_ms / 1000.0, labels=labels)
    
    def track_user_activity(self, activity_type: str, user_id: Optional[str] = None):
        """Track user activities"""
        labels = {'activity_type': activity_type}
        if user_id:
            labels['user_id'] = user_id
        
        self.increment_counter(f"{activity_type}_total", labels=labels)
    
    def update_system_metrics(self, memory_usage: float, cpu_usage: float, active_connections: int):
        """Update system resource metrics"""
        self.set_gauge("system_memory_usage_bytes", memory_usage)
        self.set_gauge("system_cpu_usage_percent", cpu_usage)
        self.set_gauge("database_connections_active", active_connections)
        self.active_connections = active_connections
    
    def get_performance_summary(self) -> Dict[str, Any]:
        """Get performance summary for monitoring"""
        with self._lock:
            return {
                'requests': {
                    'total': sum(self.request_counts.values()),
                    'errors': sum(self.error_counts.values()),
                    'error_rate': (sum(self.error_counts.values()) / max(sum(self.request_counts.values()), 1)) * 100,
                    'avg_duration_ms': sum(sum(durations) / len(durations) for durations in self.request_durations.values() if durations) / max(len(self.request_durations), 1)
                },
                'database': self.database_pool_stats,
                'system': {
                    'active_connections': self.active_connections,
                    'uptime_seconds': (datetime.utcnow() - self.start_time).total_seconds()
                }
            }

# Global metrics collector instance
metrics_collector = MetricsCollector()