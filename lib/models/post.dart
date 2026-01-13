import 'package:cloud_firestore/cloud_firestore.dart';

// Enum for different types of content
enum PostType { image, video, reel, idea, gallery, live }

// Enum for post visibility
enum PostVisibility { public, private, sponsorsOnly, followersOnly }

// Model for location data
class PostLocation {
  PostLocation({
    this.city,
    this.state,
    this.country,
    this.latitude,
    this.longitude,
  });

  factory PostLocation.fromMap(Map<String, dynamic> map) => PostLocation(
    city: map['city'],
    state: map['state'],
    country: map['country'],
    latitude: map['latitude']?.toDouble(),
    longitude: map['longitude']?.toDouble(),
  );
  final String? city;
  final String? state;
  final String? country;
  final double? latitude;
  final double? longitude;

  Map<String, dynamic> toMap() => {
    'city': city,
    'state': state,
    'country': country,
    'latitude': latitude,
    'longitude': longitude,
  };
}

// Model for collaboration details
class CollaborationInfo {
  CollaborationInfo({
    required this.collaboratorIds,
    this.sponsorId,
    this.isSponsored = false,
    this.sponsorshipDetails,
  });

  factory CollaborationInfo.fromMap(Map<String, dynamic> map) =>
      CollaborationInfo(
        collaboratorIds: List<String>.from(map['collaboratorIds'] ?? []),
        sponsorId: map['sponsorId'],
        isSponsored: map['isSponsored'] ?? false,
        sponsorshipDetails: map['sponsorshipDetails'],
      );
  final List<String> collaboratorIds;
  final String? sponsorId;
  final bool isSponsored;
  final String? sponsorshipDetails;

  Map<String, dynamic> toMap() => {
    'collaboratorIds': collaboratorIds,
    'sponsorId': sponsorId,
    'isSponsored': isSponsored,
    'sponsorshipDetails': sponsorshipDetails,
  };
}

// Enhanced Post model
class Post {
  // Last like/comment time

  Post({
    required this.id,
    required this.userId,
    required this.type,
    this.mediaUrl,
    this.mediaUrls,
    required this.caption,
    this.description,
    required this.skills,
    this.tags = const [],
    required this.timestamp,
    this.updatedAt,
    this.visibility = PostVisibility.public,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.viewsCount = 0,
    this.likedBy = const [],
    this.kudosCount = 0,
    this.kudosByType = const {},
    this.kudosGivenBy = const {},
    this.location,
    this.collaboration,
    this.duration,
    this.thumbnailUrl,
    this.aspectRatio,
    this.allowComments = true,
    this.allowSharing = true,
    this.isPinned = false,
    this.demographics,
    this.lastEngagement,
  });

  // Create Post from Firestore document
  factory Post.fromMap(Map<String, dynamic> map, String documentId) => Post(
    id: documentId,
    userId: map['userId'] ?? '',
    type: PostType.values.firstWhere(
      (e) => e.name == map['type'],
      orElse: () => PostType.image,
    ),
    mediaUrl: map['mediaUrl'],
    mediaUrls: map['mediaUrls'] != null
        ? List<String>.from(map['mediaUrls'])
        : null,
    caption: map['caption'] ?? '',
    description: map['description'],
    skills: List<String>.from(map['skills'] ?? []),
    tags: List<String>.from(map['tags'] ?? []),
    timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    visibility: PostVisibility.values.firstWhere(
      (e) => e.name == map['visibility'],
      orElse: () => PostVisibility.public,
    ),
    likesCount: map['likesCount'] ?? 0,
    commentsCount: map['commentsCount'] ?? 0,
    sharesCount: map['sharesCount'] ?? 0,
    viewsCount: map['viewsCount'] ?? 0,
    likedBy: List<String>.from(map['likedBy'] ?? []),
    kudosCount: map['kudosCount'] ?? 0,
    kudosByType: map['kudosByType'] != null
        ? Map<String, int>.from(map['kudosByType'])
        : {},
    kudosGivenBy: map['kudosGivenBy'] != null
        ? Map<String, String>.from(map['kudosGivenBy'])
        : {},
    location: map['location'] != null
        ? PostLocation.fromMap(map['location'])
        : null,
    collaboration: map['collaboration'] != null
        ? CollaborationInfo.fromMap(map['collaboration'])
        : null,
    duration: map['duration'],
    thumbnailUrl: map['thumbnailUrl'],
    aspectRatio: map['aspectRatio']?.toDouble(),
    allowComments: map['allowComments'] ?? true,
    allowSharing: map['allowSharing'] ?? true,
    isPinned: map['isPinned'] ?? false,
    demographics: map['demographics'] != null
        ? Map<String, int>.from(map['demographics'])
        : null,
    lastEngagement: (map['lastEngagement'] as Timestamp?)?.toDate(),
  );

