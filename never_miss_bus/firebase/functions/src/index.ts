/**
 * NEVER MISS BUS — privileged backend.
 *
 * Everything security-critical lives here, running with the Admin SDK:
 *  - account provisioning + custom-claim management (roles, bus binding)
 *  - assignment changes with refresh-token revocation
 *  - account enable/disable
 *  - notification fan-out to explicit FCM tokens (no topics)
 *  - geofence "bus approaching / reached stop / reached school" alerts
 *  - stale-trip sweeper (driver phone died mid-trip)
 *  - tamper-proof audit logging
 *
 * No secrets are embedded: the Admin SDK uses the runtime service account.
 */
import * as admin from "firebase-admin";
import { onCall, HttpsError, CallableRequest } from "firebase-functions/v2/https";
import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { onValueWritten } from "firebase-functions/v2/database";
import { onSchedule } from "firebase-functions/v2/scheduler";

admin.initializeApp();
const db = admin.firestore();
const rtdb = admin.database();

type Role = "student" | "driver" | "admin";

// ─────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────

/** Rejects unless the caller's verified ID token carries the admin claim. */
function requireAdmin(req: CallableRequest): string {
  const auth = req.auth;
  if (!auth) throw new HttpsError("unauthenticated", "Sign in required.");
  if (auth.token.role !== "admin" || auth.token.active !== true) {
    throw new HttpsError("permission-denied", "Admin access required.");
  }
  return auth.uid;
}

function requireString(v: unknown, field: string, maxLen = 200): string {
  if (typeof v !== "string" || v.trim().length === 0 || v.length > maxLen) {
    throw new HttpsError("invalid-argument", `Invalid ${field}.`);
  }
  return v.trim();
}

function optionalString(v: unknown, field: string, maxLen = 200): string | null {
  if (v === undefined || v === null || v === "") return null;
  return requireString(v, field, maxLen);
}

async function audit(
  actorUid: string,
  actorRole: string,
  action: string,
  target: { type: string; id: string },
  details: Record<string, unknown> = {},
): Promise<void> {
  await db.collection("auditLogs").add({
    actorUid,
    actorRole,
    action,
    target,
    details,
    at: admin.firestore.FieldValue.serverTimestamp(),
  });
}

/** Sends a push to explicit tokens and writes per-user inbox copies. */
async function notifyUsers(
  uids: string[],
  payload: { type: string; title: string; body: string },
): Promise<void> {
  if (uids.length === 0) return;
  const userDocs = await Promise.all(
    uids.map((uid) => db.collection("users").doc(uid).get()),
  );

  const tokens: string[] = [];
  const batch = db.batch();
  const now = admin.firestore.FieldValue.serverTimestamp();

  for (const doc of userDocs) {
    if (!doc.exists) continue;
    const data = doc.data()!;
    if (data.isActive === false) continue;

    // Per-user inbox copy (private; readable only by that user).
    const inboxRef = db
      .collection("users").doc(doc.id)
      .collection("inbox").doc();
    batch.set(inboxRef, { ...payload, read: false, receivedAt: now });

    const fcmTokens = data.fcmTokens as Record<string, unknown> | undefined;
    if (fcmTokens) tokens.push(...Object.keys(fcmTokens));
  }
  await batch.commit();

  // FCM allows 500 tokens per multicast call.
  for (let i = 0; i < tokens.length; i += 500) {
    const chunk = tokens.slice(i, i + 500);
    try {
      const res = await admin.messaging().sendEachForMulticast({
        tokens: chunk,
        notification: { title: payload.title, body: payload.body },
        data: { type: payload.type },
        android: { priority: "high" },
        apns: { payload: { aps: { sound: "default" } } },
      });
      // Prune dead tokens.
      const dead: string[] = [];
      res.responses.forEach((r, idx) => {
        if (
          !r.success &&
          (r.error?.code === "messaging/registration-token-not-registered" ||
            r.error?.code === "messaging/invalid-registration-token")
        ) {
          dead.push(chunk[idx]);
        }
      });
      if (dead.length > 0) {
        for (const doc of userDocs) {
          if (!doc.exists) continue;
          const updates: Record<string, unknown> = {};
          for (const t of dead) {
            if ((doc.data()!.fcmTokens ?? {})[t] !== undefined) {
              updates[`fcmTokens.${t}`] = admin.firestore.FieldValue.delete();
            }
          }
          if (Object.keys(updates).length > 0) await doc.ref.update(updates);
        }
      }
    } catch (e) {
      console.error("FCM multicast failed", e);
    }
  }
}

