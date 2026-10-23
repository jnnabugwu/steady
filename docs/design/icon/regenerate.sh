#!/usr/bin/env bash
# Regenerates the iOS and macOS app icon PNGs from the Cairn master SVGs.
# Needs macOS (for NSImage SVG rendering) and ImageMagick (`magick`).
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../../.." && pwd)"
ios="$repo/app/ios/Runner/Assets.xcassets/AppIcon.appiconset"
mac="$repo/app/macos/Runner/Assets.xcassets/AppIcon.appiconset"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

render() { swift "$here/render_svg.swift" "$1" "$2" "$3"; }

# iOS: one 1024 universal image per appearance, full bleed, no alpha channel.
for a in default dark tinted; do
  render "$here/cairn-$a.svg" "$tmp/$a.png" 1024
  magick "$tmp/$a.png" -alpha off -strip "PNG24:$ios/AppIcon-$a-1024.png"
done

# macOS does not mask icons before macOS 26, so it gets the rounded preview
# shape on Apple's macOS icon grid: an 824x824 tile centred in 1024, transparent margins.
render "$here/cairn-preview.svg" "$tmp/tile.png" 824
magick "$tmp/tile.png" -background none -gravity center -extent 1024x1024 -strip "PNG32:$tmp/mac-1024.png"
for s in 16 32 64 128 256 512 1024; do
  magick "$tmp/mac-1024.png" -filter Lanczos -resize "${s}x${s}" -strip "PNG32:$mac/app_icon_$s.png"
done
