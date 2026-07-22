#!/usr/bin/env python3
"""Generate the native-splash brand assets from the master app icon.

The native splash (the frame the OS paints before Flutter boots) has to be a
flat PNG, so the brand tile that the Flutter splash draws with a gradient +
shadow is baked here instead. Everything is derived from
``assets/images/app_icon.png`` so the launcher icon, the native splash and the
in-app brand mark stay the same object.

Outputs (all written to ``assets/branding/``):

  brand_glyph.png            the EasyWay mark keyed out of the icon background,
                             white-on-transparent, for the in-app brand tile.
  splash_mark.png            704x704 @4x -> 176dp. Gradient squircle (96dp, the
                             same size the Flutter splash draws) with a soft
                             brand shadow, on transparent padding.
  splash_mark_android12.png  1152x1152 canvas with the tile inside the 768px
                             safe circle Android 12+ clips the splash icon to.

Usage:  python3 tool/generate_splash_assets.py
Then:   dart run flutter_native_splash:create --path=config/splash/<flavor>.yaml
"""

from __future__ import annotations

import pathlib

from PIL import Image, ImageDraw, ImageFilter

ROOT = pathlib.Path(__file__).resolve().parent.parent
SOURCE_ICON = ROOT / "assets" / "images" / "app_icon.png"
OUT_DIR = ROOT / "assets" / "branding"

# The flat blue the master icon is drawn on. Keyed out to isolate the mark.
ICON_BACKGROUND = (15, 88, 217)

# Matches ClientColors.primaryGradient / CaptainColors.primaryGradient:
# topLeft -> bottomRight, Blue 600 -> Blue 700.
GRADIENT_START = (37, 99, 235)   # #2563EB
GRADIENT_END = (29, 78, 216)     # #1D4ED8

# Geometry, in @4x pixels. The tile is 96dp so it lands exactly where the
# Flutter splash draws its own brand mark — the handoff is then invisible.
SCALE = 4
TILE_DP = 96
CANVAS_DP = 176
CORNER_RATIO = 0.31   # BorderRadius.circular(size * 0.31)
GLYPH_RATIO = 0.62    # mark size relative to the tile


def _keyed_mark(image: Image.Image) -> Image.Image:
    """Return the icon's mark on a transparent background.

    Alpha is the pixel's distance from the icon background, normalised against
    the background->white distance, which keeps anti-aliased edges soft and
    drops the blue interior details (bus windows, road line) out of the glyph —
    on a blue tile they read as the tile showing through, exactly as in the
    launcher icon.
    """
    bg = ICON_BACKGROUND
    span = sum((255 - c) ** 2 for c in bg) ** 0.5
    src = image.convert("RGBA").load()
    out = Image.new("RGBA", image.size, (0, 0, 0, 0))
    dst = out.load()

    for y in range(image.height):
        for x in range(image.width):
            r, g, b, _ = src[x, y]
            dist = ((r - bg[0]) ** 2 + (g - bg[1]) ** 2 + (b - bg[2]) ** 2) ** 0.5
            alpha = (dist / span - 0.10) / 0.80
            alpha = 0.0 if alpha < 0 else (1.0 if alpha > 1 else alpha)
            if alpha <= 0:
                continue
            # Un-mix the background out of partially covered pixels so edges
            # carry no blue fringe.
            unmixed = tuple(
                min(255, max(0, int((c - (1 - alpha) * k) / alpha)))
                for c, k in ((r, bg[0]), (g, bg[1]), (b, bg[2]))
            )
            dst[x, y] = (*unmixed, int(round(alpha * 255)))

    return out.crop(out.getbbox())


def _gradient_tile(size: int) -> Image.Image:
    """A squircle filled with the brand gradient, topLeft -> bottomRight."""
    gradient = Image.new("RGB", (size, size))
    pixels = gradient.load()
    for y in range(size):
        for x in range(size):
            t = (x + y) / (2 * (size - 1))
            pixels[x, y] = tuple(
                int(round(a + (b - a) * t))
                for a, b in zip(GRADIENT_START, GRADIENT_END)
            )

    # Draw the mask oversampled, then downsample, for clean corner antialiasing.
    factor = 4
    mask = Image.new("L", (size * factor, size * factor), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, size * factor - 1, size * factor - 1),
        radius=int(size * factor * CORNER_RATIO),
        fill=255,
    )
    mask = mask.resize((size, size), Image.LANCZOS)

    tile = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    tile.paste(gradient, (0, 0), mask)
    return tile


def _compose(canvas_px: int, tile_px: int, glyph: Image.Image, shadow: bool) -> Image.Image:
    """Center the branded tile (plus its shadow) on a transparent canvas."""
    tile = _gradient_tile(tile_px)

    glyph_box = int(tile_px * GLYPH_RATIO)
    ratio = min(glyph_box / glyph.width, glyph_box / glyph.height)
    mark = glyph.resize(
        (max(1, int(glyph.width * ratio)), max(1, int(glyph.height * ratio))),
        Image.LANCZOS,
    )
    tile.alpha_composite(
        mark, ((tile_px - mark.width) // 2, (tile_px - mark.height) // 2)
    )

    canvas = Image.new("RGBA", (canvas_px, canvas_px), (0, 0, 0, 0))
    origin = (canvas_px - tile_px) // 2

    if shadow:
        # Mirrors the Flutter tile's BoxShadow: brand blue at ~35% alpha,
        # offset down, heavily blurred.
        layer = Image.new("RGBA", (canvas_px, canvas_px), (0, 0, 0, 0))
        silhouette = Image.new("RGBA", tile.size, (*GRADIENT_END, 0))
        silhouette.putalpha(tile.getchannel("A").point(lambda a: int(a * 0.40)))
        layer.alpha_composite(silhouette, (origin, origin + int(tile_px * 0.13)))
        canvas.alpha_composite(
            layer.filter(ImageFilter.GaussianBlur(tile_px * 0.11))
        )

    canvas.alpha_composite(tile, (origin, origin))
    return canvas


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    glyph = _keyed_mark(Image.open(SOURCE_ICON))

    # White-on-transparent glyph for the in-app brand tile.
    white = Image.new("RGBA", glyph.size, (255, 255, 255, 0))
    white.putalpha(glyph.getchannel("A"))
    ratio = 512 / max(glyph.size)
    white.resize(
        (int(glyph.width * ratio), int(glyph.height * ratio)), Image.LANCZOS
    ).save(OUT_DIR / "brand_glyph.png")

    _compose(CANVAS_DP * SCALE, TILE_DP * SCALE, glyph, shadow=True).save(
        OUT_DIR / "splash_mark.png"
    )

    # Android 12+ clips the splash icon to a 768px circle on a 1152px canvas.
    # A 600px squircle sits comfortably inside it; the shadow is dropped here
    # because the circular mask would slice its tail into a visible arc.
    _compose(1152, 600, glyph, shadow=False).save(
        OUT_DIR / "splash_mark_android12.png"
    )

    for name in ("brand_glyph.png", "splash_mark.png", "splash_mark_android12.png"):
        path = OUT_DIR / name
        print(f"{path.relative_to(ROOT)}  {Image.open(path).size}")


if __name__ == "__main__":
    main()
