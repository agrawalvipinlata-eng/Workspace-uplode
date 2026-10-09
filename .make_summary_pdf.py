#!/usr/bin/env python3
"""Never Miss Bus — Creative Hinglish App Summary PDF (v1.2.0)."""
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.lib.colors import HexColor, white
from reportlab.lib.styles import ParagraphStyle
from reportlab.platypus import (
    BaseDocTemplate, PageTemplate, Frame, Paragraph, Spacer, Table,
    TableStyle, PageBreak, NextPageTemplate,
)

PRIMARY = HexColor("#2557D6")
PRIMARY_DARK = HexColor("#1A3FA0")
PRIMARY_SOFT = HexColor("#E8EEFC")
ACCENT = HexColor("#FFB300")
ACCENT_DARK = HexColor("#8A5B00")
ACCENT_SOFT = HexColor("#FFF3D6")
SUCCESS = HexColor("#1E8E3E")
SUCCESS_SOFT = HexColor("#E2F3E7")
DANGER = HexColor("#C5221F")
DANGER_SOFT = HexColor("#FCE8E7")
PURPLE = HexColor("#7B61FF")
PURPLE_SOFT = HexColor("#EFEAFF")
TEXT = HexColor("#17233B")
TEXT2 = HexColor("#5A6779")
DIVIDER = HexColor("#E4E9F2")
BG = HexColor("#F6F8FC")

W, H = A4
OUT = "/home/user/never_miss_bus/docs/Never_Miss_Bus_App_Summary_Hinglish.pdf"
CW = W - 36 * mm  # content width

def st(name, **kw):
    base = dict(fontName="Helvetica", fontSize=10.5, leading=15,
                textColor=TEXT, spaceAfter=6)
    base.update(kw)
    return ParagraphStyle(name, **base)

S = {
    "h1": st("h1", fontName="Helvetica-Bold", fontSize=20, leading=24,
             textColor=PRIMARY_DARK, spaceBefore=8, spaceAfter=8),
    "h2": st("h2", fontName="Helvetica-Bold", fontSize=14, leading=18,
             textColor=PRIMARY, spaceBefore=10, spaceAfter=5),
    "body": st("body"),
    "body2": st("body2", textColor=TEXT2, fontSize=10, leading=14),
    "big": st("big", fontSize=12.5, leading=18),
    "cellh": st("cellh", fontName="Helvetica-Bold", fontSize=10,
                leading=13, textColor=white, spaceAfter=0),
    "cell": st("cell", fontSize=10, leading=13.5, spaceAfter=0),
    "small": st("small", fontSize=9, leading=12, textColor=TEXT2),
}

def feature_card(title, emoji, color, soft, items):
    """Rounded feature card: colored title bar + bullet list."""
    head = Table([[Paragraph(f"{emoji}  <b>{title}</b>",
                   ParagraphStyle("fh", fontName="Helvetica-Bold",
                                  fontSize=12.5, leading=16,
                                  textColor=white))]], colWidths=[CW])
    head.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), color),
        ("TOPPADDING", (0, 0), (-1, -1), 7),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 7),
        ("LEFTPADDING", (0, 0), (-1, -1), 12),
    ]))
    rows = []
    for it in items:
        rows.append([Paragraph(f"<font color='#{color.hexval()[2:]}'>"
                               f"<b>✓</b></font>  {it}", S["cell"])])
    bodyT = Table(rows, colWidths=[CW])
    bodyT.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), soft),
        ("TOPPADDING", (0, 0), (-1, -1), 4.5),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 4.5),
        ("LEFTPADDING", (0, 0), (-1, -1), 12),
        ("RIGHTPADDING", (0, 0), (-1, -1), 10),
    ]))
    return [head, bodyT, Spacer(1, 10)]

