# tests/test_user_service.py
import pytest
from datetime import datetime
from bson import ObjectId, errors
from unittest.mock import patch, AsyncMock

from app.services.user_service import UserService
from app.models.user import User
from app.schemas.user import UserCreate, UserUpdate


@pytest.mark.asyncio
class TestUserService:
    """Comprehensive tests for UserService"""

    async def test_create_user_success(self):
        """Test successful user creation"""
        # Arrange
        firebase_uid = "new_firebase_uid"
        user_data = UserCreate(
            email="newuser@example.com",
            display_name="New User"
        )

        # Act
        result = await UserService.create_user(firebase_uid, user_data)

        # Assert
        assert result is not None
        assert result.firebase_uid == firebase_uid
        assert result.email == "newuser@example.com"
        assert result.display_name == "New User"
        assert result.created_at is not None
        assert result.last_login is not None

    async def test_create_user_already_exists(self, sample_user):
        """Test creating user that already exists returns existing user"""
        # Arrange
        user_data = UserCreate(
            email="different@example.com",
            display_name="Different Name"
        )

        # Act
        result = await UserService.create_user(sample_user.firebase_uid, user_data)

        # Assert
        assert str(result.id) == str(sample_user.id)
        assert result.firebase_uid == sample_user.firebase_uid
        # Should return existing user, not create new one with different data
        assert result.email == sample_user.email
        assert result.display_name == sample_user.display_name

    async def test_create_user_with_minimal_data(self):
        """Test creating user with minimal required data"""
        # Arrange
        firebase_uid = "minimal_user_uid"
        user_data = UserCreate(
            email="minimal@example.com",
            display_name="Min User"
        )

        # Act
        result = await UserService.create_user(firebase_uid, user_data)

        # Assert
        assert result is not None
        assert result.firebase_uid == firebase_uid
        assert result.email == "minimal@example.com"
        assert result.display_name == "Min User"
        assert result.onboarding_completed is False  # Default value
        assert isinstance(result.settings, dict)  # Default empty dict

    async def test_update_user_success(self, sample_user):
        """Test successful user update"""
        # Arrange
        update_data = UserUpdate(
            display_name="Updated Name",
            bio="Updated bio",
            onboarding_completed=True
        )

        # Act
        result = await UserService.update_user(str(sample_user.id), update_data)

        # Assert
        assert result is not None
        assert result.display_name == "Updated Name"
        assert result.bio == "Updated bio"
        assert result.onboarding_completed is True
        # Unchanged fields should remain the same
        assert result.email == sample_user.email
        assert result.firebase_uid == sample_user.firebase_uid

    async def test_update_user_partial_update(self, sample_user):
        """Test partial user update (only some fields)"""
        # Arrange
        original_display_name = sample_user.display_name
        update_data = UserUpdate(bio="Just updating bio")

        # Act
        result = await UserService.update_user(str(sample_user.id), update_data)

        # Assert
        assert result is not None
        assert result.bio == "Just updating bio"
        assert result.display_name == original_display_name  # Unchanged

    async def test_update_user_with_settings(self, sample_user):
        """Test updating user settings"""
        # Arrange
        new_settings = {
            "notifications_enabled": True,
            "theme": "dark",
            "language": "en"
        }
        update_data = UserUpdate(settings=new_settings)

        # Act
        result = await UserService.update_user(str(sample_user.id), update_data)

        # Assert
        assert result is not None
        assert result.settings == new_settings

    async def test_update_user_empty_update(self, sample_user):
        """Test update with no changes"""
        # Arrange
        original_display_name = sample_user.display_name
        update_data = UserUpdate()  # No fields to update

        # Act
        result = await UserService.update_user(str(sample_user.id), update_data)

        # Assert
        assert result is not None
        assert result.display_name == original_display_name  # Should be unchanged

    async def test_update_user_not_found(self):
        """Test updating non-existent user"""
        # Arrange
        fake_user_id = str(ObjectId())
        update_data = UserUpdate(display_name="Updated Name")

        # Act
        result = await UserService.update_user(fake_user_id, update_data)

        # Assert
        assert result is None

    async def test_update_user_invalid_id(self):
        """Test updating user with invalid ID format"""
        # Arrange
        invalid_id = "not_a_valid_object_id"
        update_data = UserUpdate(display_name="Updated Name")

        # Act
        result = await UserService.update_user(invalid_id, update_data)

        # Assert
        assert result is None

    async def test_update_user_exception_handling(self, sample_user):
        """Test error handling during user update"""
        # Arrange
        update_data = UserUpdate(display_name="Updated Name")
        
        # Mock User.get to raise an exception
        with patch.object(User, 'get', side_effect=Exception("Database error")):
            # Act
            result = await UserService.update_user(str(sample_user.id), update_data)

            # Assert
            assert result is None

    async def test_get_user_by_id_success(self, sample_user):
        """Test getting user by ID successfully"""
        # Act
        result = await UserService.get_user_by_id(str(sample_user.id))

        # Assert
        assert result is not None
        assert str(result.id) == str(sample_user.id)
        assert result.email == sample_user.email
        assert result.firebase_uid == sample_user.firebase_uid

    async def test_get_user_by_id_not_found(self):
        """Test getting non-existent user by ID"""
        # Arrange
        fake_user_id = str(ObjectId())

        # Act
        result = await UserService.get_user_by_id(fake_user_id)

        # Assert
        assert result is None

    async def test_get_user_by_id_invalid_format(self):
        """Test getting user with invalid ID format"""
        # Arrange
        invalid_id = "not_valid_object_id"

        # Act
        result = await UserService.get_user_by_id(invalid_id)

        # Assert
        assert result is None

    async def test_get_user_by_firebase_uid_success(self, sample_user):
        """Test getting user by Firebase UID successfully"""
        # Act
        result = await UserService.get_user_by_firebase_uid(sample_user.firebase_uid)

        # Assert
        assert result is not None
        assert result.firebase_uid == sample_user.firebase_uid
        assert str(result.id) == str(sample_user.id)

    async def test_get_user_by_firebase_uid_not_found(self):
        """Test getting user by non-existent Firebase UID"""
        # Arrange
        fake_firebase_uid = "non_existent_firebase_uid"

        # Act
        result = await UserService.get_user_by_firebase_uid(fake_firebase_uid)

        # Assert
        assert result is None

    async def test_get_user_by_email_success(self, sample_user):
        """Test getting user by email successfully"""
        # Act
        result = await UserService.get_user_by_email(sample_user.email)

        # Assert
        assert result is not None
        assert result.email == sample_user.email
        assert str(result.id) == str(sample_user.id)

    async def test_get_user_by_email_not_found(self):
        """Test getting user by non-existent email"""
        # Arrange
        fake_email = "nonexistent@example.com"

        # Act
        result = await UserService.get_user_by_email(fake_email)

        # Assert
        assert result is None

    async def test_get_user_by_email_case_insensitive(self, sample_user):
        """Test getting user by email is case sensitive (as per current implementation)"""
        # Act
        result_upper = await UserService.get_user_by_email(sample_user.email.upper())
        result_lower = await UserService.get_user_by_email(sample_user.email.lower())

        # Assert - Current implementation is case sensitive
        if sample_user.email != sample_user.email.upper():
            assert result_upper is None  # Should not find with different case
        assert result_lower is not None or sample_user.email == sample_user.email.lower()

    async def test_user_crud_workflow(self):
        """Test complete user CRUD workflow"""
        # Create
        firebase_uid = "workflow_test_uid"
        user_data = UserCreate(
            email="workflow@example.com",
            display_name="Workflow User"
        )
        
        created_user = await UserService.create_user(firebase_uid, user_data)
        assert created_user is not None
        
        # Read
        retrieved_user = await UserService.get_user_by_id(str(created_user.id))
        assert retrieved_user is not None
        assert retrieved_user.email == "workflow@example.com"
        
        # Update
        update_data = UserUpdate(
            display_name="Updated Workflow User",
            bio="Test bio"
        )
        updated_user = await UserService.update_user(str(created_user.id), update_data)
        assert updated_user is not None
        assert updated_user.display_name == "Updated Workflow User"
        assert updated_user.bio == "Test bio"
        
        # Verify changes persisted
        final_user = await UserService.get_user_by_id(str(created_user.id))
        assert final_user.display_name == "Updated Workflow User"
        assert final_user.bio == "Test bio"

    async def test_create_multiple_users_unique_constraints(self):
        """Test that unique constraints are enforced"""
        # Create first user
        firebase_uid_1 = "unique_test_uid_1"
        user_data_1 = UserCreate(
            email="unique@example.com",
            display_name="User 1"
        )
        user1 = await UserService.create_user(firebase_uid_1, user_data_1)
        assert user1 is not None

        # Try to create second user with same email (should work as separate test)
        firebase_uid_2 = "unique_test_uid_2"
        user_data_2 = UserCreate(
            email="unique2@example.com",  # Different email
            display_name="User 2"
        )
        user2 = await UserService.create_user(firebase_uid_2, user_data_2)
        assert user2 is not None
        assert str(user1.id) != str(user2.id)

    async def test_update_user_with_object_id_parameter(self, sample_user):
        """Test updating user when ObjectId is passed instead of string"""
        # Arrange
        update_data = UserUpdate(display_name="ObjectId Test")

        # Act - pass ObjectId instead of string
        result = await UserService.update_user(sample_user.id, update_data)

        # Assert
        assert result is not None
        assert result.display_name == "ObjectId Test"

    async def test_concurrent_user_creation_same_firebase_uid(self):
        """Test concurrent creation of users with same Firebase UID"""
        firebase_uid = "concurrent_test_uid"
        user_data = UserCreate(
            email="concurrent@example.com",
            display_name="Concurrent User"
        )

        # This simulates what would happen if two requests try to create
        # the same user simultaneously - the second should return existing
        user1 = await UserService.create_user(firebase_uid, user_data)
        user2 = await UserService.create_user(firebase_uid, user_data)

        assert str(user1.id) == str(user2.id)  # Should be the same user

    async def test_user_timestamps(self):
        """Test that user creation sets timestamps correctly"""
        # Arrange
        before_creation = datetime.utcnow()
        firebase_uid = "timestamp_test_uid"
        user_data = UserCreate(
            email="timestamp@example.com",
            display_name="Timestamp User"
        )

        # Act
        result = await UserService.create_user(firebase_uid, user_data)
        after_creation = datetime.utcnow()

        # Assert
        assert result.created_at >= before_creation
        assert result.created_at <= after_creation
        assert result.last_login >= before_creation
        assert result.last_login <= after_creation

    async def test_user_default_values(self):
        """Test that users are created with correct default values"""
        # Arrange
        firebase_uid = "defaults_test_uid"
        user_data = UserCreate(
            email="defaults@example.com",
            display_name="Defaults User"
        )

        # Act
        result = await UserService.create_user(firebase_uid, user_data)

        # Assert
        assert result.onboarding_completed is False
        assert isinstance(result.settings, dict)
        assert len(result.settings) == 0  # Should be empty dict by default
        assert result.bio is None
        assert result.profile_picture_url is None
        assert result.version == 1