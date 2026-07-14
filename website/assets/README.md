# Asset regeneration (Phase 5)

All raster assets in this folder are **derived from the brand icon**
`plugins/deep-skills/assets/icon.png` (512×512 RGBA). Nothing was fetched from
the network; no online converters. Everything below runs from the **repo root**.

Tooling used: ImageMagick 7 (`magick`, Homebrew) and Python 3 + Pillow.
Fallback if ImageMagick is absent: `sips -Z <size>` for the PNGs plus a small
struct-packed Python ICO writer (PNG-in-ICO is valid) - not needed here.

## Favicon set

```sh
SRC=plugins/deep-skills/assets/icon.png
magick "$SRC" -resize 32x32   website/assets/favicon-32.png
magick "$SRC" -resize 16x16   website/assets/favicon-16.png
magick "$SRC" -resize 180x180 website/assets/apple-touch-icon.png
cp "$SRC" website/assets/icon-512.png
# multi-size .ico (48/32/16, 32-bit PNG frames)
magick "$SRC" -define icon:auto-resize=48,32,16 website/assets/favicon.ico
```

## OG / social image (`og-image.png`, exactly 1200×630)

Generated programmatically with Pillow (script below, run as
`python3 gen_og_image.py` from the repo root). Design tokens match
`site.css`: background `#07080c`, amber accent `#ffb24d`. Space Grotesk is not
installed on the build machine, so the closest macOS system faces are used:
Avenir Next Bold (wordmark, TTC index 0), Menlo (mono tagline), Avenir Next
Medium (domain line, TTC index 5).

```python
#!/usr/bin/env python3
"""Generate website/assets/og-image.png (1200x630) for deep-skills.com."""
from PIL import Image, ImageDraw, ImageFont
import os

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))) \
    if "__file__" in globals() else "."
SRC_ICON = os.path.join(REPO, "plugins/deep-skills/assets/icon.png")
OUT = os.path.join(REPO, "website/assets/og-image.png")

W, H = 1200, 630
BG = (7, 8, 12)         # #07080c
AMBER = (255, 178, 77)  # #ffb24d
TEXT = (240, 242, 248)
MUTED = (150, 156, 172)

img = Image.new("RGB", (W, H), BG)

# subtle amber radial glow, upper-left (matches the site's .glow motif)
glow = Image.new("L", (W, H), 0)
gd = ImageDraw.Draw(glow)
cx, cy, r = 180, 140, 620
for i in range(r, 0, -4):
    a = int(26 * (1 - i / r))
    gd.ellipse([cx - i, cy - i, cx + i, cy + i], fill=a)
img = Image.composite(Image.new("RGB", (W, H), AMBER), img, glow)
d = ImageDraw.Draw(img)

# brand ring icon, left side
icon = Image.open(SRC_ICON).convert("RGBA").resize((260, 260), Image.LANCZOS)
img.paste(icon, (110, (H - 260) // 2 - 18), icon)

# fonts (macOS system faces)
display = ImageFont.truetype("/System/Library/Fonts/Avenir Next.ttc", 112, index=0)  # Bold
sub = ImageFont.truetype("/System/Library/Fonts/Menlo.ttc", 40, index=0)
small = ImageFont.truetype("/System/Library/Fonts/Avenir Next.ttc", 30, index=5)  # Medium

TX = 440
d.text((TX, 218), "Deep Skills", font=display, fill=TEXT)
d.rounded_rectangle([TX + 6, 372, TX + 206, 380], radius=4, fill=AMBER)
d.text((TX + 6, 408), "idea → verified code", font=sub, fill=AMBER)
d.text((TX + 6, 486), "deep-skills.com", font=small, fill=MUTED)

img.save(OUT, "PNG")
print("wrote", OUT, img.size)
```

## Verification

```sh
sips -g pixelWidth -g pixelHeight website/assets/*.png
file website/assets/favicon.ico   # → MS Windows icon resource - 3 icons
```

Expected: favicon-16 16×16, favicon-32 32×32, apple-touch-icon 180×180,
icon-512 512×512, og-image 1200×630.
