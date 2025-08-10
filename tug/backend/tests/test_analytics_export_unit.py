# tests/test_analytics_export_unit.py
import pytest
import asyncio
import sys
import os
from datetime import datetime, timezone
from unittest.mock import Mock, patch, AsyncMock

# Add the app directory to Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

# Mock Firebase dependencies before importing
sys.modules['firebase_admin'] = Mock()
sys.modules['firebase_admin.credentials'] = Mock()
sys.modules['firebase_admin.auth'] = Mock()
sys.modules['beanie'] = Mock()

from app.services.analytics_service import AnalyticsService


class MockUser:
    """Mock user class for testing"""
    def __init__(self, user_id="test_user_123", email="test@example.com"):
        self.id = user_id
        self.email = email
        self.created_at = datetime.now(timezone.utc)


class TestAnalyticsExportUnit:
    """Unit tests for analytics export functionality without full app context"""
    
    @pytest.fixture
    def sample_user(self):
        """Create a sample user for testing"""
        return MockUser()
    
    @pytest.fixture
    def sample_analytics_data(self):
        """Create sample analytics data for testing"""
        return {
            'overview': {
                'total_activities': 150,
                'total_duration_minutes': 7200,
                'total_duration_hours': 120.0,
                'avg_daily_activities': 5.0,
                'avg_daily_duration_minutes': 240.0,
                'active_days': 25,
                'total_days': 30,
                'consistency_percentage': 83.3,
                'productivity_score': 4.2,
                'avg_session_duration': 48.0
            },
            'value_breakdown': [
                {
                    'value_id': 'value_1',
                    'value_name': 'Health & Fitness',
                    'value_color': '#10B981',
                    'activity_count': 45,
                    'total_duration': 2160,
                    'avg_session_duration': 48.0,
                    'min_session_duration': 15,
                    'max_session_duration': 120,
                    'days_active': 20,
                    'consistency_score': 85.5
                },
                {
                    'value_id': 'value_2',
                    'value_name': 'Learning',
                    'value_color': '#6366F1',
                    'activity_count': 30,
                    'total_duration': 1800,
                    'avg_session_duration': 60.0,
                    'min_session_duration': 30,
                    'max_session_duration': 90,
                    'days_active': 15,
                    'consistency_score': 75.0
                }
            ],
            'trends': [
                {'period': '2024-01-01', 'activity_count': 5, 'total_duration': 240, 'avg_duration': 48.0},
                {'period': '2024-01-02', 'activity_count': 4, 'total_duration': 180, 'avg_duration': 45.0},
                {'period': '2024-01-03', 'activity_count': 6, 'total_duration': 300, 'avg_duration': 50.0}
            ],
            'streaks': {
                'value_1': {
                    'value_name': 'Health & Fitness',
                    'current_streak': 7,
                    'longest_streak': 14,
                    'total_streaks': 3,
                    'avg_streak_length': 8.5,
                    'streak_distribution': {'7': 1, '14': 1, '5': 1}
                }
            },
            'patterns': {
                'best_days_of_week': [
                    {'day': 'Monday', 'count': 25, 'percentage': 16.7},
                    {'day': 'Wednesday', 'count': 22, 'percentage': 14.7}
                ],
                'best_hours': [
                    {'hour': 7, 'count': 30, 'time_label': '7:00 AM'},
                    {'hour': 18, 'count': 25, 'time_label': '6:00 PM'}
                ],
                'duration_stats': {
                    'average': 48.0,
                    'median': 45.0,
                    'mode': 60,
                    'std_dev': 15.2
                }
            },
            'predictions': {
                'trend_direction': 'increasing',
                'trend_percentage': 12.5,
                'recommended_activity_hours': [7, 18, 19],
                'weekly_goal_probability': 85.5,
                'consistency_improvement_tips': [
                    'Try scheduling activities at your most productive hours',
                    'Consider shorter but more frequent sessions'
                ],
                'insufficient_data': False
            }
        }
    
    def test_csv_export_creates_all_files(self, sample_user, sample_analytics_data):
        """Test that CSV export creates all expected files"""
        
        # Test CSV export
        result = asyncio.run(
            AnalyticsService.export_to_csv(
                analytics=sample_analytics_data,
                user=sample_user,
                requested_types=['all'],
                days_back=30
            )
        )
        
        # Verify all expected CSV files are created
        assert 'metadata' in result
        assert 'overview' in result
        assert 'value_breakdown' in result
        assert 'trends' in result
        assert 'streaks' in result
        
        # Verify CSV content structure
        metadata_csv = result['metadata']
        assert 'Export Metadata' in metadata_csv
        assert str(sample_user.id) in metadata_csv
        assert 'CSV' in metadata_csv
        
        overview_csv = result['overview']
        assert 'Total Activities,Total Duration (Hours)' in overview_csv
        assert '150,120.0' in overview_csv
        
        value_breakdown_csv = result['value_breakdown']
        assert 'Value Name,Activity Count' in value_breakdown_csv
        assert 'Health & Fitness,45' in value_breakdown_csv
        assert 'Learning,30' in value_breakdown_csv
    
    def test_csv_export_with_custom_data_types(self, sample_user, sample_analytics_data):
        """Test CSV export with specific data types selected"""
        
        result = asyncio.run(
            AnalyticsService.export_to_csv(
                analytics=sample_analytics_data,
                user=sample_user,
                requested_types=['overview', 'streaks'],
                days_back=30
            )
        )
        
        # Should include metadata, overview, and streaks
        assert 'metadata' in result
        assert 'overview' in result
        assert 'streaks' in result
        
        # Should NOT include other data types
        assert 'value_breakdown' not in result
        assert 'trends' not in result
    
    def test_csv_export_with_date_range(self, sample_user, sample_analytics_data):
        """Test CSV export with custom date range"""
        
        start_date = datetime(2024, 1, 1)
        end_date = datetime(2024, 1, 31)
        
        result = asyncio.run(
            AnalyticsService.export_to_csv(
                analytics=sample_analytics_data,
                user=sample_user,
                requested_types=['all'],
                days_back=30,
                start_date=start_date,
                end_date=end_date
            )
        )
        
        # Verify date range is included in metadata
        metadata_csv = result['metadata']
        assert '2024-01-01' in metadata_csv
        assert '2024-01-31' in metadata_csv
    
    def test_export_handles_empty_data_gracefully(self, sample_user):
        """Test that export methods handle empty/minimal data gracefully"""
        
        minimal_data = {
            'overview': {},
            'value_breakdown': [],
            'trends': [],
            'streaks': {},
            'patterns': {},
            'predictions': {'insufficient_data': True}
        }
        
        # CSV export should still work with empty data
        csv_result = asyncio.run(
            AnalyticsService.export_to_csv(
                analytics=minimal_data,
                user=sample_user,
                requested_types=['all'],
                days_back=30
            )
        )
        
        assert 'metadata' in csv_result


if __name__ == "__main__":
    # Run a simple test manually
    test_instance = TestAnalyticsExportUnit()
    user = MockUser()
    
    sample_data = {
        'overview': {
            'total_activities': 50,
            'total_duration_hours': 25.0,
            'consistency_percentage': 75.0
        },
        'value_breakdown': [
            {'value_name': 'Test Value', 'activity_count': 10, 'total_duration': 600}
        ],
        'trends': [],
        'streaks': {},
        'patterns': {},
        'predictions': {}
    }
    
    # Test CSV export
    result = asyncio.run(
        AnalyticsService.export_to_csv(
            analytics=sample_data,
            user=user,
            requested_types=['all'],
            days_back=30
        )
    )
    
    print("CSV Export Test Results:")
    print(f"Files created: {list(result.keys())}")
    print("\nMetadata CSV (first 200 chars):")
    print(result['metadata'][:200])
    print("\nOverview CSV:")
    print(result['overview'])
    print("\nCSV Export Test: PASSED ✅")