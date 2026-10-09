#!/usr/bin/env python3
"""Generates the Never Miss Bus project PDF."""
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.lib.colors import HexColor, white
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.platypus import (
    BaseDocTemplate, PageTemplate, Frame, Paragraph, Spacer, Table,
    TableStyle, PageBreak, KeepTogether,
)

PRIMARY = HexColor("#2557D6")
PRIMARY_DARK = HexColor("#1A3FA0")
PRIMARY_SOFT = HexColor("#E8EEFC")
ACCENT = HexColor("#FFB300")
ACCENT_SOFT = HexColor("#FFF3D6")
SUCCESS = HexColor("#1E8E3E")
SUCCESS_SOFT = HexColor("#E2F3E7")
DANGER = HexColor("#C5221F")
TEXT = HexColor("#17233B")
TEXT2 = HexColor("#5A6779")
DIVIDER = HexColor("#E4E9F2")
BG = HexColor("#F6F8FC")

W, H = A4
OUT = "/home/user/never_miss_bus/docs/Never_Miss_Bus_App.pdf"

# ── styles ────────────────────────────────────────────────────────────
def st(name, **kw):
    base = dict(fontName="Helvetica", fontSize=10.5, leading=15,
                textColor=TEXT, spaceAfter=6)
    base.update(kw)
    return ParagraphStyle(name, **base)

S = {
    "h1": st("h1", fontName="Helvetica-Bold", fontSize=22, leading=26,
             textColor=PRIMARY_DARK, spaceBefore=6, spaceAfter=10),
    "h2": st("h2", fontName="Helvetica-Bold", fontSize=14.5, leading=18,
             textColor=PRIMARY, spaceBefore=14, spaceAfter=6),
    "h3": st("h3", fontName="Helvetica-Bold", fontSize=11.5, leading=15,
             textColor=TEXT, spaceBefore=8, spaceAfter=4),
    "body": st("body"),
    "body2": st("body2", textColor=TEXT2, fontSize=10, leading=14),
    "bullet": st("bullet", leftIndent=14, bulletIndent=4, spaceAfter=3),
    "small": st("small", fontSize=9, leading=12.5, textColor=TEXT2),
    "mono": st("mono", fontName="Courier", fontSize=9, leading=12.5,
               textColor=TEXT),
    "cellh": st("cellh", fontName="Helvetica-Bold", fontSize=9.5,
                leading=12.5, textColor=white, spaceAfter=0),
    "cell": st("cell", fontSize=9.5, leading=12.5, spaceAfter=0),
    "cell2": st("cell2", fontSize=9.5, leading=12.5, textColor=TEXT2,
                spaceAfter=0),
}

def bullets(items):
    return [Paragraph(f"<bullet>&bull;</bullet> {t}", S["bullet"])
            for t in items]

def table(headers, rows, widths):
    data = [[Paragraph(h, S["cellh"]) for h in headers]]
    for r in rows:
        data.append([Paragraph(c, S["cell"]) for c in r])
    t = Table(data, colWidths=widths, repeatRows=1)
    style = [
        ("BACKGROUND", (0, 0), (-1, 0), PRIMARY),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("TOPPADDING", (0, 0), (-1, -1), 5),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
        ("LEFTPADDING", (0, 0), (-1, -1), 7),
        ("RIGHTPADDING", (0, 0), (-1, -1), 7),
        ("GRID", (0, 0), (-1, -1), 0.5, DIVIDER),
    ]
    for i in range(1, len(data)):
        if i % 2 == 0:
            style.append(("BACKGROUND", (0, i), (-1, i), BG))
    t.setStyle(TableStyle(style))
    return t

def callout(text, bg=PRIMARY_SOFT, border=PRIMARY):
    t = Table([[Paragraph(text, S["body"])]], colWidths=[W - 40 * mm])
    t.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), bg),
        ("BOX", (0, 0), (-1, -1), 0.8, border),
        ("TOPPADDING", (0, 0), (-1, -1), 8),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 8),
        ("LEFTPADDING", (0, 0), (-1, -1), 10),
        ("RIGHTPADDING", (0, 0), (-1, -1), 10),
        ("ROUNDEDCORNERS", [6, 6, 6, 6]),
    ]))
    return t

