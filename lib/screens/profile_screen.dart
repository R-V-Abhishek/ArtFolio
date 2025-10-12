import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';

import '../models/user.dart' as model;
import '../theme/scale.dart';
import '../models/role_models.dart' as roles;
import '../models/post.dart';
import '../services/firestore_service.dart';
import '../widgets/firestore_image.dart';
import 'edit_profile_screen.dart';
import 'follow_list_screen.dart';
import '../services/session_state.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId; // Optional: view other user's profile later
  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final _auth = fb.FirebaseAuth.instance;
  final _firestore = FirestoreService();

  model.User? _user;
  roles.Artist? _artist;
  Map<String, int> _followCounts = const {'followers': 0, 'following': 0};
  bool _isFollowing = false;
  bool _loading = true;
  List<Post> _posts = const [];
  bool _gridView = true;
  bool _followBusy = false;

  late final TabController _tabController = TabController(
    length: 4,
    vsync: this,
  );

  @override
  void initState() {
    super.initState();
    _loadData();
    // Refresh when notified (e.g., after creating a post)
    SessionState.instance.profileRefreshTick.addListener(_loadData);
  }

  Future<void> _editBio() async {
    if (_user == null) return;
    final controller = TextEditingController(text: _user!.bio);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Edit bio'),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Tell people about your art, style, and interests',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (result == null) return;
    try {
      final updated = _user!.copyWith(bio: result);
      await _firestore.updateUser(updated);
      if (!mounted) return;
      setState(() => _user = updated);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Bio updated')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update bio: $e')));
    }
  }

  Future<void> _loadData() async {
    try {
      final targetUserId = widget.userId ?? _auth.currentUser?.uid;
      if (targetUserId == null) {
        setState(() {
          _loading = false;
        });
        return;
      }

      final user = await _firestore.getUser(targetUserId);
      roles.Artist? artist;
      if (user?.role == model.UserRole.artist) {
        artist = await _firestore.getArtist(targetUserId);
      }

      final posts = await _firestore.getUserPosts(targetUserId);
      final counts = await _firestore.getFollowCounts(targetUserId);

      bool following = false;
      final viewerId = _auth.currentUser?.uid;
      if (viewerId != null && viewerId != targetUserId) {
        following = await _firestore.isFollowing(viewerId, targetUserId);
      }

      if (mounted) {
        setState(() {
          _user = user;
          _artist = artist;
          _posts = posts;
          _followCounts = counts;
          _isFollowing = following;
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load profile: $e')));
    }
  }

  @override
  void dispose() {
    SessionState.instance.profileRefreshTick.removeListener(_loadData);
    super.dispose();
  }

  bool get _isOwnProfile {
    final uid = _auth.currentUser?.uid;
    return uid != null && _user?.id == uid;
  }

  Future<void> _onFollowToggle() async {
    if (_followBusy) return;
    final viewer = _auth.currentUser?.uid;
    final target = _user?.id;
    if (viewer == null || target == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to follow artists')),
      );
      return;
    }
    setState(() {
      _followBusy = true;
      _isFollowing = !_isFollowing; // optimistic
    });
    try {
      final nowFollowing = await _firestore.toggleFollow(
        viewerUserId: viewer,
        targetUserId: target,
      );
      setState(() {
        _isFollowing = nowFollowing;
        _followCounts = {
          'followers': _followCounts['followers']! + (nowFollowing ? 1 : -1),
          'following': _followCounts['following']!,
        };
        _followBusy = false;
      });
      final msg = nowFollowing ? 'Started following' : 'Unfollowed';
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isFollowing = !_isFollowing;
        _followBusy = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_user == null) {
      final signedIn = _auth.currentUser != null;
      if (!signedIn) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 56),
                const SizedBox(height: 12),
                Text(
                  'Please sign in to set up your profile',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your profile to share your art, get followers, and collaborate with others.',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  icon: const Icon(Icons.login),
                  label: const Text('Sign in'),
                  onPressed: () {
                    // Exit guest mode if enabled, then navigate to auth
                    SessionState.instance.exitGuest();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AuthScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      }
      // Signed in but user document missing
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_off_outlined, size: 48),
            const SizedBox(height: 8),
            Text('Profile not found', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            FilledButton(onPressed: _loadData, child: const Text('Retry')),
          ],
        ),
      );
    }

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverAppBar(
          pinned: true,
          title: Text(_user!.username),
          actions: [
            if (!_isOwnProfile) ...[
              IconButton(
                icon: const Icon(Icons.mail_outline),
                tooltip: 'Message',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Messaging coming soon')),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.favorite_outline),
                tooltip: 'Sponsor',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sponsor flow coming soon')),
                  );
                },
              ),
            ],
          ],
        ),
        SliverToBoxAdapter(
          child: _ProfileHeader(
            user: _user!,
            artist: _artist,
            counts: _followCounts,
            isOwnProfile: _isOwnProfile,
            isFollowing: _isFollowing,
            followBusy: _followBusy,
            onFollowToggle: _onFollowToggle,
            postsCount: _posts.length,
            onEditProfile: () async {
              final nav = Navigator.of(context);
              await nav.push(
                MaterialPageRoute(
                  builder: (_) => EditProfileScreen(user: _user!),
                ),
              );
              if (!mounted) return;
              _loadData();
            },
            onEditBio: _editBio,
          ),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _TabBarHeaderDelegate(
            TabBar(
              controller: _tabController,
              indicatorColor: Theme.of(context).colorScheme.primary,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Theme.of(context).colorScheme.outline,
              tabs: const [
                Tab(icon: Icon(Icons.grid_on_rounded), text: 'Posts'),
                Tab(icon: Icon(Icons.assignment_outlined), text: 'Projects'),
                Tab(icon: Icon(Icons.group_outlined), text: 'Collabs'),
                Tab(icon: Icon(Icons.favorite_border), text: 'Sponsors'),
              ],
            ),
          ),
        ),
      ],
      body: SafeArea(
        top: false,
        bottom: false,
        child: TabBarView(
          controller: _tabController,
          children: [
            _PostsTab(
              posts: _posts,
              gridView: _gridView,
              onToggleView: () => setState(() => _gridView = !_gridView),
              onRefreshRequested: _loadData,
            ),
            const _PlaceholderTab(
              icon: Icons.assignment_outlined,
              title: 'Projects & Proposals',
              subtitle: 'Coming soon',
            ),
            const _PlaceholderTab(
              icon: Icons.group_outlined,
              title: 'Collaborations & Orgs',
              subtitle: 'Coming soon',
            ),
            const _PlaceholderTab(
              icon: Icons.favorite_border,
              title: 'Sponsors',
              subtitle: 'Coming soon',
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatefulWidget {
  final model.User user;
  final roles.Artist? artist;
  final Map<String, int> counts;
  final bool isOwnProfile;
  final bool isFollowing;
  final bool followBusy;
  final VoidCallback onFollowToggle;
  final int postsCount;
  final VoidCallback onEditProfile;
  final VoidCallback onEditBio;

  const _ProfileHeader({
    required this.user,
    required this.artist,
    required this.counts,
    required this.isOwnProfile,
    required this.isFollowing,
    required this.followBusy,
    required this.onFollowToggle,
    required this.postsCount,
    required this.onEditProfile,
    required this.onEditBio,
  });

  @override
  State<_ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<_ProfileHeader> {
  bool _bioExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final skills = widget.artist?.artForms ?? const <String>[];
    final links = widget.artist?.portfolioUrls ?? const <String>[];
    final width = MediaQuery.of(context).size.width;
    final isNarrow = width < 380;
    final s = Scale(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.colorScheme.surfaceContainerHighest,
            theme.colorScheme.surface,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row (avatar, name with inline edit, follow)
            Material(
              elevation: 2,
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: (s.size(112)).clamp(96.0, 112.0),
                      height: (s.size(112)).clamp(96.0, 112.0),
                      child: ClipOval(
                        child: widget.user.profilePictureUrl.isNotEmpty
                            ? (widget.user.profilePictureUrl.startsWith('http')
                                  ? Image.network(
                                      widget.user.profilePictureUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (
                                            context,
                                            error,
                                            stackTrace,
                                          ) => Container(
                                            color: theme
                                                .colorScheme
                                                .surfaceContainerHighest,
                                            alignment: Alignment.center,
                                            child: Text(
                                              (widget.user.username.isNotEmpty
                                                      ? widget.user.username[0]
                                                      : 'A')
                                                  .toUpperCase(),
                                              style:
                                                  theme.textTheme.headlineSmall,
                                            ),
                                          ),
                                    )
                                  : Image.asset(
                                      widget.user.profilePictureUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (
                                            context,
                                            error,
                                            stackTrace,
                                          ) => Container(
                                            color: theme
                                                .colorScheme
                                                .surfaceContainerHighest,
                                            alignment: Alignment.center,
                                            child: Text(
                                              (widget.user.username.isNotEmpty
                                                      ? widget.user.username[0]
                                                      : 'A')
                                                  .toUpperCase(),
                                              style:
                                                  theme.textTheme.headlineSmall,
                                            ),
                                          ),
                                    ))
                            : Container(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                alignment: Alignment.center,
                                child: Text(
                                  (widget.user.username.isNotEmpty
                                          ? widget.user.username[0]
                                          : 'A')
                                      .toUpperCase(),
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                        fontSize: s.font(
                                          theme
                                                  .textTheme
                                                  .headlineSmall
                                                  ?.fontSize ??
                                              24,
                                        ),
                                      ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name + inline edit button (owner only)
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.user.fullName.isNotEmpty
                                      ? widget.user.fullName
                                      : widget.user.username,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: s.font(
                                      theme.textTheme.titleLarge?.fontSize ??
                                          20,
                                    ),
                                  ),
                                ),
                              ),
                              if (widget.isOwnProfile)
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  tooltip: 'Edit Profile',
                                  onPressed: widget.onEditProfile,
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Role badge/pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _roleLabel(widget.user.role),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!widget.isOwnProfile)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: isNarrow
                            ? IconButton.filledTonal(
                                tooltip: widget.isFollowing
                                    ? 'Following'
                                    : 'Follow',
                                onPressed: widget.followBusy
                                    ? null
                                    : widget.onFollowToggle,
                                icon: Icon(
                                  widget.isFollowing
                                      ? Icons.check
                                      : Icons.person_add_alt_1,
                                ),
                              )
                            : FilledButton.icon(
                                onPressed: widget.followBusy
                                    ? null
                                    : widget.onFollowToggle,
                                icon: Icon(
                                  widget.isFollowing
                                      ? Icons.check
                                      : Icons.person_add_alt_1,
                                ),
                                label: Text(
                                  widget.isFollowing ? 'Following' : 'Follow',
                                ),
                              ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Stats (single elegant row, evenly spaced)
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => FollowListScreen(
                            userId: widget.user.id,
                            type: FollowListType.followers,
                          ),
                        ),
                      );
                    },
                    child: _Stat(
                      number: widget.counts['followers'] ?? 0,
                      label: 'Followers',
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => FollowListScreen(
                            userId: widget.user.id,
                            type: FollowListType.following,
                          ),
                        ),
                      );
                    },
                    child: _Stat(
                      number: widget.counts['following'] ?? 0,
                      label: 'Following',
                    ),
                  ),
                ),
                Expanded(
                  child: _Stat(number: widget.postsCount, label: 'Posts'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Bio section with More/Less toggle
            Builder(
              builder: (context) {
                final hasBio = widget.user.bio.trim().isNotEmpty;
                final rawBio = hasBio
                    ? widget.user.bio.trim()
                    : 'Digital artist exploring light and color.';
                final needsToggle =
                    rawBio.length > 160 || rawBio.contains('\n');
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rawBio,
                      style: theme.textTheme.bodyMedium,
                      maxLines: needsToggle && !_bioExpanded ? 3 : null,
                      overflow: needsToggle && !_bioExpanded
                          ? TextOverflow.fade
                          : TextOverflow.visible,
                    ),
                    Row(
                      children: [
                        if (needsToggle)
                          TextButton(
                            onPressed: () =>
                                setState(() => _bioExpanded = !_bioExpanded),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                            child: Text(_bioExpanded ? 'Less' : 'More'),
                          ),
                        if (widget.isOwnProfile)
                          TextButton.icon(
                            onPressed: widget.onEditBio,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.only(left: 8),
                              visualDensity: VisualDensity.compact,
                            ),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: Text(hasBio ? 'Edit bio' : 'Add bio'),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            // Skills
            if (skills.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: -4,
                children: skills
                    .take(6)
                    .map((s) => Chip(label: Text(s)))
                    .toList(),
              ),
            const SizedBox(height: 8),
            // Links
            if (links.isNotEmpty)
              Wrap(
                spacing: 8,
                children: links
                    .take(3)
                    .map(
                      (l) => ActionChip(
                        label: Text(Uri.tryParse(l)?.host ?? l),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Open link: $l')),
                          );
                        },
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  String _roleLabel(model.UserRole role) {
    switch (role) {
      case model.UserRole.artist:
        return 'Artist';
      case model.UserRole.audience:
        return 'Audience';
      case model.UserRole.sponsor:
        return 'Sponsor';
      case model.UserRole.organisation:
        return 'Organisation';
    }
  }
}

class _TabBarHeaderDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _TabBarHeaderDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final color = Theme.of(context).colorScheme.surface;
    return Container(
      color: color,
      child: Material(color: Colors.transparent, child: tabBar),
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarHeaderDelegate oldDelegate) {
    return oldDelegate.tabBar != tabBar;
  }
}

class _PostsTab extends StatelessWidget {
  final List<Post> posts;
  final bool gridView;
  final VoidCallback onToggleView;
  final Future<void> Function() onRefreshRequested;

  const _PostsTab({
    required this.posts,
    required this.gridView,
    required this.onToggleView,
    required this.onRefreshRequested,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Always support pull-to-refresh
    final content = posts.isEmpty
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.image_outlined, size: 48),
                const SizedBox(height: 8),
                Text('No posts yet', style: theme.textTheme.titleMedium),
              ],
            ),
          )
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: Row(
                  children: [
                    Text('Posts', style: theme.textTheme.titleMedium),
                    const Spacer(),
                    IconButton(
                      onPressed: onToggleView,
                      tooltip: gridView ? 'List view' : 'Grid view',
                      icon: Icon(
                        gridView
                            ? Icons.view_list_rounded
                            : Icons.grid_view_rounded,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: gridView ? _Grid(posts: posts) : _List(posts: posts),
              ),
            ],
          );

    return RefreshIndicator(
      onRefresh: onRefreshRequested,
      child: posts.isEmpty
          ? ListView(
              padding: const EdgeInsets.only(top: 40),
              children: [SizedBox(height: 200), content],
            )
          : content,
    );
  }
}

class _Grid extends StatelessWidget {
  final List<Post> posts;
  const _Grid({required this.posts});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Compute columns based on available width (min tile ~120px)
        final crossAxisCount = (constraints.maxWidth / 140).floor().clamp(2, 6);
        final spacing = 2.0;
        return GridView.builder(
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
          ),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final p = posts[index];
            final ref = p.thumbnailUrl ?? p.primaryMediaUrl;
            if (ref.isEmpty) {
              return Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              );
            }
            final isUrl =
                ref.startsWith('http://') || ref.startsWith('https://');
            return isUrl
                ? Image.network(
                    ref,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image),
                    ),
                  )
                : FirestoreImage(imageId: ref, fit: BoxFit.cover);
          },
        );
      },
    );
  }
}

class _List extends StatelessWidget {
  final List<Post> posts;
  const _List({required this.posts});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: posts.length,
      separatorBuilder: (_, i) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final p = posts[index];
        final ref = p.thumbnailUrl ?? p.primaryMediaUrl;
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          leading: SizedBox(
            width: 56,
            height: 56,
            child: ref.isEmpty
                ? Container(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                  )
                : (ref.startsWith('http')
                      ? Image.network(
                          ref,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                                alignment: Alignment.center,
                                child: const Icon(Icons.broken_image),
                              ),
                        )
                      : FirestoreImage(imageId: ref, fit: BoxFit.cover)),
          ),
          title: Text(p.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(p.type.name.toUpperCase()),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Post detail coming soon')),
            );
          },
        );
      },
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _PlaceholderTab({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48),
          const SizedBox(height: 8),
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(subtitle, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final int? number;
  final String label;
  const _Stat({required this.number, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          number?.toString() ?? '-',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
