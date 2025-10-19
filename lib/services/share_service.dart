import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import '../models/post.dart';
import '../models/user.dart';
import 'firestore_image_service.dart';

class ShareService {
  // Private constructor
  ShareService._();
  
  // Singleton instance
  static final ShareService _instance = ShareService._();
  static ShareService get instance => _instance;
  
  // Image service for handling Firestore images
  final FirestoreImageService _imageService = FirestoreImageService();

  /// Share a post with its content and image
  Future<void> sharePost(Post post, {User? author}) async {
    try {
      final String username = author?.username ?? 'Unknown Artist';
      final String content = _buildPostShareContent(post, username);
      
      // Try to download and share with image if available
      if (post.mediaUrl != null && post.mediaUrl!.isNotEmpty) {
        try {
          final imageFile = await _downloadImageForSharing(post.mediaUrl!);
          if (imageFile != null) {
            await Share.shareXFiles(
              [XFile(imageFile.path)],
              text: content,
              subject: '🎨 Amazing artwork by $username',
            );
            // Clean up the temporary file
            await imageFile.delete();
            return;
          }
        } catch (e) {
          // If image download fails, fall back to text-only sharing
          debugPrint('Failed to download image for sharing: $e');
        }
      } else if (post.mediaUrls != null && post.mediaUrls!.isNotEmpty) {
        // For gallery posts, share multiple images if available
        try {
          final List<XFile> imageFiles = [];
          final List<File> tempFiles = [];
          
          // Try to download up to 3 images for gallery posts
          for (int i = 0; i < post.mediaUrls!.length && i < 3; i++) {
            final imageFile = await _downloadImageForSharing(post.mediaUrls![i]);
            if (imageFile != null) {
              imageFiles.add(XFile(imageFile.path));
              tempFiles.add(imageFile);
            }
          }
          
          if (imageFiles.isNotEmpty) {
            await Share.shareXFiles(
              imageFiles,
              text: content,
              subject: '🎨 Amazing artwork gallery by $username',
            );
            // Clean up temporary files
            for (final file in tempFiles) {
              await file.delete();
            }
            return;
          }
        } catch (e) {
          // If image download fails, fall back to text-only sharing
          debugPrint('Failed to download gallery images for sharing: $e');
        }
      }
      
      // Fall back to text-only sharing
      await Share.share(
        content,
        subject: 'Check out this amazing artwork on ArtFolio!',
      );
    } catch (e) {
      throw Exception('Failed to share post: $e');
    }
  }

  /// Share a user profile with profile image
  Future<void> shareProfile(User user) async {
    try {
      final String content = _buildProfileShareContent(user);
      
      // Try to download and share with profile image if available
      if (user.profilePictureUrl.isNotEmpty) {
        try {
          final imageFile = await _downloadImageForSharing(user.profilePictureUrl);
          if (imageFile != null) {
            await Share.shareXFiles(
              [XFile(imageFile.path)],
              text: content,
              subject: 'Check out ${user.username} on ArtFolio!',
            );
            // Clean up the temporary file
            await imageFile.delete();
            return;
          }
        } catch (e) {
          // If image download fails, fall back to text-only sharing
          debugPrint('Failed to download profile image for sharing: $e');
        }
      }
      
      // Fall back to text-only sharing
      await Share.share(
        content,
        subject: 'Check out ${user.username} on ArtFolio!',
      );
    } catch (e) {
      throw Exception('Failed to share profile: $e');
    }
  }

  /// Share app with referral
  Future<void> shareApp({String? referralCode}) async {
    try {
      final String content = _buildAppShareContent(referralCode);
      
      await Share.share(
        content,
        subject: 'Join me on ArtFolio - The Creative Network!',
      );
    } catch (e) {
      throw Exception('Failed to share app: $e');
    }
  }

  /// Share with custom content
  Future<void> shareCustom({
    required String text,
    String? subject,
  }) async {
    try {
      await Share.share(text, subject: subject);
    } catch (e) {
      throw Exception('Failed to share: $e');
    }
  }