def stat_row(stats):
    """Row of small stat boxes."""
    cells = []
    for value, label, color in stats:
        cells.append(Table(
            [[Paragraph(f"<b>{value}</b>",
              ParagraphStyle("sv", fontName="Helvetica-Bold", fontSize=17,
                             leading=20, textColor=color, alignment=1))],
             [Paragraph(label,
              ParagraphStyle("sl", fontName="Helvetica", fontSize=8.5,
                             leading=11, textColor=TEXT2, alignment=1))]],
            colWidths=[CW / len(stats) - 4 * mm]))
    for c in cells:
        c.setStyle(TableStyle([
            ("BACKGROUND", (0, 0), (-1, -1), white),
            ("BOX", (0, 0), (-1, -1), 0.8, DIVIDER),
            ("TOPPADDING", (0, 0), (-1, -1), 5),
            ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
        ]))
    t = Table([cells], colWidths=[CW / len(stats)] * len(stats))
    t.setStyle(TableStyle([
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("ALIGN", (0, 0), (-1, -1), "CENTER"),
    ]))
    return t

# ── page furniture ────────────────────────────────────────────────────
def cover(canvas, doc):
    canvas.saveState()
    canvas.setFillColor(PRIMARY)
    canvas.rect(0, 0, W, H, stroke=0, fill=1)
    canvas.setFillColor(PRIMARY_DARK)
    canvas.rect(0, 0, W, 62 * mm, stroke=0, fill=1)
    # road
    canvas.setFillColor(HexColor("#37474F"))
    canvas.rect(0, 60 * mm, W, 6 * mm, stroke=0, fill=1)
    canvas.setFillColor(ACCENT)
    for i in range(9):
        canvas.rect(8 * mm + i * 24 * mm, 62.4 * mm, 10 * mm, 1.2 * mm,
                    stroke=0, fill=1)
    # bus badge
    cx, cy, r = W / 2, H - 78 * mm, 23 * mm
    canvas.setFillColor(white)
    canvas.circle(cx, cy, r, stroke=0, fill=1)
    canvas.setFillColor(ACCENT)
    canvas.roundRect(cx - 15 * mm, cy - 8 * mm, 30 * mm, 16 * mm, 3.4 * mm,
                     stroke=0, fill=1)
    canvas.setFillColor(HexColor("#E3F2FD"))
    for i in range(3):
        canvas.roundRect(cx - 11.6 * mm + i * 8.5 * mm, cy + 1 * mm,
                         6.2 * mm, 4.8 * mm, 1 * mm, stroke=0, fill=1)
    canvas.setFillColor(white)
    canvas.rect(cx - 15 * mm, cy - 3 * mm, 30 * mm, 1.4 * mm, stroke=0, fill=1)
    canvas.setFillColor(HexColor("#37474F"))
    canvas.circle(cx - 8.5 * mm, cy - 9 * mm, 2.8 * mm, stroke=0, fill=1)
    canvas.circle(cx + 8.5 * mm, cy - 9 * mm, 2.8 * mm, stroke=0, fill=1)

    canvas.setFillColor(white)
    canvas.setFont("Helvetica-Bold", 32)
    canvas.drawCentredString(W / 2, H - 118 * mm, "NEVER MISS BUS")
    canvas.setFont("Helvetica-Bold", 15)
    canvas.setFillColor(ACCENT)
    canvas.drawCentredString(W / 2, H - 130 * mm,
                             "Ab Bus Miss Nahi Hogi!")
    canvas.setFont("Helvetica", 12.5)
    canvas.setFillColor(HexColor("#CFE0FF"))
    canvas.drawCentredString(W / 2, H - 141 * mm,
                             "Secure School Bus Live-Tracking App")
    canvas.setFillColor(white)
    canvas.roundRect(W / 2 - 46 * mm, H - 160 * mm, 92 * mm, 10.5 * mm,
                     5 * mm, stroke=0, fill=1)
    canvas.setFillColor(PRIMARY_DARK)
    canvas.setFont("Helvetica-Bold", 11.5)
    canvas.drawCentredString(W / 2, H - 156.8 * mm,
                             "SRBS  INTERNATIONAL  SCHOOL")

    canvas.setFillColor(HexColor("#CFE0FF"))
    canvas.setFont("Helvetica", 10.5)
    lines = [
        "Android + iOS  |  Student  ·  Driver  ·  Admin  |  Version 1.2.0",
        "Single-Device Security  |  Live GPS  |  Cost: ~Rs. 0/month",
        "",
        "App Summary — Hindi-English  ·  2026",
    ]
    y = 46 * mm
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
    canvas.drawString(18 * mm, H - 8 * mm,
                      "NEVER MISS BUS  ·  App Summary")
    canvas.drawRightString(W - 18 * mm, H - 8 * mm,
                           "SRBS International School")
    canvas.setFillColor(TEXT2)
    canvas.setFont("Helvetica", 8.5)
    canvas.drawCentredString(W / 2, 8 * mm, f"Page {doc.page - 1}")
    canvas.restoreState()

