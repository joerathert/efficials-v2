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
5. **Coach Signup Flow** - Complete 5-screen flow with advanced features ✅
6. **Firebase Integration** - User creation, profile storage, real-time sync ✅
7. **Advanced Theme System** - Light/dark mode with theme-aware components ✅
8. **Universal Design System** - Complete style guide with patterns and templates ✅
9. **Sophisticated Card Styling** - Theme-aware cards with optimal contrast ✅
10. **End-to-End Testing** - Both Athletic Director & Coach signup flows tested ✅

### ✅ RECENT FIXES COMPLETED

**Theme System & Design System Implementation** - MAJOR UI/UX ENHANCEMENT:
- **Complete Theme System**: Implemented light/dark mode support with automatic theme switching
- **Theme Provider**: Created centralized theme management with persistent user preferences
- **Theme-Aware Components**: All UI elements now adapt to light/dark mode automatically
- **Logo Theming**: App bar logos change color based on theme (black in light, yellow in dark)

**Advanced Card Styling System** - SOPHISTICATED UI COMPONENTS:
- **Theme-Aware Card Design**: Cards automatically adapt styling based on light/dark mode
- **Light Mode**: Light gray backgrounds with black borders for better contrast against white
- **Dark Mode**: Yellow accent backgrounds with black text/icons (original design preserved)
- **Interactive States**: Selected cards have enhanced shadows and borders
- **Icon Consistency**: All card icons remain black for clean appearance

**Universal Design System Documentation** - COMPREHENSIVE STYLE GUIDE:
- **Design System Guide**: Created `lib/design_system.md` with complete styling patterns
- **Screen Templates**: Created `lib/templates/screen_template.dart` for consistent new screen development
- **Design Checker**: Built `check_design_system.dart` to validate compliance with design rules
- **Pattern Library**: Documented card selection, app bar, and component patterns

**Hot Restart Issues Resolved** - CRITICAL FIXES FOR DEVELOPMENT WORKFLOW:
- **Environment File Creation**: Created `.env` file with Firebase configuration from `google-services.json`
- **Fixed FileNotFoundError**: Resolved `flutter_dotenv` package error during hot restart
- **Firebase Duplicate App Error**: Implemented try-catch error handling in `main.dart` to gracefully handle Firebase reinitialization during hot restart
- **Development Workflow**: Hot restart now works seamlessly without crashes

**Assigner Profile Screen Enhancement** - IMPROVED USER EXPERIENCE:
- **Clarified Address Purpose**: Changed "Home Address" to "Assignment Area Address" to better explain the geographic matching purpose
- **Better Instructions**: Added specific guidance: "Use your league office, school, or primary location where games are typically held"
- **Reduced Confusion**: Eliminated implication that personal home address is required for official matching

**Coach Signup Flow Complete** - IMPLEMENTED! Full Coach profile system with advanced features:
- **Team Setup Form**: Team name, sport, level of competition, gender
- **School Affiliation Toggle**: Smart switching between age-based (6U-18U, Adult) and school-based (3rd Grade-Varsity) levels
- **Dynamic Gender Options**: Adult teams get "Men/Women/Co-ed", youth get "Boys/Girls/Co-ed"
- **Address Collection**: "Where are your home games played?" for official distance calculations
- **Route Integration**: CoachHomeScreen created and properly routed
- **End-to-End Testing**: Account creation, Firestore storage, navigation all working

**Universal Design System** - ESTABLISHED! Consistent theming across all screens:
- **Dark Theme**: Grey[900] backgrounds with black app bars
- **Yellow Accents**: Efficials branding color for highlights and buttons
- **Form Consistency**: InputDecoration with white text, grey backgrounds, yellow focus
- **Text Selection**: Yellow cursor and selection colors
- **Icon Theming**: Proper contrast and visibility

**UI Polish & Accessibility** - COMPLETED! Fixed all text contrast issues:
- **Hint Text Colors**: All dropdown hints now white (was black) for proper visibility
- **Form Validation**: Helpful error messages with clear styling
- **Loading States**: Progress indicators during account creation
- **Success Feedback**: Green snackbars for successful operations

