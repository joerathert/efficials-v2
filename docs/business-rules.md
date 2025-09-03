# Efficials v2.0 - Business Rules & Logic

## Core Data Isolation Rules

### Scheduler Data Separation
- Each Athletic Director, Coach, and Assigner maintains completely isolated data
- **Games**: John (AD) cannot see Jane's (AD) games
- **Official Lists**: John cannot see or access Jane's official lists  
- **Templates**: John cannot see Jane's game templates
- **Schedules**: John cannot see Jane's schedules
- **Locations**: John cannot see Jane's locations

### Official Data Sharing
- **Officials Collection**: Global pool shared by all schedulers
- **List Membership**: Same official (e.g., "Mike Johnson") can be in multiple schedulers' lists
- **Game Visibility**: Officials only see published games where they are eligible
- **Eligibility Rule**: Official sees game ONLY if included in a list used by that game

## Game Visibility Logic

### For Officials
**Mike sees a game IF:**
1. Game status = "published" AND
2. Game uses a list that includes Mike's officialId OR
3. Game uses advanced method with quotas from lists containing Mike

**Examples**:
- John creates Game A using "Varsity Refs" list (includes Mike) → Mike sees it
- John creates Game B using "JV Football" list (excludes Mike) → Mike doesn't see it  
- Jane creates Game C using "Basketball Officials" list (includes Mike) → Mike sees it

### For Schedulers
**John sees games where:**
- `schedulerId` equals John's userId
- Complete isolation from other schedulers' games

## Home Team Generation Rules

### Athletic Directors
- **Formula**: `${schoolName} ${mascot}`
- **Examples**: 
  - School: "Edwardsville", Mascot: "Tigers" → "Edwardsville Tigers"
  - School: "St. Mary's", Mascot: "Lions" → "St. Mary's Lions"
- **Usage**: Auto-filled in ALL games created by this AD

### Coaches  
- **Source**: Direct usage of `teamName` field
- **Examples**: "Edwardsville Eagles", "Central High Bulldogs"
- **Usage**: Auto-filled in ALL games created by this coach

### Assigners
- **Behavior**: No auto-fill, must select home team for each game
- **Reason**: Assigners work across multiple schools/teams

## Game Creation Pre-filling Logic

### Athletic Directors
- **Auto-filled**: Home team (school + mascot)
- **Must Select**: Sport, level of competition, gender, date, time, opponent, location
- **Workflow**: Full selection required for each game

### Coaches (Most Streamlined)
- **Auto-filled**: Home team, sport, level of competition, gender
- **Must Select**: Date, time, opponent, location
- **Workflow**: Minimal input required (most efficient)

### Assigners  
- **Auto-filled**: Sport only
- **Must Select**: Home team, level of competition, gender, date, time, opponent, location
- **Workflow**: Most manual input required

## Official Search Radius Logic

### Geographic Center Points
- **Athletic Directors**: Use `schoolAddress` from profile
- **Coaches**: Use address from their selected `defaultLocationId` 
- **Assigners**: Use `homeAddress` from profile

### Search Context
- **Game-Specific**: Use game location address for radius searches
- **General List Creation**: Use profile-based address as center point

## Location Management

### Creation Rights
- **All scheduler types** can create new locations via Add New Location screen
- **Location ownership**: Scoped to the scheduler who created it
- **Usage**: Any scheduler can only use locations they created

### Required Address Components  
- Location name
- Street address
- City
- State (2-letter code)
- ZIP code (5 digits)

## Assignment & Claiming Rules

### Official Claiming Process
1. Official sees published game (based on list eligibility)
2. Official expresses interest → creates assignment with status "interested"
3. Scheduler reviews interested officials → changes status to "assigned"
4. Official can accept/decline → status becomes "accepted"/"declined"

### Race Condition Prevention
- **Game claiming**: Online-only operation using Cloud Functions
- **Atomic validation**: Prevents over-assignment or double-claiming
- **Quota enforcement**: Advanced method enforces min/max per list

## Offline vs Online Operations

### Offline-Capable (Non-Critical)
- Viewing schedules and games
- Creating/editing draft games  
- Managing official lists
- Profile updates
- Browse assignments

### Online-Only (Critical)
- Publishing games → triggers FCM notifications
- Claiming assignments → requires atomic validation
- Real-time game updates → prevents conflicts
- Assignment status changes → triggers notifications

---

*These rules ensure data integrity, prevent conflicts, and maintain proper isolation while enabling the core scheduling and assignment workflows.*