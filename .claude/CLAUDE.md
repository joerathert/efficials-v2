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
10. **Enhanced Visual Feedback** - Selected cards with `Colors.grey.shade400` backgrounds ✅
11. **Theme-Aware Typography** - Yellow titles in dark mode, black in light mode ✅
12. **Professional Card Design** - Consistent styling across all selection screens ✅
13. **End-to-End Testing** - Both Athletic Director & Coach signup flows tested ✅
14. **Official Registration Flow** - Complete 4-step signup process with Firebase integration ✅
15. **Test Officials Database** - 10 test officials loaded into Firestore with detailed sports data ✅
16. **Firebase Web Configuration** - Complete web deployment setup with proper environment variables ✅
17. **Responsive Web Design** - Narrow buttons and centered layout for web version ✅
18. **Game Creation Flow Foundation** - Athletic Director game creation screens implemented ✅
19. **ReviewGameInfoScreen Redesign** - Complete UI/UX overhaul matching v2.0 design patterns ✅

### ✅ RECENT FIXES COMPLETED

**REVIEW GAME INFO SCREEN REDESIGN** - COMPLETE UI/UX OVERHAUL:

#### 🎯 **Complete Screen Redesign & Layout Optimization**
- **Responsive Layout**: Implemented v2.0 design patterns with `ConstrainedBox(maxWidth: 430)` for optimal content width
- **Theme Integration**: Full theme-aware design with proper color scheme usage throughout
- **Professional Button Design**: Full-width buttons with `minimumSize: const Size(double.infinity, 56)` for better mobile UX
- **Column Spacing**: Optimized label-to-value spacing with `160px` labels and `16px` gap for clean text flow
- **Navigation Integration**: Seamless integration with existing game creation workflow

#### 🏗️ **Technical Implementation**
- **Screen Architecture**: Complete rewrite of `review_game_info_screen.dart` to match v2.0 patterns
- **Layout Structure**: `SafeArea` → `Center` → `SingleChildScrollView` → `Padding` → `ConstrainedBox` pattern
- **Theme Provider**: Integrated `Consumer<ThemeProvider>` for dynamic logo and color theming
- **Data Flow**: Proper argument handling with null safety and state management
- **Responsive Design**: Optimized for both mobile and web platforms

#### 🎨 **Advanced UI Features**
- **Theme-Aware App Bar**: Logo automatically switches between black (light mode) and yellow (dark mode)
- **Professional Card Layout**: Game details in `Container` with `surfaceVariant` background and proper shadows
- **Typography Hierarchy**: Clear distinction between title, labels, and values with theme-aware colors
- **Interactive Elements**: Properly styled buttons with loading states and error handling
- **Visual Consistency**: Matches design patterns from other v2.0 screens (SelectOfficials, etc.)

#### 📱 **Key User Experience Enhancements**
- **No Text Wrapping**: Optimized spacing ensures labels like "Officials Required" fit on single lines
- **Clear Visual Hierarchy**: Game details, selected officials, and action buttons clearly separated
- **Mobile-First Design**: Touch-friendly button sizes and spacing optimized for mobile interaction
- **Loading Feedback**: Proper loading indicators during publish operations
- **Error Handling**: User-friendly error messages for validation failures

#### 🔧 **Design System Compliance**
- **Pattern Consistency**: Follows established v2.0 screen template with `Center` + `ConstrainedBox` layout
- **Color Scheme Usage**: Uses `colorScheme.primary`, `colorScheme.onSurface`, etc. throughout
- **Shadow Standards**: Consistent `colorScheme.shadow.withOpacity(0.1)` for card shadows
- **Typography Rules**: No hardcoded yellow text, proper theme-aware text colors
- **Component Reuse**: Leverages existing button and card styling patterns

#### 📊 **Layout Optimization Results**
- **Width**: `430px` (balanced between mobile readability and web usability)
- **Label Width**: `160px` (wide enough for longest labels: "Competition Level", "Hire Automatically")
- **Gap**: `16px` (optimal visual separation between columns)
- **Button Height**: `56px` (touch-friendly minimum size)
- **Button Width**: Full width for mobile-first UX

**OFFICIAL REGISTRATION FLOW** - COMPLETE 4-STEP SIGNUP PROCESS:

#### 🎯 **Complete Official Signup Flow (4 Steps)**
- **Step 1**: Basic Information - Email, password, name, phone with validation
- **Step 2**: Location & Preferences - Address, travel distance, notification preferences
- **Step 3**: Sports & Certifications - Multi-sport selection with certification levels, experience tracking, and competition levels
- **Step 4**: Profile & Verification - Registration summary, rate setting, account creation

