# app/api/endpoints/users.py
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, status, Request
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from typing import List, Dict, Any, Optional
import logging
from firebase_admin import auth
from ...models.user import User
from ...schemas.user import UserCreate, UserUpdate, UserResponse

router = APIRouter()
security = HTTPBearer()

# Set up logging
logger = logging.getLogger(__name__)

@router.post("/sync")
async def sync_user(request: Request):
    """
    Create or update a user record in MongoDB after Firebase authentication
    Extracts the token from the Authorization header directly without the dependency
    """
    logger.info("Sync user endpoint called")
    try:
        # Extract token manually
        auth_header = request.headers.get('Authorization')
        logger.info(f"Auth header: {auth_header}")
        
        if not auth_header or not auth_header.startswith('Bearer '):
            logger.error("Missing or invalid Authorization header")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Missing or invalid Authorization header"
            )
        
        token = auth_header.split(' ')[1]
        
        # Verify Firebase token
        try:
            decoded_token = auth.verify_id_token(token)
            logger.info(f"Token verified for UID: {decoded_token.get('uid')}")
        except Exception as e:
            logger.error(f"Token verification failed: {e}")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail=f"Invalid token: {e}"
            )
        
        # Log the received data
        body = await request.json()
        logger.info(f"Received user data: {body}")
        
        # Check if user exists
        firebase_uid = decoded_token.get('uid')
        user = await User.find_one(User.firebase_uid == firebase_uid)
        logger.info(f"User found: {user is not None}")
        logger.info(f"User ID: {user.id if user else 'None'}")
        
        # Extract user data from request body
        display_name = body.get('display_name', '')
        email = body.get('email', '')
        
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
            logger.info(f"User created with ID: {user.id}")
        else:
            # Update existing user
            logger.info(f"Updating existing user: {user.id}")
            user.last_login = datetime.utcnow()
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
    request: Request
):
    """Create or update user profile"""
    logger.info("Create user endpoint called")
    try:
        # Extract token manually
        auth_header = request.headers.get('Authorization')
        if not auth_header or not auth_header.startswith('Bearer '):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Missing or invalid Authorization header"
            )
        
        token = auth_header.split(' ')[1]
        decoded_token = auth.verify_id_token(token)
        firebase_uid = decoded_token.get('uid')
        
        # Check if user exists
        user = await User.find_one(User.firebase_uid == firebase_uid)
        if user:
            # Update existing user
            user.display_name = user_data.display_name
            user.last_login = datetime.utcnow()
            await user.save()
        else:
            # Create new user
            user = User(
                firebase_uid=firebase_uid,
                email=user_data.email,
                display_name=user_data.display_name,
                created_at=datetime.utcnow(),
                last_login=datetime.utcnow()
            )
            await user.insert()
        
        return user
    except Exception as e:
        logger.error(f"Create user error: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Failed to create user: {e}")

@router.get("/me", response_model=UserResponse)
async def get_current_user_profile(request: Request):
    """Get current user profile"""
    try:
        # Extract token manually
        auth_header = request.headers.get('Authorization')
        if not auth_header or not auth_header.startswith('Bearer '):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Missing or invalid Authorization header"
            )
        
        token = auth_header.split(' ')[1]
        decoded_token = auth.verify_id_token(token)
        firebase_uid = decoded_token.get('uid')
        
        # Get user
        user = await User.find_one(User.firebase_uid == firebase_uid)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        return user
    except Exception as e:
        logger.error(f"Get user profile error: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to get user: {e}")

# Update the patch endpoint
@router.patch("/me", response_model=UserResponse)
async def update_user_profile(
    user_update: UserUpdate,
    request: Request
):
    """Update current user profile"""
    try:
        # Extract token manually
        auth_header = request.headers.get('Authorization')
        if not auth_header or not auth_header.startswith('Bearer '):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Missing or invalid Authorization header"
            )
        
        token = auth_header.split(' ')[1]
        decoded_token = auth.verify_id_token(token)
        firebase_uid = decoded_token.get('uid')
        
        # Get user
        user = await User.find_one(User.firebase_uid == firebase_uid)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        # Log the user ID for debugging
        logger.info(f"Updating user with ID: {user.id}, type: {type(user.id)}")
        
        # Update fields
        update_data = user_update.model_dump(exclude_unset=True)
        if update_data:
            for field, value in update_data.items():
                setattr(user, field, value)
            await user.save()
        
        return user
    except Exception as e:
        logger.error(f"Update user profile error: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to update user: {e}")
# Additional endpoint for app/api/endpoints/users.py

@router.delete("/me", status_code=status.HTTP_204_NO_CONTENT)
async def delete_user_profile(request: Request):
    """Delete current user profile"""
    try:
        # Extract token manually
        auth_header = request.headers.get('Authorization')
        if not auth_header or not auth_header.startswith('Bearer '):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Missing or invalid Authorization header"
            )
        
        token = auth_header.split(' ')[1]
        decoded_token = auth.verify_id_token(token)
        firebase_uid = decoded_token.get('uid')
        
        # Get user
        user = await User.find_one(User.firebase_uid == firebase_uid)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        # Delete the user
        await user.delete()
        
        return None
    except Exception as e:
        logger.error(f"Delete user profile error: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to delete user: {e}")