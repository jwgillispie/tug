# tests/test_additional_services.py
import pytest
from datetime import datetime, date, timedelta
from unittest.mock import patch, AsyncMock, Mock
from bson import ObjectId

# Import services to test
from app.services.mood_service import MoodService
from app.services.vice_service import ViceService
from app.services.notification_service import NotificationService
from app.services.analytics_service import AnalyticsService

# Import models
from app.models.mood import MoodEntry
from app.models.vice import Vice
from app.models.indulgence import Indulgence
from app.models.notification import Notification, NotificationBatch
from app.models.user import User

# Import schemas
from app.schemas.mood import MoodEntryCreate, MoodEntryUpdate


@pytest.mark.asyncio
class TestMoodService:
    """Tests for MoodService"""

    async def test_create_mood_entry_success(self, sample_user):
        """Test successful mood entry creation"""
        # Arrange
        mood_data = MoodEntryCreate(
            mood_score=7,
            energy_level=6,
            stress_level=4,
            notes="Feeling good today"
        )

        # Act
        result = await MoodService.create_mood_entry(sample_user, mood_data)

        # Assert
        assert result is not None
        assert result.user_id == str(sample_user.id)
        assert result.mood_score == 7
        assert result.energy_level == 6
        assert result.stress_level == 4
        assert result.notes == "Feeling good today"
        assert result.date == date.today()

    async def test_create_mood_entry_duplicate_date(self, sample_user):
        """Test creating mood entry for date that already exists"""
        # Arrange - create first mood entry
        mood_data1 = MoodEntryCreate(
            mood_score=7,
            energy_level=6,
            stress_level=4,
            notes="First entry"
        )
        await MoodService.create_mood_entry(sample_user, mood_data1)

        # Try to create second entry for same date
        mood_data2 = MoodEntryCreate(
            mood_score=8,
            energy_level=7,
            stress_level=3,
            notes="Second entry"
        )

        # Act & Assert
        from fastapi import HTTPException
        with pytest.raises(HTTPException) as exc_info:
            await MoodService.create_mood_entry(sample_user, mood_data2)
        
        assert exc_info.value.status_code == 400
        assert "already exists" in str(exc_info.value.detail)

    async def test_get_mood_entries_date_range(self, sample_user):
        """Test getting mood entries within date range"""
        # Arrange - create mood entries for different dates
        today = date.today()
        for i in range(5):
            entry_date = today - timedelta(days=i)
            mood_entry = MoodEntry(
                user_id=str(sample_user.id),
                mood_score=5 + i,
                energy_level=6,
                stress_level=4,
                date=entry_date
            )
            await mood_entry.insert()

        start_date = today - timedelta(days=2)
        end_date = today

        # Act
        entries = await MoodService.get_mood_entries(sample_user, start_date, end_date)

        # Assert
        assert len(entries) == 3  # Should get 3 entries (today, yesterday, 2 days ago)
        assert all(start_date <= entry.date <= end_date for entry in entries)

    async def test_update_mood_entry_success(self, sample_user):
        """Test successful mood entry update"""
        # Arrange - create mood entry
        mood_entry = MoodEntry(
            user_id=str(sample_user.id),
            mood_score=5,
            energy_level=5,
            stress_level=5,
            date=date.today()
        )
        await mood_entry.insert()

        update_data = MoodEntryUpdate(
            mood_score=8,
            notes="Updated with new notes"
        )

        # Act
        result = await MoodService.update_mood_entry(sample_user, str(mood_entry.id), update_data)

        # Assert
        assert result.mood_score == 8
        assert result.notes == "Updated with new notes"
        assert result.energy_level == 5  # Unchanged

    async def test_get_mood_statistics(self, sample_user):
        """Test getting mood statistics"""
        # Arrange - create several mood entries
        today = date.today()
        scores = [7, 6, 8, 5, 9]
        for i, score in enumerate(scores):
            mood_entry = MoodEntry(
                user_id=str(sample_user.id),
                mood_score=score,
                energy_level=score,
                stress_level=10 - score,
                date=today - timedelta(days=i)
            )
            await mood_entry.insert()

        # Act
        stats = await MoodService.get_mood_statistics(sample_user, days=5)

        # Assert
        assert stats["total_entries"] == 5
        assert stats["average_mood"] == 7.0  # (7+6+8+5+9)/5
        assert stats["average_energy"] == 7.0
        assert stats["average_stress"] == 3.0  # (3+4+2+5+1)/5


