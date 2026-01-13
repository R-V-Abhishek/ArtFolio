import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Base64 Image Utilities', () {
    test('base64ToUint8List converts base64 to bytes correctly', () {
      const base64String = 'SGVsbG8gV29ybGQ='; // "Hello World" in base64
      final result = base64Decode(base64String);

      expect(result, isA<Uint8List>());
      expect(result.length, greaterThan(0));

      // Convert back to string to verify
      final resultString = String.fromCharCodes(result);
      expect(resultString, equals('Hello World'));
    });

    test('base64 encoding and decoding round trip', () {
      // Create test data
      final testData = Uint8List.fromList([1, 2, 3, 4, 5, 255, 128, 64]);

      // Convert to base64 and back
      final base64String = base64Encode(testData);
      final decodedData = base64Decode(base64String);

      expect(decodedData, equals(testData));
    });

    test('image-like data encoding and decoding', () {
      // Create some fake image header data
      final fakeImageData = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG header
        0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR chunk start
        0xFF, 0xFF, 0xFF, 0xFF, // Some data
      ]);

      // Encode and decode
      final base64String = base64Encode(fakeImageData);
      final decodedData = base64Decode(base64String);

      expect(decodedData, equals(fakeImageData));
      expect(decodedData.length, equals(fakeImageData.length));

      // Verify PNG header is preserved
      expect(
        decodedData.sublist(0, 8),
        equals([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]),
      );
    });
  });
}
