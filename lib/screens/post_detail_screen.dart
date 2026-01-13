import 'package:flutter/material.dart';

import '../models/post.dart';
import '../widgets/post_card.dart';

class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({
    super.key,
    required this.posts,
    this.initialIndex = 0,
  });
  final List<Post> posts;
  final int initialIndex;

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _listController = ScrollController();
  late final int _initialIndex;
  late List<Post> _posts;
  final _initialItemKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _posts = List.of(widget.posts);
    _initialIndex = widget.initialIndex.clamp(0, _posts.length - 1);
    // Scroll to the initially selected post after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _initialItemKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 1),
        );
      }
    });
  }

  @override
  void dispose() {
    _listController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Post'),
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView.builder(
        controller: _listController,
        padding: EdgeInsets.zero,
        itemCount: _posts.length,
        itemBuilder: (context, i) {
          final post = _posts[i];
          final key = i == _initialIndex ? _initialItemKey : null;
          return KeyedSubtree(
            key: key,
            child: PostCard(
              post: post,
              onDeleted: () {
                setState(() {
                  _posts.removeAt(i);
                  if (_posts.isEmpty) {
                    Navigator.of(context).pop();
                    return;
                  }
                });
              },
              onHidden: () {
                if (_posts.length <= 1) {
                  // Last post: keep existing behavior (pop)
                  setState(() {
                    _posts.removeAt(i);
                    if (_posts.isEmpty) Navigator.of(context).pop();
                  });
                  return;
                }
                final removedIndex = i;
                final removed = post;
                setState(() {
                  _posts.removeAt(i);
                });
                ScaffoldMessenger.of(context)
                  ..clearSnackBars()
                  ..showSnackBar(
                    SnackBar(
                      content: const Text('Post hidden'),
                      action: SnackBarAction(
                        label: 'Undo',
                        onPressed: () {
                          if (!mounted) return;
                          setState(() {
                            final insertAt = removedIndex.clamp(
                              0,
                              _posts.length,
                            );
                            _posts.insert(insertAt, removed);
                          });
                          // Ensure the restored item is visible
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            final ctx = key?.currentContext;
                            if (ctx != null) {
                              Scrollable.ensureVisible(
                                ctx,
                                duration: const Duration(milliseconds: 200),
                              );
                            }
                          });
                        },
                      ),
                    ),
                  );
              },
            ),
          );
        },
      ),
    );
  }
}
