# tests/conftest.py
import pytest
import asyncio
from typing import AsyncGenerator, Generator
from httpx import AsyncClient
from motor.motor_asyncio import AsyncIOMotorClient
from beanie import init_beanie
from faker import Faker
from datetime import datetime, timedelta
import logging
import os

# Import app and models
from app.main import app
from app.core.config import settings
from app.models.user import User
from app.models.value import Value
from app.models.activity import Activity
from app.models.vice import Vice
from app.models.indulgence import Indulgence
from app.models.friendship import Friendship
from app.models.social_post import SocialPost
from app.models.post_comment import PostComment
from app.models.notification import Notification, NotificationBatch
from app.models.mood import MoodEntry

# Configure logging for tests
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Configure test environment
TEST_DATABASE_NAME = "tug_test"
TEST_MONGODB_URL = os.environ.get("TEST_MONGODB_URL", "mongodb://localhost:27017")

fake = Faker()
fake.seed_instance(42)  # For reproducible test data


@pytest.fixture(scope="session")
def event_loop() -> Generator[asyncio.AbstractEventLoop, None, None]:
    """Create an instance of the default event loop for the test session."""
    loop = asyncio.new_event_loop()
    yield loop
    loop.close()


@pytest.fixture(scope="session")
async def test_db_client() -> AsyncGenerator[AsyncIOMotorClient, None]:
    """Create test database client and initialize collections"""
    client = AsyncIOMotorClient(TEST_MONGODB_URL)
    
    # Test connection
    try:
        await client.admin.command('ping')
        logger.info("Successfully connected to test MongoDB")
    except Exception as e:
        logger.error(f"Failed to connect to test MongoDB: {e}")
        raise
    
    # Initialize beanie with test database
    await init_beanie(
        database=client[TEST_DATABASE_NAME],
        document_models=[
            User,
            Value,
            Activity,
            Vice,
            Indulgence,
            Friendship,
            SocialPost,
            PostComment,
            Notification,
            NotificationBatch,
            MoodEntry,
        ]
    )
    
    yield client
    
    # Cleanup: Drop test database after all tests
    await client.drop_database(TEST_DATABASE_NAME)
    client.close()


@pytest.fixture(autouse=True)
async def cleanup_db(test_db_client):
    """Clean up database before each test"""
    # Clean all collections before each test
    collections = [
        User, Value, Activity, Vice, Indulgence,
        Friendship, SocialPost, PostComment, 
        Notification, NotificationBatch, MoodEntry
    ]
    
    for collection in collections:
        await collection.delete_all()
    
    yield
    
    # Clean up after test as well
    for collection in collections:
        await collection.delete_all()


@pytest.fixture
async def test_client(test_db_client) -> AsyncGenerator[AsyncClient, None]:
    """Create test HTTP client"""
    async with AsyncClient(app=app, base_url="http://test") as client:
        yield client


# User fixtures
@pytest.fixture
async def sample_user() -> User:
    """Create a sample user for testing"""
    user = User(
        firebase_uid="test_firebase_uid_1",
        email="test@example.com",
        username="testuser",
        display_name="Test User",
        created_at=datetime.utcnow(),
        last_login=datetime.utcnow(),
        onboarding_completed=True
    )
    await user.insert()
    return user


@pytest.fixture
async def sample_user_2() -> User:
    """Create a second sample user for testing relationships"""
    user = User(
        firebase_uid="test_firebase_uid_2",
        email="test2@example.com",
        username="testuser2",
        display_name="Test User 2",
        created_at=datetime.utcnow(),
        last_login=datetime.utcnow(),
        onboarding_completed=True
    )
    await user.insert()
    return user


@pytest.fixture
async def sample_users_batch() -> list[User]:
    """Create multiple users for testing"""
    users = []
    for i in range(5):
        user = User(
            firebase_uid=f"test_firebase_uid_{i+10}",
            email=f"testuser{i+10}@example.com",
            username=f"testuser{i+10}",
            display_name=f"Test User {i+10}",
            created_at=datetime.utcnow(),
            last_login=datetime.utcnow(),
            onboarding_completed=True
        )
        await user.insert()
        users.append(user)
    return users


# Value fixtures
@pytest.fixture
async def sample_value(sample_user: User) -> Value:
    """Create a sample value for testing"""
    value = Value(
        user_id=str(sample_user.id),
        name="Health & Fitness",
        importance=5,
        description="Staying healthy and fit",
        color="#FF6B6B",
        active=True,
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow()
    )
    await value.insert()
    return value


@pytest.fixture
async def sample_values_batch(sample_user: User) -> list[Value]:
    """Create multiple values for testing"""
    values = []
    value_names = [
        ("Health & Fitness", "#FF6B6B", 5),
        ("Learning", "#4ECDC4", 4),
        ("Family Time", "#45B7D1", 5),
        ("Creativity", "#F7DC6F", 3),
        ("Career", "#BB8FCE", 4)
    ]
    
    for name, color, importance in value_names:
        value = Value(
            user_id=str(sample_user.id),
            name=name,
            importance=importance,
            description=f"Activities related to {name.lower()}",
            color=color,
            active=True,
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow()
        )
        await value.insert()
        values.append(value)
    
    return values


