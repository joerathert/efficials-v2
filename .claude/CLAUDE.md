# EFFICIALS V2.0 - PROJECT CONTEXT & STATUS

## 🎯 MISSION: Complete Rebuild from SQLite to Firebase

I am rebuilding the Efficials sports officials scheduling app from scratch as v2.0. The v1.0 codebase at `/mnt/c/Users/Efficials/efficials_app` worked well on Android emulator but became a patched-together SQLite mess when migrating to Firebase. I reset to a clean slate and started v2.0 at `/mnt/c/Users/Efficials/efficials_v2` with Firebase from the ground up.

## 🏗️ V2.0 ARCHITECTURE GOALS

### Core Technology Stack
- **Flutter** - Cross-platform (Android, iOS, Web)
- **Firebase Firestore** - Real-time NoSQL database  
- **Firebase Authentication** - User management
- **Firebase Cloud Functions** - Server-side atomic operations
- **FCM** - Push notifications

### Key Features Required
- **Real-time Collaboration** - Multiple schedulers editing simultaneously
- **Offline-First** - Non-critical tasks work offline, sync later
- **Atomic Operations** - Prevent race conditions in game claiming
- **Role-Based Access** - Schedulers create/edit, Officials view/claim
- **"Publish Later"** - Queue games offline, publish online with notifications

## 📊 CURRENT STATUS (CRITICAL FOR CONTEXT)

### ✅ COMPLETED FEATURES
1. **Complete Firebase Architecture Design** - No organizations model, scheduler isolation
2. **User Authentication System** - Firebase Auth + Firestore user profiles
3. **Full User Models** - Athletic Director, Coach, Assigner, Official profiles
4. **Athletic Director Signup Flow** - 5-screen complete flow working ✅
5. **Firebase Integration** - User creation, profile storage, real-time sync ✅
6. **Athletic Director End-to-End Testing** - Account creation, Firestore storage, navigation working ✅

### ✅ RECENT FIXES COMPLETED
**Firebase Package Compatibility Issue** - RESOLVED! Fixed Dart SDK constraint and Firebase package compatibility:
- Fixed Dart SDK constraint from `^3.9.0` to `^3.4.0` for Flutter 3.22.0 compatibility
- Downgraded flutter_lints to `^4.0.0` 
- Updated Firebase packages to compatible versions
- Athletic Director signup now works end-to-end with successful account creation

**School Name vs Schedule Name Enhancement** - IMPLEMENTED! Enhanced Athletic Director profile to properly distinguish:
- **Full School Name**: "Edwardsville High School" (official records)
- **Schedule Name**: "Edwardsville" (appears on game schedules)  
- **Mascot**: "Tigers"
- **Generated Home Team**: "Edwardsville Tigers" (scheduleName + mascot)

### 🎛️ WORKING FLOW (Athletic Director Signup Complete ✅)
1. Welcome Screen → "Get Started"
2. Role Selection → "Scheduler"
3. Basic Profile → Email, password, name, phone
4. Scheduler Type → "Athletic Director"
5. School Info → School name, mascot, address (live preview working)
6. **CREATE ACCOUNT** → ✅ Firebase Auth + Firestore storage working
7. **Navigation to Dashboard** → ✅ Athletic Director home screen loads properly

### 🚧 IMMEDIATE NEXT STEPS
1. **BUILD**: Coach Signup Flow - Adapt Athletic Director pattern for coaches
2. **CREATE**: Coach Profile Screen - Sports focus, team management needs
3. **TEST**: Coach signup end-to-end workflow
4. **BUILD**: Assigner Signup Flow - Similar to Athletic Director pattern
5. **CREATE**: Official Signup Flow - Simpler profile for officials
6. **IMPLEMENT**: Sign-in screen for existing users (all user types)

## 📁 KEY FILES (V2.0 PROJECT STRUCTURE)

### Models & Services
- `lib/models/user_model.dart` - Complete user data structure
- `lib/services/auth_service.dart` - Firebase Auth integration  
- `lib/services/user_service.dart` - Firestore user operations

### Signup Flow Screens
- `lib/screens/auth/role_selection_screen.dart` ✅
- `lib/screens/auth/basic_profile_screen.dart` ✅  
- `lib/screens/auth/scheduler_type_screen.dart` ✅
- `lib/screens/auth/athletic_director_profile_screen.dart` ✅
- `lib/screens/home/athletic_director_home_screen.dart` ✅

### Documentation
- `docs/firebase-architecture.md` - Complete Firebase schema design
- `docs/user-schema-detailed.md` - User model specifications
- `docs/business-rules.md` - Data isolation and workflow rules
- `docs/implementation-status.md` - Current progress tracking

## 🎨 UI/UX NOTES
- Dark theme with yellow accent (Efficials branding)
- Scrollable screens for mobile compatibility
- Live preview features (home team name generation)
- Form validation with helpful error messages
- Loading states and success feedback

## 🗺️ FUTURE ROADMAP

### Phase 1: Complete Authentication (Current - Athletic Director Complete ✅)
- ✅ Athletic Director signup flow complete and tested
- 🔄 Coach signup flow (in progress)
- ⏳ Assigner signup flow (pending)
- ⏳ Official signup flow (pending)
- ⏳ Sign-in screen for existing users (pending)
- ⏳ Route guards for authenticated screens (pending)

### Phase 2: Core Game Management
- Sports, Locations, Schedules collections
- Game creation workflow with real-time updates  
- Templates system migration from v1.0

### Phase 3: Officials System
- Officials collection and list management
- Game claiming with atomic operations
- Assignment tracking and notifications

### Phase 4: Advanced Features  
- Game linking, multiple lists with quotas
- Offline sync queue implementation
- FCM push notifications

## 🧠 CONTEXT FOR CLAUDE
- **Primary Goal**: Complete all user signup flows and authentication system
- **Current Progress**: Athletic Director signup fully working and tested ✅
- **Next Focus**: Coach signup flow - adapt existing patterns for coaches
- **Success Metric**: All user types can signup → dashboard loads → data stored in Firestore
- **Architecture Status**: Solid foundation established, ready for expansion
- **Development Pattern**: Reuse Athletic Director flow structure for other user types

**V1.0 Reference**: `/mnt/c/Users/Efficials/efficials_app` - use for business logic understanding
**V2.0 Active**: `/mnt/c/Users/Efficials/efficials_v2` - clean Firebase implementation

## 💡 DEVELOPMENT APPROACH
- **Systematic & Documented** - Every decision captured in docs
- **Test-Driven** - Validate each feature works before moving on  
- **Firebase-First** - No SQLite legacy, pure Firebase patterns
- **Real-time Ready** - Built for collaboration from day one