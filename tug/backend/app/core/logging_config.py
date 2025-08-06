# app/core/logging_config.py
import json
import logging
import logging.config
import sys
import traceback
import uuid
from datetime import datetime
from typing import Any, Dict, Optional
from contextvars import ContextVar
from pathlib import Path

# Context variable to store correlation ID across async calls
correlation_id_context: ContextVar[Optional[str]] = ContextVar('correlation_id', default=None)

class StructuredFormatter(logging.Formatter):
    """Custom formatter that outputs structured JSON logs"""
    
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.service_name = "tug-api"
        self.environment = "production"  # Should be set from environment variable
        
    def format(self, record: logging.LogRecord) -> str:
        """Format log record as structured JSON"""
        
        # Base log structure
        log_data = {
            "@timestamp": datetime.utcnow().isoformat() + "Z",
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
            "service": self.service_name,
            "environment": self.environment,
            "correlation_id": correlation_id_context.get(),
            "thread": record.thread,
            "thread_name": record.threadName,
            "process": record.process,
            "filename": record.filename,
            "line_number": record.lineno,
            "function": record.funcName,
        }
        
        # Add exception information if present
        if record.exc_info:
            log_data["exception"] = {
                "type": record.exc_info[0].__name__,
                "message": str(record.exc_info[1]),
                "traceback": traceback.format_exception(*record.exc_info)
            }
        
        # Add extra fields from LoggerAdapter or record
        if hasattr(record, 'extra_fields'):
            log_data.update(record.extra_fields)
        
        # Add HTTP request context if available
        if hasattr(record, 'request_id'):
            log_data["request_id"] = record.request_id
        if hasattr(record, 'user_id'):
            log_data["user_id"] = record.user_id
        if hasattr(record, 'ip_address'):
            log_data["ip_address"] = record.ip_address
        if hasattr(record, 'user_agent'):
            log_data["user_agent"] = record.user_agent
        if hasattr(record, 'endpoint'):
            log_data["endpoint"] = record.endpoint
        if hasattr(record, 'method'):
            log_data["method"] = record.method
        if hasattr(record, 'status_code'):
            log_data["status_code"] = record.status_code
        if hasattr(record, 'response_time_ms'):
            log_data["response_time_ms"] = record.response_time_ms
        
        # Performance monitoring fields
        if hasattr(record, 'db_query_time_ms'):
            log_data["db_query_time_ms"] = record.db_query_time_ms
        if hasattr(record, 'db_query_count'):
            log_data["db_query_count"] = record.db_query_count
        
        # Security event fields
        if hasattr(record, 'security_event'):
            log_data["security_event"] = record.security_event
        if hasattr(record, 'threat_level'):
            log_data["threat_level"] = record.threat_level
        
        return json.dumps(log_data, default=str, ensure_ascii=False)

class CorrelationIdLoggerAdapter(logging.LoggerAdapter):
    """Logger adapter that automatically includes correlation ID and context"""
    
    def __init__(self, logger: logging.Logger, extra: Optional[Dict[str, Any]] = None):
        super().__init__(logger, extra or {})
    
    def process(self, msg, kwargs):
        # Add correlation ID and any extra context
        correlation_id = correlation_id_context.get()
        if correlation_id:
            if 'extra' not in kwargs:
                kwargs['extra'] = {}
            kwargs['extra']['correlation_id'] = correlation_id
        
        # Merge with adapter's extra data
        if self.extra:
            if 'extra' not in kwargs:
                kwargs['extra'] = {}
            kwargs['extra'].update(self.extra)
        
        return msg, kwargs

