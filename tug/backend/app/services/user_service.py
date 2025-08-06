# app/services/user_service.py
import time
from bson import ObjectId
from typing import Optional, List
from datetime import datetime

from ..models.user import User
from ..schemas.user import UserCreate, UserUpdate
from ..core.logging_config import get_logger, log_performance_metric
from ..core.errors import (
    DatabaseException, 
    ResourceNotFoundException, 
    ValidationException,
    BusinessRuleException
)
from ..core.retry import with_retry, RetryConfigs

logger = get_logger(__name__)

class UserService:
    @staticmethod
    @with_retry(config=RetryConfigs.DATABASE)
    async def create_user(firebase_uid: str, user_data: UserCreate) -> User:
        """Create a new user with retry logic and performance monitoring"""
        start_time = time.time()
        
        try:
            logger.info(
                f"Creating user for Firebase UID: {firebase_uid}",
                extra={
                    'firebase_uid': firebase_uid,
                    'email': user_data.email,
                    'operation': 'create_user'
                }
            )
            
            # Validate input
            if not firebase_uid or not firebase_uid.strip():
                raise ValidationException("Firebase UID is required")
            
            if not user_data.email or not user_data.email.strip():
                raise ValidationException("Email is required")
            
            # Check if user already exists
            existing_user = await User.find_one(User.firebase_uid == firebase_uid)
            if existing_user:
                logger.info(
                    f"User already exists for Firebase UID: {firebase_uid}",
                    extra={
                        'firebase_uid': firebase_uid,
                        'user_id': str(existing_user.id),
                        'operation': 'create_user_existing'
                    }
                )
                return existing_user
            
            # Create new user
            new_user = User(
                firebase_uid=firebase_uid,
                email=user_data.email,
                display_name=user_data.display_name,
                created_at=datetime.utcnow(),
                last_login=datetime.utcnow()
            )
            
            await new_user.insert()
            
            # Log successful creation
            execution_time = (time.time() - start_time) * 1000
            log_performance_metric(
                logger,
                'user_creation_time',
                execution_time,
                'ms',
                {
                    'firebase_uid': firebase_uid,
                    'user_id': str(new_user.id),
                    'operation': 'create_user'
                }
            )
            
            logger.info(
                f"Successfully created user: {new_user.id}",
                extra={
                    'firebase_uid': firebase_uid,
                    'user_id': str(new_user.id),
                    'execution_time_ms': execution_time,
                    'operation': 'create_user_success'
                }
            )
            
            return new_user
            
        except Exception as e:
            execution_time = (time.time() - start_time) * 1000
            
            logger.error(
                f"Failed to create user for Firebase UID: {firebase_uid}",
                extra={
                    'firebase_uid': firebase_uid,
                    'error': str(e),
                    'execution_time_ms': execution_time,
                    'operation': 'create_user_error'
                },
                exc_info=True
            )
            
            if isinstance(e, (ValidationException, BusinessRuleException)):
                raise e
            else:
                raise DatabaseException(
                    operation="create_user",
                    message=f"Failed to create user: {str(e)}",
                    details={
                        'firebase_uid': firebase_uid,
                        'original_error': str(e)
                    }
                )
    
    @staticmethod
    @with_retry(config=RetryConfigs.DATABASE)
    async def update_user(user_id: str, user_data: UserUpdate) -> Optional[User]:
        """Update user data with retry logic and performance monitoring"""
        start_time = time.time()
        
        try:
            logger.info(
                f"Updating user: {user_id}",
                extra={
                    'user_id': user_id,
                    'operation': 'update_user'
                }
            )
            
            # Validate input
            if not user_id or not user_id.strip():
                raise ValidationException("User ID is required")
            
            # Convert string ID to ObjectId if needed
            try:
                object_id = user_id if isinstance(user_id, ObjectId) else ObjectId(user_id)
            except Exception:
                raise ValidationException(f"Invalid user ID format: {user_id}")
            
            # Find the user by ID
            user = await User.get(object_id)
            if not user:
                raise ResourceNotFoundException("User", user_id)
                
            # Update user with provided data
            update_data = user_data.model_dump(exclude_unset=True)
            if not update_data:
                logger.info(
                    f"No data to update for user: {user_id}",
                    extra={
                        'user_id': user_id,
                        'operation': 'update_user_no_changes'
                    }
                )
                return user
            
            # Apply updates
            for field, value in update_data.items():
                setattr(user, field, value)
            
            await user.save()
            
            # Log successful update
            execution_time = (time.time() - start_time) * 1000
            log_performance_metric(
                logger,
                'user_update_time',
                execution_time,
                'ms',
                {
                    'user_id': user_id,
                    'fields_updated': list(update_data.keys()),
                    'operation': 'update_user'
                }
            )
            
            logger.info(
                f"Successfully updated user: {user_id}",
                extra={
                    'user_id': user_id,
                    'fields_updated': list(update_data.keys()),
                    'execution_time_ms': execution_time,
                    'operation': 'update_user_success'
                }
            )
            
            return user
            
        except Exception as e:
            execution_time = (time.time() - start_time) * 1000
            
            logger.error(
                f"Failed to update user: {user_id}",
                extra={
                    'user_id': user_id,
                    'error': str(e),
                    'execution_time_ms': execution_time,
                    'operation': 'update_user_error'
                },
                exc_info=True
            )
            
            if isinstance(e, (ValidationException, ResourceNotFoundException, BusinessRuleException)):
                raise e
            else:
                raise DatabaseException(
                    operation="update_user",
                    message=f"Failed to update user: {str(e)}",
                    details={
                        'user_id': user_id,
                        'original_error': str(e)
                    }
                )
    
    @staticmethod
    async def get_user_by_id(user_id: str) -> Optional[User]:
        """Get user by ID"""
        return await User.get(user_id)
    
    @staticmethod
    async def get_user_by_firebase_uid(firebase_uid: str) -> Optional[User]:
        """Get user by Firebase UID"""
        return await User.find_one(User.firebase_uid == firebase_uid)
    
    @staticmethod
    async def get_user_by_email(email: str) -> Optional[User]:
        """Get user by email"""
        return await User.find_one(User.email == email)