#!/usr/bin/env bash
# Usage: check_raw_values.sh [target_dir]   (default: lib)
# Sunburst Pop's no-raw-values gate. Every colour, radius, border width, shadow,
# duration, curve and type step lives in lib/theme/**; every other file reads a
# slot off SunburstColors / SunburstShape / SunburstMotion / SunburstType.
# A value you cannot express as a slot is a NEW SLOT, never a `// ignore`.
set -euo pipefail

TARGET="${1:-lib}"
if [ ! -d "$TARGET" ]; then
  echo "note: '$TARGET' not found; nothing to scan."
  exit 0
fi

# Generated files are exempt.
GEN_RE='\.g\.dart$|\.freezed\.dart$|\.drift\.dart$'

# Banned outside */theme/. `Colors.`/`Curves.` are anchored on a non-identifier
# lookbehind so `SunburstColors.of` and `AnswerColours.x` do not trip the gate.
#  - Color(0x / fromARGB / fromRGBO  -> a hex belongs in _P
#  - Colors. / Curves.               -> the framework's opinions, not ours
#  - Duration(milliseconds:|seconds: -> one of durTap/durState/durMove/durCelebrate
#  - Cubic(                          -> easePop/easeOut/easeInOut
#  - BorderRadius/Radius.circular(n) -> radiusSm/Md/Lg/Xl/Pill
#  - fontSize:/fontFamily:/letterSpacing: -> a SunburstType step
#  - blurRadius:/spreadRadius: anything but a literal 0 -> there is no blur in
#    this system at any elevation; PopSurface passes 0 and nothing else may
#    (the surface contract itself is owned by `sunburst-components`)
#  - .withOpacity/.withValues(alpha: -> fading a surface fades its 3px ink
#    border with it, and the border is the brand; recede by changing the fill
PATTERNS='Color\(0x|Color\.fromARGB\(|Color\.fromRGBO\(|(^|[^A-Za-z0-9_])Colors\.|(^|[^A-Za-z0-9_])Curves\.|Duration\((milliseconds|seconds):|(^|[^A-Za-z0-9_])Cubic\(|BorderRadius\.circular\([0-9]|Radius\.circular\([0-9]|fontSize:[[:space:]]*[0-9]|fontFamily:[[:space:]]*[^)]|letterSpacing:[[:space:]]*-?[0-9]|(blur|spread)Radius:[[:space:]]*[^0[:space:],)]|\.withOpacity\(|\.withValues\([[:space:]]*alpha:'

# Legitimate exceptions, stripped BEFORE the scan rather than used to drop the
# whole line, so `x ? Colors.transparent : Color(0xFFAA0000)` still fails.
ALLOW_STRIP='s/Colors\.transparent//g; s/Duration\.zero//g'

fail=0
while IFS= read -r -d '' f; do
  case "$f" in */theme/*) continue ;; esac
  if printf '%s\n' "$f" | grep -qE "$GEN_RE"; then continue; fi

  # sed preserves the line count, so grep -n numbers still match the source.
  hits="$(sed -E "$ALLOW_STRIP" "$f" | grep -nE "$PATTERNS" || true)"
  if [ -n "$hits" ]; then
    echo "== $f =="
    printf '%s\n' "$hits"
    fail=1
  fi
done < <(find "$TARGET" -name '*.dart' -type f -print0)

if [ "$fail" -ne 0 ]; then
  echo "FAIL: raw aesthetic value(s) outside */theme/. Read a Sunburst slot, or add one (see references/adding-a-token.md)."
  exit 1
fi
echo "OK: no raw aesthetic values outside */theme/."
