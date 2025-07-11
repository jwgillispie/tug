#!/usr/bin/env python3

"""
Quick test script for notification batching functionality
Run this to verify the notification batching system works correctly.
"""

import asyncio
import sys
from datetime import datetime, timedelta
from typing import List

# Add backend to path
sys.path.append('/Users/jordangillispie/development/tug/tug/backend')

try:
    from app.models.notification import Notification, NotificationBatch, NotificationType
except ImportError as e:
    print(f"Error importing models: {e}")
    print("Make sure you're in the correct directory and dependencies are installed.")
    sys.exit(1)


async def test_notification_batch_creation():
    """Test creating notification batches"""
    print("🧪 Testing notification batch creation...")
    
    # Test batch creation
    user_id = "test_user_123"
    post_id = "test_post_456"
    
    # Create first batch
    batch1 = await NotificationBatch.find_or_create_batch(
        user_id=user_id,
        batch_type=NotificationType.COMMENT,
        related_id=post_id,
        window_minutes=5
    )
    
    print(f"✅ Created batch: {batch1.id}")
    print(f"   User ID: {batch1.user_id}")
    print(f"   Type: {batch1.batch_type}")
    print(f"   Window: {batch1.batch_window_start} to {batch1.batch_window_end}")
    
    # Add notifications to batch
    batch1.add_notification("notif_1", "user_1", "Alice")
    await batch1.save()
    print(f"✅ Added notification 1 - Count: {batch1.count}")
    print(f"   Title: {batch1.title}")
    print(f"   Message: {batch1.message}")
    
    batch1.add_notification("notif_2", "user_2", "Bob")
    await batch1.save()
    print(f"✅ Added notification 2 - Count: {batch1.count}")
    print(f"   Title: {batch1.title}")
    print(f"   Message: {batch1.message}")
    
    batch1.add_notification("notif_3", "user_3", "Charlie")
    await batch1.save()
    print(f"✅ Added notification 3 - Count: {batch1.count}")
    print(f"   Title: {batch1.title}")
    print(f"   Message: {batch1.message}")
    
    # Test finding existing batch within window
    batch2 = await NotificationBatch.find_or_create_batch(
        user_id=user_id,
        batch_type=NotificationType.COMMENT,
        related_id=post_id,
        window_minutes=5
    )
    
    if str(batch1.id) == str(batch2.id):
        print("✅ Found existing batch within window (as expected)")
    else:
        print("❌ Created new batch when should have found existing")
    
    return batch1


async def test_different_batch_types():
    """Test different notification types create separate batches"""
    print("\n🧪 Testing different batch types...")
    
    user_id = "test_user_456"
    
    # Create comment batch
    comment_batch = await NotificationBatch.find_or_create_batch(
        user_id=user_id,
        batch_type=NotificationType.COMMENT,
        related_id="post_1",
        window_minutes=5
    )
    
    # Create friend request batch
    friend_batch = await NotificationBatch.find_or_create_batch(
        user_id=user_id,
        batch_type=NotificationType.FRIEND_REQUEST,
        related_id=None,
        window_minutes=5
    )
    
    if str(comment_batch.id) != str(friend_batch.id):
        print("✅ Different notification types create separate batches")
    else:
        print("❌ Same batch ID for different notification types")
    
    return comment_batch, friend_batch


async def test_time_window_expiry():
    """Test that expired time windows create new batches"""
    print("\n🧪 Testing time window expiry...")
    
    user_id = "test_user_789"
    
    # Create batch with expired window
    batch1 = await NotificationBatch.find_or_create_batch(
        user_id=user_id,
        batch_type=NotificationType.COMMENT,
        related_id="post_2",
        window_minutes=5
    )
    
    # Manually expire the batch
    batch1.batch_window_end = datetime.utcnow() - timedelta(minutes=1)
    await batch1.save()
    
    # Try to create another batch - should create new one
    batch2 = await NotificationBatch.find_or_create_batch(
        user_id=user_id,
        batch_type=NotificationType.COMMENT,
        related_id="post_2",
        window_minutes=5
    )
    
    if str(batch1.id) != str(batch2.id):
        print("✅ Expired time window creates new batch")
    else:
        print("❌ Reused expired batch")
    
    return batch1, batch2


async def test_batch_message_formatting():
    """Test batch message formatting for different counts"""
    print("\n🧪 Testing batch message formatting...")
    
    user_id = "test_user_msg"
    
    # Test single comment
    batch = await NotificationBatch.find_or_create_batch(
        user_id=user_id,
        batch_type=NotificationType.COMMENT,
        related_id="post_msg",
        window_minutes=5
    )
    
    batch.add_notification("notif_1", "user_1", "Alice")
    await batch.save()
    print(f"✅ Single comment: {batch.title}")
    
    # Test two comments
    batch.add_notification("notif_2", "user_2", "Bob")
    await batch.save()
    print(f"✅ Two comments: {batch.title}")
    
    # Test multiple comments
    batch.add_notification("notif_3", "user_3", "Charlie")
    await batch.save()
    print(f"✅ Multiple comments: {batch.title}")
    
    # Test friend requests
    friend_batch = await NotificationBatch.find_or_create_batch(
        user_id=user_id,
        batch_type=NotificationType.FRIEND_REQUEST,
        related_id=None,
        window_minutes=5
    )
    
    friend_batch.add_notification("friend_1", "user_1", "Alice")
    await friend_batch.save()
    print(f"✅ Single friend request: {friend_batch.title}")
    
    friend_batch.add_notification("friend_2", "user_2", "Bob")
    await friend_batch.save()
    print(f"✅ Multiple friend requests: {friend_batch.title}")
    
    return batch, friend_batch


async def cleanup_test_data():
    """Clean up test data"""
    print("\n🧹 Cleaning up test data...")
    
    try:
        # Delete test batches
        test_batches = await NotificationBatch.find({
            "user_id": {"$regex": "test_user"}
        }).to_list()
        
        for batch in test_batches:
            await batch.delete()
        
        print(f"✅ Cleaned up {len(test_batches)} test batches")
        
    except Exception as e:
        print(f"⚠️  Error during cleanup: {e}")


async def main():
    """Run all tests"""
    print("🚀 Starting notification batching tests...\n")
    
    try:
        # Run tests
        await test_notification_batch_creation()
        await test_different_batch_types()
        await test_time_window_expiry()
        await test_batch_message_formatting()
        
        print("\n✅ All tests completed successfully!")
        
    except Exception as e:
        print(f"\n❌ Test failed with error: {e}")
        import traceback
        traceback.print_exc()
    
    finally:
        # Always cleanup
        await cleanup_test_data()
    
    print("\n🎉 Notification batching test complete!")


if __name__ == "__main__":
    asyncio.run(main())