#### 🏗️ **Technical Implementation**
- **Screen Architecture**: `official_profile_screen.dart`, `official_step2_screen.dart`, `official_step3_screen.dart`, `official_step4_screen.dart`
- **Data Persistence**: Complete form state management across all steps
- **Firebase Integration**: Real Firestore saving with user authentication
- **Smart Navigation**: Seamless flow between steps with data preservation
- **Form Validation**: Comprehensive validation for all required fields

#### 🎨 **Advanced UI Features**
- **Theme-Aware Design**: Full light/dark mode support with proper color schemes
- **Responsive Layout**: Optimized for different screen sizes
- **Interactive Sport Cards**: Dynamic sport configuration with dropdowns and filter chips
- **Professional Form Styling**: Consistent input fields with proper theming
- **Loading States**: Smooth user feedback during account creation process

#### 📱 **Key User Experience Enhancements**
- **Multi-Sport Support**: Officials can register for multiple sports with individual certifications
- **Flexible Competition Levels**: Filter chips for grade school through adult competitions
- **Experience Tracking**: Years of experience per sport with validation
- **Rate Setting**: Optional rate per game with proper formatting
- **Registration Summary**: Complete overview before account creation

#### 🔧 **Data Management Features**
- **Smart Calculations**: Automatic highest certification and max experience aggregation
- **Firestore Integration**: Complete user profile storage with all collected data
- **Error Handling**: Comprehensive error messages and user feedback
- **Account Creation**: Firebase Auth + Firestore user document creation

#### 🛠️ **Development Fixes & UI Polish**
- **Layout Optimization**: Fixed ListView.builder rendering issues by switching to Column mapping
- **Form Field Consistency**: Matched font sizes between Certification Level and Years of Experience fields
- **State Label Fix**: Resolved ST label visibility issues with proper hint styling
- **ZIP Field Width**: Increased ZIP field width for better number display
- **Height Alignment**: Ensured all address fields have uniform height
- **Add Sport UX**: Added "Add Another Sport" button at bottom for better user flow
- **Sports Filtering**: Limited to same 6 sports as coach profile for consistency
- **Navigation Flow**: Seamless step transitions with data preservation

#### 🔧 **Critical Navigation Flow Fixes**
- **Data Persistence Issue**: Fixed Step 3/4 navigation where previously added sports disappeared
- **Dialog Width Issue**: Added `ConstrainedBox(maxWidth: 400)` to prevent full-width dialogs
- **Data Key Consistency**: Standardized `'competitionLevels'` vs `'levels'` across all screens
- **Null Safety**: Enhanced error handling for navigation arguments and data flow

**Theme System & Design System Implementation** - MAJOR UI/UX ENHANCEMENT:
- **Complete Theme System**: Implemented light/dark mode support with automatic theme switching
- **Theme Provider**: Created centralized theme management with persistent user preferences
- **Theme-Aware Components**: All UI elements now adapt to light/dark mode automatically
- **Logo Theming**: App bar logos change color based on theme (black in light, yellow in dark)

**Advanced Card Styling System** - SOPHISTICATED UI COMPONENTS:
- **Theme-Aware Card Design**: Cards automatically adapt styling based on light/dark mode
- **Light Mode**: Light gray backgrounds (`Colors.grey.shade50`) with black borders for better contrast against white
- **Dark Mode**: Yellow accent backgrounds with black text/icons (original design preserved)
- **Interactive States**: Selected cards have enhanced shadows and borders, plus darker backgrounds (`Colors.grey.shade400`)
- **Icon Consistency**: All card icons remain black in light mode, yellow in dark mode for brand consistency
- **Enhanced Visual Feedback**: Selected cards have stronger shadows, darker backgrounds, and clearer visual hierarchy

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

**Scheduler Type Screen Card Design Refinement** - PERFECTED VISUAL HIERARCHY:
- **Theme-Aware Card Matching**: Updated "What Type of Scheduler Are You?" cards to match "Choose Your Role" screen design
- **Enhanced Selected State**: Selected cards now use `Colors.grey.shade400` background for maximum visual clarity
- **Theme-Appropriate Colors**: Black text/icons in light mode, yellow text/icons in dark mode for optimal contrast
- **Improved Visual Feedback**: Enhanced shadow depth and border thickness for selected cards
- **Professional Appearance**: Consistent styling across all card-based selection screens

