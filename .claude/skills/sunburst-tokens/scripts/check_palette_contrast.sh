#!/usr/bin/env bash
# Usage: check_palette_contrast.sh [theme_file] [primitives_file]
#        defaults: lib/theme/sunburst_colors.dart, lib/theme/sunburst_primitives.dart
# Recomputes WCAG 2.2 contrast for every text/surface pair the theme DECLARES,
# straight from the hexes in the source. Pure bash + awk, no dependencies.
#
# The theme file declares its own pairs in comments:
#     // @contrast <foreground> <background> <min_ratio>  free text
# Names resolve through the const instance (`textPrimary: _P.ink,`) down to a
# primitive (`static const ink = Color(0xFF2B1B4D);`). Both are matched line by
# line, so keep one `slot: _P.primitive,` per line in the const instance.
# `_P` lives in its own file in the repo, so the sibling primitives file is read
# alongside the theme file; pass one combined file (examples/sunburst_theme.dart)
# and it resolves from that alone.
# Floors: 4.5 body text, 3.0 large text and non-text UI (SC 1.4.3 / 1.4.11).
# An unresolvable name is a failure, not a skip — a typo must not read as a pass.
set -euo pipefail

FILE="${1:-lib/theme/sunburst_colors.dart}"
if [ ! -f "$FILE" ]; then
  echo "note: '$FILE' not found; nothing to scan."
  exit 0
fi

# Where `_P` is declared. Explicit second argument wins; otherwise look for the
# sibling primitives file. Absent is fine — a combined file carries both.
PRIM_FILE="${2:-$(dirname "$FILE")/sunburst_primitives.dart}"
SOURCES=("$FILE")
if [ "$PRIM_FILE" != "$FILE" ] && [ -f "$PRIM_FILE" ]; then
  SOURCES+=("$PRIM_FILE")
fi

PRIMS="$(sed -nE 's%^[[:space:]]*static const[[:space:]]+([A-Za-z0-9_]+)[[:space:]]*=[[:space:]]*Color\(0x[0-9A-Fa-f]{2}([0-9A-Fa-f]{6})\).*%\1 \2%p' "${SOURCES[@]}")"
ALIAS="$(sed -nE 's%^[[:space:]]*([A-Za-z0-9_]+):[[:space:]]*_P\.([A-Za-z0-9_]+),.*%\1 \2%p' "${SOURCES[@]}")"
PAIRS="$(sed -nE 's%^[[:space:]]*//[[:space:]]*@contrast[[:space:]]+([A-Za-z0-9_]+)[[:space:]]+([A-Za-z0-9_]+)[[:space:]]+([0-9.]+).*%\1 \2 \3%p' "$FILE")"

if [ -z "$PAIRS" ]; then
  echo "== $FILE =="
  echo "no '// @contrast <fg> <bg> <min>' declarations found"
  echo "FAIL: theme declares no contrast pairs, so this gate proves nothing. Declare every text/surface pair."
  exit 1
fi

{
  [ -n "$PRIMS" ] && printf '%s\n' "$PRIMS" | sed 's/^/P /'
  [ -n "$ALIAS" ] && printf '%s\n' "$ALIAS" | sed 's/^/A /'
  printf '%s\n' "$PAIRS" | sed 's/^/C /'
} | awk -v file="$FILE" '
function hx(s,   i,c,n){n=0;for(i=1;i<=length(s);i++){c=index("0123456789ABCDEF",toupper(substr(s,i,1)))-1;n=n*16+c}return n}
function lin(v,   s){s=v/255.0; if(s<=0.04045) return s/12.92; return exp(2.4*log((s+0.055)/1.055))}
function lum(h){return 0.2126*lin(hx(substr(h,1,2)))+0.7152*lin(hx(substr(h,3,2)))+0.0722*lin(hx(substr(h,5,2)))}
function ratio(a,b,   la,lb,t){la=lum(a);lb=lum(b);if(la<lb){t=la;la=lb;lb=t}return (la+0.05)/(lb+0.05)}
function resolve(n){ if(n in hex) return hex[n]; if((n in alias) && (alias[n] in hex)) return hex[alias[n]]; return "" }
$1=="P"{hex[$2]=toupper($3)}
$1=="A"{alias[$2]=$3}
$1=="C"{n++; fg[n]=$2; bg[n]=$3; min[n]=$4}
END{
  # Buffered so a failing run can print the `== <file> ==` header first, the way
  # every other gate in this repo reports.
  bad=0
  for(i=1;i<=n;i++){
    f=resolve(fg[i]); b=resolve(bg[i])
    if(f=="" || b==""){
      out[i]=sprintf("  UNRESOLVED  %s on %s — no primitive behind %s", fg[i], bg[i], (f==""?fg[i]:bg[i]))
      offending[++nb]=out[i]; bad++; continue
    }
    r=ratio(f,b)
    if(r+0.005 < min[i]+0){
      out[i]=sprintf("  FAIL  %-22s on %-18s #%s on #%s = %.2f:1  (needs %.1f:1)", fg[i], bg[i], f, b, r, min[i])
      offending[++nb]=out[i]; bad++
    } else {
      out[i]=sprintf("  ok    %-22s on %-18s = %5.2f:1  (>= %.1f)", fg[i], bg[i], r, min[i])
    }
  }
  if(bad>0){
    printf "== %s ==\n", file
    for(i=1;i<=nb;i++) print offending[i]
    printf "FAIL: %d of %d declared pair(s) below floor in %s. Fix the hex or restate the pair — never lower the floor.\n", bad, n, file
    exit 1
  }
  for(i=1;i<=n;i++) print out[i]
  printf "OK: %d declared text/surface pairs meet their WCAG floor.\n", n
}
'
