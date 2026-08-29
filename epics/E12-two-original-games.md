# E12 · Digit Bridge and False Light

| | |
|---|---|
| **Branch** | `epic/12-two-original-games` |
| **Depends on** | E03, E04, E07, E08, E09, E10, E11 |
| **Unblocks** | the 1.0.1 resubmission |
| **Status** | Not started |

## The epic

Ship two more games — **Digit Bridge** and **False Light** — entirely under `lib/games/`, plus two
appended lines in `lib/games/game_registry.dart`, two new `GameAccent` cases with the palette slots
they need, and their ARB keys in **four** locales. Both inherit home, game detail, difficulty select,
countdown, play scaffold, pause, results, stats and settings without a line being added to any of
them, and `tool/check_no_shell_edits.sh` proves it for the second time.

This epic exists for a reason that is not "more content", and the reason is worth writing down
because it decides which games get built:

> **App Review rejected 1.0.0 build 1 under Guideline 4.3(a) — Design: Spam**, on the grounds that
> the app "shares a similar binary, metadata, and/or concept as apps submitted to the App Store by
> other developers, with only minor differences."

That is not a claim about the source, and answering it as though it were — the repository is public,
the design system is ours, there is no template — answers a question nobody asked. It is a claim
about the **catalogue**: MindForge's entire content is the Stroop task and the Schulte table, two
public-domain psychology instruments the App Store already carries in quantity. From a reviewer's
screen, four seconds in, the app is indistinguishable from thirty others.

So the selection rule for this epic is stated up front, and it disqualifies most of the obvious
candidates:

**A new game must be a mechanic that only MindForge can ship.** N-back, Simon, Corsi block-tapping,
Trail Making, Tower of Hanoi and mental rotation are all excluded, not because they are bad tasks but
because each is a public-domain classic with exactly the saturation that produced the rejection.
Adding two of them converts "two classic tests" into "four classic tests", which is a worse answer,
not a better one.

MindForge has precisely two assets no clone has, both of them paid for by earlier epics:

1. **Four locales across two numeral scripts**, with `LocaleNumbers` pinning a numbering system per
   locale, `AsciiNumerals.normalize` for comparison, and a custom `ckb` delegate trio that exists
   because `flutter_localizations` ships none. **Digit Bridge** makes that the mechanic.
2. **A shape language with one imaginary light source** — a 3px ink border and a hard offset shadow
   at zero blur that translates down on press and, alone among the app's geometry, does *not* mirror
   in RTL. **False Light** makes that the mechanic.

Neither game contains a psychology eponym in its name, and that is deliberate: an eponym is the clone
smell.

Two decisions are recorded here because they will be questioned:

- **Digit Bridge's stimulus is script-pinned, not locale-rendered.** This is a scoped, documented
  exception to `CLAUDE.md` working agreement 12. See T12.4.
- **False Light deals fields rather than running a clock**, and its score never goes negative. Both
  were measured decisions, not simplifications; see *What measurement changed* above and T12.11.

iOS is the only shipping target. Everything below is built and verified on the iOS Simulator; Android
is deferred and nothing here claims parity with it.

## What measurement changed before a line was written

This epic was planned against the seam contracts and then **checked against the tree**. Four things it
specified turned out to be unbuildable or to cost far more than they were worth. They are recorded
here rather than quietly dropped, because two of them were the epic's own headline claims.

1. **False Light's timed flip schedule is removed. Fields are dealt, not flipped.**
   The board was to flip tiles on an interval. There is no legal source of elapsed time inside
   `lib/games/**`: `RunConfig` carries only `gameId`, `difficulty` and `seed`; `GameBoardBuilder` is
   `Widget Function(BuildContext, RunConfig)` and passes no clock; and `Stopwatch`, `Ticker`,
   `createTicker`, `Timer.periodic` and `AnimationController` are each banned under `lib/games/**` by
   two gate scripts and two policy tests. The only channel is a new `buildBoard` parameter, which is an
   edit to `lib/features/play/ui/play_scaffold.dart`.
   **Decision:** the game deals one field at a time and advances when the field is swept — the same
   round loop Stroop Rush already proves. The mechanic is unchanged (find the pressed tiles among the
   raised), the clock is not part of it, and the zero-lines claim survives.

2. **Neither game is clock-limited. Both end when their rounds are exhausted.**
   No shipped game declares a `runLimitFor`, so `RunNotifier._expiredOutcome()` has never executed
   outside a fixture — and it is hardcoded to `0%` / `0` / `0ms`. Two clock-limited games would have
   been the first to ship a results trio of zeros. Fixing that means widening `BoardSnapshot` with a
   "stats if the clock expires" channel and editing `run_notifier.dart`.
   **Decision:** both games publish a `RunOutcome` when their last round completes, exactly as Stroop
   Rush does. `isTimed: true` with no run limit, so the HUD still counts up and speed still matters
   through the streak multiplier.

3. **False Light's negative score is removed. A wrong tap costs the streak, not points.**
   This was the epic's deliberate seam stress, and the seam answered clearly. Rendering and ranking
   handle a negative points value correctly — `TabularText` pins the digit row LTR so the minus stays
   leading under RTL, and `RunMetric` ranks points higher-is-better. **Persistence does not.**
   `lib/data/db/tables/runs.dart:85` carries `CHECK (metric_value >= 0)`; the insert fails, the
   repository returns `ConstraintViolated`, no UI reads `saveFailure`, and the player sees a normal
   results screen for a run that left no row. Relaxing it is a schema-version bump, the app's first
   `onUpgrade`, a table rebuild (SQLite cannot `ALTER` a `CHECK`), a v2 dump and a regenerated
   `test/drift/generated/`.
   **Decision:** that is a persistence epic, and it is not what a 4.3(a) rejection is asking for. A
   wrong tap resets the streak multiplier and marks the tile rejected, which is a real cost inside a
   non-negative score. Note the sibling `CHECK (longest_combo <= correct_count)` at `runs.dart:88`,
   which both new games must also respect.

4. **Digit Bridge's script pin is relative to the locale, not absolute.**
   Pinning "target is always Latin" would have shown a Persian player two Latin sides in no locale and
   an unfamiliar script on both sides in some. **Decision:** one side always renders the *reader's own*
   numerals and the other renders the other script; a seeded bit decides which side is which, so the
   vector stays locale-independent while the game is always "translate from or to what you know".

The seam stresses that remain are real and still untested anywhere: a board whose stimulus script is
chosen by the round rather than the locale, a board with **no text and no colour at all** whose golden
is byte-identical across four locales, and the first two additions to `GameAccent` since the theme was
written.

Three corrections to names this epic used, found the same way — the shipped API is
`const LocaleNumbers(SupportedLocale)` (there is no `forLocale`), `BidiText.isolate` (there is no
`Bidi` class and no `isolateLtr`), `Moment.streakMilestone` (there is no `comboUp`), ARB keys are
`game<Pascal>Name` / `Tagline` / `Kicker` (not `<game>Title`), and `flutter_test` has
`matchesSemantics`/`containsSemantics` but no `isSemantics`. Task bodies below use the shipped names.

## Why we need it

Without this epic, the resubmission is the same binary with a better cover letter. A 4.3(a) reply
that promises differentiation without shipping any is the weakest possible position, and repeat
resubmission of a rejected concept attracts account-level scrutiny rather than a second opinion.

There is also an engineering reason, and it is the same one E10 had. E09 built the first game against
a shell designed alongside it; E10 built the opposite game and found four places the seam was too
narrow. **Two games at once, added by someone reading only the registry contract, is the third and
strongest test of the engine claim in `CLAUDE.md`** — and this pair is chosen so each stresses an
axis nothing has yet touched:

| Axis | Stroop Rush | Schulte Grid | Digit Bridge | False Light |
|---|---|---|---|---|
| `GameColourRole` | `mechanic` | `decorative` | `decorative` | `decorative` |
| `boardBackground` | `surfaceSunk` | `gameAccent` | `gameAccent` (lilac) | `gameAccent` (leaf) |
| `scoreFormat` | `points` | `duration` | `points` | `points` |
| `scoreSource` | `board` | `runClock` | `board` | `board` |
| Score domain | `>= 0` | `> 0` ms | `>= 0` | `>= 0` |
| Run end | rounds exhausted | board reports `outcome` | rounds exhausted | fields exhausted |
| Localised content | words | numbers, locale-rendered | numbers, **script-pinned** | **none at all** |
| Colour in the answer | yes | no | no | **no colour anywhere** |
| New accent needed | no | no | yes | yes |