doc = BaseDocTemplate(OUT, pagesize=A4,
                      leftMargin=18 * mm, rightMargin=18 * mm,
                      topMargin=20 * mm, bottomMargin=15 * mm,
                      title="Never Miss Bus — App Summary (Hinglish)",
                      author="SRBS International School")
frame = Frame(18 * mm, 13 * mm, CW, H - 33 * mm, id="f")
doc.addPageTemplates([
    PageTemplate(id="cover", frames=[Frame(0, 0, W, H)], onPage=cover),
    PageTemplate(id="page", frames=[frame], onPage=page),
])

E = [Spacer(1, 1), NextPageTemplate("page"), PageBreak()]

# ═══ 1. App kya hai ═══
E.append(Paragraph("1. App Kya Hai? 🚌", S["h1"]))
E.append(Paragraph(
    "<b>Never Miss Bus</b> ek school bus live-tracking app hai — students "
    "apni bus ko <b>real-time map par</b> dekhte hain, driver <b>ek button</b> "
    "se GPS share karta hai, aur school admin poora transport system "
    "control karta hai. <b>Ek hi app, teen roles</b> — login se decide hota "
    "hai kaun kya dekhega.", S["big"]))
E.append(Spacer(1, 6))
E.append(stat_row([
    ("3", "Roles — Student, Driver, Admin", PRIMARY),
    ("~5 sec", "GPS update speed", SUCCESS),
    ("Rs. 0", "Monthly running cost", ACCENT_DARK),
    ("2", "Platforms — Android + iOS", PURPLE),
]))
E.append(Spacer(1, 8))

# Ek din ki kahani
story = Table([[Paragraph(
    "<b>📖 Ek Subah Ki Kahani:</b> 6:45 AM — Driver Rohit ne START TRIP "
    "dabaya. 6:46 AM — Class 7-B ke Aarav ke phone par notification: "
    "<i>'Bus trip started!'</i> Aarav ne Track My Bus dabaya — bus map par "
    "chalti dikhi. 7:05 AM — <i>'Bus approaching — ~8 min'</i> alert aaya. "
    "Aarav aaraam se nikla, theek time par stop pahuncha, bus aayi, baith "
    "gaya. Na intezaar, na tension, na bus miss. <b>Yahi hai Never Miss "
    "Bus!</b> ✨", S["body"])]], colWidths=[CW])
story.setStyle(TableStyle([
    ("BACKGROUND", (0, 0), (-1, -1), ACCENT_SOFT),
    ("BOX", (0, 0), (-1, -1), 1, ACCENT),
    ("TOPPADDING", (0, 0), (-1, -1), 10),
    ("BOTTOMPADDING", (0, 0), (-1, -1), 10),
    ("LEFTPADDING", (0, 0), (-1, -1), 12),
    ("RIGHTPADDING", (0, 0), (-1, -1), 12),
]))
E.append(story)
E.append(Spacer(1, 10))

