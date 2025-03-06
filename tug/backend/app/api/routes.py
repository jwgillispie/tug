# app/api/routes.py
from fastapi import APIRouter
from .endpoints import users, values, activities

api_router = APIRouter()

api_router.include_router(users.router, prefix="/users", tags=["users"])
api_router.include_router(values.router, prefix="/values", tags=["values"])
api_router.include_router(activities.router, prefix="/activities", tags=["activities"])