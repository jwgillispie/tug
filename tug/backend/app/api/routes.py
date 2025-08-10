# app/api/routes.py
from fastapi import APIRouter
from .endpoints import users, values, activities, achievements, rankings, vices, indulgences, social, notifications, mood, analytics, subscription
# Temporarily commented out for Phase 1 validation:
# premium_features, ml_predictions, habit_suggestions, coaching, premium_groups, group_messaging

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
api_router.include_router(analytics.router, prefix="/analytics", tags=["analytics"])
api_router.include_router(subscription.router, prefix="/subscription", tags=["subscription"])
# api_router.include_router(premium_features.router, prefix="/premium", tags=["premium"])
# api_router.include_router(premium_groups.router, prefix="/premium-groups", tags=["premium-groups"])
# api_router.include_router(ml_predictions.router, prefix="/ml-predictions", tags=["ml-predictions"])
# api_router.include_router(habit_suggestions.router, prefix="/habit-suggestions", tags=["habit-suggestions"])
# api_router.include_router(coaching.router, prefix="/coaching", tags=["coaching"])
# api_router.include_router(group_messaging.router, prefix="/messaging", tags=["group-messaging"])