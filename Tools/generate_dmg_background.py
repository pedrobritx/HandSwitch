#!/usr/bin/env python3
"""Generate the HandSwitch DMG installer background.

Draws the backdrop the user sees when they open HandSwitch.dmg: a calm
indigo→blue gradient (matching the app icon) with a soft arrow pointing from
the app's position toward the Applications folder, plus a short instruction.
The icons themselves are placed by `create-dmg`; this only paints what sits
behind them.

Renders at @1x (600×400) and @2x (1200×800). macOS picks the @2x variant
automatically from the `.background` folder on Retina displays.

Usage:
    python3 Tools/generate_dmg_background.py

Requires Pillow (`pip install Pillow`). Output PNGs are written to
Resources/dmg/.
"""

from __future__ import annotations

import math
import os

from PIL import Image, ImageDraw, ImageFilter, ImageFont

# Window geometry, kept in sync with Scripts/build-dmg.sh.
WIDTH, HEIGHT = 600, 400
APP_ICON_CENTER = (150, 190)
APPS_ICON_CENTER = (450, 190)

OUTPUT_DIR = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "Resources", "dmg",
)

# Same brand endpoints as the app icon, but lightened: the background must stay
# quiet enough that the two icons on top of it remain the focus.
GRADIENT_TOP = (240, 242, 252)
GRADIENT_BOTTOM = (222, 232, 250)
NEBULA = (94, 92, 230)   # #5E5CE6
BLUE = (10, 132, 255)    # #0A84FF


def _vertical_gradient(width: int, height: int) -> Image.Image:
    base = Image.new("RGB", (width, height))
    pixels = base.load()
    for y in range(height):
        t = y / max(height - 1, 1)
        r = round(GRADIENT_TOP[0] + (GRADIENT_BOTTOM[0] - GRADIENT_TOP[0]) * t)
        g = round(GRADIENT_TOP[1] + (GRADIENT_BOTTOM[1] - GRADIENT_TOP[1]) * t)
        b = round(GRADIENT_TOP[2] + (GRADIENT_BOTTOM[2] - GRADIENT_TOP[2]) * t)
        for x in range(width):
            pixels[x, y] = (r, g, b)
    return base


def _load_font(size: int) -> ImageFont.ImageFont:
    """Best-effort system font lookup, falling back to Pillow's default."""
    candidates = [
        "/System/Library/Fonts/SFNS.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf",
    ]
    for path in candidates:
        if os.path.exists(path):
            try:
                return ImageFont.truetype(path, size)
            except OSError:
                continue
    return ImageFont.load_default()


def _draw_arrow(layer: Image.Image, scale: int) -> None:
    """A soft, tapered arrow curving from the app toward Applications."""
    draw = ImageDraw.Draw(layer)

    start_x = (APP_ICON_CENTER[0] + 78) * scale
    end_x = (APPS_ICON_CENTER[0] - 78) * scale
    mid_y = APP_ICON_CENTER[1] * scale
    span = end_x - start_x

    # Dashed shaft: short segments that fade in, suggesting motion.
    segments = 13
    gap = 0.38
    seg_len = span / segments
    for index in range(segments):
        x0 = start_x + index * seg_len
        x1 = x0 + seg_len * (1 - gap)
        # Ease the color from indigo to blue along the path.
        t = index / max(segments - 1, 1)
        color = (
            round(NEBULA[0] + (BLUE[0] - NEBULA[0]) * t),
            round(NEBULA[1] + (BLUE[1] - NEBULA[1]) * t),
            round(NEBULA[2] + (BLUE[2] - NEBULA[2]) * t),
            round(70 + 120 * t),
        )
        draw.rounded_rectangle(
            [x0, mid_y - 2 * scale, x1, mid_y + 2 * scale],
            radius=2 * scale,
            fill=color,
        )

    # Arrowhead.
    head = 15 * scale
    draw.polygon(
        [
            (end_x + head * 0.9, mid_y),
            (end_x - head * 0.35, mid_y - head * 0.72),
            (end_x - head * 0.35, mid_y + head * 0.72),
        ],
        fill=BLUE + (205,),
    )


def render(scale: int) -> Image.Image:
    width, height = WIDTH * scale, HEIGHT * scale
    canvas = _vertical_gradient(width, height).convert("RGBA")

    # Wide, very soft brand glow behind the arrow for depth.
    glow = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse(
        [width * 0.12, height * 0.30, width * 0.88, height * 0.70],
        fill=NEBULA + (26,),
    )
    glow = glow.filter(ImageFilter.GaussianBlur(38 * scale))
    canvas = Image.alpha_composite(canvas, glow)

    arrow = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    _draw_arrow(arrow, scale)
    canvas = Image.alpha_composite(canvas, arrow)

    # Instruction line, centered under the icons.
    draw = ImageDraw.Draw(canvas)
    text = "Drag HandSwitch into your Applications folder"
    font = _load_font(15 * scale)
    left, top, right, bottom = draw.textbbox((0, 0), text, font=font)
    draw.text(
        ((width - (right - left)) / 2, height * 0.80 - (bottom - top) / 2),
        text,
        font=font,
        fill=(58, 64, 92, 190),
    )
    return canvas.convert("RGB")


def main() -> None:
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    for scale, name in ((1, "background.png"), (2, "background@2x.png")):
        path = os.path.join(OUTPUT_DIR, name)
        render(scale).save(path, "PNG")
        print(f"wrote {path}")


if __name__ == "__main__":
    main()
