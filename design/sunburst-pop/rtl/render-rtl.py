#!/usr/bin/env python3
"""Render a Persian, right-to-left copy of app.html into a temp directory.

The output is NEVER committed. Committing a 75 KB duplicate of the design
source is exactly how two sources of truth are born; this reads `app.html` and
`strings-fa.json` and writes a throwaway.

  usage: render-rtl.py <app.html> <strings-fa.json> <out.html>
"""

import json
import re
import sys

# Vazirmatn is the face the app bundles for Arabic script (E03 T03.7). The
# design page fetching a webfont is NOT a violation of the offline constraint:
# CLAUDE.md's rule governs the Flutter binary, and app.html has always fetched
# Fredoka and Nunito the same way. The shipped app bundles its faces.
RTL_HEAD = """
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Vazirmatn:wght@400;500;700;900&display=swap" rel="stylesheet">
<style>
  /* Bind the Arabic face to both type roles, matching SunburstType.forScript:
     one family, heavier for display, lighter for body. Nothing else here
     touches layout — the mirroring must come from dir="rtl" and the
     stylesheet's own logical properties, so that anywhere the CSS uses a
     physical side and fails to mirror is a real defect to fix in app.html
     rather than to paper over here. */
  [dir="rtl"] { --display: "Vazirmatn", sans-serif; --body: "Vazirmatn", sans-serif; }
  [dir="rtl"] * { letter-spacing: 0 !important; }
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
        if key and key.group(1) in strings:
            swapped += 1
            return tag + strings[key.group(1)] + close

        num = re.search(r'data-num="([^"]+)"', tag)
        if num and num.group(1) in numbers:
            swapped += 1
            return tag + numbers[num.group(1)] + close

        return match.group(0)

    html = re.sub(
        r"(<[a-z][a-z0-9]*\b[^<>]*data-(?:l10n|num)=[^<>]*>)([^<>]*)(</[a-z][a-z0-9]*>)",
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
    # data-num-latin: the iOS status-bar clock, which is system chrome and
    # stays Latin on a real fa or ckb device.
    stray = []
    for screen in _screen_subtrees(html):
        text = re.sub(
            r"<[^>]*\bdata-num-latin\b[^>]*>.*?</[a-z][a-z0-9]*>", "", screen, flags=re.S
        )
        text = re.sub(r"<[^>]*>", "\n", text)
        stray += [line.strip() for line in text.split("\n") if re.search(r"[0-9]", line)]

    if stray:
        print(
            "render-rtl: ASCII digits survived into the rendered screens: "
            + "; ".join(stray[:10]),
            file=sys.stderr,
        )
        return 1

    html = html.replace("</head>", RTL_HEAD + "</head>", 1)

    open(out, "w", encoding="utf-8").write(html)
    print(f"render-rtl: swapped {swapped} nodes, no ASCII digit left on a screen")
    return 0


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
