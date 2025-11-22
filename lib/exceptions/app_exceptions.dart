/// Custom exception classes for better error handling and user experience
library;

/// Base class for all app-specific exceptions
abstract class AppException implements Exception {
  const AppException(this.message, {this.code, this.originalError});
  final String message;
  final String? code;
  final dynamic originalError;

  @override
  String toString() => 'AppException: $message';
}

/// Authentication related exceptions
class UserNotAuthenticatedException extends AppException {
  const UserNotAuthenticatedException()
    : super('User is not authenticated. Please log in again.');
}

class AuthenticationFailedException extends AppException {
  const AuthenticationFailedException(super.message);
}

/// Network related exceptions
class NetworkUnavailableException extends AppException {
  const NetworkUnavailableException()
    : super('Network is unavailable. Please check your internet connection.');
}

class TimeoutException extends AppException {
  const TimeoutException() : super('Request timed out. Please try again.');
}

/// Firestore related exceptions
class PostFetchException extends AppException {
  const PostFetchException(String? message)
    : super(message ?? 'Failed to fetch posts. Please try again.');
}

class PostUploadException extends AppException {
  const PostUploadException(String? message)
    : super(message ?? 'Failed to upload post. Please try again.');
}

class UserDataException extends AppException {
  const UserDataException(String? message)
    : super(message ?? 'Failed to load user data.');
}

/// Image handling exceptions
class ImageUploadException extends AppException {
  const ImageUploadException(String? message)
    : super(message ?? 'Failed to upload image. Please try again.');
}

class ImageCompressionException extends AppException {
  const ImageCompressionException(String? message)
    : super(message ?? 'Failed to process image.');
}

/// Validation exceptions
class ValidationException extends AppException {
  const ValidationException(super.message, this.fieldErrors);
  final Map<String, String> fieldErrors;
}

/// Permission exceptions
class PermissionDeniedException extends AppException {
  const PermissionDeniedException(String? message)
    : super(message ?? 'Permission denied.');
}

/// Storage exceptions
class StorageException extends AppException {
  const StorageException(String? message)
    : super(message ?? 'Storage operation failed.');
}
