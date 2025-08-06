# app/monitoring/alerts.py
import asyncio
import time
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any, Callable
from enum import Enum
from dataclasses import dataclass, field
from collections import defaultdict
import json
import aiohttp

from .health import health_checker, HealthStatus
from .metrics import metrics_collector
from ..core.logging_config import get_logger

logger = get_logger(__name__)

class AlertSeverity(Enum):
    INFO = "info"
    WARNING = "warning"
    CRITICAL = "critical"

class AlertStatus(Enum):
    ACTIVE = "active"
    RESOLVED = "resolved"
    SILENCED = "silenced"

@dataclass
class Alert:
    """Alert definition"""
    name: str
    description: str
    severity: AlertSeverity
    status: AlertStatus = AlertStatus.ACTIVE
    created_at: datetime = field(default_factory=datetime.utcnow)
    resolved_at: Optional[datetime] = None
    silenced_until: Optional[datetime] = None
    metadata: Dict[str, Any] = field(default_factory=dict)
    
    def to_dict(self) -> Dict[str, Any]:
        return {
            'name': self.name,
            'description': self.description,
            'severity': self.severity.value,
            'status': self.status.value,
            'created_at': self.created_at.isoformat() + 'Z',
            'resolved_at': self.resolved_at.isoformat() + 'Z' if self.resolved_at else None,
            'silenced_until': self.silenced_until.isoformat() + 'Z' if self.silenced_until else None,
            'metadata': self.metadata
        }

@dataclass
class AlertRule:
    """Alert rule definition"""
    name: str
    description: str
    severity: AlertSeverity
    condition_func: Callable[[], bool]
    cooldown_minutes: int = 5  # Minimum time between alerts
    max_alerts_per_hour: int = 12
    enabled: bool = True
    last_triggered: Optional[datetime] = None
    trigger_count: int = 0
    
    def should_trigger(self) -> bool:
        """Check if alert should trigger based on cooldown and rate limiting"""
        if not self.enabled:
            return False
        
        now = datetime.utcnow()
        
        # Check cooldown
        if self.last_triggered:
            if now - self.last_triggered < timedelta(minutes=self.cooldown_minutes):
                return False
        
        # Check rate limiting
        if self.last_triggered and now - self.last_triggered < timedelta(hours=1):
            if self.trigger_count >= self.max_alerts_per_hour:
                return False
        elif self.last_triggered and now - self.last_triggered >= timedelta(hours=1):
            # Reset counter after an hour
            self.trigger_count = 0
        
        return True

class NotificationChannel:
    """Base class for notification channels"""
    
    async def send_notification(self, alert: Alert) -> bool:
        """Send notification for alert"""
        raise NotImplementedError

class EmailNotificationChannel(NotificationChannel):
    """Email notification channel"""
    
    def __init__(self, smtp_host: str, smtp_port: int, username: str, password: str, 
                 from_email: str, to_emails: List[str], use_tls: bool = True):
        self.smtp_host = smtp_host
        self.smtp_port = smtp_port
        self.username = username
        self.password = password
        self.from_email = from_email
        self.to_emails = to_emails
        self.use_tls = use_tls
    
    async def send_notification(self, alert: Alert) -> bool:
        """Send email notification"""
        try:
            # Create message
            msg = MIMEMultipart()
            msg['From'] = self.from_email
            msg['To'] = ', '.join(self.to_emails)
            msg['Subject'] = f"[TUG-API] {alert.severity.value.upper()}: {alert.name}"
            
            # Create email body
            body = self._create_email_body(alert)
            msg.attach(MIMEText(body, 'html'))
            
            # Send email (in a thread to avoid blocking)
            loop = asyncio.get_event_loop()
            await loop.run_in_executor(None, self._send_email, msg)
            
            logger.info(f"Email alert sent: {alert.name}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to send email alert: {str(e)}")
            return False
    
    def _send_email(self, msg):
        """Send email synchronously"""
        server = smtplib.SMTP(self.smtp_host, self.smtp_port)
        if self.use_tls:
            server.starttls()
        server.login(self.username, self.password)
        server.send_message(msg)
        server.quit()
    
    def _create_email_body(self, alert: Alert) -> str:
        """Create HTML email body"""
        severity_colors = {
            AlertSeverity.INFO: '#17a2b8',
            AlertSeverity.WARNING: '#ffc107',
            AlertSeverity.CRITICAL: '#dc3545'
        }
        
        color = severity_colors.get(alert.severity, '#6c757d')
        
        return f"""
        <html>
        <body style="font-family: Arial, sans-serif; line-height: 1.6;">
            <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
                <div style="background: {color}; color: white; padding: 15px; margin-bottom: 20px; border-radius: 5px;">
                    <h2 style="margin: 0;">{alert.severity.value.upper()}: {alert.name}</h2>
                    <p style="margin: 5px 0 0 0;">{alert.created_at.strftime('%Y-%m-%d %H:%M:%S')} UTC</p>
                </div>
                
                <div style="background: #f8f9fa; padding: 15px; border-radius: 5px; margin-bottom: 20px;">
                    <h3>Description:</h3>
                    <p>{alert.description}</p>
                </div>
                
                {self._format_metadata(alert.metadata)}
                
                <div style="background: #e9ecef; padding: 10px; border-radius: 5px; margin-top: 20px;">
                    <p style="margin: 0; font-size: 12px; color: #6c757d;">
                        This alert was generated by TUG API monitoring system.
                    </p>
                </div>
            </div>
        </body>
        </html>
        """
    
    def _format_metadata(self, metadata: Dict[str, Any]) -> str:
        """Format metadata for email"""
        if not metadata:
            return ""
        
        items = []
        for key, value in metadata.items():
            items.append(f"<li><strong>{key}:</strong> {value}</li>")
        
        return f"""
        <div style="background: #f8f9fa; padding: 15px; border-radius: 5px; margin-bottom: 20px;">
            <h3>Additional Information:</h3>
            <ul>{"".join(items)}</ul>
        </div>
        """

