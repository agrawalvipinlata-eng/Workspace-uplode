#!/usr/bin/env python3
"""Never Miss Bus v1.3.0 — Complete Source Code PDF:
cover + app status + code structure tree + all files in sections."""
import os

from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.lib.colors import HexColor, white
from reportlab.lib.styles import ParagraphStyle
from reportlab.platypus import (
    BaseDocTemplate, PageTemplate, Frame, Paragraph, Spacer, Table,
    TableStyle, PageBreak, NextPageTemplate, Preformatted,
)

ROOT = "/home/user/never_miss_bus"
OUT = os.path.join(ROOT, "docs", "Never_Miss_Bus_Complete_Code_v1.3.0.pdf")

PRIMARY = HexColor("#2557D6")
PRIMARY_DARK = HexColor("#1A3FA0")
PRIMARY_SOFT = HexColor("#E8EEFC")
ACCENT = HexColor("#FFB300")
SUCCESS = HexColor("#1E8E3E")
SUCCESS_SOFT = HexColor("#E2F3E7")
TEXT = HexColor("#17233B")
TEXT2 = HexColor("#5A6779")
DIVIDER = HexColor("#E4E9F2")
BG = HexColor("#F6F8FC")
CODE_BG = HexColor("#F8F9FB")

W, H = A4
CW = W - 28 * mm