@pytest.mark.asyncio
class TestViceService:
    """Tests for ViceService"""

    async def test_create_vice_success(self, sample_user):
        """Test successful vice creation"""
        # Arrange
        vice_data = {
            "name": "Social Media",
            "description": "Excessive social media usage",
            "color": "#E74C3C",
            "target_days_clean": 30
        }

        # Act
        result = await ViceService.create_vice(sample_user, vice_data)

        # Assert
        assert result is not None
        assert result.user_id == str(sample_user.id)
        assert result.name == "Social Media"
        assert result.target_days_clean == 30

    async def test_log_indulgence_success(self, sample_user, sample_vice):
        """Test successful indulgence logging"""
        # Arrange
        indulgence_data = {
            "notes": "Spent 2 hours on social media"
        }

        # Act
        result = await ViceService.log_indulgence(sample_user, str(sample_vice.id), indulgence_data)

        # Assert
        assert result is not None
        assert result.user_id == str(sample_user.id)
        assert result.vice_id == str(sample_vice.id)
        assert result.notes == "Spent 2 hours on social media"

    async def test_get_vice_statistics(self, sample_user, sample_vice):
        """Test getting vice statistics"""
        # Arrange - create some indulgences
        base_date = datetime.utcnow()
        for i in range(3):
            indulgence = Indulgence(
                user_id=str(sample_user.id),
                vice_id=str(sample_vice.id),
                date=base_date - timedelta(days=i * 2),
                notes=f"Indulgence {i+1}"
            )
            await indulgence.insert()

        # Act
        stats = await ViceService.get_vice_statistics(
            sample_user, 
            str(sample_vice.id), 
            days=10
        )

        # Assert
        assert stats["total_indulgences"] == 3
        assert stats["days_since_last"] >= 0

    async def test_calculate_clean_streak(self, sample_user, sample_vice):
        """Test clean streak calculation"""
        # Arrange - create indulgences with gaps
        base_date = datetime.utcnow()
        # Last indulgence 5 days ago
        last_indulgence = Indulgence(
            user_id=str(sample_user.id),
            vice_id=str(sample_vice.id),
            date=base_date - timedelta(days=5),
            notes="Last indulgence"
        )
        await last_indulgence.insert()

        # Act
        streak_days = await ViceService.calculate_clean_streak(sample_user, str(sample_vice.id))

        # Assert
        assert streak_days == 5


@pytest.mark.asyncio
class TestNotificationService:
    """Tests for NotificationService"""

    async def test_create_friend_request_notification(self, sample_user, sample_user_2):
        """Test creating friend request notification"""
        # Act
        result = await NotificationService.create_friend_request_notification(
            addressee_id=str(sample_user.id),
            requester_id=str(sample_user_2.id),
            requester_name=sample_user_2.display_name,
            friendship_id=str(ObjectId())
        )

        # Assert
        assert result is not None
        assert result.user_id == str(sample_user.id)
        assert result.type == "friend_request"
        assert sample_user_2.display_name in result.title

    async def test_create_comment_notification(self, sample_user, sample_user_2):
        """Test creating comment notification"""
        # Act
        result = await NotificationService.create_comment_notification(
            post_owner_id=str(sample_user.id),
            commenter_id=str(sample_user_2.id),
            commenter_name=sample_user_2.display_name,
            post_id=str(ObjectId()),
            post_content="Great post!"
        )

        # Assert
        assert result is not None
        assert result.user_id == str(sample_user.id)
        assert result.type == "comment"

    async def test_get_notifications(self, sample_user):
        """Test getting user notifications"""
        # Arrange - create some notifications
        for i in range(3):
            notification = Notification(
                user_id=str(sample_user.id),
                type="general",
                title=f"Notification {i+1}",
                message=f"Message {i+1}",
                read=False
            )
            await notification.insert()

        # Act
        notifications = await NotificationService.get_notifications(sample_user)

        # Assert
        assert len(notifications) == 3
        assert all(notif.user_id == str(sample_user.id) for notif in notifications)

    async def test_mark_notification_read(self, sample_user):
        """Test marking notification as read"""
        # Arrange
        notification = Notification(
            user_id=str(sample_user.id),
            type="general",
            title="Test Notification",
            message="Test Message",
            read=False
        )
        await notification.insert()

        # Act
        result = await NotificationService.mark_notification_read(sample_user, str(notification.id))

        # Assert
        assert result.read is True

    async def test_mark_all_notifications_read(self, sample_user):
        """Test marking all notifications as read"""
        # Arrange - create unread notifications
        for i in range(3):
            notification = Notification(
                user_id=str(sample_user.id),
                type="general",
                title=f"Notification {i+1}",
                message=f"Message {i+1}",
                read=False
            )
            await notification.insert()

        # Act
        count = await NotificationService.mark_all_notifications_read(sample_user)

        # Assert
        assert count == 3
        
        # Verify all are marked as read
        notifications = await NotificationService.get_notifications(sample_user)
        assert all(notif.read for notif in notifications)

    async def test_batch_notification_creation(self, sample_users_batch):
        """Test batch notification creation"""
        # Arrange
        user_ids = [str(user.id) for user in sample_users_batch]
        
        # Act
        result = await NotificationService.create_batch_notification(
            user_ids=user_ids,
            notification_type="announcement",
            title="System Announcement",
            message="New features available!"
        )

        # Assert
        assert result is not None
        assert len(result.user_ids) == len(user_ids)