Three of those cells have never been exercised — the script-pinned stimulus, the total absence of
colour, and the new accent. The "no colour anywhere" cell is the one that matters to E11's
accessibility floor: False Light is the first board that is fully playable with every hue removed
*without* the colour-blind palette being involved at all, and the first whose golden is byte-identical
in `en` and `fa` because it contains nothing a locale can change.

The localisation cells matter for the App Review answer specifically. Digit Bridge is the only game
in the app that a reviewer cannot understand as a reskin of something else, because its content is
the relationship between two numeral systems — and the app already had to solve that relationship to
ship `fa` and `ckb` at all.

## Current state

Verified by `ls`, `git log` and measurement on `main` at `774e5f5`.

- **The app is built and tagged `v1.0.0+1`.** All eleven epics are merged. Everything this epic
  consumes exists and is named below rather than assumed.
- **1.0.0 build 1 is uploaded and rejected.** App id `6803829952`, bundle `io.applander.mindforge`,
  build/delivery UUID `e075a2f7-bae9-4e1d-be07-63524ba2ad0e`. The rejection is 4.3(a) as quoted
  above. Nothing in this epic uploads anything; the resubmission is an account-holder action
  (`release-and-store-shipping` rule 14).
- **The engine seam, as it stands:**
  - `lib/games/game_definition.dart` — `GameDefinition` with `id`, `accent`, `colourRole`,
    `scoreFormat`, `strings`, `difficulties`, `boardBackground`, `scoreSource`, `isTimed`,
    `isLocked`, `buildBoard`, `buildArtwork`, `buildHeroArt`, `bindBoard`, `runLimitMsFor`. Four
    constructor asserts, one of which pairs `colourRole` with `boardBackground`.
  - `lib/games/game_registry.dart` — `gameRegistryProvider` returns
    `<GameDefinition>[stroopRushDefinition, schulteGridDefinition]`. **One line per game is the whole
    of adding one.**
  - `lib/core/board_snapshot.dart` — `BoardSnapshot(hud, progress, outcome, score, correctCount,
    wrongCount, longestCombo, totalReactionMs)`; `GameHud(leading, middle, trailing?)`;
    `HudSlot(labelKey, canonicalValue, format, tone, source, total?)`.
  - `lib/theme/game_accent.dart` — `enum GameAccent { stroop, schulte }` and three extension methods
    (`accentFor`, `bandRayFor`, `accentLabelFor`) that are **exhaustive with no `default:`**. Adding
    a case is a compile error in all three until handled, which is the intended behaviour.
  - `test/policy/engine_seam_test.dart` — the durable claim, run by CI: no shell file knows a game.
  - `tool/check_no_shell_edits.sh` — branch-scoped, not in CI, output pasted into the PR body.
- **The palette, measured on this tree, and the reason T12.1 exists.** Two new accents need two new
  base/deep pairs whose ink label clears 4.5:1 on any face that carries text. Every unused primitive
  in `lib/theme/sunburst_primitives.dart` was measured against `ink #2B1B4D` and `paper #FFFFFF`:

  | primitive pair | ink | paper | verdict |
  |---|---|---|---|
  | `leaf` `#4CC86A` / `leafDeep` `#2FA64F` | **7.15** / **4.89** | 2.15 / 3.14 | **usable as-is** |
  | `grapePop` `#7C5CFF` / `grape` `#6A45E8` | 3.54 / 2.66 | 4.35 / 5.79 | **unusable** |
  | `tangerine` `#FF9330` | 6.93 | 2.22 | base only; has no deep partner |

  `grapePop` fails with ink **and** with paper on the base face, and the base face is the play band,
  which is a text surface. There is no purple in `system.html` that can be a game accent. So one of
  the two accents is a genuine addition to the design source, not a token pick — which makes it a
  design change under working agreement 9, not a hex chosen in Dart.
- **`design/sunburst-pop/`** — `system.html` (token values), `app.html` (layout across eight
  screens), `screens/01..08*.png` and `screens/rtl/01..08*.png` at 390×844 @2x, `capture-screens.sh`
  with its `--rtl` flag, and `manifest.json` in both directories. There is no section 9 or 10 and no
  screen 09 or 10; T12.2 creates them.
- **Consumed by name from E04 and never re-created:** `LocaleNumbers.forLocale(Locale)` with `ckb`
  pinned to `fa`; `localeNumbersProvider`; `AsciiNumerals.normalize(String)`; `Bidi.isolate` /
  `Bidi.isolateLtr`; `localeProvider`; `appLocalizationsProvider`; the `ckb` delegate trio;
  `lib/l10n/arb_lookup.dart` and `lib/l10n/game_strings.dart` (the sanctioned second and third files
  that name a game — both under `lib/l10n/`, neither under `lib/features/**`).
- **Consumed from E05:** `PopSurface`, `PopElevation { flat, e1, e2 }`, `PopGridTile` with
  `PopGridTileState { idle, next, found, wrong, disabled }`, `kPopMinTarget` (48).
- **Consumed from E06:** the eighteen `Moment`s, `FeedbackService`, `HapticGateway`, `PressPhysics`,
  `ShakeOnWrong`, `PopCelebration`, and the reduce-motion collapse to `Duration.zero`.
- **The canonical device already exists:** `MindForge iPhone 14`,
  `C13DDC02-375D-4E1B-8F81-44EB407D09A4`, iOS 18.6, **exactly 390×844**.

  ```bash
  xcrun simctl boot C13DDC02-375D-4E1B-8F81-44EB407D09A4
  flutter run -d C13DDC02-375D-4E1B-8F81-44EB407D09A4
  ```

## What we will achieve

A reader can tell this epic is done by doing all of the following on
`MindForge iPhone 14` (`C13DDC02-375D-4E1B-8F81-44EB407D09A4`).

1. Launch in English. Home shows **four** unlocked game cards, in registry order: Stroop Rush,
   Schulte Grid, Digit Bridge (lilac), False Light (leaf green). Each has its own artwork tile and a
   BEST pill in its own score format.
2. Play **Digit Bridge** on Classic. After the 3-2-1, a large target numeral sits on a lilac band —
   say `4 7 2` in Latin digits — with six chips below it in a 3×2 grid rendering Eastern Arabic
   numerals. Exactly one chip is `۴۷۲`. The others are near-misses: a transposition, a one-digit
   substitution, a reordering.
3. Tap the correct chip. It presses to `flat`, the HUD `Correct` count rises, the combo pill lifts to
   the highlight tone, one `selectionClick` fires, and the next round arrives.
4. Tap a wrong chip. It shakes twice at 240ms, the round does **not** advance, and the score does not
   move. The wrong latch clears on the next tap.
5. Switch Settings → Language to **فارسی** mid-run. The chrome mirrors. The HUD numerals become
   Eastern Arabic. **The board's two scripts do not swap**: the target stays in the script the round
   pinned it to, because the round, not the locale, decides which side of the bridge is which.
6. Play **False Light** on Classic. A field of chunky tiles sits on the leaf band, most raised with
   the app's one light source, some pressed flat. Sweep the pressed ones. Tiles keep flipping
   underneath you for the length of the run.
7. Tap a raised tile by mistake. The score goes **down**, and the results screen renders a negative
   points total without a crash, without a `switch (gameId)` anywhere, and with the minus sign on the
   correct side in both directions.
8. Turn on **Settings → Colour-blind friendly palette** and play False Light. Nothing changes,
   because the board carries no colour information to re-point. Turn the phone's own greyscale filter
   on (Accessibility → Display & Text Size → Colour Filters → Greyscale) and it remains fully
   playable.
9. Switch to **کوردیی ناوەندی**. Nothing throws, both new boards render, no glyph is a tofu box, and
   False Light's field is byte-identical to the `en` render because it contains no text at all.
10. Switch to **Deutsch** at text scale 1.3. Every new label still fits its pill; nothing is
    ellipsised, nothing is shrunk, nothing is wrapped in a clamped scaler.
11. `bash tool/check_no_shell_edits.sh` prints `OK: lib/features/** untouched`. The whole diff is
    `lib/games/digit_bridge/**`, `lib/games/false_light/**`, two lines of `game_registry.dart`,
    `lib/theme/**`, `lib/l10n/**`, `design/sunburst-pop/**`, `test/**` and `tool/**`.
12. `flutter test` is green, including: golden vectors byte-identical across all four locales for
    both games; a greyscale golden proving every False Light tile state pair differs in ≥3 non-hue
    channels; a real-font Persian lane for Digit Bridge's chips; and cell-geometry tests at
    320/360/375/390/430.
