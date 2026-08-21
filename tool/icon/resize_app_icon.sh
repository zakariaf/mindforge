#!/usr/bin/env bash
# Usage: tool/icon/resize_app_icon.sh
#
# Fills ios/Runner/Assets.xcassets/AppIcon.appiconset from the 1024 master that
# test/tool/app_icon_test.dart renders.
#
# The MASTER IS RENDERED BY THE APP, not exported by hand: it comes out of
# AppIconMark, which reads the same tokens every screen reads, so a palette
# change reds the golden and the icon is regenerated rather than drifting. Run
# the golden update first:
#
#   flutter test --update-goldens test/tool/app_icon_test.dart
#   tool/icon/resize_app_icon.sh
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MASTER="$HERE/test/tool/goldens/app_icon_1024.png"
OUT="$HERE/ios/Runner/Assets.xcassets/AppIcon.appiconset"

[ -f "$MASTER" ] || { echo "FAIL: no master at $MASTER — run the golden first."; exit 1; }

command -v ffmpeg >/dev/null || {
  echo "FAIL: ffmpeg is needed to drop the alpha channel (brew install ffmpeg)."
  exit 1
}

# THE ALPHA CHANNEL COMES OFF FIRST, and it is not optional: App Store Connect
# rejects an icon that HAS one, even when every pixel in it is opaque — and the
# rejection arrives at upload, long after the build looked fine. A Flutter
# golden is always captured RGBA, so the master always has one. `sips` cannot
# remove a channel; ffmpeg re-encodes to rgb24 losslessly, which is exact for
# the flat colours this mark is made of.
# Both names are cleaned up: appending .png to mktemp's path leaves the
# zero-byte file it actually created behind on every run.
STEM="$(mktemp -t mindforge-icon)"
OPAQUE="$STEM.png"
trap 'rm -f "$STEM" "$OPAQUE"' EXIT
ffmpeg -y -loglevel error -i "$MASTER" -pix_fmt rgb24 "$OPAQUE"

# Every file Contents.json names, with the pixel size it must be.
while IFS='|' read -r name size; do
  [ -z "$name" ] && continue
  sips -s format png -z "$size" "$size" "$OPAQUE" --out "$OUT/$name" >/dev/null
  printf '  %-34s %sx%s\n' "$name" "$size" "$size"
done <<'SIZES'
Icon-App-20x20@1x.png|20
Icon-App-20x20@2x.png|40
Icon-App-20x20@3x.png|60
Icon-App-29x29@1x.png|29
Icon-App-29x29@2x.png|58
Icon-App-29x29@3x.png|87
Icon-App-40x40@1x.png|40
Icon-App-40x40@2x.png|80
Icon-App-40x40@3x.png|120
Icon-App-60x60@2x.png|120
Icon-App-60x60@3x.png|180
Icon-App-76x76@1x.png|76
Icon-App-76x76@2x.png|152
Icon-App-83.5x83.5@2x.png|167
Icon-App-1024x1024@1x.png|1024
SIZES

echo "OK: app icon regenerated from the rendered master."
