import 'package:flutter/material.dart';

import '../models/post.dart';
import '../widgets/post_card.dart';

class PostDetailScreen extends StatelessWidget {

  const PostDetailScreen({super.key, required this.post});
  final Post post;

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Post'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(child: PostCard(post: post)),
    );
}
