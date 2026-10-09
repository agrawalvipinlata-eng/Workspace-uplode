# 🔥 Firebase Setup — Step by Step (Hindi)

**Never Miss Bus ko live karne ka poora rasta.** Har step copy-paste ready
hai. Total time: ~45-60 minute (pehli baar).

> **Kya chahiye:** Google account, tumhara computer (Windows/Mac/Linux),
> internet. Firebase ka **Blaze plan** chahiye Cloud Functions ke liye —
> card add karna padta hai but chhote school ke liye bill usually ₹0 ke
> aas-paas hi rehta hai (free limits bahut bade hain).

---

## STEP 0 — Computer pe tools install karo (ek baar)

```bash
# 1. Flutter SDK (agar nahi hai): https://docs.flutter.dev/get-started/install
flutter --version        # 3.24+ hona chahiye

# 2. Node.js 20: https://nodejs.org (LTS download karo)
node --version           # v20.x

# 3. Firebase CLI
npm install -g firebase-tools
firebase login           # browser khulega → Google account se login

# 4. FlutterFire CLI
dart pub global activate flutterfire_cli
```

> **Windows note:** `dart pub global activate` ke baad agar `flutterfire`
> command nahi milti, toh PATH mein `%USERPROFILE%\AppData\Local\Pub\Cache\bin`
> add karo.

---

## STEP 1 — Firebase project banao (browser mein, ~5 min)

1. https://console.firebase.google.com kholo
2. **"Create a project"** → naam do: `never-miss-bus-srbs`
3. Google Analytics: **off** kar sakte ho (zaroori nahi)
4. Project ban jaane ke baad, left menu se yeh 4 cheezein enable karo:

| Kya | Kahan | Kaise |
|---|---|---|
| **Authentication** | Build → Authentication | "Get started" → Sign-in method → **Email/Password** → Enable |
| **Firestore** | Build → Firestore Database | "Create database" → **Production mode** → Location: **asia-south1 (Mumbai)** |
| **Realtime Database** | Build → Realtime Database | "Create database" → Location: **Singapore (asia-southeast1)** → **Locked mode** |
| **Blaze plan** | Left-bottom "Upgrade" | Blaze select karo (Functions ke liye zaroori) |

> ⚠️ **Production/Locked mode hi chuno** — "test mode" mat chunna, woh
> sabke liye khula hota hai. Hamare asli security rules Step 4 mein
> deploy honge.

---

## STEP 2 — App ko project se jodo (~5 min)

Project folder mein terminal kholo (`never_miss_bus/`):

```bash
flutterfire configure --project=never-miss-bus-srbs
```

- Platforms poocha jayega → **android** aur **ios** select karo (space se)
- Android package id confirm karo: `com.srbs.never_miss_bus`

**Yeh command 3 files banati hai (isse Firebase judd jaata hai):**
- `lib/firebase_options.dart` ← placeholder replace ho jayega ✅
- `android/app/google-services.json` ✅
- `ios/Runner/GoogleService-Info.plist` ✅

> Maine `android/app/build.gradle` aisa set kiya hai ki
> `google-services.json` aate hi Firebase **automatically enable** ho
> jayega — koi manual uncomment nahi karna. 👍

---

## STEP 3 — Backend deploy karo: Rules + Functions (~10 min)

```bash
cd firebase

# Project link karo
firebase use never-miss-bus-srbs

# Functions dependencies + build
cd functions
npm install
npm run build
cd ..

# SAB deploy karo: security rules + indexes + functions
firebase deploy --only firestore:rules,firestore:indexes,database,functions
```

> ⚠️ **Yeh step skip mat karna!** Security rules hi asli taala hain —
> inke bina database khula rehta hai. Deploy hone ke baad:
> - Student sirf apni bus dekh sakta hai
> - Driver sirf apni bus ki location bhej sakta hai
> - Admin-only cheezein sirf admin kar sakta hai

Agar `firebase deploy` mein region/permission error aaye toh ek baar
`firebase login --reauth` karke dobara try karo.

---

## STEP 4 — Pehla Admin account banao (ek baar, ~5 min)

Sabse pehla admin script se banta hai (kyunki app mein account banane ke
liye admin hona zaroori hai — chicken & egg 🐣):

