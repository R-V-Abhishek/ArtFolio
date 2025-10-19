import 'dart:async';

import 'package:flutter/material.dart';

import '../models/post.dart';
import '../services/error_handler_service.dart';
import '../services/firestore_service.dart';
import '../services/image_cache_service.dart';
import '../widgets/loading_widgets.dart';

/// Example screen demonstrating improved patterns and practices
class ImprovedFeedScreen extends StatefulWidget {
  const ImprovedFeedScreen({super.key});

  @override
  State<ImprovedFeedScreen> createState() => _ImprovedFeedScreenState();
}

class _ImprovedFeedScreenState extends State<ImprovedFeedScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final ScrollController _scrollController = ScrollController();

  List<Post> _posts = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
    _setupScrollListener();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Initialize screen with proper error handling
  Future<void> _initializeScreen() async {
    try {
      // Initialize image cache
      await ImageCacheService().initialize();

      // Load initial posts
      await _loadPosts();
    } catch (e) {
      _handleError(e);
    }
  }

  /// Setup scroll listener for pagination
  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent * 0.8 &&
          !_isLoadingMore &&
          !_hasError) {
        _loadMorePosts();
      }
    });
  }

  /// Load posts with comprehensive error handling
  Future<void> _loadPosts({bool isRefresh = false}) async {
    if (_isLoading && !isRefresh) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      if (isRefresh) _posts.clear();
    });

    try {
      final posts = await _firestoreService.getAllPosts();

      if (mounted) {
        setState(() {
          _posts = posts;
          _isLoading = false;
        });

        // Preload images for better UX
        final imageUrls = posts
            .where((post) => post.mediaUrl?.isNotEmpty ?? false)
            .map((post) => post.mediaUrl!)
            .take(5) // Preload first 5 images
            .toList();

        if (imageUrls.isNotEmpty) {
          unawaited(ImageCacheService().preloadImages(imageUrls));
        }
      }
    } catch (e) {
      _handleError(e);
    }
  }

  /// Load more posts for pagination
  Future<void> _loadMorePosts() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      // Implement pagination logic here
      // For now, just simulate loading more posts
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
      _handleError(e);
    }
  }

  /// Handle errors with user-friendly messages
  void _handleError(dynamic error) {
    if (!mounted) return;

    final appException = ErrorHandlerService.handleFirebaseException(error);

    setState(() {
      _isLoading = false;
      _isLoadingMore = false;
      _hasError = true;
    });

    ErrorHandlerService.showErrorSnackBar(context, appException);
    ErrorHandlerService.logError('FeedScreen', error);
  }

  /// Handle like/unlike with optimistic updates
  Future<void> _handleLike(Post post) async {
    try {
      // Check if user already liked the post
      final isCurrentlyLiked = post.likedBy.contains(
        'currentUserId',
      ); // Replace with actual user ID

      // Optimistic update
      setState(() {
        final index = _posts.indexOf(post);
        if (index != -1) {
          final newLikedBy = List<String>.from(post.likedBy);
          if (isCurrentlyLiked) {
            newLikedBy.remove('currentUserId');
          } else {
            newLikedBy.add('currentUserId');
          }

          _posts[index] = post.copyWith(
            likedBy: newLikedBy,
            likesCount: isCurrentlyLiked
                ? post.likesCount - 1
                : post.likesCount + 1,
          );
        }
      });

      // Actual API call - implement these methods in FirestoreService
      // if (isCurrentlyLiked) {
      //   await _firestoreService.unlikePost(post.id);
      // } else {
      //   await _firestoreService.likePost(post.id);
      // }
    } catch (e) {
      // Revert optimistic update on error
      setState(() {
        final index = _posts.indexOf(post);
        if (index != -1) {
          _posts[index] = post;
        }
      });
      _handleError(e);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: const Text('Feed'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadPosts(isRefresh: true),
          ),
        ],
      ),
      body: _buildBody(),
    );

  Widget _buildBody() {
    if (_isLoading && _posts.isEmpty) {
      return const LoadingPlaceholder(
        isLoading: true,
        loadingMessage: 'Loading posts...',
        child: SizedBox.shrink(),
      );
    }

    if (_hasError && _posts.isEmpty) {
      return _buildErrorWidget();
    }

    if (_posts.isEmpty) {
      return _buildEmptyWidget();
    }

    return RefreshIndicator(
      onRefresh: () => _loadPosts(isRefresh: true),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _posts.length + (_isLoadingMore ? 1 : 0),
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          if (index >= _posts.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          return _buildPostCard(_posts[index]);
        },
      ),
    );
  }

  Widget _buildErrorWidget() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, size: 64, color: Colors.grey),
        const SizedBox(height: 16),
        const Text(
          'Something went wrong',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Failed to load posts. Please try again.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: _loadPosts, child: const Text('Retry')),
      ],
    ),
  );

  Widget _buildEmptyWidget() => Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.post_add_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('No posts yet', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Be the first to share something amazing!',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Navigate to create post screen
            },
            child: const Text('Create Post'),
          ),
        ],
      ),
    );

  Widget _buildPostCard(Post post) => Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info header
          ListTile(
            leading: const CircleAvatar(
              child: Text('U'), // Replace with actual user data when available
            ),
            title: Text(
              'User ${post.userId.substring(0, 8)}...',
            ), // Placeholder until user data is available
            subtitle: Text(_formatTimestamp(post.timestamp)),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showPostOptions(post),
            ),
          ),

          // Post content
          if (post.caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                post.caption,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),

          // Post image with caching
          if (post.mediaUrl?.isNotEmpty ?? false)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: post.mediaUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: ShimmerLoading(
                    isLoading: true,
                    child: Container(height: 200, color: Colors.grey),
                  ),
                  errorWidget: Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 48),
                    ),
                  ),
                ),
              ),
            ),

          // Action buttons
          OverflowBar(
            children: [
              TextButton.icon(
                onPressed: () => _handleLike(post),
                icon: Icon(
                  post.likedBy.contains('currentUserId')
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: post.likedBy.contains('currentUserId')
                      ? Colors.red
                      : null,
                ),
                label: Text('${post.likesCount}'),
              ),
              TextButton.icon(
                onPressed: () => _navigateToComments(post),
                icon: const Icon(Icons.comment_outlined),
                label: Text('${post.commentsCount}'),
              ),
              TextButton.icon(
                onPressed: () => _sharePost(post),
                icon: const Icon(Icons.share_outlined),
                label: const Text('Share'),
              ),
            ],
          ),
        ],
      ),
    );

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _showPostOptions(Post post) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: const Text('Report Post'),
            onTap: () {
              Navigator.pop(context);
              _reportPost(post);
            },
          ),
          ListTile(
            leading: const Icon(Icons.block_outlined),
            title: const Text('Block User'),
            onTap: () {
              Navigator.pop(context);
              _blockUser(post.userId);
            },
          ),
          ListTile(
            leading: const Icon(Icons.cancel_outlined),
            title: const Text('Cancel'),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _navigateToComments(Post post) {
    // Navigate to comments screen
  }

  void _sharePost(Post post) {
    // Implement share functionality
  }

  void _reportPost(Post post) {
    // Implement report functionality
  }

  void _blockUser(String userId) {
    // Implement block user functionality
  }
}