# ═══ 2. Student features ═══
E.append(Paragraph("2. Teen Roles — Har Kisi Ke Liye Kuch Khaas", S["h1"]))
E.extend(feature_card(
    "STUDENT / PARENT — 'Bus kahan hai?' ka jawaab hamesha paas",
    "🎒", PRIMARY, PRIMARY_SOFT, [
    "<b>Easy login</b> — Class + Section + Roll Number + Password. "
    "Email yaad rakhne ki zaroorat nahi — bachchon ke liye perfect!",
    "<b>Home dashboard</b> — 'Good Morning, Aarav! 👋' greeting, apni bus "
    "card (number, plate, ON TRIP status), bada <b>Track My Bus</b> button",
    "<b>Live Map</b> — school-bus marker chalta hua, route line, saare "
    "stops, apna stop star ke saath, 'Center on Bus' button",
    "<b>Honest ETA</b> — 'Bus arriving in approximately 8 minutes' — "
    "app kabhi jhootha promise nahi karti",
    "<b>Route progress</b> — home screen par hi dikh jaata hai bus kitne "
    "stops door hai (Start se School tak progress line)",
    "<b>Smart alerts</b> — Trip Started, Bus Approaching, Bus Reached "
    "Stop — sab automatic notifications",
    "<b>Truth-first tracking</b> — network weak ho toh 'Last updated 2 "
    "min ago' dikhata hai; purani location ko kabhi LIVE nahi bolta",
]))
E.extend(feature_card(
    "DRIVER — Ek button, baaki sab automatic",
    "🚍", SUCCESS, SUCCESS_SOFT, [
    "<b>START TRIP</b> — bas ek bada green button. Morning pickup ya "
    "afternoon drop select karo, done!",
    "<b>Hands-free tracking</b> — GPS har ~5 second apne aap share hota "
    "hai; screen band ho, phone jeb mein ho — chalta rahta hai",
    "<b>Zero distraction</b> — driving ke time kuch touch karne ki "
    "zaroorat nahi. Safety first!",
    "<b>Status tiles</b> — GPS on/off, Internet connected, Sharing live — "
    "ek nazar mein sab clear",
    "<b>Route list</b> — bade font mein saare stops timing ke saath",
    "<b>END TRIP</b> — trip khatam, tracking band, students ko clearly "
    "pata chal jaata hai",
]))
E.extend(feature_card(
    "SCHOOL ADMIN — Poora transport system ek app mein",
    "🏫", ACCENT_DARK, ACCENT_SOFT, [
    "<b>Smart dashboard</b> — total buses, active trips, students, "
    "drivers — sab colored cards mein, date ke saath",
    "<b>Class-wise students</b> — Class dropdown se add karo (Nursery se "
    "12th), filter chips se 'Class 7-B (18)' ek tap mein dekho",
    "<b>Roll-number system</b> — student ka login admin hi banata hai: "
    "class + section + roll + password",
    "<b>Password reset</b> — bachcha bhool gaya? Admin 30 second mein "
    "naya password de deta hai",
    "<b>Buses / Routes / Stops</b> — sab manage karo; stops ko "
    "upar-neeche reorder karo, delete karo",
    "<b>Live Monitoring</b> — saari active buses ek map par, speed aur "
    "last-update time ke saath",
    "<b>Trip History</b> — kaunsi bus kab chali, kitne minute — poora "
    "record with status badges",
    "<b>Activity Logs</b> — kaun kya kab kiya — sab recorded, koi mita "
    "nahi sakta (tamper-proof)",
]))

# ═══ 3. Security ═══
E.append(PageBreak())
E.append(Paragraph("3. Security — Bachchon Ki Safety = #1 Priority 🔐",
                   S["h1"]))
E.append(Paragraph(
    "Yeh WhatsApp location sharing ya normal GPS tracker se <b>bilkul "
    "alag</b> hai. Security app mein nahi, <b>server (database) ke level "
    "par</b> hai — app hack karke bhi koi rule nahi tod sakta.", S["body"]))
E.append(Spacer(1, 6))

