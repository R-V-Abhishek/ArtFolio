import 'package:cloud_firestore/cloud_firestore.dart';

/// Types of kudos that can be given to a post
enum KudosType {
  greatComposition('Great Composition', '🎨'),
  inspiringIdea('Inspiring Idea', '💡'),
  amazingColors('Amazing Colors', '🌈'),
  technicalExcellence('Technical Excellence', '⚡'),
  creativeConcept('Creative Concept', '✨'),
  beautifulDetails('Beautiful Details', '👁️'),
  uniqueStyle('Unique Style', '🎭'),
  professionalWork('Professional Work', '⭐');

  const KudosType(this.label, this.emoji);
  final String label;
  final String emoji;
}

/// Represents a single kudos given by a user
class Kudos {
  Kudos({required this.userId, required this.type, required this.timestamp});

  factory Kudos.fromMap(Map<String, dynamic> map) => Kudos(
    userId: map['userId'] ?? '',
    type: KudosType.values.firstWhere(
      (e) => e.name == map['type'],
      orElse: () => KudosType.greatComposition,
    ),
    timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
  );

  final String userId;
  final KudosType type;
  final DateTime timestamp;

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'type': type.name,
    'timestamp': Timestamp.fromDate(timestamp),
  };
}

/// Summary of kudos for a post
class KudosSummary {
  KudosSummary({
    required this.totalCount,
    required this.byType,
    this.userKudosType,
  });

  factory KudosSummary.fromMap(Map<String, dynamic> map) {
    final byTypeMap = map['byType'] as Map<String, dynamic>? ?? {};
    final byType = <KudosType, int>{};

    for (final entry in byTypeMap.entries) {
      try {
        final type = KudosType.values.firstWhere((e) => e.name == entry.key);
        byType[type] = entry.value as int? ?? 0;
      } catch (_) {
        // Skip invalid types
      }
    }

    KudosType? userType;
    if (map['userKudosType'] != null) {
      try {
        userType = KudosType.values.firstWhere(
          (e) => e.name == map['userKudosType'],
        );
      } catch (_) {
        // Invalid type
      }
    }

    return KudosSummary(
      totalCount: map['totalCount'] ?? 0,
      byType: byType,
      userKudosType: userType,
    );
  }

  final int totalCount;
  final Map<KudosType, int> byType;
  final KudosType? userKudosType; // Type given by current user, if any

  Map<String, dynamic> toMap() => {
    'totalCount': totalCount,
    'byType': byType.map((key, value) => MapEntry(key.name, value)),
    'userKudosType': userKudosType?.name,
  };

  /// Get the most popular kudos type
  KudosType? get mostPopularType {
    if (byType.isEmpty) return null;
    return byType.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// Get formatted string of top kudos types
  String getTopKudosText({int limit = 2}) {
    if (byType.isEmpty) return '';

    final sorted = byType.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topTypes = sorted.take(limit).map((e) => e.key.emoji).join(' ');
    return topTypes;
  }
}