13. Every gate under `Gates that must pass` exits 0, including `check_palette_contrast.sh` over the
    four new `// @contrast` declarations.
14. `screens/09-digit-bridge.png`, `screens/10-false-light.png` and their `rtl/` counterparts have
    been compared and signed off in the PR body, plus `01-home.png` in both directions as a
    regression — the hub now carries four cards and its scroll rhythm changed.

## Skills to load

| Skill | Why, for this epic |
|---|---|
| `sunburst-tokens` | Owns T12.1 entirely: `system.html` is authoritative for every hex, so a new accent pair is added **there first** and transcribed, never invented in Dart. Working agreement 2's four-touchpoint rule for a new slot (field + constructor, `copyWith`, `lerp`, the const instance — and the props list). `check_palette_contrast.sh` recomputes every `// @contrast` pair from the source hexes and fails on an unresolvable name, so the four new declarations are real assertions. Rule 11: light theme only, so there is no dark pair to add. |
| `sunburst-game-surfaces` | The accent claim per game, `GameColourRole.decorative` for both, the tile state matrix, the `cell(12) >= kPopMinTarget ? 12 : 8` gap derivation, the ≥3-non-hue-channel rule — which False Light satisfies by construction and must still be tested — and the ban on `FittedBox` in favour of a smaller BASE style. Supplies `check_game_palette.sh`. |
| `sunburst-shell-screens` | The seam: what `GameDefinition` and `BoardSnapshot` carry, `_BoardPane` owning the board's background and insets (a game must not re-apply them), the `lib/games/**` ban list, and the zero-lines rule this epic proves for the second time. Rule 13's comparison order for T12.16. |
| `i18n-rtl-l10n` | Co-owns Digit Bridge. The Persian block U+06F0–06F9 versus the Arabic block U+0660–0669; `ckb` pinned to `fa` because `intl` ships no `ckb` symbols and falls back to Latin silently; `AsciiNumerals.normalize` before every comparison; FSI/PDI isolation for the mixed-script round; Directional-only geometry; the LTR-pinned island a numeral run needs; and the ban on rendering numeral goldens with Ahem. `references/numerals-and-calendars.md` is the authority T12.4's exception is written against. |
| `seeded-determinism-and-golden-vectors` | Both games are derived content. Injected key, one entropy source, an owned SplitMix64 salted per feature, a frozen generator version, committed vector tables regenerated only by `tool/`. Rule 4's "entropy has exactly one source" is what makes the locale-independence proof provable — and Digit Bridge is the case where the script token is part of the vector, so the vector must pin it. |
| `sunburst-motion-and-haptics` | The moments both boards spend, each with its reduce-motion residue: `answerCorrect`, `answerWrong` (two 240ms shake cycles, `lightImpact`), `comboUp`, `tileFound`. False Light's tile flip is a **state change, not an animation** — under reduce motion it must still be legible the instant it happens, which rule 3's transform-dropped/fill-kept split already decides. |
| `accessibility-as-code` | The 48px floor both boards defend, `Semantics` on every chip and tile, the ban on `withClampedTextScaling`/`FittedBox`/`ellipsis`, and the never-colour-alone rule. False Light needs the **opposite** scrutiny from every other board: depth is its only channel, so its semantics label must say "raised"/"pressed" in words, and T12.9 must prove the depth delta is perceivable rather than assume it. |
| `widget-golden-and-a11y-testing` | `useDevice`/`pumpApp` at DPR 2; one `testWidgets` per (device, scale, locale) tuple; the two golden lanes — Ahem for geometry and mirroring, **real fonts via `loadAppFonts()`** for Digit Bridge's Persian chips, because Ahem renders no Persian digit and would bless an em-square. Pure-Dart WCAG on colour values, never `meetsGuideline` on pixels. |
| `state-management-riverpod` | One family `Notifier` per board over one immutable state with `void` intent methods; `bindBoard` implemented as **listen-then-read**, never `ref.watch` inside `RunNotifier.build` — the doc on `GameDefinition.bindBoard` records what happened the first time and this epic must not repeat it. State holds `int`s and script tokens, never a formatted string. |
| `widget-composition` | Class-not-method extraction; computed sizing from `LayoutBuilder` constraints; rule 5 — **no `NumberFormat` inside `build()`**, so Digit Bridge formats its seven values once per (round, locale) above the chips; `ValueKey` identity so a re-tap cannot act on a stale capture. |
| `custom-canvas-and-gestures` | False Light's tile is a painted depth, so if it becomes a `CustomPainter` it is dumb, fed an immutable scene, `shouldRepaint` as one value compare, zero allocation in `paint()`, `ExcludeSemantics` with a sibling `Semantics` speaking the state in words. It must **not** read `Directionality`: the light source is a constant, which is working agreement 11's one exception. |
| `dart3-idioms-and-coding-standards` | Payload-free enums switched exhaustively with no `default:`; hand-rolled `@immutable final class` values; total, non-throwing generators. |
| `testing-strategy` | Pure tier for both generators and both state machines; `ProviderContainer` for the notifiers; bare-`implements` fakes for `FeedbackService`; seeded fuzz against an independent oracle; the round-trip property `AsciiNumerals.normalize(format(n)) == n` for every locale and both scripts. |
| `error-handling-typed-results` | Nothing in either game is recoverable I/O, so nothing here returns a `Result`. Named so the absence is a decision rather than an omission. |
| `project-structure-and-packages` | `lib/games/<id>/` holds the definition plus `application/`, `domain/`, `ui/`; `test/` mirrors 1:1; no file under `lib/features/**` may import a specific game. Supplies `check_import_boundaries.sh`. |
| `release-and-store-shipping` | T12.17 only: what the store listing may and may not claim, the ban on absolute privacy claims in all four locales, and rule 14 — the resubmission itself is an account-holder action this epic does not perform. |

## Tasks

### T12.1 — Two accent pairs, decided in `system.html` and proved by contrast

**Goal.** Give both games an identity colour whose label clears the floor on every face that carries
text, and do it as a design change rather than a hex chosen in Dart.

**Tests first (TDD).**
- `test/theme/sunburst_theme_test.dart` gains rows for both new accents — it is the file that
  already exercises `accentFor`, `bandRayFor` and `accentLabelFor`, and it **computes** the WCAG
  ratio for every (accent, role) pair rather than trusting a declaration list. Extend its matrix; do
  not add a parallel file, and do not extend a constant.
  - `accentFor` returns a distinct colour for all eight (accent, role) combinations.
  - `accentLabelFor` returns non-null exactly where the computed ratio is ≥ 4.5:1, and `null`
    everywhere it is not. A face that fails must return `null`, not a colour that fails.
  - `bandRayFor` returns a colour with alpha `0x73` for all four accents, matching the established
    band construction.
- `test/theme/token_parity_test.dart` — **already exists and already does this.** Its
  `kPrimitiveToCssVar` table maps every `_P` constant to the `system.html` custom property it
  transcribes, so a hex invented in Dart fails it. Add `lilac`, `lilacDeep`, `lilacDeepBand` and
  `leafDeepBand` to that table in the same commit as the primitives. It is the test that fails first
  if someone picks a colour in Dart, so it is extended, never bypassed.
- `.claude/skills/sunburst-tokens/scripts/check_palette_contrast.sh lib/theme/sunburst_colors.dart`
  passes over four new `// @contrast` declarations.

**Implementation.**
1. **Digit Bridge takes a new lilac pair, added to `system.html`.** Measured on this tree against
   `ink #2B1B4D`:

   | slot | hex | ink ratio |
   |---|---|---|
   | `lilac` | `#BE9BFF` | **6.82** |
   | `lilacDeep` | `#A87DFF` | **5.15** |

   Both faces carry ink comfortably, so `accentLabelFor` returns `textPrimary` for both — the Schulte
   shape, not the Stroop shape. Add the pair to `system.html` **§02 Colour**, where the game accents actually live — there is no
   §10 game-accent section; §10 is Components. The band ray carries alpha and therefore has no
   `:root` custom property: `DesignSource.cssRootHexes()` requires exactly six hex digits, so
   `lilacDeepBand` belongs in `token_parity_test.dart`'s `kCompositedPrimitives` table beside
   `coralDeepBand`, not in `kPrimitiveToCssVar`.

   **Why a new hex and not `grapePop`.** `grapePop #7C5CFF` measures **3.54** against ink and
   **4.35** against paper. It fails with both, and the base face is the play band, which is a text
   surface. The lilac is a lighter sibling of the same family; it is not a re-tint of an existing
   slot and it does not replace one.

