#!/bin/bash
# NEVER MISS BUS — Setup checker (FREE MODE)
# Chalao:  bash firebase/check-setup.sh   (project root se)

cd "$(dirname "$0")/.." || exit 1
PASS=0; FAIL=0

ok()   { echo "  ✅ $1"; PASS=$((PASS+1)); }
miss() { echo "  ❌ $1"; echo "     → $2"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════"
echo "  NEVER MISS BUS — Setup Check (FREE MODE)"
echo "════════════════════════════════════════════════"

echo ""
echo "[1] Firebase app config:"
if grep -q "UnsupportedError" lib/firebase_options.dart 2>/dev/null; then
  miss "lib/firebase_options.dart abhi placeholder hai" \
       "Chalao: flutterfire configure --project=<project-id>"
else
  ok "firebase_options.dart real config ke saath generated hai"
fi

if [ -f android/app/google-services.json ]; then
  ok "android/app/google-services.json maujood hai"
else
  miss "android/app/google-services.json nahi mila" \
       "flutterfire configure yeh file automatically banata hai"
fi

echo ""
echo "[2] Maps:"
ok "OpenStreetMap use ho raha hai — koi key/card NAHI chahiye 🎉"

echo ""
echo "[3] Backend rules:"
if command -v firebase >/dev/null 2>&1; then
  ok "Firebase CLI installed hai"
  echo "     (Rules deploy karne ke liye: cd firebase && firebase deploy --only firestore:rules,firestore:indexes,database)"
else
  miss "Firebase CLI nahi hai" \
       "npm install -g firebase-tools && firebase login"
fi

echo ""
echo "[4] FREE mode notes:"
ok "Cloud Functions ki zaroorat NAHI (Spark/free plan kaafi hai)"
ok "Pehla admin browser se banta hai — firebase/FIRST_ADMIN_FREE_MODE.md"

echo ""
echo "[5] Secrets hygiene:"
if [ -f firebase/serviceAccountKey.json ]; then
  miss "serviceAccountKey.json pada hai — DELETE karo (free mode mein zaroorat hi nahi)" \
       "rm firebase/serviceAccountKey.json"
else
  ok "Koi secret key repo mein nahi padi"
fi

echo ""
echo "════════════════════════════════════════════════"
echo "  Result: $PASS ready · $FAIL baaki"
if [ $FAIL -eq 0 ]; then
  echo "  🎉 Sab set! flutter build apk --release chalao."
else
  echo "  📖 Poora guide: docs/FREE_SETUP_HINDI.md"
fi
echo "════════════════════════════════════════════════"
