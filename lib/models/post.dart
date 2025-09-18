import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String userId;
  final String mediaUrl;
  final String caption;
  final List<String> skills;
  final DateTime timestamp;

  Post({
    required this.id,
    required this.userId,
    required this.mediaUrl,
    required this.caption,
    required this.skills,
    required this.timestamp,
  });

  // Convert Post to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'mediaUrl': mediaUrl,
      'caption': caption,
      'skills': skills,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  // Create Post from Firestore document
  factory Post.fromMap(Map<String, dynamic> map, String documentId) {
    return Post(
      id: documentId,
      userId: map['userId'] ?? '',
      mediaUrl: map['mediaUrl'] ?? '',
      caption: map['caption'] ?? '',
      skills: List<String>.from(map['skills'] ?? []),
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Create Post from Firestore DocumentSnapshot
  factory Post.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return Post.fromMap(data, snapshot.id);
  }

  // Copy with method for updating posts
  Post copyWith({
    String? id,
    String? userId,
    String? mediaUrl,
    String? caption,
    List<String>? skills,
    DateTime? timestamp,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      caption: caption ?? this.caption,
      skills: skills ?? this.skills,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'Post(id: $id, userId: $userId, mediaUrl: $mediaUrl, caption: $caption, skills: $skills, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is Post &&
        other.id == id &&
        other.userId == userId &&
        other.mediaUrl == mediaUrl &&
        other.caption == caption &&
        other.skills.toString() == skills.toString() &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        mediaUrl.hashCode ^
        caption.hashCode ^
        skills.hashCode ^
        timestamp.hashCode;
  }
}