# Cloudflare R2 Document Storage Setup

इस project में R2 integration staged mode में है। बिना `R2_WORKER_URL` के app Firebase Storage fallback use करती है। R2 activate करने के लिए नीचे के steps पूरे करें।

## 1. R2 bucket बनाएं

Cloudflare Dashboard → **R2 Object Storage** → **Create bucket**:

```text
Bucket name: srbs-school-documents
```

Bucket को public न करें। Files Worker के capability URLs से serve होंगी।

## 2. Worker configuration

```bash
cd r2-worker
cp wrangler.toml.example wrangler.toml
```

`wrangler.toml` में ये values भरें:

```toml
FIREBASE_PROJECT_ID = "never-miss-bus-c67b5"
ADMIN_UIDS = "firebase-admin-user-uid"
PUBLIC_WORKER_URL = "https://<your-worker-subdomain>.workers.dev"
```

`ADMIN_UIDS` में केवल admin Firebase Auth UIDs रखें, comma-separated:

```toml
ADMIN_UIDS = "uid_one,uid_two"
```

## 3. Worker secret

Capability download links के लिए random secret set करें:

```bash
openssl rand -base64 48 | wrangler secret put CAPABILITY_SECRET
```

## 4. Worker deploy

Cloudflare API token से login करें:

```bash
wrangler login
```

फिर:

```bash
npm install
npm run typecheck
wrangler deploy
```

Deploy के बाद मिलने वाला Worker URL `PUBLIC_WORKER_URL` में डालकर दोबारा deploy करें।

## 5. R2-enabled APK build

Worker URL के साथ app build करें:

```bash
cd ../never_miss_bus
flutter pub get
flutter build apk --release \
  --dart-define=R2_WORKER_URL=https://<your-worker-subdomain>.workers.dev
```

APK path:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## 6. Security model

- Firebase Auth ID token हर Worker request में verify होता है।
- केवल `ADMIN_UIDS` वाले users upload कर सकते हैं।
- Student केवल अपने `studentUid` documents का temporary view URL ले सकता है।
- Download URL 15 minutes में expire होता है।
- R2 bucket public नहीं है।
- Firestore में actual binary नहीं, केवल `objectKey`, label, size और metadata save होगी।
- Per-file maximum size 20 MB है।

## 7. Firestore rules

`firestore.rules` में `studentDocuments` collection Firebase Storage और R2 दोनों metadata formats स्वीकार करती है:

- Firebase: `storageProvider = 'firebase'`, `downloadUrl`, `storagePath`
- R2: `storageProvider = 'r2'`, `objectKey`

Rules बदलने के बाद Firebase Console में **Validate → Publish** करें।

## 8. Current state

- Worker source: `r2-worker/src/index.ts`
- Worker config template: `r2-worker/wrangler.toml.example`
- Flutter R2 client: `lib/services/document_vault_service.dart`
- Firebase fallback: बिना `R2_WORKER_URL` के automatic
- Bucket name: `srbs-school-documents`

Cloudflare credentials मिलने के बाद Worker deploy और R2-enabled final APK अलग से build करना होगा।
