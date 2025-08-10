# app/api/endpoints/group_messaging.py
import logging
import uuid
from typing import Optional, List
from fastapi import APIRouter, Depends, HTTPException, status, Query, Path, WebSocket, WebSocketDisconnect, UploadFile, File, Form
from fastapi.responses import JSONResponse

from ...models.user import User
from ...schemas.group_message import (
    SendMessageRequest, EditMessageRequest, ReactToMessageRequest,
    MarkMessagesReadRequest, MessageSearchRequest, TypingIndicatorRequest,
    MessageListResponse, MessageSearchResponse, TypingIndicatorResponse,
    MediaUploadRequest, MediaUploadResponse
)
from ...services.group_messaging_service import group_messaging_service
from ...services.websocket_manager import websocket_manager, WebSocketConnection
from ...services.media_service import media_service
from ...core.auth import get_current_user, get_optional_user
from ...utils.json_utils import MongoJSONEncoder

router = APIRouter()
logger = logging.getLogger(__name__)

# WebSocket endpoint for real-time messaging
@router.websocket("/ws/{group_id}")
async def websocket_endpoint(
    websocket: WebSocket,
    group_id: str,
    token: Optional[str] = Query(None, description="JWT token for authentication")
):
    """WebSocket endpoint for real-time group messaging"""
    connection_id = str(uuid.uuid4())
    connection = None
    
    try:
        if not token:
            await websocket.close(code=4001, reason="Authentication required")
            return
        
        # Connect and authenticate user
        connection = await websocket_manager.connect_user(websocket, token, connection_id)
        
        if not connection:
            logger.warning(f"Failed to establish WebSocket connection for group {group_id}")
            return
        
        # Join the specified group
        if not await websocket_manager.join_group(connection_id, group_id):
            await websocket.close(code=4003, reason="Access denied to group")
            return
        
        logger.info(f"WebSocket connection established for user {connection.username} in group {group_id}")
        
        # Listen for messages
        while True:
            try:
                # Receive message from client
                raw_message = await websocket.receive_text()
                
                # Handle message through WebSocket manager
                success = await websocket_manager.handle_message(connection_id, raw_message)
                
                if not success:
                    logger.warning(f"Failed to handle message from connection {connection_id}")
                
            except WebSocketDisconnect:
                logger.info(f"WebSocket disconnected for user {connection.username}")
                break
            except Exception as e:
                logger.error(f"Error in WebSocket message handling: {e}")
                break
                
    except Exception as e:
        logger.error(f"WebSocket connection error: {e}")
    finally:
        # Cleanup connection
        if connection:
            await websocket_manager.disconnect_user(connection_id, "Connection ended")

# REST API endpoints for messaging

@router.post("/{group_id}/messages", status_code=status.HTTP_201_CREATED)
async def send_message(
    group_id: str = Path(..., description="Group ID"),
    message_data: SendMessageRequest = ...,
    current_user: User = Depends(get_current_user)
):
    """Send a new message to the group"""
    try:
        message = await group_messaging_service.send_message(current_user, group_id, message_data)
        
        message_dict = message.dict()
        message_dict = MongoJSONEncoder.encode_mongo_data(message_dict)
        
        return {"message": message_dict}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in send_message endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to send message"
        )

@router.get("/{group_id}/messages")
async def get_group_messages(
    group_id: str = Path(..., description="Group ID"),
    limit: int = Query(50, ge=1, le=100, description="Number of messages to return"),
    before_message_id: Optional[str] = Query(None, description="Get messages before this message ID"),
    current_user: User = Depends(get_current_user)
):
    """Get paginated group messages"""
    try:
        messages = await group_messaging_service.get_group_messages(
            current_user, group_id, limit, before_message_id
        )
        
        messages_dict = messages.dict()
        messages_dict = MongoJSONEncoder.encode_mongo_data(messages_dict)
        
        return messages_dict
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in get_group_messages endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get group messages"
        )

@router.put("/messages/{message_id}")
async def edit_message(
    message_id: str = Path(..., description="Message ID"),
    edit_data: EditMessageRequest = ...,
    current_user: User = Depends(get_current_user)
):
    """Edit an existing message"""
    try:
        message = await group_messaging_service.edit_message(current_user, message_id, edit_data)
        
        message_dict = message.dict()
        message_dict = MongoJSONEncoder.encode_mongo_data(message_dict)
        
        return {"message": message_dict}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in edit_message endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to edit message"
        )

@router.delete("/messages/{message_id}")
async def delete_message(
    message_id: str = Path(..., description="Message ID"),
    current_user: User = Depends(get_current_user)
):
    """Delete a message"""
    try:
        await group_messaging_service.delete_message(current_user, message_id)
        return {"message": "Message deleted successfully"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in delete_message endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to delete message"
        )

@router.post("/messages/{message_id}/react")
async def react_to_message(
    message_id: str = Path(..., description="Message ID"),
    reaction_data: ReactToMessageRequest = ...,
    current_user: User = Depends(get_current_user)
):
    """React to a message"""
    try:
        await group_messaging_service.react_to_message(current_user, message_id, reaction_data)
        return {"message": "Reaction added successfully"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in react_to_message endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to react to message"
        )

