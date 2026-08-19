> **SUPERSEDED — do not build from this file.** It plans the old ten-epic sequence, written
> before the four-locale/two-direction and iOS-only requirements landed. It is superseded by
> [`../E02-persistence-layer.md`](../E02-persistence-layer.md) — **E02 · Persistence layer**. Kept for the record only; the live set is the
> eleven files in `epics/`, indexed by [`../README.md`](../README.md).

# E05 · Persistence layer

| | |
|---|---|
| **Branch** | `epic/05-persistence-layer` |
| **Depends on** | E01 |
| **Unblocks** | E06, E07, E08, E09, E10 |
| **Status** | Not started |

## The epic

Build `lib/data/` — the drift/SQLite store and the repositories over it — plus the pure value objects in
`lib/core/` that those repositories hand upward. Schema v1 is two STRICT tables: `runs` (one row per
completed run, the only authority for everything a player has ever done) and `settings` (one singleton
row for the four toggles on screen 08). Invariants live in the schema: `CHECK` on every enumerable and
every range, a partial `UNIQUE INDEX` that makes recording the same run twice impossible, and
`foreign_keys`/`journal_mode`/`synchronous`/`busy_timeout` re-asserted in `setup`/`beforeOpen` on every
open. DAOs hold single-table queries and map rows to immutable value objects; `RunRepository` and
`SettingsRepository` are the single write path, each mutation exactly one `db.transaction`, each
fallible method returning `Result<T, DataFailure>`.

Personal bests, per-game/per-difficulty aggregates and the daily streak are **not tables**. They are
folds over `runs`, recomputed on read and exposed as scoped `.watch()` streams — the derive-don't-store
rule, applied per field and stated per field below. The epic also stands up the migration ritual at v1:
a committed `drift_schemas/drift_schema_v1.json`, era-correct generated classes, a content round-trip
test on a hostile fixture, and a snapshot-restore opener proven by a forced mid-migration throw, so the
first real schema bump in a later epic has a harness instead of a hope.

## Why we need it

E06 (Engine core) owns `RunNotifier`, the `RunPhase` machine and the injected `Clock`. When a run ends
it has a result in memory and nowhere durable to put it. Without this epic there is no BEST pill on the
home cards, no "Your best / Games played" row on game detail, no personal-best badge on results, no
stats screen at all, and no settings that survive a relaunch — and every one of those is a shipped
surface in `design/sunburst-pop/screens/`.

It also has to be right the first time. MindForge has no server, no accounts and no telemetry
(`CLAUDE.md`, hard product constraints): the on-device DB is the only copy of a player's history, and a
migration that drops rows destroys data that exists nowhere else with nobody to report it. Getting the
canonical column types, the schema-level invariants and the migration harness in before there is any
data is the only cheap moment to do it.

## Current state

Verified by `ls` at the repo root on 2026-08-19:

- **No Flutter app.** No `pubspec.yaml`, no `pubspec.lock`, no `lib/`, no `test/`, no `analysis_options.yaml`,
  no `build.yaml`, no `.github/`. The repo holds `CLAUDE.md`, `50-apps-challenge-slides.html`,
  `design/` and `.claude/`.
- **4 commits on `main`**, latest `cb1c3e2`. `gh` authenticated, remote `git@github.com:zakariaf/mindforge.git`.
- `.claude/skills/` — 45 skills. Three of the four data-layer gate scripts exit 0 on a missing target
  (`persistence-drift/scripts/check-drift-confinement.sh`,
  `persistence-drift/scripts/check-persistence-bans.sh`,
  `error-handling-typed-results/scripts/check-swallowed-catch.sh`); the fourth,
  `seeded-determinism-and-golden-vectors/scripts/check-determinism-bans.sh`, **exits 2** — it defaults
  to `lib/core/` and needs the directory to exist. Measured across all 49 scripts, 29 fail with no
  argument, so `CLAUDE.md`'s "they all exit 0 when the target is absent" was wrong; E01 T01.5 corrected
  it and E01 T01.8 built `tool/skill_gates.sh`, which is the only sanctioned way to run the set.
- `design/sunburst-pop/` — the chosen direction. Relevant to this epic only as the source of the numbers
  the derived reads must produce: `app.html` screen 02 (`Your best 1,480`, `Games played 128`,
  difficulty segmented control `Chill / Classic / Blitz`), screen 06 (`Accuracy 92%`,
  `Avg reaction 640ms`, `Longest streak x11`, `New personal best`), screen 07 (`Best score Stroop Rush
  1,480`, `Best time Schulte Grid 18.6s`, `Games played 128`, `Time trained 3h 12m`, `Last 7 runs`) and
  screen 01 (`4 day streak`).

**Everything E05 touches is new.** E01 landed `pubspec.yaml`, `analysis_options.yaml`, `lib/main.dart`,
`lib/bootstrap.dart`, the empty `lib/core/` directory and `.github/workflows/ci.yml`; E04 landed
`lib/core/app_settings.dart` as an in-memory value. **E01 does not ship a `Result`/`Failure` spine — it
ships bootstrap and CI and nothing else — so this epic owns it** (T05.2). E06 adopts what lands here and
adds `lib/core/run_failure.dart`; it must not define a second spine. Confirm with
`ls lib/core/ lib/bootstrap.dart` on `main` before T05.1.

## What we will achieve

A reader can verify all of this by running the commands named:

1. `flutter test` is green, and includes a real `NativeDatabase.memory()` suite for every DAO and
   repository — no mocked DAO anywhere under `test/data/`.
2. `bash .claude/skills/persistence-drift/scripts/check-drift-confinement.sh lib` prints PASS: no file
   outside `lib/data/` imports `package:drift` or `package:sqlite3`, and `package:sqflite` appears nowhere.
3. `dart run drift_dev schema dump lib/data/db/app_database.dart drift_schemas/` followed by
   `git diff --exit-code -- drift_schemas/` produces no diff — the committed v1 snapshot matches the
   live schema.
4. `sqlite3` on a freshly created DB shows both tables declared `STRICT`, the `CHECK` list on each, and
   `ux_runs_client_key … WHERE is_deleted = 0`; `PRAGMA integrity_check` returns `ok` and
   `PRAGMA foreign_key_check` returns empty.
5. A `ProviderContainer` test can override `clockProvider` with `Clock.fixed(...)`, insert a fixture run
   set, and read back exactly the numbers on screens 02, 06 and 07 — `1,480`, `128`, `3h 12m`, `92%`,
   `640ms`, `x11`, `18.6s`, `4 day streak` — from `RunRepository` streams alone.
6. `grep -rn "DateTime.now()" lib/` returns nothing, and
   `bash .claude/skills/seeded-determinism-and-golden-vectors/scripts/check-determinism-bans.sh lib` passes.
7. A killed process mid-`saveRun()` leaves either zero rows or one complete row, proven by the rollback
   test in T05.6.
8. The CI freshness gates cover `*.drift.dart` and `drift_schemas/`, verified by pushing a deliberately
   stale generated file on a scratch commit and watching the job go red.

## Skills to load

