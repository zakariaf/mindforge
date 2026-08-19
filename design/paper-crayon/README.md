# MindForge — Paper Crayon

**Files:** [`app.html`](app.html) — all 8 screens as phone mockups · [`system.html`](system.html) — the design system reference.

---

## Personality

A sketchbook come to life. Warm paper, ink outlines that wobble, crayon fills that streak, washi tape holding the cards to the page — a beautifully art-directed activity book rather than an app. It is hand-made without being childish: the charm lives entirely in the shapes and the handwriting, while every number, label and paragraph is set in Nunito so the data never pays for the personality. MindForge has no ads, no accounts and no internet; Paper Crayon is what makes that read as *generosity* instead of *austerity*.

---

## Palette

### Primitives — the crayon box

| Token | Hex | Role | Contrast on `--surface` |
|---|---|---|---|
| `--paper` | `#FDF6E3` | The page. Warm, aged, never pure white | base |
| `--graphite` | `#33302E` | All body text and every drawn outline | **12.14:1** |
| `--crayon-red` | `#E5544B` | Danger, timer bar, Stroop red | 3.41:1 · fills only |
| `--marker-blue` | `#3D7DD8` | Focus ring, Schulte cues, Stroop blue | 3.80:1 · fills only |
| `--grass` | `#58B368` | Success fills and the toggle body | 2.41:1 · fills only |
| `--sunny` | `#F2B705` | Streaks, records, washi tape, Stroop yellow | 1.69:1 · fills only |
| `--violet` | `#8A5FBF` | Brand: primary buttons, active nav, final score | 4.36:1 |

### Paper family — four steps of surface

| Token | Hex | Role |
|---|---|---|
| `--paper-white` | `#FFFCF2` | `--surface-raised` — cards, sheets, tiles |
| `--paper-warm` | `#F8EFD8` | `--surface-sunk` — nav bar, grouped rows |
| `--paper-shade` | `#F0E4C6` | `--surface-deep` — tracks, wells, found tiles |
| `--kraft` | `#E7D5AC` | `--surface-frame` — card stock, device bezel |

### Ink ramp & crayon inks — the text-safe half

Every crayon has a darker **ink** sibling. The crayon fills a shape; the ink writes on paper. This is what keeps the system colourful without ever putting 3:1 text on a page. All ratios on `--surface`.

| Token | Hex | Role | Contrast |
|---|---|---|---|
| `--ink-soft` | `#5E574E` | `--text-secondary` — subtitles, hints | 6.60:1 |
| `--ink-faint` | `#736B5E` | `--text-muted` — 10px eyebrows, HUD keys | 4.87:1 |
| `--ink-ghost` | `#C2B9A6` | `--text-disabled` — inert controls only | 1.81:1 |
| `--red-ink` | `#BE382F` | Error text, the wrong-tile numeral | 5.13:1 |
| `--blue-ink` | `#2A5FA8` | Schulte "next" numeral, informational values | 5.90:1 |
| `--green-ink` | `#2D7A45` | Accuracy, the toggle tick, the found-tile strike | 4.89:1 |
| `--sunny-ink` | `#8A6200` | Streak values, records, the chart's "best" guide line | 5.09:1 |
| `--violet-ink` | `#6F45A0` | Final score, active nav label, brand text | 6.42:1 |

Tints (`--red-tint #FBE3E0`, `--blue-tint #E2ECFB`, `--green-tint #E3F3E7`, `--sunny-tint #FDF1D0`, `--violet-tint #EFE7F8`) are the large-fill backgrounds; each carries its matching ink at ≥ 4.5:1 (4.52 / 5.34 / 4.58 / 4.88 / 5.75).

### Deep crayons — the Stroop stimulus ramp

The stimulus word is the one place a crayon has to behave as **text**, and a text ratio cannot be rescued by an outline. Green and yellow therefore get a deeper sibling; red and blue already clear the floor and are unchanged.

| Token | Hex | Role | Contrast on `--surface-raised` |
|---|---|---|---|
| `--grass-deep` | `#3F814B` | `--stim-green` — the Stroop word in green | **4.59:1** |
| `--gold-deep` | `#A17300` | `--stim-yellow` — the Stroop word in yellow | **4.12:1** |

The word is set at 104px, so the applicable floor is 3:1 (large text) — both clear it with margin, and the glyph also carries a 2px graphite outline as a second, independent boundary. Never use this ramp below 24px, and never use the chip fills for the word.

### Semantic slots

`--surface` · `--surface-raised` · `--surface-sunk` · `--surface-deep` · `--surface-frame` · `--text-primary` · `--text-secondary` · `--text-muted` · `--text-disabled` · `--accent` / `--accent-ink` / `--accent-tint` · `--success` / `--success-ink` · `--warning` / `--warning-ink` · `--danger` / `--danger-ink` · `--focus-ring` · `--stroke` · `--stroke-soft` · `--on-accent` · `--stim-red` / `--stim-blue` / `--stim-green` / `--stim-yellow`

These are the only names a widget may reference. Primitives are private. Two of them carry usage rules that are not obvious from the name:

- **`--stroke-soft` is decoration only.** It composites to about 1.70:1, so it may be a divider, a dashed grouping strip or the nav's top edge — never a tappable control's only boundary. Anything you can act on keeps the full `--stroke`.
- **`--on-accent` has no headroom.** It is 4.58:1 on `--accent` at full opacity; adding alpha to it (even `.92`) drops it below 4.5:1.

---

## Type pairing

| Face | Google Fonts name | Used for |
|---|---|---|
| Display handwriting | **Caveat** (700) | Once per screen: "Ready to train?", "Nice run!", screen titles on Stats/Settings |
| Everyday hand | **Patrick Hand** (400) | Card titles, button labels, HUD values, grid numerals, the final score |
| Everything you read | **Nunito** (400/600/700/800/900) | Paragraphs, subtitles, list rows, settings copy, chart axes, all dense data |

