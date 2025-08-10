# app/services/websocket_manager.py
import json
import asyncio
import logging
from typing import Dict, List, Set, Optional, Any
from datetime import datetime, timedelta
from dataclasses import dataclass, asdict
from enum import Enum
import weakref

from fastapi import WebSocket, WebSocketDisconnect
from fastapi.websockets import WebSocketState
from pydantic import ValidationError

from ..models.user import User
from ..models.group_message import GroupMessage, MessageReaction, TypingIndicator
from ..models.premium_group import GroupMembership, MembershipStatus
from ..schemas.group_message import WebSocketMessage, WebSocketMessageType, WebSocketError
from ..core.auth import verify_firebase_token
from ..core.config import settings

logger = logging.getLogger(__name__)

class ConnectionStatus(str, Enum):
    CONNECTING = "connecting"
    CONNECTED = "connected"
    AUTHENTICATING = "authenticating"
    AUTHENTICATED = "authenticated"
    DISCONNECTING = "disconnecting"
    DISCONNECTED = "disconnected"

@dataclass
class WebSocketConnection:
    """Represents a WebSocket connection with metadata"""
    websocket: WebSocket
    user_id: str
    username: str
    connection_id: str
    connected_at: datetime
    last_heartbeat: datetime
    status: ConnectionStatus
    subscribed_groups: Set[str]
    active_threads: Set[str]
    rate_limit_bucket: List[datetime]
    
    def is_alive(self) -> bool:
        """Check if connection is alive and authenticated"""
        return (self.websocket.client_state == WebSocketState.CONNECTED and 
                self.status == ConnectionStatus.AUTHENTICATED)
    
    def is_heartbeat_expired(self, timeout_seconds: int = 60) -> bool:
        """Check if heartbeat has expired"""
        return datetime.utcnow() - self.last_heartbeat > timedelta(seconds=timeout_seconds)
    
    def can_send_message(self, rate_limit_per_minute: int = 30) -> bool:
        """Check rate limiting for message sending"""
        now = datetime.utcnow()
        # Remove old entries
        self.rate_limit_bucket = [
            timestamp for timestamp in self.rate_limit_bucket 
            if now - timestamp < timedelta(minutes=1)
        ]
        return len(self.rate_limit_bucket) < rate_limit_per_minute
    
    def add_rate_limit_entry(self):
        """Add current timestamp to rate limit bucket"""
        self.rate_limit_bucket.append(datetime.utcnow())
    
    def update_heartbeat(self):
        """Update heartbeat timestamp"""
        self.last_heartbeat = datetime.utcnow()

