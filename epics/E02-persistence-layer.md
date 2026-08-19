# E02 · Persistence layer

| | |
|---|---|
| **Branch** | `epic/02-persistence-layer` |
| **Depends on** | E01 |
| **Unblocks** | E04, E07 |
| **Status** | Not started |

## The epic

Build `lib/data/` — the drift/SQLite store and the repositories over it — plus the pure value objects in
`lib/core/` that those repositories hand upward. Schema v1 is two STRICT tables: `runs` (one row per
completed run, the only authority for everything a player has ever done) and `settings` (one singleton
row for the four toggles on screen 08 **and the persisted locale override**). Invariants live in the
schema: `CHECK` on every enumerable and every range, an ASCII-tag shape `CHECK` on every semantic
identifier, a partial `UNIQUE INDEX` that makes recording the same run twice impossible, and
`foreign_keys`/`journal_mode`/`synchronous`/`busy_timeout` re-asserted in `setup`/`beforeOpen` on every
open. DAOs hold single-table queries and map rows to immutable value objects; `RunRepository` and
`SettingsRepository` are the single write path, each mutation exactly one `db.transaction`, each
fallible method returning `Result<T, DataFailure>`.

Everything stored is **locale-independent**: integers, UTC epoch milliseconds, local serial days and
ASCII tags. No formatted string, no localized numeral and no calendar-specific field ever reaches a
column. `1,480`, `18.6s` and `۱٬۴۸۰` are render projections E04 owns; this layer stores `1480` and
`18600`. The one string the store holds that a human ever chose is the BCP-47 `locale_tag`, and it is
validated against the supported set on read so a corrupt or withdrawn tag degrades to "follow system"
rather than throwing.

Personal bests, per-game/per-difficulty aggregates and the daily streak are **not tables**. They are
folds over `runs`, recomputed on read and exposed as scoped `.watch()` streams — the derive-don't-store
rule, applied per field and stated per field below. The epic also stands up the migration ritual at v1:
a committed `drift_schemas/drift_schema_v1.json`, era-correct generated classes, a content round-trip
test on a hostile fixture, and a snapshot-restore opener proven by a forced mid-migration throw, so the
first real schema bump in a later epic has a harness instead of a hope.

## Why we need it

E07 (Engine core) owns `RunNotifier`, the `RunPhase` machine and the injected `Clock`. When a run ends
it has a result in memory and nowhere durable to put it. Without this epic there is no BEST pill on the
home cards, no "Your best / Games played" row on game detail, no personal-best badge on results, no
stats screen at all, and no settings that survive a relaunch — and every one of those is a shipped
surface in `design/sunburst-pop/screens/`.

**It moved from fifth to second because of localization.** E04 (Localization and RTL foundation) lets
the user override the system locale in Settings, and that choice has to persist — a language picker
that forgets on relaunch is not a language picker. E04 therefore needs a durable settings row before it
can resolve a locale at all, and it needs the `locale_tag` column to exist in **schema v1** so that
shipping four locales is a string job rather than the app's first migration. The data layer is pure
Dart over drift and depends on no design layer, so nothing is lost by pulling it forward.

It also has to be right the first time. MindForge has no server, no accounts and no telemetry
(`CLAUDE.md`, hard product constraints): the on-device DB is the only copy of a player's history, and a
migration that drops rows destroys data that exists nowhere else with nobody to report it. Getting the
canonical column types, the schema-level invariants and the migration harness in before there is any
data is the only cheap moment to do it.

**iOS is the only shipping target.** Android is deferred and this epic makes no claim about it: the
`sqlite3_flutter_libs` FFI path, the application-support container and the on-simulator smoke check in
T02.9 are all stated as iOS facts, not as cross-platform parity.

## Current state

Verified by `ls`, `git log` and `xcrun simctl` at the repo root on 2026-08-19:

- **No Flutter app yet at the time of writing.** No `pubspec.yaml`, no `pubspec.lock`, no `lib/`, no
  `test/`, no `analysis_options.yaml`, no `build.yaml`, no `.github/`. The repo holds `CLAUDE.md`,
  `50-apps-challenge-slides.html`, `design/`, `epics/` and `.claude/`.
- **5 commits on `main`**, latest `ddcb79d`. `gh` authenticated, remote `git@github.com:zakariaf/mindforge.git`.
- `.claude/skills/` — 45 skills. Three of the four data-layer gate scripts exit 0 on a missing target
  (`persistence-drift/scripts/check-drift-confinement.sh`,
  `persistence-drift/scripts/check-persistence-bans.sh`,
  `error-handling-typed-results/scripts/check-swallowed-catch.sh`); the fourth,
  `seeded-determinism-and-golden-vectors/scripts/check-determinism-bans.sh`, **exits 2** — it defaults
  to `lib/core/` and needs the directory to exist. Measured across all 49 scripts, 29 fail with no
  argument, so `CLAUDE.md`'s "they all exit 0 when the target is absent" was wrong; E01 corrected the
  claim and built `tool/skill_gates.sh`, which is the only sanctioned way to run the set.
- `i18n-rtl-l10n/scripts/check_arb_parity.sh` **exits 2** while `lib/l10n/` holds only the template:
  `FAIL: no locale ARB files (app_*.arb) beside the template`. E04 ships `app_de.arb`, `app_fa.arb` and
  `app_ckb.arb` and is the epic that turns this gate on. E02 leaves it in `tool/skill_gates.sh`'s skip
  table with that reason and runs `check_i18n_bans.sh lib`, which **is** meaningful here.
- `design/sunburst-pop/` — the chosen direction. Relevant to this epic only as the source of the numbers
  the derived reads must produce: `app.html` screen 02 (`Your best 1,480`, `Games played 128`,
  difficulty segmented control `Chill / Classic / Blitz`), screen 06 (`Accuracy 92%`,
  `Avg reaction 640ms`, `Longest streak x11`, `New personal best`), screen 07 (`Best score Stroop Rush
  1,480`, `Best time Schulte Grid 18.6s`, `Games played 128`, `Time trained 3h 12m`, `Last 7 runs`) and
  screen 01 (`4 day streak`). Those are the **English** renderings; this epic stores the integers behind
  them and asserts the integers, never the strings.

**Everything E02 touches is new.** E01 landed `pubspec.yaml`, `analysis_options.yaml`, `lib/main.dart`,
`lib/bootstrap.dart`, `lib/app.dart`, the empty `lib/core/` directory, the gen-l10n wiring (`l10n.yaml`
with `nullable-getter: false`, `lib/l10n/app_en.arb`, `AppLocalizations` on `MaterialApp`), the bundled
fonts with their OFL licences registered through `LicenseRegistry`, `tool/skill_gates.sh`, the iOS
target configuration and `.github/workflows/ci.yml`.

**E01 does not ship a `Result`/`Failure` spine — it ships bootstrap, l10n wiring, the iOS target and CI
— so this epic owns it** (T02.2). E07 adopts what lands here and adds `lib/core/run_failure.dart`; it
must not define a second spine.

**E02 also owns `lib/core/app_settings.dart` outright.** Under the previous ordering, Motion and
feedback landed before persistence and shipped `AppSettings` behind an in-memory notifier that
persistence then re-pointed. That ordering is gone: E06 (Motion and feedback) now lands *after* this
epic and reads the persisted value from day one. There is no in-memory settings notifier at any point
in the build, and no re-pointing task.

Confirm with `ls lib/core/ lib/l10n/ lib/bootstrap.dart tool/skill_gates.sh` on `main` before T02.1.

**Verified toolchain (do not re-derive).** Flutter 3.44.6 stable · Dart 3.12.2 · DevTools 2.57.0 ·
Xcode 26.6 (17F113) · CocoaPods 1.15.2. Simulator runtimes: iOS 18.0, 18.6, 26.5. The canonical device
is **`MindForge iPhone 14`, UDID `C13DDC02-375D-4E1B-8F81-44EB407D09A4`, iOS 18.6** — chosen because it
is exactly 390×844 logical points, matching the reference screenshots (no iPhone 16-class simulator
does: 16 is 393×852, 16 Pro is 402×874). Boot with
`xcrun simctl boot C13DDC02-375D-4E1B-8F81-44EB407D09A4`, run with
`flutter run -d C13DDC02-375D-4E1B-8F81-44EB407D09A4`. The host `sqlite3` on this machine reports
**3.44.3**, comfortably above the 3.37 that `STRICT` tables require.

## What we will achieve

A reader can verify all of this by running the commands named:

1. `flutter test` is green, and includes a real `NativeDatabase.memory()` suite for every DAO and
   repository — no mocked DAO anywhere under `test/data/`.
2. `bash .claude/skills/persistence-drift/scripts/check-drift-confinement.sh lib` prints PASS: no file
   outside `lib/data/` imports `package:drift` or `package:sqlite3`, and `package:sqflite` appears nowhere.
3. `dart run drift_dev schema dump lib/data/db/app_database.dart drift_schemas/` followed by
   `git diff --exit-code -- drift_schemas/` produces no diff — the committed v1 snapshot matches the
   live schema.
4. `sqlite3` on a freshly created DB shows both tables declared `STRICT`, the `CHECK` list on each,
   `ux_runs_client_key … WHERE is_deleted = 0`, and the `locale_tag` shape constraint;
   `PRAGMA integrity_check` returns `ok` and `PRAGMA foreign_key_check` returns empty.
5. A `ProviderContainer` test can override `clockProvider` with `Clock.fixed(...)`, insert a fixture run
   set, and read back exactly the numbers behind screens 02, 06 and 07 — `1480`, `128`, `11520000`,
   `0.92`, `640`, `11`, `18600`, `4` — from `RunRepository` streams alone, as integers and doubles, with
   no string formatting anywhere in the assertion.
6. The same fixture, written and read under each of `en`, `de`, `fa` and `ckb`, produces **four
   identical row sets** — proven by `test/data/locale_independence_test.dart` (T02.11).
7. `grep -rn "DateTime.now()" lib/` returns nothing, and
   `bash .claude/skills/seeded-determinism-and-golden-vectors/scripts/check-determinism-bans.sh lib` passes.
8. `bash .claude/skills/i18n-rtl-l10n/scripts/check_i18n_bans.sh lib` passes, and
   `test/policy/canonical_storage_test.dart` proves `package:intl`, `NumberFormat`, `DateFormat` and
   `AppLocalizations` appear nowhere under `lib/data/` or `lib/core/`.
9. A killed process mid-`saveRun()` leaves either zero rows or one complete row, proven by the rollback
   test in T02.6.
10. The app launches on `MindForge iPhone 14` and creates its database in the iOS application-support
    container — the one thing `flutter test` structurally cannot prove, checked by hand in T02.9.
