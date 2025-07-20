# Vices/Indulgence UI Specification

## Overview
This document outlines the complete specification for the vices and indulgence tracking functionality in the Tug app, including UI design, user experience flows, and backend requirements.

## App Structure in Vices Mode

### Navigation Layout
When the app is in **Vices Mode**, the bottom navigation changes to:

1. **Social Page** (Button 1) - `Icons.people` - `/social`
2. **Indulgences Page** (Button 2) - `Icons.spa` - `/indulgence-tracking` 
3. **Hello Page** (Button 3 - FAB) - `Icons.waving_hand` - `/home`
4. **Profile Page** (Button 4) - `Icons.person` - `/profile`

---

## 1. Social Page
**Status**: ✅ Keep as currently implemented

**Description**: The social page remains unchanged and functions exactly as it currently does, providing the social feed and community features.

---

## 2. Indulgences Page (`/indulgence-tracking`)

### 2.1 Page Structure
**Layout**: Tabbed interface with two main tabs

#### Tab 1: "Vices" - Vice Management & Quick Actions
**Purpose**: Display all tracked vices with current streak information and quick actions

**Components**:
- **Header**: "Indulgence Tracking" with refresh button
- **Vice Cards**: Each vice displays:
  - Vice name and color indicator
  - Current clean streak (in days)
  - Severity level badge
  - Best streak record
  - Swipe actions for quick access

**Swipe Actions**:
- **Left Swipe → Record**: Quick record indulgence for this vice
- **Left Swipe → Edit**: Navigate to vice management screen

**Tap Action**: Show detailed vice information modal with:
- Vice description/motivation
- Severity level details
- Current vs best streak comparison
- Quick "Record Indulgence" button

#### Tab 2: "Calendar" - Visual Streak Tracking
**Purpose**: Provide calendar view of clean days vs indulgence days

**Components**:
- **Calendar Widget**: Monthly calendar with day markers
- **Legend**: Visual guide for calendar markers
- **Streak Analysis**: Current streaks for all vices

**Calendar Markers**:
- 🟢 **Green Dot**: Clean day (no indulgences recorded)
- 🔴 **Red Dot**: Indulgence day (one or more indulgences)
- ⚫ **No Marker**: No data/future date

**Day Interaction**:
- **Tap Day**: Show modal with detailed day information:
  - List of indulgences (if any)
  - Time stamps and notes
  - Quick "Record Indulgence" button for recent days

### 2.2 Data Requirements

#### Frontend State Management
```dart
// Vices State
class VicesState {
  List<ViceModel> vices;
  Map<DateTime, List<IndulgenceModel>> indulgencesByDate;
  bool isLoading;
  String? error;
}

// Vice Model
class ViceModel {
  String id;
  String name;
  String color;
  int severity; // 1-5
  String description;
  int currentStreak; // Days since last indulgence
  int longestStreak; // Best streak record
  DateTime? lastIndulgence;
  bool active;
}

// Indulgence Model
class IndulgenceModel {
  String id;
  String viceId;
  String userId;
  DateTime date;
  int? duration; // Optional duration in minutes
  String notes;
  List<String> triggers;
  int emotionalState; // 1-10 scale
  bool isPublic;
  bool notesPublic;
}
```

#### Backend API Requirements

**Base URL**: `/api/v1/vices/`

**Endpoints Required**:

1. **GET `/api/v1/vices/`**
   - Returns: List of user's vices with calculated streaks
   - Include current streak calculation based on indulgences

2. **GET `/api/v1/vices/{viceId}/indulgences`**
   - Returns: All indulgences for specific vice
   - Sorted by date (newest first)

3. **POST `/api/v1/vices/{viceId}/indulge`**
   - Creates new indulgence record
   - Automatically resets current streak to 0
   - Updates last indulgence date

4. **GET `/api/v1/vices/stats/streaks`** *(New endpoint needed)*
   - Returns: Calculated streak data for all vices
   - Include clean days calculation

#### Streak Calculation Logic
```typescript
// Backend streak calculation
interface StreakCalculation {
  viceId: string;
  currentStreak: number; // Days since last indulgence
  longestStreak: number; // Historical best
  lastIndulgence: Date | null;
  cleanDays: Date[]; // Array of clean days for calendar
}

// Algorithm:
// 1. Get all indulgences for vice, sorted by date
// 2. Current streak = days between today and last indulgence
// 3. Longest streak = max days between any two consecutive indulgences
// 4. Clean days = all days without indulgences (for calendar markers)
```

### 2.3 User Experience Flows

#### Flow 1: View Current Streaks
1. User opens indulgences page
2. Tab 1 (Vices) shows all vices with current streaks
3. User can see at-a-glance progress for all tracked vices

#### Flow 2: Record Indulgence
1. User swipes left on vice card → "Record" action
2. Navigate to indulgence recording screen
3. After recording, streak resets to 0
4. Calendar updates with red marker for that day

#### Flow 3: View Historical Progress
1. User switches to Tab 2 (Calendar)
2. Browse monthly calendar to see clean vs indulgence patterns
3. Tap specific days to see detailed indulgence information
4. View streak analysis summary below calendar

---

## 3. Hello Page (`/home`) - Updated Design

### 3.1 Current Changes Required

#### Remove Components:
- ❌ **"Vice Check" widget** - Remove entirely

#### Add Components:
- ✅ **Weekly Vices Bar Chart** - Replace vice check widget
- ✅ **Updated Features Section** - Add indulgences navigation

### 3.2 New Weekly Vices Bar Chart

**Purpose**: Show weekly indulgence patterns across all vices

