# tests/test_analytics_export.py
import pytest
import asyncio
from unittest.mock import Mock, patch, AsyncMock
from datetime import datetime, timezone
from app.services.analytics_service import AnalyticsService
from app.models.user import User
from app.models.analytics import UserAnalytics


class TestAnalyticsExport:
    """Test analytics export functionality"""
    
    @pytest.fixture
    def sample_user(self):
        """Create a sample user for testing"""
        return User(
            id="test_user_123",
            email="test@example.com",
            created_at=datetime.now(timezone.utc)
        )
    
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
    
    @patch('app.services.analytics_service.AnalyticsService._create_value_breakdown_chart')
    @patch('app.services.analytics_service.AnalyticsService._create_trends_chart')
    def test_pdf_export_creates_comprehensive_report(self, mock_trends_chart, mock_breakdown_chart, sample_user, sample_analytics_data):
        """Test that PDF export creates a comprehensive report"""
        
        # Mock chart creation to return temporary file paths
        mock_breakdown_chart.return_value = asyncio.Future()
        mock_breakdown_chart.return_value.set_result('/tmp/breakdown_chart.png')
        
        mock_trends_chart.return_value = asyncio.Future()
        mock_trends_chart.return_value.set_result('/tmp/trends_chart.png')
        
        # Test PDF export
        result = asyncio.run(
            AnalyticsService.export_to_pdf(
                analytics=sample_analytics_data,
                user=sample_user,
                requested_types=['all'],
                days_back=30,
                include_charts=True
            )
        )
        
        # Verify PDF data structure
        assert 'pdf_base64' in result
        assert 'filename' in result
        assert 'content_type' in result
        assert 'size_bytes' in result
        
        # Verify filename format
        assert result['filename'].startswith('tug_analytics_')
        assert result['filename'].endswith('.pdf')
        assert result['content_type'] == 'application/pdf'
        
        # Verify PDF content is base64 encoded
        import base64
        try:
            decoded_pdf = base64.b64decode(result['pdf_base64'])
            assert len(decoded_pdf) > 0
            # PDF files start with %PDF
            assert decoded_pdf.startswith(b'%PDF')
        except Exception as e:
            pytest.fail(f"Failed to decode PDF base64 data: {e}")
    
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
    
    def test_pdf_export_without_charts(self, sample_user, sample_analytics_data):
        """Test PDF export without charts"""
        
        result = asyncio.run(
            AnalyticsService.export_to_pdf(
                analytics=sample_analytics_data,
                user=sample_user,
                requested_types=['overview', 'breakdown'],
                days_back=30,
                include_charts=False
            )
        )
        
        # Should still create a PDF
        assert 'pdf_base64' in result
        assert result['content_type'] == 'application/pdf'
        
        # Verify PDF content
        import base64
        decoded_pdf = base64.b64decode(result['pdf_base64'])
        assert decoded_pdf.startswith(b'%PDF')
    
    @patch('app.services.analytics_service.matplotlib.pyplot.savefig')
    @patch('app.services.analytics_service.matplotlib.pyplot.figure')
    def test_chart_generation_methods(self, mock_figure, mock_savefig, sample_analytics_data):
        """Test individual chart generation methods"""
        
        # Mock matplotlib components
        mock_figure.return_value = Mock()
        mock_savefig.return_value = None
        
        # Test value breakdown chart
        with patch('app.services.analytics_service.tempfile.mktemp', return_value='/tmp/test_chart.png'):
            chart_path = asyncio.run(
                AnalyticsService._create_value_breakdown_chart(sample_analytics_data['value_breakdown'])
            )
            assert chart_path == '/tmp/test_chart.png'
            mock_figure.assert_called()
        
        # Reset mocks
        mock_figure.reset_mock()
        
        # Test trends chart
        with patch('app.services.analytics_service.tempfile.mktemp', return_value='/tmp/trends.png'):
            chart_path = asyncio.run(
                AnalyticsService._create_trends_chart(sample_analytics_data['trends'])
            )
            assert chart_path == '/tmp/trends.png'
            mock_figure.assert_called()
    
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
        
        # PDF export should also handle empty data
        pdf_result = asyncio.run(
            AnalyticsService.export_to_pdf(
                analytics=minimal_data,
                user=sample_user,
                requested_types=['all'],
                days_back=30
            )
        )
        
        assert 'pdf_base64' in pdf_result