11. The CI freshness gates cover `*.drift.dart` and `drift_schemas/`, verified by pushing a deliberately
    stale generated file on a scratch commit and watching the job go red.

## Skills to load

| Skill | Why, for this epic |
|---|---|
| `flutter-conventions-index` | House rules 1, 5, 6, 7, 8, 9 and 12 are the spine of this epic: downward-only layering, single write path, derive-don't-store, typed `Result`/`Failure`, injected `Clock`, never-silent async, and i18n correctness by construction. Open it first. |
| `persistence-drift` | The governing skill. STRICT tables, schema-level `CHECK`/FK/partial-UNIQUE, the `AuditColumns` mixin, per-connection pragmas in `setup`/`beforeOpen`, one `db.transaction` per mutation, persist-before-publish, scoped `.watch()`, keyset pagination, `NativeDatabase` FFI over `sqflite`. Rule 5 is the i18n rule in disguise: no display strings, no localized numerals, the local day as a serial int, and **switching locale must leave stored rows byte-identical** — which is exactly what T02.11 asserts. |
| `i18n-rtl-l10n` | Rule 6 (store canonical: UTC epoch + ASCII digits; calendars and numeral systems are display projections), rule 7 (normalize to ASCII before any parse), and the per-locale formatter boundary — E04's `LocaleNumbers` — that must stay *outside* this layer. It is also the source of the `ckb`-has-no-`intl`-number-symbols fact that E04 acts on and this epic must not paper over. `check_i18n_bans.sh` is a gate here; `check_arb_parity.sh` cannot run until E04. |
| `run-migration` | T02.10 only: the forward-only append-only ritual, the committed snapshot, `schema_versions.dart`, the pre-open snapshot/restore opener, the every-pair shape loop, why `migrateAndValidate` alone proves nothing, and rule 9 — never add a float-money, display-string or localized-numeral column. |
| `error-handling-typed-results` | `DataFailure` is one sealed family per boundary with stable `code`s and typed params — rule 3 says **never a localized string**, which is why `UnsupportedLocaleTag` carries the offending tag and not a sentence. Convert `SqliteException` at the DAO/repository seam, log `(e, st)` first, return `Err`; call sites switch with no `default:`. Also the one-transaction-per-mutation half of never-lose-data. |
| `testing-strategy` | Every DAO test runs against `NativeDatabase.memory()`; `addTearDown(db.close)`; pure folds tested with `package:test` and `withClock`; the aggregate maths gets a seeded fuzz loop against an independent oracle with the seed echoed in `reason:`; Notifier/provider wiring driven through `ProviderContainer`; rule 11's honesty clause is why T02.9 carries a named manual on-simulator step. |
| `value-objects-money-and-units` | Canonical storage: integer SI units, UTC instants, and the `package:clock` `Clock` injected rather than `DateTime.now()`. There is no money in MindForge — the rules that apply are the canonical-int one, the injected-clock one, and rule 11: normalize digits to ASCII **before** anything reaches this core. |
| `seeded-determinism-and-golden-vectors` | The calendar-day rule: a day identity is a civil date / serial day, never an instant, and one day definition serves the streak, the "played today" check and the chart. Rule 8 (regenerate derived content, never store it) plus the ban on ambient `Random()` and `DateTime.now()` that `check-determinism-bans.sh` enforces. Also the reason `test/support/run_fixtures.dart` must produce identical rows under every locale. |
| `service-boundary-and-native` | `clockProvider` is the one time seam and `IdGenerator` is the one id seam; both are injected interfaces overridden at the composition root and faked in tests. The provider throws until overridden so a forgotten wiring fails loudly. |
| `state-management-riverpod` | Provider shapes for the data layer: plain `Provider` for DI, `StreamProvider.autoDispose.family` for scoped reads, the throwing `appDatabaseProvider` seam, `ref.onDispose(db.close)`, and the rule that a committed write re-emits rather than being republished by hand. Rule 4 (derive, don't store) governs why there is no cached settings copy. |
| `flutter-architecture` | The downward-only DAG this layer sits at the bottom of, repositories as single source of truth *and* single write path, map-at-the-boundary so no Drift row reaches a Notifier, and "abstract only what cannot run in a test" — which is why there is no `RunRepository` interface. |
| `project-structure-and-packages` | Where each file goes: `lib/data/` for the store, `lib/core/` for the pure value objects and calculators (the sanctioned pure-foundation layer, not a junk drawer), tests mirroring `lib/` 1:1, package imports only, single package — no `packages/`. Rule 7 is why `lib/core/` may not import `package:intl`. |
| `naming-conventions` | `RunsDao`/`SettingsDao`, `RunRepository`/`SettingsRepository`, `DataFailure`, `StreakCalculator`, `SupportedLocale`; units in identifiers (`durationMs`, `totalReactionMs`, `playedOnDay`, `localeTag`); booleans as `is`/`has`/`can`; file name equals its primary declaration. |
| `dart3-idioms-and-coding-standards` | `sealed` `DataFailure` + `final class` leaves with `const` ctors, exhaustive switches with no `default:`, immutable value objects with explicit stable identity, total non-throwing pure folds, rule 7 (make illegal states unrepresentable — why `AppSettings.copyWith` has no locale parameter), and the complexity-limit table. |
| `dartdoc-conventions` | Every public symbol in `lib/data/` and `lib/core/` is a contract: a `///` that states units, ranges, nullability and the invariant — including "which column is authoritative and which value is derived" on each getter, and "null means follow the system locale" on `localeOverride`. |
| `codegen-and-toolchain` | `build.yaml` fencing drift_dev to `lib/data/**` so one edit does not regenerate the tree, the commit-vs-gitignore decision for `*.drift.dart` and the matching CI gate, and mirroring the generated globs into analyzer and coverage excludes. |
| `run-codegen` | The exact pass — `dart run build_runner build --delete-conflicting-outputs` — run before `flutter analyze`, never after, and never hand-editing a generated file. |
| `dependency-hygiene` | `drift`, `sqlite3_flutter_libs`, `path_provider`, `path`, `uuid`, `clock` all go through the transitive audit against the no-network/no-telemetry policy; caret ranges in `pubspec.yaml`, exact pins only in the committed `pubspec.lock`; `sqflite` joins the banned set. |
| `ci-pipeline-and-gates` | Confirming E01's freshness gates actually cover `*.drift.dart` and `drift_schemas/`, and that whichever runner hosts `flutter test` has a host SQLite ≥ 3.37 — without it the whole real-DB suite fails for a reason that looks like a broken repo. Rule 7's three-criteria bar is what justifies `test/policy/canonical_storage_test.dart` as a grep gate. |
| `async-safety` | Every query inside `transaction(() async {` is awaited (a dropped one runs after the commit — Drift calls that data loss), no bare or empty catch at the conversion seam, `rethrow` never `throw e`, every `.watch()` subscription torn down with its provider, and rule 9 — nothing unbounded before `runApp`, which bounds what T02.9 may await in `bootstrap()`. |

## Tasks

### T02.1 — Data-layer dependencies, fenced codegen, and the CI freshness gate

**Goal.** Add exactly the packages the store needs, fence drift_dev to `lib/data/**`, and confirm E01's
CI gates already fail on a stale `*.drift.dart` or `drift_schemas/`.

**Tests first (TDD).**
- `test/policy/dependency_policy_test.dart` — **extend E01's existing file; do not re-author it.**
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
either is missing, add it here. **Then read which runner the test job uses** and make the host SQLite
requirement match it: an `ubuntu-*` job needs `libsqlite3-dev` installed before `flutter test`; a
`macos-*` job inherits the system library and needs nothing. Do not add an apt step to a macOS job and
do not assume Linux — check `ci.yml` and record the answer in the PR body.

`sqlite3_flutter_libs` ships the FFI library for **iOS** (and, when it is un-deferred, Android). It does
nothing in the plain Dart VM that `flutter test` runs in — the suite uses the host library, which is why
T02.3 asserts `sqlite_version()` and T02.9 carries an on-simulator check.

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
- [ ] `ci.yml` has a `*.drift.dart` diff gate and a `drift_schemas/` diff gate, and the test job's host
      SQLite provisioning matches its actual runner.

**Commits.**
1. `test: extend the dependency policy with the data-layer allow-set and ban sqflite`
2. `deps: add drift, sqlite3_flutter_libs, path_provider, uuid, clock`
3. `build: fence drift_dev codegen to lib/data and exclude generated files`
4. `ci: cover *.drift.dart and drift_schemas in the freshness gates`

---

### T02.2 — Canonical value objects, `SupportedLocale`, `AppSettings` and the `DataFailure` family

**Goal.** Land the sealed `Result`/`Failure` spine, the pure Flutter-free types the store maps rows into,
the locale vocabulary the whole app resolves against, and the one sealed failure family the data
boundary returns — before any table exists, so the schema is designed against them.

**This task owns the spine.** `lib/core/result.dart` (`sealed class Result<T, F extends Failure>` with
`final class Ok` / `final class Err` and an `extension ResultX` carrying `fold` and `map`) and
`lib/core/failure.dart` (`sealed class Failure` with `String get code`) are created here, verbatim from
`error-handling-typed-results`, with no "if E01 shipped it" conditional. E02 is the first consumer:
every repository method below returns one. E07 T07.1 adopts these files and adds
`lib/core/run_failure.dart`; if E07 finds itself writing `sealed class Result` again, that is the defect.

**One locale vocabulary, decided here.** `lib/core/supported_locale.dart` declares
`enum SupportedLocale { en, de, fa, ckb }` with `String get tag` (the BCP-47 string that is stored),
`bool get isRightToLeft` (`fa` and `ckb` true) and `static SupportedLocale? tryParse(String tag)`
returning `null` for anything outside the set. **This is the only list of shipped locales in the repo.**
E04 builds `supportedLocales` and its `ckb` delegate decision from it rather than declaring a second
list, exactly as E07's `GameDefinition.scoreFormat` imports `ScoreFormat` rather than declaring
`MetricKind`. The enum is pure: it names no `Locale`, no `TextDirection` and no Flutter type, and
nothing under `lib/data/` reads `isRightToLeft` — direction is a render fact recorded here so E04 has
one authority for it, not a storage concern.

**Tests first (TDD).** All under `test/core/` with `package:test`, no `flutter_test` import.
- `calendar_day_test.dart` — `CalendarDay.fromLocal(DateTime)` produces the same serial for
  `2026-03-29 00:30` and `2026-03-29 23:30` in a DST-shifting zone; `CalendarDay.serial` round-trips
  through `CalendarDay.fromSerial`; `daysBetween` is symmetric in magnitude and signed by order; the
  epoch day is `0`. Rounding golden: the first and last instant of a local day map to one serial.
  **Calendar-independence golden:** the same instant produces the same serial with
  `Intl.defaultLocale` set to `en`, `de`, `fa` and `ckb` in turn — the day identity is the Gregorian
  civil date the device's clock reports, and a Jalali or Hijri label is a projection E04 renders, never a
  stored value. (`CalendarDay` imports no `intl`; the test sets the ambient locale purely to prove the
  absence of a dependency.)
- `result_test.dart` — `fold` maps `Ok` through `onOk` and `Err` through `onErr`, both arms asserted with
  no `default:`; `map` transforms an `Ok` value and passes the **identical** `Err` instance through;
  a `switch` over `Ok`/`Err` compiles without a wildcard, so adding a variant breaks the build.
- `supported_locale_test.dart` — `SupportedLocale.values.map((l) => l.tag)` equals the frozen literal
  `['en', 'de', 'fa', 'ckb']`, so adding or removing a locale is a deliberate test edit; `tryParse('fa')`
  is `SupportedLocale.fa`; `tryParse('ckb')` is `SupportedLocale.ckb`; `tryParse('ar')`, `tryParse('EN')`,
  `tryParse('fa-IR')`, `tryParse('')` and `tryParse('۱۲')` are all `null` — the parse is exact, total and
  never throws; `isRightToLeft` is true for exactly `fa` and `ckb`.
- `run_metric_test.dart` — `RunMetric.points(1480).isBetterThan(RunMetric.points(1310))` is true;
  `RunMetric.duration(18600).isBetterThan(RunMetric.duration(21400))` is true (lower wins);
  comparing two different `ScoreFormat`s returns a `ScoreFormatMismatch` value, never a throw (total
  function rule). `RunMetric` exposes **no** `toString`-for-display and no formatter — a test asserts
  the class declares no method returning a formatted string.
- `run_record_test.dart` — `accuracy` of 46 correct / 4 wrong is `0.92`; `accuracy` with zero answered
  is `null`, not `NaN`; `averageReaction` of `totalReactionMs: 32000` over 50 answered is
  `Duration(milliseconds: 640)`; `==`/`hashCode` are identity-on-`id`, so two records with the same id
  and different scores are equal (explicit stable identity).
- `app_settings_test.dart` — the const default is sound on, haptics on, reduce motion off, colour-blind
  palette off, `localeOverride` **null**; `copyWith` flips exactly one boolean and leaves the rest
  including the locale untouched; `withLocaleOverride(SupportedLocale.ckb)` sets it;
  `withSystemLocale()` clears it back to null; and `AppSettings.copyWith` **has no locale parameter at
  all**, asserted by a reflection-free compile-shape test — a nullable `copyWith` field cannot express
  "set to null" without a sentinel, so the type does not offer the broken option.
- `data_failure_test.dart` — every `DataFailure` leaf exposes a stable `code`
  (`data.store_unavailable`, `data.constraint_violated`, `data.run_already_recorded`,
  `data.not_found`, `data.corrupt_row`, `data.unsupported_locale_tag`); the set of codes is asserted
  against a frozen literal list so renaming one is a test failure; no leaf carries a user-facing string,
  and `UnsupportedLocaleTag` carries the raw offending tag as a typed `String` param for the log line,
  never a sentence.

**Implementation.** `lib/core/result.dart` and `lib/core/failure.dart` (the spine, above);
`lib/core/calendar_day.dart` (serial computed as
`DateTime.utc(local.year, local.month, local.day).millisecondsSinceEpoch ~/ 86400000` — the local Y/M/D
lifted into UTC midnight, which is what makes it DST-proof);
`lib/core/supported_locale.dart` (the locale vocabulary, above);
**`lib/core/score_format.dart` — `enum ScoreFormat { points, duration }`, the one score vocabulary in
the project**; `lib/core/run_metric.dart` (a `final class RunMetric` holding `format` + `value`, with
`isBetterThan` returning a sealed comparison outcome); `lib/core/run_draft.dart` (what E07 hands the
repository: `gameId`, `difficultyId`, `clientRunKey`, `playedOnDay`, `durationMs`, `format`, `value` and
the four counters — no id, no timestamps, those are the repository's to stamp); `lib/core/run_record.dart`;
`lib/core/run_scope.dart` (`gameId` + nullable `difficultyId`, both `String`, value equality — the family
key for scoped streams); `lib/core/app_settings.dart`; `lib/core/game_stats.dart`;
`lib/core/streak_status.dart`; `lib/core/hud_tone.dart`;
`lib/data/data_failure.dart` (`sealed class DataFailure extends Failure`
with `final class` leaves, `const` ctors, typed params).

**`HudTone` lands here too, for the same reason.** `enum HudTone { neutral, highlight, alarm }` in
`lib/core/hud_tone.dart` — the tone a HUD value carries, payload-free and Flutter-free. It is declared
in this epic rather than in E05 because **both** `lib/ui/` (E05's `HudPill` renders it) and
`lib/features/`/`lib/games/` (E07's `GameHud`/`HudSlot` carries it) need it, `lib/ui/` may not import
`lib/features/`, and **E07 depends on E02 but not on E05** — putting it in E05 would make E07's
`board_snapshot.dart` import from an epic it does not declare a dependency on. `lib/core/` is the one
layer both reach and this is the epic that owns `lib/core/`'s vocabulary. E05 T05.1 and E07 T07.3
import it; neither declares it.

**One score vocabulary, decided here.** E07 T07.3 would otherwise declare
`enum ScoreFormat { points, duration }` for `GameDefinition.scoreFormat` while this file declares
`enum MetricKind { points, durationMs }` for the persisted column — two enums for one concept, one
rename away from a silent mismatch on the single column that decides MAX versus MIN. **Decision:
`ScoreFormat` only.** `MetricKind` does not exist. E02 lands first and owns the file; E07 T07.3 imports
it. The `runs` CHECK is therefore `IN ('points','duration')`, mirroring `ScoreFormat.name`.

**`AppSettings` is this epic's file.** `@immutable final class AppSettings` with a `const` constructor,
five `final` fields — `isSoundEnabled`, `isHapticsEnabled`, `isReduceMotionEnabled`,
`isColourBlindPalette` and `SupportedLocale? localeOverride` — plus `copyWith` over the four booleans,
`withLocaleOverride`, `withSystemLocale`, and value equality. It lives in `lib/core/` because the
repository maps rows into it and E04, E06 and E08 all read it. `null` on `localeOverride` means **follow
the system locale**, documented on the field; it does not mean English.

**Files.** `lib/core/result.dart`, `lib/core/failure.dart`, `lib/core/calendar_day.dart`,
`lib/core/supported_locale.dart`, `lib/core/score_format.dart`, `lib/core/run_metric.dart`,
`lib/core/run_draft.dart`, `lib/core/run_record.dart`, `lib/core/run_scope.dart`,
`lib/core/app_settings.dart`, `lib/core/game_stats.dart`, `lib/core/streak_status.dart`,
`lib/core/hud_tone.dart`, `lib/data/data_failure.dart`, and their mirrors under `test/core/` and
`test/data/`.

**Skills.** `dart3-idioms-and-coding-standards`, `value-objects-money-and-units`,
`seeded-determinism-and-golden-vectors`, `error-handling-typed-results`, `i18n-rtl-l10n`,
`naming-conventions`, `dartdoc-conventions`, `project-structure-and-packages`.

**Screenshot check.** n/a (no visual surface).

**Done when.**
- [ ] Nothing under `lib/core/` imports `package:flutter`, `package:intl`, `dart:io`, `package:drift`
      or calls `DateTime.now()`.
- [ ] `HudTone` exists exactly once, in `lib/core/hud_tone.dart`
      (`grep -rn 'enum HudTone' lib/` returns one line), and nothing under `lib/core/` imports
      `package:flutter`.
- [ ] `SupportedLocale` is the only enumeration of shipped locales in `lib/`
      (`grep -rn 'ckb' lib/ | grep -v supported_locale.dart` returns nothing at the end of this epic).
- [ ] Every public symbol carries a `///` that names its unit and its invariant — including "null means
      follow the system locale"; `flutter analyze --fatal-infos` is clean with `public_member_api_docs`
      at error.
- [ ] `bash .claude/skills/dart3-idioms-and-coding-standards/scripts/check-dart3-idioms.sh lib` passes.

**Commits.**
1. `test: specify the Result and Failure spine`
2. `core: add the sealed Result and Failure spine`
3. `test: freeze the supported locale set and its parse contract`
4. `core: add SupportedLocale as the one locale vocabulary`
5. `core: add HudTone where the UI, the shell and the engine can all reach it`
6. `test: specify CalendarDay, ScoreFormat, RunMetric, RunRecord and AppSettings invariants`
7. `core: add CalendarDay, ScoreFormat, RunMetric, the run value objects and AppSettings`
8. `test: freeze the DataFailure code list`
9. `data: add the sealed DataFailure family`

---

### T02.3 — `AppDatabase`, the connection, and schema v1

**Goal.** Create the database class, the `LazyDatabase` connection with per-connection pragmas, and the
two STRICT tables with every invariant the storage layer can enforce — including the ASCII-tag shape
constraints that keep a localized string out of a column.

**Tests first (TDD).** `test/data/db/app_database_schema_test.dart`, all against `NativeDatabase.memory()`
with `addTearDown(db.close)`.
- `sqlite_version()` is ≥ 3.37, asserted first with a `reason:` naming `STRICT` — a stale host must fail
  loudly rather than as a wall of confusing constraint errors.
- `sqlite_master` reports `STRICT` on both `runs` and `settings`.
- Inserting a run with `duration_ms = -1`, `metric_value < 0`, `longest_combo > correct_count`,
  an empty `game_id`, an empty `difficulty_id`, or `metric_kind = 'elo'` each throws `SqliteException` —
  six separate expectations, each naming the constraint it proves.
- **ASCII-tag constraints, one expectation each:** `game_id = 'ستروپ'` throws; `game_id = 'Stroop Rush'`
  throws (space and capitals are outside the token shape); `difficulty_id = 'کلاسیک'` throws;
  `client_run_key = 'کلید۱'` throws; `locale_tag = 'فا'` throws; `locale_tag = 'EN'` throws.
- `locale_tag` accepts `NULL`, `'en'`, `'de'`, `'fa'` and `'ckb'`, and a five-way expectation proves it.
  The column deliberately has **no** closed `CHECK … IN` — see the decision note below.
- Inserting a second `settings` row with `id = 'preferences'` throws (`CHECK (id = 'app')`).
- Inserting two runs with the same `client_run_key` throws; soft-deleting the first
  (`is_deleted = 1`) then inserting the same key succeeds — the partial UNIQUE index, both halves.
- `PRAGMA journal_mode`, `PRAGMA foreign_keys`, `PRAGMA synchronous` and `PRAGMA busy_timeout` report
  `wal` / `1` / `2` (FULL) / `5000` on a freshly opened connection, and again after `close()` + reopen —
  the per-connection pragmas are re-asserted, not assumed.
- A fresh database has exactly one `settings` row with the four toggles at their design defaults
  (sound on, haptics on, reduce motion off, colour-blind palette off — screen 08) and
  `locale_tag IS NULL`, and reopening does **not** re-seed it (seeding lives only inside
  `if (details.wasCreated)`).

**Implementation.** `lib/data/db/tables/audit_columns.dart` — the `mixin AuditColumns on Table` from
`persistence-drift` (text UUID PK, `createdAt`/`updatedAt` UTC ms, `rowRevision`, `isDeleted`,
`deletedAt`). `lib/data/db/tables/runs.dart` and `lib/data/db/tables/settings.dart`.
`lib/data/db/app_database.dart` (`@DriftDatabase`, `schemaVersion => 1`, `MigrationStrategy` with
`onCreate: m.createAll()`, `beforeOpen` re-asserting `foreign_keys` and seeding under `wasCreated`).
`lib/data/db/connection.dart` — `LazyDatabase` over `NativeDatabase.createInBackground` in the
application **support** directory (not Documents), `setup:` executing `journal_mode = WAL`,
`synchronous = FULL`, `foreign_keys = ON`, `busy_timeout = 5000`.

On iOS, `getApplicationSupportDirectory()` resolves inside the app container's
`Library/Application Support`. That is deliberate on two counts: it is included in the iCloud/Finder
device backup (this DB is the only copy of a player's history, so it should survive a device restore),
and it is not exposed through the Files app the way `Documents` is under `UIFileSharingEnabled`. The
container UUID changes on reinstall and restore, so **no absolute path is ever persisted** — the
connection resolves the directory at open time and the schema holds no path column.

`runs` columns and the decision per field:

| Column | Type | Decision |
|---|---|---|
| `game_id` | TEXT | `CHECK (length(game_id) BETWEEN 1 AND 64 AND game_id NOT GLOB '*[^a-z0-9_]*')` — a **shape** check only, and an ASCII one. The set of game ids is registry data owned by `GameDefinition` (E07); a `CHECK … IN` here would turn shipping a third game into a needless migration. The shape check exists because a game id is a semantic token (`stroop_rush`), never a display name — a translated title in this column would make every scoped query locale-dependent. The repository rejects an unregistered id with `Err`. |
| `difficulty_id` | TEXT | same reasoning — ASCII token shape only; per-game difficulty lists are registry data. `Chill / Classic / Blitz` are ARB strings E04 owns; `chill / classic / blitz` are what is stored. |
| `client_run_key` | TEXT | idempotency key minted by E07 per run. `CHECK` on printable-ASCII shape and length 1..128. Partial `UNIQUE INDEX … WHERE is_deleted = 0`. |
| `started_at_utc_ms` | INTEGER | true instant, UTC epoch ms. `CHECK (> 0)`. |
| `played_on_day` | INTEGER | **local** serial day, Gregorian civil date. Distinct from the instant on purpose: it is the day boundary the streak and the "played today" check both read. Never a `DateTime`, and never a Jalali or Hijri field — a Persian civil day starts at the same local midnight as a Gregorian one, so the boundary is identical and only the *label* differs. E04 projects the label; this column never changes. |
| `duration_ms` | INTEGER | wall-clock length of the run; the source of "Time trained". `CHECK (>= 0)`. |
| `metric_kind` | TEXT | `CHECK (metric_kind IN ('points','duration'))` — mirrors `ScoreFormat.name` exactly (T02.2: there is one score enum, not a `MetricKind` beside it). This one **is** a closed `CHECK … IN` because the data layer itself interprets it to decide MAX vs MIN. A test asserts the CHECK list equals `ScoreFormat.values.map((f) => f.name)`, so adding a third format is a migration rather than a silent constraint violation. |
| `metric_value` | INTEGER | the number the game scores by. `CHECK (>= 0)`. Stamped per run so a later scoring change leaves old rows interpretable. |
| `correct_count`, `wrong_count`, `longest_combo` | INTEGER | `CHECK (>= 0)` each, plus `CHECK (longest_combo <= correct_count)`. |
| `total_reaction_ms` | INTEGER | the **sum**, not the average. `CHECK (>= 0)`. Average reaction is derived on read so no rounded double is ever stored. |
| formatted score / duration | — | **not stored.** `1,480`, `1.480`, `۱٬۴۸۰`, `18.6s` are render projections of `metric_value`; the store holds `1480` and `18600`. |
| accuracy | — | **not stored.** Derived: `correct / (correct + wrong)`. |
| personal best | — | **not stored.** Derived: MAX/MIN of `metric_value` by `metric_kind` (T02.7). |
| aggregates | — | **not stored.** Derived: `COUNT(*)`, `SUM(duration_ms)` folds (T02.7). |
| daily streak | — | **not stored.** Derived: a fold over distinct `played_on_day` (T02.8). |

`settings` columns: the `AuditColumns` set, `id` with `CHECK (id = 'app')`, four INTEGER toggles each
with `CHECK (col IN (0,1))` (STRICT has no BOOLEAN type — the constraint is what makes the column
boolean), and:

| Column | Type | Decision |
|---|---|---|
| `locale_tag` | TEXT NULL | The user's explicit locale choice as a BCP-47 tag; `NULL` means follow the system locale. `CHECK (locale_tag IS NULL OR (length(locale_tag) BETWEEN 2 AND 35 AND locale_tag NOT GLOB '*[^a-z-]*'))` — a **shape** check, deliberately not `IN ('en','de','fa','ckb')`. A closed list would make withdrawing a locale in a later version leave existing rows in permanent violation, so that every subsequent `UPDATE` of the settings row fails for exactly the users who chose it. The supported set is enforced **on read** in T02.4, where an unrecognised tag can degrade to "follow system" instead of bricking the row. The shape check still does the job that matters here: it makes a localized string, a numeral or a display name unrepresentable in the column. |

The column ships in **schema v1** rather than arriving with E04 so that adding three locales is a string
job, not the app's first migration on a DB that already holds user history.

No foreign key exists at v1, because no cross-table relation exists at v1 — inventing a `games` table
would create a second authority for game identity against the code registry. `foreign_keys = ON` and a
`PRAGMA foreign_key_check` assertion ship anyway so the first relation added is enforced from the day
it lands. Soft-delete columns come from `AuditColumns` and no delete UI ships in E02; every read filters
`is_deleted = 0` through one shared base-query helper so the first delete cannot regress a read.

**Files.** `lib/data/db/app_database.dart`, `lib/data/db/connection.dart`,
`lib/data/db/tables/{audit_columns,runs,settings}.dart`, `lib/data/db/app_database.drift.dart`
(generated, committed), `test/data/db/app_database_schema_test.dart`.

**Skills.** `persistence-drift`, `i18n-rtl-l10n`, `dartdoc-conventions`, `naming-conventions`,
`run-codegen`, `testing-strategy`.

**Screenshot check.** n/a (no visual surface).

**Done when.**
- [ ] `dart run build_runner build --delete-conflicting-outputs` then `flutter analyze --fatal-infos`
      is clean, in that order.
- [ ] Every constraint above has a test that proves SQLite rejects the bad row — not a Dart guard.
- [ ] The ASCII-tag CHECKs reject Persian and Sorani text in `game_id`, `difficulty_id`,
      `client_run_key` and `locale_tag`, each with its own expectation.
- [ ] `bash .claude/skills/persistence-drift/scripts/check-persistence-bans.sh lib` passes and reports
      all three pragmas configured.
- [ ] `bash .claude/skills/persistence-drift/scripts/check-drift-confinement.sh lib` passes.

**Commits.**
1. `test: specify schema v1 constraints, pragmas and seeding`
2. `data: add the AuditColumns mixin and the runs and settings tables`
3. `test: reject non-ASCII tags in every identifier column`
4. `data: add the nullable locale_tag column with an ASCII shape constraint`
5. `data: open the database with WAL, FULL sync and foreign keys per connection`
6. `chore: regenerate drift output for schema v1`

---

### T02.4 — `SettingsDao`, `SettingsRepository` and locale validation on read

**Goal.** Ship the simplest complete vertical — table to value object to `Result` to watched stream —
so the pattern every later repository copies is settled and reviewed, and make the locale override
survive a relaunch, a corrupt tag and a withdrawn locale.

**Tests first (TDD).** `test/data/daos/settings_dao_test.dart` and
`test/data/repositories/settings_repository_test.dart`, both on `NativeDatabase.memory()`.
- `watch()` emits the seeded defaults immediately on subscribe, with `localeOverride` **null**.
- `read()` returns `Ok(AppSettings)` for the seeded row in one shot without opening a stream — the
  bounded call `bootstrap()` awaits before `runApp` (T02.9).
- `update(settings.copyWith(isSoundEnabled: false))` resolves **after** the row is durable: reading the
  raw row inside the returned `Future`'s `then` already shows `0`.
- The `.watch()` stream re-emits the new value with no manual republish — assert the stream emits
  exactly twice (`emitsInOrder`), proving persist-before-publish rather than an optimistic push.
- **Locale round-trip, one expectation per locale:** `update(s.withLocaleOverride(SupportedLocale.de))`
  stores the raw column value `'de'` and `watch()` re-emits `localeOverride: SupportedLocale.de`; the
  same for `fa` and `ckb`. Assert the **raw column**, not just the mapped value — the point is that the
  stored form is the ASCII tag.
- **Clearing works:** `update(s.withSystemLocale())` writes SQL `NULL`, and `watch()` re-emits
  `localeOverride: null`. Asserted against the raw column so a `copyWith` that silently kept the old
  value cannot pass.
- **An unrecognised tag degrades, it does not throw.** Write `locale_tag = 'ar'` through a raw
  `customStatement` (legal by shape, absent from `SupportedLocale`), then subscribe: `watch()` emits
  `localeOverride: null` — follow the system — and does **not** throw, and does **not** rewrite the
  column. Three assertions in one test: the emitted value, the absence of a throw, and
  `SELECT locale_tag` still reading `'ar'` afterwards.
- **The degradation is visible.** The same read logs one `UnsupportedLocaleTag('ar')` through the
  injected log sink, asserted on a fake sink, and logs it **once** per emission rather than per
  subscriber — so a withdrawn locale shows up in a diagnostics export instead of vanishing.
- `update` bumps `row_revision` by exactly 1 and stamps `updated_at` from the injected `Clock`, not the
  wall clock: with `Clock.fixed(2026-08-19T10:00Z)` the stored `updated_at` equals that instant exactly.
- A DAO forced to fail (open the DB, `close()` it, then call `update`) returns
  `Err(StoreUnavailable())`, never throws, and the original `SqliteException` is logged before the
  return.
- The returned `Result` is switched exhaustively in the test with no `default:` — a compile-time proof
  the family is sealed.

**Implementation.** `lib/data/daos/settings_dao.dart` (`@DriftAccessor(tables: [SettingsTable])`,
single-table queries only, rows mapped to `AppSettings` from `lib/core/app_settings.dart`).
`lib/data/repositories/settings_repository.dart` — constructor takes `AppDatabase`, `SettingsDao`,
`Clock` and the log sink; `Stream<AppSettings> watch()`;
`@useResult Future<Result<AppSettings, DataFailure>> read()`;
`@useResult Future<Result<AppSettings, DataFailure>> update(AppSettings)` wrapping one `db.transaction`
with the shared write wrapper that stamps `updatedAt`/`rowRevision`. Narrow `on SqliteException` catch,
log `(e, st)` first, then return the typed `Err`.

**The locale read is where the supported set is enforced.** Mapping a row runs
`SupportedLocale.tryParse(row.localeTag)`; `null` in the column means "follow system" and maps straight
through, while a **non-null tag that fails to parse** logs `UnsupportedLocaleTag(tag)` and also maps to
null. **Decision: the read does not self-heal.** Rewriting the column to `NULL` would be a side effect
inside a read, and it would permanently destroy a real preference for a user who downgraded to a build
that dropped a locale and then upgraded again — their `ckb` would come back on its own if the column is
left alone. So the row is preserved, the degradation is logged, and the visible behaviour is that the UI
falls back to the system locale, which is exactly what E04's resolution chain does with no override.

**Writing is the only path.** There is no `AppSettingsNotifier` and no in-memory settings state anywhere
in the app. `settingsProvider` (T02.9) is a stream over `watch()`; every write is
`settingsRepositoryProvider.update(...)`. E06's `MotionPreferenceScope` and E08's Settings screen read
and write through exactly that pair.

**Files.** `lib/data/daos/settings_dao.dart`, `lib/data/repositories/settings_repository.dart`,
`lib/data/db/write_stamp.dart` (the one shared `updatedAt`/`rowRevision` wrapper),
`test/data/daos/settings_dao_test.dart`, `test/data/repositories/settings_repository_test.dart`,
`test/support/fake_log_sink.dart`.

**Skills.** `persistence-drift`, `error-handling-typed-results`, `i18n-rtl-l10n`, `async-safety`,
`testing-strategy`, `service-boundary-and-native`.

**Screenshot check.** n/a (no visual surface). The four toggles, their default states and the language
row come from `design/sunburst-pop/screens/08-settings.png`; E04 adds the language row to `app.html`
and its RTL counterpart, and E08 compares the screen against both.

**Done when.**
- [ ] No Drift symbol appears in the `SettingsRepository` public signature — `AppSettings` and
      `Result<AppSettings, DataFailure>` only.
- [ ] An unrecognised `locale_tag` degrades to "follow system", logs once, throws never, and leaves the
      column untouched — all four asserted.
- [ ] `bash .claude/skills/error-handling-typed-results/scripts/check-swallowed-catch.sh lib` passes.
- [ ] Every query inside the transaction is awaited (analyzer `unawaited_futures` at error backs this).

**Commits.**
1. `test: specify the settings read, write and failure contract`
2. `data: add SettingsDao mapping rows to AppSettings`
3. `data: add SettingsRepository as the single settings write path`
4. `test: specify locale override round-trip, clearing and degradation`
5. `data: validate the stored locale tag against the supported set on read`

---

### T02.5 — `RunsDao`: scoped reads, keyset pagination, and the index plan

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
- Ordering is by `started_at_utc_ms`, an integer — asserted to be stable under
  `Intl.defaultLocale = 'fa'`, because a collation-sensitive ordering over a text column would be the
  classic way for a locale to change a query result. Two runs of the same fixture under `en` and `ckb`
  return identical id sequences.
- A watch subscription cancelled in `addTearDown` leaves no pending timer — the suite runs with
  `--test-randomize-ordering-seed random` and stays green.

**Implementation.** `lib/data/daos/runs_dao.dart` — `@DriftAccessor(tables: [Runs])`;
`Stream<List<RunRecord>> watchRecent(RunScope, {required int limit})`,
`Future<List<RunRecord>> pageBefore({required int cursorStartedAtUtcMs, required int limit})`,
`Future<void> insertRun(RunsCompanion)`, plus the raw folds T02.7/T02.8 consume. One private
`_baseSelect()` that applies `is_deleted = 0` so no query can forget it, and one private `_toRecord(RunRow)`
mapper. Indexes declared on the table:
`idx_runs_game_difficulty_time (game_id, difficulty_id, started_at_utc_ms)` — equality columns lead, the
sort column trails — and `idx_runs_day (played_on_day)`. Every `ORDER BY` in this file is over an
integer column; no query sorts or compares text, so no `COLLATE` clause is needed and none is written.

**Files.** `lib/data/daos/runs_dao.dart`, `lib/data/db/tables/runs.dart` (indexes),
`test/data/daos/runs_dao_test.dart`, `test/support/run_fixtures.dart` (a seeded builder that produces a
deterministic run set from an integer seed — no ambient `Random`, no locale-dependent value).

**Skills.** `persistence-drift`, `testing-strategy`, `seeded-determinism-and-golden-vectors`,
`async-safety`, `naming-conventions`.

**Screenshot check.** n/a (no visual surface).

**Done when.**
- [ ] No `OFFSET` anywhere — `check-persistence-bans.sh` proves it.
- [ ] Both `EXPLAIN QUERY PLAN` assertions are green; adding a query without an index fails the suite.
- [ ] `RunsDao` returns `RunRecord`, never a generated row type.
- [ ] No `ORDER BY` or comparison in this file touches a TEXT column.

**Commits.**
1. `test: specify scoped run reads, keyset paging and the query plan`
2. `data: add the runs indexes for scoped reads and the streak fold`
3. `data: add RunsDao with scoped watches and keyset pagination`

---

### T02.6 — `RunRepository.saveRun`: the single write path

**Goal.** One method, one transaction, idempotent, returning the durable `RunRecord` **and whether it is
a personal best** — or a typed `DataFailure` — and proven to leave nothing partial behind when it fails.

**The name and the payload, decided here.** E07 T07.8, E08 T08.8 and E10 T10.3 all call
`runRepositoryProvider.saveRun(...)`; this epic owns the write path, so the method is **`saveRun`**, not
`record`. And it returns `Result<RunCommit, DataFailure>` where
`final class RunCommit { final RunRecord record; final bool isPersonalBest; }` — not a bare `RunRecord`.
The reason is not convenience: E07's `RunNotifier` persists *then* transitions to `over`, and E08's
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
- `isPersonalBest` is computed inside the transaction — asserted by checking that the returned flag
  matches a `watchPersonalBest` read taken **after** the commit for every row in a 200-run seeded
  fixture, so a guard that read outside the transaction would disagree on at least one row.
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
  guard, before any SQL runs. A draft whose `gameId` is a display string rather than a token
  (`'Stroop Rush'`, `'ستروپ'`) returns the same `Err` from the same guard, so the ASCII CHECK in T02.3 is
  the backstop and not the first line of defence.
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
- [ ] `saveRun` is exactly one `db.transaction`, and the personal-best read happens inside it; no query
      inside it is unawaited.
- [ ] No `DateTime.now()` and no bare `Uuid().v7()` call site outside `UuidIdGenerator`.
- [ ] `check-swallowed-catch.sh` and `check-determinism-bans.sh` both pass on `lib`.

**Commits.**
1. `test: specify the run write path, idempotency and rollback`
2. `core: add the IdGenerator seam and its UUID v7 implementation`
3. `data: add RunRepository.saveRun as the single run write path, returning RunCommit`

---

### T02.7 — Derived reads: personal best and per-game/per-difficulty aggregates

**Goal.** Personal best and the stats numbers as folds over `runs`, recomputed on read, exposed as
scoped `.watch()` streams — no second authority anywhere, and no formatted value at any point.

**Tests first (TDD).** `test/data/repositories/run_repository_stats_test.dart` and
`test/core/aggregate_property_test.dart`.
- `watchPersonalBest(RunScope('stroop_rush','classic'))` returns MAX(`metric_value`) for
  `ScoreFormat.points`; `watchPersonalBest(RunScope('schulte_grid','classic'))` returns MIN for
  `ScoreFormat.duration`. Both assert the direction explicitly.
- Personal best over an empty scope is `null`, not `0` — a zero would render as a real BEST pill.
- `watchBestsByGame()` returns one entry per game id that has any run, keyed by `gameId`, with `null`
  for a game that has none — **the all-games fold Home's BEST pills need**. Asserted with three games in
  the fixture and one of them run-free. This is the only read E08's `HomeNotifier` cannot build out of
  the scoped ones without an N+1 of stream subscriptions, and it is the reason there is no separate
  `StatsRepository`: everything the stats screen and the home hub need is a fold over `runs`, and a
  second repository over the same table would be a second authority.
- Recording a better run makes the best stream re-emit; recording a worse run does **not** re-emit a
  changed value (the stream is scoped and the fold is stable).
- Mixed `metric_kind` rows inside one scope surface `Err(CorruptRow)` rather than silently comparing
  points against milliseconds.
- **Every value crossing this boundary is a number, not a string.** A test asserts the static types of
  `GameStats`'s members — `int gamesPlayed`, `int timeTrainedMs`, `double? accuracy`,
  `Duration? averageReaction`, `int longestCombo` — and that `GameStats` declares no `String` member and
  no formatting method. Grouping separators, the `%` sign, `ms`, `s` and `h`/`m` are E04's ARB and
  `NumberFormat` job.
- **Property test, seeded fuzz, 500 seeds:** for a random run set, `gamesPlayed` equals the list length,
  `timeTrainedMs` equals the sum of `duration_ms`, and `best` equals the extremum computed by an
  independent Dart oracle (`list.map(...).reduce(...)`) — never by the SQL under test. The seed, the run
  count and the generated values are echoed in `reason:` so a failure is its own repro.
- **Property test:** accuracy is always in `[0.0, 1.0]` and `null` exactly when nothing was answered;
  `averageReaction` is `null` exactly when nothing was answered (no division by zero, no `NaN`).
- `test/data/reference_fixture_test.dart` — the design-numbers gate, asserted as **integers**. A fixture
  run set produces exactly the values behind the reference screens: `1480` and `128` (screen 02's
  `Your best 1,480` / `Games played 128`), `0.92`, `Duration(milliseconds: 640)` and `11` (screen 06's
  `Accuracy 92%` / `Avg reaction 640ms` / `Longest streak x11`), `1480`, `18600`, `128`, `11520000` ms
  and a 7-element `Last 7 runs` series (screen 07). The rendered strings on those PNGs are the English
  projection of these numbers; E04 owns the projection and E08 owns the pixel comparison. Asserting the
  integer here is what makes the test survive the arrival of `de`, `fa` and `ckb`.

**Implementation.** Add to `lib/data/daos/runs_dao.dart` the folds: `watchBest(RunScope)`,
`watchBestsByGame()` (one `GROUP BY game_id` query, not a fan-out of per-game streams),
`watchAggregate(RunScope)` (`COUNT(*)`, `SUM(duration_ms)`, `SUM(correct_count)`, `SUM(wrong_count)`,
`SUM(total_reaction_ms)`, `MAX(longest_combo)`), `watchLastN(RunScope, int n)` for the chart series. Add
to `lib/data/repositories/run_repository.dart`: `Stream<RunMetric?> watchPersonalBest(RunScope)`,
**`Stream<Map<String, RunMetric?>> watchBestsByGame()`**, `Stream<GameStats> watchStats(RunScope)`,
`Stream<List<RunRecord>> watchChartSeries(RunScope, {int count = 7})`. Derivation lives in
`lib/core/game_stats.dart` as pure getters so the property tests run under `package:test` with no
database.

**There is no `StatsRepository`.** E08's inherited-symbols table asks for one; this is the answer. Home,
game detail, results and stats all read folds over the single `runs` table, and `RunRepository` is that
table's single source of truth. A second repository would be a second authority over one table — the
exact thing `flutter-architecture` forbids. E08 T08.5's `HomeNotifier` reads `allBestsProvider` (T02.9),
and T08.9's `StatsNotifier` reads `runStatsProvider`/`chartSeriesProvider`.

**Files.** `lib/data/daos/runs_dao.dart`, `lib/data/repositories/run_repository.dart`,
`lib/core/game_stats.dart`, `test/data/repositories/run_repository_stats_test.dart`,
`test/core/aggregate_property_test.dart`, `test/data/reference_fixture_test.dart`.

**Skills.** `persistence-drift`, `testing-strategy`, `dart3-idioms-and-coding-standards`,
`value-objects-money-and-units`, `i18n-rtl-l10n`, `flutter-architecture`.

**Screenshot check.** n/a (no visual surface) — but `test/data/reference_fixture_test.dart` is the
equivalent: it asserts the exact quantities rendered in `design/sunburst-pop/screens/02-game-detail.png`,
`06-results.png` and `07-stats.png`, as the integers behind those strings. If a number there is
unreachable from the schema, the schema is wrong and this task fixes it; if the reference figure is
itself inconsistent, edit `app.html`, re-run `./capture-screens.sh` and commit that as a deliberate
design change.

**Done when.**
- [ ] No table, column or cached field stores a best, a count or a total.
- [ ] `GameStats` exposes no `String` member and no formatting method.
- [ ] The fuzz loop runs 500 seeds against an independent oracle and echoes the seed in `reason:`.
- [ ] The reference-fixture test reproduces every quantity behind screens 02, 06 and 07 as a number.

**Commits.**
1. `test: specify personal best direction, the all-games fold and aggregate folds`
2. `data: derive personal best, bests-by-game and per-scope aggregates on read`
3. `test: pin the aggregate maths with a seeded property test`
4. `test: reproduce the reference screen quantities from a run fixture`

---

### T02.8 — The daily streak, driven by the injected `Clock`

**Goal.** A pure `StreakCalculator` over distinct local serial days, and a repository stream whose
"today" comes from the injected `Clock` — never `DateTime.now()`, and never a calendar the locale picks.

**Tests first (TDD).** `test/core/streak_calculator_test.dart` (pure, `package:test`) and
`test/data/repositories/run_repository_streak_test.dart` (`ProviderContainer` + in-memory DB).
- Days `[d, d-1, d-2, d-3]` with today `d` give `currentDays: 4`, the quantity behind the `4 day streak`
  chip on screen 01.
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
- **The locale test.** The same fixture and the same fixed clock produce the identical `StreakStatus`
  with `Intl.defaultLocale` set to `en`, `de`, `fa` and `ckb` in turn. The streak counts Gregorian civil
  days because that is what `CalendarDay` is; a Persian user's streak breaks at the same local midnight
  and only the rendered date label differs. Asserting this here is what stops someone "fixing" the
  streak with Jalali arithmetic in E04.

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
`i18n-rtl-l10n`, `dart3-idioms-and-coding-standards`, `persistence-drift`.

**Screenshot check.** n/a (no visual surface). The `4` behind the `4 day streak` chip on
`design/sunburst-pop/screens/01-home.png` is asserted as a value in the calculator test; E08 compares the
chip itself against the LTR PNG and its RTL counterpart from E04.

**Done when.**
- [ ] `StreakCalculator` imports nothing but `package:meta` and the `lib/core/` value objects.
- [ ] The two-container clock test is green and would fail if `clock.now()` were replaced with
      `DateTime.now()` — verify by making that edit locally, watching it go red, and reverting.
- [ ] The four-locale test is green and no calendar-conversion package appears in `pubspec.yaml`.
- [ ] `bash .claude/skills/seeded-determinism-and-golden-vectors/scripts/check-determinism-bans.sh lib`
      passes.

**Commits.**
1. `test: specify streak continuation, breakage and clock dependence`
2. `core: add the pure StreakCalculator over local serial days`
3. `data: expose watchStreak driven by the injected Clock`
4. `test: pin the streak to Gregorian civil days across all four locales`

---

### T02.9 — Riverpod wiring, the composition-root override, and the on-simulator check

**Goal.** Expose the store through providers — a throwing `appDatabaseProvider` seam, plain `Provider`
DI for the repositories, scoped `StreamProvider.autoDispose.family` reads — wire the one live instance
at the composition root, and confirm on the canonical simulator that the store actually opens on iOS.

**Tests first (TDD).** `test/data/data_providers_test.dart`.
- Reading `appDatabaseProvider` without an override throws `UnimplementedError` with a message naming
  the file to fix — a forgotten wiring must fail loudly, not construct a real DB inside a test. The same
  for `initialAppSettingsProvider`.
- With `appDatabaseProvider.overrideWithValue(AppDatabase(NativeDatabase.memory()))` and
  `clockProvider.overrideWithValue(Clock.fixed(...))`, `runStatsProvider(RunScope(...))` emits
  `AsyncData<GameStats>` with the fixture's numbers.
- `settingsProvider` emits the seeded `AppSettings` and re-emits after
  `settingsRepositoryProvider.update(...)`, with no manual republish.
- Two reads of `runStatsProvider` with the *same* `RunScope` return the same provider instance (value
  equality on the family key); two different scopes do not share state.
- Disposing the container cancels the underlying `.watch()` subscription — the test ends with no
  pending timer under `--test-randomize-ordering-seed random`.
- `test/policy/provider_shapes_test.dart` — greps `lib/` for `StateProvider`, `StateNotifierProvider`,
  `ChangeNotifierProvider`, `get_it` and `package:provider` and asserts none appear.

**Implementation.** `lib/data/data_providers.dart` — `appDatabaseProvider` (throwing seam),
`initialAppSettingsProvider` (throwing seam, holding the settings row read before `runApp`),
`idGeneratorProvider`, `settingsDaoProvider`, `runsDaoProvider`, `settingsRepositoryProvider`,
`runRepositoryProvider`, and the reads `settingsProvider`, `personalBestProvider(RunScope)`,
**`allBestsProvider`** (over `watchBestsByGame()` — the one Home's BEST pills need, unscoped and
therefore not a `family`), `runStatsProvider(RunScope)`, `chartSeriesProvider(RunScope)`,
`streakProvider`. `autoDispose` and `family` used as modifiers only, never as base classes. Add to the
composition root E01 produced (`lib/bootstrap.dart`) the `appDatabaseProvider.overrideWithValue(...)`
line with `ref.onDispose(db.close)` owning teardown, plus **one awaited
`settingsRepository.read()`** whose `Ok` value overrides `initialAppSettingsProvider`.
`clockProvider` self-defaults to `const Clock()` and needs no override outside tests.

**Why `bootstrap()` awaits a read at all.** E04 must build `MaterialApp` with the persisted locale on
the **first** frame. If the locale arrived through an `AsyncValue`, a Persian user's cold start would
paint an English LTR frame and then flip to Persian RTL — a visible, unmistakable defect. The same
argument applies to E06's reduce-motion toggle, which must be honoured by the first transition rather
than by the second. (There is no theme flash to avoid: MindForge is light-theme only, working agreement
1, so E03 has nothing to restore.) `async-safety` rule 9 forbids unbounded work before `runApp`; a
single-row read from a local file is bounded, and that is the whole justification.
The `Err` arm falls back to `AppSettings`'s const defaults so a broken store still boots, and the read
is the **only** thing this epic adds before `runApp` — the `main()` sequence stays E01's and is not
reordered.

**Files.** `lib/data/data_providers.dart`, `lib/bootstrap.dart` (two overrides and one awaited read),
`test/data/data_providers_test.dart`, `test/policy/provider_shapes_test.dart`.

**Skills.** `state-management-riverpod`, `service-boundary-and-native`, `flutter-architecture`,
`async-safety`, `project-structure-and-packages`.

**Screenshot check.** n/a (no visual surface) — but this task carries the one manual step
`flutter test` structurally cannot cover, because the suite runs in a plain Dart VM where
`sqlite3_flutter_libs` does nothing:

```bash
xcrun simctl boot C13DDC02-375D-4E1B-8F81-44EB407D09A4
flutter run -d C13DDC02-375D-4E1B-8F81-44EB407D09A4
# then, with the app running:
xcrun simctl get_app_container C13DDC02-375D-4E1B-8F81-44EB407D09A4 <bundle-id> data
# and confirm Library/Application Support/mindforge.sqlite exists, plus its -wal sidecar
```

Confirm the file is created, `sqlite3 <path> 'PRAGMA integrity_check;'` returns `ok` and
`PRAGMA journal_mode;` returns `wal`. Record the bundled `sqlite_version()` reported on device in the PR
body next to the host version, because they are different libraries and the difference is the risk.
Android is out of scope; no Android device is booted and no claim is made about one.

**Done when.**
- [ ] `bash .claude/skills/state-management-riverpod/scripts/ban-legacy-providers.sh lib` passes.
- [ ] No DAO is exposed through a provider; only repositories and their derived streams are.
- [ ] The app opens its database on `MindForge iPhone 14` and the container check above is recorded in
      the PR body with both SQLite versions.
- [ ] `bash .claude/skills/flutter-architecture/scripts/check_architecture.sh lib` and
      `bash .claude/skills/project-structure-and-packages/scripts/check_import_boundaries.sh lib` pass.

**Commits.**
1. `test: specify the database seam and scoped stream providers`
2. `data: add the data-layer provider graph`
3. `app: override the database seam and preload settings at the composition root`

---

### T02.10 — Schema snapshot v1, the migration harness, and the restore path

**Goal.** Commit the v1 schema snapshot, generate era-correct classes, and prove the migration machinery
end to end — including the restore path that only runs when something has already gone wrong.

**Tests first (TDD).** `test/data/migration/schema_v1_test.dart` and
`test/data/migration/snapshot_restore_test.dart`.
- **Version guard:** `AppDatabase(NativeDatabase.memory()).schemaVersion == kLatestSchemaVersion` and a
  snapshot file exists for every version `1..kLatestSchemaVersion`. Bumping the version without dumping
  the snapshot fails here as well as in CI.
- **Content round-trip at v1, hostile fixture:** write rows through the generated `DatabaseAtV1` using
  `schema.newConnection()`, then reopen the same bytes as `AppDatabase`, run
  `verifier.migrateAndValidate(db, 1)`, and read back with the v1-era classes. Assert per key (never per
  list index), with a `reason:` on every `expect`, that every value survived byte for byte. The fixture
  is hostile where the schema still allows it: `metric_value = 0`, `metric_value` at
  `9007199254740991`, `duration_ms = 0`, `played_on_day` at both ends of the supported range,
  `total_reaction_ms` at zero with a non-zero `correct_count`, a `client_run_key` of printable-ASCII
  punctuation, and `locale_tag` at each of `NULL`, `'en'`, `'de'`, `'fa'`, `'ckb'`.
  **This fixture changed from the pre-i18n plan.** It used to carry an em dash and non-ASCII text in
  `game_id`; the ASCII-tag `CHECK` from T02.3 makes that row illegal, which is the point. The fixture
  now proves the rejection instead: a companion expectation asserts that inserting `game_id = 'ستروپ'`
  or `locale_tag = 'فا'` through `DatabaseAtV1` throws, so the constraint is era-correct and not
  something a later migration silently relaxes.
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
- [ ] The v1 snapshot contains `locale_tag`, so E04 ships no migration.

**Commits.**
1. `test: guard the schema version against a missing snapshot`
2. `data: commit the v1 schema snapshot and era-correct test classes`
3. `test: round-trip a hostile fixture through the v1 schema`
4. `data: snapshot and restore the database file around the open`
5. `test: prove a forced mid-migration throw restores the snapshot`

---

### T02.11 — Locale independence of the store, proven end to end

**Goal.** Turn "everything stored is locale-independent" from a stated intention into a failing test if
it is ever violated — at the value layer, at the SQL layer, and as a static property of the source.

**This task exists because the failure is silent.** A `NumberFormat` that creeps into a repository, a
`played_on_day` that starts reading a Jalali calendar, a `game_id` that becomes a translated title —
none of those break an English build, and all of them corrupt a Persian or Sorani user's history in a
way no later migration can undo. `persistence-drift` rule 5 states the invariant ("switching locale
must leave stored rows byte-identical") and this task is where it is asserted.

**Tests first (TDD).**
- `test/data/locale_independence_test.dart` — **the four-locale row-set identity test.** For each of
  `en`, `de`, `fa`, `ckb`: open a fresh `NativeDatabase.memory()`, override `clockProvider` with the
  same `Clock.fixed(...)` and `idGeneratorProvider` with the same `FakeIdGenerator`, run
  `Intl.withLocale(tag, () async { … })` around building the same seeded fixture through
  `RunRepository.saveRun`, then `SELECT * FROM runs ORDER BY id` and `SELECT * FROM settings`. Assert
  the four resulting row lists are **equal** — the same integers, the same ASCII tags, the same
  `typeof()` for every column. One `expect` per locale pair, with the pair named in `reason:` so a
  failure says which locale diverged.
- The narrow version the brief names, kept as its own test so it reads as a spec line: a run scoring
  `1480` written under `fa` reads back under `en` as the integer `1480`, and the raw column
  `typeof(metric_value)` is `'integer'` in both directions. `۱۴۸۰` never appears anywhere.
- **The ASCII sweep.** Walk `pragma_table_info` for `runs` and `settings`, and for every TEXT column
  assert `SELECT count(*) FROM <table> WHERE <col> IS NOT NULL AND <col> GLOB '*[^ -~]*'` is `0` after
  the four-locale fixture has been written. This covers columns added by a future task without anyone
  remembering to extend the test.
- **Seeded generation is locale-independent.** `test/support/run_fixtures.dart` built from seed `12345`
  produces the identical `List<RunDraft>` under all four locales — asserted field by field, with the
  seed echoed in `reason:`. This is the golden-vector rule from
  `seeded-determinism-and-golden-vectors` applied at the only place this epic generates anything: a
  vector must not change because the locale changed.
- `test/policy/canonical_storage_test.dart` — the static half, a grep gate that meets
  `ci-pipeline-and-gates`'s three-criteria bar (textually decidable, silent when broken, one line to
  break). Assert that no file under `lib/data/` or `lib/core/` contains `package:intl`,
  `package:flutter_localizations`, `AppLocalizations`, `NumberFormat`, `DateFormat`, `toStringAsFixed`,
  `Intl.` or a Persian/Arabic-Indic digit codepoint (`U+0660`–`U+0669`, `U+06F0`–`U+06F9`). Assert
  separately that no `.dart` file in either directory contains a `'` -quoted string matching
  `[0-9]{1,3}([,.][0-9]{3})+` — a grouped number literal in the store is a formatted value that escaped.

**Implementation.** Mostly assertions over code that already exists; the fixes this task forces are
deletions, not additions. Where a helper is needed, it goes in `test/support/locale_matrix.dart` —
`localeMatrix`, **derived** as `SupportedLocale.values.map((l) => l.tag)` rather than typed as a second
literal, plus a `runInEachLocale(...)` harness that every one of the tests above iterates. T02.2 made
`SupportedLocale` the only list of shipped locales in the repo and this keeps that true on the test
side: E04 T04.10's `LocaleCase.all` is the widget-tier projection of the same enum, and there is no
`kTestLocales` and no `test/support/locales.dart` anywhere in the sequence.

**Where the numerals actually live.** `LocaleNumbers` — the per-locale formatter with a pinned
numbering system, `fa` and `ckb` both borrowing the `fa` symbols because `intl` ships none for `ckb`,
and the **one** `NumberFormat` construction site in the app — is **E04's file**
(`lib/l10n/locale_numbers.dart`), not this epic's. This task's job is to prove it can never be called
from `lib/data/` or `lib/core/`. Stating the boundary in both directions is what stops a future task
from "helpfully" formatting a score at the repository.

**Files.** `test/data/locale_independence_test.dart`, `test/policy/canonical_storage_test.dart`,
`test/support/locale_matrix.dart`, plus whatever deletions the gates force in `lib/data/` and
`lib/core/`.

**Skills.** `i18n-rtl-l10n`, `persistence-drift`, `seeded-determinism-and-golden-vectors`,
`testing-strategy`, `ci-pipeline-and-gates`, `value-objects-money-and-units`.

**Screenshot check.** n/a (no visual surface). This task is the data layer's equivalent of the RTL
screenshot comparison E04 introduces: it proves the store does not move when the locale does, without
rendering a pixel.

**Done when.**
- [ ] The four-locale row sets are identical, asserted pairwise with the pair named in `reason:`.
- [ ] The ASCII sweep walks `pragma_table_info` rather than a hand-written column list.
- [ ] `test/policy/canonical_storage_test.dart` fails if `import 'package:intl/intl.dart';` is added to
      any file under `lib/data/` or `lib/core/` — verify by adding it locally, watching it go red, and
      reverting.
- [ ] `bash .claude/skills/i18n-rtl-l10n/scripts/check_i18n_bans.sh lib` passes.
- [ ] `test/support/locale_matrix.dart` is the single declaration of the four-locale list in `test/`.

**Commits.**
1. `test: add the four-locale matrix harness`
2. `test: prove the store is byte-identical across en, de, fa and ckb`
3. `test: ban intl and formatted values from lib/data and lib/core`

## Gates that must pass

```bash
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs   # ALWAYS before analyze
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos --fatal-warnings
flutter test --test-randomize-ordering-seed random --reporter expanded

# every skill gate, through the one runner E01 built
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

# i18n gates
bash .claude/skills/i18n-rtl-l10n/scripts/check_i18n_bans.sh                          lib
# check_arb_parity.sh is NOT run here: it exits 2 while lib/l10n/ holds only the
# template. E04 ships app_de.arb, app_fa.arb and app_ckb.arb and turns it on.

# the one thing the suite cannot prove — iOS only, Android is deferred
xcrun simctl boot C13DDC02-375D-4E1B-8F81-44EB407D09A4
flutter run -d C13DDC02-375D-4E1B-8F81-44EB407D09A4
```

The block above is this epic's **named spot-checks**, run individually so a failure names itself.
`bash tool/skill_gates.sh` is the authoritative sweep — never a
`for s in .claude/skills/*/scripts/*.sh` loop, which cannot exit 0. This epic creates `lib/core/`, so
**move `check-determinism-bans.sh` from its `lib` argument note in `tool/skill_gates.sh` to whichever
row now reflects reality** and record the change. `check_arb_parity.sh` stays in the skip table with its
reason updated to name E04 as the epic that removes it. The five `sunburst-*` gates and
`check_palette_contrast.sh` are unaffected because E02 touches no theme file.

## Risks and open questions

- **E02 owns the `Result`/`Failure` spine, not E01.** E01 stops at bootstrap, l10n wiring, the iOS
  target and CI; it ships no `lib/core/result.dart`. E02 is the first consumer — every repository method
  returns one — so **T02.2 creates `lib/core/result.dart` and `lib/core/failure.dart` outright**, per
  `error-handling-typed-results`, with no conditional. E07 T07.1 adopts them and extends the taxonomy
  with `lib/core/run_failure.dart`; a second spine is the failure mode, and two hedged "whichever epic
  lands first owns it" clauses are not an owner. `clockProvider` likewise lands here (T02.6) if E01 did
  not need it. Do not restructure anything E01 shipped.
- **E02 now owns `AppSettings`, and E06 must not ship a second one.** Under the old sequence, Motion and
  feedback landed before persistence and shipped `AppSettings` behind an in-memory `Notifier` that
  persistence then re-pointed. That ordering is reversed. **Decision:** `lib/core/app_settings.dart` is
  created here with five fields, `settingsProvider` is a `StreamProvider` over the repository, and there
  is no `AppSettingsNotifier` at any point. E06 reads `settingsProvider` and writes through
  `settingsRepositoryProvider.update`; if E06 finds itself declaring an in-memory notifier, that is the
  defect, and its epic text needs the same correction this one got.
- **The `ckb` `flutter_localizations` delegate gap is real and is E04's to solve, not this epic's.**
  `GlobalMaterialLocalizations`/`GlobalCupertinoLocalizations` ship for a fixed locale list and `ckb` is
  very likely not on it; a missing delegate throws at runtime the moment the locale switches. E02 stores
  the tag and hands E04 a validated `SupportedLocale`; it does **not** verify the delegate list and must
  not be read as having done so. What E02 does contribute is the failure mode that makes the gap
  survivable: a `ckb` tag that a future build cannot serve degrades to "follow system" on read instead of
  throwing, and the tag is preserved so it works again when support returns.
- **Sorani glyph coverage is unverified here.** Whether Lalezar covers ڕ ڵ ۆ ێ ھ, and whether Vazirmatn
  Bold has to carry display for `fa`/`ckb` instead, is E04's task and its outcome is recorded there. This
  epic stores three ASCII letters; nothing in `lib/data/` renders a glyph. Flagged so nobody reads the
  presence of `SupportedLocale.ckb` as evidence that `ckb` renders correctly.
- **Translation quality is an open question, not a solved one.** Nothing in this epic produces Persian or
  Sorani text. When E04 does, machine-quality Sorani in particular is a real risk and needs a native
  speaker's review before ship. Recorded here only so the locale column is not mistaken for locale
  support.
- **`locale_tag` has no closed `CHECK … IN`, deliberately.** A closed list would put every row that names
  a withdrawn locale into permanent violation, so the next settings write fails for exactly the users who
  chose it. **Decision:** shape `CHECK` in the schema (ASCII, lowercase, 2–35 characters), supported-set
  validation on read in T02.4, degrade to "follow system" and log, never rewrite the column. The cost is
  that a garbage-but-well-shaped tag can sit in the DB; the test asserts it is harmless.
- **Nothing has verified `intl`'s number-symbol coverage for `ckb` on this toolchain.** The
  `i18n-rtl-l10n` skill states that `intl` has no symbols for `ckb` and that it must borrow `fa`. E02
  cannot check this because it imports no `intl` — that is the point. **E04 must verify it at build time
  and pin the numbering system explicitly rather than assuming**, and this epic's canonical-storage tests
  are what guarantee that whichever way it resolves, no stored row moves.
- **`lib/core/` is already in `CLAUDE.md`.** E01 amended the layout block once, adding `core/`,
  `shared/motion/` and `l10n/`, and `test/policy/project_structure_test.dart` reads that block. **Do not
  propose the amendment again in this PR** — the pure value objects, `SupportedLocale`,
  `StreakCalculator` and the `IdGenerator` interface go in `lib/core/` as the sanctioned pure-foundation
  layer (`project-structure-and-packages` rule 7) with no further ceremony.
- **No foreign key exists at schema v1.** Two independent tables, no relation. Inventing a `games` table
  to manufacture one would create a second authority for game identity against the E07 registry.
  **Decision:** ship without an FK, keep `foreign_keys = ON` and the `foreign_key_check` assertion so the
  first relation is enforced the day it lands, and say so in the PR body rather than quietly omitting it.
- **The migration test at v1 is a round-trip, not a v1→v2 upgrade.** There is no shipped prior version to
  migrate from, and a green test that proves nothing is worse than an admitted gap
  (`testing-strategy` rule 11). **Decision:** T02.10 delivers the harness, the hostile-fixture content
  round-trip, the all-pairs loop (vacuous today, correct forever) and the restore proof. The old plan
  named `locale_tag` as the likely first bump; that column now ships in v1, so **there is no scheduled
  first migration at all** and the harness will sit unused until a real one arrives. Saying so is more
  honest than inventing a placeholder.
- **`flutter test` runs in a plain Dart VM where `sqlite3_flutter_libs` does nothing.** The host falls
  back to the system `libsqlite3` — a real version-skew risk against the FFI library shipped on the
  device, and `STRICT` tables need SQLite ≥ 3.37. This machine reports 3.44.3. **Decision:** T02.3
  asserts `sqlite_version()` ≥ 3.37 in the suite so a stale host fails loudly, T02.1 makes the CI test
  job's provisioning match its actual runner, and T02.9 records the on-device version beside the host
  version in the PR body. The two are different libraries and no automated gate compares them.
- **iOS data protection is on its default class and that is currently fine.** iOS applies
  `NSFileProtectionCompleteUntilFirstUserAuthentication` to app-container files, which a foreground-only
  app can always read. MindForge schedules no background work today, so no override is needed. **If a
  later epic adds a background task or a notification handler that touches the DB, this must be
  revisited** — a stricter class would make the store unreadable while the device is locked, and the
  symptom would be an intermittent open failure that no test reproduces.
- **`metric_kind` is stamped per run from the E07 registry, which does not exist yet.** T02.6's
  registry-id guard therefore takes an injected predicate rather than importing a registry.
  **Decision:** ship the predicate seam; E07 supplies the real one. The *value* is not a risk: T02.2
  fixes `ScoreFormat` as the single score enum in `lib/core/`, and E07's `GameDefinition.scoreFormat`
  imports it rather than declaring a parallel `MetricKind`.
- **`RunScope` holds plain strings; `GameId` and `Difficulty` are E07 types.** E08's screens hold the
  typed ids and call `personalBestProvider(RunScope)`, so something has to convert. **Decision:** E02
  ships `RunScope(String gameId, String? difficultyId)` — it cannot import E07 types that do not exist
  yet — and **E07 T07.3 adds the single conversion `RunScope.of(GameId, Difficulty?)` to that same
  file**, which is then the only place a typed id becomes a persisted string. No screen builds a
  `RunScope` by hand.
- **Reduce motion is both an OS signal and an app toggle.** The `settings` table stores only the user's
  toggle; the effective value is `MediaQuery.disableAnimations || settings.isReduceMotionEnabled` and is
  resolved by E06's `MotionPreferenceScope`, not here. Flagged so nobody wires the stored toggle as the
  sole authority.
- **`AuditColumns` brings soft-delete columns MindForge has no UI for.** Keeping them is the house rule
  and the partial UNIQUE index depends on `is_deleted = 0`. **Decision:** keep them, filter every read
  through one `_baseSelect()` helper, and ship no delete method in E02.

## Definition of done

- [ ] All eleven tasks complete, each with its tests written before its implementation and committed
      alongside the code they cover.
- [ ] `lib/data/` holds the database, connection, tables, DAOs and repositories; `lib/core/` holds the
      `Result`/`Failure` spine, `ScoreFormat`, `SupportedLocale`, `AppSettings` and the pure value
      objects and calculators; `test/` mirrors both 1:1.
- [ ] There is exactly one `sealed class Result`, one score enum and one locale enum in the repo
      (`grep -rn 'sealed class Result\|enum ScoreFormat\|enum MetricKind\|enum SupportedLocale' lib/`
      returns three lines).
- [ ] `saveRun` returns `RunCommit(record, isPersonalBest)` with the flag computed inside the same
      transaction; no `StatsRepository` exists, and `watchBestsByGame()` is the all-games fold Home reads.
- [ ] `package:drift` and `package:sqlite3` are imported only under `lib/data/`; no Drift symbol appears
      in any public signature outside it; `package:sqflite` appears nowhere.
- [ ] Both tables are `STRICT`; every enumerable the data layer interprets has a `CHECK … IN`; every
      range has a `CHECK`; every identifier column has an ASCII shape `CHECK`; `ux_runs_client_key` is a
      partial `UNIQUE INDEX`; the pragmas are re-asserted on every open; seeding happens only under
      `if (details.wasCreated)`.
- [ ] Every mutation is exactly one `db.transaction` with every query awaited; each fallible repository
      method returns `Result<T, DataFailure>`; no recoverable failure throws across a layer.
- [ ] Personal best, aggregates and the streak are folds over `runs` — no column, table or cached field
      stores a derived value; the decision for each field is written into the schema task and the PR body.
- [ ] `locale_tag` ships in schema v1, round-trips `en`/`de`/`fa`/`ckb`, clears to `NULL` through
      `withSystemLocale()`, and degrades an unrecognised tag to "follow system" with one log line and no
      throw and no rewrite.
- [ ] Nothing under `lib/data/` or `lib/core/` imports `package:intl` or names `NumberFormat`,
      `DateFormat` or `AppLocalizations`; the four-locale fixture produces identical row sets; the ASCII
      sweep over `pragma_table_info` finds nothing.
- [ ] `test/data/reference_fixture_test.dart` reproduces every quantity behind screens 02, 06 and 07 as
      a number, and the streak test reproduces the `4` behind screen 01's chip.
- [ ] `drift_schemas/drift_schema_v1.json`, `schema_versions.dart` and `test/drift/generated/**` are
      committed and diff-clean against a fresh dump.
- [ ] `grep -rn "DateTime.now()" lib/` is empty; the two-container clock test proves the streak is driven
      by the injected `Clock`; the four-locale streak test proves it is driven by Gregorian civil days.
- [ ] The app opens its database on `MindForge iPhone 14` (`C13DDC02-375D-4E1B-8F81-44EB407D09A4`), and
      the container path, `integrity_check`, `journal_mode` and on-device `sqlite_version()` are recorded
      in the PR body. No Android claim is made.
- [ ] `/simplify` run and its findings addressed.
- [ ] `/code-review` run and its findings addressed.
- [ ] Every command under "Gates that must pass" is green locally.
- [ ] Pushed to `epic/02-persistence-layer`; PR body states what changed, why, how it was verified,
      that no screen was compared because the epic has no visual surface (naming the fixture test and the
      locale-independence test that stand in for one), and what was deliberately left out — the FK, the
      `LocaleNumbers` formatter (E04), the ARB parity gate (E04, which ships the locale files), **any
      backup/export/import path (v1 ships none; E11's on-device pass records the same omission)**, any
      durable crash sink, any run-deletion UI, and any Android support.
- [ ] CI green on the PR, including the `*.drift.dart` and `drift_schemas/` freshness gates.
- [ ] Merged preserving the granular commits, branch deleted, back on `main`, pulled.
