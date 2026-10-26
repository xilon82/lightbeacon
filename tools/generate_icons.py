"""Generates the LightBeacon launcher icon and splash assets.

Run from the repository root:

    python tools/generate_icons.py

The mark is three concentric amber rings around a solid core: a beacon
broadcasting light, which reads clearly even at 48 px.

Outputs:
    docs/icon-concepts/*.png                        design previews
    android/app/src/main/res/mipmap-*/ic_launcher.png
    android/app/src/main/res/mipmap-*/ic_launcher_foreground.png
    android/app/src/main/res/drawable-*/splash_logo.png
    android/app/src/main/res/drawable-*/splash_icon.png
"""

from __future__ import annotations

import os

from PIL import Image, ImageDraw

BG = (10, 10, 12, 255)
AMBER = (255, 176, 32, 255)

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, "android", "app", "src", "main", "res")
CONCEPTS = os.path.join(ROOT, "docs", "icon-concepts")

SS = 4  # supersampling factor

# Geometry as fractions of the half-size. Fractions, not pixels, so the same
# values render correctly at every density.
#
# Constraint that drives these numbers: the gap between two rings must be at
# least as wide as the ring itself, otherwise the mark turns into a solid
# blob at 48 dp. Outer edge = 0.80 + 0.08 / 2 = 0.84 < 1.0, so nothing is
# clipped, and 0.84 * 0.70 = 0.59 < 0.67 keeps the adaptive foreground inside
# the 72 dp safe zone.
CORE_RADIUS = 0.20
RING_RADII = (0.40, 0.60, 0.80)
RING_WIDTH = 0.08


def _canvas(size: int, bg=BG) -> Image.Image:
    return Image.new("RGBA", (size * SS, size * SS), bg)


def _finish(img: Image.Image, size: int) -> Image.Image:
    return img.resize((size, size), Image.LANCZOS)


def save_optimized(img: Image.Image, path: str) -> None:
    """Writes a full-quality PNG.

    No palette quantization: the antialiased ring edges need the full colour
    depth, otherwise the icon looks grainy on the launcher.
    """
    img.save(path, optimize=True)


def beacon_mark(
    size: int,
    *,
    scale: float = 1.0,
    bg=BG,
) -> Image.Image:
    """Draws the rings + core mark centred in a square canvas.

    [scale] shrinks the mark inside the canvas. Adaptive icons need
    ``scale=0.70`` so the outermost ring stays inside the 72 dp safe zone of the
    108 dp canvas and is not clipped by the launcher mask.
    """
    img = _canvas(size, bg)
    d = ImageDraw.Draw(img)
    s = size * SS
    cx = cy = s / 2
    half = s / 2 * scale

    # Solid amber rather than translucent rings: at 48 dp any alpha variation
    # is lost to antialiasing and the mark reads as a smudge.
    stroke = max(1, int(round(half * RING_WIDTH)))
    for r in RING_RADII:
        radius = half * r
        d.ellipse(
            [cx - radius, cy - radius, cx + radius, cy + radius],
            outline=AMBER,
            width=stroke,
        )

    core = half * CORE_RADIUS
    d.ellipse([cx - core, cy - core, cx + core, cy + core], fill=AMBER)
    return _finish(img, size)


# ---------------------------------------------------------------------------
# Alternative concepts, kept for reference
# ---------------------------------------------------------------------------

def concept_bolt(size: int, bg=BG) -> Image.Image:
    img = _canvas(size, bg)
    d = ImageDraw.Draw(img)
    s = size * SS

    pts = [
        (0.56, 0.10), (0.26, 0.55), (0.46, 0.55),
        (0.40, 0.90), (0.74, 0.42), (0.53, 0.42),
    ]
    d.polygon([(x * s, y * s) for x, y in pts], fill=AMBER)
    return _finish(img, size)


def concept_beam(size: int, bg=BG) -> Image.Image:
    img = _canvas(size, bg)
    d = ImageDraw.Draw(img)
    s = size * SS
    cx = s / 2

    d.polygon(
        [
            (cx - s * 0.30, s * 0.16),
            (cx + s * 0.30, s * 0.16),
            (cx + s * 0.085, s * 0.62),
            (cx - s * 0.085, s * 0.62),
        ],
        fill=(255, 176, 32, 120),
    )

    body_w = s * 0.20
    d.rounded_rectangle(
        [cx - body_w / 2, s * 0.60, cx + body_w / 2, s * 0.86],
        radius=s * 0.05,
        fill=AMBER,
    )
    d.ellipse(
        [cx - body_w / 2, s * 0.555, cx + body_w / 2, s * 0.645],
        fill=(255, 255, 255, 255),
    )
    return _finish(img, size)


CONCEPTS_MAP = {
    "a-beacon": beacon_mark,
    "b-bolt": concept_bolt,
    "c-beam": concept_beam,
}

# Android density buckets: (suffix, multiplier)
DENSITIES = [
    ("mdpi", 1.0),
    ("hdpi", 1.5),
    ("xhdpi", 2.0),
    ("xxhdpi", 3.0),
    ("xxxhdpi", 4.0),
]

LEGACY_ICON_DP = 48


def _write_densities(filename: str, folder_template: str, dp: int) -> None:
    for suffix, multiplier in DENSITIES:
        folder = os.path.join(RES, folder_template.format(suffix))
        os.makedirs(folder, exist_ok=True)
        px = int(round(dp * multiplier))
        path = os.path.join(folder, filename)
        save_optimized(beacon_mark(px), path)
        print(f"  {folder_template.format(suffix)}/{filename}  {px}x{px}")


def main() -> None:
    print("design concepts:")
    os.makedirs(CONCEPTS, exist_ok=True)
    for name, fn in CONCEPTS_MAP.items():
        fn(512).save(os.path.join(CONCEPTS, f"{name}.png"))
        print(f"  docs/icon-concepts/{name}.png")

    # Only the legacy icon is raster. The adaptive icon and the splash logo are
    # vector drawables (ic_beacon_mark.xml, splash_logo.xml), which stay sharp
    # at every density and on every launcher mask.
    print("legacy launcher icon (API < 26):")
    _write_densities("ic_launcher.png", "mipmap-{}", LEGACY_ICON_DP)


if __name__ == "__main__":
    main()