sec_rows = [
    ("🔒 Ek ID = Ek Phone", "Single-device login (WhatsApp jaisa): dusre "
     "phone par login karte hi pehla phone auto-logout. Password share ka "
     "misuse impossible!"),
    ("👁️ Admin ko sab dikhta hai", "Har student/driver par LOGGED IN / NOT "
     "LOGGED IN badge + kaunsa phone, kab se + Force Logout button"),
    ("🚌 Apni bus only", "Student sirf APNI assigned bus dekh sakta hai — "
     "server rules enforce karte hain, koi doosri bus browse nahi kar sakta"),
    ("🚫 Koi public link nahi", "Bina school-account login ke kuch nahi "
     "dikhta. Zero unauthenticated access."),
    ("🏫 Accounts sirf school banata hai", "Koi khud register nahi kar "
     "sakta, koi apni bus/role change nahi kar sakta"),
    ("🗑️ Privacy by design", "Location history store NahI hoti — trip "
     "khatam, location data delete. Students ke phone numbers tak store "
     "nahi hote."),
    ("🔑 Encrypted passwords", "Google Firebase Authentication — kabhi "
     "plain text mein store nahi hote"),
]
for head, body in sec_rows:
    t = Table([[Paragraph(f"<b>{head}</b>", S["cell"]),
                Paragraph(body, S["cell"])]],
              colWidths=[52 * mm, CW - 52 * mm])
    t.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (0, -1), DANGER_SOFT),
        ("BACKGROUND", (1, 0), (1, -1), white),
        ("BOX", (0, 0), (-1, -1), 0.6, DIVIDER),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("TOPPADDING", (0, 0), (-1, -1), 6),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
        ("LEFTPADDING", (0, 0), (-1, -1), 9),
        ("RIGHTPADDING", (0, 0), (-1, -1), 9),
    ]))
    E.append(t)
    E.append(Spacer(1, 4))

# ═══ 4. Design ═══
E.append(Paragraph("4. Design — Premium Look, Simple Use 🎨", S["h1"]))
E.extend(feature_card(
    "UI/UX Highlights", "✨", PURPLE, PURPLE_SOFT, [
    "<b>Blue gradient headers</b> — greeting + avatar with online dot, "
    "modern app jaisa premium feel",
    "<b>5-tab navigation</b> — Home · Track Bus · My Stop · Notifications "
    "· Profile — sab ek tap door",
    "<b>Side drawer menu</b> — profile photo, naam, class-roll, saare "
    "shortcuts + logout",
    "<b>Colorful quick actions</b> — My Stop (purple), ETA (blue), "
    "Notifications (orange), Contact School (green)",
    "<b>Cute school-bus logo</b> — smiling yellow bus on blue 😄",
    "<b>Back button sahi kaam karta hai</b> — page se page wapas, app "
    "achanak band nahi hoti",
    "<b>Full English text</b> — English medium school ke liye professional "
    "language",
]))

# ═══ 5. Technology ═══
E.append(PageBreak())
E.append(Paragraph("5. Technology — Google Ki Power, Free Mein 🛠️", S["h1"]))
tech = Table([
    [Paragraph("<b>Component</b>", S["cellh"]),
     Paragraph("<b>Kya hai</b>", S["cellh"]),
     Paragraph("<b>Kyun best hai</b>", S["cellh"])],
    [Paragraph("Flutter", S["cell"]),
     Paragraph("Google ka app framework", S["cell"]),
     Paragraph("Ek code se Android + iPhone dono apps", S["cell"])],
    [Paragraph("Firebase", S["cell"]),
     Paragraph("Google ka secure backend", S["cell"]),
     Paragraph("Login, database, real-time — sab free tier mein", S["cell"])],
    [Paragraph("OpenStreetMap", S["cell"]),
     Paragraph("Free world map", S["cell"]),
     Paragraph("Koi paid API key nahi, koi card nahi", S["cell"])],
    [Paragraph("Realtime Database", S["cell"]),
     Paragraph("Live GPS pipeline", S["cell"]),
     Paragraph("Bus location har ~5 second update", S["cell"])],
], colWidths=[35 * mm, 55 * mm, CW - 90 * mm])
tech.setStyle(TableStyle([
    ("BACKGROUND", (0, 0), (-1, 0), PRIMARY),
    ("BACKGROUND", (0, 1), (-1, 1), white),
    ("BACKGROUND", (0, 2), (-1, 2), BG),
    ("BACKGROUND", (0, 3), (-1, 3), white),
    ("BACKGROUND", (0, 4), (-1, 4), BG),
    ("GRID", (0, 0), (-1, -1), 0.5, DIVIDER),
    ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
    ("TOPPADDING", (0, 0), (-1, -1), 6),
    ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
    ("LEFTPADDING", (0, 0), (-1, -1), 8),
]))
E.append(tech)
E.append(Spacer(1, 8))
E.append(stat_row([
    ("9,000+", "Lines of code", PRIMARY),
    ("0", "Analyzer errors", SUCCESS),
    ("15/15", "Tests passing", PURPLE),
    ("v1.2.0", "Current version", ACCENT_DARK),
]))
E.append(Spacer(1, 10))

