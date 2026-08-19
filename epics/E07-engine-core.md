# E07 · Engine core

| | |
|---|---|
| **Branch** | `epic/07-engine-core` |
| **Depends on** | E02, E03, E04 |
| **Unblocks** | E08, E09, E10 |
| **Status** | Not started |

## The epic

Build the seam that makes "one codebase, many games" real, with **zero games in it**. This epic
delivers the engine vocabulary — `GameDefinition`, `BoardSnapshot`, `GameRegistry`, `RunConfig`,
`GameId`, `Difficulty`, `RunOutcome` — the run lifecycle (`RunPhase` machine, `RunTicker` over the
injected `Clock`, `RunNotifier` and its persist-then-transition edge), and the seeded PRNG that makes
a round reproducible from a bug report. It **adopts** the typed `Result`/`Failure` spine E02 shipped
and extends it with `RunFailure`; it does not define a second one. `ScoreFormat` likewise comes from
E02's `lib/core/score_format.dart` — it is the enum the `runs` table's `metric_kind` CHECK mirrors,
and there is no `MetricKind` beside it.

Two properties are load-bearing and they pull in opposite directions, so the epic states both up
front:

- **Nothing the engine computes depends on the locale.** Seeds, draw sequences, phase transitions,
  elapsed milliseconds, scope strings and the persisted `RunDraft` are byte-identical under `en`,
  `de`, `fa` and `ckb`. Generators produce integers and semantic tokens; localisation happens at
  RENDER, never inside a generator. T07.10 proves it under all four locales.
- **Everything the engine hands upward is localisable.** `ScoreFormatter` formats through E04's
  numeral policy — `1,480` / `1.480` / `۱٬۴۸۰` — never through string interpolation.
  `GameDefinition` carries ARB **keys**, not display strings. `ResultStat` carries a key plus a
  canonical integer. `RunState` carries no formatted string at all.

Nothing here renders. No screen, no board, no Stroop, no Schulte, and no simulator run. The proof
that the seam works is a **fixture game that lives only under `test/`**: it is registered through
`gameRegistryProvider`, driven through a complete run headlessly, and it adds zero lines to
`lib/features/**`. E08 then builds the eight screens against these types, and E09/E10 add real games
by appending one line to the registry.

## Why we need it

Schulte Grid is the product's central claim: the second game must ship without editing
`lib/features/**`. That claim is decided here, not in E10. If `GameDefinition` is missing a field the
shell needs, E10's only options are a `switch (gameId)` in a shell file or a fork of
`PlayScaffoldScreen` — and the engine is gone.

Without this epic:

- E08 has nothing to render. Every shell screen reads `GameDefinition` fields and `RunState`; the
  screens cannot be written against types that do not exist.
- The run has no clock. `sunburst-shell-screens` rule 3 gives the shell exactly one ticker; without it
  every game grows a `Stopwatch` and pause stops none of them.
- Runs are irreproducible. A player reporting "the Blitz round gave me two orange keys" hands us a
  seed that means nothing, because there is no frozen PRNG to replay it with.
- The persist-then-transition ordering has no owner, so the personal-best badge will eventually
  celebrate a run that failed to save.
- **The locale leaks into the engine.** This is the new failure mode and it is silent: a generator
  seeded off a formatted score, a `RunState` holding `"۱٬۴۸۰"`, or a `ResultStat` holding a German
  sentence all compile, all pass an English-only test suite, and all produce a different game for a
  Persian player. The seam has to be locale-independent by construction before eight screens and two
  boards are written on top of it.

## Current state

Verified by `ls` at the repo root on 2026-08-19:

- **The Flutter app is not scaffolded.** No `pubspec.yaml`, no `lib/`, no `test/`, no `.github/`.
  The repo root holds `CLAUDE.md`, `50-apps-challenge-slides.html`, `design/`, `.claude/`, `epics/`.
- `git log --oneline` shows 4 commits on `main`: convention skills + slides, three candidate design
  systems, Sunburst Pop screenshots, five `sunburst-*` skills + `CLAUDE.md`.
- `.claude/skills/` holds 45 skills and 49 gate scripts under `.claude/skills/*/scripts/*.sh`. **They
  do not all exit 0 on an absent target** — measured with no argument, 29 of the 49 fail: 21 exit 2, 7
  exit 1, and `check-scheduler-purity.sh` exits 127 on macOS bash 3.2. E01 T01.6 corrected `CLAUDE.md`
  working agreement 10 to say so and E01 T01.11 built `tool/skill_gates.sh`, which carries an explicit
  run table and a skip table with a reason per row. That runner is the only sanctioned way to run the
  set.
- `.claude/skills/i18n-rtl-l10n/scripts/` holds `check_i18n_bans.sh` and `check_arb_parity.sh`. Both
  are wired by earlier epics; this epic consumes them and adds no new script.
- `design/sunburst-pop/` holds `system.html`, `app.html`, `capture-screens.sh` and eight LTR
  reference PNGs. `app.html` contains the literal score strings this epic formats: `1,480`, `1,240`,
  `18.6s`. Those are the **English** renderings; the RTL counterparts land under
  `design/sunburst-pop/screens/rtl/` in E04.

Toolchain, verified on this machine and not to be re-derived:

- Flutter **3.44.6** stable · Dart **3.12.2** · DevTools 2.57.0
- Xcode **26.6** (build 17F113) · CocoaPods **1.15.2** · simulator runtimes iOS 18.0, 18.6, 26.5
- **iOS is the only shipping target. Android is deferred** — not "parity later", not "should also
  work". Nothing in this epic may claim an Android behaviour.
- The canonical device is the simulator `MindForge iPhone 14`, UDID
  `C13DDC02-375D-4E1B-8F81-44EB407D09A4`, iOS 18.6, at exactly 390×844 logical points.
  **This epic never boots it** — it renders nothing. E08 is the first epic that does.

This epic's declared dependencies are **E02, E03 and E04** — every symbol it consumes comes from one
of those three. In the linear delivery order E05 and E06 have also merged by the time it starts, so
`lib/ui/components/**` and `lib/shared/**` exist on disk; this epic imports nothing from either, which
is why neither is an edge. What it does inherit: `pubspec.yaml`, `analysis_options.yaml`,
`.github/workflows/`, `l10n.yaml` + `AppLocalizations`, the four-locale ARB set, `lib/core/**`,
`lib/theme/**` (including `game_accent.dart` with `GameAccent` and `GameColourRole`), and `lib/data/**`
with the drift database and `RunRepository`. **Nothing under `lib/games/**` or `lib/features/play/**`
exists yet.**

Specifically inherited, and **not to be redeclared here**:

| From | Symbol |
|---|---|
| E02 T02.2 | `lib/core/result.dart`, `lib/core/failure.dart` (the spine), `lib/core/score_format.dart` (`enum ScoreFormat { points, duration }`), `lib/core/run_metric.dart`, `lib/core/run_draft.dart`, `lib/core/run_record.dart`, `lib/core/run_scope.dart`, `lib/core/calendar_day.dart` |
| E02 T02.6 | `lib/core/run_commit.dart` — `RunCommit(record, isPersonalBest)`, what `RunRepository.saveRun` returns |
| E02 T02.2 | `lib/core/app_settings.dart` — the settings value, **complete on arrival**: the four booleans (`isSoundEnabled`, `isHapticsEnabled`, `isReduceMotionEnabled`, `isColourBlindPalette`) and `SupportedLocale? localeOverride`. E04 and E06 read it and neither adds a field. This epic reads none of it directly. |
| E03 T03.10 | `lib/theme/game_accent.dart` — `GameAccent`, `GameColourRole` |
| E04 | `lib/l10n/` — the four-locale ARB set (`app_en.arb` template, `app_de.arb`, `app_fa.arb`, `app_ckb.arb`), the generated `AppLocalizations`, the active-locale provider, `LocaleNumbers.forLocale(Locale)`, `AsciiNumerals.normalize(String)`, the FSI/PDI isolate helper, and **`appLocalizationsProvider`** (a context-free `Provider<AppLocalizations>`) |
| E02 T02.2 | `lib/core/hud_tone.dart` — `enum HudTone { neutral, highlight, alarm }`. E05's `HudPill` renders it, this epic's `GameHud` carries it; `lib/ui/` may not import `lib/features/`, so `lib/core/` is the only layer both reach — and it is declared in **E02** rather than E05 precisely so this epic can import it without depending on an epic its header does not name. |

`ls lib/core/ lib/l10n/` before T07.1. If any of these is missing, that is a gap in the epic that owns
it — fix it there, do not shim it here, and never declare a second `Result`, a second score enum, a
second `HudTone`, or a second number formatter.

**Two E04 hand-offs this epic depends on and cannot work around.** Name them out loud before starting:

1. `appLocalizationsProvider`. `scoreFormatterProvider` (T07.3) needs the seconds unit string with no
   `BuildContext`. Under the pre-localization sequence this provider was introduced by the shell
   epic; with E04 landing first, it belongs to E04. If it is absent, that is an E04 gap.
2. **ARB keys are `lowerCamelCase`,** so a key string is character-for-character the name of its
   generated `AppLocalizations` getter (`difficultyChill` → `l10n.difficultyChill`). T07.5 turns
   `GameDefinition`'s key fields into a checkable contract by reading the generated class and
   asserting a getter exists per declared key; snake_case keys would generate snake_case getters,
   break `naming-conventions` rule 2, and make that check impossible. E01 T01.9's key regex
   (`^[a-z][a-zA-Z0-9_]*$`) already permits it. If E04 chose snake_case, resolve it in E04 before this
   epic starts.

## What we will achieve

A human can run `flutter test` and see a whole run happen for a game the engine has never heard of,
with no widget pumped, no test that sleeps, and the same bytes out under four locales.

Observable end state:

1. `lib/games/game_definition.dart` declares `GameDefinition` with `id`, `accent`, `colourRole`,
   `scoreFormat`, `strings` (ARB keys), `difficulties`, `boardBackground`, `isTimed`, `runLimitFor`,
   `isLocked`, `buildBoard`, `buildArtwork`, `snapshotOf`. **No field is a display string, a `Locale`,
   a `NumberFormat` or an `AppLocalizations`.**
2. `lib/games/game_registry.dart` declares `gameRegistryProvider` and `gameDefinitionProvider` and is
   the only file in `lib/` allowed to enumerate the game registry. It ships **empty**
   (`const <GameDefinition>[]`).
3. `RunNotifier` drives `idle → countdown → playing → paused → over` and is the only thing that
   assigns a `RunPhase`. `over` is terminal, provably: a test asserts no public method produces an
   edge out of it.
4. `flutter test` runs the full transition table — 25 cells, 7 legal, 18 illegal — plus a lifecycle
   suite that pushes `AppLifecycleState` values through the observer and asserts `resumed` does not
   un-pause.
5. No test sleeps. Time comes from `fakeAsync` + `package:clock`; the ticker runs at 10 Hz in fake
   time and a 60-second Blitz run completes in microseconds.
6. `test/core/seed_vectors.dart` holds a committed golden-vector table computed by an **independent**
   oracle (`tool/seed_vectors_oracle.py`), and `flutter test` fails if `SeededGenerator` drifts by one
   bit — **in any of the four locales**.
7. `test/engine/engine_seam_test.dart` registers `fixtureGameDefinition` — declared in
   `test/support/fixture_game.dart`, referenced nowhere in `lib/` — plays it to completion through
   `RunNotifier`, and reads its score, HUD and progress back off `RunState`.
8. `test/policy/shell_boundary_test.dart` fails if any file under `lib/features/**` imports
   `lib/games/<a specific game>/`, and
   `.claude/skills/sunburst-shell-screens/scripts/check_shell_boundaries.sh lib` is green.
