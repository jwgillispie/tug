# Indulgence Streak Implementation Documentation

## Overview

The indulgence streak system tracks "clean days" for each vice - consecutive days without recording an indulgence. Unlike values mode which tracks positive behaviors (activities completed), vices mode tracks negative behaviors (indulgences avoided).

## Core Concepts

### Streak Definition
- **Clean Streak**: Number of consecutive days without an indulgence for a specific vice
- **Indulgence Day**: Any calendar day where at least one indulgence is recorded
- **Clean Day**: Any calendar day where no indulgences are recorded
- **Streak Reset**: When an indulgence is recorded, the streak resets to 0

### Key Principle
> **Every day without an indulgence increases the streak by 1**

## Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend UI   │    │  Backend API    │    │   Database      │
│                 │    │                 │    │                 │
│ • Vice Cards    │◄──►│ • ViceService   │◄──►│ • Vice Model    │
│ • Streak Display│    │ • Calculations  │    │ • Streak Fields │
│ • Indulgence UI │    │ • API Endpoints │    │ • Indulgences   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Backend Implementation

### Database Schema (`/backend/app/models/vice.py`)

```python
class Vice(Document):
    # Core fields
    name: str
    user_id: str
    created_at: datetime
    
    # Streak tracking fields
    current_streak: int = Field(default=0)
    longest_streak: int = Field(default=0)
    last_indulgence_date: Optional[datetime] = None
    total_indulgences: int = Field(default=0)
    indulgence_dates: List[datetime] = Field(default_factory=list)
```

### Streak Calculation Logic

#### Primary Method: `calculate_current_streak()`
```python
def calculate_current_streak(self) -> int:
    """Calculate current clean streak based on last indulgence date"""
    if self.last_indulgence_date is None:
        # No indulgences recorded - streak is days since creation
        days_since_creation = (datetime.utcnow() - self.created_at).days
        return days_since_creation
    
    # Calculate days since last indulgence
    days_since_last_indulgence = (datetime.utcnow() - self.last_indulgence_date).days
    return days_since_last_indulgence
```

#### Indulgence Recording: `update_streak_on_indulgence()`
```python
def update_streak_on_indulgence(self, indulgence_date: datetime) -> None:
    """Update streak counters when an indulgence is recorded"""
    # Save current streak as longest if it's better
    current = self.calculate_current_streak()
    if current > self.longest_streak:
        self.longest_streak = current
    
    # Reset current streak and update tracking
    self.current_streak = 0
    self.last_indulgence_date = indulgence_date
    self.total_indulgences += 1
    self.indulgence_dates.append(indulgence_date)
```

### API Endpoints

| Method | Endpoint | Purpose |
|--------|----------|---------|
| `GET` | `/api/v1/vices/` | Get all vices with calculated streaks |
| `POST` | `/api/v1/vices/{vice_id}/indulge` | Record indulgence (resets streak) |
| `PATCH` | `/api/v1/vices/{vice_id}/streak` | Manual streak correction |

### Service Layer (`/backend/app/services/vice_service.py`)

```python
async def get_vices(user: User) -> List[Vice]:
    """Get user's vices with updated streak calculations"""
    vices = await Vice.find({"user_id": str(user.id)}).to_list()
    
    # Calculate current streaks for all vices
    for vice in vices:
        vice.current_streak = vice.calculate_current_streak()
    
    return vices

async def record_indulgence(user: User, vice_id: str, indulgence_data: IndulgenceCreate) -> Indulgence:
    """Record indulgence and update vice streak"""
    vice = await Vice.get(vice_id)
    
    # Create indulgence record
    indulgence = Indulgence(
        vice_id=vice_id,
        user_id=str(user.id),
        date=indulgence_data.date,
        # ... other fields
    )
    await indulgence.save()
    
    # Update vice streak (resets to 0)
    vice.update_streak_on_indulgence(indulgence_data.date)
    await vice.save()
    
    return indulgence
```

## Frontend Implementation

### Models (`/lib/models/vice_model.dart`)

```dart
class ViceModel {
  final String? id;
  final String name;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastIndulgenceDate;
  final int totalIndulgences;
  final DateTime createdAt;
  
  // Calculated properties
  int get daysSinceLastIndulgence {
    if (lastIndulgenceDate == null) {
      return DateTime.now().difference(createdAt).inDays;
    }
    return DateTime.now().difference(lastIndulgenceDate!).inDays;
  }
  
  bool get isOnCleanStreak => currentStreak > 0;
  
  String get streakDisplayText {
    if (currentStreak == 0) return "Start your streak";
    if (currentStreak == 1) return "1 day clean";
    return "$currentStreak days clean";
  }
}
```

