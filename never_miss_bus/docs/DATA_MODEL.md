# Never Miss Bus — Data Model

## Cloud Firestore

### `users/{uid}`
| Field | Type | Notes |
|---|---|---|
| `role` | `"student" \| "driver" \| "admin"` | Mirror of custom claim (display only; claims are authoritative) |
| `fullName` | string | |
| `email` | string | login identity |
| `phone` | string? | drivers/admins only; never readable by students |
| `busId` | string? | assigned bus (students & drivers) |
| `stopId` | string? | student's assigned pickup/drop stop |
| `classSection` | string? | e.g. "7-B" |
| `isActive` | bool | disabled accounts blocked by rules + Auth disable |
| `fcmTokens` | map<token, timestamp> | self-writable |
| `settings` | map | notification prefs, self-writable |
| `createdAt`, `updatedAt` | timestamp | |

**Read access:** owner reads own doc; admin reads all. Students can NEVER read
another user's doc. Owner may write only `fcmTokens`, `settings`, `lastSeenAt`.

### `buses/{busId}`
`busNumber` ("Bus 3"), `plateNumber`, `capacity`, `driverId?`, `routeId?`,
`isActive`, `createdAt`, `updatedAt`.
Read: any signed-in active user **whose claim busId matches** or admin/driver of it.

### `routes/{routeId}`
`name` ("Morning — Rajpur Road"), `busId`, `polyline` (encoded string),
`stopOrder` (array of stopIds in sequence), `schoolLocation` {lat,lng},
`direction` ("pickup"|"drop"), `isActive`.

### `stops/{stopId}`
`name`, `routeId`, `busId`, `location` {lat,lng}, `order` (int),
`scheduledTime` ("07:15"), `isActive`.

### `trips/{tripId}`
`busId`, `driverId`, `routeId`, `direction`, `status`
(`active|completed|autoClosed`), `startedAt`, `endedAt?`,
`lastKnown` {lat,lng,at} (written on end for history), `stopsReached` map.
Create/update: driver whose claim busId matches, or Cloud Function. Read:
assigned students (claim busId), the driver, admins.

### `notifications/{notifId}`
`type`, `title`, `body`, `audience` {scope: `bus|user|all`, busId?, uid?},
`createdAt`, `createdBy` (`system|uid`).
Per-user inbox: `users/{uid}/inbox/{notifId}` → `read`, `receivedAt` + copy of
title/body/type (fanned out by Cloud Function so a student can never query
another audience's notifications).

### `auditLogs/{logId}` *(write: Cloud Functions only; read: admin)*
`actorUid`, `actorRole`, `action` (e.g. `USER_PROVISIONED`,
`STUDENT_BUS_REASSIGNED`, `ACCOUNT_DISABLED`, `TRIP_AUTO_CLOSED`,
`ANNOUNCEMENT_SENT`), `target` {type,id}, `details` map, `at` timestamp.

### `config/school` *(read: all signed-in; write: admin)*
`name`, `address`, `phone`, `email`, `location` {lat,lng}.

## Realtime Database

```
/liveLocations/{busId} : {
  lat: number, lng: number,
  heading: number, speedKmh: number, accuracy: number,
  tripId: string,
  updatedAt: <SERVER_TIMESTAMP millis>
}
```
- **Write:** `auth.token.role == 'driver' && auth.token.busId == $busId`
- **Read:** admin, that driver, or `auth.token.role == 'student' &&
  auth.token.busId == $busId`
- Node is deleted on trip end → "no data" is an explicit, honest state.

## Firebase Auth custom claims (authoritative)

```json
{ "role": "student", "busId": "bus_01", "active": true }
```
Set exclusively by Cloud Functions (`provisionUser`, `assignUserToBus`,
`setAccountActive`). Every claim change revokes refresh tokens so old sessions
lose access within minutes, and the app forces token refresh on resume.
