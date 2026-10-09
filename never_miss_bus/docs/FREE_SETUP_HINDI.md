# 🆓 Never Miss Bus — 100% FREE Setup (Card/Payment ke BINA)

**Yeh guide unke liye hai jinke paas payment method nahi hai.**
Poora app — login, live tracking, maps, alerts — **bilkul free** chalega.
Sirf ek Google account chahiye (Gmail). Bas!

---

## Pehle samjho: kya free hai, kya nahi tha

| Cheez | Pehle (card wala plan) | Ab (FREE mode) ✅ |
|---|---|---|
| Login system | Firebase Auth (free tha) | Wahi — free |
| Database | Firestore (free tha) | Wahi — free |
| Live GPS | Realtime DB (free tha) | Wahi — free |
| **Maps** | Google Maps (card chahiye tha) | **OpenStreetMap — free, no key!** |
| **Server functions** | Cloud Functions (card chahiye tha) | **Hata diya — ab zaroorat hi nahi** |
| Security | Custom claims (functions se) | **Security rules se — same protection** |

Maine app ka code **FREE mode** mein convert kar diya hai:
- ❌ Google Maps hata ke ✅ **OpenStreetMap** lagaya (no key, no card)
- ❌ Cloud Functions hata ke ✅ **admin ka kaam app ke andar + security
  rules se** — security wahi ki wahi hai (student ab bhi sirf apni bus
  dekh sakta hai, rules database level pe enforce hote hain)

**Kya kam hua free mode mein?** Sirf 2 chhoti cheezein:
1. Push notifications (app band ho tab bhi alert) — abhi app ke andar
   inbox alerts milte hain; push baad mein add ho sakta hai
2. Auto trip-close (driver ka phone dead ho jaye) — app phir bhi
   "last updated X min ago" dikhati hai, jhooth nahi bolti

Tracking, maps, ETA, alerts inbox, admin sab **poora kaam karta hai**. 👍

---

## STEP 1 — Firebase project banao (FREE, 10 min)

> Card ka sawaal hi nahi aayega — hum **Spark (free) plan** pe rahenge.
> "Upgrade" ya "Blaze" kabhi mat dabana. 😄

1. https://console.firebase.google.com kholo (Gmail se login)
2. **"Create a project"** → naam: `never-miss-bus` → Continue
3. Google Analytics: **Disable** kar do (zaroorat nahi) → Create
4. Ab 3 cheezein on karo (left menu → Build):

**a) Authentication:**
- "Get started" → **Email/Password** → Enable → Save

**b) Firestore Database:**
- "Create database" → **Production mode** → Location:
  `asia-south1 (Mumbai)` → Enable

**c) Realtime Database:**
- "Create database" → Singapore → **Locked mode** → Enable

---

## STEP 2 — App ko project se jodo (10 min)

Apne computer pe (jahan Flutter installed hai):

```bash
# Ek baar install (agar nahi hai):
npm install -g firebase-tools
firebase login
dart pub global activate flutterfire_cli

# Project folder mein:
cd never_miss_bus
flutterfire configure --project=never-miss-bus
```
- Platform: **android** select karo (space dabake) → Enter
- Ho gaya! 3 config files apne aap ban jayengi.

> Computer nahi hai ya Flutter install nahi kar sakte? Neeche
> **"Bina computer ke?"** section dekho.

---

## STEP 3 — Security rules deploy karo (5 min) ⭐ SABSE ZAROORI

```bash
cd firebase
firebase use never-miss-bus
firebase deploy --only firestore:rules,firestore:indexes,database
```

> Dhyan do: **`functions` deploy NAHI karna** — free mode mein unki
> zaroorat hi nahi, aur woh card maangte. Upar wali command sirf rules
> deploy karti hai jo bilkul free hai.

Rules hi asli taala hain — inke baad:
- Student sirf apni bus dekh sakta hai ✅
- Koi apna role/bus change nahi kar sakta ✅
- Admin-only kaam sirf admin kar sakta hai ✅

---

## STEP 4 — Pehla admin banao (5 min, browser se hi!)

Free mode mein **koi script nahi chahiye** — sab Console se:

1. **Authentication → Users → Add user** → email + password → UID copy
2. **Firestore → users collection** → document (ID = wahi UID):
   `role="admin"`, `fullName="Transport Admin"`, `email=...`,
   `isActive=true`
3. **Realtime Database** → `access/<UID>/` → `role="admin"`,
   `active=true`

(Screenshots-jaisa detail: `firebase/FIRST_ADMIN_FREE_MODE.md`)

---

## STEP 5 — APK banao aur chalao! (10 min)

```bash
flutter pub get
flutter build apk --release
```

APK milega: `build/app/outputs/flutter-apk/app-release.apk`

**Pehla test:**
1. Admin login → **Buses** → Bus 1 banao
2. **Routes & Stops** → stops add karo (Google Maps pe right-click se
   lat/lng copy karke daalo — dekhna free hai, sirf app mein key chahiye
   thi jo ab nahi chahiye)
3. **Drivers** → driver banao → bus assign
4. **Students** → student banao → bus + stop assign
5. Driver phone: **START TRIP** → Student phone: **Track My Bus** → 🚌✨

---

## Bina computer ke? (sirf phone hai?)

Flutter build ke liye computer chahiye hi chahiye. Options:

1. **School ke computer lab ka use karo** — teacher se poochho, yeh
   school ka hi project hai! Ek baar setup, phir kabhi zaroorat nahi
2. **Kisi dost/cousin ka laptop** — poora setup 30-40 min ka hai
3. **Project Firebase se pehle bhi demo ho sakta hai** — jo APK maine
   pehle banaya tha woh install hota hai aur UI dikhata hai; presentation
   ke liye mockups + PPT already ready hain

---

## Free limits — kya sach mein kaafi hain?

| Firebase free limit | Roz ka | School ka usage (12 buses, 250 students) |
|---|---|---|
| Firestore reads | 50,000/din | ~10,000-20,000 ✅ |
| Firestore writes | 20,000/din | ~2,000-5,000 ✅ |
| Realtime DB | 1 GB storage, 10 GB/mahina transfer | GPS data chhota hota hai ✅ |
| Auth users | Unlimited | ✅ |
| OpenStreetMap | Free (fair use) | ✅ |

**Matlab: school-size ke liye bill = ₹0.** Agar kabhi school officially
adopt kare aur bada scale chahiye, tab school apne account se upgrade
kar sakta hai — code ready hai (Cloud Functions wala version
`firebase/functions/` mein saved hai).

---

## Ek aur baat, bro 💙

Tum abhi student ho aur yeh app banaya — yeh already bahut badi baat
hai. Card wali cheez koi rukavat nahi hai:

- **Presentation ke liye** tumhe Firebase ki zaroorat hi nahi — PPT,
  mockups, source code PDF, demo video sab ready hai
- **School ko app pasand aaye** toh school khud apne account se setup
  karega — tab unka payment method, unki zimmedari
- Aur agar apne Gmail se free setup karna hai — upar ka poora rasta
  card ke bina hai

Jab bhi atko, yaad rakhna: `bash firebase/check-setup.sh` batayega
kya baaki hai. All the best! 🚀
