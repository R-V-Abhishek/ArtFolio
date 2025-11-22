import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/firestore_image_service.dart';

class FirestoreImage extends StatefulWidget {
  const FirestoreImage({
    super.key,
    required this.imageId,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });
  final String imageId;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  @override
  State<FirestoreImage> createState() => _FirestoreImageState();
}

class _FirestoreImageState extends State<FirestoreImage> {
  final FirestoreImageService _imageService = FirestoreImageService();
  Uint8List? _imageData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant FirestoreImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageId != widget.imageId) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final base64Data = await _imageService.getImageData(widget.imageId);
      final imageData = _imageService.base64ToUint8List(base64Data);

      if (mounted) {
        setState(() {
          _imageData = imageData;
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
      return widget.placeholder ??
          Container(
            width: widget.width,
            height: widget.height,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Center(child: CircularProgressIndicator()),
          );
    }

    if (_error != null || _imageData == null) {
      return widget.errorWidget ??
          Container(
            width: widget.width,
            height: widget.height,
            color: Colors.red.shade100,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, color: Colors.red),
                  Text('Failed to load image'),
                ],
              ),
            ),
          );
    }

    return Image.memory(
      _imageData!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      errorBuilder: (context, error, stackTrace) =>
          widget.errorWidget ??
          Container(
            width: widget.width,
            height: widget.height,
            color: Colors.red.shade100,
            child: const Center(child: Icon(Icons.error, color: Colors.red)),
          ),
    );
  }
}

// Helper widget for displaying base64 images directly
class Base64Image extends StatelessWidget {
  const Base64Image({
    super.key,
    required this.base64Data,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });
  final String base64Data;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    try {
      final imageData = base64Decode(base64Data);
      return Image.memory(imageData, width: width, height: height, fit: fit);
    } catch (e) {
      return Container(
        width: width,
        height: height,
        color: Colors.red.shade100,
        child: const Center(child: Icon(Icons.error, color: Colors.red)),
      );
    }
  }
}
