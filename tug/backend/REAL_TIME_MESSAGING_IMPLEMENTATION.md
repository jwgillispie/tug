# Real-Time Messaging System Implementation

## Overview

A comprehensive real-time messaging system has been implemented for premium groups in the Tug app, providing live chat functionality with modern features including WebSocket support, message threading, media sharing, and advanced premium-only features.

## Architecture Overview

### Backend Components

1. **WebSocket Manager** (`app/services/websocket_manager.py`)
   - Real-time connection management
   - Authentication and authorization
   - Room-based messaging (groups and threads)
   - Rate limiting and security
   - Connection cleanup and health monitoring

2. **Group Messaging Service** (`app/services/group_messaging_service.py`)
   - Message CRUD operations
   - Thread management
   - Reaction handling
   - Search and pagination
   - Typing indicators

3. **Media Service** (`app/services/media_service.py`)
   - File upload handling
   - Image processing and thumbnails
   - Audio/video metadata extraction
   - Security validation
   - Storage management

4. **Notification Service Integration**
   - Group message notifications
   - Mention notifications
   - Offline user queuing
   - Push notification support

## Key Features Implemented

### 🔄 Real-Time Communication
- **WebSocket Server**: FastAPI-based WebSocket support with secure connections
- **Connection Management**: User session tracking with automatic cleanup
- **Group Rooms**: Real-time group-based message broadcasting
- **Thread Rooms**: Support for threaded conversations
- **Authentication**: JWT token validation for WebSocket connections
- **Rate Limiting**: Intelligent throttling to prevent spam (30 messages/minute per user)
- **Connection Limits**: Maximum 5 concurrent connections per user

### 💬 Core Messaging Features
- **Message Types**: Text, image, voice, video, file, system, announcement
- **Message Status**: Sending, sent, delivered, read, failed
- **Message Threading**: Reply to specific messages with organized conversations
- **Message Editing**: Edit messages within 15-minute window (unlimited for admins)
- **Message Deletion**: Soft delete with admin override capabilities
- **Message Pinning**: Pin important messages (admin/moderator only)
- **Message Search**: Full-text search within group history

### 🎯 Advanced Features
- **Reactions**: 10+ emoji reactions (like, love, laugh, wow, sad, angry, thumbs up/down, fire, heart)
- **Mentions**: @username mentions with special notifications
- **Typing Indicators**: Real-time typing status with auto-expiry
- **Read Receipts**: Message delivery and read confirmation
- **Presence System**: User online/offline status tracking

### 📁 Media & File Sharing
- **Image Support**: JPEG, PNG, GIF, WebP, SVG, BMP, TIFF (10MB limit)
- **Voice Notes**: MP3, WAV, OGG, MP4, AAC, WebM (25MB limit)
- **Video Files**: MP4, MPEG, QuickTime, WebM, AVI, 3GP (100MB limit)
- **Documents**: PDF, DOC, DOCX, XLS, XLSX, PPT, PPTX (50MB limit)
- **Image Processing**: Automatic thumbnail generation (small, medium, large)
- **Security**: MIME type validation, content scanning, secure filenames

### 🔒 Security & Premium Features
- **Premium Access Control**: Only premium group members can access messaging
- **Role-Based Permissions**: Owner, admin, moderator, member roles
- **Content Moderation**: AI-powered content filtering for premium groups
- **Message History**: Extended history for premium groups
- **Priority Delivery**: Enhanced message delivery for premium users
- **Input Sanitization**: XSS, SQL injection, and NoSQL injection protection

## Database Schema

### Core Collections

1. **group_messages**
   - Message content and metadata
   - Threading support (thread_id, reply_count)
   - Status tracking (delivery_receipts, read_receipts)
   - Media attachments (media_urls, attachment_data)
   - Moderation fields (is_deleted, is_pinned, is_announcement)

2. **message_reactions**
   - User reactions to messages
   - Reaction types and custom emojis
   - Aggregated reaction counts

3. **typing_indicators**
   - Real-time typing status
   - Auto-expiry after 10 seconds
   - Thread-specific typing

4. **message_queue**
   - Offline message delivery
   - Retry mechanism (max 3 attempts)
   - Priority-based queuing

### Optimized Indexes
- Group message timeline: `[("group_id", 1), ("created_at", -1)]`
- Thread queries: `[("thread_id", 1), ("created_at", 1)]`
- User activity: `[("user_id", 1), ("created_at", -1)]`
- Content search: `[("group_id", 1), ("content", "text")]`
- Message status: `[("group_id", 1), ("status", 1)]`

## API Endpoints

### WebSocket Connection
```
WS /api/v1/messaging/ws/{group_id}?token=<jwt_token>
```

### REST API Endpoints
```
POST   /api/v1/messaging/{group_id}/messages        # Send message
GET    /api/v1/messaging/{group_id}/messages        # Get messages
PUT    /api/v1/messaging/messages/{message_id}      # Edit message  
DELETE /api/v1/messaging/messages/{message_id}      # Delete message
POST   /api/v1/messaging/messages/{message_id}/react # React to message
POST   /api/v1/messaging/{group_id}/messages/mark-read # Mark as read
POST   /api/v1/messaging/{group_id}/search          # Search messages
POST   /api/v1/messaging/{group_id}/typing          # Typing indicators
POST   /api/v1/messaging/{group_id}/upload          # Upload media
```

