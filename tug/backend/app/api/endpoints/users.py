# app/api/endpoints/users.py
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, status, Request
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from typing import List, Dict, Any, Optional
import logging
import base64
import os
import uuid
from firebase_admin import auth
from bson import ObjectId
from ...models.user import User
from ...models.value import Value
from ...models.activity import Activity
from ...models.vice import Vice
from ...models.indulgence import Indulgence
from ...models.social_post import SocialPost
from ...models.post_comment import PostComment
from ...models.friendship import Friendship
from ...models.notification import Notification, NotificationBatch
from ...models.achievement import Achievement
from ...schemas.user import UserCreate, UserUpdate, UserResponse
from ...utils.json_utils import MongoJSONEncoder
from ...core.auth import get_current_user, authenticate_request
from ...utils.validation import InputValidator

router = APIRouter()
security = HTTPBearer()

# Set up logging
logger = logging.getLogger(__name__)

@router.post("/sync")
async def sync_user(request: Request):
    """
    Create or update a user record in MongoDB after Firebase authentication
    Uses secure authentication with proper error handling
    """
    logger.info("Sync user endpoint called")
    try:
        # Secure authentication
        decoded_token = await authenticate_request(request)
        logger.info(f"Token verified for UID: {decoded_token.get('uid')}")
        
        # Log the received data with validation
        try:
            body = await request.json()
            # Validate the JSON payload
            body = InputValidator.validate_json_payload(body, max_keys=10)
        except Exception as e:
            logger.error(f"Invalid JSON payload: {e}")
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail={"error": "invalid_json", "message": "Invalid JSON format"}
            )
        
        logger.info(f"Received user data: {body}")
        
        # Check if user exists
        firebase_uid = decoded_token.get('uid')
        user = await User.find_one(User.firebase_uid == firebase_uid)
        logger.info(f"User found: {user is not None}")
        logger.info(f"User ID: {user.id if user else 'None'}")
        
        # Extract and validate user data from request body
        display_name = InputValidator.sanitize_string(body.get('display_name', ''), max_length=100)
        email = body.get('email', '')
        if email:
            email = InputValidator.validate_email(email)
        
        if not user:
            # Create new user
            logger.info(f"Creating new user for Firebase UID: {firebase_uid}")
            user = User(
                firebase_uid=firebase_uid,
                email=email,
                display_name=display_name,
                created_at=datetime.utcnow(),
                last_login=datetime.utcnow()
            )
            await user.insert()
            await user.ensure_username()
            logger.info(f"User created with ID: {user.id} and username: {user.username}")
        else:
            # Update existing user
            logger.info(f"Updating existing user: {user.id}")
            user.last_login = datetime.utcnow()
            
            # Ensure existing user has a username
            if not user.username:
                await user.ensure_username()
                logger.info(f"Generated username for existing user: {user.username}")
            if display_name:
                user.display_name = display_name
            
            await user.save()
            logger.info(f"User updated: {user.id}")
        
        return {
            "status": "success", 
            "user_id": str(user.id),
            "message": "User synced successfully"
        }
        
    except HTTPException:
        # Re-raise HTTP exceptions
        raise
    except Exception as e:
        logger.error(f"Sync user error: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Failed to sync user: {e}")

