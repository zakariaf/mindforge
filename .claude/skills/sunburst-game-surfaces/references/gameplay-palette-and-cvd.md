# The gameplay palette and colour vision deficiency

Stroop Rush asks "which hue is this glyph painted in". That makes red/green confusion a **correctness
bug**, not a polish item — a deuteranope playing the default palette is not having a worse
experience, they are being scored on a question they cannot read. Hexes and ΔE76 figures below are
from `system.html` §03; contrast on cream and label contrast are from its measured table; the
**on-paper** column and every **greyscale ratio** are derived here: on-paper = on-cream × 1.0558
(cream's relative luminance is 0.9445, paper's is 1.0), and greyscale ratios are
`(L_hi + 0.05)/(L_lo + 0.05)` — all reproducible from the hexes with `Color.computeLuminance()`.

## Default palette

| Slot | Hex | `PlayFill` | On cream `#FFF8EC` | On paper `#FFFFFF` | Label on the fill | Set |
|---|---|---|---|---|---|---|
| `playRed` | `#D81E2C` | stripe | 4.8:1 | 5.1:1 | paper 5.1:1 | default |
| `playBlue` | `#1F6BE0` | solid | 4.7:1 | 5.0:1 | paper 5.0:1 | default |
| `playGreen` | `#157A39` | dot | 5.1:1 | 5.4:1 | paper 5.4:1 | default |
| `playYellow` | `#F5B301` | ring | **1.76:1 — fails** | **1.85:1 — fails** | ink 8.3:1 | default |
| `playPurple` | `#6A45E8` | solid | 5.5:1 | 5.8:1 | cream 5.5:1 | Blitz |
| `playOrange` | `#C24409` | stripe | 4.8:1 | 5.1:1 | paper 5.1:1 | Blitz |
| `playPink` | `#C2185B` | stripe | 5.6:1 | 5.9:1 | paper 5.9:1 | CB only |

Yellow's 1.76:1 is why **the stimulus is never a bare glyph**: a 6px ink stroke pass under the fill
makes effective contrast ink-on-cream (14.55:1) and turns hue into decoration on an already-legible
shape. Both figures are `sunburst-tokens`' — the same numbers its rule 6 and
`references/palette-and-slots.md` carry; do not re-round them here. Answer keys solve it separately — `answerLabel()` returns `textPrimary` for yellow and
`surfaceRaised` for everything else, so there is no "pick one" case at any call site.

## Colour-blind palette (Settings → "Colour-blind friendly palette")

The toggle re-points four slots. It is **not** a red↔blue swap, and it deliberately does **not**
substitute orange for red — those two simulate to within ΔE76 5.2 of each other.

| Slot | Default | With the setting ON | `PlayFill` (unchanged) |
|---|---|---|---|
| `PlayAnswer.red` | `playRed #D81E2C` | `cbPink #C2185B` | stripe |
| `PlayAnswer.green` | `playGreen #157A39` | `cbOrange #C24409` | dot |
| `PlayAnswer.blue` | `playBlue #1F6BE0` | `cbBlue #1F6BE0` | solid |
| `PlayAnswer.yellow` | `playYellow #F5B301` | `cbYellow #F5B301` | ring |

The enum case is the **slot**, not the hue: `PlayAnswer.green` under the flag paints orange and is
labelled "Orange". `purple` and `orange` have no CB mapping, so **the answer set is capped at these
four whenever the flag is on.**

## Dichromat analysis

Simulated under Viénot–Brettel–Mollon (1999):

| Pair | Deuteranope ΔE76 | Protanope ΔE76 | Verdict |
|---|---|---|---|
| default `playRed` ↔ `playGreen` | 27.0 | 17.2 | worst pair in the default set |
| CB set, worst pair | 37.7 | 49.0 | +39% deutan, +185% protan |
| `playRed` ↔ `playOrange` | ≈5.2 | ≈5.2 | why orange never replaces red |

`playRed #D81E2C` simulates to `#7E7E1A` and `playGreen #157A39` to `#68683C` for a deuteranope —
two olives. The other simulated values are **not recorded in `system.html`**; do not quote a number
for them until it has been measured.

## Greyscale — the channel the CB palette does *not* fix

Relative luminance (WCAG) and the resulting contrast between answer hues:

