# Sunburst Pop — MindForge design direction

**Files:** [`app.html`](./app.html) — all 8 screens as phone mockups · [`system.html`](./system.html) — tokens, type, motion, components, Flutter mapping.

## Personality

Arcade-cabinet joy. Every surface is an ink-outlined object sitting *on top of* the page — 3px border, hard offset shadow, no blur — and it visibly presses down when you touch it. It is loud, warm and physical, the way a chunky plastic toy is: the platform is confident enough to host any number of small games, and each game arrives wearing its own colour block without breaking the shell.

## Palette

| Role | Token | Hex | Notes |
| --- | --- | --- | --- |
| App background | `--cream` | `#FFF8EC` | The page everything is printed on |
| Inset wells | `--cream-2` | `#FFEEDA` | Segmented control, progress track, toggle track |
| Raised surfaces | `--paper` | `#FFFFFF` | Cards, HUD pills, grid tiles, sheets |
| Text, borders, shadows | `--ink` | `#2B1B4D` | 14.4:1 on cream. Never pure black |
| Secondary text | `--ink-2` | `#5A4A7D` | 7.3:1 on cream **or paper only**. On a saturated fill the label goes full ink — ink-2 is 2.8:1 on coral |
| Disabled text | `--ink-3` | `#8E80AE` | Disabled controls only, always with a shape change. A status line or a tagline is ink-2 |
| Primary / selected | `--sunshine` | `#FFC53D` | ink label, 9.6:1 |
| Stroop Rush identity | `--coral` | `#FF6B5A` | ink label, 5.4:1 |
| Schulte Grid identity | `--turquoise` | `#22C7B8` | ink label, 7.2:1 |
| Daily Mix / countdown | `--grape` | `#6A45E8` | cream label, 5.5:1 |
| Decoration + focus ring | `--grape-pop` | `#7C5CFF` | never text under 24px (4.1:1) |
| Success / Play / toggle ON | `--leaf` | `#4CC86A` | ink label, 7.1:1 |
| Warning | `--tangerine` | `#FF9330` | held apart from sunshine so caution ≠ primary |

**Gameplay palette** (Stroop answers — tuned for contrast on cream, not for brand harmony):
`playRed #D81E2C` 4.8:1 · `playBlue #1F6BE0` 4.7:1 · `playGreen #157A39` 5.2:1 · `playYellow #F5B301` 1.8:1 · `playPurple #6A45E8` 5.5:1 (Blitz) · `playOrange #C24409` 4.8:1 (Blitz) · `playPink #C2185B` 5.6:1 (CB set).

**Hue is never the only channel.** Under deuteranopia `playRed` and `playGreen` both simulate to olive (ΔE76 27.0), and in flat greyscale red, blue and green sit within 1.02–1.09:1 of each other — so every answer colour also owns an ink **fill pattern** (solid / 45° stripe / dot / ring), painted on the answer key *and* into the stimulus glyph. Match the pattern, not the hue, and the game survives with no colour vision at all. The **Colour-blind friendly palette** setting is a real token swap on top of that: it re-points the four answer slots to `playBlue`, `playYellow`, `playOrange`, `playPink`, taking the worst deuteranope pair from ΔE76 27.0 to 37.7 and the worst protanope pair from 17.2 to 49.0. It does *not* substitute orange for red — those two simulate to within ΔE76 5.2 of each other.

Yellow cannot pass 4.5:1 on cream and still read as yellow, so **the Stroop stimulus is always painted with a 3px ink outline plus an 8px ink hard shadow**, in a pass underneath the pattern fill (a text-shadow paints over a `background-clip:text` fill, so the outline and the fill must be two registered glyph copies). Effective text contrast becomes ink-on-cream (14.4:1) and the hue rides on top of an already-legible shape — which is also exactly the arcade look the direction wants. Answer buttons solve it separately: yellow takes an ink label (8.2:1), everything else takes a paper or cream label.

## Rhythm

Screen gutter is **20** on all eight screens; the gap between stacked cards is **16**; card inner padding is 15–17. Scale: 4 / 8 / 12 / 16 / 20 / 28 / 40. Every pressable surface presses down — e2 surfaces translate 4px, e1 surfaces 2px, both shrink to `scale(.97–.98)` and keep a 1px shadow. Icons are inline SVG at exactly two stroke weights: **2.6** for 22px navigation and status glyphs, **3** for the 18–20px glyphs inside icon buttons and settings rows. No emoji anywhere — a full-colour platform glyph is the one mark that would not look hand-built.

## Type

| Use | Family | Google Fonts name | Weights |
| --- | --- | --- | --- |
| Headings, numbers, buttons, HUD | Display | **Fredoka** (fallback: Baloo 2) | 600, 700 |
| Body, captions, settings rows | Body | **Nunito** | 700, 800 |

```
https://fonts.googleapis.com/css2?family=Fredoka:wght@400;500;600;700&family=Nunito:wght@400;600;700;800&display=swap
```

Fredoka is round, heavy and slightly childlike — it is doing the emotional work. Nunito shares its roundness but stays quiet at 13–15px. All numerals are tabular so HUD values never jitter mid-run. In Flutter, bundle both as assets rather than using `google_fonts` (the app is offline-first).

## Pick this direction when…

- The app should feel like a **toy you want to poke**, not a tool you have to use — short sessions, reward loop as the product.
- The audience is broad and casual: family living rooms, commutes, waiting rooms.
- New games need to ship often. Each one takes a colour and a board; the shell never has to change.
- The pitch needs to survive being seen from the back of a room, or as a 2-second App Store screenshot.

**Pick Cotton Cloud instead** when the product should feel calm, premium and grown-up. **Pick Paper Crayon instead** when it should feel handmade, gentle and personal. Sunburst Pop is the loudest of the three by design; it wins attention and loses subtlety.

## Risks

- **Data density.** Hard shadows and 3px borders eat vertical rhythm. The Stats screen is already the tightest fit of the eight; a leaderboard or a 30-day history would need a quieter card variant (drop to e1, thinner divider) before it works.
- **Fredoka at small sizes.** Below ~12px the heavy round terminals blur together. That is why every label under 12px is uppercase with +14% tracking, and why body copy is Nunito rather than Fredoka.
- **Loudness fatigue.** Saturated blocks are great for a 4-minute session and tiring for a 40-minute one. If session length ever grows, mute the surrounding chrome and keep the colour inside the board.
- **No dark mode.** This direction is committed to light and warm. A dark variant would need a full re-derivation (ink becomes a warm off-white, shadows become a deeper plum) and would not look like the same product — treat it as a separate direction, not a toggle.
- **Yellow, forever.** Any new gameplay colour has to clear 4.5:1 on cream *or* ship with the ink outline, **and** claim an unused fill pattern. Do not let a new game add a pastel to the answer palette, and do not let it ship with hue as its only channel.