2. **False Light takes `leaf` / `leafDeep`, which `system.html` already carries.** Ink measures
   **7.15** and **4.89**; both clear the floor, so no new hex is needed and none is invented. Add
   only the band ray, `leafDeepBand` `#732FA64F`, following the same deep-at-0x73 construction as
   `coralDeepBand` and `turquoiseDeepBand` — and, like them, into `kCompositedPrimitives`.

3. Add four slots to `SunburstColors` — `gameDigitBridge`, `gameDigitBridgeDeep`, `gameFalseLight`,
   `gameFalseLightDeep` — plus `bandRayDigitBridge` and `bandRayFalseLight`. Working agreement 2:
   each touches the field, the constructor, `copyWith`, `lerp`, the props list and the const
   instance. Six places, six times. Missing one is a silent `lerp` discontinuity, which is why the
   test walks every slot rather than the ones someone remembered.

4. Add the `// @contrast` declarations above the const instance:

   ```
   // @contrast textPrimary gameDigitBridge      4.5  ink label on the Digit Bridge band
   // @contrast textPrimary gameDigitBridgeDeep  4.5  ink numeral on a matched chip
   // @contrast textPrimary gameFalseLight       4.5  ink label on the False Light band
   // @contrast textPrimary gameFalseLightDeep   4.5  ink glyph on a pressed tile
   ```

5. **Bump the three hardcoded parser guards in the same commit, never delete them.**
   `test/theme/token_parity_test.dart` counts the `:root` hexes (30 -> 32);
   `test/theme/contrast_test.dart` counts the `// @contrast` pairs (26 -> 30) and resolves each
   declared name through a hand-written `_slots` map that needs four new rows, or every new
   declaration fails as unresolvable. Each fails with a message naming the parser rather than the
   colour, which is why they are listed here rather than discovered.

6. **Check the candidate hexes against the five existing loops over `GameAccent.values` before
   committing them**, not after: `test/a11y/shell_contrast_test.dart` (hero-panel composite against
   ink, and the header lattice measured strictly worse), `test/features/shell/widgets/play_band_test.dart`,
   `test/features/shell/widgets/best_card_test.dart` and `test/theme/sunburst_theme_test.dart` all
   iterate the enum, so a new case enrolls itself in assertions nobody edits.

7. Add `digitBridge` and `falseLight` to `enum GameAccent`. All three extension methods are
   exhaustive with no `default:`, so this step **will not compile** until each is handled — which is
   the design working, and the reason no game can ship a silently grey band.

**Files.** `design/sunburst-pop/system.html`, `lib/theme/sunburst_primitives.dart`,
`lib/theme/sunburst_colors.dart`, `lib/theme/game_accent.dart`, `test/theme/sunburst_theme_test.dart`,
`test/theme/token_parity_test.dart`, `test/theme/contrast_test.dart`, `test/policy/theme_equality_test.dart`.

---

### T12.2 — `app.html` sections 9 and 10, and the reference screens in both directions

**Goal.** Produce the implementation targets before the implementation, because working agreement 9
compares a built screen against a reference and a reference invented afterwards proves nothing.

**Tests first (TDD).**
- `test/policy/reference_manifest_test.dart` — `design/sunburst-pop/screens/manifest.json` and
  `screens/rtl/manifest.json` list the same basenames, and every basename has a file at exactly
  390×844 @2x in both directories. Extend the expected set to ten; it currently expects eight and
  will fail until the captures exist.
- `tool/dump_design_strings_test.dart` — the Persian strings the RTL capture renders come from the
  shipped ARBs, not from hand-written HTML. Extend for the new keys.

**Implementation.**
1. Add §9 (Digit Bridge) and §10 (False Light) to `app.html`, using only tokens `system.html`
   defines. Digit Bridge: a lilac play band, the target numeral at the display step centred above a
   3×2 chip grid with 12px gaps. False Light: a leaf band carrying a 4×5 field of tiles at two
   depths, with enough tiles at each depth that the reference shows the delta rather than describing
   it.
2. Regenerate **both** sets:

   ```bash
   cd design/sunburst-pop
   ./capture-screens.sh
   ./capture-screens.sh --rtl
   ```

3. Commit the PNGs with the HTML change in the same commit. A reference regenerated in a later commit
   than the layout it renders is a reference nobody can date.

**Note.** `01-home.png` changes in both directions in this task, because the hub now carries four
cards. That is a deliberate design change, not a side effect, and T12.16 signs it off.

**Files.** `design/sunburst-pop/app.html`, `design/sunburst-pop/screens/09-digit-bridge.png`,
`screens/10-false-light.png`, `screens/01-home.png`, the three `rtl/` counterparts, both
`manifest.json`, `test/policy/reference_manifest_test.dart`.

---

### T12.3 — Digit Bridge: seeded round generation and the distractor taxonomy

**Goal.** Generate a round that is hard for the right reason — near-misses, not random numbers — and
reproduce it byte-for-byte on every device and in every locale.

**Tests first (TDD).**
- `test/games/digit_bridge/domain/bridge_round_test.dart`
  - `bridgeRound(seed: s, difficulty: d)` returns the same `BridgeRound` for the same `(s, d)` across
    1000 calls, and differs for `s + 1`.
  - Exactly one candidate equals the target. Asserted after `AsciiNumerals.normalize` on both sides,
    because a comparison of rendered strings is a comparison of fonts.
  - Every distractor is drawn from the declared taxonomy and each taxonomy member appears at least
    once across a seeded sweep of 500 rounds:
    - **transposition** — two adjacent digits swapped (`472` → `427`)
    - **substitution** — one digit replaced (`472` → `672`)
    - **reordering** — the same multiset, non-adjacent (`472` → `724`)
    - **length** — one digit added or dropped (`472` → `472` → `4723`)
  - No two candidates are equal to each other.
  - Digit count follows the rules table below, and a `blitz` round never emits fewer digits than a
    `chill` one.
- `test/games/digit_bridge/domain/bridge_vectors_test.dart` — a committed table of
  `(seed, difficulty) -> (targetDigits, candidateDigits[6], correctIndex, targetScript)` is
  reproduced exactly. The table is regenerated only by `tool/update_bridge_vectors.dart`, never by
  CI, and **the script token is part of the vector**: a vector that pinned only the integers would
  pass while the bridge ran backwards.
- `test/policy/engine_locale_purity_test.dart` — extended: `lib/games/digit_bridge/domain/**` imports
  neither `intl` nor `dart:ui`, and contains no `NumberFormat`.

**Implementation.**
1. `BridgeRound` is a hand-rolled `@immutable final class` holding `int target`,
   `List<int> candidates`, `int correctIndex`, `NumeralScript targetScript`. Integers and a semantic
   token — no strings, so working agreement 12's golden-vector rule is satisfied by construction.
2. `enum NumeralScript { latin, easternArabic }` in the game's `domain/`. It is the *round's*
   choice, not the locale's; T12.4 explains why it can be.
3. Rules table, keyed by `Difficulty`:

   | difficulty | digits | run limit | candidates |
   |---|---|---|---|
   | `chill` | 2 | 90s | 6 |
   | `classic` | 3 | 60s | 6 |
   | `blitz` | 4 | 45s | 6 |

   Candidate count is fixed at six across all three so the board geometry never changes mid-game;
   difficulty is carried by digit count and clock, which is the axis that actually scales.
4. One entropy source, salted `digit_bridge`, generator version frozen at 1.

**Files.** `lib/games/digit_bridge/domain/bridge_round.dart`, `numeral_script.dart`,
`bridge_rules.dart`, `tool/update_bridge_vectors.dart`, the three test files.

---

### T12.4 — The script-pinned stimulus, and the exception it takes to working agreement 12

**Goal.** Decide, in writing and in a test, that the board's two scripts are chosen by the round
rather than by the locale — and fence the exception so it cannot leak.

**The decision.** Working agreement 12 says numerals are localized at render: `en`/`de` render Latin,
`fa`/`ckb` render Eastern Arabic. Digit Bridge cannot obey that, because if the locale decided the
script then both sides of the bridge would render identically and **there would be no game**. So:

> The round pins one script to the target and the other to the candidates. Everything else on the
> screen — the HUD, the combo, the score, the results, the BEST pill — localizes exactly as before.

This is narrower than it sounds, and the fence is what makes it safe:

- The exception applies to **two widget subtrees**, the target numeral and the chip labels, and
  nowhere else.