# ── page furniture ────────────────────────────────────────────────────
def cover(canvas, doc):
    canvas.saveState()
    canvas.setFillColor(PRIMARY)
    canvas.rect(0, 0, W, H, stroke=0, fill=1)
    canvas.setFillColor(PRIMARY_DARK)
    canvas.rect(0, 0, W, 70 * mm, stroke=0, fill=1)
    # bus badge
    cx, cy, r = W / 2, H - 95 * mm, 21 * mm
    canvas.setFillColor(white)
    canvas.circle(cx, cy, r, stroke=0, fill=1)
    canvas.setFillColor(ACCENT)
    canvas.roundRect(cx - 14 * mm, cy - 8 * mm, 28 * mm, 15 * mm, 3 * mm,
                     stroke=0, fill=1)
    canvas.setFillColor(HexColor("#E3F2FD"))
    for i in range(3):
        canvas.roundRect(cx - 11 * mm + i * 8 * mm, cy + 0.5 * mm,
                         6 * mm, 4.5 * mm, 1 * mm, stroke=0, fill=1)
    canvas.setFillColor(white)
    canvas.rect(cx - 14 * mm, cy - 3.2 * mm, 28 * mm, 1.2 * mm,
                stroke=0, fill=1)
    canvas.setFillColor(HexColor("#37474F"))
    canvas.circle(cx - 8 * mm, cy - 8.5 * mm, 2.6 * mm, stroke=0, fill=1)
    canvas.circle(cx + 8 * mm, cy - 8.5 * mm, 2.6 * mm, stroke=0, fill=1)

    canvas.setFillColor(white)
    canvas.setFont("Helvetica-Bold", 30)
    canvas.drawCentredString(W / 2, H - 135 * mm, "NEVER MISS BUS")
    canvas.setFont("Helvetica", 13)
    canvas.setFillColor(HexColor("#CFE0FF"))
    canvas.drawCentredString(W / 2, H - 145 * mm,
                             "Secure School Bus Live-Tracking Application")
    canvas.setFillColor(ACCENT)
    canvas.roundRect(W / 2 - 45 * mm, H - 165 * mm, 90 * mm, 10 * mm,
                     5 * mm, stroke=0, fill=1)
    canvas.setFillColor(HexColor("#5B3C00"))
    canvas.setFont("Helvetica-Bold", 11)
    canvas.drawCentredString(W / 2, H - 162 * mm,
                             "SRBS  INTERNATIONAL  SCHOOL")

    canvas.setFillColor(HexColor("#CFE0FF"))
    canvas.setFont("Helvetica", 10.5)
    lines = [
        "Android  +  iOS   |   Flutter  +  Firebase",
        "Student  ·  Driver  ·  Admin",
        "",
        "Project Documentation  —  v1.0  ·  August 2026",
    ]
    y = 52 * mm
    for ln in lines:
        canvas.drawCentredString(W / 2, y, ln)
        y -= 7 * mm
    canvas.restoreState()

def page(canvas, doc):
    canvas.saveState()
    canvas.setFillColor(PRIMARY)
    canvas.rect(0, H - 12 * mm, W, 12 * mm, stroke=0, fill=1)
    canvas.setFillColor(white)
    canvas.setFont("Helvetica-Bold", 9)
    canvas.drawString(20 * mm, H - 8 * mm,
                      "NEVER MISS BUS  ·  SRBS International School")
    canvas.drawRightString(W - 20 * mm, H - 8 * mm, "App Documentation")
    canvas.setFillColor(TEXT2)
    canvas.setFont("Helvetica", 8.5)
    canvas.drawCentredString(W / 2, 9 * mm, f"Page {doc.page - 1}")
    canvas.setStrokeColor(DIVIDER)
    canvas.line(20 * mm, 13 * mm, W - 20 * mm, 13 * mm)
    canvas.restoreState()

