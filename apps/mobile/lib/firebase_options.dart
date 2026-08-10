// DefaultFirebaseOptions stub configuration for Flutter
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
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCq8KkBvYpG31As57gTF3toF5EYPyw30z0',
    appId: '1:594141034415:web:ac9ca9642b8dd58d1de15a',
    messagingSenderId: '594141034415',
    projectId: 'grahvani-1444a',
    authDomain: 'grahvani-1444a.firebaseapp.com',
    storageBucket: 'grahvani-1444a.firebasestorage.app',
    measurementId: 'G-MNF5MSV4PS',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD65PO6o81JXPfGQ9m0rKqpPBpYbtVnJwA',
    appId: '1:594141034415:android:a2c093ded1e910f21de15a',
    messagingSenderId: '594141034415',
    projectId: 'grahvani-1444a',
    storageBucket: 'grahvani-1444a.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDIHCa_ooaSFb8Wkf3WR-wnUNOVUq5oNFg',
    appId: '1:594141034415:ios:2374d64f1b54bc681de15a',
    messagingSenderId: '594141034415',
    projectId: 'grahvani-1444a',
    storageBucket: 'grahvani-1444a.firebasestorage.app',
    iosBundleId: 'com.grahvani.app',
  );
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'demo-api-key',
    appId: '1:1234567890:ios:1234567890',
    messagingSenderId: '1234567890',
    projectId: 'grahvani-demo',
    storageBucket: 'grahvani-demo.appspot.com',
    iosBundleId: 'com.grahvani.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCq8KkBvYpG31As57gTF3toF5EYPyw30z0',
    appId: '1:594141034415:web:e32ebdddedc4ea251de15a',
    messagingSenderId: '594141034415',
    projectId: 'grahvani-1444a',
    authDomain: 'grahvani-1444a.firebaseapp.com',
    storageBucket: 'grahvani-1444a.firebasestorage.app',
    measurementId: 'G-B46X9T64L5',
  );
}