  // Create Post from Firestore DocumentSnapshot
  factory Post.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data()! as Map<String, dynamic>;
    return Post.fromMap(data, snapshot.id);
  }

  // Create Post from a generic JSON map (e.g., from assets), supporting
  // ISO-8601 string timestamps and optional fields.
  factory Post.fromJson(Map<String, dynamic> map) {
    DateTime parseTs(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      return DateTime.now();
    }

    PostType parseType(String? t) {
      if (t == null) return PostType.image;
      return PostType.values.firstWhere(
        (e) => e.name.toLowerCase() == t.toLowerCase(),
        orElse: () => PostType.image,
      );
    }

    return Post(
      id: map['id']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      type: parseType(map['type'] as String?),
      mediaUrl: map['mediaUrl'] as String?,
      mediaUrls: map['mediaUrls'] != null
          ? List<String>.from(map['mediaUrls'])
          : null,
      caption: map['caption']?.toString() ?? '',
      description: map['description'] as String?,
      skills: List<String>.from(map['skills'] ?? const <String>[]),
      tags: List<String>.from(map['tags'] ?? const <String>[]),
      timestamp: parseTs(map['timestamp']),
      updatedAt: map['updatedAt'] != null ? parseTs(map['updatedAt']) : null,
      likesCount: (map['likesCount'] as num?)?.toInt() ?? 0,
      commentsCount: (map['commentsCount'] as num?)?.toInt() ?? 0,
      sharesCount: (map['sharesCount'] as num?)?.toInt() ?? 0,
      viewsCount: (map['viewsCount'] as num?)?.toInt() ?? 0,
      thumbnailUrl: map['thumbnailUrl'] as String?,
      aspectRatio: (map['aspectRatio'] as num?)?.toDouble(),
      allowComments: map['allowComments'] as bool? ?? true,
      allowSharing: map['allowSharing'] as bool? ?? true,
      isPinned: map['isPinned'] as bool? ?? false,
    );
  }
  final String id;
  final String userId;
  final PostType type;
  final String? mediaUrl;
  final List<String>? mediaUrls; // For gallery posts
  final String caption;
  final String? description; // Longer form description
  final List<String> skills;
  final List<String> tags; // Hashtags
  final DateTime timestamp;
  final DateTime? updatedAt;
  final PostVisibility visibility;

  // Engagement metrics
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final int viewsCount;
  final List<String> likedBy; // User IDs who liked

  // Kudos (professional feedback)
  final int kudosCount;
  final Map<String, int> kudosByType; // Count by kudos type name
  final Map<String, String> kudosGivenBy; // userId -> kudosType mapping

  // Location and collaboration
  final PostLocation? location;
  final CollaborationInfo? collaboration;

  // Media metadata
  final int? duration; // For videos/reels in seconds
  final String? thumbnailUrl; // For videos
  final double? aspectRatio; // For proper display

  // Engagement features
  final bool allowComments;
  final bool allowSharing;
  final bool isPinned; // Artist can pin posts

  // Analytics
  final Map<String, int>? demographics; // View demographics
  final DateTime? lastEngagement;

  // Convert Post to Map for Firestore
  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'type': type.name,
    'mediaUrl': mediaUrl,
    'mediaUrls': mediaUrls,
    'caption': caption,
    'description': description,
    'skills': skills,
    'tags': tags,
    'timestamp': Timestamp.fromDate(timestamp),
    'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    'visibility': visibility.name,
    'likesCount': likesCount,
    'commentsCount': commentsCount,
    'sharesCount': sharesCount,
    'viewsCount': viewsCount,
    'likedBy': likedBy,
    'kudosCount': kudosCount,
    'kudosByType': kudosByType,
    'kudosGivenBy': kudosGivenBy,
    'location': location?.toMap(),
    'collaboration': collaboration?.toMap(),
    'duration': duration,
    'thumbnailUrl': thumbnailUrl,
    'aspectRatio': aspectRatio,
    'allowComments': allowComments,
    'allowSharing': allowSharing,
    'isPinned': isPinned,
    'demographics': demographics,
    'lastEngagement': lastEngagement != null
        ? Timestamp.fromDate(lastEngagement!)
        : null,
  };

  // Copy with method for updating posts
  Post copyWith({
    String? id,
    String? userId,
    PostType? type,
    String? mediaUrl,
    List<String>? mediaUrls,
    String? caption,
    String? description,
    List<String>? skills,
    List<String>? tags,
    DateTime? timestamp,
    DateTime? updatedAt,
    PostVisibility? visibility,
    int? likesCount,
    int? commentsCount,
    int? sharesCount,
    int? viewsCount,
    List<String>? likedBy,
    int? kudosCount,
    Map<String, int>? kudosByType,
    Map<String, String>? kudosGivenBy,
    PostLocation? location,
    CollaborationInfo? collaboration,
    int? duration,
    String? thumbnailUrl,
    double? aspectRatio,
    bool? allowComments,
    bool? allowSharing,
    bool? isPinned,
    Map<String, int>? demographics,
    DateTime? lastEngagement,
  }) => Post(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    type: type ?? this.type,
    mediaUrl: mediaUrl ?? this.mediaUrl,
    mediaUrls: mediaUrls ?? this.mediaUrls,
    caption: caption ?? this.caption,
    description: description ?? this.description,
    skills: skills ?? this.skills,
    tags: tags ?? this.tags,
    timestamp: timestamp ?? this.timestamp,
    updatedAt: updatedAt ?? this.updatedAt,
    visibility: visibility ?? this.visibility,
    likesCount: likesCount ?? this.likesCount,
    commentsCount: commentsCount ?? this.commentsCount,
    sharesCount: sharesCount ?? this.sharesCount,
    viewsCount: viewsCount ?? this.viewsCount,
    likedBy: likedBy ?? this.likedBy,
    kudosCount: kudosCount ?? this.kudosCount,
    kudosByType: kudosByType ?? this.kudosByType,
    kudosGivenBy: kudosGivenBy ?? this.kudosGivenBy,
    location: location ?? this.location,
    collaboration: collaboration ?? this.collaboration,
    duration: duration ?? this.duration,
    thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    aspectRatio: aspectRatio ?? this.aspectRatio,
    allowComments: allowComments ?? this.allowComments,
    allowSharing: allowSharing ?? this.allowSharing,
    isPinned: isPinned ?? this.isPinned,
    demographics: demographics ?? this.demographics,
    lastEngagement: lastEngagement ?? this.lastEngagement,
  );

  // Helper methods for engagement
  bool isLikedBy(String userId) => likedBy.contains(userId);

  bool get hasLocation => location != null;

  bool get isSponsored => collaboration?.isSponsored ?? false;

  bool get hasCollaborators =>
      collaboration?.collaboratorIds.isNotEmpty ?? false;

  // Get main media URL (for backward compatibility)
  String get primaryMediaUrl =>
      mediaUrl ?? (mediaUrls?.isNotEmpty ?? false ? mediaUrls!.first : '');

  // Calculate trending score based on engagement and recency
  // Higher score = more trending
  double get trendingScore {
    final now = DateTime.now();
    final ageInHours = now.difference(timestamp).inHours;

    // Penalize older posts exponentially
    // Posts older than 7 days get minimal boost
    final recencyFactor =
        ageInHours <=
            168 // 7 days
        ? 1.0 /
              (1.0 + ageInHours / 24.0) // Decay over days
        : 0.1;

    // Engagement score with weighted metrics
    final engagementScore =
        (likesCount * 1.0) + // Likes worth 1 point
        (commentsCount * 3.0) + // Comments worth 3 points (more valuable)
        (sharesCount * 5.0) + // Shares worth 5 points (most valuable)
        (kudosCount * 4.0) + // Kudos worth 4 points (professional feedback)
        (viewsCount * 0.1); // Views worth 0.1 points

    return engagementScore * recencyFactor;
  }

  // Get total engagement count
  int get totalEngagement =>
      likesCount + commentsCount + sharesCount + kudosCount;

  // Check if post is trending (high engagement in last 48 hours)
  bool get isTrending {
    final ageInHours = DateTime.now().difference(timestamp).inHours;
    return ageInHours <= 48 && trendingScore > 10.0;
  }

  @override
  String toString() =>
      'Post(id: $id, userId: $userId, type: $type, caption: $caption, skills: $skills, timestamp: $timestamp, likesCount: $likesCount)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Post &&
        other.id == id &&
        other.userId == userId &&
        other.type == type &&
        other.mediaUrl == mediaUrl &&
        other.caption == caption &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      type.hashCode ^
      mediaUrl.hashCode ^
      caption.hashCode ^
      timestamp.hashCode;
}
