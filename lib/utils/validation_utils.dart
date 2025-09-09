/// Utility functions for form validation
class ValidationUtils {
  static const int minPasswordLength = 8;
  static const int maxNameLength = 100;
  static const int maxDescriptionLength = 500;

  /// Validate email format
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  /// Validate password strength
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < minPasswordLength) {
      return 'Password must be at least $minPasswordLength characters long';
    }

    // Check for at least one uppercase letter
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }

    // Check for at least one lowercase letter
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }

    // Check for at least one number
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }

    return null;
  }

  /// Validate password confirmation
  static String? validatePasswordConfirmation(
      String? value, String? originalPassword) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != originalPassword) {
      return 'Passwords do not match';
    }

    return null;
  }

  /// Validate required text field
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validate text length
  static String? validateLength(
      String? value, String fieldName, int maxLength) {
    if (value != null && value.length > maxLength) {
      return '$fieldName cannot exceed $maxLength characters';
    }
    return null;
  }

  /// Validate phone number format
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Phone is optional in many cases
    }

    // Remove all non-digit characters for validation
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.length != 10) {
      return 'Please enter a valid 10-digit phone number';
    }

    return null;
  }

  /// Validate ZIP code format
  static String? validateZipCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'ZIP code is required';
    }

    final zipRegex = RegExp(r'^\d{5}(-\d{4})?$');
    if (!zipRegex.hasMatch(value)) {
      return 'Please enter a valid ZIP code (e.g., 12345 or 12345-6789)';
    }

    return null;
  }

  /// Validate name fields
  static String? validateName(String? value, String fieldName) {
    final required = validateRequired(value, fieldName);
    if (required != null) return required;

    final length = validateLength(value, fieldName, maxNameLength);
    if (length != null) return length;

    // Check for valid characters (letters, spaces, hyphens, apostrophes)
    final nameRegex = RegExp(r"^[a-zA-Z\s\-']+$");
    if (value != null && !nameRegex.hasMatch(value)) {
      return '$fieldName can only contain letters, spaces, hyphens, and apostrophes';
    }

    return null;
  }

  /// Validate description field
  static String? validateDescription(String? value) {
    return validateLength(value, 'Description', maxDescriptionLength);
  }

  /// Validate positive number
  static String? validatePositiveNumber(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    final number = int.tryParse(value);
    if (number == null) {
      return '$fieldName must be a valid number';
    }

    if (number <= 0) {
      return '$fieldName must be greater than 0';
    }

    return null;
  }

  /// Validate range
  static String? validateRange(int? value, String fieldName, int min, int max) {
    if (value == null) {
      return '$fieldName is required';
    }

    if (value < min || value > max) {
      return '$fieldName must be between $min and $max';
    }

    return null;
  }

  /// Validate selection from list
  static String? validateSelection(
      String? value, List<String> options, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Please select a $fieldName';
    }

    if (!options.contains(value)) {
      return 'Please select a valid $fieldName';
    }

    return null;
  }
}

