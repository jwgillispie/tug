# app/monitoring/deployment_monitor.py
import asyncio
import time
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any, Callable
from dataclasses import dataclass, field
from enum import Enum
import aiohttp
import json

from .health import health_checker
from .metrics import metrics_collector
from .alerts import alert_manager, AlertSeverity
from ..core.logging_config import get_logger

logger = get_logger(__name__)

class DeploymentStatus(Enum):
    PENDING = "pending"
    IN_PROGRESS = "in_progress"
    SUCCESS = "success"
    FAILED = "failed"
    ROLLING_BACK = "rolling_back"
    ROLLED_BACK = "rolled_back"

class HealthCheckResult(Enum):
    PASS = "pass"
    FAIL = "fail"
    TIMEOUT = "timeout"

@dataclass
class DeploymentConfig:
    """Deployment configuration and thresholds"""
    deployment_id: str
    version: str
    environment: str
    health_check_url: str
    rollback_url: Optional[str] = None
    
    # Health check configuration
    health_check_timeout_seconds: int = 30
    health_check_retries: int = 3
    health_check_interval_seconds: int = 10
    
    # Performance thresholds
    max_error_rate_percent: float = 5.0
    max_response_time_ms: float = 2000.0
    min_success_rate_percent: float = 95.0
    
    # Monitoring duration
    monitoring_duration_minutes: int = 15
    warmup_duration_minutes: int = 5
    
    # Rollback configuration
    auto_rollback_enabled: bool = True
    rollback_on_health_check_failure: bool = True
    rollback_on_performance_degradation: bool = True
    
    # Notification configuration
    notify_on_deployment: bool = True
    notify_on_rollback: bool = True

@dataclass
class DeploymentMetrics:
    """Deployment monitoring metrics"""
    start_time: datetime
    end_time: Optional[datetime] = None
    health_checks_passed: int = 0
    health_checks_failed: int = 0
    total_requests: int = 0
    successful_requests: int = 0
    failed_requests: int = 0
    avg_response_time_ms: float = 0.0
    error_rate_percent: float = 0.0
    success_rate_percent: float = 100.0
    
    def update_from_metrics(self, metrics_data: Dict[str, Any]):
        """Update metrics from monitoring data"""
        perf = metrics_data.get('requests', {})
        self.total_requests = perf.get('total', 0)
        self.failed_requests = perf.get('errors', 0)
        self.successful_requests = self.total_requests - self.failed_requests
        self.error_rate_percent = perf.get('error_rate', 0.0)
        self.success_rate_percent = 100.0 - self.error_rate_percent
        self.avg_response_time_ms = perf.get('avg_duration_ms', 0.0)

@dataclass
class DeploymentRecord:
    """Record of a deployment monitoring session"""
    config: DeploymentConfig
    status: DeploymentStatus
    metrics: DeploymentMetrics
    created_at: datetime = field(default_factory=datetime.utcnow)
    completed_at: Optional[datetime] = None
    rollback_triggered_at: Optional[datetime] = None
    rollback_reason: Optional[str] = None
    health_check_results: List[Dict[str, Any]] = field(default_factory=list)
    performance_snapshots: List[Dict[str, Any]] = field(default_factory=list)
    alerts_triggered: List[str] = field(default_factory=list)

