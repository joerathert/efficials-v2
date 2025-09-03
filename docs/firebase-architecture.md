# Efficials v2.0 - Firebase Architecture

## Overview

Efficials v2.0 uses Firebase Firestore as the primary database, designed for:
- Real-time collaboration between schedulers
- Offline-first functionality for non-critical operations
- Role-based access control (Schedulers vs Officials)
- Scalable multi-scheduler environment

## Key Architectural Decisions

### 1. No Organizations Model
- **Decision**: Eliminated organization-based multi-tenancy 
- **Rationale**: Each scheduler (AD/Coach/Assigner) works independently with isolated data
- **Implementation**: All collections scoped by `schedulerId` field

### 2. Data Isolation Rules
- **Schedulers**: Cannot see other schedulers' games, lists, templates, or schedules
- **Officials**: See published games from ALL schedulers (if eligible based on list membership)
- **Shared Data**: Officials pool, Sports definitions are global

### 3. Role-Based Experience
- **Officials**: Single app experience focused on claiming games
- **Schedulers**: Three distinct experiences based on type:
  - **Athletic Directors**: School-wide game management
  - **Coaches**: Single team focus  
  - **Assigners**: League/association coordination

## Collection Structure

```
/users/{userId} - User profiles (Schedulers & Officials)
/officials/{officialId} - Global official pool
/sports/{sportId} - Global sports definitions
/schedules/{scheduleId} - Scheduler-specific schedules  
/locations/{locationId} - Scheduler-specific locations
/officialLists/{listId} - Scheduler-specific official groupings
/gameTemplates/{templateId} - Scheduler-specific templates
/games/{gameId} - Scheduler-specific games
/assignments/{assignmentId} - Official-game assignment tracking
/gameLinks/{linkId} - Scheduler-specific game linking
/syncQueue/{queueId} - Offline operation queue
/notifications/{notificationId} - User notifications
```

## Security Model

### Read Access
- **Users**: Own profile + other users' basic info
- **Officials**: Global read access
- **Games**: Officials see published games where eligible; Schedulers see only own games
- **Lists/Templates/Schedules**: Schedulers see only own data

### Write Access  
- **Users**: Can update own profile
- **Games**: Only owning scheduler can modify
- **Assignments**: Officials can create (claim interest); Schedulers can modify status
- **All other collections**: Only owning scheduler can modify

## Offline Strategy

### Offline-Capable Operations
- View schedules and games
- Edit draft games
- Browse official lists
- Update profile information

### Online-Only Operations (Critical)
- Publishing games
- Claiming assignments
- Real-time assignment updates
- FCM notifications

## Real-Time Features

### Live Updates Via Firestore Listeners
- Game status changes
- Assignment updates
- New published games
- Schedule modifications

### Optimistic Locking
- Version field in game documents
- Conflict resolution for concurrent edits
- Last modified tracking

---

*This architecture supports the core v1.0 workflows while adding real-time collaboration, offline functionality, and improved scalability.*