**Design System Refinements** - ADVANCED UI POLISH:
- **Title Text Theming**: All screen titles now use yellow in dark mode, black in light mode for consistency
- **Icon Theming**: App bar icons, card icons, and interactive elements follow theme-aware color schemes
- **Form Field Enhancements**: Text box outlines change to black when selected in light mode for better UX
- **Background Contrast**: Form containers use `Colors.grey[300]` in light mode for clear visual separation
- **Typography Hierarchy**: Consistent text colors using `colorScheme.onSurfaceVariant` for secondary text

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

**Firebase Web Configuration & Responsive Design** - COMPLETE! Critical web deployment fixes:
- **Environment Variable Setup**: Created `.env` file with proper Firebase web API keys and configuration
- **Asset Declaration**: Added `.env` to `pubspec.yaml` assets for Flutter web deployment
- **UTF-8 Encoding Fix**: Resolved `FormatException` by ensuring proper file encoding
- **Responsive Layout**: Implemented `ConstrainedBox` and `LayoutBuilder` for web-specific button sizing
- **Centered Content**: Added proper centering for web layout while maintaining mobile responsiveness
- **Firebase Initialization**: Fixed web-specific Firebase initialization with correct API keys

**Athletic Director Game Creation Flow** - SIGNIFICANTLY EXPANDED:
- ✅ **Home Screen Updates**: Enhanced Athletic Director home screen with games list and FAB navigation
- ✅ **Template System**: Created game templates screen with sport grouping and management
- ✅ **Schedule Selection**: Implemented schedule selection screen with existing/new schedule options
- ✅ **Sport Selection**: Built sport selection screen for new schedule creation
- ✅ **Name Schedule Screen**: Complete schedule naming with Firebase integration and duplicate validation
- ✅ **Set Date & Time Screen**: Professional date/time picker with proper data flow
- ✅ **Choose Location Screen**: Location selection with "Away Game" and "Create new location" options
- ✅ **Add New Location Screen**: Complete location creation form with address validation
- ✅ **Firebase Integration**: Full schedule and game data persistence to Firestore
- ✅ **Navigation Flow**: Complete end-to-end flow from AD home → Choose Location → Add New Location
- ✅ **Layout Fixes**: Resolved RenderFlex overflow issues and blank screen problems
- ✅ **Error Handling**: Fixed ModalRoute access issues and proper lifecycle management

**Critical Lessons Learned - Firebase Web Configuration** - DOCUMENTED FOR FUTURE REFERENCE:

#### 🔴 **Firebase Web Initialization Issues (Major Lesson)**
**Problem**: Firebase initialization failures during web startup caused entire Flutter app to crash
**Root Cause**: Incorrect API keys, UTF-8 encoding issues in `.env` file, missing asset declarations
**Impact**: "Site can't be reached" errors, blank white screens, development workflow blocked
**Solution**: Proper Firebase web configuration with correct API keys, asset declarations, and encoding

#### 🔧 **Key Technical Lessons**
- **Firebase API Keys**: Web and mobile use different API keys - must be configured separately
- **Environment Files**: `.env` files must be UTF-8 encoded and declared as assets in `pubspec.yaml`
- **Flutter Web Sensitivity**: Web platform is more sensitive to Firebase configuration errors than mobile
- **Asset Loading**: All referenced files must be properly declared in `pubspec.yaml` assets section
- **Error Cascading**: Firebase failures can crash entire web app before UI loads

#### 🛠️ **Development Workflow Improvements**
- **Quick Access Testing**: Implemented one-click sign-in buttons for development testing
- **Responsive Design**: Web buttons now properly sized vs mobile (400px max width vs full width)
- **Layout Centering**: Content properly centered on web while maintaining mobile responsiveness
- **Port Management**: Established consistent port usage to avoid conflicts

#### 📝 **Future Prevention Measures**
- **Always verify Firebase web configuration** before web deployment
- **Test .env file encoding** and asset declarations during setup
- **Implement Firebase error handling** in main.dart to prevent app crashes
- **Document API key differences** between platforms for team reference
- **Use proper asset management** for all environment and configuration files

#### 🛠️ **Flutter Layout & Navigation Lessons**
- **ModalRoute Access**: Never call `ModalRoute.of(context)` in `initState()` - use `didChangeDependencies()` instead
- **RenderFlex Overflow**: Use `mainAxisSize: MainAxisSize.min` for inner containers to prevent unbounded height constraints
- **Spacer Replacement**: Replace `Spacer()` with `SizedBox(height: 40)` when layout constraints are tight
- **ConstrainedBox**: Use `ConstrainedBox` with `maxWidth: 400` for dropdowns to prevent overflow on wider screens
- **Navigation Guards**: Add `_argumentsFetched` flags to prevent multiple executions of argument parsing

