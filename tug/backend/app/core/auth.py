# app/core/auth.py
import firebase_admin
from firebase_admin import auth, credentials
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from ..models.user import User
from .config import settings
import os
from datetime import datetime

# Initialize security
security = HTTPBearer()

# Initialize Firebase Admin SDK - only once
try:
    # Check if app is already initialized
    default_app = firebase_admin.get_app()
except ValueError:
    # Not initialized, do it now
    cred_path = settings.FIREBASE_CREDENTIALS_PATH
    if os.path.exists(cred_path):
        cred = credentials.Certificate(cred_path)
        firebase_admin.initialize_app(cred)
    else:
        raise FileNotFoundError(f"Firebase credentials file not found at {cred_path}")

async def verify_firebase_token(token: str) -> dict:
    """Verify Firebase ID token and return decoded token data"""
    try:
        decoded_token = auth.verify_id_token(token)
        return decoded_token
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid authentication credentials: {str(e)}",
            headers={"WWW-Authenticate": "Bearer"},
        )

async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security)
) -> User:
    """Get the current authenticated user or create if not exists"""
    token_data = await verify_firebase_token(credentials.credentials)
    firebase_uid = token_data["uid"]
    
    # Try to find the user
    user = await User.find_one(User.firebase_uid == firebase_uid)
    
    # If user doesn't exist, create a new one
    if not user:
        try:
            # Get user info from Firebase
            firebase_user = auth.get_user(firebase_uid)
            
            # Create user in our database
            user = User(
                firebase_uid=firebase_uid,
                email=firebase_user.email or token_data.get("email", ""),
                display_name=firebase_user.display_name or token_data.get("name", "User"),
                created_at=datetime.utcnow(),
                last_login=datetime.utcnow()
            )
            await user.insert()
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Failed to create user: {str(e)}",
            )
    else:
        # Update last login time
        user.last_login = datetime.utcnow()
        await user.save()
    
    return user

async def get_optional_user(
    credentials: HTTPAuthorizationCredentials = Depends(security)
) -> User:
    """Get the current user if authenticated, or None if not"""
    try:
        return await get_current_user(credentials)
    except HTTPException:
        return None