SECTIONS = [
    ("1. Project Configuration", "Dependencies, lint rules, entry point, Firebase config.", [
        "pubspec.yaml", "analysis_options.yaml",
        "lib/main.dart", "lib/app.dart", "lib/firebase_options.dart",
    ]),
    ("2. Design System & Core", "Colors, typography, theme, constants (classes, "
     "student login-IDs), validators, formatters, Result type.", [
        "lib/core/theme/nmb_colors.dart", "lib/core/theme/nmb_typography.dart",
        "lib/core/theme/nmb_theme.dart", "lib/core/constants/enums.dart",
        "lib/core/constants/nmb_constants.dart", "lib/core/utils/validators.dart",
        "lib/core/utils/formatters.dart", "lib/core/utils/result.dart",
    ]),
    ("3. Reusable Widgets", "Cards, status pills, dialogs, states + NEW: "
     "YouTube-style shimmer skeleton loading.", [
        "lib/core/widgets/nmb_card.dart", "lib/core/widgets/status_pill.dart",
        "lib/core/widgets/state_views.dart", "lib/core/widgets/nmb_dialogs.dart",
        "lib/core/widgets/responsive_scaffold_body.dart",
        "lib/core/widgets/skeleton.dart",
    ]),
    ("4. Data Models", "Pure-Dart data classes incl. rollNumber & activeDevice "
     "(single-device login).", [
        "lib/models/geo_point_data.dart", "lib/models/app_user.dart",
        "lib/models/bus.dart", "lib/models/bus_route.dart",
        "lib/models/bus_stop.dart", "lib/models/trip.dart",
        "lib/models/live_location.dart", "lib/models/app_notification.dart",
        "lib/models/audit_log.dart",
    ]),
    ("5. Services", "Firebase gateways: auth (roll-number generations), "
     "Firestore, admin ops (password reset, force logout), live GPS, ETA, "
     "notifications, device sessions.", [
        "lib/services/auth_service.dart", "lib/services/firestore_service.dart",
        "lib/services/admin_service.dart", "lib/services/live_location_service.dart",
        "lib/services/driver_trip_service.dart", "lib/services/eta_service.dart",
        "lib/services/notification_service.dart",
        "lib/services/connectivity_service.dart",
        "lib/services/device_session_service.dart",
    ]),
    ("6. State & Navigation", "Riverpod providers (error-quiet streams) + "
     "role-fenced go_router.", [
        "lib/providers/app_providers.dart", "lib/providers/data_providers.dart",
        "lib/router/app_router.dart",
    ]),
    ("7. Auth Screens", "Animated splash (bus drive-in) + premium login "
     "(curved header, floating card, animated toggle).", [
        "lib/features/auth/splash_screen.dart",
        "lib/features/auth/login_screen.dart",
    ]),
    ("8. Student App", "5-tab shell, rich home (blue header, quick actions, "
     "route progress), drawer, map, stops, alerts, profile, settings.", [
        "lib/features/student/student_shell.dart",
        "lib/features/student/screens/student_home_screen.dart",
        "lib/features/student/widgets/student_drawer.dart",
        "lib/features/student/widgets/tracking_status_card.dart",
        "lib/features/student/screens/student_map_screen.dart",
        "lib/features/shared/bus_marker_widget.dart",
        "lib/features/student/screens/student_bus_details_screen.dart",
        "lib/features/student/screens/student_stops_screen.dart",
        "lib/features/student/screens/student_alerts_screen.dart",
        "lib/features/student/screens/student_profile_screen.dart",
        "lib/features/student/screens/student_settings_screen.dart",
    ]),
    ("9. Driver App", "Shell, one-tap trip dashboard, route, profile.", [
        "lib/features/driver/driver_shell.dart",
        "lib/features/driver/screens/driver_home_screen.dart",
        "lib/features/driver/screens/driver_route_screen.dart",
        "lib/features/driver/screens/driver_profile_screen.dart",
    ]),
    ("10. Admin App", "Shell + dashboard (stat cards, live banner) + all "
     "management screens incl. trip history & login-status.", [
        "lib/features/admin/admin_shell.dart",
        "lib/features/admin/screens/admin_dashboard_screen.dart",
        "lib/features/admin/widgets/user_editor_sheet.dart",
        "lib/features/admin/screens/admin_students_screen.dart",
        "lib/features/admin/screens/admin_drivers_screen.dart",
        "lib/features/admin/screens/admin_buses_screen.dart",
        "lib/features/admin/screens/admin_routes_stops_screen.dart",
        "lib/features/admin/screens/admin_monitoring_screen.dart",
        "lib/features/admin/screens/admin_notifications_screen.dart",
        "lib/features/admin/screens/admin_trip_history_screen.dart",
        "lib/features/admin/screens/admin_audit_logs_screen.dart",
        "lib/features/admin/screens/admin_settings_screen.dart",
    ]),
    ("11. Firebase Backend — Security Rules", "Free-mode rules: role checks "
     "from users doc, single-device mirror, live-location fencing.", [
        "firebase/firestore.rules", "firebase/database.rules.json",
        "firebase/firestore.indexes.json", "firebase/firebase.json",
    ]),
    ("12. Platform Config", "Android manifest/gradle (desugaring, blue native "
     "splash) + iOS AppDelegate.", [
        "android/app/src/main/AndroidManifest.xml",
        "android/app/build.gradle",
        "android/app/src/main/res/drawable/launch_background.xml",
        "ios/Runner/AppDelegate.swift",
    ]),
    ("13. Tests", "Unit tests: validators, freshness honesty, ETA guardrails.", [
        "test/unit_test.dart", "test/widget_test.dart",
    ]),
]

def st(name, **kw):
    base = dict(fontName="Helvetica", fontSize=10.5, leading=15,
                textColor=TEXT, spaceAfter=6)
    base.update(kw)
    return ParagraphStyle(name, **base)

S = {
    "h1": st("h1", fontName="Helvetica-Bold", fontSize=20, leading=24,
             textColor=PRIMARY_DARK, spaceBefore=4, spaceAfter=8),
    "desc": st("desc", fontSize=10.5, leading=14.5, textColor=TEXT2),
    "cellh": st("cellh", fontName="Helvetica-Bold", fontSize=9.5,
                leading=12.5, textColor=white, spaceAfter=0),
    "cell": st("cell", fontSize=9.5, leading=12.5, spaceAfter=0),
    "code": ParagraphStyle("code", fontName="Courier", fontSize=6.8,
                           leading=8.6, textColor=TEXT),
    "tree": ParagraphStyle("tree", fontName="Courier", fontSize=8.2,
                           leading=10.6, textColor=TEXT),
}