#### 🔧 **CURRENT WEB ENGINE TROUBLESHOOTING (ACTIVE ISSUE)**
**Flutter Web Engine Errors During Hot Restart:**
- **Primary Symptoms**: "Cannot send Null" errors, assertion failures in `window.dart:99:12`
- **Impact**: Hot restart not working reliably, app loading on wrong screens, development workflow blocked
- **Root Causes Being Investigated**:
  - Browser cache conflicts with Flutter web engine state
  - Hot restart preserving navigation stack incorrectly
  - Flutter web engine receiving null values during state transitions
  - Development server state corruption after multiple hot restarts

**Troubleshooting Attempts:**
- ✅ Cleared browser cache and used incognito mode
- ✅ Killed all Dart processes before restart
- ✅ Implemented navigation reset logic in `main.dart` with `_hasResetNavigation` flag
- ✅ Used `Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false)` for hard reset
- ✅ Modified `MaterialApp` from `home` to `initialRoute: '/'` with explicit route definition
- ⚠️ **Current Status**: Still experiencing intermittent web engine errors and navigation issues

**Next Steps for Resolution:**
- Test alternative browsers (Edge, Firefox) to isolate Chrome-specific issues
- Implement more aggressive navigation stack clearing
- Add comprehensive error handling around Flutter web engine operations
- Consider browser cache clearing automation or alternative development workflow

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
1. ✅ **COMPLETED**: Official Registration Flow - 4-step process with Firebase integration
2. ✅ **COMPLETED**: Test Officials Database - 10 officials loaded with detailed sports data
3. ✅ **COMPLETED**: ReviewGameInfoScreen Redesign - Complete UI/UX overhaul with v2.0 patterns
4. 🔄 **NEXT PRIORITY**: Publish Game Button Functionality - Implement complete game publishing workflow
5. **CREATE**: Assigner & Coach Test Users - For comprehensive testing
6. **TEST**: Complete Game Publishing Workflow - From template to published game with notifications
7. **BUILD**: Additional Game Info Screens - Condensed vs full flow options
8. **IMPLEMENT**: Game Publishing to Database - Complete Firebase integration with real-time updates
9. **TEST**: Official Filtering & Selection - Using test officials data and distance calculations
10. **BUILD**: Assigner Signup Flow - Adapt Athletic Director pattern for assigners
11. **IMPLEMENT**: Sign-in screen for existing users (all user types)

## 📁 KEY FILES (V2.0 PROJECT STRUCTURE)

### Models & Services
- `lib/models/user_model.dart` - Complete user data structure
- `lib/models/game_template_model.dart` ✅ (Game template data structure)
- `lib/services/auth_service.dart` - Firebase Auth integration
- `lib/services/user_service.dart` - Firestore user operations
- `lib/services/game_service.dart` ✅ (Game and template management)

### Signup Flow Screens
- `lib/screens/auth/role_selection_screen.dart` ✅
- `lib/screens/auth/basic_profile_screen.dart` ✅
- `lib/screens/auth/scheduler_type_screen.dart` ✅
- `lib/screens/auth/athletic_director_profile_screen.dart` ✅
- `lib/screens/auth/coach_profile_screen.dart` ✅
- `lib/screens/auth/assigner_profile_screen.dart` ✨ (Enhanced with UX improvements)
- `lib/screens/home/athletic_director_home_screen.dart` ✅ ✨ (Enhanced with game creation FAB)
- `lib/screens/home/coach_home_screen.dart` ✅
- `lib/screens/home/assigner_home_screen.dart` ✅

### Game Creation Flow Screens (NEW)
- `lib/screens/game_templates_screen.dart` ✅ (Template management with sport grouping)
- `lib/screens/select_schedule_screen.dart` ✅ (Schedule selection with existing/new options)
- `lib/screens/select_sport_screen.dart` ✅ (Sport selection for new schedules)
- `lib/screens/name_schedule_screen.dart` ✅ (Schedule naming interface)
- `lib/screens/date_time_screen.dart` ✅ (Date and time selection with validation)
- `lib/screens/choose_location_screen.dart` ✅ (Location selection with create new option)
- `lib/screens/add_new_location_screen.dart` ✅ (Complete location creation form)

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
- **Cards**: Dark gray backgrounds (`Colors.grey[800]`) with yellow titles and icons for brand consistency
- **Text**: Yellow titles and primary elements, white/light gray secondary text for optimal readability
- **Logos**: Yellow for brand consistency against dark backgrounds
- **Interactive Elements**: Yellow accents, enhanced shadows, and darker backgrounds for selected states
- **Visual Hierarchy**: Yellow highlights draw attention while maintaining comfortable contrast ratios

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