class WebSocketManager:
    """Manages WebSocket connections for real-time messaging"""
    
    def __init__(self):
        # Active connections by connection_id
        self.connections: Dict[str, WebSocketConnection] = {}
        
        # User connections mapping (user_id -> set of connection_ids)
        self.user_connections: Dict[str, Set[str]] = {}
        
        # Group connections mapping (group_id -> set of connection_ids)
        self.group_connections: Dict[str, Set[str]] = {}
        
        # Thread connections mapping (thread_id -> set of connection_ids)
        self.thread_connections: Dict[str, Set[str]] = {}
        
        # Message broadcast queues
        self.broadcast_queues: Dict[str, asyncio.Queue] = {}
        
        # Connection cleanup task
        self.cleanup_task: Optional[asyncio.Task] = None
        
        # Rate limiting settings
        self.rate_limit_messages_per_minute = 30
        self.rate_limit_connections_per_user = 5
        self.heartbeat_timeout_seconds = 60
        
    async def start_manager(self):
        """Start the WebSocket manager background tasks"""
        logger.info("Starting WebSocket manager")
        self.cleanup_task = asyncio.create_task(self._cleanup_expired_connections())
    
    async def stop_manager(self):
        """Stop the WebSocket manager and cleanup"""
        logger.info("Stopping WebSocket manager")
        if self.cleanup_task:
            self.cleanup_task.cancel()
        
        # Disconnect all connections gracefully
        for conn in list(self.connections.values()):
            await self.disconnect_user(conn.connection_id, "Server shutdown")
    
    async def connect_user(
        self, 
        websocket: WebSocket, 
        token: str,
        connection_id: str
    ) -> Optional[WebSocketConnection]:
        """Authenticate and connect a user via WebSocket"""
        try:
            # Accept the WebSocket connection
            await websocket.accept()
            
            # Create temporary connection for authentication
            temp_connection = WebSocketConnection(
                websocket=websocket,
                user_id="",
                username="",
                connection_id=connection_id,
                connected_at=datetime.utcnow(),
                last_heartbeat=datetime.utcnow(),
                status=ConnectionStatus.AUTHENTICATING,
                subscribed_groups=set(),
                active_threads=set(),
                rate_limit_bucket=[]
            )
            
            # Authenticate user
            try:
                payload = decode_jwt_token(token)
                user_id = payload.get("sub")
                username = payload.get("username", "Unknown")
                
                if not user_id:
                    await self._send_error(websocket, "authentication_failed", "Invalid token")
                    await websocket.close()
                    return None
                
                # Check connection limits per user
                user_connection_count = len(self.user_connections.get(user_id, set()))
                if user_connection_count >= self.rate_limit_connections_per_user:
                    await self._send_error(websocket, "connection_limit_exceeded", 
                                          f"Maximum {self.rate_limit_connections_per_user} connections per user")
                    await websocket.close()
                    return None
                
                # Update connection with user info
                temp_connection.user_id = user_id
                temp_connection.username = username
                temp_connection.status = ConnectionStatus.AUTHENTICATED
                
                # Store connection
                self.connections[connection_id] = temp_connection
                
                # Update user connections mapping
                if user_id not in self.user_connections:
                    self.user_connections[user_id] = set()
                self.user_connections[user_id].add(connection_id)
                
                logger.info(f"User {username} ({user_id}) connected via WebSocket: {connection_id}")
                
                # Send connection success message
                await self._send_to_connection(connection_id, {
                    "type": "connection_established",
                    "data": {
                        "connection_id": connection_id,
                        "user_id": user_id,
                        "username": username,
                        "connected_at": temp_connection.connected_at.isoformat()
                    }
                })
                
                return temp_connection
                
            except Exception as auth_error:
                logger.error(f"WebSocket authentication error: {auth_error}")
                await self._send_error(websocket, "authentication_failed", "Invalid or expired token")
                await websocket.close()
                return None
        
        except Exception as e:
            logger.error(f"WebSocket connection error: {e}")
            try:
                await websocket.close()
            except:
                pass
            return None
    
    async def disconnect_user(self, connection_id: str, reason: str = "Normal closure"):
        """Disconnect a user and cleanup their connection"""
        connection = self.connections.get(connection_id)
        if not connection:
            return
        
        logger.info(f"Disconnecting user {connection.username} ({connection.user_id}): {reason}")
        
        try:
            # Update connection status
            connection.status = ConnectionStatus.DISCONNECTING
            
            # Leave all groups
            for group_id in list(connection.subscribed_groups):
                await self.leave_group(connection_id, group_id)
            
            # Leave all threads
            for thread_id in list(connection.active_threads):
                await self.leave_thread(connection_id, thread_id)
            
            # Remove from user connections
            if connection.user_id in self.user_connections:
                self.user_connections[connection.user_id].discard(connection_id)
                if not self.user_connections[connection.user_id]:
                    del self.user_connections[connection.user_id]
            
            # Close WebSocket if still open
            if connection.websocket.client_state == WebSocketState.CONNECTED:
                await connection.websocket.close()
            
            # Remove connection
            connection.status = ConnectionStatus.DISCONNECTED
            del self.connections[connection_id]
            
        except Exception as e:
            logger.error(f"Error during disconnection: {e}")
    
    async def join_group(self, connection_id: str, group_id: str) -> bool:
        """Subscribe connection to a group for real-time updates"""
        connection = self.connections.get(connection_id)
        if not connection or not connection.is_alive():
            return False
        
        try:
            # Verify user is a member of the group
            membership = await GroupMembership.find_one({
                "group_id": group_id,
                "user_id": connection.user_id,
                "status": MembershipStatus.ACTIVE
            })
            
            if not membership:
                await self._send_error_to_connection(
                    connection_id, "access_denied", 
                    "You are not a member of this group"
                )
                return False
            
            # Add to group connections
            if group_id not in self.group_connections:
                self.group_connections[group_id] = set()
            self.group_connections[group_id].add(connection_id)
            
            # Update connection
            connection.subscribed_groups.add(group_id)
            
            # Notify other group members
            await self._broadcast_to_group(group_id, {
                "type": WebSocketMessageType.USER_JOINED,
                "group_id": group_id,
                "data": {
                    "user_id": connection.user_id,
                    "username": connection.username,
                    "joined_at": datetime.utcnow().isoformat()
                }
            }, exclude_connection=connection_id)
            
            logger.info(f"User {connection.username} joined group {group_id}")
            return True
            
        except Exception as e:
            logger.error(f"Error joining group {group_id}: {e}")
            return False
    
    async def leave_group(self, connection_id: str, group_id: str):
        """Unsubscribe connection from a group"""
        connection = self.connections.get(connection_id)
        if not connection:
            return
        
        # Remove from group connections
        if group_id in self.group_connections:
            self.group_connections[group_id].discard(connection_id)
            if not self.group_connections[group_id]:
                del self.group_connections[group_id]
        
        # Update connection
        connection.subscribed_groups.discard(group_id)
        
        # Notify other group members
        await self._broadcast_to_group(group_id, {
            "type": WebSocketMessageType.USER_LEFT,
            "group_id": group_id,
            "data": {
                "user_id": connection.user_id,
                "username": connection.username,
                "left_at": datetime.utcnow().isoformat()
            }
        })
        
        logger.info(f"User {connection.username} left group {group_id}")
    
    async def join_thread(self, connection_id: str, thread_id: str) -> bool:
        """Subscribe connection to a specific message thread"""
        connection = self.connections.get(connection_id)
        if not connection or not connection.is_alive():
            return False
        
        # Add to thread connections
        if thread_id not in self.thread_connections:
            self.thread_connections[thread_id] = set()
        self.thread_connections[thread_id].add(connection_id)
        
        # Update connection
        connection.active_threads.add(thread_id)
        
        return True
    
    async def leave_thread(self, connection_id: str, thread_id: str):
        """Unsubscribe connection from a message thread"""
        connection = self.connections.get(connection_id)
        if not connection:
            return
        
        # Remove from thread connections
        if thread_id in self.thread_connections:
            self.thread_connections[thread_id].discard(connection_id)
            if not self.thread_connections[thread_id]:
                del self.thread_connections[thread_id]
        
        # Update connection
        connection.active_threads.discard(thread_id)
    
    async def broadcast_message(self, group_id: str, message_data: Dict[str, Any]):
        """Broadcast a message to all connected group members"""
        await self._broadcast_to_group(group_id, {
            "type": WebSocketMessageType.MESSAGE,
            "group_id": group_id,
            "data": message_data,
            "timestamp": datetime.utcnow().isoformat()
        })
    
    async def broadcast_message_update(self, group_id: str, message_data: Dict[str, Any]):
        """Broadcast message update to group"""
        await self._broadcast_to_group(group_id, {
            "type": WebSocketMessageType.MESSAGE_UPDATED,
            "group_id": group_id,
            "data": message_data,
            "timestamp": datetime.utcnow().isoformat()
        })
    
    async def broadcast_message_deletion(self, group_id: str, message_id: str):
        """Broadcast message deletion to group"""
        await self._broadcast_to_group(group_id, {
            "type": WebSocketMessageType.MESSAGE_DELETED,
            "group_id": group_id,
            "data": {"message_id": message_id},
            "timestamp": datetime.utcnow().isoformat()
        })
    
    async def broadcast_reaction(self, group_id: str, reaction_data: Dict[str, Any]):
        """Broadcast message reaction to group"""
        await self._broadcast_to_group(group_id, {
            "type": WebSocketMessageType.MESSAGE_REACTION,
            "group_id": group_id,
            "data": reaction_data,
            "timestamp": datetime.utcnow().isoformat()
        })
    
    async def broadcast_typing_start(self, group_id: str, user_data: Dict[str, Any], thread_id: Optional[str] = None):
        """Broadcast typing start indicator"""
        await self._broadcast_to_group(group_id, {
            "type": WebSocketMessageType.TYPING_START,
            "group_id": group_id,
            "data": {
                **user_data,
                "thread_id": thread_id
            }
        })
    
    async def broadcast_typing_stop(self, group_id: str, user_data: Dict[str, Any], thread_id: Optional[str] = None):
        """Broadcast typing stop indicator"""
        await self._broadcast_to_group(group_id, {
            "type": WebSocketMessageType.TYPING_STOP,
            "group_id": group_id,
            "data": {
                **user_data,
                "thread_id": thread_id
            }
        })
    
    async def send_to_user(self, user_id: str, message_data: Dict[str, Any]):
        """Send message to all connections of a specific user"""
        user_connection_ids = self.user_connections.get(user_id, set())
        for connection_id in list(user_connection_ids):
            await self._send_to_connection(connection_id, message_data)
    
    async def handle_message(self, connection_id: str, raw_message: str) -> bool:
        """Handle incoming WebSocket message from client"""
        connection = self.connections.get(connection_id)
        if not connection or not connection.is_alive():
            return False
        
        try:
            # Parse message
            message_data = json.loads(raw_message)
            ws_message = WebSocketMessage(**message_data)
            
            # Update heartbeat
            connection.update_heartbeat()
            
            # Handle heartbeat ping
            if ws_message.type == WebSocketMessageType.PING:
                await self._send_to_connection(connection_id, {
                    "type": WebSocketMessageType.PONG,
                    "timestamp": datetime.utcnow().isoformat()
                })
                return True
            
            # Check rate limiting for non-ping messages
            if not connection.can_send_message(self.rate_limit_messages_per_minute):
                await self._send_error_to_connection(
                    connection_id, "rate_limit_exceeded",
                    f"Message rate limit of {self.rate_limit_messages_per_minute}/min exceeded"
                )
                return False
            
            # Add to rate limit bucket
            connection.add_rate_limit_entry()
            
            # Route message based on type
            return await self._route_message(connection, ws_message)
            
        except json.JSONDecodeError:
            await self._send_error_to_connection(connection_id, "invalid_json", "Invalid JSON format")
            return False
        except ValidationError as e:
            await self._send_error_to_connection(connection_id, "validation_error", str(e))
            return False
        except Exception as e:
            logger.error(f"Error handling message from {connection_id}: {e}")
            await self._send_error_to_connection(connection_id, "internal_error", "Message processing failed")
            return False
    
    async def _route_message(self, connection: WebSocketConnection, message: WebSocketMessage) -> bool:
        """Route WebSocket message to appropriate handler"""
        try:
            # Import here to avoid circular imports
            from .group_messaging_service import group_messaging_service
            from ..models.user import User
            from ..schemas.group_message import (
                SendMessageRequest, EditMessageRequest, ReactToMessageRequest,
                MarkMessagesReadRequest, TypingIndicatorRequest
            )
            
            # Get current user
            user = await User.get(connection.user_id)
            if not user:
                await self._send_error_to_connection(
                    connection.connection_id, "user_not_found", "User not found"
                )
                return False
            
            # Route based on message type
            if message.type == WebSocketMessageType.SEND_MESSAGE:
                # Send new message
                try:
                    send_data = SendMessageRequest(**message.data)
                    result = await group_messaging_service.send_message(user, message.group_id, send_data)
                    
                    await self._send_to_connection(connection.connection_id, {
                        "type": "message_sent",
                        "data": result.dict(),
                        "message_id": message.message_id
                    })
                    return True
                except Exception as e:
                    await self._send_error_to_connection(
                        connection.connection_id, "send_failed", str(e)
                    )
                    return False
            
            elif message.type == WebSocketMessageType.EDIT_MESSAGE:
                # Edit message
                try:
                    edit_data = EditMessageRequest(**message.data.get("edit_data", {}))
                    message_id = message.data.get("message_id")
                    
                    if not message_id:
                        await self._send_error_to_connection(
                            connection.connection_id, "missing_message_id", "Message ID required"
                        )
                        return False
                    
                    result = await group_messaging_service.edit_message(user, message_id, edit_data)
                    
                    await self._send_to_connection(connection.connection_id, {
                        "type": "message_edited",
                        "data": result.dict(),
                        "message_id": message.message_id
                    })
                    return True
                except Exception as e:
                    await self._send_error_to_connection(
                        connection.connection_id, "edit_failed", str(e)
                    )
                    return False
            
            elif message.type == WebSocketMessageType.DELETE_MESSAGE:
                # Delete message
                try:
                    message_id = message.data.get("message_id")
                    
                    if not message_id:
                        await self._send_error_to_connection(
                            connection.connection_id, "missing_message_id", "Message ID required"
                        )
                        return False
                    
                    await group_messaging_service.delete_message(user, message_id)
                    
                    await self._send_to_connection(connection.connection_id, {
                        "type": "message_deleted",
                        "data": {"message_id": message_id},
                        "message_id": message.message_id
                    })
                    return True
                except Exception as e:
                    await self._send_error_to_connection(
                        connection.connection_id, "delete_failed", str(e)
                    )
                    return False
            
            elif message.type == WebSocketMessageType.REACT_TO_MESSAGE:
                # React to message
                try:
                    reaction_data = ReactToMessageRequest(**message.data.get("reaction_data", {}))
                    message_id = message.data.get("message_id")
                    
                    if not message_id:
                        await self._send_error_to_connection(
                            connection.connection_id, "missing_message_id", "Message ID required"
                        )
                        return False
                    
                    await group_messaging_service.react_to_message(user, message_id, reaction_data)
                    
                    await self._send_to_connection(connection.connection_id, {
                        "type": "reaction_added",
                        "data": {"message_id": message_id, "reaction": reaction_data.dict()},
                        "message_id": message.message_id
                    })
                    return True
                except Exception as e:
                    await self._send_error_to_connection(
                        connection.connection_id, "reaction_failed", str(e)
                    )
                    return False
            
            elif message.type == WebSocketMessageType.MARK_READ:
                # Mark messages as read
                try:
                    read_data = MarkMessagesReadRequest(**message.data)
                    await group_messaging_service.mark_messages_read(user, message.group_id, read_data)
                    
                    await self._send_to_connection(connection.connection_id, {
                        "type": "messages_marked_read",
                        "data": {"message_ids": read_data.message_ids},
                        "message_id": message.message_id
                    })
                    return True
                except Exception as e:
                    await self._send_error_to_connection(
                        connection.connection_id, "mark_read_failed", str(e)
                    )
                    return False
            
            elif message.type == WebSocketMessageType.START_TYPING:
                # Start typing indicator
                try:
                    typing_data = TypingIndicatorRequest(is_typing=True, **message.data)
                    await group_messaging_service.handle_typing_indicator(user, message.group_id, typing_data)
                    return True
                except Exception as e:
                    await self._send_error_to_connection(
                        connection.connection_id, "typing_failed", str(e)
                    )
                    return False
            
            elif message.type == WebSocketMessageType.STOP_TYPING:
                # Stop typing indicator
                try:
                    typing_data = TypingIndicatorRequest(is_typing=False, **message.data)
                    await group_messaging_service.handle_typing_indicator(user, message.group_id, typing_data)
                    return True
                except Exception as e:
                    await self._send_error_to_connection(
                        connection.connection_id, "typing_failed", str(e)
                    )
                    return False
            
            elif message.type == WebSocketMessageType.JOIN_THREAD:
                # Join thread
                thread_id = message.data.get("thread_id")
                if thread_id:
                    success = await self.join_thread(connection.connection_id, thread_id)
                    if success:
                        await self._send_to_connection(connection.connection_id, {
                            "type": "thread_joined",
                            "data": {"thread_id": thread_id}
                        })
                    else:
                        await self._send_error_to_connection(
                            connection.connection_id, "join_thread_failed", "Failed to join thread"
                        )
                return True
            
            elif message.type == WebSocketMessageType.LEAVE_THREAD:
                # Leave thread
                thread_id = message.data.get("thread_id")
                if thread_id:
                    await self.leave_thread(connection.connection_id, thread_id)
                    await self._send_to_connection(connection.connection_id, {
                        "type": "thread_left",
                        "data": {"thread_id": thread_id}
                    })
                return True
            
            else:
                logger.warning(f"Unknown message type: {message.type}")
                await self._send_error_to_connection(
                    connection.connection_id, "unknown_message_type", f"Unknown message type: {message.type}"
                )
                return False
                
        except Exception as e:
            logger.error(f"Error routing message from {connection.connection_id}: {e}")
            await self._send_error_to_connection(
                connection.connection_id, "routing_error", "Message routing failed"
            )
            return False
    
    async def _broadcast_to_group(self, group_id: str, message_data: Dict[str, Any], exclude_connection: Optional[str] = None):
        """Broadcast message to all connections in a group"""
        group_connection_ids = self.group_connections.get(group_id, set())
        
        for connection_id in list(group_connection_ids):
            if exclude_connection and connection_id == exclude_connection:
                continue
            await self._send_to_connection(connection_id, message_data)
    
    async def _send_to_connection(self, connection_id: str, message_data: Dict[str, Any]) -> bool:
        """Send message to a specific connection"""
        connection = self.connections.get(connection_id)
        if not connection or not connection.is_alive():
            return False
        
        try:
            message_json = json.dumps(message_data, default=str)
            await connection.websocket.send_text(message_json)
            return True
        except Exception as e:
            logger.error(f"Failed to send message to connection {connection_id}: {e}")
            # Schedule connection cleanup
            asyncio.create_task(self.disconnect_user(connection_id, "Send failed"))
            return False
    
    async def _send_error_to_connection(self, connection_id: str, error_code: str, error_message: str):
        """Send error message to connection"""
        await self._send_to_connection(connection_id, {
            "type": WebSocketMessageType.ERROR,
            "data": {
                "error_code": error_code,
                "error_message": error_message,
                "timestamp": datetime.utcnow().isoformat()
            }
        })
    
    async def _send_error(self, websocket: WebSocket, error_code: str, error_message: str):
        """Send error to websocket before connection is established"""
        try:
            error_data = {
                "type": WebSocketMessageType.ERROR,
                "data": {
                    "error_code": error_code,
                    "error_message": error_message,
                    "timestamp": datetime.utcnow().isoformat()
                }
            }
            await websocket.send_text(json.dumps(error_data, default=str))
        except:
            pass  # Connection might already be closed
    
    async def _cleanup_expired_connections(self):
        """Background task to cleanup expired connections"""
        while True:
            try:
                await asyncio.sleep(30)  # Check every 30 seconds
                
                expired_connections = []
                for connection_id, connection in self.connections.items():
                    if connection.is_heartbeat_expired(self.heartbeat_timeout_seconds):
                        expired_connections.append(connection_id)
                
                # Disconnect expired connections
                for connection_id in expired_connections:
                    await self.disconnect_user(connection_id, "Heartbeat timeout")
                
                if expired_connections:
                    logger.info(f"Cleaned up {len(expired_connections)} expired connections")
                
            except asyncio.CancelledError:
                break
            except Exception as e:
                logger.error(f"Error in connection cleanup: {e}")
    
    def get_connection_stats(self) -> Dict[str, Any]:
        """Get WebSocket connection statistics"""
        return {
            "total_connections": len(self.connections),
            "authenticated_connections": sum(1 for conn in self.connections.values() 
                                           if conn.status == ConnectionStatus.AUTHENTICATED),
            "unique_users": len(self.user_connections),
            "active_groups": len(self.group_connections),
            "active_threads": len(self.thread_connections),
            "connections_by_status": {
                status.value: sum(1 for conn in self.connections.values() if conn.status == status)
                for status in ConnectionStatus
            }
        }

# Global WebSocket manager instance
websocket_manager = WebSocketManager()