1. **Service account key lo:**
   Firebase Console → ⚙️ Project settings → **Service accounts** →
   **"Generate new private key"** → `serviceAccountKey.json` download →
   `firebase/` folder mein rakho

2. **Script chalao:**
   ```bash
   cd firebase
   npm install firebase-admin

   # Mac/Linux:
   GOOGLE_APPLICATION_CREDENTIALS=./serviceAccountKey.json \
     node bootstrap-admin.js admin@srbs.edu.in "StrongPass@123" "Transport Admin"

   # Windows (PowerShell):
   $env:GOOGLE_APPLICATION_CREDENTIALS=".\serviceAccountKey.json"
   node bootstrap-admin.js admin@srbs.edu.in "StrongPass@123" "Transport Admin"
   ```

3. **⚠️ Turant baad:**
   ```bash
   # Yeh secret file DELETE karo — ab kabhi zaroorat nahi:
   rm serviceAccountKey.json
   ```

> Email/password apna daalo. Password kam se kam 10 characters,
> ek capital letter + ek number ke saath.

---

## STEP 5 — Google Maps key (~10 min)

Firebase project = Google Cloud project bhi hota hai:

1. https://console.cloud.google.com kholo → upar project selector mein
   `never-miss-bus-srbs` chuno
2. **APIs & Services → Library** → search karo aur **enable** karo:
   - "Maps SDK for Android"
   - "Maps SDK for iOS" (agar iPhone bhi target hai)
3. **APIs & Services → Credentials → Create credentials → API key**
4. Key ko **restrict** karo (important!):
   - Application restrictions → **Android apps** →
     package: `com.srbs.never_miss_bus` + SHA-1
   - SHA-1 nikaalne ke liye (project root se):
     ```bash
     cd android && ./gradlew signingReport | grep SHA1 | head -2
     ```
5. Key ko yahan daalo — `android/local.properties` mein:
   ```
   MAPS_API_KEY=AIzaSy...tumhari-key...
   ```

iOS ke liye alag key banao aur `ios/Runner/Secrets.plist` mein daalo
(format `docs/SETUP.md` section 5 mein hai).

---

## STEP 6 — Test karo! 🎉

```bash
# Sab check karne ke liye (batayega kya baaki hai):
bash firebase/check-setup.sh

# Phone/emulator pe chalao:
flutter run

# Ya naya APK banao (ab Firebase ke SAATH):
flutter build apk --release
```

**Pehla test flow:**
1. App kholo → **admin email/password** se login → Admin Console khulega
2. **Buses** → "Add bus" → Bus 1 banao
3. **Routes & Stops** → Bus 1 chuno → stops add karo (naam + lat/lng)
   - Lat/lng nikaalne ke liye: Google Maps pe jagah pe **right-click** →
     coordinates copy karo
4. **Admin Settings** → school ka naam, phone, location bharo
5. **Drivers** → driver account banao → Bus 1 assign karo
6. **Students** → student account banao → Bus 1 + stop assign karo
7. **Driver ke phone** pe login → **START TRIP** → location allow karo
8. **Student ke phone** pe login → **Track My Bus** → bus live dikhegi! 🚌

---

## Aakhri cheez — iOS push (sirf iPhone ke liye)

Apple Developer account chahiye ($99/saal):
1. developer.apple.com → Keys → **APNs Auth Key** (.p8) banao
2. Firebase Console → Project settings → **Cloud Messaging** → iOS app →
   .p8 upload karo (Key ID + Team ID ke saath)
3. Xcode → Runner → Signing & Capabilities → **Push Notifications** +
   **Background Modes** add karo

Android push ke liye kuch nahi karna — automatic chalega. ✅

---

## Common problems

| Problem | Fix |
|---|---|
| `flutterfire: command not found` | PATH mein pub cache bin add karo (Step 0 note) |
| Deploy pe "requires Blaze plan" | Step 1 → Upgrade to Blaze |
| Login pe "not set up yet" | Step 4 bootstrap script nahi chali ya claims nahi lage |
| Map blank/grey | Maps key galat ya API enable nahi (Step 5) |
| "permission-denied" errors | Rules deploy nahi hue (Step 3) |
| Student ko bus nahi dikhti | Admin ne bus assign nahi ki, ya driver ne trip start nahi kiya |

**Checklist chalao kabhi bhi:** `bash firebase/check-setup.sh` —
yeh batayega exactly kya ho gaya aur kya baaki hai.