@router.post("/", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def create_user(
    user_data: UserCreate,
    current_user: User = Depends(get_current_user)
):
    """Create or update user profile"""
    logger.info("Create user endpoint called")
    try:
        firebase_uid = current_user.firebase_uid
        
        # Update existing user (current_user is already authenticated)
        current_user.display_name = user_data.display_name
        current_user.last_login = datetime.utcnow()
        
        # Ensure existing user has a username
        if not current_user.username:
            await current_user.ensure_username()
            
        await current_user.save()
        
        # Manually convert to response format
        response = {
            "id": str(current_user.id),
            "email": current_user.email,
            "display_name": current_user.display_name,
            "profile_picture_url": current_user.profile_picture_url,
            "bio": current_user.bio,
            "onboarding_completed": current_user.onboarding_completed
        }
        
        return response
    except Exception as e:
        logger.error(f"Create user error: {e}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail={"error": "internal_error", "message": "Failed to create/update user"}
        )

@router.get("/me", response_model=UserResponse)
async def get_current_user_profile(current_user: User = Depends(get_current_user)):
    """Get current user profile"""
    try:
        
        # Manually convert to response format
        response = {
            "id": str(current_user.id),
            "email": current_user.email,
            "display_name": current_user.display_name,
            "profile_picture_url": current_user.profile_picture_url,
            "bio": current_user.bio,
            "onboarding_completed": current_user.onboarding_completed
        }
        
        return response
    except Exception as e:
        logger.error(f"Get user profile error: {e}")
        raise HTTPException(
            status_code=500, 
            detail={"error": "internal_error", "message": "Failed to retrieve user profile"}
        )

@router.patch("/me", response_model=UserResponse)
async def update_user_profile(
    user_update: UserUpdate,
    current_user: User = Depends(get_current_user)
):
    """Update current user profile"""
    try:
        
        # Log the user ID and the update data
        logger.info(f"Updating user: {current_user.id} (type: {type(current_user.id)})")
        update_data = user_update.model_dump(exclude_unset=True)
        logger.info(f"Update data: {update_data}")
        
        # Update fields with validation
        if update_data:
            try:
                # Validate and sanitize update data
                allowed_fields = {'display_name', 'bio', 'profile_picture_url', 'onboarding_completed'}
                for field, value in update_data.items():
                    if field not in allowed_fields:
                        logger.warning(f"Attempted to update restricted field: {field}")
                        continue
                    
                    if hasattr(current_user, field):
                        # Sanitize string fields
                        if isinstance(value, str) and field in {'display_name', 'bio'}:
                            value = value.strip()[:500]  # Limit length and trim
                        setattr(current_user, field, value)
                    else:
                        logger.warning(f"Field '{field}' not found in user model")
                
                # Save the user
                await current_user.save()
                logger.info(f"User updated successfully: {current_user.id}")
            except Exception as e:
                logger.error(f"Error updating user fields: {e}")
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail={"error": "update_failed", "message": "Failed to update user profile"}
                )
        
        # Manually convert to response format
        response = {
            "id": str(current_user.id),
            "email": current_user.email,
            "display_name": current_user.display_name,
            "profile_picture_url": current_user.profile_picture_url,
            "bio": current_user.bio,
            "onboarding_completed": current_user.onboarding_completed
        }
        
        return response
    except HTTPException:
        # Re-raise HTTP exceptions
        raise
    except Exception as e:
        logger.error(f"Update user profile error: {e}", exc_info=True)
        raise HTTPException(
            status_code=500, 
            detail={"error": "internal_error", "message": "Failed to update user profile"}
        )

@router.post("/me/profile-picture")
@router.post("/me/profile-picture/")
async def upload_profile_picture(
    request: Request,
    current_user: User = Depends(get_current_user)
):
    """Upload and save user profile picture"""
    try:
        
        # Get request body with size validation
        try:
            body = await request.json()
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail={"error": "invalid_json", "message": "Invalid JSON format"}
            )
        
        base64_image = body.get('image')
        
        if not base64_image:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail={"error": "missing_image", "message": "No image data provided"}
            )
        
        # Validate base64 string format and size (max 5MB encoded)
        if len(base64_image) > 7 * 1024 * 1024:  # ~5MB when decoded
            raise HTTPException(
                status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                detail={"error": "image_too_large", "message": "Image size exceeds 5MB limit"}
            )
        
        try:
            # Decode base64 image with validation
            try:
                image_data = base64.b64decode(base64_image, validate=True)
            except Exception as e:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail={"error": "invalid_base64", "message": "Invalid base64 image data"}
                )
            
            # Validate decoded image size (max 5MB)
            if len(image_data) > 5 * 1024 * 1024:
                raise HTTPException(
                    status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                    detail={"error": "image_too_large", "message": "Decoded image exceeds 5MB limit"}
                )
            
            # Create uploads directory if it doesn't exist
            upload_dir = "uploads/profile_pictures"
            os.makedirs(upload_dir, exist_ok=True)
            
            # Generate secure filename
            unique_filename = f"{current_user.firebase_uid}_{uuid.uuid4().hex}.jpg"
            file_path = os.path.join(upload_dir, unique_filename)
            
            # Save image to file
            with open(file_path, 'wb') as f:
                f.write(image_data)
            
            # Create full URL for the saved image
            # Get the base URL from the request
            base_url = f"{request.url.scheme}://{request.url.netloc}"
            profile_picture_url = f"{base_url}/uploads/profile_pictures/{unique_filename}"
            
            # Update user profile with picture URL
            current_user.profile_picture_url = profile_picture_url
            await current_user.save()
            
            logger.info(f"Profile picture uploaded for user {current_user.id}: {profile_picture_url}")
            
            return {
                "profile_picture_url": profile_picture_url,
                "message": "Profile picture uploaded successfully"
            }
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error processing image: {e}")
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail={"error": "image_processing_failed", "message": "Failed to process image"}
            )
            
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Upload profile picture error: {e}", exc_info=True)
        raise HTTPException(
            status_code=500, 
            detail={"error": "internal_error", "message": "Failed to upload profile picture"}
        )

