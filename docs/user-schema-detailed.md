# Users Schema - Detailed Analysis

## Collection: `/users/{userId}`

### Core Document Structure
```dart
{
  'id': String, // Firebase Auth UID
  'email': String,
  'role': String, // 'scheduler' | 'official'
  'profile': {
    'firstName': String,
    'lastName': String,
    'phone': String,
    'profileImageUrl': String?, // Optional
  },
  'schedulerProfile': { /* Scheduler-specific fields */ }?,
  'officialProfile': { /* Official-specific fields */ }?,
  'fcmTokens': List<String>, // Push notification tokens
  'createdAt': Timestamp,
  'updatedAt': Timestamp,
}
```

## Field-by-Field Analysis

### Universal Fields (All Users)

**`id` (String)** - Firebase Auth UID
- **When Set**: Automatically during Firebase Auth account creation
- **Purpose**: Primary key, security rule validation, cross-collection references
- **Usage**: Links to assignments, games, and other user-specific data

**`email` (String)** 
- **When Set**: During signup (Step 1 - universal)
- **Purpose**: Authentication, communication, user identification
- **Usage**: Firebase Auth login, notification delivery, contact info

**`role` (String)** - 'scheduler' | 'official'
- **When Set**: Role selection screen (first step after basic info)
- **Purpose**: Basic app routing and security permissions
- **Usage**: Determines broad app experience and collection access rights
- **Note**: For schedulers, `schedulerProfile.type` determines specific experience

**`profile` (Object)** - Basic identity info
- **When Set**: During signup (Step 2 - after role selection)
- **Required Fields**: firstName, lastName, phone
- **Optional Fields**: profileImageUrl (can be added later)
- **Purpose**: User identification, professional communication, app display

**`fcmTokens` (List<String>)** 
- **When Set**: Automatically on app login from each device
- **Purpose**: Push notification delivery across multiple devices
- **Usage**: Game publishing alerts, assignment updates, schedule changes

**`createdAt` / `updatedAt` (Timestamp)**
- **When Set**: createdAt during signup, updatedAt on profile changes
- **Purpose**: Audit trail, debugging, data integrity tracking

## Scheduler-Specific Profiles

### Athletic Director Profile
```dart
'schedulerProfile': {
  'type': 'Athletic Director',
  'schoolName': String,        // e.g., "Edwardsville" 
  'mascot': String,           // e.g., "Tigers"
  'schoolAddress': String,    // Full address for official radius searches
}
```

**Business Logic**:
- **Home Team Generation**: `${schoolName} ${mascot}` (e.g., "Edwardsville Tigers")
- **Game Creation Scope**: All sports, all levels for their school
- **Official Search Center**: Uses `schoolAddress` for radius-based official searches
- **Required During Signup**: All fields mandatory

**Signup Screen**: "School Information"
- School/City Name field
- School Mascot field  
- School Address field
- Explanation: Address used for finding officials in your area

### Coach Profile
```dart
'schedulerProfile': {
  'type': 'Coach',
  'teamName': String,           // e.g., "Edwardsville Eagles"
  'sport': String,             // e.g., "Basketball" 
  'levelOfCompetition': String, // e.g., "JV"
  'gender': String,            // e.g., "Boys"
  'defaultLocationId': String,  // Reference to location for official searches
}
```

**Business Logic**:
- **Home Team**: Direct usage of `teamName` (e.g., "Edwardsville Eagles")
- **Game Creation Scope**: MOST RESTRICTIVE - single team, single sport only
- **Pre-filled Game Fields**: sport, levelOfCompetition, gender auto-filled during game creation
- **Official Search Center**: Uses address from `defaultLocationId` location
- **Required During Signup**: All fields mandatory

**Signup Flow**:
1. Team Information screen (name, sport, level, gender)
2. Location creation/selection screen (explained as center for official searches)

### Assigner Profile  
```dart
'schedulerProfile': {
  'type': 'Assigner',
  'organizationName': String,   // e.g., "Edwardsville Little League", "SAOA"
  'sport': String,             // e.g., "Basketball"
  'homeAddress': {             // For official radius searches
    'address': String,
    'city': String,
    'state': String, 
    'zipCode': String
  },
}
```

**Business Logic**:
- **Home Team**: Must select for each game (works across multiple schools/teams)
- **Game Creation Scope**: Single sport, multiple teams/locations
- **Pre-filled Game Fields**: Only sport is auto-filled
- **Official Search Center**: Uses `homeAddress` for radius searches  
- **Required During Signup**: All fields mandatory

**Signup Flow**:
1. Organization Information screen (name, sport)
2. Address entry screen (explained as center for official searches)

## Official-Specific Profile
```dart
'officialProfile': {
  'city': String,
  'state': String,
  'experienceYears': int?,
  'certificationLevel': String?,
  'availabilityStatus': String, // 'available' | 'busy' | 'unavailable'
  'followThroughRate': double,  // 0.0-100.0
  'totalAcceptedGames': int,
  'totalBackedOutGames': int,
  'bio': String?,
}
```

**Purpose**: Enables schedulers to make informed assignment decisions
- **Location Info**: Used for travel distance calculations and local game preferences
- **Experience Data**: Helps schedulers match skill levels to game importance
- **Reliability Metrics**: Reputation system for trustworthiness assessment
- **Availability**: Quick filtering for active officials

## Signup Flow Summary

### Universal Flow
1. **Welcome Screen**: Sign In or Sign Up
2. **Role Selection**: "Are you a Scheduler or Official?"
3. **Basic Profile**: Email, password, first name, last name, phone

### Scheduler-Specific Continuation
4. **Scheduler Type**: "Athletic Director", "Coach", or "Assigner"
5. **Type-Specific Info**: School info, team info, or organization info
6. **Location Setup**: School address, default location, or home address

### Official-Specific Continuation  
4. **Official Profile**: Location, experience, certifications, bio

---

*The role and scheduler type selections are the primary drivers of the entire user experience, determining navigation, features, and data access patterns.*