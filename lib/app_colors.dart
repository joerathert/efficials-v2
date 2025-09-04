import 'package:flutter/material.dart';

/// Custom color scheme for the Efficials app
/// Supports both light and dark themes
class AppColors {
  // Primary brand colors
  static const Color primary = Color(0xFFFFD700); // Yellow/Gold
  static const Color primaryDark = Color(0xFFFFC107); // Slightly darker yellow

  // Light Theme Colors
  static const AppColorScheme light = AppColorScheme(
    background: Color(0xFFFAFAFA), // Very light grey
    surface: Color(0xFFFFFFFF), // Pure white
    surfaceVariant: Color(0xFFF5F5F5), // Light grey for cards
    onBackground: Color(0xFF1C1B1F), // Very dark grey for text on light bg
    onSurface: Color(0xFF1C1B1F), // Very dark grey for text on surfaces
    onSurfaceVariant: Color(0xFF49454F), // Medium grey for secondary text
    outline: Color(0xFF79747E), // Border color
    outlineVariant: Color(0xFFCAC4D0), // Lighter border
    shadow: Color(0xFF000000), // Black for shadows
    scrim: Color(0xFF000000), // Black for scrims
    inverseSurface: Color(0xFF2F2F2F), // Dark surface for contrast
    onInverseSurface: Color(0xFFF2F2F2), // Light text on dark surface
    inversePrimary: Color(0xFFE6C300), // Darker yellow for inverse
    surfaceTint: Color(0xFFFFD700), // Primary for surface tint
  );

  // Dark Theme Colors
  static const AppColorScheme dark = AppColorScheme(
    background: Color(0xFF121212), // Dark grey background
    surface: Color(0xFF1E1E1E), // Slightly lighter dark surface
    surfaceVariant: Color(0xFF2D2D2D), // Card background
    onBackground: Color(0xFFE6E1E5), // Light grey text on dark bg
    onSurface: Color(0xFFE6E1E5), // Light grey text on surfaces
    onSurfaceVariant: Color(0xFFCAC4D0), // Light grey for secondary text
    outline: Color(0xFF938F99), // Medium grey border
    outlineVariant: Color(0xFF49454F), // Darker border variant
    shadow: Color(0xFF000000), // Black for shadows
    scrim: Color(0xFF000000), // Black for scrims
    inverseSurface: Color(0xFFE6E1E5), // Light surface for contrast
    onInverseSurface: Color(0xFF2F2F2F), // Dark text on light surface
    inversePrimary: Color(0xFFFFE161), // Lighter yellow for inverse
    surfaceTint: Color(0xFFFFD700), // Primary for surface tint
  );

  // Common colors used across themes
  static const Color error = Color(0xFFD32F2F); // Red for errors
  static const Color onError = Color(0xFFFFFFFF); // White text on error
  static const Color success = Color(0xFF4CAF50); // Green for success
  static const Color warning = Color(0xFFFF9800); // Orange for warnings
}

/// Color scheme that matches Material Design 3 structure
class AppColorScheme {
  const AppColorScheme({
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.onBackground,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.outline,
    required this.outlineVariant,
    required this.shadow,
    required this.scrim,
    required this.inverseSurface,
    required this.onInverseSurface,
    required this.inversePrimary,
    required this.surfaceTint,
  });

  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color onBackground;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color outline;
  final Color outlineVariant;
  final Color shadow;
  final Color scrim;
  final Color inverseSurface;
  final Color onInverseSurface;
  final Color inversePrimary;
  final Color surfaceTint;
}
