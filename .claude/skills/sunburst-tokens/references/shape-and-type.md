# Shape and type

The non-colour values: border width, radius, hard-offset elevation, press physics, spacing, and the ten type steps. Sources: `system.html` §05–§07 and §04.

## Border width — one value, `borderWidth: 3`

There is no thin variant, no hairline, no 1px divider. `--bw:3px` is on every surface in the system, and it is the reason the whole app survives greyscale and low vision: the boundary is always ink at 3px, so no surface depends on its fill contrasting with the fill behind it. A "quieter card" is a shallower shadow (e2 → e1), never a thinner border.

## Radius — the nesting rule

| Token | Value | What earns it |
|---|---|---|
| `radiusSm` | 10 | Inner chips, swatches, the ink key on an answer button |
| `radiusMd` | 16 | HUD pills, grid tiles, icon buttons, snackbars |
| `radiusLg` | 22 | Cards and buttons — the default raised surface |
| `radiusXl` | 28 | Hero panels, the stimulus card, sheets, dialogs |
| `radiusPill` | 999 | Anything holding a single short value: badges, best-pills, segmented items |

The rule is nesting, not size preference: **the bigger the surface, the bigger the radius**. A 22 card holding a 16 tile holding a 10 chip reads as nested plastic. A 22 card holding a 22 tile reads as sloppy rounding, and a 16 card holding a 22 tile reads as broken.

## Elevation — offset scales, blur is always zero

| Token | Offset | What earns it |
|---|---|---|
| *(no field)* | `const <BoxShadow>[]` | Flat on the page: pressed buttons, found tiles, the ghost button, the locked card. system.html calls it `--sh-0`; Dart calls it `PopElevation.flat` (`sunburst-components`). `SunburstShape` declares no `e0` — the absence of a shadow is not a value to interpolate |
| `e1` | `Offset(3, 3)` | HUD pills, chips, small tiles, icon buttons |
| `e2` | `Offset(5, 5)` | Cards and buttons — the default raised surface |
| `e3` | `Offset(8, 8)` | Hero panels, the stimulus card, modal sheets |
| `e4` | `Offset(10, 10)` | One per screen, maximum: the countdown ring |

`blurRadius` and `spreadRadius` are `0` at every step, and the shadow colour is `border` — the same ink as the edge. That is what makes a surface read as die-cut card stock rather than as a floating panel, and it is why `Material(elevation:)`, `Card(elevation:)` and `AppBar` elevation are all zeroed in `buildSunburstTheme()`. `SunburstShape.shadow()` is the only place a `BoxShadow` is constructed; `scripts/check_raw_values.sh` fails any non-zero `blurRadius:`/`spreadRadius:` outside `lib/theme/`.

**Press physics.** `pressTranslate(e) = Offset(e.dx - 1, e.dy - 1)` and the shadow collapses to `pressedShadow = Offset(1, 1)`. An e2 button moves 4px and keeps a 1px shadow; an e1 pill moves 2px. Two scales ship, both transcribed: `pressScale: 0.98` (`.btn/.ans/.gcard:active`) and `pressScaleSmall: 0.97` (`.tile/.tgl/.tab/.seg-i:active`). The sketched Dart block in §12 collapses them to a single 0.98; the rendered gallery wins, which is the same precedent §04 gets over §12 on a weight. The geometry is derived, never typed per component — that is what keeps every pressable surface in the app moving by the same law. `PopElevation` (`sunburst-components`) is the only thing that picks between the two scales; the animation and haptic that ride on the geometry belong to `sunburst-motion-and-haptics`.

**Disabled.** The border drops to `borderDisabled` and the shadow drops one step *and* repaints in `borderDisabled` — `.btn[disabled]{box-shadow:3px 3px 0 var(--ink-3)}` is an e1 shadow in ink-3, not `--sh-0`. §11's "shadow goes soft-ink" names a colour this system has no token for; `borderDisabled` is the DERIVED stand-in and is flagged as such in `palette-and-slots.md`.

**Focus.** `focusGap: 3` then `focusWidth: 4` of `focusRing`. The cream gap is load-bearing: it is what keeps the ring at 4.12:1 measured against `surface` on every fill, instead of 2.8:1 measured directly against sunshine.

## Spacing — static, not themeable

`space1..space7` = 4 / 8 / 12 / 16 / 20 / 28 / 40, plus three constants app.html holds fixed on all eight screens: `gutter = 20`, `cardGap = 16`, `cardPadding = 16`. These are `static const` on `SunburstShape` rather than instance fields, because a gutter is layout rhythm — it is identical in every conceivable variant, and interpolating one mid-animation is meaningless. Hard shadows already add visual space, which is why the gaps run tighter here than a soft-shadow system would want. The screen-level application of the rhythm is owned by `sunburst-shell-screens`.

## Type — ten steps, and no eleventh

