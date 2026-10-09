#!/usr/bin/env node
/**
 * NEVER MISS BUS — First Admin Bootstrap (ONE-TIME USE)
 * ─────────────────────────────────────────────────────
 * `provisionUser` Cloud Function ko admin caller chahiye, isliye SABSE
 * PEHLA admin account yeh script banati hai (Admin SDK ke saath).
 *
 * KAISE CHALAYEIN:
 *   1. Firebase Console → Project settings → Service accounts →
 *      "Generate new private key" → serviceAccountKey.json download karo.
 *      (YEH FILE SECRET HAI — kisi ko mat dena, git mein mat daalna!)
 *   2. Is folder mein:  npm install firebase-admin
 *   3. Chalao:
 *      GOOGLE_APPLICATION_CREDENTIALS=./serviceAccountKey.json \
 *        node bootstrap-admin.js admin@srbs.edu.in "StrongPass@123" "Transport Admin"
 *   4. Kaam hone ke baad serviceAccountKey.json DELETE kar do aur
 *      pehle login ke baad password change kar lo.
 *
 * Iske baad saare accounts (students/drivers/admins) APP KE ANDAR se
 * banenge — yeh script dobara nahi chahiye.
 */
const admin = require("firebase-admin");

const [email, password, fullName] = process.argv.slice(2);

if (!email || !password) {
  console.error(
    "Usage: node bootstrap-admin.js <email> <password> [\"Full Name\"]\n" +
    "Example: node bootstrap-admin.js admin@srbs.edu.in \"StrongPass@123\" \"Transport Admin\""
  );
  process.exit(1);
}
if (password.length < 10) {
  console.error("ERROR: Password kam se kam 10 characters ka hona chahiye.");
  process.exit(1);
}

admin.initializeApp(); // GOOGLE_APPLICATION_CREDENTIALS env var se key uthata hai

(async () => {
  try {
    // Create (ya existing user reuse karo agar email pehle se hai)
    let user;
    try {
      user = await admin.auth().createUser({
        email,
        password,
        displayName: fullName || "Transport Admin",
      });
      console.log("✓ Auth user created:", user.uid);
    } catch (e) {
      if (e.code === "auth/email-already-exists") {
        user = await admin.auth().getUserByEmail(email);
        console.log("• User pehle se hai, admin claims laga raha hoon:", user.uid);
      } else {
        throw e;
      }
    }

    // Admin custom claims — yahi asli authorization hai
    await admin.auth().setCustomUserClaims(user.uid, {
      role: "admin",
      active: true,
    });
    console.log("✓ Admin custom claims set");

    // Profile document
    await admin.firestore().doc(`users/${user.uid}`).set(
      {
        role: "admin",
        fullName: fullName || "Transport Admin",
        email,
        isActive: true,
        fcmTokens: {},
        settings: {},
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
    console.log("✓ Firestore profile written");

    console.log("\n══════════════════════════════════════════════");
    console.log("  ADMIN READY! App mein login karo:");
    console.log("  Email   :", email);
    console.log("  Password: (jo tumne diya)");
    console.log("══════════════════════════════════════════════");
    console.log("\n⚠ AB YEH KARO:");
    console.log("  1. serviceAccountKey.json DELETE karo");
    console.log("  2. Pehle login ke baad password change karo");
    process.exit(0);
  } catch (err) {
    console.error("FAILED:", err.message || err);
    process.exit(1);
  }
})();
