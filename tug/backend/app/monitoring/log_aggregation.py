# app/monitoring/log_aggregation.py
import asyncio
import os
import gzip
import shutil
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any, Set
from pathlib import Path
import logging
import json
import re
from dataclasses import dataclass, field
from collections import defaultdict, deque
import threading

from ..core.logging_config import get_logger

logger = get_logger(__name__)

@dataclass
class LogEntry:
    """Structured log entry"""
    timestamp: datetime
    level: str
    message: str
    logger_name: str
    service: str
    environment: str
    correlation_id: Optional[str] = None
    user_id: Optional[str] = None
    endpoint: Optional[str] = None
    method: Optional[str] = None
    status_code: Optional[int] = None
    response_time_ms: Optional[float] = None
    error_type: Optional[str] = None
    metadata: Dict[str, Any] = field(default_factory=dict)

@dataclass
class LogAggregationStats:
    """Log aggregation statistics"""
    total_logs_processed: int = 0
    logs_by_level: Dict[str, int] = field(default_factory=lambda: defaultdict(int))
    logs_by_service: Dict[str, int] = field(default_factory=lambda: defaultdict(int))
    errors_by_type: Dict[str, int] = field(default_factory=lambda: defaultdict(int))
    slow_requests: List[Dict[str, Any]] = field(default_factory=list)
    recent_errors: deque = field(default_factory=lambda: deque(maxlen=100))
    
class LogRotationPolicy:
    """Log rotation policy configuration"""
    
    def __init__(self, 
                 max_file_size_mb: int = 100,
                 max_files: int = 10,
                 rotation_interval_hours: int = 24,
                 compress_old_files: bool = True):
        self.max_file_size_mb = max_file_size_mb
        self.max_files = max_files
        self.rotation_interval_hours = rotation_interval_hours
        self.compress_old_files = compress_old_files

class LogRetentionPolicy:
    """Log retention policy configuration"""
    
    def __init__(self,
                 retention_days: int = 30,
                 critical_logs_retention_days: int = 90,
                 archive_old_logs: bool = True,
                 archive_location: Optional[str] = None):
        self.retention_days = retention_days
        self.critical_logs_retention_days = critical_logs_retention_days
        self.archive_old_logs = archive_old_logs
        self.archive_location = archive_location or "logs/archive"

