import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';

import '../models/post.dart';
import '../models/user.dart' as model;
import '../services/firestore_service.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final VoidCallback? onCommentTap;

  const PostCard({super.key, required this.post, this.onCommentTap});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final _auth = fb.FirebaseAuth.instance;
  final _firestore = FirestoreService();

  // Local optimistic state
  late int _likesCount;
  late bool _isLiked;
  int _currentPage = 0; // for gallery
  model.User? _author;
  bool _incrementedView = false;

  @override
  void initState() {
    super.initState();
    _likesCount = widget.post.likesCount;
    final uid = _auth.currentUser?.uid;
    _isLiked = uid != null && widget.post.likedBy.contains(uid);
    _loadAuthor();
  }

  Future<void> _loadAuthor() async {
    try {
      final user = await _firestore.getUser(widget.post.userId);
      if (mounted) {
        setState(() {
          _author = user;
        });
      }
    } catch (_) {
      // ignore
    }
  }

  void _ensureViewIncremented() {
    if (_incrementedView) {
      return;
    }
    _incrementedView = true;
    _firestore.incrementPostViews(widget.post.id).catchError((_) {});
  }

  Future<void> _toggleLike() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Sign in to like posts')));
      }
      return;
    }

    setState(() {
      _isLiked = !_isLiked;
      _likesCount += _isLiked ? 1 : -1;
    });

    try {
      await _firestore.togglePostLike(widget.post.id, uid);
    } catch (e) {
      // Revert on failure
      if (mounted) {
        setState(() {
          _isLiked = !_isLiked;
          _likesCount += _isLiked ? 1 : -1;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update like: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(16);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                backgroundImage:
                    ((_author != null) && _author!.profilePictureUrl.isNotEmpty)
                    ? NetworkImage(_author!.profilePictureUrl)
                    : null,
                child:
                    ((_author != null) && _author!.profilePictureUrl.isNotEmpty)
                    ? null
                    : Text(
                        ((_author != null && _author!.username.isNotEmpty)
                                ? _author!.username[0]
                                : 'A')
                            .toUpperCase(),
                        style: theme.textTheme.labelLarge,
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _author?.username ?? 'Unknown',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _timeAgo(widget.post.timestamp),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(icon: const Icon(Icons.more_horiz), onPressed: () {}),
            ],
          ),
        ),

        // Media
        _buildMedia(context, radius),

        // Actions
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              IconButton(
                iconSize: 28,
                onPressed: _toggleLike,
                icon: Icon(
                  _isLiked ? Icons.favorite : Icons.favorite_border,
                  color: _isLiked
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurface,
                ),
              ),
              IconButton(
                iconSize: 28,
                onPressed:
                    widget.onCommentTap ??
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Comments coming soon')),
                      );
                    },
                icon: const Icon(Icons.mode_comment_outlined),
              ),
              IconButton(
                iconSize: 28,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Share coming soon')),
                  );
                },
                icon: const Icon(Icons.send_outlined),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.bookmark_border),
                onPressed: () {},
              ),
            ],
          ),
        ),

        // Counts
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '$_likesCount likes  •  ${widget.post.commentsCount} comments',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Caption
        if (widget.post.caption.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            child: RichText(
              text: TextSpan(
                style: theme.textTheme.bodyMedium,
                children: [
                  TextSpan(
                    text: '${_author?.username ?? 'artist'} ',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(text: widget.post.caption),
                ],
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  Widget _buildMedia(BuildContext context, BorderRadius radius) {
    final type = widget.post.type;
    final aspect = widget.post.aspectRatio ?? 1.0;

    Widget child;
    if (type == PostType.gallery &&
        (widget.post.mediaUrls?.isNotEmpty ?? false)) {
      child = Stack(
        children: [
          PageView.builder(
            itemCount: widget.post.mediaUrls!.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) {
              final url = widget.post.mediaUrls![index];
              return _NetworkImage(url: url);
            },
          ),
          // indicator
          Positioned(
            right: 8,
            top: 8,
            child: _GalleryDots(
              length: widget.post.mediaUrls!.length,
              current: _currentPage,
            ),
          ),
        ],
      );
    } else if (type == PostType.image || type == PostType.idea) {
      final url = widget.post.primaryMediaUrl;
      child = url.isNotEmpty
          ? _NetworkImage(url: url)
          : Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              alignment: Alignment.center,
              child: const Icon(Icons.image, size: 48),
            );
    } else {
      // video/reel/live
      final thumb = widget.post.thumbnailUrl ?? widget.post.primaryMediaUrl;
      child = Stack(
        fit: StackFit.expand,
        children: [
          thumb.isNotEmpty
              ? _NetworkImage(url: thumb)
              : Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
          const Center(
            child: CircleAvatar(
              radius: 28,
              backgroundColor: Colors.black54,
              child: Icon(Icons.play_arrow, color: Colors.white, size: 36),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onDoubleTap: _toggleLike,
      onTap: _ensureViewIncremented,
      child: AspectRatio(
        aspectRatio: aspect,
        child: ClipRRect(borderRadius: radius, child: child),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    final weeks = (diff.inDays / 7).floor();
    if (weeks < 5) return '${weeks}w';
    final months = (diff.inDays / 30).floor();
    if (months < 12) return '${months}mo';
    final years = (diff.inDays / 365).floor();
    return '${years}y';
  }
}

class _NetworkImage extends StatelessWidget {
  final String url;
  const _NetworkImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          alignment: Alignment.center,
          child: CircularProgressIndicator(
            value: progress.expectedTotalBytes != null
                ? progress.cumulativeBytesLoaded /
                      (progress.expectedTotalBytes ?? 1)
                : null,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image),
      ),
    );
  }
}

class _GalleryDots extends StatelessWidget {
  final int length;
  final int current;
  const _GalleryDots({required this.length, required this.current});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(length, (i) {
            final active = i == current;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: active ? 8 : 6,
              height: active ? 8 : 6,
              decoration: BoxDecoration(
                color: active ? Colors.white : Colors.white70,
                shape: BoxShape.circle,
              ),
            );
          }),
        ),
      ),
    );
  }
}