**Design Specifications**:
```dart
// Chart Data Structure
class WeeklyViceData {
  String viceName;
  String viceColor;
  List<int> dailyIndulgences; // 7 days, Sunday-Saturday
  int weeklyTotal;
}

// Chart Layout
Widget WeeklyVicesChart {
  // Bar chart showing:
  // - X-axis: Days of week (S M T W T F S)
  // - Y-axis: Number of indulgences
  // - Multiple series: One per vice (different colors)
  // - Tooltip: Show vice name + count on tap
}
```

**Visual Design**:
- **Chart Type**: Grouped bar chart
- **Time Period**: Current week (Sunday to Saturday)
- **Colors**: Use each vice's assigned color
- **Height**: ~200px
- **Legend**: Show vice names with color indicators
- **Empty State**: "No indulgences this week - great job!" message

**Data Requirements**:
- Aggregate indulgences by vice for current week
- Group by day of week
- Handle empty data gracefully

### 3.3 Updated Features Section

**Current Features to Update**:

```dart
// Updated Features List
final features = [
  {
    'title': 'Indulgences',
    'description': 'Track your vices and monitor clean streaks',
    'icon': Icons.spa_rounded,
    'color': TugColors.indulgenceGreen,
    'route': '/indulgence-tracking',
  },
  {
    'title': 'Social',
    'description': 'Connect with community and share progress',
    'icon': Icons.people_rounded,
    'color': TugColors.primaryPurple,
    'route': '/social',
  },
  // ... other existing features
];
```

**Design Requirements**:
- Update feature cards to include indulgences tracking
- Use appropriate icons and colors for vice mode
- Ensure navigation routes work correctly
- Maintain existing card design patterns

---

## 4. Profile Page
**Status**: ✅ Keep unchanged

**Description**: Profile page remains exactly as currently implemented.

---

## Implementation Priority

### Phase 1: Core Functionality ✅ (Completed)
- [x] Basic indulgences page with tabs
- [x] Vice list with streak display
- [x] Calendar with basic day markers
- [x] Updated navigation structure

### Phase 2: Enhanced Features (Next Steps)
- [ ] Remove vice check widget from hello page
- [ ] Implement weekly vices bar chart
- [ ] Update features section on hello page
- [ ] Improve streak calculation accuracy
- [ ] Add data persistence and caching

### Phase 3: Polish & Optimization
- [ ] Smooth animations and transitions
- [ ] Offline data handling
- [ ] Performance optimizations
- [ ] User onboarding for vices mode

---

## Backend API Specifications

### Required Database Schema Updates

```sql
-- Vices table (existing, may need updates)
CREATE TABLE vices (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    severity INTEGER CHECK (severity >= 1 AND severity <= 5),
    color VARCHAR(7), -- Hex color code
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Indulgences table (existing, may need updates)
CREATE TABLE indulgences (
    id UUID PRIMARY KEY,
    vice_id UUID REFERENCES vices(id),
    user_id UUID REFERENCES users(id),
    recorded_at TIMESTAMP NOT NULL,
    duration_minutes INTEGER,
    notes TEXT,
    triggers TEXT[], -- Array of trigger strings
    emotional_state INTEGER CHECK (emotional_state >= 1 AND emotional_state <= 10),
    is_public BOOLEAN DEFAULT false,
    notes_public BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_indulgences_vice_date ON indulgences(vice_id, recorded_at DESC);
CREATE INDEX idx_indulgences_user_date ON indulgences(user_id, recorded_at DESC);
CREATE INDEX idx_vices_user_active ON vices(user_id, active);
```

### API Response Formats

```typescript
// GET /api/v1/vices/ Response
interface VicesResponse {
  vices: {
    id: string;
    name: string;
    description: string;
    severity: number;
    color: string;
    current_streak: number; // Calculated
    longest_streak: number; // Calculated
    last_indulgence: string | null; // ISO date
    total_indulgences: number; // Calculated
    active: boolean;
  }[];
}

// GET /api/v1/vices/stats/weekly Response
interface WeeklyStatsResponse {
  week_start: string; // ISO date of Sunday
  vice_stats: {
    vice_id: string;
    vice_name: string;
    vice_color: string;
    daily_counts: number[]; // [sun, mon, tue, wed, thu, fri, sat]
    weekly_total: number;
  }[];
}
```

---

## Testing Requirements

### Unit Tests
- [ ] Streak calculation logic
- [ ] Date grouping for calendar
- [ ] Weekly aggregation for charts
- [ ] API error handling

### Integration Tests
- [ ] Vice creation → indulgence recording → streak reset
- [ ] Calendar navigation and day selection
- [ ] Tab switching and data persistence

### User Acceptance Tests
- [ ] Can view current streaks easily
- [ ] Can record indulgences quickly
- [ ] Calendar shows accurate clean/indulgence days
- [ ] Weekly chart reflects actual usage patterns

---

## Performance Considerations

### Caching Strategy
- Cache vice data for 5 minutes
- Cache indulgence data for 2 minutes
- Preload current week data on app start
- Background refresh for streak calculations

### Optimization
- Lazy load calendar data (load only visible months)
- Paginate indulgence history
- Compress chart data for better performance
- Use efficient date calculations for streaks

---

## Accessibility & Usability

### Visual Design
- High contrast markers for calendar
- Color-blind friendly palette
- Clear typography hierarchy
- Responsive layout for different screen sizes

### Interaction Design
- Large tap targets for calendar days
- Swipe gestures with haptic feedback
- Clear loading states and error messages
- Smooth transitions between tabs

This specification provides a complete roadmap for implementing the vices/indulgence UI with clear requirements for both frontend and backend development.