@router.get("/{user_id}")
async def get_user_profile(
    user_id: str, 
    current_user: User = Depends(get_current_user)
):
    """Get public user profile by user ID"""
    try:
        # Validate user_id format
        if not user_id or len(user_id) > 100:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail={"error": "invalid_user_id", "message": "Invalid user ID format"}
            )
        
        # Get the target user
        target_user = await User.get_by_id(user_id)
        if not target_user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        # Return public profile information
        response = {
            "id": str(target_user.id),
            "display_name": target_user.display_name,
            "username": target_user.username,
            "profile_picture_url": target_user.profile_picture_url,
            "bio": target_user.bio,
        }
        
        return response
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Get user profile error: {e}", exc_info=True)
        raise HTTPException(
            status_code=500, 
            detail={"error": "internal_error", "message": "Failed to retrieve user profile"}
        )

@router.delete("/me", status_code=status.HTTP_204_NO_CONTENT)
async def delete_user_profile(current_user: User = Depends(get_current_user)):
    """Delete current user profile and all associated data"""
    try:
        user_id_str = str(current_user.id)
        
        # Log deletion process
        logger.info(f"Starting deletion of user {user_id_str} and all associated data")
        
        # Delete all user values
        values_result = await Value.find(Value.user_id == user_id_str).delete()
        logger.info(f"Deleted {values_result.deleted_count} values for user {user_id_str}")
        
        # Delete all user activities
        activities_result = await Activity.find(Activity.user_id == user_id_str).delete()
        logger.info(f"Deleted {activities_result.deleted_count} activities for user {user_id_str}")
        
        # Delete all user vices
        vices_result = await Vice.find(Vice.user_id == user_id_str).delete()
        logger.info(f"Deleted {vices_result.deleted_count} vices for user {user_id_str}")
        
        # Delete all user indulgences
        indulgences_result = await Indulgence.find(Indulgence.user_id == user_id_str).delete()
        logger.info(f"Deleted {indulgences_result.deleted_count} indulgences for user {user_id_str}")
        
        # Delete all social posts by the user
        posts_result = await SocialPost.find(SocialPost.user_id == user_id_str).delete()
        logger.info(f"Deleted {posts_result.deleted_count} social posts for user {user_id_str}")
        
        # Delete all comments by the user
        comments_result = await PostComment.find(PostComment.user_id == user_id_str).delete()
        logger.info(f"Deleted {comments_result.deleted_count} comments for user {user_id_str}")
        
        # Delete all friendships involving the user (both as requester and addressee)
        friendships_requester_result = await Friendship.find(Friendship.requester_id == user_id_str).delete()
        friendships_addressee_result = await Friendship.find(Friendship.addressee_id == user_id_str).delete()
        total_friendships = friendships_requester_result.deleted_count + friendships_addressee_result.deleted_count
        logger.info(f"Deleted {total_friendships} friendships for user {user_id_str}")
        
        # Delete all notifications for the user (both received and sent)
        notifications_received_result = await Notification.find(Notification.user_id == user_id_str).delete()
        notifications_sent_result = await Notification.find(Notification.related_user_id == user_id_str).delete()
        total_notifications = notifications_received_result.deleted_count + notifications_sent_result.deleted_count
        logger.info(f"Deleted {total_notifications} notifications for user {user_id_str}")
        
        # Delete all notification batches for the user
        notification_batches_result = await NotificationBatch.find(NotificationBatch.user_id == user_id_str).delete()
        logger.info(f"Deleted {notification_batches_result.deleted_count} notification batches for user {user_id_str}")
        
        # Delete all achievements for the user
        achievements_result = await Achievement.find(Achievement.user_id == user_id_str).delete()
        logger.info(f"Deleted {achievements_result.deleted_count} achievements for user {user_id_str}")
        
        # Finally delete the user
        await current_user.delete()
        logger.info(f"User {user_id_str} and all associated data successfully deleted")
        logger.info(f"Summary - Values: {values_result.deleted_count}, Activities: {activities_result.deleted_count}, Vices: {vices_result.deleted_count}, Indulgences: {indulgences_result.deleted_count}, Posts: {posts_result.deleted_count}, Comments: {comments_result.deleted_count}, Friendships: {total_friendships}, Notifications: {total_notifications}, Notification Batches: {notification_batches_result.deleted_count}, Achievements: {achievements_result.deleted_count}")
        
        return None
    except Exception as e:
        logger.error(f"Delete user profile error: {e}", exc_info=True)
        raise HTTPException(
            status_code=500, 
            detail={"error": "internal_error", "message": "Failed to delete user profile"}
        )