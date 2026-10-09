#!/usr/bin/env python3
"""Draws polished phone-screen mockups of Never Miss Bus for the
presentation deck (matches the real app's design system)."""
from PIL import Image, ImageDraw, ImageFont
import os

OUT = "/home/user/never_miss_bus/docs/mockups"
os.makedirs(OUT, exist_ok=True)

# Design system colors
PRIMARY = (37, 87, 214)
PRIMARY_DARK = (26, 63, 160)
PRIMARY_SOFT = (232, 238, 252)
ACCENT = (255, 179, 0)
ACCENT_DARK = (138, 91, 0)
ACCENT_SOFT = (255, 243, 214)
SUCCESS = (30, 142, 62)
SUCCESS_SOFT = (226, 243, 231)
DANGER = (197, 34, 31)
TEXT = (23, 35, 59)
TEXT2 = (90, 103, 121)
TEXT3 = (138, 148, 166)
DIVIDER = (228, 233, 242)
BG = (246, 248, 252)
WHITE = (255, 255, 255)

W, H = 750, 1560  # phone canvas
R = 40            # phone corner radius

def font(size, bold=False):
    path = ("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf" if bold
            else "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf")
    return ImageFont.truetype(path, size)

def rounded(d, xy, r, fill, outline=None, width=1):
    d.rounded_rectangle(xy, radius=r, fill=fill, outline=outline, width=width)

def text_c(d, cx, y, s, f, fill):
    w = d.textlength(s, font=f)
    d.text((cx - w / 2, y), s, font=f, fill=fill)

def phone_frame(title):
    img = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(img)
    # status bar
    d.rectangle((0, 0, W, 60), fill=BG)
    d.text((40, 18), "9:41", font=font(26, True), fill=TEXT)
    d.text((W - 150, 18), "5G  100%", font=font(24), fill=TEXT)
    # app bar
    d.text((40, 90), title, font=font(40, True), fill=TEXT)
    return img, d

def bus_icon(d, x, y, s, body=ACCENT):
    """Simple bus glyph in a box of size s at (x,y)."""
    rounded(d, (x, y + s*0.15, x + s, y + s*0.75), int(s*0.12), body)
    ww = s * 0.18
    for i in range(3):
        wx = x + s*0.12 + i*(ww + s*0.09)
        rounded(d, (wx, y + s*0.25, wx + ww, y + s*0.42), int(s*0.04), (227, 242, 253))
    d.rectangle((x, y + s*0.52, x + s, y + s*0.56), fill=WHITE)
    d.ellipse((x + s*0.13, y + s*0.68, x + s*0.30, y + s*0.85), fill=(55, 71, 79))
    d.ellipse((x + s*0.70, y + s*0.68, x + s*0.87, y + s*0.85), fill=(55, 71, 79))

def nav_bar(d, active, items):
    y0 = H - 130
    d.rectangle((0, y0, W, H), fill=WHITE)
    d.line((0, y0, W, y0), fill=DIVIDER, width=2)
    n = len(items)
    for i, label in enumerate(items):
        cx = W * (2*i + 1) / (2*n)
        if i == active:
            rounded(d, (cx-56, y0+14, cx+56, y0+58), 22, PRIMARY_SOFT)
        col = PRIMARY if i == active else TEXT3
        d.ellipse((cx-13, y0+24, cx+13, y0+50), outline=col, width=4)
        text_c(d, cx, y0 + 68, label, font(20, i == active), col)

def pill(d, x, y, s, fg, bg, f=None):
    f = f or font(20, True)
    w = d.textlength(s, font=f) + 46
    rounded(d, (x, y, x + w, y + 40), 20, bg)
    d.ellipse((x+14, y+14, x+26, y+26), fill=fg)
    d.text((x + 34, y + 8), s, font=f, fill=fg)
    return w

# ═════════════ 1. STUDENT HOME ═════════════
img, d = phone_frame("Never Miss Bus")
d.text((40, 160), "Good morning, Aarav!", font=font(42, True), fill=TEXT)
d.text((40, 215), "Here's your bus for today", font=font(26), fill=TEXT2)

# assigned bus card (blue)
rounded(d, (40, 270, W-40, 430), 28, PRIMARY)
rounded(d, (70, 305, 160, 395), 22, ACCENT)
bus_icon(d, 80, 310, 70, ACCENT)
d.text((185, 300), "My bus", font=font(22), fill=(200, 216, 250))
d.text((185, 330), "Bus 3", font=font(40, True), fill=WHITE)
d.text((185, 382), "UK07 PA 1234", font=font(24), fill=(200, 216, 250))
rounded(d, (W-200, 320, W-70, 372), 26, SUCCESS)
text_c(d, W-135, 332, "ON TRIP", font(22, True), WHITE)

