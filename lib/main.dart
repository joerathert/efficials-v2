import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'providers/theme_provider.dart';
import 'app_theme.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Firebase with error handling for hot restart
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
            '/coach-home': (context) => const CoachHomeScreen(),
            '/coach-profile': (context) => const CoachProfileScreen(),
            '/assigner-profile': (context) => const AssignerProfileScreen(),
            '/assigner-home': (context) => const AssignerHomeScreen(),
            '/official-profile': (context) => const OfficialProfileScreen(),
            '/official-step2': (context) => const OfficialStep2Screen(),
            '/official-step3': (context) => const OfficialStep3Screen(),
            '/official-step4': (context) => const OfficialStep4Screen(),
            // TODO: Add other routes as we create them
          },
        );
      },
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
              SizedBox(
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

              const SizedBox(height: 16),

              // Sign In Button (placeholder)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Navigate to sign in screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sign In - Coming Soon!')),
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

              const SizedBox(height: 48),

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
    );
  }
}