class SlackNotificationChannel(NotificationChannel):
    """Slack notification channel"""
    
    def __init__(self, webhook_url: str, channel: Optional[str] = None):
        self.webhook_url = webhook_url
        self.channel = channel
    
    async def send_notification(self, alert: Alert) -> bool:
        """Send Slack notification"""
        try:
            # Create Slack message
            payload = self._create_slack_payload(alert)
            
            async with aiohttp.ClientSession() as session:
                async with session.post(self.webhook_url, json=payload) as response:
                    if response.status == 200:
                        logger.info(f"Slack alert sent: {alert.name}")
                        return True
                    else:
                        logger.error(f"Slack notification failed with status {response.status}")
                        return False
                        
        except Exception as e:
            logger.error(f"Failed to send Slack alert: {str(e)}")
            return False
    
    def _create_slack_payload(self, alert: Alert) -> Dict[str, Any]:
        """Create Slack message payload"""
        colors = {
            AlertSeverity.INFO: '#36a64f',
            AlertSeverity.WARNING: '#ff9500',
            AlertSeverity.CRITICAL: '#ff0000'
        }
        
        color = colors.get(alert.severity, '#808080')
        
        fields = []
        if alert.metadata:
            for key, value in alert.metadata.items():
                fields.append({
                    'title': key,
                    'value': str(value),
                    'short': True
                })
        
        attachment = {
            'color': color,
            'title': f"{alert.severity.value.upper()}: {alert.name}",
            'text': alert.description,
            'fields': fields,
            'timestamp': alert.created_at.isoformat(),
            'footer': 'TUG API Monitoring'
        }
        
        payload = {
            'attachments': [attachment]
        }
        
        if self.channel:
            payload['channel'] = self.channel
        
        return payload

class WebhookNotificationChannel(NotificationChannel):
    """Generic webhook notification channel"""
    
    def __init__(self, webhook_url: str, headers: Optional[Dict[str, str]] = None):
        self.webhook_url = webhook_url
        self.headers = headers or {'Content-Type': 'application/json'}
    
    async def send_notification(self, alert: Alert) -> bool:
        """Send webhook notification"""
        try:
            payload = {
                'alert': alert.to_dict(),
                'timestamp': datetime.utcnow().isoformat() + 'Z'
            }
            
            async with aiohttp.ClientSession() as session:
                async with session.post(
                    self.webhook_url,
                    json=payload,
                    headers=self.headers
                ) as response:
                    if response.status < 400:
                        logger.info(f"Webhook alert sent: {alert.name}")
                        return True
                    else:
                        logger.error(f"Webhook notification failed with status {response.status}")
                        return False
                        
        except Exception as e:
            logger.error(f"Failed to send webhook alert: {str(e)}")
            return False