| Skill | Why, for this epic |
|---|---|
| `flutter-conventions-index` | House rules 1, 5, 6, 7, 8, 9 are the spine of this epic: downward-only layering, single write path, derive-don't-store, typed `Result`/`Failure`, injected `Clock`, never-silent async. Open it first. |
| `persistence-drift` | The governing skill. STRICT tables, schema-level `CHECK`/FK/partial-UNIQUE, the `AuditColumns` mixin, per-connection pragmas in `setup`/`beforeOpen`, one `db.transaction` per mutation, persist-before-publish, scoped `.watch()`, keyset pagination, `NativeDatabase` FFI over `sqflite`. |
| `run-migration` | T05.10 only: the forward-only append-only ritual, the committed snapshot, `schema_versions.dart`, the pre-open snapshot/restore opener, the every-pair shape loop, and why `migrateAndValidate` alone proves nothing. |
| `error-handling-typed-results` | `DataFailure` is one sealed family per boundary with stable `code`s and typed params, no localized strings; convert `SqliteException` at the DAO/repository seam, log `(e, st)` first, return `Err`; call sites switch with no `default:`. Also the one-transaction-per-mutation half of never-lose-data. |
| `testing-strategy` | Every DAO test runs against `NativeDatabase.memory()`; `addTearDown(db.close)`; pure folds tested with `package:test` and `withClock`; the aggregate maths gets a seeded fuzz loop against an independent oracle with the seed echoed in `reason:`; Notifier/provider wiring driven through `ProviderContainer`. |
| `value-objects-money-and-units` | Canonical storage: integer SI units, UTC instants, and the `package:clock` `Clock` injected rather than `DateTime.now()`. There is no money in MindForge — the rules that apply are the canonical-int and injected-clock ones. |
| `seeded-determinism-and-golden-vectors` | The calendar-day rule: a day identity is a civil date / serial day, never an instant, and one day definition serves the streak, the "played today" check and the chart. Also the ban on ambient `Random()` and `DateTime.now()` that `check-determinism-bans.sh` enforces. |
| `service-boundary-and-native` | `clockProvider` is the one time seam and `IdGenerator` is the one id seam; both are injected interfaces overridden at the composition root and faked in tests. The provider throws until overridden so a forgotten wiring fails loudly. |
| `state-management-riverpod` | Provider shapes for the data layer: plain `Provider` for DI, `StreamProvider.autoDispose.family` for scoped reads, the throwing `appDatabaseProvider` seam, `ref.onDispose(db.close)`, and the rule that a committed write re-emits rather than being republished by hand. |
| `flutter-architecture` | The downward-only DAG this layer sits at the bottom of, repositories as single source of truth *and* single write path, map-at-the-boundary so no Drift row reaches a Notifier, and "abstract only what cannot run in a test" — which is why there is no `RunRepository` interface. |
| `project-structure-and-packages` | Where each file goes: `lib/data/` for the store, `lib/core/` for the pure value objects and calculators (the sanctioned pure-foundation layer, not a junk drawer), tests mirroring `lib/` 1:1, package imports only, single package — no `packages/`. |
| `naming-conventions` | `RunsDao`/`SettingsDao`, `RunRepository`/`SettingsRepository`, `DataFailure`, `StreakCalculator`; units in identifiers (`durationMs`, `totalReactionMs`, `playedOnDay`); booleans as `is`/`has`/`can`; file name equals its primary declaration. |
| `dart3-idioms-and-coding-standards` | `sealed` `DataFailure` + `final class` leaves with `const` ctors, exhaustive switches with no `default:`, immutable value objects with explicit stable identity, total non-throwing pure folds, and the complexity-limit table. |
| `dartdoc-conventions` | Every public symbol in `lib/data/` and `lib/core/` is a contract: a `///` that states units, ranges, nullability and the invariant — including "which column is authoritative and which value is derived" on each getter. |
| `codegen-and-toolchain` | `build.yaml` fencing drift_dev to `lib/data/**` so one edit does not regenerate the tree, the commit-vs-gitignore decision for `*.drift.dart` and the matching CI gate, and mirroring the generated globs into analyzer and coverage excludes. |
| `run-codegen` | The exact pass — `dart run build_runner build --delete-conflicting-outputs` — run before `flutter analyze`, never after, and never hand-editing a generated file. |
| `dependency-hygiene` | `drift`, `drift_flutter`/`sqlite3_flutter_libs`, `path_provider`, `path`, `uuid`, `clock` all go through the transitive audit against the no-network/no-telemetry policy; caret ranges in `pubspec.yaml`, exact pins only in the committed `pubspec.lock`. |
| `ci-pipeline-and-gates` | Confirming E01's freshness gates actually cover `*.drift.dart` and `drift_schemas/`, and that the Linux job installs host `libsqlite3-dev` — without it the whole real-DB suite fails for a reason that looks like a broken repo. |
| `async-safety` | Every query inside `transaction(() async {` is awaited (a dropped one runs after the commit — Drift calls that data loss), no bare or empty catch at the conversion seam, `rethrow` never `throw e`, and every `.watch()` subscription torn down with its provider. |

## Tasks

### T05.1 — Data-layer dependencies, fenced codegen, and the CI freshness gate

**Goal.** Add exactly the packages the store needs, fence drift_dev to `lib/data/**`, and confirm E01's
CI gates already fail on a stale `*.drift.dart` or `drift_schemas/`.

**Tests first (TDD).**
- `test/policy/dependency_policy_test.dart` — **extend E01 T01.3's existing file; do not re-author it.**
  E01 already asserts caret ranges, a non-empty committed lock, the banned set and the frozen allow-set.
  This task adds `sqflite` to the banned set (drift's FFI path is the one this repo takes, and a second
  SQLite binding is how a `path`-vs-`path_provider` mismatch becomes a runtime crash) and adds the six
  new packages to the frozen allow-set with the epic that first spends each. Duplicating E01's
  assertions in a second file is how the two lists drift.
- `test/policy/codegen_hygiene_test.dart` — asserts `build.yaml` fences `drift_dev` with a
  `generate_for:` glob rooted at `lib/data/`, that `analysis_options.yaml` excludes `**/*.drift.dart`,
  and that `.gitignore` does **not** ignore `*.drift.dart` (the repo commits generated code, so the CI
  freshness diff is its mitigation).

**Implementation.** `flutter pub add drift sqlite3_flutter_libs path_provider path uuid clock` and
`flutter pub add --dev drift_dev build_runner sqlite3`. Write `build.yaml` with
`targets: $default: builders: drift_dev: generate_for: ['lib/data/**']`. Mirror `**/*.drift.dart` into
the analyzer excludes. Read `.github/workflows/ci.yml` and confirm the "Generated code is up to date"
step diffs `'*.drift.dart'` and that a "Schema dumps are up to date" step diffs `drift_schemas/`; if
either is missing or the Linux job lacks `libsqlite3-dev`, add it in this task.

**Files.** `pubspec.yaml`, `pubspec.lock`, `build.yaml`, `analysis_options.yaml`,
`.github/workflows/ci.yml`, `test/policy/dependency_policy_test.dart`,
`test/policy/codegen_hygiene_test.dart`.

**Skills.** `dependency-hygiene`, `codegen-and-toolchain`, `ci-pipeline-and-gates`, `run-codegen`.

**Screenshot check.** n/a (no visual surface).

**Done when.**
- [ ] `bash .claude/skills/dependency-hygiene/scripts/audit-deps.sh` passes; the licence of every new
      package is permissive and recorded in the PR body.
- [ ] `bash .claude/skills/codegen-and-toolchain/scripts/check-codegen-hygiene.sh lib` passes.
- [ ] Both policy tests are green; `pubspec.lock` is staged in the same commit as `pubspec.yaml`.
- [ ] `ci.yml` has a `*.drift.dart` diff gate, a `drift_schemas/` diff gate, and `libsqlite3-dev`
      installed before `flutter test` on the Linux job.

**Commits.**
1. `test: extend the dependency policy with the data-layer allow-set and ban sqflite`
2. `deps: add drift, sqlite3_flutter_libs, path_provider, uuid, clock`
3. `build: fence drift_dev codegen to lib/data and exclude generated files`
4. `ci: cover *.drift.dart and drift_schemas in the freshness gates`

---

### T05.2 — Canonical value objects and the `DataFailure` family

**Goal.** Land the sealed `Result`/`Failure` spine, the pure Flutter-free types the store maps rows into,
and the one sealed failure family the data boundary returns — before any table exists, so the schema is
designed against them.

**This task owns the spine.** `lib/core/result.dart` (`sealed class Result<T, F extends Failure>` with
`final class Ok` / `final class Err` and an `extension ResultX` carrying `fold` and `map`) and
`lib/core/failure.dart` (`sealed class Failure` with `String get code`) are created here, verbatim from
`error-handling-typed-results`, with no "if E01 shipped it" conditional. E05 is the first consumer:
every repository method below returns one. E06 T06.1 adopts these files and adds
`lib/core/run_failure.dart`; if E06 finds itself writing `sealed class Result` again, that is the defect.

**Tests first (TDD).** All under `test/core/` with `package:test`, no `flutter_test` import.
- `calendar_day_test.dart` — `CalendarDay.fromLocal(DateTime)` produces the same serial for
  `2026-03-29 00:30` and `2026-03-29 23:30` in a DST-shifting zone; `CalendarDay.serial` round-trips
  through `CalendarDay.fromSerial`; `daysBetween` is symmetric in magnitude and signed by order; the
  epoch day is `0`. Rounding golden: the first and last instant of a local day map to one serial.
