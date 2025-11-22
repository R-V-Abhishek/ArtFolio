import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/post.dart';
import '../models/user.dart' as app_models;
import 'firestore_service.dart';
import 'storage_service.dart';

/// Exception thrown when account deletion requires recent authentication
class RecentLoginRequiredException implements Exception {
  const RecentLoginRequiredException(
    this.message, {
    required this.originalException,
  });
  final String message;
  final FirebaseAuthException originalException;

  @override
  String toString() => message;
}

class AccountDeletionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final StorageService _storage = StorageService();
  static final FirestoreService _firestoreService = FirestoreService();

  /// Deletes the user account and all associated data
  /// This is a comprehensive deletion that removes:
  /// - User profile and role-specific data
  /// - All posts created by the user
  /// - All comments made by the user
  /// - All likes by the user (removes from posts' likedBy arrays)
  /// - All follow relationships
  /// - All notifications related to the user
  /// - All storage files (profile pictures, post images)
  /// - Firebase Auth account
  static Future<void> deleteAccount(String userId) async {
    try {
      // Get user data first for verification
      final userData = await _firestoreService.getUser(userId);
      if (userData == null) {
        throw Exception('User not found');
      }

      debugPrint('Starting account deletion for user: $userId');

      // 1. Delete all posts created by the user (including images)
      await _deleteUserPosts(userId);

      // 2. Delete all comments made by the user
      await _deleteUserComments(userId);

      // 3. Remove user from all liked posts
      await _removeUserLikes(userId);

      // 4. Delete all follow relationships
      await _deleteFollowRelationships(userId);

      // 5. Delete all notifications related to the user
      await _deleteUserNotifications(userId);

      // 6. Delete role-specific data
      await _deleteRoleSpecificData(userId, userData.role);

      // 7. Delete user profile picture from storage
      if (userData.profilePictureUrl.isNotEmpty) {
        try {
          // Validate URL format before attempting deletion
          if (userData.profilePictureUrl.startsWith('https://') ||
              userData.profilePictureUrl.startsWith('gs://')) {
            await _storage.deleteImage(userData.profilePictureUrl);
          } else {
            debugPrint(
              'Skipping invalid profile picture URL: ${userData.profilePictureUrl}',
            );
          }
        } catch (e) {
          debugPrint('Warning: Failed to delete profile picture: $e');
        }
      }

      // 8. Delete user document
      await _firestore.collection('users').doc(userId).delete();

      // 9. Finally, delete Firebase Auth account
      final currentUser = _auth.currentUser;
      if (currentUser != null && currentUser.uid == userId) {
        try {
          await currentUser.delete();
        } on FirebaseAuthException catch (e) {
          if (e.code == 'requires-recent-login') {
            // User needs to re-authenticate before account deletion
            throw RecentLoginRequiredException(
              'For security, please sign in again to delete your account.',
              originalException: e,
            );
          } else {
            // Other auth errors
            throw Exception('Authentication error: ${e.message}');
          }
        }
      }

      debugPrint('Account deletion completed successfully for user: $userId');
    } catch (e) {
      debugPrint('Error during account deletion: $e');
      throw Exception('Failed to delete account: $e');
    }
  }

  /// Deletes all posts created by the user including images
  static Future<void> _deleteUserPosts(String userId) async {
    try {
      debugPrint('Deleting posts for user: $userId');

      // Get all posts by the user
      final postsSnapshot = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .get();

      for (final postDoc in postsSnapshot.docs) {
        final post = Post.fromSnapshot(postDoc);

        // Delete post images from storage
        final imagesToDelete = <String>[];
        if (post.mediaUrl != null && post.mediaUrl!.isNotEmpty) {
          imagesToDelete.add(post.mediaUrl!);
        }
        if (post.mediaUrls != null && post.mediaUrls!.isNotEmpty) {
          imagesToDelete.addAll(post.mediaUrls!);
        }
        if (post.thumbnailUrl != null && post.thumbnailUrl!.isNotEmpty) {
          imagesToDelete.add(post.thumbnailUrl!);
        }

        for (final imageUrl in imagesToDelete) {
          try {
            // Validate URL format before attempting deletion
            if (imageUrl.isNotEmpty &&
                (imageUrl.startsWith('https://') ||
                    imageUrl.startsWith('gs://'))) {
              await _storage.deleteImage(imageUrl);
            } else {
              debugPrint('Skipping invalid image URL: $imageUrl');
            }
          } catch (e) {
            debugPrint('Warning: Failed to delete post image $imageUrl: $e');
          }
        }

        // Delete all comments in this post
        final commentsSnapshot = await _firestore
            .collection('posts')
            .doc(post.id)
            .collection('comments')
            .get();

        for (final commentDoc in commentsSnapshot.docs) {
          await commentDoc.reference.delete();
        }

        // Delete the post document
        await postDoc.reference.delete();
      }

      debugPrint(
        'Deleted ${postsSnapshot.docs.length} posts for user: $userId',
      );
    } catch (e) {
      throw Exception('Failed to delete user posts: $e');
    }
  }

  /// Deletes all comments made by the user across all posts
  static Future<void> _deleteUserComments(String userId) async {
    try {
      debugPrint('Deleting comments for user: $userId');

      // Get all posts to check their comments
      final postsSnapshot = await _firestore.collection('posts').get();
      var deletedComments = 0;

      for (final postDoc in postsSnapshot.docs) {
        final commentsSnapshot = await _firestore
            .collection('posts')
            .doc(postDoc.id)
            .collection('comments')
            .where('userId', isEqualTo: userId)
            .get();

        final batch = _firestore.batch();
        for (final commentDoc in commentsSnapshot.docs) {
          batch.delete(commentDoc.reference);
          deletedComments++;
        }

        // Update post's comment count
        if (commentsSnapshot.docs.isNotEmpty) {
          batch.update(postDoc.reference, {
            'commentsCount': FieldValue.increment(
              -commentsSnapshot.docs.length,
            ),
          });
        }

        if (commentsSnapshot.docs.isNotEmpty) {
          await batch.commit();
        }
      }

      debugPrint('Deleted $deletedComments comments for user: $userId');
    } catch (e) {
      throw Exception('Failed to delete user comments: $e');
    }
  }

  /// Removes user from likedBy arrays of all posts they liked
  static Future<void> _removeUserLikes(String userId) async {
    try {
      debugPrint('Removing likes for user: $userId');

      // Get all posts where user is in likedBy array
      final postsSnapshot = await _firestore
          .collection('posts')
          .where('likedBy', arrayContains: userId)
          .get();

      final batch = _firestore.batch();
      for (final postDoc in postsSnapshot.docs) {
        batch.update(postDoc.reference, {
          'likedBy': FieldValue.arrayRemove([userId]),
          'likesCount': FieldValue.increment(-1),
        });
      }

      if (postsSnapshot.docs.isNotEmpty) {
        await batch.commit();
      }

      debugPrint(
        'Removed likes from ${postsSnapshot.docs.length} posts for user: $userId',
      );
    } catch (e) {
      throw Exception('Failed to remove user likes: $e');
    }
  }

  /// Deletes all follow relationships (both following and followers)
  static Future<void> _deleteFollowRelationships(String userId) async {
    try {
      debugPrint('Deleting follow relationships for user: $userId');

      // Delete where user is the follower (user following others)
      final followingSnapshot = await _firestore
          .collection('userFollows')
          .where('viewerId', isEqualTo: userId)
          .get();

      // Delete where user is being followed (others following user)
      final followersSnapshot = await _firestore
          .collection('userFollows')
          .where('targetId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();

      for (final doc in followingSnapshot.docs) {
        batch.delete(doc.reference);
      }

      for (final doc in followersSnapshot.docs) {
        batch.delete(doc.reference);
      }

      if (followingSnapshot.docs.isNotEmpty ||
          followersSnapshot.docs.isNotEmpty) {
        await batch.commit();
      }

      debugPrint(
        'Deleted ${followingSnapshot.docs.length + followersSnapshot.docs.length} follow relationships for user: $userId',
      );
    } catch (e) {
      throw Exception('Failed to delete follow relationships: $e');
    }
  }

  /// Deletes all notifications related to the user
  static Future<void> _deleteUserNotifications(String userId) async {
    try {
      debugPrint('Deleting notifications for user: $userId');

      // Delete notifications FOR the user
      final userNotificationsSnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      // Delete notifications ABOUT the user (where they might be mentioned)
      // This is more complex and might require additional fields in notifications

      final batch = _firestore.batch();
      for (final doc in userNotificationsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      if (userNotificationsSnapshot.docs.isNotEmpty) {
        await batch.commit();
      }

      debugPrint(
        'Deleted ${userNotificationsSnapshot.docs.length} notifications for user: $userId',
      );
    } catch (e) {
      throw Exception('Failed to delete user notifications: $e');
    }
  }

  /// Deletes role-specific data based on user role
  static Future<void> _deleteRoleSpecificData(
    String userId,
    app_models.UserRole role,
  ) async {
    try {
      debugPrint(
        'Deleting role-specific data for user: $userId (role: ${role.name})',
      );

      switch (role) {
        case app_models.UserRole.artist:
          await _firestore.collection('artists').doc(userId).delete();
          break;
        case app_models.UserRole.audience:
          await _firestore.collection('audiences').doc(userId).delete();
          break;
        case app_models.UserRole.sponsor:
          await _firestore.collection('sponsors').doc(userId).delete();
          break;
        case app_models.UserRole.organisation:
          await _firestore.collection('organisations').doc(userId).delete();
          break;
      }

      debugPrint('Deleted role-specific data for user: $userId');
    } catch (e) {
      throw Exception('Failed to delete role-specific data: $e');
    }
  }

  /// Validates if user can delete their account (additional security checks)
  static Future<bool> canDeleteAccount(String userId) async {
    try {
      // Check if user exists
      final user = await _firestoreService.getUser(userId);
      if (user == null) return false;

      // Check if current authenticated user matches
      final currentUser = _auth.currentUser;
      if (currentUser == null || currentUser.uid != userId) return false;

      // Add any additional business logic here
      // For example, check if user has any pending transactions, etc.

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Gets account deletion summary (what will be deleted)
  static Future<Map<String, int>> getAccountDeletionSummary(
    String userId,
  ) async {
    try {
      final summary = <String, int>{};

      // Count posts
      final postsSnapshot = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .get();
      summary['posts'] = postsSnapshot.docs.length;

      // Count comments (approximate - would need to check all posts)
      var commentCount = 0;
      final postsForComments = await _firestore.collection('posts').get();
      for (final postDoc in postsForComments.docs) {
        final commentsSnapshot = await _firestore
            .collection('posts')
            .doc(postDoc.id)
            .collection('comments')
            .where('userId', isEqualTo: userId)
            .get();
        commentCount += commentsSnapshot.docs.length;
      }
      summary['comments'] = commentCount;

      // Count likes
      final likedPostsSnapshot = await _firestore
          .collection('posts')
          .where('likedBy', arrayContains: userId)
          .get();
      summary['likes'] = likedPostsSnapshot.docs.length;

      // Count follow relationships
      final followingSnapshot = await _firestore
          .collection('userFollows')
          .where('viewerId', isEqualTo: userId)
          .get();
      final followersSnapshot = await _firestore
          .collection('userFollows')
          .where('targetId', isEqualTo: userId)
          .get();
      summary['following'] = followingSnapshot.docs.length;
      summary['followers'] = followersSnapshot.docs.length;

      return summary;
    } catch (e) {
      throw Exception('Failed to get deletion summary: $e');
    }
  }

  /// Re-authenticates the current user with their credentials
  /// Call this method when account deletion fails with requires-recent-login
  static Future<void> reauthenticateUser({
    String? email,
    String? password,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('No user is currently signed in');
    }

    try {
      AuthCredential credential;

      // Check if user signed in with Google
      final providerData = currentUser.providerData;
      final hasGoogleProvider = providerData.any(
        (provider) => provider.providerId == 'google.com',
      );

      if (hasGoogleProvider) {
        // Re-authenticate with Google
        final googleSignIn = GoogleSignIn();
        final googleUser = await googleSignIn.signIn();

        if (googleUser == null) {
          throw Exception('Google sign-in was cancelled');
        }

        final googleAuth = await googleUser.authentication;
        credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
      } else {
        // Re-authenticate with email/password
        if (email == null || password == null) {
          throw Exception(
            'Email and password are required for re-authentication',
          );
        }
        credential = EmailAuthProvider.credential(
          email: email,
          password: password,
        );
      }

      await currentUser.reauthenticateWithCredential(credential);
      debugPrint('User re-authenticated successfully');
    } catch (e) {
      debugPrint('Re-authentication failed: $e');
      throw Exception('Re-authentication failed: $e');
    }
  }
}