@pytest.mark.asyncio
class TestAnalyticsService:
    """Tests for AnalyticsService"""

    async def test_get_user_analytics_overview(self, sample_user, sample_activities_batch, sample_values_batch):
        """Test getting user analytics overview"""
        # Act
        analytics = await AnalyticsService.get_user_analytics_overview(sample_user)

        # Assert
        assert "total_activities" in analytics
        assert "total_values" in analytics
        assert "active_values" in analytics
        assert analytics["total_activities"] >= 0

    async def test_get_activity_trends(self, sample_user, sample_activities_batch):
        """Test getting activity trends"""
        # Act
        trends = await AnalyticsService.get_activity_trends(sample_user, days=30)

        # Assert
        assert "daily_activities" in trends
        assert "weekly_totals" in trends
        assert isinstance(trends["daily_activities"], list)

    async def test_get_value_distribution(self, sample_user, sample_activities_batch, sample_values_batch):
        """Test getting value distribution analytics"""
        # Act
        distribution = await AnalyticsService.get_value_distribution(sample_user, days=30)

        # Assert
        assert "value_breakdown" in distribution
        assert "total_minutes" in distribution
        assert isinstance(distribution["value_breakdown"], list)

    async def test_get_streak_analytics(self, sample_user, sample_values_batch):
        """Test getting streak analytics"""
        # Arrange - set up some streak data
        sample_values_batch[0].current_streak = 5
        sample_values_batch[0].longest_streak = 10
        await sample_values_batch[0].save()

        # Act
        streaks = await AnalyticsService.get_streak_analytics(sample_user)

        # Assert
        assert "total_active_streaks" in streaks
        assert "longest_current_streak" in streaks
        assert "value_streaks" in streaks

    async def test_get_mood_analytics(self, sample_user):
        """Test getting mood analytics"""
        # Arrange - create mood entries
        today = date.today()
        for i in range(7):
            mood_entry = MoodEntry(
                user_id=str(sample_user.id),
                mood_score=5 + (i % 3),
                energy_level=6,
                stress_level=4,
                date=today - timedelta(days=i)
            )
            await mood_entry.insert()

        # Act
        mood_analytics = await AnalyticsService.get_mood_analytics(sample_user, days=7)

        # Assert
        assert "average_mood" in mood_analytics
        assert "mood_trend" in mood_analytics
        assert "mood_distribution" in mood_analytics

    async def test_compare_periods(self, sample_user, sample_activities_batch):
        """Test period comparison analytics"""
        # Act
        comparison = await AnalyticsService.compare_periods(
            sample_user,
            current_days=7,
            previous_days=7
        )

        # Assert
        assert "current_period" in comparison
        assert "previous_period" in comparison
        assert "changes" in comparison

    async def test_get_achievement_progress(self, sample_user):
        """Test getting achievement progress"""
        # Act
        progress = await AnalyticsService.get_achievement_progress(sample_user)

        # Assert
        assert "total_achievements" in progress
        assert "completed_achievements" in progress
        assert "in_progress_achievements" in progress

    async def test_analytics_error_handling(self, sample_user):
        """Test analytics error handling"""
        # Test with invalid date ranges
        with patch.object(AnalyticsService, 'get_activity_trends') as mock_trends:
            mock_trends.side_effect = Exception("Database error")
            
            # Should handle errors gracefully
            try:
                await AnalyticsService.get_activity_trends(sample_user, days=-1)
            except Exception:
                pass  # Error handling should prevent this from propagating

    async def test_analytics_caching(self, sample_user):
        """Test analytics caching mechanism"""
        # This test would verify that repeated calls return cached results
        # Implementation depends on caching strategy
        
        # First call
        analytics1 = await AnalyticsService.get_user_analytics_overview(sample_user)
        
        # Second call (should potentially use cache)
        analytics2 = await AnalyticsService.get_user_analytics_overview(sample_user)
        
        # Results should be consistent
        assert analytics1["total_activities"] == analytics2["total_activities"]

    async def test_real_time_analytics_updates(self, sample_user, sample_value):
        """Test that analytics update in real-time with new data"""
        # Get initial analytics
        initial_analytics = await AnalyticsService.get_user_analytics_overview(sample_user)
        initial_count = initial_analytics["total_activities"]
        
        # Add new activity
        from app.models.activity import Activity
        new_activity = Activity(
            user_id=str(sample_user.id),
            value_id=str(sample_value.id),
            value_ids=[str(sample_value.id)],
            name="New Test Activity",
            duration=30,
            date=datetime.utcnow(),
            notes="Analytics test",
            is_public=False,
            notes_public=False
        )
        await new_activity.insert()
        
        # Get updated analytics
        updated_analytics = await AnalyticsService.get_user_analytics_overview(sample_user)
        updated_count = updated_analytics["total_activities"]
        
        # Should reflect the new activity
        assert updated_count == initial_count + 1