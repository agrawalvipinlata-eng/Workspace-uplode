# Never Miss Bus — Architecture

**School:** SRBS International School
**Platforms:** Android + iOS (Flutter)

---

## 1. High-level system

```
┌─────────────┐     writes (rules-gated)      ┌──────────────────────────┐
│ DRIVER APP  │ ────────────────────────────► │ Firebase Realtime DB     │
│ (GPS every  │                               │ /liveLocations/{busId}   │
│  5s / 20m)  │                               └──────────┬───────────────┘
└─────┬───────┘                                          │ reads (rules-gated:
      │ Start/End trip (Firestore)                       │ student.busId == busId)
      ▼                                                  ▼
┌──────────────────┐    Cloud Functions        ┌─────────────────┐
│ Cloud Firestore  │ ◄──── triggers/callables ─│  STUDENT APP    │
│ users/buses/     │        - provisioning     │  Live map + ETA │
│ routes/stops/    │        - custom claims    └─────────────────┘
│ trips/notifs/    │        - FCM fan-out
│ auditLogs        │        - geofence alerts
└──────────────────┘
      ▲
      │ admin-only callables + rules-gated CRUD
┌─────┴───────┐
│  ADMIN APP  │
└─────────────┘
```

### Why two databases?
- **Cloud Firestore** — structured, queryable data: users, buses, routes, stops,
  trips, notifications, audit logs. Billed per document op → wrong tool for a
  GPS ping every 5 seconds.
- **Firebase Realtime Database** — a single small node per bus
  (`/liveLocations/{busId}`) overwritten continuously. Extremely cheap for
  high-frequency writes, and clients get sub-second push updates. RTDB security
  rules independently enforce that a student may only read their own bus node.

## 2. Authorization model (server-side, never client-trusted)

1. Admin creates accounts through the **`provisionUser` callable Cloud Function**
   (admin-only, verified by custom claim on the caller's ID token).
2. The function creates the Firebase Auth user and stamps **custom claims**:
   `{ role: 'student'|'driver'|'admin', busId: '<assignedBus>' }`.
3. **Firestore rules** and **RTDB rules** read `request.auth.token.role` and
   `request.auth.token.busId` — the client can lie all it wants; the backend
   only honours the signed token.
4. Reassigning a student/driver to another bus is a Cloud Function that updates
   claims + Firestore atomically and **revokes refresh tokens** so stale claims
   die immediately.
5. Disabling an account: Auth `disabled=true` + `users/{uid}.isActive=false` +
   token revocation. Rules also check `isActive`.

**Consequences enforced by rules (not UI):**
- A student can read exactly one `liveLocations` node — their own bus.
- A student cannot write to any assignment field (users doc writes are
  restricted to a safe field allow-list: `fcmTokens`, `settings`, `lastSeenAt`).
- A driver can only write `liveLocations/{busId}` where `busId` equals the
  claim on their token, and only while a trip they own is active.
- All management collections are admin-claim-only.

## 3. Flutter app layering

```
lib/
├── main.dart / app.dart          bootstrapping, ProviderScope, MaterialApp.router
├── core/
│   ├── theme/                    design system: colors, typography, theme
│   ├── constants/                enums, sizes, strings
│   ├── utils/                    validators, formatters, Result type
│   └── widgets/                  NmbButton, NmbCard, StatusPill, EmptyState,
│                                 LoadingView, ErrorView, dialogs, snackbars…
├── models/                       immutable data classes + from/to Firestore
├── services/                     Firebase & platform gateways (no UI imports)
├── providers/                    Riverpod graph: auth state, role, streams
├── router/                       go_router + role-based redirect guard
└── features/
    ├── auth/                     splash, login, logout confirm
    ├── student/                  home, live map, bus/route, stops, alerts,
    │                             profile, settings
    ├── driver/                   home, start/active/end trip, route, status,
    │                             profile
    └── admin/                    dashboard, students, drivers, buses, routes,
                                  stops, assignments, monitoring, notifications,
                                  access mgmt, audit logs, settings
```

**Rules of the layering:**
- `features/` (UI) talks only to `providers/`.
- `providers/` compose `services/` and expose `AsyncValue<T>` streams.
- `services/` are the only layer importing Firebase SDKs.
- `models/` are pure Dart, unit-testable.

## 4. Live tracking pipeline

1. Driver taps **Start Trip** → `DriverTripService.startTrip()`:
   - checks GPS service + permission (requests if needed),
   - creates `trips/{tripId}` (`status: active`) in Firestore,
   - starts a foreground-service location stream
     (5 s interval / 20 m distance filter, `LocationAccuracy.high`).
2. Each fix → single `set()` on `/liveLocations/{busId}`:
   `{lat, lng, heading, speedKmh, accuracy, tripId, updatedAt: SERVER_TIMESTAMP}`.
3. Student app subscribes to that one node. Freshness logic in
   `LiveLocationService`:
   - `updatedAt` ≤ 30 s old → **LIVE**
   - 30 s–3 min → **"Last updated X ago"** (stale, marker dimmed)
   - > 3 min or no active trip → **"Location temporarily unavailable"**
   Never renders an old fix as live.
4. **End Trip** → confirm dialog → stop stream, `trips/{id}.status=completed`,
   remove `liveLocations/{busId}` node.
5. Cloud Function `onTripWrite` fans out FCM "Trip started/ended"; scheduled
   function `sweepStaleTrips` auto-closes trips whose location is silent
   > 15 min (driver phone died) and pushes "Tracking unavailable".

## 5. ETA

`EtaService` computes a **conservative approximation**: remaining route
polyline distance from the bus's snapped position to the student's stop ÷
rolling average speed (floored at 12 km/h, capped display at "~N min").
If speed/coverage data is insufficient it returns `EtaUnavailable` and the UI
shows the live map + route only — an ETA is never shown as a guarantee
("approx." wording is enforced in one shared formatter).

## 6. Notifications

- FCM device tokens saved to `users/{uid}.fcmTokens` (map token→timestamp).
- **No FCM topics** (topics can be subscribed to by any client — not private).
  Cloud Functions look up the authorized audience (students of a bus, etc.) and
  send to explicit tokens.
- Events: trip started, bus approaching (geofence ~800 m from stop, computed in
  `onLocationWrite` function), reached stop, reached school, delayed, tracking
  unavailable, admin announcement.

## 7. Navigation flow

```
Splash ─► (no session) ─► Login ─► role from custom claims
   │                                   ├─ student ─► StudentShell (Home/Map/Alerts/Profile)
   └─ (session) ─► role redirect ──────┼─ driver  ─► DriverShell  (Home/Route/Profile)
                                       └─ admin   ─► AdminShell   (Dashboard + sections)
```
go_router `redirect` re-evaluates on every auth change: expired/revoked
sessions bounce to Login; a student typing an admin URL is bounced to home.
