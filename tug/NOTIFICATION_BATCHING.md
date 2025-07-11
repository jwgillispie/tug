# Notification Batching Implementation

This document describes the notification batching system implemented to prevent notification spam and improve user experience.

## Overview

The notification batching system groups related notifications within a time window (default: 5 minutes) to reduce notification noise. Instead of receiving multiple individual notifications like "Alice commented on your post", "Bob commented on your post", "Charlie commented on your post", users now receive a single batched notification like "Alice and 2 others commented on your post".

## Architecture

### Backend Components

#### 1. NotificationBatch Model (`/backend/app/models/notification.py`)

```python
class NotificationBatch(Document):
    user_id: str                    # User receiving the batch
    batch_type: NotificationType    # Type of notifications (comment, friend_request, etc.)
    related_id: Optional[str]       # Related entity (post_id, etc.)
    
    # Batch content
    title: str                      # Dynamic title ("Alice and 2 others...")
    message: str                    # Dynamic message
    notification_ids: List[str]     # Individual notification IDs in batch
    user_ids: List[str]            # Users who triggered notifications
    user_names: List[str]          # Display names of users
    
    # Metadata
    count: int                     # Number of notifications
    batch_window_start: datetime   # Window start time
    batch_window_end: datetime     # Window end time
    
    # Status
    is_read: bool                  # Read status
    is_active: bool               # Whether batch accepts new notifications
```

**Key Methods:**
- `find_or_create_batch()`: Finds existing active batch or creates new one
- `add_notification()`: Adds notification to batch and updates message
- `_update_batch_message()`: Updates title/message based on current content

#### 2. Updated NotificationService (`/backend/app/services/notification_service.py`)

**Enhanced Methods:**
- `create_comment_notification()`: Now creates individual notification AND adds to batch
- `create_friend_request_notification()`: Same batching logic
- `create_friend_accepted_notification()`: Same batching logic
- `_add_to_batch()`: Helper method to add notifications to batches
- `get_batched_notifications()`: Retrieves batched notifications
- `get_batched_notification_summary()`: Retrieves batched summary

#### 3. New API Endpoints (`/backend/app/api/endpoints/notifications.py`)

- `GET /api/v1/notifications/batched/summary`: Get batched notification summary
- `GET /api/v1/notifications/batched`: Get list of batched notifications

### Frontend Components

#### 1. Updated SocialNotificationService (`/lib/services/social_notification_service.dart`)

**Enhanced Methods:**
- `getNotificationSummary()`: Added `useBatched` parameter (default: true)
- `getNotifications()`: Added `useBatched` parameter (default: true)
- `getBatchedNotifications()`: Convenience method for batched notifications
- `getIndividualNotifications()`: Convenience method for individual notifications

## Batching Logic

### Time Windows
- **Default Window**: 5 minutes
- **Window Start**: When first notification in batch is created
- **Window End**: 5 minutes after window start
- **Batch Closure**: Batches automatically close when window expires

### Grouping Rules
Notifications are grouped into the same batch if they have:
1. Same `user_id` (recipient)
2. Same `notification_type` (comment, friend_request, etc.)
3. Same `related_id` (same post, etc.) OR both null
4. Active batch within the time window

### Message Generation

#### Comment Notifications
- **1 notification**: "Alice commented on your post"
- **2 notifications**: "Alice and Bob commented on your post"  
- **3+ notifications**: "Alice and 2 others commented on your post"

#### Friend Request Notifications
- **1 notification**: "Alice sent you a friend request"
- **2+ notifications**: "You have 3 new friend requests"

#### Friend Accepted Notifications
- **1 notification**: "Alice accepted your friend request"
- **2+ notifications**: "3 people accepted your friend requests"

## Database Schema

### NotificationBatch Collection
```javascript
{
  _id: ObjectId,
  user_id: "user_123",
  batch_type: "comment",
  related_id: "post_456",           // Optional
  title: "Alice and 2 others commented on your post",
  message: "Tap to view all 3 comments",
  notification_ids: ["notif_1", "notif_2", "notif_3"],
  user_ids: ["user_1", "user_2", "user_3"],
  user_names: ["Alice", "Bob", "Charlie"],
  count: 3,
  batch_window_start: ISODate("2024-01-01T10:00:00Z"),
  batch_window_end: ISODate("2024-01-01T10:05:00Z"),
  is_read: false,
  is_active: true,
  created_at: ISODate("2024-01-01T10:00:00Z"),
  updated_at: ISODate("2024-01-01T10:02:30Z")
}
```

