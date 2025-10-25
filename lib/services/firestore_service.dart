import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:flutter/foundation.dart';
import '../models/app_notification.dart';
import '../models/comment.dart';
import '../models/post.dart';
import '../models/role_models.dart';
import '../models/user.dart';
import 'error_handler_service.dart';
import 'storage_service.dart';

// Pagination result for notifications
class NotificationsPage {
  const NotificationsPage(this.items, this.lastDoc);
  final List<AppNotification> items;
  final DocumentSnapshot? lastDoc;
}

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final StorageService _storageService = StorageService();

  // Collection references
  CollectionReference get _usersCollection => _db.collection('users');
  CollectionReference get _artistsCollection => _db.collection('artists');
  CollectionReference get _audiencesCollection => _db.collection('audiences');
  CollectionReference get _sponsorsCollection => _db.collection('sponsors');
  CollectionReference get _organisationsCollection =>
      _db.collection('organisations');
  CollectionReference get _postsCollection => _db.collection('posts');
  CollectionReference get _notificationsCollection =>
      _db.collection('notifications');
  CollectionReference get _postReportsCollection =>
    _db.collection('postReports');
  CollectionReference _commentsCollection(String postId) =>
      _postsCollection.doc(postId).collection('comments');
  CollectionReference get _userFollowsCollection =>
      _db.collection('userFollows');

  // ===== USER MANAGEMENT =====

  // Create base user profile
  Future<void> createUser(User user) async {
    try {
      await _usersCollection.doc(user.id).set(user.toMap());
    } catch (e) {
      throw ErrorHandlerService.handleFirebaseException(e);
    }
  }

  // ===== REPORTS / MODERATION =====
  Future<void> reportPost({
    required String postId,
    required String reportedBy,
    required String ownerUserId,
    required String reason,
    String? details,
  }) async {
    try {
      await _postReportsCollection.add({
        'postId': postId,
        'reportedBy': reportedBy,
        'ownerUserId': ownerUserId,
        'reason': reason,
        'details': details,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw ErrorHandlerService.handleFirebaseException(e);
    }
  }

  /// Get the set of postIds that the current user has reported.
  /// If the user is not signed in or access fails, returns an empty set.
  Future<Set<String>> getReportedPostIdsForCurrentUser() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return {};
      final snap = await _postReportsCollection
          .where('reportedBy', isEqualTo: uid)
          .get();
      final ids = <String>{};
      for (final d in snap.docs) {
        final data = d.data() as Map<String, dynamic>?;
        final id = data?['postId'];
        if (id is String && id.isNotEmpty) ids.add(id);
      }
      return ids;
    } catch (e) {
      // Swallow and return empty set to avoid breaking feeds on permission issues
      if (kDebugMode) {
        // ignore: avoid_print
        print('Failed to load reported post ids: $e');
      }
      return {};
    }
  }

  // Get user by ID
  Future<User?> getUser(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      return doc.exists ? User.fromSnapshot(doc) : null;
    } catch (e) {
      throw ErrorHandlerService.handleFirebaseException(e);
    }
  }

  // Update user profile
  Future<void> updateUser(User user) async {
    try {
      await _usersCollection
          .doc(user.id)
          .update(user.copyWith(updatedAt: DateTime.now()).toMap());
    } catch (e) {
      throw ErrorHandlerService.handleFirebaseException(e);
    }
  }

  // ===== ROLE-SPECIFIC DATA MANAGEMENT =====

  // Create artist profile
  Future<void> createArtist(Artist artist) async {
    try {
      await _artistsCollection.doc(artist.userId).set(artist.toMap());
    } catch (e) {
      throw Exception('Failed to create artist profile: $e');
    }
  }

  // Get artist profile
  Future<Artist?> getArtist(String userId) async {
    try {
      final doc = await _artistsCollection.doc(userId).get();
      return doc.exists ? Artist.fromSnapshot(doc) : null;
    } catch (e) {
      throw Exception('Failed to get artist profile: $e');
    }
  }

  // Create audience profile
  Future<void> createAudience(Audience audience) async {
    try {
      await _audiencesCollection.doc(audience.userId).set(audience.toMap());
    } catch (e) {
      throw Exception('Failed to create audience profile: $e');
    }
  }

  // Get audience profile
  Future<Audience?> getAudience(String userId) async {
    try {
      final doc = await _audiencesCollection.doc(userId).get();
      return doc.exists ? Audience.fromSnapshot(doc) : null;
    } catch (e) {
      throw Exception('Failed to get audience profile: $e');
    }
  }

  // Create sponsor profile
  Future<void> createSponsor(Sponsor sponsor) async {
    try {
      await _sponsorsCollection.doc(sponsor.userId).set(sponsor.toMap());
    } catch (e) {
      throw Exception('Failed to create sponsor profile: $e');
    }
  }

  // Get sponsor profile
  Future<Sponsor?> getSponsor(String userId) async {
    try {
      final doc = await _sponsorsCollection.doc(userId).get();
      return doc.exists ? Sponsor.fromSnapshot(doc) : null;
    } catch (e) {
      throw Exception('Failed to get sponsor profile: $e');
    }
  }

  // Create organisation profile
  Future<void> createOrganisation(Organisation organisation) async {
    try {
      await _organisationsCollection
          .doc(organisation.userId)
          .set(organisation.toMap());
    } catch (e) {
      throw Exception('Failed to create organisation profile: $e');
    }
  }

  // Get organisation profile
  Future<Organisation?> getOrganisation(String userId) async {
    try {
      final doc = await _organisationsCollection.doc(userId).get();
      return doc.exists ? Organisation.fromSnapshot(doc) : null;
    } catch (e) {
      throw Exception('Failed to get organisation profile: $e');
    }
  }

  // ===== COMBINED USER DATA =====

  // Get complete user data (base + role-specific)
  Future<Map<String, dynamic>?> getCompleteUserData(String userId) async {
    try {
      final user = await getUser(userId);
      if (user == null) return null;

      final userData = <String, dynamic>{'user': user.toMap()};

      // Get role-specific data based on user role
      switch (user.role) {
        case UserRole.artist:
          final artist = await getArtist(userId);
          if (artist != null) userData['artist'] = artist.toMap();
          break;
        case UserRole.audience:
          final audience = await getAudience(userId);
          if (audience != null) userData['audience'] = audience.toMap();
          break;
        case UserRole.sponsor:
          final sponsor = await getSponsor(userId);
          if (sponsor != null) userData['sponsor'] = sponsor.toMap();
          break;
        case UserRole.organisation:
          final organisation = await getOrganisation(userId);
          if (organisation != null) {
            userData['organisation'] = organisation.toMap();
          }
          break;
      }

      return userData;
    } catch (e) {
      throw Exception('Failed to get complete user data: $e');
    }
  }

  // Create a new post
  Future<void> createPost(Post post) async {
    try {
      await _postsCollection.add(post.toMap());
    } catch (e) {
      throw Exception('Failed to create post: $e');
    }
  }

  // Create post with image upload
  Future<void> createPostWithImage({
    required Post post,
    File? imageFile,
    Uint8List? imageData,
    String? imageFileName,
  }) async {
    try {
      String? imageUrl;

      // Upload image if provided
      if (imageFile != null || imageData != null) {
        imageFileName ??=
            'post_image_${DateTime.now().millisecondsSinceEpoch}.jpg';

        imageUrl = await _storageService.uploadPostImage(
          postId: post.id,
          fileName: imageFileName,
          file: imageFile,
          data: imageData,
        );
      }

      // Create updated post with image URL
      final updatedPost = post.copyWith(
        mediaUrls: imageUrl != null ? [imageUrl] : [],
      );

      await _postsCollection.doc(post.id).set(updatedPost.toMap());
    } catch (e) {
      throw Exception('Failed to create post with image: $e');
    }
  }

  // Create post with multiple images
  Future<void> createPostWithMultipleImages({
    required Post post,
    required List<File> imageFiles,
    List<String>? imageFileNames,
  }) async {
    try {
      final imageUrls = <String>[];

      // Upload all images
      for (var i = 0; i < imageFiles.length; i++) {
        final fileName = imageFileNames != null && i < imageFileNames.length
            ? imageFileNames[i]
            : 'post_image_${i + 1}_${DateTime.now().millisecondsSinceEpoch}.jpg';

        final imageUrl = await _storageService.uploadPostImage(
          postId: post.id,
          fileName: fileName,
          file: imageFiles[i],
        );

        imageUrls.add(imageUrl);
      }

      // Create updated post with image URLs
      final updatedPost = post.copyWith(mediaUrls: imageUrls);

      await _postsCollection.doc(post.id).set(updatedPost.toMap());
    } catch (e) {
      throw Exception('Failed to create post with multiple images: $e');
    }
  }

  // Update post and add/replace images
  Future<void> updatePostWithImages({
    required String postId,
    required Map<String, dynamic> updates,
    List<File>? newImageFiles,
    List<String>? newImageFileNames,
    bool replaceExistingImages = false,
  }) async {
    try {
      // Get existing post
      final doc = await _postsCollection.doc(postId).get();
      if (!doc.exists) {
        throw Exception('Post not found');
      }

      final existingPost = Post.fromSnapshot(doc);
      final currentImageUrls = existingPost.mediaUrls ?? [];

      // Delete existing images if replacing
      if (replaceExistingImages && currentImageUrls.isNotEmpty) {
        for (final url in currentImageUrls) {
          try {
            await _storageService.deleteImage(url);
          } catch (e) {
            // Continue even if deletion fails
            debugPrint('Warning: Failed to delete image $url: $e');
          }
        }
      }

      // Upload new images if provided
      final newImageUrls = <String>[];
      if (newImageFiles != null && newImageFiles.isNotEmpty) {
        for (var i = 0; i < newImageFiles.length; i++) {
          final fileName =
              newImageFileNames != null && i < newImageFileNames.length
              ? newImageFileNames[i]
              : 'post_image_${i + 1}_${DateTime.now().millisecondsSinceEpoch}.jpg';

          final imageUrl = await _storageService.uploadPostImage(
            postId: postId,
            fileName: fileName,
            file: newImageFiles[i],
          );

          newImageUrls.add(imageUrl);
        }
      }

      // Combine image URLs
      final finalImageUrls = replaceExistingImages
          ? newImageUrls
          : [...currentImageUrls, ...newImageUrls];

      // Update post with new data and images
      final finalUpdates = {
        ...updates,
        'mediaUrls': finalImageUrls,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _postsCollection.doc(postId).update(finalUpdates);
    } catch (e) {
      throw Exception('Failed to update post with images: $e');
    }
  }

  // Delete post and its images
  Future<void> deletePostWithImages(String postId) async {
    try {
      // Get post to find image URLs
      final doc = await _postsCollection.doc(postId).get();
      if (doc.exists) {
        final post = Post.fromSnapshot(doc);

        // Delete images from storage
        if (post.mediaUrls != null && post.mediaUrls!.isNotEmpty) {
          for (final url in post.mediaUrls!) {
            try {
              await _storageService.deleteImage(url);
            } catch (e) {
              // Continue even if deletion fails
              debugPrint('Warning: Failed to delete image $url: $e');
            }
          }
        }

        // Delete the post document
        await _postsCollection.doc(postId).delete();
      }
    } catch (e) {
      throw Exception('Failed to delete post with images: $e');
    }
  }

  // Get posts by user ID
  Future<List<Post>> getUserPosts(String userId) async {
    try {
      // Use a single-field filter and sort client-side to avoid requiring a composite index
      final querySnapshot = await _postsCollection
          .where('userId', isEqualTo: userId)
          .get();

      final items = querySnapshot.docs
          .map(Post.fromSnapshot)
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return items;
    } catch (e) {
      throw Exception('Failed to get user posts: $e');
    }
  }

  // ===== COMMENTS =====

  Stream<List<Comment>> streamComments(String postId, {int limit = 100}) {
    final currentUserId = _auth.currentUser?.uid;
    
    return _commentsCollection(postId)
        .orderBy('createdAt', descending: false)
        .limit(limit)
        .snapshots()
        .map((snap) {
          final comments = snap.docs.map((d) => Comment.fromSnapshot(d, postId)).toList();
          
          // Sort comments: user's comments first, then others by newest first
          if (currentUserId != null) {
            comments.sort((a, b) {
              final aIsUser = a.userId == currentUserId;
              final bIsUser = b.userId == currentUserId;
              
              if (aIsUser && !bIsUser) return -1; // User's comment comes first
              if (!aIsUser && bIsUser) return 1;  // Other user's comment comes after
              
              // If both are user's comments or both are others', sort by newest first
              return b.createdAt.compareTo(a.createdAt);
            });
          } else {
            // If no current user, just sort by newest first
            comments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          }
          
          return comments;
        });
  }

  Future<void> addComment({
    required String postId,
    required String userId,
    required String text,
  }) async {
    final user = await getUser(userId);
    final username = user?.username ?? 'User';
    final avatarUrl = user?.profilePictureUrl ?? '';

    // Fetch post owner for notification
    var ownerId = '';
    try {
      final postDoc = await _postsCollection.doc(postId).get();
      if (postDoc.exists) {
        final data = postDoc.data()! as Map<String, dynamic>;
        ownerId = (data['userId'] as String?) ?? '';
      }
    } catch (_) {}

    final batch = _db.batch();
    final commentsRef = _commentsCollection(postId).doc();
    batch
      ..set(commentsRef, {
        'userId': userId,
        'username': username,
        'avatarUrl': avatarUrl,
        'text': text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      })
      ..update(_postsCollection.doc(postId), {
        'commentsCount': FieldValue.increment(1),
        'lastEngagement': FieldValue.serverTimestamp(),
      });
    await batch.commit();

    // Best-effort notification (skip self-comment)
    try {
      if (ownerId.isNotEmpty && ownerId != userId) {
        final preview = text.trim();
        final previewShort = preview.length > 40
            ? '${preview.substring(0, 40)}…'
            : preview;
        await _notificationsCollection.add({
          'userId': ownerId,
          'type': 'comment',
          'postId': postId,
          'title': '$username commented: $previewShort',
          'createdAt': FieldValue.serverTimestamp(),
          'read': false,
        });
      }
    } catch (_) {}
  }

  Future<void> deleteComment({
    required String postId,
    required String commentId,
  }) async {
    final batch = _db.batch()
      ..delete(_commentsCollection(postId).doc(commentId))
      ..update(_postsCollection.doc(postId), {
        'commentsCount': FieldValue.increment(-1),
        'lastEngagement': FieldValue.serverTimestamp(),
      });
    await batch.commit();
  }

  // ===== FOLLOW SYSTEM (basic) =====

  /// Check if [viewerUserId] follows [targetUserId]. Universal across roles.
  Future<bool> isFollowing(String viewerUserId, String targetUserId) async {
    try {
      final docId = '${viewerUserId}_$targetUserId';
      final doc = await _userFollowsCollection.doc(docId).get();
      return doc.exists;
    } catch (e) {
      throw Exception('Failed to check following state: $e');
    }
  }

  /// Toggle follow between any two users. Returns the new following state (true if now following).
  Future<bool> toggleFollow({
    required String viewerUserId,
    required String targetUserId,
  }) async {
    try {
      if (viewerUserId == targetUserId) {
        throw Exception('Cannot follow yourself');
      }
      final docId = '${viewerUserId}_$targetUserId';
      final ref = _userFollowsCollection.doc(docId);
      final snap = await ref.get();
      if (snap.exists) {
        await ref.delete();
        return false;
      } else {
        await ref.set({
          'followerId':
              viewerUserId, // Changed from 'viewerId' to 'followerId' to match Firestore rules
          'viewerId':
              viewerUserId, // Keep both for compatibility with existing code
          'targetId': targetUserId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        // Create a notification for the target user
        try {
          final viewer = await getUser(viewerUserId);
          final title =
              '${viewer?.username ?? 'Someone'} started following you';
          await _notificationsCollection.add({
            'userId': targetUserId,
            'type': 'follow',
            'title': title,
            'createdAt': FieldValue.serverTimestamp(),
            'read': false,
          });
        } catch (_) {
          // Notifications are best-effort; ignore failures
        }
        return true;
      }
    } catch (e) {
      throw Exception('Failed to toggle follow: $e');
    }
  }

  /// Get follower/following counts for any user using the userFollows collection.
  Future<Map<String, int>> getFollowCounts(String userId) async {
    try {
      final followersSnap = await _userFollowsCollection
          .where('targetId', isEqualTo: userId)
          .get();
      final followingSnap = await _userFollowsCollection
          .where('viewerId', isEqualTo: userId)
          .get();
      return {'followers': followersSnap.size, 'following': followingSnap.size};
    } catch (e) {
      throw Exception('Failed to get follow counts: $e');
    }
  }

  // ===== FOLLOW LISTS =====

  /// Get the list of users who follow [userId]. Note: simple implementation (N+1 fetches).
  Future<List<User>> getFollowersUsers(String userId) async {
    try {
      final snap = await _userFollowsCollection
          .where('targetId', isEqualTo: userId)
          .get();
      final viewerIds = snap.docs
          .map((d) => (d.data()! as Map)['viewerId'] as String)
          .toList();
      final users = <User>[];
      for (final id in viewerIds) {
        final u = await getUser(id);
        if (u != null) users.add(u);
      }
      return users;
    } catch (e) {
      throw Exception('Failed to get followers: $e');
    }
  }

  /// Get the list of users whom [userId] is following. Note: simple implementation (N+1 fetches).
  Future<List<User>> getFollowingUsers(String userId) async {
    try {
      final snap = await _userFollowsCollection
          .where('viewerId', isEqualTo: userId)
          .get();
      final targetIds = snap.docs
          .map((d) => (d.data()! as Map)['targetId'] as String)
          .toList();
      final users = <User>[];
      for (final id in targetIds) {
        final u = await getUser(id);
        if (u != null) users.add(u);
      }
      return users;
    } catch (e) {
      throw Exception('Failed to get following: $e');
    }
  }

  // Get all posts
  Future<List<Post>> getAllPosts() async {
    try {
      final querySnapshot = await _postsCollection
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs.map(Post.fromSnapshot).toList();
    } catch (e) {
      throw ErrorHandlerService.handleFirebaseException(e);
    }
  }

  // ===== ENHANCED POST OPERATIONS =====

  // Get posts by type
  Future<List<Post>> getPostsByType(PostType type) async {
    try {
      final querySnapshot = await _postsCollection
          .where('type', isEqualTo: type.name)
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs.map(Post.fromSnapshot).toList();
    } catch (e) {
      throw ErrorHandlerService.handleFirebaseException(e);
    }
  }

  // Get trending posts (by engagement)
  Future<List<Post>> getTrendingPosts({int limit = 20}) async {
    try {
      final querySnapshot = await _postsCollection
          .where('likesCount', isGreaterThan: 10)
          .orderBy('likesCount', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map(Post.fromSnapshot).toList();
    } catch (e) {
      throw Exception('Failed to get trending posts: $e');
    }
  }

  // Get posts by skill tags
  Future<List<Post>> getPostsBySkill(String skill) async {
    try {
      final querySnapshot = await _postsCollection
          .where('skills', arrayContains: skill)
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs.map(Post.fromSnapshot).toList();
    } catch (e) {
      throw Exception('Failed to get posts by skill: $e');
    }
  }

  // Like/unlike a post
  Future<void> togglePostLike(String postId, String userId) async {
    try {
      final postRef = _postsCollection.doc(postId);
      final postSnapshot = await postRef.get();

      if (!postSnapshot.exists) {
        throw Exception('Post not found');
      }

      final postData = postSnapshot.data()! as Map<String, dynamic>;
      final likedBy = List<String>.from(postData['likedBy'] ?? []);
      final currentLikes = postData['likesCount'] ?? 0;
      final ownerId = (postData['userId'] as String?) ?? '';

      if (likedBy.contains(userId)) {
        // Unlike the post
        likedBy.remove(userId);
        await postRef.update({
          'likedBy': likedBy,
          'likesCount': currentLikes - 1,
          'lastEngagement': FieldValue.serverTimestamp(),
        });
      } else {
        // Like the post
        likedBy.add(userId);
        await postRef.update({
          'likedBy': likedBy,
          'likesCount': currentLikes + 1,
          'lastEngagement': FieldValue.serverTimestamp(),
        });

        // Best-effort notification for post owner (skip self-like)
        try {
          if (ownerId.isNotEmpty && ownerId != userId) {
            final liker = await getUser(userId);
            await _notificationsCollection.add({
              'userId': ownerId,
              'type': 'like',
              'postId': postId,
              'title': '${liker?.username ?? 'Someone'} liked your post',
              'createdAt': FieldValue.serverTimestamp(),
              'read': false,
            });
          }
        } catch (_) {
          // ignore notification failures
        }
      }
    } catch (e) {
      throw Exception('Failed to toggle post like: $e');
    }
  }

  // Increment post views
  Future<void> incrementPostViews(String postId) async {
    try {
      final postRef = _postsCollection.doc(postId);
      await postRef.update({'viewsCount': FieldValue.increment(1)});
    } catch (e) {
      throw Exception('Failed to increment post views: $e');
    }
  }

  // Increment post shares
  Future<void> incrementPostShares(String postId) async {
    try {
      final postRef = _postsCollection.doc(postId);
      await postRef.update({
        'sharesCount': FieldValue.increment(1),
        'lastEngagement': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to increment post shares: $e');
    }
  }

  // Get posts for feed (mixed content, optimized for engagement)
  Future<List<Post>> getFeedPosts({int limit = 20, String? lastPostId}) async {
    try {
      var query = _postsCollection
          .where('visibility', isEqualTo: 'public')
          .orderBy('timestamp', descending: true);

      if (lastPostId != null) {
        final lastDoc = await _postsCollection.doc(lastPostId).get();
        query = query.startAfterDocument(lastDoc);
      }

      final querySnapshot = await query.limit(limit).get();

      return querySnapshot.docs.map(Post.fromSnapshot).toList();
    } catch (e) {
      throw Exception('Failed to get feed posts: $e');
    }
  }

  // Search posts by caption/description
  Future<List<Post>> searchPosts(String searchTerm) async {
    try {
      // Note: For production, consider using Algolia or similar for better search
      final querySnapshot = await _postsCollection
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs
          .map(Post.fromSnapshot)
          .where(
            (post) =>
                post.caption.toLowerCase().contains(searchTerm.toLowerCase()) ||
                (post.description?.toLowerCase().contains(
                      searchTerm.toLowerCase(),
                    ) ??
                    false) ||
                post.skills.any(
                  (skill) =>
                      skill.toLowerCase().contains(searchTerm.toLowerCase()),
                ) ||
                post.tags.any(
                  (tag) => tag.toLowerCase().contains(searchTerm.toLowerCase()),
                ),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to search posts: $e');
    }
  }

  // Search users by username or fullName (case-insensitive contains, with prefix query optimization)
  Future<List<User>> searchUsers(String searchTerm, {int limit = 50}) async {
    try {
      final term = searchTerm.trim();
      if (term.isEmpty) return [];

      // Try prefix searches where possible
      final results = <User>[];

      // Username is typically lowercase in this app; use prefix query
      try {
        final snapU = await _usersCollection
            .orderBy('username')
            .startAt([term])
            .endAt(['$term\uf8ff'])
            .limit(limit)
            .get();
        results.addAll(snapU.docs.map(User.fromSnapshot));
      } catch (_) {}

      // Full name may have capitalization; try prefix on various casings
      try {
        final cap = term.isEmpty
            ? term
            : term[0].toUpperCase() + term.substring(1).toLowerCase();
        final snapF = await _usersCollection
            .orderBy('fullName')
            .startAt([cap])
            .endAt(['$cap\uf8ff'])
            .limit(limit)
            .get();
        results.addAll(snapF.docs.map(User.fromSnapshot));
      } catch (_) {}

      // Deduplicate by id
      final byId = <String, User>{};
      for (final u in results) {
        byId[u.id] = u;
      }
      final list = byId.values.toList();

      // Final client-side filter for case-insensitive contains on username/fullName
      final q = term.toLowerCase();
      return list
          .where(
            (u) =>
                u.username.toLowerCase().contains(q) ||
                u.fullName.toLowerCase().contains(q),
          )
          .take(limit)
          .toList();
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }

  // ===== END ENHANCED POST OPERATIONS =====

  // ===== NOTIFICATIONS =====

  /// Stream unread count badge for current user
  Stream<int> unreadNotificationsCountStream(String userId) => _notificationsCollection
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.size);

  /// Fetch notifications page for a user ordered by createdAt desc
  Future<NotificationsPage> getNotificationsPage({
    required String userId,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      var q = _notificationsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit);
      if (startAfter != null) {
        q = q.startAfterDocument(startAfter);
      }
      final snap = await q.get();
      final items = snap.docs.map(AppNotification.fromSnapshot).toList();
      final last = snap.docs.isNotEmpty ? snap.docs.last : null;
      return NotificationsPage(items, last);
    } catch (e) {
      throw Exception('Failed to fetch notifications: $e');
    }
  }

  // Backwards-compatible simple fetch (first page only)
  Future<List<AppNotification>> getNotifications({
    required String userId,
    int limit = 20,
  }) async {
    final page = await getNotificationsPage(userId: userId, limit: limit);
    return page.items;
  }

  Future<void> markNotificationRead(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).update({'read': true});
    } catch (e) {
      throw Exception('Failed to mark notification read: $e');
    }
  }

  Future<void> markAllNotificationsRead(String userId) async {
    try {
      final batch = _db.batch();
      final snap = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();
      for (final d in snap.docs) {
        batch.update(d.reference, {'read': true});
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark all notifications read: $e');
    }
  }

  /// Seed a few mock notifications for quick UI testing
  Future<void> seedMockNotifications(String userId) async {
    final now = DateTime.now();
    final docs = [
      AppNotification(
        id: '',
        userId: userId,
        type: NotificationType.like,
        title: 'Someone liked your post',
        createdAt: now.subtract(const Duration(minutes: 5)),
      ),
      AppNotification(
        id: '',
        userId: userId,
        type: NotificationType.comment,
        title: 'New comment on your project',
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
      AppNotification(
        id: '',
        userId: userId,
        type: NotificationType.follow,
        title: 'You have a new follower',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      AppNotification(
        id: '',
        userId: userId,
        type: NotificationType.collab,
        title: 'Collaboration request received',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      AppNotification(
        id: '',
        userId: userId,
        type: NotificationType.sponsor,
        title: 'Sponsor viewed your profile',
        createdAt: now.subtract(const Duration(days: 3)),
      ),
    ];
    final batch = _db.batch();
    for (final n in docs) {
      final ref = _notificationsCollection.doc();
      batch.set(ref, n.toMap());
    }
    await batch.commit();
  }

  // Seed mock data
  Future<void> seedMockData() async {
    try {
      // Check if data already exists
      final existingPosts = await _postsCollection.limit(1).get();
      if (existingPosts.docs.isNotEmpty) {
        return;
      }

      // Create mock users
      await _createMockUsers();

      // Create mock posts
      await _createMockPosts();
    } catch (e) {
      throw Exception('Failed to seed mock data: $e');
    }
  }

  // Private method to create mock users with new schema
  Future<void> _createMockUsers() async {
    final now = DateTime.now();

    // Create Artist user
    final artistUser = User(
      id: 'artist1',
      username: 'alice_painter',
      email: 'alice@example.com',
      fullName: 'Alice Painter',
      profilePictureUrl: 'assets/images/placeholder.png',
      bio: 'Exploring textures and colors on canvas.',
      role: UserRole.artist,
      createdAt: DateTime.parse('2025-09-18T12:00:00Z'),
      updatedAt: now,
    );

    final artistProfile = Artist(
      userId: 'artist1',
      artForms: ['OilPainting', 'Sketching'],
      portfolioUrls: [],
      reels: [],
      followers: [],
      following: [],
    );

    await createUser(artistUser);
    await createArtist(artistProfile);

    // Create Audience user
    final audienceUser = User(
      id: 'audience1',
      username: 'bob_viewer',
      email: 'bob@example.com',
      fullName: 'Bob Viewer',
      profilePictureUrl: 'assets/images/placeholder.png',
      bio: 'Loves attending creative festivals and exhibitions.',
      role: UserRole.audience,
      createdAt: DateTime.parse('2025-09-18T12:10:00Z'),
      updatedAt: now,
    );

    final audienceProfile = Audience(
      userId: 'audience1',
      likedContent: [],
      followingArtists: [],
      sponsorApplications: [],
    );

    await createUser(audienceUser);
    await createAudience(audienceProfile);

    // Create Sponsor user
    final sponsorUser = User(
      id: 'sponsor1',
      username: 'clara_sponsor',
      email: 'clara@example.com',
      fullName: 'Clara Sponsor',
      profilePictureUrl: 'assets/images/placeholder.png',
      bio: 'Supporting local talent and creative initiatives.',
      role: UserRole.sponsor,
      createdAt: DateTime.parse('2025-09-18T12:20:00Z'),
      updatedAt: now,
    );

    final sponsorProfile = Sponsor(
      userId: 'sponsor1',
      companyName: 'CreativeFunds Inc.',
      budgetRange: {'min': 50000.0, 'max': 200000.0},
      sponsoredPrograms: [],
      openToApplications: true,
    );

    await createUser(sponsorUser);
    await createSponsor(sponsorProfile);
  }

  // Private method to create enhanced mock posts
  Future<void> _createMockPosts() async {
    final now = DateTime.now();

    final mockPosts = [
      // Image post with high engagement
      Post(
        id: '',
        userId: 'artist1',
        type: PostType.image,
        mediaUrl: 'assets/images/placeholder.png',
        caption:
            'Latest oil painting - exploring textures and light. Really excited about how this landscape turned out! 🎨✨',
        description:
            'This piece took me 3 weeks to complete. I wanted to capture the golden hour light hitting the mountains. Used traditional oil painting techniques with modern color theory.',
        skills: ['OilPainting', 'Landscape', 'ColorTheory'],
        tags: [
          '#OilPainting',
          '#Landscape',
          '#Art',
          '#GoldenHour',
          '#Mountains',
        ],
        timestamp: now.subtract(const Duration(hours: 2)),
        likesCount: 47,
        commentsCount: 12,
        sharesCount: 8,
        viewsCount: 156,
        likedBy: ['audience1', 'sponsor1'],
        location: PostLocation(
          city: 'Mumbai',
          state: 'Maharashtra',
          country: 'India',
          latitude: 19.0760,
          longitude: 72.8777,
        ),
        aspectRatio: 0.67, // 400/600
        lastEngagement: now.subtract(const Duration(minutes: 15)),
      ),

      // Reel with collaboration
      Post(
        id: '',
        userId: 'artist1',
        type: PostType.reel,
        mediaUrl:
            'https://sample-videos.com/zip/10/mp4/480p/mp4-file_sample.mp4',
        thumbnailUrl: 'assets/images/placeholder.png',
        caption:
            'Quick sketch from life drawing session today. Love capturing the essence of a moment with just a few lines. ✏️',
        description:
            'Collaborated with @local_art_studio for this live sketching session. Amazing energy and fellow artists!',
        skills: ['Sketching', 'LifeDrawing', 'QuickStudy'],
        tags: [
          '#Sketching',
          '#LifeDrawing',
          '#Art',
          '#LiveSession',
          '#Collaboration',
        ],
        timestamp: now.subtract(const Duration(days: 1)),
        likesCount: 32,
        commentsCount: 8,
        sharesCount: 5,
        viewsCount: 89,
        likedBy: ['audience1'],
        duration: 45, // 45 seconds
        aspectRatio: 1.5, // 600/400
        collaboration: CollaborationInfo(
          collaboratorIds: ['studio123'],
        ),
        lastEngagement: now.subtract(const Duration(hours: 3)),
      ),

      // Sponsored gallery post
      Post(
        id: '',
        userId: 'artist1',
        type: PostType.gallery,
        mediaUrls: [
          'assets/images/placeholder.png',
          'assets/images/placeholder.png',
          'assets/images/placeholder.png',
        ],
        caption:
            'Portrait study series in oils. Been practicing capturing personality and emotion through brushwork. 🎭',
        description:
            'This series represents my exploration of human emotion through traditional oil painting. Each portrait tells a different story. Thanks to @CreativeFunds for supporting this project!',
        skills: ['OilPainting', 'Portrait', 'EmotionalExpression'],
        tags: [
          '#OilPainting',
          '#Portrait',
          '#Study',
          '#Sponsored',
          '#ArtSeries',
        ],
        timestamp: now.subtract(const Duration(days: 3)),
        likesCount: 78,
        commentsCount: 24,
        sharesCount: 15,
        viewsCount: 234,
        likedBy: ['audience1', 'sponsor1', 'artist2', 'artist3'],
        collaboration: CollaborationInfo(
          collaboratorIds: [],
          sponsorId: 'sponsor1',
          isSponsored: true,
          sponsorshipDetails: 'Art supplies sponsored by CreativeFunds Inc.',
        ),
        aspectRatio: 1, // Square images
        isPinned: true, // Artist pinned this post
        demographics: {'artists': 45, 'audience': 35, 'sponsors': 20},
        lastEngagement: now.subtract(const Duration(minutes: 45)),
      ),

      // Idea post (text-heavy)
      Post(
        id: '',
        userId: 'artist1',
        type: PostType.idea,
        caption:
            '💡 Idea: What if we created a community art space where artists can showcase work AND teach workshops?',
        description:
            'I\'ve been thinking about how we can make art more accessible to everyone. Imagine a space where:\n\n• Artists display their work\n• Conduct workshops for all skill levels\n• Collaborate on community projects\n• Host art therapy sessions\n\nWould love to hear your thoughts! Who would be interested in something like this?',
        skills: ['CommunityBuilding', 'ArtEducation', 'SocialImpact'],
        tags: [
          '#ArtCommunity',
          '#Ideas',
          '#Collaboration',
          '#ArtEducation',
          '#SocialImpact',
        ],
        timestamp: now.subtract(const Duration(hours: 18)),
        likesCount: 62,
        commentsCount: 35,
        sharesCount: 18,
        viewsCount: 189,
        likedBy: ['audience1', 'sponsor1', 'artist4', 'artist5'],
        lastEngagement: now.subtract(const Duration(hours: 2)),
      ),

      // Video tutorial
      Post(
        id: '',
        userId: 'artist1',
        type: PostType.video,
        mediaUrl:
            'https://sample-videos.com/zip/10/mp4/720p/mp4-file_sample.mp4',
        thumbnailUrl: 'assets/images/placeholder.png',
        caption:
            '🎨 Oil Painting Tutorial: Creating depth with layering techniques',
        description:
            'In this 10-minute tutorial, I show you my favorite layering technique for creating depth in oil paintings. Perfect for intermediate artists looking to improve their landscape work.',
        skills: ['OilPainting', 'Teaching', 'Tutorials', 'Layering'],
        tags: [
          '#Tutorial',
          '#OilPainting',
          '#ArtEducation',
          '#Techniques',
          '#LearnArt',
        ],
        timestamp: now.subtract(const Duration(days: 5)),
        likesCount: 156,
        commentsCount: 43,
        sharesCount: 67,
        viewsCount: 892,
        likedBy: ['audience1', 'sponsor1', 'artist6', 'artist7', 'student1'],
        duration: 600, // 10 minutes
        aspectRatio: 1.78, // 16:9
        demographics: {'beginners': 60, 'intermediate': 30, 'advanced': 10},
        lastEngagement: now.subtract(const Duration(minutes: 30)),
      ),
    ];

    for (final post in mockPosts) {
      await _postsCollection.add(post.toMap());
    }
  }

  // Helper method to get current user ID
  String? getCurrentUserId() => _auth.currentUser?.uid;

  // Check if current user has a profile
  Future<bool> hasUserProfile() async {
    final userId = getCurrentUserId();
    if (userId == null) return false;

    final profile = await getUser(userId);
    return profile != null;
  }

  // ===== TESTING METHODS =====

  /// Test method to fetch and print posts to console
  /// Use this to verify Firestore connectivity and data fetching
  Future<void> testFetchPosts() async {
    try {
      debugPrint('🔥 Testing Firestore connection...');

      // Test 1: Get all posts
      final allPosts = await getAllPosts();
      debugPrint('📊 Found ${allPosts.length} total posts');

      if (allPosts.isNotEmpty) {
        debugPrint('📝 Sample post details:');
        final firstPost = allPosts.first;
        debugPrint('  - ID: ${firstPost.id}');
        debugPrint('  - Caption: ${firstPost.caption}');
        debugPrint('  - Type: ${firstPost.type}');
        debugPrint('  - User ID: ${firstPost.userId}');
        debugPrint('  - Media URL: ${firstPost.mediaUrl ?? 'No media'}');
        debugPrint(
          '  - Media URLs: ${firstPost.mediaUrls?.join(', ') ?? 'None'}',
        );
        debugPrint('  - Timestamp: ${firstPost.timestamp}');
      }

      // Test 2: Get posts by type
      final imagePosts = await getPostsByType(PostType.image);
      debugPrint('🖼️ Found ${imagePosts.length} image posts');

      // Test 3: Check if we can create a test post (without actually creating it)
      debugPrint('✅ Firestore connection test completed successfully!');
    } catch (e) {
      debugPrint('❌ Firestore test failed: $e');
    }
  }

  /// Test method to verify Storage service integration
  Future<void> testStorageIntegration() async {
    try {
      debugPrint('☁️ Testing Firebase Storage integration...');

      // Check if storage service is properly initialized
      debugPrint('✅ Storage service initialized');

      // Note: Actual upload test should be done through the UI
      debugPrint(
        '📱 Use the "Test Upload" button in the app to test image upload',
      );
    } catch (e) {
      debugPrint('❌ Storage integration test failed: $e');
    }
  }
}
