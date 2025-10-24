import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';

import '../models/post.dart';
import '../models/user.dart' as model;
import '../routes/app_routes.dart';
import '../routes/route_arguments.dart';
import '../services/firestore_service.dart';
import '../services/saved_posts_service.dart';
import '../services/share_service.dart';
import '../theme/scale.dart';
import 'comments_sheet.dart';
import 'firestore_image.dart';
import 'share_options_sheet.dart';

class PostCard extends StatefulWidget {

  const PostCard({super.key, required this.post, this.onCommentTap});
  final Post post;
  final VoidCallback? onCommentTap;

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with TickerProviderStateMixin {
  final _auth = fb.FirebaseAuth.instance;
  final _firestore = FirestoreService();
  final _savedPostsService = SavedPostsService.instance;

  // Local optimistic state
  late int _likesCount;
  late int _commentsCount; // Add local comment count
  late bool _isLiked;
  late bool _isSaved; // Add saved state
  int _currentPage = 0; // for gallery
  model.User? _author;
  bool _incrementedView = false;
  bool _isFollowing = false;
  bool _followBusy = false;
  bool _showFollow = false;
  bool _showMeta = false; // toggles tags + location visibility

  // Like animations
  late final AnimationController _likeOverlayCtrl;
  late final AnimationController _iconBurstCtrl;
  bool _showOverlay = false;

  @override
  void initState() {
    super.initState();
    _likesCount = widget.post.likesCount;
    _commentsCount =
        widget.post.commentsCount; // Initialize local comment count
    final uid = _auth.currentUser?.uid;
    _isLiked = uid != null && widget.post.likedBy.contains(uid);
    _isSaved = false; // Initialize as false, will be loaded async
    _loadAuthor();
    _loadSavedState();

    _likeOverlayCtrl =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1600),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            if (mounted) setState(() => _showOverlay = false);
          }
        });
    _iconBurstCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
  }

  @override
  void dispose() {
    _likeOverlayCtrl.dispose();
    _iconBurstCtrl.dispose();
    super.dispose();
  }

  void _startLikeAnimations() {
    setState(() => _showOverlay = true);
    _likeOverlayCtrl.forward(from: 0);
    _iconBurstCtrl.forward(from: 0);
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

  Future<void> _refreshCommentCount() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.post.id)
          .get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _commentsCount = data['commentsCount'] ?? 0;
        });
      }
    } catch (e) {
      // Ignore errors silently for now
    }
  }

  Future<void> _loadSavedState() async {
    try {
      final isSaved = await _savedPostsService.isPostSaved(widget.post.id);
      if (mounted) {
        setState(() {
          _isSaved = isSaved;
        });
      }
    } catch (e) {
      // Ignore errors silently for saved state loading
    }
  }

  Future<void> _toggleSave() async {
    try {
      setState(() {
        _isSaved = !_isSaved; // Optimistic update
      });

      final newSavedState = await _savedPostsService.togglePostSave(widget.post.id);
      
      if (mounted) {
        setState(() {
          _isSaved = newSavedState;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newSavedState ? 'Post saved' : 'Post unsaved'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      // Revert optimistic update on error
      if (mounted) {
        setState(() {
          _isSaved = !_isSaved;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${_isSaved ? 'unsave' : 'save'} post: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
      if (_isLiked) {
        _startLikeAnimations();
      }
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
              GestureDetector(
                onTap: () {
                  if (_author != null) {
                    Navigator.of(context).pushNamed(
                      AppRoutes.profile,
                      arguments: ProfileArguments(userId: _author!.id),
                    );
                  }
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: s.size(36),
                      height: s.size(36),
                      child: ClipOval(
                        child: Builder(
                          builder: (context) {
                            final name =
                                (_author != null &&
                                    _author!.username.isNotEmpty)
                                ? _author!.username[0].toUpperCase()
                                : 'A';
                            if (_author == null ||
                                _author!.profilePictureUrl.isEmpty) {
                              return Container(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                alignment: Alignment.center,
                                child: Text(
                                  name,
                                  style: theme.textTheme.labelLarge,
                                ),
                              );
                            }
                            final ref = _author!.profilePictureUrl;
                            if (ref.startsWith('http')) {
                              return Image.network(
                                ref,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      color: theme
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      alignment: Alignment.center,
                                      child: Text(
                                        name,
                                        style: theme.textTheme.labelLarge,
                                      ),
                                    ),
                              );
                            }
                            if (ref.startsWith('assets/')) {
                              return Image.asset(
                                ref,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      color: theme
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      alignment: Alignment.center,
                                      child: Text(
                                        name,
                                        style: theme.textTheme.labelLarge,
                                      ),
                                    ),
                              );
                            }
                            // Firestore image id
                            return FirestoreImage(
                              imageId: ref,
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(width: s.size(10)),
                    Column(
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
                  ],
                ),
              ),
              const Spacer(),
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
              SizedBox(
                width: s.size(48),
                height: s.size(48),
                child: Stack(
                  alignment: Alignment.center,
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
                    IgnorePointer(
                      child: _MiniBurst(
                        animation: _iconBurstCtrl,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                iconSize: s.size(28),
                onPressed:
                    widget.onCommentTap ??
                    () async {
                      await showModalBottomSheet(
                        context: context,
                        useSafeArea: true,
                        isScrollControlled: true,
                        showDragHandle: true,
                        builder: (_) => CommentsSheet(
                          postId: widget.post.id,
                          allowComments: widget.post.allowComments,
                        ),
                      );
                      // Refresh comment count after the sheet closes
                      unawaited(_refreshCommentCount());
                    },
                icon: const Icon(Icons.mode_comment_outlined),
              ),
              IconButton(
                iconSize: s.size(28),
                onPressed: () async {
                  try {
                    await ShareService.instance.sharePost(
                      widget.post,
                      author: _author,
                    );
                    // Increment share count optimistically
                    await _firestore.incrementPostShares(widget.post.id);
                  } catch (e) {
                    if (mounted && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to share: $e')),
                      );
                    }
                  }
                },
                onLongPress: () {
                  showModalBottomSheet<void>(
                    context: context,
                    showDragHandle: true,
                    builder: (context) => ShareOptionsSheet(
                      post: widget.post,
                      onShareComplete: () async {
                        try {
                          await _firestore.incrementPostShares(widget.post.id);
                        } catch (e) {
                          // Ignore error for now
                        }
                      },
                    ),
                  );
                },
                icon: const Icon(Icons.send_outlined),
              ),
              const Spacer(),
              IconButton(
                iconSize: s.size(24),
                icon: Icon(
                  _isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: _isSaved ? Theme.of(context).primaryColor : null,
                ),
                onPressed: _toggleSave,
              ),
            ],
          ),
        ),

        // Counts
        Padding(
          padding: EdgeInsets.symmetric(horizontal: s.size(16)),
          child: Text(
            '$_likesCount likes  •  $_commentsCount comments',
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
              s.size(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: s.font(
                        theme.textTheme.bodyMedium?.fontSize ?? 14,
                      ),
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
                  maxLines: _showMeta ? null : 3,
                  overflow: _showMeta ? TextOverflow.visible : TextOverflow.ellipsis,
                ),
                // Show "more" button if caption is long or if there are tags/location to show
                if (!_showMeta && (_isLongCaption() || _hasMetaToShow()))
                  InkWell(
                    onTap: () => setState(() => _showMeta = true),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'more',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outline,
                          fontSize: s.font(
                            theme.textTheme.bodyMedium?.fontSize ?? 14,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

        // Tags row (if any)
        if (_showMeta && widget.post.tags.isNotEmpty)
          Padding(
            padding: EdgeInsets.fromLTRB(s.size(12), 0, s.size(12), s.size(8)),
            child: _TagsWrap(tags: widget.post.tags),
          ),

        // Location (if any)
        if (_showMeta && widget.post.location != null)
          Padding(
            padding: EdgeInsets.fromLTRB(s.size(16), 0, s.size(16), s.size(10)),
            child: Row(
              children: [
                Icon(
                  Icons.place_outlined,
                  size: s.size(16),
                  color: theme.colorScheme.outline,
                ),
                SizedBox(width: s.size(6)),
                Flexible(
                  child: Text(
                    _formatLocation(widget.post.location!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

        // Less button when meta is shown
        if (_showMeta && (_isLongCaption() || _hasMetaToShow()))
          Padding(
            padding: EdgeInsets.fromLTRB(s.size(16), 0, s.size(16), s.size(8)),
            child: InkWell(
              onTap: () => setState(() => _showMeta = false),
              child: Text(
                'less',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                  fontSize: s.font(
                    theme.textTheme.bodyMedium?.fontSize ?? 14,
                  ),
                ),
              ),
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
    return FirestoreImage(imageId: ref);
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
          if (thumb.isNotEmpty) _buildImage(thumb) else Container(
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
      onDoubleTap: () {
        if (!_isLiked) {
          _toggleLike();
        } else {
          _startLikeAnimations();
        }
      },
      onTap: _ensureViewIncremented,
      child: AspectRatio(
        aspectRatio: aspect,
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              child,
              if (_showOverlay)
                IgnorePointer(
                  child: Center(
                    child: _LikeOverlay(
                      animation: _likeOverlayCtrl,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
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

  String _formatLocation(PostLocation loc) {
    final parts = [
      loc.city,
      loc.state,
      loc.country,
    ].where((e) => (e ?? '').trim().isNotEmpty).map((e) => e!.trim()).toList();
    return parts.isEmpty ? 'Unknown location' : parts.join(', ');
  }

  bool _isLongCaption() => widget.post.caption.length > 100;

  bool _hasMetaToShow() => widget.post.tags.isNotEmpty || widget.post.location != null;
}

class _TagsWrap extends StatelessWidget {
  const _TagsWrap({required this.tags});
  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const maxToShow = 3;
    final shown = tags.take(maxToShow).toList();
    final hidden = tags.length - shown.length;
    final text = [
      for (final t in shown) '#$t',
      if (hidden > 0) '+$hidden',
    ].join(' ');
    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(color: Colors.blue),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _NetworkImage extends StatelessWidget {
  const _NetworkImage({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) => Image.network(
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

class _GalleryDots extends StatelessWidget {
  const _GalleryDots({required this.length, required this.current});
  final int length;
  final int current;

  @override
  Widget build(BuildContext context) => DecoratedBox(
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

class _LikeOverlay extends StatelessWidget {
  const _LikeOverlay({required this.animation, required this.color});
  final Animation<double> animation;
  final Color color;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = Curves.easeOutCubic.transform(animation.value);
        final ringScale1 = 0.6 + 0.5 * t;
        final ringScale2 = 0.8 + 0.9 * t;
        final ringOpacity = (1.0 - t).clamp(0.0, 1.0);
        final heartScale = 1.0 + 0.25 * Curves.elasticOut.transform(t);
        const fadeStart = 0.6; // keep fully visible for 60% of the timeline
        final heartOpacity = t < fadeStart
            ? 1.0
            : (1.0 -
                      Curves.easeOut.transform(
                        ((t - fadeStart) / (1 - fadeStart)).clamp(0.0, 1.0),
                      ))
                  .clamp(0.0, 1.0);
        return SizedBox(
          width: 220,
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: ringOpacity * 0.5,
                child: Transform.scale(
                  scale: ringScale2,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color.withValues(alpha: 0.35),
                        width: 6 * (1.0 - t) + 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              Opacity(
                opacity: ringOpacity * 0.8,
                child: Transform.scale(
                  scale: ringScale1,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color.withValues(alpha: 0.45),
                        width: 8 * (1.0 - t) + 2,
                      ),
                    ),
                  ),
                ),
              ),
              Opacity(
                opacity: heartOpacity,
                child: Transform.scale(
                  scale: heartScale,
                  child: const Icon(
                    Icons.favorite,
                    size: 96,
                    color: Color(0xFFFF8DA1), // subtle pink
                  ),
                ),
              ),
              // Sparkles (gold) - 5 rays moving from heart to ring, fading with the heart
              ...List.generate(5, (i) {
                const step = 360 / 5;
                final angle = -18 + step * i;
                const startR = 14.0;
                const endR = 105.0; // approx outer ring radius
                return _Sparkle(
                  angleDeg: angle,
                  startRadius: startR,
                  endRadius: endR,
                  t: t,
                  color: const Color(0xFFFFD700), // gold
                  opacity: heartOpacity,
                );
              }),
            ],
          ),
        );
      },
    );
}

class _Sparkle extends StatelessWidget { // typically synced with heartOpacity
  const _Sparkle({
    required this.angleDeg,
    required this.startRadius,
    required this.endRadius,
    required this.t,
    required this.color,
    required this.opacity,
  });
  final double angleDeg;
  final double startRadius;
  final double endRadius;
  final double t;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final rad = angleDeg * math.pi / 180;
    final p = Curves.easeOut.transform(t);
    final r = startRadius + (endRadius - startRadius) * p;
    final dx = math.cos(rad) * r;
    final dy = math.sin(rad) * r;
    final scale =
        0.8 + 0.3 * Curves.easeOut.transform(1 - (t - 0.1).clamp(0, 1));
    return Transform.translate(
      offset: Offset(dx, dy),
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: opacity,
          child: Icon(
            Icons.star_rounded,
            color: color.withValues(alpha: 0.95),
            size: 16,
          ),
        ),
      ),
    );
  }
}

class _MiniBurst extends StatelessWidget {
  const _MiniBurst({required this.animation, required this.color});
  final Animation<double> animation;
  final Color color;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        if (animation.value <= 0.001) return const SizedBox.shrink();
        return CustomPaint(
          painter: _MiniBurstPainter(animation.value, const Color(0xFFFFD700)),
          size: const Size(40, 40),
        );
      },
    );
}

class _MiniBurstPainter extends CustomPainter {
  _MiniBurstPainter(this.v, this.color);
  final double v;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: (1.0 - v).clamp(0.0, 1.0));
    final center = Offset(size.width / 2, size.height / 2);
    const count = 8;
    final baseR = size.shortestSide * 0.2;
    final maxRadius = size.shortestSide * 0.9 * Curves.easeOut.transform(v);
    for (var i = 0; i < count; i++) {
      final angle = (2 * math.pi * i / count) + (v * 2 * math.pi * 0.2);
      final r = maxRadius;
      final pos = Offset(
        center.dx + math.cos(angle) * r,
        center.dy + math.sin(angle) * r,
      );
      final dotR = baseR * (1.0 - v * 0.8);
      canvas.drawCircle(pos, dotR, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MiniBurstPainter oldDelegate) => oldDelegate.v != v || oldDelegate.color != color;
}