### Database Indexes
```javascript
// Optimized for batch lookup
{ "user_id": 1, "batch_type": 1, "related_id": 1, "is_active": 1 }

// Optimized for user queries
{ "user_id": 1, "is_read": 1, "updated_at": -1 }

// Single field indexes
{ "batch_window_end": 1 }
{ "is_active": 1 }
```

## Usage Examples

### Backend Usage

```python
# Create a comment notification (automatically batched)
await NotificationService.create_comment_notification(
    post_owner_id="user_123",
    commenter_id="user_456", 
    commenter_name="Alice",
    post_id="post_789",
    post_content="Check out this cool feature!"
)

# Get batched notifications
batched = await NotificationService.get_batched_notifications(
    current_user=user,
    limit=20,
    unread_only=True
)

# Get batched summary
summary = await NotificationService.get_batched_notification_summary(user)
```

### Frontend Usage

```dart
// Get batched notification summary (default behavior)
final summary = await SocialNotificationService().getNotificationSummary();

// Get batched notifications
final notifications = await SocialNotificationService().getBatchedNotifications(
  limit: 20,
  unreadOnly: true,
);

// Get individual notifications (if needed)
final individual = await SocialNotificationService().getIndividualNotifications();
```

## Benefits

### User Experience
- **Reduced Noise**: Users see "Alice and 2 others commented" instead of 3 separate notifications
- **Better Context**: Batched messages provide clearer understanding of activity
- **Cleaner Interface**: Notification lists are less cluttered

### Performance
- **Fewer API Calls**: Frontend requests fewer notification items
- **Reduced Database Load**: Batch queries are more efficient
- **Better Scalability**: System handles high notification volumes better

### System Health
- **Spam Prevention**: Automatic grouping prevents notification floods
- **Resource Efficiency**: Less storage and bandwidth usage
- **Improved Delivery**: More reliable notification processing

## Configuration

### Adjusting Time Windows
```python
# Create batch with custom window
batch = await NotificationBatch.find_or_create_batch(
    user_id=user_id,
    batch_type=NotificationType.COMMENT,
    related_id=post_id,
    window_minutes=10  # 10-minute window instead of 5
)
```

### Enabling/Disabling Batching
```dart
// Frontend can choose batched or individual
final summary = await service.getNotificationSummary(useBatched: false);
final notifications = await service.getNotifications(useBatched: false);
```

## Migration Strategy

The system maintains backward compatibility:

1. **Dual Endpoints**: Both batched and individual notification endpoints exist
2. **Gradual Rollout**: Frontend can toggle between batched/individual
3. **Fallback Support**: Errors in batching fall back to individual notifications
4. **Data Preservation**: Original notifications are still stored individually

## Testing

Run the test script to verify functionality:

```bash
cd /Users/jordangillispie/development/tug/tug
python test_notification_batching.py
```

The test covers:
- Batch creation and time windows
- Message formatting for different counts
- Separate batches for different notification types
- Time window expiry behavior

## Future Enhancements

### Planned Features
1. **User Preferences**: Allow users to customize batching behavior
2. **Smart Grouping**: AI-powered intelligent notification grouping
3. **Digest Notifications**: Daily/weekly digest emails
4. **Real-time Updates**: WebSocket-based instant batch updates
5. **Analytics**: Track batching effectiveness and user engagement

### Potential Improvements
1. **Dynamic Windows**: Adjust time windows based on user activity patterns
2. **Priority Batching**: Different batching rules for high-priority notifications
3. **Cross-type Batching**: Group different notification types intelligently
4. **Batch Actions**: Bulk actions on batched notifications

## Monitoring

Key metrics to monitor:
- Batch creation rate vs individual notification rate
- Average notifications per batch
- User engagement with batched vs individual notifications
- Time window hit rates
- System performance improvements

## Troubleshooting

### Common Issues

1. **Batches Not Creating**: Check time window logic and database indexes
2. **Messages Not Updating**: Verify `_update_batch_message()` is called after `add_notification()`
3. **Duplicate Notifications**: Ensure proper deduplication in `add_notification()`
4. **Performance Issues**: Review database indexes and query patterns

### Debug Commands

```python
# Check active batches for user
batches = await NotificationBatch.find({
    "user_id": "user_123",
    "is_active": True
}).to_list()

# Check batch content
print(f"Batch {batch.id}: {batch.count} notifications")
print(f"Users: {batch.user_names}")
print(f"Window: {batch.batch_window_start} to {batch.batch_window_end}")
```

---

This notification batching system significantly improves the user experience by reducing notification spam while maintaining all the context and functionality users expect from a social notification system.