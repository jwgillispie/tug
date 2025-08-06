# TUG API - Production Monitoring & Observability System

This document describes the comprehensive monitoring and observability infrastructure implemented for the TUG API.

## Architecture Overview

The monitoring system consists of several integrated components:

1. **Health Monitoring System** - Real-time health checks and system status
2. **Metrics Collection** - Prometheus-compatible metrics collection
3. **Alerting System** - Intelligent alerting with multiple notification channels
4. **Log Aggregation** - Structured logging with rotation and retention
5. **Monitoring Dashboards** - Real-time visualization with Grafana
6. **Deployment Monitoring** - Automated deployment health checks with rollback triggers

## Components

### Health Monitoring (`app/monitoring/health.py`)

Provides comprehensive health checks for:
- Database connectivity and performance
- System resources (memory, CPU, disk)
- Network connectivity
- Application-specific health indicators

**Endpoints:**
- `GET /monitoring/health` - Comprehensive health check
- `GET /monitoring/health/live` - Kubernetes liveness probe
- `GET /monitoring/health/ready` - Kubernetes readiness probe

### Metrics Collection (`app/monitoring/metrics.py`)

Collects and aggregates metrics including:
- HTTP request metrics (rate, duration, status codes)
- Database query performance
- System resource utilization
- User activity metrics
- Application-specific metrics

**Endpoints:**
- `GET /monitoring/metrics` - Prometheus metrics format
- `GET /monitoring/metrics/json` - JSON metrics format

### Alerting System (`app/monitoring/alerts.py`)

Intelligent alerting with:
- Configurable alert rules
- Multiple notification channels (Email, Slack, Webhook)
- Rate limiting and cooldown periods
- Alert correlation and grouping

**Features:**
- High error rate detection
- Slow response time monitoring
- Resource utilization alerts
- Database connectivity alerts

### Log Aggregation (`app/monitoring/log_aggregation.py`)

Structured logging with:
- JSON log format
- Automatic log rotation
- Configurable retention policies
- Pattern analysis and anomaly detection
- Performance trend analysis

### Monitoring Dashboards (`app/monitoring/dashboard.py`)

Real-time dashboards featuring:
- System health overview
- Performance metrics
- Error tracking
- Resource utilization
- Alert status

### Deployment Monitoring (`app/monitoring/deployment_monitor.py`)

Automated deployment monitoring with:
- Health check validation
- Performance regression detection
- Automatic rollback triggers
- Deployment success/failure tracking

## Infrastructure Setup

The monitoring infrastructure is orchestrated using Docker Compose with the following services:

### Core Services

1. **Prometheus** (`:9090`) - Metrics collection and storage
2. **Grafana** (`:3000`) - Visualization and dashboards
3. **AlertManager** (`:9093`) - Alert handling and routing
4. **Loki** (`:3100`) - Log aggregation
5. **Promtail** - Log collection agent
6. **Node Exporter** (`:9100`) - System metrics
7. **Redis** (`:6379`) - Caching and session storage

### Starting the Monitoring Stack

```bash
# Start the complete monitoring stack
docker-compose up -d

# Start only specific services
docker-compose up -d prometheus grafana alertmanager

# View logs
docker-compose logs -f prometheus
```

### Service URLs

- **API**: http://localhost:8000
- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3000 (admin/admin123)
- **AlertManager**: http://localhost:9093

## Configuration

### Environment Variables

```bash
# Monitoring configuration
LOG_LEVEL=INFO
LOG_FILE_PATH=/app/logs/application.log
ENVIRONMENT=production

# Alert configuration (optional)
SLACK_WEBHOOK_URL=https://hooks.slack.com/your-webhook
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password
```

### Prometheus Configuration

The Prometheus configuration automatically scrapes:
- TUG API metrics from `/monitoring/metrics`
- Node exporter system metrics
- Redis metrics (if redis_exporter is added)

### Grafana Dashboards

Pre-configured dashboards include:
- **TUG API Overview** - High-level application metrics
- **System Resources** - Server resource utilization
- **Database Performance** - MongoDB query metrics
- **Error Tracking** - Application error analysis

### Alert Rules

Default alert rules monitor:
- Error rate > 10%
- Average response time > 2 seconds
- Memory usage > 85%
- CPU usage > 80%
- Database connectivity issues

## Usage

### Accessing Metrics