class LogAggregator:
    """Production-ready log aggregation system"""
    
    def __init__(self, 
                 log_directory: str = "logs",
                 rotation_policy: Optional[LogRotationPolicy] = None,
                 retention_policy: Optional[LogRetentionPolicy] = None):
        self.log_directory = Path(log_directory)
        self.log_directory.mkdir(parents=True, exist_ok=True)
        
        self.rotation_policy = rotation_policy or LogRotationPolicy()
        self.retention_policy = retention_policy or LogRetentionPolicy()
        
        self.stats = LogAggregationStats()
        self._lock = threading.RLock()
        
        # Log parsing patterns
        self.json_pattern = re.compile(r'^\{.*\}$')
        self.structured_pattern = re.compile(
            r'(?P<timestamp>\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?Z?)\s+'
            r'(?P<level>\w+)\s+(?P<logger>\S+)\s+(?P<message>.+)'
        )
        
        # Start background tasks
        asyncio.create_task(self._rotation_task())
        asyncio.create_task(self._retention_task())
        asyncio.create_task(self._aggregation_task())
    
    async def process_log_line(self, line: str, source: str = "application"):
        """Process a single log line"""
        try:
            log_entry = self._parse_log_line(line, source)
            if log_entry:
                await self._aggregate_log_entry(log_entry)
                self.stats.total_logs_processed += 1
                
        except Exception as e:
            logger.error(f"Failed to process log line: {str(e)}")
    
    def _parse_log_line(self, line: str, source: str) -> Optional[LogEntry]:
        """Parse a log line into a structured LogEntry"""
        line = line.strip()
        if not line:
            return None
        
        try:
            # Try parsing as JSON first
            if self.json_pattern.match(line):
                data = json.loads(line)
                return LogEntry(
                    timestamp=datetime.fromisoformat(data.get('@timestamp', datetime.utcnow().isoformat()).replace('Z', '')),
                    level=data.get('level', 'INFO'),
                    message=data.get('message', ''),
                    logger_name=data.get('logger', 'unknown'),
                    service=data.get('service', source),
                    environment=data.get('environment', 'production'),
                    correlation_id=data.get('correlation_id'),
                    user_id=data.get('user_id'),
                    endpoint=data.get('endpoint'),
                    method=data.get('method'),
                    status_code=data.get('status_code'),
                    response_time_ms=data.get('response_time_ms'),
                    error_type=data.get('error_type'),
                    metadata={k: v for k, v in data.items() if k not in [
                        '@timestamp', 'level', 'message', 'logger', 'service', 'environment',
                        'correlation_id', 'user_id', 'endpoint', 'method', 'status_code',
                        'response_time_ms', 'error_type'
                    ]}
                )
            
            # Try parsing structured log format
            match = self.structured_pattern.match(line)
            if match:
                return LogEntry(
                    timestamp=datetime.fromisoformat(match.group('timestamp').replace('Z', '')),
                    level=match.group('level'),
                    message=match.group('message'),
                    logger_name=match.group('logger'),
                    service=source,
                    environment='production'
                )
            
            # Fallback: treat as plain text log
            return LogEntry(
                timestamp=datetime.utcnow(),
                level='INFO',
                message=line,
                logger_name='unknown',
                service=source,
                environment='production'
            )
            
        except Exception as e:
            logger.error(f"Failed to parse log line: {str(e)}")
            return None
    
    async def _aggregate_log_entry(self, entry: LogEntry):
        """Aggregate log entry statistics"""
        with self._lock:
            # Update level statistics
            self.stats.logs_by_level[entry.level] += 1
            
            # Update service statistics
            self.stats.logs_by_service[entry.service] += 1
            
            # Track errors
            if entry.level in ['ERROR', 'CRITICAL'] or entry.error_type:
                error_type = entry.error_type or 'unknown'
                self.stats.errors_by_type[error_type] += 1
                
                error_info = {
                    'timestamp': entry.timestamp.isoformat(),
                    'message': entry.message,
                    'error_type': error_type,
                    'user_id': entry.user_id,
                    'endpoint': entry.endpoint,
                    'correlation_id': entry.correlation_id
                }
                self.stats.recent_errors.append(error_info)
            
            # Track slow requests
            if entry.response_time_ms and entry.response_time_ms > 1000:
                slow_request = {
                    'timestamp': entry.timestamp.isoformat(),
                    'endpoint': entry.endpoint,
                    'method': entry.method,
                    'response_time_ms': entry.response_time_ms,
                    'user_id': entry.user_id,
                    'status_code': entry.status_code
                }
                self.stats.slow_requests.append(slow_request)
                
                # Keep only recent slow requests
                if len(self.stats.slow_requests) > 1000:
                    self.stats.slow_requests = self.stats.slow_requests[-500:]
    
    async def _rotation_task(self):
        """Background task for log rotation"""
        while True:
            try:
                await self._rotate_logs_if_needed()
                await asyncio.sleep(3600)  # Check every hour
                
            except Exception as e:
                logger.error(f"Error in log rotation task: {str(e)}")
                await asyncio.sleep(3600)
    
    async def _retention_task(self):
        """Background task for log retention"""
        while True:
            try:
                await self._cleanup_old_logs()
                await asyncio.sleep(86400)  # Check daily
                
            except Exception as e:
                logger.error(f"Error in log retention task: {str(e)}")
                await asyncio.sleep(86400)
    
    async def _aggregation_task(self):
        """Background task for log aggregation and analysis"""
        while True:
            try:
                await self._analyze_log_patterns()
                await asyncio.sleep(300)  # Analyze every 5 minutes
                
            except Exception as e:
                logger.error(f"Error in log aggregation task: {str(e)}")
                await asyncio.sleep(300)
    
    async def _rotate_logs_if_needed(self):
        """Rotate logs if needed based on rotation policy"""
        for log_file in self.log_directory.glob("*.log"):
            try:
                # Check file size
                file_size_mb = log_file.stat().st_size / (1024 * 1024)
                
                # Check file age
                file_age_hours = (datetime.now().timestamp() - log_file.stat().st_mtime) / 3600
                
                should_rotate = (
                    file_size_mb > self.rotation_policy.max_file_size_mb or
                    file_age_hours > self.rotation_policy.rotation_interval_hours
                )
                
                if should_rotate:
                    await self._rotate_log_file(log_file)
                    
            except Exception as e:
                logger.error(f"Failed to check rotation for {log_file}: {str(e)}")
    
    async def _rotate_log_file(self, log_file: Path):
        """Rotate a specific log file"""
        try:
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            base_name = log_file.stem
            extension = log_file.suffix
            
            # Create rotated filename
            rotated_name = f"{base_name}_{timestamp}{extension}"
            rotated_path = log_file.parent / rotated_name
            
            # Move current log file
            shutil.move(str(log_file), str(rotated_path))
            
            # Compress if enabled
            if self.rotation_policy.compress_old_files:
                compressed_path = rotated_path.with_suffix(rotated_path.suffix + '.gz')
                with open(rotated_path, 'rb') as f_in:
                    with gzip.open(compressed_path, 'wb') as f_out:
                        shutil.copyfileobj(f_in, f_out)
                rotated_path.unlink()  # Remove uncompressed file
                rotated_path = compressed_path
            
            logger.info(f"Rotated log file: {log_file} -> {rotated_path}")
            
            # Clean up old rotated files
            await self._cleanup_rotated_files(base_name)
            
        except Exception as e:
            logger.error(f"Failed to rotate log file {log_file}: {str(e)}")
    
    async def _cleanup_rotated_files(self, base_name: str):
        """Clean up old rotated files beyond max_files limit"""
        try:
            # Find all rotated files for this base name
            pattern = f"{base_name}_*"
            rotated_files = list(self.log_directory.glob(pattern))
            
            # Sort by modification time (newest first)
            rotated_files.sort(key=lambda x: x.stat().st_mtime, reverse=True)
            
            # Keep only max_files
            files_to_remove = rotated_files[self.rotation_policy.max_files:]
            
            for file_to_remove in files_to_remove:
                file_to_remove.unlink()
                logger.info(f"Removed old rotated log file: {file_to_remove}")
                
        except Exception as e:
            logger.error(f"Failed to cleanup rotated files for {base_name}: {str(e)}")
    
    async def _cleanup_old_logs(self):
        """Clean up old logs based on retention policy"""
        try:
            now = datetime.now()
            retention_cutoff = now - timedelta(days=self.retention_policy.retention_days)
            critical_cutoff = now - timedelta(days=self.retention_policy.critical_logs_retention_days)
            
            archive_dir = Path(self.retention_policy.archive_location)
            if self.retention_policy.archive_old_logs:
                archive_dir.mkdir(parents=True, exist_ok=True)
            
            # Process all log files
            for log_file in self.log_directory.glob("*"):
                if not log_file.is_file():
                    continue
                
                file_time = datetime.fromtimestamp(log_file.stat().st_mtime)
                
                # Check if file contains critical logs
                is_critical = await self._contains_critical_logs(log_file)
                cutoff_time = critical_cutoff if is_critical else retention_cutoff
                
                if file_time < cutoff_time:
                    if self.retention_policy.archive_old_logs:
                        # Archive the file
                        archive_path = archive_dir / log_file.name
                        shutil.move(str(log_file), str(archive_path))
                        logger.info(f"Archived old log file: {log_file} -> {archive_path}")
                    else:
                        # Delete the file
                        log_file.unlink()
                        logger.info(f"Deleted old log file: {log_file}")
                        
        except Exception as e:
            logger.error(f"Failed to cleanup old logs: {str(e)}")
    
    async def _contains_critical_logs(self, log_file: Path) -> bool:
        """Check if log file contains critical logs"""
        try:
            # Quick scan for critical log levels
            critical_patterns = [b'CRITICAL', b'ERROR', b'security_event']
            
            if log_file.suffix == '.gz':
                with gzip.open(log_file, 'rb') as f:
                    sample = f.read(10240)  # Read first 10KB
            else:
                with open(log_file, 'rb') as f:
                    sample = f.read(10240)  # Read first 10KB
            
            return any(pattern in sample for pattern in critical_patterns)
            
        except Exception:
            # If we can't read the file, assume it's not critical
            return False
    
    async def _analyze_log_patterns(self):
        """Analyze log patterns for insights and anomalies"""
        try:
            with self._lock:
                # Analyze error patterns
                if len(self.stats.recent_errors) > 10:
                    await self._analyze_error_patterns()
                
                # Analyze performance patterns
                if len(self.stats.slow_requests) > 10:
                    await self._analyze_performance_patterns()
                
        except Exception as e:
            logger.error(f"Failed to analyze log patterns: {str(e)}")
    
    async def _analyze_error_patterns(self):
        """Analyze recent errors for patterns"""
        try:
            # Group errors by type and endpoint
            error_groups = defaultdict(list)
            
            for error in list(self.stats.recent_errors):
                key = (error.get('error_type', 'unknown'), error.get('endpoint', 'unknown'))
                error_groups[key].append(error)
            
            # Look for error spikes
            for (error_type, endpoint), errors in error_groups.items():
                if len(errors) > 5:  # More than 5 similar errors
                    recent_errors = [e for e in errors if 
                                   datetime.fromisoformat(e['timestamp']) > 
                                   datetime.utcnow() - timedelta(minutes=30)]
                    
                    if len(recent_errors) > 3:
                        logger.warning(
                            f"Error spike detected: {error_type} at {endpoint} "
                            f"({len(recent_errors)} errors in 30 minutes)",
                            extra={
                                'pattern_analysis': True,
                                'error_type': error_type,
                                'endpoint': endpoint,
                                'error_count': len(recent_errors)
                            }
                        )
                        
        except Exception as e:
            logger.error(f"Failed to analyze error patterns: {str(e)}")
    
    async def _analyze_performance_patterns(self):
        """Analyze performance patterns"""
        try:
            # Group slow requests by endpoint
            endpoint_performance = defaultdict(list)
            
            for request in self.stats.slow_requests[-100:]:  # Last 100 slow requests
                endpoint = request.get('endpoint', 'unknown')
                response_time = request.get('response_time_ms', 0)
                endpoint_performance[endpoint].append(response_time)
            
            # Identify consistently slow endpoints
            for endpoint, response_times in endpoint_performance.items():
                if len(response_times) > 5:
                    avg_time = sum(response_times) / len(response_times)
                    if avg_time > 2000:  # Average > 2 seconds
                        logger.warning(
                            f"Consistently slow endpoint: {endpoint} "
                            f"(avg: {avg_time:.2f}ms, count: {len(response_times)})",
                            extra={
                                'pattern_analysis': True,
                                'endpoint': endpoint,
                                'avg_response_time_ms': avg_time,
                                'slow_request_count': len(response_times)
                            }
                        )
                        
        except Exception as e:
            logger.error(f"Failed to analyze performance patterns: {str(e)}")
    
    def get_aggregation_stats(self) -> Dict[str, Any]:
        """Get current aggregation statistics"""
        with self._lock:
            return {
                'total_logs_processed': self.stats.total_logs_processed,
                'logs_by_level': dict(self.stats.logs_by_level),
                'logs_by_service': dict(self.stats.logs_by_service),
                'errors_by_type': dict(self.stats.errors_by_type),
                'recent_errors_count': len(self.stats.recent_errors),
                'slow_requests_count': len(self.stats.slow_requests),
                'timestamp': datetime.utcnow().isoformat() + 'Z'
            }
    
    def get_recent_errors(self, limit: int = 50) -> List[Dict[str, Any]]:
        """Get recent errors"""
        with self._lock:
            return list(self.stats.recent_errors)[-limit:]
    
    def get_slow_requests(self, limit: int = 50) -> List[Dict[str, Any]]:
        """Get recent slow requests"""
        with self._lock:
            return self.stats.slow_requests[-limit:]
    
    async def export_logs(self, 
                         start_time: datetime, 
                         end_time: datetime,
                         levels: Optional[List[str]] = None,
                         services: Optional[List[str]] = None) -> List[Dict[str, Any]]:
        """Export logs for a time range with filtering"""
        # This would be implemented to read through log files and extract matching entries
        # For brevity, returning a placeholder
        return []

# Global log aggregator instance
log_aggregator = LogAggregator()