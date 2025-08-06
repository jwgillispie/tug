# tests/test_value_service.py
import pytest
from datetime import datetime, date, timedelta
from fastapi import HTTPException
from bson import ObjectId
from unittest.mock import patch, AsyncMock

from app.services.value_service import ValueService
from app.models.value import Value
from app.models.user import User
from app.schemas.value import ValueCreate, ValueUpdate


@pytest.mark.asyncio
class TestValueService:
    """Comprehensive tests for ValueService"""

    async def test_create_value_success(self, sample_user):
        """Test successful value creation"""
        # Arrange
        value_data = ValueCreate(
            name="Test Value",
            importance=4,
            description="A test value for testing",
            color="#FF5733"
        )

        # Act
        result = await ValueService.create_value(sample_user, value_data)

        # Assert
        assert result is not None
        assert result.user_id == str(sample_user.id)
        assert result.name == "Test Value"
        assert result.importance == 4
        assert result.description == "A test value for testing"
        assert result.color == "#FF5733"
        assert result.active is True

    async def test_create_value_maximum_limit_reached(self, sample_user):
        """Test creating value when maximum limit (5) is reached"""
        # Arrange - create 5 active values first
        for i in range(5):
            value = Value(
                user_id=str(sample_user.id),
                name=f"Value {i+1}",
                importance=3,
                description=f"Test value {i+1}",
                color="#000000",
                active=True
            )
            await value.insert()

        value_data = ValueCreate(
            name="Sixth Value",
            importance=4,
            description="This should fail",
            color="#FF5733"
        )

        # Act & Assert
        with pytest.raises(HTTPException) as exc_info:
            await ValueService.create_value(sample_user, value_data)
        
        assert exc_info.value.status_code == 400
        assert "Maximum 5 active values allowed" in str(exc_info.value.detail)

    async def test_create_value_with_inactive_values_allows_creation(self, sample_user):
        """Test that inactive values don't count toward the 5-value limit"""
        # Arrange - create 5 inactive values and 4 active values
        for i in range(5):
            value = Value(
                user_id=str(sample_user.id),
                name=f"Inactive Value {i+1}",
                importance=3,
                description=f"Inactive test value {i+1}",
                color="#000000",
                active=False
            )
            await value.insert()

        for i in range(4):
            value = Value(
                user_id=str(sample_user.id),
                name=f"Active Value {i+1}",
                importance=3,
                description=f"Active test value {i+1}",
                color="#000000",
                active=True
            )
            await value.insert()

        value_data = ValueCreate(
            name="Fifth Active Value",
            importance=4,
            description="This should succeed",
            color="#FF5733"
        )

        # Act
        result = await ValueService.create_value(sample_user, value_data)

        # Assert
        assert result is not None
        assert result.name == "Fifth Active Value"

    async def test_get_values_active_only(self, sample_user, sample_values_batch):
        """Test getting only active values (default behavior)"""
        # Arrange - make some values inactive
        sample_values_batch[1].active = False
        await sample_values_batch[1].save()
        sample_values_batch[2].active = False
        await sample_values_batch[2].save()

        # Act
        result = await ValueService.get_values(sample_user)

        # Assert
        assert len(result) == 3  # Only active values
        assert all(value.active for value in result)
        # Should be sorted by importance descending
        if len(result) > 1:
            assert result[0].importance >= result[-1].importance

    async def test_get_values_include_inactive(self, sample_user, sample_values_batch):
        """Test getting all values including inactive ones"""
        # Arrange - make some values inactive
        sample_values_batch[1].active = False
        await sample_values_batch[1].save()

        # Act
        result = await ValueService.get_values(sample_user, include_inactive=True)

        # Assert
        assert len(result) == len(sample_values_batch)
        # Should include both active and inactive values

    async def test_get_values_empty_result(self, sample_user):
        """Test getting values when user has none"""
        # Act
        result = await ValueService.get_values(sample_user)

        # Assert
        assert len(result) == 0
        assert isinstance(result, list)

    async def test_get_values_sorting(self, sample_user):
        """Test that values are sorted by importance descending"""
        # Arrange - create values with different importance levels
        importance_levels = [1, 5, 3, 4, 2]
        for i, importance in enumerate(importance_levels):
            value = Value(
                user_id=str(sample_user.id),
                name=f"Value {i}",
                importance=importance,
                description=f"Test value {i}",
                color="#000000",
                active=True
            )
            await value.insert()

        # Act
        result = await ValueService.get_values(sample_user)

        # Assert
        assert len(result) == 5
        # Check sorting - should be [5, 4, 3, 2, 1]
        for i in range(len(result) - 1):
            assert result[i].importance >= result[i + 1].importance

    async def test_get_value_success(self, sample_user, sample_value):
        """Test getting specific value by ID"""
        # Act
        result = await ValueService.get_value(sample_user, str(sample_value.id))

        # Assert
        assert result is not None
        assert str(result.id) == str(sample_value.id)
        assert result.user_id == str(sample_user.id)

    async def test_get_value_not_found(self, sample_user):
        """Test getting non-existent value"""
        # Arrange
        fake_id = str(ObjectId())

        # Act & Assert
        with pytest.raises(HTTPException) as exc_info:
            await ValueService.get_value(sample_user, fake_id)
        
        assert exc_info.value.status_code == 404
        assert "Value not found" in str(exc_info.value.detail)

    async def test_get_value_wrong_user(self, sample_user, sample_user_2, sample_value):
        """Test getting value that belongs to different user"""
        # Act & Assert
        with pytest.raises(HTTPException) as exc_info:
            await ValueService.get_value(sample_user_2, str(sample_value.id))
        
        assert exc_info.value.status_code == 404

    async def test_get_value_invalid_id_format(self, sample_user):
        """Test getting value with invalid ObjectId format"""
        # Arrange
        invalid_id = "not_a_valid_object_id"

        # Act & Assert
        with pytest.raises(HTTPException) as exc_info:
            await ValueService.get_value(sample_user, invalid_id)
        
        assert exc_info.value.status_code == 404

    async def test_update_value_success(self, sample_user, sample_value):
        """Test successful value update"""
        # Arrange
        update_data = ValueUpdate(
            name="Updated Value Name",
            importance=3,
            description="Updated description",
            color="#00FF00"
        )

        # Act
        result = await ValueService.update_value(sample_user, str(sample_value.id), update_data)

        # Assert
        assert result is not None
        assert result.name == "Updated Value Name"
        assert result.importance == 3
        assert result.description == "Updated description"
        assert result.color == "#00FF00"
        assert result.updated_at > sample_value.updated_at

    async def test_update_value_partial_update(self, sample_user, sample_value):
        """Test partial value update"""
        # Arrange
        original_name = sample_value.name
        original_color = sample_value.color
        update_data = ValueUpdate(importance=2)  # Only update importance

        # Act
        result = await ValueService.update_value(sample_user, str(sample_value.id), update_data)

        # Assert
        assert result.name == original_name  # Should remain unchanged
        assert result.color == original_color  # Should remain unchanged
        assert result.importance == 2

    async def test_update_value_not_found(self, sample_user):
        """Test updating non-existent value"""
        # Arrange
        fake_id = str(ObjectId())
        update_data = ValueUpdate(name="Updated Name")

        # Act & Assert
        with pytest.raises(HTTPException) as exc_info:
            await ValueService.update_value(sample_user, fake_id, update_data)
        
        assert exc_info.value.status_code == 404

    async def test_update_value_wrong_user(self, sample_user, sample_user_2, sample_value):
        """Test updating value that belongs to different user"""
        # Arrange
        update_data = ValueUpdate(name="Hacked Name")

        # Act & Assert
        with pytest.raises(HTTPException) as exc_info:
            await ValueService.update_value(sample_user_2, str(sample_value.id), update_data)
        
        assert exc_info.value.status_code == 404

    async def test_update_value_exception_handling(self, sample_user, sample_value):
        """Test error handling during value update"""
        # Arrange
        update_data = ValueUpdate(name="Updated Name")
        
        # Mock find_one to raise an exception
        with patch.object(Value, 'find_one', side_effect=Exception("Database error")):
            # Act & Assert
            with pytest.raises(HTTPException) as exc_info:
                await ValueService.update_value(sample_user, str(sample_value.id), update_data)
            
            assert exc_info.value.status_code == 500

    async def test_check_value_exists_success(self, sample_user, sample_value):
        """Test checking if value exists - positive case"""
        # Act
        result = await ValueService.check_value_exists(sample_user, str(sample_value.id))

        # Assert
        assert result is True

    async def test_check_value_exists_not_found(self, sample_user):
        """Test checking if value exists - negative case"""
        # Arrange
        fake_id = str(ObjectId())

        # Act
        result = await ValueService.check_value_exists(sample_user, fake_id)

        # Assert
        assert result is False

    async def test_check_value_exists_wrong_user(self, sample_user, sample_user_2, sample_value):
        """Test checking value existence for different user"""
        # Act
        result = await ValueService.check_value_exists(sample_user_2, str(sample_value.id))

        # Assert
        assert result is False

    async def test_check_value_exists_invalid_id(self, sample_user):
        """Test checking value existence with invalid ID"""
        # Arrange
        invalid_id = "not_valid_object_id"

        # Act
        result = await ValueService.check_value_exists(sample_user, invalid_id)

        # Assert
        assert result is False

    async def test_get_value_counts_by_user(self, sample_user, sample_values_batch):
        """Test getting value counts for user"""
        # Arrange - make some values inactive
        sample_values_batch[1].active = False
        await sample_values_batch[1].save()
        sample_values_batch[2].active = False
        await sample_values_batch[2].save()

        # Act
        result = await ValueService.get_value_counts_by_user(sample_user)

        # Assert
        assert "total" in result
        assert "active" in result
        assert result["total"] == len(sample_values_batch)
        assert result["active"] == len(sample_values_batch) - 2

    async def test_get_value_counts_no_values(self, sample_user):
        """Test getting counts when user has no values"""
        # Act
        result = await ValueService.get_value_counts_by_user(sample_user)

        # Assert
        assert result["total"] == 0
        assert result["active"] == 0

    async def test_update_streak_new_value(self, sample_value):
        """Test updating streak for value with no previous streak data"""
        # Arrange
        activity_date = datetime.utcnow()

        # Act
        result = await ValueService.update_streak(str(sample_value.id), activity_date)

        # Assert
        assert result is not None
        assert result.current_streak == 1
        assert result.longest_streak == 1
        assert result.last_activity_date == activity_date.date()
        assert activity_date.date() in result.streak_dates

    async def test_update_streak_consecutive_days(self, sample_value):
        """Test updating streak with consecutive days"""
        # Arrange
        day1 = datetime.utcnow() - timedelta(days=2)
        day2 = datetime.utcnow() - timedelta(days=1)
        day3 = datetime.utcnow()

        # Act - day 1
        await ValueService.update_streak(str(sample_value.id), day1)
        # Act - day 2 (consecutive)
        result2 = await ValueService.update_streak(str(sample_value.id), day2)
        # Act - day 3 (consecutive)
        result3 = await ValueService.update_streak(str(sample_value.id), day3)

        # Assert
        assert result3.current_streak == 3
        assert result3.longest_streak == 3
        assert len(result3.streak_dates) == 3

    async def test_update_streak_non_consecutive_resets(self, sample_value):
        """Test that non-consecutive days reset the streak"""
        # Arrange
        day1 = datetime.utcnow() - timedelta(days=5)
        day2 = datetime.utcnow()  # Gap of 4 days

        # Act
        await ValueService.update_streak(str(sample_value.id), day1)
        result = await ValueService.update_streak(str(sample_value.id), day2)

        # Assert
        assert result.current_streak == 1  # Reset to 1
        assert result.longest_streak == 1  # Previous streak was only 1

    async def test_update_streak_same_date_twice(self, sample_value):
        """Test updating streak with same date twice (should not change)"""
        # Arrange
        activity_date = datetime.utcnow()

        # Act
        result1 = await ValueService.update_streak(str(sample_value.id), activity_date)
        result2 = await ValueService.update_streak(str(sample_value.id), activity_date)

        # Assert
        assert result1.current_streak == result2.current_streak
        assert len(result1.streak_dates) == len(result2.streak_dates)

    async def test_update_streak_longest_streak_tracking(self, sample_value):
        """Test that longest streak is properly tracked"""
        # Arrange - create a streak of 3 days, then break it, then start a new streak of 2
        base_date = datetime.utcnow() - timedelta(days=10)
        
        # First streak: 3 consecutive days
        for i in range(3):
            await ValueService.update_streak(str(sample_value.id), base_date + timedelta(days=i))
        
        # Break the streak (skip several days)
        new_start = base_date + timedelta(days=7)
        
        # New streak: 2 consecutive days
        result = await ValueService.update_streak(str(sample_value.id), new_start)
        assert result.current_streak == 1
        assert result.longest_streak == 3  # Should remember the previous longest
        
        result = await ValueService.update_streak(str(sample_value.id), new_start + timedelta(days=1))

        # Assert
        assert result.current_streak == 2
        assert result.longest_streak == 3  # Still remembers the longer streak

    async def test_update_streak_value_not_found(self):
        """Test updating streak for non-existent value"""
        # Arrange
        fake_id = str(ObjectId())
        activity_date = datetime.utcnow()

        # Act
        result = await ValueService.update_streak(fake_id, activity_date)

        # Assert
        assert result is None

    async def test_check_and_reset_streaks_recent_activity(self, sample_user, sample_values_batch):
        """Test that recent activity doesn't reset streaks"""
        # Arrange - set up values with recent activity (yesterday)
        yesterday = date.today() - timedelta(days=1)
        for value in sample_values_batch[:2]:
            value.current_streak = 5
            value.last_activity_date = yesterday
            await value.save()

        # Act
        await ValueService.check_and_reset_streaks(sample_user)

        # Assert - streaks should not be reset
        updated_values = await Value.find({"user_id": str(sample_user.id)}).to_list()
        for value in updated_values[:2]:
            assert value.current_streak == 5  # Should not be reset

    async def test_check_and_reset_streaks_old_activity(self, sample_user, sample_values_batch):
        """Test that old activity resets streaks"""
        # Arrange - set up values with old activity (3 days ago)
        old_date = date.today() - timedelta(days=3)
        for value in sample_values_batch[:2]:
            value.current_streak = 5
            value.last_activity_date = old_date
            await value.save()

        # Act
        await ValueService.check_and_reset_streaks(sample_user)

        # Assert - streaks should be reset
        updated_values = await Value.find({"user_id": str(sample_user.id)}).to_list()
        for value in updated_values[:2]:
            assert value.current_streak == 0  # Should be reset

    async def test_get_streak_stats_specific_value(self, sample_user, sample_value):
        """Test getting streak statistics for specific value"""
        # Arrange - set up value with streak data
        sample_value.current_streak = 3
        sample_value.longest_streak = 7
        sample_value.last_activity_date = date.today() - timedelta(days=1)
        await sample_value.save()

        # Act
        stats = await ValueService.get_streak_stats(sample_user, str(sample_value.id))

        # Assert
        assert stats["current_streak"] == 3
        assert stats["longest_streak"] == 7
        assert stats["streak_active"] is True  # Activity was yesterday

    async def test_get_streak_stats_inactive_streak(self, sample_user, sample_value):
        """Test getting streak stats when streak is inactive"""
        # Arrange - set up value with old activity
        sample_value.current_streak = 5
        sample_value.longest_streak = 10
        sample_value.last_activity_date = date.today() - timedelta(days=3)
        await sample_value.save()

        # Act
        stats = await ValueService.get_streak_stats(sample_user, str(sample_value.id))

        # Assert
        assert stats["current_streak"] == 5
        assert stats["longest_streak"] == 10
        assert stats["streak_active"] is False  # Activity was 3 days ago

    async def test_get_streak_stats_value_not_found(self, sample_user):
        """Test getting streak stats for non-existent value"""
        # Arrange
        fake_id = str(ObjectId())

        # Act
        stats = await ValueService.get_streak_stats(sample_user, fake_id)

        # Assert
        assert stats["current_streak"] == 0
        assert stats["longest_streak"] == 0
        assert stats["streak_active"] is False

    async def test_get_streak_stats_all_values(self, sample_user, sample_values_batch):
        """Test getting streak statistics for all values"""
        # Arrange - set up some values with streak data
        sample_values_batch[0].current_streak = 3
        sample_values_batch[0].longest_streak = 5
        sample_values_batch[0].last_activity_date = date.today()
        await sample_values_batch[0].save()

        sample_values_batch[1].current_streak = 1
        sample_values_batch[1].longest_streak = 8
        sample_values_batch[1].last_activity_date = date.today() - timedelta(days=2)
        await sample_values_batch[1].save()

        # Act
        stats = await ValueService.get_streak_stats(sample_user)

        # Assert
        assert isinstance(stats, dict)
        assert len(stats) >= 2
        
        # Check specific value stats
        value_0_id = str(sample_values_batch[0].id)
        assert value_0_id in stats
        assert stats[value_0_id]["current_streak"] == 3
        assert stats[value_0_id]["streak_active"] is True

        value_1_id = str(sample_values_batch[1].id)
        assert value_1_id in stats
        assert stats[value_1_id]["current_streak"] == 1
        assert stats[value_1_id]["streak_active"] is False

    async def test_streak_error_handling(self):
        """Test error handling in streak operations"""
        # Test update_streak with exception
        with patch.object(Value, 'find_one', side_effect=Exception("Database error")):
            result = await ValueService.update_streak(str(ObjectId()), datetime.utcnow())
            assert result is None

        # Test get_streak_stats with exception  
        sample_user = User(firebase_uid="test", email="test@example.com", display_name="Test")
        with patch.object(Value, 'find_one', side_effect=Exception("Database error")):
            stats = await ValueService.get_streak_stats(sample_user, str(ObjectId()))
            assert stats == {}

    async def test_value_edge_cases(self, sample_user):
        """Test value creation and update edge cases"""
        # Test with extreme importance values
        value_data = ValueCreate(
            name="Edge Case Value",
            importance=5,  # Maximum importance
            description="",  # Empty description
            color="#FFFFFF"
        )
        
        result = await ValueService.create_value(sample_user, value_data)
        assert result.importance == 5
        assert result.description == ""

        # Test update with minimal data
        update_data = ValueUpdate()  # Empty update
        updated = await ValueService.update_value(sample_user, str(result.id), update_data)
        assert str(updated.id) == str(result.id)  # Should not fail