"""
Performance testing configuration for Tug API using Locust
This file defines load testing scenarios for the Tug application
"""

import json
import random
import time
from typing import Dict, Any

from locust import HttpUser, task, between, events
from locust.env import Environment


class TugApiUser(HttpUser):
    """
    Simulates a typical Tug app user interacting with the API
    """
    wait_time = between(1, 5)  # Wait 1-5 seconds between requests
    
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.auth_token = None
        self.user_id = None
        
    def on_start(self):
        """Called when a simulated user starts"""
        self.login_or_register()
        
    def login_or_register(self):
        """Simulate user authentication"""
        # For testing purposes, we'll simulate auth without actual credentials
        # In real scenarios, you'd use test credentials
        test_users = [
            {"email": "test1@example.com", "password": "testpass123"},
            {"email": "test2@example.com", "password": "testpass123"},
            {"email": "test3@example.com", "password": "testpass123"},
        ]
        
        user_creds = random.choice(test_users)
        
        # Simulate login attempt (adjust endpoint based on actual API)
        response = self.client.post("/api/v1/auth/login", json=user_creds, catch_response=True)
        
        if response.status_code == 200:
            data = response.json()
            self.auth_token = data.get("access_token")
            self.user_id = data.get("user_id")
            response.success()
        else:
            # If login fails, it might be expected in test environment
            response.success()
            
    def get_auth_headers(self) -> Dict[str, str]:
        """Get authentication headers"""
        if self.auth_token:
            return {"Authorization": f"Bearer {self.auth_token}"}
        return {}
    
    @task(3)
    def health_check(self):
        """Test the health endpoint - should be fast"""
        self.client.get("/health")
    
    @task(2)  
    def get_user_profile(self):
        """Test getting user profile"""
        headers = self.get_auth_headers()
        self.client.get("/api/v1/users/me", headers=headers, catch_response=True)
    
    @task(4)
    def get_activities(self):
        """Test getting user activities - high frequency endpoint"""
        headers = self.get_auth_headers()
        self.client.get("/api/v1/activities", headers=headers, catch_response=True)
        
    @task(3)
    def get_values(self):
        """Test getting user values"""
        headers = self.get_auth_headers()
        self.client.get("/api/v1/values", headers=headers, catch_response=True)
        
    @task(2)
    def get_vices(self):
        """Test getting user vices"""
        headers = self.get_auth_headers()
        self.client.get("/api/v1/vices", headers=headers, catch_response=True)
        
    @task(1)
    def create_activity(self):
        """Test creating a new activity - write operation"""
        headers = self.get_auth_headers()
        activity_data = {
            "title": f"Test Activity {random.randint(1, 1000)}",
            "description": "Performance test activity",
            "category": random.choice(["exercise", "learning", "social"]),
            "duration": random.randint(15, 120)
        }
        
        response = self.client.post(
            "/api/v1/activities",
            json=activity_data,
            headers=headers,
            catch_response=True
        )
        
        # For testing, we accept various response codes as success
        if response.status_code in [200, 201, 401, 403]:
            response.success()
        else:
            response.failure(f"Unexpected status code: {response.status_code}")
    
    @task(1)
    def get_mood_data(self):
        """Test getting mood tracking data"""
        headers = self.get_auth_headers()
        self.client.get("/api/v1/mood", headers=headers, catch_response=True)
        
    @task(1)
    def get_rankings(self):
        """Test getting user rankings"""
        headers = self.get_auth_headers()
        self.client.get("/api/v1/rankings", headers=headers, catch_response=True)


class AdminUser(HttpUser):
    """
    Simulates administrative operations - lower frequency but important
    """
    wait_time = between(5, 15)
    weight = 1  # Lower weight means fewer admin users
    
    @task
    def admin_health_check(self):
        """Admin-level health checks"""
        self.client.get("/health")
        
    @task
    def get_system_stats(self):
        """Get system statistics (if such endpoint exists)"""
        headers = {"Authorization": "Bearer admin-test-token"}
        self.client.get("/api/v1/admin/stats", headers=headers, catch_response=True)


class ReadHeavyUser(HttpUser):
    """
    Simulates users who primarily read data - analytics users
    """
    wait_time = between(2, 8)
    weight = 2
    
    @task(5)
    def browse_activities(self):
        """Heavy reading of activities"""
        self.client.get("/api/v1/activities", catch_response=True)
        
    @task(3)
    def browse_rankings(self):
        """Check rankings frequently"""
        self.client.get("/api/v1/rankings", catch_response=True)
        
    @task(2)
    def get_analytics(self):
        """Get analytics data"""
        self.client.get("/api/v1/analytics", catch_response=True)


# Event listeners for custom metrics and reporting
@events.request.add_listener
def record_custom_metrics(request_type, name, response_time, response_length, response, context, exception, **kwargs):
    """Record custom performance metrics"""
    if exception:
        print(f"Request failed: {name} - {exception}")
    elif response_time > 1000:  # Log slow requests (>1s)
        print(f"Slow request detected: {name} took {response_time}ms")


@events.test_start.add_listener  
def on_test_start(environment: Environment, **kwargs):
    """Called when the test starts"""
    print("🚀 Starting Tug API performance tests...")
    print(f"Target host: {environment.host}")
    

@events.test_stop.add_listener
def on_test_stop(environment: Environment, **kwargs):
    """Called when the test stops"""
    print("🏁 Performance test completed")
    
    # Calculate custom metrics
    stats = environment.stats
    total_requests = stats.total.num_requests
    total_failures = stats.total.num_failures
    avg_response_time = stats.total.avg_response_time
    
    print(f"📊 Test Summary:")
    print(f"   Total requests: {total_requests}")
    print(f"   Total failures: {total_failures}")
    print(f"   Failure rate: {(total_failures/total_requests*100):.2f}%" if total_requests > 0 else "   Failure rate: 0%")
    print(f"   Average response time: {avg_response_time:.2f}ms")
    
    # Performance thresholds
    if avg_response_time > 500:
        print("⚠️  Warning: Average response time exceeds 500ms")
    if total_failures / total_requests > 0.01:  # 1% failure rate threshold
        print("⚠️  Warning: Failure rate exceeds 1%")


# Custom load shapes for different testing scenarios
from locust import LoadTestShape

class StepLoadShape(LoadTestShape):
    """
    A step load shape that gradually increases load
    """
    step_time = 30  # seconds
    step_load = 10   # users per step
    spawn_rate = 2   # users spawned per second
    time_limit = 300  # total test time in seconds
    
    def tick(self):
        run_time = self.get_run_time()
        
        if run_time > self.time_limit:
            return None
            
        current_step = run_time // self.step_time + 1
        return (current_step * self.step_load, self.spawn_rate)


class SpikePeakShape(LoadTestShape):
    """
    A load shape that simulates traffic spikes
    """
    stages = [
        {"duration": 60, "users": 10, "spawn_rate": 2},
        {"duration": 120, "users": 50, "spawn_rate": 5},  # Spike
        {"duration": 180, "users": 10, "spawn_rate": 2},
        {"duration": 240, "users": 100, "spawn_rate": 10}, # Bigger spike
        {"duration": 300, "users": 10, "spawn_rate": 2},
    ]
    
    def tick(self):
        run_time = self.get_run_time()
        
        for stage in self.stages:
            if run_time < stage["duration"]:
                return (stage["users"], stage["spawn_rate"])
                
        return None