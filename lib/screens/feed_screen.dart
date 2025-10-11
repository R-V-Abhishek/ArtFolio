import 'dart:async';
import 'package:flutter/material.dart';

import '../models/post.dart';
import '../services/firestore_service.dart';
import '../widgets/post_card.dart';
import '../services/asset_loader.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _firestore = FirestoreService();
  final _scrollController = ScrollController();

  final List<Post> _posts = [];
  bool _loading = false;
  bool _hasMore = true;
  String? _lastPostId;
  bool _usingLocal = false;

  @override
  void initState() {
    super.initState();
    _loadInitial();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    setState(() => _loading = true);
    try {
      final items = await _firestore
          .getFeedPosts(limit: 10)
          .timeout(const Duration(seconds: 4));
      setState(() {
        _posts
          ..clear()
          ..addAll(items);
        _hasMore = items.length == 10;
        _lastPostId = items.isNotEmpty ? items.last.id : null;
        _usingLocal = false;
      });

      // If no posts were returned, try asset-backed mock posts then demo
      if (_posts.isEmpty) {
        final assetPosts = await _loadFromAssets();
        if (assetPosts.isNotEmpty) {
          setState(() {
            _posts
              ..clear()
              ..addAll(assetPosts);
            _hasMore = false;
            _lastPostId = null;
            _usingLocal = true;
          });
        } else {
          final demo = _localDemoPosts();
          setState(() {
            _posts
              ..clear()
              ..addAll(demo);
            _hasMore = false;
            _lastPostId = null;
            _usingLocal = true;
          });
        }
      }
    } on TimeoutException {
      // Fallback to local demo if Firebase is slow/unavailable
      final assetPosts = await _loadFromAssets();
      final demo = assetPosts.isNotEmpty ? assetPosts : _localDemoPosts();
      setState(() {
        _posts
          ..clear()
          ..addAll(demo);
        _hasMore = false;
        _lastPostId = null;
        _usingLocal = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Offline or not configured. Showing demo feed.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load feed: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    if (_usingLocal) return; // don't page local demo
    setState(() => _loading = true);
    try {
      final items = await _firestore
          .getFeedPosts(limit: 10, lastPostId: _lastPostId)
          .timeout(const Duration(seconds: 4));
      setState(() {
        _posts.addAll(items);
        _hasMore = items.length == 10;
        _lastPostId = items.isNotEmpty ? items.last.id : _lastPostId;
      });
    } on TimeoutException {
      // stop paging on timeout
      setState(() {
        _hasMore = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load more: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _loading || !_hasMore) return;
    final threshold = 300; // px before end
    if (_scrollController.position.extentAfter < threshold) {
      _loadMore();
    }
  }

  Future<void> _refresh() async {
    _lastPostId = null;
    _hasMore = true;
    _usingLocal = false;
    await _loadInitial();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewPadding.bottom;
    if (_loading && _posts.isEmpty) {
      return SafeArea(child: const Center(child: CircularProgressIndicator()));
    }

    if (_posts.isEmpty) {
      return SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            controller: _scrollController,
            padding: EdgeInsets.only(bottom: bottomPad + 16),
            children: [
              const SizedBox(height: 80),
              Icon(
                Icons.palette,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'No posts yet',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Pull down to refresh or try again later',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 200),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView.separated(
          controller: _scrollController,
          padding: EdgeInsets.only(bottom: bottomPad + 80),
          itemCount: _posts.length + (_hasMore ? 1 : 0),
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index == _posts.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final post = _posts[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [PostCard(post: post)],
              ),
            );
          },
        ),
      ),
    );
  }
}

Future<List<Post>> _loadFromAssets() async {
  try {
    final list = await AssetLoader.loadJsonList('assets/mock_posts.json');
    return list
        .whereType<Map<String, dynamic>>()
        .map((m) => Post.fromJson(m))
        .toList();
  } catch (_) {
    return [];
  }
}

List<Post> _localDemoPosts() {
  final now = DateTime.now();
  return [
    Post(
      id: 'local_1',
      userId: 'local',
      type: PostType.image,
      mediaUrl: 'assets/images/placeholder.png',
      caption: 'Exploring textures and light in oils. 🎨',
      skills: const [],
      timestamp: now.subtract(const Duration(minutes: 15)),
      likesCount: 24,
      commentsCount: 3,
      aspectRatio: 0.8,
    ),
    Post(
      id: 'local_2',
      userId: 'local',
      type: PostType.gallery,
      mediaUrls: const [
        'assets/images/placeholder.png',
        'assets/images/placeholder.png',
        'assets/images/placeholder.png',
      ],
      caption: 'Portrait study series in oils.',
      skills: const [],
      timestamp: now.subtract(const Duration(hours: 2)),
      likesCount: 58,
      commentsCount: 7,
      aspectRatio: 1.0,
    ),
    Post(
      id: 'local_3',
      userId: 'local',
      type: PostType.video,
      mediaUrl: 'https://example.com/video.mp4',
      thumbnailUrl: 'assets/images/placeholder.png',
      caption: 'Quick tips for depth with layering.',
      skills: const [],
      timestamp: now.subtract(const Duration(days: 1)),
      likesCount: 102,
      commentsCount: 14,
      aspectRatio: 16 / 9,
    ),
  ];
}