- Both subtrees format through `LocaleNumbers` with an **explicitly named** numbering system rather
  than by string-substituting digits. There is exactly one `NumberFormat` construction site in
  `lib/` and this does not become a second one; `LocaleNumbers` gains a
  `forScript(NumeralScript)` entry point beside `forLocale(Locale)`, sharing the same pinning.
- Storage, comparison and scoring are ASCII throughout. `AsciiNumerals.normalize` runs before every
  comparison, so a tap is matched on integers and never on glyphs.
- Which script lands on which side alternates by round, seeded, so a player cannot learn "the target
  is always Latin" and stop reading one of the two systems.

**Tests first (TDD).**
- `test/games/digit_bridge/application/script_pinning_test.dart`
  - For all four locales, a given seed produces the **same** `targetScript`. The locale does not
    move the bridge.
  - The target and the candidates never share a script.
  - Across a seeded sweep, both scripts appear as the target roughly evenly (within 10% over 500
    rounds).
  - `LocaleNumbers.forScript(NumeralScript.easternArabic)` emits U+06F0–U+06F9 and **never**
    U+0660–U+0669. Asserted by code point, not by eyeballing a string literal.
- `test/policy/number_format_sites_test.dart` — still exactly one `NumberFormat` construction site in
  `lib/`. This is the test that fails if `forScript` is implemented by constructing a second one.
- `test/policy/canonical_storage_test.dart` — extended: no Eastern Arabic code point reaches a
  `runs` row or a golden vector for this game.
- `test/a11y/numerals_test.dart` — **the test that actually enforces working agreement 12 at render**,
  and the one this exception has to be argued into. It sweeps every `SweepSurface` in all four locales
  and treats any Latin digit drawn under `fa`/`ckb` as an offender, with a hand-named exemption list
  whose comment says a third entry "has to come here and argue for itself". Digit Bridge's board is
  that third entry: the argument is that a cross-script matching game in which both sides rendered the
  reader's own numerals would have no question in it. The exemption is scoped to the board subtree, so
  the HUD, the score and every other surface stay under the original assertion.

**Implementation.**
1. Add `LocaleNumbers.forScript` beside `forLocale`, both delegating to the same private pinning
   helper. `ckb` continues to borrow `fa`'s symbol data.
2. Document the exception at the point of use — on `NumeralScript` and on the two widgets — and add
   one line to `docs/decisions/0002-four-locales-and-rtl.md` pointing at it. An exception recorded
   only in an epic file is an exception the next reader will treat as a bug.
3. The mixed-script round needs bidi isolation: the target and each chip are isolated runs via
   `Bidi.isolateLtr`, because a numeral run adjacent to Persian chrome will otherwise reorder at the
   boundary. Isolates never reach storage.

**Files.** `lib/l10n/locale_numbers.dart`, `lib/games/digit_bridge/domain/numeral_script.dart`,
`docs/decisions/0002-four-locales-and-rtl.md`, the three test files.

---

### T12.5 — Digit Bridge: board notifier, snapshot and HUD projection

**Tests first (TDD).**
- `test/games/digit_bridge/application/bridge_board_notifier_test.dart`, driven headlessly with
  `ProviderContainer`
  - A correct tap advances the round, increments `correctCount`, and raises `longestCombo`.
  - A wrong tap increments `wrongCount`, does **not** advance the round, and resets the combo to 0.
  - A second tap on the same wrong chip while the latch is set is a no-op.
  - The state holds `int`s and a `NumeralScript`, never a formatted string. Asserted by reflection
    over the state class's field types, the same way E10 asserted it.
  - No `DateTime.now()` anywhere under `lib/games/digit_bridge/**` — the game owns no clock.
- `test/games/digit_bridge/application/bridge_snapshot_test.dart`
  - `GameHud` carries `Correct` (count), `Combo` (count, `HudTone.highlight` above 2, else
    `neutral`), and a `null` trailing slot.
  - `progress` is `null` — the run is bounded by the clock, not by a round count, so a progress track
    would be lying about a finish line that does not exist.
  - `outcome` is always `null`: this game never ends itself. `isTimed: true` plus a run limit is what
    ends it, and asserting the `null` is what stops someone adding a premature end condition later.
  - `score == correctCount`, and it is never negative.
- `test/games/digit_bridge/application/bind_board_test.dart` — `bindBoard` **listens and reads**; a
  `ref.watch` implementation is caught by asserting that `RunNotifier.build` runs exactly once across
  ten board updates. This is the defect `GameDefinition.bindBoard`'s doc records; the test is what
  stops it recurring.

**Implementation.** A family `Notifier` keyed by `RunConfig`, `void` intent methods (`tapCandidate`,
`start`), one immutable state. The wrong latch is state, not a timer — working agreement 2 bans a raw
`Duration` outside `lib/theme/`, which is why it clears on the next tap rather than after an interval.

**Files.** `lib/games/digit_bridge/application/bridge_board_notifier.dart`, `bridge_snapshot.dart`,
`lib/games/digit_bridge/domain/bridge_board_state.dart`, the four test files.

---

### T12.6 — Digit Bridge: the board widget and the per-locale glyph fit

**Tests first (TDD).**
- `test/games/digit_bridge/ui/bridge_board_layout_test.dart`
  - At 320/360/375/390/430 logical width, every chip's **fill box** is ≥ `kPopMinTarget` (48) on both
    axes, and the gap steps 12 → 8 exactly where the derivation says.
  - One `testWidgets` per (device, scale, locale) tuple, because an overflow reports once per
    `RenderObject` and a loop inside one test finds the first and hides the rest.
  - At text scale 1.3 in `de`, no chip overflows and nothing is ellipsised.
- `test/games/digit_bridge/ui/bridge_glyph_fit_test.dart` — the **real-font lane**, via
  `loadAppFonts()`. A four-digit Eastern Arabic label fits its chip in `fa` and `ckb`. Ahem renders
  no Persian digit and would bless an em-square, so this lane may not use it.
- `test/games/digit_bridge/ui/bridge_board_golden_test.dart` — goldens in `en` and `fa`, LTR and RTL.
  The chip **grid** mirrors (it is chrome, and reading order applies to a row of choices); the
  numerals inside each chip do not reorder.
- `test/policy/directional_geometry_test.dart` — no `EdgeInsets.only(left:/right:)`,
  `Alignment.centerLeft` or `TextAlign.left` under the new game directories.

**Implementation.**
1. `DigitBridgeBoard` → `BridgeTarget` + `BridgeChipGrid` → `BridgeChip`. Class extraction, not
   methods.
2. Format the seven values (one target, six candidates) **once** per (round, locale) above the chips.
   Rule 5 of `widget-composition`: no `NumberFormat` inside `build()`.
3. `ValueKey(candidateIndex)` identity, so a rebuild mid-tap cannot act on a stale capture.
4. The board must not re-apply its own background or gutter: `_BoardPane` already owns both.

**Files.** `lib/games/digit_bridge/ui/digit_bridge_board.dart`, `ui/board/bridge_target.dart`,
`ui/board/bridge_chip.dart`, `ui/bridge_metrics.dart`, the four test files.

---

### T12.7 — Digit Bridge: definition, artwork, ARB keys and the registry line

**Tests first (TDD).**
- `test/games/digit_bridge/digit_bridge_definition_test.dart` — `id.value == 'digit_bridge'`;
  `accent == GameAccent.digitBridge`; `colourRole == BoardColourRole.decorative`;
  `boardBackground == BoardBackground.gameAccent`; `scoreSource == ScoreSource.board`;
  `scoreFormat == ScoreFormat.points`; `isTimed` true with a run limit for all three difficulties.
- `test/policy/registry_localization_test.dart` — extended. Every key in `GameStringIds` exists in all
  **four** ARBs and has a generated getter. This is the test that catches a key added to `en` and
  forgotten in `ckb`.
- `test/games/game_registry_test.dart` — the registry holds four definitions, ids are unique, and
  display order is stable.
- `.claude/skills/i18n-rtl-l10n/scripts/check_arb_parity.sh lib/l10n` passes.

**Implementation.** Three ARB keys — `gameDigitBridgeName`, `gameDigitBridgeTagline`, `gameDigitBridgeKicker` —
added to all four ARBs **in the same commit**, plus HUD label keys. `buildArtwork` draws the 64pt
home-card tile (two numerals in two scripts, bridged); `buildHeroArt` draws the `.swatchrow` legend
that introduces the two scripts on a screen with no clock running. They are different drawings, which
is why there are two hooks. One appended line in `game_registry.dart`; one row each in
`arb_lookup.dart` and `game_strings.dart`.