# tracking status card
rounded(d, (40, 460, W-40, 590), 28, WHITE, DIVIDER, 2)
rounded(d, (70, 490, 140, 560), 18, SUCCESS_SOFT)
d.ellipse((90, 510, 120, 540), outline=SUCCESS, width=5)
d.text((165, 488), "Bus is being tracked live", font=font(27, True), fill=TEXT)
d.text((165, 528), "Arriving in approximately 8 min", font=font(24), fill=TEXT2)
pill(d, W-190, 478, "LIVE", SUCCESS, SUCCESS_SOFT)

# Track My Bus button
rounded(d, (40, 620, W-40, 730), 28, PRIMARY)
text_c(d, W/2, 652, "Track My Bus", font(36, True), WHITE)

# my stop card
rounded(d, (40, 760, W-40, 880), 28, WHITE, DIVIDER, 2)
rounded(d, (70, 790, 140, 860), 18, ACCENT_SOFT)
d.ellipse((90, 806, 120, 836), fill=ACCENT_DARK)
d.text((165, 782), "My stop", font=font(22), fill=TEXT3)
d.text((165, 812), "Rajpur Road Gate 2", font=font(28, True), fill=TEXT)
d.text((165, 848), "Scheduled: 07:15", font=font(22), fill=TEXT2)

# quick actions
labels = ["Bus & Route", "Bus Stops", "Alerts"]
for i, lb in enumerate(labels):
    x0 = 40 + i * ((W - 80 - 40) / 3 + 20)
    x1 = x0 + (W - 80 - 40) / 3
    rounded(d, (x0, 910, x1, 1040), 24, WHITE, DIVIDER, 2)
    d.ellipse((x0 + (x1-x0)/2 - 22, 935, x0 + (x1-x0)/2 + 22, 979), outline=PRIMARY, width=5)
    text_c(d, x0 + (x1-x0)/2, 993, lb, font(20), TEXT2)

# latest alert
d.text((40, 1075), "Latest alert", font=font(28, True), fill=TEXT)
rounded(d, (40, 1120, W-40, 1250), 28, WHITE, PRIMARY, 3)
d.ellipse((70, 1150, 120, 1200), fill=PRIMARY_SOFT)
d.text((145, 1140), "Bus approaching", font=font(26, True), fill=TEXT)
d.text((145, 1178), "Your bus is close to Rajpur Road", font=font(23), fill=TEXT2)
d.text((145, 1212), "2 minutes ago", font=font(20), fill=TEXT3)
nav_bar(d, 0, ["Home", "Live Map", "Alerts", "Profile"])
img.save(f"{OUT}/student_home.png")

# ═════════════ 2. STUDENT LIVE MAP ═════════════
img, d = phone_frame("Live Map")
pill(d, W-200, 92, "LIVE", SUCCESS, SUCCESS_SOFT)
# map area
d.rectangle((0, 160, W, H-130), fill=(232, 240, 235))
# fake roads
for pts, wd in [([(0, 500), (300, 470), (520, 560), (W, 520)], 26),
                ([(180, 160), (230, 520), (200, 900), (260, H-130)], 22),
                ([(0, 950), (400, 900), (W, 980)], 22)]:
    d.line(pts, fill=(255, 255, 255), width=wd)
# route polyline
route = [(120, 1180), (210, 990), (330, 830), (300, 640), (450, 500), (600, 380)]
d.line(route, fill=PRIMARY, width=10)
# stops
stops = [(120, 1180, False), (330, 830, False), (300, 640, True), (450, 500, False)]
for x, y, mine in stops:
    col = ACCENT if mine else (123, 97, 255)
    d.ellipse((x-18, y-18, x+18, y+18), fill=col, outline=WHITE, width=5)
    if mine:
        text_c(d, x, y - 66, "My stop", font(22, True), ACCENT_DARK)
# school marker
d.ellipse((600-22, 380-22, 600+22, 380+22), fill=(11, 108, 189), outline=WHITE, width=5)
text_c(d, 600, 320, "School", font(22, True), (11, 108, 189))
# bus marker (white circle + bus)
bx, by = 260, 900
d.ellipse((bx-52, by-52, bx+52, by+52), fill=WHITE, outline=(200,200,200), width=3)
bus_icon(d, bx-34, by-30, 68)
# center on bus FAB
rounded(d, (W-320, H-230, W-50, H-160), 34, PRIMARY)
text_c(d, W-185, H-212, "Center on Bus", font(24, True), WHITE)
nav_bar(d, 1, ["Home", "Live Map", "Alerts", "Profile"])
img.save(f"{OUT}/student_map.png")