```
https://fonts.googleapis.com/css2?family=Caveat:wght@500;600;700&family=Nunito:wght@400;600;700;800;900&family=Patrick+Hand&display=swap
```

The published scale, and there is nothing between the steps:

- **Nunito** — 10 / 12 / 13 / 15 / 18
- **Patrick Hand** — 17 / 20 / 23 / 26 / 34 / 50 / 76 / 104
- **Caveat** — 36 / 52 / 190

Rules that are not negotiable: handwriting never goes below **17px** (the sticker step — stickers, badges, mode chips, the status-bar clock), never sets more than about four words, never carries an error message and **never sets a paragraph or a data value** — chart values, stat units and list-row titles are Nunito. Numerals are always tabular. No fractional sizes: a 12.5px or a 14.5px in a diff means someone eyeballed it.

Fallback stacks avoid Comic Sans deliberately — the brief's guardrail is "charming but not childish", and Comic Sans is the first thing a missing-font frame would reach for. Both hands fall back through `Chalkboard SE` / `Bradley Hand` / `ui-rounded` instead. In Flutter, bundle all three as assets — never `google_fonts`, because an offline app must not have a network dependency in its first frame.

---

## When to pick this direction

**Pick Paper Crayon when:**

- The app should feel like a **gift or a hobby**, not a discipline tool. Brain training is voluntary; nothing here nags.
- You want **each game to keep its own character**. Wobbly outlines, rotations and crayon fills absorb wildly different board designs without the shell falling apart — the Stroop stimulus and the Schulte 5×5 sit inside identical chrome and still feel like different games.
- The product is a long-lived **engine**. Hand-drawn shapes hide the seams when game #7 arrives with an odd aspect ratio or an unusual control.
- You are competing on charm and want people to screenshot it.
- Offline-and-free is the pitch, and you need it to read as warmth rather than as a missing feature.

**Pick a different direction when:** the roadmap is heavy on leaderboards and long histories; you need a dark mode; the audience is clinical or corporate; or you need to look like a serious performance tool at first glance.

---

## Risks — read before shipping

1. **Handwriting hurts dense data.** This is the direction's central tax. Patrick Hand and Caveat are banned from paragraphs, tables and anything that scrolls, so the more data screens the roadmap adds, the more the app drifts toward plain Nunito and the personality thins out exactly where you need it. Stats is already the least "Paper Crayon" screen in the set — treat that as the ceiling, not the floor.
2. **Two of the four Stroop chip fills fail 3:1 on their own.** Green is 2.54:1 and yellow is 1.77:1 against `--surface-raised`. WCAG 1.4.11 is satisfied by the 2.5px graphite outline (12.76:1), which makes that outline **load-bearing** — a designer who "cleans it up" breaks accessibility on the app's core mechanic. The same dependency applies to the timer bar: `--danger` on `--surface-deep` is 2.91:1 and is rescued only by the 2.5px graphite cap on the fill's leading edge. Do not remove either.
3. **Colour cannot be the channel that carries a Stroop answer.** Under deuteranopia `#E5544B` and `#58B368` simulate to 1.18:1 of each other; every pair in the four-colour set lands under 3:1, and no four-hue set clears 3:1 between all six pairs while staying legible on warm paper. So the redundant channel is **shape and pattern, printed on the stimulus as well as on the chips** — solid circle, hatched square, dotted triangle, cross-hatched diamond — plus each chip's printed name at 12.76:1. The colour-blind palette (`[--red-ink, --blue-ink, --graphite, --sunny]`) maximises *lightness* separation, not hue separation; violet is excluded because it simulates to 1.07:1 against marker blue. If the shapes are ever made always-on, the Settings subtitle changes with them.
4. **No dark mode.** Crayon on paper inverted becomes chalk on slate, which is a different design system, not a variant. If dark mode is a launch requirement, this direction costs a second full system.
5. **Localisation.** Caveat and Patrick Hand have limited script coverage. Plan a Nunito fallback for the display face and accept a flatter look in Cyrillic, Greek, Arabic and CJK locales.
6. **Rotation and wobble can look sloppy at scale.** The discipline is: rotations only between −1.5° and 1.5°, never two adjacent cards at the same angle, and alternating `--r-card` / `--r-card2` down a list. Without that rule it stops reading as hand-drawn and starts reading as broken.
7. **Motion must be decoration, never state.** Everything gets "stamped" in 150–250ms, and under *Reduce motion* all three durations collapse to zero with a pixel-identical end state. Put the resting transform on the element, never in the last keyframe — `animation:none` throws the 100% frame away and takes every resting tilt with it. If a screen only makes sense once it has animated, it is wrong.
8. **The mockups clip; the build must not.** Every screen in `app.html` is a fixed 390×844 box with `overflow:hidden`, which is correct for a static device mockup and wrong as a specification. In Flutter: no `MediaQuery.withClampedTextScaling`, no `FittedBox` and no `TextOverflow.ellipsis` to make the Stroop stimulus or a Settings row fit. The board reflows at the largest system text scale; it does not shrink. The design-review sweep includes a largest-text-scale pass on Stroop and Settings specifically.

---

## Implementation note

Every colour in both HTML files is declared as a custom property on `:root` and referenced by `var()` — there is not one raw hex below `:root` in either stylesheet (the only matches are documentation text and inline `style="...var(--token)"` attributes). That is the same discipline the Flutter codebase uses, so the mockup models it rather than cheating it. `system.html` closes with a complete `MindforgeTokens` `ThemeExtension` carrying these exact hex values, ready to transcribe into `lib/theme/mindforge_tokens.dart`.