doc = BaseDocTemplate(OUT, pagesize=A4,
                      leftMargin=20 * mm, rightMargin=20 * mm,
                      topMargin=20 * mm, bottomMargin=18 * mm,
                      title="Never Miss Bus — App Documentation",
                      author="SRBS International School")
frame = Frame(20 * mm, 18 * mm, W - 40 * mm, H - 38 * mm, id="f")
doc.addPageTemplates([
    PageTemplate(id="cover", frames=[Frame(0, 0, W, H)], onPage=cover),
    PageTemplate(id="page", frames=[frame], onPage=page),
])

E = []  # elements
E.append(Spacer(1, 1))  # cover content handled by onPage
from reportlab.platypus import NextPageTemplate
E.append(NextPageTemplate("page"))
E.append(PageBreak())

# ── 1. Overview ───────────────────────────────────────────────────────
E.append(Paragraph("1. App Overview", S["h1"]))
E.append(Paragraph(
    "Never Miss Bus is a secure school transportation management app for "
    "SRBS International School, built for Android and iOS with Flutter and "
    "Firebase. Students see the full live location of their assigned school "
    "bus, its route, designated stops and approximate arrival time, and "
    "receive important bus notifications. Drivers share GPS with a single "
    "tap. School admins manage the complete transport structure.", S["body"]))
E.append(Spacer(1, 4))
E.append(callout(
    "<b>This is not a generic GPS tracker.</b> Every piece of data is "
    "role-fenced on the backend: a student can only ever see their own "
    "assigned bus — enforced by server-side security rules, not the app UI."))
E.append(Paragraph("Key facts", S["h2"]))
E.append(table(
    ["Item", "Detail"],
    [
        ["App name", "Never Miss Bus"],
        ["School", "SRBS International School"],
        ["Platforms", "Android + iOS (single Flutter codebase)"],
        ["Frontend", "Flutter · Riverpod state management · go_router navigation"],
        ["Backend", "Firebase — Auth, Cloud Firestore, Realtime Database, "
         "Cloud Functions, Cloud Messaging (FCM)"],
        ["Maps", "Google Maps (google_maps_flutter) with a custom school-bus marker"],
        ["Roles", "Student · Driver · Admin — separate permissions and interfaces"],
        ["Quality", "flutter analyze: 0 issues · 15/15 unit tests passing · "
         "strict-TypeScript Cloud Functions"],
    ],
    [38 * mm, W - 40 * mm - 38 * mm]))

# ── 2. How it works ──────────────────────────────────────────────────
E.append(Paragraph("2. How Live Tracking Works", S["h1"]))
E.append(Paragraph(
    "DRIVER GPS &nbsp;&rarr;&nbsp; SECURE BACKEND &nbsp;&rarr;&nbsp; "
    "REAL-TIME DATABASE &nbsp;&rarr;&nbsp; AUTHORIZED STUDENT "
    "&nbsp;&rarr;&nbsp; LIVE MAP", S["h3"]))
E.extend(bullets([
    "Driver taps <b>Start Trip</b> — the phone begins sending a GPS fix "
    "every ~5 seconds / 20 metres through a foreground service (keeps "
    "working with the screen off; no interaction needed while driving).",
    "Each fix is written to a single per-bus node in Firebase Realtime "
    "Database with a <b>server timestamp</b>, so freshness cannot be faked.",
    "Students subscribed to their assigned bus see the marker move live, "
    "with the route line, all stops, their own stop highlighted with a star, "
    "and the school location.",
    "Driver taps <b>End Trip</b> — tracking stops and the location node is "
    "deleted. If the driver's phone dies mid-trip, a server job auto-closes "
    "the trip within 15 minutes and notifies students that tracking is "
    "unavailable.",
]))
E.append(Paragraph("Honest status policy", S["h2"]))
E.append(table(
    ["Data age", "What the student sees"],
    [
        ["&le; 30 seconds", "<b>LIVE</b> — pulsing green badge, full-opacity bus marker"],
        ["30 s – 3 min", "\u201cLast updated X minutes ago\u201d — amber badge, dimmed marker"],
        ["&gt; 3 min / no trip", "\u201cLocation temporarily unavailable\u201d or \u201cNo trip in "
         "progress\u201d — <b>no bus marker at all</b>"],
    ],
    [34 * mm, W - 40 * mm - 34 * mm]))
