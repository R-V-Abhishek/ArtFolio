import 'dart:async';
import 'package:flutter/material.dart';
import '../models/post.dart';
import '../models/user.dart' as model;
import '../routes/app_routes.dart';
import '../routes/route_arguments.dart';
import '../services/firestore_service.dart';
import '../widgets/post_card.dart';
import '../widgets/firestore_image.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _service = FirestoreService();
  final _scroll = ScrollController();

  Timer? _debounce;
  List<Post> _postResults = [];
  List<model.User> _userResults = [];
  bool _showUsers = true;
  bool _loading = false;
  String _lastQuery = '';
  final List<String> _recent = [];

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _search(value.trim());
    });
  }

  Future<void> _search(String q) async {
    if (!mounted) return;
    if (q.isEmpty) {
      setState(() {
        _postResults = [];
        _userResults = [];
        _loading = false;
        _lastQuery = '';
      });
      return;
    }
    setState(() {
      _loading = true;
      _lastQuery = q;
    });
    try {
      // Run post and user searches in parallel
      final postsF = _service.searchPosts(q);
      final usersF = _service.searchUsers(q);
      final results = await Future.wait([postsF, usersF]);
      if (!mounted) return;
      setState(() {
        _postResults = results[0] as List<Post>;
        _userResults = results[1] as List<model.User>;
      });
      _remember(q);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Search failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _remember(String q) {
    final existing = _recent.indexWhere(
      (e) => e.toLowerCase() == q.toLowerCase(),
    );
    if (existing >= 0) {
      _recent.removeAt(existing);
    }
    _recent.insert(0, q);
    if (_recent.length > 8) _recent.removeLast();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TextField(
            controller: _controller,
            onChanged: _onChanged,
            textInputAction: TextInputAction.search,
            onSubmitted: (v) => _search(v.trim()),
            decoration: InputDecoration(
              hintText: 'Search posts, tags, skills…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _controller.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear',
                      onPressed: () {
                        _controller.clear();
                        _onChanged('');
                      },
                      icon: const Icon(Icons.close),
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => FocusScope.of(context).unfocus(),
          child: _buildBody(context),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_controller.text.isEmpty) {
      return _buildSuggestions(context);
    }
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if ((_showUsers ? _userResults : _postResults).isEmpty) {
      return _emptyState(context);
    }
    return ListView.separated(
      controller: _scroll,
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).viewPadding.bottom + 16,
      ),
      itemCount:
          _showUsers ? _userResults.length : _postResults.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _showUsers
          ? _UserRow(user: _userResults[index])
          : PostCard(post: _postResults[index]),
    );
  }

  Widget _buildSuggestions(BuildContext context) {
    if (_recent.isEmpty) {
      return _emptyState(context);
    }
    return ListView(
      padding: EdgeInsets.fromLTRB(
        12,
        12,
        12,
        MediaQuery.of(context).viewPadding.bottom + 16,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Users')),
              ButtonSegment(value: false, label: Text('Posts')),
            ],
            selected: {_showUsers},
            onSelectionChanged: (s) => setState(() => _showUsers = s.first),
          ),
        ),
        const SizedBox(height: 8),
        Text('Recent searches', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final q in _recent)
              InputChip(
                label: Text(q),
                onPressed: () {
                  _controller.text = q;
                  _onChanged(q);
                },
                onDeleted: () {
                  setState(() => _recent.remove(q));
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_rounded,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              _controller.text.isEmpty
                  ? 'Search users or posts'
                  : 'No results for "$_lastQuery"',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _showUsers
                  ? 'Try searching by username or name'
                  : 'Try searching by caption, tags, or skills',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  final model.User user;
  const _UserRow({required this.user});

  @override
  Widget build(BuildContext context) {
    final ref = user.profilePictureUrl.trim();
    Widget avatar;
    if (ref.isEmpty) {
      avatar = Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: Text(
          (user.username.isNotEmpty ? user.username[0] : 'A').toUpperCase(),
        ),
      );
    } else if (ref.startsWith('http')) {
      avatar = Image.network(
        ref,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => Center(
          child: Text(
            (user.username.isNotEmpty ? user.username[0] : 'A').toUpperCase(),
          ),
        ),
      );
    } else if (ref.startsWith('assets/')) {
      avatar = Image.asset(
        ref,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => Center(
          child: Text(
            (user.username.isNotEmpty ? user.username[0] : 'A').toUpperCase(),
          ),
        ),
      );
    } else {
      avatar = FirestoreImage(imageId: ref, fit: BoxFit.cover);
    }

    return ListTile(
      leading: SizedBox(
        width: 40,
        height: 40,
        child: ClipOval(child: avatar),
      ),
      title: Text(user.fullName.isNotEmpty ? user.fullName : user.username),
      subtitle: Text('@${user.username}'),
      onTap: () {
        Navigator.of(context).pushNamed(
          AppRoutes.profile,
          arguments: ProfileArguments(userId: user.id),
        );
      },
    );
  }
}
