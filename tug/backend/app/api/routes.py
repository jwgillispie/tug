# app/api/routes.py
from fastapi import APIRouter
from .endpoints import users, values, activities, achievements, rankings, vices, indulgences, social, notifications, mood

api_router = APIRouter()

api_router.include_router(users.router, prefix="/users", tags=["users"])
api_router.include_router(values.router, prefix="/values", tags=["values"])
api_router.include_router(activities.router, prefix="/activities", tags=["activities"])
api_router.include_router(achievements.router, prefix="/achievements", tags=["achievements"])
api_router.include_router(rankings.router, prefix="/rankings", tags=["rankings"])
api_router.include_router(vices.router, prefix="/vices", tags=["vices"])
api_router.include_router(indulgences.router, prefix="/indulgences", tags=["indulgences"])
api_router.include_router(social.router, prefix="/social", tags=["social"])
api_router.include_router(notifications.router, prefix="/notifications", tags=["notifications"])
api_router.include_router(mood.router, prefix="/mood", tags=["mood"])