**School Name vs Schedule Name Enhancement** - IMPLEMENTED! Enhanced Athletic Director profile to properly distinguish:
- **Full School Name**: "Edwardsville High School" (official records)
- **Schedule Name**: "Edwardsville" (appears on game schedules)
- **Mascot**: "Tigers"
- **Generated Home Team**: "Edwardsville Tigers" (scheduleName + mascot)

**Firebase Package Compatibility Issue** - RESOLVED! Fixed Dart SDK constraint and Firebase package compatibility:
- Fixed Dart SDK constraint from `^3.9.0` to `^3.4.0` for Flutter 3.22.0 compatibility
- Downgraded flutter_lints to `^4.0.0`
- Updated Firebase packages to compatible versions
- Both Athletic Director and Coach signup flows now work end-to-end

### 🎛️ WORKING FLOWS (Athletic Director & Coach Signup Complete ✅)

#### Athletic Director Flow:
1. Welcome Screen → "Get Started"
2. Role Selection → "Scheduler"
3. Basic Profile → Email, password, name, phone
4. Scheduler Type → "Athletic Director"
5. School Info → School name, mascot, address (live preview working)
6. **CREATE ACCOUNT** → ✅ Firebase Auth + Firestore storage working
7. **Navigation to Dashboard** → ✅ Athletic Director home screen loads properly

#### Coach Flow:
1. Welcome Screen → "Get Started"
2. Role Selection → "Scheduler"
3. Basic Profile → Email, password, name, phone
4. Scheduler Type → "Coach"
5. Team Setup → Team name, sport, school affiliation toggle, address for distance
6. **CREATE ACCOUNT** → ✅ Firebase Auth + Firestore storage working
7. **Navigation to Dashboard** → ✅ Coach home screen loads properly

**Smart Features**: School affiliation toggle dynamically switches between age-based (6U-18U) and school-based (3rd Grade-Varsity) competition levels

### 🚧 IMMEDIATE NEXT STEPS
1. **BUILD**: Assigner Signup Flow - Adapt Athletic Director pattern for assigners
2. **CREATE**: Assigner Profile Screen - Organization focus, broader region management
3. **TEST**: Assigner signup end-to-end workflow
4. **BUILD**: Official Signup Flow - Simpler profile for officials
5. **CREATE**: Official Profile Screen - City, experience, certification levels
6. **IMPLEMENT**: Sign-in screen for existing users (all user types)
7. **ADD**: Route guards for authenticated screens (prevent unauthorized access)

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
- `lib/screens/auth/coach_profile_screen.dart` ✅
- `lib/screens/auth/assigner_profile_screen.dart` ✨ (Enhanced with UX improvements)
- `lib/screens/home/athletic_director_home_screen.dart` ✅
- `lib/screens/home/coach_home_screen.dart` ✅
- `lib/screens/home/assigner_home_screen.dart` ✅

### Documentation
- `docs/firebase-architecture.md` - Complete Firebase schema design
- `docs/user-schema-detailed.md` - User model specifications
- `docs/business-rules.md` - Data isolation and workflow rules
- `docs/implementation-status.md` - Current progress tracking
- `lib/design_system.md` - Complete UI/UX style guide and patterns
- `lib/templates/screen_template.dart` - Copy-paste template for consistent screens
- `check_design_system.dart` - Automated design compliance checker

## 🎨 UI/UX NOTES
- **Advanced Theme System**: Full light/dark mode support with automatic theme switching
- **Theme-Aware Components**: All UI elements adapt to current theme automatically
- **Intelligent Logo Theming**: Black logos in light mode, yellow logos in dark mode
- **Sophisticated Card Design**: Theme-aware cards with optimal contrast in both modes
- **Universal Design System**: Complete style guide with patterns, templates, and compliance checker
- Scrollable screens for mobile compatibility
- Live preview features (home team name generation)
- Form validation with helpful error messages
- Loading states and success feedback