| Step | Font | Weight | Size / line-height | Tracking | Usage |
|---|---|---|---|---|---|
| `scoreHero` | Fredoka | 700 | 76 / 0.95 | −3.04 | The results score. One per screen. Tabular |
| `displayXl` | Fredoka | 700 | 42 / 1.0 | −1.26 | Celebration titles, countdown copy |
| `displayL` | Fredoka | 700 | 33 / 1.02 | −0.83 | Screen titles: Home, Stats, Settings |
| `title` | Fredoka | 600 | 21 / 1.1 | −0.32 | Card titles, sheet titles |
| `numericHud` | Fredoka | 700 | 22 / 1.18 | −0.44 | Every live HUD value. Tabular |
| `button` | Fredoka | 600 | 18 / 1.22 | 0 | All buttons and nav labels. Never all-caps |
| `body` | Nunito | 700 | 15 / 1.4 | 0 | Instructions, descriptions, settings rows |
| `caption` | Nunito | 700 | 13 / 1.38 | 0 | Card subtitles, helper text |
| `label` | Fredoka | 600 | 10 / 1.4 | +1.4 | The only place caps are allowed |
| `stimulus` | Fredoka | 700 | 78 / 1.0 | +0.78 | Stroop word only. Outline + pattern mandatory |

Tracking is stated in px: the design gives percentages (−4%, −3%, −2.5%, −1.5%, −2%, +14%), and Flutter's `letterSpacing` is logical pixels, so each is `percent × fontSize`.

**Where the design doc contradicts itself:** §04 specifies `title` and `button` as Fredoka **600**; the Dart transcription in §12 writes `w700` for both, and `app.html` renders `.btn{font-weight:700}` and `.gcard h4{font-weight:600}`. §04 wins for both steps — it is the rendered specimen the whole scale was measured from, and it is the only place the two steps are shown side by side. `SunburstType.button` is therefore `w600`, and every sibling skill quotes it that way: `sunburst-components`' catalog, and any screen in `sunburst-shell-screens` that labels a button. This is the one open question worth putting to the designer; until it is answered, do not "fix" a call site to 700, and do not change this without changing `system.html` §04 first.

`fontFeatures: [FontFeature.tabularFigures()]` is mandatory on `scoreHero` and `numericHud` and is already baked into those steps. A HUD value whose digits change width jitters the pill every second of a run, which reads as a rendering bug.

Fredoka blurs below ~12px, which is why `label` is the only step under 13 and buys legibility back with caps and +14% tracking, and why body copy is Nunito rather than Fredoka. This is also why nothing scales type down to fit: `accessibility-as-code` owns the ban on `FittedBox` / clamped `textScaler`.

## Fonts are bundled, never fetched

MindForge is offline: no `google_fonts`, no runtime fetch, no HTTP code path at all. Four faces ship as assets — Fredoka 600 and 700, Nunito 700 and 800. The reference page's Google Fonts URL also requests Fredoka 400/500 and Nunito 400/600; those are for the HTML page and are **not** shipped.

```yaml
# pubspec.yaml
flutter:
  fonts:
    - family: Fredoka
      fonts:
        - asset: assets/fonts/Fredoka-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Fredoka-Bold.ttf
          weight: 700
    - family: Nunito
      fonts:
        - asset: assets/fonts/Nunito-Bold.ttf
          weight: 700
        - asset: assets/fonts/Nunito-ExtraBold.ttf
          weight: 800
```

**Nunito 800 is bundled, and no type step spends it.** §04's ten steps put `body` and `caption` at Nunito 700, but `app.html` renders a handful of strings at weight 800 — the home greeting, the section labels, the locked-card line, the chart axis captions — and the README lists 700 *and* 800 as the shipped body weights. The face ships so those screens can be built without a re-bundle. It does **not** license an eleventh step invented here: if a screen genuinely needs 800, the step earns a name in `system.html` §04 first and arrives through this table. Until then those strings take `body` or `caption`.

Ship `assets/fonts/OFL.txt` and register it through `LicenseRegistry.addLicense` — both families are SIL Open Font License. If you bundle the variable `.ttf` instead of static instances, drive weight with `FontWeight` (which drives the `wght` axis) and never a redundant `FontVariation`; the mechanics are owned by `design-system-structure`.

**DERIVED:** the design names "Baloo 2" as Fredoka's fallback, but an offline app ships no third face, so `SunburstType.displayFallback` is `['Nunito']` — the bundled body face is the closest round sans actually present on the device.

## The six shell steps (E08 T08.0)

`system.html` section 04 names ten steps; E05 added two and E08 adds six, taking the scale to
eighteen. These six are **DERIVED from `app.html`**, which is authoritative over the eight screens,
and each carries its rule in a `//` at the point of declaration.

| Step | `app.html` rule | Value |
|---|---|---|
| `titleBar` | `.topbar .tt` | Fredoka 600 / 17 / -.01em |
| `greeting` | `.greet` | Nunito 800 / 14 / +.02em — the one BODY step of the six |
| `sectionLabel` | `.hero .kicker` | Fredoka 600 / 10 / +.16em, uppercase |
| `heroTitle` | `.hero .ht` | Fredoka 700 / 38 / line .98 / -.03em |
| `countdownNumeral` | `.bigring b` | Fredoka 700 / 132 / line 1 / -.04em, tabular |
| `statValue` | `.statbox b` | Fredoka 700 / 26 / -.02em, tabular |

Two rules they inherit rather than restate:

- **The tracking is zeroed under Arabic script** by `SunburstType.forScript`. `.16em` on a cursive
  script breaks the joins — a spaced-out `کۆ` is broken text, not a style. No screen conditionalises.
- **The uppercase in `sectionLabel` is authored into the ARB value**, per locale, and never applied
  with `toUpperCase()`. Persian and Sorani have no case, so casing in Dart is a no-op that still
  states the author thought it was a rendering decision. A test greps `lib/features/` and `lib/ui/`
  for both casing calls.
