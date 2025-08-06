# tests/test_fixtures.py
"""
Additional test fixtures and factory functions for complex test scenarios
"""
import factory
from datetime import datetime, timedelta
from faker import Faker
from bson import ObjectId

from app.models.user import User
from app.models.value import Value
from app.models.activity import Activity
from app.models.vice import Vice
from app.models.indulgence import Indulgence
from app.models.friendship import Friendship, FriendshipStatus
from app.models.social_post import SocialPost, PostType
from app.models.post_comment import PostComment
from app.models.mood import MoodEntry

fake = Faker()


class UserFactory(factory.Factory):
    """Factory for creating User objects"""
    class Meta:
        model = User

    firebase_uid = factory.Sequence(lambda n: f"firebase_uid_{n}")
    email = factory.Sequence(lambda n: f"user{n}@example.com")
    username = factory.Sequence(lambda n: f"user{n}")
    display_name = factory.Faker('name')
    created_at = factory.LazyFunction(datetime.utcnow)
    last_login = factory.LazyFunction(datetime.utcnow)
    onboarding_completed = True


class ValueFactory(factory.Factory):
    """Factory for creating Value objects"""
    class Meta:
        model = Value

    user_id = factory.LazyFunction(lambda: str(ObjectId()))
    name = factory.Faker('word')
    importance = factory.Faker('random_int', min=1, max=5)
    description = factory.Faker('sentence')
    color = factory.Faker('color')
    active = True
    created_at = factory.LazyFunction(datetime.utcnow)
    updated_at = factory.LazyFunction(datetime.utcnow)


class ActivityFactory(factory.Factory):
    """Factory for creating Activity objects"""
    class Meta:
        model = Activity

    user_id = factory.LazyFunction(lambda: str(ObjectId()))
    value_id = factory.LazyFunction(lambda: str(ObjectId()))
    value_ids = factory.LazyAttribute(lambda obj: [obj.value_id])
    name = factory.Faker('sentence', nb_words=3)
    duration = factory.Faker('random_int', min=15, max=120)
    date = factory.LazyFunction(lambda: datetime.utcnow() - timedelta(days=fake.random_int(0, 30)))
    notes = factory.Faker('paragraph')
    is_public = False
    notes_public = False


class ViceFactory(factory.Factory):
    """Factory for creating Vice objects"""
    class Meta:
        model = Vice

    user_id = factory.LazyFunction(lambda: str(ObjectId()))
    name = factory.Faker('word')
    description = factory.Faker('sentence')
    color = factory.Faker('color')
    created_at = factory.LazyFunction(datetime.utcnow)
    target_days_clean = 30


class IndulgenceFactory(factory.Factory):
    """Factory for creating Indulgence objects"""
    class Meta:
        model = Indulgence

    user_id = factory.LazyFunction(lambda: str(ObjectId()))
    vice_id = factory.LazyFunction(lambda: str(ObjectId()))
    date = factory.LazyFunction(datetime.utcnow)
    notes = factory.Faker('sentence')


class FriendshipFactory(factory.Factory):
    """Factory for creating Friendship objects"""
    class Meta:
        model = Friendship

    requester_id = factory.LazyFunction(lambda: str(ObjectId()))
    addressee_id = factory.LazyFunction(lambda: str(ObjectId()))
    status = FriendshipStatus.PENDING
    created_at = factory.LazyFunction(datetime.utcnow)
    updated_at = factory.LazyFunction(datetime.utcnow)


class SocialPostFactory(factory.Factory):
    """Factory for creating SocialPost objects"""
    class Meta:
        model = SocialPost

    user_id = factory.LazyFunction(lambda: str(ObjectId()))
    content = factory.Faker('paragraph')
    post_type = PostType.GENERAL
    is_public = True
    comments_count = 0
    created_at = factory.LazyFunction(datetime.utcnow)
    updated_at = factory.LazyFunction(datetime.utcnow)


class PostCommentFactory(factory.Factory):
    """Factory for creating PostComment objects"""
    class Meta:
        model = PostComment

    post_id = factory.LazyFunction(lambda: str(ObjectId()))
    user_id = factory.LazyFunction(lambda: str(ObjectId()))
    content = factory.Faker('sentence')
    created_at = factory.LazyFunction(datetime.utcnow)
    updated_at = factory.LazyFunction(datetime.utcnow)