  /// Build content string for sharing a post
  String _buildPostShareContent(Post post, String username) {
    final buffer = StringBuffer()
      ..writeln('🎨 Amazing artwork by @$username');
    
    if (post.caption.isNotEmpty) {
      // Limit caption length for sharing - shorter for better readability
      final caption = post.caption.length > 150 
          ? '${post.caption.substring(0, 150)}...' 
          : post.caption;
      buffer
        ..writeln()
        ..writeln(caption);
    }

    // Add skills/tags on same line to save space
    if (post.skills.isNotEmpty || post.tags.isNotEmpty) {
      buffer.writeln();
      if (post.skills.isNotEmpty) {
        buffer.write('Skills: ${post.skills.take(2).join(', ')}');
      }
      if (post.tags.isNotEmpty) {
        final tags = post.tags.take(3).map((tag) => tag.startsWith('#') ? tag : '#$tag').join(' ');
        buffer.write(' $tags');
      }
    }

    buffer
      ..writeln()
      ..writeln()
      ..writeln('Discover more amazing artists on ArtFolio!'); // Removed app store link since you don't have one
    
    return buffer.toString();
  }

  /// Build content string for sharing a profile
  String _buildProfileShareContent(User user) {
    final buffer = StringBuffer()
      ..writeln('👨‍🎨 Check out @${user.username}\'s profile!');
    
    if (user.bio.isNotEmpty) {
      final bio = user.bio.length > 120 
          ? '${user.bio.substring(0, 120)}...' 
          : user.bio;
      buffer
        ..writeln()
        ..writeln(bio);
    }

    // Add role information
    buffer
      ..writeln()
      ..writeln('${_formatRole(user.role)} on ArtFolio');

    buffer
      ..writeln()
      ..writeln('Connect with amazing artists on ArtFolio!');
    
    return buffer.toString();
  }

  /// Build content string for sharing the app
  String _buildAppShareContent(String? referralCode) {
    final buffer = StringBuffer()
      ..writeln('🎨 Join me on ArtFolio - The Creative Network!')
      ..writeln()
      ..writeln('Where artists, students, sponsors, and art enthusiasts connect:')
      ..writeln('• Showcase amazing artwork')
      ..writeln('• Connect with fellow creatives')
      ..writeln('• Discover new talent')
      ..writeln('• Share artistic journeys');
    
    if (referralCode != null) {
      buffer
        ..writeln()
        ..writeln('Use my referral code: $referralCode');
    }
    
    buffer
      ..writeln()
      ..writeln('Download ArtFolio today!');
    
    return buffer.toString();
  }

  /// Format user role for display
  String _formatRole(UserRole role) {
    switch (role) {
      case UserRole.artist:
        return 'Artist';
      case UserRole.audience:
        return 'Art Enthusiast';
      case UserRole.sponsor:
        return 'Sponsor';
      case UserRole.organisation:
        return 'Organization';
    }
  }

  /// Download image from URL for sharing
  Future<File?> _downloadImageForSharing(String imageUrl) async {
    try {
      // Handle Firestore image IDs (if it doesn't look like a URL)
      if (!imageUrl.startsWith('http')) {
        try {
          final base64Data = await _imageService.getImageData(imageUrl);
          final imageBytes = base64Decode(base64Data);
          final tempDir = await getTemporaryDirectory();
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final fileName = 'artfolio_share_$timestamp.jpg';
          final file = File('${tempDir.path}/$fileName');
          await file.writeAsBytes(imageBytes);
          return file;
        } catch (e) {
          debugPrint('Error loading Firestore image for sharing: $e');
          return null;
        }
      }
      
      // Handle regular URLs including Firebase Storage URLs
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        // Determine file extension from URL or Content-Type
        String extension = '.jpg';
        final contentType = response.headers['content-type'];
        if (contentType != null) {
          if (contentType.contains('png')) extension = '.png';
          else if (contentType.contains('gif')) extension = '.gif';
          else if (contentType.contains('webp')) extension = '.webp';
        } else if (imageUrl.contains('.png')) {
          extension = '.png';
        } else if (imageUrl.contains('.gif')) {
          extension = '.gif';
        } else if (imageUrl.contains('.webp')) {
          extension = '.webp';
        }
        
        final fileName = 'artfolio_share_$timestamp$extension';
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);
        return file;
      }
    } catch (e) {
      debugPrint('Error downloading image for sharing: $e');
    }
    return null;
  }
}