| Slot | Relative luminance | Closest other answer | Greyscale ratio |
|---|---|---|---|
| `playRed` | 0.157 | `playOrange` 0.156 | **1.00:1** |
| `playOrange` | 0.156 | `playRed` | **1.00:1** |
| `playBlue` | 0.162 | `playRed` 0.157 | **1.02:1** |
| `playGreen` | 0.144 | `playOrange` 0.156 | 1.06:1 |
| `playPurple` | 0.131 | `playPink` 0.129 | 1.01:1 |
| `playPink` | 0.129 | `playPurple` | 1.01:1 |
| `playYellow` | 0.517 | any of the above | ≥ 2.67:1 |

Worst pair in the CB set is `cbBlue` ↔ `cbOrange` at **1.03:1**. So: switching palettes moves the
dichromat floor a long way and moves the greyscale floor essentially nowhere. **Only the `PlayFill`
pattern separates these hues in a screenshot, in a print-out, or for an achromatope** — which is why
the pattern is always on, in both palettes, and is painted on the key *and* into the glyph.

Yellow is the one default answer that separates on luminance alone. That is a reason you may drop
yellow from a set without losing separation — never a reason to ship the others bare.

## Known defect: the Blitz six-set collides

`PlayAnswer` binds `purple → solid` and `orange → stripe`, which duplicates `blue → solid` and
`red → stripe`. In a Blitz round offering all six, two pairs share a pattern *and* red/orange share a
greyscale luminance to three decimals. Blitz therefore violates the "claim an unused fill pattern"
rule as tokenised today. The fix is **two new ink patterns** (a cross-hatch and a chevron, drawn at
the same 5/9px and 4/7px pitch family as the existing four) authored in `sunburst-tokens` — **derived,
not in `system.html`**. Until then, cap Blitz at four answers or accept that the pattern channel is
carrying only four of six.

## Toggle semantics

1. The flag is **captured into the round's immutable state at round start**, from settings, once.
2. The **generator** reads it: with the flag on it draws only from `{red, green, blue, yellow}`.
3. The **painter** reads the same captured value via `colors.answerColour(a, colourBlind: …)`. No
   widget branches on the setting itself.
4. Changing the setting mid-run does not alter the running round. It applies to the next round.
5. The Settings row previews exactly what it swaps in — blue, yellow, orange, pink, each keeping its
   ink pattern (`app.html` screen 08).

The failure this prevents: generate `{red, green, purple, orange}`, then swap at paint time →
`{pink, orange, purple, orange}`. Two identical keys, one labelled "Green" and one "Orange", and a
round that cannot be answered correctly.

## The test that pins it

```dart
// test/theme/gameplay_palette_test.dart
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

const t = SunburstColors.sunburstPop;
const defaultSet = [PlayAnswer.red, PlayAnswer.blue, PlayAnswer.green, PlayAnswer.yellow];

test('every answer label clears AA on its own fill', () {
  for (final cvd in [false, true]) {
    for (final a in defaultSet) {
      final fill = t.answerColour(a, colourBlind: cvd);
      expect(contrastRatio(t.answerLabel(a), fill), greaterThanOrEqualTo(4.5), reason: '$a cvd=$cvd');
    }
  }
});

test('each palette offers four distinct hues and four distinct patterns', () {
  for (final cvd in [false, true]) {
    final fills = {for (final a in defaultSet) t.answerColour(a, colourBlind: cvd)};
    expect(fills, hasLength(4), reason: 'a duplicate key is an unanswerable round');
  }
  expect({for (final a in defaultSet) a.fill}, hasLength(4));
});

test('red and blue are indistinguishable in greyscale — the pattern is load-bearing', () {
  final red = t.answerColour(PlayAnswer.red).computeLuminance();
  final blue = t.answerColour(PlayAnswer.blue).computeLuminance();
  expect((red - blue).abs(), lessThan(0.02)); // if this ever passes by luminance,
});                                           // review the pattern pass, do not drop it
```

Pair it with a **greyscale golden** of the answer row plus the stimulus (`widget-golden-and-a11y-testing`).
The acceptance question is one sentence: *from the greyscale image alone, can you match each key to
the stimulus?* If the answer is "only by reading the words", the pattern pass is broken.

