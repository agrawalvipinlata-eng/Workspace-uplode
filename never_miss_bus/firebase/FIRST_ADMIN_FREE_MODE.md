# Pehla Admin Account — FREE MODE (koi script nahi chahiye!)

Free mode mein pehla admin banana **aur bhi asaan** hai — sab kuch
Firebase Console (browser) se hota hai, 5 minute mein:

## Step 1 — Auth user banao
1. Firebase Console → **Authentication** → **Users** tab
2. **"Add user"** button dabao
3. Email: `admin@srbs.edu.in` (ya apna), Password: strong wala
4. Ban gaya! Uska **UID copy karo** (users list mein dikhega)

## Step 2 — Firestore profile banao
1. Console → **Firestore Database** → **"Start collection"**
2. Collection ID: `users`
3. Document ID: **(wahi UID paste karo)**
4. Fields add karo:

| Field | Type | Value |
|---|---|---|
| `role` | string | `admin` |
| `fullName` | string | `Transport Admin` |
| `email` | string | `admin@srbs.edu.in` |
| `isActive` | boolean | `true` |

5. Save!

## Step 3 — RTDB access mirror banao
1. Console → **Realtime Database** → Data tab
2. Root pe **+** dabao → key: `access` → uske andar **+** →
   key: **(wahi UID)** → uske andar teen entries:
   - `role` = `"admin"`
   - `active` = `true`
   - `busId` = `""` (khaali)

Structure aisa dikhega:
```
access/
  └── <UID>/
        ├── role: "admin"
        ├── active: true
        └── busId: ""
```

## Done! 🎉
App kholo → is email/password se login karo → **Admin Console** khul
jayega. Ab baaki SAARE accounts (students, drivers) **app ke andar se**
banao — Console dobara kabhi nahi chahiye.

> Note: App se naye accounts banate waqt security rules check karti hain
> ki banane wala admin hai — koi student/driver account nahi bana sakta.