9. `ScoreFormatter` renders `1480` as `1,480` (en) · `1.480` (de) · `۱٬۴۸۰` (fa) · `۱٬۴۸۰` (ckb), and
   `18_600 ms` as `18.6` · `18,6` · `۱۸٫۶` · `۱۸٫۶` seconds, composed with the unit word from ARB. The
   English pair is the exact string in `design/sunburst-pop/app.html`.
10. `test/engine/locale_independence_test.dart` runs the vector table and a complete fixture run under
    `en`, `de`, `fa` and `ckb` and asserts byte-identical output, and
    `test/policy/engine_locale_purity_test.dart` fails if `package:intl` or `AppLocalizations` appears
    anywhere on the generation path.

Nothing renders. There is no new screen to compare against a PNG and no simulator to boot; that lands
in E08.

## Skills to load

| Skill | Why, for this epic |
|---|---|
| `flutter-conventions-index` | Front door. Carries the cross-cutting house rules and routes anything this table does not cover. Rule 12 is the one that changed shape: RTL and a11y by construction, every user string from ARB. |
| `i18n-rtl-l10n` | The whole localisation half of this epic. `references/numerals-and-calendars.md` is normative for T07.3: the four digit systems, the Persian/Arabic separator trap (`٫` U+066B decimal, `٬` U+066C grouping), the measured fact that **`intl` has no number symbols for `ckb` and silently falls back to Latin**, and the "assert the digit block per shipped locale" test. Rule 6 (store canonical: UTC epoch + ASCII) and rule 7 (normalise before parse) are what T07.10 proves. `scripts/check_i18n_bans.sh` and `check_arb_parity.sh` are the two gates. |
| `sunburst-shell-screens` | Owns the seam this epic implements: `references/shell-game-boundary.md` fixes `GameDefinition`/`BoardSnapshot`/`GameHud`/`RunConfig` field-for-field, and `references/run-lifecycle.md` fixes every `RunPhase` edge, its trigger and its side-effect order. Build to those two files; the three deliberate widenings are named in Risks. |
| `sunburst-game-surfaces` | Declares `GameAccent`, `GameColourRole` and the `mechanic ⇒ surfaceSunk` / `decorative ⇒ gameAccent` pairing that `GameDefinition` must carry and T07.5 turns into a constructor assert plus a test. Rule 9 — large text is absorbed by a smaller BASE style, never a clamped scaler — is why nothing here formats to a fixed width. |
| `flutter-architecture` | Where each engine file belongs, the downward-only DAG (`features → data → core`), and rule 3 — abstract only what cannot run in a test, which is why the ticker takes a `Clock` and nothing else here gets an interface. |
| `project-structure-and-packages` | Fixes `lib/core/` as the sanctioned Flutter-free foundation (`Result`, `Failure`, `SeededGenerator`, `Difficulty`, `ScoreFormatter`), the one-package default, and `test/` mirroring `lib/` 1:1. Its `check_import_boundaries.sh` is the gate that keeps `lib/core/` pure — and T07.3 records the hole in that gate's regex. |
| `state-management-riverpod` | `RunNotifier` is a `FamilyNotifier` over an immutable `RunState`; providers are the DI; `family` keys must be value-equal (`RunConfig`); no legacy providers; no `DateTime.now()` in state logic. Rule 4 (derive, don't store) is why `RunState` holds no formatted score. |
| `service-boundary-and-native` | The `Clock` seam: `clockProvider` from `package:clock`, never a bespoke `ClockService`, overridden with `Clock.fixed`/`fakeAsync` in tests. Rule 2 — abstract only what cannot run in a test — is why `scoreFormatterProvider` is a plain derived provider now, not a throwing seam. |
| `error-handling-typed-results` | The sealed `Result<T, F extends Failure>` spine, and rule 3 specifically: **a `Failure` carries a stable `code` and typed params, never a localized string**, because a baked-in message breaks translation, RTL mirroring and numeral rendering. Also exhaustive switches with no `default:`, and the persist-then-transition rule `RunNotifier._finish` implements. |
| `seeded-determinism-and-golden-vectors` | FNV-1a-64 + SplitMix64 written out line for line, the salt-per-feature rule, draw order as a contract, the frozen-generator rule, and the golden-vector table computed from an independent oracle that CI verifies and never blesses. Rule 1 (the key is injected, never read) extends here to: the key is ASCII, never a formatted string. |
| `dart3-idioms-and-coding-standards` | Which construct each engine type earns: `sealed` + `final` for `Result`/`Failure`/`RunOutcome`, enhanced enums for `Difficulty`/`ScoreFormat`/`StatFormat`, immutable value types with `copyWith`, total non-throwing domain functions, and the complexity limits `RunState` and `RunNotifier` must justify. |
| `testing-strategy` | Every test shape this epic uses: `package:test` tier for pure logic, `ProviderContainer` for headless notifiers, `fakeAsync` for timers, bare-`implements` fakes over mocks, seeded fuzz against an independent oracle, and the locale matrix as a parameterised table rather than four copied test bodies. |
| `async-safety` | `RunNotifier._finish` is the one `unawaited(...)` in the shell; `ref.mounted` after the `saveRun` await; `_ticker` and the lifecycle observer released in `ref.onDispose`. |
| `value-objects-money-and-units` | Canonical storage for a score: integer points, whole milliseconds for a duration, per-mille for a percentage, converted only at the presentation edge. Rule 11 — normalise digits to ASCII **before** input reaches the core — is exactly the boundary T07.10 asserts nothing crosses. |
| `naming-conventions` | The role suffixes this epic spends: `RunNotifier` (ViewModel), `ScoreFormatter` (pure formatter), `RunFailure` (sealed failure), `RunTicker`; file name = primary declaration; units in identifiers (`scoreValue`, `elapsedMilliseconds`, `canonicalValue`). |
| `dartdoc-conventions` | Every symbol here is a public contract three later epics build on. `public_member_api_docs` is an analyzer error, so a missing `///` fails `flutter analyze --fatal-infos`. Rule 5 is load-bearing for `ResultStat.canonicalValue`, whose unit depends on its `StatFormat`. |
| `sunburst-motion-and-haptics` | T07.7 only, and only for two numbers: the run timer ticks at 10 Hz, and every boundary moment (`timerAlarm`) carries a latch on the immutable notifier state. No haptic is fired in this epic — that wiring is E06's `FeedbackService`, consumed in E08. |
| `ci-pipeline-and-gates` | T07.9 and T07.10 add steps to `.github/workflows/ci.yml` (E01's file): the shell-boundary grep, the determinism-ban grep and the locale-purity policy test. Rules 1, 7 and 9 govern them — one named contract each, textually decidable, verify-never-bless. |
| `dependency-hygiene` | Only if `intl` is not already resolved through E01's l10n setup: caret range, `pubspec.lock` staged in the same commit, and the transitive audit that proves it opens no network path. |

## Tasks

### T07.1 — Adopt E02's result spine and add the run failure family

**Goal.** One `Result`/`Failure` vocabulary shared by the engine, the repository and every pure
function, with failure codes that survive translation. **E02 T02.2 owns `lib/core/result.dart` and
`lib/core/failure.dart`** — it is the first consumer, every repository method returns one, and it
merges before this epic. This task adopts them unchanged and adds only `lib/core/run_failure.dart`.
There is no conditional and no fallback: if the spine is missing, that is an E02 gap to fix in E02.

**Tests first (TDD).** `test/core/result_test.dart` (extend E02's):
- `fold maps Ok through onOk and Err through onErr` — asserts both arms, no `default:` anywhere.
- `map transforms an Ok value and passes an Err through untouched` — asserts the `Err` instance is
  identical, not rebuilt.
- `switching a Result is exhaustive without a wildcard` — a switch over `Ok`/`Err` that compiles; the
  test's value is that adding a variant breaks the build.

`test/core/run_failure_test.dart`:
- `every RunFailure exposes a stable code and no localized string` — reflection-free: a const list of
  every `RunFailure` instance, asserting `code` matches `^[a-z]+\.[a-z_]+$`.
- `every RunFailure code is pure ASCII` — every rune below `0x80`. A code is a lookup key that is
  compared, logged and eventually mapped to an ARB entry; an Eastern-Arabic digit or an RTL mark in it
  is unmatchable and invisible in a diff.
- `no RunFailure field holds a sentence` — every `String` field on every variant matches
  `^[a-zA-Z0-9_.:-]*$`: ids and codes pass, prose does not.
- `no RunFailure field carries a bidi isolate character` — U+2066–U+2069 never reach a failure value.
  `i18n-rtl-l10n` rule 8: isolate characters are a view-layer wrapper and must never reach storage,
  search or export, and a failure code is all three.

**Implementation.** Read `lib/core/result.dart` and `lib/core/failure.dart` and change nothing in
them. Add `lib/core/run_failure.dart` — `sealed class RunFailure extends Failure` with the variants
the run needs that the repository does not own: an unregistered game id
(`run.unknown_game`, carrying the `GameId`), and a config whose difficulty the definition does not
offer (`run.unsupported_difficulty`, carrying the `GameId` and the `Difficulty`). Persistence failures
are **`DataFailure`**, E02's family, surfaced through `RunState.saveFailure` — do not mirror them into
`RunFailure`, or the results screen has two ways to say "the save did not land".

E08 renders a failure by switching on the sealed variant and reading an ARB key; the code is what
makes that switch possible in four locales. Write that sentence as a `///` on `RunFailure` so the next
agent does not add a `message` field.

**Files.** `lib/core/run_failure.dart`, `test/core/result_test.dart` (extend E02's),
`test/core/run_failure_test.dart`.

**Skills.** `error-handling-typed-results`, `dart3-idioms-and-coding-standards`,
`project-structure-and-packages`, `i18n-rtl-l10n`, `dartdoc-conventions`.

**Screenshot check.** n/a (no visual surface).

**Done when.**
- [ ] `flutter test test/core/` green.
- [ ] `.claude/skills/error-handling-typed-results/scripts/check-swallowed-catch.sh lib` green.
- [ ] `.claude/skills/project-structure-and-packages/scripts/check_import_boundaries.sh lib` green —
      `lib/core/` imports no Flutter, no `dart:io`, no `dart:ui`, and reads no wall clock.
- [ ] Exactly one `Result` and one base `Failure` exist in the repo (`grep -rn "sealed class Result" lib/`
      returns one line, and `git log --diff-filter=A -- lib/core/result.dart` shows E02's commit).
- [ ] `grep -rn "message\|label\|title" lib/core/run_failure.dart` returns nothing.

**Commits.**
1. `Add run failure taxonomy tests`
2. `Adopt E02's result spine and add the sealed RunFailure family`

### T07.2 — Seeded generator, run seed provider and golden vectors

**Goal.** A PRNG this repo owns, frozen by a committed vector table, so a round is reproducible from
`(gameId, difficulty, seed)` on any device, any future SDK **and any locale**.

**Tests first (TDD).** `test/core/seeded_generator_test.dart`:
- `fnv1a64 matches the frozen vector table` — every row of `test/core/seed_vectors.dart`.
- `SeededGenerator reproduces the frozen draw sequence` — first 16 `nextInt(1000)` draws per seed,
  fingerprinted, per row.
- `two generators from the same seed produce identical sequences` — byte-identical over 1000 draws.
- `consecutive keys do not correlate` — seeded fuzz, 500 iterations, asserting the first draw of
  `key_n` and `key_n+1` differ in at least 20 of 64 bits (SplitMix64 avalanche), with the key echoed
  in `reason:`.
- `nextInt(max) stays in range for max 1..1000` — fuzz, 5000 iterations.
- `seedFrom salts per feature` — the same key with two `featureSalt`s yields different sequences.
- `fnv1a64 hashes UTF-8 bytes, not code units` — the rows keyed `run-۱۲۳` (Persian digits, U+06Fx) and
  `ڕەنگ` (Sorani, including U+0695) come from the oracle, which encodes UTF-8 explicitly. These rows
  exist to pin the byte path, **not** to sanction a non-ASCII key.
- `seedFrom rejects a non-ASCII key` — `expect(() => seedFrom('run-۱۲۳', featureSalt: 1), throwsA(isA<AssertionError>()))`.
  This is the tripwire for the whole locale-independence property: if a future refactor ever seeds off
  a formatted string, it trips here in debug rather than silently producing a different game for a
  Persian player.

`test/core/seeded_random_provider_test.dart`:
- `the run seed is a pure function of the injected clock` — `clockProvider.overrideWithValue(Clock.fixed(t))`,
  two draws, identical seeds.
- `two instants produce different seeds` — `Clock.fixed(t)` vs `Clock.fixed(t + 1ms)`.
- `the seed key is an ASCII ISO-8601 instant under every locale` — `Intl.defaultLocale` set to `fa`,
  the key is still `2026-01-01T00:00:00.000Z`, never Jalali and never Eastern-Arabic digits.

**Implementation.** **`lib/core/seeded_generator.dart` is the one PRNG path in this repository, and
this task is where it lands.** It exports exactly three things and E09 and E10 both import them by
these names: `int fnv1a64(String key)`, `final class SeededGenerator` (SplitMix64: `nextInt64()`,
`nextInt(int max)`), and
`SeededGenerator seedFrom(String key, {required int featureSalt, int modeSalt = 0})` — transcribed
from `seeded-determinism-and-golden-vectors`, not invented. There is no `SeededRng`, no
`lib/core/random/seeded_rng.dart` and no `lib/shared/determinism/`; a game epic that adds one has
built a second generator and destroyed the frozen-vector guarantee this task exists to create. Frozen
salt constants live beside them, one per consumer, with a comment that they are frozen forever.

`seedFrom` opens with
`assert(key.runes.every((r) => r < 0x80), 'seed keys are ASCII; a localized string must never reach a generator')`.
`fnv1a64` itself takes any string — the oracle's non-ASCII rows go through it directly — so the guard
sits on the app-facing helper where the mistake would actually be made.

`lib/features/play/application/seeded_random_provider.dart`: `typedef RunSeedDraw = int Function();`
and `seededRandomProvider`, a `Provider<RunSeedDraw>` that reads `clockProvider` once and returns
`() => fnv1a64(clock.now().toUtc().toIso8601String())`. This is the only place a run's entropy is
read; the generator itself never touches a clock. `toIso8601String()` on a UTC `DateTime` is ASCII
Gregorian by construction and reads no ambient locale — restate that as a `//` at the call site,
because it is the line a well-meaning refactor toward "localised timestamps" would break.

`tool/seed_vectors_oracle.py`: a ~30-line **independent** Python implementation of FNV-1a-64 and
SplitMix64 that writes `test/core/seed_vectors.dart`. Rows cover the first and last key, an all-ASCII
key, `run-۱۲۳`, `ڕەنگ`, and one historical key. It encodes with `key.encode('utf-8')` explicitly.
Regeneration is `python3 tool/seed_vectors_oracle.py` reviewed in the PR diff — **CI verifies, never
blesses**.

Header comment on `seeded_generator.dart`: 64-bit integer arithmetic assumes a native target; **the
app ships iOS only** and must not be built for web without reimplementing this in 32-bit halves.

**Files.** `lib/core/seeded_generator.dart`,
`lib/features/play/application/seeded_random_provider.dart`, `tool/seed_vectors_oracle.py`,
`test/core/seed_vectors.dart`, `test/core/seeded_generator_test.dart`,
`test/core/seeded_random_provider_test.dart`.

**Skills.** `seeded-determinism-and-golden-vectors`, `testing-strategy`, `service-boundary-and-native`,
`i18n-rtl-l10n`, `dart3-idioms-and-coding-standards`.

**Screenshot check.** n/a (no visual surface).

**Done when.**
- [ ] `flutter test test/core/seeded_generator_test.dart test/core/seeded_random_provider_test.dart` green.
- [ ] `.claude/skills/seeded-determinism-and-golden-vectors/scripts/check-determinism-bans.sh lib/core` green.
- [ ] `.claude/skills/service-boundary-and-native/scripts/check-service-boundaries.sh lib` green — no
      `DateTime.now()`, no ambient `Random()`.
- [ ] The vector table's header names the oracle command and states it was not generated by the
      implementation under test.
- [ ] `grep -rn 'SeededRng\|shared/determinism\|core/random' lib/ test/` returns nothing — one name,
      one path, and E09/E10 have no fallback to fall back to.
- [ ] `grep -rn "package:intl\|NumberFormat\|AppLocalizations" lib/core/seeded_generator.dart lib/features/play/application/seeded_random_provider.dart`
      returns nothing.

**Commits.**
1. `Add seeded generator tests and the oracle-computed vector table`
2. `Add FNV-1a and SplitMix64 seeded generator`
3. `Assert seed keys are ASCII so a localized string can never seed a run`
4. `Add the run seed provider over the injected clock`

### T07.3 — Engine vocabulary: GameId, Difficulty, RunScope.of, and the locale-aware ScoreFormatter

**Goal.** The pure value types every later epic names, the single conversion from typed ids to the
ASCII strings E02 persists, and score formatting that produces the right digits in all four locales.

**`ScoreFormat` is E02's, not this epic's.** `lib/core/score_format.dart` already declares
`enum ScoreFormat { points, duration }`, and the `runs` table's `metric_kind` CHECK mirrors
`ScoreFormat.name`. This task imports it for `GameDefinition.scoreFormat` and `ScoreFormatter`. Do not
declare a second score enum here — one rename between `duration` and `durationMs` on the single column
that decides MAX versus MIN is a silent wrong-personal-best bug.

**`LocaleNumbers` is E04's, not this epic's, and this task adds no `NumberFormat` construction
site.** `lib/l10n/locale_numbers.dart` is the **only** file in `lib/` allowed to construct one — E02
T02.11's `canonical_storage_test.dart` asserts no file under `lib/data/` or `lib/core/` contains
`package:intl`, `NumberFormat`, `DateFormat`, `toStringAsFixed` or `Intl.`, and E04 T04.6's
`locale_independence_test.dart` plus its Done-when grep assert the same rule from the other side.
`LocaleNumbers` is also where `ckb` is pinned to `fa`'s symbol data, because `intl` ships no `ckb`
number symbols and would otherwise fall back to Latin digits. **Consequence for this task:**
`ScoreFormatter` takes *injected closures*, not formatters of its own, so `lib/core/score_formatter.dart`
imports nothing at all; and `lib/l10n/score_formatter_provider.dart` supplies those closures from the
one `LocaleNumbers`. Both E02's and E04's policy tests are in this epic's named spot-checks below.

**Tests first (TDD).** `test/core/game_id_test.dart`:
- `GameId is value-equal and usable as a map key` — two `GameId('stroop_rush')` are `==` with equal
  `hashCode`; a `Map<GameId, int>` round-trips.
- `GameId rejects an empty or non-snake-case value` — asserts in debug; the id is also a route
  segment and a DB key.
- `GameId rejects a non-ASCII value` — `GameId('بازی')` and `GameId('run-۱')` both trip the assert.
  The id is a URL segment, a filename fragment and a primary key; localised text in it is
  unrepresentable downstream and unsearchable.

`test/core/difficulty_test.dart`:
- `the three difficulties are declared in display order` — `Difficulty.values` is
  `[chill, classic, blitz]`.
- `a difficulty carries a lock flag and nothing about time` — `Difficulty` has **no `runLimit` field**;
  the test asserts the field list, because a run length on the difficulty enum forces every game to be
  timed the same way (see T07.5 and Risk 5).
- `a difficulty carries an ARB key, never a label` — `Difficulty.chill.labelKey == 'difficultyChill'`,
  and no `Difficulty` member holds a string containing a space or a capital first letter.

`test/core/run_scope_test.dart`:
- `RunScope.of maps a typed id and difficulty to the persisted strings` —
  `RunScope.of(const GameId('stroop_rush'), Difficulty.classic)` equals
  `const RunScope('stroop_rush', 'classic')`, and a null difficulty yields a null `difficultyId`
  (the all-difficulties scope).
- `the persisted difficulty id is the enum name, never the label key` — `'classic'`, not
  `'difficultyClassic'` and never a translated word. The column is a join key that must survive a
  translation edit.
- `RunScope.of is the only conversion` — a policy grep asserting no file outside `run_scope.dart`
  constructs a `RunScope` from a `.value` or a `.name`.

`test/core/score_formatter_test.dart` — one parameterised table over
`['en', 'de', 'fa', 'ckb']`, not four copied bodies:
- `points render with each locale's grouping separator` — `1480` renders `1,480` / `1.480` / `۱٬۴۸۰` /
  `۱٬۴۸۰`, and `1240` renders `1,240` / `1.240` / `۱٬۲۴۰` / `۱٬۲۴۰`. The English pair is transcribed
  from `design/sunburst-pop/app.html`.
- `fa and ckb emit Extended Arabic-Indic digits` — every digit rune of the `fa` and `ckb` output is in
  U+06F0–06F9. **Not** U+0660–0669 (that is Arabic-Indic, a different block and different glyphs for
  4, 5 and 6) and **not** U+0030–0039. This is the assertion that catches `intl`'s silent Latin
  fallback for `ckb`; without it, `ckb` ships an untranslated-looking UI and no other gate notices.
- `de groups with a full stop and separates decimals with a comma` — `1.480` and `18,6`.
- `a duration renders one decimal in each locale's separator` — `18_600 ms` → `18.6` / `18,6` / `۱۸٫۶` /
  `۱۸٫۶`, then composed through the ARB unit pattern so the full `en` string is `18.6s`.
- `the seconds unit comes from ARB, not from a literal` — `grep "'s'" lib/core/score_formatter.dart`
  returns nothing; the formatter is constructed with the unit pattern and cannot know the word.
- `a duration rounds half away from zero at the tenth in every locale` — `18_650 → .7`,
  `18_649 → .6`, asserted on the ASCII-normalised output so the row reads the same for all four.
- `zero and a sub-second duration render without a leading gap` — `0 → 0.0` / `۰٫۰`,
  `900 → 0.9` / `۰٫۹`.
- `every formatted duration round-trips through AsciiNumerals.normalize` — fuzz, 2000 values × 4 locales:
  `double.parse(AsciiNumerals.normalize(rendered))` equals `tenths / 10`. This exercises both the digit fold
  and the separator fold (`٫` U+066B → `.`, `٬` U+066C dropped), which is where a digits-only
  normaliser silently corrupts `1٫5` into `15`.
- `formatting is a pure function of its injected closures` — set `Intl.defaultLocale = 'fa'`, format
  through a `ScoreFormatter` built from `LocaleNumbers.forLocale(const Locale('en'))`, assert Latin
  digits. No ambient locale is ever read.
- `lib/core/score_formatter.dart` imports nothing but lib/core` — a source assertion, re-stating
  E02 T02.11's and E04 T04.6's rule at the one file most likely to break it.

`test/l10n/score_formatter_provider_test.dart`:
- `the formatter follows the active locale` — override E04's locale provider with each of the four and
  assert the digit block.
- `changing the locale rebuilds the formatter and nothing else` — a `RunState` held across the change
  is `==` to itself; only the rendered string differs.

**Implementation.** `lib/core/game_id.dart`: `final class GameId` wrapping `final String value`, const
constructor, `==`/`hashCode`/`toString`, `assert` on the snake_case-ASCII shape
(`^[a-z][a-z0-9_]*$`).

`lib/core/difficulty.dart`: enhanced `enum Difficulty { chill, classic, blitz }` with
`final bool isLocked`, `final String labelKey`, and **no run limit**. Run length belongs to the game,
not to the difficulty: Stroop Rush is a fixed round count and Schulte Grid is a race scored by elapsed
time, and a `runLimit` on this enum would force the shell to cut a Schulte player off mid-board.
`GameDefinition.runLimitFor(Difficulty)` (T07.5) carries it instead, nullable, `null` meaning untimed.
`labelKey` is the ARB key (`difficultyChill` / `difficultyClassic` / `difficultyBlitz`) — the enum
carries the key, E08 resolves it. German is the length case here: "Klassisch" against "Classic" is the
kind of expansion the difficulty chip has to absorb by taking a smaller BASE style, never by clamping
(`sunburst-game-surfaces` rule 9). This epic ships no layout and so cannot prove it fits; E08 owns
that.

`lib/core/run_scope.dart` **(edit — E02 created it)**: add
`factory RunScope.of(GameId gameId, Difficulty? difficulty)`, mapping to `gameId.value` and
`difficulty?.name`. This is the one place a typed id becomes a persisted string; screens hold
`GameId`/`Difficulty` and E02's providers are keyed by `RunScope`, so without it every screen
hand-builds the key and one of them eventually spells it differently. A `//` on the `difficulty?.name`
line restates the invariant: **the persisted id is the enum name, never `labelKey` and never a
localized label.**

`lib/core/score_formatter.dart`:

```dart
/// Renders a canonical score value as display text.
///
/// Holds no formatter and imports nothing: `formatPoints` and `formatSeconds`
/// arrive from E04's single `LocaleNumbers`, and `durationLabel` is the ARB
/// pattern. That is what keeps `lib/core/` free of `package:intl` — a rule
/// E02 T02.11 and E04 T04.6 each assert from their own side.
final class ScoreFormatter {
  const ScoreFormatter({
    required this.formatPoints,   // String Function(int)    — grouped, 0 fraction digits
    required this.formatSeconds,  // String Function(double)  — exactly 1 fraction digit
    required this.durationLabel,  // ARB pattern: (secondsText) => '18.6s'
  });

  final String Function(int) formatPoints;
  final String Function(double) formatSeconds;
  final String Function(String) durationLabel;

  String format(int scoreValue, ScoreFormat format) => switch (format) {
        ScoreFormat.points => formatPoints(scoreValue),
        ScoreFormat.duration => durationLabel(formatSeconds(_tenths(scoreValue) / 10)),
      };

  // Round half away from zero in integer arithmetic, BEFORE any formatter sees the
  // value, so the rounding boundary is identical in all four locales.
  static int _tenths(int milliseconds) => milliseconds.isNegative
      ? (milliseconds - 50) ~/ 100
      : (milliseconds + 50) ~/ 100;
}
```

`lib/core/score_formatter.dart` therefore has **no import directive at all** except
`lib/core/score_format.dart` — no `package:intl`, no `package:flutter`, nothing. That is the whole
reason for the closures: three function fields carry the locale's decisions without dragging
`NumberFormat` or `AppLocalizations` down a layer.

`lib/l10n/score_formatter_provider.dart`: `scoreFormatterProvider`, a `Provider<ScoreFormatter>` that
watches `localeNumbersProvider` and `appLocalizationsProvider` and wires
`formatPoints: numbers.score`, `formatSeconds: numbers.seconds` and
`durationLabel: l10n.durationSeconds`. **It constructs no `NumberFormat`** — every one of those already
exists inside the single `LocaleNumbers` instance. It is also **not a throwing seam and does not live
in `lib/core/`**, for two measured reasons: a value derivable from two providers does not earn the
override-me-or-crash idiom (`service-boundary-and-native` rule 2), and `check_import_boundaries.sh`
greps `package:flutter/`, which does **not** match `package:flutter_riverpod/` — so a Riverpod provider
parked in `lib/core/` would import Flutter transitively while the purity gate stayed green. Keeping the
provider in `lib/l10n/` makes that boundary hold by construction rather than by a gap in a regex.

**Files.** `lib/core/game_id.dart`, `lib/core/difficulty.dart`, `lib/core/run_scope.dart` (edit),
`lib/core/score_formatter.dart`, `lib/l10n/score_formatter_provider.dart`,
`test/core/game_id_test.dart`, `test/core/difficulty_test.dart`, `test/core/run_scope_test.dart`,
`test/core/score_formatter_test.dart`, `test/l10n/score_formatter_provider_test.dart`.

**Skills.** `i18n-rtl-l10n`, `value-objects-money-and-units`, `dart3-idioms-and-coding-standards`,
`naming-conventions`, `service-boundary-and-native`, `dartdoc-conventions`.

**Screenshot check.** n/a (no visual surface). The expected strings `1,480`, `1,240` and `18.6s` are
transcribed from `design/sunburst-pop/app.html`, which renders
`design/sunburst-pop/screens/02-game-detail.png` and `06-results.png`; the Persian counterparts are
targets for `design/sunburst-pop/screens/rtl/` from the same two figures. E08 compares the rendered
pixels against both sets.

**Done when.**
- [ ] `flutter test test/core/ test/l10n/` green, with the locale table producing 4 cases per row.
- [ ] `.claude/skills/project-structure-and-packages/scripts/check_import_boundaries.sh lib` green.
- [ ] `.claude/skills/i18n-rtl-l10n/scripts/check_i18n_bans.sh lib` green.
- [ ] `flutter analyze --fatal-infos --fatal-warnings` clean, which includes a `///` on every public
      member.
- [ ] `Difficulty` has no `runLimit`; `grep -rn 'enum ScoreFormat' lib/` returns exactly one line and
      it is in `lib/core/score_format.dart` (E02's file).
- [ ] `grep -rn 'NumberFormat' lib/ | grep -v 'lib/l10n/locale_numbers.dart'` is **empty** — this task
      added no construction site. E02 T02.11's `test/policy/canonical_storage_test.dart` and E04
      T04.6's `test/policy/locale_independence_test.dart` both pass unchanged.
- [ ] `RunScope.of` is the only conversion from `GameId`/`Difficulty` to persisted strings, and its
      output is ASCII under all four locales.
- [ ] The `ckb` digit-block assertion was seen **red** against a locally-hacked `LocaleNumbers` whose
      `_formattingLocale` returned `'ckb'` instead of `'fa'`, then green after reverting. Paste the red
      output in the PR body — this is the one measurement that proves the fallback is real. The hack
      lives in E04's file for the duration of the check and is reverted before the commit.

**Commits.**
1. `Add GameId and Difficulty tests`
2. `Add GameId and Difficulty value types with ARB label keys`
3. `Add RunScope.of as the one typed-id-to-scope conversion`
4. `Add score formatter tests across en, de, fa and ckb`
5. `Add ScoreFormatter over E02's ScoreFormat with injected per-locale closures`
6. `Wire scoreFormatterProvider to the active locale`

### T07.4 — The upward channel: BoardSnapshot, GameHud, RunOutcome, ResultStat, RunConfig

**Goal.** Everything a game hands back to the shell, and the only thing the shell hands down — with no
display string anywhere in it.

**Tests first (TDD).** `test/features/play/domain/board_snapshot_test.dart`:
- `a snapshot with no outcome is a live run` — `outcome == null`; the shell reads that as "keep going".
- `progress is null or within 0..1` — asserts on 0, 1, 0.5, and that -0.1 and 1.1 trip the assert.
- `GameHud holds exactly three slots` — the type makes a fourth unrepresentable; the test documents it.
- `HudSlot defaults to the neutral tone` — a game never sets `alarm`.
- `an HudSlot carries a label key and a canonical value, never a formatted string` — `labelKey`
  matches `^[a-z][a-zA-Z0-9_]*$`; `canonicalValue` is an `int`; there is no `String value` field.
- `value equality holds for identical snapshots` — required, because Riverpod diffs by value.

`test/features/play/domain/run_outcome_test.dart`:
- `a completed outcome carries a score and exactly three stats` — the results trio is a fixed
  3-column grid; fewer than three is a `GameDefinition` bug.
- `an abandoned outcome carries no score` — the type has no score field to read.
- `switching a RunOutcome is exhaustive without a wildcard`.

`test/features/play/domain/result_stat_test.dart`:
- `a result stat carries an ARB key and a canonical integer` — `labelKey` matches
  `^[a-z][a-zA-Z0-9_]*$` and is ASCII; `canonicalValue` is an `int`.
- `each StatFormat declares its canonical unit` — `points` → points, `duration` → milliseconds,
  `percent` → per-mille, `count` → items. Asserted as a table so the doc and the enum cannot drift.
- `StatFormat never reaches the database` — a policy grep: `StatFormat` appears in no file under
  `lib/data/`, and `RunDraft` has no field of that type. It is a presentation enum; `ScoreFormat` is
  the persisted one and the two must not merge.
- `a result stat holds no display string` — no field contains a space, a capital first letter, or a
  rune above `0x7F`.

`test/features/play/domain/run_config_test.dart`:
- `RunConfig is value-equal so it is a safe family key` — two configs with the same
  `(gameId, difficulty, seed)` are `==` with equal `hashCode`.
- `a different seed is a different config` — the reason "Play again" is a new notifier.
- `RunConfig carries no locale` — the field list is asserted; a locale on the family key would make a
  language switch mid-run a different run, which is exactly backwards.

**Implementation.** `lib/features/play/domain/board_snapshot.dart` holds the cohesive set
`BoardSnapshot`, `GameHud` and `HudSlot` — one file because they are one contract, close to how
`sunburst-shell-screens/references/shell-game-boundary.md` declares them. All `@immutable`, `const`
constructors, hand-rolled `==`/`hashCode`.

`HudSlot` is `(String labelKey, int canonicalValue, StatFormat format, HudTone tone)`. The reference
declares `(label, value, tone)` with display strings; this widens it, deliberately, for the reason in
Risk 6: a HUD slot built inside a board would otherwise need `AppLocalizations` in domain code, and a
slot holding `"۱۸٫۶ ثانیه"` goes stale the instant the player changes language in Settings. E08's
`HudPill` formats through `scoreFormatterProvider` at render.

**`HudTone` is imported, not declared.** E02 T02.2 put it in `lib/core/hud_tone.dart` because
`HudPill` (in `lib/ui/`) renders a tone and `HudSlot` (here, in `lib/features/`) carries one, and
`lib/ui/` may never import `lib/features/` under the downward-only DAG. Declaring it in this file too
would produce two enums with one name that never unify: a game sets `HudTone.highlight` from the
domain side, the pill switches on the UI side, and the code would not compile at the seam.
`lib/core/` is the only layer both can reach. Add the import and note it in this task's
`check_import_boundaries.sh` done-when.

`lib/features/play/domain/result_stat.dart`: `enum StatFormat { points, duration, percent, count }`
and `@immutable final class ResultStat({required String labelKey, required int canonicalValue, required StatFormat format})`.
The `///` states the unit per format, per `dartdoc-conventions` rule 5. `StatFormat` is separate from
E02's `ScoreFormat` on purpose: `ScoreFormat` is mirrored by the `runs.metric_kind` CHECK constraint,
so adding `percent` to it would be a schema change to serve a label.

`lib/features/play/domain/run_outcome.dart`: `sealed class RunOutcome` with
`final class RunCompleted` (`int scoreValue`, `List<ResultStat> stats`, `assert(stats.length == 3)`)
and `final class RunAbandoned`, plus
`const factory RunOutcome.completed({required int scoreValue, required List<ResultStat> stats})` and
`const factory RunOutcome.abandoned()` so the call sites in the skills' board examples compile with a
one-word rename.

`lib/features/play/domain/run_config.dart`: `RunConfig(gameId, difficulty, seed)` with value equality.

**Files.** `lib/features/play/domain/board_snapshot.dart`,
`lib/features/play/domain/run_outcome.dart`, `lib/features/play/domain/result_stat.dart`,
`lib/features/play/domain/run_config.dart`, and their four mirrored test files.

**Skills.** `sunburst-shell-screens`, `i18n-rtl-l10n`, `dart3-idioms-and-coding-standards`,
`value-objects-money-and-units`, `naming-conventions`, `dartdoc-conventions`.

**Screenshot check.** n/a (no visual surface). `HudTone`'s three tones and the results trio are
rendered in E08 against `04-stroop-rush.png`, `05-schulte-grid.png` and `06-results.png`, and against
their `screens/rtl/` counterparts.

**Done when.**
- [ ] `flutter test test/features/play/domain/` green.
- [ ] `.claude/skills/dart3-idioms-and-coding-standards/scripts/check-dart3-idioms.sh lib` reports no
      hard failure and no unjustified advisory.
- [ ] `.claude/skills/project-structure-and-packages/scripts/check_import_boundaries.sh lib` green with
      `board_snapshot.dart` importing `lib/core/hud_tone.dart`; `grep -rn 'enum HudTone' lib/` returns
      exactly one line, in `lib/core/`.
- [ ] No `Color`, no `Widget`, no `BuildContext`, no `Locale`, no `NumberFormat` and no
      `AppLocalizations` in any file under `lib/features/play/domain/`.
- [ ] Every string literal under `lib/features/play/domain/` matches `^[a-z][a-zA-Z0-9_]*$` after
      comments are stripped — ids and ARB keys pass, prose does not.

**Commits.**
1. `Add board snapshot and HUD contract tests`
2. `Add BoardSnapshot, GameHud and HudSlot over the shared HudTone`
3. `Add result stat tests`
4. `Add ResultStat and StatFormat as key plus canonical integer`
5. `Add run outcome and run config tests`
6. `Add sealed RunOutcome and RunConfig`

### T07.5 — GameDefinition, its localization keys, and the registry

**Goal.** The one file allowed to name every game, a registry whose invariants are tests rather than
review notes, and a definition that carries ARB keys instead of English.

**Tests first (TDD).** `test/games/game_definition_test.dart`:
- `a mechanic game must declare BoardBackground.surfaceSunk` — asserts the pairing
  `sunburst-game-surfaces` says "no switch can catch"; here the constructor assert catches it.
- `a decorative game must declare BoardBackground.gameAccent` — the other half.
- `a definition must offer at least one difficulty`.
- `a locked definition still declares an accent and an artwork` — the "Coming soon" slot shows
  neither, but unlocking it changes nothing else.
- `a timed game returns a run limit per difficulty and an untimed one returns null` —
  `runLimitFor(Difficulty.classic)` is a `Duration` for a definition with `isTimed: true` and `null`
  for one with `isTimed: false`, exhaustively over all three difficulties.
- `a definition carries ARB keys, never display strings` — `strings.titleKey`, `strings.taglineKey`
  and `strings.kickerKey` each match `^[a-z][a-zA-Z0-9_]*$` and are ASCII; the constructor asserts it.
- `a definition holds no localization machinery` — the field list contains no `Locale`, no
  `NumberFormat`, no `AppLocalizations` and no `String Function(...)` returning prose.

`test/games/game_registry_test.dart`:
- `the registry is the only file in lib/ that names a game` — the durable assertion. The
  **emptiness** of the list is asserted separately, in this epic's own fixture-registry override, so
  that E08 (placeholders), E09 (Stroop) and E10 (Schulte) each append without having to delete and
  re-explain a test whose name no longer describes what it checks.
- `game ids are unique across the registry` — driven with two fixture definitions.
- `gameDefinitionProvider resolves a registered id` — via `ProviderContainer.test`.
- `gameDefinitionProvider throws a StateError for an unknown id` — a bug, not a recoverable failure.
- `registry order is display order` — the list is returned unsorted and unfiltered.

`test/policy/registry_localization_test.dart` — the test the delta asks for by name:
- `no user-facing literal lives in the registry` — reads every `.dart` under `lib/games/`, strips
  comments first (`ci-pipeline-and-gates`, `references/policy-grep-gate.md`), and fails on any string
  literal that does not match `^[a-z][a-zA-Z0-9_]*$`. Snake-case ids and lowerCamelCase ARB keys pass;
  anything with a space, a capital first letter, punctuation or a non-ASCII rune is a display string
  and fails. Passes vacuously while the registry is empty, and is the tripwire for E08–E10.
- `every declared ARB key exists in all four locales` — for every key named by a `GameDefinition` or a
  `Difficulty`, assert the key is present in `lib/l10n/app_en.arb`, `app_de.arb`, `app_fa.arb` and
  `app_ckb.arb`. This is `check_arb_parity.sh`'s job for the ARB set as a whole; this test is the
  narrower claim that **the keys the engine names** are among them.
- `every declared ARB key has a generated getter` — reads `lib/l10n/app_localizations.dart` and
  asserts a getter of exactly that name exists. This is what closes the drift between a key held as a
  string and a getter called by E08; it only works because E04's keys are lowerCamelCase.

**Implementation.** `lib/games/game_definition.dart`:
`typedef GameBoardBuilder = Widget Function(BuildContext, RunConfig);`,
`enum BoardBackground { surfaceSunk, gameAccent }`,
`@immutable final class GameStringIds({required String titleKey, required String taglineKey, required String kickerKey})`,
and `@immutable final class GameDefinition` with `id`, `accent` (`GameAccent`, from
`lib/theme/game_accent.dart`), `colourRole` (`GameColourRole`), `scoreFormat` (E02's `ScoreFormat`),
`strings` (`GameStringIds`), `difficulties`, `boardBackground`, `isTimed` (default `true`), `isLocked`
(default `false`), **`Duration? Function(Difficulty)? runLimitFor`** (default `null` for every
difficulty), `buildBoard`, `buildArtwork`, and
`ProviderListenable<BoardSnapshot> Function(RunConfig) snapshotOf`. Constructor asserts encode the
role/background pairing, `difficulties.isNotEmpty`, that `isTimed == false` implies `runLimitFor`
returns `null` everywhere, and that all three keys are ASCII lowerCamelCase.

**Why keys and not a resolver function.** gen-l10n has no dynamic key lookup, so a key string cannot
be turned into a getter at runtime; resolution goes through E08's `lib/l10n/game_strings.dart`, which
maps each `GameId` to typed `AppLocalizations` getters. The key field is therefore not the resolution
path — it is the **checkable declaration** of what a definition promises to have translated, and
`registry_localization_test.dart` is what makes it earn its place. The alternative,
`String Function(AppLocalizations)` on the definition, was considered and rejected in E08 Risk 3; if a
reviewer prefers it, that is a `sunburst-shell-screens` change to raise before E08 T08.5, not a
change to make here.

**Run length lives on the game, not on `Difficulty`.** Stroop Rush is a fixed round count and ends via
`BoardSnapshot.outcome`; Schulte Grid is a race scored by elapsed time and any shell-imposed limit
would cut the player off mid-board. A `runLimit` on the `Difficulty` enum would force one answer on
both. With `runLimitFor` nullable per definition, a game declares a limit or does not, and
T07.6/T07.8's "end when `remaining` hits zero" applies only when one exists.

`lib/games/game_registry.dart`: `gameRegistryProvider` (`Provider<List<GameDefinition>>` returning an
empty const list) and `gameDefinitionProvider` (`Provider.family<GameDefinition, GameId>`). The file
header states: **"this is the only file in `lib/` that may enumerate the game registry."**
Deliberately not "the only file that may name a game" — E08 T08.1 adds `lib/l10n/game_strings.dart`,
which maps every `GameId` to its ARB-resolved title, and that header would become false the moment E08
merges. E08 states the two-file rule in one place; this header stays true forever.

`colourRole` and `strings` together widen the `GameDefinition` in `sunburst-shell-screens` by two
fields. Both are licensed by that skill's own instruction to widen the seam rather than special-case a
screen: `colourRole` converts the `mechanic ⇒ surfaceSunk` rule from a review-only check into a
constructor assert plus a test, and `strings` converts "the shell will look up the right ARB key" from
a convention into a field a test can read.

**Files.** `lib/games/game_definition.dart`, `lib/games/game_registry.dart`,
`test/games/game_definition_test.dart`, `test/games/game_registry_test.dart`,
`test/policy/registry_localization_test.dart`,
`test/support/fixture_game.dart` (first version — a minimal definition used by these tests).

**Skills.** `sunburst-shell-screens`, `sunburst-game-surfaces`, `i18n-rtl-l10n`,
`state-management-riverpod`, `flutter-architecture`, `dartdoc-conventions`.

**Screenshot check.** n/a (no visual surface).

**Done when.**
- [ ] `flutter test test/games/ test/policy/registry_localization_test.dart` green.
- [ ] `.claude/skills/sunburst-shell-screens/scripts/check_shell_boundaries.sh lib` green.
- [ ] `.claude/skills/state-management-riverpod/scripts/ban-legacy-providers.sh lib` green.
- [ ] `.claude/skills/i18n-rtl-l10n/scripts/check_arb_parity.sh lib/l10n` green — it now **runs**, with
      four locales present. If `tool/skill_gates.sh` still lists it in the skip table, move it to the
      run table in this commit and say so in the PR body.
- [ ] `grep -rn "switch (gameId)\|switch (config.gameId)" lib/` returns nothing.
- [ ] The literal test was seen red: add `title: 'Stroop Rush'` to the fixture definition, watch it
      fail, remove it.

**Commits.**
1. `Add game definition invariant tests`
2. `Add GameDefinition, GameStringIds and BoardBackground`
3. `Add the registry localization policy test`
4. `Add game registry tests`
5. `Add the empty game registry and its providers`

### T07.6 — The RunPhase machine as a pure, exhaustive table

**Goal.** Phase legality as a total pure function, so the machine is decided before any notifier
exists — and a `RunState` that carries no locale.

**Tests first (TDD).** `test/features/play/domain/run_phase_test.dart`:
- `the transition table is exhaustive` — a nested loop over `RunPhase.values × RunPhase.values`
  asserting all 25 cells against a table literal written in the test, with the pair echoed in
  `reason:`. Legal: `idle→countdown`, `countdown→playing`, `countdown→idle`, `playing→paused`,
  `playing→over`, `paused→countdown`, `paused→over`. The other 18, including all five
  self-transitions, are illegal.
- `over is terminal` — every `RunPhase.over → x` cell is false.
- `no phase transitions to itself`.

`test/features/play/domain/run_state_test.dart`:
- `a legal transition returns a new state with the new phase` — and the old instance is unchanged.
- `an illegal transition trips an assert in debug` — `expect(() => …, throwsA(isA<AssertionError>()))`.
- `remaining is null for an untimed run` — `runLimit == null`, which is what
  `definition.runLimitFor(config.difficulty)` returns for a game that declares no limit.
- `remaining never goes below zero` — clamped at the limit.
- `isTimerAlarm is true only at or below five seconds remaining` — boundary rows at 5001 ms, 5000 ms,
  0 ms.
- `RunState is value-equal` — two identical states are `==`, because Riverpod listeners diff by value.
- **`RunState carries no formatted string`** — reads `lib/features/play/domain/run_state.dart` and
  fails on any `final String` field declaration. The state holds `scoreValue` (an `int`), never a
  rendered `"1,480"` or `"۱٬۴۸۰"`. Two reasons: a formatted field goes stale the moment the player
  changes language mid-run, and it drags a locale into a value type that is a Riverpod family key's
  payload.

**Implementation.** `lib/features/play/domain/run_phase.dart`:
`enum RunPhase { idle, countdown, playing, paused, over }` with `bool canTransitionTo(RunPhase next)`
implemented as one exhaustive `switch` with no `default:`.

`lib/features/play/domain/run_state.dart`: `@immutable final class RunState` storing `config`,
`phase`, `elapsed`, `runLimit` (`Duration?`), `snapshot`, `scoreValue` (`int`), `isPersonalBest`,
`saveFailure`, `hasFiredTimerAlarm`; deriving `hud`, `progress`, `outcome`, `remaining` and
`isTimerAlarm` as getters (derive, don't store); `RunState.idle(config, runLimit)`, `copyWith`,
`transitionTo(RunPhase)` guarded by `assert(phase.canTransitionTo(next))`, and the named edges
`toOver(outcome, {isPersonalBest, saveFailure})`. Hand-rolled `==`/`hashCode`; no `freezed`, so this
epic adds no codegen step.

**`scoreLabel` is gone.** The pre-localization field list carried a `String scoreLabel` formatted by
the notifier. It is replaced by `int scoreValue`; E08 formats through `scoreFormatterProvider` at
render, which is also where the countdown's `3-2-1` and the HUD's clock localise. This is a deliberate
deviation, recorded in Risk 7.

**Files.** `lib/features/play/domain/run_phase.dart`, `lib/features/play/domain/run_state.dart`,
`test/features/play/domain/run_phase_test.dart`, `test/features/play/domain/run_state_test.dart`.

**Skills.** `sunburst-shell-screens` (`references/run-lifecycle.md`),
`dart3-idioms-and-coding-standards`, `state-management-riverpod`, `testing-strategy`,
`dartdoc-conventions`.

**Screenshot check.** n/a (no visual surface).

**Done when.**
- [ ] `flutter test test/features/play/domain/run_phase_test.dart test/features/play/domain/run_state_test.dart` green.
- [ ] The table test names all 25 cells; deleting one legal edge from the implementation fails it.
- [ ] No `default:` or `case _:` in either file.
- [ ] `grep -n 'final String' lib/features/play/domain/run_state.dart` returns nothing.

**Commits.**
1. `Add the exhaustive RunPhase transition table test`
2. `Add RunPhase and its legality table`
3. `Add RunState transition tests`
4. `Add immutable RunState with derived remaining and alarm and no formatted score`

### T07.7 — RunTicker over the injected Clock

**Goal.** The engine's one clock, at 10 Hz, pausable, and driven in tests by fake time so nothing
sleeps.

**Tests first (TDD).** `test/features/play/application/run_ticker_test.dart`, all inside
`fakeAsync((async) { … })` with `withClock(async.getClock(DateTime.utc(2026, 1, 1)), …)`:
- `elapsed advances with the clock while running` — elapse 2500 ms, expect 2500 ms.
- `the ticker fires at 10 Hz` — elapse 1000 ms, expect 10 callbacks.
- `stop freezes elapsed` — stop, elapse 5000 ms, elapsed unchanged.
- `resuming after a stop does not credit the paused interval` — run 1000, stop, elapse 5000, start,
  run 1000, expect 2000 ms total. This is the whole reason the shell owns the clock.
- `dispose cancels the timer` — elapse 5000 ms after dispose, expect zero further callbacks.
- `a 60 second run completes in fake time` — the suite never sleeps; the test asserts wall time is
  irrelevant by running entirely inside `fakeAsync`.
- `elapsed is derived from the clock, not from tick count` — drop ticks by elapsing 1000 ms in one
  jump and assert elapsed is still 1000 ms, so a janked frame cannot lose time.
- `elapsed is a Duration, never a rendered clock string` — the public surface exposes
  `Duration get elapsed` and nothing else; the `0:23` in `04-stroop-rush.png` is E08's rendering of
  it, and in `fa` it is `۰:۲۳`.

**Implementation.** `lib/features/play/application/run_ticker.dart`: `final class RunTicker`
constructed with a `Clock` and a `void Function() onTick`; `start()`, `stop()`, `Duration get elapsed`,
`dispose()`. Internally one `Timer.periodic(const Duration(milliseconds: 100))` for the pulse and
`clock.now()` for the truth — the tick is a repaint cue, the clock is the measurement. Accumulates
elapsed across stop/start segments. The 10 Hz cadence is `sunburst-motion-and-haptics` rule 6's stated
run-timer rate, cited in a comment.

**Files.** `lib/features/play/application/run_ticker.dart`,
`test/features/play/application/run_ticker_test.dart`.

**Skills.** `service-boundary-and-native`, `testing-strategy`, `async-safety`,
`sunburst-motion-and-haptics` (the 10 Hz rate and the latched-boundary rule only — no haptic is fired
here).

**Screenshot check.** n/a (no visual surface).

**Done when.**
- [ ] `flutter test test/features/play/application/run_ticker_test.dart` green in under a second.
- [ ] `grep -rn "Future.delayed\|sleep(" test/` returns nothing.
- [ ] `.claude/skills/service-boundary-and-native/scripts/check-service-boundaries.sh lib` green.
- [ ] `.claude/skills/testing-strategy/scripts/check_test_hygiene.sh lib test` green.
- [ ] `grep -n "String" lib/features/play/application/run_ticker.dart` returns nothing.

**Commits.**
1. `Add run ticker tests driven by fake async`
2. `Add RunTicker over the injected clock`

### T07.8 — RunNotifier: the machine, the lifecycle and persist-then-transition

**Goal.** One owner for every phase change, one write path, a resume that never steals the player's
pause, and a persisted draft that is the same bytes in every language.

**Tests first (TDD).** `test/features/play/application/run_notifier_test.dart`, all headless via
`ProviderContainer.test` with `clockProvider` frozen, a bare-`implements` `FakeRunRepository` and the
fixture game registered:
- `start moves idle to countdown` and `the countdown ends into playing after three ticks`.
- `abandon during countdown returns to idle and writes nothing` — the fake repository records zero
  calls.
- `pause moves playing to paused and stops the clock`.
- `keepPlaying moves paused back to countdown, not straight to playing`.
- `leaveRun moves paused to over with an abandoned outcome and writes nothing`.
- `a board outcome moves playing to over` — the fake snapshot sets `outcome`.
- `a timed run ends when remaining hits zero` — `fakeAsync`, elapse the limit the *definition* returns
  from `runLimitFor(config.difficulty)`.
- `an untimed run never ends on the clock` — a definition whose `runLimitFor` returns `null`; elapse 10
  minutes, still `playing`.
- **`the run is persisted before the phase becomes over`** — the fake repository records the phase
  observed at the moment `saveRun` is called; asserts it is `playing`.
- `a successful save carries the committed personal-best flag` — `Ok(RunCommit(record, isPersonalBest: true))`
  in, `isPersonalBest == true` out. The flag comes from the committed row (E02 computes it inside the
  same transaction as the insert), never from a post-commit read of `watchPersonalBest`, which would
  race the notifier's own write.
- `a failed save still reaches over, carrying the failure and no personal best` — `Err(DataFailure)`
  in, `saveFailure != null` and `isPersonalBest == false` out.
- `backgrounding pauses a live run` — push `AppLifecycleState.inactive`, then `.paused`, then
  `.hidden`; each pauses from `playing`.
- **`resuming never un-pauses`** — push `.paused` then `.resumed`; the phase stays `paused`.
- `detached writes nothing`.
- `over is terminal` — call `start`, `pause`, `keepPlaying`, `leaveRun` and `abandon` from `over` and
  assert the phase never changes and no assert-legal edge exists.
- `the timer alarm latch flips exactly once` — a 60 s run ticked at 10 Hz through the last 5 seconds
  sets `hasFiredTimerAlarm` once, not fifty times.
- `the ticker and the lifecycle observer are released on dispose`.
- **`the notifier never formats a value`** — `scoreFormatterProvider` is not read anywhere in
  `run_notifier.dart`; asserted by a grep in this test file. Formatting is E08's, at render.
- **`changing the locale mid-run changes nothing in RunState`** — start a run under `en`, override the
  locale provider with `fa` while `playing`, assert the `RunState` instance is `==` to the one before
  the switch. Only the rendered string differs, and nothing rendered lives in the state.

**Implementation.** `lib/features/play/application/run_notifier.dart`:
`final class RunNotifier extends FamilyNotifier<RunState, RunConfig>` plus
`runNotifierProvider = NotifierProvider.family<RunNotifier, RunState, RunConfig>(RunNotifier.new)`.
`build(config)` watches `gameDefinitionProvider(config.gameId)`, listens to
`definition.snapshotOf(config)`, constructs the `RunTicker` from `clockProvider`, registers a
run-scoped `WidgetsBindingObserver`, and releases both in `ref.onDispose`. Intent methods return
`void`: `start()`, `abandon()`, `pause()`, `keepPlaying()`, `leaveRun()`.

`_finish(outcome)` is the one `unawaited(...)` in the engine — it stops the ticker, builds a
**`RunDraft`** (E02's `lib/core/run_draft.dart`: scope strings via `RunScope.of`, `clientRunKey`,
`playedOnDay`, `durationMs: _ticker.elapsed.inMilliseconds`, `format`, `value` and the counters),
awaits `ref.read(runRepositoryProvider).saveRun(draft)` — E02's single write path, returning
`Result<RunCommit, DataFailure>` — guards `ref.mounted`, then switches the `Result` exhaustively into
`toOver(outcome, isPersonalBest: commit.isPersonalBest)` on `Ok` and
`toOver(outcome, saveFailure: failure)` on `Err`. The method name and the payload are E02's contract,
not this epic's to rename. Every phase assignment goes through `RunState.transitionTo`.

**The draft is canonical, not rendered.** `playedOnDay` is a Gregorian civil date from E02's
`CalendarDay` over the injected `Clock` — never a Jalali or Hijri projection, per `i18n-rtl-l10n`
rule 6 and `seeded-determinism-and-golden-vectors` rule 2. `durationMs` is whole milliseconds.
`value` is an integer. `clientRunKey` is ASCII. Nothing in the draft reads a locale, and T07.10 proves
it. Restate that as a `//` above the draft construction — it is the line that a "show Persian dates in
the export" request would break.

**Files.** `lib/features/play/application/run_notifier.dart`,
`test/features/play/application/run_notifier_test.dart`, `test/support/fake_run_repository.dart`,
`test/support/fake_board_snapshot_source.dart`.

**Skills.** `sunburst-shell-screens` (`references/run-lifecycle.md`), `state-management-riverpod`,
`error-handling-typed-results`, `async-safety`, `testing-strategy`, `service-boundary-and-native`,
`i18n-rtl-l10n`.

**Screenshot check.** n/a (no visual surface). The pause sheet has no reference PNG in either
direction and is not built here; E08 owns it.

**Done when.**
- [ ] `flutter test test/features/play/` green.
- [ ] `.claude/skills/state-management-riverpod/scripts/ban-legacy-providers.sh lib` green.
- [ ] `.claude/skills/error-handling-typed-results/scripts/check-swallowed-catch.sh lib` green.
- [ ] `.claude/skills/flutter-architecture/scripts/check_architecture.sh lib` green.
- [ ] `grep -rn "state.phase =\|phase:" lib/ --include=*.dart | grep -v run_notifier | grep -v run_state`
      shows no other writer of a phase.
- [ ] `grep -rn "scoreFormatterProvider\|NumberFormat\|AppLocalizations" lib/features/play/application/run_notifier.dart`
      returns nothing.

**Commits.**
1. `Add fake run repository and fake snapshot source`
2. `Add run notifier lifecycle tests`
3. `Add RunNotifier and the run phase transitions`
4. `Add persist-then-transition tests`
5. `Persist a finished run before entering the over phase`
6. `Add background and resume lifecycle tests`
7. `Pause on background and never un-pause on resume`

### T07.9 — Prove the seam: a fixture game that touches no shell file

**Goal.** Demonstrate, in the test suite, that a game the engine has never seen plays end to end and
contributes zero lines to `lib/features/**`.

**Tests first (TDD).** `test/engine/engine_seam_test.dart`:
- `a registered fixture game plays a full run` — override `gameRegistryProvider` with
  `[fixtureGameDefinition]`, `start()`, run the countdown, push three snapshots, set an outcome, and
  assert `RunState` ends `over` with the fixture's score, HUD values and progress read back
  unmodified.
- `the shell never learns which game is running` — the run is driven entirely through
  `gameDefinitionProvider`; the test asserts `fixtureGameDefinition` is reachable only via the
  registry override.
- `the fixture game names no shell type` — asserts `test/support/fixture_game.dart` imports nothing
  under `features/`.
- `the fixture game's HUD slots carry keys, not words` — the fixture declares
  `hudSlotTime` / `hudSlotScore` / `hudSlotStreak` as ARB keys, and the test asserts the values that
  come back through `RunState.hud` are integers plus keys.

`test/policy/shell_boundary_test.dart`:
- `no file under lib/features imports a specific game` — reads every `.dart` under `lib/features/`
  and fails on `import '…games/<segment>/…'`, mirroring `check_shell_boundaries.sh` at the Dart tier
  so it runs in `flutter test` too. Passes vacuously while `lib/features/` is thin, and stays as the
  tripwire for E08–E10.
- `no file under lib/games builds shell chrome` — the same grep set as the shell script
  (`go_router`, `Navigator.`, `Scaffold(`, `AppBar(`, `SafeArea(`, `HudPill`, `Stopwatch(`,
  `Timer.periodic(`, `runNotifierProvider`).
- `lib/games/game_registry.dart is the only file in lib/ that names a game directory`.

**Implementation.** `test/support/fixture_game.dart`: `fixtureGameDefinition` — a `GameDefinition`
with `GameAccent.schulteTurquoise`, `GameColourRole.decorative`, `BoardBackground.gameAccent`,
`ScoreFormat.points`, all three difficulties, `GameStringIds` pointing at three fixture ARB keys, a
board builder returning a `SizedBox.shrink()`, and a `snapshotOf` pointing at a controllable test
notifier. It lives under `test/` and is referenced from nowhere in `lib/`. Its keys are declared in
the test file, not appended to `lib/l10n/app_en.arb` — a fixture must not add a key four translators
would then be asked to translate; `registry_localization_test.dart` reads `lib/games/`, not `test/`.

`test/policy/shell_boundary_test.dart` uses `dart:io` file reads — legal in a policy test, which is
the sanctioned home for cross-cutting assertions that belong to no single file.

Wire the two engine-relevant gate scripts into `.github/workflows/ci.yml` (created by E01) if they are
not already there: `check_shell_boundaries.sh lib` and `check-determinism-bans.sh lib/core`.

**Files.** `test/support/fixture_game.dart` (extended), `test/engine/engine_seam_test.dart`,
`test/policy/shell_boundary_test.dart`, `.github/workflows/ci.yml` (two gate steps).

**Skills.** `sunburst-shell-screens`, `testing-strategy`, `ci-pipeline-and-gates`,
`project-structure-and-packages`.

**Screenshot check.** n/a (no visual surface).

**Done when.**
- [ ] `flutter test` green, whole suite.
- [ ] `git grep -n "fixtureGameDefinition" lib/` returns nothing.
- [ ] `.claude/skills/sunburst-shell-screens/scripts/check_shell_boundaries.sh lib` green, and the
      same rule is asserted from `flutter test`.
- [ ] The CI workflow runs both gate scripts and fails the job on a non-zero exit.

**Commits.**
1. `Add the fixture game and the engine seam test`
2. `Add the shell boundary policy test`
3. `Run the shell boundary and determinism gates in CI`

### T07.10 — Prove locale independence: the four-locale matrix

**Goal.** Make "the engine does not depend on the language" a test rather than an intention. This is
the task that stops a future refactor from seeding a round off a formatted string, storing a Jalali
date, or persisting `۱٬۴۸۰` into a column that a personal-best query compares with `MAX()`.

**Tests first (TDD).** `test/engine/locale_independence_test.dart` — one helper,
`Future<void> underEachLocale(Future<void> Function(String tag) body)`, iterating
`['en', 'de', 'fa', 'ckb']` inside `Intl.withLocale(tag, ...)` with `Intl.defaultLocale` also set and
restored in a `tearDown`:
- `the golden vector table reproduces under en, de, fa and ckb` — the whole of
  `test/core/seed_vectors.dart`, re-asserted per locale, byte-identical. **This is the test the delta
  exists for.** If it ever goes red, a formatter has reached the generation path.
- `a full fixture run produces the same RunDraft under all four locales` — drive
  `RunNotifier` to completion four times with the same `RunConfig` and the same frozen `Clock`, and
  assert the four captured `RunDraft`s are `==`. Covers `gameId`, `difficultyId`, `clientRunKey`,
  `playedOnDay`, `durationMs`, `format` and `value` in one assertion.
- `RunScope strings are ASCII under every locale` — every rune below `0x80`, no U+06Fx digit, no
  U+2066–U+2069 isolate.
- `playedOnDay is a Gregorian civil date under fa and ckb` — the day for `2026-03-21T00:00:00Z` is
  `2026-03-21`, not `1405-01-01`. Calendar projection is a render-time concern and must not reach the
  database (`i18n-rtl-l10n` rule 6).
- `elapsed and score are integers under every locale` — no `String` crosses the notifier boundary.

`test/policy/engine_locale_purity_test.dart`:
- `nothing on the generation path imports intl or AppLocalizations` — reads
  `lib/core/seeded_generator.dart`, `lib/features/play/application/seeded_random_provider.dart` and
  every file under `lib/features/play/domain/`, and fails on `package:intl`, `app_localizations`,
  `LocaleNumbers`, `Intl.` or `NumberFormat`. Meets the three-criteria bar in
  `ci-pipeline-and-gates` `references/policy-grep-gate.md`: textually decidable, silent when broken,
  one line to break.
- `check_arb_parity.sh is in the run table, not the skip table` — reads `tool/skill_gates.sh` and
  fails if `check_arb_parity.sh` still carries E01 T01.9's measured one-locale skip reason. With four
  locales shipped by E04, that reason is stale, and a stale skip row is a gate that silently checks
  nothing.

**Implementation.** No production code. Two test files, one CI step, one edit to
`tool/skill_gates.sh` if E04 has not already moved `check_arb_parity.sh` across.

`.github/workflows/ci.yml` (edit): add a step running
`flutter test test/engine/locale_independence_test.dart test/policy/engine_locale_purity_test.dart`
with a comment naming the contract it blocks on — *seeded generation and persisted values are
locale-independent; localisation happens at render*. It is a separate named step rather than being
folded into the whole-suite run so a failure names itself in the job log
(`ci-pipeline-and-gates` rule 1).

**Honest limit, stated in the test file header.** These tests exercise `intl` formatting and ARB key
presence. They do **not** pump a `MaterialApp`, so they prove nothing about
`GlobalMaterialLocalizations` accepting `ckb` — that is E04's custom `LocalizationsDelegate` and E04's
test that switching to `ckb` does not throw. A green E07 is not evidence that the app can switch to
Kurdish Sorani.

**Files.** `test/engine/locale_independence_test.dart`,
`test/policy/engine_locale_purity_test.dart`, `.github/workflows/ci.yml` (one step),
`tool/skill_gates.sh` (only if the parity row is still skipped).

**Skills.** `i18n-rtl-l10n`, `seeded-determinism-and-golden-vectors`, `testing-strategy`,
`ci-pipeline-and-gates`.

**Screenshot check.** n/a (no visual surface).

**Done when.**
- [ ] `flutter test test/engine/ test/policy/` green.
- [ ] The vector test was seen red under a deliberate break: temporarily seed from
      `LocaleNumbers.forLocale(const Locale('fa')).score(1480)` instead of an ASCII key, watch `fa` and `ckb`
      diverge from `en`, revert. Paste the red output in the PR body.
- [ ] `bash tool/skill_gates.sh` exits 0 with `check_arb_parity.sh` in the run table.
- [ ] CI runs the locale matrix as its own named step.

**Commits.**
1. `Add the four-locale engine independence matrix`
2. `Add the engine locale purity policy test`
3. `Run the locale matrix as a named CI gate`

## Gates that must pass

Run from the repo root, in this order, before every commit and again before the PR:

```bash
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs   # ALWAYS before analyze
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos --fatal-warnings
flutter test --test-randomize-ordering-seed random
```

Skill gates relevant to this epic, spot-checked individually with the argument each one takes:

```bash
.claude/skills/project-structure-and-packages/scripts/check_structure.sh              lib
.claude/skills/project-structure-and-packages/scripts/check_import_boundaries.sh      lib
.claude/skills/flutter-architecture/scripts/check_architecture.sh                     lib
.claude/skills/state-management-riverpod/scripts/ban-legacy-providers.sh              lib
.claude/skills/service-boundary-and-native/scripts/check-service-boundaries.sh        lib
.claude/skills/error-handling-typed-results/scripts/check-swallowed-catch.sh          lib
.claude/skills/dart3-idioms-and-coding-standards/scripts/check-dart3-idioms.sh        lib
.claude/skills/seeded-determinism-and-golden-vectors/scripts/check-determinism-bans.sh lib/core
.claude/skills/sunburst-shell-screens/scripts/check_shell_boundaries.sh               lib
.claude/skills/sunburst-tokens/scripts/check_raw_values.sh                            lib
.claude/skills/testing-strategy/scripts/check_test_hygiene.sh                         lib test
.claude/skills/i18n-rtl-l10n/scripts/check_i18n_bans.sh                               lib
.claude/skills/i18n-rtl-l10n/scripts/check_arb_parity.sh                              lib/l10n
```

Two policy tests written by earlier epics are also named here, because **this task is the one most
likely to break them**: `test/policy/canonical_storage_test.dart` (E02 T02.11 — nothing under
`lib/data/` or `lib/core/` contains `package:intl`, `NumberFormat`, `DateFormat`, `toStringAsFixed` or
`Intl.`) and `test/policy/locale_independence_test.dart` (E04 T04.6 — `lib/l10n/locale_numbers.dart` is
the only `NumberFormat` construction site in `lib/`). Run both by name after T07.3:

```bash
flutter test test/policy/canonical_storage_test.dart test/policy/locale_independence_test.dart
```

`check_arb_parity.sh` is the one that changed status. E01 T01.9 measured it exiting 2 with
`FAIL: no locale ARB files (app_*.arb) beside the template` at one locale and parked it in
`tool/skill_gates.sh`'s skip table with that reason. E04 ships `app_de.arb`, `app_fa.arb` and
`app_ckb.arb`, so the reason is dead and the row belongs in the run table. T07.10 fails if it is
still skipped.

`check_i18n_bans.sh` runs green here for a slightly hollow reason worth stating: it scans for physical
geometry, non-adaptive icons, number splices, legacy bidi embeddings and `google_fonts`, and this epic
renders nothing. Its number-splice rule (`+ n.toString()`) is the only clause with real bite over
engine code. Treat a green result as "no regression", not as evidence the engine is localised — that
evidence is T07.3 and T07.10.

Then the whole set, through the one runner E01 T01.11 built:

```bash
bash tool/skill_gates.sh
```

**Not** `for s in .claude/skills/*/scripts/*.sh; do bash "$s"; done`. That loop cannot exit 0:
measured, 29 of the 49 scripts fail argument-less, five take a required argument and can never pass
that way, and `check-scheduler-purity.sh` exits 127 on macOS bash 3.2. The runner's explicit run and
skip tables are what make the sweep a gate rather than noise, and
`test/policy/skill_gates_coverage_test.dart` fails if a script is missing from both.

## Risks and open questions

1. **`Result`/`Failure` is E02's, decided.** E02 T02.2 creates `lib/core/result.dart` and
   `lib/core/failure.dart` outright — it is the first consumer and it merges first. T07.1 adopts them
   and adds `RunFailure` only. Two hedged "whichever lands first" clauses are not an owner; this is.
   `RunState.saveFailure` is `DataFailure`, E02's family, the one `RunRepository.saveRun` returns. Do
   not mirror persistence variants into `RunFailure`, or the results screen has two ways to say the
   same thing.
2. **`ckb` has no `intl` number symbols, and the fallback is silent.** `i18n-rtl-l10n`'s
   `references/numerals-and-calendars.md` states it and the fix: pin `ckb` to `fa`, which shares the
   Extended Arabic-Indic block and both separators. **Verify it at build time, do not assume it** —
   T07.3's done-when requires seeing the digit-block assertion fail against a `LocaleNumbers` whose
   `_formattingLocale` is temporarily hacked to return `'ckb'`, before it passes against the `fa` pin,
   with the red output in the PR. If a future `intl` ships real `ckb` symbols with different separators, that assertion fails
   loudly, which is the intended behaviour: someone must then decide whether the new separators are
   what Sorani readers expect. **Open, needs a native speaker.**
3. **The Sorani and Persian wording is machine-quality until reviewed.** The seconds unit, the three
   difficulty labels and the stat labels are ARB values, and neither this epic nor its author can
   vouch for them. The tests are written to assert *composition and digit block*, never the words, so
   a native reviewer's fix is a one-line ARB edit that breaks no engine test. **Do not present the
   translations as done.** E11 owns the sign-off; the reviewer has not been engaged.
4. **The `ckb` Material/Cupertino delegate gap is E04's, and E07 cannot mask it.** `ckb` is very
   likely absent from `GlobalMaterialLocalizations.delegate`'s supported list, and a missing delegate
   throws at runtime on locale switch. E04 owns the custom `LocalizationsDelegate` that serves our ARB
   strings for `ckb` while delegating Material/Cupertino strings to the nearest script neighbour
   (`fa`, else `ar`), and owns the test that switching does not throw. Every test in E07 is headless,
   so **a green E07 says nothing about whether the app can switch to Kurdish Sorani.** T07.10's file
   header states that in the source.
5. **Run length is per game, not per difficulty.** `GameDefinition.runLimitFor(Difficulty)` is
   nullable and defaults to `null`. Stroop Rush declares 90 / 60 / 30 seconds (**DERIVED** — neither
   `system.html` nor `app.html` states a run length) *or* declares none and ends on round count; E09
   Risk 2 decides which, and this epic's field shape supports either. Schulte Grid declares none.
   Confirm the Stroop numbers with the product owner (Zakaria) before E09 ships; changing them later
   invalidates every stored personal best, which the offline app cannot recompute.
6. **Three deliberate widenings of the `sunburst-shell-screens` seam.** `colourRole` makes the
   `mechanic ⇒ surfaceSunk` pairing a constructor assert instead of a review note. `strings`
   (`GameStringIds`) replaces the reference's implicit "the shell looks up the right key" with a field
   a test can read. `HudSlot` carries `(labelKey, canonicalValue, StatFormat, tone)` where the
   reference declares `(label, value, tone)` as display strings — because a board cannot reach
   `AppLocalizations` from domain code, and a slot holding `"۱۸٫۶ ثانیه"` is stale the moment the
   player changes language. All three are licensed by that skill's own instruction to widen the seam
   rather than special-case a screen. If the skill is later updated, these fields are the reason.
7. **`RunState.scoreLabel` is removed, and that is a deviation.** The pre-localization field list
   stored a formatted score on the state. Under four locales that field is a bug with two heads: it
   goes stale on a mid-run language change, and it bakes a locale into a value type that is a family
   key's payload. Replaced by `int scoreValue`, formatted by E08 at render through
   `scoreFormatterProvider`. If a reviewer wants the label back, they are asking for a locale on
   `RunState`, and that has to be argued, not assumed.
8. **`ResultStat` becoming `(labelKey, canonicalValue, StatFormat)` introduces a second format enum.**
   `StatFormat` sits beside E02's `ScoreFormat` and they are not the same thing: `ScoreFormat` is
   mirrored by the `runs.metric_kind` CHECK and adding `percent` to it would be a schema change made
   to serve a label. `StatFormat` never persists, and T07.4's policy test asserts it appears nowhere
   under `lib/data/`. The residual cost is two enums a reader must distinguish; the doc on each names
   the other.
9. **The key-to-getter tie is a string convention, backed by one test.** `GameDefinition.strings`
   holds key names; resolution goes through typed `AppLocalizations` getters in E08's
   `lib/l10n/game_strings.dart`, because gen-l10n has no dynamic lookup. Those two could drift.
   T07.5's `every declared ARB key has a generated getter` test closes it by reading the generated
   class — and that only works if E04's ARB keys are lowerCamelCase. **That is a contract on E04**,
   stated in *Current state*; snake_case keys would generate snake_case getters, break
   `naming-conventions` rule 2, and make the check impossible.
10. **`scoreFormatterProvider` moved out of `lib/core/`, for a measured reason.** The pre-localization
    plan put it beside `ScoreFormatter` in `lib/core/score_formatter.dart`.
    `check_import_boundaries.sh` greps `package:flutter/`, which does not match
    `package:flutter_riverpod/` — so a Riverpod provider in `lib/core/` imports Flutter transitively
    while the purity gate stays green. The provider now lives in `lib/l10n/score_formatter_provider.dart`
    and the pure formatter stays in `lib/core/`. The gate's regex is still a hole; this epic routes
    around it rather than widening the gate, because a wider regex would also flag
    `flutter_test`-importing files that legitimately live elsewhere. Worth raising with
    `project-structure-and-packages` separately.
11. **`RunState` is a phase enum plus nine fields, not a sealed union.** A sealed `RunIdle`/`RunOver`
    would make phase-specific fields unrepresentable, but every example in `sunburst-shell-screens`
    switches on `state.phase`. Decision: keep the enum, guard with constructor asserts, and revisit
    only if E08 finds itself null-checking phase-specific fields.
12. **`isTimed` is a second knob next to `scoreFormat`.** They are correlated in practice
    (`points` ⇒ timed, `duration` ⇒ race) but not identical, and deriving one from the other would
    silently constrain the third game. Decision: keep both explicit, plus `runLimitFor` as the third —
    `isTimed` says whether the shell shows a clock, `runLimitFor` says whether it ends the run, and
    Stroop Rush is the case that shows a TIME pill (`04-stroop-rush.png`, `0:23`; `۰:۲۳` in `fa`)
    while ending on round count. Add a registry test in E10 if a real divergence never appears.
13. **Text expansion is untested here, by construction.** German is ~30% longer and Persian and Sorani
    have taller line boxes; "Klassisch" and the Sorani difficulty labels have to fit a chip this epic
    does not build. E07 guarantees only that the label comes from ARB and that nothing formats to a
    fixed width. The locale × text-scale × width overflow matrix belongs to E08 and E11, and nothing
    here may shrink to fit — no `FittedBox`, no clamped `textScaler`, no ellipsis on a value.
14. **`intl` is already a dependency.** E01 T01.3 adds `intl` and `flutter_localizations` explicitly,
    naming this epic's `ScoreFormatter` as `intl`'s first consumer, and E01 T01.9 wires gen-l10n. No
    `dependency-hygiene` decision is pending here; if `intl` is missing, that is an E01 gap.
15. **The golden-vector oracle is Python.** `python3` is present on macOS and is not needed by CI (CI
    only verifies the committed table). If that is unacceptable, the oracle may be a second, slower
    Dart implementation — but it must not import the implementation under test.
16. **64-bit integers assume a native target.** Dart ints are JS doubles on web. **MindForge ships iOS
    only**; the header comment on `seeded_generator.dart` records that a web build would silently
    change every generated round. Android is deferred and no claim is made about it.
17. **CI exists from E01 and must be waited on.** This epic's PR is not merged until the pipeline is
    green, including the three gate steps T07.9 and T07.10 add.

## Definition of done

- [ ] Branch `epic/07-engine-core` cut from an up-to-date `main`.
- [ ] All ten tasks complete, each with its tests committed alongside the code they cover, tests
      first in every case.
- [ ] `lib/games/game_registry.dart` exists, ships an empty registry, and is the only file in `lib/`
      that may **enumerate** the registry (E08 adds `lib/l10n/game_strings.dart` as the second and last
      file that may name every game).
- [ ] Nothing here redeclares `Result`, `Failure`, `ScoreFormat`, `HudTone` or `LocaleNumbers`;
      `Difficulty` carries no `runLimit`; the PRNG is `SeededGenerator` in
      `lib/core/seeded_generator.dart` and there is no `SeededRng` anywhere.
- [ ] `RunNotifier` is the only writer of `RunPhase`; `over` is terminal and a test proves it.
- [ ] The 25-cell transition table, the lifecycle suite, the persist-then-transition assertion and
      the seeded-generator vectors are all green.
- [ ] **No user-facing literal lives under `lib/games/` or `lib/features/play/domain/`**, and
      `test/policy/registry_localization_test.dart` was seen red against a planted `title:` string.
- [ ] **`ScoreFormatter` renders `1,480` / `1.480` / `۱٬۴۸۰` / `۱٬۴۸۰`,** the `fa` and `ckb` digits are
      asserted to be U+06Fx, and the `ckb`-falls-back-to-Latin assertion was seen red before the `fa`
      pin made it green.
- [ ] **The golden vectors and a full fixture run are byte-identical under `en`, `de`, `fa` and
      `ckb`,** and the vector test was seen red against a deliberately locale-dependent seed key.
- [ ] `test/engine/engine_seam_test.dart` plays a fixture game to completion; `lib/features/**`
      contains zero lines about it.
- [ ] No test sleeps; the suite runs in seconds.
- [ ] `/simplify` run and its findings addressed.
- [ ] `/code-review` run and its findings addressed.
- [ ] `dart format --output=none --set-exit-if-changed .`,
      `flutter analyze --fatal-infos --fatal-warnings` and
      `flutter test --test-randomize-ordering-seed random` all green.
- [ ] `bash tool/skill_gates.sh` exits 0, with `check_arb_parity.sh` in the run table.
- [ ] PR opened with the five required sections. **Screens compared** says: *no screen was built and
      no simulator was booted, so no PNG comparison applies in either direction* — the LTR set and the
      new `screens/rtl/` set both become targets in E08. **Deliberately left out** names screens,
      boards, games, haptics, persistence internals, the `ckb` Material delegate (E04) and the
      translation review (E11).
- [ ] CI green on the PR, including the locale-matrix step.
- [ ] Merged preserving the granular commits, branch deleted, back on `main`, pulled.