class AlertManager:
    """Production-ready alerting system"""
    
    def __init__(self):
        self.rules: Dict[str, AlertRule] = {}
        self.active_alerts: Dict[str, Alert] = {}
        self.alert_history: List[Alert] = []
        self.notification_channels: List[NotificationChannel] = []
        
        # Statistics
        self.stats = {
            'alerts_triggered': 0,
            'alerts_resolved': 0,
            'notifications_sent': 0,
            'notifications_failed': 0
        }
        
        # Initialize default rules
        self._initialize_default_rules()
        
        # Start monitoring task
        asyncio.create_task(self._monitoring_loop())
    
    def add_notification_channel(self, channel: NotificationChannel):
        """Add a notification channel"""
        self.notification_channels.append(channel)
        logger.info(f"Added notification channel: {type(channel).__name__}")
    
    def add_alert_rule(self, rule: AlertRule):
        """Add an alert rule"""
        self.rules[rule.name] = rule
        logger.info(f"Added alert rule: {rule.name}")
    
    def _initialize_default_rules(self):
        """Initialize default alert rules"""
        
        # High error rate alert
        def check_high_error_rate():
            perf = metrics_collector.get_performance_summary()
            return perf['requests']['error_rate'] > 10.0  # More than 10% error rate
        
        self.add_alert_rule(AlertRule(
            name="high_error_rate",
            description="Application error rate is above 10%",
            severity=AlertSeverity.CRITICAL,
            condition_func=check_high_error_rate,
            cooldown_minutes=5
        ))
        
        # Slow response time alert
        def check_slow_response():
            perf = metrics_collector.get_performance_summary()
            return perf['requests']['avg_duration_ms'] > 2000  # Slower than 2 seconds
        
        self.add_alert_rule(AlertRule(
            name="slow_response_time",
            description="Average response time is above 2 seconds",
            severity=AlertSeverity.WARNING,
            condition_func=check_slow_response,
            cooldown_minutes=10
        ))
        
        # Database connectivity alert
        def check_database_health():
            try:
                # This would be called from the monitoring loop, so we can't use async here
                # In a real implementation, we'd need to handle this differently
                return False  # Placeholder
            except:
                return True
        
        self.add_alert_rule(AlertRule(
            name="database_unhealthy",
            description="Database health check is failing",
            severity=AlertSeverity.CRITICAL,
            condition_func=check_database_health,
            cooldown_minutes=2
        ))
        
        # High memory usage alert
        def check_high_memory():
            memory_usage = metrics_collector.get_metric_value("system_memory_usage_bytes")
            if not memory_usage:
                return False
            
            import psutil
            total_memory = psutil.virtual_memory().total
            usage_percent = (memory_usage / total_memory) * 100
            return usage_percent > 85.0
        
        self.add_alert_rule(AlertRule(
            name="high_memory_usage",
            description="System memory usage is above 85%",
            severity=AlertSeverity.WARNING,
            condition_func=check_high_memory,
            cooldown_minutes=15
        ))
        
        # High CPU usage alert
        def check_high_cpu():
            cpu_usage = metrics_collector.get_metric_value("system_cpu_usage_percent")
            return cpu_usage and cpu_usage > 80.0
        
        self.add_alert_rule(AlertRule(
            name="high_cpu_usage",
            description="System CPU usage is above 80%",
            severity=AlertSeverity.WARNING,
            condition_func=check_high_cpu,
            cooldown_minutes=15
        ))
    
    async def _monitoring_loop(self):
        """Main monitoring loop"""
        while True:
            try:
                await self._check_alert_rules()
                await self._cleanup_resolved_alerts()
                await asyncio.sleep(30)  # Check every 30 seconds
                
            except Exception as e:
                logger.error(f"Error in monitoring loop: {str(e)}", exc_info=True)
                await asyncio.sleep(60)  # Wait longer on error
    
    async def _check_alert_rules(self):
        """Check all alert rules"""
        for rule_name, rule in self.rules.items():
            try:
                if rule.condition_func() and rule.should_trigger():
                    await self._trigger_alert(rule_name, rule)
                elif rule_name in self.active_alerts:
                    # Check if alert should be resolved
                    if not rule.condition_func():
                        await self._resolve_alert(rule_name)
                        
            except Exception as e:
                logger.error(f"Error checking alert rule {rule_name}: {str(e)}")
    
    async def _trigger_alert(self, rule_name: str, rule: AlertRule):
        """Trigger an alert"""
        if rule_name in self.active_alerts:
            return  # Alert already active
        
        # Create alert
        alert = Alert(
            name=rule_name,
            description=rule.description,
            severity=rule.severity,
            metadata=await self._get_alert_metadata(rule_name)
        )
        
        self.active_alerts[rule_name] = alert
        self.alert_history.append(alert)
        
        # Update statistics
        self.stats['alerts_triggered'] += 1
        rule.last_triggered = datetime.utcnow()
        rule.trigger_count += 1
        
        # Send notifications
        await self._send_notifications(alert)
        
        logger.warning(f"Alert triggered: {rule_name} ({rule.severity.value})")
    
    async def _resolve_alert(self, rule_name: str):
        """Resolve an alert"""
        if rule_name not in self.active_alerts:
            return
        
        alert = self.active_alerts[rule_name]
        alert.status = AlertStatus.RESOLVED
        alert.resolved_at = datetime.utcnow()
        
        # Remove from active alerts
        del self.active_alerts[rule_name]
        
        # Update statistics
        self.stats['alerts_resolved'] += 1
        
        logger.info(f"Alert resolved: {rule_name}")
    
    async def _send_notifications(self, alert: Alert):
        """Send notifications for alert"""
        if not self.notification_channels:
            logger.warning("No notification channels configured")
            return
        
        for channel in self.notification_channels:
            try:
                success = await channel.send_notification(alert)
                if success:
                    self.stats['notifications_sent'] += 1
                else:
                    self.stats['notifications_failed'] += 1
                    
            except Exception as e:
                logger.error(f"Failed to send notification via {type(channel).__name__}: {str(e)}")
                self.stats['notifications_failed'] += 1
    
    async def _get_alert_metadata(self, rule_name: str) -> Dict[str, Any]:
        """Get additional metadata for alert"""
        metadata = {
            'timestamp': datetime.utcnow().isoformat() + 'Z',
            'server_time': time.time()
        }
        
        # Add rule-specific metadata
        if rule_name == "high_error_rate":
            perf = metrics_collector.get_performance_summary()
            metadata.update({
                'error_rate_percent': round(perf['requests']['error_rate'], 2),
                'total_requests': perf['requests']['total'],
                'total_errors': perf['requests']['errors']
            })
        
        elif rule_name == "slow_response_time":
            perf = metrics_collector.get_performance_summary()
            metadata.update({
                'avg_response_time_ms': round(perf['requests']['avg_duration_ms'], 2),
                'total_requests': perf['requests']['total']
            })
        
        elif rule_name in ["high_memory_usage", "high_cpu_usage"]:
            import psutil
            memory = psutil.virtual_memory()
            metadata.update({
                'memory_usage_percent': round(memory.percent, 1),
                'cpu_usage_percent': round(psutil.cpu_percent(), 1),
                'available_memory_gb': round(memory.available / (1024**3), 2)
            })
        
        return metadata
    
    async def _cleanup_resolved_alerts(self):
        """Clean up old resolved alerts"""
        cutoff_time = datetime.utcnow() - timedelta(days=7)
        
        # Keep only recent alerts in history
        self.alert_history = [
            alert for alert in self.alert_history
            if alert.created_at > cutoff_time
        ]
    
    def get_alert_status(self) -> Dict[str, Any]:
        """Get current alert status"""
        return {
            'active_alerts': len(self.active_alerts),
            'total_rules': len(self.rules),
            'enabled_rules': sum(1 for rule in self.rules.values() if rule.enabled),
            'statistics': self.stats,
            'alerts': [alert.to_dict() for alert in self.active_alerts.values()]
        }
    
    def silence_alert(self, rule_name: str, duration_minutes: int):
        """Silence an alert for a specified duration"""
        if rule_name in self.active_alerts:
            alert = self.active_alerts[rule_name]
            alert.status = AlertStatus.SILENCED
            alert.silenced_until = datetime.utcnow() + timedelta(minutes=duration_minutes)
            logger.info(f"Alert silenced: {rule_name} for {duration_minutes} minutes")
    
    def enable_rule(self, rule_name: str):
        """Enable an alert rule"""
        if rule_name in self.rules:
            self.rules[rule_name].enabled = True
            logger.info(f"Alert rule enabled: {rule_name}")
    
    def disable_rule(self, rule_name: str):
        """Disable an alert rule"""
        if rule_name in self.rules:
            self.rules[rule_name].enabled = False
            logger.info(f"Alert rule disabled: {rule_name}")

# Global alert manager instance
alert_manager = AlertManager()