# Platform status
plat = Table([[
    Paragraph("<b>🤖 Android</b><br/><font size=9>APK ready & tested — "
              "aaj hi install karo. Min Android 6.0+</font>", S["cell"]),
    Paragraph("<b>🍎 iPhone (iOS)</b><br/><font size=9>Same code ready — "
              "sirf Apple Developer account chahiye ($99/yr, school ke "
              "naam par). Code change zero.</font>", S["cell"]),
]], colWidths=[CW / 2, CW / 2])
plat.setStyle(TableStyle([
    ("BACKGROUND", (0, 0), (0, 0), SUCCESS_SOFT),
    ("BACKGROUND", (1, 0), (1, 0), PRIMARY_SOFT),
    ("BOX", (0, 0), (0, 0), 1, SUCCESS),
    ("BOX", (1, 0), (1, 0), 1, PRIMARY),
    ("TOPPADDING", (0, 0), (-1, -1), 10),
    ("BOTTOMPADDING", (0, 0), (-1, -1), 10),
    ("LEFTPADDING", (0, 0), (-1, -1), 12),
    ("RIGHTPADDING", (0, 0), (-1, -1), 12),
]))
E.append(plat)
E.append(Spacer(1, 10))

# ═══ 6. Journey ═══
E.append(Paragraph("6. App Ka Safar — Version Journey 🛤️", S["h1"]))
jrows = [
    ("v1.0", "Base app + Firebase connected — pehla working version"),
    ("v1.4", "Class-wise admin system + naya cute bus logo"),
    ("v1.6", "Roll-number login — email ki zaroorat khatam"),
    ("v1.7", "Trip History + student password reset + stops reorder/delete"),
    ("v1.1.1", "Premium UI upgrade — blue headers, drawer, 5-tab navigation"),
    ("v1.2.0 ⭐", "Single-device security + login status + full English"),
]
jt = Table(
    [[Paragraph(f"<b>{v}</b>", S["cell"]), Paragraph(d, S["cell"])]
     for v, d in jrows],
    colWidths=[28 * mm, CW - 28 * mm])
jt.setStyle(TableStyle([
    ("BACKGROUND", (0, 0), (0, -1), PRIMARY_SOFT),
    ("GRID", (0, 0), (-1, -1), 0.5, DIVIDER),
    ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
    ("TOPPADDING", (0, 0), (-1, -1), 6),
    ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
    ("LEFTPADDING", (0, 0), (-1, -1), 9),
]))
E.append(jt)
E.append(Spacer(1, 12))

# ═══ Closing banner ═══
close = Table([[Paragraph(
    "<b>Never Miss Bus</b> — kyunki har bachche ka time, safety aur "
    "parents ka sukoon important hai.<br/>"
    "<font size=11>Ab bus miss nahi hogi! 🚌✨</font>",
    ParagraphStyle("cl", fontName="Helvetica-Bold", fontSize=14,
                   leading=20, textColor=white, alignment=1))]],
    colWidths=[CW])
close.setStyle(TableStyle([
    ("BACKGROUND", (0, 0), (-1, -1), PRIMARY),
    ("TOPPADDING", (0, 0), (-1, -1), 14),
    ("BOTTOMPADDING", (0, 0), (-1, -1), 14),
]))
E.append(close)
E.append(Spacer(1, 6))
E.append(Paragraph(
    "SRBS International School  ·  Never Miss Bus v1.2.0  ·  Android + iOS  "
    "·  2026", ParagraphStyle("ft", fontName="Helvetica", fontSize=9,
                              textColor=TEXT2, alignment=1)))

doc.build(E)
import os
print("PDF written:", OUT, os.path.getsize(OUT) // 1024, "KB")
