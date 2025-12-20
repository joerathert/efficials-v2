import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'providers/theme_provider.dart';
import 'app_theme.dart';
import 'services/auth_service.dart';
import 'screens/auth/role_selection_screen.dart';
import 'screens/auth/basic_profile_screen.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/auth/official_profile_screen.dart';
import 'screens/auth/official_step2_screen.dart';
import 'screens/auth/official_step3_screen.dart';
import 'screens/auth/official_step4_screen.dart';
import 'screens/auth/scheduler_type_screen.dart';
import 'screens/auth/athletic_director_profile_screen.dart';
import 'screens/auth/coach_profile_screen.dart';
import 'screens/auth/assigner_profile_screen.dart';
import 'screens/home/athletic_director_home_screen.dart';
import 'screens/home/coach_home_screen.dart';
import 'screens/home/assigner_home_screen.dart';
import 'screens/home/official_home_screen.dart';
import 'screens/game_templates_screen.dart';
import 'screens/select_schedule_screen.dart';
import 'screens/select_sport_screen.dart';
import 'screens/dynamic_name_schedule_screen.dart';
import 'screens/date_time_screen.dart';
import 'screens/choose_location_screen.dart';
import 'screens/add_new_location_screen.dart';
import 'screens/additional_game_info_screen.dart';
import 'screens/additional_game_info_condensed_screen.dart';
import 'screens/additional_game_info_coach_screen.dart';
import 'screens/coach_calendar_screen.dart';
import 'screens/select_officials_screen.dart';
import 'screens/lists_of_officials_screen.dart';
import 'screens/multiple_lists_setup_screen.dart';
import 'screens/name_list_screen.dart';
import 'screens/populate_roster_screen.dart';
import 'screens/filter_settings_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/review_list_screen.dart';
import 'screens/edit_list_screen.dart';
import 'screens/review_game_info_screen.dart';
import 'screens/game_information_screen.dart';
import 'screens/official_game_details_screen.dart';
import 'screens/edit_game_info_screen.dart';
import 'screens/schedule_details_screen.dart';
import 'screens/create_game_template_screen.dart';
import 'screens/locations_screen.dart';
import 'screens/unpublished_games_screen.dart';
import 'screens/schedules/assigner_manage_schedules_screen.dart';
import 'screens/backout_notifications_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/official_profile_view_screen.dart';
import 'screens/view_official_profile_screen.dart';
import 'screens/admin/admin_panel_screen.dart';
import 'screens/admin/admin_user_search_screen.dart';
import 'screens/admin/admin_user_detail_screen.dart';
import 'screens/admin/admin_audit_log_screen.dart';
import 'screens/admin/admin_backouts_screen.dart';
import 'screens/bulk_import/bulk_import_preflight_screen.dart';
import 'screens/bulk_import/bulk_import_wizard_screen.dart';
import 'screens/bulk_import/bulk_import_generate_screen.dart';
import 'screens/bulk_import/bulk_import_upload_screen.dart';
import 'screens/bulk_import/bulk_import_preview_screen.dart';
import 'screens/select_crew_screen.dart';
import 'screens/filter_crews_screen.dart';
import 'screens/crew_dashboard_screen.dart';
import 'screens/create_crew_screen.dart';
import 'screens/crew_details_screen.dart';
import 'screens/crew_invitations_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase configuration is now handled directly in firebase_options.dart
  // Note: Using hardcoded config for web due to .env loading issues

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    if (!e.toString().contains('duplicate-app')) {
      rethrow; // Re-throw if it's not a duplicate app error
    }
    // If it's a duplicate app error, continue - Firebase is already initialized
  }
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  // Initialize theme provider and load saved theme preference
  final themeProvider = ThemeProvider();
  await themeProvider.loadThemeMode();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Efficials v2.0',
          theme: themeProvider.themeData,
          darkTheme: AppTheme.dark,
          themeMode: themeProvider.themeMode,
          initialRoute: '/auth',
          routes: {
            '/': (context) => const MyHomePage(),
            '/auth': (context) => const AuthWrapper(),
            '/sign-in': (context) => const SignInScreen(),
            '/role-selection': (context) => const RoleSelectionScreen(),
            '/basic-profile': (context) => const BasicProfileScreen(),
            '/scheduler-type': (context) => const SchedulerTypeScreen(),
            '/athletic-director-profile': (context) =>
                const AthleticDirectorProfileScreen(),
            '/athletic-director-home': (context) =>
                const AthleticDirectorHomeScreen(),
            // Add duplicate route for testing
            '/ad-home': (context) => const AthleticDirectorHomeScreen(),
            '/coach-home': (context) => const CoachHomeScreen(),
            '/coach-profile': (context) => const CoachProfileScreen(),
            '/assigner-profile': (context) => const AssignerProfileScreen(),
            '/assigner-home': (context) => const AssignerHomeScreen(),
            '/assigner_manage_schedules': (context) =>
                const AssignerManageSchedulesScreen(),
            '/official-profile': (context) => const OfficialProfileScreen(),
            '/official-profile-view': (context) =>
                const OfficialProfileViewScreen(),
            '/view-official-profile': (context) =>
                const ViewOfficialProfileScreen(),
            '/official-home': (context) => const OfficialHomeScreen(),
            '/official-step2': (context) => const OfficialStep2Screen(),
            '/official-step3': (context) => const OfficialStep3Screen(),
            '/official-step4': (context) => const OfficialStep4Screen(),
            '/game-templates': (context) => const GameTemplatesScreen(),
            '/select-schedule': (context) => const SelectScheduleScreen(),
            '/select-sport': (context) => const SelectSportScreen(),
            '/name-schedule': (context) => const DynamicNameScheduleScreen(),
            '/date-time': (context) => const DateTimeScreen(),
            '/choose-location': (context) => const ChooseLocationScreen(),
            '/add-new-location': (context) => const AddNewLocationScreen(),
            '/additional-game-info': (context) =>
                const AdditionalGameInfoScreen(),
            '/additional-game-info-condensed': (context) =>
                const AdditionalGameInfoCondensedScreen(),
            '/additional-game-info-coach': (context) =>
                const AdditionalGameInfoCoachScreen(),
            '/coach-calendar': (context) => const CoachCalendarScreen(),
            '/select-officials': (context) => const SelectOfficialsScreen(),
            '/lists-of-officials': (context) => const ListsOfOfficialsScreen(),
            '/multiple-lists-setup': (context) =>
                const MultipleListsSetupScreen(),
            '/name-list': (context) => const NameListScreen(),
            '/populate-roster': (context) => const PopulateRosterScreen(),
            '/filter-settings': (context) => const FilterSettingsScreen(),
            '/settings': (context) => const SettingsScreen(),
            '/review-list': (context) => const ReviewListScreen(),
            '/edit-list': (context) => const EditListScreen(),
            '/review-game-info': (context) => const ReviewGameInfoScreen(),
            '/game-information': (context) => const GameInformationScreen(),
            '/official-game-details': (context) =>
                const OfficialGameDetailsScreen(),
            '/edit_game_info': (context) => const EditGameInfoScreen(),
            '/schedule_details': (context) => const ScheduleDetailsScreen(),
            '/create_game_template': (context) =>
                const CreateGameTemplateScreen(),
            '/locations': (context) => LocationsScreen(),
            '/unpublished-games': (context) => const UnpublishedGamesScreen(),
            '/backout-notifications': (context) =>
                const BackoutNotificationsScreen(),
            '/notifications': (context) => const NotificationsScreen(),
            // Admin routes
            '/admin': (context) => const AdminPanelScreen(),
            '/admin/users': (context) => const AdminUserSearchScreen(),
            '/admin/officials': (context) =>
                const AdminUserSearchScreen(officialsOnly: true),
            '/admin/user-detail': (context) => const AdminUserDetailScreen(),
            '/admin/audit-log': (context) => const AdminAuditLogScreen(),
            '/admin/backouts': (context) => const AdminBackoutsScreen(),
            // Bulk Import routes
            '/bulk_import': (context) => const BulkImportPreflightScreen(),
            '/bulk_import_wizard': (context) => const BulkImportWizardScreen(),
            '/bulk_import_generate': (context) =>
                const BulkImportGenerateScreen(),
            '/bulk_import_upload': (context) => const BulkImportUploadScreen(),
            '/bulk_import_preview': (context) =>
                const BulkImportPreviewScreen(),
            '/select_crew_screen': (context) => const SelectCrewScreen(),
            '/filter_crews_settings': (context) => const FilterCrewsScreen(),
            // Crew routes
            '/crew_dashboard': (context) => CrewDashboardScreen(),
            '/create_crew': (context) => CreateCrewScreen(),
            '/crew_details': (context) => CrewDetailsScreen(),
            '/crew_invitations': (context) => CrewInvitationsScreen(),
          },
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isSigningIn = false;
  bool _hasResetNavigation = false;
  bool _showQuickAccess = false; // Start collapsed

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check if we're on a different route due to hot restart and reset if needed
    if (!_hasResetNavigation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final currentRoute = ModalRoute.of(context)?.settings.name;
          if (currentRoute != null && currentRoute != '/') {
            _hasResetNavigation = true;
            // Only reset if we're actually on a different route
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/', (route) => false);
          } else {
            _hasResetNavigation =
                true; // Still mark as done even if no reset needed
          }
        }
      });
    }
  }

  Future<void> _quickSignIn(
      BuildContext context, String email, String password, String route) async {
    if (_isSigningIn) return;

    setState(() {
      _isSigningIn = true;
    });

    try {
      final authService = AuthService();

      final result = await authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (mounted) {
        if (result.success && result.user != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '✅ Signed in as ${result.user!.profile.firstName} ${result.user!.profile.lastName}'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate to the appropriate home screen
          Navigator.pushNamedAndRemoveUntil(
            context,
            route,
            (route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('❌ Sign in failed: ${result.error ?? 'Unknown error'}'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSigningIn = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        title: Icon(
          Icons.sports,
          color: colorScheme.primary,
          size: 32,
        ),
        centerTitle: true,
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  color: colorScheme.onSurface,
                ),
                onPressed: () {
                  themeProvider.toggleTheme();
                },
                tooltip: 'Toggle theme',
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    kToolbarHeight -
                    MediaQuery.of(context).padding.top,
                maxWidth:
                    800, // Limit max width for better readability on wide screens
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Welcome to Efficials',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: theme.brightness == Brightness.dark
                          ? colorScheme.primary // Yellow in dark mode
                          : colorScheme.onBackground, // Dark in light mode
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sports Officials Scheduling Platform',
                    style: TextStyle(
                      fontSize: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Sign Up Button
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/role-selection');
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Get Started',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  const SizedBox(height: 16),

                  // Sign In Button (placeholder)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/sign-in');
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Quick Access Toggle (only in debug mode)
                  if (kDebugMode)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showQuickAccess = !_showQuickAccess;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 16),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: theme.brightness == Brightness.light
                              ? colorScheme
                                  .primary // Yellow background in light mode
                              : colorScheme.surfaceVariant
                                  .withOpacity(0.7), // Original in dark mode
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: colorScheme.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _showQuickAccess
                                  ? 'Hide Quick Access'
                                  : 'Quick Access',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.brightness == Brightness.light
                                    ? colorScheme
                                        .onPrimary // Black text in light mode
                                    : colorScheme
                                        .primary, // Yellow text in dark mode
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _showQuickAccess
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: theme.brightness == Brightness.light
                                  ? colorScheme
                                      .onPrimary // Black icon in light mode
                                  : colorScheme
                                      .primary, // Yellow icon in dark mode
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Expanded Quick Access Menu
                  if (kDebugMode && _showQuickAccess)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceVariant.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.outline.withOpacity(0.3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.shadow.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '⚡ Quick Access (Test Accounts)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Sign in instantly with predefined test accounts',
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _QuickAccessButton(
                              title: 'Athletic Director',
                              subtitle: 'Manage games & schedules',
                              email: 'bob.mayhew@efficials.com',
                              password: 'test123',
                              color: Colors.blue,
                              onTap: () => _quickSignIn(
                                  context,
                                  'bob.mayhew@efficials.com',
                                  'test123',
                                  '/athletic-director-home'),
                            ),
                            const SizedBox(height: 6),
                            _QuickAccessButton(
                              title: 'Coach',
                              subtitle: 'Request officials for games',
                              email: 'jarrod.frey@efficials.com',
                              password: 'test123',
                              color: Colors.green,
                              onTap: () => _quickSignIn(
                                  context,
                                  'jarrod.frey@efficials.com',
                                  'test123',
                                  '/coach-home'),
                            ),
                            const SizedBox(height: 6),
                            _QuickAccessButton(
                              title: 'Assigner',
                              subtitle: 'Assign officials to games',
                              email: 'jason.unverzagt@efficials.com',
                              password: 'test123',
                              color: Colors.purple,
                              onTap: () => _quickSignIn(
                                  context,
                                  'jason.unverzagt@efficials.com',
                                  'test123',
                                  '/assigner-home'),
                            ),
                            const SizedBox(height: 6),
                            _QuickAccessButton(
                              title: 'Official',
                              subtitle: 'View assigned games',
                              email: 'joe.rathert@efficials.com',
                              password: 'test123',
                              color: Colors.orange,
                              onTap: () => _quickSignIn(
                                  context,
                                  'joe.rathert@efficials.com',
                                  'test123',
                                  '/official-home'),
                            ),
                            const SizedBox(height: 6),
                            _QuickAccessButton(
                              title: 'Administrator',
                              subtitle: 'Manage users & system',
                              email: 'admin@efficials.com',
                              password: 'test123',
                              color: Colors.red,
                              onTap: () => _quickSignIn(
                                  context,
                                  'admin@efficials.com',
                                  'test123',
                                  '/athletic-director-home'), // Admin goes to AD home since they're an Athletic Director
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickAccessButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final String email;
  final String password;
  final Color color;
  final VoidCallback onTap;

  const _QuickAccessButton({
    required this.title,
    required this.subtitle,
    required this.email,
    required this.password,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          // User is signed in, navigate to appropriate home screen
          return FutureBuilder<Map<String, dynamic>?>(
            future: _getUserProfile(snapshot.data!.uid),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (userSnapshot.hasData && userSnapshot.data != null) {
                final userData = userSnapshot.data!;
                final userType = userData['role']; // Field name in Firestore
                final schedulerProfile =
                    userData['schedulerProfile'] as Map<String, dynamic>?;
                final schedulerType =
                    schedulerProfile?['type']; // Nested in schedulerProfile

                // Use post-frame callback to navigate after build is complete
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && context.mounted) {
                    String routeName;
                    switch (userType) {
                      case 'scheduler':
                        switch (schedulerType) {
                          case 'Athletic Director': // Exact string from Firestore
                            routeName = '/athletic-director-home';
                            break;
                          case 'Coach':
                            routeName = '/coach-home';
                            break;
                          case 'Assigner':
                            routeName = '/assigner-home';
                            break;
                          default:
                            routeName = '/'; // Fallback to welcome screen
                            break;
                        }
                        break;
                      case 'official':
                        // Check if official has completed registration
                        if (userData['officialProfile'] != null) {
                          routeName = '/official-home';
                        } else {
                          routeName = '/official-profile';
                        }
                        break;
                      default:
                        routeName = '/'; // Fallback to welcome screen
                        break;
                    }

                    Navigator.of(context).pushNamedAndRemoveUntil(
                      routeName,
                      (route) => false,
                    );
                  }
                });

                // Return loading screen while navigation happens
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              // If we can't get user profile, show welcome screen
              return const MyHomePage();
            },
          );
        } else {
          // User is not signed in, show welcome screen
          return const MyHomePage();
        }
      },
    );
  }

  Future<Map<String, dynamic>?> _getUserProfile(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists && doc.data() != null) {
        return doc.data();
      }
    } catch (e) {
      // Log error in development/debug mode only
      if (kDebugMode) {
        print('AuthWrapper: Error getting user profile: $e');
      }
    }
    return null;
  }
}
