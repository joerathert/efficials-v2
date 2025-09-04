import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_theme.dart';

/// Provider for managing app theme (light/dark mode)
class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'theme_mode';

  /// Current theme mode
  ThemeMode _themeMode = ThemeMode.system;

  /// Get current theme mode
  ThemeMode get themeMode => _themeMode;

  /// Get current theme data based on mode and system preference
  ThemeData get themeData {
    switch (_themeMode) {
      case ThemeMode.light:
        return AppTheme.light;
      case ThemeMode.dark:
        return AppTheme.dark;
      case ThemeMode.system:
        // This will be handled by MaterialApp automatically
        // But we can provide a fallback
        return AppTheme.dark; // Default to dark for now
    }
  }

  /// Check if current theme is dark
  bool get isDarkMode {
    switch (_themeMode) {
      case ThemeMode.dark:
        return true;
      case ThemeMode.light:
        return false;
      case ThemeMode.system:
        // For system mode, we'll default to dark for consistency
        // In a real app, you'd check MediaQuery.platformBrightnessOf(context)
        return true;
    }
  }

  /// Toggle between light and dark mode
  void toggleTheme() {
    switch (_themeMode) {
      case ThemeMode.light:
        _themeMode = ThemeMode.dark;
        break;
      case ThemeMode.dark:
        _themeMode = ThemeMode.light;
        break;
      case ThemeMode.system:
        // If system, toggle to light
        _themeMode = ThemeMode.light;
        break;
    }
    _saveThemeMode();
    notifyListeners();
  }

  /// Set theme mode to light
  void setLightMode() {
    _themeMode = ThemeMode.light;
    _saveThemeMode();
    notifyListeners();
  }

  /// Set theme mode to dark
  void setDarkMode() {
    _themeMode = ThemeMode.dark;
    _saveThemeMode();
    notifyListeners();
  }

  /// Set theme mode to system (follow system preference)
  void setSystemMode() {
    _themeMode = ThemeMode.system;
    _saveThemeMode();
    notifyListeners();
  }

  /// Load theme mode from shared preferences
  Future<void> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString(_themeKey);

    if (savedMode != null) {
      switch (savedMode) {
        case 'light':
          _themeMode = ThemeMode.light;
          break;
        case 'dark':
          _themeMode = ThemeMode.dark;
          break;
        case 'system':
          _themeMode = ThemeMode.system;
          break;
        default:
          _themeMode = ThemeMode.system; // Default fallback
      }
    } else {
      // First time user - default to dark mode to match current design
      _themeMode = ThemeMode.dark;
      _saveThemeMode();
    }

    notifyListeners();
  }

  /// Save current theme mode to shared preferences
  Future<void> _saveThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    String modeString;

    switch (_themeMode) {
      case ThemeMode.light:
        modeString = 'light';
        break;
      case ThemeMode.dark:
        modeString = 'dark';
        break;
      case ThemeMode.system:
        modeString = 'system';
        break;
    }

    await prefs.setString(_themeKey, modeString);
  }

  /// Get theme mode as string for display purposes
  String get themeModeString {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  /// Get icon for current theme mode
  IconData get themeIcon {
    switch (_themeMode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }
}
