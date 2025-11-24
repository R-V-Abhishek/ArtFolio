import 'dart:async';

import 'package:flutter/material.dart';

import '../models/post.dart';
import '../services/asset_loader.dart';
import '../services/firestore_service.dart';
import '../services/trending_service.dart';
import '../theme/scale.dart';
import '../widgets/post_card.dart';

/// Explore screen showing trending content and discovery features
/// Focuses on skill-based and trending content rather than chronological feed
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with SingleTickerProviderStateMixin {
  final _firestore = FirestoreService();
  final _trending = TrendingService.instance;
  final _scrollController = ScrollController();

  List<Post> _allPosts = [];
  List<Post> _displayedPosts = [];
  List<String> _popularSkills = [];
  final Set<String> _selectedSkills = {};

  bool _loading = false;
  String _currentView = 'diverse'; // 'trending', 'latest', 'diverse'

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
    _tabController.addListener(_onTabChanged);
    _loadExploreContent();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        switch (_tabController.index) {
          case 0:
            _currentView = 'trending';
            break;
          case 1:
            _currentView = 'diverse';
            break;
          case 2:
            _currentView = 'latest';
            break;
        }
        _updateDisplayedPosts();
      });
    }
  }

  Future<void> _loadExploreContent() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _firestore.getExplorePosts().timeout(const Duration(seconds: 4)),
        _firestore.getReportedPostIdsForCurrentUser(),
      ]);

      final posts = results[0] as List<Post>;
      final reportedIds = results[1] as Set<String>;
      final filtered = posts.where((p) => !reportedIds.contains(p.id)).toList();

      setState(() {
        _allPosts = filtered;
        _popularSkills = _trending.getPopularSkills(_allPosts, limit: 15);
      });

      _updateDisplayedPosts();

      // If no posts, fallback to local demo
      if (_allPosts.isEmpty) {
        await _loadLocalFallback();
      }
    } on TimeoutException {
      await _loadLocalFallback();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Offline or not configured. Showing demo content.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load explore content: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadLocalFallback() async {
    final assetPosts = await _loadFromAssets();
    final demo = assetPosts.isNotEmpty ? assetPosts : _localDemoPosts();

    setState(() {
      _allPosts = demo;
      _popularSkills = _trending.getPopularSkills(_allPosts, limit: 15);
    });

    _updateDisplayedPosts();
  }

  void _updateDisplayedPosts() {
    var posts = _allPosts;

    // Apply skill filter if any selected
    if (_selectedSkills.isNotEmpty) {
      posts = _trending.filterBySkills(posts, _selectedSkills.toList());
    }

    // Apply view mode
    switch (_currentView) {
      case 'trending':
        posts = _trending.getTrendingPosts(posts, limit: 50);
        break;
      case 'diverse':
        posts = _trending.getDiverseTrendingPosts(posts, limit: 50);
        break;
      case 'latest':
        posts = List.from(posts)
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
        break;
    }

    setState(() {
      _displayedPosts = posts;
    });
  }

  void _toggleSkillFilter(String skill) {
    setState(() {
      if (_selectedSkills.contains(skill)) {
        _selectedSkills.remove(skill);
      } else {
        _selectedSkills.add(skill);
      }
      _updateDisplayedPosts();
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedSkills.clear();
      _updateDisplayedPosts();
    });
  }

  Future<void> _refresh() async {
    _selectedSkills.clear();
    await _loadExploreContent();
  }

  @override
  Widget build(BuildContext context) {
    final s = Scale(context);
    final theme = Theme.of(context);
    final bottomPad = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      body: Column(
        children: [
          // Tab bar for different views
          Material(
            color: theme.colorScheme.surface,
            elevation: 1,
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      s.size(16),
                      s.size(4),
                      s.size(16),
                      s.size(4),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.explore,
                          size: s.size(20),
                          color: theme.colorScheme.primary,
                        ),
                        SizedBox(width: s.size(8)),
                        Text(
                          'Explore',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        if (_selectedSkills.isNotEmpty)
                          TextButton.icon(
                            onPressed: _clearFilters,
                            icon: const Icon(Icons.clear, size: 16),
                            label: const Text('Clear'),
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                      ],
                    ),
                  ),
                  TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'Trending'),
                      Tab(text: 'Diverse'),
                      Tab(text: 'Latest'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Skills filter chips - only show on Trending tab if there are skills
          if (_currentView == 'trending' && _popularSkills.isNotEmpty)
            Container(
              color: theme.colorScheme.surfaceContainerHighest,
              padding: EdgeInsets.symmetric(
                horizontal: s.size(8),
                vertical: s.size(8),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Icon(
                      Icons.filter_list,
                      size: s.size(20),
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(width: s.size(8)),
                    ..._popularSkills.map((skill) {
                      final isSelected = _selectedSkills.contains(skill);
                      return Padding(
                        padding: EdgeInsets.only(right: s.size(8)),
                        child: FilterChip(
                          label: Text(skill),
                          selected: isSelected,
                          onSelected: (_) => _toggleSkillFilter(skill),
                          avatar: isSelected
                              ? Icon(
                                  Icons.check,
                                  size: s.size(16),
                                  color: theme.colorScheme.onSecondaryContainer,
                                )
                              : null,
                          labelStyle: TextStyle(fontSize: s.size(12)),
                          visualDensity: VisualDensity.compact,
                        ),
                      );
                    }),
                  ],
                ),
              ),
            )
          else if (_currentView == 'trending' && _allPosts.isNotEmpty)
            // Show info when posts exist but no skills are defined
            Container(
              color: theme.colorScheme.surfaceContainerHighest,
              padding: EdgeInsets.symmetric(
                horizontal: s.size(16),
                vertical: s.size(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: s.size(16),
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(width: s.size(8)),
                  Expanded(
                    child: Text(
                      'Add skills to posts to enable filtering',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Content
          Expanded(child: _buildContent(bottomPad)),
        ],
      ),
    );
  }

  Widget _buildContent(double bottomPad) {
    if (_loading && _displayedPosts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_displayedPosts.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          controller: _scrollController,
          padding: EdgeInsets.only(bottom: bottomPad + 16),
          children: [
            SizedBox(height: Scale(context).size(80)),
            Icon(
              Icons.explore_outlined,
              size: Scale(context).size(64),
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(height: Scale(context).size(16)),
            Text(
              _selectedSkills.isNotEmpty
                  ? 'No posts found for selected skills'
                  : 'No trending content yet',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: Scale(context).size(8)),
            Text(
              _selectedSkills.isNotEmpty
                  ? 'Try different skill filters'
                  : 'Pull down to refresh or try again later',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.only(bottom: bottomPad + 16),
        itemCount: _displayedPosts.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildDiscoveryHeader();
          }

          final post = _displayedPosts[index - 1];
          return PostCard(key: ValueKey(post.id), post: post);
        },
      ),
    );
  }

  Widget _buildDiscoveryHeader() {
    final s = Scale(context);
    final theme = Theme.of(context);

    String headerText;
    String subtitleText;
    IconData headerIcon;

    switch (_currentView) {
      case 'trending':
        headerText = 'Trending Now';
        subtitleText = 'Most engaging posts from the last 7 days';
        headerIcon = Icons.trending_up;
        break;
      case 'diverse':
        headerText = 'Diverse Discovery';
        subtitleText = 'Mix of different skills and content types';
        headerIcon = Icons.grid_view;
        break;
      case 'latest':
        headerText = 'Latest Posts';
        subtitleText = 'Fresh content from artists worldwide';
        headerIcon = Icons.access_time;
        break;
      default:
        headerText = 'Explore';
        subtitleText = 'Discover new artists';
        headerIcon = Icons.explore;
    }

    return Container(
      margin: EdgeInsets.all(s.size(16)),
      padding: EdgeInsets.all(s.size(16)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.secondaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(s.size(16)),
      ),
      child: Row(
        children: [
          Icon(
            headerIcon,
            size: s.size(40),
            color: theme.colorScheme.onPrimaryContainer,
          ),
          SizedBox(width: s.size(16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headerText,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: s.size(4)),
                Text(
                  subtitleText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer.withValues(
                      alpha: 0.8,
                    ),
                  ),
                ),
                if (_selectedSkills.isNotEmpty) ...[
                  SizedBox(height: s.size(8)),
                  Wrap(
                    spacing: s.size(4),
                    runSpacing: s.size(4),
                    children: _selectedSkills.map((skill) {
                      return Chip(
                        label: Text(
                          skill,
                          style: TextStyle(fontSize: s.size(10)),
                        ),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<List<Post>> _loadFromAssets() async {
    try {
      final list = await AssetLoader.loadJsonList('assets/mock_posts.json');
      return list.whereType<Map<String, dynamic>>().map(Post.fromJson).toList();
    } catch (e) {
      return [];
    }
  }

  List<Post> _localDemoPosts() {
    final now = DateTime.now();
    return [
      Post(
        id: 'demo1',
        userId: 'demo_user',
        type: PostType.image,
        caption: 'Demo trending artwork',
        description: 'This is a demo post showing trending content',
        skills: ['Digital Art', 'Illustration'],
        tags: ['demo', 'trending'],
        timestamp: now.subtract(const Duration(hours: 2)),
        likesCount: 150,
        commentsCount: 25,
        sharesCount: 10,
        viewsCount: 500,
      ),
      Post(
        id: 'demo2',
        userId: 'demo_user',
        type: PostType.image,
        caption: '3D Character Design',
        description: 'Exploring different styles',
        skills: ['3D Modeling', 'Character Design'],
        tags: ['demo', '3d'],
        timestamp: now.subtract(const Duration(hours: 5)),
        likesCount: 89,
        commentsCount: 12,
        sharesCount: 5,
        viewsCount: 300,
      ),
    ];
  }
}