class MoodEntryFactory(factory.Factory):
    """Factory for creating MoodEntry objects"""
    class Meta:
        model = MoodEntry

    user_id = factory.LazyFunction(lambda: str(ObjectId()))
    mood_score = factory.Faker('random_int', min=1, max=10)
    energy_level = factory.Faker('random_int', min=1, max=10)
    stress_level = factory.Faker('random_int', min=1, max=10)
    notes = factory.Faker('sentence')
    date = factory.LazyFunction(lambda: datetime.utcnow().date())
    created_at = factory.LazyFunction(datetime.utcnow)


# Utility functions for creating test data scenarios

async def create_user_with_full_profile():
    """Create a user with complete profile data"""
    user = User(
        firebase_uid=fake.uuid4(),
        email=fake.email(),
        username=fake.user_name(),
        display_name=fake.name(),
        bio=fake.text(max_nb_chars=200),
        profile_picture_url=fake.image_url(),
        onboarding_completed=True,
        settings={
            "notifications_enabled": True,
            "theme": "dark",
            "language": "en"
        }
    )
    await user.insert()
    return user


async def create_user_with_values_and_activities(num_values=3, num_activities=10):
    """Create a user with values and activities"""
    user = await create_user_with_full_profile()
    
    values = []
    for i in range(num_values):
        value = Value(
            user_id=str(user.id),
            name=f"Value {i+1}",
            importance=fake.random_int(1, 5),
            description=fake.sentence(),
            color=fake.color(),
            active=True
        )
        await value.insert()
        values.append(value)
    
    activities = []
    for i in range(num_activities):
        selected_value = fake.random_element(values)
        activity = Activity(
            user_id=str(user.id),
            value_id=str(selected_value.id),
            value_ids=[str(selected_value.id)],
            name=fake.sentence(nb_words=3),
            duration=fake.random_int(15, 120),
            date=datetime.utcnow() - timedelta(days=fake.random_int(0, 30)),
            notes=fake.paragraph(),
            is_public=fake.boolean(),
            notes_public=fake.boolean()
        )
        await activity.insert()
        activities.append(activity)
    
    return user, values, activities


async def create_social_network(num_users=5):
    """Create a network of users with friendships and social posts"""
    users = []
    for i in range(num_users):
        user = await create_user_with_full_profile()
        users.append(user)
    
    # Create friendships between users
    friendships = []
    for i in range(num_users - 1):
        for j in range(i + 1, min(i + 3, num_users)):  # Each user friends with 2 others
            friendship = Friendship(
                requester_id=str(users[i].id),
                addressee_id=str(users[j].id),
                status=FriendshipStatus.ACCEPTED
            )
            await friendship.save()
            friendships.append(friendship)
    
    # Create social posts
    posts = []
    for user in users:
        for _ in range(fake.random_int(1, 5)):
            post = SocialPost(
                user_id=str(user.id),
                content=fake.paragraph(),
                post_type=fake.random_element(list(PostType)),
                is_public=True
            )
            await post.save()
            posts.append(post)
    
    return users, friendships, posts


async def create_user_with_vice_tracking():
    """Create a user with vices and indulgences for testing vice tracking"""
    user = await create_user_with_full_profile()
    
    vices = []
    indulgences = []
    
    # Create some vices
    vice_names = ["Social Media", "Junk Food", "Smoking", "Procrastination"]
    for name in vice_names:
        vice = Vice(
            user_id=str(user.id),
            name=name,
            description=f"Tracking {name.lower()} usage",
            color=fake.color(),
            target_days_clean=30
        )
        await vice.insert()
        vices.append(vice)
        
        # Create some indulgences for each vice
        for _ in range(fake.random_int(0, 5)):
            indulgence = Indulgence(
                user_id=str(user.id),
                vice_id=str(vice.id),
                date=datetime.utcnow() - timedelta(days=fake.random_int(0, 60)),
                notes=fake.sentence()
            )
            await indulgence.insert()
            indulgences.append(indulgence)
    
    return user, vices, indulgences


