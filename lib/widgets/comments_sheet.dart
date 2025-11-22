import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import '../models/comment.dart';
import '../services/firestore_service.dart';
import '../theme/scale.dart';

class CommentsSheet extends StatefulWidget {
  const CommentsSheet({
    super.key,
    required this.postId,
    this.allowComments = true,
  });
  final String postId;
  final bool allowComments;

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final _auth = fb.FirebaseAuth.instance;
  final _service = FirestoreService();
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to comment')),
      );
      return;
    }
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await _service.addComment(postId: widget.postId, userId: uid, text: text);
      _controller.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to comment: $e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = Scale(context);

    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: viewInsets),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: s.size(16),
                  vertical: s.size(8),
                ),
                child: Row(
                  children: [
                    Text(
                      'Comments',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: s.font(
                          theme.textTheme.titleMedium?.fontSize ?? 16,
                        ),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 0),
              Expanded(
                child: StreamBuilder<List<Comment>>(
                  stream: _service.streamComments(widget.postId, limit: 200),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final items = snap.data ?? const <Comment>[];
                    if (items.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.all(s.size(24)),
                          child: Text(
                            'No comments yet. Be the first!',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.only(bottom: s.size(8)),
                      itemCount: items.length,
                      separatorBuilder: (_, index) => const Divider(height: 0),
                      itemBuilder: (context, i) {
                        final c = items[i];
                        final isCurrentUser =
                            _auth.currentUser?.uid == c.userId;

                        return DecoratedBox(
                          decoration: isCurrentUser
                              ? BoxDecoration(
                                  color: theme.colorScheme.primaryContainer
                                      .withValues(alpha: 0.1),
                                  border: Border(
                                    left: BorderSide(
                                      color: theme.colorScheme.primary,
                                      width: 3,
                                    ),
                                  ),
                                )
                              : const BoxDecoration(),
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: s.size(18),
                              backgroundColor: isCurrentUser
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.surfaceContainerHighest,
                              backgroundImage: c.avatarUrl.startsWith('http')
                                  ? NetworkImage(c.avatarUrl)
                                  : null,
                              child: c.avatarUrl.isEmpty
                                  ? Text(
                                      (c.username.isNotEmpty
                                              ? c.username[0]
                                              : 'U')
                                          .toUpperCase(),
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(
                                            color: isCurrentUser
                                                ? theme.colorScheme.onPrimary
                                                : null,
                                          ),
                                    )
                                  : null,
                            ),
                            title: Row(
                              children: [
                                Text(
                                  c.username,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: isCurrentUser
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                                if (isCurrentUser) ...[
                                  SizedBox(width: s.size(6)),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: s.size(6),
                                      vertical: s.size(2),
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      borderRadius: BorderRadius.circular(
                                        s.size(8),
                                      ),
                                    ),
                                    child: Text(
                                      'You',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: theme.colorScheme.onPrimary,
                                            fontSize: s.font(10),
                                          ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            subtitle: Text(c.text),
                            trailing: Text(
                              _timeAgo(c.createdAt),
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              if (widget.allowComments)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      s.size(12),
                      s.size(6),
                      s.size(12),
                      s.size(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            minLines: 1,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              hintText: 'Add a comment…',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onSubmitted: (_) => _send(),
                          ),
                        ),
                        SizedBox(width: s.size(8)),
                        IconButton(
                          onPressed: _sending ? null : _send,
                          icon: _sending
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.send),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Padding(
                  padding: EdgeInsets.all(s.size(16)),
                  child: Text(
                    'Comments are turned off for this post',
                    style: theme.textTheme.bodyMedium,
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
    if (diff.inSeconds < 60) return 'now';
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
