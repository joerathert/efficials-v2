import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'providers/theme_provider.dart';
import 'app_theme.dart';
import 'services/auth_service.dart';
import 'screens/auth/role_selection_screen.dart';
import 'screens/auth/basic_profile_screen.dart';
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
import 'screens/game_templates_screen.dart';
import 'screens/select_schedule_screen.dart';
import 'screens/select_sport_screen.dart';
import 'screens/name_schedule_screen.dart';
import 'screens/date_time_screen.dart';
import 'screens/choose_location_screen.dart';
import 'screens/add_new_location_screen.dart';
import 'screens/additional_game_info_screen.dart';
import 'screens/additional_game_info_condensed_screen.dart';
import 'screens/select_officials_screen.dart';
import 'screens/lists_of_officials_screen.dart';
import 'screens/name_list_screen.dart';
import 'screens/populate_roster_screen.dart';
import 'screens/filter_settings_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/review_list_screen.dart';
import 'screens/review_game_info_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

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
          home: const MyHomePage(),
          routes: {
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
            '/official-profile': (context) => const OfficialProfileScreen(),
            '/official-step2': (context) => const OfficialStep2Screen(),
            '/official-step3': (context) => const OfficialStep3Screen(),
            '/official-step4': (context) => const OfficialStep4Screen(),
            '/game-templates': (context) => const GameTemplatesScreen(),
            '/select-schedule': (context) => const SelectScheduleScreen(),
            '/select-sport': (context) => const SelectSportScreen(),
            '/name-schedule': (context) => const NameScheduleScreen(),
            '/date-time': (context) => const DateTimeScreen(),
            '/choose-location': (context) => const ChooseLocationScreen(),
            '/add-new-location': (context) => const AddNewLocationScreen(),
            '/additional-game-info': (context) =>
                const AdditionalGameInfoScreen(),
            '/additional-game-info-condensed': (context) =>
                const AdditionalGameInfoCondensedScreen(),
            '/select-officials': (context) => const SelectOfficialsScreen(),
            '/lists-of-officials': (context) => const ListsOfOfficialsScreen(),
            '/name-list': (context) => const NameListScreen(),
            '/populate-roster': (context) => const PopulateRosterScreen(),
            '/filter-settings': (context) => const FilterSettingsScreen(),
            '/settings': (context) => const SettingsScreen(),
            '/review-list': (context) => const ReviewListScreen(),
            '/review-game-info': (context) => const ReviewGameInfoScreen(),
            // TODO: Add other routes as we create them
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
              content: Text('Signed in as ${result.user!.profile.firstName}'),
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
              content: Text(result.error ?? 'Sign in failed'),
              backgroundColor: Colors.red,
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
        title: Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return Icon(
              Icons.sports,
              color: themeProvider.isDarkMode
                  ? colorScheme.primary // Yellow in dark mode
                  : Colors.black, // Black in light mode
              size: 32,
            );
          },
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
                    'Welcome to Efficials v2.0',
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

                  // Quick Access for Development/Testing
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: SizedBox(
                      width: double.infinity,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceVariant.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.outline.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quick Access (Development)',
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
                              email: 'ad.test@efficials.com',
                              password: 'test123456',
                              color: Colors.blue,
                              onTap: () => _quickSignIn(
                                  context,
                                  'ad.test@efficials.com',
                                  'test123456',
                                  '/athletic-director-home'),
                            ),
                            const SizedBox(height: 6),
                            _QuickAccessButton(
                              title: 'Coach',
                              subtitle: 'Request officials for games',
                              email: 'coach.test@efficials.com',
                              password: 'test123456',
                              color: Colors.green,
                              onTap: () => _quickSignIn(
                                  context,
                                  'coach.test@efficials.com',
                                  'test123456',
                                  '/coach-home'),
                            ),
                            const SizedBox(height: 6),
                            _QuickAccessButton(
                              title: 'Assigner',
                              subtitle: 'Assign officials to games',
                              email: 'assigner.test@efficials.com',
                              password: 'test123456',
                              color: Colors.purple,
                              onTap: () => _quickSignIn(
                                  context,
                                  'assigner.test@efficials.com',
                                  'test123456',
                                  '/assigner-home'),
                            ),
                            const SizedBox(height: 6),
                            _QuickAccessButton(
                              title: 'Official',
                              subtitle: 'View assigned games',
                              email: 'official.test@efficials.com',
                              password: 'test123456',
                              color: Colors.orange,
                              onTap: () => _quickSignIn(
                                  context,
                                  'official.test@efficials.com',
                                  'test123456',
                                  '/official-profile'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Sign In Button (placeholder)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: Navigate to sign in screen
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Sign In - Coming Soon!')),
                          );
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

                  Text(
                    'Firebase Initialized & Ready!',
                    style: TextStyle(
                      color: colorScheme
                          .onBackground, // Proper contrast instead of yellow
                      fontSize: 14,
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
