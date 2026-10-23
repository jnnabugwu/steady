# Cairn app icon (#71)

Master SVGs for the Steady app icon. Geometry and colours are copied from the
"Icon 3 · Cairn" artboard; don't redraw or recolour them.

- `cairn-default.svg`, `cairn-dark.svg`, `cairn-tinted.svg`: full-bleed squares for iOS,
  which applies its own mask.
- `cairn-preview.svg`: the same icon with the `rx="22.5"` corner, for docs. It is also the
  macOS source. macOS (before 26) doesn't mask app icons, so the macOS PNGs place this tile
  at 824×824 inside a 1024 canvas (Apple's macOS icon grid) with transparent margins.

## Regenerating the PNGs

```sh
docs/design/icon/regenerate.sh
```

This needs macOS and ImageMagick. It renders with `render_svg.swift`, which uses the
system's native SVG renderer (ImageMagick's built-in renderer drops the gradient and the
rotated stones), at two sizes:

- The iOS masters (`cairn-{default,dark,tinted}.svg`) at **1024×1024**, written as iOS
  `AppIcon-{default,dark,tinted}-1024.png` with no alpha channel.
- The macOS source (`cairn-preview.svg`) at **824×824**, centred on a transparent
  1024×1024 canvas. That 1024 image is downscaled with Lanczos to the macOS sizes
  **16, 32, 64, 128, 256, 512 and 1024** (`app_icon_16.png` … `app_icon_1024.png`), which
  the asset catalog maps to 16–512 @1x/@2x. Smaller sizes are scaled, not simplified.
