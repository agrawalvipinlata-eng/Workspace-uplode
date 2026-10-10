# SRBS International School App — Development Roadmap

The application will be enhanced in small, testable phases. Every phase must
keep role-based Firestore rules, preserve original document quality, pass the
Flutter test suite, produce a release APK, and be committed to GitHub.

## Phase 1 — Parent Dashboard (started)

- Student/parent snapshot: profile, fee due, alerts, attendance, homework and remarks.
- Reuse existing secured streams; do not duplicate school data.
- Add the dashboard to the categorized Modules screen.

## Phase 2 — Original-quality document vault

- Store birth certificates and other documents in private Cloud Storage, never in Firestore or Git.
- Store only metadata and storage paths in Firestore.
- Admin upload, preview and replace; authorized parent/student read access only.
- Use Storage Rules and expiring app-generated access; never expose service credentials in the APK.

## Phase 3 — Academic records

- Exam/result, timetable, daily diary improvements and student progress tracker.
- Teacher bulk actions with class-scoped permissions.

## Phase 4 — Communication and finance

- Notice Board, class notices, online fee receipts and payment history.
- Push notification delivery verification and retry/error visibility.

## Phase 5 — Safety and administration

- Geofence alerts, pickup authorization, admin analytics, admissions and certificates.
- Staff attendance and salary records with admin-only access.

## Phase 6 — Reliability and polish

- Dark mode, full language coverage, offline cache/sync, app lock and security review.

## Delivery rule

After each phase: format, analyze, test, build, inspect Git diff, commit and push
to the selected private repository. Generated dependencies and real student
documents must never be committed.
