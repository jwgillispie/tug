# app/main.py
from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from .core.config import settings
from .core.database import connect_to_mongodb, close_mongodb_connection
from .services.auth import AuthService
from .models.user import UserCreate, UserInDB

app = FastAPI(title=settings.APP_NAME)
security = HTTPBearer()

# Initialize CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Event handlers
@app.on_event("startup")
async def startup_event():
    print("Starting up...")
    await connect_to_mongodb()
    print("Database connected")
    app.state.auth_service = AuthService()
    print("Auth service initialized")

@app.on_event("shutdown")
async def shutdown_event():
    await close_mongodb_connection()

# Dependency to get auth service
async def get_auth_service():
    return app.state.auth_service

# Dependency to get current user
async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    auth_service: AuthService = Depends(get_auth_service)
) -> UserInDB:
    try:
        token = credentials.credentials
        decoded_token = await auth_service.verify_token(token)
        user = await auth_service.get_user_by_firebase_uid(decoded_token["uid"])
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        return user
    except ValueError as e:
        raise HTTPException(status_code=401, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# Routes
@app.get("/")
async def root():
    return {"message": f"Welcome to {settings.APP_NAME}"}

@app.get("/health")
async def health_check():
    try:
        return {
            "status": "healthy",
            "database": "connected",
            "auth": "initialized"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/auth/register", response_model=UserInDB)
async def register_user(
    user: UserCreate,
    credentials: HTTPAuthorizationCredentials = Depends(security),
    auth_service: AuthService = Depends(get_auth_service)
):
    try:
        decoded_token = await auth_service.verify_token(credentials.credentials)
        existing_user = await auth_service.get_user_by_firebase_uid(decoded_token["uid"])
        
        if existing_user:
            raise HTTPException(status_code=400, detail="User already registered")
        
        return await auth_service.create_user(user, decoded_token["uid"])
    except ValueError as e:
        raise HTTPException(status_code=401, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/auth/me", response_model=UserInDB)
async def get_user_profile(current_user: UserInDB = Depends(get_current_user)):
    return current_user