#!/usr/bin/env bash
# Usage: check_shell_boundaries.sh [target_dir]   (default: lib)
# Enforces the shell/game seam. Under lib/games/** a game may not navigate, own a
# screen, own a clock, inset itself, or draw shell chrome; under lib/features/**
# the shell may not import a specific game. See references/shell-game-boundary.md.
set -euo pipefail

TARGET="${1:-lib}"
if [ ! -d "$TARGET" ]; then
  echo "note: '$TARGET' not found; nothing to scan."
  exit 0
fi

# Generated files are exempt.
GEN_RE='\.g\.dart$|\.freezed\.dart$|\.drift\.dart$'

# 1. A game may not navigate, own a screen, own a clock, inset itself, or draw
#    the HUD/chrome. `SafeArea` and the gutter are applied by _BoardPane.
#    Note: `context.go` is matched literally, so a differently-named BuildContext
#    variable slips past it — the go_router import ban is the real backstop.
GAME_BANS='package:go_router|(^|[^A-Za-z0-9_])context\.(go|goNamed|push|pushNamed|pop|replace|pushReplacement)\b'
GAME_BANS="$GAME_BANS"'|(^|[^A-Za-z0-9_])Navigator\.|\bScaffold\(|\bAppBar\(|\bPopScope\(|\bSafeArea\('
GAME_BANS="$GAME_BANS"'|\bHudPill\b|\bPopProgressBar\b|\bPlayBand\b|\bPauseSheet\b|\bCountdownScreen\b|\bPopBottomNav\b'
GAME_BANS="$GAME_BANS"'|\brunNotifierProvider\b|\bStopwatch\(|\bTicker\(|\bcreateTicker\(|\bTimer\.periodic\('

# 2. A shell file may not import or export a specific game. `games/game_registry.dart`
#    is the one allowed target: the pattern needs a SECOND slash, so `games/x/...`
#    fails while `games/game_registry.dart` passes.
SHELL_BANS="(import|export)[[:space:]]+['\"][^'\"]*games/[a-z0-9_]+/"

fail=0
scan() { # scan <dir> <pattern> <label>
  local dir="$1" pattern="$2" label="$3" f hits
  [ -d "$dir" ] || return 0
  while IFS= read -r -d '' f; do
    if printf '%s\n' "$f" | grep -qE "$GEN_RE"; then continue; fi
    hits="$(grep -nE "$pattern" "$f" || true)"
    if [ -n "$hits" ]; then
      echo "== $f == ($label)"
      printf '%s\n' "$hits"
      fail=1
    fi
  done < <(find "$dir" -name '*.dart' -type f -print0)
}

scan "$TARGET/games" "$GAME_BANS" \
  "a game may not navigate, build a Scaffold/AppBar/SafeArea, own a clock, or draw shell chrome"
scan "$TARGET/features" "$SHELL_BANS" \
  "a shell file may not name a specific game"

if [ "$fail" -ne 0 ]; then
  echo "FAIL: shell/game seam violated. A game returns a board widget and a BoardSnapshot; the shell owns routing, chrome, the HUD, the insets and the clock. Add a GameDefinition field instead of special-casing a screen."
  exit 1
fi
echo "OK: no game builds shell chrome, and no shell file names a specific game."
