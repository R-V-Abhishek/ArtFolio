import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.imageUrl,
    required this.createdAt,
    required this.isRead,
  });

  factory Message.fromMap(Map<String, dynamic> map) => Message(
        id: map['id'] ?? '',
        conversationId: map['conversationId'] ?? '',
        senderId: map['senderId'] ?? '',
        receiverId: map['receiverId'] ?? '',
        text: map['text'] ?? '',
        imageUrl: map['imageUrl'] ?? '',
        createdAt: map['createdAt'] != null 
            ? (map['createdAt'] as Timestamp).toDate()
            : DateTime.now(), // Fallback for pending server timestamp
        isRead: map['isRead'] ?? false,
      );

  factory Message.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data()! as Map<String, dynamic>;
    return Message.fromMap(data);
  }

  final String id;
  final String conversationId;
  final String senderId;
  final String receiverId;
  final String text;
  final String imageUrl;
  final DateTime createdAt;
  final bool isRead;

  Map<String, dynamic> toMap() => {
        'id': id,
        'conversationId': conversationId,
        'senderId': senderId,
        'receiverId': receiverId,
        'text': text,
        'imageUrl': imageUrl,
        'createdAt': Timestamp.fromDate(createdAt),
        'isRead': isRead,
      };
}

class Conversation {
  Conversation({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
  });

  factory Conversation.fromMap(Map<String, dynamic> map) => Conversation(
        id: map['id'] ?? '',
        participants: List<String>.from(map['participants'] ?? []),
        lastMessage: map['lastMessage'] ?? '',
        lastMessageTime: (map['lastMessageTime'] as Timestamp).toDate(),
        unreadCount: Map<String, int>.from(map['unreadCount'] ?? {}),
      );

  factory Conversation.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data()! as Map<String, dynamic>;
    return Conversation.fromMap(data);
  }

  final String id;
  final List<String> participants;
  final String lastMessage;
  final DateTime lastMessageTime;
  final Map<String, int> unreadCount;

  Map<String, dynamic> toMap() => {
        'id': id,
        'participants': participants,
        'lastMessage': lastMessage,
        'lastMessageTime': Timestamp.fromDate(lastMessageTime),
        'unreadCount': unreadCount,
      };
}
