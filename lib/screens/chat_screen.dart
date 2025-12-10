import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/message.dart';
import '../models/user.dart' as model;
import '../services/messaging_service.dart';
import '../widgets/firestore_image.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.otherUser});

  final model.User otherUser;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _conversationId = '';
  late Stream<List<Message>>? _messagesStream;
  StreamSubscription<List<Message>>? _streamSubscription;
  List<Message> _messages = [];

  @override
  void initState() {
    super.initState();
    _initConversation();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _streamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initConversation() async {
    final conversationId = await MessagingService.instance
        .getOrCreateConversation(widget.otherUser.id);
    
    if (!mounted) return;
    
    setState(() {
      _conversationId = conversationId;
    });
    
    // Set up the stream and actively listen to it
    _messagesStream = MessagingService.instance.getMessagesStream(
      conversationId,
    );
    
    // Subscribe to stream updates
    _streamSubscription = _messagesStream!.listen((messages) {
      if (mounted) {
        setState(() {
          _messages = messages;
        });
      }
    });
    
    await MessagingService.instance.markAsRead(conversationId);
  }

  Future<void> _refreshMessages() async {
    if (kDebugMode) {
      debugPrint('Manually refreshing messages...');
    }
    // Cancel old subscription
    await _streamSubscription?.cancel();
    
    // Recreate stream and subscription
    _messagesStream = MessagingService.instance.getMessagesStream(
      _conversationId,
    );
    
    _streamSubscription = _messagesStream!.listen((messages) {
      if (mounted) {
        setState(() {
          _messages = messages;
        });
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _conversationId.isEmpty) return;

    _controller.clear();

    // Send message - Firestore stream will automatically update both sender and receiver
    await MessagingService.instance.sendMessage(
      conversationId: _conversationId,
      receiverId: widget.otherUser.id,
      text: text,
    );

    // Refresh messages after sending to ensure immediate visibility
    await _refreshMessages();

    // Scroll to bottom to show new message
    _scrollToBottomIfNeeded();
  }

  void _scrollToBottomIfNeeded() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0, // Scroll to top since list is reversed
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  Widget _buildMessagesList() {
    // Auto-scroll when new messages arrive
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients &&
          _scrollController.position.pixels < 100) {
        _scrollToBottomIfNeeded();
      }
    });

    if (_messages.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshMessages,
        child: ListView(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: Center(
                child: Text(
                  'Start the conversation!',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshMessages,
      child: ListView.builder(
        reverse: true,
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final message = _messages[index];
          final isMe =
              message.senderId == FirebaseAuth.instance.currentUser?.uid;

          return _MessageBubble(message: message, isMe: isMe);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            _buildAvatar(context),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUser.fullName.isNotEmpty
                        ? widget.otherUser.fullName
                        : widget.otherUser.username,
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    '@${widget.otherUser.username}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh messages',
            onPressed: _refreshMessages,
          ),
        ],
      ),
      body: Column(
              children: [
                Expanded(
                  child: _conversationId.isEmpty
                      ? const SizedBox.shrink()
                      : _buildMessagesList(),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            maxLines: null,
                            textCapitalization: TextCapitalization.sentences,
                          ),
                        ),
                        const SizedBox(width: 8),
                        FloatingActionButton(
                          mini: true,
                          onPressed: _sendMessage,
                          child: const Icon(Icons.send),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final ref = widget.otherUser.profilePictureUrl.trim();
    final fallbackText =
        (widget.otherUser.username.isNotEmpty
                ? widget.otherUser.username[0]
                : 'A')
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
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else if (ref.startsWith('http')) {
      avatar = Image.network(ref, fit: BoxFit.cover);
    } else if (ref.startsWith('assets/')) {
      avatar = Image.asset(ref, fit: BoxFit.cover);
    } else {
      avatar = FirestoreImage(imageId: ref, width: 40, height: 40);
    }

    return SizedBox(width: 40, height: 40, child: ClipOval(child: avatar));
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMe});

  final Message message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isMe
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20).copyWith(
                bottomRight: isMe ? const Radius.circular(4) : null,
                bottomLeft: !isMe ? const Radius.circular(4) : null,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  message.text,
                  style: TextStyle(
                    color: isMe
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.createdAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe
                        ? Theme.of(
                            context,
                          ).colorScheme.onPrimary.withValues(alpha: 0.7)
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
