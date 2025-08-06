#!/usr/bin/env python3
"""
Database Performance Analysis Script

This script analyzes the MongoDB database performance, provides recommendations,
and generates a comprehensive performance report for the Tug application.

Usage:
    python scripts/db_performance_report.py

Features:
- Index usage analysis
- Slow query detection
- Collection statistics
- Performance recommendations
- Database health metrics
"""

import asyncio
import os
import sys
import logging
import json
from datetime import datetime, timedelta
from motor.motor_asyncio import AsyncIOMotorClient
from typing import Dict, List, Any

# Add the parent directory to the path to import app modules
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Database configuration
MONGODB_URL = os.environ.get("MONGODB_URL", "mongodb://localhost:27017")
MONGODB_DB_NAME = os.environ.get("MONGODB_DB_NAME", "tug")

class DatabasePerformanceAnalyzer:
    """Analyze MongoDB performance and provide optimization recommendations"""
    
    def __init__(self, client: AsyncIOMotorClient, db_name: str):
        self.client = client
        self.db = client[db_name]
        self.db_name = db_name
        
    async def get_server_status(self) -> Dict[str, Any]:
        """Get MongoDB server status for performance metrics"""
        try:
            return await self.client.admin.command('serverStatus')
        except Exception as e:
            logger.error(f"Failed to get server status: {e}")
            return {}
    
    async def get_database_stats(self) -> Dict[str, Any]:
        """Get database statistics"""
        try:
            return await self.db.command('dbStats')
        except Exception as e:
            logger.error(f"Failed to get database stats: {e}")
            return {}
    
    async def analyze_collection_performance(self, collection_name: str) -> Dict[str, Any]:
        """Analyze performance for a specific collection"""
        try:
            collection = self.db[collection_name]
            
            # Get collection stats
            stats = await self.db.command('collStats', collection_name)
            
            # Get index information
            indexes = await collection.list_indexes().to_list(length=None)
            
            # Get sample documents to understand data patterns
            sample_docs = await collection.find().limit(5).to_list(length=5)
            
            # Try to get index stats (MongoDB 3.2+)
            index_stats = []
            try:
                index_stats = await collection.aggregate([{"$indexStats": {}}]).to_list(length=None)
            except:
                pass  # indexStats may not be available
            
            return {
                "collection": collection_name,
                "stats": {
                    "count": stats.get('count', 0),
                    "size": stats.get('size', 0),
                    "storageSize": stats.get('storageSize', 0),
                    "avgObjSize": stats.get('avgObjSize', 0),
                    "indexSize": stats.get('indexSize', 0),
                    "totalIndexSize": stats.get('totalIndexSize', 0),
                },
                "indexes": {
                    "count": len(indexes),
                    "details": indexes,
                    "usage_stats": index_stats
                },
                "sample_documents": len(sample_docs),
                "analysis": await self._analyze_collection_efficiency(stats, indexes)
            }
            
        except Exception as e:
            logger.error(f"Failed to analyze collection {collection_name}: {e}")
            return {"collection": collection_name, "error": str(e)}
    
    async def _analyze_collection_efficiency(self, stats: Dict, indexes: List) -> Dict[str, Any]:
        """Analyze collection efficiency and provide recommendations"""
        analysis = {
            "recommendations": [],
            "warnings": [],
            "efficiency_score": 100
        }
        
        count = stats.get('count', 0)
        size = stats.get('size', 0)
        storage_size = stats.get('storageSize', 0)
        avg_obj_size = stats.get('avgObjSize', 0)
        index_size = stats.get('indexSize', 0)
        
        # Check collection size vs document count
        if count > 0:
            if avg_obj_size > 16 * 1024:  # 16KB
                analysis["warnings"].append("Large average document size may impact query performance")
                analysis["efficiency_score"] -= 10
            
            # Check index to data ratio
            if size > 0:
                index_ratio = (index_size / size) * 100
                if index_ratio > 50:
                    analysis["warnings"].append(f"High index-to-data ratio ({index_ratio:.1f}%) - consider reviewing index usage")
                    analysis["efficiency_score"] -= 15
                elif index_ratio < 5:
                    analysis["recommendations"].append("Low index coverage - consider adding more indexes for query optimization")
        
        # Check storage efficiency
        if storage_size > 0 and size > 0:
            storage_efficiency = (size / storage_size) * 100
            if storage_efficiency < 60:
                analysis["recommendations"].append("Low storage efficiency - consider running compact operation")
                analysis["efficiency_score"] -= 10
        
        # Analyze index coverage
        index_names = [idx.get('name', '') for idx in indexes]
        essential_patterns = ['_id_']  # Always present
        
        if len(indexes) < 3:
            analysis["recommendations"].append("Consider adding more indexes for common query patterns")
            analysis["efficiency_score"] -= 20
        elif len(indexes) > 15:
            analysis["warnings"].append("High number of indexes may impact write performance")
            analysis["efficiency_score"] -= 5
        
        return analysis
    
    async def check_slow_operations(self) -> List[Dict[str, Any]]:
        """Check for currently running slow operations"""
        try:
            current_ops = await self.db.current_op()
            slow_ops = []
            
            for op in current_ops.get('inprog', []):
                # Consider operations running for more than 1 second as potentially slow
                if op.get('secs_running', 0) > 1:
                    slow_ops.append({
                        'op': op.get('op', 'unknown'),
                        'ns': op.get('ns', 'unknown'),
                        'duration_seconds': op.get('secs_running', 0),
                        'command': op.get('command', {}),
                        'client': op.get('client', 'unknown')
                    })
            
            return slow_ops
            
        except Exception as e:
            logger.error(f"Failed to check slow operations: {e}")
            return []
    
    async def analyze_query_patterns(self) -> Dict[str, Any]:
        """Analyze common query patterns and performance"""
        try:
            server_status = await self.get_server_status()
            op_counters = server_status.get('opcounters', {})
            
            # Calculate query distribution
            total_ops = sum(op_counters.values())
            if total_ops > 0:
                query_distribution = {
                    'insert_percentage': (op_counters.get('insert', 0) / total_ops) * 100,
                    'query_percentage': (op_counters.get('query', 0) / total_ops) * 100,
                    'update_percentage': (op_counters.get('update', 0) / total_ops) * 100,
                    'delete_percentage': (op_counters.get('delete', 0) / total_ops) * 100,
                    'command_percentage': (op_counters.get('command', 0) / total_ops) * 100,
                }
            else:
                query_distribution = {}
            
            # Get connection metrics
            connections = server_status.get('connections', {})
            
            # Get memory metrics
            mem = server_status.get('mem', {})
            
            return {
                'operation_counters': op_counters,
                'query_distribution': query_distribution,
                'connections': connections,
                'memory_usage': mem,
                'uptime_seconds': server_status.get('uptime', 0),
                'analysis': self._analyze_performance_patterns(op_counters, connections, mem)
            }
            
        except Exception as e:
            logger.error(f"Failed to analyze query patterns: {e}")
            return {"error": str(e)}
    
    def _analyze_performance_patterns(self, op_counters: Dict, connections: Dict, mem: Dict) -> Dict[str, Any]:
        """Analyze performance patterns and provide recommendations"""
        analysis = {
            "recommendations": [],
            "warnings": [],
            "performance_score": 100
        }
        
        # Analyze operation patterns
        total_ops = sum(op_counters.values())
        if total_ops > 0:
            query_ratio = op_counters.get('query', 0) / total_ops
            if query_ratio > 0.8:
                analysis["recommendations"].append("High read workload - consider read replicas for scaling")
            
            update_ratio = op_counters.get('update', 0) / total_ops
            if update_ratio > 0.3:
                analysis["warnings"].append("High update workload - monitor for lock contention")
                analysis["performance_score"] -= 10
        
        # Analyze connections
        current_conn = connections.get('current', 0)
        available_conn = connections.get('available', 0)
        
        if available_conn > 0:
            conn_usage = (current_conn / (current_conn + available_conn)) * 100
            if conn_usage > 80:
                analysis["warnings"].append(f"High connection usage ({conn_usage:.1f}%) - consider connection pooling optimization")
                analysis["performance_score"] -= 15
        
        # Analyze memory usage
        resident_mb = mem.get('resident', 0)
        virtual_mb = mem.get('virtual', 0)
        
        if resident_mb > 0:
            if resident_mb > 8192:  # 8GB
                analysis["recommendations"].append("High memory usage - monitor for memory pressure")
            
            if virtual_mb > 0 and (virtual_mb / resident_mb) > 10:
                analysis["warnings"].append("High virtual to resident memory ratio - check for memory fragmentation")
                analysis["performance_score"] -= 5
        
        return analysis
    
    async def generate_comprehensive_report(self) -> Dict[str, Any]:
        """Generate a comprehensive performance report"""
        report = {
            "report_metadata": {
                "generated_at": datetime.utcnow().isoformat(),
                "database": self.db_name,
                "analysis_version": "1.0"
            },
            "server_info": {},
            "database_stats": {},
            "collections_analysis": {},
            "performance_analysis": {},
            "slow_operations": [],
            "recommendations": [],
            "overall_score": 100
        }
        
        try:
            # Server and database information
            report["server_info"] = await self.get_server_status()
            report["database_stats"] = await self.get_database_stats()
            
            # Analyze each collection
            collections = await self.db.list_collection_names()
            for collection_name in collections:
                if not collection_name.startswith('system.'):  # Skip system collections
                    analysis = await self.analyze_collection_performance(collection_name)
                    report["collections_analysis"][collection_name] = analysis
            
            # Performance analysis
            report["performance_analysis"] = await self.analyze_query_patterns()
            
            # Check for slow operations
            report["slow_operations"] = await self.check_slow_operations()
            
            # Generate overall recommendations
            report["recommendations"] = self._generate_overall_recommendations(report)
            
            # Calculate overall performance score
            report["overall_score"] = self._calculate_overall_score(report)
            
        except Exception as e:
            logger.error(f"Failed to generate comprehensive report: {e}")
            report["error"] = str(e)
        
        return report
    
    def _generate_overall_recommendations(self, report: Dict[str, Any]) -> List[str]:
        """Generate overall optimization recommendations based on the full report"""
        recommendations = []
        
        # Database size recommendations
        db_stats = report.get("database_stats", {})
        data_size_mb = db_stats.get("dataSize", 0) / (1024 * 1024)
        index_size_mb = db_stats.get("indexSize", 0) / (1024 * 1024)
        
        if data_size_mb > 1000:  # 1GB
            recommendations.append("Consider implementing data archival strategy for large database")
        
        if index_size_mb > 500:  # 500MB
            recommendations.append("Review index usage - large index size may impact performance")
        
        # Collection-specific recommendations
        collections_analysis = report.get("collections_analysis", {})
        for collection_name, analysis in collections_analysis.items():
            if isinstance(analysis, dict) and "analysis" in analysis:
                coll_recommendations = analysis["analysis"].get("recommendations", [])
                for rec in coll_recommendations:
                    recommendations.append(f"{collection_name}: {rec}")
        
        # Performance recommendations
        perf_analysis = report.get("performance_analysis", {})
        if "analysis" in perf_analysis:
            perf_recommendations = perf_analysis["analysis"].get("recommendations", [])
            recommendations.extend(perf_recommendations)
        
        # Slow operations recommendations
        slow_ops = report.get("slow_operations", [])
        if slow_ops:
            recommendations.append(f"Found {len(slow_ops)} slow operations - investigate query optimization")
        
        return list(set(recommendations))  # Remove duplicates
    
    def _calculate_overall_score(self, report: Dict[str, Any]) -> int:
        """Calculate overall performance score based on various metrics"""
        score = 100
        
        # Deduct points for slow operations
        slow_ops = report.get("slow_operations", [])
        score -= min(len(slow_ops) * 5, 20)  # Max 20 points deduction
        
        # Deduct points based on collection efficiency
        collections_analysis = report.get("collections_analysis", {})
        efficiency_scores = []
        for analysis in collections_analysis.values():
            if isinstance(analysis, dict) and "analysis" in analysis:
                eff_score = analysis["analysis"].get("efficiency_score", 100)
                efficiency_scores.append(eff_score)
        
        if efficiency_scores:
            avg_efficiency = sum(efficiency_scores) / len(efficiency_scores)
            score = min(score, avg_efficiency)
        
        # Performance pattern score
        perf_analysis = report.get("performance_analysis", {})
        if "analysis" in perf_analysis:
            perf_score = perf_analysis["analysis"].get("performance_score", 100)
            score = min(score, perf_score)
        
        return max(0, int(score))  # Ensure score is not negative

