import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';

import '../models/post.dart';
import '../models/user.dart' as model;
import '../services/firestore_service.dart';
import 'firestore_image.dart';
import '../theme/scale.dart';
import 'comments_sheet.dart';

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
  bool _isFollowing = false;
  bool _followBusy = false;
  bool _showFollow = false;

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
      // Determine follow visibility and initial state (any user can be followed)
      final viewerId = _auth.currentUser?.uid;
      if (viewerId != null && user != null && user.id != viewerId) {
        try {
          final f = await _firestore.isFollowing(viewerId, user.id);
          if (mounted) {
            setState(() {
              _isFollowing = f;
              _showFollow = true;
            });
          }
        } catch (_) {
          if (mounted) setState(() => _showFollow = true);
        }
      } else if (mounted) {
        setState(() => _showFollow = false);
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

  Future<void> _toggleFollowAuthor() async {
    if (_followBusy) return;
    final viewerId = _auth.currentUser?.uid;
    final targetId = _author?.id;
    if (viewerId == null || targetId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign in to follow artists')),
        );
      }
      return;
    }
    setState(() {
      _followBusy = true;
      _isFollowing = !_isFollowing; // optimistic
    });
    try {
      final nowFollowing = await _firestore.toggleFollow(
        viewerUserId: viewerId,
        targetUserId: targetId,
      );
      if (mounted) {
        setState(() {
          _isFollowing = nowFollowing;
          _followBusy = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(nowFollowing ? 'Started following' : 'Unfollowed'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFollowing = !_isFollowing; // revert
          _followBusy = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = Scale(context);
    final radius = BorderRadius.circular(16);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: s.size(12),
            vertical: s.size(8),
          ),
          child: Row(
            children: [
              SizedBox(
                width: s.size(36),
                height: s.size(36),
                child: ClipOval(
                  child:
                      ((_author != null) &&
                          _author!.profilePictureUrl.isNotEmpty)
                      ? (_author!.profilePictureUrl.startsWith('http')
                            ? Image.network(
                                _author!.profilePictureUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      color: theme
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      alignment: Alignment.center,
                                      child: Text(
                                        ((_author != null &&
                                                    _author!
                                                        .username
                                                        .isNotEmpty)
                                                ? _author!.username[0]
                                                : 'A')
                                            .toUpperCase(),
                                        style: theme.textTheme.labelLarge,
                                      ),
                                    ),
                              )
                            : Image.asset(
                                _author!.profilePictureUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      color: theme
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      alignment: Alignment.center,
                                      child: Text(
                                        ((_author != null &&
                                                    _author!
                                                        .username
                                                        .isNotEmpty)
                                                ? _author!.username[0]
                                                : 'A')
                                            .toUpperCase(),
                                        style: theme.textTheme.labelLarge,
                                      ),
                                    ),
                              ))
                      : Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          alignment: Alignment.center,
                          child: Text(
                            ((_author != null && _author!.username.isNotEmpty)
                                    ? _author!.username[0]
                                    : 'A')
                                .toUpperCase(),
                            style: theme.textTheme.labelLarge,
                          ),
                        ),
                ),
              ),
              SizedBox(width: s.size(10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _author?.username ?? 'Unknown',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: s.font(
                          theme.textTheme.titleSmall?.fontSize ?? 14,
                        ),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _timeAgo(widget.post.timestamp),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withValues(
                          alpha: 0.7,
                        ),
                        fontSize: s.font(
                          theme.textTheme.bodySmall?.fontSize ?? 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_showFollow)
                Padding(
                  padding: EdgeInsets.only(right: s.size(6)),
                  child: ActionChip(
                    avatar: Icon(
                      _isFollowing ? Icons.check : Icons.person_add_alt_1,
                      size: s.size(16),
                    ),
                    label: Text(_isFollowing ? 'Following' : 'Follow'),
                    onPressed: _followBusy ? null : _toggleFollowAuthor,
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              IconButton(
                iconSize: s.size(24),
                icon: const Icon(Icons.more_horiz),
                onPressed: () {},
              ),
            ],
          ),
        ),

        // Media
        _buildMedia(context, radius),

        // Actions
        Padding(
          padding: EdgeInsets.symmetric(horizontal: s.size(8)),
          child: Row(
            children: [
              IconButton(
                iconSize: s.size(28),
                onPressed: _toggleLike,
                icon: Icon(
                  _isLiked ? Icons.favorite : Icons.favorite_border,
                  color: _isLiked
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurface,
                ),
              ),
              IconButton(
                iconSize: s.size(28),
                onPressed:
                    widget.onCommentTap ??
                    () {
                      showModalBottomSheet(
                        context: context,
                        useSafeArea: true,
                        isScrollControlled: true,
                        showDragHandle: true,
                        builder: (_) => CommentsSheet(
                          postId: widget.post.id,
                          allowComments: widget.post.allowComments,
                        ),
                      );
                    },
                icon: const Icon(Icons.mode_comment_outlined),
              ),
              IconButton(
                iconSize: s.size(28),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Share coming soon')),
                  );
                },
                icon: const Icon(Icons.send_outlined),
              ),
              const Spacer(),
              IconButton(
                iconSize: s.size(24),
                icon: const Icon(Icons.bookmark_border),
                onPressed: () {},
              ),
            ],
          ),
        ),

        // Counts
        Padding(
          padding: EdgeInsets.symmetric(horizontal: s.size(16)),
          child: Text(
            '$_likesCount likes  •  ${widget.post.commentsCount} comments',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: s.font(theme.textTheme.bodyMedium?.fontSize ?? 14),
            ),
          ),
        ),

        // Caption
        if (widget.post.caption.isNotEmpty)
          Padding(
            padding: EdgeInsets.fromLTRB(
              s.size(16),
              s.size(6),
              s.size(16),
              s.size(12),
            ),
            child: RichText(
              text: TextSpan(
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: s.font(theme.textTheme.bodyMedium?.fontSize ?? 14),
                ),
                children: [
                  TextSpan(
                    text: '${_author?.username ?? 'artist'} ',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: s.font(
                        theme.textTheme.bodyMedium?.fontSize ?? 14,
                      ),
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

  // Selects appropriate image widget: FirestoreImage for non-URL IDs, Image.network for URLs
  Widget _buildImage(String ref) {
    final isUrl = ref.startsWith('http://') || ref.startsWith('https://');
    if (isUrl) {
      return _NetworkImage(url: ref);
    }
    // Treat as Firestore image document ID
    return FirestoreImage(imageId: ref, fit: BoxFit.cover);
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
              return _buildImage(url);
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
          ? _buildImage(url)
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
              ? _buildImage(thumb)
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