def setup_logging(
    level: str = "INFO",
    service_name: str = "tug-api",
    environment: str = "production",
    log_file_path: Optional[str] = None
) -> None:
    """Setup structured logging configuration"""
    
    # Create logs directory if logging to file
    if log_file_path:
        log_dir = Path(log_file_path).parent
        log_dir.mkdir(parents=True, exist_ok=True)
    
    # Console handler configuration
    console_handler = {
        'class': 'logging.StreamHandler',
        'formatter': 'structured',
        'stream': 'ext://sys.stdout'
    }
    
    # File handler configuration (if specified)
    handlers = ['console']
    handler_configs = {'console': console_handler}
    
    if log_file_path:
        file_handler = {
            'class': 'logging.handlers.RotatingFileHandler',
            'formatter': 'structured',
            'filename': log_file_path,
            'maxBytes': 50 * 1024 * 1024,  # 50MB
            'backupCount': 5,
            'encoding': 'utf-8'
        }
        handlers.append('file')
        handler_configs['file'] = file_handler
    
    # Logging configuration
    config = {
        'version': 1,
        'disable_existing_loggers': False,
        'formatters': {
            'structured': {
                '()': StructuredFormatter,
            }
        },
        'handlers': handler_configs,
        'loggers': {
            'uvicorn': {
                'level': 'INFO',
                'handlers': handlers,
                'propagate': False
            },
            'uvicorn.access': {
                'level': 'INFO',
                'handlers': handlers,
                'propagate': False
            },
            'fastapi': {
                'level': 'INFO',
                'handlers': handlers,
                'propagate': False
            },
            'app': {
                'level': level,
                'handlers': handlers,
                'propagate': False
            },
            'motor': {
                'level': 'WARNING',
                'handlers': handlers,
                'propagate': False
            },
            'pymongo': {
                'level': 'WARNING',
                'handlers': handlers,
                'propagate': False
            }
        },
        'root': {
            'level': level,
            'handlers': handlers
        }
    }
    
    # Apply logging configuration
    logging.config.dictConfig(config)
    
    # Update formatter with service info
    for handler in logging.root.handlers:
        if isinstance(handler.formatter, StructuredFormatter):
            handler.formatter.service_name = service_name
            handler.formatter.environment = environment

def get_logger(name: str, extra: Optional[Dict[str, Any]] = None) -> CorrelationIdLoggerAdapter:
    """Get a logger with correlation ID support"""
    logger = logging.getLogger(name)
    return CorrelationIdLoggerAdapter(logger, extra)

def set_correlation_id(correlation_id: str) -> None:
    """Set correlation ID for current context"""
    correlation_id_context.set(correlation_id)

def get_correlation_id() -> Optional[str]:
    """Get current correlation ID"""
    return correlation_id_context.get()

def generate_correlation_id() -> str:
    """Generate a new correlation ID"""
    return str(uuid.uuid4())

# Security event logging helpers
def log_security_event(
    logger: logging.Logger,
    event_type: str,
    threat_level: str,
    description: str,
    user_id: Optional[str] = None,
    ip_address: Optional[str] = None,
    additional_data: Optional[Dict[str, Any]] = None
) -> None:
    """Log a security event with structured data"""
    
    extra = {
        'security_event': event_type,
        'threat_level': threat_level,
        'user_id': user_id,
        'ip_address': ip_address,
    }
    
    if additional_data:
        extra.update(additional_data)
    
    logger.warning(description, extra=extra)

# Performance monitoring helpers
def log_performance_metric(
    logger: logging.Logger,
    metric_name: str,
    value: float,
    unit: str = "ms",
    additional_data: Optional[Dict[str, Any]] = None
) -> None:
    """Log a performance metric"""
    
    extra = {
        'metric_name': metric_name,
        'metric_value': value,
        'metric_unit': unit,
    }
    
    if additional_data:
        extra.update(additional_data)
    
    logger.info(f"Performance metric: {metric_name} = {value}{unit}", extra=extra)

# Database query logging
def log_slow_query(
    logger: logging.Logger,
    query_info: Dict[str, Any],
    execution_time_ms: float,
    threshold_ms: float = 100.0
) -> None:
    """Log slow database queries"""
    
    if execution_time_ms > threshold_ms:
        extra = {
            'db_query_time_ms': execution_time_ms,
            'slow_query': True,
            'query_info': query_info,
            'threshold_ms': threshold_ms
        }
        
        logger.warning(
            f"Slow query detected: {execution_time_ms}ms > {threshold_ms}ms",
            extra=extra
        )