```python
# In your application code
from app.monitoring import metrics_collector, user_activity_monitor

# Track user activities
user_activity_monitor.track_user_registration("user123", "email")
user_activity_monitor.track_feature_usage("user123", "activity_creation")

# Custom metrics
metrics_collector.increment_counter("custom_events_total", labels={"event_type": "signup"})
metrics_collector.set_gauge("active_users", 150)
```

### Health Checks

```bash
# Basic health check
curl http://localhost:8000/monitoring/health

# Liveness probe
curl http://localhost:8000/monitoring/health/live

# Readiness probe  
curl http://localhost:8000/monitoring/health/ready

# Detailed system status
curl http://localhost:8000/monitoring/status
```

### Deployment Monitoring

```python
from app.monitoring import deployment_monitor, DeploymentConfig

# Configure deployment monitoring
config = DeploymentConfig(
    deployment_id="v3.1.0-prod",
    version="3.1.0",
    environment="production",
    health_check_url="http://localhost:8000/monitoring/health",
    rollback_url="http://ci-cd-system/rollback",
    auto_rollback_enabled=True,
    max_error_rate_percent=5.0,
    monitoring_duration_minutes=15
)

# Start monitoring
deployment_id = await deployment_monitor.start_deployment_monitoring(config)
```

## Monitoring Best Practices

### 1. Alert Fatigue Prevention
- Set appropriate thresholds
- Use alert correlation and grouping
- Implement escalation policies
- Regular alert rule review

### 2. Performance Monitoring
- Monitor key business metrics
- Track performance trends
- Set up SLA monitoring
- Use percentile-based alerting

### 3. Log Management
- Use structured logging
- Implement log sampling for high-volume endpoints
- Set appropriate retention policies
- Monitor log ingestion rates

### 4. Dashboard Design
- Focus on actionable metrics
- Use consistent time ranges
- Implement drill-down capabilities
- Regular dashboard reviews

## Troubleshooting

### Common Issues

1. **High Memory Usage**
   ```bash
   # Check system resources
   curl http://localhost:8000/monitoring/health
   
   # View detailed metrics
   curl http://localhost:8000/monitoring/debug/info
   ```

2. **Database Connection Issues**
   ```bash
   # Check database health
   curl http://localhost:8000/monitoring/health | jq '.checks[] | select(.name=="database")'
   ```

3. **Missing Metrics**
   ```bash
   # Verify Prometheus is scraping
   curl http://localhost:9090/api/v1/targets
   
   # Check application metrics endpoint
   curl http://localhost:8000/monitoring/metrics
   ```

### Log Analysis

```bash
# View recent errors
docker-compose logs api | grep ERROR

# Follow real-time logs
docker-compose logs -f --tail=100 api

# Search for specific patterns
docker-compose logs api | grep -i "slow query"
```

## Security Considerations

1. **Access Control**: Monitoring endpoints should be restricted in production
2. **Data Sanitization**: Ensure no sensitive data in logs or metrics
3. **Network Security**: Use internal networks for monitoring traffic
4. **Authentication**: Enable authentication for Grafana and Prometheus
5. **Encryption**: Use TLS for all monitoring communications

## Scaling Considerations

1. **Metrics Storage**: Configure Prometheus retention and federation
2. **Log Volume**: Implement log sampling and archiving
3. **Alert Volume**: Use alert grouping and suppression
4. **Dashboard Performance**: Optimize queries and time ranges
5. **High Availability**: Deploy monitoring stack in HA configuration

## Maintenance

### Regular Tasks

1. **Weekly**:
   - Review alert noise and adjust thresholds
   - Check dashboard accuracy
   - Analyze performance trends

2. **Monthly**:
   - Update monitoring stack versions
   - Review log retention policies
   - Optimize resource allocation

3. **Quarterly**:
   - Audit monitoring coverage
   - Update disaster recovery procedures
   - Review and update alert rules

### Backup and Recovery

```bash
# Backup Prometheus data
docker-compose exec prometheus tar -czf /prometheus-backup.tar.gz /prometheus

# Backup Grafana dashboards
curl -X GET http://admin:admin123@localhost:3000/api/dashboards/home

# Backup alert rules
cp monitoring/alert_rules.yml monitoring/alert_rules.yml.backup
```

## Integration with CI/CD

The monitoring system integrates with CI/CD pipelines through:

1. **Health Check Gates**: Deployment gates based on health checks
2. **Performance Regression Detection**: Automatic rollback on performance degradation
3. **Metrics-based Deployment Validation**: Success criteria based on key metrics
4. **Alert Integration**: Notifications to development teams

For more detailed implementation examples, see the source code in `app/monitoring/`.