async function studentsOfBus(busId: string): Promise<string[]> {
  const snap = await db
    .collection("users")
    .where("role", "==", "student")
    .where("busId", "==", busId)
    .get();
  return snap.docs.map((d) => d.id);
}

// ─────────────────────────────────────────────────────────────────────
// 1. provisionUser — admin creates student/driver/admin accounts
// ─────────────────────────────────────────────────────────────────────
export const provisionUser = onCall(async (req) => {
  const adminUid = requireAdmin(req);

  const email = requireString(req.data.email, "email");
  const fullName = requireString(req.data.fullName, "fullName");
  const role = requireString(req.data.role, "role") as Role;
  const password = requireString(req.data.temporaryPassword, "password", 128);
  const busId = optionalString(req.data.busId, "busId");
  const stopId = optionalString(req.data.stopId, "stopId");
  const classSection = optionalString(req.data.classSection, "classSection", 20);
  const phone = optionalString(req.data.phone, "phone", 20);

  if (!["student", "driver", "admin"].includes(role)) {
    throw new HttpsError("invalid-argument", "Invalid role.");
  }
  if (password.length < 10) {
    throw new HttpsError("invalid-argument", "Password must be ≥10 characters.");
  }
  if (busId) {
    const bus = await db.collection("buses").doc(busId).get();
    if (!bus.exists) throw new HttpsError("invalid-argument", "Bus not found.");
  }

  const user = await admin.auth().createUser({
    email,
    password,
    displayName: fullName,
  });

  const claims: Record<string, unknown> = { role, active: true };
  if (busId) claims.busId = busId;
  await admin.auth().setCustomUserClaims(user.uid, claims);

  await db.collection("users").doc(user.uid).set({
    role,
    fullName,
    email,
    busId: busId ?? null,
    stopId: role === "student" ? stopId ?? null : null,
    classSection: role === "student" ? classSection ?? null : null,
    phone: role !== "student" ? phone ?? null : null,
    isActive: true,
    fcmTokens: {},
    settings: {},
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  await audit(adminUid, "admin", "USER_PROVISIONED",
    { type: "user", id: user.uid }, { role, busId });

  return { uid: user.uid };
});

// ─────────────────────────────────────────────────────────────────────
// 2. assignUserToBus — student re-assignment (claims + doc + revocation)
// ─────────────────────────────────────────────────────────────────────
export const assignUserToBus = onCall(async (req) => {
  const adminUid = requireAdmin(req);
  const uid = requireString(req.data.uid, "uid");
  const busId = optionalString(req.data.busId, "busId");
  const stopId = optionalString(req.data.stopId, "stopId");

  const userDoc = await db.collection("users").doc(uid).get();
  if (!userDoc.exists) throw new HttpsError("not-found", "User not found.");
  const role = userDoc.data()!.role as Role;
  if (role !== "student") {
    throw new HttpsError("invalid-argument", "Use assignDriverToBus for drivers.");
  }
  if (busId) {
    const bus = await db.collection("buses").doc(busId).get();
    if (!bus.exists) throw new HttpsError("invalid-argument", "Bus not found.");
  }
  if (stopId) {
    const stop = await db.collection("stops").doc(stopId).get();
    if (!stop.exists || stop.data()!.busId !== busId) {
      throw new HttpsError("invalid-argument", "Stop does not belong to that bus.");
    }
  }

  const existing = (await admin.auth().getUser(uid)).customClaims ?? {};
  await admin.auth().setCustomUserClaims(uid, {
    ...existing,
    role: "student",
    busId: busId ?? null,
  });
  await db.collection("users").doc(uid).update({
    busId: busId ?? null,
    stopId: stopId ?? null,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Old ID tokens (with old busId claim) die now.
  await admin.auth().revokeRefreshTokens(uid);

  await audit(adminUid, "admin", "STUDENT_BUS_REASSIGNED",
    { type: "user", id: uid }, { busId, stopId });
  return { ok: true };
});

// ─────────────────────────────────────────────────────────────────────
// 3. assignDriverToBus — one driver per bus, enforced transactionally
// ─────────────────────────────────────────────────────────────────────
export const assignDriverToBus = onCall(async (req) => {
  const adminUid = requireAdmin(req);
  const uid = requireString(req.data.uid, "uid");
  const busId = optionalString(req.data.busId, "busId");

  const userDoc = await db.collection("users").doc(uid).get();
  if (!userDoc.exists || userDoc.data()!.role !== "driver") {
    throw new HttpsError("invalid-argument", "Driver account not found.");
  }

  await db.runTransaction(async (tx) => {
    if (busId) {
      const busRef = db.collection("buses").doc(busId);
      const bus = await tx.get(busRef);
      if (!bus.exists) throw new HttpsError("invalid-argument", "Bus not found.");
      const currentDriver = bus.data()!.driverId as string | null;
      if (currentDriver && currentDriver !== uid) {
        // Unassign previous driver's doc; claims fixed below via revocation.
        tx.update(db.collection("users").doc(currentDriver), { busId: null });
      }
      tx.update(busRef, { driverId: uid });
    }
    // Clear driver from any bus that previously pointed at them.
    const previous = await db
      .collection("buses").where("driverId", "==", uid).get();
    previous.docs.forEach((d) => {
      if (d.id !== busId) tx.update(d.ref, { driverId: null });
    });
    tx.update(db.collection("users").doc(uid), {
      busId: busId ?? null,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  const existing = (await admin.auth().getUser(uid)).customClaims ?? {};
  await admin.auth().setCustomUserClaims(uid, {
    ...existing,
    role: "driver",
    busId: busId ?? null,
  });
  await admin.auth().revokeRefreshTokens(uid);

  await audit(adminUid, "admin", "DRIVER_BUS_REASSIGNED",
    { type: "user", id: uid }, { busId });
  return { ok: true };
});

// ─────────────────────────────────────────────────────────────────────
// 4. setAccountActive — enable/disable with immediate effect
// ─────────────────────────────────────────────────────────────────────
export const setAccountActive = onCall(async (req) => {
  const adminUid = requireAdmin(req);
  const uid = requireString(req.data.uid, "uid");
  const active = req.data.active === true;

  if (uid === adminUid && !active) {
    throw new HttpsError("failed-precondition", "You cannot disable your own account.");
  }

  const existing = (await admin.auth().getUser(uid)).customClaims ?? {};
  await admin.auth().updateUser(uid, { disabled: !active });
  await admin.auth().setCustomUserClaims(uid, { ...existing, active });
  await admin.auth().revokeRefreshTokens(uid);
  await db.collection("users").doc(uid).update({
    isActive: active,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  await audit(adminUid, "admin", active ? "ACCOUNT_ENABLED" : "ACCOUNT_DISABLED",
    { type: "user", id: uid });
  return { ok: true };
});

// ─────────────────────────────────────────────────────────────────────
// 5. sendAnnouncement — audience resolved SERVER-side
// ─────────────────────────────────────────────────────────────────────
export const sendAnnouncement = onCall(async (req) => {
  const adminUid = requireAdmin(req);
  const title = requireString(req.data.title, "title", 80);
  const body = requireString(req.data.body, "body", 400);
  const scope = requireString(req.data.scope, "scope", 10);

  let uids: string[] = [];
  if (scope === "all") {
    const snap = await db.collection("users")
      .where("isActive", "==", true).get();
    uids = snap.docs.map((d) => d.id);
  } else if (scope === "bus") {
    const busId = requireString(req.data.busId, "busId");
    uids = await studentsOfBus(busId);
    const bus = await db.collection("buses").doc(busId).get();
    const driverId = bus.data()?.driverId as string | undefined;
    if (driverId) uids.push(driverId);
  } else if (scope === "class") {
    const classSection = requireString(req.data.classSection, "classSection");
    const snap = await db.collection("users")
      .where("isActive", "==", true)
      .where("role", "==", "student")
      .where("classSection", "==", classSection).get();
    uids = snap.docs.map((d) => d.id);
  } else if (scope === "user") {
    uids = [requireString(req.data.uid, "uid")];
  } else {
    throw new HttpsError("invalid-argument", "Invalid scope.");
  }

  await db.collection("notifications").add({
    type: "announcement", title, body,
    audience: {
      scope,
      busId: req.data.busId ?? null,
      classSection: req.data.classSection ?? null,
      uid: req.data.uid ?? null,
    },
    createdBy: adminUid,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  await notifyUsers(uids, { type: "announcement", title, body });
  await audit(adminUid, "admin", "ANNOUNCEMENT_SENT",
    { type: "notification", id: scope }, { title });
  return { ok: true };
});

// ─────────────────────────────────────────────────────────────────────
// 6. onTripWrite — trip started/ended notifications + audit
// ─────────────────────────────────────────────────────────────────────
export const onTripWrite = onDocumentWritten("trips/{tripId}", async (event) => {
  const before = event.data?.before?.data();
  const after = event.data?.after?.data();
  if (!after) return;

  const busId = after.busId as string;
  const direction = after.direction === "drop" ? "drop-off" : "pickup";

  // Trip started.
  if (!before && after.status === "active") {
    const uids = await studentsOfBus(busId);
    await notifyUsers(uids, {
      type: "tripStarted",
      title: "Bus trip started 🚌",
      body: `Your bus has started its ${direction} trip. Track it live now!`,
    });
    await audit(after.driverId, "driver", "TRIP_STARTED",
      { type: "trip", id: event.params.tripId }, { busId });
    return;
  }

  // Trip ended.
  if (before?.status === "active" && after.status !== "active") {
    // Defensive cleanup: remove live node even if the client failed to.
    await rtdb.ref(`liveLocations/${busId}`).remove().catch(() => undefined);
    await audit(after.driverId ?? "system",
      after.status === "autoClosed" ? "system" : "driver",
      after.status === "autoClosed" ? "TRIP_AUTO_CLOSED" : "TRIP_ENDED",
      { type: "trip", id: event.params.tripId }, { busId });
  }
});

// ─────────────────────────────────────────────────────────────────────
// 7. onLocationWrite — geofence alerts (approaching / reached / school)
// ─────────────────────────────────────────────────────────────────────
const APPROACH_METERS = 800;
const REACHED_METERS = 120;

function haversine(aLat: number, aLng: number, bLat: number, bLng: number): number {
  const R = 6371000;
  const dLat = ((bLat - aLat) * Math.PI) / 180;
  const dLng = ((bLng - aLng) * Math.PI) / 180;
  const s =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((aLat * Math.PI) / 180) *
      Math.cos((bLat * Math.PI) / 180) *
      Math.sin(dLng / 2) ** 2;
  return 2 * R * Math.atan2(Math.sqrt(s), Math.sqrt(1 - s));
}

export const onLocationWrite = onValueWritten(
  { ref: "/liveLocations/{busId}" },
  async (event) => {
    const after = event.data.after.val();
    if (!after) return;
    const busId = event.params.busId;
    const { lat, lng, tripId } = after as { lat: number; lng: number; tripId: string };
    if (typeof lat !== "number" || typeof lng !== "number" || !tripId) return;

    const tripRef = db.collection("trips").doc(tripId);
    const trip = await tripRef.get();
    if (!trip.exists || trip.data()!.status !== "active") return;
    const alreadyNotified: Record<string, string> =
      trip.data()!.geofenceState ?? {};

    const stopsSnap = await db
      .collection("stops")
      .where("busId", "==", busId)
      .where("isActive", "==", true)
      .get();

    const updates: Record<string, string> = {};
    for (const stopDoc of stopsSnap.docs) {
      const stop = stopDoc.data();
      const dist = haversine(lat, lng, stop.location.lat, stop.location.lng);
      const state = alreadyNotified[stopDoc.id];

      if (dist <= REACHED_METERS && state !== "reached") {
        updates[stopDoc.id] = "reached";
        const students = await db
          .collection("users")
          .where("role", "==", "student")
          .where("stopId", "==", stopDoc.id)
          .get();
        await notifyUsers(students.docs.map((d) => d.id), {
          type: "busReachedStop",
          title: "Bus at your stop 📍",
          body: `The bus has reached ${stop.name}.`,
        });
      } else if (dist <= APPROACH_METERS && !state) {
        updates[stopDoc.id] = "approaching";
        const students = await db
          .collection("users")
          .where("role", "==", "student")
          .where("stopId", "==", stopDoc.id)
          .get();
        await notifyUsers(students.docs.map((d) => d.id), {
          type: "busApproaching",
          title: "Bus approaching 🚌",
          body: `Your bus is close to ${stop.name}. Please be ready!`,
        });
      }
    }

    // School arrival (pickup trips).
    const routeSnap = await db
      .collection("routes")
      .where("busId", "==", busId)
      .where("isActive", "==", true)
      .limit(1)
      .get();
    if (!routeSnap.empty && !alreadyNotified["__school"]) {
      const school = routeSnap.docs[0].data().schoolLocation;
      if (
        school &&
        haversine(lat, lng, school.lat, school.lng) <= REACHED_METERS &&
        trip.data()!.direction === "pickup"
      ) {
        updates["__school"] = "reached";
        const uids = await studentsOfBus(busId);
        await notifyUsers(uids, {
          type: "busReachedSchool",
          title: "Bus reached school 🏫",
          body: "The bus has arrived at SRBS International School.",
        });
      }
    }

    if (Object.keys(updates).length > 0) {
      const merged: Record<string, string> = { ...alreadyNotified, ...updates };
      await tripRef.update({ geofenceState: merged });
    }
  },
);

// ─────────────────────────────────────────────────────────────────────
// 8. sweepStaleTrips — driver phone died / app killed mid-trip
// ─────────────────────────────────────────────────────────────────────
export const sweepStaleTrips = onSchedule("every 5 minutes", async () => {
  const STALE_MS = 15 * 60 * 1000;
  const active = await db
    .collection("trips").where("status", "==", "active").get();

  for (const tripDoc of active.docs) {
    const busId = tripDoc.data().busId as string;
    const snap = await rtdb.ref(`liveLocations/${busId}`).get();
    const last = snap.exists() ? (snap.val().updatedAt as number) : 0;
    const startedAt =
      (tripDoc.data().startedAt as admin.firestore.Timestamp | undefined)
        ?.toMillis() ?? 0;
    const reference = Math.max(last, startedAt);

    if (Date.now() - reference > STALE_MS) {
      await tripDoc.ref.update({
        status: "autoClosed",
        endedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      await rtdb.ref(`liveLocations/${busId}`).remove().catch(() => undefined);
      const uids = await studentsOfBus(busId);
      await notifyUsers(uids, {
        type: "trackingUnavailable",
        title: "Tracking unavailable",
        body:
          "We lost contact with the bus and tracking has been paused. " +
          "Please contact the school if you need help.",
      });
    }
  }
});
