import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';

import '../models/app_notification.dart';
import '../services/firestore_service.dart';
import '../services/share_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _auth = fb.FirebaseAuth.instance;
  final _firestore = FirestoreService();
  final _controller = ScrollController();

  final List<AppNotification> _items = [];
  DocumentSnapshot? _lastDoc;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadInitial();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    setState(() => _loading = true);
    _items.clear();
    _lastDoc = null;
    _hasMore = true;
    await _loadMore();
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _loadingMore) return;
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _hasMore = false);
      return;
    }
    setState(() => _loadingMore = true);
    try {
      final page = await _firestore.getNotificationsPage(
        userId: uid,
        startAfter: _lastDoc,
      );
      if (page.items.isEmpty) {
        _hasMore = false;
      } else {
        _items.addAll(page.items);
        _lastDoc = page.lastDoc;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load: $e')));
      }
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _onScroll() {
    if (_controller.position.pixels >=
        _controller.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  IconData _iconForType(NotificationType t) {
    switch (t) {
      case NotificationType.like:
        return Icons.favorite;
      case NotificationType.kudos:
        return Icons.auto_awesome;
      case NotificationType.comment:
        return Icons.mode_comment;
      case NotificationType.share:
        return Icons.send;
      case NotificationType.follow:
        return Icons.person_add_alt_1;
      case NotificationType.collab:
        return Icons.theater_comedy;
      case NotificationType.sponsor:
        return Icons.business_center;
      case NotificationType.orgUpdate:
        return Icons.apartment;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            onPressed: () async {
              try {
                await ShareService.instance.shareApp();
              } catch (e) {
                if (mounted) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to share app: $e')),
                    );
                  }
                }
              }
            },
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share ArtFolio',
          ),
          TextButton(
            onPressed: () async {
              final uid = _auth.currentUser?.uid;
              if (uid == null) return;
              await _firestore.markAllNotificationsRead(uid);
              if (!mounted) return;
              unawaited(_loadInitial());
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadInitial,
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewPadding.bottom,
                  ),
                  child: ListView.separated(
                    controller: _controller,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _items.length + (_loadingMore ? 1 : 0),
                    separatorBuilder: (_, i) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      if (index >= _items.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final n = _items[index];
                      return ListTile(
                        leading: Stack(
                          alignment: Alignment.topRight,
                          children: [
                            CircleAvatar(
                              backgroundColor:
                                  theme.colorScheme.surfaceContainerHighest,
                              child: Icon(
                                _iconForType(n.type),
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            if (!n.read)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.error,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        title: Text(n.title),
                        subtitle: Text(_timeAgo(n.createdAt)),
                        onTap: () async {
                          await _firestore.markNotificationRead(n.id);
                          if (!mounted) return;
                          setState(
                            () => _items[index] = AppNotification(
                              id: n.id,
                              userId: n.userId,
                              type: n.type,
                              title: n.title,
                              actorId: n.actorId,
                              postId: n.postId,
                              data: n.data,
                              createdAt: n.createdAt,
                              read: true,
                            ),
                          );
                        },
                      );
                    },
                  ),
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
}
