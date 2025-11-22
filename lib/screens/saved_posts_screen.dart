import 'dart:async';

import 'package:flutter/material.dart';

import '../models/post.dart';
import '../services/saved_posts_service.dart';
import '../theme/scale.dart';
import '../widgets/post_card.dart';

class SavedPostsScreen extends StatefulWidget {
  const SavedPostsScreen({super.key});

  @override
  State<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends State<SavedPostsScreen> {
  final _savedPostsService = SavedPostsService.instance;

  @override
  Widget build(BuildContext context) {
    final s = Scale(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Saved Posts')),
      body: StreamBuilder<List<Post>>(
        stream: _savedPostsService.streamSavedPosts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildErrorWidget(snapshot.error.toString());
          }

          final posts = snapshot.data ?? [];

          if (posts.isEmpty) {
            return _buildEmptyWidget();
          }

          return RefreshIndicator(
            onRefresh: _refreshSavedPosts,
            child: ListView.separated(
              padding: EdgeInsets.all(s.size(8)),
              itemCount: posts.length,
              separatorBuilder: (context, index) =>
                  SizedBox(height: s.size(12)),
              itemBuilder: (context, index) {
                final post = posts[index];
                return PostCard(
                  post: post,
                  // Remove the onCommentTap override to use default behavior
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyWidget() {
    final s = Scale(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(s.size(24)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border,
              size: s.size(64),
              color: Colors.grey[400],
            ),
            SizedBox(height: s.size(16)),
            Text(
              'No Saved Posts',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
            ),
            SizedBox(height: s.size(8)),
            Text(
              'Posts you save will appear here',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: s.size(24)),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.explore),
              label: const Text('Explore Posts'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    final s = Scale(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(s.size(24)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: s.size(64), color: Colors.red[400]),
            SizedBox(height: s.size(16)),
            Text(
              'Something went wrong',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: Colors.red[600]),
            ),
            SizedBox(height: s.size(8)),
            Text(
              'Failed to load saved posts',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: s.size(16)),
            FilledButton.icon(
              onPressed: () {
                setState(() {
                  // Trigger rebuild to retry
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshSavedPosts() async {
    // The StreamBuilder will automatically update when data changes
    // This method is here for the RefreshIndicator
    try {
      await _savedPostsService.cleanupSavedPosts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }
}
