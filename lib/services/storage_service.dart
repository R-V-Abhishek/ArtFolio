import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Ensure user is authenticated (anonymously if needed)
  Future<void> _ensureAuthenticated() async {
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
  }

  // Upload image and return download URL
  Future<String> uploadImage({
    required String fileName,
    required String folder,
    File? file,
    Uint8List? data,
  }) async {
    try {
      // Ensure user is authenticated
      await _ensureAuthenticated();

      // Validate input
      if (file == null && data == null) {
        throw Exception('Either file or data must be provided');
      }

      // Create reference with timestamp to avoid conflicts
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(fileName).toLowerCase();
      final uniqueFileName = '${timestamp}_$fileName';
      final ref = _storage.ref().child('$folder/$uniqueFileName');

      // Upload the file
      UploadTask uploadTask;
      if (file != null) {
        uploadTask = ref.putFile(
          file,
          SettableMetadata(
            contentType: _getContentType(extension),
            customMetadata: {'uploadedAt': DateTime.now().toIso8601String()},
          ),
        );
      } else {
        uploadTask = ref.putData(
          data!,
          SettableMetadata(
            contentType: _getContentType(extension),
            customMetadata: {'uploadedAt': DateTime.now().toIso8601String()},
          ),
        );
      }

      // Wait for upload to complete
      final snapshot = await uploadTask;

      // Get download URL
      final downloadURL = await snapshot.ref.getDownloadURL();
      return downloadURL;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Upload profile image
  Future<String> uploadProfileImage({
    required String userId,
    required String fileName,
    File? file,
    Uint8List? data,
  }) async {
    return uploadImage(
      fileName: fileName,
      folder: 'profiles/$userId',
      file: file,
      data: data,
    );
  }

  // Upload post image
  Future<String> uploadPostImage({
    required String postId,
    required String fileName,
    File? file,
    Uint8List? data,
  }) async {
    return uploadImage(
      fileName: fileName,
      folder: 'posts/$postId',
      file: file,
      data: data,
    );
  }

  // Upload artwork image
  Future<String> uploadArtworkImage({
    required String artistId,
    required String artworkId,
    required String fileName,
    File? file,
    Uint8List? data,
  }) async {
    return uploadImage(
      fileName: fileName,
      folder: 'artworks/$artistId/$artworkId',
      file: file,
      data: data,
    );
  }

  // Delete image by URL
  Future<void> deleteImage(String downloadURL) async {
    try {
      final ref = _storage.refFromURL(downloadURL);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }

  // Delete all images in a folder
  Future<void> deleteFolder(String folderPath) async {
    try {
      final ref = _storage.ref().child(folderPath);
      final listResult = await ref.listAll();

      // Delete all files in the folder
      for (final item in listResult.items) {
        await item.delete();
      }

      // Recursively delete subfolders
      for (final prefix in listResult.prefixes) {
        await deleteFolder(prefix.fullPath);
      }
    } catch (e) {
      throw Exception('Failed to delete folder: $e');
    }
  }

  // Get image metadata
  Future<FullMetadata> getImageMetadata(String downloadURL) async {
    try {
      final ref = _storage.refFromURL(downloadURL);
      return await ref.getMetadata();
    } catch (e) {
      throw Exception('Failed to get image metadata: $e');
    }
  }

  // List all images in a folder
  Future<List<String>> listImagesInFolder(String folderPath) async {
    try {
      final ref = _storage.ref().child(folderPath);
      final listResult = await ref.listAll();

      final urls = <String>[];
      for (final item in listResult.items) {
        final url = await item.getDownloadURL();
        urls.add(url);
      }

      return urls;
    } catch (e) {
      throw Exception('Failed to list images in folder: $e');
    }
  }

  // Helper method to determine content type
  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.bmp':
        return 'image/bmp';
      case '.svg':
        return 'image/svg+xml';
      default:
        return 'image/jpeg'; // Default fallback
    }
  }

  // Upload with progress tracking
  Stream<double> uploadImageWithProgress({
    required String fileName,
    required String folder,
    File? file,
    Uint8List? data,
  }) {
    if (file == null && data == null) {
      throw Exception('Either file or data must be provided');
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = path.extension(fileName).toLowerCase();
    final uniqueFileName = '${timestamp}_$fileName';
    final ref = _storage.ref().child('$folder/$uniqueFileName');

    UploadTask uploadTask;
    if (file != null) {
      uploadTask = ref.putFile(
        file,
        SettableMetadata(contentType: _getContentType(extension)),
      );
    } else {
      uploadTask = ref.putData(
        data!,
        SettableMetadata(contentType: _getContentType(extension)),
      );
    }

    return uploadTask.snapshotEvents.map((snapshot) {
      return snapshot.bytesTransferred / snapshot.totalBytes;
    });
  }
}