**Files.** `lib/games/digit_bridge/digit_bridge_definition.dart`, `ui/board/bridge_artwork.dart`,
`ui/board/bridge_hero_art.dart`, `lib/games/game_registry.dart`, `lib/l10n/app_*.arb` (four),
`lib/l10n/arb_lookup.dart`, `lib/l10n/game_strings.dart`, the three test files.

---

### T12.8 — Digit Bridge: motion, haptics and semantics

**Tests first (TDD).**
- `test/games/digit_bridge/ui/bridge_feedback_test.dart` with a bare-`implements` `FeedbackService`
  fake — exactly one `Moment.answerCorrect` per correct tap, exactly one `Moment.answerWrong` per
  wrong tap, and **zero** haptics fired per animation frame.
- `test/policy/haptic_confinement_test.dart` — still no `HapticFeedback` call site outside
  `lib/shared/feedback/`.
- Reduce motion: with the flag set, every duration collapses to `Duration.zero` and the non-motion
  residue survives — the wrong chip still carries its ink strike, the correct chip still presses to
  `flat`.
- `test/games/digit_bridge/ui/bridge_semantics_test.dart` — `matchesSemantics(...)` over `tester.getSemantics(...)` inside an `ensureSemantics()` handle — the
  `pop_surface_test.dart` idiom — on every chip, in all four locales. `matchesSemantics` is exact, so
  every flag the widget declares must be listed. The label speaks
  the numeral as rendered, so a screen-reader user hears the script they are being asked to read.

**Files.** the two test files, plus the moment wiring in `bridge_chip.dart`.

---

### T12.9 — False Light: prove the depth delta before building the board

**Goal.** Establish, by measurement rather than by taste, that raised and pressed are distinguishable
at the sizes and offsets the board will actually use — **before** any of T12.10–T12.14 is written.
This is the task most likely to kill the game, so it runs first.

**Why it is a real risk.** The app's component shadow is a small offset at zero blur, tuned for
chrome a player looks at deliberately. A board mechanic is scanned peripherally under time pressure,
and the same offset that reads as "a button" at rest may not read as "different from its neighbour"
at speed. Assuming otherwise is how a game ships that is unplayable for anyone with reduced contrast
sensitivity — which is a large fraction of the over-50 audience a brain trainer is aimed at.

**Tests first (TDD).**
- `test/games/false_light/ui/depth_delta_test.dart`
  - The raised and pressed tile states differ in **≥3 non-hue channels**: shadow presence, fill
    lightness, border weight or inset, and glyph baseline offset. Counted mechanically, not asserted
    as a number someone typed.
  - A greyscale golden of a mixed field is generated and every pressed tile is separable from every
    raised one by luminance difference ≥ the declared floor, computed in pure Dart.
  - The delta holds at the smallest cell the largest grid produces at 320 logical width.
- `test/games/false_light/ui/depth_scale_test.dart` — the board's own offset is a named token, and
  difficulty scales the **delta** between states, never the tile size. A difficulty that shrinks
  tiles below `kPopMinTarget` fails here.

**Implementation.**
1. Add the board's own depth tokens to `system.html` §10 and transcribe them. The board offset is
   larger than the chrome offset; that is a design decision with a reason, recorded next to the
   value, not a magic number.
2. Build a throwaway page in `tool/gallery_main.dart` showing the field at all three difficulties and
   all five device widths. **Look at it on the canonical simulator before proceeding.** If the delta
   is not obvious at arm's length in one second, the game is wrong and this epic stops here rather
   than shipping something that fails E11's floor.
3. Record the outcome — including a "this did not work, here is what changed" line if that is what
   happened — in `docs/verification/e12-depth-delta.md`.

**Files.** `design/sunburst-pop/system.html`, `lib/theme/sunburst_shape.dart`,
`tool/gallery_main.dart`, `docs/verification/e12-depth-delta.md`, the two test files.

---

### T12.10 — False Light: seeded field generation and the field ladder

**Tests first (TDD).**
- `test/games/false_light/domain/light_field_test.dart`
  - `lightFields(seed: s, difficulty: d)` is reproducible across 1000 calls and differs for `s + 1`.
  - The pressed fraction stays within the declared band for the difficulty across a 500-seed sweep — a
    field that is 90% pressed is not a harder game, it is a different one.
  - At least one pressed and one raised tile always exist in every field. A field with no target is
    unplayable; a field with no distractor is not a game.
  - **The whole ladder is dealt up front**, as a `List<LightField>`, exactly as Stroop deals its rounds.
    The board owns no clock and needs none: a field advances when it is swept, never on an interval.
- `test/games/false_light/domain/light_vectors_test.dart` — a committed vector table of
  `(seed, difficulty) -> fields`, regenerated only by `tool/update_light_vectors.dart`, byte-identical
  under all four locales.
- `test/policy/engine_locale_purity_test.dart` — extended: `lib/games/false_light/**` contains **no
  user-facing string at all**. This game has no text on its board, and asserting it is what makes the
  byte-identical `en`/`fa` golden in T12.12 meaningful.

**Implementation.**
1. `LightField` is an immutable value over a `List<TileDepth>` plus its grid shape.
   `enum TileDepth { raised, pressed }`. `LightBoardState` holds the dealt ladder, the field index and
   the swept set — the Stroop shape, with fields where Stroop has rounds.
2. Rules table:

   | difficulty | grid | pressed fraction | fields |
   |---|---|---|---|
   | `chill` | 4×4 | 0.30–0.40 | 8 |
   | `classic` | 4×5 | 0.25–0.35 | 12 |
   | `blitz` | 5×6 | 0.20–0.30 | 16 |

   The grid grows and the pressed fraction *falls* with difficulty, so targets get scarcer rather than
   tiles getting smaller. The `blitz` cell at 320 logical width is the case T12.9's 48px floor test is
   written against.
3. One entropy source, `seedFrom('false_light:$seed', featureSalt: kFalseLightFeatureSalt,
   modeSalt: difficulty.index)`, generator version frozen at 1.

**Files.** `lib/games/false_light/domain/light_field.dart`, `tile_depth.dart`, `light_rules.dart`,
`light_board_state.dart`, `tool/update_light_vectors.dart`, the three test files.

---

### T12.11 — False Light: the notifier, and what the seam said about a negative score

**Goal.** Score the sweep, and record what asking the negative-score question actually returned.

**The question was asked and answered before the notifier was written.** The epic originally specified
a score that could go negative, as a deliberate stress on `ScoreFormat.points`. Measured against the
tree: the rendering and ranking tiers handle it correctly, and the persistence tier cannot. See
*What measurement changed* above for the four files that carry the constraint. **The finding is the
deliverable; the migration is not this epic's.**

**Tests first (TDD).**
- `test/games/false_light/application/light_board_notifier_test.dart`
  - Tapping a pressed tile marks it swept, increments `correctCount`, and raises the streak.
  - Tapping a raised tile marks it `rejected`, bumps `wrongTapId` (the shake identity latch), resets
    the streak multiplier to 1, and increments `wrongCount`. The score does not fall.
  - Tapping an already-swept tile is a no-op — neither count moves.
  - Sweeping the last pressed tile in a field advances to the next field; sweeping the last field
    publishes a `RunOutcome` and ends the run.
  - `longestCombo <= correctCount` holds after every transition. This is not a style rule: it is
    `CHECK (longest_combo <= correct_count)` in the `runs` table, and violating it makes a run
    unsavable in exactly the silent way the negative score would have been.
- `test/data/repositories/false_light_run_test.dart` — a repository-tier save of a False Light run
  succeeds and is readable back. This is the test that would have failed on the negative score, so it
  is the one that proves the decision rather than assuming it.

**Implementation.** A family `Notifier` keyed by `RunConfig`, `void` intent methods, one immutable
state, the streak multiplier derived and never stored — `stroop_scoring.dart` is the shape to copy.

**Files.** `lib/games/false_light/application/light_board_notifier.dart`, `light_snapshot.dart`,
`lib/games/false_light/domain/light_scoring.dart`, the two test files.

---

### T12.12 — False Light: the board widget, sizing and hit area

**Tests first (TDD).**
- `test/games/false_light/ui/light_board_layout_test.dart` — at 320/360/375/390/430, every tile's
  fill box is ≥ 48 on both axes at every difficulty, and the gap derivation steps where it should.
