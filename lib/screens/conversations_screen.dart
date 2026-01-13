import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/message.dart';
import '../models/user.dart' as model;
import '../routes/app_routes.dart';
import '../routes/route_arguments.dart';
import '../services/firestore_service.dart';
import '../services/messaging_service.dart';
import '../widgets/firestore_image.dart';

class ConversationsScreen extends StatelessWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.newMessage);
            },
            tooltip: 'New Message',
          ),
        ],
      ),
      body: StreamBuilder<List<Conversation>>(
        stream: MessagingService.instance.getConversationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Unable to load messages',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please check your connection and try again',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          final conversations = snapshot.data ?? [];

          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.message_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No messages yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start a conversation with an artist',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              final otherUserId = conversation.participants.firstWhere(
                (id) => id != currentUserId,
              );

              return FutureBuilder<model.User?>(
                future: FirestoreService().getUserById(otherUserId),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const ListTile(
                      leading: CircleAvatar(),
                      title: Text('Loading...'),
                    );
                  }

                  final otherUser = userSnapshot.data!;
                  final unreadCount =
                      conversation.unreadCount[currentUserId] ?? 0;

                  return _ConversationTile(
                    user: otherUser,
                    conversation: conversation,
                    unreadCount: unreadCount,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.user,
    required this.conversation,
    required this.unreadCount,
  });

  final model.User user;
  final Conversation conversation;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: _buildAvatar(context),
        title: Text(
          user.fullName.isNotEmpty ? user.fullName : user.username,
          style: TextStyle(
            fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          conversation.lastMessage,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatTime(conversation.lastMessageTime),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (unreadCount > 0) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  unreadCount.toString(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        onTap: () {
          Navigator.of(context).pushNamed(
            AppRoutes.chat,
            arguments: ChatArguments(otherUser: user),
          );
        },
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final ref = user.profilePictureUrl.trim();
    final fallbackText = (user.username.isNotEmpty ? user.username[0] : 'A')
        .toUpperCase();

    Widget avatar;
    if (ref.isEmpty) {
      avatar = Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          fallbackText,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else if (ref.startsWith('http')) {
      avatar = Image.network(ref, fit: BoxFit.cover);
    } else if (ref.startsWith('assets/')) {
      avatar = Image.asset(ref, fit: BoxFit.cover);
    } else {
      avatar = FirestoreImage(imageId: ref, width: 50, height: 50);
    }

    return SizedBox(width: 50, height: 50, child: ClipOval(child: avatar));
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
}
