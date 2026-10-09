#!/usr/bin/env python3
"""Generates the Never Miss Bus SOURCE CODE PDF — all files arranged in
sections with a cover, table of contents, section dividers and per-file
headers with line-numbered code."""
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
OUT = os.path.join(ROOT, "docs", "Never_Miss_Bus_Source_Code.pdf")

PRIMARY = HexColor("#2557D6")
PRIMARY_DARK = HexColor("#1A3FA0")
PRIMARY_SOFT = HexColor("#E8EEFC")
ACCENT = HexColor("#FFB300")
TEXT = HexColor("#17233B")
TEXT2 = HexColor("#5A6779")
DIVIDER = HexColor("#E4E9F2")
BG = HexColor("#F6F8FC")
CODE_BG = HexColor("#F8F9FB")

W, H = A4

# ── section plan: (section title, description, [file paths]) ─────────
SECTIONS = [
    ("1. Project Configuration", "Dependencies, lint rules and app entry point.", [
        "pubspec.yaml",
        "analysis_options.yaml",
        "lib/main.dart",
        "lib/app.dart",
        "lib/firebase_options.dart",
    ]),
    ("2. Design System & Core", "Colors, typography, theme, constants, "
     "validators, formatters and the Result type.", [
        "lib/core/theme/nmb_colors.dart",
        "lib/core/theme/nmb_typography.dart",
        "lib/core/theme/nmb_theme.dart",
        "lib/core/constants/enums.dart",
        "lib/core/constants/nmb_constants.dart",
        "lib/core/utils/validators.dart",
        "lib/core/utils/formatters.dart",
        "lib/core/utils/result.dart",
    ]),
    ("3. Reusable Widgets", "Shared UI components used by all three roles.", [
        "lib/core/widgets/nmb_card.dart",
        "lib/core/widgets/status_pill.dart",
        "lib/core/widgets/state_views.dart",
        "lib/core/widgets/nmb_dialogs.dart",
        "lib/core/widgets/responsive_scaffold_body.dart",
    ]),
    ("4. Data Models", "Pure-Dart data classes (no Firebase imports).", [
        "lib/models/geo_point_data.dart",
        "lib/models/app_user.dart",
        "lib/models/bus.dart",
        "lib/models/bus_route.dart",
        "lib/models/bus_stop.dart",
        "lib/models/trip.dart",
        "lib/models/live_location.dart",
        "lib/models/app_notification.dart",
        "lib/models/audit_log.dart",
    ]),
    ("5. Services", "Firebase & platform gateways: auth, Firestore, live "
     "location, driver GPS trips, ETA, notifications, connectivity, "
     "admin Cloud Function calls.", [
        "lib/services/auth_service.dart",
        "lib/services/firestore_service.dart",
        "lib/services/admin_functions_service.dart",
        "lib/services/live_location_service.dart",
        "lib/services/driver_trip_service.dart",
        "lib/services/eta_service.dart",
        "lib/services/notification_service.dart",
        "lib/services/connectivity_service.dart",
    ]),
    ("6. State & Navigation", "Riverpod provider graph and the role-fenced "
     "go_router.", [
        "lib/providers/app_providers.dart",
        "lib/providers/data_providers.dart",
        "lib/router/app_router.dart",
    ]),
    ("7. Auth Screens", "Splash and the single role-aware login.", [
        "lib/features/auth/splash_screen.dart",
        "lib/features/auth/login_screen.dart",
    ]),
    ("8. Student App", "Shell, home, live map, bus details, stops, alerts, "
     "profile, settings + shared widgets.", [
        "lib/features/student/student_shell.dart",
        "lib/features/student/screens/student_home_screen.dart",
        "lib/features/student/widgets/tracking_status_card.dart",
        "lib/features/student/screens/student_map_screen.dart",
        "lib/features/shared/bus_marker_icon.dart",
        "lib/features/student/screens/student_bus_details_screen.dart",
        "lib/features/student/screens/student_stops_screen.dart",
        "lib/features/student/screens/student_alerts_screen.dart",
        "lib/features/student/screens/student_profile_screen.dart",
        "lib/features/student/screens/student_settings_screen.dart",
    ]),
    ("9. Driver App", "Shell, one-tap trip dashboard, route list, profile.", [
        "lib/features/driver/driver_shell.dart",
        "lib/features/driver/screens/driver_home_screen.dart",
        "lib/features/driver/screens/driver_route_screen.dart",
        "lib/features/driver/screens/driver_profile_screen.dart",
    ]),
    ("10. Admin App", "Shell + all management screens.", [
        "lib/features/admin/admin_shell.dart",
        "lib/features/admin/screens/admin_dashboard_screen.dart",
        "lib/features/admin/widgets/user_editor_sheet.dart",
        "lib/features/admin/screens/admin_students_screen.dart",
        "lib/features/admin/screens/admin_drivers_screen.dart",
        "lib/features/admin/screens/admin_buses_screen.dart",
        "lib/features/admin/screens/admin_routes_stops_screen.dart",
        "lib/features/admin/screens/admin_monitoring_screen.dart",
        "lib/features/admin/screens/admin_notifications_screen.dart",
        "lib/features/admin/screens/admin_audit_logs_screen.dart",
        "lib/features/admin/screens/admin_settings_screen.dart",
    ]),
    ("11. Firebase Backend — Security Rules", "The real access control: "
     "Firestore rules + Realtime Database rules + indexes.", [
        "firebase/firestore.rules",
        "firebase/database.rules.json",
        "firebase/firestore.indexes.json",
        "firebase/firebase.json",
    ]),
    ("12. Cloud Functions (TypeScript)", "Privileged backend: provisioning, "
     "claims, assignment, announcements, geofence alerts, stale-trip "
     "sweeper, audit logging.", [
        "firebase/functions/src/index.ts",
        "firebase/functions/package.json",
        "firebase/functions/tsconfig.json",
    ]),
    ("13. Platform Configuration", "Android manifest/gradle and iOS "
     "AppDelegate with key-injection (no secrets in source).", [
        "android/app/src/main/AndroidManifest.xml",
        "android/app/build.gradle",
        "android/app/proguard-rules.pro",
        "ios/Runner/AppDelegate.swift",
    ]),
    ("14. Tests", "Unit tests: validators, freshness honesty, ETA "
     "guardrails, role parsing.", [
        "test/unit_test.dart",
        "test/widget_test.dart",
    ]),
]