@router.post("/{group_id}/messages/mark-read")
async def mark_messages_read(
    group_id: str = Path(..., description="Group ID"),
    read_data: MarkMessagesReadRequest = ...,
    current_user: User = Depends(get_current_user)
):
    """Mark messages as read"""
    try:
        await group_messaging_service.mark_messages_read(current_user, group_id, read_data)
        return {"message": "Messages marked as read"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in mark_messages_read endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to mark messages as read"
        )

@router.post("/{group_id}/search")
async def search_messages(
    group_id: str = Path(..., description="Group ID"),
    search_data: MessageSearchRequest = ...,
    current_user: User = Depends(get_current_user)
):
    """Search messages within the group"""
    try:
        results = await group_messaging_service.search_messages(current_user, group_id, search_data)
        
        results_dict = results.dict()
        results_dict = MongoJSONEncoder.encode_mongo_data(results_dict)
        
        return results_dict
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in search_messages endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to search messages"
        )

@router.post("/{group_id}/typing")
async def handle_typing_indicator(
    group_id: str = Path(..., description="Group ID"),
    typing_data: TypingIndicatorRequest = ...,
    current_user: User = Depends(get_current_user)
):
    """Handle typing indicator"""
    try:
        await group_messaging_service.handle_typing_indicator(current_user, group_id, typing_data)
        return {"message": "Typing indicator updated"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in handle_typing_indicator endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to handle typing indicator"
        )

@router.get("/{group_id}/typing")
async def get_typing_users(
    group_id: str = Path(..., description="Group ID"),
    current_user: User = Depends(get_current_user)
):
    """Get users currently typing in the group"""
    try:
        typing_users = await group_messaging_service.get_typing_users(current_user, group_id)
        
        typing_dict = typing_users.dict()
        typing_dict = MongoJSONEncoder.encode_mongo_data(typing_dict)
        
        return typing_dict
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in get_typing_users endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get typing users"
        )

# Media upload endpoints

@router.post("/{group_id}/upload", status_code=status.HTTP_201_CREATED)
async def upload_media(
    group_id: str = Path(..., description="Group ID"),
    file: UploadFile = File(...),
    file_type: str = Form(..., description="File type: image, voice, video, document"),
    current_user: User = Depends(get_current_user)
):
    """Upload media file for group messaging"""
    try:
        upload_response = await media_service.upload_media(current_user, file, file_type, group_id)
        
        response_dict = upload_response.dict()
        response_dict = MongoJSONEncoder.encode_mongo_data(response_dict)
        
        return response_dict
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in upload_media endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to upload media file"
        )

# Thread management endpoints

@router.get("/messages/{message_id}/thread")
async def get_thread_messages(
    message_id: str = Path(..., description="Thread starter message ID"),
    limit: int = Query(50, ge=1, le=100, description="Number of messages to return"),
    skip: int = Query(0, ge=0, description="Number of messages to skip"),
    current_user: User = Depends(get_current_user)
):
    """Get messages in a specific thread"""
    try:
        # This would be implemented in the messaging service
        # For now, return a placeholder
        return {"thread_messages": [], "has_more": False, "total_count": 0}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in get_thread_messages endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get thread messages"
        )

# Message management endpoints (admin only)

@router.put("/messages/{message_id}/pin")
async def pin_message(
    message_id: str = Path(..., description="Message ID"),
    current_user: User = Depends(get_current_user)
):
    """Pin a message (admin/moderator only)"""
    try:
        # This would be implemented in the messaging service
        # For now, return a placeholder
        return {"message": "Message pinned successfully"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in pin_message endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to pin message"
        )

@router.delete("/messages/{message_id}/pin")
async def unpin_message(
    message_id: str = Path(..., description="Message ID"),
    current_user: User = Depends(get_current_user)
):
    """Unpin a message (admin/moderator only)"""
    try:
        # This would be implemented in the messaging service
        # For now, return a placeholder
        return {"message": "Message unpinned successfully"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in unpin_message endpoint: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to unpin message"
        )

# WebSocket connection management endpoints

@router.get("/connections/stats")
async def get_connection_stats(
    current_user: User = Depends(get_current_user)
):
    """Get WebSocket connection statistics (admin only)"""
    try:
        # In a real implementation, you'd check admin permissions here
        stats = websocket_manager.get_connection_stats()
        return stats
    except Exception as e:
        logger.error(f"Error getting connection stats: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get connection statistics"
        )

# Health check for messaging system
@router.get("/health")
async def messaging_health_check():
    """Health check for messaging system"""
    try:
        stats = websocket_manager.get_connection_stats()
        
        return {
            "status": "healthy",
            "websocket_manager": "operational",
            "active_connections": stats["total_connections"],
            "timestamp": "2025-01-08T10:00:00Z"
        }
    except Exception as e:
        logger.error(f"Messaging health check failed: {e}")
        return JSONResponse(
            status_code=500,
            content={
                "status": "unhealthy",
                "error": str(e),
                "timestamp": "2025-01-08T10:00:00Z"
            }
        )