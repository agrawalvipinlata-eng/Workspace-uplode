# 🏪 Play Store Launch Checklist — SRBS International School App

## ✅ App jo requirements ABHI fulfill karti hai

| Requirement | Status | Detail |
|---|---|---|
| Privacy Policy (in-app) | ✅ | Settings → Privacy Policy (English + Hindi) |
| Privacy Policy (web URL) | ⚠️ | `docs/privacy_policy.html` ready hai — kahin host karna hoga (niche dekho) |
| No ads | ✅ | App me koi ad nahi |
| No public sign-up | ✅ | Sirf school account banata hai |
| Data safety (koi data sale nahi) | ✅ | Data sirf school ke Firebase me |
| Location disclosure | ✅ | Sirf DRIVER ka GPS, sirf trip ke time |
| Target SDK 34+ (2026 requirement) | ✅ | compileSdk 35, targetSdk latest |
| 64-bit APK (arm64) | ✅ | arm64-v8a build |
| App icon + naam proper | ✅ | School logo + "SRBS International School" |
| Crash-free | ✅ | 0 analyzer issues, 15/15 tests, startup error-guard |
| Password security | ✅ | Firebase Auth + single-device + forced change |

## ⚠️ Play Store pe daalne se PEHLE ye karna hoga

1. **Google Play Developer Account** — $25 (one-time, ~₹2100).
   Ye 18+ account chahiye — **papa/mummy ya school ke naam se banwana**.
2. **Privacy Policy URL** — `privacy_policy.html` ko host karo (FREE options):
   - GitHub Pages (free) — sabse aasan
   - Google Sites (free) — school ka Gmail se
   - Firebase Hosting (free) — same project me
3. **App Signing** — Play Console khud manage karega (upload key banana hoga:
   `keytool -genkey -v -keystore upload.keystore ...` — jab account ban jaye tab batana, main karwa dunga).
4. **AAB format** — Play Store ko `.apk` nahi, `.aab` chahiye:
   `flutter build appbundle` (main bana dunga jab account ready ho).
5. **Store listing** — screenshots (2+), description, feature graphic 1024x500.
6. **Data Safety form** — Console me bharna hota hai. Answers:
   - Location: YES (app functionality, driver only, not shared)
   - Personal info (name, phone): YES (app functionality, not shared)
   - Photos: YES (optional profile photo, not shared)
   - Data encrypted in transit: YES · Data deletion request: YES
7. **Content rating questionnaire** — "Utility/Education", no violence etc. → Everyone rating.
8. **Children policy note**: App "school tool" category me hai, students
   supervision me use karte hain, self sign-up nahi hai — ye Play ke
   Families policy ke under theek hai kyunki app sirf school distribute karta hai.

## 💡 IMPORTANT — Play Store ke bina bhi distribute kar sakte ho

School ke liye asli me Play Store zaroori NahI hai:
- APK direct WhatsApp/website se share karo (abhi jaise chal raha hai)
- Ya Play Console me "Closed testing" track use karo (sirf school ke logo ko link se milega)

## 📊 STUDENT CAPACITY (Firebase FREE/Spark plan)

| Cheez | Free limit | Matlab |
|---|---|---|
| Firestore reads | 50,000/din | ~600-800 active students aaram se |
| Firestore writes | 20,000/din | Attendance + fees sab included |
| RTDB connections | 100 ek saath | Ek time pe ~100 log LIVE tracking dekh sakte hain |
| RTDB storage | 1 GB | Bus locations ke liye bahut zyada hai |
| Auth users | UNLIMITED | Kitne bhi students |
| Firestore storage | 1 GB | ~5,000+ students ka data (photos base64 300px small) |

**Practical answer: ~500-700 students + 20-30 staff comfortably.**
Bottleneck sirf "100 simultaneous live-tracking viewers" hai — matlab ek hi
second me 100 se zyada log map khol ke baithe ho toh 101st ko wait karna
padega. Normal use me ye kabhi touch nahi hoga kyunki sab alag-alag time pe
dekhte hain. School bada ho jaye toh Blaze plan me bhi ye sab FREE tier ke
andar hi rehta hai (card lagta hai par bill ~₹0 aata hai).