E.append(Paragraph(
    "ETA is always worded \u201cBus arriving in approximately N minutes\u201d and is "
    "hidden entirely whenever the data is not reliable — an estimate is "
    "never presented as a guarantee.", S["body2"]))

# ── 3. Roles ─────────────────────────────────────────────────────────
E.append(PageBreak())
E.append(Paragraph("3. The Three Roles", S["h1"]))

E.append(Paragraph("3.1 Student", S["h2"]))
E.extend(bullets([
    "Secure school-provided login (accounts created only by the school admin).",
    "Home: friendly greeting, assigned bus card (number, plate, ON TRIP / IDLE), "
    "live tracking status, big <b>Track My Bus</b> button, assigned stop, "
    "quick actions and latest alert.",
    "Live Map: bus marker, route, stops, my stop (star), school, "
    "\u201cCenter on Bus\u201d control.",
    "Bus &amp; Route details, ordered stop timeline, alerts inbox, profile with "
    "school contact info, settings, logout confirmation.",
    "Cannot select another bus, change assignments, or see any other "
    "student's data — blocked by backend rules.",
]))
E.append(Paragraph("3.2 Driver", S["h2"]))
E.extend(bullets([
    "Separate secure account, assigned to one bus by the admin.",
    "One giant <b>START TRIP / END TRIP</b> button — chooses morning pickup or "
    "afternoon drop, then everything is automatic.",
    "Status tiles: GPS on/off, internet connected/offline, sharing live/stopped.",
    "Route stop list in large glanceable text; trip resumes automatically if "
    "the phone restarts mid-route.",
    "Can only control their own bus and trip — enforced server-side.",
]))
E.append(Paragraph("3.3 Admin", S["h2"]))
E.extend(bullets([
    "Dashboard with fleet stats and active trips.",
    "Manage students, drivers, buses, routes and ordered bus stops.",
    "Assign students &rarr; buses &rarr; stops; assign drivers &rarr; buses.",
    "Live monitoring map of all active buses at once.",
    "Send announcements to everyone or to a single bus.",
    "Enable/disable accounts (takes effect within minutes via token "
    "revocation) and review a tamper-proof activity/audit log.",
]))

# ── 4. Screens ───────────────────────────────────────────────────────
E.append(Paragraph("4. Screen Inventory", S["h1"]))
E.append(table(
    ["Student (10)", "Driver (9)", "Admin (16 capabilities)"],
    [[
        "Splash · Login · Home · Live Map · Bus/Route Details · Bus Stops · "
        "Alerts · Profile · Settings · Logout confirm",
        "Login · Home/Dashboard · Assigned Bus · Start Trip · Active Trip · "
        "Route/Stops · GPS &amp; Connection Status · End Trip confirm · Profile",
        "Login · Dashboard · Students · Student details · Drivers · Driver "
        "details · Buses · Bus details · Routes · Stops · Assignments · Live "
        "Monitoring · Notifications · Access Management · Audit Logs · Settings",
    ]],
    [(W - 40 * mm) / 3] * 3))
E.append(Paragraph(
    "All three interfaces share one design system: rounded cards with soft "
    "shadows, school-blue + bus-amber palette (WCAG AA contrast), large "
    "readable typography, friendly icons, large touch targets, consistent "
    "status pills, dialogs, snackbars, loading / empty / error / offline "
    "states.", S["body2"]))

