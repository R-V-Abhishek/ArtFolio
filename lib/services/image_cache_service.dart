import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Image caching service for better performance and offline support
class ImageCacheService {
  factory ImageCacheService() => _instance;
  ImageCacheService._internal();
  static final ImageCacheService _instance = ImageCacheService._internal();

  // In-memory cache for frequently accessed images
  final Map<String, Uint8List> _memoryCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  // Cache configuration
  static const int maxMemoryCacheSize =
      50; // Number of images to keep in memory
  static const Duration cacheExpiration = Duration(days: 7);
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB max file size

  Directory? _cacheDirectory;

  /// Initialize the cache service
  Future<void> initialize() async {
    try {
      // ignore: avoid_slow_async_io
      final appDir = await getApplicationDocumentsDirectory();
      _cacheDirectory = Directory(path.join(appDir.path, 'image_cache'));

      if (!await _cacheDirectory!.exists()) {
        // ignore: avoid_slow_async_io
        await _cacheDirectory!.create(recursive: true);
      }

      // Clean up expired cache on startup
      unawaited(_cleanupExpiredCache());
    } catch (e) {
      debugPrint('Failed to initialize image cache: $e');
    }
  }

  /// Get cached image or download and cache if not available
  Future<Uint8List?> getCachedImage(String imageUrl) async {
    try {
      final cacheKey = _getCacheKey(imageUrl);

      // Check memory cache first
      if (_memoryCache.containsKey(cacheKey)) {
        final timestamp = _cacheTimestamps[cacheKey];
        if (timestamp != null &&
            DateTime.now().difference(timestamp) < cacheExpiration) {
          return _memoryCache[cacheKey];
        } else {
          // Remove expired item from memory cache
          _memoryCache.remove(cacheKey);
          _cacheTimestamps.remove(cacheKey);
        }
      }

      // Check disk cache
      final cachedFile = await _getCachedFile(cacheKey);
      if (cachedFile != null && await cachedFile.exists()) {
        // ignore: avoid_slow_async_io
        final fileStats = await cachedFile.stat();
        if (DateTime.now().difference(fileStats.modified) < cacheExpiration) {
          // ignore: avoid_slow_async_io
          final imageData = await cachedFile.readAsBytes();
          _addToMemoryCache(cacheKey, imageData);
          return imageData;
        } else {
          // Delete expired cache file
          // ignore: avoid_slow_async_io
          await cachedFile.delete();
        }
      }

      // Download and cache the image
      return await _downloadAndCacheImage(imageUrl, cacheKey);
    } catch (e) {
      debugPrint('Failed to get cached image: $e');
      return null;
    }
  }

