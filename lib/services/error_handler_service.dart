import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../exceptions/app_exceptions.dart';

/// Centralized error handling service for consistent error management
class ErrorHandlerService {

  /// Convert Firebase exceptions to app-specific exceptions
  static AppException handleFirebaseException(dynamic error) {
    if (error is FirebaseAuthException) {
      return _handleAuthException(error);
    } else if (error is FirebaseException) {
      return _handleFirestoreException(error);
    } else {
      return PostFetchException(
        'An unexpected error occurred: $error',
      );
    }
  }

  /// Handle Firebase Auth exceptions
  static AppException _handleAuthException(FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
        return const AuthenticationFailedException(
          'No user found with this email.',
        );
      case 'wrong-password':
        return const AuthenticationFailedException('Incorrect password.');
      case 'email-already-in-use':
        return const AuthenticationFailedException(
          'Email is already registered.',
        );
      case 'weak-password':
        return const AuthenticationFailedException('Password is too weak.');
      case 'invalid-email':
        return const AuthenticationFailedException('Invalid email address.');
      case 'user-disabled':
        return const AuthenticationFailedException(
          'This account has been disabled.',
        );
      case 'too-many-requests':
        return const AuthenticationFailedException(
          'Too many attempts. Please try again later.',
        );
      case 'network-request-failed':
        return const NetworkUnavailableException();
      default:
        return AuthenticationFailedException(
          error.message ?? 'Authentication failed.',
        );
    }
  }

  /// Handle Firestore exceptions
  static AppException _handleFirestoreException(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return const UserNotAuthenticatedException();
      case 'unavailable':
        return const NetworkUnavailableException();
      case 'deadline-exceeded':
        return const TimeoutException();
      case 'not-found':
        return const PostFetchException('Content not found.');
      case 'already-exists':
        return const PostUploadException('Content already exists.');
      case 'resource-exhausted':
        return const PostUploadException('Storage quota exceeded.');
      default:
        return PostFetchException(error.message);
    }
  }

  /// Show user-friendly error message
  static void showErrorSnackBar(BuildContext context, AppException error) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                error.message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        action: _getRetryAction(context, error),
      ),
    );
  }

  /// Show success message
  static void showSuccessSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show warning message
  static void showWarningSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_outlined, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Get retry action for specific errors
  static SnackBarAction? _getRetryAction(
    BuildContext context,
    AppException error,
  ) {
    if (error is NetworkUnavailableException || error is TimeoutException) {
      return SnackBarAction(
        label: 'Retry',
        textColor: Colors.white,
        onPressed: () {
          // The calling code should implement retry logic
          // This is just a placeholder
        },
      );
    }
    return null;
  }

  /// Handle and show error in one call
  static void handleAndShowError(BuildContext context, dynamic error) {
    final appException = handleFirebaseException(error);
    showErrorSnackBar(context, appException);
  }

  /// Log error for debugging (in debug mode)
  static void logError(
    String context,
    dynamic error, [
    StackTrace? stackTrace,
  ]) {
    debugPrint('ERROR in $context: $error');
    if (stackTrace != null) {
      debugPrint('Stack trace: $stackTrace');
    }
  }
}
