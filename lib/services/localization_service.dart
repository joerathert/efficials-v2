import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'base_service.dart';

/// Supported languages in the app
enum SupportedLanguage {
  english('en', 'English', '🇺🇸'),
  spanish('es', 'Español', '🇪🇸'),
  french('fr', 'Français', '🇫🇷');

  const SupportedLanguage(this.code, this.name, this.flag);
  final String code;
  final String name;
  final String flag;
}

/// Comprehensive localization service for managing app strings
class LocalizationService extends BaseService {
  static final LocalizationService _instance = LocalizationService._internal();
  LocalizationService._internal();
  factory LocalizationService() => _instance;

  static const String _stringsPrefix = 'app_strings_';
  static const String _defaultLanguage = 'en';

  // Current language and strings cache
  String _currentLanguage = _defaultLanguage;
  Map<String, String> _strings = {};
  bool _isInitialized = false;

  /// Initialize the localization service
  Future<void> initialize([String languageCode = _defaultLanguage]) async {
    if (_isInitialized && _currentLanguage == languageCode) return;

    _currentLanguage = languageCode;

    try {
      // Load strings from assets
      final jsonString = await rootBundle.loadString(
        'assets/localization/${languageCode}.json',
      );
      final Map<String, dynamic> jsonMap = json.decode(jsonString);

      // Flatten nested structure into dot-notation keys
      _strings = _flattenJson(jsonMap);

      _isInitialized = true;
      debugPrint('Localization initialized for language: $languageCode');
    } catch (e) {
      debugPrint('Failed to load localization for $languageCode: $e');

      // Fallback to English if loading fails
      if (languageCode != _defaultLanguage) {
        await initialize(_defaultLanguage);
      } else {
        // Use hardcoded English strings as final fallback
        _strings = _getFallbackStrings();
        _isInitialized = true;
      }
    }
  }

  /// Get localized string by key
  String getString(String key, [Map<String, String>? args]) {
    if (!_isInitialized) {
      debugPrint('Warning: LocalizationService not initialized');
      return key;
    }

    String? result = _strings[key];

    if (result == null) {
      debugPrint('Warning: Missing localization key: $key');
      return key;
    }

    // Replace placeholders if arguments provided
    if (args != null) {
      args.forEach((placeholder, value) {
        result = result!.replaceAll('{$placeholder}', value);
      });
    }

    return result!;
  }

  /// Get current language code
  String get currentLanguage => _currentLanguage;

  /// Get available languages
  List<SupportedLanguage> get supportedLanguages => SupportedLanguage.values;

  /// Change language
  Future<void> setLanguage(String languageCode) async {
    await initialize(languageCode);
  }

  /// Check if a language is supported
  bool isLanguageSupported(String languageCode) {
    return SupportedLanguage.values.any((lang) => lang.code == languageCode);
  }

  /// Get language name by code
  String getLanguageName(String languageCode) {
    final language = SupportedLanguage.values
        .firstWhere((lang) => lang.code == languageCode);
    return language.name;
  }

  /// Get language flag by code
  String getLanguageFlag(String languageCode) {
    final language = SupportedLanguage.values
        .firstWhere((lang) => lang.code == languageCode);
    return language.flag;
  }

  /// Flatten nested JSON structure into dot-notation keys
  Map<String, String> _flattenJson(Map<String, dynamic> json, [String prefix = '']) {
    final Map<String, String> result = {};

    json.forEach((key, value) {
      final newKey = prefix.isEmpty ? key : '$prefix.$key';

      if (value is Map<String, dynamic>) {
        result.addAll(_flattenJson(value, newKey));
      } else {
        result[newKey] = value.toString();
      }
    });

    return result;
  }

