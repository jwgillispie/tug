# app/monitoring/health.py
import asyncio
import time
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any
from enum import Enum
import psutil
import logging
from dataclasses import dataclass, asdict

from ..core.database import get_database
from ..core.logging_config import get_logger

logger = get_logger(__name__)

class HealthStatus(Enum):
    HEALTHY = "healthy"
    DEGRADED = "degraded"
    UNHEALTHY = "unhealthy"

@dataclass
class HealthCheckResult:
    """Individual health check result"""
    name: str
    status: HealthStatus
    response_time_ms: float
    message: str
    details: Optional[Dict[str, Any]] = None
    timestamp: datetime = None
    
    def __post_init__(self):
        if self.timestamp is None:
            self.timestamp = datetime.utcnow()
    
    def to_dict(self) -> Dict[str, Any]:
        result = asdict(self)
        result['status'] = self.status.value
        result['timestamp'] = self.timestamp.isoformat() + 'Z'
        return result

@dataclass 
class SystemHealthReport:
    """Complete system health report"""
    overall_status: HealthStatus
    checks: List[HealthCheckResult]
    system_info: Dict[str, Any]
    timestamp: datetime
    response_time_ms: float
    
    def to_dict(self) -> Dict[str, Any]:
        return {
            'overall_status': self.overall_status.value,
            'checks': [check.to_dict() for check in self.checks],
            'system_info': self.system_info,
            'timestamp': self.timestamp.isoformat() + 'Z',
            'response_time_ms': self.response_time_ms
        }

