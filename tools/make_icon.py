"""Generate a 1024x1024 app icon for the children's math game.

Outputs assets/icon/app_icon.png. Run with: python tools/make_icon.py
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter

SIZE = 1024
OUT = Path(__file__).resolve().parents[1] / "assets" / "icon" / "app_icon.png"


def radial_background(size: int) -> Image.Image:
    img = Image.new("RGB", (size, size), (255, 200, 102))
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    # Concentric circles fading from sunny yellow center to coral edge
    for i in range(size, 0, -8):
        t = i / size
        r = int(255 * (1 - t) + 255 * t)
        g = int(214 * (1 - t) + 138 * t)
        b = int(102 * (1 - t) + 128 * t)
        draw.ellipse((cx - i, cy - i, cx + i, cy + i), fill=(r, g, b))
    return img


def find_font(candidates, size):
    for name in candidates:
        try:
            return ImageFont.truetype(name, size)
        except OSError:
            continue
    return ImageFont.load_default()


def draw_symbol(draw, font, text, center, color, shadow=(0, 0, 0, 80)):
    bbox = draw.textbbox((0, 0), text, font=font, anchor="mm")
    cx, cy = center
    # soft shadow
    draw.text((cx + 6, cy + 8), text, font=font, fill=shadow, anchor="mm")
    draw.text((cx, cy), text, font=font, fill=color, anchor="mm")


def main():
    OUT.parent.mkdir(parents=True, exist_ok=True)

    base = radial_background(SIZE).convert("RGBA")

    # White rounded card centered, gives the "sticker" look
    card = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    cdraw = ImageDraw.Draw(card)
    pad = 110
    cdraw.rounded_rectangle(
        (pad, pad, SIZE - pad, SIZE - pad),
        radius=170,
        fill=(255, 255, 255, 240),
        outline=(255, 255, 255, 255),
        width=8,
    )

    # Drop shadow under the card
    shadow_layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(shadow_layer)
    sdraw.rounded_rectangle(
        (pad + 10, pad + 26, SIZE - pad + 10, SIZE - pad + 26),
        radius=170,
        fill=(0, 0, 0, 90),
    )
    shadow_layer = shadow_layer.filter(ImageFilter.GaussianBlur(18))
    base = Image.alpha_composite(base, shadow_layer)
    base = Image.alpha_composite(base, card)

    draw = ImageDraw.Draw(base)
    big = find_font(
        ["arialbd.ttf", "arial.ttf", "DejaVuSans-Bold.ttf", "seguibl.ttf"],
        420,
    )
    small = find_font(
        ["arialbd.ttf", "arial.ttf", "DejaVuSans-Bold.ttf"],
        260,
    )

    # Big red plus dead center
    draw_symbol(draw, big, "+", (SIZE // 2, SIZE // 2 - 30), (231, 76, 60, 255))

    # Three small symbols in the corners of the card
    inset = 270
    draw_symbol(draw, small, "−", (inset, inset), (52, 152, 219, 255))
    draw_symbol(draw, small, "×", (SIZE - inset, inset), (46, 204, 113, 255))
    draw_symbol(draw, small, "÷", (SIZE // 2, SIZE - inset + 40), (155, 89, 182, 255))

    base.convert("RGB").save(OUT, "PNG", optimize=True)
    print(f"wrote {OUT} ({OUT.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