- `result_test.dart` — `fold` maps `Ok` through `onOk` and `Err` through `onErr`, both arms asserted with
  no `default:`; `map` transforms an `Ok` value and passes the **identical** `Err` instance through;
  a `switch` over `Ok`/`Err` compiles without a wildcard, so adding a variant breaks the build.
- `run_metric_test.dart` — `RunMetric.points(1480).isBetterThan(RunMetric.points(1310))` is true;
  `RunMetric.duration(18600).isBetterThan(RunMetric.duration(21400))` is true (lower wins);
  comparing two different `ScoreFormat`s returns a `ScoreFormatMismatch` value, never a throw (total
  function rule).
- `run_record_test.dart` — `accuracy` of 46 correct / 4 wrong is `0.92`; `accuracy` with zero answered
  is `null`, not `NaN`; `averageReaction` of `totalReactionMs: 32000` over 50 answered is
  `Duration(milliseconds: 640)`; `==`/`hashCode` are identity-on-`id`, so two records with the same id
  and different scores are equal (explicit stable identity).
- `data_failure_test.dart` — every `DataFailure` leaf exposes a stable `code`
  (`data.store_unavailable`, `data.constraint_violated`, `data.run_already_recorded`,
  `data.not_found`, `data.corrupt_row`); the set of codes is asserted against a frozen literal list so
  renaming one is a test failure; no leaf carries a user-facing string.

