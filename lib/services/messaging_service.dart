import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/message.dart';

class MessagingService {
  MessagingService._();
  static final MessagingService instance = MessagingService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUserId => _auth.currentUser?.uid ?? '';

  // Get or create conversation between two users
  Future<String> getOrCreateConversation(String otherUserId) async {
    final participants = [currentUserId, otherUserId]..sort();
    final conversationId = participants.join('_');

    final conversationDoc = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .get();

    if (!conversationDoc.exists) {
      await _firestore.collection('conversations').doc(conversationId).set({
        'id': conversationId,
        'participants': participants,
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount': {currentUserId: 0, otherUserId: 0},
      });
    }

    return conversationId;
  }

  // Send a message
  Future<void> sendMessage({
    required String conversationId,
    required String receiverId,
    required String text,
    String imageUrl = '',
  }) async {
    final messageId = _firestore.collection('messages').doc().id;

    // Use a map directly with server timestamp
    await _firestore.collection('messages').doc(messageId).set({
      'id': messageId,
      'conversationId': conversationId,
      'senderId': currentUserId,
      'receiverId': receiverId,
      'text': text,
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    // Update conversation
    await _firestore.collection('conversations').doc(conversationId).update({
      'lastMessage': text.isNotEmpty ? text : '📷 Image',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCount.$receiverId': FieldValue.increment(1),
    });

    // Create notification for the receiver
    await _createMessageNotification(
      receiverId: receiverId,
      messageText: text,
      conversationId: conversationId,
    );
  }

  // Create a notification for new message
  Future<void> _createMessageNotification({
    required String receiverId,
    required String messageText,
    required String conversationId,
  }) async {
    try {
      final notificationId = _firestore.collection('notifications').doc().id;
      final preview = messageText.length > 50
          ? '${messageText.substring(0, 50)}...'
          : messageText;

      await _firestore.collection('notifications').doc(notificationId).set({
        'id': notificationId,
        'userId': receiverId,
        'type': 'message',
        'title': 'New message',
        'actorId': currentUserId,
        'data': {'conversationId': conversationId, 'preview': preview},
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      // Fail silently to not interrupt message sending
    }
  }

  // Mark messages as read
  Future<void> markAsRead(String conversationId) async {
    final messages = await _firestore
        .collection('messages')
        .where('conversationId', isEqualTo: conversationId)
        .where('receiverId', isEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in messages.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();

    // Reset unread count
    await _firestore.collection('conversations').doc(conversationId).update({
      'unreadCount.$currentUserId': 0,
    });
  }

  // Get conversations for current user
  Stream<List<Conversation>> getConversationsStream() {
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots(includeMetadataChanges: true)
        .map(
          (snapshot) => snapshot.docs.map(Conversation.fromSnapshot).toList(),
        );
  }

  // Get messages for a conversation
  Stream<List<Message>> getMessagesStream(String conversationId) {
    return _firestore
        .collection('messages')
        .where('conversationId', isEqualTo: conversationId)
        .orderBy('createdAt', descending: true)
        .snapshots(includeMetadataChanges: true) // Include pending writes
        .handleError((error) {
          if (kDebugMode) {
            debugPrint('Error loading messages: $error');
          }
          // If index is building, try without orderBy
          return _firestore
              .collection('messages')
              .where('conversationId', isEqualTo: conversationId)
              .snapshots(includeMetadataChanges: true);
        })
        .map((snapshot) {
          if (kDebugMode) {
            debugPrint(
              'Stream update: ${snapshot.docs.length} messages, '
              'fromCache: ${snapshot.metadata.isFromCache}, '
              'hasPendingWrites: ${snapshot.metadata.hasPendingWrites}',
            );
          }
          final messages = snapshot.docs.map(Message.fromSnapshot).toList();
          // Sort manually if we couldn't use orderBy
          messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return messages;
        });
  }

  // Get total unread count for current user
  Stream<int> getUnreadCountStream() {
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) {
          var total = 0;
          for (final doc in snapshot.docs) {
            final data = doc.data();
            final unreadCount = data['unreadCount'] as Map<String, dynamic>?;
            total += (unreadCount?[currentUserId] as int?) ?? 0;
          }
          return total;
        });
  }
}