# ═════════════ 3. DRIVER HOME ═════════════
img, d = phone_frame("Driver Dashboard")
d.text((40, 160), "Good morning, Ramesh!", font=font(40, True), fill=TEXT)
# bus card (active)
rounded(d, (40, 240, W-40, 400), 28, SUCCESS_SOFT, SUCCESS, 3)
rounded(d, (70, 275, 160, 365), 22, ACCENT)
bus_icon(d, 80, 280, 70)
d.text((185, 270), "Bus 3", font=font(34, True), fill=TEXT)
d.text((185, 318), "UK07 PA 1234", font=font(24), fill=TEXT2)
d.text((185, 352), "Morning — Rajpur Road", font=font(22), fill=TEXT3)
d.text((W-250, 285), "TRIP ACTIVE", font=font(24, True), fill=SUCCESS)
d.text((W-250, 320), "since 6:45 AM", font=font(20), fill=TEXT2)
# status tiles
tiles = [("GPS", "On", True), ("Internet", "Connected", True), ("Sharing", "Live", True)]
for i, (lb, val, ok) in enumerate(tiles):
    x0 = 40 + i * ((W - 80 - 40) / 3 + 20)
    x1 = x0 + (W - 80 - 40) / 3
    rounded(d, (x0, 430, x1, 590), 24, WHITE, DIVIDER, 2)
    cx = x0 + (x1-x0)/2
    d.ellipse((cx-24, 455, cx+24, 503), outline=SUCCESS, width=6)
    text_c(d, cx, 515, lb, font(22), TEXT2)
    text_c(d, cx, 545, val, font(22, True), TEXT)
# location card
rounded(d, (40, 620, W-40, 740), 28, WHITE, DIVIDER, 2)
d.ellipse((70, 655, 120, 705), outline=PRIMARY, width=6)
d.text((145, 645), "Sharing location — 32 km/h", font=font(27, True), fill=TEXT)
d.text((145, 688), "Last sent just now", font=font(23), fill=TEXT2)
# giant END TRIP
rounded(d, (40, 790, W-40, 940), 30, DANGER)
text_c(d, W/2, 830, "■  END TRIP", font(44, True), WHITE)
text_c(d, W/2, 975,
       "Location is shared automatically —", font(22), TEXT2)
text_c(d, W/2, 1005, "no further action needed.", font(22), TEXT2)
nav_bar(d, 0, ["Trip", "Route", "Profile"])
img.save(f"{OUT}/driver_home.png")

# ═════════════ 4. ADMIN DASHBOARD ═════════════
img, d = phone_frame("Dashboard")
stats = [("Students", "248", PRIMARY), ("Drivers", "12", ACCENT_DARK),
         ("Buses", "12", (11, 108, 189)), ("Active trips", "8", SUCCESS)]
for i, (lb, val, col) in enumerate(stats):
    r_, c_ = divmod(i, 2)
    x0 = 40 + c_ * ((W-100)/2 + 20)
    x1 = x0 + (W-100)/2
    y0 = 180 + r_ * 190
    rounded(d, (x0, y0, x1, y0+170), 26, WHITE, DIVIDER, 2)
    d.ellipse((x0+28, y0+24, x0+72, y0+68), outline=col, width=6)
    d.text((x0+28, y0+78), val, font=font(46, True), fill=TEXT)
    d.text((x0+28, y0+132), lb, font=font(24), fill=TEXT2)
# active trips
d.text((40, 590), "Active trips", font=font(30, True), fill=TEXT)
trips = [("Bus 3", "Pickup trip in progress"), ("Bus 7", "Pickup trip in progress"),
         ("Bus 1", "Drop-off trip in progress")]
for i, (b, s) in enumerate(trips):
    y0 = 645 + i * 130
    rounded(d, (40, y0, W-40, y0+110), 26, WHITE, DIVIDER, 2)
    rounded(d, (66, y0+25, 126, y0+85), 16, SUCCESS_SOFT)
    bus_icon(d, 72, y0+32, 48, SUCCESS)
    d.text((150, y0+22), b, font=font(28, True), fill=TEXT)
    d.text((150, y0+60), s, font=font(23), fill=TEXT2)
    pill(d, W-190, y0+32, "LIVE", SUCCESS, SUCCESS_SOFT)
# quick actions
d.text((40, 1050), "Quick actions", font=font(30, True), fill=TEXT)
acts = ["+  Add a student or driver", "📢  Send an announcement", "🗒  Review activity logs"]
rounded(d, (40, 1100, W-40, 1360), 26, WHITE, DIVIDER, 2)
for i, a in enumerate(acts):
    y0 = 1100 + i * 86
    d.text((80, y0 + 26), a, font=font(26), fill=TEXT)
    if i < 2:
        d.line((70, y0+86, W-70, y0+86), fill=DIVIDER, width=2)
nav_bar(d, 0, ["Dashboard", "Buses", "More"])
img.save(f"{OUT}/admin_dashboard.png")

print("mockups saved:", os.listdir(OUT))
