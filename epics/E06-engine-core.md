# E06 · Engine core

| | |
|---|---|
| **Branch** | `epic/06-engine-core` |
| **Depends on** | E01, E02, E03, E05 |
| **Unblocks** | E07, E08, E09 |
| **Status** | Not started |

## The epic

Build the seam that makes "one codebase, many games" real, with **zero games in it**. This epic
delivers the engine vocabulary — `GameDefinition`, `BoardSnapshot`, `GameRegistry`, `RunConfig`,
`GameId`, `Difficulty`, `RunOutcome` — the run lifecycle (`RunPhase` machine, `RunTicker` over the
injected `Clock`, `RunNotifier` and its persist-then-transition edge), and the seeded PRNG that makes a
round reproducible from a bug report. It **adopts** the typed `Result`/`Failure` spine E05 shipped and
extends it with `RunFailure`; it does not define a second one. `ScoreFormat` likewise comes from E05's
`lib/core/score_format.dart` — it is the enum the `runs` table's `metric_kind` CHECK mirrors, and there
is no `MetricKind` beside it.

Nothing here renders. No screen, no board, no Stroop, no Schulte. The proof that the seam works is a
**fixture game that lives only under `test/`**: it is registered through `gameRegistryProvider`, driven
through a complete run headlessly, and it adds zero lines to `lib/features/**`. E07 then builds the
eight screens against these types, and E08/E09 add real games by appending one line to the registry.

## Why we need it

Schulte Grid is the product's central claim: the second game must ship without editing
`lib/features/**`. That claim is decided here, not in E09. If `GameDefinition` is missing a field the
shell needs, E09's only options are a `switch (gameId)` in a shell file or a fork of
`PlayScaffoldScreen` — and the engine is gone.

Without this epic:

- E07 has nothing to render. Every shell screen reads `GameDefinition` fields and `RunState`; the
  screens cannot be written against types that do not exist.
- The run has no clock. `sunburst-shell-screens` rule 3 gives the shell exactly one ticker; without it
  every game grows a `Stopwatch` and pause stops none of them.
- Runs are irreproducible. A player reporting "the Blitz round gave me two orange keys" hands us a
  seed that means nothing, because there is no frozen PRNG to replay it with.
- The persist-then-transition ordering has no owner, so the personal-best badge will eventually
  celebrate a run that failed to save.

## Current state

Verified by `ls` at the repo root on 2026-08-19:

- **The Flutter app is not scaffolded.** No `pubspec.yaml`, no `lib/`, no `test/`, no `.github/`.
  The repo root holds `CLAUDE.md`, `50-apps-challenge-slides.html`, `design/`, `.claude/`.
- `git log --oneline` shows 4 commits on `main`: convention skills + slides, three candidate design
  systems, Sunburst Pop screenshots, five `sunburst-*` skills + `CLAUDE.md`.
- `.claude/skills/` holds 45 skills and 49 gate scripts under `.claude/skills/*/scripts/*.sh`. **They do
  not all exit 0 on an absent target** — measured with no argument, 29 of the 49 fail: 21 exit 2, 7 exit
  1, and `check-scheduler-purity.sh` exits 127 on macOS bash 3.2. E01 T01.5 corrected `CLAUDE.md`
  working agreement 10 to say so and E01 T01.8 built `tool/skill_gates.sh`, which carries an explicit
  run table and a skip table with a reason per row. That runner is the only sanctioned way to run the
  set.
- `design/sunburst-pop/` holds `system.html`, `app.html`, `capture-screens.sh` and eight reference
  PNGs. `app.html` contains the literal score strings this epic formats: `1,480`, `1,240`, `18.6s`.
- `epics/` was empty before this file.

By the time this epic starts, E01–E05 have merged: `pubspec.yaml`, `analysis_options.yaml`,
`.github/workflows/`, `l10n.yaml` + `AppLocalizations`, `lib/theme/**` (including `game_accent.dart`
with `GameAccent` and `GameColourRole`), `lib/ui/components/**`, `lib/shared/**`, and `lib/data/**` with
the drift database and `RunRepository`. **Nothing under `lib/games/**` or `lib/features/play/**` exists
yet.**

Specifically inherited from `lib/core/`, and **not to be redeclared here**:

| From | Symbol |
|---|---|
| E03 T03.1 | `lib/core/hud_tone.dart` — `enum HudTone { neutral, highlight, alarm }`. `HudPill` renders it, `GameHud` carries it; `lib/ui/` may not import `lib/features/`, so `lib/core/` is the only layer both reach. |
| E04 T04.4 | `lib/core/app_settings.dart` — the four-flag settings value, persisted by E05. |
| E05 T05.2 | `lib/core/result.dart`, `lib/core/failure.dart` (the spine), `lib/core/score_format.dart` (`enum ScoreFormat { points, duration }`), `lib/core/run_metric.dart`, `lib/core/run_draft.dart`, `lib/core/run_record.dart`, `lib/core/run_scope.dart`, `lib/core/calendar_day.dart` |
| E05 T05.6 | `lib/core/run_commit.dart` — `RunCommit(record, isPersonalBest)`, what `RunRepository.saveRun` returns |

`ls lib/core/` before T06.1. If any of these is missing, that is a gap in the epic that owns it — fix it
there, do not shim it here, and never declare a second `Result`, a second score enum or a second
`HudTone`.

## What we will achieve

A human can run `flutter test` and see a whole run happen for a game the engine has never heard of,
with no widget pumped and no test that sleeps.

Observable end state:

1. `lib/games/game_definition.dart` declares `GameDefinition` with `id`, `accent`, `colourRole`,
   `scoreFormat`, `difficulties`, `boardBackground`, `isTimed`, `runLimitFor`, `isLocked`, `buildBoard`,
   `buildArtwork`, `snapshotOf`.
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
   bit.
