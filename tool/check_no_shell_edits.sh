#!/usr/bin/env bash
# Usage: tool/check_no_shell_edits.sh [base_ref]   (default: origin/main)
#
# Shipping a game must add zero lines to lib/features/**.
#
# NOT WIRED INTO CI, deliberately: a permanent "no PR may touch lib/features"
# gate would block every future shell epic. This is a required pre-PR step for a
# GAME epic, and its output goes in the PR body. The durable half is
# test/policy/engine_seam_test.dart, which CI already runs.
#
# If it fails, stop. Do not edit a shell screen. Record what the shell could not
# express, and widen GameDefinition or BoardSnapshot for every game at once.
set -euo pipefail

BASE_REF="${1:-origin/main}"
BASE="$(git merge-base "$BASE_REF" HEAD)"
CHANGED="$(git diff --name-only "$BASE"...HEAD -- lib/features || true)"

if [ -n "$CHANGED" ]; then
  printf '%s\n' "$CHANGED"
  echo "FAIL: shipping a game must add zero lines to lib/features/**."
  echo "      The fix is a game-agnostic widening of GameDefinition or"
  echo "      BoardSnapshot, never a special case in a shell screen."
  exit 1
fi

echo "OK: lib/features/** untouched by $(git rev-parse --abbrev-ref HEAD)."
