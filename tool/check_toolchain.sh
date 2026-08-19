#!/usr/bin/env bash
# check_toolchain.sh — assert the host toolchain matches .toolchain.json.
#
# One record, one check. A version drift becomes a failing check rather than a
# mystery three epics later: the Flutter version is what re-renders goldens and
# perturbs seeded determinism between this laptop and the CI runner.
#
# Exit codes
#   0  every pinned tool matches (or a host-tool mismatch was downgraded to WARN)
#   1  a pinned tool does not match
#   2  the record, or a tool needed to read it, is missing
#
# Environment
#   TOOLCHAIN_HOST_TOOLS=warn   report Xcode/CocoaPods mismatches as WARN, exit 0.
#                               CI sets this: the GitHub runner image's Xcode is
#                               not ours to pin, and failing on a fact we do not
#                               control is not a gate.
#
# Observed states while this script was written (T01.1, TDD — script before record):
#   1. no .toolchain.json                          -> exit 2, "missing .toolchain.json"
#   2. .toolchain.json with flutter 3.0.0          -> exit 1, "flutter: expected 3.0.0, actual 3.44.6"
#   3. .toolchain.json with xcode 1.0, no env      -> exit 1, "xcode: expected 1.0, actual 26.6"
#   4. the same, TOOLCHAIN_HOST_TOOLS=warn         -> exit 0, "WARN xcode: expected 1.0, actual 26.6"
#   5. the true values                             -> exit 0

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RECORD="$ROOT/.toolchain.json"

fail=0

if [[ ! -f "$RECORD" ]]; then
  echo "FAIL: missing .toolchain.json at $RECORD — the toolchain record is the single source of truth"
  exit 2
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "FAIL: python3 not found — needed to parse .toolchain.json (ships with the Xcode command line tools)"
  exit 2
fi

read_key() {
  python3 -c 'import json,sys
d=json.load(open(sys.argv[1]))
for k in sys.argv[2].split("."):
    d=d.get(k, "") if isinstance(d, dict) else ""
print(d)' "$RECORD" "$1"
}

compare() {
  # compare <label> <expected> <actual> <hard|soft>
  local label="$1" expected="$2" actual="$3" severity="$4"
  if [[ "$expected" == "$actual" ]]; then
    echo "OK   $label: $actual"
    return 0
  fi
  if [[ "$severity" == "soft" && "${TOOLCHAIN_HOST_TOOLS:-}" == "warn" ]]; then
    echo "WARN $label: expected $expected, actual $actual (TOOLCHAIN_HOST_TOOLS=warn)"
    return 0
  fi
  echo "FAIL $label: expected $expected, actual $actual"
  fail=1
}

# --- Flutter and Dart: hard. This is the version that moves goldens. ---
if ! command -v flutter >/dev/null 2>&1; then
  echo "FAIL: flutter not on PATH"
  exit 2
fi
machine="$(flutter --version --machine 2>/dev/null)"
if [[ -z "$machine" ]]; then
  echo "FAIL: 'flutter --version --machine' produced no output"
  exit 2
fi
actual_flutter="$(printf '%s' "$machine" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("frameworkVersion",""))')"
actual_dart="$(printf '%s' "$machine" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("dartSdkVersion",""))')"

compare "flutter" "$(read_key flutter)" "$actual_flutter" hard
compare "dart"    "$(read_key dart)"    "$actual_dart"    hard

# --- Xcode and CocoaPods: soft under TOOLCHAIN_HOST_TOOLS=warn. ---
actual_xcode="$(xcodebuild -version 2>/dev/null | head -1 | awk '{print $2}')"
compare "xcode" "$(read_key xcode)" "${actual_xcode:-<not found>}" soft

actual_pod="$(pod --version 2>/dev/null)"
compare "cocoapods" "$(read_key cocoapods)" "${actual_pod:-<not found>}" soft

exit "$fail"
