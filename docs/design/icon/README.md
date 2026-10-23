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

This needs macOS and ImageMagick. It renders each master at 1024 with `render_svg.swift`,
which uses the system's native SVG renderer. ImageMagick's built-in renderer drops the
gradient and the rotated stones. The script then writes:

- iOS `AppIcon-{default,dark,tinted}-1024.png`, with no alpha channel.
- macOS `app_icon_{16..1024}.png`, downscaled from the 1024 render with Lanczos.
  Smaller sizes are scaled, not simplified.
