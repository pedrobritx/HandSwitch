#!/usr/bin/env python3
"""Generate the HandSwitch app icon.

Renders a single high-resolution master and downsamples it to every size the
macOS asset catalog needs. The icon is a rounded "squircle" tile with a calm
indigo→blue gradient and a white two-button mouse silhouette — the split
between the two buttons is the visual metaphor for swapping the primary
(left/right) button.

Usage:
    python3 Tools/generate_appicon.py

Requires Pillow (`pip install Pillow`). Output PNGs are written into
HandSwitch/Resources/Assets.xcassets/AppIcon.appiconset/.
"""

from __future__ import annotations

import os

from PIL import Image, ImageChops, ImageDraw, ImageFilter

MASTER = 2048  # master render resolution; downsampled to each target size
OUTPUT_DIR = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "HandSwitch", "Resources", "Assets.xcassets", "AppIcon.appiconset",
)
TARGET_SIZES = [1024, 512, 256, 128, 64, 32, 16]

# Gradient endpoints (top → bottom).
GRADIENT_TOP = (94, 92, 230)      # #5E5CE6 indigo
GRADIENT_BOTTOM = (10, 132, 255)  # #0A84FF system blue


def _vertical_gradient(width: int, height: int) -> Image.Image:
    """A smooth top-to-bottom gradient between the two brand colors."""
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


def _rounded_mask(width: int, height: int, radius: int) -> Image.Image:
    mask = Image.new("L", (width, height), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle([0, 0, width - 1, height - 1], radius=radius, fill=255)
    return mask


def _clip_alpha(layer: Image.Image, clip_mask: Image.Image) -> Image.Image:
    """Multiply a full-canvas RGBA layer's alpha by a full-canvas mask."""
    red, green, blue, alpha = layer.split()
    alpha = ImageChops.multiply(alpha, clip_mask)
    return Image.merge("RGBA", (red, green, blue, alpha))


def _mouse_mask(canvas: int, tile_box: tuple[int, int, int, int]) -> Image.Image:
    """A mask where the white mouse silhouette is 255 and its cut-outs are 0."""
    tx0, ty0, tx1, ty1 = tile_box
    tile_w = tx1 - tx0
    tile_h = ty1 - ty0

    body_w = tile_w * 0.34
    body_h = tile_h * 0.52
    cx = (tx0 + tx1) / 2
    cy = (ty0 + ty1) / 2 + tile_h * 0.01

    bx0 = cx - body_w / 2
    by0 = cy - body_h / 2
    bx1 = cx + body_w / 2
    by1 = cy + body_h / 2

    mask = Image.new("L", (canvas, canvas), 0)
    draw = ImageDraw.Draw(mask)
    # Mouse body: a vertical capsule.
    draw.rounded_rectangle([bx0, by0, bx1, by1], radius=body_w / 2, fill=255)

    # Cut out the button seam (vertical divider in the top portion).
    seam_w = max(body_w * 0.06, 2)
    seam_top = by0 + body_h * 0.10
    seam_bottom = by0 + body_h * 0.42
    draw.rounded_rectangle(
        [cx - seam_w / 2, seam_top, cx + seam_w / 2, seam_bottom],
        radius=seam_w / 2,
        fill=0,
    )

    # Cut out a small scroll wheel near the top-center.
    wheel_w = body_w * 0.14
    wheel_h = body_h * 0.12
    wheel_cy = by0 + body_h * 0.205
    draw.rounded_rectangle(
        [cx - wheel_w / 2, wheel_cy - wheel_h / 2, cx + wheel_w / 2, wheel_cy + wheel_h / 2],
        radius=wheel_w / 2,
        fill=0,
    )
    return mask


def render_master() -> Image.Image:
    canvas = MASTER
    icon = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))

    # Squircle tile geometry (macOS icon grid: ~80% with padding).
    margin = round(canvas * 0.0977)
    tile_box = (margin, margin, canvas - margin, canvas - margin)
    tile_w = tile_box[2] - tile_box[0]
    tile_h = tile_box[3] - tile_box[1]
    radius = round(tile_w * 0.225)

    # Full-canvas alpha mask for the rounded tile.
    tile_alpha = Image.new("L", (canvas, canvas), 0)
    tile_alpha.paste(_rounded_mask(tile_w, tile_h, radius), (tile_box[0], tile_box[1]))

    # Gradient fill clipped to the rounded tile.
    gradient = _vertical_gradient(tile_w, tile_h).convert("RGBA")
    tile = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
    tile.paste(gradient, (tile_box[0], tile_box[1]))
    tile = _clip_alpha(tile, tile_alpha)
    icon = Image.alpha_composite(icon, tile)

    # Soft top highlight for a gentle glassy sheen.
    highlight = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
    ImageDraw.Draw(highlight).ellipse(
        [tile_box[0] - tile_w * 0.2, tile_box[1] - tile_h * 0.55,
         tile_box[2] + tile_w * 0.2, tile_box[1] + tile_h * 0.42],
        fill=(255, 255, 255, 60),
    )
    highlight = _clip_alpha(highlight, tile_alpha)
    icon = Image.alpha_composite(icon, highlight)

    # Drop shadow behind the mouse for subtle depth.
    mouse_mask = _mouse_mask(canvas, tile_box)
    shadow = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
    shadow.paste((0, 0, 0, 110), (0, round(canvas * 0.006)), mouse_mask)
    shadow = shadow.filter(ImageFilter.GaussianBlur(canvas * 0.008))
    shadow = _clip_alpha(shadow, tile_alpha)
    icon = Image.alpha_composite(icon, shadow)

    # White mouse silhouette (with seam/wheel cut-outs letting the gradient show).
    white = Image.new("RGBA", (canvas, canvas), (255, 255, 255, 255))
    white.putalpha(mouse_mask)
    icon = Image.alpha_composite(icon, white)

    return icon


def main() -> None:
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    master = render_master()
    for size in TARGET_SIZES:
        resized = master.resize((size, size), Image.LANCZOS)
        path = os.path.join(OUTPUT_DIR, f"icon_{size}.png")
        resized.save(path, "PNG")
        print(f"wrote {path}")


if __name__ == "__main__":
    main()
