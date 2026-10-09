# 🚌 Never Miss Bus — SRBS International School

A secure, modern, friendly **school bus live-tracking app** for Android and
iOS. Students see their assigned bus live on a map with its route, stops and
alerts; drivers share GPS with one tap; the school admin manages the entire
transport structure.

> **This is a school transportation management system, not a generic GPS
> tracker.** Every piece of data is role-fenced on the backend: a student can
> only ever see *their own* bus.

---

## Feature summary

| Student | Driver | Admin |
|---|---|---|
| Secure school-provided login | Secure login | Strong admin login |
| Home: greeting, bus card, live status, **Track My Bus** | One-tap **Start / End Trip** | Dashboard with fleet stats |
| Full live map: bus 🚌 marker, route, stops, my stop ⭐, school | Automatic GPS sharing (foreground service) | Manage students / drivers / buses / routes / stops |
| Honest tracking states: LIVE / "last updated X ago" / unavailable | GPS + internet + sharing status tiles | Assign students↔buses↔stops, drivers↔buses |
| Approximate ETA ("~8 min", never a guarantee) | Route stop list | Live monitoring map of all active buses |
| Alerts inbox + push notifications | Trip resume after app restart | Announcements (all / per-bus) |
| Profile, school contact, settings, logout | Profile + transport office contact | Enable/disable accounts, audit logs, school profile |

## Architecture (short version)

- **Flutter + Riverpod + go_router** — clean layering: `models → services →
  providers → features`, one design system for all three roles.
- **Cloud Firestore** — structured data (users, buses, routes, stops, trips,
  notifications, audit logs).
- **Firebase Realtime Database** — one tiny node per bus for high-frequency
  live GPS (`/liveLocations/{busId}`), deleted when the trip ends.
- **Firebase Auth custom claims** (`role`, `busId`, `active`) — the *only*
  authorization source; set exclusively by Cloud Functions, enforced by
  Firestore + RTDB security rules. Client role checks are cosmetic.
- **Cloud Functions** — account provisioning, assignment changes with token
  revocation, FCM fan-out to explicit tokens (no topics), geofence alerts
  ("bus approaching / reached stop / reached school"), stale-trip sweeper,
  tamper-proof audit logging.
- **google_maps_flutter** — production maps on both platforms with a custom
  drawn school-bus marker.

Full details: [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) ·
[`docs/DATA_MODEL.md`](docs/DATA_MODEL.md) ·
[`docs/SECURITY.md`](docs/SECURITY.md)

## Getting it running

The repo intentionally contains **zero credentials**. Follow
[`docs/SETUP.md`](docs/SETUP.md):

1. `flutterfire configure` (generates `firebase_options.dart` + platform files)
2. Deploy rules + indexes + functions: `firebase deploy`
3. Bootstrap the first admin (one-time Admin-SDK script)
4. Add Google Maps keys (`android/local.properties`, `ios/Runner/Secrets.plist`)
5. Upload APNs key for iOS push
6. `flutter run`

## Project layout

```
lib/
├── core/          design system (colors, typography, theme), shared widgets,
│                  constants, validators, formatters, Result type
├── models/        pure-Dart data classes
├── services/      Firebase/platform gateways (auth, firestore, RTDB live
│                  location, driver trip GPS, ETA, FCM, connectivity)
├── providers/     Riverpod graph (session, role, data streams, freshness)
├── router/        go_router with role-fenced redirects
└── features/      auth / student / driver / admin screens
firebase/
├── firestore.rules            role + claim enforced access control
├── database.rules.json        per-bus live-location fencing
├── firestore.indexes.json
└── functions/src/index.ts     privileged backend (TypeScript)
docs/              architecture, data model, security, setup
test/              unit tests (validators, freshness honesty, ETA guardrails)
```

## Quality gates

- `flutter analyze` → **0 issues**
- `flutter test` → **15/15 passing**, including tests that assert the app
  can never present stale GPS as "live" and never fabricates an ETA
- Cloud Functions compile clean under `tsc --strict`

## Honest-status policy

The UI never lies about tracking:
- fix ≤ 30 s old → **LIVE** (pulsing green)
- 30 s – 3 min → **"Last updated X ago"** (amber, dimmed marker)
- older / no trip → **"Location temporarily unavailable"** / "No trip in
  progress" (no bus marker at all)
- ETA is always worded "approximately" and suppressed entirely when data is
  unreliable.