- `test/games/false_light/ui/light_press_law_test.dart` — the press **visual** translates down while
  the **hit area holds still**. `sunburst-components` rule 5, and the one a board most easily breaks
  by animating the `GestureDetector` instead of its child.
- `test/games/false_light/ui/light_direction_test.dart` — the tile's shadow offset is **identical**
  in LTR and RTL. Working agreement 11's one exception, asserted rather than assumed, because a
  future refactor to `EdgeInsetsDirectional` would silently mirror the light and break the mechanic
  in exactly two locales.
- `test/games/false_light/ui/light_board_golden_test.dart` — goldens in `en` and `fa`. **They must be
  byte-identical**, because the board contains no text and no directional geometry. A diff here is a
  bug, and it is the cheapest possible proof of the claim in step 9.

**Implementation.** `FalseLightBoard` → `LightField` → `LightTile`. If the tile becomes a
`CustomPainter`, it takes an immutable scene, compares it in `shouldRepaint`, allocates nothing in
`paint()`, carries `ExcludeSemantics` with a sibling `Semantics`, and does not read `Directionality`.

**Files.** `lib/games/false_light/ui/false_light_board.dart`, `ui/board/light_tile.dart`,
`ui/light_metrics.dart`, the four test files.

---

### T12.13 — False Light: definition, artwork, ARB keys and the registry line

**Tests first (TDD).** As T12.7, for `false_light`: `accent == GameAccent.falseLight`,
`boardBackground == BoardBackground.gameAccent`, `scoreSource == ScoreSource.board`,
`scoreFormat == ScoreFormat.points`, three difficulties, run limits per the rules table.
`test/policy/registry_localization_test.dart` and `check_arb_parity.sh` cover the four ARBs.

**Implementation.** Three ARB keys plus HUD labels in four locales, same commit. Note the asymmetry
worth stating: this game has ARB keys for its **chrome** — its name, tagline, kicker and HUD labels —
and none for its board, because its board has no text. One appended registry line.

**Files.** `lib/games/false_light/false_light_definition.dart`, `ui/board/light_artwork.dart`,
`ui/board/light_hero_art.dart`, `lib/games/game_registry.dart`, `lib/l10n/app_*.arb` (four),
`lib/l10n/arb_lookup.dart`, `lib/l10n/game_strings.dart`, the test files.

---

### T12.14 — False Light: the no-colour proof, semantics and motion

**Goal.** Turn "playable without colour" from a claim in a store listing into a test that fails.

**Tests first (TDD).**
- `test/games/false_light/ui/light_greyscale_test.dart` — a greyscale golden of a full field, with
  every tile-state pair separable by luminance. Computed in pure Dart, never `meetsGuideline` on
  pixels.
- `test/games/false_light/ui/light_palette_independence_test.dart` — **the headline test.** The
  board's rendered output is byte-identical with `isColourBlindPalette` true and false. Nothing on
  this board is re-pointed, because nothing on it is an answer colour. That is the assertion the
  4.3(a) response rests on, so it is a golden comparison, not a prose claim.
- `test/games/false_light/ui/light_semantics_test.dart` — every tile exposes a `matchesSemantics` label of
  `"raised"` or `"pressed"`, localized. Depth is the only visual
  channel, so the semantic label must say it **in words** — a screen-reader user cannot see a shadow.
  This is why the game has HUD and state ARB keys despite having no board text.
- `test/games/false_light/ui/light_feedback_test.dart` — one `Moment.tileFound` per correct sweep,
  one `Moment.answerWrong` per raised tap, none per frame, none per flip. **A tile flipping is not a
  player action and must fire no haptic**; a field of twenty tiles flipping on a 1200ms interval
  would otherwise buzz continuously.
- Reduce motion: the flip has no transition to collapse — it is a state change — and the board is
  fully legible the instant it happens.

**Files.** the five test files, plus the moment wiring in `light_tile.dart`.

---

### T12.15 — The engine seam, proved for the second time

**Tests first (TDD).**
- `test/policy/engine_seam_test.dart` — extended in coverage: no file under `lib/features/**` imports,
  names or switches on any of the four game ids. Its `const gameNames` list at the top is what makes
  that real, and **the tokens added there must be the full ids, not bare words**: `'light'` matches
  `SystemUiOverlayStyle.light` in `lib/features/countdown/ui/countdown_screen.dart` and turns a green
  suite red for no reason. Add `'digit_bridge'`, `'false_light'`, `'digitbridge'`, `'falselight'`.
- `test/policy/registry_localization_test.dart` — its `declaredKeys()` walks `fixtureGame().strings`,
  not the shipped registry, so today it would pass with every new key missing. Widen it to the real
  registry; that widening is what makes the four-ARB assertion mean anything for these games.
- `test/policy/banned_imports_test.dart` — no `go_router`, `Navigator`, `Scaffold`, `AppBar`,
  `HudPill`, `Color(0x`, `Stopwatch` or `DateTime.now()` under either new game directory.
- `test/policy/play_domain_purity_test.dart` — extended over both new `domain/` directories.

**Implementation.**

```bash
bash tool/check_no_shell_edits.sh
```

Paste the output into the PR body. If it fails, **stop**. Do not edit a shell screen. Record what the
shell could not express and widen `GameDefinition` or `BoardSnapshot` for every game at once — the
same instruction the script itself prints, and the same one E10 followed when it found four.

Add `verify_feature.sh lib/games/digit_bridge` and `verify_feature.sh lib/games/false_light` rows to
`tool/skill_gates.sh`'s run table, and a row each to
`test/policy/skill_gates_coverage_test.dart` so neither can silently fall out of the gate set.

**Files.** `tool/skill_gates.sh`, the three policy tests.

---

### T12.16 — Screenshot sign-off, in both directions, including the home regression

**This is a human step. No pipeline performs it.**

On `MindForge iPhone 14` only — it is the sole device that is exactly 390×844, which is what makes
the comparison honest.

Compare, in `sunburst-shell-screens` rule 13's order (structure → spacing rhythm → surface
construction → type role → sampled hex):

| built screen | against |
|---|---|
| Digit Bridge, `en` | `screens/09-digit-bridge.png` |
| Digit Bridge, `fa` | `screens/rtl/09-digit-bridge.png` |
| False Light, `en` | `screens/10-false-light.png` |
| False Light, `fa` | `screens/rtl/10-false-light.png` |
| Home, `en` | `screens/01-home.png` — **regression: four cards now** |
| Home, `fa` | `screens/rtl/01-home.png` — same |

Also run, and record, the four passes no golden covers: `ckb` on both boards; text scale at its
maximum on both; Sound off + Haptics off + Reduce motion on; and the phone's own greyscale filter on
False Light.

A difference is an implementation defect. If a reference is genuinely wrong, edit `app.html`, re-run
`capture-screens.sh` in both directions, and commit that as a deliberate design change — never adjust
the code to match a reference nobody re-rendered.

Record the outcome in `docs/verification/e12-simulator-signoff.md` with the date, the build, the
screens compared and what was found. Name the rows that could not be checked and why, rather than
omitting them — E11 set that precedent for real hardware and it holds here.

---

### T12.17 — The store answer, written from what shipped

**Goal.** Produce the artifact that turns this epic into a reply App Review can act on, without
claiming anything the tree does not support.

**Tests first (TDD).**
- `test/policy/permissions_test.dart` — still asserts the whole-set posture: zero
  `NS*UsageDescription` keys, no entitlements, no background modes. Two new games must not move it,
  and it is named here because "the app asks for nothing" is one of the claims T12.17 makes.
- `test/policy/arb_content_test.dart` — extended with the banned-absolutes check over the new copy,
  for the locales the team can read. E11 recorded that `fa`/`ckb` claim strength is a native-review
  line item rather than a grep, and that stays true here.
- `test/policy/store_listing_test.dart` — **new.** Every differentiator asserted in
  `docs/review/app-review-4-3-a.md` names a file, a test or a setting that exists. A store answer
  that drifts from the tree is the failure mode this test exists to prevent, and it is the reason
  this task is last rather than first.

**Implementation.**
1. `docs/review/app-review-4-3-a.md` — what was rejected, what changed, and the checkable claim
   behind each differentiator: the four locales and the `ckb` delegate trio; the script-pinned
   numeral bridge; the colour-free board and its palette-independence golden; zero permissions, zero
   network code, zero telemetry.
2. Update the store description and the What's New text in every locale the store supports, from
   that document rather than from memory.
3. Update `README.md`'s game table to four rows, and `epics/README.md` to twelve epics.