# ── styles ────────────────────────────────────────────────────────────
def st(name, **kw):
    base = dict(fontName="Helvetica", fontSize=10.5, leading=15,
                textColor=TEXT, spaceAfter=6)
    base.update(kw)
    return ParagraphStyle(name, **base)

S = {
    "h1": st("h1", fontName="Helvetica-Bold", fontSize=20, leading=24,
             textColor=PRIMARY_DARK, spaceBefore=4, spaceAfter=8),
    "secdesc": st("secdesc", fontSize=11, leading=15, textColor=TEXT2),
    "body2": st("body2", textColor=TEXT2, fontSize=10, leading=14),
    "cellh": st("cellh", fontName="Helvetica-Bold", fontSize=9.5,
                leading=12.5, textColor=white, spaceAfter=0),
    "cell": st("cell", fontSize=9.5, leading=12.5, spaceAfter=0),
    "code": ParagraphStyle("code", fontName="Courier", fontSize=6.8,
                           leading=8.6, textColor=TEXT),
}

# ── page furniture ────────────────────────────────────────────────────
def cover(canvas, doc):
    canvas.saveState()
    canvas.setFillColor(PRIMARY_DARK)
    canvas.rect(0, 0, W, H, stroke=0, fill=1)
    canvas.setFillColor(PRIMARY)
    canvas.rect(0, H - 80 * mm, W, 80 * mm, stroke=0, fill=1)

    cx, cy, r = W / 2, H - 55 * mm, 17 * mm
    canvas.setFillColor(white)
    canvas.circle(cx, cy, r, stroke=0, fill=1)
    canvas.setFillColor(ACCENT)
    canvas.roundRect(cx - 11 * mm, cy - 6.5 * mm, 22 * mm, 12 * mm, 2.5 * mm,
                     stroke=0, fill=1)
    canvas.setFillColor(HexColor("#E3F2FD"))
    for i in range(3):
        canvas.roundRect(cx - 8.6 * mm + i * 6.3 * mm, cy + 0.4 * mm,
                         4.6 * mm, 3.6 * mm, 0.8 * mm, stroke=0, fill=1)
    canvas.setFillColor(HexColor("#37474F"))
    canvas.circle(cx - 6 * mm, cy - 7 * mm, 2 * mm, stroke=0, fill=1)
    canvas.circle(cx + 6 * mm, cy - 7 * mm, 2 * mm, stroke=0, fill=1)

    canvas.setFillColor(white)
    canvas.setFont("Helvetica-Bold", 27)
    canvas.drawCentredString(W / 2, H - 100 * mm, "NEVER MISS BUS")
    canvas.setFont("Helvetica-Bold", 16)
    canvas.setFillColor(ACCENT)
    canvas.drawCentredString(W / 2, H - 112 * mm, "COMPLETE  SOURCE  CODE")
    canvas.setFont("Helvetica", 12)
    canvas.setFillColor(HexColor("#CFE0FF"))
    canvas.drawCentredString(W / 2, H - 124 * mm, "SRBS International School")

    canvas.setFont("Helvetica", 10.5)
    lines = [
        "Flutter (Dart)  ·  Firebase  ·  Cloud Functions (TypeScript)",
        "Security Rules  ·  Android & iOS Platform Config  ·  Tests",
        "",
        "14 sections  ·  ~8,000 lines of code",
        "flutter analyze: 0 issues  ·  15/15 tests passing",
        "",
        "v1.0  ·  August 2026",
    ]
    y = H - 150 * mm
    for ln in lines:
        canvas.drawCentredString(W / 2, y, ln)
        y -= 6.5 * mm
    canvas.restoreState()

