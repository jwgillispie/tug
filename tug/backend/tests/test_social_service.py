# tests/test_social_service.py
import pytest
from datetime import datetime
from fastapi import HTTPException
from bson import ObjectId
from unittest.mock import patch, AsyncMock

from app.services.social_service import SocialService
from app.models.friendship import Friendship, FriendshipStatus
from app.models.social_post import SocialPost, PostType
from app.models.post_comment import PostComment
from app.models.user import User
from app.schemas.social import (
    FriendRequestCreate, SocialPostCreate, SocialPostUpdate,
    CommentCreate, CommentUpdate
)


@pytest.mark.asyncio
class TestSocialService:
    """Comprehensive tests for SocialService"""

    # Friend Management Tests
    async def test_send_friend_request_success(self, sample_user, sample_user_2):
        """Test successful friend request sending"""
        # Arrange
        request_data = FriendRequestCreate(addressee_id=str(sample_user_2.id))

        # Mock notification service
        with patch('app.services.social_service.NotificationService.create_friend_request_notification') as mock_notify:
            mock_notify.return_value = AsyncMock()

            # Act
            result = await SocialService.send_friend_request(sample_user, request_data)

            # Assert
            assert result is not None
            assert result.requester_id == str(sample_user.id)
            assert result.addressee_id == str(sample_user_2.id)
            assert result.status == FriendshipStatus.PENDING
            mock_notify.assert_called_once()

    async def test_send_friend_request_to_self(self, sample_user):
        """Test sending friend request to self should fail"""
        # Arrange
        request_data = FriendRequestCreate(addressee_id=str(sample_user.id))

        # Act & Assert
        with pytest.raises(HTTPException) as exc_info:
            await SocialService.send_friend_request(sample_user, request_data)
        
        assert exc_info.value.status_code == 400
        assert "Cannot send friend request to yourself" in str(exc_info.value.detail)

    async def test_send_friend_request_user_not_found(self, sample_user):
        """Test sending friend request to non-existent user"""
        # Arrange
        fake_user_id = str(ObjectId())
        request_data = FriendRequestCreate(addressee_id=fake_user_id)

        # Act & Assert
        with pytest.raises(HTTPException) as exc_info:
            await SocialService.send_friend_request(sample_user, request_data)
        
        assert exc_info.value.status_code == 404
        assert "User not found" in str(exc_info.value.detail)

    async def test_send_friend_request_already_friends(self, sample_user, sample_user_2):
        """Test sending friend request when already friends"""
        # Arrange - create existing accepted friendship
        existing_friendship = Friendship(
            requester_id=str(sample_user.id),
            addressee_id=str(sample_user_2.id),
            status=FriendshipStatus.ACCEPTED
        )
        await existing_friendship.save()

        request_data = FriendRequestCreate(addressee_id=str(sample_user_2.id))

        # Act & Assert
        with pytest.raises(HTTPException) as exc_info:
            await SocialService.send_friend_request(sample_user, request_data)
        
        assert exc_info.value.status_code == 400
        assert "Already friends with this user" in str(exc_info.value.detail)

    async def test_send_friend_request_already_pending(self, sample_user, sample_user_2):
        """Test sending friend request when one is already pending"""
        # Arrange - create existing pending friendship
        existing_friendship = Friendship(
            requester_id=str(sample_user.id),
            addressee_id=str(sample_user_2.id),
            status=FriendshipStatus.PENDING
        )
        await existing_friendship.save()

        request_data = FriendRequestCreate(addressee_id=str(sample_user_2.id))

        # Act & Assert
        with pytest.raises(HTTPException) as exc_info:
            await SocialService.send_friend_request(sample_user, request_data)
        
        assert exc_info.value.status_code == 400
        assert "Friend request already pending" in str(exc_info.value.detail)

    async def test_respond_to_friend_request_accept(self, sample_user, sample_user_2):
        """Test accepting a friend request"""
        # Arrange - create pending friendship
        friendship = Friendship(
            requester_id=str(sample_user.id),
            addressee_id=str(sample_user_2.id),
            status=FriendshipStatus.PENDING
        )
        await friendship.save()

        # Mock notification service
        with patch('app.services.social_service.NotificationService.create_friend_accepted_notification') as mock_notify:
            mock_notify.return_value = AsyncMock()

            # Act
            result = await SocialService.respond_to_friend_request(sample_user_2, str(friendship.id), accept=True)

            # Assert
            assert result.status == FriendshipStatus.ACCEPTED
            mock_notify.assert_called_once()

    async def test_respond_to_friend_request_reject(self, sample_user, sample_user_2):
        """Test rejecting a friend request"""
        # Arrange - create pending friendship
        friendship = Friendship(
            requester_id=str(sample_user.id),
            addressee_id=str(sample_user_2.id),
            status=FriendshipStatus.PENDING
        )
        await friendship.save()

        # Act
        result = await SocialService.respond_to_friend_request(sample_user_2, str(friendship.id), accept=False)

        # Assert
        # For rejection, the friendship should be deleted
        deleted_friendship = await Friendship.get(str(friendship.id))
        assert deleted_friendship is None

    async def test_respond_to_friend_request_not_found(self, sample_user):
        """Test responding to non-existent friend request"""
        # Arrange
        fake_id = str(ObjectId())

        # Act & Assert
        with pytest.raises(HTTPException) as exc_info:
            await SocialService.respond_to_friend_request(sample_user, fake_id, accept=True)
        
        assert exc_info.value.status_code == 404
        assert "Friend request not found" in str(exc_info.value.detail)

    async def test_respond_to_friend_request_not_addressee(self, sample_user, sample_user_2):
        """Test responding to friend request when not the addressee"""
        # Arrange - create friendship where sample_user_2 is requester
        friendship = Friendship(
            requester_id=str(sample_user_2.id),
            addressee_id=str(sample_user.id),
            status=FriendshipStatus.PENDING
        )
        await friendship.save()

        # Act & Assert - sample_user_2 trying to respond (should be sample_user)
        with pytest.raises(HTTPException) as exc_info:
            await SocialService.respond_to_friend_request(sample_user_2, str(friendship.id), accept=True)
        
        assert exc_info.value.status_code == 403

    async def test_get_friends(self, sample_user, sample_user_2, sample_users_batch):
        """Test getting user's friends list"""
        # Arrange - create multiple friendships
        friendship1 = Friendship(
            requester_id=str(sample_user.id),
            addressee_id=str(sample_user_2.id),
            status=FriendshipStatus.ACCEPTED
        )
        await friendship1.save()

        friendship2 = Friendship(
            requester_id=str(sample_users_batch[0].id),
            addressee_id=str(sample_user.id),
            status=FriendshipStatus.ACCEPTED
        )
        await friendship2.save()

        # Act
        friends = await SocialService.get_friends(sample_user)

        # Assert
        assert len(friends) == 2
        friend_ids = {f.friend_username for f in friends}
        assert sample_user_2.username in friend_ids
        assert sample_users_batch[0].username in friend_ids

    async def test_get_friends_empty_list(self, sample_user):
        """Test getting friends when user has none"""
        # Act
        friends = await SocialService.get_friends(sample_user)

        # Assert
        assert len(friends) == 0
        assert isinstance(friends, list)

    async def test_get_pending_friend_requests(self, sample_user, sample_user_2, sample_users_batch):
        """Test getting pending friend requests"""
        # Arrange - create pending requests
        request1 = Friendship(
            requester_id=str(sample_user_2.id),
            addressee_id=str(sample_user.id),
            status=FriendshipStatus.PENDING
        )
        await request1.save()

        request2 = Friendship(
            requester_id=str(sample_users_batch[0].id),
            addressee_id=str(sample_user.id),
            status=FriendshipStatus.PENDING
        )
        await request2.save()

        # Act
        requests = await SocialService.get_pending_friend_requests(sample_user)

        # Assert
        assert len(requests) == 2
        requester_names = {r.friend_username for r in requests}
        assert sample_user_2.username in requester_names
        assert sample_users_batch[0].username in requester_names

    async def test_search_users_success(self, sample_user, sample_users_batch):
        """Test successful user search"""
        # Act
        results = await SocialService.search_users(sample_user, "testuser1", limit=10)

        # Assert
        assert len(results) >= 1
        # Should exclude current user from results
        result_ids = {r.id for r in results}
        assert str(sample_user.id) not in result_ids

    async def test_search_users_empty_query(self, sample_user):
        """Test search with empty/short query"""
        # Act
        results = await SocialService.search_users(sample_user, "a", limit=10)

        # Assert
        assert len(results) == 0  # Query too short

    async def test_search_users_with_friendship_status(self, sample_user, sample_user_2):
        """Test search includes friendship status"""
        # Arrange - create friendship
        friendship = Friendship(
            requester_id=str(sample_user.id),
            addressee_id=str(sample_user_2.id),
            status=FriendshipStatus.PENDING
        )
        await friendship.save()

        # Act
        results = await SocialService.search_users(sample_user, sample_user_2.username, limit=10)

        # Assert
        assert len(results) == 1
        assert results[0].friendship_status == FriendshipStatus.PENDING.value

    async def test_search_users_security_validation(self, sample_user):
        """Test search with suspicious input"""
        # Mock the validation to detect injection attempts
        with patch('app.services.social_service.InputValidator.detect_injection_attempts') as mock_detect:
            mock_detect.return_value = ["sql_injection"]

            # Act & Assert
            with pytest.raises(HTTPException) as exc_info:
                await SocialService.search_users(sample_user, "'; DROP TABLE users; --", limit=10)
            
            assert exc_info.value.status_code == 400

    # Social Posts Tests
    async def test_create_post_success(self, sample_user, sample_activity):
        """Test successful social post creation"""
        # Arrange
        post_data = SocialPostCreate(
            content="Just completed an amazing workout!",
            post_type=PostType.ACTIVITY_UPDATE,
            activity_id=str(sample_activity.id),
            is_public=True
        )

        # Act
        result = await SocialService.create_post(sample_user, post_data)

        # Assert
        assert result is not None
        assert result.user_id == str(sample_user.id)
        assert result.content == "Just completed an amazing workout!"
        assert result.post_type == PostType.ACTIVITY_UPDATE
        assert result.activity_id == str(sample_activity.id)
        assert result.is_public is True

    async def test_create_post_general_type(self, sample_user):
        """Test creating general post without activity"""
        # Arrange
        post_data = SocialPostCreate(
            content="Just sharing some thoughts!",
            post_type=PostType.GENERAL,
            is_public=True
        )

        # Act
        result = await SocialService.create_post(sample_user, post_data)

        # Assert
        assert result is not None
        assert result.post_type == PostType.GENERAL
        assert result.activity_id is None
        assert result.vice_id is None

    async def test_update_post_success(self, sample_user, sample_social_post):
        """Test successful post update"""
        # Arrange
        update_data = SocialPostUpdate(content="Updated post content!")

        # Act
        result = await SocialService.update_post(sample_user, str(sample_social_post.id), update_data)

        # Assert
        assert result is not None
        assert result.content == "Updated post content!"

    async def test_update_post_not_owner(self, sample_user, sample_user_2, sample_social_post):
        """Test updating post by non-owner"""
        # Arrange
        update_data = SocialPostUpdate(content="Hacked content!")

        # Act & Assert
        with pytest.raises(HTTPException) as exc_info:
            await SocialService.update_post(sample_user_2, str(sample_social_post.id), update_data)
        
        assert exc_info.value.status_code == 403

    async def test_delete_post_success(self, sample_user, sample_social_post):
        """Test successful post deletion"""
        # Act
        result = await SocialService.delete_post(sample_user, str(sample_social_post.id))

        # Assert
        assert result is True
        # Verify post is deleted
        deleted_post = await SocialPost.get(str(sample_social_post.id))
        assert deleted_post is None

    async def test_delete_post_not_owner(self, sample_user_2, sample_social_post):
        """Test deleting post by non-owner"""
        # Act & Assert
        with pytest.raises(HTTPException) as exc_info:
            await SocialService.delete_post(sample_user_2, str(sample_social_post.id))
        
        assert exc_info.value.status_code == 403

    async def test_create_vice_milestone_post(self, sample_user, sample_vice):
        """Test creating vice milestone post"""
        # Act
        result = await SocialService.create_vice_milestone_post(sample_user, sample_vice, 7)

        # Assert
        assert result is not None
        assert result.post_type == PostType.VICE_PROGRESS
        assert result.vice_id == str(sample_vice.id)
        assert "One week clean" in result.content

    async def test_get_social_feed(self, sample_user, sample_user_2, sample_friendship):
        """Test getting social feed"""
        # Arrange - create some posts
        post1 = SocialPost(
            user_id=str(sample_user.id),
            content="My post",
            post_type=PostType.GENERAL,
            is_public=True
        )
        await post1.save()

        post2 = SocialPost(
            user_id=str(sample_user_2.id),
            content="Friend's post",
            post_type=PostType.GENERAL,
            is_public=True
        )
        await post2.save()

        # Act
        feed = await SocialService.get_social_feed(sample_user)

        # Assert
        assert len(feed) >= 2
        post_contents = {p.content for p in feed}
        assert "My post" in post_contents
        assert "Friend's post" in post_contents

    async def test_get_social_feed_only_public_posts(self, sample_user, sample_user_2, sample_friendship):
        """Test that social feed only includes public posts"""
        # Arrange - create public and private posts
        public_post = SocialPost(
            user_id=str(sample_user_2.id),
            content="Public post",
            post_type=PostType.GENERAL,
            is_public=True
        )
        await public_post.save()

        private_post = SocialPost(
            user_id=str(sample_user_2.id),
            content="Private post",
            post_type=PostType.GENERAL,
            is_public=False
        )
        await private_post.save()

        # Act
        feed = await SocialService.get_social_feed(sample_user)

        # Assert
        post_contents = {p.content for p in feed}
        assert "Public post" in post_contents
        assert "Private post" not in post_contents

    # Comments Tests
    async def test_add_comment_success(self, sample_user, sample_user_2, sample_social_post):
        """Test successful comment addition"""
        # Arrange
        comment_data = CommentCreate(content="Great post!")

        # Mock notification service
        with patch('app.services.social_service.NotificationService.create_comment_notification') as mock_notify:
            mock_notify.return_value = AsyncMock()

            # Act
            result = await SocialService.add_comment(sample_user_2, str(sample_social_post.id), comment_data)

            # Assert
            assert result is not None
            assert result.user_id == str(sample_user_2.id)
            assert result.post_id == str(sample_social_post.id)
            assert result.content == "Great post!"
            mock_notify.assert_called_once()

    async def test_add_comment_own_post_no_notification(self, sample_user, sample_social_post):
        """Test adding comment to own post doesn't create notification"""
        # Arrange
        comment_data = CommentCreate(content="My own comment")

        # Mock notification service
        with patch('app.services.social_service.NotificationService.create_comment_notification') as mock_notify:
            mock_notify.return_value = AsyncMock()

            # Act
            result = await SocialService.add_comment(sample_user, str(sample_social_post.id), comment_data)

            # Assert
            assert result is not None
            mock_notify.assert_not_called()  # Should not notify self

    async def test_add_comment_post_not_found(self, sample_user):
        """Test adding comment to non-existent post"""
        # Arrange
        fake_post_id = str(ObjectId())
        comment_data = CommentCreate(content="Comment on nothing")

        # Act & Assert
        with pytest.raises(HTTPException) as exc_info:
            await SocialService.add_comment(sample_user, fake_post_id, comment_data)
        
        assert exc_info.value.status_code == 404

    async def test_get_post_comments(self, sample_user, sample_user_2, sample_social_post):
        """Test getting comments for a post"""
        # Arrange - create some comments
        comment1 = PostComment(
            post_id=str(sample_social_post.id),
            user_id=str(sample_user.id),
            content="First comment"
        )
        await comment1.save()

        comment2 = PostComment(
            post_id=str(sample_social_post.id),
            user_id=str(sample_user_2.id),
            content="Second comment"
        )
        await comment2.save()

        # Act
        comments = await SocialService.get_post_comments(str(sample_social_post.id))

        # Assert
        assert len(comments) == 2
        comment_contents = {c.content for c in comments}
        assert "First comment" in comment_contents
        assert "Second comment" in comment_contents

    async def test_get_social_statistics(self, sample_user):
        """Test getting social statistics"""
        # Arrange - create some posts and friendships
        post1 = SocialPost(
            user_id=str(sample_user.id),
            content="Post 1",
            post_type=PostType.GENERAL,
            is_public=True,
            comments_count=3
        )
        await post1.save()

        post2 = SocialPost(
            user_id=str(sample_user.id),
            content="Post 2",
            post_type=PostType.ACTIVITY_UPDATE,
            is_public=True,
            comments_count=2
        )
        await post2.save()

        # Act
        stats = await SocialService.get_social_statistics(sample_user)

        # Assert
        assert stats.total_posts == 2
        assert stats.total_comments == 5
        assert stats.avg_comments_per_post == 2.5
        assert stats.post_type_breakdown.general == 1
        assert stats.post_type_breakdown.activity_update == 1

    async def test_get_social_statistics_no_activity(self, sample_user):
        """Test getting statistics when user has no social activity"""
        # Act
        stats = await SocialService.get_social_statistics(sample_user)

        # Assert
        assert stats.total_posts == 0
        assert stats.total_comments == 0
        assert stats.friends_count == 0
        assert stats.pending_requests == 0
        assert stats.avg_comments_per_post == 0.0

    async def test_error_handling_in_social_operations(self, sample_user):
        """Test error handling in various social operations"""
        # Test friend request with database error
        with patch.object(User, 'get', side_effect=Exception("Database error")):
            with pytest.raises(HTTPException) as exc_info:
                request_data = FriendRequestCreate(addressee_id=str(ObjectId()))
                await SocialService.send_friend_request(sample_user, request_data)
            assert exc_info.value.status_code == 500

        # Test post creation with error
        with patch.object(SocialPost, 'save', side_effect=Exception("Save error")):
            with pytest.raises(HTTPException) as exc_info:
                post_data = SocialPostCreate(
                    content="Test post",
                    post_type=PostType.GENERAL,
                    is_public=True
                )
                await SocialService.create_post(sample_user, post_data)
            assert exc_info.value.status_code == 500

    async def test_social_feed_pagination(self, sample_user, sample_friendship):
        """Test social feed pagination"""
        # Arrange - create many posts
        for i in range(25):
            post = SocialPost(
                user_id=str(sample_user.id),
                content=f"Post {i}",
                post_type=PostType.GENERAL,
                is_public=True
            )
            await post.save()

        # Act
        first_page = await SocialService.get_social_feed(sample_user, limit=10, skip=0)
        second_page = await SocialService.get_social_feed(sample_user, limit=10, skip=10)

        # Assert
        assert len(first_page) == 10
        assert len(second_page) == 10
        # No overlap between pages
        first_ids = {p.id for p in first_page}
        second_ids = {p.id for p in second_page}
        assert not first_ids.intersection(second_ids)

    async def test_vice_milestone_post_error_handling(self, sample_user, sample_vice):
        """Test that vice milestone post errors don't propagate"""
        # Mock SocialPost.save to raise exception
        with patch.object(SocialPost, 'save', side_effect=Exception("Save error")):
            # Act - should not raise exception
            result = await SocialService.create_vice_milestone_post(sample_user, sample_vice, 30)

            # Assert
            assert result is None  # Should return None on error, not raise