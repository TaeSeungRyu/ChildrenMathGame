# -*- coding: utf-8 -*-
"""Generate '류선생' brand assets:
 - youtube_banner_ryu.png  (2048x1152) : channel banner, '류선생' only
 - youtube_profile_ryu.png (800x800)   : circular profile / logo mark
Theme: app sky-blue (#4FC3F7) + cream (#FFF8E7). Bundled Jua font.
Background decoration is a playful confetti/dot motif (no math symbols).
"""
import os
import math
import random
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONT = os.path.join(ROOT, "assets", "fonts", "Jua-Regular.ttf")
OUT_BANNER = os.path.join(ROOT, "marketing", "youtube_banner_ryu.png")
OUT_PROFILE = os.path.join(ROOT, "marketing", "youtube_profile_ryu.png")

# ---- palette ----
SKY_TOP = (138, 217, 251)
SKY_BOT = (53, 182, 240)
CREAM = (255, 248, 231)
INK = (13, 71, 161)
RED = (232, 82, 75)
BLUE = (74, 144, 217)
GREEN = (60, 194, 110)
PURPLE = (155, 89, 182)
YELLOW = (255, 202, 64)
DOT_COLORS = [RED, GREEN, PURPLE, YELLOW, (255, 255, 255)]


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def sky_gradient(w, h):
    bg = Image.new("RGB", (w, h))
    px = bg.load()
    for y in range(h):
        c = lerp(SKY_TOP, SKY_BOT, y / (h - 1))
        for x in range(w):
            px[x, y] = c
    return bg.convert("RGBA")


def scatter_motif(w, h, keep_out, seed=7, count=90):
    """Playful confetti: dots + rounded squares + rings. keep_out(x,y)->True to skip."""
    rnd = random.Random(seed)
    layer = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    placed = 0
    tries = 0
    while placed < count and tries < count * 40:
        tries += 1
        x = rnd.randint(0, w)
        y = rnd.randint(0, h)
        s = rnd.randint(int(min(w, h) * 0.018), int(min(w, h) * 0.055))
        if keep_out(x, y, s):
            continue
        col = rnd.choice(DOT_COLORS)
        a = rnd.randint(120, 200) if col != (255, 255, 255) else rnd.randint(60, 110)
        kind = rnd.random()
        if kind < 0.55:  # filled dot
            d.ellipse([x - s, y - s, x + s, y + s], fill=col + (a,))
        elif kind < 0.8:  # ring
            wdt = max(4, s // 3)
            d.ellipse([x - s, y - s, x + s, y + s], outline=col + (a,), width=wdt)
        else:  # rounded square (tilted feel via small offset)
            d.rounded_rectangle([x - s, y - s, x + s, y + s],
                                radius=s // 2, fill=col + (a,))
        placed += 1
    return layer


def draw_center_text(img, text, box, font_path, max_font, fill):
    """Fit text centered inside box=(x0,y0,x1,y1)."""
    draw = ImageDraw.Draw(img)
    bw = box[2] - box[0]
    bh = box[3] - box[1]
    size = max_font
    while size > 10:
        f = ImageFont.truetype(font_path, size)
        b = draw.textbbox((0, 0), text, font=f)
        tw, th = b[2] - b[0], b[3] - b[1]
        if tw <= bw and th <= bh:
            break
        size -= 4
    f = ImageFont.truetype(font_path, size)
    b = draw.textbbox((0, 0), text, font=f)
    tw, th = b[2] - b[0], b[3] - b[1]
    tx = box[0] + (bw - tw) // 2 - b[0]
    ty = box[1] + (bh - th) // 2 - b[1]
    draw.text((tx, ty), text, font=f, fill=fill)


# ======================= BANNER 2048x1152 =======================
W, H = 2048, 1152
img = sky_gradient(W, H)

card_w, card_h = 1120, 460
cx0 = (W - card_w) // 2
cy0 = (H - card_h) // 2

# motif everywhere except behind the card
pad = 60


def banner_keepout(x, y, s):
    return (cx0 - pad - s < x < cx0 + card_w + pad + s and
            cy0 - pad - s < y < cy0 + card_h + pad + s)


img = Image.alpha_composite(img, scatter_motif(W, H, banner_keepout, seed=11, count=110))

# soft shadow + cream card
shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
ImageDraw.Draw(shadow).rounded_rectangle(
    [cx0 + 8, cy0 + 22, cx0 + card_w + 8, cy0 + card_h + 22], radius=90, fill=(10, 40, 80, 120))
img = Image.alpha_composite(img, shadow.filter(ImageFilter.GaussianBlur(26)))
ImageDraw.Draw(img).rounded_rectangle(
    [cx0, cy0, cx0 + card_w, cy0 + card_h], radius=90,
    fill=CREAM + (255,), outline=(255, 255, 255, 255), width=8)

draw_center_text(img, "류선생", (cx0 + 70, cy0 + 60, cx0 + card_w - 70, cy0 + card_h - 60),
                 FONT, 300, INK)
img.convert("RGB").save(OUT_BANNER, "PNG", optimize=True)
print("saved:", OUT_BANNER, os.path.getsize(OUT_BANNER), "bytes")

# ======================= PROFILE 800x800 (circular) =======================
P = 800
prof = sky_gradient(P, P)
R = P // 2
cx = cy = P // 2
disc = R - 26  # inner cream disc radius

# confetti inside the visible circle, outside the center text disc
def profile_keepout(x, y, s):
    dist = math.hypot(x - cx, y - cy)
    if dist + s > R - 12:          # outside visible circle
        return True
    if dist - s < disc * 0.72:     # too close to center text
        return True
    return False


prof = Image.alpha_composite(prof, scatter_motif(P, P, profile_keepout, seed=5, count=42))

# cream center disc with soft shadow
sh = Image.new("RGBA", (P, P), (0, 0, 0, 0))
ImageDraw.Draw(sh).ellipse([cx - disc * 0.72, cy - disc * 0.72 + 8,
                            cx + disc * 0.72, cy + disc * 0.72 + 8], fill=(10, 40, 80, 110))
prof = Image.alpha_composite(prof, sh.filter(ImageFilter.GaussianBlur(16)))
ImageDraw.Draw(prof).ellipse(
    [cx - disc * 0.72, cy - disc * 0.72, cx + disc * 0.72, cy + disc * 0.72],
    fill=CREAM + (255,), outline=(255, 255, 255, 255), width=8)

inner = int(disc * 0.72)
draw_center_text(prof, "류선생",
                 (cx - inner + 34, cy - inner + 34, cx + inner - 34, cy + inner - 34),
                 FONT, 260, INK)

# mask to a clean circle (transparent corners) so it looks right anywhere
mask = Image.new("L", (P, P), 0)
ImageDraw.Draw(mask).ellipse([2, 2, P - 2, P - 2], fill=255)
prof.putalpha(mask)
prof.save(OUT_PROFILE, "PNG", optimize=True)
print("saved:", OUT_PROFILE, os.path.getsize(OUT_PROFILE), "bytes")