### Streak Utilities (`/lib/utils/streak_utils.dart`)

```dart
class StreakUtils {
  /// Calculate updated streak for a vice based on indulgences
  static ViceModel calculateViceStreak(ViceModel vice, List<IndulgenceModel> indulgences) {
    if (indulgences.isEmpty) {
      // No indulgences - streak is days since creation
      final daysSinceCreation = DateTime.now().difference(vice.createdAt).inDays;
      return vice.copyWith(currentStreak: daysSinceCreation);
    }
    
    // Sort indulgences by date (newest first)
    final sortedIndulgences = List<IndulgenceModel>.from(indulgences)
      ..sort((a, b) => b.date.compareTo(a.date));
    
    final lastIndulgence = sortedIndulgences.first;
    final daysSinceLastIndulgence = DateTime.now().difference(lastIndulgence.date).inDays;
    
    return vice.copyWith(
      currentStreak: daysSinceLastIndulgence,
      lastIndulgenceDate: lastIndulgence.date,
    );
  }
  
  /// Update all vices with recalculated streaks
  static List<ViceModel> updateVicesWithStreaks(
    List<ViceModel> vices, 
    List<IndulgenceModel> allIndulgences,
  ) {
    return vices.map((vice) {
      // Filter indulgences for this vice
      final viceIndulgences = allIndulgences
          .where((indulgence) => indulgence.viceId == vice.id)
          .toList();
      
      return calculateViceStreak(vice, viceIndulgences);
    }).toList();
  }
}
```

### UI Display (`/lib/screens/vices/`)

#### Vice List Cards
```dart
// Streak indicator in vice card
Container(
  child: Column(
    children: [
      Text(
        '${vice.currentStreak}',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: color,
        ),
      ),
      Text(
        'days',
        style: TextStyle(
          fontSize: 10,
          color: color.withOpacity(0.7),
        ),
      ),
    ],
  ),
)
```

#### Detailed Streak Display
```dart
_buildDetailRow(
  icon: Icons.psychology,
  iconColor: TugColors.getStreakColor(true, vice.currentStreak),
  label: 'clean streak:',
  value: '${vice.currentStreak} day${vice.currentStreak != 1 ? 's' : ''}',
),
_buildDetailRow(
  icon: Icons.emoji_events,
  iconColor: TugColors.success,
  label: 'best streak:',
  value: '${vice.longestStreak} day${vice.longestStreak != 1 ? 's' : ''}',
),
```

## Workflow Examples

### Scenario 1: New Vice Creation
```
Day 0: Vice "Smoking" created
├─ current_streak = 0
├─ longest_streak = 0
├─ last_indulgence_date = null
└─ Calculated streak = days since creation (0)

Day 1: No indulgence
└─ Calculated streak = 1 day

Day 3: No indulgence  
└─ Calculated streak = 3 days
```

### Scenario 2: Indulgence Recorded
```
Day 5: User records smoking indulgence
├─ longest_streak = max(3, 5) = 5
├─ current_streak = 0
├─ last_indulgence_date = Day 5
└─ Calculated streak = 0 days

Day 6: No indulgence
└─ Calculated streak = 1 day

Day 8: No indulgence
└─ Calculated streak = 3 days
```

### Scenario 3: Multiple Indulgences Same Day
```
Day 10: User records 2 indulgences (same day)
├─ Only first indulgence affects streak
├─ last_indulgence_date = Day 10
└─ Streak resets once, not twice
```

## Current Issues & Limitations

### ⚠️ Critical Issues

1. **Timezone Inconsistency**
   ```python
   # Backend uses UTC
   datetime.utcnow()
   
   # Frontend uses local time
   DateTime.now()
   ```
   **Impact**: Streak calculations may be off by up to 24 hours depending on timezone.

2. **Dual Calculation Systems**
   - Backend: Simple date math
   - Frontend: Complex StreakUtils logic
   - **Risk**: Different results from same data

3. **Calendar Day vs 24-Hour Confusion**
   ```python
   # Current: 24-hour periods
   (datetime.utcnow() - self.last_indulgence_date).days
   
   # Should be: Calendar days (midnight to midnight)
   ```

