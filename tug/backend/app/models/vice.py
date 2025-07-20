# app/models/vice.py
from beanie import Document, Indexed
from typing import Optional, Any, Dict, List
from datetime import datetime, date, timezone
from pydantic import Field

class Vice(Document):
    """Vice model for MongoDB with Beanie ODM"""
    user_id: str = Indexed()
    name: str = Field(..., min_length=2, max_length=50)
    severity: int = Field(..., ge=1, le=5, description="Severity level from 1 (mild) to 5 (critical)")
    description: Optional[str] = Field(default="", max_length=500)
    color: str = Field(..., pattern="^#[0-9a-fA-F]{6}$")
    active: bool = True
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    current_streak: int = Field(default=0, ge=0, description="Current clean streak in days")
    longest_streak: int = Field(default=0, ge=0, description="Longest clean streak achieved")
    last_indulgence_date: Optional[datetime] = None
    total_indulgences: int = Field(default=0, ge=0, description="Total number of indulgences")
    indulgence_dates: List[datetime] = Field(default_factory=list)
    milestone_achievements: List[int] = Field(default_factory=list, description="List of milestone days achieved (7, 30, 100, etc.)")

    class Settings:
        name = "vices"
        indexes = [
            [("user_id", 1), ("created_at", -1)],
            [("user_id", 1), ("active", 1)],
            [("user_id", 1), ("severity", -1)]
        ]

    class Config:
        schema_extra = {
            "example": {
                "user_id": "user123",
                "name": "Smoking",
                "severity": 4,
                "description": "Cigarette smoking habit",
                "color": "#F44336",
                "active": True,
                "current_streak": 5,
                "longest_streak": 12,
                "total_indulgences": 23
            }
        }
    
    def dict(self, **kwargs) -> Dict[str, Any]:
        """Override default dict to convert ObjectId to string and format dates."""
        data = super().dict(**kwargs)
        # Convert the _id field to a string
        if '_id' in data:
            data['id'] = str(data.pop('_id'))
        elif 'id' in data and data['id'] is not None:
            data['id'] = str(data['id'])
        
        # Convert datetime fields to ISO format strings for JSON serialization
        datetime_fields = ['created_at', 'updated_at', 'last_indulgence_date']
        for field in datetime_fields:
            if field in data and data[field] is not None:
                if isinstance(data[field], datetime):
                    data[field] = data[field].isoformat()
        
        # Convert list of datetime objects to ISO strings
        if 'indulgence_dates' in data and data['indulgence_dates']:
            data['indulgence_dates'] = [
                date.isoformat() if isinstance(date, datetime) else date 
                for date in data['indulgence_dates']
            ]
        
        return data

    async def update_streak_on_indulgence(self):
        """Update streak counters when an indulgence is recorded"""
        self.last_indulgence_date = datetime.utcnow()
        self.total_indulgences += 1
        self.indulgence_dates.append(self.last_indulgence_date)
        
        # Reset current streak and update longest if needed
        if self.current_streak > self.longest_streak:
            self.longest_streak = self.current_streak
        self.current_streak = 0
        self.updated_at = datetime.utcnow()
        
        await self.save()

    async def update_clean_streak(self, days: int):
        """Update clean streak manually"""
        old_streak = self.current_streak
        self.current_streak = days
        if days > self.longest_streak:
            self.longest_streak = days
        self.updated_at = datetime.utcnow()
        
        # Check if a milestone was reached
        milestone = self.check_milestone_reached(old_streak, days)
        if milestone:
            await self.record_milestone_achievement(milestone)
            # Note: Social posting would need to be handled at the service level
            # to access the user context
        
        await self.save()

    def _calendar_days_between(self, start_date: datetime, end_date: datetime) -> int:
        """
        Calculate calendar days between two dates (midnight to midnight).
        This ensures consistent streak calculation regardless of time of day.
        
        Examples:
        - 2024-01-01 23:59 to 2024-01-02 00:01 = 1 day
        - 2024-01-01 12:00 to 2024-01-03 12:00 = 2 days
        
        Note: Both dates are assumed to be in UTC for consistency.
        For future enhancement, consider user timezone handling.
        """
        # Ensure dates are timezone-aware (assume UTC if naive)
        if start_date.tzinfo is None:
            start_date = start_date.replace(tzinfo=timezone.utc)
        if end_date.tzinfo is None:
            end_date = end_date.replace(tzinfo=timezone.utc)
            
        # Convert to date objects to ignore time component
        start_cal = start_date.date()
        end_cal = end_date.date()
        return (end_cal - start_cal).days

    def calculate_current_streak(self) -> int:
        """
        Calculate current streak based on calendar days since last indulgence.
        Uses calendar day logic (midnight to midnight) for consistent results.
        """
        now = datetime.utcnow()
        
        if self.last_indulgence_date is None:
            # If no indulgences recorded, streak is calendar days since creation
            return self._calendar_days_between(self.created_at, now)
        
        # Calculate calendar days since last indulgence
        return self._calendar_days_between(self.last_indulgence_date, now)
    
    def debug_streak_calculation(self) -> dict:
        """
        Debug method to provide detailed streak calculation information.
        Useful for comparing backend vs frontend calculations.
        """
        now = datetime.utcnow()
        
        return {
            "vice_id": str(self.id),
            "vice_name": self.name,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "last_indulgence_date": self.last_indulgence_date.isoformat() if self.last_indulgence_date else None,
            "current_streak_stored": self.current_streak,
            "current_streak_calculated": self.calculate_current_streak(),
            "longest_streak": self.longest_streak,
            "total_indulgences": self.total_indulgences,
            "calculation_timestamp": now.isoformat(),
            "calculation_method": "calendar_days_backend",
            "timezone": "UTC",
        }

    @property
    def severity_description(self) -> str:
        """Get human-readable severity description"""
        severity_map = {
            1: "Mild",
            2: "Moderate", 
            3: "Concerning",
            4: "Severe",
            5: "Critical"
        }
        return severity_map.get(self.severity, "Unknown")

    @property
    def is_on_clean_streak(self) -> bool:
        """Check if currently on a clean streak"""
        return self.current_streak > 0

    def check_milestone_reached(self, old_streak: int, new_streak: int) -> Optional[int]:
        """Check if a milestone was crossed between old and new streak"""
        VICE_MILESTONES = [7, 30, 100, 365]  # 7 days, 30 days, 100 days, 1 year
        
        for milestone in VICE_MILESTONES:
            if old_streak < milestone <= new_streak and milestone not in self.milestone_achievements:
                return milestone
        return None

    async def record_milestone_achievement(self, milestone: int):
        """Record that a milestone has been achieved"""
        if milestone not in self.milestone_achievements:
            self.milestone_achievements.append(milestone)
            await self.save()