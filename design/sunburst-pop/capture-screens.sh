#!/usr/bin/env bash
# Usage: ./capture-screens.sh [--rtl]
#
# Regenerates screens/*.png — the reference screenshots every implementation is
# compared against. Run this whenever app.html changes, and commit the result.
#
# Each screen is rendered standalone at 390x844 (iPhone 14 class) at 2x by
# injecting a CSS override that isolates one <figure> and strips the device
# bezel, then screenshotting it with headless Chrome. The screen is pinned with
# position:fixed so no ancestor's centring can offset it in the capture.
set -euo pipefail

CHROME="${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RTL=0
case "${1:-}" in
  "")     RTL=0 ;;
  --rtl)  RTL=1 ;;
  # An unrecognised argument used to fall through and silently capture LTR, so
  # `--rtl-only` or `--RTL` regenerated screens/, printed eight OK lines, and
  # left the operator believing the RTL set had been refreshed.
  *) echo "FAIL: unknown argument '$1'. Usage: $0 [--rtl]" >&2; exit 2 ;;
esac

SRC="$HERE/app.html"
# The COMMITTED source, kept even when SRC is repointed at the rendered RTL
# copy below: the manifest must record what a reviewer can diff, not a temp
# file that no longer exists.
SOURCE_HTML="$HERE/app.html"
DEST="$HERE/screens"
if [ "$RTL" -eq 1 ]; then DEST="$HERE/screens/rtl"; fi
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Captures land in a staging directory and are moved into place only once ALL
# of them succeeded. Writing straight into the tracked directory meant a Chrome
# failure on screen five left four new and four old PNGs behind — a set that
# looks complete and is half a version old.
OUT="$TMP/out"
mkdir -p "$OUT"

if [ ! -x "$CHROME" ]; then
  echo "FAIL: Chrome not found at '$CHROME'. Set CHROME=/path/to/chrome and retry." >&2
  exit 1
fi
if [ ! -f "$SRC" ]; then
  echo "FAIL: '$SRC' not found." >&2
  exit 1
fi

if [ "$RTL" -eq 1 ]; then
  # Rendered into the temp directory and never committed: a second copy of the
  # design source in git is how two sources of truth are born. The Persian
  # strings come straight out of lib/l10n/app_fa.arb via strings-fa.json, so
  # the reference and the app cannot disagree.
  python3 "$HERE/rtl/render-rtl.py" "$SRC" "$HERE/rtl/strings-fa.json" \
    "$TMP/app-rtl.html"
  SRC="$TMP/app-rtl.html"
fi

mkdir -p "$OUT"

# figure id -> output basename. Keep in sync with the <figure id> values in app.html.
SCREENS=(
  "s1:01-home"
  "s2:02-game-detail"
  "s3:03-countdown"
  "s4:04-stroop-rush"
  "s5:05-schulte-grid"
  "s6:06-results"
  "s7:07-stats"
  "s8:08-settings"
)

for entry in "${SCREENS[@]}"; do
  id="${entry%%:*}"
  name="${entry##*:}"

  cat > "$TMP/inject.css" <<CSS
html,body{margin:0!important;padding:0!important;overflow:hidden!important;background:#fff!important}
.wrap{margin:0!important;padding:0!important;max-width:none!important;width:390px!important;background:none!important}
.wrap > *:not(.gallery){display:none!important}
.gallery{display:block!important;margin:0!important;padding:0!important;gap:0!important;grid-template-columns:none!important;max-width:none!important}
.fig{display:none!important}
.fig#${id}{display:block!important;margin:0!important;padding:0!important}
.fig#${id} figcaption{display:none!important}
.fig#${id} .slot{display:block!important;margin:0!important;padding:0!important;background:none!important}
.fig#${id} .phone{margin:0!important;padding:0!important;border:0!important;border-radius:0!important;box-shadow:none!important;width:390px!important;height:844px!important;background:none!important;transform:none!important}
.fig#${id} .screen{position:fixed!important;left:0!important;top:0!important;margin:0!important;border:0!important;border-radius:0!important;box-shadow:none!important;width:390px!important;height:844px!important;overflow:hidden!important;transform:none!important}
CSS

  python3 - "$SRC" "$TMP/inject.css" "$TMP/$name.html" <<'PY'
import sys
src, css, dst = sys.argv[1], sys.argv[2], sys.argv[3]
html = open(src, encoding='utf-8').read()
i = html.lower().rfind('</head>')
if i == -1:
    raise SystemExit('FAIL: no </head> in ' + src)
style = '<style id="capture-override">\n' + open(css, encoding='utf-8').read() + '\n</style>\n</head>'
open(dst, 'w', encoding='utf-8').write(html[:i] + style + html[i + len('</head>'):])
PY

  # --virtual-time-budget lets the Google Fonts webfonts land before the capture.
  "$CHROME" --headless=new --disable-gpu --hide-scrollbars \
    --force-device-scale-factor=2 --virtual-time-budget=6000 \
    --window-size=390,844 --screenshot="$OUT/$name.png" \
    "file://$TMP/$name.html" >/dev/null 2>&1

  # -s alone would pass on the PREVIOUS run's file, which is why the capture
  # writes to an empty staging directory: a Chrome invocation that exits 0
  # without writing is then indistinguishable from nothing at all, and fails.
  if [ ! -s "$OUT/$name.png" ]; then
    echo "FAIL: $name.png was not written." >&2
    exit 1
  fi
  printf '  %-22s %s\n' "$name.png" "$(du -h "$OUT/$name.png" | cut -f1)"
done

for entry in "${SCREENS[@]}"; do
  name="${entry##*:}"
  mv "$OUT/$name.png" "$DEST/$name.png"
done

# The manifest is what ties the committed PNGs to the sources they were
# rendered from. Without it the reference and app.html drift silently and CI
# cannot tell -- that happened: app.html carried data-num="640" while the
# committed 06-results.png still showed a Latin 640, with every gate green.
# test/policy/reference_manifest_test.dart recomputes every hash here.
python3 "$HERE/rtl/write-manifest.py" "$DEST" "$SOURCE_HTML" "$HERE/rtl/strings-fa.json" "$RTL"

echo "OK: ${#SCREENS[@]} reference screens written to ${DEST#"$HERE/"}/."