### 🐛 Minor Issues

4. **Redundant Calculations**
   - Streaks calculated on every API call
   - No caching mechanism
   - Performance impact with many vices

5. **Stale Data Risk**
   - Frontend caches vices for 5 minutes
   - Background updates may not appear immediately

## Comparison with Values Mode

| Aspect | Values (Activities) | Vices (Indulgences) |
|--------|-------------------|-------------------|
| **Tracking Type** | Positive (action required) | Negative (absence preferred) |
| **Streak Trigger** | Complete activity | Avoid indulgence |
| **Reset Condition** | Miss a day | Record indulgence |
| **Default State** | No streak (requires action) | Clean streak (passive) |
| **Calculation Basis** | Calendar days | Date difference |
| **Complexity** | High (weekend handling, etc.) | Low (simple counting) |

## Recommended Improvements

### High Priority

1. **Standardize Timezone Handling**
   ```python
   # Use timezone-aware dates throughout
   from datetime import timezone
   
   def calculate_current_streak(self) -> int:
       now = datetime.now(timezone.utc)
       # Convert to user's timezone for calendar day calculation
   ```

2. **Implement Calendar Day Logic**
   ```python
   def days_between_calendar_dates(start_date: datetime, end_date: datetime) -> int:
       """Calculate days between dates using calendar days, not 24-hour periods"""
       start_cal = start_date.date()
       end_cal = end_date.date()
       return (end_cal - start_cal).days
   ```

3. **Unify Calculation Logic**
   - Use single source of truth (backend or frontend)
   - Remove redundant calculations
   - Ensure consistency across platforms

### Medium Priority

4. **Add Streak Milestones**
   ```python
   STREAK_MILESTONES = [1, 3, 7, 14, 30, 60, 90, 180, 365]
   
   def get_next_milestone(current_streak: int) -> Optional[int]:
       return next((m for m in STREAK_MILESTONES if m > current_streak), None)
   ```

5. **Implement Proper Caching**
   ```python
   @cached(ttl=300)  # 5 minutes
   async def get_vices_with_streaks(user_id: str) -> List[Vice]:
       # Cached streak calculations
   ```

6. **Add Validation & Audit Trail**
   ```python
   class StreakEvent(Document):
       vice_id: str
       event_type: str  # "reset", "milestone", "manual_update"
       old_streak: int
       new_streak: int
       reason: str
       timestamp: datetime
   ```

## Testing Scenarios

### Unit Tests Required

1. **Basic Streak Calculation**
   - New vice (no indulgences)
   - Vice with indulgences
   - Multiple indulgences same day
   - Future dates edge cases

2. **Timezone Edge Cases**
   - User changes timezone
   - Indulgence recorded at midnight
   - Cross-date-line scenarios

3. **Longest Streak Tracking**
   - Streak exceeds previous best
   - Multiple streak cycles
   - Manual corrections

### Integration Tests

1. **End-to-End Workflow**
   - Create vice → Record indulgence → Check streak
   - Multiple users, different timezones
   - API consistency across endpoints

2. **Performance Tests**
   - Large numbers of vices
   - Many indulgences per vice
   - Concurrent updates

## Monitoring & Debugging

### Key Metrics to Track

1. **Streak Accuracy**
   - Backend vs frontend calculation differences
   - User-reported discrepancies
   - Timezone-related issues

2. **Performance**
   - Streak calculation time
   - API response times
   - Cache hit rates

### Debug Tools

```python
# Add to vice model for debugging
def debug_streak_calculation(self) -> dict:
    return {
        "vice_id": str(self.id),
        "created_at": self.created_at.isoformat(),
        "last_indulgence_date": self.last_indulgence_date.isoformat() if self.last_indulgence_date else None,
        "current_streak_stored": self.current_streak,
        "current_streak_calculated": self.calculate_current_streak(),
        "longest_streak": self.longest_streak,
        "total_indulgences": self.total_indulgences,
        "timezone": "UTC",
        "calculation_time": datetime.utcnow().isoformat(),
    }
```

## Conclusion

The current indulgence streak implementation provides a solid foundation but requires improvements in timezone handling, calculation consistency, and performance optimization. The system correctly implements the core concept of tracking clean days, but attention to edge cases and user experience details will significantly improve accuracy and reliability.

The key insight is that vice streaks are fundamentally different from value streaks - they track the absence of behavior rather than the presence of behavior, which requires a different approach to calculation and user interface design.