async def main():
    """Main function to generate and display performance report"""
    logger.info("🔍 Starting MongoDB Performance Analysis")
    logger.info(f"📡 Connecting to: {MONGODB_URL}")
    logger.info(f"🗄️  Database: {MONGODB_DB_NAME}")
    
    # Connect to MongoDB
    try:
        client = AsyncIOMotorClient(MONGODB_URL)
        await client.admin.command('ping')
        logger.info("✅ Successfully connected to MongoDB")
    except Exception as e:
        logger.error(f"❌ Failed to connect to MongoDB: {e}")
        return False
    
    # Initialize analyzer and generate report
    analyzer = DatabasePerformanceAnalyzer(client, MONGODB_DB_NAME)
    
    logger.info("📊 Generating comprehensive performance report...")
    report = await analyzer.generate_comprehensive_report()
    
    # Display summary
    print("\n" + "="*80)
    print("🎯 MONGODB PERFORMANCE ANALYSIS REPORT")
    print("="*80)
    
    print(f"\n📋 Report Metadata:")
    metadata = report.get("report_metadata", {})
    print(f"   Generated: {metadata.get('generated_at', 'Unknown')}")
    print(f"   Database: {metadata.get('database', 'Unknown')}")
    print(f"   Overall Score: {report.get('overall_score', 0)}/100")
    
    # Database overview
    db_stats = report.get("database_stats", {})
    if db_stats:
        print(f"\n🗄️  Database Overview:")
        print(f"   Collections: {db_stats.get('collections', 0)}")
        print(f"   Data Size: {db_stats.get('dataSize', 0) / (1024*1024):.2f} MB")
        print(f"   Index Size: {db_stats.get('indexSize', 0) / (1024*1024):.2f} MB")
        print(f"   Storage Size: {db_stats.get('storageSize', 0) / (1024*1024):.2f} MB")
    
    # Collections analysis summary
    collections_analysis = report.get("collections_analysis", {})
    if collections_analysis:
        print(f"\n📚 Collections Analysis:")
        for name, analysis in collections_analysis.items():
            if isinstance(analysis, dict) and "stats" in analysis:
                stats = analysis["stats"]
                indexes = analysis.get("indexes", {})
                efficiency = analysis.get("analysis", {}).get("efficiency_score", 0)
                print(f"   {name}:")
                print(f"     Documents: {stats.get('count', 0):,}")
                print(f"     Indexes: {indexes.get('count', 0)}")
                print(f"     Efficiency: {efficiency}/100")
    
    # Performance metrics
    perf_analysis = report.get("performance_analysis", {})
    if perf_analysis and "operation_counters" in perf_analysis:
        op_counters = perf_analysis["operation_counters"]
        print(f"\n⚡ Performance Metrics:")
        print(f"   Queries: {op_counters.get('query', 0):,}")
        print(f"   Inserts: {op_counters.get('insert', 0):,}")
        print(f"   Updates: {op_counters.get('update', 0):,}")
        print(f"   Deletes: {op_counters.get('delete', 0):,}")
        
        connections = perf_analysis.get("connections", {})
        if connections:
            print(f"   Current Connections: {connections.get('current', 0)}")
            print(f"   Available Connections: {connections.get('available', 0)}")
    
    # Slow operations
    slow_ops = report.get("slow_operations", [])
    if slow_ops:
        print(f"\n⚠️  Slow Operations Detected: {len(slow_ops)}")
        for i, op in enumerate(slow_ops[:3], 1):  # Show first 3
            print(f"   {i}. {op.get('op', 'unknown')} on {op.get('ns', 'unknown')} ({op.get('duration_seconds', 0)}s)")
    
    # Top recommendations
    recommendations = report.get("recommendations", [])
    if recommendations:
        print(f"\n💡 Top Recommendations:")
        for i, rec in enumerate(recommendations[:5], 1):  # Show top 5
            print(f"   {i}. {rec}")
    
    # Save detailed report to file
    report_filename = f"db_performance_report_{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}.json"
    try:
        with open(report_filename, 'w') as f:
            json.dump(report, f, indent=2, default=str)
        print(f"\n💾 Detailed report saved to: {report_filename}")
    except Exception as e:
        logger.warning(f"Could not save report file: {e}")
    
    print("\n" + "="*80)
    
    # Provide performance grade
    score = report.get("overall_score", 0)
    if score >= 90:
        grade = "A (Excellent)"
        emoji = "🟢"
    elif score >= 80:
        grade = "B (Good)" 
        emoji = "🟡"
    elif score >= 70:
        grade = "C (Fair)"
        emoji = "🟠"
    else:
        grade = "D (Needs Improvement)"
        emoji = "🔴"
    
    print(f"{emoji} Overall Performance Grade: {grade} ({score}/100)")
    print("="*80)
    
    # Close connection
    client.close()
    return True

if __name__ == "__main__":
    try:
        success = asyncio.run(main())
        exit_code = 0 if success else 1
        sys.exit(exit_code)
    except KeyboardInterrupt:
        logger.info("\n🛑 Analysis interrupted by user")
        sys.exit(1)
    except Exception as e:
        logger.error(f"❌ Analysis failed with error: {e}")
        sys.exit(1)