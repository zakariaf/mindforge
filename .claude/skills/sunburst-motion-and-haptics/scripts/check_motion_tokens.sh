#!/usr/bin/env bash
# Usage: check_motion_tokens.sh [target_dir]   (default: lib)
# Three Sunburst Pop motion gates:
#   1. a raw Duration/Curves./Cubic( outside lib/theme/** — there are four
#      durations and three curves, and they live on SunburstMotion.
#   2. HapticFeedback.* outside lib/**/feedback/** — every haptic goes through
#      HapticGateway so the Settings toggle is one gate, not many.
#   3. AnimationController.repeat() in a file with no dispose() AND no .stop() —
#      nothing in this app repeats without an end (system.html section 09).
set -euo pipefail

TARGET="${1:-lib}"
if [ ! -d "$TARGET" ]; then
  echo "note: '$TARGET' not found; nothing to scan."
  exit 0
fi

GEN_RE='\.g\.dart$|\.freezed\.dart$|\.drift\.dart$'
MOTION_RE='Duration\((milliseconds|seconds|microseconds):|(^|[^A-Za-z0-9_])Curves\.|(^|[^A-Za-z0-9_])Cubic\('
HAPTIC_RE='(^|[^A-Za-z0-9_])HapticFeedback\.'
# Neutralized BEFORE the scan so a banned value elsewhere on the same line still fails.
ALLOW_STRIP='s/Duration\.zero//g'

fail=0
while IFS= read -r -d '' f; do
  if printf '%s\n' "$f" | grep -qE "$GEN_RE"; then continue; fi

  case "$f" in
    */theme/*) ;;
    *)
      hits="$(sed -E "$ALLOW_STRIP" "$f" | grep -nE "$MOTION_RE" || true)"
      if [ -n "$hits" ]; then
        echo "== $f =="
        printf '%s\n' "$hits"
        echo "   -> raw motion value; read durTap/durState/durMove/durCelebrate and"
        echo "      easePop/easeOut/easeInOut off SunburstMotion.of(context) instead."
        fail=1
      fi
      ;;
  esac

  case "$f" in
    */feedback/*) ;;
    *)
      hits="$(grep -nE "$HAPTIC_RE" "$f" || true)"
      if [ -n "$hits" ]; then
        echo "== $f =="
        printf '%s\n' "$hits"
        echo "   -> HapticFeedback outside the feedback service; call"
        echo "      ref.read(feedbackServiceProvider).fire(Moment.x) instead."
        fail=1
      fi
      ;;
  esac

  if grep -qE '\.repeat\(' "$f"; then
    if ! grep -q 'dispose(' "$f" || ! grep -qE '\.stop\(' "$f"; then
      echo "== $f =="
      grep -nE '\.repeat\(' "$f"
      echo "   -> repeating animation with no stop condition in the same file."
      echo "      Nothing in Sunburst Pop repeats; write bounded forward(from: 0) calls."
      fail=1
    fi
  fi
done < <(find "$TARGET" -name '*.dart' -type f -print0)

if [ "$fail" -ne 0 ]; then
  echo "FAIL: motion/haptic violation(s) above. Fix the call site or add a catalog row."
  exit 1
fi
echo "OK: motion values tokenized, haptics confined to the feedback service, nothing repeating."
