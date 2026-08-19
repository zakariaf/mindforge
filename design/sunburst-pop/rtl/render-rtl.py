#!/usr/bin/env python3
"""Render a Persian, right-to-left copy of app.html into a temp directory.

The output is NEVER committed. Committing a 75 KB duplicate of the design
source is exactly how two sources of truth are born; this reads `app.html` and
`strings-fa.json` and writes a throwaway.

  usage: render-rtl.py <app.html> <strings-fa.json> <out.html>
"""

import json
import re
import os
import sys

# Vazirmatn is loaded from the file the APP BUNDLES, not from a webfont CDN.
#
# Two reasons, and the first is a measured defect. A CDN fetch that fails —
# captive portal, offline moment — renders the whole set in the macOS system
# Arabic fallback: different digit shapes, different weights, no tofu to give it
# away, chrome exits 0, and eight plausible wrong PNGs get committed as the
# reference every RTL screen is built against. Nothing downstream can tell.
# Second, reading assets/fonts/Vazirmatn[wght].ttf makes the reference and the
# app the same bytes rather than the same font name.
_FONT = "../../../assets/fonts/Vazirmatn[wght].ttf"

# The weights and the line factor come from SunburstType.forScript, because the
# reference is compared against what the app renders. Leaving app.html's Latin
# weights and line-heights standing made every Persian screenshot lighter and
# tighter than the build — and the README then tells the reviewer to conclude
# the APP's line factor is wrong.
RTL_HEAD = """
<style>
  @font-face {
    font-family: "Vazirmatn";
    src: url("__FONT__") format("truetype-variations");
    font-weight: 100 900;
    font-display: block;
  }
  /* Bind the Arabic face to both type roles, matching SunburstType.forScript:
     one family, heavier for display, lighter for body. The mirroring must come
     from dir="rtl" and the stylesheet's own logical properties, so anywhere the
     CSS uses a physical side and fails to mirror is a real defect to fix in
     app.html rather than to paper over here. */
  [dir="rtl"] { --display: "Vazirmatn", sans-serif; --body: "Vazirmatn", sans-serif; }
  /* SunburstType.arabicDisplayWeight / arabicBodyWeight / arabicLineFactor. */
  [dir="rtl"] * { letter-spacing: 0 !important; line-height: 1.35em !important; }
  [dir="rtl"] h1, [dir="rtl"] h2, [dir="rtl"] h3, [dir="rtl"] b, [dir="rtl"] .ht,
  [dir="rtl"] .ask, [dir="rtl"] .hero p, [dir="rtl"] .wm { font-weight: 900 !important; }
  [dir="rtl"] p, [dir="rtl"] s, [dir="rtl"] em, [dir="rtl"] small,
  [dir="rtl"] span, [dir="rtl"] div { font-weight: 500 !important; }
</style>
"""


