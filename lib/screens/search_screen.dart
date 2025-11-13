import 'dart:async';

import 'package:flutter/material.dart';

import '../models/post.dart';
import '../models/user.dart' as model;
import '../routes/app_routes.dart';
import '../routes/route_arguments.dart';
import '../services/firestore_service.dart';
import '../widgets/firestore_image.dart';
import '../widgets/post_card.dart';

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
  List<String> _tagResults = [];
  String _searchType = 'users'; // 'users', 'posts', 'tags'
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
      // Run searches based on search type
      final futures = <Future>[];
      
      if (_searchType == 'posts') {
        futures
          ..add(_service.searchPosts(q))
          ..add(_service.getReportedPostIdsForCurrentUser());
      } else if (_searchType == 'users') {
        futures.add(_service.searchUsers(q));
      } else if (_searchType == 'tags') {
        futures.add(_service.getPopularTags(limit: 50));
      }
      
      final results = await Future.wait(futures);
      if (!mounted) return;
      
      setState(() {
        if (_searchType == 'posts') {
          final posts = results[0] as List<Post>;
          final reported = results[1] as Set<String>;
          _postResults = posts.where((p) => !reported.contains(p.id)).toList();
        } else if (_searchType == 'users') {
          _userResults = results[0] as List<model.User>;
        } else if (_searchType == 'tags') {
          final allTags = results[0] as List<String>;
          _tagResults = allTags
              .where((tag) => tag.toLowerCase().contains(q.toLowerCase()))
              .toList();
        }
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

  List<dynamic> _getCurrentResults() {
    switch (_searchType) {
      case 'users':
        return _userResults;
      case 'posts':
        return _postResults;
      case 'tags':
        return _tagResults;
      default:
        return [];
    }
  }

  Widget _buildResultItem(BuildContext context, int index) {
    switch (_searchType) {
      case 'users':
        return _UserRow(user: _userResults[index]);
      case 'posts':
        return PostCard(
          post: _postResults[index],
          onHidden: () {
            final removedIndex = index;
            final removed = _postResults[index];
            setState(() => _postResults.removeAt(index));
            ScaffoldMessenger.of(context)
              ..clearSnackBars()
              ..showSnackBar(
              SnackBar(
                content: const Text('Post hidden'),
                action: SnackBarAction(
                  label: 'Undo',
                  // ignore: prefer_expression_function_bodies
                  onPressed: () {
                    if (!mounted) return;
                    setState(() {
                      final insertAt = removedIndex.clamp(0, _postResults.length);
                      _postResults.insert(insertAt, removed);
                    });
                  },
                ),
              ),
            );
          },
        );
      case 'tags':
        final tag = _tagResults[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.tag),
            ),
            title: Text('#$tag'),
            subtitle: const Text('Tap to search posts with this tag'),
            onTap: () {
              _searchType = 'posts';
              _controller.text = '#$tag';
              _search('#$tag');
            },
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
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
              hintText: 'Search posts, users, tags (#tag)...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _controller.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear',
                      // ignore: prefer_expression_function_bodies
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

  Widget _buildBody(BuildContext context) {
    if (_controller.text.isEmpty) {
      return _buildSuggestions(context);
    }
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final currentResults = _getCurrentResults();
    if (currentResults.isEmpty) {
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
      itemCount: currentResults.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: _buildResultItem,
    );
  }

  Widget _buildSuggestions(BuildContext context) {
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
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'posts', label: Text('Posts')),
              ButtonSegment(value: 'users', label: Text('Users')),
              ButtonSegment(value: 'tags', label: Text('Tags')),
            ],
            selected: {_searchType},
            onSelectionChanged: (s) => setState(() => _searchType = s.first),
          ),
        ),
        const SizedBox(height: 16),
        
        // Recent Searches Section
        if (_recent.isNotEmpty) ...[
          Row(
            children: [
              Icon(Icons.history, size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text('Recent searches', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final q in _recent)
                InputChip(
                  label: Text(q),
                  // ignore: prefer_expression_function_bodies
                  onPressed: () {
                    _controller.text = q;
                    _onChanged(q);
                  },
                  onDeleted: () => setState(() => _recent.remove(q)),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _emptyState(BuildContext context) => Center(
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
              _searchType == 'users'
                  ? 'Try searching by username or name'
                  : _searchType == 'posts'
                      ? 'Try searching by caption, tags, or skills'
                      : 'Try searching for hashtags',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
}

class _UserRow extends StatelessWidget {
  const _UserRow({required this.user});
  final model.User user;

  @override
  Widget build(BuildContext context) {
    final ref = user.profilePictureUrl.trim();
    final fallbackText = (user.username.isNotEmpty ? user.username[0] : 'A').toUpperCase();
    
    Widget avatar;
    if (ref.isEmpty) {
      avatar = Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          fallbackText,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else if (ref.startsWith('http')) {
      avatar = Image.network(
        ref,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
            ),
          );
        },
        errorBuilder: (c, e, s) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.errorContainer,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            fallbackText,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onErrorContainer,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    } else if (ref.startsWith('assets/')) {
      avatar = Image.asset(
        ref,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.errorContainer,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            fallbackText,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onErrorContainer,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    } else {
      avatar = FirestoreImage(
        imageId: ref,
        width: 50,
        height: 50,
        placeholder: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        errorWidget: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.errorContainer,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            fallbackText,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onErrorContainer,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: SizedBox(
          width: 50, 
          height: 50, 
          child: ClipOval(child: avatar),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user.fullName.isNotEmpty ? user.fullName : user.username,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getRoleColor(context, user.role),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getRoleDisplayName(user.role),
                style: TextStyle(
                  color: _getRoleTextColor(context, user.role),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('@${user.username}'),
            if (user.bio.isNotEmpty) 
              Text(
                user.bio,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios, 
          size: 16, 
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        // ignore: prefer_expression_function_bodies
        onTap: () {
          Navigator.of(context).pushNamed(
            AppRoutes.profile,
            arguments: ProfileArguments(userId: user.id),
          );
        },
      ),
    );
  }

  Color _getRoleColor(BuildContext context, model.UserRole role) {
    switch (role) {
      case model.UserRole.artist:
        return Theme.of(context).colorScheme.primaryContainer;
      case model.UserRole.sponsor:
        return Theme.of(context).colorScheme.secondaryContainer;
      case model.UserRole.organisation:
        return Theme.of(context).colorScheme.tertiaryContainer;
      case model.UserRole.audience:
        return Theme.of(context).colorScheme.surfaceContainerHighest;
    }
  }

  Color _getRoleTextColor(BuildContext context, model.UserRole role) {
    switch (role) {
      case model.UserRole.artist:
        return Theme.of(context).colorScheme.onPrimaryContainer;
      case model.UserRole.sponsor:
        return Theme.of(context).colorScheme.onSecondaryContainer;
      case model.UserRole.organisation:
        return Theme.of(context).colorScheme.onTertiaryContainer;
      case model.UserRole.audience:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  String _getRoleDisplayName(model.UserRole role) {
    switch (role) {
      case model.UserRole.artist:
        return 'Artist';
      case model.UserRole.sponsor:
        return 'Sponsor';
      case model.UserRole.organisation:
        return 'Org';
      case model.UserRole.audience:
        return 'Fan';
    }
  }
}