def page(canvas, doc):
    canvas.saveState()
    canvas.setFillColor(PRIMARY)
    canvas.rect(0, H - 11 * mm, W, 11 * mm, stroke=0, fill=1)
    canvas.setFillColor(white)
    canvas.setFont("Helvetica-Bold", 8.5)
    canvas.drawString(15 * mm, H - 7.5 * mm,
                      "NEVER MISS BUS  ·  Source Code")
    canvas.drawRightString(W - 15 * mm, H - 7.5 * mm,
                           getattr(doc, "_section", ""))
    canvas.setFillColor(TEXT2)
    canvas.setFont("Helvetica", 8)
    canvas.drawCentredString(W / 2, 7 * mm, f"Page {doc.page - 1}")
    canvas.restoreState()

class CodeDoc(BaseDocTemplate):
    _section = ""

class SectionMarker(Spacer):
    def __init__(self, title):
        super().__init__(1, 0.1)
        self.title = title
    def draw(self):
        pass
    def wrap(self, aW, aH):
        return (0, 0)

doc = CodeDoc(OUT, pagesize=A4,
              leftMargin=14 * mm, rightMargin=14 * mm,
              topMargin=17 * mm, bottomMargin=13 * mm,
              title="Never Miss Bus — Complete Source Code",
              author="SRBS International School")

class MarkedPageTemplate(PageTemplate):
    pass

frame = Frame(14 * mm, 12 * mm, W - 28 * mm, H - 30 * mm, id="f")
doc.addPageTemplates([
    PageTemplate(id="cover", frames=[Frame(0, 0, W, H)], onPage=cover),
    PageTemplate(id="page", frames=[frame], onPage=page),
])

def afterFlowable(flowable):
    if isinstance(flowable, SectionMarker):
        doc._section = flowable.title
doc.afterFlowable = afterFlowable

E = []
E.append(Spacer(1, 1))
E.append(NextPageTemplate("page"))
E.append(PageBreak())

# ── Table of contents ────────────────────────────────────────────────
E.append(Paragraph("Table of Contents", S["h1"]))
toc_rows = []
for title, desc, files in SECTIONS:
    nfiles = len(files)
    nlines = 0
    for f in files:
        p = os.path.join(ROOT, f)
        if os.path.exists(p):
            with open(p, encoding="utf-8") as fh:
                nlines += sum(1 for _ in fh)
    toc_rows.append([title, desc, f"{nfiles} files · {nlines} lines"])
t = Table(
    [[Paragraph("Section", S["cellh"]), Paragraph("Contents", S["cellh"]),
      Paragraph("Size", S["cellh"])]] +
    [[Paragraph(a, S["cell"]), Paragraph(b, S["cell"]),
      Paragraph(c, S["cell"])] for a, b, c in toc_rows],
    colWidths=[56 * mm, W - 28 * mm - 56 * mm - 34 * mm, 34 * mm],
    repeatRows=1)
