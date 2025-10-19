import 'dart:core';

/// Validation result containing success status and error message
class ValidationResult {

  const ValidationResult({required this.isValid, this.errorMessage});

  factory ValidationResult.valid() => const ValidationResult(isValid: true);
  factory ValidationResult.invalid(String message) =>
      ValidationResult(isValid: false, errorMessage: message);
  final bool isValid;
  final String? errorMessage;
}

/// Comprehensive input validation service
class ValidationService {
  // Email validation
  static ValidationResult validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return ValidationResult.invalid('Email is required');
    }

    final trimmedEmail = email.trim();

    // Check minimum length
    if (trimmedEmail.length < 5) {
      return ValidationResult.invalid('Email is too short');
    }

    // Check maximum length
    if (trimmedEmail.length > 254) {
      return ValidationResult.invalid('Email is too long');
    }

    // Comprehensive email regex
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(trimmedEmail)) {
      return ValidationResult.invalid('Please enter a valid email address');
    }

    // Check for consecutive dots
    if (trimmedEmail.contains('..')) {
      return ValidationResult.invalid('Email cannot contain consecutive dots');
    }

    return ValidationResult.valid();
  }

  // Password validation
  static ValidationResult validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return ValidationResult.invalid('Password is required');
    }

    if (password.length < 8) {
      return ValidationResult.invalid(
        'Password must be at least 8 characters long',
      );
    }

    if (password.length > 128) {
      return ValidationResult.invalid(
        'Password is too long (max 128 characters)',
      );
    }

    // Check for at least one uppercase letter
    if (!password.contains(RegExp('[A-Z]'))) {
      return ValidationResult.invalid(
        'Password must contain at least one uppercase letter',
      );
    }

    // Check for at least one lowercase letter
    if (!password.contains(RegExp('[a-z]'))) {
      return ValidationResult.invalid(
        'Password must contain at least one lowercase letter',
      );
    }

    // Check for at least one digit
    if (!password.contains(RegExp('[0-9]'))) {
      return ValidationResult.invalid(
        'Password must contain at least one number',
      );
    }

    // Check for at least one special character
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return ValidationResult.invalid(
        'Password must contain at least one special character',
      );
    }

    // Check for common weak passwords
    final weakPasswords = [
      'password',
      '12345678',
      'qwerty123',
      'abc123456',
      'Password1',
      'password123',
      '123456789',
    ];

    if (weakPasswords.any(
      (weak) => password.toLowerCase().contains(weak.toLowerCase()),
    )) {
      return ValidationResult.invalid(
        'Password is too common, please choose a stronger one',
      );
    }

    return ValidationResult.valid();
  }

  // Confirm password validation
  static ValidationResult validateConfirmPassword(
    String? password,
    String? confirmPassword,
  ) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return ValidationResult.invalid('Please confirm your password');
    }

    if (password != confirmPassword) {
      return ValidationResult.invalid('Passwords do not match');
    }

    return ValidationResult.valid();
  }

  // Username validation
  static ValidationResult validateUsername(String? username) {
    if (username == null || username.trim().isEmpty) {
      return ValidationResult.invalid('Username is required');
    }

    final trimmedUsername = username.trim();

    if (trimmedUsername.length < 3) {
      return ValidationResult.invalid(
        'Username must be at least 3 characters long',
      );
    }

    if (trimmedUsername.length > 30) {
      return ValidationResult.invalid(
        'Username is too long (max 30 characters)',
      );
    }

    // Allow letters, numbers, underscores, and hyphens
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_-]+$');
    if (!usernameRegex.hasMatch(trimmedUsername)) {
      return ValidationResult.invalid(
        'Username can only contain letters, numbers, underscores, and hyphens',
      );
    }

    // Cannot start or end with underscore or hyphen
    if (trimmedUsername.startsWith('_') ||
        trimmedUsername.startsWith('-') ||
        trimmedUsername.endsWith('_') ||
        trimmedUsername.endsWith('-')) {
      return ValidationResult.invalid(
        'Username cannot start or end with underscore or hyphen',
      );
    }

    // Check for reserved usernames
    final reservedUsernames = [
      'admin',
      'administrator',
      'mod',
      'moderator',
      'root',
      'system',
      'api',
      'app',
      'www',
      'mail',
      'ftp',
      'help',
      'support',
    ];

    if (reservedUsernames.contains(trimmedUsername.toLowerCase())) {
      return ValidationResult.invalid(
        'This username is reserved, please choose another',
      );
    }

    return ValidationResult.valid();
  }

  // Display name validation
  static ValidationResult validateDisplayName(String? displayName) {
    if (displayName == null || displayName.trim().isEmpty) {
      return ValidationResult.invalid('Display name is required');
    }

    final trimmedName = displayName.trim();

    if (trimmedName.length < 2) {
      return ValidationResult.invalid(
        'Display name must be at least 2 characters long',
      );
    }

    if (trimmedName.length > 50) {
      return ValidationResult.invalid(
        'Display name is too long (max 50 characters)',
      );
    }

    // Allow letters, numbers, spaces, and common punctuation
    final nameRegex = RegExp(r"^[a-zA-Z0-9\s\-'\.]+$");
    if (!nameRegex.hasMatch(trimmedName)) {
      return ValidationResult.invalid(
        'Display name contains invalid characters',
      );
    }

    // Cannot be only spaces
    if (trimmedName.replaceAll(' ', '').isEmpty) {
      return ValidationResult.invalid('Display name cannot be only spaces');
    }

    return ValidationResult.valid();
  }

  // Post content validation
  static ValidationResult validatePostContent(
    String? content, {
    int maxLength = 2000,
  }) {
    if (content == null || content.trim().isEmpty) {
      return ValidationResult.invalid('Post content is required');
    }

    final trimmedContent = content.trim();

    if (trimmedContent.isEmpty) {
      return ValidationResult.invalid('Post content cannot be empty');
    }

    if (trimmedContent.length > maxLength) {
      return ValidationResult.invalid(
        'Post content is too long (max $maxLength characters)',
      );
    }

    return ValidationResult.valid();
  }

  // Comment validation
  static ValidationResult validateComment(String? comment) {
    if (comment == null || comment.trim().isEmpty) {
      return ValidationResult.invalid('Comment cannot be empty');
    }

    final trimmedComment = comment.trim();

    if (trimmedComment.length > 500) {
      return ValidationResult.invalid(
        'Comment is too long (max 500 characters)',
      );
    }

    return ValidationResult.valid();
  }

  // Bio validation
  static ValidationResult validateBio(String? bio) {
    if (bio == null || bio.trim().isEmpty) {
      return ValidationResult.valid(); // Bio is optional
    }

    final trimmedBio = bio.trim();

    if (trimmedBio.length > 500) {
      return ValidationResult.invalid('Bio is too long (max 500 characters)');
    }

    return ValidationResult.valid();
  }

  // URL validation
  static ValidationResult validateUrl(String? url) {
    if (url == null || url.trim().isEmpty) {
      return ValidationResult.valid(); // URL is optional
    }

    final trimmedUrl = url.trim();

    try {
      final uri = Uri.parse(trimmedUrl);
      if (!uri.hasScheme || (!uri.scheme.startsWith('http'))) {
        return ValidationResult.invalid(
          'Please enter a valid URL starting with http:// or https://',
        );
      }

      if (uri.host.isEmpty) {
        return ValidationResult.invalid('Please enter a valid URL');
      }

      return ValidationResult.valid();
    } catch (e) {
      return ValidationResult.invalid('Please enter a valid URL');
    }
  }

  // Search query validation
  static ValidationResult validateSearchQuery(String? query) {
    if (query == null || query.trim().isEmpty) {
      return ValidationResult.invalid('Search query cannot be empty');
    }

    final trimmedQuery = query.trim();

    if (trimmedQuery.length < 2) {
      return ValidationResult.invalid(
        'Search query must be at least 2 characters long',
      );
    }

    if (trimmedQuery.length > 100) {
      return ValidationResult.invalid(
        'Search query is too long (max 100 characters)',
      );
    }

    return ValidationResult.valid();
  }

  // Skills validation
  static ValidationResult validateSkills(List<String>? skills) {
    if (skills == null || skills.isEmpty) {
      return ValidationResult.valid(); // Skills are optional
    }

    if (skills.length > 10) {
      return ValidationResult.invalid('Maximum 10 skills allowed');
    }

    for (final skill in skills) {
      if (skill.trim().isEmpty) {
        return ValidationResult.invalid('Skill cannot be empty');
      }

      if (skill.length > 30) {
        return ValidationResult.invalid(
          'Skill name is too long (max 30 characters)',
        );
      }
    }

    return ValidationResult.valid();
  }

  // Phone number validation (optional)
  static ValidationResult validatePhoneNumber(String? phone) {
    if (phone == null || phone.trim().isEmpty) {
      return ValidationResult.valid(); // Phone is optional
    }

    final trimmedPhone = phone.trim();

    // Remove common formatting characters
    final cleanPhone = trimmedPhone.replaceAll(RegExp(r'[^\d+]'), '');

    if (cleanPhone.length < 10 || cleanPhone.length > 15) {
      return ValidationResult.invalid('Please enter a valid phone number');
    }

    final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]+$');
    if (!phoneRegex.hasMatch(phone)) {
      return ValidationResult.invalid('Please enter a valid phone number');
    }

    return ValidationResult.valid();
  }

  /// Sanitize input by removing potentially harmful content
  static String sanitizeInput(String input) {
    // Remove leading and trailing whitespace
    var sanitized = input.trim();

    // Remove null characters
    sanitized = sanitized.replaceAll('\x00', '');

    // Limit consecutive whitespace
    sanitized = sanitized.replaceAll(RegExp(r'\s{3,}'), '  ');

    // Remove other control characters except common ones like newlines and tabs
    sanitized = sanitized.replaceAll(RegExp(r'[\x01-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');

    return sanitized;
  }

  /// Validate multiple fields at once
  static Map<String, String> validateMultipleFields(
    Map<String, dynamic> fields,
  ) {
    final errors = <String, String>{};

    fields.forEach((fieldName, value) {
      ValidationResult result;

      switch (fieldName.toLowerCase()) {
        case 'email':
          result = validateEmail(value as String?);
          break;
        case 'password':
          result = validatePassword(value as String?);
          break;
        case 'username':
          result = validateUsername(value as String?);
          break;
        case 'displayname':
        case 'display_name':
          result = validateDisplayName(value as String?);
          break;
        case 'bio':
          result = validateBio(value as String?);
          break;
        case 'url':
        case 'website':
          result = validateUrl(value as String?);
          break;
        case 'phone':
        case 'phonenumber':
        case 'phone_number':
          result = validatePhoneNumber(value as String?);
          break;
        default:
          result = ValidationResult.valid(); // Skip unknown fields
          break;
      }

      if (!result.isValid && result.errorMessage != null) {
        errors[fieldName] = result.errorMessage!;
      }
    });

    return errors;
  }
}