  /// Download image and save to cache
  Future<Uint8List?> _downloadAndCacheImage(
    String imageUrl,
    String cacheKey,
  ) async {
    try {
      final response = await http
          .get(
            Uri.parse(imageUrl),
            headers: {'User-Agent': 'ArtFolio/1.0', 'Accept': 'image/*'},
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final imageData = response.bodyBytes;

        // Check file size
        if (imageData.length > maxImageSize) {
          debugPrint('Image too large: ${imageData.length} bytes');
          return null;
        }

        // Validate image format
        if (!_isValidImageFormat(imageData)) {
          debugPrint('Invalid image format');
          return null;
        }

        // Save to disk cache
        await _saveToDiskCache(cacheKey, imageData);

        // Add to memory cache
        _addToMemoryCache(cacheKey, imageData);

        return imageData;
      } else {
        debugPrint('Failed to download image: HTTP ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error downloading image: $e');
      return null;
    }
  }

  /// Generate cache key from URL
  String _getCacheKey(String url) {
    final bytes = utf8.encode(url);
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  /// Get cached file reference
  Future<File?> _getCachedFile(String cacheKey) async {
    if (_cacheDirectory == null) return null;
    return File(path.join(_cacheDirectory!.path, '$cacheKey.cache'));
  }

  /// Save image data to disk cache
  Future<void> _saveToDiskCache(String cacheKey, Uint8List imageData) async {
    try {
      final file = await _getCachedFile(cacheKey);
      if (file != null) {
        await file.writeAsBytes(imageData);
      }
    } catch (e) {
      debugPrint('Failed to save to disk cache: $e');
    }
  }

  /// Add image to memory cache with size management
  void _addToMemoryCache(String cacheKey, Uint8List imageData) {
    // Remove oldest items if cache is full
    if (_memoryCache.length >= maxMemoryCacheSize) {
      final oldestKey = _cacheTimestamps.entries
          .reduce((a, b) => a.value.isBefore(b.value) ? a : b)
          .key;
      _memoryCache.remove(oldestKey);
      _cacheTimestamps.remove(oldestKey);
    }

    _memoryCache[cacheKey] = imageData;
    _cacheTimestamps[cacheKey] = DateTime.now();
  }

  /// Check if data represents a valid image format
  bool _isValidImageFormat(Uint8List data) {
    if (data.length < 4) return false;

    // Check for common image file signatures
    // JPEG
    if (data[0] == 0xFF && data[1] == 0xD8) return true;

    // PNG
    if (data[0] == 0x89 &&
        data[1] == 0x50 &&
        data[2] == 0x4E &&
        data[3] == 0x47) {
      return true;
    }

    // GIF
    if (data[0] == 0x47 && data[1] == 0x49 && data[2] == 0x46) return true;

    // WebP
    if (data.length >= 12 &&
        data[0] == 0x52 &&
        data[1] == 0x49 &&
        data[2] == 0x46 &&
        data[3] == 0x46 &&
        data[8] == 0x57 &&
        data[9] == 0x45 &&
        data[10] == 0x42 &&
        data[11] == 0x50) {
      return true;
    }

    return false;
  }

  /// Clean up expired cache files
  Future<void> _cleanupExpiredCache() async {
    try {
      if (_cacheDirectory == null || !await _cacheDirectory!.exists()) {
        return;
      }

      // ignore: avoid_slow_async_io
      final files = await _cacheDirectory!.list().toList();
      final now = DateTime.now();

      for (final file in files) {
        if (file is File) {
          // ignore: avoid_slow_async_io
          final stats = await file.stat();
          if (now.difference(stats.modified) > cacheExpiration) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to cleanup expired cache: $e');
    }
  }

  /// Clear all cached images
  Future<void> clearCache() async {
    try {
      // Clear memory cache
      _memoryCache.clear();
      _cacheTimestamps.clear();

      // Clear disk cache
      if (_cacheDirectory != null && await _cacheDirectory!.exists()) {
        // ignore: avoid_slow_async_io
        await _cacheDirectory!.delete(recursive: true);
        // ignore: avoid_slow_async_io
        await _cacheDirectory!.create(recursive: true);
      }
    } catch (e) {
      debugPrint('Failed to clear cache: $e');
    }
  }

  /// Get cache size information
  Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      var diskCacheSize = 0;
      var diskCacheCount = 0;

      if (_cacheDirectory != null && await _cacheDirectory!.exists()) {
        // ignore: avoid_slow_async_io
        final files = await _cacheDirectory!.list().toList();
        for (final file in files) {
          if (file is File) {
            // ignore: avoid_slow_async_io
            final stats = await file.stat();
            diskCacheSize += stats.size;
            diskCacheCount++;
          }
        }
      }

      var memoryCacheSize = 0;
      for (final imageData in _memoryCache.values) {
        memoryCacheSize += imageData.length;
      }

      return {
        'diskCacheSize': diskCacheSize,
        'diskCacheCount': diskCacheCount,
        'memoryCacheSize': memoryCacheSize,
        'memoryCacheCount': _memoryCache.length,
        'cacheDirectory': _cacheDirectory?.path,
      };
    } catch (e) {
      debugPrint('Failed to get cache info: $e');
      return {};
    }
  }

  /// Preload images for better UX
  Future<void> preloadImages(List<String> imageUrls) async {
    for (final url in imageUrls) {
      // Preload in background without blocking
      unawaited(
        getCachedImage(url).catchError((e) {
          debugPrint('Failed to preload image: $url, error: $e');
          return null;
        }),
      );
    }
  }
}

/// Custom image widget with caching support
class CachedNetworkImage extends StatefulWidget {
  const CachedNetworkImage({
    super.key,
    required this.imageUrl,
    this.placeholder,
    this.errorWidget,
    this.fit,
    this.width,
    this.height,
    this.borderRadius,
  });
  final String imageUrl;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  @override
  State<CachedNetworkImage> createState() => _CachedNetworkImageState();
}

class _CachedNetworkImageState extends State<CachedNetworkImage> {
  Uint8List? _imageData;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(CachedNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _imageData = null;
    });

    try {
      final imageData = await ImageCacheService().getCachedImage(
        widget.imageUrl,
      );

      if (mounted) {
        setState(() {
          _imageData = imageData;
          _isLoading = false;
          _hasError = imageData == null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (_isLoading) {
      child =
          widget.placeholder ??
          const Center(child: CircularProgressIndicator());
    } else if (_hasError || _imageData == null) {
      child =
          widget.errorWidget ??
          const Center(child: Icon(Icons.error_outline, color: Colors.grey));
    } else {
      child = Image.memory(
        _imageData!,
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
      );
    }

    if (widget.borderRadius != null) {
      child = ClipRRect(borderRadius: widget.borderRadius!, child: child);
    }

    return SizedBox(width: widget.width, height: widget.height, child: child);
  }
}
