import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.username,
    required this.avatarUrl,
    required this.text,
    required this.createdAt,
  });

  factory Comment.fromMap(Map<String, dynamic> map, String id, String postId) =>
      Comment(
        id: id,
        postId: postId,
        userId: map['userId'] ?? '',
        username: map['username'] ?? 'User',
        avatarUrl: map['avatarUrl'] ?? '',
        text: map['text'] ?? '',
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  factory Comment.fromSnapshot(DocumentSnapshot snap, String postId) {
    final data = snap.data()! as Map<String, dynamic>;
    return Comment.fromMap(data, snap.id, postId);
  }
  final String id;
  final String postId;
  final String userId;
  final String username;
  final String avatarUrl;
  final String text;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
    'postId': postId,
    'userId': userId,
    'username': username,
    'avatarUrl': avatarUrl,
    'text': text,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
