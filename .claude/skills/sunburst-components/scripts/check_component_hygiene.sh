#!/usr/bin/env bash
# Usage: check_component_hygiene.sh [target_dir]   (default: lib)
# Guards the Sunburst Pop surface contract: hard offset shadows only, ink borders
# only, no Material elevation, no press timing typed into a widget. Every raised
# surface goes through PopSurface, which reads SunburstShape.shadow() from
# lib/theme/. A new need is a new token slot, never a `// ignore`.
set -euo pipefail

TARGET="${1:-lib}"
if [ ! -d "$TARGET" ]; then
  echo "note: '$TARGET' not found; nothing to scan."
  exit 0
fi

GEN_RE='\.g\.dart$|\.freezed\.dart$|\.drift\.dart$'
# Comment-only lines are blanked (never dropped, so grep -n line numbers still
# match the source) — a `// WRONG` teaching example must not fail the gate.
STRIP_COMMENTS='s@^[[:space:]]*//.*@@'

fail=0
report() { # report <file> <hits> <label>
  if [ -n "$2" ]; then
    echo "== $1 ==  ($3)"
    printf '%s\n' "$2"
    fail=1
  fi
}

while IFS= read -r -d '' f; do
  if printf '%s\n' "$f" | grep -qE "$GEN_RE"; then continue; fi
  in_theme=0
  case "$f" in */theme/*) in_theme=1 ;; esac
  src="$(sed -E "$STRIP_COMMENTS" "$f")"

  # 1+2. Blur and spread are 0 everywhere, theme included: a blurred shadow is a
  # different design system, and the focus ring is a stroke so spread is never
  # needed. `0`, `0.0` and `0,` are the only accepted values.
  report "$f" "$(printf '%s\n' "$src" | grep -nE '(blur|spread)Radius:' \
      | grep -vE '(blur|spread)Radius:[[:space:]]*0(\.0+)?[[:space:],)]' || true)" \
    "blur/spread must be 0 — hard offset shadows only"

  # 3. Material's elevation model has no representation here, and the only way to
  # spell it is a NUMBER. Flagging numeric values only is what lets the rule pass
  # `elevation: 0` (lib/theme/ switching Material's own off), `PopElevation.e2`,
  # and a resolved local or field — `elevation: elevation`, `widget.elevation` —
  # which is how `sunburst-game-surfaces`' boards and `PopSurface` itself are
  # written. A name-based allow-list cannot see through a local and would fail
  # the sibling skills' own examples.
  report "$f" "$(printf '%s\n' "$src" \
      | grep -nE '(^|[^A-Za-z0-9_])elevation:[[:space:]]*(const[[:space:]]+)?[0-9]' \
      | grep -vE 'elevation:[[:space:]]*0(\.0+)?[[:space:],)]' || true)" \
    "Material elevation — use PopSurface + PopElevation"

  if [ "$in_theme" -eq 0 ]; then
    # 4. BoxShadow is constructed in one place: SunburstShape.shadow() in lib/theme/.
    report "$f" "$(printf '%s\n' "$src" | grep -nE '(^|[^A-Za-z0-9_])BoxShadow\(' || true)" \
      "BoxShadow outside lib/theme/ — call shape.shadow(offset, ink)"

    # 5. Every border is ink: colors.border, colors.borderDisabled, a local named
    # `ink` resolved from one of those, or Colors.transparent for a reserved edge.
    # awk rejoins a constructor that spans lines and reports the line it opened on,
    # so a `color:` on its own line cannot slip past a line-oriented grep.
    #
    # The check is "does this constructor name a slot it may not", not "does the
    # token sit immediately after `color:`" — a disabled edge is legitimately
    # written as a conditional between two legal slots
    # (`state == disabled ? colors.borderDisabled : colors.border`), and the
    # earlier positional form failed that.
    report "$f" "$(printf '%s\n' "$src" | awk '
        function check(   tmp, tok, bad, named) {
          if (b !~ /color:/) return
          bad = 0; named = 0
          tmp = b
          while (match(tmp, /colors\.[A-Za-z0-9_]+/)) {
            tok = substr(tmp, RSTART, RLENGTH); tmp = substr(tmp, RSTART + RLENGTH)
            named = 1
            if (tok != "colors.border" && tok != "colors.borderDisabled") bad = 1
          }
          tmp = b
          while (match(tmp, /Colors\.[A-Za-z0-9_]+/)) {
            tok = substr(tmp, RSTART, RLENGTH); tmp = substr(tmp, RSTART + RLENGTH)
            named = 1
            if (tok != "Colors.transparent") bad = 1
          }
          if (b ~ /Color\(0x/) bad = 1
          # No slot named at all: fall back to the local-name convention, so
          # `color: ink` passes and `color: brandTint` does not. POSIX awk has no
          # \b, so the word boundary is spelled out as a character class.
          if (!named && b !~ /(^|[^A-Za-z0-9_])(ink|border|borderDisabled)([^A-Za-z0-9_]|$)/) bad = 1
          if (bad) print n ":" b
        }
        /Border\.all\(|BorderSide\(|Border\(/ && !n { n = NR; b = "" }
        n { b = b " " $0; if (index($0, ")")) { check(); n = 0 } }' || true)" \
      "border colour must be the border slot (or borderDisabled / transparent)"

    # 6. Press timing is a token: durTap on easePop, collapsed by motion.resolve().
    # A Duration literal at a `duration:` site is a hand-typed animation.
    report "$f" "$(printf '%s\n' "$src" \
        | grep -nE 'duration:[[:space:]]*(const[[:space:]]+)?Duration\(' || true)" \
      "raw animation duration — use motion.resolve(context, motion.durTap)"
  fi
done < <(find "$TARGET" -name '*.dart' -type f -print0)

if [ "$fail" -ne 0 ]; then
  echo "FAIL: Sunburst surface contract violated. Compose PopSurface and read tokens; see references/surface-and-press.md."
  exit 1
fi
echo "OK: hard shadows only, ink borders only, no Material elevation, no raw press timing."