def cover(canvas, doc):
    canvas.saveState()
    canvas.setFillColor(PRIMARY_DARK)
    canvas.rect(0, 0, W, H, stroke=0, fill=1)
    canvas.setFillColor(PRIMARY)
    canvas.rect(0, H - 85 * mm, W, 85 * mm, stroke=0, fill=1)
    cx, cy = W / 2, H - 58 * mm
    canvas.setFillColor(white)
    canvas.circle(cx, cy, 17 * mm, stroke=0, fill=1)
    canvas.setFillColor(ACCENT)
    canvas.roundRect(cx - 11 * mm, cy - 6.5 * mm, 22 * mm, 12 * mm,
                     2.5 * mm, stroke=0, fill=1)
    canvas.setFillColor(HexColor("#E3F2FD"))
    for i in range(3):
        canvas.roundRect(cx - 8.6 * mm + i * 6.3 * mm, cy + 0.4 * mm,
                         4.6 * mm, 3.6 * mm, 0.8 * mm, stroke=0, fill=1)
    canvas.setFillColor(HexColor("#37474F"))
    canvas.circle(cx - 6 * mm, cy - 7 * mm, 2 * mm, stroke=0, fill=1)
    canvas.circle(cx + 6 * mm, cy - 7 * mm, 2 * mm, stroke=0, fill=1)

    canvas.setFillColor(white)
    canvas.setFont("Helvetica-Bold", 26)
    canvas.drawCentredString(W / 2, H - 103 * mm, "NEVER MISS BUS")
    canvas.setFont("Helvetica-Bold", 15)
    canvas.setFillColor(ACCENT)
    canvas.drawCentredString(W / 2, H - 114 * mm,
                             "COMPLETE SOURCE CODE + APP STATUS")
    canvas.setFont("Helvetica", 12)
    canvas.setFillColor(HexColor("#CFE0FF"))
    canvas.drawCentredString(W / 2, H - 125 * mm,
                             "SRBS International School  ·  Version 1.3.0")
    canvas.setFont("Helvetica", 10.5)
    lines = [
        "Flutter (Dart)  ·  Firebase  ·  Security Rules  ·  Android + iOS",
        "13 sections  ·  67 Dart files  ·  11,000+ lines of code",
        "flutter analyze: 0 issues  ·  15/15 tests passing",
        "",
        "August 2026",
    ]
    y = H - 150 * mm
    for ln in lines:
        canvas.drawCentredString(W / 2, y, ln)
        y -= 7 * mm
    canvas.restoreState()

def page(canvas, doc):
    canvas.saveState()
    canvas.setFillColor(PRIMARY)
    canvas.rect(0, H - 11 * mm, W, 11 * mm, stroke=0, fill=1)
    canvas.setFillColor(white)
    canvas.setFont("Helvetica-Bold", 8.5)
    canvas.drawString(14 * mm, H - 7.5 * mm,
                      "NEVER MISS BUS v1.3.0  ·  Source Code")
    canvas.drawRightString(W - 14 * mm, H - 7.5 * mm,
                           "SRBS International School")
    canvas.setFillColor(TEXT2)
    canvas.setFont("Helvetica", 8)
    canvas.drawCentredString(W / 2, 7 * mm, f"Page {doc.page - 1}")
    canvas.restoreState()

doc = BaseDocTemplate(OUT, pagesize=A4,
                      leftMargin=14 * mm, rightMargin=14 * mm,
                      topMargin=17 * mm, bottomMargin=13 * mm,
                      title="Never Miss Bus v1.3.0 — Complete Source Code",
                      author="SRBS International School")
frame = Frame(14 * mm, 12 * mm, CW, H - 30 * mm, id="f")
doc.addPageTemplates([
    PageTemplate(id="cover", frames=[Frame(0, 0, W, H)], onPage=cover),
    PageTemplate(id="page", frames=[frame], onPage=page),
])

E = [Spacer(1, 1), NextPageTemplate("page"), PageBreak()]

