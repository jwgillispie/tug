# app/api/endpoints/users.py
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from typing import List
from ...models.user import User
from ...schemas.user import UserCreate, UserUpdate, UserResponse
from ...core.auth import get_current_user, verify_firebase_token
from ...services.user_service import UserService

router = APIRouter()
security = HTTPBearer()

@router.post("/sync")
async def sync_user(current_user: dict = Depends(get_current_user)):
    """
    Create or update a user record in MongoDB after Firebase authentication
    The user is already verified via the get_current_user dependency
    """
    try:
        # Check if user exists
        user = await User.find_one(User.firebase_uid == current_user["uid"])
        
        if not user:
            # Create new user
            user = User(
                firebase_uid=current_user["uid"],
                email=current_user.get("email", ""),
                display_name=current_user.get("name", ""),
                created_at=datetime.utcnow(),
                last_login=datetime.utcnow()
            )
            await user.insert()
        else:
            # Update existing user
            user.last_login = datetime.utcnow()
            if "name" in current_user and current_user["name"]:
                user.display_name = current_user["name"]
            
            await user.save()
        
        return {"status": "success", "user_id": str(user.id)}
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to sync user: {e}")

@router.post("/", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def create_user(
    user_data: UserCreate,
    current_user: User = Depends(get_current_user)
):
    """Create or update user profile"""
    # User is already created or updated by the auth middleware
    return current_user

@router.get("/me", response_model=UserResponse)
async def get_current_user_profile(current_user: User = Depends(get_current_user)):
    """Get current user profile"""
    return current_user

@router.patch("/me", response_model=UserResponse)
async def update_user_profile(
    user_update: UserUpdate,
    current_user: User = Depends(get_current_user)
):
    """Update current user profile"""
    updated_user = await UserService.update_user(current_user, user_update)
    return updated_user