**Implementation.** `lib/core/result.dart` and `lib/core/failure.dart` (the spine, above);
`lib/core/calendar_day.dart` (serial computed as
`DateTime.utc(local.year, local.month, local.day).millisecondsSinceEpoch ~/ 86400000` — the local Y/M/D
lifted into UTC midnight, which is what makes it DST-proof);
**`lib/core/score_format.dart` — `enum ScoreFormat { points, duration }`, the one score vocabulary in
the project**; `lib/core/run_metric.dart` (a `final class RunMetric` holding `format` + `value`, with
`isBetterThan` returning a sealed comparison outcome); `lib/core/run_draft.dart` (what E06 hands the
repository: `gameId`, `difficultyId`, `clientRunKey`, `playedOnDay`, `durationMs`, `format`, `value` and
the four counters — no id, no timestamps, those are the repository's to stamp); `lib/core/run_record.dart`;
`lib/core/run_scope.dart` (`gameId` + nullable `difficultyId`, both `String`, value equality — the family
key for scoped streams); `lib/core/game_stats.dart`; `lib/core/streak_status.dart`;
`lib/data/data_failure.dart` (`sealed class DataFailure extends Failure` with `final class` leaves,
`const` ctors, typed params).

**One score vocabulary, decided here.** E06 T06.3 would otherwise declare
`enum ScoreFormat { points, duration }` for `GameDefinition.scoreFormat` while this file declares
`enum MetricKind { points, durationMs }` for the persisted column — two enums for one concept, one
rename away from a silent mismatch on the single column that decides MAX versus MIN. **Decision:
`ScoreFormat` only.** `MetricKind` does not exist. E05 lands first and owns the file; E06 T06.3 imports
it. The `runs` CHECK is therefore `IN ('points','duration')`, mirroring `ScoreFormat.name`.

**`AppSettings` is E04's file, not this one.** E04 T04.4 ships `lib/core/app_settings.dart` with the four
booleans (`isSoundEnabled`, `isHapticsEnabled`, `isReduceMotionEnabled`, `isColourBlindPalette`) behind
an in-memory notifier. T05.4 re-points that notifier at `SettingsRepository.watch()`; this task neither
creates nor renames the value type.

**Files.** `lib/core/result.dart`, `lib/core/failure.dart`, `lib/core/calendar_day.dart`,
`lib/core/score_format.dart`, `lib/core/run_metric.dart`, `lib/core/run_draft.dart`,
`lib/core/run_record.dart`, `lib/core/run_scope.dart`, `lib/core/game_stats.dart`,
`lib/core/streak_status.dart`, `lib/data/data_failure.dart`, and their mirrors under `test/core/` and
`test/data/`.

**Skills.** `dart3-idioms-and-coding-standards`, `value-objects-money-and-units`,
`seeded-determinism-and-golden-vectors`, `error-handling-typed-results`, `naming-conventions`,
`dartdoc-conventions`, `project-structure-and-packages`.

**Screenshot check.** n/a (no visual surface).

**Done when.**
- [ ] Nothing under `lib/core/` imports `package:flutter`, `dart:io`, `package:drift` or calls
      `DateTime.now()`.
- [ ] Every public symbol carries a `///` that names its unit and its invariant; `flutter analyze
      --fatal-infos` is clean with `public_member_api_docs` at error.
- [ ] `bash .claude/skills/dart3-idioms-and-coding-standards/scripts/check-dart3-idioms.sh lib` passes.

**Commits.**
1. `test: specify the Result and Failure spine`
2. `core: add the sealed Result and Failure spine`
3. `test: specify CalendarDay, ScoreFormat, RunMetric and RunRecord invariants`
4. `core: add CalendarDay, ScoreFormat, RunMetric and the run value objects`
5. `test: freeze the DataFailure code list`
6. `data: add the sealed DataFailure family`

---

### T05.3 — `AppDatabase`, the connection, and schema v1

**Goal.** Create the database class, the `LazyDatabase` connection with per-connection pragmas, and the
two STRICT tables with every invariant the storage layer can enforce.

**Tests first (TDD).** `test/data/db/app_database_schema_test.dart`, all against `NativeDatabase.memory()`
with `addTearDown(db.close)`.
- `sqlite_master` reports `STRICT` on both `runs` and `settings`.
- Inserting a run with `duration_ms = -1`, `score`/`metric_value < 0`, `longest_combo > correct_count`,
  an empty `game_id`, an empty `difficulty_id`, or `metric_kind = 'elo'` each throws `SqliteException` —
  five separate expectations, each naming the constraint it proves.
- Inserting a second `settings` row with `id = 'preferences'` throws (`CHECK (id = 'app')`).
- Inserting two runs with the same `client_run_key` throws; soft-deleting the first
  (`is_deleted = 1`) then inserting the same key succeeds — the partial UNIQUE index, both halves.
- `PRAGMA journal_mode`, `PRAGMA foreign_keys`, `PRAGMA synchronous` and `PRAGMA busy_timeout` report
  `wal` / `1` / `2` (FULL) / `5000` on a freshly opened connection, and again after `close()` + reopen —
  the per-connection pragmas are re-asserted, not assumed.
- A fresh database has exactly one `settings` row with all four toggles at their design defaults
  (sound on, haptics on, reduce motion off, colour-blind palette off — screen 08), and reopening does
  **not** re-seed it (seeding lives only inside `if (details.wasCreated)`).

**Implementation.** `lib/data/db/tables/audit_columns.dart` — the `mixin AuditColumns on Table` from
`persistence-drift` (text UUID PK, `createdAt`/`updatedAt` UTC ms, `rowRevision`, `isDeleted`,
`deletedAt`). `lib/data/db/tables/runs.dart` and `lib/data/db/tables/settings.dart`.
`lib/data/db/app_database.dart` (`@DriftDatabase`, `schemaVersion => 1`, `MigrationStrategy` with
`onCreate: m.createAll()`, `beforeOpen` re-asserting `foreign_keys` and seeding under `wasCreated`).
`lib/data/db/connection.dart` — `LazyDatabase` over `NativeDatabase.createInBackground` in the
application **support** directory (not Documents), `setup:` executing `journal_mode = WAL`,
`synchronous = FULL`, `foreign_keys = ON`, `busy_timeout = 5000`.

`runs` columns and the decision per field:

| Column | Type | Decision |
|---|---|---|
| `game_id` | TEXT | `CHECK (length(game_id) BETWEEN 1 AND 64)` — a **shape** check only. The set of game ids is registry data owned by `GameDefinition` (E06); a `CHECK … IN` here would turn shipping a third game into a needless migration. The repository rejects an unregistered id with `Err`. |
| `difficulty_id` | TEXT | same reasoning — shape `CHECK` only; per-game difficulty lists are registry data. |
| `client_run_key` | TEXT | idempotency key minted by E06 per run. Partial `UNIQUE INDEX … WHERE is_deleted = 0`. |
| `started_at_utc_ms` | INTEGER | true instant, UTC epoch ms. `CHECK (> 0)`. |
| `played_on_day` | INTEGER | **local** serial day. Distinct from the instant on purpose: it is the day boundary the streak and the "played today" check both read. Never a `DateTime`. |
| `duration_ms` | INTEGER | wall-clock length of the run; the source of "Time trained". `CHECK (>= 0)`. |
| `metric_kind` | TEXT | `CHECK (metric_kind IN ('points','duration'))` — mirrors `ScoreFormat.name` exactly (T05.2: there is one score enum, not a `MetricKind` beside it). This one **is** a closed `CHECK … IN` because the data layer itself interprets it to decide MAX vs MIN. A test asserts the CHECK list equals `ScoreFormat.values.map((f) => f.name)`, so adding a third format is a migration rather than a silent constraint violation. |
| `metric_value` | INTEGER | the number the game scores by. `CHECK (>= 0)`. Stamped per run so a later scoring change leaves old rows interpretable. |
| `correct_count`, `wrong_count`, `longest_combo` | INTEGER | `CHECK (>= 0)` each, plus `CHECK (longest_combo <= correct_count)`. |
| `total_reaction_ms` | INTEGER | the **sum**, not the average. `CHECK (>= 0)`. Average reaction is derived on read so no rounded double is ever stored. |
| accuracy | — | **not stored.** Derived: `correct / (correct + wrong)`. |
| personal best | — | **not stored.** Derived: MAX/MIN of `metric_value` by `metric_kind` (T05.7). |
| aggregates | — | **not stored.** Derived: `COUNT(*)`, `SUM(duration_ms)` folds (T05.7). |
| daily streak | — | **not stored.** Derived: a fold over distinct `played_on_day` (T05.8). |

No foreign key exists at v1, because no cross-table relation exists at v1 — inventing a `games` table
would create a second authority for game identity against the code registry. `foreign_keys = ON` and a
`PRAGMA foreign_key_check` assertion ship anyway so the first relation added is enforced from the day
it lands. Soft-delete columns come from `AuditColumns` and no delete UI ships in E05; every read filters
`is_deleted = 0` through one shared base-query helper so the first delete cannot regress a read.

**Files.** `lib/data/db/app_database.dart`, `lib/data/db/connection.dart`,
`lib/data/db/tables/{audit_columns,runs,settings}.dart`, `lib/data/db/app_database.drift.dart`
(generated, committed), `test/data/db/app_database_schema_test.dart`.

**Skills.** `persistence-drift`, `dartdoc-conventions`, `naming-conventions`, `run-codegen`,
`testing-strategy`.

**Screenshot check.** n/a (no visual surface).

**Done when.**
- [ ] `dart run build_runner build --delete-conflicting-outputs` then `flutter analyze --fatal-infos`
      is clean, in that order.
- [ ] Every constraint above has a test that proves SQLite rejects the bad row — not a Dart guard.
- [ ] `bash .claude/skills/persistence-drift/scripts/check-persistence-bans.sh lib` passes and reports
      all three pragmas configured.
- [ ] `bash .claude/skills/persistence-drift/scripts/check-drift-confinement.sh lib` passes.

**Commits.**
1. `test: specify schema v1 constraints, pragmas and seeding`
2. `data: add the AuditColumns mixin and the runs and settings tables`
3. `data: open the database with WAL, FULL sync and foreign keys per connection`
4. `chore: regenerate drift output for schema v1`

---

### T05.4 — `SettingsDao` and `SettingsRepository`

**Goal.** Ship the simplest complete vertical — table to value object to `Result` to watched stream —
so the pattern every later repository copies is settled and reviewed on four booleans.

**Tests first (TDD).** `test/data/daos/settings_dao_test.dart` and
`test/data/repositories/settings_repository_test.dart`, both on `NativeDatabase.memory()`.
- `watch()` emits the seeded defaults immediately on subscribe.
- `update(settings.copyWith(isSoundEnabled: false))` resolves **after** the row is durable: reading the
  raw row inside the returned `Future`'s `then` already shows `0`.
- The `.watch()` stream re-emits the new value with no manual republish — assert the stream emits
  exactly twice (`emitsInOrder`), proving persist-before-publish rather than an optimistic push.
- `update` bumps `row_revision` by exactly 1 and stamps `updated_at` from the injected `Clock`, not the
  wall clock: with `Clock.fixed(2026-08-19T10:00Z)` the stored `updated_at` equals that instant exactly.
- A DAO forced to fail (open the DB, `close()` it, then call `update`) returns
  `Err(StoreUnavailable())`, never throws, and the original `SqliteException` is logged before the
  return.
- The returned `Result` is switched exhaustively in the test with no `default:` — a compile-time proof
  the family is sealed.

**Implementation.** `lib/data/daos/settings_dao.dart` (`@DriftAccessor(tables: [SettingsTable])`,
single-table queries only, rows mapped to **E04's `AppSettings`** from `lib/core/app_settings.dart` — the
same four fields with the same names, not a new type). Re-point E04's `AppSettingsNotifier.build()` at
`settingsRepositoryProvider.watch()` in the same commit, leaving `hapticsEnabledProvider`,
`soundEnabledProvider` and `MotionPreferenceScope`'s read and mounting point untouched: that is the whole
point of E04 having used this value type in memory first.
`lib/data/repositories/settings_repository.dart`
— constructor takes `AppDatabase`, `SettingsDao` and `Clock`; `Stream<AppSettings> watch()`;
`@useResult Future<Result<AppSettings, DataFailure>> update(AppSettings)` wrapping one `db.transaction`
with the shared write wrapper that stamps `updatedAt`/`rowRevision`. Narrow `on SqliteException` catch,
log `(e, st)` first, then return the typed `Err`.

**Files.** `lib/data/daos/settings_dao.dart`, `lib/data/repositories/settings_repository.dart`,
`lib/data/db/write_stamp.dart` (the one shared `updatedAt`/`rowRevision` wrapper),
`lib/shared/feedback/app_settings_notifier.dart` (edit — `build()` now watches the repository),
`test/data/daos/settings_dao_test.dart`, `test/data/repositories/settings_repository_test.dart`.

**Skills.** `persistence-drift`, `error-handling-typed-results`, `async-safety`, `testing-strategy`,
`service-boundary-and-native`.

**Screenshot check.** n/a (no visual surface). The four toggles and their default states come from
`design/sunburst-pop/screens/08-settings.png`; E07 compares the screen.

**Done when.**
- [ ] No Drift symbol appears in the `SettingsRepository` public signature — `AppSettings` and
      `Result<AppSettings, DataFailure>` only.
- [ ] `bash .claude/skills/error-handling-typed-results/scripts/check-swallowed-catch.sh lib` passes.
- [ ] Every query inside the transaction is awaited (analyzer `unawaited_futures` at error backs this).

**Commits.**
1. `test: specify the settings read, write and failure contract`
2. `data: add SettingsDao mapping rows to AppSettings`
3. `data: add SettingsRepository as the single settings write path`

---

### T05.5 — `RunsDao`: scoped reads, keyset pagination, and the index plan

**Goal.** Single-table queries over `runs` that are scoped, ordered, keyset-paginated, and backed by an
index proven with `EXPLAIN QUERY PLAN`.

**Tests first (TDD).** `test/data/daos/runs_dao_test.dart`.
- `watchRecent(RunScope('stroop_rush', 'classic'), limit: 7)` emits newest-first and never includes a
  run from another game, another difficulty, or a soft-deleted row — one expectation each.
- `watchRecent` with a scope whose `difficultyId` is null spans all difficulties of one game.
- `pageBefore(cursor: startedAtUtcMs, limit: 20)` returns strictly older rows, and paging twice through
  a 45-row fixture yields 45 distinct ids with no repeat and no gap (the invariant `OFFSET` breaks).
- `EXPLAIN QUERY PLAN` for the `watchRecent` query contains `USING INDEX idx_runs_game_difficulty_time`
  and does **not** contain `SCAN`; the same for the streak query against `idx_runs_day`. The assertion
  is on the plan string with the query echoed in `reason:`.
- A watch subscription cancelled in `addTearDown` leaves no pending timer — the suite runs with
  `--test-randomize-ordering-seed random` and stays green.

**Implementation.** `lib/data/daos/runs_dao.dart` — `@DriftAccessor(tables: [Runs])`;
`Stream<List<RunRecord>> watchRecent(RunScope, {required int limit})`,
`Future<List<RunRecord>> pageBefore({required int cursorStartedAtUtcMs, required int limit})`,
`Future<void> insertRun(RunsCompanion)`, plus the raw folds T05.7/T05.8 consume. One private
`_baseSelect()` that applies `is_deleted = 0` so no query can forget it, and one private `_toRecord(RunRow)`
mapper. Indexes declared on the table:
`idx_runs_game_difficulty_time (game_id, difficulty_id, started_at_utc_ms)` — equality columns lead, the
sort column trails — and `idx_runs_day (played_on_day)`.

**Files.** `lib/data/daos/runs_dao.dart`, `lib/data/db/tables/runs.dart` (indexes),
`test/data/daos/runs_dao_test.dart`, `test/support/run_fixtures.dart` (a seeded builder that produces a
deterministic run set from an integer seed — no ambient `Random`).

**Skills.** `persistence-drift`, `testing-strategy`, `seeded-determinism-and-golden-vectors`,
`async-safety`, `naming-conventions`.

**Screenshot check.** n/a (no visual surface).

**Done when.**
- [ ] No `OFFSET` anywhere — `check-persistence-bans.sh` proves it.
- [ ] Both `EXPLAIN QUERY PLAN` assertions are green; adding a query without an index fails the suite.
- [ ] `RunsDao` returns `RunRecord`, never a generated row type.

**Commits.**
1. `test: specify scoped run reads, keyset paging and the query plan`
2. `data: add the runs indexes for scoped reads and the streak fold`
3. `data: add RunsDao with scoped watches and keyset pagination`

---

### T05.6 — `RunRepository.saveRun`: the single write path

**Goal.** One method, one transaction, idempotent, returning the durable `RunRecord` **and whether it is
a personal best** — or a typed `DataFailure` — and proven to leave nothing partial behind when it fails.

**The name and the payload, decided here.** E06 T06.8, E07 T07.8 and E09 T09.3 all call
`runRepositoryProvider.saveRun(...)`; this epic owns the write path, so the method is **`saveRun`**, not
`record`. And it returns `Result<RunCommit, DataFailure>` where
`final class RunCommit { final RunRecord record; final bool isPersonalBest; }` — not a bare `RunRecord`.
The reason is not convenience: E06's `RunNotifier` persists *then* transitions to `over`, and E07's
results screen renders the personal-best badge from the committed row. `isPersonalBest` therefore has to
be computed against the pre-write best **inside the same `db.transaction`** as the insert, or two runs
finishing close together can both claim the badge. A caller that instead reads `watchPersonalBest` after
the commit is racing its own write.

**Tests first (TDD).** `test/data/repositories/run_repository_save_test.dart`.
- `saveRun(draft)` returns `Ok(RunCommit)` whose `record.id` came from the injected `FakeIdGenerator` and
  whose `createdAt` came from `Clock.fixed(...)` — not the wall clock.
- `isPersonalBest` is true when the draft beats every prior run in its scope and false when it does not —
  asserted for both directions of `ScoreFormat` (higher wins for `points`, lower for `duration`), and
  **true for the first run in a scope**, which is the case a naive `> currentBest` on a null best gets
  wrong.
- `isPersonalBest` is computed inside the transaction — assert by inserting a better run from a second
  connection between the guard and the commit is impossible: the test opens one connection and asserts
  the read and the insert share a transaction id, or, more simply, that the returned flag matches a
  `watchPersonalBest` read taken **after** the commit for every row in a 200-run seeded fixture.
- The returned `Future` resolves only after commit: reading the row directly in the same tick already
  finds it, and `watchRecent` emits the new run without any manual republish (assert two emissions in
  order).
- Recording the same `clientRunKey` twice returns `Err(RunAlreadyRecorded(key))` on the second call,
  leaves exactly one row, and leaves that row's `row_revision` and `updated_at` **unchanged** — the
  idempotency guarantee, both halves.
- A draft violating `longest_combo <= correct_count` returns `Err(ConstraintViolated('longest_combo'))`
  and the table is byte-identical afterwards: same row count, same `row_revision` on every pre-existing
  row.
- A draft naming an unregistered `gameId` returns `Err(NotFound(gameId))` from the repository's own
  guard, before any SQL runs.
- `test/data/db/transaction_rollback_test.dart` — the guarantee `saveRun` rests on, asserted directly on
  `AppDatabase`: one `db.transaction` inserting a valid run then a CHECK-violating run throws, and
  afterwards `SELECT COUNT(*) FROM runs` is `0`. Written against real SQLite, no fake.
- Exhaustive `switch` over the returned `Result` with no `default:`.

**Implementation.** `lib/data/repositories/run_repository.dart` — constructor takes `AppDatabase`,
`RunsDao`, `Clock` and `IdGenerator`. `lib/core/run_commit.dart` holds
`@immutable final class RunCommit { final RunRecord record; final bool isPersonalBest; }`.
`@useResult Future<Result<RunCommit, DataFailure>> saveRun(RunDraft)`:
validate the draft against the injected registry-id predicate, then one `db.transaction` that reads the
current best for the draft's scope, inserts the row (every query awaited), re-reads it, and returns
`RunCommit(record, isPersonalBest)` — the comparison uses `RunMetric.isBetterThan`, so the MAX/MIN
direction lives in exactly one place. Narrow
`on SqliteException` catch mapping constraint codes to `ConstraintViolated`/`RunAlreadyRecorded`, logging
`(e, st)` before returning. `lib/core/id_generator.dart` — `abstract interface class IdGenerator` with
`String newId()`; `lib/data/uuid_id_generator.dart` — the live UUID v7 impl; `test/support/fake_id_generator.dart`
— a counting fake. The seam exists because a random id makes every repository assertion unwritable; that
is the named thing it buys.

**Files.** `lib/data/repositories/run_repository.dart`, `lib/core/run_commit.dart`,
`lib/core/id_generator.dart`, `lib/data/uuid_id_generator.dart`,
`test/data/repositories/run_repository_save_test.dart`,
`test/data/db/transaction_rollback_test.dart`, `test/support/fake_id_generator.dart`.

**Skills.** `persistence-drift`, `error-handling-typed-results`, `service-boundary-and-native`,
`async-safety`, `testing-strategy`, `flutter-architecture`.

**Screenshot check.** n/a (no visual surface).

**Done when.**
- [ ] `saveRun` is exactly one `db.transaction`, and the personal-best read happens inside it; no query inside it is unawaited.
- [ ] No `DateTime.now()` and no bare `Uuid().v7()` call site outside `UuidIdGenerator`.
- [ ] `check-swallowed-catch.sh` and `check-determinism-bans.sh` both pass on `lib`.

**Commits.**
1. `test: specify the run write path, idempotency and rollback`
2. `core: add the IdGenerator seam and its UUID v7 implementation`
3. `data: add RunRepository.saveRun as the single run write path, returning RunCommit`

---

### T05.7 — Derived reads: personal best and per-game/per-difficulty aggregates

**Goal.** Personal best and the stats numbers as folds over `runs`, recomputed on read, exposed as
scoped `.watch()` streams — no second authority anywhere.

**Tests first (TDD).** `test/data/repositories/run_repository_stats_test.dart` and
`test/core/aggregate_property_test.dart`.
- `watchPersonalBest(RunScope('stroop_rush','classic'))` returns MAX(`metric_value`) for
  `ScoreFormat.points`; `watchPersonalBest(RunScope('schulte_grid','classic'))` returns MIN for
  `ScoreFormat.duration`. Both assert the direction explicitly.
- Personal best over an empty scope is `null`, not `0` — a zero would render as a real BEST pill.
- `watchBestsByGame()` returns one entry per game id that has any run, keyed by `gameId`, with `null`
  for a game that has none — **the all-games fold Home's BEST pills need**. Asserted with three games in
  the fixture and one of them run-free. This is the only read E07's `HomeNotifier` cannot build out of
  the scoped ones without an N+1 of stream subscriptions, and it is the reason there is no separate
  `StatsRepository`: everything the stats screen and the home hub need is a fold over `runs`, and a
  second repository over the same table would be a second authority.
- Recording a better run makes the best stream re-emit; recording a worse run does **not** re-emit a
  changed value (the stream is scoped and the fold is stable).
- Mixed `metric_kind` rows inside one scope surface `Err(CorruptRow)` rather than silently comparing
  points against milliseconds.
- **Property test, seeded fuzz, 500 seeds:** for a random run set, `gamesPlayed` equals the list length,
  `timeTrained` equals the sum of `duration_ms`, and `best` equals the extremum computed by an
  independent Dart oracle (`list.map(...).reduce(...)`) — never by the SQL under test. The seed, the run
  count and the generated values are echoed in `reason:` so a failure is its own repro.
- **Property test:** accuracy is always in `[0.0, 1.0]` and `null` exactly when nothing was answered;
  `averageReaction` is `null` exactly when nothing was answered (no division by zero, no `NaN`).
- `test/data/reference_fixture_test.dart` — the design-numbers gate. A fixture run set produces exactly
  the values printed on the reference screens: `Your best 1,480` and `Games played 128` (screen 02),
  `Accuracy 92%`, `Avg reaction 640ms`, `Longest streak x11` (screen 06), `Best score 1,480`,
  `Best time 18.6s`, `Games played 128`, `Time trained 3h 12m` and a 7-element `Last 7 runs` series
  (screen 07). This is how a data-layer task is held to a screenshot without rendering a pixel.

**Implementation.** Add to `lib/data/daos/runs_dao.dart` the folds: `watchBest(RunScope)`,
`watchBestsByGame()` (one `GROUP BY game_id` query, not a fan-out of per-game streams),
`watchAggregate(RunScope)` (`COUNT(*)`, `SUM(duration_ms)`, `SUM(correct_count)`, `SUM(wrong_count)`,
`SUM(total_reaction_ms)`, `MAX(longest_combo)`), `watchLastN(RunScope, int n)` for the chart series. Add
to `lib/data/repositories/run_repository.dart`: `Stream<RunMetric?> watchPersonalBest(RunScope)`,
**`Stream<Map<String, RunMetric?>> watchBestsByGame()`**, `Stream<GameStats> watchStats(RunScope)`,
`Stream<List<RunRecord>> watchChartSeries(RunScope, {int count = 7})`. Derivation lives in
`lib/core/game_stats.dart` as pure getters so the property tests run under `package:test` with no
database.

**There is no `StatsRepository`.** E07's inherited-symbols table asks for one; this is the answer. Home,
game detail, results and stats all read folds over the single `runs` table, and `RunRepository` is that
table's single source of truth. A second repository would be a second authority over one table — the
exact thing `flutter-architecture` forbids. E07 T07.5's `HomeNotifier` reads `allBestsProvider` (T05.9),
and T07.9's `StatsNotifier` reads `runStatsProvider`/`chartSeriesProvider`.

**Files.** `lib/data/daos/runs_dao.dart`, `lib/data/repositories/run_repository.dart`,
`lib/core/game_stats.dart`, `test/data/repositories/run_repository_stats_test.dart`,
`test/core/aggregate_property_test.dart`, `test/data/reference_fixture_test.dart`.

**Skills.** `persistence-drift`, `testing-strategy`, `dart3-idioms-and-coding-standards`,
`value-objects-money-and-units`, `flutter-architecture`.

**Screenshot check.** n/a (no visual surface) — but `test/data/reference_fixture_test.dart` is the
equivalent: it asserts the exact figures rendered in `design/sunburst-pop/screens/02-game-detail.png`,
`06-results.png` and `07-stats.png`. If a number there is unreachable from the schema, the schema is
wrong and this task fixes it; if the reference figure is itself inconsistent, edit `app.html`, re-run
`./capture-screens.sh` and commit that as a deliberate design change.

**Done when.**
- [ ] No table, column or cached field stores a best, a count or a total.
- [ ] The fuzz loop runs 500 seeds against an independent oracle and echoes the seed in `reason:`.
- [ ] The reference-fixture test reproduces every figure on screens 02, 06 and 07.

**Commits.**
1. `test: specify personal best direction, the all-games fold and aggregate folds`
2. `data: derive personal best, bests-by-game and per-scope aggregates on read`
3. `test: pin the aggregate maths with a seeded property test`
4. `test: reproduce the reference screen figures from a run fixture`

---

### T05.8 — The daily streak, driven by the injected `Clock`

**Goal.** A pure `StreakCalculator` over distinct local serial days, and a repository stream whose
"today" comes from the injected `Clock` — never `DateTime.now()`.

**Tests first (TDD).** `test/core/streak_calculator_test.dart` (pure, `package:test`) and
`test/data/repositories/run_repository_streak_test.dart` (`ProviderContainer` + in-memory DB).
- Days `[d, d-1, d-2, d-3]` with today `d` give `currentDays: 4`, matching the `4 day streak` chip on
  screen 01.
- Today `d+1` with the same history gives `currentDays: 4` and `isActiveToday: false` — a streak
  survives until the day after the gap opens.
- Today `d+2` gives `currentDays: 0` and `longestDays: 4` — broken, but the record stands.
- Two runs on the same day count once (distinct days).
- An empty history gives `currentDays: 0`, `longestDays: 0`, `isActiveToday: false` — never `null`,
  never a throw (total function).
- Seeded fuzz over random day sets: `currentDays <= longestDays <= distinctDayCount` always, seed echoed
  in `reason:`.
- **The clock test.** Two `ProviderContainer`s over the *same* fixture, one with
  `clockProvider.overrideWithValue(Clock.fixed(day))`, one with `Clock.fixed(day + 2 days)`, produce
  `currentDays: 4` and `currentDays: 0` respectively. Since the only difference is the injected clock,
  a `DateTime.now()` anywhere in the path makes this test fail. Backed by
  `check-determinism-bans.sh lib` as the static half.

**Implementation.** `lib/core/streak_calculator.dart` — `final class StreakCalculator` with
`StreakStatus compute({required List<CalendarDay> playedDays, required CalendarDay today})`; pure, total,
takes `today` as a parameter so it holds no clock at all. `RunRepository.watchStreak()` reads distinct
`played_on_day` values via `RunsDao.watchPlayedDays()` and maps them through the calculator with
`CalendarDay.fromLocal(_clock.now())`. One day definition — the same `CalendarDay` — serves the streak,
"played today" and the chart.

**Files.** `lib/core/streak_calculator.dart`, `lib/data/daos/runs_dao.dart` (`watchPlayedDays`),
`lib/data/repositories/run_repository.dart` (`watchStreak`),
`test/core/streak_calculator_test.dart`, `test/data/repositories/run_repository_streak_test.dart`.

**Skills.** `seeded-determinism-and-golden-vectors`, `service-boundary-and-native`, `testing-strategy`,
`dart3-idioms-and-coding-standards`, `persistence-drift`.

**Screenshot check.** n/a (no visual surface). The `4 day streak` figure on
`design/sunburst-pop/screens/01-home.png` is asserted as a value in the calculator test; E07 compares
the chip itself.

**Done when.**
- [ ] `StreakCalculator` imports nothing but `package:meta` and the `lib/core/` value objects.
- [ ] The two-container clock test is green and would fail if `clock.now()` were replaced with
      `DateTime.now()` — verify by making that edit locally, watching it go red, and reverting.
- [ ] `bash .claude/skills/seeded-determinism-and-golden-vectors/scripts/check-determinism-bans.sh lib`
      passes.

**Commits.**
1. `test: specify streak continuation, breakage and clock dependence`
2. `core: add the pure StreakCalculator over local serial days`
3. `data: expose watchStreak driven by the injected Clock`

---

### T05.9 — Riverpod wiring and the composition-root override

**Goal.** Expose the store through providers — a throwing `appDatabaseProvider` seam, plain `Provider`
DI for the repositories, scoped `StreamProvider.autoDispose.family` reads — and wire the one live
instance at the composition root.

**Tests first (TDD).** `test/data/data_providers_test.dart`.
- Reading `appDatabaseProvider` without an override throws `UnimplementedError` with a message naming
  the file to fix — a forgotten wiring must fail loudly, not construct a real DB inside a test.
- With `appDatabaseProvider.overrideWithValue(AppDatabase(NativeDatabase.memory()))` and
  `clockProvider.overrideWithValue(Clock.fixed(...))`, `runStatsProvider(RunScope(...))` emits
  `AsyncData<GameStats>` with the fixture's numbers.
- Two reads of `runStatsProvider` with the *same* `RunScope` return the same provider instance (value
  equality on the family key); two different scopes do not share state.
- Disposing the container cancels the underlying `.watch()` subscription — the test ends with no
  pending timer under `--test-randomize-ordering-seed random`.
- `test/policy/provider_shapes_test.dart` — greps `lib/` for `StateProvider`, `StateNotifierProvider`,
  `ChangeNotifierProvider`, `get_it` and `package:provider` and asserts none appear.

**Implementation.** `lib/data/data_providers.dart` — `appDatabaseProvider` (throwing seam),
`idGeneratorProvider`, `settingsDaoProvider`, `runsDaoProvider`, `settingsRepositoryProvider`,
`runRepositoryProvider`, and the reads `settingsProvider`, `personalBestProvider(RunScope)`,
**`allBestsProvider`** (over `watchBestsByGame()` — the one Home's BEST pills need, unscoped and
therefore not a `family`), `runStatsProvider(RunScope)`, `chartSeriesProvider(RunScope)`,
`streakProvider`. `autoDispose` and
`family` used as modifiers only, never as base classes. Add the single
`appDatabaseProvider.overrideWithValue(...)` line to the composition root E01 produced
(`lib/bootstrap.dart` if it exists, otherwise `lib/main.dart`), with `ref.onDispose(db.close)` owning
teardown. `clockProvider` self-defaults to `const Clock()` and needs no override outside tests.

**Files.** `lib/data/data_providers.dart`, `lib/bootstrap.dart` or `lib/main.dart` (one override),
`test/data/data_providers_test.dart`, `test/policy/provider_shapes_test.dart`.

**Skills.** `state-management-riverpod`, `service-boundary-and-native`, `flutter-architecture`,
`project-structure-and-packages`. E05 adds one override line to the existing composition root and does
not reorder `main()` — the startup sequence stays E01's.

**Screenshot check.** n/a (no visual surface).

**Done when.**
- [ ] `bash .claude/skills/state-management-riverpod/scripts/ban-legacy-providers.sh lib` passes.
- [ ] No DAO is exposed through a provider; only repositories and their derived streams are.
- [ ] `bash .claude/skills/flutter-architecture/scripts/check_architecture.sh lib` and
      `bash .claude/skills/project-structure-and-packages/scripts/check_import_boundaries.sh lib` pass.

**Commits.**
1. `test: specify the database seam and scoped stream providers`
2. `data: add the data-layer provider graph`
3. `app: override the database seam at the composition root`

---

### T05.10 — Schema snapshot v1, the migration harness, and the restore path

**Goal.** Commit the v1 schema snapshot, generate era-correct classes, and prove the migration machinery
end to end — including the restore path that only runs when something has already gone wrong.

**Tests first (TDD).** `test/data/migration/schema_v1_test.dart` and
`test/data/migration/snapshot_restore_test.dart`.
- **Version guard:** `AppDatabase(NativeDatabase.memory()).schemaVersion == kLatestSchemaVersion` and a
  snapshot file exists for every version `1..kLatestSchemaVersion`. Bumping the version without dumping
  the snapshot fails here as well as in CI.
- **Content round-trip at v1, hostile fixture:** write rows through the generated `DatabaseAtV1` using
  `schema.newConnection()` — `game_id` values with an apostrophe, an em dash, non-ASCII and a
  whitespace-only `client_run_key` where the schema allows it — then reopen the same bytes as
  `AppDatabase`, run `verifier.migrateAndValidate(db, 1)`, and read back with the v1-era classes.
  Assert per key (never per list index), with a `reason:` on every `expect`, that every value survived
  byte for byte.
- `PRAGMA integrity_check` is `ok` and `PRAGMA foreign_key_check` is empty after the open.
- **All-pairs shape loop:** the nested `for (from) for (to)` loop over `1..kLatestSchemaVersion`, present
  and correct today even though it runs zero iterations at v1 — written now so the next bump cannot
  forget a skip path. One line in the test file states plainly that it is vacuous at v1.
- **Forced mid-migration throw restores the snapshot:** `openMigratedDatabase(File)` snapshots the DB
  file and its `-wal`/`-shm` sidecars before opening, opens, and on a throw closes the dead connection,
  restores the files with nothing open, and rethrows. The test opens through a test-only subclass whose
  migration step throws, asserts the open rethrows, and asserts the file bytes and the row set are
  identical to before the attempt.

**Implementation.** Run `dart run drift_dev schema dump lib/data/db/app_database.dart drift_schemas/`,
`dart run drift_dev schema generate --data-classes --companions drift_schemas/ test/drift/generated/`
(the `--data-classes --companions` flags are load-bearing: without them only shape tests are possible),
and `dart run drift_dev schema steps drift_schemas/ lib/data/db/schema_versions.dart`. Commit all three
outputs. Add `lib/data/db/app_database_opener.dart` with `openMigratedDatabase` — snapshot before the
open, `customStatement('PRAGMA user_version;')` to force the migration to run while the file fallback
still stands, try/close/restore/rethrow, every file operation outside any live connection. Add
`kLatestSchemaVersion` next to `schemaVersion` so both tests and CI have one number to read.

**Files.** `drift_schemas/drift_schema_v1.json`, `lib/data/db/schema_versions.dart`,
`lib/data/db/app_database_opener.dart`, `test/drift/generated/**`,
`test/data/migration/schema_v1_test.dart`, `test/data/migration/snapshot_restore_test.dart`.

**Skills.** `run-migration`, `persistence-drift`, `testing-strategy`, `ci-pipeline-and-gates`,
`run-codegen`.

**Screenshot check.** n/a (no visual surface).

**Done when.**
- [ ] `dart run drift_dev schema dump lib/data/db/app_database.dart drift_schemas/` then
      `git diff --exit-code -- drift_schemas/` is clean.
- [ ] `eraseDatabaseOnSchemaChange` appears nowhere in `lib/`.
- [ ] The restore test passes and would fail if the snapshot were taken after the open — verify by
      moving the snapshot call below the `AppDatabase(...)` line locally, watching it go red, reverting.
- [ ] The version guard fails if `schemaVersion` is bumped to 2 without a `drift_schema_v2.json`.

**Commits.**
1. `test: guard the schema version against a missing snapshot`
2. `data: commit the v1 schema snapshot and era-correct test classes`
3. `test: round-trip a hostile fixture through the v1 schema`
4. `data: snapshot and restore the database file around the open`
5. `test: prove a forced mid-migration throw restores the snapshot`

## Gates that must pass

```bash
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs   # ALWAYS before analyze
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos --fatal-warnings
flutter test --test-randomize-ordering-seed random --reporter expanded

# every skill gate, through the one runner E01 T01.8 built
bash tool/skill_gates.sh

# schema freshness — must produce no diff
dart run drift_dev schema dump lib/data/db/app_database.dart drift_schemas/
git diff --exit-code -- drift_schemas/
git diff --exit-code -- '*.drift.dart'

# data-layer gates
bash .claude/skills/persistence-drift/scripts/check-drift-confinement.sh              lib
bash .claude/skills/persistence-drift/scripts/check-persistence-bans.sh               lib
bash .claude/skills/error-handling-typed-results/scripts/check-swallowed-catch.sh     lib
bash .claude/skills/error-handling-typed-results/scripts/check-softdelete-parity.sh   lib
bash .claude/skills/seeded-determinism-and-golden-vectors/scripts/check-determinism-bans.sh lib
bash .claude/skills/state-management-riverpod/scripts/ban-legacy-providers.sh         lib
bash .claude/skills/flutter-architecture/scripts/check_architecture.sh                lib
bash .claude/skills/project-structure-and-packages/scripts/check_import_boundaries.sh lib
bash .claude/skills/project-structure-and-packages/scripts/check_structure.sh         lib
bash .claude/skills/dart3-idioms-and-coding-standards/scripts/check-dart3-idioms.sh   lib
bash .claude/skills/codegen-and-toolchain/scripts/check-codegen-hygiene.sh            lib
bash .claude/skills/testing-strategy/scripts/check_test_hygiene.sh                    lib test
bash .claude/skills/dependency-hygiene/scripts/audit-deps.sh
bash .claude/skills/ci-pipeline-and-gates/scripts/banned-strings.sh
```

The block above is this epic's **named spot-checks**, run individually so a failure names itself.
`bash tool/skill_gates.sh` is the authoritative sweep — never a
`for s in .claude/skills/*/scripts/*.sh` loop, which cannot exit 0. This epic creates `lib/core/`, so
**move `check-determinism-bans.sh` from its `lib` argument note in `tool/skill_gates.sh` to whichever
row now reflects reality** and record the change; the five `sunburst-*` gates and
`check_palette_contrast.sh` are unaffected because E05 touches no theme file.

## Risks and open questions

- **E05 owns the `Result`/`Failure` spine, not E01.** E01's nine tasks stop at bootstrap and CI; it
  ships no `lib/core/result.dart`. E05 is the first consumer — every repository method returns one — so
  **T05.2 creates `lib/core/result.dart` and `lib/core/failure.dart` outright**, per
  `error-handling-typed-results`, with no conditional. E06 T06.1 adopts them and extends the taxonomy
  with `lib/core/run_failure.dart`; a second spine is the failure mode, and two hedged "whichever epic
  lands first owns it" clauses are not an owner. `clockProvider` likewise lands here (T05.6) if E01 did
  not need it. Do not restructure anything E01 shipped.
- **`lib/core/` is already in `CLAUDE.md`.** E01 T01.5 amended the layout block once, adding `core/`,
  `shared/motion/` and `l10n/`, and `test/policy/project_structure_test.dart` reads that block. **Do not
  propose the amendment again in this PR** — the pure value objects, `StreakCalculator` and the
  `IdGenerator` interface go in `lib/core/` as the sanctioned pure-foundation layer
  (`project-structure-and-packages` rule 7) with no further ceremony.
- **No foreign key exists at schema v1.** Two independent tables, no relation. Inventing a `games` table
  to manufacture one would create a second authority for game identity against the E06 registry.
  **Decision:** ship without an FK, keep `foreign_keys = ON` and the `foreign_key_check` assertion so the
  first relation is enforced the day it lands, and say so in the PR body rather than quietly omitting it.
- **The migration test at v1 is a round-trip, not a v1→v2 upgrade.** There is no shipped prior version to
  migrate from, and a green test that proves nothing is worse than an admitted gap
  (`testing-strategy` rule 11). **Decision:** T05.10 delivers the harness, the hostile-fixture content
  round-trip, the all-pairs loop (vacuous today, correct forever) and the restore proof; the first real
  from→to content test lands with the first real bump, most likely the `locale_tag` column in E10.
- **`flutter test` runs in a plain Dart VM where `sqlite3_flutter_libs` does nothing.** macOS falls back
  to the system `libsqlite3` — a real version-skew risk against the FFI library shipped on device, and
  `STRICT` tables need SQLite ≥ 3.37. **Decision:** T05.3 asserts `sqlite_version()` ≥ 3.37 in the suite
  so a stale host fails loudly, and T05.1 confirms the Linux CI job installs `libsqlite3-dev`.
- **`metric_kind` is stamped per run from the E06 registry, which does not exist yet.** T05.6's
  registry-id guard therefore takes an injected predicate rather than importing a registry.
  **Decision:** ship the predicate seam; E06 supplies the real one. The *value* is not a risk: T05.2
  fixes `ScoreFormat` as the single score enum in `lib/core/`, and E06's `GameDefinition.scoreFormat`
  imports it rather than declaring a parallel `MetricKind`.
- **`RunScope` holds plain strings; `GameId` and `Difficulty` are E06 types.** E07's screens hold the
  typed ids and call `personalBestProvider(RunScope)`, so something has to convert. **Decision:** E05
  ships `RunScope(String gameId, String? difficultyId)` — it cannot import E06 types that do not exist
  yet — and **E06 T06.3 adds the single conversion `RunScope.of(GameId, Difficulty?)` to that same
  file**, which is then the only place a typed id becomes a persisted string. No screen builds a
  `RunScope` by hand.
- **Reduce motion is both an OS signal and an app toggle.** The `settings` table stores only the user's
  toggle; the effective value is `MediaQuery.disableAnimations || settings.isReduceMotionEnabled` and is
  resolved by E04's `MotionPreferenceScope`, not here. T05.4 re-points E04's `AppSettingsNotifier` at the
  repository and changes nothing else — not the value type, not the derived providers, not where the
  scope is mounted. Flagged so nobody wires the toggle as the sole authority or forks a second settings
  value.
- **`AuditColumns` brings soft-delete columns MindForge has no UI for.** Keeping them is the house rule
  and the partial UNIQUE index depends on `is_deleted = 0`. **Decision:** keep them, filter every read
  through one `_baseSelect()` helper, and ship no delete method in E05.

## Definition of done

- [ ] All ten tasks complete, each with its tests written before its implementation and committed
      alongside the code they cover.
- [ ] `lib/data/` holds the database, connection, tables, DAOs and repositories; `lib/core/` holds the
      `Result`/`Failure` spine, `ScoreFormat` and the pure value objects and calculators; `test/`
      mirrors both 1:1.
- [ ] There is exactly one `sealed class Result` and one score enum in the repo
      (`grep -rn 'sealed class Result\|enum ScoreFormat\|enum MetricKind' lib/` returns two lines).
- [ ] `saveRun` returns `RunCommit(record, isPersonalBest)` with the flag computed inside the same
      transaction; no `StatsRepository` exists, and `watchBestsByGame()` is the all-games fold Home reads.
- [ ] `package:drift` and `package:sqlite3` are imported only under `lib/data/`; no Drift symbol appears
      in any public signature outside it; `package:sqflite` appears nowhere.
- [ ] Both tables are `STRICT`; every enumerable the data layer interprets has a `CHECK … IN`; every
      range has a `CHECK`; `ux_runs_client_key` is a partial `UNIQUE INDEX`; the pragmas are re-asserted
      on every open; seeding happens only under `if (details.wasCreated)`.
- [ ] Every mutation is exactly one `db.transaction` with every query awaited; each fallible repository
      method returns `Result<T, DataFailure>`; no recoverable failure throws across a layer.
- [ ] Personal best, aggregates and the streak are folds over `runs` — no column, table or cached field
      stores a derived value; the decision for each field is written into the schema task and the PR body.
- [ ] `test/data/reference_fixture_test.dart` reproduces every figure on screens 02, 06 and 07, and the
      streak test reproduces the `4 day streak` figure on screen 01.
- [ ] `drift_schemas/drift_schema_v1.json`, `schema_versions.dart` and `test/drift/generated/**` are
      committed and diff-clean against a fresh dump.
- [ ] `grep -rn "DateTime.now()" lib/` is empty; the two-container clock test proves the streak is driven
      by the injected `Clock`.
- [ ] `/simplify` run and its findings addressed.
- [ ] `/code-review` run and its findings addressed.
- [ ] Every command under "Gates that must pass" is green locally.
- [ ] Pushed to `epic/05-persistence-layer`; PR body states what changed, why, how it was verified,
      that no screen was compared because the epic has no visual surface (naming the fixture test that
      stands in for one), and what was deliberately left out — the FK, the `locale_tag` column, **any
      backup/export/import path (v1 ships none; E10's on-device pass records the same omission)**, any
      durable crash sink, and any run-deletion UI.
- [ ] CI green on the PR, including the `*.drift.dart` and `drift_schemas/` freshness gates.
- [ ] Merged preserving the granular commits, branch deleted, back on `main`, pulled.