# ═══ PART A: APP STATUS ═══
E.append(Paragraph("Part A — App Status (Current)", S["h1"]))
status_rows = [
    ["Version", "1.3.0 (build 5) — latest APK: NeverMissBus-v1.3.0.apk (26.7 MB)"],
    ["Platforms", "Android: APK ready & installed-tested. iOS: code ready, "
     "needs Apple Developer account + Mac build."],
    ["Backend", "Firebase project 'never-miss-bus-c67b5' — LIVE. Firestore + "
     "Realtime DB (Singapore) + Auth (Email/Password). FREE Spark plan, no card."],
    ["Security rules", "Deployed. Role checks server-side; student sees only "
     "own bus; tamper-proof audit logs; single-device mirror in RTDB."],
    ["Admin account", "Working (agrawalvipinlata@gmail.com). Creates all other "
     "accounts inside the app."],
    ["Login system", "Students: Class + Section + Roll + Password (generation "
     "system for password resets). Staff: email + password."],
    ["Device security", "Single-device login (WhatsApp-style kick-out), admin "
     "sees LOGGED IN status, Force Logout button."],
    ["UI", "v1.1.1 redesign: blue gradient headers, drawer, 5-tab nav. "
     "v1.3.0: animated splash (bus drive-in), YouTube-style shimmer "
     "skeletons, premium login card."],
    ["Stability", "v1.2.1 hardening: startup-only error screen, 16 streams "
     "error-quiet, ref-after-dispose fixed in all logout flows."],
    ["Quality", "flutter analyze: 0 issues · 15/15 unit tests passing"],
    ["Maps", "OpenStreetMap (flutter_map) — free, no API key, no billing."],
    ["Known limits (free plan)", "No push notifications when app is closed "
     "(in-app inbox works); no SMS OTP; iOS build pending."],
]
t = Table([[Paragraph(f"<b>{a}</b>", S["cell"]), Paragraph(b, S["cell"])]
           for a, b in status_rows],
          colWidths=[38 * mm, CW - 38 * mm])
t.setStyle(TableStyle([
    ("BACKGROUND", (0, 0), (0, -1), PRIMARY_SOFT),
    ("GRID", (0, 0), (-1, -1), 0.5, DIVIDER),
    ("VALIGN", (0, 0), (-1, -1), "TOP"),
    ("TOPPADDING", (0, 0), (-1, -1), 5),
    ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
    ("LEFTPADDING", (0, 0), (-1, -1), 8),
    ("RIGHTPADDING", (0, 0), (-1, -1), 8),
]))
E.append(t)
E.append(Spacer(1, 8))

# Version journey
E.append(Paragraph("Version Journey", ParagraphStyle(
    "h2", fontName="Helvetica-Bold", fontSize=13, leading=16,
    textColor=PRIMARY, spaceBefore=8, spaceAfter=5)))
vj = [
    ("v1.0", "Base app, Firebase connected, first APK"),
    ("v1.4–v1.7", "Class-wise admin, roll-number login, trip history, "
     "password reset, stops reorder, back-button fix, new logo"),
    ("v1.1.1", "Premium UI redesign (mock-based): headers, drawer, 5 tabs"),
    ("v1.2.0", "Single-device login security + full English + login status"),
    ("v1.2.1", "Stability: root-cause fixes for recurring error screens"),
    ("v1.3.0", "Animated splash, shimmer skeleton loading, premium login"),
]
t2 = Table([[Paragraph(f"<b>{a}</b>", S["cell"]), Paragraph(b, S["cell"])]
            for a, b in vj], colWidths=[26 * mm, CW - 26 * mm])
t2.setStyle(TableStyle([
    ("BACKGROUND", (0, 0), (0, -1), SUCCESS_SOFT),
    ("GRID", (0, 0), (-1, -1), 0.5, DIVIDER),
    ("TOPPADDING", (0, 0), (-1, -1), 4),
    ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
    ("LEFTPADDING", (0, 0), (-1, -1), 8),
]))
E.append(t2)

