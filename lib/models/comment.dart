import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String postId;
  final String userId;
  final String username;
  final String avatarUrl;
  final String text;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.username,
    required this.avatarUrl,
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'userId': userId,
      'username': username,
      'avatarUrl': avatarUrl,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Comment.fromMap(Map<String, dynamic> map, String id, String postId) {
    return Comment(
      id: id,
      postId: postId,
      userId: map['userId'] ?? '',
      username: map['username'] ?? 'User',
      avatarUrl: map['avatarUrl'] ?? '',
      text: map['text'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory Comment.fromSnapshot(DocumentSnapshot snap, String postId) {
    final data = snap.data() as Map<String, dynamic>;
    return Comment.fromMap(data, snap.id, postId);
  }
}
