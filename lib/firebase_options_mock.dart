// Mock Firebase options for CI/CD environments
// This file is used when the actual firebase_options.dart is not available

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'mock-api-key',
    appId: 'mock-app-id',
    messagingSenderId: 'mock-sender-id',
    projectId: 'mock-project-id',
    authDomain: 'mock-project.firebaseapp.com',
    storageBucket: 'mock-project.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'mock-android-api-key',
    appId: 'mock-android-app-id',
    messagingSenderId: 'mock-sender-id',
    projectId: 'mock-project-id',
    storageBucket: 'mock-project.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'mock-ios-api-key',
    appId: 'mock-ios-app-id',
    messagingSenderId: 'mock-sender-id',
    projectId: 'mock-project-id',
    storageBucket: 'mock-project.appspot.com',
    iosBundleId: 'com.example.mock',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'mock-macos-api-key',
    appId: 'mock-macos-app-id',
    messagingSenderId: 'mock-sender-id',
    projectId: 'mock-project-id',
    storageBucket: 'mock-project.appspot.com',
    iosBundleId: 'com.example.mock',
  );
}