# ═══ PART B: CODE STRUCTURE ═══
E.append(PageBreak())
E.append(Paragraph("Part B — Code Structure (App Architecture)", S["h1"]))
E.append(Paragraph(
    "Layered architecture: UI (features) → State (providers) → Services "
    "(Firebase gateways) → Models (pure Dart). UI never touches Firebase "
    "directly. Security is enforced by backend rules, not the app.",
    S["desc"]))
E.append(Spacer(1, 4))

tree = """never_miss_bus/
├── pubspec.yaml                     # dependencies (Flutter, Firebase, flutter_map…)
├── lib/
│   ├── main.dart                    # startup + crash-safe error handling
│   ├── app.dart                     # root widget, single-device login guard
│   ├── firebase_options.dart        # Firebase project config (never-miss-bus-c67b5)
│   ├── core/
│   │   ├── theme/                   # colors, typography, ThemeData
│   │   ├── constants/               # enums, classes list, StudentLoginId
│   │   ├── utils/                   # validators, formatters, Result type
│   │   └── widgets/                 # NmbCard, StatusPill, dialogs, states,
│   │                                #   skeleton.dart (shimmer loading)
│   ├── models/                      # 9 pure-Dart data classes
│   ├── services/                    # 9 services — the ONLY Firebase layer
│   │   ├── auth_service.dart        #   login/session (roll generations)
│   │   ├── firestore_service.dart   #   all Firestore reads/writes
│   │   ├── admin_service.dart       #   provisioning, reset, force-logout
│   │   ├── live_location_service.dart  # RTDB GPS node per bus
│   │   ├── driver_trip_service.dart #   trip lifecycle + GPS stream
│   │   ├── eta_service.dart         #   honest ETA calculation
│   │   ├── notification_service.dart#   FCM tokens + local notifications
│   │   ├── connectivity_service.dart#   online/offline stream
│   │   └── device_session_service.dart # single-device IDs
│   ├── providers/                   # Riverpod graph (error-quiet streams)
│   ├── router/                      # go_router with role fencing
│   └── features/
│       ├── auth/                    # animated splash + premium login
│       ├── student/                 # shell(5 tabs), home, drawer, map,
│       │                            #   stops, alerts, profile, settings
│       ├── driver/                  # shell, trip dashboard, route, profile
│       ├── admin/                   # shell(drawer), dashboard, students,
│       │                            #   drivers, buses, routes/stops,
│       │                            #   monitoring, notifications, trips,
│       │                            #   audit logs, settings
│       └── shared/                  # BusMarkerWidget (painted bus)
├── firebase/
│   ├── firestore.rules              # role-based access (free mode)
│   ├── database.rules.json          # live-location + access mirror rules
│   └── firestore.indexes.json       # composite indexes
├── android/                         # manifest, gradle (desugaring), splash
├── ios/                             # Info.plist, AppDelegate
└── test/                            # 15 unit tests"""
E.append(Preformatted(tree, S["tree"]))
E.append(Spacer(1, 8))
E.append(Paragraph(
    "<b>Data flow (live tracking):</b> Driver GPS → RTDB /liveLocations/"
    "{busId} (server-timestamped) → student stream (rules-fenced to own "
    "bus) → map marker + freshness logic (LIVE / stale / unavailable).",
    S["desc"]))
E.append(Paragraph(
    "<b>Single-device flow:</b> login → device ID saved in settings."
    "activeDevice → other phones watching profile see a different ID → "
    "auto sign-out with message. Admin sets id=REVOKED for Force Logout.",
    S["desc"]))

# ═══ PART C: SOURCE CODE ═══
MAX_W = 96
CHUNK = 58

def wrap_line(line):
    line = line.replace("\t", "    ").rstrip("\n")
    if len(line) <= MAX_W:
        return [line]
    out = []
    while len(line) > MAX_W:
        out.append(line[:MAX_W])
        line = "\u21aa " + line[MAX_W:]
    out.append(line)
    return out

