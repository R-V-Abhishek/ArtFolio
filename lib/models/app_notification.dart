import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  like,
  kudos,
  comment,
  share,
  follow,
  collab,
  sponsor,
  orgUpdate,
  message,
}

class AppNotification {
  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    this.actorId,
    this.postId,
    this.data,
    required this.createdAt,
    this.read = false,
  });

  factory AppNotification.fromSnapshot(DocumentSnapshot snap) {
    final m = snap.data()! as Map<String, dynamic>;
    return AppNotification(
      id: snap.id,
      userId: m['userId'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == m['type'],
        orElse: () => NotificationType.like,
      ),
      title: m['title'] ?? '',
      actorId: m['actorId'],
      postId: m['postId'],
      data: (m['data'] as Map?)?.cast<String, dynamic>(),
      createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      read: m['read'] ?? false,
    );
  }
  final String id;
  final String userId; // recipient
  final NotificationType type;
  final String title; // short description for row
  final String? actorId; // who triggered
  final String? postId; // related post/project id
  final Map<String, dynamic>? data; // extra payload
  final DateTime createdAt;
  final bool read;

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'type': type.name,
    'title': title,
    'actorId': actorId,
    'postId': postId,
    'data': data,
    'createdAt': Timestamp.fromDate(createdAt),
    'read': read,
  };
}
