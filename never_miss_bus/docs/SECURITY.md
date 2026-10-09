# Never Miss Bus — Security Model

## Threat model & guarantees

| Requirement | Enforcement (server-side) |
|---|---|
| Student can't change own bus assignment | `users` rule: self-writes limited to `fcmTokens`, `settings`, `lastSeenAt`. `role`/`busId`/`stopId` changes are Cloud-Function-only. |
| Student can't read another student's data | `users/{uid}` readable only by owner or admin. Inbox is a subcollection under the owner. |
| Student can't track another bus | RTDB rule: read on `/liveLocations/{busId}` requires `auth.token.busId === $busId`. Firestore `buses`/`routes`/`stops`/`trips` reads equally claim-fenced. There is no list/browse permission on any bus collection for students. |
| Driver controls only their own bus/trip | Trip `create` requires `driverId == auth.uid` AND `busId == auth.token.busId`; trip `update` restricted to status/end fields by the same driver. RTDB write requires the same busId claim. |
| Admin-only management | All management collections require the `admin` claim; privileged mutations run in callable functions that re-verify the claim server-side. |
| No public tracking URLs | Nothing is world-readable. Default rule is deny; RTDB root is deny; there is no unauthenticated surface. |
| Roles can't be self-upgraded | Roles live in custom claims signed into the ID token by Firebase. Clients cannot write claims. The `role` field in `users` docs is display-only and non-writable by the owner. |
| Revocation is fast | Assignment/disable functions call `revokeRefreshTokens`; ID tokens expire ≤60 min; app force-refreshes token on resume; rules also check `isActive`/`active` so disabled accounts fail immediately on the doc flag too. |
| Passwords never stored in plaintext | Firebase Authentication (scrypt) manages all credentials. The app never persists a password. |
| Audit trail is tamper-proof | `auditLogs` write access is `false` for all clients; entries are created only by Cloud Functions; admins have read-only access. |
| Input validation | Client validators for UX + rules-level type/range checks (lat ∈ [-90,90], lng ∈ [-180,180], status enums, field allow-lists) + function-side re-validation. |
| Location spoof-resistance | RTDB `.validate` forces `updatedAt === now` (server time), so freshness can't be forged with a wrong clock; writes only accepted from the assigned driver's authenticated session. |
| Secrets hygiene | No API keys in source. Maps keys via git-ignored `local.properties` / `Secrets.plist`; Firebase server credentials exist only in the Functions runtime; `firebase_options.dart` is a placeholder until generated. |

## Notification privacy

FCM **topics are not used** — any client can subscribe to any topic name,
which would leak bus-scoped events. Instead, Cloud Functions resolve the
audience from Firestore (e.g. students where `busId == X`) and send to their
registered device tokens, and write a private inbox copy under each user.

## Privacy / data minimisation

- Students: name, school email, class, bus/stop assignment. No phone numbers.
- Drivers: name, email, optional phone (visible to admin only).
- Bus location exists only during an active trip and is deleted at trip end;
  no location history is stored beyond the trip document's `lastKnown`.
- Student devices never share their own location — only the driver's device
  publishes GPS, and only while a trip is active, with a visible foreground
  notification.

## Residual risks & recommendations

- **Driver device compromise**: a malicious assigned driver could publish
  wrong coordinates for their own bus. Mitigation: geofence sanity alerts
  (server-side), plate-number verification by parents, rapid admin disable.
- **Shared student credentials**: passwords can be shared. Mitigation:
  school policy + password resets; access still limited to that student's
  single bus.
- Enable **App Check** (Play Integrity / App Attest) on Firestore, RTDB and
  Functions once app distribution is set up, to block non-app clients.
- Enforce a review cadence for `auditLogs` and Firebase Auth sign-in logs.
