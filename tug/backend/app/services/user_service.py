# app/services/user_service.py
from ..models.user import User
from ..schemas.user import UserCreate, UserUpdate
from datetime import datetime
from typing import Optional, List

class UserService:
    @staticmethod
    async def create_user(firebase_uid: str, user_data: UserCreate) -> User:
        """Create a new user"""
        # Check if user already exists
        existing_user = await User.find_one(User.firebase_uid == firebase_uid)
        if existing_user:
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
        return new_user
    
    @staticmethod
    async def update_user(user: User, user_data: UserUpdate) -> User:
        """Update user data"""
        update_data = user_data.model_dump(exclude_unset=True)
        if update_data:
            for field, value in update_data.items():
                setattr(user, field, value)
            await user.save()
        return user
    
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