#!/usr/bin/env bash
# ios_simulator.sh — drive the ONE simulator every screenshot comparison in this
# project is made on.
#
# Every reference PNG under design/sunburst-pop/screens/ is 780x1688 pixels:
# 390x844 logical points at 2x. `MindForge iPhone 14` is exactly 390x844 logical
# points. No iPhone 16-class simulator matches — iPhone 16 is 393x852, 16 Pro is
# 402x874 — so a screenshot taken on those is a comparison against a different
# canvas, and every spacing judgement made from it is wrong by a few points in a
# way that is invisible until it accumulates.
#
# The device is named ONLY in .toolchain.json. This script contains no UDID of
# its own, so there is one place the device is recorded.
#
#   usage: ios_simulator.sh verify | boot | run | shot <path>
#
# Exit codes
#   0  ok
#   1  the recorded device is not on this machine, or its runtime differs
#   2  the record, or a tool needed to read it, is missing
#
# Observed states while `verify` was written (T01.10, TDD — runner before use):
#   1. an unknown UDID in .toolchain.json -> exit 1, prints the UDID looked for
#      and says no `xcrun simctl list devices` line carries it
#   2. the real UDID with runtime "iOS 99.9" -> exit 1, naming both runtimes
#   3. the true record -> exit 0, printing name, UDID, runtime and 390x844

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RECORD="$ROOT/.toolchain.json"

[[ -f "$RECORD" ]] || { echo "FAIL: missing $RECORD"; exit 2; }
command -v python3 >/dev/null 2>&1 || { echo "FAIL: python3 not found"; exit 2; }
command -v xcrun   >/dev/null 2>&1 || { echo "FAIL: xcrun not found — install the Xcode command line tools"; exit 2; }

read_key() {
  python3 -c 'import json,sys
d=json.load(open(sys.argv[1]))
for k in sys.argv[2].split("."):
    d=d.get(k, "") if isinstance(d, dict) else ""
print(d)' "$RECORD" "$1"
}

NAME="$(read_key simulator.name)"
UDID="$(read_key simulator.udid)"
RUNTIME="$(read_key simulator.runtime)"
LOGICAL="$(read_key simulator.logicalSize)"

verify() {
  local line
  line="$(xcrun simctl list devices | grep -F "$UDID" || true)"
  if [[ -z "$line" ]]; then
    echo "FAIL: no device with UDID $UDID on this machine."
    echo "      .toolchain.json records '$NAME' ($RUNTIME, $LOGICAL)."
    echo "      'xcrun simctl list devices' has no line carrying that UDID."
    return 1
  fi

  # simctl groups devices under a "-- iOS 18.6 --" heading, so the runtime is
  # read from the heading above the matching line rather than from the line.
  local actual_runtime
  actual_runtime="$(
    xcrun simctl list devices \
      | awk -v udid="$UDID" '
          /^-- / { rt = $0; gsub(/^-- | --$/, "", rt) }
          index($0, udid) { print rt; exit }
        '
  )"

  if [[ "$actual_runtime" != "$RUNTIME" ]]; then
    echo "FAIL: runtime mismatch for $UDID."
    echo "      .toolchain.json records: $RUNTIME"
    echo "      simctl reports:          ${actual_runtime:-<none>}"
    return 1
  fi

  echo "OK   $NAME"
  echo "     $UDID"
  echo "     $RUNTIME"
  echo "     $LOGICAL logical points — the only geometry a reference PNG can"
  echo "     honestly be compared on"
  return 0
}

boot() {
  # Idempotent: a device that is already Booted is not an error.
  xcrun simctl boot "$UDID" 2>/dev/null || true
  open -a Simulator
}

case "${1:-}" in
  verify) verify ;;
  boot)   verify && boot ;;
  run)    verify && boot && flutter run -d "$UDID" ;;
  shot)
    [[ -n "${2:-}" ]] || { echo "usage: ios_simulator.sh shot <path>"; exit 2; }
    mkdir -p "$(dirname "$2")"
    xcrun simctl io "$UDID" screenshot "$2"
    ;;
  *)
    echo "usage: ios_simulator.sh verify | boot | run | shot <path>"
    exit 2
    ;;
esac
