# E08 on-simulator sign-off: eight screens, four locales, two directions

Run on the canonical device — `MindForge iPhone 14`,
`C13DDC02-375D-4E1B-8F81-44EB407D09A4`, iOS 18.6, exactly 390x844 logical
points at DPR 3. Debug build, `flutter build ios --simulator --debug`, installed
with `simctl install`, and launched once per screen:

```bash
xcrun simctl launch <udid> io.applander.mindforge \
  --route=/settings -AppleLanguages "(fa)" -AppleLocale fa_IR
```

`--route` reaches the app because `initialLocationProvider` honours the
platform's initial route. That is a real feature, not a test hook: iOS hands one
over for a Universal Link, a Handoff continuation or a shortcut, and an app that
ignores it drops the player at Home with no sign it was asked for anywhere else.
It defaults to `/`, so the ordinary launch is unchanged.

**One simulator note, not a product defect.** `-AppleLanguages` had no effect on
an app that had already launched in English: iOS reads the argument domain into
the container's `NSUserDefaults` and the earlier value wins. `simctl uninstall`
before the first non-English launch fixes it, and the app follows the device
language correctly from a clean install.

## What the comparison found

Nine defects, every one of them invisible to 1,842 passing tests. This is the
whole argument for working agreement 9 being a human step.

| # | Screen | Found | Fixed by |
|---|---|---|---|
| 1 | detail, countdown, play, results | **Rendered on black with yellow-underlined text.** They sit outside `StatefulShellRoute`, so they never inherited `NavShell`'s `Scaffold`, and without a `Material` ancestor Flutter paints the debug double-underline on the window's own background. | `RunScaffold`, and `all_screens_test` now asserts each screen's own ancestry rather than the harness's |
| 2 | home | The game card had **no art frame**. `.gart` is a 64pt cream square with the standard ink edge; a definition contributes only what goes inside it. | The frame moved into `GameCard` |
| 3 | home | Then I built it **80pt**, by wrapping the 8pt padding around the box instead of inside it. | Caught on the second capture |
| 4 | home | The locked slot was a `GameCard` with a flag and **said the same thing twice** — "Not yet unlocked" as its tagline, "Coming soon" as a badge. | `LockedGameSlot`, which has room for one status line |
| 5 | home | The streak glyph was a **water drop**. A point over a semicircle is a teardrop; a flame's shape is the inner lick. | Transcribed from `app.html`'s own path |
| 6 | detail, results, stats | **Ten labels were in sentence case** where the design draws them uppercase. | Cased in the ARB, per locale — see below |
| 7 | detail | **Chill** was selected by default, because it is `offered.first`. | Classic where it is offered |
| 8 | settings | Row labels sat **in the middle of the row**: two loose flexible halves in a `spaceBetween` row put a shrink-wrapped label wherever its share leaves it. | The label's half is tight again |
| 9 | results, play | The results primary was sunshine where the design has leaf; the play band had **no progress track** and the pause control sat on a row of its own, costing the board twelve points of height. | Both moved into the band; the track is absent, not empty, when a board reports no progress |

**The casing went into the ARB, not into a Dart `toUpperCase()`.** Case is a
language property: Persian and Sorani have none, so their values stay in natural
form and `SunburstType.forScript` already drops the tracking there, because
Arabic script is cursive and positive tracking breaks the joins. A Dart uppercase
would also be locale-blind about Turkish dotted i and German eszett.

## Screens compared

Every screen was compared in the five-step order — structure, spacing rhythm,
surface construction, type role, sampled hex.

| Screen | LTR reference | RTL reference | Verdict |
|---|---|---|---|
| Home | `01-home.png` | `rtl/01-home.png` | matches after 2–5 above |
| Game detail | `02-game-detail.png` | `rtl/02-game-detail.png` | matches after 1, 3, 6, 7 |
| Countdown | `03-countdown.png` | `rtl/03-countdown.png` | matches after 1; idle beat dots were the ray colour and all but vanished into the burst |
| Play | `04-stroop-rush.png` | `rtl/04-stroop-rush.png` | chrome matches after 1 and 9; **the board is a placeholder** |
| Results | `06-results.png` | `rtl/06-results.png` | matches after 1 and 9; the trio needs a completed run and does not appear on a cold deep link |
| Stats | `07-stats.png` | `rtl/07-stats.png` | matches after 6; **the chart needs run history** and is absent with none, by design |
| Settings | `08-settings.png` | `rtl/08-settings.png` | matches after 8 |

`05-schulte-grid.png` has no counterpart to compare: it is a board, and boards
are E09 and E10. The play chrome was compared against `04`'s band instead.

## What is deliberately different from the reference

Recorded rather than fixed, each with its reason.

- **The Daily Mix card says "Today's pick: <game>", not "3 games, 4 minutes".**
  The card routes to ONE seeded game. A curated three-game mix is a product
  feature nobody has built, and printing that line would be a sentence about
  software that does not exist. `dailyMixSummary` stays in the ARB for the epic
  that ships the real mix.
- **The play band carries a pause control and `app.html` draws none.** Its band
  is three pills and a track. iOS's edge-swipe does pause the run, and it is not
  a thing a player finds mid-Blitz.
- **The streak flame is stroked, not coral-filled.** `app.html` fills it with
  `var(--coral)` under an ink stroke. A two-tone glyph would need a second colour
  channel through the whole glyph API for one mark; the silhouette carries the
  meaning and the chip's text carries the fact.
- **The wordmark does not scale with Dynamic Type.** It is a logotype: iOS ships
  app marks as artwork. At scale 2.0 on a 320pt screen the tile and the name are
  wider than the header in all four locales. The accessible name is the
  `Semantics` label, which a screen reader announces regardless.
- **The three tab headers scroll away** rather than staying fixed. Identical at
  rest. Home's header in Sorani at text scale 2.0 is 618 points tall on a 320x693
  screen, which leaves the pane below it a negative height, and a fixed header
  cannot be told to be shorter without clamping the text.
- **Placeholder games.** Reaction Lab, Grid Sweep and Pattern Trace stand in for
  Stroop Rush, Schulte Grid and N-Back. E09 deletes them in its first commit.

## `de` and `ckb`, which have no reference

Checked for fit and script correctness only.

| Locale | Checked | Result |
|---|---|---|
| `de` | Settings and game detail | No overflow, no clipping. `SCHWIERIGKEIT` and `DEINE BESTLEISTUNG` fit their rows; the segmented control holds Chill / Klassisch / Blitz |
| `ckb` | Settings | Right-to-left throughout, Vazirmatn, no tofu. The toggle words `کراوە` / `داخراوە` widen their tracks rather than overflowing — which is the flexible word doing its job, and the reason it is flexible |

Attached: `e08-home-en.png`, `e08-home-fa.png`, `e08-settings-ckb.png`.
