import 'dart:convert';

import 'package:flutter/material.dart';
import '../models/profile_readme.dart';
import '../services/firestore_image_service.dart';

/// Widget to display a profile README with styled blocks
class ProfileReadmeDisplay extends StatelessWidget {
  const ProfileReadmeDisplay({
    super.key,
    required this.readme,
    this.onSkillTap,
  });

  final ProfileReadme readme;
  final void Function(String skill)? onSkillTap;

  @override
  Widget build(BuildContext context) {
    final sortedBlocks = readme.sortedBlocks;

    if (sortedBlocks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.article_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'No README yet',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Create a profile README to tell your story',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: sortedBlocks
          .map((block) => _buildBlock(context, block))
          .toList(),
    );
  }

  Widget _buildBlock(BuildContext context, ReadmeBlock block) {
    switch (block.type) {
      case ReadmeBlockType.header1:
        return _buildHeader1(context, block);
      case ReadmeBlockType.header2:
        return _buildHeader2(context, block);
      case ReadmeBlockType.header3:
        return _buildHeader3(context, block);
      case ReadmeBlockType.text:
        return _buildText(context, block);
      case ReadmeBlockType.image:
        return _buildImage(context, block);
      case ReadmeBlockType.skillsTags:
        return _buildSkillsTags(context, block);
      case ReadmeBlockType.quote:
        return _buildQuote(context, block);
      case ReadmeBlockType.list:
        return _buildList(context, block);
      case ReadmeBlockType.divider:
        return _buildDivider(context);
    }
  }

  Widget _buildHeader1(BuildContext context, ReadmeBlock block) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12, left: 16, right: 16),
      child: Text(
        block.content,
        style: Theme.of(
          context,
        ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildHeader2(BuildContext context, ReadmeBlock block) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8, left: 16, right: 16),
      child: Text(
        block.content,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildHeader3(BuildContext context, ReadmeBlock block) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8, left: 16, right: 16),
      child: Text(
        block.content,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildText(BuildContext context, ReadmeBlock block) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(block.content, style: Theme.of(context).textTheme.bodyMedium),
    );
  }

  Widget _buildImage(BuildContext context, ReadmeBlock block) {
    if (block.imageUrl == null || block.imageUrl!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _FirestoreImageWidget(imageId: block.imageUrl!),
          ),
          if (block.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
              child: Text(
                block.content,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSkillsTags(BuildContext context, ReadmeBlock block) {
    final tags = List<String>.from(block.metadata?['tags'] ?? <String>[]);

    if (tags.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: tags.map((tag) {
          return ActionChip(
            label: Text(tag),
            avatar: const Icon(Icons.local_offer, size: 16),
            onPressed: onSkillTap != null ? () => onSkillTap!(tag) : null,
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            labelStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuote(BuildContext context, ReadmeBlock block) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 4,
          ),
        ),
      ),
      child: Text(
        block.content,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontStyle: FontStyle.italic,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, ReadmeBlock block) {
    final lines = block.content.split('\n').where((l) => l.trim().isNotEmpty);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines.map((line) {
          // Remove existing bullet points if any
          final cleanLine = line.trim().replaceFirst(
            RegExp(r'^[•\-\*]\s*'),
            '',
          );
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• ',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: Text(
                    cleanLine,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Divider(
        thickness: 1,
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
    );
  }
}

/// Widget to display images stored in Firestore (base64)
class _FirestoreImageWidget extends StatefulWidget {
  const _FirestoreImageWidget({required this.imageId});

  final String imageId;

  @override
  State<_FirestoreImageWidget> createState() => _FirestoreImageWidgetState();
}

class _FirestoreImageWidgetState extends State<_FirestoreImageWidget> {
  String? _base64Data;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(_FirestoreImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload image if imageId changed
    if (oldWidget.imageId != widget.imageId) {
      setState(() {
        _isLoading = true;
        _error = null;
        _base64Data = null;
      });
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    try {
      final imageService = FirestoreImageService();
      final base64 = await imageService.getImageData(widget.imageId);
      if (mounted) {
        setState(() {
          _base64Data = base64;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 100,
        color: Colors.grey.shade100,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _base64Data == null) {
      return Container(
        height: 100,
        color: Colors.grey.shade300,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.broken_image, size: 48, color: Colors.grey),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Error loading image',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      );
    }

    try {
      final bytes = base64Decode(_base64Data!);
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 100,
          color: Colors.grey.shade300,
          child: const Icon(Icons.broken_image, size: 48),
        ),
      );
    } catch (e) {
      return Container(
        height: 100,
        color: Colors.grey.shade300,
        child: const Icon(Icons.broken_image, size: 48),
      );
    }
  }
}