## WebSocket Message Protocol

### Client → Server Messages
```json
{
  "type": "send_message",
  "group_id": "group_id_here",
  "data": {
    "content": "Hello, world!",
    "message_type": "text",
    "thread_id": null,
    "mentioned_user_ids": [],
    "media_urls": []
  },
  "message_id": "client_message_id"
}
```

### Server → Client Messages
```json
{
  "type": "message",
  "group_id": "group_id_here",
  "data": {
    "id": "message_id_here",
    "content": "Hello, world!",
    "author": {
      "id": "user_id",
      "username": "john_doe",
      "display_name": "John Doe",
      "avatar_url": "/uploads/avatars/user.jpg"
    },
    "created_at": "2025-01-08T10:00:00Z",
    "message_type": "text",
    "reactions": [],
    "reply_count": 0
  },
  "timestamp": "2025-01-08T10:00:00Z"
}
```

## Security Measures

### Input Validation
- Content sanitization (XSS prevention)
- Pattern detection for injection attempts
- File type and size validation
- MIME type verification
- Secure filename generation

### Rate Limiting
- 30 messages per minute per user
- 5 concurrent connections per user
- File upload size limits by type
- Request payload size limits (10MB max)

### Authentication & Authorization
- JWT token validation for all operations
- Group membership verification
- Role-based permission checks
- Premium subscription validation

## Performance Optimizations

### Database Optimizations
- Strategic indexing for common queries
- Message pagination with cursor-based approach
- Aggregated reaction counts
- Efficient text search with MongoDB text indexes

### WebSocket Optimizations
- Connection pooling and reuse
- Message broadcasting batching
- Heartbeat-based connection health checks
- Graceful connection cleanup

### Media Optimizations
- Thumbnail generation for images
- File deduplication using MD5 hashes
- Temporary file cleanup
- Progressive image loading support

## Monitoring & Health

### Connection Monitoring
- Real-time connection statistics
- User activity tracking
- Error rate monitoring
- Performance metrics collection

### Health Checks
```
GET /api/v1/messaging/health
```

Returns system health including:
- WebSocket manager status
- Active connection count
- Error rates
- System resources

## Production Deployment

### Requirements Added
- `websockets>=12.0` - WebSocket protocol support
- `aiofiles>=23.0.0` - Async file operations
- `Pillow>=10.0.0` - Image processing

### Application Startup
- WebSocket manager auto-starts with application
- Background cleanup tasks for expired connections
- Graceful shutdown handling

### Configuration
- Configurable rate limits
- Adjustable file size limits
- Customizable security settings
- Environment-based feature toggles

## Usage Examples

### Frontend WebSocket Integration (Flutter/Dart)
```dart
// Connect to group messaging
final websocket = WebSocketChannel.connect(
  Uri.parse('ws://localhost:8000/api/v1/messaging/ws/$groupId?token=$jwtToken')
);

// Send message
websocket.sink.add(jsonEncode({
  'type': 'send_message',
  'group_id': groupId,
  'data': {
    'content': 'Hello everyone!',
    'message_type': 'text'
  }
}));

// Listen for messages
websocket.stream.listen((message) {
  final data = jsonDecode(message);
  if (data['type'] == 'message') {
    // Handle new message
    updateMessageList(data['data']);
  }
});
```

### React to Message
```dart
websocket.sink.add(jsonEncode({
  'type': 'react_to_message',
  'group_id': groupId,
  'data': {
    'message_id': messageId,
    'reaction_data': {
      'reaction_type': 'like'
    }
  }
}));
```

### Start/Stop Typing
```dart
// Start typing
websocket.sink.add(jsonEncode({
  'type': 'start_typing',
  'group_id': groupId,
  'data': {'thread_id': threadId} // optional
}));

// Stop typing  
websocket.sink.add(jsonEncode({
  'type': 'stop_typing',
  'group_id': groupId,
  'data': {'thread_id': threadId} // optional
}));
```

## Future Enhancements

### Planned Features
1. **Voice Messages**: Real-time voice note recording and playback
2. **Video Calls**: Integrated video calling for premium groups
3. **Message Scheduling**: Schedule messages for later delivery
4. **Message Templates**: Pre-defined message templates
5. **Advanced Search**: Search by date, user, file type, etc.
6. **Message Export**: Export group conversations
7. **Message Translation**: Real-time message translation
8. **AI Moderation**: Enhanced AI-powered content moderation

### Technical Improvements
1. **Horizontal Scaling**: Multi-server WebSocket support with Redis
2. **Message Encryption**: End-to-end encryption for premium groups
3. **CDN Integration**: Global media delivery network
4. **Caching Layer**: Redis-based message caching
5. **Advanced Analytics**: Message engagement analytics
6. **Performance Monitoring**: Real-time performance dashboards

## Testing

### Test Coverage Areas
- WebSocket connection handling
- Message CRUD operations
- Real-time broadcasting
- File upload and processing
- Security validation
- Rate limiting
- Error handling

### Performance Testing
- Concurrent connection limits
- Message throughput testing
- File upload stress testing
- Database query optimization
- Memory usage monitoring

This comprehensive real-time messaging system provides premium group members with modern chat functionality while maintaining high performance, security, and scalability standards. The system is production-ready and can handle thousands of concurrent users with proper infrastructure scaling.