class DeploymentMonitor:
    """Production deployment monitoring and rollback system"""
    
    def __init__(self):
        self.active_deployments: Dict[str, DeploymentRecord] = {}
        self.deployment_history: List[DeploymentRecord] = []
        self.rollback_handlers: Dict[str, Callable] = {}
        
        # Baseline metrics for comparison
        self.baseline_metrics: Optional[Dict[str, Any]] = None
        self.baseline_established_at: Optional[datetime] = None
    
    def register_rollback_handler(self, environment: str, handler: Callable):
        """Register a rollback handler for an environment"""
        self.rollback_handlers[environment] = handler
        logger.info(f"Registered rollback handler for environment: {environment}")
    
    async def start_deployment_monitoring(self, config: DeploymentConfig) -> str:
        """Start monitoring a new deployment"""
        deployment_record = DeploymentRecord(
            config=config,
            status=DeploymentStatus.PENDING,
            metrics=DeploymentMetrics(start_time=datetime.utcnow())
        )
        
        self.active_deployments[config.deployment_id] = deployment_record
        
        logger.info(
            f"Started deployment monitoring: {config.deployment_id} "
            f"(version: {config.version}, environment: {config.environment})"
        )
        
        # Start monitoring task
        asyncio.create_task(self._monitor_deployment(config.deployment_id))
        
        # Send deployment notification
        if config.notify_on_deployment:
            await self._send_deployment_notification(deployment_record, "started")
        
        return config.deployment_id
    
    async def _monitor_deployment(self, deployment_id: str):
        """Main deployment monitoring loop"""
        try:
            record = self.active_deployments[deployment_id]
            config = record.config
            
            # Update status
            record.status = DeploymentStatus.IN_PROGRESS
            
            # Wait for warmup period
            logger.info(f"Deployment {deployment_id}: Starting warmup period ({config.warmup_duration_minutes} minutes)")
            await asyncio.sleep(config.warmup_duration_minutes * 60)
            
            # Establish baseline if not exists
            if not self.baseline_metrics:
                await self._establish_baseline()
            
            # Start monitoring loop
            monitoring_start = datetime.utcnow()
            monitoring_end = monitoring_start + timedelta(minutes=config.monitoring_duration_minutes)
            
            logger.info(f"Deployment {deployment_id}: Starting active monitoring for {config.monitoring_duration_minutes} minutes")
            
            while datetime.utcnow() < monitoring_end:
                # Perform health check
                health_result = await self._perform_health_check(config)
                record.health_check_results.append(health_result)
                
                if health_result['result'] == HealthCheckResult.PASS.value:
                    record.metrics.health_checks_passed += 1
                else:
                    record.metrics.health_checks_failed += 1
                    
                    # Check if rollback should be triggered
                    if config.rollback_on_health_check_failure and record.metrics.health_checks_failed >= config.health_check_retries:
                        await self._trigger_rollback(deployment_id, f"Health check failures: {record.metrics.health_checks_failed}")
                        return
                
                # Collect performance metrics
                performance_snapshot = await self._collect_performance_snapshot()
                record.performance_snapshots.append(performance_snapshot)
                record.metrics.update_from_metrics(performance_snapshot)
                
                # Check performance thresholds
                if config.rollback_on_performance_degradation:
                    if await self._check_performance_degradation(record, config):
                        return  # Rollback was triggered
                
                # Wait before next check
                await asyncio.sleep(config.health_check_interval_seconds)
            
            # Monitoring completed successfully
            record.status = DeploymentStatus.SUCCESS
            record.completed_at = datetime.utcnow()
            record.metrics.end_time = record.completed_at
            
            logger.info(f"Deployment {deployment_id}: Monitoring completed successfully")
            
            # Move to history
            self._archive_deployment(deployment_id)
            
        except Exception as e:
            logger.error(f"Error monitoring deployment {deployment_id}: {str(e)}", exc_info=True)
            if deployment_id in self.active_deployments:
                await self._trigger_rollback(deployment_id, f"Monitoring error: {str(e)}")
    
    async def _perform_health_check(self, config: DeploymentConfig) -> Dict[str, Any]:
        """Perform health check for deployment"""
        result = {
            'timestamp': datetime.utcnow().isoformat(),
            'url': config.health_check_url,
            'result': HealthCheckResult.FAIL.value,
            'response_time_ms': 0.0,
            'status_code': None,
            'error': None
        }
        
        start_time = time.time()
        
        try:
            timeout = aiohttp.ClientTimeout(total=config.health_check_timeout_seconds)
            async with aiohttp.ClientSession(timeout=timeout) as session:
                async with session.get(config.health_check_url) as response:
                    result['response_time_ms'] = (time.time() - start_time) * 1000
                    result['status_code'] = response.status
                    
                    if response.status == 200:
                        result['result'] = HealthCheckResult.PASS.value
                    else:
                        result['error'] = f"HTTP {response.status}"
                        
        except asyncio.TimeoutError:
            result['result'] = HealthCheckResult.TIMEOUT.value
            result['error'] = "Request timeout"
            result['response_time_ms'] = config.health_check_timeout_seconds * 1000
            
        except Exception as e:
            result['error'] = str(e)
            result['response_time_ms'] = (time.time() - start_time) * 1000
        
        return result
    
    async def _collect_performance_snapshot(self) -> Dict[str, Any]:
        """Collect current performance metrics snapshot"""
        try:
            performance_data = metrics_collector.get_performance_summary()
            
            return {
                'timestamp': datetime.utcnow().isoformat(),
                'requests': performance_data['requests'],
                'system': performance_data['system'],
                'database': performance_data.get('database', {})
            }
            
        except Exception as e:
            logger.error(f"Failed to collect performance snapshot: {str(e)}")
            return {
                'timestamp': datetime.utcnow().isoformat(),
                'error': str(e)
            }
    
    async def _check_performance_degradation(self, record: DeploymentRecord, config: DeploymentConfig) -> bool:
        """Check if performance has degraded beyond acceptable thresholds"""
        metrics = record.metrics
        
        # Check error rate
        if metrics.error_rate_percent > config.max_error_rate_percent:
            await self._trigger_rollback(
                config.deployment_id,
                f"Error rate too high: {metrics.error_rate_percent:.2f}% > {config.max_error_rate_percent}%"
            )
            return True
        
        # Check response time
        if metrics.avg_response_time_ms > config.max_response_time_ms:
            await self._trigger_rollback(
                config.deployment_id,
                f"Response time too slow: {metrics.avg_response_time_ms:.2f}ms > {config.max_response_time_ms}ms"
            )
            return True
        
        # Check success rate
        if metrics.success_rate_percent < config.min_success_rate_percent:
            await self._trigger_rollback(
                config.deployment_id,
                f"Success rate too low: {metrics.success_rate_percent:.2f}% < {config.min_success_rate_percent}%"
            )
            return True
        
        # Compare with baseline if available
        if self.baseline_metrics and await self._compare_with_baseline(metrics):
            await self._trigger_rollback(
                config.deployment_id,
                "Performance significantly worse than baseline"
            )
            return True
        
        return False
    
    async def _compare_with_baseline(self, current_metrics: DeploymentMetrics) -> bool:
        """Compare current metrics with baseline to detect degradation"""
        if not self.baseline_metrics:
            return False
        
        baseline_error_rate = self.baseline_metrics.get('requests', {}).get('error_rate', 0.0)
        baseline_response_time = self.baseline_metrics.get('requests', {}).get('avg_duration_ms', 1000.0)
        
        # Check if error rate increased significantly
        if current_metrics.error_rate_percent > baseline_error_rate * 2.0:  # 2x increase
            logger.warning(f"Error rate increased significantly: {current_metrics.error_rate_percent:.2f}% vs baseline {baseline_error_rate:.2f}%")
            return True
        
        # Check if response time increased significantly
        if current_metrics.avg_response_time_ms > baseline_response_time * 1.5:  # 50% increase
            logger.warning(f"Response time increased significantly: {current_metrics.avg_response_time_ms:.2f}ms vs baseline {baseline_response_time:.2f}ms")
            return True
        
        return False
    
    async def _establish_baseline(self):
        """Establish performance baseline for comparison"""
        try:
            # Collect metrics over a short period to establish baseline
            logger.info("Establishing performance baseline...")
            
            snapshots = []
            for _ in range(5):  # Collect 5 snapshots over 50 seconds
                snapshot = await self._collect_performance_snapshot()
                snapshots.append(snapshot)
                await asyncio.sleep(10)
            
            # Calculate baseline averages
            total_error_rate = sum(s.get('requests', {}).get('error_rate', 0.0) for s in snapshots)
            total_response_time = sum(s.get('requests', {}).get('avg_duration_ms', 0.0) for s in snapshots)
            
            self.baseline_metrics = {
                'requests': {
                    'error_rate': total_error_rate / len(snapshots),
                    'avg_duration_ms': total_response_time / len(snapshots)
                }
            }
            self.baseline_established_at = datetime.utcnow()
            
            logger.info(f"Baseline established: error_rate={self.baseline_metrics['requests']['error_rate']:.2f}%, "
                       f"avg_response_time={self.baseline_metrics['requests']['avg_duration_ms']:.2f}ms")
            
        except Exception as e:
            logger.error(f"Failed to establish baseline: {str(e)}")
    
    async def _trigger_rollback(self, deployment_id: str, reason: str):
        """Trigger rollback for a deployment"""
        if deployment_id not in self.active_deployments:
            logger.error(f"Cannot rollback unknown deployment: {deployment_id}")
            return
        
        record = self.active_deployments[deployment_id]
        config = record.config
        
        if not config.auto_rollback_enabled:
            logger.warning(f"Auto-rollback disabled for deployment {deployment_id}. Manual intervention required.")
            record.status = DeploymentStatus.FAILED
            record.rollback_reason = f"Auto-rollback disabled. {reason}"
            return
        
        logger.warning(f"Triggering rollback for deployment {deployment_id}: {reason}")
        
        record.status = DeploymentStatus.ROLLING_BACK
        record.rollback_triggered_at = datetime.utcnow()
        record.rollback_reason = reason
        
        try:
            # Execute rollback
            if config.environment in self.rollback_handlers:
                handler = self.rollback_handlers[config.environment]
                await handler(deployment_id, config, reason)
            elif config.rollback_url:
                await self._execute_webhook_rollback(config, reason)
            else:
                logger.error(f"No rollback mechanism configured for deployment {deployment_id}")
                record.status = DeploymentStatus.FAILED
                return
            
            record.status = DeploymentStatus.ROLLED_BACK
            record.completed_at = datetime.utcnow()
            record.metrics.end_time = record.completed_at
            
            # Create alert
            await alert_manager._trigger_alert(
                f"deployment_rollback_{deployment_id}",
                type('AlertRule', (), {
                    'name': f"deployment_rollback_{deployment_id}",
                    'description': f"Deployment {deployment_id} was rolled back: {reason}",
                    'severity': AlertSeverity.CRITICAL
                })()
            )
            
            # Send notification
            if config.notify_on_rollback:
                await self._send_deployment_notification(record, "rolled_back")
            
            logger.info(f"Rollback completed for deployment {deployment_id}")
            
        except Exception as e:
            logger.error(f"Rollback failed for deployment {deployment_id}: {str(e)}", exc_info=True)
            record.status = DeploymentStatus.FAILED
        
        finally:
            # Move to history
            self._archive_deployment(deployment_id)
    
    async def _execute_webhook_rollback(self, config: DeploymentConfig, reason: str):
        """Execute rollback via webhook"""
        if not config.rollback_url:
            raise ValueError("No rollback URL configured")
        
        payload = {
            'deployment_id': config.deployment_id,
            'version': config.version,
            'environment': config.environment,
            'reason': reason,
            'timestamp': datetime.utcnow().isoformat()
        }
        
        async with aiohttp.ClientSession() as session:
            async with session.post(
                config.rollback_url,
                json=payload,
                headers={'Content-Type': 'application/json'}
            ) as response:
                if response.status >= 400:
                    raise Exception(f"Rollback webhook failed with status {response.status}")
    
    async def _send_deployment_notification(self, record: DeploymentRecord, event_type: str):
        """Send deployment notification"""
        # This would integrate with the alert manager's notification system
        message = f"Deployment {record.config.deployment_id} {event_type}"
        if event_type == "rolled_back":
            message += f": {record.rollback_reason}"
        
        logger.info(f"Deployment notification: {message}")
    
    def _archive_deployment(self, deployment_id: str):
        """Move deployment from active to history"""
        if deployment_id in self.active_deployments:
            record = self.active_deployments.pop(deployment_id)
            self.deployment_history.append(record)
            
            # Keep only recent history (last 100 deployments)
            if len(self.deployment_history) > 100:
                self.deployment_history = self.deployment_history[-50:]
    
    def get_deployment_status(self, deployment_id: str) -> Optional[Dict[str, Any]]:
        """Get status of a specific deployment"""
        # Check active deployments
        if deployment_id in self.active_deployments:
            record = self.active_deployments[deployment_id]
            return self._serialize_deployment_record(record)
        
        # Check deployment history
        for record in self.deployment_history:
            if record.config.deployment_id == deployment_id:
                return self._serialize_deployment_record(record)
        
        return None
    
    def get_active_deployments(self) -> List[Dict[str, Any]]:
        """Get all active deployments"""
        return [
            self._serialize_deployment_record(record)
            for record in self.active_deployments.values()
        ]
    
    def get_deployment_history(self, limit: int = 20) -> List[Dict[str, Any]]:
        """Get deployment history"""
        recent_history = self.deployment_history[-limit:]
        return [
            self._serialize_deployment_record(record)
            for record in recent_history
        ]
    
    def _serialize_deployment_record(self, record: DeploymentRecord) -> Dict[str, Any]:
        """Serialize deployment record for API response"""
        return {
            'deployment_id': record.config.deployment_id,
            'version': record.config.version,
            'environment': record.config.environment,
            'status': record.status.value,
            'created_at': record.created_at.isoformat(),
            'completed_at': record.completed_at.isoformat() if record.completed_at else None,
            'rollback_triggered_at': record.rollback_triggered_at.isoformat() if record.rollback_triggered_at else None,
            'rollback_reason': record.rollback_reason,
            'metrics': {
                'health_checks_passed': record.metrics.health_checks_passed,
                'health_checks_failed': record.metrics.health_checks_failed,
                'total_requests': record.metrics.total_requests,
                'error_rate_percent': record.metrics.error_rate_percent,
                'success_rate_percent': record.metrics.success_rate_percent,
                'avg_response_time_ms': record.metrics.avg_response_time_ms
            },
            'alerts_triggered': record.alerts_triggered
        }

# Global deployment monitor instance
deployment_monitor = DeploymentMonitor()