import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class ImageGalleryScreen extends StatefulWidget {
  const ImageGalleryScreen({super.key});

  @override
  State<ImageGalleryScreen> createState() => _ImageGalleryScreenState();
}

class _ImageGalleryScreenState extends State<ImageGalleryScreen> {
  final _picker = ImagePicker();
  final List<File> _images = [];
  AspectRatioOption _ratio = AspectRatioOption.original;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Gallery Builder'),
      actions: [
        IconButton(
          tooltip: 'Add images',
          onPressed: _pickImages,
          icon: const Icon(Icons.add_photo_alternate_outlined),
        ),
        PopupMenuButton<AspectRatioOption>(
          tooltip: 'Aspect ratio',
          initialValue: _ratio,
          onSelected: (r) => setState(() => _ratio = r),
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: AspectRatioOption.original,
              child: Text('Original'),
            ),
            PopupMenuItem(
              value: AspectRatioOption.square,
              child: Text('1:1 Square'),
            ),
            PopupMenuItem(
              value: AspectRatioOption.r4_5,
              child: Text('4:5 Portrait'),
            ),
            PopupMenuItem(
              value: AspectRatioOption.r16_9,
              child: Text('16:9 Landscape'),
            ),
          ],
          icon: const Icon(Icons.crop_rounded),
        ),
      ],
    ),
    body: _images.isEmpty
        ? _empty()
        : ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
            itemCount: _images.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex--;
                final item = _images.removeAt(oldIndex);
                _images.insert(newIndex, item);
              });
            },
            itemBuilder: (context, index) {
              final file = _images[index];
              return Card(
                key: ValueKey(file.path),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    AspectRatio(
                      aspectRatio: _ratio.value,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(file, fit: BoxFit.cover),
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Row(
                              children: [
                                IconButton.filledTonal(
                                  tooltip: 'Crop',
                                  onPressed: () => _cropAt(index),
                                  icon: const Icon(Icons.crop),
                                ),
                                const SizedBox(width: 6),
                                IconButton.filled(
                                  tooltip: 'Remove',
                                  onPressed: () => _removeAt(index),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.drag_indicator),
                      title: Text(_fileName(file.path)),
                      subtitle: Text('${file.lengthSync()} bytes'),
                    ),
                  ],
                ),
              );
            },
          ),
    bottomNavigationBar: _images.isEmpty
        ? null
        : SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: FilledButton.icon(
                onPressed: () => Navigator.pop(context, _images),
                icon: const Icon(Icons.check),
                label: Text(
                  'Use ${_images.length} image${_images.length == 1 ? '' : 's'}',
                ),
              ),
            ),
          ),
    floatingActionButton: _images.isEmpty
        ? FloatingActionButton.extended(
            onPressed: _pickImages,
            icon: const Icon(Icons.collections),
            label: const Text('Pick images'),
          )
        : null,
  );

  Widget _empty() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.collections_outlined,
          size: 64,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 12),
        const Text('Build a gallery by selecting multiple images'),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _pickImages,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: const Text('Select from gallery'),
        ),
      ],
    ),
  );

  Future<void> _pickImages() async {
    final xs = await _picker.pickMultiImage(imageQuality: 90, maxWidth: 2000);
    if (xs.isEmpty) return;
    setState(() {
      _images.addAll(xs.map((x) => File(x.path)));
    });
  }

  Future<void> _cropAt(int index) async {
    final file = _images[index];
    final ratio = _ratio.cropperRatio;
    final result = await ImageCropper().cropImage(
      sourcePath: file.path,
      aspectRatio: ratio,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop',
          toolbarColor: Theme.of(context).colorScheme.surface,
          toolbarWidgetColor: Theme.of(context).colorScheme.onSurface,
          activeControlsWidgetColor: Theme.of(context).colorScheme.primary,
          initAspectRatio: ratio != null
              ? CropAspectRatioPreset.original
              : CropAspectRatioPreset.original,
          lockAspectRatio: ratio != null,
        ),
        IOSUiSettings(title: 'Crop'),
      ],
    );
    if (result == null) return;
    setState(() {
      _images[index] = File(result.path);
    });
  }

  void _removeAt(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  String _fileName(String path) => path.split('/').last.split(r'\').last;
}

enum AspectRatioOption { original, square, r4_5, r16_9 }

extension on AspectRatioOption {
  double get value {
    switch (this) {
      case AspectRatioOption.original:
        return 1; // Display only; real original varies per image
      case AspectRatioOption.square:
        return 1;
      case AspectRatioOption.r4_5:
        return 4 / 5;
      case AspectRatioOption.r16_9:
        return 16 / 9;
    }
  }

  CropAspectRatio? get cropperRatio {
    switch (this) {
      case AspectRatioOption.original:
        return null; // free/original
      case AspectRatioOption.square:
        return const CropAspectRatio(ratioX: 1, ratioY: 1);
      case AspectRatioOption.r4_5:
        return const CropAspectRatio(ratioX: 4, ratioY: 5);
      case AspectRatioOption.r16_9:
        return const CropAspectRatio(ratioX: 16, ratioY: 9);
    }
  }
}
