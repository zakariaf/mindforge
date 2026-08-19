#!/usr/bin/env bash
# Usage: check_game_palette.sh [target_dir]   (default: lib)
# Guards the two-tier colour rule under <target>/games/**:
#   1. a game may not declare a Color — it declares a GameAccent case instead;
#   2. a game may import only the theme SLOT files, never sunburst_primitives.dart
#      (the hexes) or sunburst_theme.dart (the composition root);
#   3. a gameplay COLOUR (play*/cb*/answerColour/answerLabel) may be resolved only
#      inside a *_board.dart or a file under a board/ directory. The PlayAnswer /
#      PlayFill enums are deliberately NOT here: they carry no Color, and the round
#      generator in application/ must name them (SKILL.md rule 4);
#   4. a board that reads the gameplay palette IS a GameColourRole.mechanic board,
#      so it may not also read a chrome slot — `danger` resolves to playRed and
#      `success` is a green, and both are answers on a Stroop screen.
set -euo pipefail

TARGET="${1:-lib}"
if [ ! -d "$TARGET" ]; then
  echo "note: '$TARGET' not found; nothing to scan."
  exit 0
fi
GAMES="$TARGET/games"
if [ ! -d "$GAMES" ]; then
  echo "note: '$GAMES' not found; nothing to scan."
  exit 0
fi

GEN_RE='\.g\.dart$|\.freezed\.dart$|\.drift\.dart$'
DECLARES_COLOUR='Color\(0x|Color\.fromARGB\(|Color\.fromRGBO\(|(^|[^A-Za-z0-9_])Colors\.'
THEME_IMPORT="^[[:space:]]*import[^;]*theme/"
THEME_ALLOWED='theme/(sunburst_(colors|shape|motion|type)|game_accent)\.dart'
GAMEPLAY_SLOT='(^|[^A-Za-z0-9_])(play(Red|Blue|Green|Yellow|Purple|Orange|Pink)|cb(Blue|Yellow|Orange|Pink)|answerColour|answerLabel)([^A-Za-z0-9_]|$)'
CHROME_SLOT='\.(accent|accentAlt|accentDeep|success|successDeep|warning|danger|gameStroop|gameSchulte|gameNBack)([^A-Za-z0-9_]|$)'

# Comments are stripped first: a board file is REQUIRED to explain the tier rule,
# and prose like "danger IS playRed" must not be read as a colour read. Then
# Colors.transparent, the one legal Colors.* read. Both are stripped rather than
# line-dropped, and sed preserves the line count, so grep -n still points at the
# real source line and a banned value elsewhere on the line still fails.
ALLOW_STRIP='s@//.*@@; s/Colors\.transparent//g'

fail=0
emit() { # emit <file> <hits> <why>
  echo "== $1 =="
  printf '%s\n' "$2"
  echo "   -> $3"
  fail=1
}

while IFS= read -r -d '' f; do
  if printf '%s\n' "$f" | grep -qE "$GEN_RE"; then continue; fi
  body="$(sed -E "$ALLOW_STRIP" "$f")"

  hits="$(printf '%s\n' "$body" | grep -nE "$DECLARES_COLOUR" || true)"
  if [ -n "$hits" ]; then
    emit "$f" "$hits" "a game declares a GameAccent case, never a Color."
  fi

  hits="$(printf '%s\n' "$body" | grep -nE "$THEME_IMPORT" | grep -vE "$THEME_ALLOWED" || true)"
  if [ -n "$hits" ]; then
    emit "$f" "$hits" "import a theme slot file; primitives and the theme builder are off limits."
  fi

  case "$f" in
    *_board.dart | */board/*) is_board=1 ;;
    *) is_board=0 ;;
  esac

  hits="$(printf '%s\n' "$body" | grep -nE "$GAMEPLAY_SLOT" || true)"
  if [ -n "$hits" ] && [ "$is_board" -eq 0 ]; then
    emit "$f" "$hits" "gameplay colour outside a *_board.dart / board/ file is chrome, and chrome is a hint."
  fi
  if [ -n "$hits" ] && [ "$is_board" -eq 1 ]; then
    chrome="$(printf '%s\n' "$body" | grep -nE "$CHROME_SLOT" || true)"
    if [ -n "$chrome" ]; then
      emit "$f" "$chrome" "a mechanic board may not read a chrome slot: danger IS playRed."
    fi
  fi
done < <(find "$GAMES" -name '*.dart' -type f -print0)

if [ "$fail" -ne 0 ]; then
  echo "FAIL: game palette tier violation(s). See sunburst-game-surfaces SKILL.md rules 1-3."
  exit 1
fi
echo "OK: no Color declarations, stray theme imports, or tier crossings under $GAMES."