async def create_user_with_mood_tracking(days_of_data=30):
    """Create a user with mood tracking data"""
    user = await create_user_with_full_profile()
    
    mood_entries = []
    for i in range(days_of_data):
        entry_date = datetime.utcnow().date() - timedelta(days=i)
        
        # Create realistic mood patterns
        base_mood = fake.random_int(4, 8)
        mood_entry = MoodEntry(
            user_id=str(user.id),
            mood_score=base_mood + fake.random_int(-2, 2),
            energy_level=base_mood + fake.random_int(-3, 3),
            stress_level=10 - base_mood + fake.random_int(-2, 2),
            notes=fake.sentence() if fake.boolean() else None,
            date=entry_date
        )
        await mood_entry.insert()
        mood_entries.append(mood_entry)
    
    return user, mood_entries


async def create_complex_activity_scenario():
    """Create a complex scenario with multiple users, values, activities, and relationships"""
    # Create main user
    main_user, main_values, main_activities = await create_user_with_values_and_activities(5, 20)
    
    # Create friend users
    friend_users = []
    for _ in range(3):
        friend_user, _, _ = await create_user_with_values_and_activities(3, 10)
        friend_users.append(friend_user)
        
        # Create friendship
        friendship = Friendship(
            requester_id=str(main_user.id),
            addressee_id=str(friend_user.id),
            status=FriendshipStatus.ACCEPTED
        )
        await friendship.save()
    
    # Create some public activities that generate social posts
    public_activities = []
    for i in range(5):
        activity = Activity(
            user_id=str(main_user.id),
            value_id=str(main_values[0].id),
            value_ids=[str(main_values[0].id)],
            name=f"Public Activity {i+1}",
            duration=fake.random_int(30, 90),
            date=datetime.utcnow() - timedelta(days=i),
            notes=fake.paragraph(),
            is_public=True,
            notes_public=True
        )
        await activity.insert()
        public_activities.append(activity)
        
        # Create corresponding social post
        post = SocialPost(
            user_id=str(main_user.id),
            content=activity.notes,
            post_type=PostType.ACTIVITY_UPDATE,
            activity_id=str(activity.id),
            is_public=True
        )
        await post.save()
    
    return {
        "main_user": main_user,
        "main_values": main_values,
        "main_activities": main_activities,
        "friend_users": friend_users,
        "public_activities": public_activities
    }


# Test data validation helpers

def validate_user_data(user_dict):
    """Validate user data structure"""
    required_fields = ["id", "firebase_uid", "email", "display_name", "created_at"]
    return all(field in user_dict for field in required_fields)


def validate_activity_data(activity_dict):
    """Validate activity data structure"""
    required_fields = ["id", "user_id", "name", "duration", "date"]
    return all(field in activity_dict for field in required_fields)


def validate_value_data(value_dict):
    """Validate value data structure"""
    required_fields = ["id", "user_id", "name", "importance", "color"]
    return all(field in value_dict for field in required_fields)


# Performance test data generators

async def create_large_dataset_for_performance_testing():
    """Create a large dataset for performance testing"""
    print("Creating large dataset for performance testing...")
    
    # Create 100 users
    users = []
    for i in range(100):
        user = await create_user_with_full_profile()
        users.append(user)
        
        if i % 10 == 0:
            print(f"Created {i+1} users...")
    
    # Create values and activities for each user
    all_activities = []
    for i, user in enumerate(users):
        # Create 5 values per user
        values = []
        for j in range(5):
            value = Value(
                user_id=str(user.id),
                name=f"Value {j+1} for User {i+1}",
                importance=fake.random_int(1, 5),
                description=fake.sentence(),
                color=fake.color(),
                active=True
            )
            await value.insert()
            values.append(value)
        
        # Create 50 activities per user
        for k in range(50):
            selected_value = fake.random_element(values)
            activity = Activity(
                user_id=str(user.id),
                value_id=str(selected_value.id),
                value_ids=[str(selected_value.id)],
                name=f"Activity {k+1}",
                duration=fake.random_int(15, 120),
                date=datetime.utcnow() - timedelta(days=fake.random_int(0, 365)),
                notes=fake.paragraph(),
                is_public=fake.boolean(chance_of_getting_true=30),
                notes_public=fake.boolean(chance_of_getting_true=50)
            )
            await activity.insert()
            all_activities.append(activity)
        
        if i % 10 == 0:
            print(f"Created data for {i+1} users...")
    
    print(f"Dataset creation complete: {len(users)} users, {len(all_activities)} activities")
    return users, all_activities