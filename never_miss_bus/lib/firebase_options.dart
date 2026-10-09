// Generated for Firebase project: never-miss-bus-c67b5
// (equivalent of `flutterfire configure` output, built from the app's
// registered google-services.json)
//
// NOTE: These values are PUBLIC app identifiers, not secrets. Real access
// control lives in Firestore/RTDB security rules, which are already
// deployed to this project.
//
// Platforms configured: Android.
// iOS requires registering an iOS app in Firebase Console first
// (see docs/SETUP.md) — until then iOS builds will throw below.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'iOS app is not registered in Firebase yet. '
          'Register an iOS app for project never-miss-bus-c67b5 and '
          'regenerate firebase_options.dart (see docs/SETUP.md).',
        );
      default:
        throw UnsupportedError(
          'Never Miss Bus targets Android and iOS only.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAiwEpyTqaAaNu87ytlKwMdF844PFL_cFE',
    appId: '1:642048321838:android:061125110463d63bf5f2bf',
    messagingSenderId: '642048321838',
    projectId: 'never-miss-bus-c67b5',
    storageBucket: 'never-miss-bus-c67b5.firebasestorage.app',
    // Realtime Database is in asia-southeast1 (Singapore), so the regional
    // URL must be set explicitly — the default (us-central1) would fail.
    databaseURL:
        'https://never-miss-bus-c67b5-default-rtdb.asia-southeast1.firebasedatabase.app',
  );
}
