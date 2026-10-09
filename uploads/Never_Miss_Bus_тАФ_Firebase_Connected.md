# Never Miss Bus — Firebase Connected

## Completed setup

The Flutter project is connected to the new Firebase project **Never Miss Bus**.

| Item | Value |
|---|---|
| Firebase project ID | `never-miss-bus-c67b5` |
| Android package | `com.example.never_miss_bus` |
| Android Firebase config | `android/app/google-services.json` |
| Android Dart Firebase options | `lib/firebase_options.dart` |
| Firestore | Created and deployed with project rules and indexes |
| Realtime Database | Created in `asia-southeast1` and deployed with project rules |
| Firebase console | https://console.firebase.google.com/project/never-miss-bus-c67b5/overview |

## Free-tier configuration

The project remains on the minimal free setup. Google Analytics and Gemini in Firebase were not enabled. OpenStreetMap remains in use, so no Google Maps API key or billing card is required. Cloud Functions were not deployed because the project documentation specifies the free-mode path without Functions.

## Important remaining work

The current Firebase app registration is Android-only. iOS must be registered separately in Firebase before an iOS build can use Firebase. The iOS app should then receive `GoogleService-Info.plist`, and `lib/firebase_options.dart` should be regenerated or extended for iOS.

The uploaded release APK cannot be patched in place. Build a new signed APK from this configured Flutter source project. Before production release, enable the required Firebase Authentication providers in the Firebase Console and follow `firebase/FIRST_ADMIN_FREE_MODE.md` to create the first administrator.

## Build commands

From the Flutter project root:

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

The generated APK will normally be under `build/app/outputs/flutter-apk/`.

## Deployment commands

The Firebase CLI project mapping is in `firebase/.firebaserc`. From the `firebase/` directory:

```bash
firebase deploy --only firestore:rules,firestore:indexes,database
```

These deployments have already been completed for project `never-miss-bus-c67b5`.
