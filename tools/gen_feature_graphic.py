"""Generate Play Store feature graphic (1024x500) for '연산 히어로'.

Run from repo root:
    python tools/gen_feature_graphic.py
Output: assets/store/feature_graphic.png
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
FONT = ROOT / "assets" / "fonts" / "Jua-Regular.ttf"
ICON = ROOT / "assets" / "icon" / "app_icon.png"
OUT = ROOT / "assets" / "store" / "feature_graphic.png"

W, H = 1024, 500


def vertical_gradient(size, top, bottom):
    w, h = size
    base = Image.new("RGB", size, top)
    top_r, top_g, top_b = top
    bot_r, bot_g, bot_b = bottom
    px = base.load()
    for y in range(h):
        t = y / (h - 1)
        r = int(top_r + (bot_r - top_r) * t)
        g = int(top_g + (bot_g - top_g) * t)
        b = int(top_b + (bot_b - top_b) * t)
        for x in range(w):
            px[x, y] = (r, g, b)
    return base


def draw_text_with_shadow(draw, xy, text, font, fill, shadow=(0, 0, 0, 60), offset=(3, 4)):
    x, y = xy
    # Shadow (separate layer for alpha blur would be heavier; flat shadow looks good here)
    sx, sy = offset
    draw.text((x + sx, y + sy), text, font=font, fill=shadow)
    draw.text((x, y), text, font=font, fill=fill)


def main():
    OUT.parent.mkdir(parents=True, exist_ok=True)

    # Background — light blue vertical gradient matching original
    bg = vertical_gradient((W, H), (160, 210, 250), (95, 165, 235)).convert("RGBA")

    # Background decorative numbers (faint white)
    deco_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    deco_draw = ImageDraw.Draw(deco_layer)
    big_font = ImageFont.truetype(str(FONT), 180)
    deco_draw.text((735, 5), "7", font=big_font, fill=(255, 255, 255, 70))
    deco_draw.text((905, 20), "9", font=big_font, fill=(255, 255, 255, 70))
    deco_draw.text((905, 305), "5", font=big_font, fill=(255, 255, 255, 70))
    bg = Image.alpha_composite(bg, deco_layer)

    # App icon with soft shadow
    icon = Image.open(ICON).convert("RGBA")
    icon_size = 360
    icon = icon.resize((icon_size, icon_size), Image.LANCZOS)

    # Shadow puck under the icon
    shadow_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow_layer)
    icon_x = 60
    icon_y = (H - icon_size) // 2
    shadow_draw.ellipse(
        (icon_x - 20, icon_y + icon_size - 50, icon_x + icon_size + 20, icon_y + icon_size + 50),
        fill=(0, 0, 0, 70),
    )
    shadow_layer = shadow_layer.filter(ImageFilter.GaussianBlur(radius=18))
    bg = Image.alpha_composite(bg, shadow_layer)
    bg.alpha_composite(icon, (icon_x, icon_y))

    # Text block
    draw = ImageDraw.Draw(bg)
    title_font = ImageFont.truetype(str(FONT), 130)
    tag_font = ImageFont.truetype(str(FONT), 42)

    title = "연산 히어로"
    tagline = "광고 없이, 매일 한 판!"

    title_bbox = draw.textbbox((0, 0), title, font=title_font)
    title_w = title_bbox[2] - title_bbox[0]
    title_h = title_bbox[3] - title_bbox[1]

    text_area_left = icon_x + icon_size + 40   # 460
    text_area_right = W - 40                    # 984
    text_area_w = text_area_right - text_area_left

    title_x = text_area_left + (text_area_w - title_w) // 2
    title_y = 130
    draw_text_with_shadow(
        draw,
        (title_x, title_y),
        title,
        title_font,
        fill=(255, 255, 255, 255),
        shadow=(0, 0, 0, 90),
        offset=(4, 5),
    )

    tag_bbox = draw.textbbox((0, 0), tagline, font=tag_font)
    tag_w = tag_bbox[2] - tag_bbox[0]
    tag_x = text_area_left + (text_area_w - tag_w) // 2
    tag_y = title_y + title_h + 50
    draw_text_with_shadow(
        draw,
        (tag_x, tag_y),
        tagline,
        tag_font,
        fill=(255, 255, 255, 255),
        shadow=(0, 0, 0, 70),
        offset=(2, 3),
    )

    # Operator badges row
    ops = [
        ("+", (231, 76, 60)),   # red
        ("−", (52, 152, 219)),  # blue
        ("×", (39, 174, 96)),   # green
        ("÷", (142, 68, 173)),  # purple
    ]
    # Jua lacks glyphs for −/×/÷; fall back to a system font that has them.
    op_font = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 62)
    badge_r = 42
    gap = 36
    total_w = len(ops) * (badge_r * 2) + (len(ops) - 1) * gap
    start_x = text_area_left + (text_area_w - total_w) // 2 + badge_r
    badge_y = tag_y + 95

    # Badge shadows
    badge_shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    bs_draw = ImageDraw.Draw(badge_shadow)
    for i, _ in enumerate(ops):
        cx = start_x + i * (badge_r * 2 + gap)
        bs_draw.ellipse(
            (cx - badge_r, badge_y - badge_r + 6, cx + badge_r, badge_y + badge_r + 6),
            fill=(0, 0, 0, 80),
        )
    badge_shadow = badge_shadow.filter(ImageFilter.GaussianBlur(radius=6))
    bg = Image.alpha_composite(bg, badge_shadow)
    draw = ImageDraw.Draw(bg)

    for i, (sym, color) in enumerate(ops):
        cx = start_x + i * (badge_r * 2 + gap)
        draw.ellipse(
            (cx - badge_r, badge_y - badge_r, cx + badge_r, badge_y + badge_r),
            fill=(255, 255, 255, 255),
        )
        sym_bbox = draw.textbbox((0, 0), sym, font=op_font)
        sw = sym_bbox[2] - sym_bbox[0]
        sh = sym_bbox[3] - sym_bbox[1]
        # textbbox of TrueType fonts has a top offset (bbox[1] > 0) — subtract it for true centering
        draw.text(
            (cx - sw / 2 - sym_bbox[0], badge_y - sh / 2 - sym_bbox[1]),
            sym,
            font=op_font,
            fill=color,
        )

    bg.convert("RGB").save(OUT, "PNG", optimize=True)
    print(f"wrote {OUT} ({OUT.stat().st_size:,} bytes)")


if __name__ == "__main__":
    main()