**Current Progress**: 3/4 user types complete (75% of Phase 1) + Game Creation Flow Nearly Complete (8/8 screens implemented)

### Phase 2: Core Game Management (IN PROGRESS)
- ✅ **Athletic Director Game Creation Flow** - 8/8 screens implemented and navigable
- ✅ **Firebase Integration** - Schedule creation and naming with Firestore backend
- ✅ **Navigation Flow** - Complete end-to-end flow from AD home to location creation
- ⏳ **Game Creation Screen** - Final screen to actually create the game
- ⏳ **Complete Firebase Integration** - Games collection and full workflow
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
- **Primary Goal**: Complete game creation workflow and remaining authentication flows
- **Current Progress**: AD & Coach signup ✅, Official signup ✅, AD game creation foundation ✅
- **Design System Status**: Advanced theme system with sophisticated card styling completed ✅
- **Web Deployment Status**: Firebase web configuration complete with responsive design ✅
- **Development Environment**: ⚠️ **ACTIVE ISSUE** - Flutter web engine errors during hot restart (Cannot send Null, assertion failures)
- **Current Block**: Hot restart navigation issues - app not consistently loading Welcome screen after hot restart
- **Next Focus**: 🔴 **URGENT** - Resolve Flutter web engine errors and hot restart navigation problems
- **Success Metric**: Users can create complete games from templates or scratch → all data stored in Firestore with full validation
- **Architecture Status**: Solid foundation with established patterns and comprehensive documentation
- **Development Pattern**: Reuse established screen patterns for remaining flows
- **Smart Features**: Quick access testing, responsive web design, comprehensive error handling
- **Critical Lesson**: Firebase web configuration must be verified before deployment
- **Current Challenge**: Flutter web engine stability during hot restart and development workflow

**Key Achievements**:
- **Advanced Theme System**: Complete light/dark mode implementation with automatic switching
- **Intelligent Logo Theming**: Context-aware logo colors (black in light, yellow in dark)
- **Sophisticated Card Design**: Theme-aware cards with optimal contrast in both modes
- **Enhanced Visual Feedback**: Selected cards with `Colors.grey.shade400` backgrounds for maximum clarity
- **Theme-Aware Typography**: Yellow titles in dark mode, black titles in light mode for consistency
- **Professional Card Styling**: Consistent design across all selection screens with enhanced shadows
- **Universal Design System**: Complete style guide with patterns, templates, and compliance checker
- **Dual Grade Systems**: Age-based (6U-18U) and school-based (3rd Grade-Varsity) competition levels
- **Form Polish**: Fixed all contrast issues, proper hint text colors, validation feedback
- **Route Architecture**: Complete navigation system with proper error handling
- **Web Deployment Success**: Firebase web configuration working with proper responsive design
- **Complete Game Creation Flow**: 8-screen Athletic Director game creation workflow implemented
- **Firebase Schedule Integration**: Schedule creation and naming with duplicate validation
- **Layout Expertise**: Fixed RenderFlex overflow issues and blank screen problems
- **Navigation Fixes**: Resolved ModalRoute access issues and proper lifecycle management
- **Location Management**: Professional location creation form with address validation
- **Critical Lessons Documented**: Firebase web configuration pitfalls and Flutter layout best practices

**Current Development Status (Latest Session):**
- ✅ **Official Registration**: Complete 4-step flow with Firebase integration
- ✅ **Test Officials Database**: 10 officials loaded with detailed sports data per sport
- 🔄 **Active Focus**: AD Game Creation Flow testing with Populate Roster functionality
- ✅ **Navigation Flow**: Fixed Step 3/4 data persistence and dialog width issues
- ✅ **Data Structure**: Sports data now saved with experience, certification, competition levels per sport
- 📋 **Next Priority**: Test complete game publishing workflow from template to database
- 🎯 **Testing Ready**: All components in place for end-to-end game creation testing
- 🔧 **Remaining**: Create Assigner & Coach test users for comprehensive workflow testing

**V1.0 Reference**: `/mnt/c/Users/Efficials/efficials_app` - use for business logic understanding
**V2.0 Active**: `/mnt/c/Users/Efficials/efficials_v2` - clean Firebase implementation with advanced UX

## 💡 DEVELOPMENT APPROACH
- **Systematic & Documented** - Every decision captured in docs
- **Test-Driven** - Validate each feature works before moving on
- **Firebase-First** - No SQLite legacy, pure Firebase patterns
- **Real-time Ready** - Built for collaboration from day one
- **Stable Development** - Hot restart issues resolved for smooth workflow
- **User-Centric UX** - Clear communication and intuitive interfaces prioritized