def file_header(path, n):
    t = Table([[Paragraph(f"<font face='Courier-Bold'>{path}</font>",
                ParagraphStyle("fh", fontName="Courier-Bold", fontSize=9,
                               leading=12, textColor=white)),
                Paragraph(f"{n} lines",
                ParagraphStyle("fh2", fontSize=8.5, leading=12,
                               textColor=HexColor('#CFE0FF'), alignment=2))]],
              colWidths=[CW - 26 * mm, 26 * mm])
    t.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), PRIMARY_DARK),
        ("TOPPADDING", (0, 0), (-1, -1), 5),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
        ("LEFTPADDING", (0, 0), (-1, -1), 8),
        ("RIGHTPADDING", (0, 0), (-1, -1), 8),
    ]))
    return t

def code_block(lines):
    pre = Preformatted("\n".join(lines), S["code"])
    box = Table([[pre]], colWidths=[CW])
    box.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), CODE_BG),
        ("BOX", (0, 0), (-1, -1), 0.5, DIVIDER),
        ("TOPPADDING", (0, 0), (-1, -1), 5),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
        ("LEFTPADDING", (0, 0), (-1, -1), 7),
        ("RIGHTPADDING", (0, 0), (-1, -1), 7),
    ]))
    return box

E.append(PageBreak())
E.append(Paragraph("Part C — Complete Source Code", S["h1"]))

# TOC
toc = []
for title, desc, files in SECTIONS:
    n = 0
    for f in files:
        p = os.path.join(ROOT, f)
        if os.path.exists(p):
            with open(p, encoding="utf-8", errors="replace") as fh:
                n += sum(1 for _ in fh)
    toc.append([title, f"{len(files)} files", f"{n} lines"])
tt = Table([[Paragraph("<b>Section</b>", S["cellh"]),
             Paragraph("<b>Files</b>", S["cellh"]),
             Paragraph("<b>Lines</b>", S["cellh"])]] +
           [[Paragraph(a, S["cell"]), Paragraph(b, S["cell"]),
             Paragraph(c, S["cell"])] for a, b, c in toc],
           colWidths=[CW - 55 * mm, 25 * mm, 30 * mm], repeatRows=1)
style = [("BACKGROUND", (0, 0), (-1, 0), PRIMARY),
         ("GRID", (0, 0), (-1, -1), 0.5, DIVIDER),
         ("TOPPADDING", (0, 0), (-1, -1), 4),
         ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
         ("LEFTPADDING", (0, 0), (-1, -1), 7)]
for i in range(1, len(toc) + 1):
    if i % 2 == 0:
        style.append(("BACKGROUND", (0, i), (-1, i), BG))
tt.setStyle(TableStyle(style))
E.append(tt)

total_files = 0
total_lines = 0
for title, desc, files in SECTIONS:
    E.append(PageBreak())
    band = Table([[Paragraph(title, ParagraphStyle(
        "sec", fontName="Helvetica-Bold", fontSize=16, leading=20,
        textColor=white))]], colWidths=[CW])
    band.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), PRIMARY),
        ("TOPPADDING", (0, 0), (-1, -1), 9),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 9),
        ("LEFTPADDING", (0, 0), (-1, -1), 10),
    ]))
    E.append(band)
    E.append(Spacer(1, 5))
    E.append(Paragraph(desc, S["desc"]))
    E.append(Spacer(1, 3))

    for f in files:
        p = os.path.join(ROOT, f)
        if not os.path.exists(p):
            continue
        with open(p, encoding="utf-8", errors="replace") as fh:
            raw = fh.readlines()
        total_files += 1
        total_lines += len(raw)
        rendered = []
        for idx, line in enumerate(raw, 1):
            pieces = wrap_line(line)
            rendered.append(f"{idx:>4} \u2502 {pieces[0]}")
            for cont in pieces[1:]:
                rendered.append(f"     \u2502 {cont}")
        E.append(Spacer(1, 8))
        E.append(file_header(f, len(raw)))
        for i in range(0, len(rendered), CHUNK):
            E.append(code_block(rendered[i:i + CHUNK]))

doc.build(E)
print(f"PDF: {OUT}")
print(f"files={total_files} lines={total_lines} "
      f"size={os.path.getsize(OUT)/1024/1024:.1f}MB")