class HealthChecker:
    """Production-ready health monitoring system"""
    
    def __init__(self):
        self.checks = {}
        self.thresholds = {
            'database_response_time_ms': 500,
            'memory_usage_percent': 85,
            'disk_usage_percent': 90,
            'cpu_usage_percent': 80
        }
        self._register_default_checks()
    
    def _register_default_checks(self):
        """Register default health checks"""
        self.register_check('database', self._check_database)
        self.register_check('memory', self._check_memory)
        self.register_check('disk', self._check_disk_space)
        self.register_check('cpu', self._check_cpu_usage)
        self.register_check('network', self._check_network_connectivity)
    
    def register_check(self, name: str, check_func):
        """Register a custom health check"""
        self.checks[name] = check_func
        logger.info(f"Registered health check: {name}")
    
    async def run_all_checks(self, include_details: bool = True) -> SystemHealthReport:
        """Run all registered health checks"""
        start_time = time.time()
        checks_results = []
        
        # Run all checks concurrently
        tasks = []
        for name, check_func in self.checks.items():
            tasks.append(self._run_single_check(name, check_func, include_details))
        
        checks_results = await asyncio.gather(*tasks, return_exceptions=True)
        
        # Handle exceptions
        final_results = []
        for i, result in enumerate(checks_results):
            if isinstance(result, Exception):
                check_name = list(self.checks.keys())[i]
                final_results.append(HealthCheckResult(
                    name=check_name,
                    status=HealthStatus.UNHEALTHY,
                    response_time_ms=0.0,
                    message=f"Health check failed: {str(result)}",
                    details={'error': str(result)} if include_details else None
                ))
            else:
                final_results.append(result)
        
        # Determine overall status
        overall_status = self._determine_overall_status(final_results)
        
        # Get system information
        system_info = await self._get_system_info()
        
        total_time_ms = (time.time() - start_time) * 1000
        
        return SystemHealthReport(
            overall_status=overall_status,
            checks=final_results,
            system_info=system_info,
            timestamp=datetime.utcnow(),
            response_time_ms=total_time_ms
        )
    
    async def _run_single_check(self, name: str, check_func, include_details: bool) -> HealthCheckResult:
        """Run a single health check with timeout and error handling"""
        start_time = time.time()
        
        try:
            # Set timeout for individual checks
            result = await asyncio.wait_for(check_func(include_details), timeout=10.0)
            return result
        except asyncio.TimeoutError:
            response_time_ms = (time.time() - start_time) * 1000
            return HealthCheckResult(
                name=name,
                status=HealthStatus.UNHEALTHY,
                response_time_ms=response_time_ms,
                message="Health check timed out",
                details={'timeout': True} if include_details else None
            )
        except Exception as e:
            response_time_ms = (time.time() - start_time) * 1000
            logger.error(f"Health check {name} failed: {str(e)}", exc_info=True)
            return HealthCheckResult(
                name=name,
                status=HealthStatus.UNHEALTHY,
                response_time_ms=response_time_ms,
                message=f"Health check error: {str(e)}",
                details={'error': str(e)} if include_details else None
            )
    
    def _determine_overall_status(self, results: List[HealthCheckResult]) -> HealthStatus:
        """Determine overall system health from individual check results"""
        if not results:
            return HealthStatus.UNHEALTHY
        
        unhealthy_count = sum(1 for r in results if r.status == HealthStatus.UNHEALTHY)
        degraded_count = sum(1 for r in results if r.status == HealthStatus.DEGRADED)
        
        # If any critical checks fail, system is unhealthy
        if unhealthy_count > 0:
            return HealthStatus.UNHEALTHY
        
        # If some checks are degraded, system is degraded
        if degraded_count > 0:
            return HealthStatus.DEGRADED
        
        return HealthStatus.HEALTHY
    
    async def _check_database(self, include_details: bool = True) -> HealthCheckResult:
        """Check database connectivity and performance"""
        start_time = time.time()
        
        try:
            db = get_database()
            
            # Test basic connectivity
            server_info = await db.admin.command('ping')
            
            # Test a simple query
            collections = await db.list_collection_names()
            
            response_time_ms = (time.time() - start_time) * 1000
            
            # Determine status based on response time
            if response_time_ms > self.thresholds['database_response_time_ms']:
                status = HealthStatus.DEGRADED
                message = f"Database responding slowly ({response_time_ms:.2f}ms)"
            else:
                status = HealthStatus.HEALTHY
                message = "Database connection healthy"
            
            details = {
                'collections_count': len(collections),
                'server_info': server_info
            } if include_details else None
            
            return HealthCheckResult(
                name='database',
                status=status,
                response_time_ms=response_time_ms,
                message=message,
                details=details
            )
            
        except Exception as e:
            response_time_ms = (time.time() - start_time) * 1000
            return HealthCheckResult(
                name='database',
                status=HealthStatus.UNHEALTHY,
                response_time_ms=response_time_ms,
                message=f"Database connection failed: {str(e)}",
                details={'error': str(e)} if include_details else None
            )
    
    async def _check_memory(self, include_details: bool = True) -> HealthCheckResult:
        """Check system memory usage"""
        start_time = time.time()
        
        try:
            memory = psutil.virtual_memory()
            response_time_ms = (time.time() - start_time) * 1000
            
            usage_percent = memory.percent
            
            if usage_percent > self.thresholds['memory_usage_percent']:
                status = HealthStatus.DEGRADED if usage_percent < 95 else HealthStatus.UNHEALTHY
                message = f"High memory usage: {usage_percent:.1f}%"
            else:
                status = HealthStatus.HEALTHY
                message = f"Memory usage normal: {usage_percent:.1f}%"
            
            details = {
                'total_gb': round(memory.total / (1024**3), 2),
                'available_gb': round(memory.available / (1024**3), 2),
                'used_gb': round(memory.used / (1024**3), 2),
                'percent': usage_percent
            } if include_details else None
            
            return HealthCheckResult(
                name='memory',
                status=status,
                response_time_ms=response_time_ms,
                message=message,
                details=details
            )
            
        except Exception as e:
            response_time_ms = (time.time() - start_time) * 1000
            return HealthCheckResult(
                name='memory',
                status=HealthStatus.UNHEALTHY,
                response_time_ms=response_time_ms,
                message=f"Memory check failed: {str(e)}",
                details={'error': str(e)} if include_details else None
            )
    
    async def _check_disk_space(self, include_details: bool = True) -> HealthCheckResult:
        """Check disk space usage"""
        start_time = time.time()
        
        try:
            disk = psutil.disk_usage('/')
            response_time_ms = (time.time() - start_time) * 1000
            
            usage_percent = (disk.used / disk.total) * 100
            
            if usage_percent > self.thresholds['disk_usage_percent']:
                status = HealthStatus.DEGRADED if usage_percent < 95 else HealthStatus.UNHEALTHY
                message = f"High disk usage: {usage_percent:.1f}%"
            else:
                status = HealthStatus.HEALTHY
                message = f"Disk usage normal: {usage_percent:.1f}%"
            
            details = {
                'total_gb': round(disk.total / (1024**3), 2),
                'used_gb': round(disk.used / (1024**3), 2),
                'free_gb': round(disk.free / (1024**3), 2),
                'percent': round(usage_percent, 1)
            } if include_details else None
            
            return HealthCheckResult(
                name='disk',
                status=status,
                response_time_ms=response_time_ms,
                message=message,
                details=details
            )
            
        except Exception as e:
            response_time_ms = (time.time() - start_time) * 1000
            return HealthCheckResult(
                name='disk',
                status=HealthStatus.UNHEALTHY,
                response_time_ms=response_time_ms,
                message=f"Disk check failed: {str(e)}",
                details={'error': str(e)} if include_details else None
            )
    
    async def _check_cpu_usage(self, include_details: bool = True) -> HealthCheckResult:
        """Check CPU usage"""
        start_time = time.time()
        
        try:
            # Get CPU usage over a short interval
            cpu_percent = psutil.cpu_percent(interval=0.1)
            response_time_ms = (time.time() - start_time) * 1000
            
            if cpu_percent > self.thresholds['cpu_usage_percent']:
                status = HealthStatus.DEGRADED if cpu_percent < 95 else HealthStatus.UNHEALTHY
                message = f"High CPU usage: {cpu_percent:.1f}%"
            else:
                status = HealthStatus.HEALTHY
                message = f"CPU usage normal: {cpu_percent:.1f}%"
            
            details = {
                'usage_percent': cpu_percent,
                'core_count': psutil.cpu_count(),
                'load_average': list(psutil.getloadavg()) if hasattr(psutil, 'getloadavg') else None
            } if include_details else None
            
            return HealthCheckResult(
                name='cpu',
                status=status,
                response_time_ms=response_time_ms,
                message=message,
                details=details
            )
            
        except Exception as e:
            response_time_ms = (time.time() - start_time) * 1000
            return HealthCheckResult(
                name='cpu',
                status=HealthStatus.UNHEALTHY,
                response_time_ms=response_time_ms,
                message=f"CPU check failed: {str(e)}",
                details={'error': str(e)} if include_details else None
            )
    
    async def _check_network_connectivity(self, include_details: bool = True) -> HealthCheckResult:
        """Check network connectivity"""
        start_time = time.time()
        
        try:
            import socket
            
            # Check if we can resolve DNS and connect
            sock = socket.create_connection(('8.8.8.8', 53), timeout=5)
            sock.close()
            
            response_time_ms = (time.time() - start_time) * 1000
            
            status = HealthStatus.HEALTHY
            message = "Network connectivity healthy"
            
            details = {
                'dns_resolution': True,
                'external_connectivity': True
            } if include_details else None
            
            return HealthCheckResult(
                name='network',
                status=status,
                response_time_ms=response_time_ms,
                message=message,
                details=details
            )
            
        except Exception as e:
            response_time_ms = (time.time() - start_time) * 1000
            return HealthCheckResult(
                name='network',
                status=HealthStatus.UNHEALTHY,
                response_time_ms=response_time_ms,
                message=f"Network connectivity failed: {str(e)}",
                details={'error': str(e)} if include_details else None
            )
    
    async def _get_system_info(self) -> Dict[str, Any]:
        """Get general system information"""
        try:
            boot_time = datetime.fromtimestamp(psutil.boot_time())
            uptime = datetime.utcnow() - boot_time
            
            return {
                'python_version': f"{psutil.version_info.major}.{psutil.version_info.minor}.{psutil.version_info.micro}",
                'uptime_seconds': int(uptime.total_seconds()),
                'uptime_human': str(uptime),
                'boot_time': boot_time.isoformat() + 'Z',
                'process_count': len(psutil.pids()),
                'system': {
                    'platform': psutil.LINUX if hasattr(psutil, 'LINUX') else 'unknown',
                    'architecture': 'unknown'  # Would need platform module for this
                }
            }
        except Exception as e:
            logger.error(f"Failed to get system info: {str(e)}")
            return {'error': str(e)}

# Global health checker instance
health_checker = HealthChecker()