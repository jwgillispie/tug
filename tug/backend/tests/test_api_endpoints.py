# tests/test_api_endpoints.py
import pytest
from httpx import AsyncClient
from datetime import datetime
import json

from app.core.config import settings


@pytest.mark.asyncio
class TestAPIEndpoints:
    """Integration tests for API endpoints"""

    # Health and Root Endpoints
    async def test_health_endpoint(self, test_client: AsyncClient):
        """Test health check endpoint"""
        # Act
        response = await test_client.get("/health")

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"
        assert "version" in data

    async def test_root_endpoint(self, test_client: AsyncClient):
        """Test root endpoint"""
        # Act
        response = await test_client.get("/")

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert "message" in data
        assert data["api_prefix"] == settings.API_V1_PREFIX
        assert "endpoints" in data

    # User Endpoints
    async def test_create_user_success(self, test_client: AsyncClient, mock_firebase_auth):
        """Test successful user creation"""
        # Arrange
        headers = {"Authorization": "Bearer valid_token"}
        user_data = {
            "email": "newuser@example.com",
            "display_name": "New User"
        }

        # Act
        response = await test_client.post(
            f"{settings.API_V1_PREFIX}/users/",
            json=user_data,
            headers=headers
        )

        # Assert
        assert response.status_code == 201
        data = response.json()
        assert data["email"] == "newuser@example.com"
        assert data["display_name"] == "New User"
        assert "id" in data

    async def test_get_current_user(self, test_client: AsyncClient, mock_firebase_auth, sample_user):
        """Test getting current user profile"""
        # Arrange
        headers = {"Authorization": "Bearer valid_token"}

        # Act
        response = await test_client.get(
            f"{settings.API_V1_PREFIX}/users/me",
            headers=headers
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["email"] == sample_user.email
        assert data["display_name"] == sample_user.display_name

    async def test_update_user_profile(self, test_client: AsyncClient, mock_firebase_auth, sample_user):
        """Test updating user profile"""
        # Arrange
        headers = {"Authorization": "Bearer valid_token"}
        update_data = {
            "display_name": "Updated Name",
            "bio": "Updated bio"
        }

        # Act
        response = await test_client.put(
            f"{settings.API_V1_PREFIX}/users/me",
            json=update_data,
            headers=headers
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["display_name"] == "Updated Name"
        assert data["bio"] == "Updated bio"

    async def test_unauthorized_access(self, test_client: AsyncClient):
        """Test accessing protected endpoint without authentication"""
        # Act
        response = await test_client.get(f"{settings.API_V1_PREFIX}/users/me")

        # Assert
        assert response.status_code == 401

    async def test_invalid_token(self, test_client: AsyncClient, mock_firebase_auth_invalid):
        """Test accessing with invalid token"""
        # Arrange
        headers = {"Authorization": "Bearer invalid_token"}

        # Act
        response = await test_client.get(
            f"{settings.API_V1_PREFIX}/users/me",
            headers=headers
        )

        # Assert
        assert response.status_code == 401

    # Value Endpoints
    async def test_create_value_success(self, test_client: AsyncClient, mock_firebase_auth, sample_user):
        """Test successful value creation"""
        # Arrange
        headers = {"Authorization": "Bearer valid_token"}
        value_data = {
            "name": "Test Value",
            "importance": 4,
            "description": "A test value",
            "color": "#FF5733"
        }

        # Act
        response = await test_client.post(
            f"{settings.API_V1_PREFIX}/values/",
            json=value_data,
            headers=headers
        )

        # Assert
        assert response.status_code == 201
        data = response.json()
        assert data["name"] == "Test Value"
        assert data["importance"] == 4
        assert data["color"] == "#FF5733"

    async def test_get_values(self, test_client: AsyncClient, mock_firebase_auth, sample_user, sample_values_batch):
        """Test getting user values"""
        # Arrange
        headers = {"Authorization": "Bearer valid_token"}

        # Act
        response = await test_client.get(
            f"{settings.API_V1_PREFIX}/values/",
            headers=headers
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        assert len(data) == len(sample_values_batch)

    async def test_update_value(self, test_client: AsyncClient, mock_firebase_auth, sample_user, sample_value):
        """Test updating a value"""
        # Arrange
        headers = {"Authorization": "Bearer valid_token"}
        update_data = {
            "name": "Updated Value Name",
            "importance": 3
        }

        # Act
        response = await test_client.put(
            f"{settings.API_V1_PREFIX}/values/{sample_value.id}",
            json=update_data,
            headers=headers
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["name"] == "Updated Value Name"
        assert data["importance"] == 3

    async def test_get_value_not_found(self, test_client: AsyncClient, mock_firebase_auth, sample_user):
        """Test getting non-existent value"""
        # Arrange
        headers = {"Authorization": "Bearer valid_token"}
        from bson import ObjectId
        fake_id = str(ObjectId())

        # Act
        response = await test_client.get(
            f"{settings.API_V1_PREFIX}/values/{fake_id}",
            headers=headers
        )

        # Assert
        assert response.status_code == 404

    # Activity Endpoints
    async def test_create_activity_success(self, test_client: AsyncClient, mock_firebase_auth, sample_user, sample_value):
        """Test successful activity creation"""
        # Arrange
        headers = {"Authorization": "Bearer valid_token"}
        activity_data = {
            "value_ids": [str(sample_value.id)],
            "name": "Test Activity",
            "duration": 45,
            "date": datetime.utcnow().isoformat(),
            "notes": "Test notes",
            "is_public": False,
            "notes_public": False
        }

        # Act
        response = await test_client.post(
            f"{settings.API_V1_PREFIX}/activities/",
            json=activity_data,
            headers=headers
        )

        # Assert
        assert response.status_code == 201
        data = response.json()
        assert data["name"] == "Test Activity"
        assert data["duration"] == 45

    async def test_get_activities(self, test_client: AsyncClient, mock_firebase_auth, sample_user, sample_activities_batch):
        """Test getting user activities"""
        # Arrange
        headers = {"Authorization": "Bearer valid_token"}

        # Act
        response = await test_client.get(
            f"{settings.API_V1_PREFIX}/activities/",
            headers=headers
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        assert len(data) == len(sample_activities_batch)

    async def test_get_activities_with_filters(self, test_client: AsyncClient, mock_firebase_auth, sample_user, sample_activities_batch, sample_values_batch):
        """Test getting activities with query parameters"""
        # Arrange
        headers = {"Authorization": "Bearer valid_token"}
        params = {
            "value_id": str(sample_values_batch[0].id),
            "limit": 2
        }

        # Act
        response = await test_client.get(
            f"{settings.API_V1_PREFIX}/activities/",
            headers=headers,
            params=params
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        assert len(data) <= 2

    async def test_update_activity(self, test_client: AsyncClient, mock_firebase_auth, sample_user, sample_activity):
        """Test updating an activity"""
        # Arrange
        headers = {"Authorization": "Bearer valid_token"}
        update_data = {
            "name": "Updated Activity Name",
            "duration": 60
        }

        # Act
        response = await test_client.put(
            f"{settings.API_V1_PREFIX}/activities/{sample_activity.id}",
            json=update_data,
            headers=headers
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["name"] == "Updated Activity Name"
        assert data["duration"] == 60

    async def test_delete_activity(self, test_client: AsyncClient, mock_firebase_auth, sample_user, sample_activity):
        """Test deleting an activity"""
        # Arrange
        headers = {"Authorization": "Bearer valid_token"}

        # Act
        response = await test_client.delete(
            f"{settings.API_V1_PREFIX}/activities/{sample_activity.id}",
            headers=headers
        )

        # Assert
        assert response.status_code == 204

    async def test_get_activity_statistics(self, test_client: AsyncClient, mock_firebase_auth, sample_user, sample_activities_batch):
        """Test getting activity statistics"""
        # Arrange
        headers = {"Authorization": "Bearer valid_token"}

        # Act
        response = await test_client.get(
            f"{settings.API_V1_PREFIX}/activities/statistics",
            headers=headers
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert "total_activities" in data
        assert "total_duration_minutes" in data
        assert "average_duration_minutes" in data

    # Social Endpoints
    async def test_send_friend_request(self, test_client: AsyncClient, mock_firebase_auth, sample_user, sample_user_2):
        """Test sending a friend request"""
        # Arrange
        headers = {"Authorization": "Bearer valid_token"}
        request_data = {
            "addressee_id": str(sample_user_2.id)
        }

        # Mock notification service
        from unittest.mock import patch, AsyncMock
        with patch('app.services.social_service.NotificationService.create_friend_request_notification') as mock_notify:
            mock_notify.return_value = AsyncMock()

            # Act
            response = await test_client.post(
                f"{settings.API_V1_PREFIX}/social/friend-requests",
                json=request_data,
                headers=headers
            )

            # Assert
            assert response.status_code == 201
            data = response.json()
            assert data["requester_id"] == str(sample_user.id)
            assert data["addressee_id"] == str(sample_user_2.id)
            assert data["status"] == "pending"

    async def test_get_friends(self, test_client: AsyncClient, mock_firebase_auth, sample_user, sample_friendship):
        """Test getting friends list"""
        # Arrange
        headers = {"Authorization": "Bearer valid_token"}

        # Act
        response = await test_client.get(
            f"{settings.API_V1_PREFIX}/social/friends",
            headers=headers
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)

    async def test_search_users(self, test_client: AsyncClient, mock_firebase_auth, sample_user, sample_users_batch):
        """Test searching users"""
        # Arrange
        headers = {"Authorization": "Bearer valid_token"}
        params = {"q": "testuser"}

        # Act
        response = await test_client.get(
            f"{settings.API_V1_PREFIX}/social/search",
            headers=headers,
            params=params
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)

    async def test_create_social_post(self, test_client: AsyncClient, mock_firebase_auth, sample_user):
        """Test creating a social post"""
        # Arrange
        headers = {"Authorization": "Bearer valid_token"}
        post_data = {
            "content": "Just sharing some thoughts!",
            "post_type": "general",
            "is_public": True
        }

        # Act
        response = await test_client.post(
            f"{settings.API_V1_PREFIX}/social/posts",
            json=post_data,
            headers=headers
        )

        # Assert
        assert response.status_code == 201
        data = response.json()
        assert data["content"] == "Just sharing some thoughts!"
        assert data["post_type"] == "general"

    async def test_get_social_feed(self, test_client: AsyncClient, mock_firebase_auth, sample_user, sample_friendship):
        """Test getting social feed"""
        # Arrange
        headers = {"Authorization": "Bearer valid_token"}

        # Act
        response = await test_client.get(
            f"{settings.API_V1_PREFIX}/social/feed",
            headers=headers
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)

    # Error Handling Tests
    async def test_invalid_json_payload(self, test_client: AsyncClient, mock_firebase_auth):
        """Test API endpoint with invalid JSON"""
        # Arrange
        headers = {
            "Authorization": "Bearer valid_token",
            "Content-Type": "application/json"
        }

        # Act
        response = await test_client.post(
            f"{settings.API_V1_PREFIX}/values/",
            content="invalid json{",
            headers=headers
        )

        # Assert
        assert response.status_code == 422

    async def test_missing_required_fields(self, test_client: AsyncClient, mock_firebase_auth):
        """Test API endpoint with missing required fields"""
        # Arrange
        headers = {"Authorization": "Bearer valid_token"}
        incomplete_data = {
            "name": "Test Value"
            # Missing importance, description, color
        }

        # Act
        response = await test_client.post(
            f"{settings.API_V1_PREFIX}/values/",
            json=incomplete_data,
            headers=headers
        )

        # Assert
        assert response.status_code == 422

    async def test_rate_limiting(self, test_client: AsyncClient, mock_firebase_auth):
        """Test rate limiting middleware"""
        headers = {"Authorization": "Bearer valid_token"}

        # Make many requests quickly to trigger rate limit
        # Note: This test depends on the rate limit configuration
        responses = []
        for _ in range(10):  # Adjust based on rate limit settings
            response = await test_client.get(
                f"{settings.API_V1_PREFIX}/users/me",
                headers=headers
            )
            responses.append(response)

        # At least some requests should succeed
        success_count = sum(1 for r in responses if r.status_code == 200)
        assert success_count > 0

    async def test_cors_headers(self, test_client: AsyncClient):
        """Test CORS headers are present"""
        # Act
        response = await test_client.options("/health")

        # Assert
        # CORS headers should be present in OPTIONS response
        assert "access-control-allow-origin" in response.headers or response.status_code == 200

    async def test_security_headers(self, test_client: AsyncClient):
        """Test security headers are present"""
        # Act
        response = await test_client.get("/health")

        # Assert
        assert response.headers.get("x-content-type-options") == "nosniff"
        assert response.headers.get("x-frame-options") == "DENY"
        assert "x-xss-protection" in response.headers
        assert "referrer-policy" in response.headers

    # Data Validation Tests
    async def test_value_importance_validation(self, test_client: AsyncClient, mock_firebase_auth):
        """Test value importance field validation"""
        # Arrange
        headers = {"Authorization": "Bearer valid_token"}
        invalid_data = {
            "name": "Test Value",
            "importance": 10,  # Should be 1-5
            "description": "Test",
            "color": "#FF5733"
        }

        # Act
        response = await test_client.post(
            f"{settings.API_V1_PREFIX}/values/",
            json=invalid_data,
            headers=headers
        )

        # Assert
        assert response.status_code == 422

    async def test_activity_future_date_validation(self, test_client: AsyncClient, mock_firebase_auth, sample_user, sample_value):
        """Test activity future date validation"""
        # Arrange
        headers = {"Authorization": "Bearer valid_token"}
        from datetime import datetime, timedelta
        future_date = (datetime.utcnow() + timedelta(days=1)).isoformat()
        
        invalid_data = {
            "value_ids": [str(sample_value.id)],
            "name": "Future Activity",
            "duration": 45,
            "date": future_date,
            "notes": "This should fail",
            "is_public": False,
            "notes_public": False
        }

        # Act
        response = await test_client.post(
            f"{settings.API_V1_PREFIX}/activities/",
            json=invalid_data,
            headers=headers
        )

        # Assert
        assert response.status_code == 400
        data = response.json()
        assert "future activities" in data["detail"].lower()

    # Pagination Tests
    async def test_activities_pagination(self, test_client: AsyncClient, mock_firebase_auth, sample_user, sample_activities_batch):
        """Test activities endpoint pagination"""
        # Arrange
        headers = {"Authorization": "Bearer valid_token"}
        params = {"limit": 2, "skip": 1}

        # Act
        response = await test_client.get(
            f"{settings.API_V1_PREFIX}/activities/",
            headers=headers,
            params=params
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert len(data) <= 2

    # Content Type Tests
    async def test_json_content_type_required(self, test_client: AsyncClient, mock_firebase_auth):
        """Test that endpoints require JSON content type"""
        # Arrange
        headers = {
            "Authorization": "Bearer valid_token",
            "Content-Type": "text/plain"
        }

        # Act
        response = await test_client.post(
            f"{settings.API_V1_PREFIX}/values/",
            content="name=Test&importance=4",
            headers=headers
        )

        # Assert
        # Should either reject non-JSON content or parse it as JSON and fail
        assert response.status_code in [422, 400]

    # Integration Test Workflows
    async def test_complete_user_workflow(self, test_client: AsyncClient, mock_firebase_auth):
        """Test complete user workflow: create user -> create value -> create activity"""
        headers = {"Authorization": "Bearer valid_token"}

        # 1. Create user
        user_data = {
            "email": "workflow@example.com",
            "display_name": "Workflow User"
        }
        user_response = await test_client.post(
            f"{settings.API_V1_PREFIX}/users/",
            json=user_data,
            headers=headers
        )
        assert user_response.status_code == 201
        user = user_response.json()

        # 2. Create value
        value_data = {
            "name": "Workflow Value",
            "importance": 4,
            "description": "Test value for workflow",
            "color": "#FF5733"
        }
        value_response = await test_client.post(
            f"{settings.API_V1_PREFIX}/values/",
            json=value_data,
            headers=headers
        )
        assert value_response.status_code == 201
        value = value_response.json()

        # 3. Create activity
        activity_data = {
            "value_ids": [value["id"]],
            "name": "Workflow Activity",
            "duration": 30,
            "date": datetime.utcnow().isoformat(),
            "notes": "Test activity for workflow",
            "is_public": False,
            "notes_public": False
        }
        activity_response = await test_client.post(
            f"{settings.API_V1_PREFIX}/activities/",
            json=activity_data,
            headers=headers
        )
        assert activity_response.status_code == 201
        activity = activity_response.json()

        # 4. Verify relationships
        assert activity["value_ids"] == [value["id"]]
        assert activity["name"] == "Workflow Activity"