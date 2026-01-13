import '../models/post.dart';

/// Service for managing trending content and discovery algorithms
class TrendingService {
  TrendingService._();
  static final TrendingService instance = TrendingService._();

  /// Sort posts by trending score
  List<Post> sortByTrending(List<Post> posts) {
    final sorted = List<Post>.from(posts);
    sorted.sort((a, b) => b.trendingScore.compareTo(a.trendingScore));
    return sorted;
  }

  /// Filter posts by skill tags
  List<Post> filterBySkill(List<Post> posts, String skill) {
    return posts
        .where(
          (post) => post.skills.any(
            (s) => s.toLowerCase().contains(skill.toLowerCase()),
          ),
        )
        .toList();
  }

  /// Filter posts by multiple skills (posts must have at least one)
  List<Post> filterBySkills(List<Post> posts, List<String> skills) {
    if (skills.isEmpty) return posts;

    final filtered = posts
        .where(
          (post) => post.skills.any(
            (postSkill) => skills.any(
              (filterSkill) =>
                  postSkill.toLowerCase().contains(filterSkill.toLowerCase()),
            ),
          ),
        )
        .toList();

    // If no posts match the filter, return all posts as fallback
    return filtered.isNotEmpty ? filtered : posts;
  }

  /// Filter posts by tag
  List<Post> filterByTag(List<Post> posts, String tag) {
    return posts
        .where(
          (post) =>
              post.tags.any((t) => t.toLowerCase().contains(tag.toLowerCase())),
        )
        .toList();
  }

  /// Get trending posts (high engagement in last 7 days)
  /// Falls back to all posts sorted by trending score if no recent posts
  List<Post> getTrendingPosts(List<Post> posts, {int limit = 20}) {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    final recentPosts = posts
        .where((post) => post.timestamp.isAfter(sevenDaysAgo))
        .toList();

    // If we have recent posts, use those; otherwise use all posts
    final postsToSort = recentPosts.isNotEmpty ? recentPosts : posts;

    final sorted = sortByTrending(postsToSort);
    return sorted.take(limit).toList();
  }

  /// Get posts by specific post type
  List<Post> filterByType(List<Post> posts, PostType type) {
    return posts.where((post) => post.type == type).toList();
  }

  /// Get diverse trending posts (mix of skills and content types)
  /// Ensures all posts are shown even if they lack skills or engagement
  List<Post> getDiverseTrendingPosts(List<Post> posts, {int limit = 20}) {
    if (posts.isEmpty) return [];

    final trending = sortByTrending(posts);
    final diverse = <Post>[];
    final seenSkills = <String>{};
    final seenTypes = <PostType>{};

    // First pass: one from each unique skill/type combo
    for (final post in trending) {
      if (diverse.length >= limit) break;

      // Include posts without skills or with new skills/types
      final hasNewSkill =
          post.skills.isEmpty ||
          post.skills.any((skill) => !seenSkills.contains(skill));
      final hasNewType = !seenTypes.contains(post.type);

      if (hasNewSkill || hasNewType) {
        diverse.add(post);
        seenSkills.addAll(post.skills);
        seenTypes.add(post.type);
      }
    }

    // Second pass: fill remaining slots with highest trending
    for (final post in trending) {
      if (diverse.length >= limit) break;
      if (!diverse.contains(post)) {
        diverse.add(post);
      }
    }

    return diverse;
  }

  /// Extract all unique skills from a list of posts
  Set<String> extractSkills(List<Post> posts) {
    final skills = <String>{};
    for (final post in posts) {
      skills.addAll(post.skills);
    }
    return skills;
  }

  /// Extract all unique tags from a list of posts
  Set<String> extractTags(List<Post> posts) {
    final tags = <String>{};
    for (final post in posts) {
      tags.addAll(post.tags);
    }
    return tags;
  }

  /// Get popular skills (most used in trending posts)
  /// Returns empty list if no posts have skills
  List<String> getPopularSkills(List<Post> posts, {int limit = 10}) {
    final skillCounts = <String, int>{};

    // Use all posts if we don't have enough content, not just trending
    final postsToCheck = posts.length > 50
        ? getTrendingPosts(posts, limit: 50)
        : posts;

    for (final post in postsToCheck) {
      for (final skill in post.skills) {
        skillCounts[skill] = (skillCounts[skill] ?? 0) + 1;
      }
    }

    if (skillCounts.isEmpty) return [];

    final sorted = skillCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(limit).map((e) => e.key).toList();
  }

  /// Recommend posts based on user's interests (skills)
  List<Post> recommendByInterests(
    List<Post> posts,
    List<String> userInterests, {
    int limit = 20,
  }) {
    if (userInterests.isEmpty) {
      return getTrendingPosts(posts, limit: limit);
    }

    // Score posts based on skill overlap and trending score
    final scoredPosts = posts.map((post) {
      final skillOverlap = post.skills
          .where(
            (skill) => userInterests.any(
              (interest) =>
                  skill.toLowerCase().contains(interest.toLowerCase()),
            ),
          )
          .length;

      // Combine skill relevance with trending score
      final relevanceScore = skillOverlap * 10.0 + post.trendingScore;

      return (post: post, score: relevanceScore);
    }).toList();

    scoredPosts.sort((a, b) => b.score.compareTo(a.score));

    return scoredPosts.take(limit).map((e) => e.post).toList();
  }
}
