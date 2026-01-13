import 'package:flutter/foundation.dart';

/// Manages loading states across the application
class LoadingState extends ChangeNotifier {
  final Map<String, bool> _loadingStates = {};

  /// Get loading state for a specific operation
  bool isLoading(String operation) => _loadingStates[operation] ?? false;

  /// Set loading state for a specific operation
  void setLoading(String operation, {required bool loading}) {
    final previousState = _loadingStates[operation] ?? false;
    _loadingStates[operation] = loading;

    // Only notify listeners if the state actually changed
    if (previousState != loading) {
      notifyListeners();
    }
  }

  /// Start loading for an operation
  void startLoading(String operation) {
    setLoading(operation, loading: true);
  }

  /// Stop loading for an operation
  void stopLoading(String operation) {
    setLoading(operation, loading: false);
  }

  /// Check if any operation is loading
  bool get isAnyLoading => _loadingStates.values.any((loading) => loading);

  /// Clear all loading states
  void clearAll() {
    _loadingStates.clear();
    notifyListeners();
  }

  /// Get all currently loading operations
  List<String> get loadingOperations => _loadingStates.entries
      .where((entry) => entry.value)
      .map((entry) => entry.key)
      .toList();
}

/// Common loading operation keys
class LoadingKeys {
  // Authentication
  static const String signIn = 'sign_in';
  static const String signUp = 'sign_up';
  static const String signOut = 'sign_out';

  // Posts
  static const String fetchPosts = 'fetch_posts';
  static const String createPost = 'create_post';
  static const String updatePost = 'update_post';
  static const String deletePost = 'delete_post';
  static const String likePost = 'like_post';

  // User operations
  static const String fetchUser = 'fetch_user';
  static const String updateProfile = 'update_profile';
  static const String uploadImage = 'upload_image';

  // Comments
  static const String fetchComments = 'fetch_comments';
  static const String addComment = 'add_comment';
  static const String deleteComment = 'delete_comment';

  // Follow operations
  static const String followUser = 'follow_user';
  static const String unfollowUser = 'unfollow_user';
  static const String fetchFollowing = 'fetch_following';
  static const String fetchFollowers = 'fetch_followers';

  // Search
  static const String search = 'search';

  // Notifications
  static const String fetchNotifications = 'fetch_notifications';
}
