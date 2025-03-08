# app/services/auth.py
import firebase_admin
from firebase_admin import auth, credentials
from datetime import datetime
from core.config import settings
from core.database import get_collection
from models.user import UserCreate, UserInDB

class AuthService:
    def __init__(self):
        # Initialize Firebase only if not already initialized
        if not firebase_admin._apps:
            cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS_PATH)
            firebase_admin.initialize_app(cred)
        
        # Don't initialize collection in constructor
        self._users_collection = None

    @property
    def users_collection(self):
        # Lazy initialization of collection
        if self._users_collection is None:
            self._users_collection = get_collection("users")
        return self._users_collection

    async def verify_token(self, token: str):
        try:
            decoded_token = auth.verify_id_token(token)
            return decoded_token
        except Exception as e:
            raise ValueError(f"Invalid token: {str(e)}")

    async def get_user_by_firebase_uid(self, firebase_uid: str) -> UserInDB:
        user_dict = await self.users_collection.find_one({"firebase_uid": firebase_uid})
        if user_dict:
            user_dict["id"] = str(user_dict.pop("_id"))
            return UserInDB(**user_dict)
        return None

    async def create_user(self, user: UserCreate, firebase_uid: str) -> UserInDB:
        user_dict = user.dict()
        user_dict.update({
            "firebase_uid": firebase_uid,
            "created_at": datetime.utcnow(),
            "last_login": datetime.utcnow(),
            "onboarding_completed": False
        })
        
        result = await self.users_collection.insert_one(user_dict)
        created_user = await self.users_collection.find_one({"_id": result.inserted_id})
        created_user["id"] = str(created_user.pop("_id"))
        
        return UserInDB(**created_user)

    async def update_last_login(self, firebase_uid: str):
        await self.users_collection.update_one(
            {"firebase_uid": firebase_uid},
            {"$set": {"last_login": datetime.utcnow()}}
        )