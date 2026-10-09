# Never Miss Bus — Configuration & Deployment Checklist

Everything that **must be configured with real credentials** before the app
runs. No keys or secrets ship in this repository by design.

---

## 1. Prerequisites

| Tool | Version |
|---|---|
| Flutter SDK | 3.24.x stable (project verified against 3.24.5) |
| Node.js | 20.x (Cloud Functions) |
| Firebase CLI | `npm i -g firebase-tools` |
| FlutterFire CLI | `dart pub global activate flutterfire_cli` |
| Xcode (iOS builds) | 15+ on macOS |
| Android Studio / SDK | API 34, minSdk is 23 |

## 2. Firebase project

1. Create a project at https://console.firebase.google.com (e.g.
   `never-miss-bus-srbs`). **Blaze plan is required** for Cloud Functions.
2. Enable products:
   - **Authentication** → Sign-in method → Email/Password.
   - **Cloud Firestore** (production mode; pick an India region e.g.
     `asia-south1`).
   - **Realtime Database** (same region family, locked mode).
   - **Cloud Messaging** (on by default).
3. Connect the Flutter app:
   ```bash
   cd never_miss_bus
   flutterfire configure --project=<your-project-id>
   ```
   This **overwrites the placeholder `lib/firebase_options.dart`** and writes
   `android/app/google-services.json` + `ios/Runner/GoogleService-Info.plist`.
4. Uncomment the Google Services Gradle plugin:
   - `android/app/build.gradle` → uncomment `id "com.google.gms.google-services"`.
   - Add to `android/settings.gradle` plugins block:
     `id "com.google.gms.google-services" version "4.4.2" apply false`.

## 3. Deploy the backend (rules + functions + indexes)

```bash
cd firebase
firebase login
firebase use <your-project-id>
cd functions && npm install && npm run build && cd ..
firebase deploy --only firestore:rules,firestore:indexes,database,functions
```

> The security rules are the real access control. **Do not launch without
> deploying them** — a fresh Firestore in test mode is world-readable.

## 4. Bootstrap the FIRST admin account (one-time)

`provisionUser` requires an admin caller, so the first admin is created
manually with the Admin SDK (run locally with a service-account, or in
Cloud Shell):

```js
// bootstrap-admin.js  (node bootstrap-admin.js)
const admin = require("firebase-admin");
admin.initializeApp(); // GOOGLE_APPLICATION_CREDENTIALS env var must point
                       // to a service-account key you keep OFFLINE.
(async () => {
  const u = await admin.auth().createUser({
    email: "transport-admin@srbs.edu.in",
    password: "<choose-a-strong-one-time-password>",
  });
  await admin.auth().setCustomUserClaims(u.uid, { role: "admin", active: true });
  await admin.firestore().doc(`users/${u.uid}`).set({
    role: "admin", fullName: "Transport Admin",
    email: "transport-admin@srbs.edu.in", isActive: true,
    fcmTokens: {}, settings: {},
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  console.log("Admin created:", u.uid);
})();
```
Delete the script and rotate the password after first login. Every further
account (students, drivers, more admins) is created **inside the app** by
this admin.

## 5. Google Maps keys

Create **two separate, restricted** API keys in Google Cloud Console
(the Firebase project is also a GCP project):

- **Maps SDK for Android** key, restricted to package
  `com.srbs.never_miss_bus` + your signing SHA-1.
  Put it in `android/local.properties` (git-ignored):
  ```
  MAPS_API_KEY=AIza...
  ```
- **Maps SDK for iOS** key, restricted to your iOS bundle id.
  Create `ios/Runner/Secrets.plist` (git-ignored):
  ```xml
  <?xml version="1.0" encoding="UTF-8"?>
  <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
    "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
  <plist version="1.0"><dict>
    <key>MAPS_API_KEY</key><string>AIza...</string>
  </dict></plist>
  ```
  and add it to the Runner target in Xcode (member of target, not copied to
  a public location).

## 6. iOS push notifications (APNs)

1. Apple Developer account → Keys → create an **APNs Auth Key** (.p8).
2. Firebase Console → Project settings → Cloud Messaging → iOS app →
   upload the .p8 with Key ID + Team ID.
3. In Xcode: Runner target → Signing & Capabilities → add
   **Push Notifications** and **Background Modes** (Location updates +
   Remote notifications are already declared in Info.plist).

## 7. Android release signing

```bash
keytool -genkey -v -keystore ~/nmb-release.jks -keyalg RSA \
        -keysize 2048 -validity 10000 -alias nmb
```
Create `android/key.properties` (git-ignored), wire a `signingConfigs.release`
block, and switch `buildTypes.release.signingConfig` to it before publishing.

## 8. Run & build

```bash
flutter pub get
flutter run                         # debug on device/emulator
flutter build appbundle --release   # Android (Play Console)
flutter build ipa --release         # iOS (App Store Connect / TestFlight)
```

## 9. Seed the transport structure (in the admin app)

1. Sign in as admin → **Buses** → add Bus 1, Bus 2, Bus 3…
2. **Routes & Stops** → pick each bus → add its ordered stops
   (name + lat/lng + scheduled time).
3. **Admin Settings** → fill the school profile incl. school lat/lng.
4. **Drivers** → add driver accounts → assigned bus.
5. **Students** → add student accounts → assigned bus + stop.
6. Driver signs in on their phone → grants location permission →
   **Start Trip** → students see the bus live.

## 10. What intentionally does NOT work until configured

| Symptom | Missing configuration |
|---|---|
| App shows "Firebase is not configured" | `flutterfire configure` not run |
| Map is blank / watermark | Maps API key(s) missing (steps 5) |
| "Admin access required" on user creation | Functions not deployed, or caller lacks admin claim |
| No push notifications on iOS | APNs key not uploaded (step 6) |
| Queries fail with permission-denied | Rules/indexes not deployed (step 3) |
