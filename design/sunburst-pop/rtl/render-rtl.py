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

    html = html.replace('<html lang="en">', '<html lang="fa" dir="rtl">', 1)
    if "<html lang=" not in html:
        html = re.sub(r"<html\b[^>]*>", '<html lang="fa" dir="rtl">', html, count=1)

    def swap(match: "re.Match[str]") -> str:
        tag, text, close = match.group(1), match.group(2), match.group(3)

        key = re.search(r'data-l10n="([^"]+)"', tag)
        if key and key.group(1) in strings:
            return tag + strings[key.group(1)] + close

        num = re.search(r'data-num="([^"]+)"', tag)
        if num and num.group(1) in numbers:
            return tag + numbers[num.group(1)] + close

        return match.group(0)

    html = re.sub(
        r"(<[a-z][a-z0-9]*\b[^<>]*data-(?:l10n|num)=[^<>]*>)([^<>]*)(</[a-z][a-z0-9]*>)",
        swap,
        html,
    )
    html = html.replace("</head>", RTL_HEAD + "</head>", 1)

    open(out, "w", encoding="utf-8").write(html)
    return 0


if __name__ == "__main__":
    sys.exit(main())