7. `test/engine/engine_seam_test.dart` registers `fixtureGameDefinition` — declared in
   `test/support/fixture_game.dart`, referenced nowhere in `lib/` — plays it to completion through
   `RunNotifier`, and reads its score, HUD and progress back off `RunState`.
8. `test/policy/shell_boundary_test.dart` fails if any file under `lib/features/**` imports
   `lib/games/<a specific game>/`, and `.claude/skills/sunburst-shell-screens/scripts/check_shell_boundaries.sh lib`
   is green.
9. `ScoreFormatter` renders `1480 → "1,480"` and `18_600 ms → "18.6s"` — the exact strings in
   `design/sunburst-pop/app.html`.

Nothing renders. There is no new screen to compare against a PNG; that lands in E07.

## Skills to load

| Skill | Why, for this epic |
|---|---|
| `flutter-conventions-index` | Front door. Carries the cross-cutting house rules and routes anything this table does not cover. |
| `sunburst-shell-screens` | Owns the seam this epic implements: `references/shell-game-boundary.md` fixes `GameDefinition`/`BoardSnapshot`/`GameHud`/`RunConfig` field-for-field, and `references/run-lifecycle.md` fixes every `RunPhase` edge, its trigger and its side-effect order. Build to those two files. |
| `sunburst-game-surfaces` | Declares `GameAccent`, `GameColourRole` and the `mechanic ⇒ surfaceSunk` / `decorative ⇒ gameAccent` pairing that `GameDefinition` must carry and T06.5 turns into a test. |
| `flutter-architecture` | Where each engine file belongs, the downward-only DAG (`features → data → core`), and rule 3 — abstract only what cannot run in a test, which is why the ticker takes a `Clock` and nothing else here gets an interface. |
| `project-structure-and-packages` | Fixes `lib/core/` as the sanctioned Flutter-free foundation (`Result`, `Failure`, `SeededGenerator`, `Difficulty`), the one-package default, and `test/` mirroring `lib/` 1:1. Its `check_import_boundaries.sh` is the gate that keeps `lib/core/` pure. |
| `state-management-riverpod` | `RunNotifier` is a `FamilyNotifier` over an immutable `RunState`; providers are the DI; `family` keys must be value-equal (`RunConfig`); no legacy providers; no `DateTime.now()` in state logic. |
| `service-boundary-and-native` | The `Clock` seam: `clockProvider` from `package:clock`, never a bespoke `ClockService`, overridden with `Clock.fixed`/`fakeAsync` in tests. Also the throwing-provider idiom used for `scoreFormatterProvider`. |
| `error-handling-typed-results` | The sealed `Result<T, F extends Failure>` spine, one `Failure` family per boundary with a stable `code` and no localized strings, exhaustive switches with no `default:`, and the persist-then-transition rule `RunNotifier._finish` implements. |
| `seeded-determinism-and-golden-vectors` | FNV-1a-64 + SplitMix64 written out line for line, the salt-per-feature rule, draw order as a contract, the frozen-generator rule, and the golden-vector table computed from an independent oracle that CI verifies and never blesses. |
| `dart3-idioms-and-coding-standards` | Which construct each engine type earns: `sealed` + `final` for `Result`/`Failure`/`RunOutcome`, enhanced enums for `Difficulty`/`ScoreFormat`, immutable value types with `copyWith`, total non-throwing domain functions, and the complexity limits `RunState` and `RunNotifier` must justify. |
| `testing-strategy` | Every test shape this epic uses: `package:test` tier for pure logic, `ProviderContainer` for headless notifiers, `fakeAsync` for timers, bare-`implements` fakes over mocks, and seeded fuzz against an independent oracle. |
| `async-safety` | `RunNotifier._finish` is the one `unawaited(...)` in the shell; `ref.mounted` after the `saveRun` await; `_ticker` and the lifecycle observer released in `ref.onDispose`. |
| `value-objects-money-and-units` | Canonical storage for a score: integer points, whole milliseconds for a duration, converted only at the presentation edge — and the injected-`Clock` rule the ticker obeys. |
| `naming-conventions` | The role suffixes this epic spends: `RunNotifier` (ViewModel), `ScoreFormatter` (pure formatter), `RunFailure` (sealed failure), `RunTicker`; file name = primary declaration; units in identifiers (`scoreValue`, `elapsedMilliseconds`). |
| `dartdoc-conventions` | Every symbol here is a public contract two later epics build on. `public_member_api_docs` is an analyzer error, so a missing `///` fails `flutter analyze --fatal-infos`. |
| `sunburst-motion-and-haptics` | T06.7 only, and only for two numbers: the run timer ticks at 10 Hz, and every boundary moment (`timerAlarm`) carries a latch on the immutable notifier state. No haptic is fired in this epic — that wiring is E04's `FeedbackService`, consumed in E07. |
| `ci-pipeline-and-gates` | T06.9 adds two steps to `.github/workflows/ci.yml` (E01's file): the shell-boundary and determinism-ban greps. Rules 1, 7 and 9 govern them — one named contract each, textually decidable, verify-never-bless. |
| `dependency-hygiene` | Only if `intl` is not already resolved through E01's l10n setup: caret range, `pubspec.lock` staged in the same commit, and the transitive audit that proves it opens no network path. |

## Tasks

### T06.1 — Adopt E05's result spine and add the run failure family

**Goal.** One `Result`/`Failure` vocabulary shared by the engine, the repository and every pure
function. **E05 T05.2 owns `lib/core/result.dart` and `lib/core/failure.dart`** — it is the first
consumer, every repository method returns one, and it merges before this epic. This task adopts them
unchanged and adds only `lib/core/run_failure.dart`. There is no conditional and no fallback: if the
spine is missing, that is an E05 gap to fix in E05.

**Tests first (TDD).** `test/core/result_test.dart`:
- `fold maps Ok through onOk and Err through onErr` — asserts both arms, no `default:` anywhere.
- `map transforms an Ok value and passes an Err through untouched` — asserts the `Err` instance is
  identical, not rebuilt.
- `switching a Result is exhaustive without a wildcard` — a switch over `Ok`/`Err` that compiles; the
  test's value is that adding a variant breaks the build.
- `every Failure subtype exposes a stable code and no localized string` — reflection-free: a const
  list of every `RunFailure` instance, asserting `code` matches `^[a-z]+\.[a-z_]+$` and that no field
  is a sentence.

**Implementation.** Read `lib/core/result.dart` and `lib/core/failure.dart` and change nothing in them.
Add `lib/core/run_failure.dart` — `sealed class RunFailure extends Failure` with the variants the run
needs that the repository does not own (an unregistered game id, a config whose difficulty the
definition does not offer). Persistence failures are **`DataFailure`**, E05's family, surfaced through
`RunState.saveFailure` — do not mirror them into `RunFailure`, or the results screen has two ways to say
"the save did not land".

**Files.** `lib/core/run_failure.dart`, `test/core/result_test.dart` (extend E05's), 
`test/core/run_failure_test.dart`.

**Skills.** `error-handling-typed-results`, `dart3-idioms-and-coding-standards`,
`project-structure-and-packages`, `dartdoc-conventions`.

**Screenshot check.** n/a (no visual surface).

**Done when.**
- [ ] `flutter test test/core/` green.
- [ ] `.claude/skills/error-handling-typed-results/scripts/check-swallowed-catch.sh lib` green.
- [ ] `.claude/skills/project-structure-and-packages/scripts/check_import_boundaries.sh lib` green —
      `lib/core/` imports no Flutter, no `dart:io`, no `dart:ui`, and reads no wall clock.
- [ ] Exactly one `Result` and one base `Failure` exist in the repo (`grep -rn "sealed class Result" lib/`
      returns one line, and `git log --diff-filter=A -- lib/core/result.dart` shows E05's commit).

**Commits.**
1. `Add run failure taxonomy tests`
2. `Adopt E05's result spine and add the sealed RunFailure family`

### T06.2 — Seeded generator, run seed provider and golden vectors

**Goal.** A PRNG this repo owns, frozen by a committed vector table, so a round is reproducible from
`(gameId, difficulty, seed)` on any device and any future SDK.

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
`test/core/seeded_random_provider_test.dart`:
- `the run seed is a pure function of the injected clock` — `clockProvider.overrideWithValue(Clock.fixed(t))`,
  two draws, identical seeds.
- `two instants produce different seeds` — `Clock.fixed(t)` vs `Clock.fixed(t + 1ms)`.

**Implementation.** **`lib/core/seeded_generator.dart` is the one PRNG path in this repository, and this
task is where it lands.** It exports exactly three things and E08 and E09 both import them by these
names: `int fnv1a64(String key)`, `final class SeededGenerator` (SplitMix64: `nextInt64()`,
`nextInt(int max)`), and
`SeededGenerator seedFrom(String key, {required int featureSalt, int modeSalt = 0})` — transcribed
from `seeded-determinism-and-golden-vectors`, not invented. There is no `SeededRng`, no
`lib/core/random/seeded_rng.dart` and no `lib/shared/determinism/`; a game epic that adds one has built
a second generator and destroyed the frozen-vector guarantee this task exists to create. Frozen salt
constants live beside them, one per consumer, with a comment that they are frozen forever.
`lib/features/play/application/seeded_random_provider.dart`: `typedef RunSeedDraw = int Function();`
and `seededRandomProvider`, a `Provider<RunSeedDraw>` that reads `clockProvider` once and returns
`() => fnv1a64(clock.now().toUtc().toIso8601String())`. This is the only place a run's entropy is
read; the generator itself never touches a clock.
`tool/seed_vectors_oracle.py`: a ~30-line **independent** Python implementation of FNV-1a-64 and
SplitMix64 that writes `test/core/seed_vectors.dart`. Rows cover the first and last key, an
all-ASCII key, a key with a multi-byte UTF-8 character, and one historical key. Regeneration is
`python3 tool/seed_vectors_oracle.py` reviewed in the PR diff — **CI verifies, never blesses**.
Header comment on `seeded_generator.dart`: 64-bit integer arithmetic assumes a native target; the app
ships iOS/Android only and must not be built for web without reimplementing this in 32-bit halves.

**Files.** `lib/core/seeded_generator.dart`,
`lib/features/play/application/seeded_random_provider.dart`, `tool/seed_vectors_oracle.py`,
`test/core/seed_vectors.dart`, `test/core/seeded_generator_test.dart`,
`test/core/seeded_random_provider_test.dart`.

**Skills.** `seeded-determinism-and-golden-vectors`, `testing-strategy`, `service-boundary-and-native`,
`dart3-idioms-and-coding-standards`.

**Screenshot check.** n/a (no visual surface).

**Done when.**
- [ ] `flutter test test/core/seeded_generator_test.dart test/core/seeded_random_provider_test.dart` green.
- [ ] `.claude/skills/seeded-determinism-and-golden-vectors/scripts/check-determinism-bans.sh lib/core` green.
- [ ] `.claude/skills/service-boundary-and-native/scripts/check-service-boundaries.sh lib` green — no
      `DateTime.now()`, no ambient `Random()`.
- [ ] The vector table's header names the oracle command and states it was not generated by the
      implementation under test.
- [ ] `grep -rn 'SeededRng\|shared/determinism\|core/random' lib/ test/` returns nothing — one name, one
      path, and E08/E09 have no fallback to fall back to.

**Commits.**
1. `Add seeded generator tests and the oracle-computed vector table`
2. `Add FNV-1a and SplitMix64 seeded generator`
3. `Add the run seed provider over the injected clock`

### T06.3 — Engine vocabulary: GameId, Difficulty, ScoreFormatter, RunScope.of

**Goal.** The pure value types every later epic names, with score formatting that produces the exact
strings in `app.html`, and the single conversion from typed ids to the strings E05 persists.

**`ScoreFormat` is E05's, not this epic's.** `lib/core/score_format.dart` already declares
`enum ScoreFormat { points, duration }`, and the `runs` table's `metric_kind` CHECK mirrors
`ScoreFormat.name`. This task imports it for `GameDefinition.scoreFormat` and `ScoreFormatter`. Do not
declare a second score enum here — one rename between `duration` and `durationMs` on the single column
that decides MAX versus MIN is a silent wrong-personal-best bug.

**Tests first (TDD).** `test/core/game_id_test.dart`:
- `GameId is value-equal and usable as a map key` — two `GameId('stroop_rush')` are `==` with equal
  `hashCode`; a `Map<GameId, int>` round-trips.
- `GameId rejects an empty or non-snake-case value` — asserts in debug; the id is also a route
  segment and a DB key.
`test/core/difficulty_test.dart`:
- `the three difficulties are declared in display order` — `Difficulty.values` is
  `[chill, classic, blitz]`.
- `a difficulty carries a lock flag and nothing about time` — `Difficulty` has **no `runLimit` field**;
  the test asserts the field list, because a run length on the difficulty enum forces every game to be
  timed the same way (see T06.5 and Risk 5).
`test/core/run_scope_test.dart`:
- `RunScope.of maps a typed id and difficulty to the persisted strings` —
  `RunScope.of(const GameId('stroop_rush'), Difficulty.classic)` equals
  `const RunScope('stroop_rush', 'classic')`, and a null difficulty yields a null `difficultyId`
  (the all-difficulties scope).
- `RunScope.of is the only conversion` — a policy grep asserting no file outside `run_scope.dart`
  constructs a `RunScope` from a `.value` or a `.name`.
`test/core/score_formatter_test.dart`:
- `points render with a thousands separator` — `1480 → "1,480"`, `1240 → "1,240"` (transcribed from
  `design/sunburst-pop/app.html`).
- `a duration renders as one decimal of seconds` — `18_600 → "18.6s"` (same source).
- `a duration rounds half away from zero at the tenth` — `18_650 → "18.7s"`, `18_649 → "18.6s"`.
- `zero and a sub-second duration render without a leading gap` — `0 → "0.0s"`, `900 → "0.9s"`.
- `formatting is a pure function of its injected NumberFormat` — the same value under two
  `NumberFormat`s differs, proving no ambient locale is read.

**Implementation.** `lib/core/game_id.dart`: `final class GameId` wrapping `final String value`, const
constructor, `==`/`hashCode`/`toString`, `assert` on the snake_case shape.
`lib/core/difficulty.dart`: enhanced `enum Difficulty { chill, classic, blitz }` with `final bool
isLocked` and **no run limit**. Run length belongs to the game, not to the difficulty: Stroop Rush is a
fixed round count and Schulte Grid is a race scored by elapsed time, and a `runLimit` on this enum would
force the shell to cut a Schulte player off mid-board. `GameDefinition.runLimitFor(Difficulty)` (T06.5)
carries it instead, nullable, `null` meaning untimed.
`lib/core/run_scope.dart` **(edit — E05 created it)**: add
`factory RunScope.of(GameId gameId, Difficulty? difficulty)`. This is the one place a typed id becomes a
persisted string; screens hold `GameId`/`Difficulty` and E05's providers are keyed by `RunScope`, so
without it every screen hand-builds the key and one of them eventually spells it differently.
`lib/core/score_formatter.dart`: `final class ScoreFormatter` constructed with a `NumberFormat` and a
seconds suffix, exposing `String format(int scoreValue, ScoreFormat format)`; plus
`scoreFormatterProvider`, a `Provider<ScoreFormatter>` that throws `UnimplementedError` until the
composition root overrides it, wired in `lib/bootstrap.dart` with
`NumberFormat.decimalPattern('en')`. `package:intl` is pure Dart, so `lib/core/` stays inside the
import-boundary gate; the "no intl in core" line in `value-objects-money-and-units` is scoped to the
money/unit value objects.

**Files.** `lib/core/game_id.dart`, `lib/core/difficulty.dart`, `lib/core/run_scope.dart` (edit),
`lib/core/score_formatter.dart`, `lib/bootstrap.dart` (one override line), `test/core/game_id_test.dart`,
`test/core/difficulty_test.dart`, `test/core/run_scope_test.dart`, `test/core/score_formatter_test.dart`.

**Skills.** `dart3-idioms-and-coding-standards`, `value-objects-money-and-units`, `naming-conventions`,
`service-boundary-and-native`, `dartdoc-conventions`.

**Screenshot check.** n/a (no visual surface). The expected strings `1,480`, `1,240` and `18.6s` are
transcribed from `design/sunburst-pop/app.html`, which renders
`design/sunburst-pop/screens/02-game-detail.png` and `06-results.png`; E07 compares the rendered
pixels.

**Done when.**
- [ ] `flutter test test/core/` green.
- [ ] `.claude/skills/project-structure-and-packages/scripts/check_import_boundaries.sh lib` green.
- [ ] `flutter analyze --fatal-infos --fatal-warnings` clean, which includes a `///` on every public
      member.
- [ ] `Difficulty` has no `runLimit`; `grep -rn 'enum ScoreFormat' lib/` returns exactly one line and it
      is in `lib/core/score_format.dart` (E05's file).
- [ ] `RunScope.of` is the only conversion from `GameId`/`Difficulty` to persisted strings.

**Commits.**
1. `Add GameId and Difficulty tests`
2. `Add GameId and Difficulty value types`
3. `Add RunScope.of as the one typed-id-to-scope conversion`
4. `Add score formatter tests transcribed from app.html`
5. `Add ScoreFormatter over E05's ScoreFormat with an injected NumberFormat`

### T06.4 — The upward channel: BoardSnapshot, GameHud, RunOutcome, RunConfig

**Goal.** Everything a game hands back to the shell, and the only thing the shell hands down.

**Tests first (TDD).** `test/features/play/domain/board_snapshot_test.dart`:
- `a snapshot with no outcome is a live run` — `outcome == null`; the shell reads that as "keep going".
- `progress is null or within 0..1` — asserts on 0, 1, 0.5, and that -0.1 and 1.1 trip the assert.
- `GameHud holds exactly three slots` — the type makes a fourth unrepresentable; the test documents it.
- `HudSlot defaults to the neutral tone` — a game never sets `alarm`.
- `value equality holds for identical snapshots` — required, because Riverpod diffs by value.
`test/features/play/domain/run_outcome_test.dart`:
- `a completed outcome carries a score and exactly three stats` — the results trio is a fixed
  3-column grid; fewer than three is a `GameDefinition` bug.
- `an abandoned outcome carries no score` — the type has no score field to read.
- `switching a RunOutcome is exhaustive without a wildcard`.
`test/features/play/domain/run_config_test.dart`:
- `RunConfig is value-equal so it is a safe family key` — two configs with the same
  `(gameId, difficulty, seed)` are `==` with equal `hashCode`.
- `a different seed is a different config` — the reason "Play again" is a new notifier.

**Implementation.** `lib/features/play/domain/board_snapshot.dart` holds the cohesive set
`BoardSnapshot`, `GameHud` and `HudSlot` — one file because they are one contract, close to how
`sunburst-shell-screens/references/shell-game-boundary.md` declares them. All `@immutable`, `const`
constructors, hand-rolled `==`/`hashCode`.

**`HudTone` is imported, not declared.** E03 T03.1 put it in `lib/core/hud_tone.dart` because `HudPill`
(in `lib/ui/`) renders a tone and `HudSlot` (here, in `lib/features/`) carries one, and `lib/ui/` may
never import `lib/features/` under the downward-only DAG. Declaring it in this file too would produce
two enums with one name that never unify: a game sets `HudTone.highlight` from the domain side, the pill
switches on the UI side, and the code would not compile at the seam. `lib/core/` is the only layer both
can reach. Add the import and note it in this task's `check_import_boundaries.sh` done-when.
`lib/features/play/domain/run_outcome.dart`: `sealed class RunOutcome` with
`final class RunCompleted` (`int score`, `List<ResultStat> stats`, `assert(stats.length == 3)`) and
`final class RunAbandoned`, plus `const factory RunOutcome.completed({required int score, required List<ResultStat> stats})`
and `const factory RunOutcome.abandoned()` so the call sites in the skills' board examples compile
unchanged. `ResultStat(label, value)` — both already-localized display strings.
`lib/features/play/domain/run_config.dart`: `RunConfig(gameId, difficulty, seed)` with value equality.

**Files.** `lib/features/play/domain/board_snapshot.dart`,
`lib/features/play/domain/run_outcome.dart`, `lib/features/play/domain/result_stat.dart`,
`lib/features/play/domain/run_config.dart`, and their three mirrored test files.

**Skills.** `sunburst-shell-screens`, `dart3-idioms-and-coding-standards`, `naming-conventions`,
`dartdoc-conventions`.

**Screenshot check.** n/a (no visual surface). `HudTone`'s three tones and the results trio are
rendered in E07 against `04-stroop-rush.png`, `05-schulte-grid.png` and `06-results.png`.

**Done when.**
- [ ] `flutter test test/features/play/domain/` green.
- [ ] `.claude/skills/dart3-idioms-and-coding-standards/scripts/check-dart3-idioms.sh lib` reports no
      hard failure and no unjustified advisory.
- [ ] `.claude/skills/project-structure-and-packages/scripts/check_import_boundaries.sh lib` green with
      `board_snapshot.dart` importing `lib/core/hud_tone.dart`; `grep -rn 'enum HudTone' lib/` returns
      exactly one line, in `lib/core/`.
- [ ] No `Color`, no `Widget`, no `BuildContext` in any file under `lib/features/play/domain/`.

**Commits.**
1. `Add board snapshot and HUD contract tests`
2. `Add BoardSnapshot, GameHud and HudSlot over the shared HudTone`
3. `Add run outcome and run config tests`
4. `Add sealed RunOutcome, ResultStat and RunConfig`

### T06.5 — GameDefinition and the registry

**Goal.** The one file allowed to name every game, and a registry whose invariants are tests rather
than review notes.

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
`test/games/game_registry_test.dart`:
- `the registry is the only file in lib/ that names a game` — the durable assertion. The
  **emptiness** of the list is asserted separately, in this epic's own fixture-registry override, so
  that E07 (placeholders), E08 (Stroop) and E09 (Schulte) each append without having to delete and
  re-explain a test whose name no longer describes what it checks.
- `game ids are unique across the registry` — driven with two fixture definitions.
- `gameDefinitionProvider resolves a registered id` — via `ProviderContainer.test`.
- `gameDefinitionProvider throws a StateError for an unknown id` — a bug, not a recoverable failure.
- `registry order is display order` — the list is returned unsorted and unfiltered.

**Implementation.** `lib/games/game_definition.dart`: `typedef GameBoardBuilder = Widget Function(BuildContext, RunConfig);`,
`enum BoardBackground { surfaceSunk, gameAccent }`, and `@immutable final class GameDefinition` with
`id`, `accent` (`GameAccent`, from `lib/theme/game_accent.dart`), `colourRole` (`GameColourRole`),
`scoreFormat` (E05's `ScoreFormat`), `difficulties`, `boardBackground`, `isTimed` (default `true`),
`isLocked` (default `false`), **`Duration? Function(Difficulty)? runLimitFor`** (default `null` for
every difficulty), `buildBoard`, `buildArtwork`, and
`ProviderListenable<BoardSnapshot> Function(RunConfig) snapshotOf`. Constructor asserts encode the
role/background pairing, `difficulties.isNotEmpty`, and that `isTimed == false` implies `runLimitFor`
returns `null` everywhere. No localized strings are fields — the shell resolves
`game_<id>_title`/`_tagline`/`_kicker` from ARB by id.

**Run length lives on the game, not on `Difficulty`.** Stroop Rush is a fixed round count and ends via
`BoardSnapshot.outcome`; Schulte Grid is a race scored by elapsed time and any shell-imposed limit would
cut the player off mid-board. A `runLimit` on the `Difficulty` enum would force one answer on both. With
`runLimitFor` nullable per definition, a game declares a limit or does not, and T06.6/T06.8's
"end when `remaining` hits zero" applies only when one exists.

`lib/games/game_registry.dart`: `gameRegistryProvider` (`Provider<List<GameDefinition>>` returning an
empty const list) and `gameDefinitionProvider` (`Provider.family<GameDefinition, GameId>`). The file
header states: **"this is the only file in `lib/` that may enumerate the game registry."** Deliberately
not "the only file that may name a game" — E07 T07.1 adds `lib/l10n/game_strings.dart`, which maps every
`GameId` to its ARB-resolved title, and that header would become false the moment E07 merges. E07 states
the two-file rule in one place; this header stays true forever.

`colourRole` widens the `GameDefinition` in `sunburst-shell-screens` by one field. That is deliberate
and licensed by that skill's own instruction to widen the seam rather than special-case a screen: it
converts the `mechanic ⇒ surfaceSunk` rule from a review-only check into a constructor assert plus a
test.

**Files.** `lib/games/game_definition.dart`, `lib/games/game_registry.dart`,
`test/games/game_definition_test.dart`, `test/games/game_registry_test.dart`,
`test/support/fixture_game.dart` (first version — a minimal definition used by these tests).

**Skills.** `sunburst-shell-screens`, `sunburst-game-surfaces`, `state-management-riverpod`,
`flutter-architecture`, `dartdoc-conventions`.

**Screenshot check.** n/a (no visual surface).

**Done when.**
- [ ] `flutter test test/games/` green.
- [ ] `.claude/skills/sunburst-shell-screens/scripts/check_shell_boundaries.sh lib` green.
- [ ] `.claude/skills/state-management-riverpod/scripts/ban-legacy-providers.sh lib` green.
- [ ] `grep -rn "switch (gameId)\|switch (config.gameId)" lib/` returns nothing.

**Commits.**
1. `Add game definition invariant tests`
2. `Add GameDefinition and BoardBackground`
3. `Add game registry tests`
4. `Add the empty game registry and its providers`

### T06.6 — The RunPhase machine as a pure, exhaustive table

**Goal.** Phase legality as a total pure function, so the machine is decided before any notifier
exists.

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

**Implementation.** `lib/features/play/domain/run_phase.dart`: `enum RunPhase { idle, countdown, playing, paused, over }`
with `bool canTransitionTo(RunPhase next)` implemented as one exhaustive `switch` with no `default:`.
`lib/features/play/domain/run_state.dart`: `@immutable final class RunState` storing `config`, `phase`,
`elapsed`, `runLimit` (`Duration?`), `snapshot`, `isPersonalBest`, `saveFailure`,
`hasFiredTimerAlarm`, `scoreLabel`; deriving `hud`, `progress`, `outcome`, `remaining` and
`isTimerAlarm` as getters (derive, don't store); `RunState.idle(config, runLimit)`,
`copyWith`, `transitionTo(RunPhase)` guarded by `assert(phase.canTransitionTo(next))`, and the named
edges `toOver(outcome, {isPersonalBest, saveFailure})`. Hand-rolled `==`/`hashCode`; no `freezed`, so
this epic adds no codegen step.

**Files.** `lib/features/play/domain/run_phase.dart`, `lib/features/play/domain/run_state.dart`,
`test/features/play/domain/run_phase_test.dart`, `test/features/play/domain/run_state_test.dart`.

**Skills.** `sunburst-shell-screens` (`references/run-lifecycle.md`),
`dart3-idioms-and-coding-standards`, `testing-strategy`, `dartdoc-conventions`.

**Screenshot check.** n/a (no visual surface).

**Done when.**
- [ ] `flutter test test/features/play/domain/run_phase_test.dart test/features/play/domain/run_state_test.dart` green.
- [ ] The table test names all 25 cells; deleting one legal edge from the implementation fails it.
- [ ] No `default:` or `case _:` in either file.

**Commits.**
1. `Add the exhaustive RunPhase transition table test`
2. `Add RunPhase and its legality table`
3. `Add RunState transition tests`
4. `Add immutable RunState with derived remaining and alarm`

### T06.7 — RunTicker over the injected Clock

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

**Commits.**
1. `Add run ticker tests driven by fake async`
2. `Add RunTicker over the injected clock`

### T06.8 — RunNotifier: the machine, the lifecycle and persist-then-transition

**Goal.** One owner for every phase change, one write path, and a resume that never steals the
player's pause.

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
- `a successful save carries the committed personal-best flag` — `Ok(RunCommit(record, isPersonalBest:
  true))` in, `isPersonalBest == true` out. The flag comes from the committed row (E05 computes it
  inside the same transaction as the insert), never from a post-commit read of `watchPersonalBest`,
  which would race the notifier's own write.
- `a failed save still reaches over, carrying the failure and no personal best` — `Err(DataFailure)` in,
  `saveFailure != null` and `isPersonalBest == false` out.
- `backgrounding pauses a live run` — push `AppLifecycleState.inactive`, then `.paused`, then
  `.hidden`; each pauses from `playing`.
- **`resuming never un-pauses`** — push `.paused` then `.resumed`; the phase stays `paused`.
- `detached writes nothing`.
- `over is terminal` — call `start`, `pause`, `keepPlaying`, `leaveRun` and `abandon` from `over` and
  assert the phase never changes and no assert-legal edge exists.
- `the timer alarm latch flips exactly once` — a 60 s run ticked at 10 Hz through the last 5 seconds
  sets `hasFiredTimerAlarm` once, not fifty times.
- `the ticker and the lifecycle observer are released on dispose`.

**Implementation.** `lib/features/play/application/run_notifier.dart`: `final class RunNotifier extends FamilyNotifier<RunState, RunConfig>`
plus `runNotifierProvider = NotifierProvider.family<RunNotifier, RunState, RunConfig>(RunNotifier.new)`.
`build(config)` watches `gameDefinitionProvider(config.gameId)`, listens to
`definition.snapshotOf(config)`, constructs the `RunTicker` from `clockProvider`, registers a
run-scoped `WidgetsBindingObserver`, and releases both in `ref.onDispose`. Intent methods return
`void`: `start()`, `abandon()`, `pause()`, `keepPlaying()`, `leaveRun()`. `_finish(outcome)` is the
one `unawaited(...)` in the engine — it stops the ticker, builds a **`RunDraft`** (E05's
`lib/core/run_draft.dart`: scope strings via `RunScope.of`, `clientRunKey`, `playedOnDay`,
`durationMs: _ticker.elapsed.inMilliseconds`, `format`, `value` and the counters), awaits
`ref.read(runRepositoryProvider).saveRun(draft)` — E05's single write path, returning
`Result<RunCommit, DataFailure>` — guards `ref.mounted`, then switches the `Result` exhaustively into
`toOver(outcome, isPersonalBest: commit.isPersonalBest)` on `Ok` and
`toOver(outcome, saveFailure: failure)` on `Err`. The method name and the payload are E05's contract,
not this epic's to rename. Formatting of `scoreLabel` uses `scoreFormatterProvider`. Every phase
assignment goes through `RunState.transitionTo`.

**Files.** `lib/features/play/application/run_notifier.dart`,
`test/features/play/application/run_notifier_test.dart`, `test/support/fake_run_repository.dart`,
`test/support/fake_board_snapshot_source.dart`.

**Skills.** `sunburst-shell-screens` (`references/run-lifecycle.md`), `state-management-riverpod`,
`error-handling-typed-results`, `async-safety`, `testing-strategy`, `service-boundary-and-native`.

**Screenshot check.** n/a (no visual surface). The pause sheet has no reference PNG and is not built
here; E07 owns it.

**Done when.**
- [ ] `flutter test test/features/play/` green.
- [ ] `.claude/skills/state-management-riverpod/scripts/ban-legacy-providers.sh lib` green.
- [ ] `.claude/skills/error-handling-typed-results/scripts/check-swallowed-catch.sh lib` green.
- [ ] `.claude/skills/flutter-architecture/scripts/check_architecture.sh lib` green.
- [ ] `grep -rn "state.phase =\|phase:" lib/ --include=*.dart | grep -v run_notifier | grep -v run_state`
      shows no other writer of a phase.

**Commits.**
1. `Add fake run repository and fake snapshot source`
2. `Add run notifier lifecycle tests`
3. `Add RunNotifier and the run phase transitions`
4. `Add persist-then-transition tests`
5. `Persist a finished run before entering the over phase`
6. `Add background and resume lifecycle tests`
7. `Pause on background and never un-pause on resume`

### T06.9 — Prove the seam: a fixture game that touches no shell file

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
`test/policy/shell_boundary_test.dart`:
- `no file under lib/features imports a specific game` — reads every `.dart` under `lib/features/`
  and fails on `import '…games/<segment>/…'`, mirroring
  `check_shell_boundaries.sh` at the Dart tier so it runs in `flutter test` too. Passes vacuously
  while `lib/features/` is thin, and stays as the tripwire for E07–E09.
- `no file under lib/games builds shell chrome` — the same grep set as the shell script
  (`go_router`, `Navigator.`, `Scaffold(`, `AppBar(`, `SafeArea(`, `HudPill`, `Stopwatch(`,
  `Timer.periodic(`, `runNotifierProvider`).
- `lib/games/game_registry.dart is the only file in lib/ that names a game directory`.

**Implementation.** `test/support/fixture_game.dart`: `fixtureGameDefinition` — a `GameDefinition`
with `GameAccent.schulteTurquoise`, `GameColourRole.decorative`,
`BoardBackground.gameAccent`, `ScoreFormat.points`, all three difficulties, a board builder returning
a `SizedBox.shrink()`, and a `snapshotOf` pointing at a controllable test notifier. It lives under
`test/` and is referenced from nowhere in `lib/`.
`test/policy/shell_boundary_test.dart` uses `dart:io` file reads — legal in a policy test, which is
the sanctioned home for cross-cutting assertions that belong to no single file.
Wire the two engine-relevant gate scripts into `.github/workflows/` (created by E01) if they are not
already there: `check_shell_boundaries.sh` and `check-determinism-bans.sh lib/core`.

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

## Gates that must pass

Run from the repo root, in this order, before every commit and again before the PR:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # ALWAYS before analyze
dart format --set-exit-if-changed .
flutter analyze --fatal-infos --fatal-warnings
flutter test
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
```

Then the whole set, through the one runner E01 T01.8 built:

```bash
bash tool/skill_gates.sh
```

**Not** `for s in .claude/skills/*/scripts/*.sh; do bash "$s"; done`. That loop cannot exit 0: measured,
29 of the 49 scripts fail argument-less, five take a required argument and can never pass that way, and
`check-scheduler-purity.sh` exits 127 on macOS bash 3.2. The runner's explicit run and skip tables are
what make the sweep a gate rather than noise, and `test/policy/skill_gates_coverage_test.dart` fails if
a script is missing from both.

## Risks and open questions

1. **`Result`/`Failure` is E05's, decided.** E05 T05.2 creates `lib/core/result.dart` and
   `lib/core/failure.dart` outright — it is the first consumer and it merges first. T06.1 adopts them
   and adds `RunFailure` only. Two hedged "whichever lands first" clauses are not an owner; this is.
2. **`RunState.saveFailure` is `DataFailure`, E05's family** — the one `RunRepository.saveRun` returns.
   Do not mirror persistence variants into `RunFailure`, or the results screen has two ways to say the
   same thing.
3. **Run length is per game, not per difficulty.** `GameDefinition.runLimitFor(Difficulty)` is nullable
   and defaults to `null`. Stroop Rush declares 90 / 60 / 30 seconds (**DERIVED** — neither
   `system.html` nor `app.html` states a run length) *or* declares none and ends on round count; E08
   Risk 2 decides which, and this epic's field shape supports either. Schulte Grid declares none.
   Confirm the Stroop numbers with the product owner (Zakaria) before E08 ships; changing them later
   invalidates every stored personal best, which the offline app cannot recompute.
4. **`colourRole` widens `GameDefinition` beyond the field list in `sunburst-shell-screens`.**
   Deliberate: it makes the `mechanic ⇒ surfaceSunk` pairing a constructor assert instead of a review
   note. If the skill is later updated, this epic's field is the reason.
5. **`isTimed` is a second knob next to `scoreFormat`.** They are correlated in practice
   (`points` ⇒ timed, `duration` ⇒ race) but not identical, and deriving one from the other would
   silently constrain the third game. Decision: keep both explicit, plus `runLimitFor` as the third —
   `isTimed` says whether the shell shows a clock, `runLimitFor` says whether it ends the run, and
   Stroop Rush is the case that shows a TIME pill (`04-stroop-rush.png`, 0:23) while ending on round
   count. Add a registry test in E09 if a real divergence never appears.
6. **`RunState` is a phase enum plus nine fields, not a sealed union.** A sealed `RunIdle`/`RunOver`
   would make phase-specific fields unrepresentable, but every example in `sunburst-shell-screens`
   switches on `state.phase`. Decision: keep the enum, guard with constructor asserts, and revisit
   only if E07 finds itself null-checking phase-specific fields.
7. **`intl` is already a dependency.** E01 T01.3 adds `intl` and `flutter_localizations` explicitly,
   naming this epic's `ScoreFormatter` as `intl`'s first consumer, and E01 T01.10 wires gen-l10n. No
   `dependency-hygiene` decision is pending here; if `intl` is missing, that is an E01 gap.
8. **The golden-vector oracle is Python.** `python3` is present on macOS and is not needed by CI (CI
   only verifies the committed table). If that is unacceptable, the oracle may be a second, slower
   Dart implementation — but it must not import the implementation under test.
9. **64-bit integers assume a native target.** Dart ints are JS doubles on web. MindForge ships
   iOS/Android only; the header comment on `seeded_generator.dart` records that a web build would
   silently change every generated round.
10. **CI exists from E01 and must be waited on.** This epic's PR is not merged until the pipeline is
    green, including the two gate steps T06.9 adds.

## Definition of done

- [ ] Branch `epic/06-engine-core` cut from an up-to-date `main`.
- [ ] All nine tasks complete, each with its tests committed alongside the code they cover, tests
      first in every case.
- [ ] `lib/games/game_registry.dart` exists, ships an empty registry, and is the only file in `lib/`
      that may **enumerate** the registry (E07 adds `lib/l10n/game_strings.dart` as the second and last
      file that may name every game).
- [ ] Nothing here redeclares `Result`, `Failure`, `ScoreFormat` or `HudTone`; `Difficulty` carries no
      `runLimit`; the PRNG is `SeededGenerator` in `lib/core/seeded_generator.dart` and there is no
      `SeededRng` anywhere.
- [ ] `RunNotifier` is the only writer of `RunPhase`; `over` is terminal and a test proves it.
- [ ] The 25-cell transition table, the lifecycle suite, the persist-then-transition assertion and
      the seeded-generator vectors are all green.
- [ ] `test/engine/engine_seam_test.dart` plays a fixture game to completion; `lib/features/**`
      contains zero lines about it.
- [ ] No test sleeps; the suite runs in seconds.
- [ ] `/simplify` run and its findings addressed.
- [ ] `/code-review` run and its findings addressed.
- [ ] `dart format --set-exit-if-changed .`, `flutter analyze --fatal-infos --fatal-warnings` and
      `flutter test` all green.
- [ ] `bash tool/skill_gates.sh` exits 0.
- [ ] PR opened with a body explaining what changed, why, how it was verified, that **no screen was
      built so no PNG comparison applies**, and what was deliberately left out (screens, boards,
      games, haptics, persistence internals).
- [ ] CI green on the PR.
- [ ] Merged preserving the granular commits, branch deleted, back on `main`, pulled.
