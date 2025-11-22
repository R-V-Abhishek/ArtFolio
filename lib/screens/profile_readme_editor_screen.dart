import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/profile_readme.dart';
import '../services/firestore_image_service.dart';
import '../services/firestore_service.dart';
import '../widgets/profile_readme_display.dart';

/// Visual editor for creating and editing profile README
class ProfileReadmeEditorScreen extends StatefulWidget {
  const ProfileReadmeEditorScreen({
    super.key,
    required this.userId,
    this.initialReadme,
  });

  final String userId;
  final ProfileReadme? initialReadme;

  @override
  State<ProfileReadmeEditorScreen> createState() =>
      _ProfileReadmeEditorScreenState();
}

class _ProfileReadmeEditorScreenState extends State<ProfileReadmeEditorScreen> {
  late ProfileReadme _readme;
  bool _saving = false;
  bool _previewMode = false;
  final _firestore = FirestoreService();
  final _imageService = FirestoreImageService();

  @override
  void initState() {
    super.initState();
    _readme =
        widget.initialReadme ?? ProfileReadme.defaultReadme(widget.userId);
  }

  Future<void> _saveReadme() async {
    setState(() => _saving = true);
    try {
      await _firestore.saveProfileReadme(_readme);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile README saved!')));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _addBlock(ReadmeBlockType type) {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final maxOrder = _readme.blocks.isEmpty
        ? 0
        : _readme.blocks.map((b) => b.order).reduce(max);

    final newBlock = ReadmeBlock(
      id: newId,
      type: type,
      content: _getDefaultContent(type),
      order: maxOrder + 1,
      metadata: type == ReadmeBlockType.skillsTags
          ? {'tags': <String>[]}
          : null,
    );

    setState(() {
      _readme = _readme.copyWith(
        blocks: [..._readme.blocks, newBlock],
        lastUpdated: DateTime.now(),
      );
    });
  }

  String _getDefaultContent(ReadmeBlockType type) {
    switch (type) {
      case ReadmeBlockType.header1:
        return 'Heading 1';
      case ReadmeBlockType.header2:
        return 'Heading 2';
      case ReadmeBlockType.header3:
        return 'Heading 3';
      case ReadmeBlockType.text:
        return 'Enter your text here...';
      case ReadmeBlockType.quote:
        return 'An inspiring quote';
      case ReadmeBlockType.list:
        return '• Item 1\n• Item 2\n• Item 3';
      case ReadmeBlockType.skillsTags:
        return 'Click to add skills';
      case ReadmeBlockType.image:
        return 'Tap to add image';
      case ReadmeBlockType.divider:
        return '';
    }
  }

  void _deleteBlock(String blockId) {
    setState(() {
      _readme = _readme.copyWith(
        blocks: _readme.blocks.where((b) => b.id != blockId).toList(),
        lastUpdated: DateTime.now(),
      );
    });
  }

  void _updateBlock(ReadmeBlock updatedBlock) {
    setState(() {
      final index = _readme.blocks.indexWhere((b) => b.id == updatedBlock.id);
      if (index != -1) {
        final updated = List<ReadmeBlock>.from(_readme.blocks);
        updated[index] = updatedBlock;
        _readme = _readme.copyWith(
          blocks: updated,
          lastUpdated: DateTime.now(),
        );
      }
    });
  }

  void _moveBlock(int oldIndex, int newIndex) {
    setState(() {
      final blocks = List<ReadmeBlock>.from(_readme.sortedBlocks);
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = blocks.removeAt(oldIndex);
      blocks.insert(newIndex, item);

      // Update order values
      for (var i = 0; i < blocks.length; i++) {
        blocks[i] = blocks[i].copyWith(order: i);
      }

      _readme = _readme.copyWith(blocks: blocks, lastUpdated: DateTime.now());
    });
  }

  Future<void> _pickImage(ReadmeBlock block) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
      );

      if (pickedFile == null) return;

