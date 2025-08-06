# tests/test_activity_service.py
import pytest
from datetime import datetime, timedelta
from fastapi import HTTPException
from bson import ObjectId
from unittest.mock import AsyncMock, patch

from app.services.activity_service import ActivityService
from app.models.activity import Activity
from app.models.value import Value
from app.models.user import User
from app.schemas.activity import ActivityCreate, ActivityUpdate


@pytest.mark.asyncio
class TestActivityService:
    """Comprehensive tests for ActivityService"""

    async def test_create_activity_success(self, sample_user, sample_value):
        """Test successful activity creation"""
        # Arrange
        activity_data = ActivityCreate(
            value_ids=[str(sample_value.id)],
            name="Test Activity",
            duration=45,
            date=datetime.utcnow(),
            notes="Test notes",
            is_public=False,
            notes_public=False
        )

        # Act
        result = await ActivityService.create_activity(sample_user, activity_data)

        # Assert
        assert result is not None
        assert result.user_id == str(sample_user.id)
        assert result.name == "Test Activity"
        assert result.duration == 45
        assert result.notes == "Test notes"
        assert result.is_public is False
        assert result.notes_public is False
        assert str(sample_value.id) in result.value_ids

    async def test_create_activity_with_multiple_values(self, sample_user, sample_values_batch):
        """Test creating activity with multiple values"""
        # Arrange
        value_ids = [str(v.id) for v in sample_values_batch[:3]]
        activity_data = ActivityCreate(
            value_ids=value_ids,
            name="Multi-value Activity",
            duration=60,
            date=datetime.utcnow(),
            notes="Activity with multiple values",
            is_public=True,
            notes_public=True
        )

        # Act
        result = await ActivityService.create_activity(sample_user, activity_data)

        # Assert
        assert result is not None
        assert len(result.value_ids) == 3
        assert all(vid in [str(v.id) for v in sample_values_batch[:3]] for vid in result.value_ids)
        assert result.value_id == value_ids[0]  # First value for backward compatibility

    async def test_create_activity_nonexistent_value(self, sample_user):
        """Test creating activity with non-existent value"""
        # Arrange
        fake_value_id = str(ObjectId())
        activity_data = ActivityCreate(
            value_ids=[fake_value_id],
            name="Test Activity",
            duration=45,
            date=datetime.utcnow(),
            notes="Test notes",
            is_public=False,
            notes_public=False
        )

        # Act & Assert
        with pytest.raises(HTTPException) as exc_info:
            await ActivityService.create_activity(sample_user, activity_data)
        
        assert exc_info.value.status_code == 404
        assert "Values not found" in str(exc_info.value.detail)

    async def test_create_activity_future_date(self, sample_user, sample_value):
        """Test creating activity with future date should fail"""
        # Arrange
        future_date = datetime.utcnow() + timedelta(days=1)
        activity_data = ActivityCreate(
            value_ids=[str(sample_value.id)],
            name="Future Activity",
            duration=45,
            date=future_date,
            notes="Test notes",
            is_public=False,
            notes_public=False
        )

        # Act & Assert
        with pytest.raises(HTTPException) as exc_info:
            await ActivityService.create_activity(sample_user, activity_data)
        
        assert exc_info.value.status_code == 400
        assert "Cannot log future activities" in str(exc_info.value.detail)

    async def test_create_activity_creates_social_post(self, sample_user, sample_value):
        """Test that public activity with notes creates social post"""
        # Arrange
        activity_data = ActivityCreate(
            value_ids=[str(sample_value.id)],
            name="Public Activity",
            duration=30,
            date=datetime.utcnow(),
            notes="This is a public activity!",
            is_public=True,
            notes_public=True
        )

        # Mock the social post creation
        with patch.object(ActivityService, '_create_activity_social_post') as mock_social_post:
            mock_social_post.return_value = AsyncMock()

            # Act
            result = await ActivityService.create_activity(sample_user, activity_data)

            # Assert
            assert result is not None
            mock_social_post.assert_called_once()

    async def test_get_activities_all(self, sample_user, sample_activities_batch):
        """Test getting all activities for a user"""
        # Act
        activities = await ActivityService.get_activities(sample_user)

        # Assert
        assert len(activities) == len(sample_activities_batch)
        assert all(activity.user_id == str(sample_user.id) for activity in activities)
        # Should be sorted by date descending
        assert activities[0].date >= activities[-1].date

    async def test_get_activities_with_value_filter(self, sample_user, sample_activities_batch, sample_values_batch):
        """Test getting activities filtered by value"""
        # Arrange
        target_value = sample_values_batch[0]
        
        # Act
        activities = await ActivityService.get_activities(sample_user, value_id=str(target_value.id))

        # Assert
        assert all(activity.value_id == str(target_value.id) for activity in activities)

    async def test_get_activities_with_date_range(self, sample_user, sample_activities_batch):
        """Test getting activities with date range filter"""
        # Arrange
        start_date = datetime.utcnow() - timedelta(days=2)
        end_date = datetime.utcnow() - timedelta(days=1)

        # Act
        activities = await ActivityService.get_activities(
            sample_user, 
            start_date=start_date, 
            end_date=end_date
        )

        # Assert
        for activity in activities:
            assert start_date <= activity.date <= end_date

    async def test_get_activities_with_pagination(self, sample_user, sample_activities_batch):
        """Test getting activities with pagination"""
        # Act
        first_page = await ActivityService.get_activities(sample_user, limit=2, skip=0)
        second_page = await ActivityService.get_activities(sample_user, limit=2, skip=2)

        # Assert
        assert len(first_page) <= 2
        assert len(second_page) <= 2
        # No overlap between pages
        first_ids = {str(a.id) for a in first_page}
        second_ids = {str(a.id) for a in second_page}
        assert not first_ids.intersection(second_ids)

    async def test_get_activity_success(self, sample_user, sample_activity):
        """Test getting specific activity by ID"""
        # Act
        result = await ActivityService.get_activity(sample_user, str(sample_activity.id))

        # Assert
        assert result is not None
        assert str(result.id) == str(sample_activity.id)
        assert result.user_id == str(sample_user.id)

    async def test_get_activity_not_found(self, sample_user):
        """Test getting non-existent activity"""
        # Arrange
        fake_id = str(ObjectId())

        # Act & Assert
        with pytest.raises(HTTPException) as exc_info:
            await ActivityService.get_activity(sample_user, fake_id)
        
        assert exc_info.value.status_code == 404
        assert "Activity not found" in str(exc_info.value.detail)

    async def test_get_activity_wrong_user(self, sample_user, sample_user_2, sample_activity):
        """Test getting activity from different user should fail"""
        # Act & Assert
        with pytest.raises(HTTPException) as exc_info:
            await ActivityService.get_activity(sample_user_2, str(sample_activity.id))
        
        assert exc_info.value.status_code == 404

    async def test_update_activity_success(self, sample_user, sample_activity):
        """Test successful activity update"""
        # Arrange
        update_data = ActivityUpdate(
            name="Updated Activity Name",
            duration=60,
            notes="Updated notes"
        )

        # Act
        result = await ActivityService.update_activity(sample_user, str(sample_activity.id), update_data)

        # Assert
        assert result is not None
        assert result.name == "Updated Activity Name"
        assert result.duration == 60
        assert result.notes == "Updated notes"

    async def test_update_activity_partial_update(self, sample_user, sample_activity):
        """Test partial activity update"""
        # Arrange
        original_name = sample_activity.name
        update_data = ActivityUpdate(duration=120)  # Only update duration

        # Act
        result = await ActivityService.update_activity(sample_user, str(sample_activity.id), update_data)

        # Assert
        assert result.name == original_name  # Should remain unchanged
        assert result.duration == 120

    async def test_update_activity_with_new_value(self, sample_user, sample_activity, sample_values_batch):
        """Test updating activity with new value"""
        # Arrange
        new_value = sample_values_batch[1]
        update_data = ActivityUpdate(value_id=str(new_value.id))

        # Act
        result = await ActivityService.update_activity(sample_user, str(sample_activity.id), update_data)

        # Assert
        assert result.value_id == str(new_value.id)

    async def test_update_activity_with_invalid_value(self, sample_user, sample_activity):
        """Test updating activity with invalid value"""
        # Arrange
        fake_value_id = str(ObjectId())
        update_data = ActivityUpdate(value_id=fake_value_id)

        # Act & Assert
        with pytest.raises(HTTPException) as exc_info:
            await ActivityService.update_activity(sample_user, str(sample_activity.id), update_data)
        
        assert exc_info.value.status_code == 404
        assert "Value not found" in str(exc_info.value.detail)

    async def test_update_activity_future_date(self, sample_user, sample_activity):
        """Test updating activity with future date should fail"""
        # Arrange
        future_date = datetime.utcnow() + timedelta(days=1)
        update_data = ActivityUpdate(date=future_date)

        # Act & Assert
        with pytest.raises(HTTPException) as exc_info:
            await ActivityService.update_activity(sample_user, str(sample_activity.id), update_data)
        
        assert exc_info.value.status_code == 400
        assert "Cannot log future activities" in str(exc_info.value.detail)

    async def test_update_activity_not_found(self, sample_user):
        """Test updating non-existent activity"""
        # Arrange
        fake_id = str(ObjectId())
        update_data = ActivityUpdate(name="Updated Name")

        # Act & Assert
        with pytest.raises(HTTPException) as exc_info:
            await ActivityService.update_activity(sample_user, fake_id, update_data)
        
        assert exc_info.value.status_code == 404

    async def test_delete_activity_success(self, sample_user, sample_activity):
        """Test successful activity deletion"""
        # Act
        await ActivityService.delete_activity(sample_user, str(sample_activity.id))

        # Assert - verify activity is deleted
        with pytest.raises(HTTPException):
            await ActivityService.get_activity(sample_user, str(sample_activity.id))

    async def test_delete_activity_not_found(self, sample_user):
        """Test deleting non-existent activity"""
        # Arrange
        fake_id = str(ObjectId())

        # Act & Assert
        with pytest.raises(HTTPException) as exc_info:
            await ActivityService.delete_activity(sample_user, fake_id)
        
        assert exc_info.value.status_code == 404

    async def test_get_activity_statistics_default_period(self, sample_user, sample_activities_batch):
        """Test getting activity statistics for default period"""
        # Act
        stats = await ActivityService.get_activity_statistics(sample_user)

        # Assert
        assert "total_activities" in stats
        assert "total_duration_minutes" in stats
        assert "total_duration_hours" in stats
        assert "average_duration_minutes" in stats
        assert stats["total_activities"] >= 0
        assert stats["total_duration_minutes"] >= 0
        assert stats["total_duration_hours"] >= 0

    async def test_get_activity_statistics_with_value_filter(self, sample_user, sample_activities_batch, sample_values_batch):
        """Test getting activity statistics filtered by value"""
        # Arrange
        target_value = sample_values_batch[0]

        # Act
        stats = await ActivityService.get_activity_statistics(sample_user, value_id=str(target_value.id))

        # Assert
        assert stats["total_activities"] >= 0
        # Should only include activities for the specific value

    async def test_get_activity_statistics_custom_date_range(self, sample_user, sample_activities_batch):
        """Test getting activity statistics for custom date range"""
        # Arrange
        start_date = datetime.utcnow() - timedelta(days=7)
        end_date = datetime.utcnow()

        # Act
        stats = await ActivityService.get_activity_statistics(
            sample_user, 
            start_date=start_date, 
            end_date=end_date
        )

        # Assert
        assert "total_activities" in stats
        assert stats["total_activities"] >= 0

    async def test_get_activity_statistics_no_activities(self, sample_user):
        """Test getting statistics when user has no activities"""
        # Act
        stats = await ActivityService.get_activity_statistics(sample_user)

        # Assert
        assert stats["total_activities"] == 0
        assert stats["total_duration_minutes"] == 0
        assert stats["total_duration_hours"] == 0
        assert stats["average_duration_minutes"] == 0

    async def test_get_value_activity_summary_default_period(self, sample_user, sample_activities_batch, sample_values_batch):
        """Test getting value activity summary for default period"""
        # Act
        summary = await ActivityService.get_value_activity_summary(sample_user)

        # Assert
        assert "period_start" in summary
        assert "period_end" in summary
        assert "period_days" in summary
        assert "values" in summary
        assert isinstance(summary["values"], list)
        
        # Check structure of value data
        if summary["values"]:
            value_data = summary["values"][0]
            assert "id" in value_data
            assert "name" in value_data
            assert "minutes" in value_data
            assert "count" in value_data
            assert "daily_average" in value_data

    async def test_get_value_activity_summary_custom_date_range(self, sample_user, sample_activities_batch):
        """Test getting value activity summary for custom date range"""
        # Arrange
        start_date = datetime.utcnow() - timedelta(days=14)
        end_date = datetime.utcnow() - timedelta(days=7)

        # Act
        summary = await ActivityService.get_value_activity_summary(
            sample_user,
            start_date=start_date,
            end_date=end_date
        )

        # Assert
        assert summary["period_start"] == start_date
        assert summary["period_end"] == end_date
        assert summary["period_days"] == 8  # 14-7+1

    async def test_get_value_activity_summary_no_activities(self, sample_user, sample_values_batch):
        """Test getting summary when user has values but no activities"""
        # Act
        summary = await ActivityService.get_value_activity_summary(sample_user)

        # Assert
        assert len(summary["values"]) > 0  # Should include all user values
        for value_data in summary["values"]:
            assert value_data["minutes"] == 0
            assert value_data["count"] == 0
            assert value_data["daily_average"] == 0

    async def test_create_activity_social_post_success(self, sample_user, sample_activity, sample_value):
        """Test creating social post for activity"""
        # Mock SocialPost creation
        with patch('app.services.activity_service.SocialPost') as mock_post:
            mock_instance = AsyncMock()
            mock_post.return_value = mock_instance

            # Act
            await ActivityService._create_activity_social_post(sample_user, sample_activity, sample_value)

            # Assert
            mock_post.assert_called_once()
            mock_instance.save.assert_called_once()

    async def test_create_activity_social_post_exception_handling(self, sample_user, sample_activity, sample_value):
        """Test that social post creation exceptions don't break activity creation"""
        # Mock SocialPost to raise exception
        with patch('app.services.activity_service.SocialPost') as mock_post:
            mock_post.side_effect = Exception("Social post error")

            # Act - should not raise exception
            await ActivityService._create_activity_social_post(sample_user, sample_activity, sample_value)
            
            # If we get here without exception, the test passes

    async def test_create_activity_edge_cases(self, sample_user, sample_value):
        """Test activity creation edge cases"""
        # Test with zero duration
        activity_data = ActivityCreate(
            value_ids=[str(sample_value.id)],
            name="Zero Duration Activity",
            duration=0,
            date=datetime.utcnow(),
            notes="",
            is_public=False,
            notes_public=False
        )

        result = await ActivityService.create_activity(sample_user, activity_data)
        assert result.duration == 0

        # Test with very long name
        long_name = "A" * 100
        activity_data = ActivityCreate(
            value_ids=[str(sample_value.id)],
            name=long_name,
            duration=30,
            date=datetime.utcnow(),
            notes="",
            is_public=False,
            notes_public=False
        )

        result = await ActivityService.create_activity(sample_user, activity_data)
        assert result.name == long_name