def main() -> int:
    src, strings_path, out = sys.argv[1], sys.argv[2], sys.argv[3]

    html = open(src, encoding="utf-8").read()
    data = json.load(open(strings_path, encoding="utf-8"))
    strings, numbers = data["strings"], data["numbers"]

    # One unconditional rewrite. The previous targeted replace plus a
    # conditional regex fallback had a branch that could only fire when the
    # replace had already failed AND no lang= survived.
    html = re.sub(r"<html\b[^>]*>", '<html lang="fa" dir="rtl">', html, count=1)

    swapped = 0

    def swap(match: "re.Match[str]") -> str:
        nonlocal swapped
        tag, close = match.group(1), match.group(3)

        key = re.search(r'data-l10n="([^"]+)"', tag)
        if key:
            # A message the design renders twice with different arguments —
            # streakMultiplier is x7 in the HUD and x11 on results — carries a
            # variant, and the dump emits "key/variant" beside "key".
            variant = re.search(r'data-l10n-variant="([^"]+)"', tag)
            name = f"{key.group(1)}/{variant.group(1)}" if variant else key.group(1)
            if name in strings:
                swapped += 1
                return tag + strings[name] + close

        num = re.search(r'data-num="([^"]+)"', tag)
        if num and num.group(1) in numbers:
            swapped += 1
            return tag + numbers[num.group(1)] + close

        return match.group(0)

    html = re.sub(
        r"(<[a-z][a-z0-9]*\b[^<>]*data-(?:l10n|num)=[^<>]*>)"
        r"((?:[^<>]|<br\s*/?>)*)"
        r"(</[a-z][a-z0-9]*>)",
        swap,
        html,
    )

    # THE COVERAGE GUARANTEE, here rather than in a sibling test. The pattern
    # above matches LEAF elements only: a marked node that later gains a nested
    # <span> stops matching, silently keeps its English text, and the reference
    # screenshot ships in the wrong language with nothing red. The renderer is
    # the only thing that knows which nodes it actually swapped, so it is the
    # only thing that can say so.
    marked = len(re.findall(r"data-(?:l10n|num)=", html))
    if swapped != marked:
        print(
            f"render-rtl: {marked} marked nodes but only {swapped} swapped. "
            "A data-l10n or data-num node is not a leaf, or its key is missing "
            "from strings-fa.json.",
            file=sys.stderr,
        )
        return 1

    # THE SECOND HALF, and the one that matters more. The count above only
    # covers nodes that were MARKED. A number that was never given a data-num
    # at all is invisible to it — measured: <b>640<em>ms</em></b> on the results
    # screen shipped a Latin 640 into the Persian reference, because 640 is a
    # bare text node beside a sibling element and the swap pattern matches leaf
    # elements only. Three such nodes had already been found BY EYE, which is
    # not a method.
    #
    # So: inside the eight .screen subtrees — which is exactly what
    # capture-screens.sh photographs, and nothing else on the page — no visible
    # text may hold an ASCII digit. The one deliberate exception carries
    # data-latin: the iOS status-bar clock, which is system chrome and
    # stays Latin on a real fa or ckb device.
    stray = _unmarked(html, r"[0-9]")

    if stray:
        print(
            "render-rtl: ASCII digits survived into the rendered screens: "
            + "; ".join(stray[:10]),
            file=sys.stderr,
        )
        return 1

    # And the same question for WORDS, which is how the other three escapes got
    # through: an unmarked node is invisible to the marked-vs-swapped count,
    # because nothing was marked, so nothing was missing. `Stroop Rush` sat in
    # 48px Fredoka in the middle of an otherwise Persian game-detail screen
    # under an app bar that read شتاب استروپ.
    #
    # Anything deliberately Latin carries data-latin: the wordmark, the N-Back
    # placeholder name, the language row showing English in English, and the
    # iOS status-bar clock, which is system chrome and stays Latin on a real
    # fa or ckb device.
    english = _unmarked(html, r"[A-Za-z]{2}")

    if english:
        print(
            "render-rtl: untranslated Latin text survived into the rendered "
            "screens: " + "; ".join(english[:10]),
            file=sys.stderr,
        )
        return 1

    # Case-insensitive and by position, exactly as capture-screens.sh does it.
    # html.replace("</head>", ...) is a SILENT no-op on <\/HEAD>, and the whole
    # set would then render in the OS fallback face at exit 0.
    head = html.lower().rfind("</head>")
    if head < 0:
        print("render-rtl: no </head> to inject the font override into", file=sys.stderr)
        return 1
    font = os.path.join(os.path.dirname(os.path.abspath(__file__)), _FONT)
    if not os.path.exists(font):
        print(f"render-rtl: the bundled face is missing: {font}", file=sys.stderr)
        return 1
    html = html[:head] + RTL_HEAD.replace("__FONT__", "file://" + font) + html[head:]

    open(out, "w", encoding="utf-8").write(html)
    print(f"render-rtl: swapped {swapped} nodes, no ASCII digit left on a screen")
    return 0


def _unmarked(html: str, pattern: str) -> "list[str]":
    """Text inside the eight screens that no marked element accounts for.

    Elements carrying `data-l10n`, `data-num` or `data-latin` are removed
    first: those were either swapped, or are a deliberate Latin run such as the
    wordmark, the N-Back placeholder name, the language row showing English in
    English, or the iOS status-bar clock. What is left is text nobody claimed,
    and that is the hole — an unmarked node is invisible to the
    marked-vs-swapped count, because nothing was marked, so nothing was
    missing.
    """
    found = []
    for screen in _screen_subtrees(html):
        text = re.sub(
            r"<[^>]*\bdata-(?:l10n|num|latin)\b[^>]*>.*?</[a-z][a-z0-9]*>",
            "",
            screen,
            flags=re.S,
        )
        text = re.sub(r"<[^>]*>", "\n", text)
        found += [
            line.strip() for line in text.split("\n") if re.search(pattern, line)
        ]
    return found


def _screen_subtrees(html: str) -> "list[str]":
    """Every `<div class="screen">...</div>` subtree, by tag depth.

    Only these are photographed — capture-screens.sh pins `.fig#id .screen` to
    the viewport and shoots that. The rest of the page is the design document
    around them: swatch hexes, figure captions, the token tables. Scanning it
    would report `#FFF8EC` as a stray digit.
    """
    out = []
    for start in [m.start() for m in re.finditer(r'<div class="screen">', html)]:
        depth, i = 0, start
        for tag in re.finditer(r"<(/?)([a-z][a-z0-9]*)\b[^>]*?(/?)>", html[start:]):
            i = start + tag.end()
            if tag.group(3) == "/" or tag.group(2) in ("br", "img", "hr", "input"):
                continue
            depth += -1 if tag.group(1) else 1
            if depth == 0:
                break
        out.append(html[start:i])
    return out


if __name__ == "__main__":
    sys.exit(main())