      // Show loading
      if (!mounted) return;
      unawaited(
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => const Center(child: CircularProgressIndicator()),
        ),
      );

      final file = File(pickedFile.path);
      final imageId = await _imageService.uploadImage(
        fileName: pickedFile.name,
        folder: 'profile_readme/${widget.userId}',
        userId: widget.userId,
        file: file,
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading

      // Store the Firestore document ID as the imageUrl
      _updateBlock(block.copyWith(imageUrl: imageId));
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading if open
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile README'),
        actions: [
          IconButton(
            icon: Icon(_previewMode ? Icons.edit : Icons.visibility),
            tooltip: _previewMode ? 'Edit' : 'Preview',
            onPressed: () => setState(() => _previewMode = !_previewMode),
          ),
          if (!_previewMode)
            IconButton(
              icon: const Icon(Icons.help_outline),
              tooltip: 'Help',
              onPressed: _showHelp,
            ),
          TextButton(
            onPressed: _saving ? null : _saveReadme,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: _previewMode ? _buildPreview() : _buildEditor(),
      floatingActionButton: _previewMode
          ? null
          : FloatingActionButton(
              onPressed: _showAddBlockMenu,
              child: const Icon(Icons.add),
            ),
    );
  }

  Widget _buildPreview() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: ProfileReadmeDisplay(readme: _readme),
  );

  Widget _buildEditor() {
    final blocks = _readme.sortedBlocks;

    if (blocks.isEmpty) {
      return Center(
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
              'Start building your profile!',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add content blocks',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.all(8).copyWith(bottom: 80),
      itemCount: blocks.length,
      onReorder: _moveBlock,
      itemBuilder: (context, index) {
        final block = blocks[index];
        return _BlockEditor(
          key: ValueKey(block.id),
          block: block,
          onUpdate: _updateBlock,
          onDelete: () => _deleteBlock(block.id),
          onPickImage: () => _pickImage(block),
        );
      },
    );
  }

  void _showAddBlockMenu() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SafeArea(
          child: Column(
            children: [
              ListTile(
                title: const Text(
                  'Add Content Block',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildBlockOption(
                      Icons.title,
                      'Heading 1',
                      'Large title',
                      () => _addBlock(ReadmeBlockType.header1),
                    ),
                    _buildBlockOption(
                      Icons.text_fields,
                      'Heading 2',
                      'Medium title',
                      () => _addBlock(ReadmeBlockType.header2),
                    ),
                    _buildBlockOption(
                      Icons.text_format,
                      'Heading 3',
                      'Small title',
                      () => _addBlock(ReadmeBlockType.header3),
                    ),
                    _buildBlockOption(
                      Icons.notes,
                      'Text',
                      'Paragraph content',
                      () => _addBlock(ReadmeBlockType.text),
                    ),
                    _buildBlockOption(
                      Icons.image_outlined,
                      'Image',
                      'Add a photo',
                      () => _addBlock(ReadmeBlockType.image),
                    ),
                    _buildBlockOption(
                      Icons.label_outline,
                      'Skills Tags',
                      'Visual skill badges',
                      () => _addBlock(ReadmeBlockType.skillsTags),
                    ),
                    _buildBlockOption(
                      Icons.format_quote,
                      'Quote',
                      'Inspiring quote',
                      () => _addBlock(ReadmeBlockType.quote),
                    ),
                    _buildBlockOption(
                      Icons.list,
                      'List',
                      'Bullet points',
                      () => _addBlock(ReadmeBlockType.list),
                    ),
                    _buildBlockOption(
                      Icons.remove,
                      'Divider',
                      'Horizontal line',
                      () => _addBlock(ReadmeBlockType.divider),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlockOption(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) => ListTile(
    leading: Icon(icon),
    title: Text(title),
    subtitle: Text(subtitle),
    onTap: () {
      Navigator.pop(context);
      onTap();
    },
  );

  void _showHelp() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to Use'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Build Your Profile README',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Tap + to add content blocks'),
              Text('• Long press and drag to reorder'),
              Text('• Tap blocks to edit content'),
              Text('• Use Preview to see final result'),
              Text('• Skills tags link to your work'),
              SizedBox(height: 12),
              Text('Tips:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('• Start with a compelling intro'),
              Text('• Add images to showcase work'),
              Text('• Use skills tags strategically'),
              Text('• Keep it concise and visual'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

/// Individual block editor widget
class _BlockEditor extends StatefulWidget {
  const _BlockEditor({
    required super.key,
    required this.block,
    required this.onUpdate,
    required this.onDelete,
    required this.onPickImage,
  });

  final ReadmeBlock block;
  final void Function(ReadmeBlock) onUpdate;
  final VoidCallback onDelete;
  final VoidCallback onPickImage;

  @override
  State<_BlockEditor> createState() => _BlockEditorState();
}

class _BlockEditorState extends State<_BlockEditor> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.block.content);
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      // Save when focus is lost
      if (_controller.text != widget.block.content) {
        widget.onUpdate(widget.block.copyWith(content: _controller.text));
      }
    }
  }

  @override
  void didUpdateWidget(_BlockEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // For image blocks, never update if only content (caption) changed
    // Only rebuild if imageUrl changed (new image uploaded)
    if (widget.block.type == ReadmeBlockType.image) {
      if (oldWidget.block.imageUrl != widget.block.imageUrl) {
        // New image uploaded, allow rebuild
        setState(() {});
      }
      // Update caption text without rebuilding
      if (oldWidget.block.content != widget.block.content &&
          !_focusNode.hasFocus &&
          _controller.text != widget.block.content) {
        _controller.text = widget.block.content;
      }
      return;
    }

    // For other block types, update as normal
    if (oldWidget.block.content != widget.block.content &&
        !_focusNode.hasFocus &&
        _controller.text != widget.block.content) {
      _controller.text = widget.block.content;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    if (_controller.text != widget.block.content) {
      widget.onUpdate(widget.block.copyWith(content: _controller.text));
    }
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with type and actions
          ListTile(
            dense: true,
            leading: Icon(_getBlockIcon(), size: 20),
            title: Text(_getBlockTypeName(), style: theme.textTheme.labelLarge),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.block.type == ReadmeBlockType.image)
                  IconButton(
                    icon: const Icon(Icons.upload),
                    iconSize: 20,
                    onPressed: widget.onPickImage,
                    tooltip: 'Upload Image',
                  ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  iconSize: 20,
                  onPressed: widget.onDelete,
                  tooltip: 'Delete',
                ),
                const Icon(Icons.drag_handle, size: 20),
              ],
            ),
          ),
          const Divider(height: 1),
          // Content editor
          Padding(
            padding: const EdgeInsets.all(12),
            child: _buildContentEditor(),
          ),
        ],
      ),
    );
  }

  Widget _buildContentEditor() {
    switch (widget.block.type) {
      case ReadmeBlockType.image:
        return _buildImageEditor();
      case ReadmeBlockType.skillsTags:
        return _buildSkillsEditor();
      case ReadmeBlockType.divider:
        return const Center(
          child: Text('────────', style: TextStyle(color: Colors.grey)),
        );
      case ReadmeBlockType.header1:
      case ReadmeBlockType.header2:
      case ReadmeBlockType.header3:
      case ReadmeBlockType.text:
      case ReadmeBlockType.quote:
      case ReadmeBlockType.list:
        return _buildTextEditor();
    }
  }

  Widget _buildTextEditor() {
    if (_isEditing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            maxLines: _getMaxLines(),
            decoration: const InputDecoration(
              hintText: 'Enter content...',
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.all(12),
            ),
            style: _getTextStyle(),
            autofocus: true,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  _controller.text = widget.block.content;
                  setState(() => _isEditing = false);
                },
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: _save, child: const Text('Save')),
            ],
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: () => setState(() => _isEditing = true),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          widget.block.content.isEmpty
              ? 'Tap to edit...'
              : widget.block.content,
          style: _getTextStyle().copyWith(
            color: widget.block.content.isEmpty ? Colors.grey : null,
          ),
        ),
      ),
    );
  }

  Widget _buildImageEditor() {
    if (widget.block.imageUrl == null || widget.block.imageUrl!.isEmpty) {
      return GestureDetector(
        onTap: widget.onPickImage,
        child: Container(
          height: 150,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300, width: 2),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade100,
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text('Tap to add image', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Column(
      key: ValueKey('image_editor_${widget.block.imageUrl}'),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _FirestoreImageWidget(
            key: ValueKey('image_${widget.block.imageUrl}'),
            imageId: widget.block.imageUrl!,
            height: 200,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: const InputDecoration(
            labelText: 'Caption (optional)',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text('Replace Image'),
                onPressed: widget.onPickImage,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSkillsEditor() {
    final tags = List<String>.from(
      widget.block.metadata?['tags'] ?? <String>[],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...tags.map(
              (tag) => Chip(
                label: Text(tag),
                onDeleted: () {
                  final updated = List<String>.from(tags)..remove(tag);
                  widget.onUpdate(
                    widget.block.copyWith(metadata: {'tags': updated}),
                  );
                },
              ),
            ),
            ActionChip(
              avatar: const Icon(Icons.add, size: 16),
              label: const Text('Add Skill'),
              onPressed: () => _showAddSkillDialog(tags),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _showAddSkillDialog(List<String> currentTags) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Skill'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'e.g., Digital Painting, Blender, UI Design',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final updated = List<String>.from(currentTags)..add(result);
      widget.onUpdate(widget.block.copyWith(metadata: {'tags': updated}));
    }
  }

  IconData _getBlockIcon() {
    switch (widget.block.type) {
      case ReadmeBlockType.header1:
        return Icons.title;
      case ReadmeBlockType.header2:
        return Icons.text_fields;
      case ReadmeBlockType.header3:
        return Icons.text_format;
      case ReadmeBlockType.text:
        return Icons.notes;
      case ReadmeBlockType.image:
        return Icons.image_outlined;
      case ReadmeBlockType.skillsTags:
        return Icons.label_outline;
      case ReadmeBlockType.quote:
        return Icons.format_quote;
      case ReadmeBlockType.list:
        return Icons.list;
      case ReadmeBlockType.divider:
        return Icons.remove;
    }
  }

  String _getBlockTypeName() {
    switch (widget.block.type) {
      case ReadmeBlockType.header1:
        return 'Heading 1';
      case ReadmeBlockType.header2:
        return 'Heading 2';
      case ReadmeBlockType.header3:
        return 'Heading 3';
      case ReadmeBlockType.text:
        return 'Text';
      case ReadmeBlockType.image:
        return 'Image';
      case ReadmeBlockType.skillsTags:
        return 'Skills';
      case ReadmeBlockType.quote:
        return 'Quote';
      case ReadmeBlockType.list:
        return 'List';
      case ReadmeBlockType.divider:
        return 'Divider';
    }
  }

  int _getMaxLines() {
    switch (widget.block.type) {
      case ReadmeBlockType.header1:
      case ReadmeBlockType.header2:
      case ReadmeBlockType.header3:
        return 2;
      case ReadmeBlockType.quote:
        return 3;
      case ReadmeBlockType.list:
        return 10;
      case ReadmeBlockType.text:
      case ReadmeBlockType.image:
      case ReadmeBlockType.skillsTags:
      case ReadmeBlockType.divider:
        return 5;
    }
  }

  TextStyle _getTextStyle() {
    final theme = Theme.of(context);
    switch (widget.block.type) {
      case ReadmeBlockType.header1:
        return theme.textTheme.headlineMedium!.copyWith(
          fontWeight: FontWeight.bold,
        );
      case ReadmeBlockType.header2:
        return theme.textTheme.titleLarge!.copyWith(
          fontWeight: FontWeight.bold,
        );
      case ReadmeBlockType.header3:
        return theme.textTheme.titleMedium!.copyWith(
          fontWeight: FontWeight.w600,
        );
      case ReadmeBlockType.quote:
        return theme.textTheme.bodyLarge!.copyWith(
          fontStyle: FontStyle.italic,
          color: theme.colorScheme.primary,
        );
      case ReadmeBlockType.text:
      case ReadmeBlockType.list:
      case ReadmeBlockType.image:
      case ReadmeBlockType.skillsTags:
      case ReadmeBlockType.divider:
        return theme.textTheme.bodyMedium!;
    }
  }
}

/// Widget to display images stored in Firestore (base64)
class _FirestoreImageWidget extends StatefulWidget {
  const _FirestoreImageWidget({
    super.key,
    required this.imageId,
    this.height,
  });

  final String imageId;
  final double? height;

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
        height: widget.height ?? 200,
        color: Colors.grey.shade100,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _base64Data == null) {
      return Container(
        height: widget.height ?? 200,
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
        height: widget.height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          height: widget.height ?? 200,
          color: Colors.grey.shade300,
          child: const Icon(Icons.broken_image, size: 48),
        ),
      );
    } catch (e) {
      return Container(
        height: widget.height ?? 200,
        color: Colors.grey.shade300,
        child: const Icon(Icons.broken_image, size: 48),
      );
    }
  }
}
