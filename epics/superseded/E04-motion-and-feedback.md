> **SUPERSEDED — do not build from this file.** It plans the old ten-epic sequence, written
> before the four-locale/two-direction and iOS-only requirements landed. It is superseded by
> [`../E06-motion-and-feedback.md`](../E06-motion-and-feedback.md) — **E06 · Motion and feedback**. Kept for the record only; the live set is the
> eleven files in `epics/`, indexed by [`../README.md`](../README.md).

# E04 · Motion and feedback

| | |
|---|---|
| **Branch** | `epic/04-motion-and-feedback` |
| **Depends on** | E01, E02, E03 |
| **Unblocks** | E07, E08, E09 |
| **Status** | Not started |

## The epic

Fill in the sensory layer whose **seam E03 already shipped**: `lib/shared/feedback/` (the `Moment` enum
extended with duration and curve roles, the eighteen-row moment catalog as data, `HapticGateway`, and
the real `FeedbackService` that replaces E03's `SilentFeedbackService` no-op) and `lib/shared/motion/`
(`PressPhysics` — E03's stub becomes the real interruptible controller — plus the two bounded motion
primitives `PopCelebration` and `ShakeOnWrong`, and the root `MotionPreferenceScope` that folds the
Settings "Reduce motion" row into `MediaQuery.disableAnimations`). `HapticFeedback.*` appears in exactly
one file after this epic; `heavyImpact` appears exactly once in the whole app.

E03 T03.3 created three files it could not ship a pressable surface without — `moment.dart`,
`feedback_service.dart` (interface + `SilentFeedbackService` + `feedbackServiceProvider`) and
`press_physics.dart` — and recorded in its Risks that **E04 replaces the implementations and owns the
moment → haptic map, but does not rewrite the seam and must not add a second press controller.** This
epic honours that: it edits those three files, it does not create them. `PopSurface`'s public
constructor is E03's contract and gains exactly one optional parameter. Nothing here renders a screen;
every consumer of this epic is E07, E08 and E09.

`ShakeOnWrong` is created **here**, at `lib/shared/motion/shake_on_wrong.dart`, and is the only copy in
the repository: E08's answer key and E09's tile both wrap it. A per-game copy under `lib/games/**` is a
review reject on that epic.

## Why we need it

Without this epic every later screen invents its own press, its own duration and its own haptic. That
is the failure mode `sunburst-motion-and-haptics` exists to prevent: two press implementations diverge
the day one of them learns about reduce-motion, and ad-hoc haptics only ever escalate until a wrong
answer punishes the player with `heavyImpact`. The catalog is also the only place the design's
non-negotiables become machine-checkable — that nothing exceeds 240ms, that nothing repeats without a
stop condition, that every moment still lands with Sound off + Haptics off + Reduce motion on.

Concretely, until E04 lands: `PopSurface` either has no press or has a second one; E07 cannot build
the countdown, the pause sheet or the results reveal because their beats are undefined; E08 cannot
implement `answerCorrect`/`answerWrong`; E09 cannot implement `tileFound`/`tileNextCue`; and
`check_motion_tokens.sh` is green only because there is nothing to scan.

## Current state

Verified by `ls` and `git log` on `main` at the time of writing (4 commits, tip `cb1c3e2`):

- **No Flutter app.** No `pubspec.yaml`, no `lib/`, no `test/`, no `.github/`. Repository root holds
  `CLAUDE.md`, `design/`, `50-apps-challenge-slides.html`, `.claude/`.
- **`lib/shared/feedback/` and `lib/shared/motion/` arrive with E03, not with this epic.** E03 T03.3
  ships `lib/shared/feedback/moment.dart` (the eighteen-value enum, no behaviour),
  `lib/shared/feedback/feedback_service.dart` (`abstract interface class FeedbackService`, a
  `SilentFeedbackService` no-op, `feedbackServiceProvider`) and `lib/shared/motion/press_physics.dart`
  (`PressGeometry`, `PressBuilder`, `PressPhysics`) — because `PopSurface` cannot be pressable without
  them and rule 2 of both press skills forbids a second implementation. **This epic edits all three; it
  creates none of them.** If `ls lib/shared/` comes back empty when this branch opens, that is an E03
  gap: stop and fix E03 rather than creating the files here, or the seam exists twice.
- `.claude/skills/sunburst-motion-and-haptics/` is complete and is the specification for this epic:
  - `SKILL.md` — twelve rules and the eighteen-row summary table.
  - `references/moment-catalog.md` — exact offsets, amplitudes and latch names per row.
  - `references/press-physics.md` — derived press geometry, the state-vs-animation split, interruption.
  - `references/haptics-map.md` — moment → verb, the commit-frame rule, the three Settings gates.
  - `examples/press_physics.dart` — a working `PressPhysics` / `PressGeometry` / `PressBuilder`.
  - `examples/feedback_moments.dart` — `StroopRunNotifier`, `StroopStimulusCard`, `ShakeOnWrong`,
    `SchulteTile`, `PersonalBestBadge`.
  - `scripts/check_motion_tokens.sh` — runs today and prints `note: 'lib' not found; nothing to scan.`
- `design/sunburst-pop/system.html` §09 Motion fixes the four durations, the three curves, the 240ms
  ceiling and the "press transform is dropped, pressed colour and shadow still apply" sentence.
- `design/sunburst-pop/screens/` holds the eight PNGs. **None of them shows a press, a haptic or a
  reduce-motion frame** — they are end states only. The pause sheet has no PNG at all.
- **Assumed present when this epic starts** (they are E01/E02/E03 deliverables, not verified here):
  `SunburstMotion` with `durTap/durState/durMove/durCelebrate`, `easePop/easeOut/easeInOut`,
  `resolve(context, duration)` and `of(context)`; `SunburstShape` with `pressTranslate`,
  `pressedShadow`, `pressScale`, `pressScaleSmall`, `e1…e4`, `shadow()`; `PopSurface`, `PopElevation`
  and `kPopMinTarget` in `lib/ui/components/pop_surface.dart`; the three seam files listed above;
  `test/support/harness.dart` (`Device`, `Device.all` at DPR 2, `pumpApp`) from E02 and
  `test/support/fake_feedback_service.dart`, `test/support/load_app_fonts.dart` and `dart_test.yaml`'s
  `golden` tag from E03; `lib/app.dart` from E01, themed by E02. If any of these is missing or
  differently named, stop and fix the dependency epic — do not shim it here.

## What we will achieve

A reader can tell this epic is done by running these and reading the result:

- `.claude/skills/sunburst-motion-and-haptics/scripts/check_motion_tokens.sh lib` prints
  `OK: motion values tokenized, haptics confined to the feedback service, nothing repeating.` over
  real code, not over an absent directory.
- `grep -rn "HapticFeedback\." lib/` returns exactly one file: `lib/shared/feedback/haptic_gateway.dart`.
- `grep -rn "heavyImpact" lib/` returns the enum declaration, the one catalog row for
  `Moment.personalBest`, and the gateway's switch arm — and nothing else.
- `flutter test test/shared/` is green, including: the fake gateway records exactly **one** verb per
  `fire()`; firing all eighteen moments records exactly one `heavyImpact`; every `Moment` has a
  catalog row with a non-empty residue channel set; no role resolves above `durCelebrate`; a press
  under `disableAnimations: true` has zero translate and zero scale but a `(1,1)` shadow and
  `isDown == true` on the pointer-down frame.
- `Moment` has eighteen values, matching `references/moment-catalog.md` row for row.
- `PopSurface` contains no `GestureDetector` and no `AnimationController`; it passes four numbers and
  a `Moment` to `PressPhysics` and paints the frame it is handed.
- The app is wrapped once in `MotionPreferenceScope`, and E07 T07.9 re-points its provider at the real
  repository rather than adding a second fold. `grep -rn "isReduceMotionEnabled" lib/` returns only
  `lib/core/app_settings.dart`, the settings notifier, `motion_preference_scope.dart` and — once E07
  lands — the Settings screen row that writes it. No other widget reads it.
- A human running the app on a device with Sound off, Haptics off and Reduce motion on can still press
  every control and see it acknowledge: the fill deepens and the shadow collapses to `(1,1)` instantly.

## Skills to load

| Skill | Why, for this epic |
|---|---|
| `flutter-conventions-index` | The front door and the routing table; house rules 8 (side effects behind injected interfaces), 9 (async is never silent) and 10 (complexity limits) all bind directly here. |
| `sunburst-motion-and-haptics` | The specification. Owns the eighteen moments, the four durations/three curves, the press geometry, the latch rules, the residue rule and `check_motion_tokens.sh`. Read `SKILL.md` plus all three `references/` files before T04.1. |
| `motion-and-haptics` | The generic discipline the sunburst rows sit on: why moments are named, the commit-frame rule, interruptibility, celebration budgets, multi-channel redundancy, "motion decorates state but is never the state". |
| `sunburst-tokens` | `SunburstMotion.resolve` is the only place a widget asks whether to animate; `durTap`/`easePop` and `shape.pressTranslate`/`pressedShadow`/`pressScale` are read, never typed. Also the raw-value gate this epic must stay clean under. |
| `sunburst-components` | Owns `PopSurface`, `PopElevation`, `kPopMinTarget` and the press *chrome* (rest/pressed/disabled triples, hit area outside the transform). T04.7 changes `PopSurface`'s internals and must not touch its contract. |
| `service-boundary-and-native` | `HapticGateway` is a boundary: an `abstract interface class`, one live impl, one hand-written fake, a provider that throws `UnimplementedError` until the composition root overrides it. Also the ban on `DateTime.now()` that `check-service-boundaries.sh` enforces. |
| `state-management-riverpod` | `AppSettings` (E05's value type, shipped here in memory) as one immutable value behind a `Notifier` with intent methods; `feedbackServiceProvider` as plain DI; the watch/read split (`ref.read` in callbacks, never `ref.watch`); no legacy providers. |
| `naming-conventions` | `Gateway` = wrapper over a platform API, `Service` = capability interface we define, `Live[Concern]Gateway` for the impl, file name = primary declaration. This epic introduces both suffixes at once and they must not be swapped. |
| `dart3-idioms-and-coding-standards` | `Moment`, `HapticVerb`, `SoundCue`, `MotionRole`, `ResidueChannel` are enums; `MomentSpec` is a hand-rolled immutable value; every `switch` over them is exhaustive with no `default:`. Also the complexity limits `PressPhysics` must respect. |
| `dartdoc-conventions` | Every public declaration here is a contract other epics build on; rule 8 (restate the enforced invariant at its enforcement point) is why the latch, the commit-frame fire and the reduce-motion branch each carry a `//` stating what they uphold. |
| `async-safety` | `HapticFeedback.*` returns a `Future`. `fire()` is `void` and does `unawaited(... .catchError(...))` inside; `onTap:` never holds a Future; the press and celebration controllers are disposed; `mounted` is checked after the await in the two-cycle shake. |
| `widget-composition` | `PressPhysics`, `PopCelebration` and `ShakeOnWrong` are `const` widget classes with disposed controllers, not `_buildX()` helpers; identity, not content, is captured in callbacks. |
| `accessibility-as-code` | Rule 3 — a11y state is read from `MediaQuery`, never from app state — is exactly why the Settings toggle is folded in at the root instead of watched per widget. Also the never-colour-alone floor the residue channels satisfy. |
| `testing-strategy` | Bare-`implements` fakes over mocks; `ProviderContainer` for headless notifier tests; assert invariants (every moment has a row) rather than examples; no mocked gateway. |
| `widget-golden-and-a11y-testing` | `pumpApp` with a pinned 390×844 surface, `pump(duration)` never `pumpAndSettle` on a pressed surface, the reduce-motion golden that must differ from the resting golden, `@Tags(['golden'])`. |
| `flutter-architecture` | Where `shared/feedback` and `shared/motion` sit in the DAG: `ui/components` may import `shared/motion`; `shared/**` may never import `ui/**` or `features/**`. |
| `app-startup-and-bootstrap` | Where `MotionPreferenceScope` mounts relative to `ProviderScope` and `MaterialApp`, and how `hapticGatewayProvider` is overridden in `bootstrap()`. |
| `ci-pipeline-and-gates` | The three-criteria bar for the grep policy test in T04.9, and the rule that a gate must map to one named contract. |

## Tasks

### T04.1 — Extend `Moment` with motion roles, and role resolution
**Goal.** Add the duration/curve *roles* that let a catalog row reference `durTap` without holding a
`Duration`, and pin the eighteen `Moment` values E03 already declared.

**Tests first (TDD).** `test/shared/feedback/moment_test.dart`
- `Moment has exactly eighteen values` — `Moment.values.length == 18` and the name set equals the
  literal set transcribed from `references/moment-catalog.md`. E03 T03.3 transcribed the enum; this
  test is the first thing that holds it to the reference table row for row.

`test/shared/motion/motion_role_test.dart` (pumps a `SunburstMotion` from `buildSunburstTheme()`)
- `every MotionRole resolves to a SunburstMotion duration` — `tap→durTap`, `state→durState`,
  `move→durMove`, `celebrate→durCelebrate`, `none→Duration.zero`.
- `no role resolves above the 240ms ceiling` — for every `MotionRole`,
  `motion.durationFor(role) <= motion.durCelebrate`.
- `every CurveRole resolves to a SunburstMotion curve` — `pop→easePop`, `out→easeOut`,
  `inOut→easeInOut`.
- `role resolution collapses under reduce motion` — under `MediaQuery(disableAnimations: true)`,
  `motion.resolvedDurationFor(context, role)` is `Duration.zero` for every role.

**Implementation.** `lib/shared/feedback/moment.dart` **(edit)** — E03 shipped the enum; correct any
value whose name or order drifts from the reference table, and add nothing else to the file: it stays
behaviour-free. New: `MotionRole { tap, state, move, celebrate, none }` and
`CurveRole { pop, out, inOut }`, plus `extension MotionRoleResolution on SunburstMotion` with
`Duration durationFor(MotionRole)`, `Curve curveFor(CurveRole)` and
`Duration resolvedDurationFor(BuildContext, MotionRole)` delegating to `resolve`. Exhaustive
switches, no `default:`. No `Duration(` literal anywhere — `MotionRole.none` returns `Duration.zero`,
which both gate scripts explicitly allow.

**Files.** `lib/shared/feedback/moment.dart` (edit — E03 created it),
`lib/shared/motion/motion_role.dart` (new), `test/shared/feedback/moment_test.dart`,
`test/shared/motion/motion_role_test.dart`.

**Skills.** `sunburst-motion-and-haptics`, `sunburst-tokens`, `dart3-idioms-and-coding-standards`,
`dartdoc-conventions`, `naming-conventions`.

**Screenshot check.** n/a (no visual surface).

**Done when.**
- [ ] `Moment.values.length == 18`; names match `references/moment-catalog.md` row for row.
- [ ] No `Duration(`, `Curves.` or `Cubic(` in either file.
- [ ] `check_motion_tokens.sh lib` and `check_raw_values.sh lib` green.
- [ ] Every public declaration carries a `///` that says what the moment *is*, not what it is called.

**Commits.**
1. `test: assert the eighteen moments and the motion role contract`
2. `feat: add MotionRole and CurveRole with SunburstMotion resolution`

---

### T04.2 — The moment catalog as data
**Goal.** Turn `references/moment-catalog.md` into a `const` Dart table so the design's invariants are
asserted by the test suite instead of by review.

**Tests first (TDD).** `test/shared/feedback/moment_catalog_test.dart`
- `every Moment has exactly one catalog row` — `kMomentCatalog.keys.toSet()` equals
  `Moment.values.toSet()`; length 18.
- `every moment declares a non-motion residue` — `spec.residue` is non-empty for all eighteen, i.e.
  every moment survives Sound off + Haptics off + Reduce motion on (rule 8).
- `heavyImpact is spent exactly once, on personalBest` — the moments whose `haptic` is
  `HapticVerb.heavyImpact` are exactly `{Moment.personalBest}`.
- `answerWrong is never above lightImpact` — asserts the specific regression the skill calls out.
- `declared silences are explicit` — `buttonPress`, `homeCardEnter`, `tileNextCue`, `resultsReveal`,
  `sheetTransition`, `routeTransition` have `haptic == null` **and** a key present in the map.
- `no moment exceeds the celebrate ceiling` — for every spec, `motion.durationFor(spec.duration)` is
  `<= motion.durCelebrate`.
- `nothing repeats without a stop condition` — `spec.cycles` is 1 for every moment except
  `answerWrong`, which is 2, and no spec exceeds 2.
- `boundary moments declare a latch` — `timerAlarm→'hasAlarmed'`, `streakMilestone→'lastMilestone'`,
  `personalBest→'hasPlayed'`, `countdownBeat→'beatIndex'`, `answerWrong→'wrongKeyId'`; every other
  moment declares `null`.
- `every sound slot is one of the nine named cues` — `SoundCue.values.length == 9`.
- `easePop only drives transform` — no spec whose visual change is a colour or opacity cross
  (`answerCorrect`, `difficultySelect`, `tileFound`, `tileNextCue`, `timerAlarm`, `runStart`,
  `sheetTransition`, `routeTransition`) declares `CurveRole.pop`.

**Implementation.** `HapticVerb { selectionClick, lightImpact, mediumImpact, heavyImpact }` — no
`vibrate` value exists, so it cannot be reached. `SoundCue { pop, tick, go, thud, click, chime,
alert, end, fanfare }`. `ResidueChannel { fill, shape, ring, border, word }`. `MomentSpec` as a
hand-rolled `@immutable` value with a `const` constructor and `final` fields: `duration`
(`MotionRole`), `curve` (`CurveRole?`), `cycles` (`int`, default 1), `haptic` (`HapticVerb?`),
`sound` (`SoundCue?`), `residue` (`Set<ResidueChannel>`), `residueNote` (`String`), `latch`
(`String?`). One `const Map<Moment, MomentSpec> kMomentCatalog` transcribed with
`references/moment-catalog.md` open; each entry's `///`-adjacent `//` cites its source row and marks
the six **DERIVED** values as such. An `assert` in `MomentSpec`'s constructor that `residue` is
non-empty and `cycles >= 1` — the runtime tripwire beside the test.

**Files.** `lib/shared/feedback/haptic_verb.dart`, `lib/shared/feedback/sound_cue.dart`,
`lib/shared/feedback/moment_spec.dart`, `lib/shared/feedback/moment_catalog.dart`,
`test/shared/feedback/moment_catalog_test.dart`.

**Skills.** `sunburst-motion-and-haptics`, `motion-and-haptics`, `dart3-idioms-and-coding-standards`,
`dartdoc-conventions`, `testing-strategy`, `accessibility-as-code`.

**Screenshot check.** n/a (no visual surface). The rows that *do* have pixels are checked where they
render: `countdownBeat` against `03-countdown.png` and `timerAlarm`/`streakMilestone` against
`04-stroop-rush.png` in E07/E08.

**Done when.**
- [ ] All eighteen rows present, each traceable to a line in `references/moment-catalog.md`.
- [ ] Every **DERIVED** value is marked `DERIVED` in a comment with its one-line reason.
- [ ] The nine sound slots exist as names only — no asset, no audio dependency, no player.
- [ ] `flutter test test/shared/feedback/moment_catalog_test.dart` green.

**Commits.**
1. `test: assert the moment catalog invariants (residue, heavyImpact, ceiling, latches)`
2. `feat: add HapticVerb, SoundCue and ResidueChannel`
3. `feat: transcribe the eighteen-row moment catalog as MomentSpec data`

---

### T04.3 — `HapticGateway`: the only `HapticFeedback` call site
**Goal.** Put every haptic behind one injected boundary with one live impl and one hand-written fake.

**Tests first (TDD).** `test/shared/feedback/haptic_gateway_test.dart`
- `the fake records each verb exactly once in order` — `play(lightImpact)` twice yields
  `[lightImpact, lightImpact]`.
- `the fake can be told to fail` — `FakeHapticGateway.failing()` returns a `Future` that completes
  with an error, so the failure path in T04.4 is reachable (a fake that always succeeds is a
  happy-path lie).
- `the provider throws until overridden` —
  `expect(() => container.read(hapticGatewayProvider), throwsUnimplementedError)`.
- `the provider serves the override` — with `hapticGatewayProvider.overrideWithValue(fake)` the
  container returns the fake.

`test/policy/haptic_confinement_test.dart` (a source grep, per the three-criteria bar)
- `HapticFeedback is named in exactly one file` — walk `lib/**/*.dart`, assert the only file matching
  `HapticFeedback\.` is `lib/shared/feedback/haptic_gateway.dart`.

**Implementation.** `abstract interface class HapticGateway { Future<void> play(HapticVerb verb); }`.
`final class LiveHapticGateway implements HapticGateway` — the only file that imports
`package:flutter/services.dart` for this purpose, with one exhaustive `switch` from `HapticVerb` to
`HapticFeedback.selectionClick/lightImpact/mediumImpact/heavyImpact` and no `default:`.
`final hapticGatewayProvider = Provider<HapticGateway>((ref) => throw UnimplementedError('override
hapticGatewayProvider in bootstrap()'))`. `final class FakeHapticGateway implements HapticGateway`
under `lib/shared/feedback/testing/` recording `List<HapticVerb> played` with a `failing()` factory.
`bootstrap()` gains `hapticGatewayProvider.overrideWithValue(const LiveHapticGateway())`.

`service-boundary-and-native` rule 4 asks every boundary method for a typed result. This one returns
`Future<void>` deliberately: a haptic that fails on an unsupported device has no recoverable branch
and must never reach the player, so the single `catchError` in `FeedbackService` (T04.5) is the whole
error contract. State that reason in the interface's `///` — it is the kind of exception a reviewer
must see argued, not discovered.

**Files.** `lib/shared/feedback/haptic_gateway.dart`,
`lib/shared/feedback/testing/fake_haptic_gateway.dart`, `lib/bootstrap.dart` (edit),
`test/shared/feedback/haptic_gateway_test.dart`, `test/policy/haptic_confinement_test.dart`.

**Skills.** `service-boundary-and-native`, `naming-conventions`, `state-management-riverpod`,
`testing-strategy`, `dartdoc-conventions`, `app-startup-and-bootstrap`.

**Screenshot check.** n/a (no visual surface).

**Done when.**
- [ ] `grep -rn "HapticFeedback\." lib/` returns exactly `lib/shared/feedback/haptic_gateway.dart`.
- [ ] `HapticVerb` has no `vibrate` value and `HapticFeedback.vibrate` appears nowhere.
- [ ] The fake `implements` (never `extends`) the interface, so a new method breaks the build.
- [ ] `check-service-boundaries.sh lib` and `check_motion_tokens.sh lib` green.

**Commits.**
1. `test: assert haptic gateway contract, failing fake and provider override`
2. `feat: add HapticGateway, LiveHapticGateway and FakeHapticGateway`
3. `test: add the policy grep confining HapticFeedback to one file`
4. `chore: override hapticGatewayProvider in bootstrap`

---

### T04.4 — The one settings gate, and the reduce-motion root fold
**Goal.** Three independent switches (Sound, Haptics, Reduce motion), read in exactly one place each,
with reduce motion folded into `MediaQuery` at the root so no widget ever reads app state to decide
whether to animate.

**One settings value, from the start.** `AppSettings` is E05's persisted value type
(`lib/core/app_settings.dart`, four fields: `isSoundEnabled`, `isHapticsEnabled`,
`isReduceMotionEnabled`, `isColourBlindPalette`) and E07's Settings screen writes all four. This epic
does **not** invent a three-field `FeedbackSettings` beside it: two value types with three overlapping
fields under two spellings is a rename waiting to silently drop a toggle, and E04 has no slot for the
colour-blind flag E08's round generator reads. Instead this task ships `AppSettings` **with E05's exact
field names**, in `lib/core/app_settings.dart`, behind an **in-memory** `Notifier<AppSettings>`. E05
T05.4 re-points that notifier's `build()` at `SettingsRepository.watch()`; E07 T07.9 adds the screen
that writes it. Neither may change the derived read providers or the scope's read.

**Tests first (TDD).** `test/core/app_settings_test.dart`
- `defaults are sound on, haptics on, reduce motion off, colour-blind off` — the four defaults on
  screen 08.
- `copyWith changes one flag and returns a new value` — `copyWith(isHapticsEnabled: false)` leaves the
  other three untouched; the new state is `!identical` to the old.
- `all four off at once is a representable, supported state`.
- `value equality covers every field` — Riverpod diffs by value; a field missing from `==` means a
  toggle that does not rebuild.

`test/shared/motion/motion_preference_scope_test.dart`
- `the app toggle ORs into disableAnimations` — with `isReduceMotionEnabled: true` and a platform
  `disableAnimations: false`, a probe below the scope reads `MediaQuery.disableAnimationsOf == true`.
- `the platform flag wins on its own` — with `isReduceMotionEnabled: false` and platform
  `disableAnimations: true`, the probe still reads `true` (an OR, never an override).
- `every other MediaQuery field is preserved` — `size`, `textScaler`, `padding`, `boldText` and
  `devicePixelRatio` below the scope equal the values above it. (Guards the classic
  `MediaQuery(data: MediaQueryData())` mistake that zeroes the pinned surface.)
- `the scope rebuilds when the toggle flips` — flipping the notifier rebuilds the probe once.

`test/policy/reduce_motion_reads_test.dart`
- `nothing decides whether to animate from app state` — grep `lib/` for `isReduceMotionEnabled`. The
  permitted files are `lib/core/app_settings.dart`, `lib/shared/feedback/app_settings_notifier.dart`,
  `lib/shared/motion/motion_preference_scope.dart` and **`lib/features/settings/**`** — the Settings
  screen must be able to render and write the toggle, and E07 T07.9 lands exactly that. The assertion
  that carries the meaning is the narrower one: **no file outside `motion_preference_scope.dart` passes
  it to a `Duration`, a `Curve` or an `AnimationController`.** Say that in the `reason:`, so the test
  survives E07 instead of turning red the day the Settings screen exists.

**Implementation.** `lib/core/app_settings.dart` — `@immutable final class AppSettings` with a `const`
constructor, four `bool` fields (`isSoundEnabled`, `isHapticsEnabled`, `isReduceMotionEnabled`,
`isColourBlindPalette`), `copyWith`, `==`/`hashCode`. It lives in `lib/core/` because E05's repository
and E08's round generator both read it and neither may import `lib/shared/`.
`AppSettingsNotifier extends Notifier<AppSettings>` in `lib/shared/feedback/app_settings_notifier.dart`
with four intent methods; every transition assigns a new value. `appSettingsProvider` as
`NotifierProvider`, plus derived `hapticsEnabledProvider` / `soundEnabledProvider` as `Provider<bool>`
over `appSettingsProvider.select(...)`. `MotionPreferenceScope extends ConsumerWidget` reading
`appSettingsProvider.select((s) => s.isReduceMotionEnabled)` and returning
`MediaQuery(data: media.copyWith(disableAnimations: media.disableAnimations || reduce), child: child)`
— built from `MediaQuery.of(context).copyWith`, never a bare `MediaQueryData()`. **Mounted once, in
`lib/app.dart`, above `MaterialApp`**, and that mounting point is final: E07 T07.9 re-points the
provider it reads and does not add a second fold in `MaterialApp.router(builder:)`. Two folds would OR
twice, pass every test, and be obviously wrong to read.

State in a `///` on the notifier that this is an **in-memory** store: E05 gives it a repository and
E07 gives it the Settings screen, and both extend the write path without changing these read
providers or the scope's mounting point. `accessibility-as-code` rule 3 (never read a11y state from app
state) is satisfied because this is the single, root-level provider read that *produces* the
`MediaQuery` everything else reads — say so in a `//` at the `copyWith`.

**Files.** `lib/core/app_settings.dart`, `lib/shared/feedback/app_settings_notifier.dart`,
`lib/shared/motion/motion_preference_scope.dart`, `lib/app.dart` (edit),
`test/core/app_settings_test.dart`,
`test/shared/motion/motion_preference_scope_test.dart`,
`test/policy/reduce_motion_reads_test.dart`.

**Skills.** `state-management-riverpod`, `accessibility-as-code`, `sunburst-motion-and-haptics`,
`app-startup-and-bootstrap`, `dart3-idioms-and-coding-standards`, `widget-golden-and-a11y-testing`.

**Screenshot check.** n/a (no visual surface). The Settings rows that drive these flags are E07's and
are compared against `08-settings.png` there.

**Done when.**
- [ ] `AppSettings` has exactly the four fields E05 persists, spelled the way E05 spells them; there is
      no `FeedbackSettings` type anywhere.
- [ ] `MotionPreferenceScope` is mounted exactly once, in `lib/app.dart`, and the PR body states that
      E07 re-points its provider rather than adding a second fold.
- [ ] The fold is an OR; a device with the OS flag on cannot be re-enabled by the app switch.
- [ ] `ban-legacy-providers.sh` green.

**Commits.**
1. `test: assert AppSettings defaults, copyWith and the all-off configuration`
2. `feat: add AppSettings, its in-memory notifier and the derived gate providers`
3. `test: assert the reduce-motion fold ORs into MediaQuery and preserves every other field`
4. `feat: add MotionPreferenceScope and mount it once in app.dart`

---

### T04.5 — Replace `SilentFeedbackService` with the real gated implementation
**Goal.** The one API feature code calls — `ref.read(feedbackServiceProvider).fire(Moment.x)` — that
resolves a moment to its verb and sound slot, applies the settings gates once, and can never fire
twice or throw. E03 shipped the interface and a no-op behind `feedbackServiceProvider`; this task makes
the provider serve a real implementation without changing the interface or the provider's name.

**Tests first (TDD).** `test/shared/feedback/feedback_service_test.dart` (plain constructor args, no
container needed except for the wiring test)
- `fire plays exactly one verb` — for each of the twelve moments with a verb, `fake.played.length == 1`.
- `a declared silence plays nothing` — for each of the six `null`-verb moments, `fake.played.isEmpty`.
- `firing all eighteen moments spends heavyImpact exactly once` —
  `fake.played.where((v) => v == HapticVerb.heavyImpact).length == 1`.
- `haptics off silences the gateway` — `hapticsEnabled: false`, fire everything, `fake.played.isEmpty`.
- `sound off does not silence the haptic` — `soundEnabled: false`, `fire(Moment.answerCorrect)` still
  records `lightImpact`; `soundCueFor` returns `null`.
- `sound on returns the moment's slot` — `soundCueFor(Moment.personalBest) == SoundCue.fanfare`.
- `reduce motion does not suppress a haptic` — the service takes no motion input at all; assert the
  constructor has no such parameter and that firing under a `disableAnimations: true` pump still
  records the verb. This is the "early return placed above `fire()`" bug the skill names.
- `a throwing gateway does not surface` — `FakeHapticGateway.failing()`, `fire(...)` returns
  normally, the zone records no unhandled error, and the failure is logged once.
- `fire returns void` — a compile-time shape assertion via a `VoidCallback` binding, so the
  arrow-callback Future-drop hole is unreachable from a call site.

`test/shared/feedback/feedback_service_provider_test.dart`
- `the provider rebuilds when a gate flips` — flipping `hapticsEnabled` yields a service instance that
  no longer reaches the gateway.

**Implementation.** `lib/shared/feedback/feedback_service.dart` **(edit)**: keep
`abstract interface class FeedbackService` and `feedbackServiceProvider` exactly as E03 declared them —
every E03 component already calls through them. Add `final class LiveFeedbackService implements
FeedbackService` with a `const` constructor taking
`{required HapticGateway gateway, required bool hapticsEnabled, required bool soundEnabled}` — plain
bools, so every test above is a unit test. `void fire(Moment moment)` looks the moment up in
`kMomentCatalog`, returns early if `!hapticsEnabled`, and otherwise
`unawaited(_gateway.play(verb).catchError(_swallow))` where `_swallow` logs with its stack and
returns. `SoundCue? soundCueFor(Moment)` returns the slot or `null` when `soundEnabled` is false.
`feedbackServiceProvider` is re-pointed — same name, same type — at a plain `Provider<FeedbackService>`
watching `hapticGatewayProvider` and `appSettingsProvider` and returning a `LiveFeedbackService`.
`SilentFeedbackService` stays: it is what `test/support/` and any headless container use, and deleting
it would leave every notifier test needing a gateway. Keep the `//` above `unawaited` stating why this
seam is `void` — `async-safety`'s comment that must survive a tidy-up.

**Files.** `lib/shared/feedback/feedback_service.dart` (edit — E03 created it),
`test/shared/feedback/feedback_service_test.dart`,
`test/shared/feedback/feedback_service_provider_test.dart`.

**Skills.** `sunburst-motion-and-haptics`, `motion-and-haptics`, `async-safety`,
`state-management-riverpod`, `service-boundary-and-native`, `testing-strategy`, `dartdoc-conventions`.

**Screenshot check.** n/a (no visual surface).

**Done when.**
- [ ] `fire` is `void`, gated once, and calls the gateway at most once per invocation.
- [ ] `heavyImpact` reaches the gateway only for `Moment.personalBest`.
- [ ] Reduce motion is nowhere in this file.
- [ ] No call site anywhere checks a settings flag before calling `fire` (the second gate is the one
      that gets forgotten).

**Commits.**
1. `test: assert exactly-once firing, the three gates and the failing-gateway path`
2. `feat: add LiveFeedbackService with the single settings gate`
3. `refactor: serve LiveFeedbackService from the existing feedbackServiceProvider`

---

### T04.6 — Replace E03's stub `PressPhysics` with the real controller
**Goal.** One interruptible controller at `durTap`, the state-vs-animation split under reduce motion,
and the commit haptic fired exactly once — handed geometry, never choosing it. E03 shipped
`lib/shared/motion/press_physics.dart` with the `PressGeometry`/`PressBuilder`/`PressPhysics` shapes so
`PopSurface` could be pressable; this task fills in the timing behind the same public signatures.

**Tests first (TDD).** `test/shared/motion/press_physics_test.dart` (`useDevice(390×844)` +
`pumpApp`, `pump(duration)` never `pumpAndSettle`)
- `pointer down fires no haptic` — tap down only; `fake.played.isEmpty`.
- `a commit fires exactly one haptic and runs onPressed once` — full tap; `fake.played.length == 1`
  and the callback counter is 1.
- `a cancelled gesture fires nothing and changes nothing` — `onTapCancel`; no haptic, no callback,
  and the geometry returns to `restShadow`.
- `a disabled surface never drives the controller` — `onPressed: null`; the builder's
  `PressGeometry.t` stays 0 through a full tap-down.
- `the shadow interpolates from rest to pressed` — at `t == 1` the builder receives
  `SunburstShape.pressedShadow`; at `t == 0`, `restShadow`.
- `a tap mid-animation resolves to the end state` — tap down, `pump(durTap ~/ 2)`, release,
  `pump(durTap)`; the geometry is exactly the rest state, and the controller value is 0. Asserts
  `animateTo`/`animateBack` behaviour rather than `forward`/`reverse` from a reset.
- `reduce motion keeps the state and drops the transform` — under `disableAnimations: true`, on the
  pointer-down frame with **no** pump of `durTap`: `isDown == true`, shadow == `pressedShadow`, and
  the `Transform.translate` offset is `Offset.zero` with `Transform.scale` at 1.0.
- `the hit area does not move` — `tester.getRect(find.byType(GestureDetector))` is identical before
  and during the press.
- `the minimum target is honoured` — the gesture's rect is ≥ `kPopMinTarget` on both axes.
- `the controller is disposed` — pump the widget out mid-press; no "ticker was disposed" and no
  pending-timer failure.

**Implementation.** `lib/shared/motion/press_physics.dart` **(edit — E03 created it)**, following
`.claude/skills/sunburst-motion-and-haptics/examples/press_physics.dart`: `@immutable PressGeometry`
(`t`, `shadow`, `isDown`), `typedef PressBuilder`, and `PressPhysics extends ConsumerStatefulWidget`
taking `restShadow`, `pressedShadow`, `travel`, `scale`, `minTarget`, `builder`, `commitMoment`,
`child`, `onPressed`. One `AnimationController` with its duration set in `didChangeDependencies` from
`SunburstMotion.of(context)`; `_drive` sets `value` directly when `resolve` returns `Duration.zero`
and `animateTo` otherwise. `GestureDetector` (opaque) outside the `ConstrainedBox` and both
`Transform`s. **No** `Semantics` here — `PopSurface` owns the button semantics. **No** elevation enum
here — this widget takes the four numbers already resolved.

**Files.** `lib/shared/motion/press_physics.dart` (edit), `test/shared/motion/press_physics_test.dart`,
`test/support/harness.dart` (extend E02's file if it lacks a reduce-motion wrapper; never fork it).

**Skills.** `sunburst-motion-and-haptics` (read `references/press-physics.md` in full),
`sunburst-components`, `sunburst-tokens`, `widget-composition`, `async-safety`,
`widget-golden-and-a11y-testing`, `dart3-idioms-and-coding-standards`.

**Screenshot check.** n/a (no visual surface of its own — `PressPhysics` paints nothing and calls
back into a builder). The pressed chrome is checked in T04.7.

**Done when.**
- [ ] Exactly one `AnimationController` and one `GestureDetector` in the file.
- [ ] No `Duration(`, no `Curves.`, no `PopElevation`, no `HapticFeedback`.
- [ ] Reduce motion drops the transform and keeps the shadow and `isDown`, on the pointer-down frame.
- [ ] `check_motion_tokens.sh lib`, `check_raw_values.sh lib`, `check-widget-composition.sh` green.

**Commits.**
1. `test: assert press commit-once, cancel, interruption and reduce-motion split`
2. `feat: drive PressPhysics with one interruptible controller at durTap`
3. `test: assert the hit area never moves with the press`

---

### T04.7 — Compose `PressPhysics` into `PopSurface`; delete the second press path
**Goal.** One press implementation in the repository. `PopSurface` resolves the geometry from
`PopElevation` and `SunburstShape`, hands it to `PressPhysics`, and paints the frame it is given.

**Tests first (TDD).** `test/ui/components/pop_surface_press_test.dart`
- `PopSurface passes the derived geometry, never a literal` — for `PopElevation.e2`, the
  `PressPhysics` it builds receives `restShadow == shape.e2`, `travel == shape.pressTranslate(shape.e2).dx`,
  `pressedShadow == SunburstShape.pressedShadow`, `scale == shape.pressScale`; for `e1`,
  `shape.pressScaleSmall`.
- `the ghost button derives its 2px travel` — `PopElevation.e1` + `borderStyle: none` yields
  `travel == 2` with no shadow drawn.
- `pressing a PopButton fires exactly one buttonCommit` — `fake.played` is `[lightImpact]`.
- `a Schulte-style tile passes its own commit moment` — a `PopSurface` given
  `commitMoment: Moment.tileFound` records `selectionClick`, proving the moment is a parameter and
  not hardcoded to `buttonCommit`.
- `the existing PopSurface contract is unchanged` — E03's `pop_surface_test.dart` passes untouched.

`test/policy/single_press_implementation_test.dart`
- `no component drives its own press` — grep `lib/ui/components/**`: no `AnimationController`, no
  `onTapDown`, no `onTapCancel`. The only permitted file naming them is
  `lib/shared/motion/press_physics.dart`.

**Golden lane.** `test/goldens/press_test.dart`, tagged `@Tags(['golden'])`, following the pinned-phase
recipe in `references/press-physics.md`: `startGesture`, `pump()`, `pump(durTap)`, then
`matchesGoldenFile`. Three files: `pop_button_rest.png`, `pop_button_pressed.png`,
`pop_button_pressed_reduce_motion.png` — and an assertion that the reduce-motion golden **differs**
from the resting golden, which is what catches a future "simplification" of the reduce-motion branch
into a no-op.

**Implementation.** Remove `PopSurface`'s own gesture handling and press controller. `PopSurface`
computes `elevation.restOffset(shape)`, `shape.pressTranslate(rest)`, `SunburstShape.pressedShadow`
and `elevation.pressScale(shape)`, then wraps its decoration builder in `PressPhysics` with
`minTarget: kPopMinTarget` and the caller's `commitMoment` (defaulting to `Moment.buttonCommit`).
`PopSurface`'s public constructor gains one optional `Moment commitMoment` parameter and loses
nothing. The disabled path keeps `onPressed: null` so the controller is never driven.

**Files.** `lib/ui/components/pop_surface.dart` (edit), any component that reimplemented a press
(edit), `test/ui/components/pop_surface_press_test.dart`,
`test/policy/single_press_implementation_test.dart`, `test/goldens/press_test.dart`,
`test/goldens/press/*.png`.

**Skills.** `sunburst-components`, `sunburst-motion-and-haptics`, `sunburst-tokens`,
`widget-golden-and-a11y-testing`, `widget-composition`.

**Screenshot check.** Follow **E03's screenshot policy**, for E03's reason: this task renders isolated
components, not screens. Compare the **resting** frames of `PopButton`, `GameCard` and `PopToggle`
against the rendered gallery in `design/sunburst-pop/system.html` §10 — *Primary button*, *Game card*,
*Toggle switch* — in the order structure → spacing rhythm → surface construction → type role → sampled
hex. The rewire must change no resting pixel; any difference is an implementation defect in this task,
not a design question, and the strongest evidence is that E03's committed component goldens still match.

Home and Settings do not exist until E07, so **`01-home.png` and `08-settings.png` are not comparable
here** — the in-situ comparison of the same components belongs to E07 T07.5 and T07.9 and is recorded
there. **The pressed and reduce-motion frames have no reference at all** — every reference in this
project is an end state — so they are covered by the golden lane above and by the on-device pass in
E10. Record both limitations in the PR body. If a resting difference turns out to be a genuine
reference error, the change goes into `system.html` (and `app.html` + `capture-screens.sh` where
geometry is at stake) and is committed as a deliberate design change.

**Done when.**
- [ ] `lib/ui/components/**` contains no `AnimationController`, `onTapDown` or `onTapCancel`.
- [ ] Every press in the app runs through `PressPhysics`.
- [ ] Three goldens committed; the reduce-motion golden differs from the resting golden.
- [ ] Resting frames match `system.html` §10; E03's component goldens are unchanged by the rewire.
- [ ] `check_component_hygiene.sh lib` and `check_motion_tokens.sh lib` green.

**Commits.**
1. `test: assert PopSurface hands PressPhysics derived geometry and the commit moment`
2. `refactor: compose PressPhysics into PopSurface and remove its own press path`
3. `test: add the policy grep for a single press implementation`
4. `test: add pinned-phase press goldens including the reduce-motion frame`

---

### T04.8 — The bounded celebration and the bounded shake
**Goal.** The only two multi-phase motions in the app, both with explicit stop conditions:
`PopCelebration` (`personalBest`, `streakMilestone`, `countdownBeat`) and `ShakeOnWrong`
(`answerWrong`, two cycles, no third).

**`ShakeOnWrong` is created here and nowhere else**, at `lib/shared/motion/shake_on_wrong.dart`. Both
games need it — E08's answer key and E09's tile — so it is shared code by construction. A copy under
`lib/games/stroop_rush/ui/board/` or a third path under `lib/ui/motion/` is a review reject on that
epic; E08 T08.7 and E09 T09.7 wire this widget in and add no file. `lib/shared/motion/` must therefore
be importable from `lib/games/**` under `check_import_boundaries.sh` — assert that in T04.9's policy
test rather than discovering it in E08.

**Tests first (TDD).** `test/shared/motion/pop_celebration_test.dart`
- `it plays once and never again` — pump, force a second `didChangeDependencies` (change the theme),
  assert the controller ran exactly once.
- `it fires its moment's haptic before any stop condition is checked` — under
  `disableAnimations: true`, `fake.played` is `[heavyImpact]` and no frame is scheduled. This is the
  ordering bug the skill names explicitly.
- `it does not play off-route` — mounted under a non-current `ModalRoute`, no frames scheduled, but
  the haptic still fires.
- `it rests at the end state` — before playing and after disposal mid-flight, the rendered scale is
  1.0, so any interruption lands on the finished state.
- `it blocks no input` — a `GestureDetector` behind it receives a tap during the celebration; assert
  no `AbsorbPointer`, no `ModalBarrier` and no `IgnorePointer` in the subtree.
- `it never repeats` — the file contains no `.repeat(`; the controller's status reaches
  `completed` once.
- `the resting transform survives reduce motion` — the −2.5° tilt is applied outside the animation
  and is present with `disableAnimations: true` (a resting transform is a state, not motion).

`test/shared/motion/shake_on_wrong_test.dart`
- `it runs exactly two cycles` — `pump(durCelebrate * 2 + 1ms)` returns to offset zero; a third cycle
  never starts.
- `reduce motion skips the shake entirely` — zero frames scheduled; the caller's residue carries it.
- `disposal mid-flight stops it` — pump the widget out between cycles; no pending timer, no
  "setState after dispose".
- `a rebuild does not re-trigger it` — `didUpdateWidget` with `isWrong` still true does not start a
  new sweep; only a false→true edge does.

**Implementation.** `PopCelebration extends ConsumerStatefulWidget` taking `{required Moment moment,
required Widget child, double restingTiltDegrees = 0}`: controller created with `value: 1`, scale as
a `TweenSequence` `0.86 → 1.06 → 1.00` on `curveFor(CurveRole.pop)` at `durationFor(MotionRole.celebrate)`,
a `_hasPlayed` latch set *before* any early return, `fire(moment)` before the stop-condition checks,
then `if (MediaQuery.disableAnimationsOf(context)) return;` and
`if (ModalRoute.of(context)?.isCurrent != true) return;`, `unawaited(_pop.forward(from: 0))`,
`dispose()`. No barrier, no `AbsorbPointer`. `ShakeOnWrong extends StatefulWidget` per
`examples/feedback_moments.dart`: a `TweenSequence` `0 → −4 → +4 → 0` at `durCelebrate` on `easeOut`,
played as two awaited `forward(from: 0)` calls with a `mounted` guard between them — the absence of a
third line is the stop condition, stated in a `//`.

**Files.** `lib/shared/motion/pop_celebration.dart`, `lib/shared/motion/shake_on_wrong.dart`,
`test/shared/motion/pop_celebration_test.dart`, `test/shared/motion/shake_on_wrong_test.dart`.

**Skills.** `sunburst-motion-and-haptics`, `motion-and-haptics`, `async-safety`, `widget-composition`,
`widget-golden-and-a11y-testing`, `dartdoc-conventions`.

**Screenshot check.** n/a (no visual surface — both are transform wrappers around a caller's child).
The badge they wrap is `06-results.png`'s personal-best badge and is compared there, in E07.

**Done when.**
- [ ] Neither file contains `.repeat(`; both dispose their controller.
- [ ] The haptic fires above every stop condition in `PopCelebration`.
- [ ] `ShakeOnWrong` has exactly two `forward(from: 0)` calls.
- [ ] The measured peak scale of the celebration is recorded in the test's `reason:` string (see
      Risks — `easePop` over a `TweenSequence` overshoots past 1.06).
- [ ] `check_motion_tokens.sh lib` green (the `.repeat(` arm has nothing to find).

**Commits.**
1. `test: assert the celebration plays once, blocks nothing and rests at its end state`
2. `feat: add PopCelebration with latch, stop conditions and haptic-first ordering`
3. `test: assert the wrong-answer shake runs exactly two cycles and stops on dispose`
4. `feat: add ShakeOnWrong as two bounded forward passes`

---

### T04.9 — Close the gates
**Goal.** Make every invariant this epic asserts a merge blocker, and state honestly what CI cannot
prove.

**Tests first (TDD).** `test/policy/motion_policy_test.dart` — one file collecting the source-graph
invariants that are textually decidable, silent when broken, and one line to break:
- `nothing repeats` — no `.repeat(` anywhere in `lib/`.
- `no raw motion value outside lib/theme` — no `Duration(milliseconds:`, `Curves.` or `Cubic(`
  (`Duration.zero` excepted, matching the gate script).
- `heavyImpact appears in at most three places` — the `HapticVerb` value, its catalog row and the
  gateway's switch arm; a fourth is a review stop.
- `no second haptic gate` — **no call site checks a settings flag before calling `fire`.** The gate
  lives once, inside `LiveFeedbackService`. Written as: no file outside `lib/shared/feedback/` and
  `lib/features/settings/**` mentions `isHapticsEnabled`, **and** no file anywhere pairs an
  `isHapticsEnabled` read with a `.fire(` call in the same method. The settings screen must be able to
  render and write the toggle (E07 T07.9); the second *gate* is the thing being banned, not the second
  *mention*. State that distinction in the `reason:` — the naive version of this test goes red the day
  the Settings screen lands and gets deleted rather than fixed.
- `one shake implementation` — `ShakeOnWrong` is declared in exactly one file, and it is
  `lib/shared/motion/shake_on_wrong.dart`; `lib/games/**` may reference it but may not declare it.

Each assertion strips comment-only lines first, accumulates all hits, and fails once with a message a
stranger can act on (`references/policy-grep-gate.md`).

**Implementation.** Confirm `.github/workflows/ci.yml` (E01) already runs
`check_motion_tokens.sh lib` through `tool/skill_gates.sh`; add it to the runner's run table if it is
not there, with a comment naming the contract it blocks on. `dart_test.yaml`'s `golden` tag is **E03
T03.2's** and already exists — do not add a second one. Never `--update-goldens` in CI. Add a short
"What CI cannot prove here" note to the workflow: haptic intensity, whether a haptic fired once or
five times in the hand, and audio — all three are physical-device checks and belong to E10's
`design-review-workflow` sweep.

**Files.** `test/policy/motion_policy_test.dart`, `.github/workflows/ci.yml` (edit if needed).

**Skills.** `ci-pipeline-and-gates`, `testing-strategy`, `sunburst-motion-and-haptics`,
`widget-golden-and-a11y-testing`.

**Screenshot check.** n/a (no visual surface).

**Done when.**
- [ ] Every gate below is a CI step, none `continue-on-error`.
- [ ] `flutter test test/policy/` green.
- [ ] The workflow states what it cannot prove, in a comment, next to the haptic gate.

**Commits.**
1. `test: add the motion and haptic source-graph policy gates`
2. `ci: wire check_motion_tokens.sh and the golden lane, with an honest limits note`

## Gates that must pass

Run from the repository root, in this order, before the PR:

```bash
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs   # ALWAYS before analyze
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos --fatal-warnings
flutter test --test-randomize-ordering-seed random

# every skill gate, through the one runner E01 T01.8 built
bash tool/skill_gates.sh

# this epic's named spot-checks, run individually so a failure names itself
.claude/skills/sunburst-motion-and-haptics/scripts/check_motion_tokens.sh lib
.claude/skills/sunburst-tokens/scripts/check_raw_values.sh                lib
.claude/skills/sunburst-components/scripts/check_component_hygiene.sh     lib
.claude/skills/sunburst-shell-screens/scripts/check_shell_boundaries.sh   lib
.claude/skills/sunburst-game-surfaces/scripts/check_game_palette.sh       lib
.claude/skills/sunburst-tokens/scripts/check_palette_contrast.sh
.claude/skills/service-boundary-and-native/scripts/check-service-boundaries.sh lib
.claude/skills/state-management-riverpod/scripts/ban-legacy-providers.sh
.claude/skills/flutter-architecture/scripts/check_architecture.sh
.claude/skills/project-structure-and-packages/scripts/check_import_boundaries.sh
.claude/skills/dart3-idioms-and-coding-standards/scripts/check-dart3-idioms.sh
.claude/skills/widget-composition/scripts/check-widget-composition.sh
.claude/skills/error-handling-typed-results/scripts/check-swallowed-catch.sh
.claude/skills/testing-strategy/scripts/check_test_hygiene.sh
.claude/skills/widget-golden-and-a11y-testing/scripts/check-test-hygiene.sh
.claude/skills/ci-pipeline-and-gates/scripts/banned-strings.sh
```

The primary gate for this epic is `check_motion_tokens.sh lib`, and it must print
`OK: motion values tokenized, haptics confined to the feedback service, nothing repeating.` over real
code. A `note: 'lib' not found` line is not a pass.

## Risks and open questions

1. **E03 shipped the seam; this epic must not rebuild it.** E03 T03.3 created `moment.dart`,
   `feedback_service.dart` and `press_physics.dart` because `PopSurface` could not be pressable without
   them. **Decision:** T04.1, T04.5 and T04.6 are *edits*. `PopSurface`'s public constructor is E03's
   contract; E04 may add one optional `commitMoment` parameter and change internals only. **E04 may not
   add a second press controller** — if E03 shipped a second press path anywhere, delete it in T04.7
   rather than leaving it unreferenced. Ask whoever landed E03 before starting T04.6.
2. **Settings are in memory until E05 and E07.** `AppSettingsNotifier` has no persistence, so the four
   toggles reset on relaunch. **Decision:** ship it in memory over **E05's `AppSettings` value type
   with E05's field names**, with a `///` naming the two epics that extend it; E05 T05.4 re-points
   `build()` at `SettingsRepository.watch()` and E07 T07.9 builds the Settings rows, and neither may
   change `hapticsEnabledProvider`/`soundEnabledProvider`, the scope's read, or where the scope is
   mounted. Call this out explicitly in the PR body under "deliberately left out". Inventing a separate
   three-field `FeedbackSettings` here is what makes E07's arrival a rename instead of a wiring change.
3. **Sound has nine named slots and no assets.** `system.html` specifies a Sound settings row and no
   audio at all. **Decision:** `SoundCue` is data; `FeedbackService.soundCueFor` returns the slot and
   nothing plays it. Do **not** add an audio package — a new dependency needs a
   `dependency-hygiene` audit, and no moment may ever depend on its sound (rule 8). The open
   question, for whoever owns the audio decision: does MindForge ship sound at all, or is the
   Settings row removed? Ask before E10.
4. **Haptics cannot be verified anywhere in CI.** Simulators reproduce none of this, and "exactly
   once" is felt, not screenshotted. **Decision:** the fake-gateway unit tests are the automated
   proof of *call count*; the felt behaviour — intensity, a burst that reads as a rattle, iOS's
   sleeping Taptic Engine right after foregrounding — goes on E10's `design-review-workflow` device
   checklist as a BLOCKER-graded item. Say so in the workflow comment (T04.9) so nobody reads a green
   CI as proof.
5. **The Dart catalog can drift from `references/moment-catalog.md`.** Two sources of truth for the
   same eighteen rows. **Decision:** transcribe the table in a single commit with the reference open,
   cite the reference line in each row's comment, and treat any future change as a change to *both* —
   the skill reference is authoritative and the Dart table is its transcription, exactly as
   `lib/theme/` is `system.html`'s.
6. **`easePop` over the celebration `TweenSequence` overshoots past 1.06.** `Cubic(0.2, 1.5, 0.4, 1)`
   returns values above 1.0, so a `0.86 → 1.06` segment driven through it peaks above 1.06 — the
   catalog states the amplitude as 1.06. **Open question:** measure the real peak in T04.8's test and
   record it in the `reason:` string. If it is materially above 1.06, ask whether the sequence should
   take `easeOut` with the overshoot living entirely in the curve, or whether the catalog's `1.06`
   describes the tween endpoint rather than the rendered peak. Do not silently change either.
7. **`lib/shared/motion/` is load-bearing and already in `CLAUDE.md`.** The split matters —
   `check_motion_tokens.sh` fences `HapticFeedback` to `*/feedback/*`, and `PressPhysics` must not sit
   in the same fence as the gateway. **E01 T01.5 amended `CLAUDE.md`'s layout block once**, adding
   `core/`, `shared/motion/` and `l10n/`, and `test/policy/project_structure_test.dart` reads that
   block. **Do not propose the amendment again here** — three epics each editing the same eight-line
   root document is the churn that amendment exists to avoid.
8. **`ShakeOnWrong` will be copied if this epic does not claim it loudly.** Both games want it.
   **Decision:** it lives at `lib/shared/motion/shake_on_wrong.dart` and nowhere else; T04.9's policy
   test asserts a single declaration, and E08/E09 wire it in rather than adding a file. Stated in the
   PR body so both game epics inherit the constraint.

## Definition of done

- [ ] All nine tasks complete, each with its tests committed alongside the code they cover.
- [ ] `Moment` has eighteen values; `kMomentCatalog` has eighteen rows; every row declares a residue.
- [ ] `HapticFeedback.*` appears in exactly one file; `heavyImpact` reaches the gateway only for
      `Moment.personalBest`.
- [ ] One press implementation: `lib/ui/components/**` drives no controller and handles no pointer.
- [ ] `Moment`, `FeedbackService` and `PressPhysics` were **edited**, not created; `git log --diff-filter=A`
      on those three paths shows E03's commits, not this epic's.
- [ ] `AppSettings` carries E05's four field names; there is no `FeedbackSettings` type.
- [ ] `ShakeOnWrong` is declared once, in `lib/shared/motion/`, and `lib/games/**` can import it.
- [ ] Reduce motion is folded into `MediaQuery` once, at the root; nothing outside
      `motion_preference_scope.dart` turns the flag into a `Duration`; the press keeps its fill and
      shadow and drops its transform.
- [ ] Nothing animates longer than 240ms per cycle; nothing repeats; the shake is exactly two cycles
      and the celebration exactly one, latched and disposed.
- [ ] `check_motion_tokens.sh lib` prints `OK:` over real code, and `bash tool/skill_gates.sh` is green.
- [ ] Resting frames of `PopButton`, `GameCard` and `PopToggle` compared against `system.html` §10
      (E03's screenshot policy — Home and Settings do not exist until E07); differences resolved as
      implementation defects, or as a deliberate `system.html`/`app.html` change committed with any
      regenerated PNGs. The PR body records that the in-situ comparison is E07's.
- [ ] Press goldens committed for rest, pressed and pressed-under-reduce-motion, and the last two
      differ.
- [ ] `/simplify` run and its findings addressed.
- [ ] `/code-review` run and its findings addressed.
- [ ] Branch `epic/04-motion-and-feedback` pushed with granular commits; PR body states what changed,
      why, how it was verified, that the comparison target was `system.html` §10 and why no screen PNG
      applies yet, and what was deliberately left out (settings persistence → E05/E07, the Settings
      rows → E07, audio playback → open question, on-device haptic verification → E10).
- [ ] CI green on the PR (the pipeline E01 created).
- [ ] Merged preserving the granular commits, branch deleted, back on `main`, `git pull` done.