# Activity fixtures
@pytest.fixture
async def sample_activity(sample_user: User, sample_value: Value) -> Activity:
    """Create a sample activity for testing"""
    activity = Activity(
        user_id=str(sample_user.id),
        value_id=str(sample_value.id),
        value_ids=[str(sample_value.id)],
        name="Morning Run",
        duration=30,
        date=datetime.utcnow(),
        notes="Great morning run in the park",
        is_public=False,
        notes_public=False
    )
    await activity.insert()
    return activity


@pytest.fixture
async def sample_activities_batch(sample_user: User, sample_values_batch: list[Value]) -> list[Activity]:
    """Create multiple activities for testing"""
    activities = []
    base_date = datetime.utcnow()
    
    activity_data = [
        ("Morning Run", 30, "Great morning run", 0),
        ("Reading Session", 45, "Read about Python testing", 1),
        ("Family Dinner", 60, "Quality time with family", 2),
        ("Workout", 45, "Strength training", 0),
        ("Study Time", 90, "Learning new concepts", 1)
    ]
    
    for i, (name, duration, notes, value_idx) in enumerate(activity_data):
        activity = Activity(
            user_id=str(sample_user.id),
            value_id=str(sample_values_batch[value_idx].id),
            value_ids=[str(sample_values_batch[value_idx].id)],
            name=name,
            duration=duration,
            date=base_date - timedelta(days=i),
            notes=notes,
            is_public=i % 2 == 0,  # Make every other activity public
            notes_public=i % 2 == 0
        )
        await activity.insert()
        activities.append(activity)
    
    return activities


# Vice fixtures
@pytest.fixture
async def sample_vice(sample_user: User) -> Vice:
    """Create a sample vice for testing"""
    vice = Vice(
        user_id=str(sample_user.id),
        name="Social Media",
        description="Excessive social media usage",
        color="#E74C3C",
        created_at=datetime.utcnow(),
        target_days_clean=30
    )
    await vice.insert()
    return vice


# Social fixtures
@pytest.fixture
async def sample_friendship(sample_user: User, sample_user_2: User) -> Friendship:
    """Create a friendship for testing"""
    from app.models.friendship import FriendshipStatus
    
    friendship = Friendship(
        requester_id=str(sample_user.id),
        addressee_id=str(sample_user_2.id),
        status=FriendshipStatus.ACCEPTED,
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow()
    )
    await friendship.insert()
    return friendship


@pytest.fixture
async def sample_social_post(sample_user: User, sample_activity: Activity) -> SocialPost:
    """Create a social post for testing"""
    from app.models.social_post import PostType
    
    post = SocialPost(
        user_id=str(sample_user.id),
        content="Just completed an amazing workout session!",
        post_type=PostType.ACTIVITY_UPDATE,
        activity_id=str(sample_activity.id),
        is_public=True,
        comments_count=0,
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow()
    )
    await post.insert()
    return post


# Authentication fixtures
class MockFirebaseToken:
    """Mock Firebase token for testing"""
    def __init__(self, uid: str, email: str):
        self.uid = uid
        self.email = email


@pytest.fixture
def mock_firebase_auth(mocker):
    """Mock Firebase authentication"""
    mock_decode = mocker.patch("firebase_admin.auth.verify_id_token")
    mock_decode.return_value = {
        "uid": "test_firebase_uid_1",
        "email": "test@example.com",
        "email_verified": True
    }
    return mock_decode


@pytest.fixture
def mock_firebase_auth_invalid(mocker):
    """Mock invalid Firebase authentication"""
    from firebase_admin.exceptions import InvalidIdTokenError
    mock_decode = mocker.patch("firebase_admin.auth.verify_id_token")
    mock_decode.side_effect = InvalidIdTokenError("Invalid token")
    return mock_decode


# Utility fixtures
@pytest.fixture
def future_date():
    """Provide a future date for testing"""
    return datetime.utcnow() + timedelta(days=1)


@pytest.fixture
def past_date():
    """Provide a past date for testing"""
    return datetime.utcnow() - timedelta(days=30)


@pytest.fixture
def valid_activity_data(sample_value: Value):
    """Provide valid activity creation data"""
    return {
        "value_ids": [str(sample_value.id)],
        "name": "Test Activity",
        "duration": 45,
        "date": datetime.utcnow().isoformat(),
        "notes": "Test activity notes",
        "is_public": False,
        "notes_public": False
    }


@pytest.fixture
def valid_value_data():
    """Provide valid value creation data"""
    return {
        "name": "Test Value",
        "importance": 4,
        "description": "A test value for testing purposes",
        "color": "#FF5733"
    }


# Test settings override
@pytest.fixture(autouse=True)
def override_settings(monkeypatch):
    """Override settings for testing"""
    monkeypatch.setenv("MONGODB_DB_NAME", TEST_DATABASE_NAME)
    monkeypatch.setenv("DEBUG", "true")
    

# Pytest configuration
@pytest.fixture(autouse=True)
def configure_pytest():
    """Configure pytest settings"""
    # Set asyncio mode to auto for pytest-asyncio
    pytest.mark.asyncio