# ── 5. Architecture ──────────────────────────────────────────────────
E.append(PageBreak())
E.append(Paragraph("5. Architecture", S["h1"]))
E.append(Paragraph("Why two databases?", S["h3"]))
E.extend(bullets([
    "<b>Cloud Firestore</b> — structured, queryable data: users, buses, "
    "routes, stops, trips, notifications, audit logs.",
    "<b>Realtime Database</b> — one tiny node per bus for high-frequency GPS "
    "(a ping every 5 seconds would be wasteful in Firestore). The node is "
    "deleted when the trip ends.",
]))
E.append(Paragraph("Flutter app layering", S["h3"]))
E.append(Paragraph(
    "features (UI) &nbsp;&rarr;&nbsp; providers (Riverpod streams) "
    "&nbsp;&rarr;&nbsp; services (Firebase gateways) &nbsp;&rarr;&nbsp; "
    "models (pure Dart)", S["mono"]))
E.extend(bullets([
    "UI never talks to Firebase directly; services are the only layer "
    "importing Firebase SDKs.",
    "go_router with role-based redirects: signed-out users only reach "
    "Login; each role is fenced into its own subtree.",
    "Cloud Functions (TypeScript) hold all privileged logic: account "
    "provisioning, assignment changes, notification fan-out, geofence "
    "alerts, stale-trip sweeper, audit logging.",
]))
E.append(Paragraph("Main data collections", S["h3"]))
E.append(table(
    ["Collection", "Purpose"],
    [
        ["users/{uid}", "Profile, role mirror, bus/stop assignment, FCM tokens, "
         "settings, private inbox subcollection"],
        ["buses/{busId}", "Bus number, plate, capacity, driver, route"],
        ["routes/{routeId}", "Name, bus, ordered stop list, school location, direction"],
        ["stops/{stopId}", "Name, location, order, scheduled time"],
        ["trips/{tripId}", "Active/completed trip records with driver and direction"],
        ["auditLogs/{id}", "Tamper-proof activity trail (written only by Cloud Functions)"],
        ["RTDB /liveLocations/{busId}", "Live GPS fix: lat, lng, heading, speed, "
         "server-stamped updatedAt"],
    ],
    [52 * mm, W - 40 * mm - 52 * mm]))

# ── 6. Security ──────────────────────────────────────────────────────
E.append(Paragraph("6. Security &amp; Privacy", S["h1"]))
E.append(callout(
    "<b>Authorization lives in the backend, not the app.</b> Roles and bus "
    "assignments are Firebase Auth custom claims, set only by Cloud "
    "Functions and enforced by Firestore + Realtime Database security "
    "rules. A modified client cannot widen its own access.",
    bg=SUCCESS_SOFT, border=SUCCESS))
E.append(Spacer(1, 6))
E.append(table(
    ["Guarantee", "How it is enforced"],
    [
        ["Student can't change own bus", "Self-writes limited to FCM tokens, settings "
         "and last-seen; assignment fields are Cloud-Function-only"],
        ["Student can't see other students", "User docs readable only by owner or admin; "
         "notification inbox is private per user"],
        ["Student can't track other buses", "RTDB read rule requires the bus ID in the "
         "student's signed token to match the node being read"],
        ["Driver controls only own trip", "Trip create/update rules bind driverId and "
         "busId to the caller's token claims"],
        ["No public tracking URLs", "Default-deny rules everywhere; zero "
         "unauthenticated surface"],
        ["Fast revocation", "Disable/reassign revokes refresh tokens; app "
         "force-refreshes on resume"],
        ["Passwords", "Managed by Firebase Authentication (scrypt) — never "
         "stored in plain text anywhere"],
        ["Audit trail", "Clients cannot write or delete audit logs; admin "
         "read-only"],
        ["Notification privacy", "No FCM topics (any client can join a topic); "
         "audiences resolved server-side, sent to explicit device tokens"],
        ["Secrets hygiene", "No API keys in source code: Maps keys in git-ignored "
         "files, server credentials only in the Functions runtime"],
    ],
    [55 * mm, W - 40 * mm - 55 * mm]))
E.append(Paragraph(
    "Privacy: only necessary data is collected. Students have no phone "
    "numbers in the system; bus location exists only during an active trip "
    "and is deleted afterwards; student devices never share their own "
    "location — only the driver's phone publishes GPS, with a visible "
    "notification.", S["body2"]))

