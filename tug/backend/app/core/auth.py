# app/core/auth.py
import firebase_admin
from firebase_admin import auth, credentials
from fastapi import Depends, HTTPException, status, Request
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from ..models.user import User
from .config import settings
import os
import logging
from datetime import datetime

# Configure logging
logger = logging.getLogger(__name__)

# Initialize security
security = HTTPBearer(auto_error=False)

# Initialize Firebase Admin SDK - only once (skip in mock mode)
if getattr(settings, 'MOCK_AUTH', False):
    logger.info("Running in MOCK_AUTH mode - Firebase authentication disabled")
else:
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
    # Mock authentication for local development
    if getattr(settings, 'MOCK_AUTH', False):
        logger.info(f"Mock auth: using token as user ID: {token}")
        return {
            'uid': token or 'mock_user_123',
            'email': f'{token or "mock_user"}@example.com',
            'name': f'Mock User {token or "123"}',
            'email_verified': True,
        }
    
    try:
        # Add generous clock skew tolerance (10 seconds)
        decoded_token = auth.verify_id_token(
            token, 
            clock_skew_seconds=10  # Increased tolerance for clock skew
        )
        return decoded_token
    except Exception as e:
        error_msg = str(e)
        logger.warning(f"Token verification error: {error_msg}")
        
        # Special handling for "Token used too early" errors
        if "Token used too early" in error_msg:
            try:
                # Try to decode the token without verification first
                # This is just to get the payload for logging purposes
                import jwt
                
                # Split the token to get the payload part
                parts = token.split('.')
                if len(parts) == 3:  # Valid JWT format: header.payload.signature
                    # Add padding if needed
                    payload = parts[1]
                    payload += '=' * (-len(payload) % 4)
                    
                    try:
                        # Import base64 for decoding
                        import base64
                        import json
                        
                        # Decode the payload part
                        decoded_bytes = base64.b64decode(payload)
                        payload_data = json.loads(decoded_bytes.decode('utf-8'))
                        
                        # Log the timing information for debugging
                        iat = payload_data.get('iat', 0)
                        current_time = int(datetime.utcnow().timestamp())
                        
                        logger.warning(f"Clock skew detected: Token iat={iat}, Server time={current_time}, " 
                                      f"Difference={current_time - iat} seconds")
                    except Exception as decode_error:
                        logger.error(f"Error decoding token payload: {decode_error}")
                
                # Attempt with a more permissive approach
                logger.info("Attempting token verification with very high tolerance...")
                decoded_token = auth.verify_id_token(
                    token, 
                    clock_skew_seconds=30  # Use an even higher tolerance as last resort
                )
                logger.info("Token verification successful with high tolerance")
                return decoded_token
            except Exception as retry_error:
                logger.error(f"Retry token verification failed: {retry_error}")
        
        # If all attempts fail, raise the HTTP exception
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid authentication credentials: {error_msg}",
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
            # Mock authentication mode - use token data directly
            if getattr(settings, 'MOCK_AUTH', False):
                # Create user in our database with mock data
                user = User(
                    firebase_uid=firebase_uid,
                    email=token_data.get("email", ""),
                    display_name=token_data.get("name", "User"),
                    created_at=datetime.utcnow(),
                    last_login=datetime.utcnow()
                )
            else:
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
            await user.ensure_username()
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Failed to create user: {str(e)}",
            )
    else:
        # Update last login time and ensure username exists
        user.last_login = datetime.utcnow()
        if not user.username:
            await user.ensure_username()
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

def extract_bearer_token(request: Request) -> str:
    """Safely extract Bearer token from Authorization header"""
    auth_header = request.headers.get('Authorization')
    
    if not auth_header:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={
                "error": "authentication_required",
                "message": "Authorization header is required"
            },
            headers={"WWW-Authenticate": "Bearer"}
        )
    
    if not auth_header.startswith('Bearer '):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={
                "error": "invalid_auth_format",
                "message": "Authorization header must use Bearer token format"
            },
            headers={"WWW-Authenticate": "Bearer"}
        )
    
    # Safe token extraction with validation
    auth_parts = auth_header.split(' ', 1)
    if len(auth_parts) != 2:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={
                "error": "invalid_auth_format",
                "message": "Invalid Authorization header format"
            },
            headers={"WWW-Authenticate": "Bearer"}
        )
    
    token = auth_parts[1].strip()
    if not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={
                "error": "missing_token",
                "message": "Bearer token is empty"
            },
            headers={"WWW-Authenticate": "Bearer"}
        )
    
    return token

async def authenticate_request(request: Request) -> dict:
    """Authenticate request and return Firebase token data"""
    try:
        token = extract_bearer_token(request)
        decoded_token = await verify_firebase_token(token)
        return decoded_token
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Authentication error: {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={
                "error": "authentication_failed",
                "message": "Invalid authentication credentials"
            },
            headers={"WWW-Authenticate": "Bearer"}
        )