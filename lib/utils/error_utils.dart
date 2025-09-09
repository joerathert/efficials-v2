import 'package:flutter/material.dart';
import '../services/base_service.dart';

/// Utility functions for error handling and display
class ErrorUtils {
  /// Show a snackbar with an error message
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Show a success snackbar
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show an info snackbar
  static void showInfoSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Handle service exceptions with appropriate user feedback
  static void handleServiceError(BuildContext context, dynamic error) {
    String message = 'An unexpected error occurred';

    if (error is ServiceException) {
      message = error.message;
    } else if (error is Exception) {
      message = error.toString().replaceFirst('Exception: ', '');
    } else if (error is String) {
      message = error;
    }

    showErrorSnackBar(context, message);
  }

  /// Handle Firebase exceptions with user-friendly messages
  static void handleFirebaseError(BuildContext context, dynamic error) {
    String message = 'A database error occurred';

    if (error.toString().contains('permission-denied')) {
      message = 'You don\'t have permission to perform this action';
    } else if (error.toString().contains('not-found')) {
      message = 'The requested item was not found';
    } else if (error.toString().contains('already-exists')) {
      message = 'This item already exists';
    } else if (error.toString().contains('unauthenticated')) {
      message = 'Please sign in to continue';
    } else if (error.toString().contains('network-request-failed')) {
      message = 'Network error. Please check your connection';
    }

    showErrorSnackBar(context, message);
  }

  /// Show a confirmation dialog
  static Future<bool?> showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    Color? confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: confirmColor != null
                ? TextButton.styleFrom(foregroundColor: confirmColor)
                : null,
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  /// Show an error dialog
  static Future<void> showErrorDialog({
    required BuildContext context,
    required String title,
    required String message,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show a loading dialog
  static Future<void> showLoadingDialog({
    required BuildContext context,
    required String message,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  /// Hide the current loading dialog
  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
  }
}

/// Extension methods for easier error handling
extension ErrorHandlingExtensions on BuildContext {
  /// Show error snackbar
  void showError(String message) {
    ErrorUtils.showErrorSnackBar(this, message);
  }

  /// Show success snackbar
  void showSuccess(String message) {
    ErrorUtils.showSuccessSnackBar(this, message);
  }

  /// Show info snackbar
  void showInfo(String message) {
    ErrorUtils.showInfoSnackBar(this, message);
  }

  /// Handle service error
  void handleServiceError(dynamic error) {
    ErrorUtils.handleServiceError(this, error);
  }

  /// Handle Firebase error
  void handleFirebaseError(dynamic error) {
    ErrorUtils.handleFirebaseError(this, error);
  }

  /// Show confirmation dialog
  Future<bool?> showConfirmation({
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    Color? confirmColor,
  }) {
    return ErrorUtils.showConfirmationDialog(
      context: this,
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      confirmColor: confirmColor,
    );
  }
}