# ── 7. Notifications ─────────────────────────────────────────────────
E.append(PageBreak())
E.append(Paragraph("7. Notifications", S["h1"]))
E.append(table(
    ["Notification", "Trigger", "Audience"],
    [
        ["Trip Started", "Driver starts a trip", "Students of that bus"],
        ["Bus Approaching", "Bus within ~800 m of a stop (server geofence)",
         "Students assigned to that stop"],
        ["Bus Reached Stop", "Bus within ~120 m of a stop",
         "Students assigned to that stop"],
        ["Bus Reached School", "Bus arrives at school on a pickup trip",
         "Students of that bus"],
        ["Tracking Unavailable", "No GPS signal for 15 min (auto-close)",
         "Students of that bus"],
        ["School Announcement", "Sent by admin", "Everyone, or one bus"],
    ],
    [40 * mm, 68 * mm, W - 40 * mm - 108 * mm]))

# ── 8. Setup ─────────────────────────────────────────────────────────
E.append(Paragraph("8. What Must Be Configured (no fake keys ship)", S["h1"]))
E.extend(bullets([
    "<b>Firebase project</b> — create it, enable Email/Password auth, "
    "Firestore, Realtime Database, FCM; run <font face='Courier'>flutterfire "
    "configure</font> to generate the real config files.",
    "<b>Deploy the backend</b> — <font face='Courier'>firebase deploy --only "
    "firestore:rules,firestore:indexes,database,functions</font>. The rules "
    "ARE the access control; never launch without them.",
    "<b>First admin account</b> — one-time bootstrap script with the Admin "
    "SDK (documented in docs/SETUP.md); every later account is created "
    "inside the app.",
    "<b>Google Maps keys</b> — one Android-restricted and one "
    "iOS-restricted key, kept in git-ignored files "
    "(android/local.properties and ios/Runner/Secrets.plist).",
    "<b>iOS push</b> — upload an APNs auth key (.p8) in Firebase Console; "
    "enable Push Notifications + Background Modes in Xcode.",
    "<b>Android release signing</b> — generate a keystore and wire "
    "key.properties before publishing.",
]))
E.append(Paragraph("Runtime permissions handled in-app", S["h3"]))
E.extend(bullets([
    "Location (driver): requested at Start Trip with clear guidance if "
    "denied or GPS is off.",
    "Notifications (all roles): requested on first run; Settings screen "
    "offers a fix-it path if declined.",
]))

# ── 9. Quality ───────────────────────────────────────────────────────
E.append(Paragraph("9. Quality &amp; Edge Cases", S["h1"]))
E.append(table(
    ["Situation", "App behaviour"],
    [
        ["No internet", "Offline banner; cached data marked as possibly out of date"],
        ["GPS disabled / permission denied", "Clear driver guidance with a "
         "one-tap path to system settings"],
        ["Driver phone dies mid-trip", "Server auto-closes the trip in 15 min "
         "and notifies students honestly"],
        ["Bus has no active trip", "\u201cNo trip in progress — tracking starts when "
         "the driver begins the trip\u201d"],
        ["Expired / revoked session", "Automatic bounce to login"],
        ["Unauthorized access attempt", "Blocked by backend rules regardless "
         "of what the client does"],
        ["Server/database failure", "Friendly error views with retry buttons"],
    ],
    [62 * mm, W - 40 * mm - 62 * mm]))
E.append(Spacer(1, 8))
E.append(callout(
    "<b>Verified:</b> flutter analyze — 0 issues &nbsp;·&nbsp; 15/15 unit "
    "tests passing (including tests that the app can never show stale GPS "
    "as live and never fabricates an ETA) &nbsp;·&nbsp; Cloud Functions "
    "compile clean under strict TypeScript.",
    bg=ACCENT_SOFT, border=ACCENT))
E.append(Spacer(1, 10))
E.append(Paragraph(
    "Full technical references in the project: docs/ARCHITECTURE.md · "
    "docs/DATA_MODEL.md · docs/SECURITY.md · docs/SETUP.md", S["small"]))

doc.build(E)
print("PDF written:", OUT)
