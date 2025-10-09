import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/post.dart';
import '../services/firestore_image_service.dart';
import '../theme/theme.dart';
import 'image_gallery_screen.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  // Form controllers
  final _captionCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();
  final _skillCtrl = TextEditingController();

  // State
  PostType _type = PostType.image;
  PostVisibility _visibility = PostVisibility.public;
  final List<String> _tags = [];
  final List<String> _skills = [];
  final List<File> _images = [];

  // Optional location
  PostLocation? _location;

  // Upload state
  bool _isUploading = false;
  double _progress = 0.0; // 0..1
  String? _uploadStatus;

  // Services
  final _imagePicker = ImagePicker();
  final _imageStore = FirestoreImageService();

  // Drafts
  static const _draftKey = 'create_post_draft_v1';

  @override
  void initState() {
    super.initState();
    _loadDraftIfAny();
  }

  @override
  void dispose() {
    _captionCtrl.dispose();
    _tagCtrl.dispose();
    _skillCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDraftIfAny() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_draftKey);
    if (raw == null) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      setState(() {
        _type = _parseType(map['type'] as String?);
        _visibility = _parseVisibility(map['visibility'] as String?);
        _captionCtrl.text = (map['caption'] as String?) ?? '';
        _tags
          ..clear()
          ..addAll(List<String>.from(map['tags'] ?? const []));
        _skills
          ..clear()
          ..addAll(List<String>.from(map['skills'] ?? const []));
        final loc = map['location'] as Map<String, dynamic>?;
        if (loc != null) {
          _location = PostLocation.fromMap(loc);
        }
      });

      // Restore image files if they're still present
      final paths = List<String>.from((map['imagePaths'] ?? const []));
      for (final path in paths) {
        final f = File(path);
        if (await f.exists()) {
          _images.add(f);
        }
      }

      if (mounted && (paths.isNotEmpty || _captionCtrl.text.isNotEmpty)) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Draft restored')));
      }
    } catch (_) {
      // Ignore corrupt draft
    }
  }

  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final map = <String, dynamic>{
      'type': _type.name,
      'visibility': _visibility.name,
      'caption': _captionCtrl.text,
      'tags': _tags,
      'skills': _skills,
      'location': _location?.toMap(),
      'imagePaths': _images.map((e) => e.path).toList(),
    };
    await prefs.setString(_draftKey, jsonEncode(map));
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Draft saved')));
    }
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey);
  }

  PostType _parseType(String? name) {
    return PostType.values.firstWhere(
      (e) => e.name == name,
      orElse: () => PostType.image,
    );
  }

  PostVisibility _parseVisibility(String? name) {
    return PostVisibility.values.firstWhere(
      (e) => e.name == name,
      orElse: () => PostVisibility.public,
    );
  }

  // Image picking
  Future<void> _pickFromCamera() async {
    if (_type == PostType.idea) {
      _showInfo('Idea posts do not include media');
      return;
    }
    final x = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1440,
    );
    if (x != null) {
      setState(() {
        if (_type == PostType.image) {
          _images
            ..clear()
            ..add(File(x.path));
        } else {
          _images.add(File(x.path));
        }
      });
    }
  }

  Future<void> _pickFromGallery() async {
    if (_type == PostType.idea) {
      _showInfo('Idea posts do not include media');
      return;
    }

    if (_type == PostType.gallery) {
      final xs = await _imagePicker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1440,
      );
      if (xs.isNotEmpty) {
        setState(() {
          _images.addAll(xs.map((e) => File(e.path)));
        });
      }
    } else {
      final x = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1440,
      );
      if (x != null) {
        setState(() {
          _images
            ..clear()
            ..add(File(x.path));
        });
      }
    }
  }

  void _removeImageAt(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  Future<void> _editLocation() async {
    final cityCtrl = TextEditingController(text: _location?.city ?? '');
    final stateCtrl = TextEditingController(text: _location?.state ?? '');
    final countryCtrl = TextEditingController(text: _location?.country ?? '');
    final latCtrl = TextEditingController(
      text: _location?.latitude?.toString() ?? '',
    );
    final lngCtrl = TextEditingController(
      text: _location?.longitude?.toString() ?? '',
    );

    final res = await showDialog<PostLocation?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set location (optional)'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: cityCtrl,
                decoration: const InputDecoration(labelText: 'City'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: stateCtrl,
                decoration: const InputDecoration(labelText: 'State'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: countryCtrl,
                decoration: const InputDecoration(labelText: 'Country'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: latCtrl,
                      decoration: const InputDecoration(labelText: 'Lat'),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: lngCtrl,
                      decoration: const InputDecoration(labelText: 'Lng'),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(
                ctx,
                PostLocation(
                  city: cityCtrl.text.trim().isEmpty
                      ? null
                      : cityCtrl.text.trim(),
                  state: stateCtrl.text.trim().isEmpty
                      ? null
                      : stateCtrl.text.trim(),
                  country: countryCtrl.text.trim().isEmpty
                      ? null
                      : countryCtrl.text.trim(),
                  latitude: double.tryParse(latCtrl.text.trim()),
                  longitude: double.tryParse(lngCtrl.text.trim()),
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (res != null) {
      setState(() => _location = res);
    }
  }

  Future<void> _submit() async {
    // Validation
    if (_type != PostType.idea && _images.isEmpty) {
      _showError('Please add at least one image');
      return;
    }

    if (_captionCtrl.text.trim().isEmpty) {
      _showError('Caption cannot be empty');
      return;
    }

    try {
      setState(() {
        _isUploading = true;
        _progress = 0.0;
        _uploadStatus = 'Preparing…';
      });

      // Ensure user (allow anonymous for now)
      final auth = fb_auth.FirebaseAuth.instance;
      if (auth.currentUser == null) {
        await auth.signInAnonymously();
      }
      final userId = auth.currentUser!.uid;

      // Prepare post id
      final posts = FirebaseFirestore.instance.collection('posts');
      final postId = posts.doc().id;

      // Build base post
      var post = Post(
        id: postId,
        userId: userId,
        type: _type,
        caption: _captionCtrl.text.trim(),
        description: null,
        skills: List.of(_skills),
        tags: List.of(_tags),
        timestamp: DateTime.now(),
        visibility: _visibility,
        location: _location,
      );

      List<String> uploadedIds = [];

      if (_type != PostType.idea) {
        // Upload images sequentially with progress
        for (int i = 0; i < _images.length; i++) {
          final file = _images[i];
          final fileName = p.basename(file.path);

          setState(
            () => _uploadStatus = 'Uploading ${i + 1}/${_images.length}',
          );

          final stream = _imageStore.uploadImageWithProgress(
            fileName: fileName,
            folder: 'posts/$postId',
            file: file,
          );

          // Track combined progress: (i + pi) / N
          final completer = Completer<void>();
          late final StreamSubscription<double> sub;
          sub = stream.listen(
            (pi) {
              final combined = (i + pi) / _images.length;
              setState(() => _progress = combined.clamp(0.0, 0.99));
            },
            onError: (e) async {
              await sub.cancel();
              if (!completer.isCompleted) completer.completeError(e);
            },
            onDone: () async {
              await sub.cancel();
              if (!completer.isCompleted) completer.complete();
            },
          );

          await completer.future;

          // After progress completes, perform the actual upload and receive Firestore image ID
          final imageId = await _imageStore.uploadImage(
            fileName: fileName,
            folder: 'posts/$postId',
            file: file,
          );
          uploadedIds.add(imageId);
        }

        // Attach media to post
        if (_type == PostType.image) {
          post = post.copyWith(
            mediaUrl: uploadedIds.first,
            mediaUrls: [uploadedIds.first],
          );
        } else {
          post = post.copyWith(mediaUrls: uploadedIds);
        }
      }

      setState(() {
        _uploadStatus = 'Saving…';
        _progress = 0.99;
      });

      await posts.doc(postId).set(post.toMap());

      await _clearDraft();

      if (mounted) {
        setState(() {
          _isUploading = false;
          _progress = 1.0;
          _uploadStatus = 'Done';
        });
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      _showError('Failed to create post: $e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  void _showInfo(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final shouldSave = await _confirmDiscardOrSave();
        if (shouldSave == true) {
          await _saveDraft();
        }
        // Use navigator captured before await to avoid using context after async gap
        navigator.maybePop();
      },
      child: Scaffold(
        // Ensure content shifts for the keyboard on small screens
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: const Text('Create Post'),
          actions: [
            IconButton(
              tooltip: 'Save draft',
              onPressed: _saveDraft,
              icon: const Icon(Icons.save_outlined),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 900;
                if (wide) {
                  // In wide layouts, make both panes independently scrollable
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildMediaPane(),
                        ),
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.only(
                            bottom:
                                MediaQuery.of(context).viewInsets.bottom + 16,
                          ),
                          child: _buildFormPane(),
                        ),
                      ),
                    ],
                  );
                }
                // On narrow layouts, make the whole screen scrollable and keyboard-safe
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    16 + MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMediaPane(),
                      const SizedBox(height: 16),
                      _buildFormPane(),
                    ],
                  ),
                );
              },
            ),
            if (_isUploading) _buildUploadingOverlay(),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _hasUnsavedChanges ? _saveDraft : null,
                    icon: const Icon(Icons.drafts_outlined),
                    label: const Text('Save draft'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isUploading ? null : _submit,
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('Post'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool get _hasUnsavedChanges {
    return _captionCtrl.text.trim().isNotEmpty ||
        _images.isNotEmpty ||
        _tags.isNotEmpty ||
        _skills.isNotEmpty ||
        _location != null;
  }

  Future<bool?> _confirmDiscardOrSave() async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave without posting?'),
        content: const Text('You have unsaved changes. Save as draft?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save draft'),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaPane() {
    final isIdea = _type == PostType.idea;
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.photo_library_outlined),
                const SizedBox(width: 8),
                Text('Media', style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                FilledButton.tonalIcon(
                  onPressed: isIdea ? null : _pickFromGallery,
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Gallery'),
                ),
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  onPressed: isIdea ? null : _pickFromCamera,
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Camera'),
                ),
                if (_type == PostType.gallery) ...[
                  const SizedBox(width: 8),
                  FilledButton.tonalIcon(
                    onPressed: () async {
                      final picked = await Navigator.of(context)
                          .push<List<File>>(
                            MaterialPageRoute(
                              builder: (_) => const ImageGalleryScreen(),
                              fullscreenDialog: true,
                            ),
                          );
                      if (picked != null && picked.isNotEmpty) {
                        setState(() {
                          _images
                            ..clear()
                            ..addAll(picked);
                        });
                      }
                    },
                    icon: const Icon(Icons.collections),
                    label: const Text('Builder'),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            if (isIdea)
              _emptyHint('No media for Idea posts')
            else if (_images.isEmpty)
              _emptyHint('No images selected')
            else ...[
              if (_type == PostType.image)
                AspectRatio(
                  aspectRatio: 1,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_images.first, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton.filled(
                          onPressed: () => _removeImageAt(0),
                          icon: const Icon(Icons.close),
                        ),
                      ),
                    ],
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _images.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemBuilder: (context, index) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_images[index], fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: InkResponse(
                            onTap: () => _removeImageAt(index),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _emptyHint(String text) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          text,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _buildFormPane() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type selection
            Text('Post type', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<PostType>(
              segments: const [
                ButtonSegment(
                  value: PostType.image,
                  label: Text('Image'),
                  icon: Icon(Icons.image_outlined),
                ),
                ButtonSegment(
                  value: PostType.gallery,
                  label: Text('Gallery'),
                  icon: Icon(Icons.grid_on_outlined),
                ),
                ButtonSegment(
                  value: PostType.idea,
                  label: Text('Idea'),
                  icon: Icon(Icons.lightbulb_outline),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (s) {
                setState(() {
                  _type = s.first;
                  if (_type == PostType.idea) _images.clear();
                  if (_type == PostType.image && _images.length > 1) {
                    _images
                      ..retainWhere((element) => element == _images.first)
                      ..removeRange(1, _images.length);
                  }
                });
              },
            ),

            const SizedBox(height: 16),
            TextField(
              controller: _captionCtrl,
              decoration: const InputDecoration(
                labelText: 'Caption',
                hintText: 'Say something about your post…',
              ),
              maxLength: 2200,
              maxLines: null,
            ),

            const SizedBox(height: 16),
            _chipsInput(
              label: 'Skills',
              controller: _skillCtrl,
              values: _skills,
              suggestions: const [
                'OilPainting',
                'Sketching',
                'Watercolor',
                'Portrait',
                'Landscape',
                'DigitalArt',
                'Sculpture',
                'Photography',
              ],
            ),

            const SizedBox(height: 12),
            _chipsInput(
              label: 'Tags',
              controller: _tagCtrl,
              values: _tags,
              prefix: '#',
            ),

            const SizedBox(height: 16),
            // Visibility + location
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<PostVisibility>(
                    initialValue: _visibility,
                    items: PostVisibility.values
                        .map(
                          (v) => DropdownMenuItem(
                            value: v,
                            child: Text(_visibilityLabel(v)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _visibility = v!),
                    decoration: const InputDecoration(labelText: 'Visibility'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    readOnly: true,
                    onTap: _editLocation,
                    decoration: InputDecoration(
                      labelText: 'Location (optional)',
                      hintText: 'Add location',
                      suffixIcon: IconButton(
                        tooltip: 'Edit',
                        onPressed: _editLocation,
                        icon: const Icon(Icons.place_outlined),
                      ),
                    ),
                    controller: TextEditingController(
                      text: _location == null
                          ? ''
                          : [
                              _location!.city,
                              _location!.state,
                              _location!.country,
                            ].where((e) => (e ?? '').isNotEmpty).join(', '),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _visibilityLabel(PostVisibility v) {
    switch (v) {
      case PostVisibility.public:
        return 'Public';
      case PostVisibility.private:
        return 'Private';
      case PostVisibility.sponsorsOnly:
        return 'Sponsors only';
      case PostVisibility.followersOnly:
        return 'Followers only';
    }
  }

  Widget _chipsInput({
    required String label,
    required TextEditingController controller,
    required List<String> values,
    List<String> suggestions = const [],
    String prefix = '',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final v in values)
              InputChip(
                label: Text('$prefix$v'),
                onDeleted: () => setState(() => values.remove(v)),
              ),
            SizedBox(
              width: 200,
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Add ${label.toLowerCase()}…',
                ),
                onSubmitted: (val) {
                  final t = val.trim();
                  if (t.isEmpty) return;
                  setState(
                    () => values.add(prefix == '#' ? t.replaceAll('#', '') : t),
                  );
                  controller.clear();
                },
              ),
            ),
          ],
        ),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: suggestions.take(8).map((s) {
              final isSelected = values.contains(s);
              return ChoiceChip(
                label: Text(s),
                selected: isSelected,
                onSelected: (_) {
                  setState(() {
                    if (isSelected) {
                      values.remove(s);
                    } else {
                      values.add(s);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildUploadingOverlay() {
    return Container(
      color: Colors.black45,
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircularProgressIndicator.adaptive(),
                    const SizedBox(width: 16),
                    Text(_uploadStatus ?? 'Uploading…'),
                  ],
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(value: _progress),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