### 🎨 ADVANCED THEME SYSTEM (Provider-based)
**Theme Architecture:**
- **Theme Provider**: Centralized theme management with persistent user preferences
- **Automatic Switching**: All components adapt to light/dark mode automatically
- **Theme-Aware Colors**: Dynamic color selection based on current brightness
- **Persistent Preferences**: User theme choice saved across app sessions

**Light Mode Configuration:**
- **Background**: White/light gray for optimal readability
- **Cards**: Light gray backgrounds with black borders for contrast
- **Text**: Black primary text, dark gray secondary text
- **Logos**: Black for maximum contrast against light backgrounds
- **Interactive Elements**: Black borders and text for selected states

**Dark Mode Configuration:**
- **Background**: Dark gray (`Colors.grey[900]`) for eye comfort
- **Cards**: Yellow accent backgrounds with black text/icons
- **Text**: White primary text, light gray secondary text
- **Logos**: Yellow for brand consistency against dark backgrounds
- **Interactive Elements**: Yellow accents for selected states

**Form Styling (Theme-Aware):**
- **Input Fields**: Adaptive backgrounds based on theme
- **Borders**: Theme-appropriate colors with yellow focus states
- **Hint Text**: Proper contrast in both light and dark modes
- **Cursor**: Yellow selection and cursor colors (consistent branding)

**Component Consistency:**
- **Buttons**: Yellow background with black text, rounded corners (theme-consistent)
- **Snackbars**: Green for success, red for errors
- **Icons**: Theme-appropriate colors with yellow for active states
- **Shadows**: Adaptive shadow colors for both light and dark modes

## 🗺️ FUTURE ROADMAP

### Phase 1: Complete Authentication (Current - Coach Complete ✅)
- ✅ Athletic Director signup flow complete and tested
- ✅ Coach signup flow complete and tested (with smart school affiliation toggle)
- ⏳ Assigner signup flow (next priority)
- ⏳ Official signup flow (pending)
- ⏳ Sign-in screen for existing users (pending)
- ⏳ Route guards for authenticated screens (pending)

**Current Progress**: 2/4 user types complete (50% of Phase 1)

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
- **Current Progress**: Athletic Director & Coach signup fully working and tested ✅
- **Development Environment**: Hot restart fully functional with proper Firebase error handling
- **Next Focus**: Assigner signup flow - adapt Athletic Director pattern for organization management
- **Success Metric**: All user types can signup → dashboard loads → data stored in Firestore
- **Architecture Status**: Solid foundation with established patterns and design system
- **Development Pattern**: Reuse Coach flow structure for remaining user types
- **Smart Features**: School affiliation toggle, dynamic form options, universal theming, UX clarity

**Key Achievements**:
- **Advanced Theme System**: Complete light/dark mode implementation with automatic switching
- **Intelligent Logo Theming**: Context-aware logo colors (black in light, yellow in dark)
- **Sophisticated Card Design**: Theme-aware cards with optimal contrast in both modes
- **Universal Design System**: Complete style guide with patterns, templates, and compliance checker
- **Dual Grade Systems**: Age-based (6U-18U) and school-based (3rd Grade-Varsity) competition levels
- **Form Polish**: Fixed all contrast issues, proper hint text colors, validation feedback
- **Route Architecture**: Complete navigation system with proper error handling
- **Hot Restart Stability**: Resolved Firebase and environment file issues for seamless development
- **UX Improvements**: Clearer address collection guidance for better user understanding

**V1.0 Reference**: `/mnt/c/Users/Efficials/efficials_app` - use for business logic understanding
**V2.0 Active**: `/mnt/c/Users/Efficials/efficials_v2` - clean Firebase implementation with advanced UX

## 💡 DEVELOPMENT APPROACH
- **Systematic & Documented** - Every decision captured in docs
- **Test-Driven** - Validate each feature works before moving on
- **Firebase-First** - No SQLite legacy, pure Firebase patterns
- **Real-time Ready** - Built for collaboration from day one
- **Stable Development** - Hot restart issues resolved for smooth workflow
- **User-Centric UX** - Clear communication and intuitive interfaces prioritized