**Explicitly not in scope:** uploading the build, replying in Resolution Center, and the resubmission
itself. Those are account-holder actions with no API (`release-and-store-shipping` rule 14). This
epic produces the evidence; a human sends it.

**Files.** `docs/review/app-review-4-3-a.md`, `README.md`, `epics/README.md`,
`test/policy/store_listing_test.dart`, `test/policy/arb_content_test.dart`.

## Gates that must pass

```bash
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs   # ALWAYS before analyze
dart format --set-exit-if-changed .
flutter analyze --fatal-infos --fatal-warnings
flutter test --test-randomize-ordering-seed random

# every skill gate, through the one runner E01 T01.11 built
bash tool/skill_gates.sh

# this epic's named spot-checks, run individually so a failure names itself
.claude/skills/sunburst-tokens/scripts/check_raw_values.sh                lib
.claude/skills/sunburst-components/scripts/check_component_hygiene.sh     lib
.claude/skills/sunburst-shell-screens/scripts/check_shell_boundaries.sh   lib
.claude/skills/sunburst-game-surfaces/scripts/check_game_palette.sh       lib
.claude/skills/sunburst-motion-and-haptics/scripts/check_motion_tokens.sh lib
.claude/skills/sunburst-tokens/scripts/check_palette_contrast.sh          lib/theme/sunburst_colors.dart

# Localization and RTL — both scripts, not one twice
.claude/skills/i18n-rtl-l10n/scripts/check_i18n_bans.sh    lib
.claude/skills/i18n-rtl-l10n/scripts/check_arb_parity.sh   lib/l10n

# Architecture, determinism, test hygiene
.claude/skills/flutter-architecture/scripts/check_architecture.sh                      lib
.claude/skills/project-structure-and-packages/scripts/check_import_boundaries.sh       lib/core
.claude/skills/state-management-riverpod/scripts/ban-legacy-providers.sh
.claude/skills/seeded-determinism-and-golden-vectors/scripts/check-determinism-bans.sh lib/games/digit_bridge/domain
.claude/skills/seeded-determinism-and-golden-vectors/scripts/check-determinism-bans.sh lib/games/false_light/domain
.claude/skills/dart3-idioms-and-coding-standards/scripts/check-dart3-idioms.sh         lib
.claude/skills/custom-canvas-and-gestures/scripts/check_painter_hygiene.sh             lib
.claude/skills/testing-strategy/scripts/check_test_hygiene.sh                          lib test

# accessibility-as-code ships no gate script of its own; test/policy/a11y_bans_test.dart is the
# gate, and `flutter test` above runs it.

# This epic's headline gate
bash tool/check_no_shell_edits.sh

# iOS build on the canonical device
xcrun simctl boot C13DDC02-375D-4E1B-8F81-44EB407D09A4
flutter run -d C13DDC02-375D-4E1B-8F81-44EB407D09A4
```

`check_palette_contrast.sh` is load-bearing in this epic in a way it has not been before: it is the
gate that decides whether an accent may ship, and T12.1's four new `// @contrast` declarations are
recomputed from the shipped hexes rather than trusted. The `flutter run` line is not a CI step — CI
has no simulator, and this epic does not pretend otherwise.

## Risks and open questions

1. **The depth delta may not be perceivable at board sizes, which would kill False Light.** The
   chrome shadow is tuned for a surface a player looks at deliberately; a board is scanned
   peripherally under time pressure, and reduced contrast sensitivity is common in the audience a
   brain trainer serves. **Decision:** T12.9 runs first, measures rather than assumes, and gates the
   rest of the game. If the delta cannot be made obvious at arm's length in one second without
   shrinking tiles below 48px, **the game does not ship** and this epic delivers Digit Bridge alone
   plus a recorded reason. That is a better outcome than a second rejection for an unplayable board.

2. **Digit Bridge may read as "a maths app" to a reviewer, which is its own saturated genre.** The
   mechanic is symbol matching, not arithmetic, and nothing in it adds or subtracts. **Decision:** the
   store copy and the in-app kicker say "match the numeral across two writing systems", never
   "numbers" or "maths", and the home-card artwork shows the two scripts side by side rather than
   digits alone. If it still reads as arithmetic on the reference screen, that is a T12.2 finding and
   `app.html` changes before any Dart is written.

3. **The script-pinned stimulus is a real exception to a working agreement, and exceptions spread.**
   **Decision:** it is fenced to two widget subtrees, routed through the single `NumberFormat` site
   via `LocaleNumbers.forScript`, recorded in `docs/decisions/0002`, and
   `test/policy/number_format_sites_test.dart` fails if it becomes a second construction site. The
   exception is to *which* script renders, never to *how* one is constructed.

4. **A negative score may not survive the shell.** `ScoreFormat.points` has only ever rendered a
   count that goes up, and the BEST ranking has only ever seen non-negative values. **Decision:**
   T12.11 asks the question with a shell test before the game depends on the answer. If it has to
   widen, it widens for every game at once and the widening is recorded — the E10 precedent. The one
   thing that must not happen is a clamp inside the game to avoid finding out.

5. **Two new accents mean two new `SunburstColors` slots, and working agreement 2 has six
   touchpoints.** A slot added to the field and the constructor but not to `lerp` is a silent
   discontinuity that no screen shows and no gate catches. **Decision:** `sunburst_theme_test.dart`
   walks every (accent, role) pair computationally and `theme_equality_test.dart` covers
   `copyWith`/`lerp`/equality across the whole slot set; both are extended in T12.1 **before** any
   slot is added.

6. **`system.html` gains a hex that was chosen, not transcribed.** The lilac pair is new; it is not in
   the rendered design today. **Decision:** it goes into `system.html` first and `app.html` renders
   with it, so the reference screens and the app agree — and `test/theme/token_parity_test.dart`
   already makes "every hex in Dart exists in `system.html`" a test rather than a habit. The lilac
   must be added to its `kPrimitiveToCssVar` transcription table, which is the step that forces it
   into the design source rather than into Dart. The measured ink
   ratios (6.82 and 5.15) are recorded beside the values so the choice is auditable.

7. **Four games change the home hub's rhythm, and `01-home.png` is a reference eight epics old.**
   **Decision:** T12.2 re-captures it in both directions as a deliberate design change, and T12.16
   signs it off as a regression rather than treating it as incidental.

8. **`ckb` remains the locale with no system-language path.** Nothing here changes that; both new
   boards must still be exercised in Sorani through the in-app Language sheet. **Decision:** T12.16
   lists it explicitly. False Light makes it cheap — with no text on the board, its `ckb` render is
   provably identical to its `en` one, and T12.12's byte-identical golden is what proves it.

9. **This epic does not guarantee the rejection is overturned.** 4.3(a) is a reviewer judgement, and
   shipping differentiation improves the argument without settling it. **Decision:** say so here
   rather than in a post-mortem. If a second rejection follows, the next step is an App Review Board
   appeal with `docs/review/app-review-4-3-a.md` as the evidence — not a third game added in hope.

## Definition of done

1. Both games are playable end to end on the canonical simulator in all four locales, at difficulty
   `chill`, `classic` and `blitz`, and both record runs that appear in Stats.
2. `bash tool/check_no_shell_edits.sh` prints `OK`, or the widenings it forced are recorded in this
   file and in the PR body with the reason each is game-agnostic.
3. `flutter test` is green, including the locale-independent vector tables for both games, the
   real-font Persian lane for Digit Bridge, the greyscale and palette-independence goldens for False
   Light, and the byte-identical `en`/`fa` golden that proves False Light carries no text.
4. Every gate in `Gates that must pass` exits 0.
5. `screens/09-digit-bridge.png`, `screens/10-false-light.png`, `screens/01-home.png` and all three
   `rtl/` counterparts exist, were captured from `app.html` in the same commit as the layout they
   render, and are signed off in `docs/verification/e12-simulator-signoff.md`.
6. `docs/verification/e12-depth-delta.md` records what T12.9 measured, including a negative result if
   that is what it found.
7. `docs/review/app-review-4-3-a.md` exists and every claim in it names a file, a test or a setting,
   with `test/policy/store_listing_test.dart` green.
8. `README.md` lists four games, `epics/README.md` lists twelve epics, and `CLAUDE.md`'s current-state
   section names the shipped set.
9. The commit sequence is granular, tests are committed with the code they cover, and no commit
   message contains an emoji.
10. `/simplify` then `/code-review` have run and their findings are addressed.
11. The PR uses `.github/PULL_REQUEST_TEMPLATE.md` and names every screen compared.