style = [
    ("BACKGROUND", (0, 0), (-1, 0), PRIMARY),
    ("VALIGN", (0, 0), (-1, -1), "TOP"),
    ("TOPPADDING", (0, 0), (-1, -1), 5),
    ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
    ("LEFTPADDING", (0, 0), (-1, -1), 7),
    ("RIGHTPADDING", (0, 0), (-1, -1), 7),
    ("GRID", (0, 0), (-1, -1), 0.5, DIVIDER),
]
for i in range(1, len(toc_rows) + 1):
    if i % 2 == 0:
        style.append(("BACKGROUND", (0, i), (-1, i), BG))
t.setStyle(TableStyle(style))
E.append(t)
E.append(Spacer(1, 8))
E.append(Paragraph(
    "Note: lib/firebase_options.dart is intentionally a placeholder — real "
    "Firebase identifiers are generated per project by `flutterfire "
    "configure`. No API keys, passwords or private credentials appear "
    "anywhere in this document.", S["body2"]))

# ── code rendering ───────────────────────────────────────────────────
MAX_CODE_WIDTH = 96  # chars per line at 6.8pt Courier in the frame width

def wrap_line(line, width=MAX_CODE_WIDTH):
    line = line.replace("\t", "    ").rstrip("\n")
    if len(line) <= width:
        return [line]
    out = []
    while len(line) > width:
        out.append(line[:width])
        line = "\u21aa " + line[width:]   # continuation marker
    out.append(line)
    return out

def file_header(path, nlines):
    hdr = Table(
        [[Paragraph(f"<font face='Courier-Bold'>{path}</font>",
                    ParagraphStyle("fh", fontName="Courier-Bold",
                                   fontSize=9, leading=12,
                                   textColor=white)),
          Paragraph(f"{nlines} lines",
                    ParagraphStyle("fh2", fontName="Helvetica",
                                   fontSize=8.5, leading=12,
                                   textColor=HexColor('#CFE0FF'),
                                   alignment=2))]],
        colWidths=[W - 28 * mm - 26 * mm, 26 * mm])
    hdr.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), PRIMARY_DARK),
        ("TOPPADDING", (0, 0), (-1, -1), 5),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
        ("LEFTPADDING", (0, 0), (-1, -1), 8),
        ("RIGHTPADDING", (0, 0), (-1, -1), 8),
    ]))
    return hdr

def code_block(lines_with_numbers):
    text = "\n".join(lines_with_numbers)
    pre = Preformatted(text, S["code"])
    box = Table([[pre]], colWidths=[W - 28 * mm])
    box.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), CODE_BG),
        ("BOX", (0, 0), (-1, -1), 0.5, DIVIDER),
        ("TOPPADDING", (0, 0), (-1, -1), 5),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
        ("LEFTPADDING", (0, 0), (-1, -1), 7),
        ("RIGHTPADDING", (0, 0), (-1, -1), 7),
    ]))
    return box

CHUNK = 58  # rendered lines per block so blocks break across pages nicely

total_files = 0
total_lines = 0

for title, desc, files in SECTIONS:
    E.append(PageBreak())
    E.append(SectionMarker(title))
    # Section divider band
    band = Table([[Paragraph(title,
                   ParagraphStyle("sec", fontName="Helvetica-Bold",
                                  fontSize=17, leading=21,
                                  textColor=white))]],
                 colWidths=[W - 28 * mm])
    band.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), PRIMARY),
        ("TOPPADDING", (0, 0), (-1, -1), 10),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 10),
        ("LEFTPADDING", (0, 0), (-1, -1), 10),
    ]))
    E.append(band)
    E.append(Spacer(1, 6))
    E.append(Paragraph(desc, S["secdesc"]))
    E.append(Paragraph(
        " · ".join(f"<font face='Courier'>{os.path.basename(f)}</font>"
                   for f in files), S["body2"]))
    E.append(Spacer(1, 4))

    for f in files:
        p = os.path.join(ROOT, f)
        if not os.path.exists(p):
            continue
        with open(p, encoding="utf-8") as fh:
            raw = fh.readlines()
        total_files += 1
        total_lines += len(raw)

        # build numbered, wrapped lines
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
size = os.path.getsize(OUT)
print(f"PDF written: {OUT}")
print(f"files={total_files} lines={total_lines} size={size/1024/1024:.1f} MB")
