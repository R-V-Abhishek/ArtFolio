import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

class FirestoreImageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Upload image to Firestore as base64 and return document ID
  Future<String> uploadImage({
    required String fileName,
    required String folder,
    required String userId, // Add userId parameter for Firestore rules
    File? file,
    Uint8List? data,
  }) async {
    try {
      if (file == null && data == null) {
        throw Exception('Either file or data must be provided');
      }

      String base64Image;
      if (file != null) {
        final bytes = await file.readAsBytes();
        base64Image = base64Encode(bytes);
      } else {
        base64Image = base64Encode(data!);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(fileName).toLowerCase();
      final uniqueFileName = '${timestamp}_$fileName';

      final docRef = await _firestore.collection('images').add({
        'userId': userId, // Include userId for Firestore security rules
        'fileName': uniqueFileName,
        'folder': folder,
        'base64Data': base64Image,
        'contentType': _getContentType(extension),
        'uploadedAt': FieldValue.serverTimestamp(),
        'size': base64Image.length,
      });

      debugPrint('✅ Image uploaded to Firestore: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Get image base64 data by document ID
  Future<String> getImageData(String imageId) async {
    try {
      final doc = await _firestore.collection('images').doc(imageId).get();
      if (!doc.exists) {
        throw Exception('Image not found');
      }

      final data = doc.data()!;
      return data['base64Data'] as String;
    } catch (e) {
      throw Exception('Failed to get image: $e');
    }
  }

  // Delete image by document ID
  Future<void> deleteImage(String imageId) async {
    try {
      await _firestore.collection('images').doc(imageId).delete();
      debugPrint('✅ Image deleted from Firestore: $imageId');
    } catch (e) {
      throw Exception('Failed to delete image: $e');
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
      default:
        return 'image/jpeg';
    }
  }

  // Upload with progress simulation
  Stream<double> uploadImageWithProgress({
    required String fileName,
    required String folder,
    required String userId, // Add userId parameter
    File? file,
    Uint8List? data,
  }) async* {
    for (var i = 0; i <= 100; i += 20) {
      yield i / 100.0;
      await Future.delayed(const Duration(milliseconds: 100));
    }

    await uploadImage(
      fileName: fileName,
      folder: folder,
      userId: userId, // Pass userId to uploadImage
      file: file,
      data: data,
    );

    yield 1.0;
  }

  // Convert base64 to Uint8List for display
  Uint8List base64ToUint8List(String base64String) =>
      base64Decode(base64String);
}