  /// Fallback English strings when localization files are unavailable
  Map<String, String> _getFallbackStrings() {
    return {
      // Navigation
      'nav.home': 'Home',
      'nav.games': 'Games',
      'nav.officials': 'Officials',
      'nav.settings': 'Settings',

      // Common Actions
      'action.continue': 'Continue',
      'action.cancel': 'Cancel',
      'action.save': 'Save',
      'action.delete': 'Delete',
      'action.edit': 'Edit',
      'action.create': 'Create',
      'action.submit': 'Submit',
      'action.back': 'Back',
      'action.next': 'Next',
      'action.previous': 'Previous',
      'action.close': 'Close',
      'action.confirm': 'Confirm',

      // Authentication
      'auth.signIn': 'Sign In',
      'auth.signOut': 'Sign Out',
      'auth.signUp': 'Sign Up',
      'auth.forgotPassword': 'Forgot Password?',
      'auth.email': 'Email',
      'auth.password': 'Password',
      'auth.confirmPassword': 'Confirm Password',
      'auth.firstName': 'First Name',
      'auth.lastName': 'Last Name',
      'auth.phone': 'Phone',
      'auth.role': 'Role',

      // Games
      'games.title': 'Games',
      'games.createGame': 'Create Game',
      'games.editGame': 'Edit Game',
      'games.deleteGame': 'Delete Game',
      'games.gameDetails': 'Game Details',
      'games.sport': 'Sport',
      'games.date': 'Date',
      'games.time': 'Time',
      'games.location': 'Location',
      'games.opponent': 'Opponent',
      'games.officialsRequired': 'Officials Required',
      'games.officialsHired': 'Officials Hired',
      'games.status': 'Status',
      'games.upcoming': 'Upcoming Games',
      'games.past': 'Past Games',

      // Officials
      'officials.title': 'Officials',
      'officials.addOfficial': 'Add Official',
      'officials.editOfficial': 'Edit Official',
      'officials.deleteOfficial': 'Delete Official',
      'officials.availability': 'Availability',
      'officials.experience': 'Experience',
      'officials.certification': 'Certification',
      'officials.contactInfo': 'Contact Information',

      // Settings
      'settings.title': 'Settings',
      'settings.language': 'Language',
      'settings.theme': 'Theme',
      'settings.notifications': 'Notifications',
      'settings.privacy': 'Privacy',
      'settings.help': 'Help',
      'settings.about': 'About',

      // Error Messages
      'error.general': 'An error occurred. Please try again.',
      'error.network': 'Network error. Please check your connection.',
      'error.validation': 'Please check your input and try again.',
      'error.authentication': 'Authentication failed. Please sign in again.',
      'error.permission': 'You do not have permission to perform this action.',
      'error.notFound': 'The requested item was not found.',

      // Success Messages
      'success.saved': 'Changes saved successfully.',
      'success.deleted': 'Item deleted successfully.',
      'success.created': 'Item created successfully.',
      'success.updated': 'Item updated successfully.',

      // Validation Messages
      'validation.required': 'This field is required.',
      'validation.email': 'Please enter a valid email address.',
      'validation.password': 'Password must be at least 6 characters.',
      'validation.passwordMismatch': 'Passwords do not match.',
      'validation.phone': 'Please enter a valid phone number.',

      // Dialogs
      'dialog.confirmDelete': 'Are you sure you want to delete this item?',
      'dialog.unsavedChanges': 'You have unsaved changes. Do you want to save them?',
      'dialog.signOut': 'Are you sure you want to sign out?',

      // Sports
      'sport.football': 'Football',
      'sport.basketball': 'Basketball',
      'sport.baseball': 'Baseball',
      'sport.softball': 'Softball',
      'sport.soccer': 'Soccer',
      'sport.volleyball': 'Volleyball',
      'sport.tennis': 'Tennis',
      'sport.track': 'Track & Field',
      'sport.crossCountry': 'Cross Country',
      'sport.swimming': 'Swimming',
      'sport.wrestling': 'Wrestling',
      'sport.golf': 'Golf',

      // Roles
      'role.athleticDirector': 'Athletic Director',
      'role.scheduler': 'Scheduler',
      'role.official': 'Official',

      // Status
      'status.active': 'Active',
      'status.inactive': 'Inactive',
      'status.pending': 'Pending',
      'status.completed': 'Completed',
      'status.cancelled': 'Cancelled',
    };
  }

  // Convenience methods for commonly used strings

  String get home => getString('nav.home');
  String get games => getString('nav.games');
  String get officials => getString('nav.officials');
  String get settings => getString('nav.settings');

  String get continueText => getString('action.continue');
  String get cancel => getString('action.cancel');
  String get save => getString('action.save');
  String get delete => getString('action.delete');

  String get createGame => getString('games.createGame');
  String get editGame => getString('games.editGame');
  String get gameDetails => getString('games.gameDetails');

  String get sport => getString('games.sport');
  String get date => getString('games.date');
  String get time => getString('games.time');
  String get location => getString('games.location');
  String get opponent => getString('games.opponent');

  String officialsRequired([int? count]) =>
      count != null ? getString('games.officialsRequired') + ' ($count)' : getString('games.officialsRequired');

  String officialsHired([int? count]) =>
      count != null ? getString('games.officialsHired') + ' ($count)' : getString('games.officialsHired');

  String get upcomingGames => getString('games.upcoming');
  String get pastGames => getString('games.past');

  // Date and time formatting with localization
  String formatDate(DateTime date) {
    return DateFormat.yMMMd(_currentLanguage).format(date);
  }

  String formatDateTime(DateTime dateTime) {
    return DateFormat.yMMMd(_currentLanguage).add_jm().format(dateTime);
  }

  String formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dateTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat.jm(_currentLanguage).format(dateTime);
  }

  String formatCurrency(double amount) {
    return NumberFormat.currency(locale: _currentLanguage, symbol: '\$').format(amount);
  }

  String formatNumber(int number) {
    return NumberFormat.decimalPattern(_currentLanguage).format(number);
  }
}
