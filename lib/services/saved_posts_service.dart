import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/post.dart';

class SavedPostsService {
  // Private constructor
  SavedPostsService._();
  
  // Singleton instance
  static final SavedPostsService _instance = SavedPostsService._();
  static SavedPostsService get instance => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get the current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  /// Collection reference for saved posts
  CollectionReference get _savedPostsCollection => 
      _firestore.collection('savedPosts');

  /// Save a post for the current user
  Future<void> savePost(String postId) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User must be logged in to save posts');
    }

    try {
      // Create a document with composite ID: userId_postId
      final docId = '${userId}_$postId';
      
      await _savedPostsCollection.doc(docId).set({
        'userId': userId,
        'postId': postId,
        'savedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to save post: $e');
    }
  }

  /// Unsave a post for the current user
  Future<void> unsavePost(String postId) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User must be logged in to unsave posts');
    }

    try {
      final docId = '${userId}_$postId';
      await _savedPostsCollection.doc(docId).delete();
    } catch (e) {
      throw Exception('Failed to unsave post: $e');
    }
  }

  /// Check if a post is saved by the current user
  Future<bool> isPostSaved(String postId) async {
    final userId = _currentUserId;
    if (userId == null) return false;

    try {
      final docId = '${userId}_$postId';
      final doc = await _savedPostsCollection.doc(docId).get();
      return doc.exists;
    } catch (e) {
      return false; // Default to false on error
    }
  }

  /// Toggle save status of a post
  Future<bool> togglePostSave(String postId) async {
    final isSaved = await isPostSaved(postId);
    
    if (isSaved) {
      await unsavePost(postId);
      return false;
    } else {
      await savePost(postId);
      return true;
    }
  }

  /// Get all saved posts for the current user
  Future<List<Post>> getSavedPosts() async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User must be logged in to view saved posts');
    }

    try {
      // Get saved post IDs without orderBy to avoid index requirement
      final savedQuery = await _savedPostsCollection
          .where('userId', isEqualTo: userId)
          .get();

      if (savedQuery.docs.isEmpty) {
        return [];
      }

      // Extract post IDs
      final postIds = <String>[];
      for (final doc in savedQuery.docs) {
        final data = doc.data();
        if (data != null && data is Map<String, dynamic> && data['postId'] != null) {
          postIds.add(data['postId'] as String);
        }
      }

      // Batch fetch posts
      final posts = <Post>[];
      final postsCollection = _firestore.collection('posts');
      
      // Firebase 'in' queries are limited to 10 items
      for (var i = 0; i < postIds.length; i += 10) {
        final batch = postIds.skip(i).take(10).toList();
        final postsQuery = await postsCollection
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        
        for (final doc in postsQuery.docs) {
          if (doc.exists) {
            posts.add(Post.fromSnapshot(doc));
          }
        }
      }

      // Sort posts by saved time (most recent first)
      final savedMap = <String, DateTime>{};
      for (final doc in savedQuery.docs) {
        final data = doc.data();
        if (data != null) {
          final dataMap = data as Map<String, dynamic>;
          final postId = dataMap['postId'] as String;
          final savedAt = (dataMap['savedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          savedMap[postId] = savedAt;
        }
      }

      posts.sort((a, b) {
        final aSavedAt = savedMap[a.id] ?? DateTime.now();
        final bSavedAt = savedMap[b.id] ?? DateTime.now();
        return bSavedAt.compareTo(aSavedAt);
      });

      return posts;
    } catch (e) {
      throw Exception('Failed to get saved posts: $e');
    }
  }

  /// Stream saved posts for real-time updates
  Stream<List<Post>> streamSavedPosts() async* {
    final userId = _currentUserId;
    if (userId == null) {
      yield [];
      return;
    }

    // Use simple query without orderBy to avoid index requirement
    yield* _savedPostsCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .asyncMap((snapshot) async {
      try {
        if (snapshot.docs.isEmpty) {
          return <Post>[];
        }

        // Extract post IDs
        final postIds = <String>[];
        for (final doc in snapshot.docs) {
          final data = doc.data();
          if (data != null && data is Map<String, dynamic> && data['postId'] != null) {
            postIds.add(data['postId'] as String);
          }
        }

        // Batch fetch posts
        final posts = <Post>[];
        final postsCollection = _firestore.collection('posts');
        
        // Firebase 'in' queries are limited to 10 items
        for (var i = 0; i < postIds.length; i += 10) {
          final batch = postIds.skip(i).take(10).toList();
          if (batch.isEmpty) continue;
          
          try {
            final postsQuery = await postsCollection
                .where(FieldPath.documentId, whereIn: batch)
                .get();
            
            for (final doc in postsQuery.docs) {
              if (doc.exists) {
                try {
                  posts.add(Post.fromSnapshot(doc));
                } catch (e) {
                  // Skip posts that fail to parse
                  debugPrint('Failed to parse post ${doc.id}: $e');
                  continue;
                }
              }
            }
          } catch (e) {
            // Log the error but continue with other batches
            debugPrint('Failed to fetch post batch $batch: $e');
            continue;
          }
        }

      // Sort posts by saved time
      final savedMap = <String, DateTime>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data != null) {
          final dataMap = data as Map<String, dynamic>;
          final postId = dataMap['postId'] as String;
          final savedAt = (dataMap['savedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          savedMap[postId] = savedAt;
        }
      }

        posts.sort((a, b) {
          final aSavedAt = savedMap[a.id] ?? DateTime.now();
          final bSavedAt = savedMap[b.id] ?? DateTime.now();
          return bSavedAt.compareTo(aSavedAt);
        });

        return posts;
      } catch (e) {
        // If there's any error in processing, throw it so StreamBuilder can catch it
        throw Exception('Failed to load saved posts: $e');
      }
    });
  }

  /// Get count of saved posts for current user
  Future<int> getSavedPostsCount() async {
    final userId = _currentUserId;
    if (userId == null) return 0;

    try {
      final query = await _savedPostsCollection
          .where('userId', isEqualTo: userId)
          .get();
      
      return query.docs.length;
    } catch (e) {
      return 0;
    }
  }

  /// Remove saved posts for posts that no longer exist
  Future<void> cleanupSavedPosts() async {
    final userId = _currentUserId;
    if (userId == null) return;

    try {
      final savedQuery = await _savedPostsCollection
          .where('userId', isEqualTo: userId)
          .get();

      final postsCollection = _firestore.collection('posts');
      final batch = _firestore.batch();

      for (final doc in savedQuery.docs) {
        final data = doc.data();
        if (data != null) {
          final dataMap = data as Map<String, dynamic>;
          final postId = dataMap['postId'] as String;
          
          // Check if post still exists
          final postDoc = await postsCollection.doc(postId).get();
          if (!postDoc.exists) {
            // Remove the saved post entry
            batch.delete(doc.reference);
          }
        }
      }

      await batch.commit();
    } catch (e) {
      // Fail silently for cleanup operations
    }
  }
}
