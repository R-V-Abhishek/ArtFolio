import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';

import '../models/user.dart' as model;
import '../services/firestore_service.dart';
import 'profile_screen.dart';

enum FollowListType { followers, following }

class FollowListScreen extends StatefulWidget {
  final String userId; // whose followers/following to show
  final FollowListType type;
  const FollowListScreen({super.key, required this.userId, required this.type});

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen> {
  final _auth = fb.FirebaseAuth.instance;
  final _firestore = FirestoreService();

  List<model.User> _users = const [];
  bool _loading = true;
  final Map<String, bool> _isFollowing = {};
  final Map<String, bool> _busy = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      List<model.User> users;
      if (widget.type == FollowListType.followers) {
        users = await _firestore.getFollowersUsers(widget.userId);
      } else {
        users = await _firestore.getFollowingUsers(widget.userId);
      }

      // Prime following state relative to current viewer
      final viewerId = _auth.currentUser?.uid;
      if (viewerId != null) {
        for (final u in users) {
          if (u.id == viewerId) {
            _isFollowing[u.id] = false; // self - hide button later
            continue;
          }
          try {
            final f = await _firestore.isFollowing(viewerId, u.id);
            _isFollowing[u.id] = f;
          } catch (_) {}
        }
      }

      if (!mounted) return;
      setState(() {
        _users = users;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load: $e')));
    }
  }

  Future<void> _toggleFollow(String targetId) async {
    final viewerId = _auth.currentUser?.uid;
    if (viewerId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sign in to follow users')));
      return;
    }
    if (_busy[targetId] == true) return;
    setState(() => _busy[targetId] = true);
    final current = _isFollowing[targetId] ?? false;
    setState(() => _isFollowing[targetId] = !current);
    try {
      final nowFollowing = await _firestore.toggleFollow(
        viewerUserId: viewerId,
        targetUserId: targetId,
      );
      if (!mounted) return;
      setState(() {
        _isFollowing[targetId] = nowFollowing;
        _busy[targetId] = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isFollowing[targetId] = current;
        _busy[targetId] = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.type == FollowListType.followers
        ? 'Followers'
        : 'Following';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                itemCount: _users.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final u = _users[index];
                  final viewerId = _auth.currentUser?.uid;
                  final canFollow = (viewerId != null && viewerId != u.id);
                  final following = _isFollowing[u.id] ?? false;
                  final busy = _busy[u.id] == true;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      child: Text(
                        (u.username.isNotEmpty ? u.username[0] : 'A')
                            .toUpperCase(),
                      ),
                    ),
                    title: Text(u.username),
                    subtitle: u.fullName.isNotEmpty ? Text(u.fullName) : null,
                    trailing: canFollow
                        ? TextButton.icon(
                            onPressed: busy ? null : () => _toggleFollow(u.id),
                            icon: Icon(
                              following ? Icons.check : Icons.person_add_alt_1,
                            ),
                            label: Text(following ? 'Following' : 'Follow'),
                          )
                        : null,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ProfileScreen(userId: u.id),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
    );
  }
}
