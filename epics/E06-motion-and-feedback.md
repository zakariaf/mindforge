# E06 · Motion and feedback

| | |
|---|---|
| **Branch** | `epic/06-motion-and-feedback` |
| **Depends on** | E03, E05 |
| **Unblocks** | E08 |
| **Status** | Not started |

## The epic

Fill in the sensory layer whose **seam E05 already shipped**: `lib/shared/feedback/` (the `Moment` enum
extended with duration, curve and **axis** roles, the eighteen-row moment catalog as data,
`HapticGateway`, and the real `FeedbackService` that replaces E05's `SilentFeedbackService` no-op) and
`lib/shared/motion/` (`PressPhysics` — E05's stub becomes the real interruptible controller — the two
bounded motion primitives `PopCelebration` and `ShakeOnWrong`, the one mirroring primitive
`DirectionalSlide`, and the root `MotionPreferenceScope` that folds the Settings "Reduce motion" row
into `MediaQuery.disableAnimations`). `HapticFeedback.*` appears in exactly one file after this epic;
`heavyImpact` appears exactly once in the whole app; `SlideTransition` is constructed in exactly one
file.

E05 T05.3 created three files it could not ship a pressable surface without — `moment.dart`,
`feedback_service.dart` (interface + `SilentFeedbackService` + `feedbackServiceProvider`) and
`press_physics.dart` — and recorded in its Risks that **E06 replaces the implementations and owns the
moment → haptic map, but does not rewrite the seam and must not add a second press controller.** This
epic honours that: it edits those three files, it does not create them. `PopSurface`'s public
constructor is E05's contract and gains exactly one optional parameter. Nothing here renders a screen;
every consumer of this epic is E08, E09 and E10.

**Motion is mostly direction-agnostic, and this epic makes the exceptions explicit rather than
leaving them to be discovered under Persian.** Every catalog row now declares a `MotionAxis`:
`inline` motion moves along the reading axis and **mirrors** under RTL (`routeTransition`,
`toggleFlip`, `answerWrong`'s shake); `vertical` motion does not (`homeCardEnter`, `resultsReveal`,
`sheetTransition`); `fixed` motion moves along the light-source axis and **must not** mirror
(`buttonPress`, `buttonCommit`, `difficultySelect`, `answerCorrect`, `tileFound`); `none` covers the
scale pops and colour crosses that translate nothing at all. The press translate is still a **state**,
not an animation, and it does not mirror: it travels down its own hard offset shadow, and that shadow
is a light-source constant, not a reading-direction property. A Persian build whose buttons press up
and to the left would be a bug, not a localization.

`ShakeOnWrong` is created **here**, at `lib/shared/motion/shake_on_wrong.dart`, and is the only copy in
the repository: E09's answer key and E10's tile both wrap it. `DirectionalSlide` is created here for
the same reason: E08's route transitions and pause sheet wrap it, and a second `SlideTransition`
anywhere is a review reject on that epic.

**iOS only.** The app is built and run on the iOS Simulator, on one named device
(`MindForge iPhone 14`, iOS 18.6, exactly 390×844 logical points). Android is deferred and nothing in
this epic is verified on it — the haptic gateway names no platform, but the only implementation this
epic proves is the iOS one.

## Why we need it

Without this epic every later screen invents its own press, its own duration and its own haptic. That
is the failure mode `sunburst-motion-and-haptics` exists to prevent: two press implementations diverge
the day one of them learns about reduce-motion, and ad-hoc haptics only ever escalate until a wrong
answer punishes the player with `heavyImpact`. The catalog is also the only place the design's
non-negotiables become machine-checkable — that nothing exceeds 240ms, that nothing repeats without a
stop condition, that every moment still lands with Sound off + Haptics off + Reduce motion on.

The same argument now covers direction. `motion-and-haptics` rule 14 is one sentence — "transitions
follow reading direction; a fixed content surface does not re-mirror" — and it is the sentence every
app gets wrong in both directions at once: a route that slides in from the same physical edge in
Persian as in English, and a press shadow that helpfully mirrors itself into the light. Neither is
visible in an English simulator run, neither is caught by `check_i18n_bans.sh` (a `SlideTransition`
offset and a `Transform.translate` are not physical-side *geometry* the grep can see), and both are
one line to break. So the axis becomes catalog **data** with a test per case, and the two motions that
actually move along the reading axis go through one widget that reads `Directionality`.

Concretely, until E06 lands: `PopSurface` either has no press or has a second one; E08 cannot build
the countdown, the pause sheet, the route transitions or the results reveal because their beats and
their axes are undefined; E09 cannot implement `answerCorrect`/`answerWrong`; E10 cannot implement
`tileFound`/`tileNextCue`; and `check_motion_tokens.sh` is green only because there is nothing to scan.

## Current state

Verified by `ls`, `git log` and the toolchain commands below, on `main` at the time of writing
(5 commits, tip `ddcb79d`).

**Toolchain — checked on this machine, do not re-derive:**

- Flutter **3.44.6** stable · Dart **3.12.2** · DevTools 2.57.0
- Xcode **26.6** (build 17F113) · CocoaPods **1.15.2**
- Simulator runtimes available: iOS 18.0, 18.6, 26.5
- The canonical device is **`MindForge iPhone 14`**, UDID `C13DDC02-375D-4E1B-8F81-44EB407D09A4`,
  iOS 18.6. It exists because it is **exactly 390×844 logical points**, which is what
  `design/sunburst-pop/screens/*.png` were captured at. No iPhone 16-class simulator matches
  (iPhone 16 is 393×852, 16 Pro is 402×874), so any screenshot comparison on another device is not
  honest. Boot with `xcrun simctl boot C13DDC02-375D-4E1B-8F81-44EB407D09A4`, run with
  `flutter run -d C13DDC02-375D-4E1B-8F81-44EB407D09A4`.
- **Android is deferred.** There is no Android gate, no Android device check and no claim of parity in
  this epic.

**Repository:**

- **No Flutter app.** No `pubspec.yaml`, no `lib/`, no `test/`, no `.github/`. Repository root holds
  `CLAUDE.md`, `design/`, `epics/`, `50-apps-challenge-slides.html`, `.claude/`.
- `.claude/skills/sunburst-motion-and-haptics/` is complete and is the specification for this epic:
  - `SKILL.md` — twelve rules and the eighteen-row summary table.
  - `references/moment-catalog.md` — exact offsets, amplitudes and latch names per row.
  - `references/press-physics.md` — derived press geometry, the state-vs-animation split, interruption.
  - `references/haptics-map.md` — moment → verb, the commit-frame rule, the three Settings gates.
  - `examples/press_physics.dart` — a working `PressPhysics` / `PressGeometry` / `PressBuilder`.
  - `examples/feedback_moments.dart` — `StroopRunNotifier`, `StroopStimulusCard`, `ShakeOnWrong`,
    `SchulteTile`, `PersonalBestBadge`.
  - `scripts/check_motion_tokens.sh` — runs today and prints `note: 'lib' not found; nothing to scan.`
- `.claude/skills/i18n-rtl-l10n/` ships `scripts/check_i18n_bans.sh` and `scripts/check_arb_parity.sh`,
  wired into `tool/skill_gates.sh` by E04. `check_i18n_bans.sh` scans physical-side geometry,
  non-adaptive directional icons, number splices, legacy bidi embeddings and `google_fonts`. It does
  **not** see a `SlideTransition` offset or a `Transform.translate` — that gap is what T06.10's policy
  test closes.
- `design/sunburst-pop/system.html` §09 Motion fixes the four durations, the three curves, the 240ms
  ceiling and the "press transform is dropped, pressed colour and shadow still apply" sentence.
  §10 Components carries the rendered gallery this epic's resting frames are compared against.
- `design/sunburst-pop/screens/` holds the eight LTR PNGs, and E04 added the Persian RTL counterparts
  under `design/sunburst-pop/screens/rtl/` (a `dir="rtl"` `fa` variant of `app.html`, captured by the
  extended `capture-screens.sh`). **Neither set shows a press, a haptic or a reduce-motion frame** —
  every reference in this project is an end state. The pause sheet has no PNG in either set.

**Assumed present when this epic starts** (deliverables of E01–E05, not verified here — if any is
missing or differently named, stop and fix the dependency epic; do not shim it here):

| From | Symbols this epic consumes |
|---|---|
| E01 | `lib/app.dart`, `lib/bootstrap.dart`, `tool/skill_gates.sh`, `.github/workflows/ci.yml`, the iOS runner target and `Info.plist` carrying `CFBundleLocalizations` = `en, de, fa, ckb` |
| E02 | `AppSettings` in `lib/core/app_settings.dart` (persisted, five fields), `settingsProvider` — a **`StreamProvider` over `SettingsRepository.watch()`, not a `Notifier`** — and `settingsRepositoryProvider` as the single write path. E02 T02.4 states there is no `AppSettingsNotifier` and no in-memory settings state anywhere in the app. Fields read here: `isSoundEnabled`, `isHapticsEnabled`, `isReduceMotionEnabled` |
| E03 | `SunburstMotion` (`durTap/durState/durMove/durCelebrate`, `easePop/easeOut/easeInOut`, `resolve(context, duration)`, `of(context)`), `SunburstShape` (`pressTranslate`, `pressedShadow`, `pressScale`, `pressScaleSmall`, `e1…e4`, `shadow()`), `buildSunburstTheme()`, the four bundled faces, `test/support/harness.dart` (`Device`, `Device.all` at DPR 2, `pumpApp`), `test/support/load_app_fonts.dart` and `dart_test.yaml`'s `golden` tag |
| E04 (reached transitively through E05 — this epic declares no direct edge to it, but T06.9's `DirectionalSlide` watches `localeProvider`, so E04 must be merged) | `AppLocalizations` + `l10n.yaml` with `nullable-getter: false`, the four ARBs, `localeProvider`, `appLocalizationsProvider`, the persisted override, the `ckb` `LocalizationsDelegate`, `LocaleNumbers`, `AsciiNumerals.normalize`, `Bidi`, `LocaleCase.all` + `pumpLocalized`, `design/sunburst-pop/screens/rtl/*.png` |
| E05 | `PopSurface`, `PopElevation`, `kPopMinTarget`, `PopProgressBar`, `PopToggle`, `PopButton`, `GameCard` in `lib/ui/components/`; the three seam files `lib/shared/feedback/moment.dart`, `lib/shared/feedback/feedback_service.dart`, `lib/shared/motion/press_physics.dart`; `test/support/fake_feedback_service.dart`; `test/support/component_harness.dart` (`pumpPopComponent`) |

Two ordering changes from the pre-localization plan matter here:

1. **Settings are already persisted.** In the old sequence this epic shipped `AppSettings` in memory
   and persistence arrived later. Persistence is now **E02**, ahead of localization, because the locale
   override must survive a relaunch. So T06.4 **consumes** E02's value type, its `settingsProvider`
   stream and its repository, and adds only the reduce-motion root fold and the two derived gate
   providers. It creates no second settings type and **no notifier** — E02 T02.4 states the repository
   is the single write path and there is no `AppSettingsNotifier` at any point. If
   `lib/core/app_settings.dart` is absent when this branch opens, that is an E02 gap.
2. **Localization is already landed, transitively.** This epic's **Depends on** row names E03 and E05;
   E05 depends on E04, so E04 is merged by the time this branch opens even though there is no direct
   edge. That matters in exactly one place: T06.9's `DirectionalSlide` watches `localeProvider`. Every
   component this epic times was already written with directional geometry from its first commit (E05
   depends on E04 for exactly that reason), so this epic never "adds RTL support" to a press — it
   asserts that the press correctly does **not** mirror, and supplies the one primitive for the
   motions that do.

## What we will achieve

A reader can tell this epic is done by running these and reading the result:

- `.claude/skills/sunburst-motion-and-haptics/scripts/check_motion_tokens.sh lib` prints
  `OK: motion values tokenized, haptics confined to the feedback service, nothing repeating.` over
  real code, not over an absent directory.
- `grep -rn "HapticFeedback\." lib/` returns exactly one file: `lib/shared/feedback/haptic_gateway.dart`.
- `grep -rn "heavyImpact" lib/` returns the enum declaration, the one catalog row for
  `Moment.personalBest`, and the gateway's switch arm — and nothing else.
- `grep -rn "SlideTransition" lib/` returns exactly one file:
  `lib/shared/motion/directional_slide.dart`.
- `grep -rln "Directionality\|TextDirection" lib/shared/motion/` returns exactly
  `directional_slide.dart`. `press_physics.dart`, `pop_celebration.dart` and `shake_on_wrong.dart`
  never ask which way the page reads.
- `flutter test test/shared/` is green, including: the fake gateway records exactly **one** verb per
  `fire()`; firing all eighteen moments records exactly one `heavyImpact`; every `Moment` has a
  catalog row with a non-empty residue channel set and a declared `MotionAxis`; no role resolves above
  `durCelebrate`; a press under `disableAnimations: true` has zero translate and zero scale but a
  `(1,1)` shadow and `isDown == true` on the pointer-down frame; and the press geometry under
  `Locale('fa')` is byte-for-byte the geometry under `Locale('en')`.
- `Moment` has eighteen values, matching `references/moment-catalog.md` row for row; exactly three are
  `MotionAxis.inline`, three are `vertical`, five are `fixed` and seven are `none`.
- `PopSurface` contains no `GestureDetector` and no `AnimationController`; it passes four numbers and
  a `Moment` to `PressPhysics` and paints the frame it is handed.
- The app is wrapped once in `MotionPreferenceScope`, above `MaterialApp` and below `ProviderScope`,
  and it adds no root `Directionality` — direction comes from E04's resolved locale, never from a
  wrapper. `grep -rn "isReduceMotionEnabled" lib/` returns `lib/core/app_settings.dart`, E02's settings
  notifier, `motion_preference_scope.dart` and — once E08 lands — the Settings screen row that writes
  it. No other widget reads it.
- `bash tool/skill_gates.sh` is green, `check_i18n_bans.sh lib` included.
- A human running the app on `MindForge iPhone 14` with Sound off, Haptics off and Reduce motion on can
  still press every control and see it acknowledge — the fill deepens and the shadow collapses to
  `(1,1)` instantly — in `en`, `de`, `fa` and `ckb`, and switching locale from Settings never throws.

## Skills to load

| Skill | Why, for this epic |
|---|---|
| `flutter-conventions-index` | The front door and the routing table; house rules 8 (side effects behind injected interfaces), 9 (async is never silent), 10 (complexity limits) and 12 (RTL by construction) all bind directly here. |
| `sunburst-motion-and-haptics` | The specification. Owns the eighteen moments, the four durations/three curves, the press geometry, the latch rules, the residue rule and `check_motion_tokens.sh`. Read `SKILL.md` plus all three `references/` files before T06.1. |
| `motion-and-haptics` | The generic discipline the sunburst rows sit on: why moments are named, the commit-frame rule, interruptibility, celebration budgets, multi-channel redundancy, "motion decorates state but is never the state" — and rule 14, the one sentence T06.9 turns into code. |
| `i18n-rtl-l10n` | Rule 5 (directional geometry only) and the `references/rtl-and-bidi.md` table are why `DirectionalSlide` exists and why the press does not use it. Also the two gate scripts, the "never wrap the root in `Directionality`" ban, and the real-fonts rule for any golden that renders Arabic script. |
| `sunburst-tokens` | `SunburstMotion.resolve` is the only place a widget asks whether to animate; `durTap`/`easePop` and `shape.pressTranslate`/`pressedShadow`/`pressScale` are read, never typed. Also the raw-value gate this epic must stay clean under. |
| `sunburst-components` | Owns `PopSurface`, `PopElevation`, `kPopMinTarget`, `PopProgressBar` and the press *chrome* (rest/pressed/disabled triples, hit area outside the transform). T06.7 changes `PopSurface`'s internals and must not touch its contract. |
| `service-boundary-and-native` | `HapticGateway` is a boundary: an `abstract interface class`, one live impl, one hand-written fake, a provider that throws `UnimplementedError` until the composition root overrides it. Also the ban on `DateTime.now()` that `check-service-boundaries.sh` enforces. |
| `state-management-riverpod` | E02's `AppSettings` behind its `Notifier` is read here through `select`, never re-owned; `feedbackServiceProvider` is plain DI; the watch/read split (`ref.read` in callbacks, never `ref.watch`); no legacy providers. |
| `naming-conventions` | `Gateway` = wrapper over a platform API, `Service` = capability interface we define, `Live[Concern]Gateway` for the impl, file name = primary declaration. This epic introduces both suffixes at once and they must not be swapped. |
| `dart3-idioms-and-coding-standards` | `Moment`, `HapticVerb`, `SoundCue`, `MotionRole`, `CurveRole`, `MotionAxis`, `ResidueChannel` are enums; `MomentSpec` is a hand-rolled immutable value; every `switch` over them is exhaustive with no `default:`. Also the complexity limits `PressPhysics` must respect. |
| `dartdoc-conventions` | Every public declaration here is a contract other epics build on; rule 8 (restate the enforced invariant at its enforcement point) is why the latch, the commit-frame fire, the reduce-motion branch and the **non-mirroring** press each carry a `//` stating what they uphold. |
| `async-safety` | `HapticFeedback.*` returns a `Future`. `fire()` is `void` and does `unawaited(... .catchError(...))` inside; `onTap:` never holds a Future; the press, slide and celebration controllers are disposed; `mounted` is checked after the await in the two-cycle shake. |
| `widget-composition` | `PressPhysics`, `PopCelebration`, `ShakeOnWrong` and `DirectionalSlide` are widget classes with disposed controllers, not `_buildX()` helpers; identity, not content, is captured in callbacks; rule 12 is the directional-geometry half of this epic. |
| `accessibility-as-code` | Rule 3 — a11y state is read from `MediaQuery`, never from app state — is exactly why the Settings toggle is folded in at the root instead of watched per widget. Also the never-colour-alone floor the residue channels satisfy, and rule 10's "keep haptics through reduced motion". |
| `testing-strategy` | Bare-`implements` fakes over mocks; `ProviderContainer` for headless notifier tests; assert invariants (every moment has a row, every row has an axis) rather than examples; no mocked gateway. |
| `widget-golden-and-a11y-testing` | `pumpApp` with a pinned 390×844 surface at DPR 2, `pump(duration)` never `pumpAndSettle` on a pressed surface, the reduce-motion golden that must differ from the resting golden, the RTL golden lane with `loadAppFonts()` (never Ahem for Arabic script), `@Tags(['golden'])`. |
| `flutter-architecture` | Where `shared/feedback` and `shared/motion` sit in the DAG: `ui/components` may import `shared/motion`; `shared/**` may never import `ui/**` or `features/**`. |
| `app-startup-and-bootstrap` | Where `MotionPreferenceScope` mounts relative to `ProviderScope` and `MaterialApp` (and relative to E04's locale wiring), and how `hapticGatewayProvider` is overridden in `bootstrap()`. |
| `ci-pipeline-and-gates` | The three-criteria bar for the grep policy tests in T06.10, the rule that a gate must map to one named contract, and rule 10 — state plainly what CI cannot prove. |

## Tasks

### T06.1 — Extend `Moment` with motion roles and a motion axis
**Goal.** Add the duration/curve *roles* that let a catalog row reference `durTap` without holding a
`Duration`, add the `MotionAxis` vocabulary that decides whether a moment mirrors, and pin the
eighteen `Moment` values E05 already declared.

**Tests first (TDD).** `test/shared/feedback/moment_test.dart`
- `Moment has exactly eighteen values` — `Moment.values.length == 18` and the name set equals the
  literal set transcribed from `references/moment-catalog.md`. E05 T05.3 transcribed the enum; this
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
- `role resolution is locale-independent` — the same four assertions under `pumpLocalized` for
  `en`, `de`, `fa` and `ckb`: a duration is a duration in every language, and the `ckb` case is the
  cheapest possible smoke test that E04's delegate does not throw when a motion widget builds.

`test/shared/motion/motion_axis_test.dart`
- `MotionAxis has exactly four values` — `{none, inline, vertical, fixed}`.
- `only inline is direction-dependent` — `axis.mirrorsUnderRtl` is `true` for `inline` and `false` for
  the other three. One getter, switched exhaustively, so the meaning of "mirrors" is defined once and
  every later test reads it rather than restating it.

**Implementation.** `lib/shared/feedback/moment.dart` **(edit)** — E05 shipped the enum; correct any
value whose name or order drifts from the reference table, and add nothing else to the file: it stays
behaviour-free. New: `lib/shared/motion/motion_role.dart` with
`MotionRole { tap, state, move, celebrate, none }` and `CurveRole { pop, out, inOut }`, plus
`extension MotionRoleResolution on SunburstMotion` with `Duration durationFor(MotionRole)`,
`Curve curveFor(CurveRole)` and `Duration resolvedDurationFor(BuildContext, MotionRole)` delegating to
`resolve`. New: `lib/shared/motion/motion_axis.dart` with
`MotionAxis { none, inline, vertical, fixed }` and `bool get mirrorsUnderRtl`, its own file because the
file name is its primary declaration. Exhaustive switches, no `default:`. No `Duration(` literal
anywhere — `MotionRole.none` returns `Duration.zero`, which both gate scripts explicitly allow.

Document the four axis values as what they mean physically, not as what they are called:
`inline` moves along the reading axis and is the only value that mirrors; `vertical` moves along the
screen's fixed vertical axis; `fixed` moves along the light-source axis the hard offset shadow
defines, which is a property of the design's lighting and **not** of reading direction; `none`
translates nothing (a scale, a colour cross, a shadow-step change with no travel).

**Files.** `lib/shared/feedback/moment.dart` (edit — E05 created it),
`lib/shared/motion/motion_role.dart` (new), `lib/shared/motion/motion_axis.dart` (new),
`test/shared/feedback/moment_test.dart`, `test/shared/motion/motion_role_test.dart`,
`test/shared/motion/motion_axis_test.dart`.

**Skills.** `sunburst-motion-and-haptics`, `sunburst-tokens`, `i18n-rtl-l10n`,
`dart3-idioms-and-coding-standards`, `dartdoc-conventions`, `naming-conventions`.

**Screenshot check.** n/a (no visual surface).

**Done when.**
- [ ] `Moment.values.length == 18`; names match `references/moment-catalog.md` row for row.
- [ ] `MotionAxis` has four values and exactly one of them returns `true` from `mirrorsUnderRtl`.
- [ ] No `Duration(`, `Curves.` or `Cubic(` in any of the three files.
- [ ] `check_motion_tokens.sh lib` and `check_raw_values.sh lib` green.
- [ ] Every public declaration carries a `///` that says what the moment or axis *is*, not what it is
      called; `MotionAxis.fixed`'s doc names the light source as the reason it never mirrors.

**Commits.**
1. `test: assert the eighteen moments, the motion role contract and the axis vocabulary`
2. `feat: add MotionRole and CurveRole with SunburstMotion resolution`
3. `feat: add MotionAxis and its mirrorsUnderRtl rule`

---

### T06.2 — The moment catalog as data, axis included
**Goal.** Turn `references/moment-catalog.md` into a `const` Dart table so the design's invariants are
asserted by the test suite instead of by review — and so "does this mirror?" is answered by data at
the point the moment is declared, not by whoever writes the widget six epics later.

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
- `exactly three moments move along the reading axis` — the moments whose `axis` is
  `MotionAxis.inline` are exactly `{answerWrong, toggleFlip, routeTransition}`.
- `exactly three moments move vertically` — `{homeCardEnter, resultsReveal, sheetTransition}`.
- `the five light-source moments never mirror` — the moments whose `axis` is `MotionAxis.fixed` are
  exactly `{buttonPress, buttonCommit, difficultySelect, answerCorrect, tileFound}`, and every one of
  them is a moment whose movement is a travel toward or away from its own hard offset shadow. The
  `reason:` string states the rule in full: **the hard offset shadow is a light-source constant, not a
  reading-direction property**, so a press in Persian travels down and to the right exactly as it does
  in English.
- `every other moment translates nothing` — the remaining seven are `MotionAxis.none`, and none of
  them declares a translate offset in its `///`.
- `the catalog is locale-independent` — `kMomentCatalog` is `const`, the file imports neither
  `AppLocalizations` nor `package:intl`, and every latch name matches `RegExp(r'^[a-zA-Z]+$')`. A latch
  is a state-machine key, never a user-facing string; a generator's output and a golden vector must not
  change because the locale did.

**Implementation.** `HapticVerb { selectionClick, lightImpact, mediumImpact, heavyImpact }` — no
`vibrate` value exists, so it cannot be reached. `SoundCue { pop, tick, go, thud, click, chime,
alert, end, fanfare }`. `ResidueChannel { fill, shape, ring, border, word }`. `MomentSpec` as a
hand-rolled `@immutable` value with a `const` constructor and `final` fields: `duration`
(`MotionRole`), `curve` (`CurveRole?`), `axis` (`MotionAxis`), `cycles` (`int`, default 1), `haptic`
(`HapticVerb?`), `sound` (`SoundCue?`), `residue` (`Set<ResidueChannel>`), `residueNote` (`String`),
`latch` (`String?`). One `const Map<Moment, MomentSpec> kMomentCatalog` transcribed with
`references/moment-catalog.md` open; each entry's `///`-adjacent `//` cites its source row and marks
the six **DERIVED** values as such. `axis` is **not** in the reference table — it is derived here from
each row's "what moves" column, and every non-`none` row's comment states which sentence of the
reference it was derived from. An `assert` in `MomentSpec`'s constructor that `residue` is non-empty,
`cycles >= 1`, and that `axis == MotionAxis.none` whenever `curve == null` and the row moves nothing —
the runtime tripwire beside the test.

`residueNote` is a developer note in English for the catalog reader. It is not a UI string, carries no
ARB key, and T06.10's policy test asserts it is never passed to a `Text`.

**Files.** `lib/shared/feedback/haptic_verb.dart`, `lib/shared/feedback/sound_cue.dart`,
`lib/shared/feedback/moment_spec.dart`, `lib/shared/feedback/moment_catalog.dart`,
`test/shared/feedback/moment_catalog_test.dart`.

**Skills.** `sunburst-motion-and-haptics`, `motion-and-haptics`, `i18n-rtl-l10n`,
`dart3-idioms-and-coding-standards`, `dartdoc-conventions`, `testing-strategy`,
`accessibility-as-code`.

**Screenshot check.** n/a (no visual surface). The rows that *do* have pixels are checked where they
render: `countdownBeat` against `03-countdown.png` and `design/sunburst-pop/screens/rtl/03-countdown.png`
in E08, and `timerAlarm`/`streakMilestone` against `04-stroop-rush.png` and its RTL counterpart in E09.

**Done when.**
- [ ] All eighteen rows present, each traceable to a line in `references/moment-catalog.md`.
- [ ] Every row declares an axis; the four axis partitions are 3 / 3 / 5 / 7 and are asserted by name.
- [ ] Every **DERIVED** value is marked `DERIVED` in a comment with its one-line reason, the axis
      column included — it is a whole derived column and the PR body says so.
- [ ] The nine sound slots exist as names only — no asset, no audio dependency, no player.
- [ ] `flutter test test/shared/feedback/moment_catalog_test.dart` green.

**Commits.**
1. `test: assert the moment catalog invariants (residue, heavyImpact, ceiling, latches)`
2. `feat: add HapticVerb, SoundCue and ResidueChannel`
3. `feat: transcribe the eighteen-row moment catalog as MomentSpec data`
4. `test: assert the axis partition and the locale-independence of the catalog`

---

### T06.3 — `HapticGateway`: the only `HapticFeedback` call site
**Goal.** Put every haptic behind one injected boundary with one live impl and one hand-written fake.

**Tests first (TDD).** `test/shared/feedback/haptic_gateway_test.dart`
- `the fake records each verb exactly once in order` — `play(lightImpact)` twice yields
  `[lightImpact, lightImpact]`.
- `the fake can be told to fail` — `FakeHapticGateway.failing()` returns a `Future` that completes
  with an error, so the failure path in T06.5 is reachable (a fake that always succeeds is a
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

The interface names no platform. iOS is the only shipping target today, so `LiveHapticGateway` is the
only implementation and the only one verified; the seam exists so that stays a one-file question if
Android is ever undeferred. Say that in the `///` rather than implying parity.

`service-boundary-and-native` rule 4 asks every boundary method for a typed result. This one returns
`Future<void>` deliberately: a haptic that fails on an unsupported device has no recoverable branch
and must never reach the player, so the single `catchError` in `FeedbackService` (T06.5) is the whole
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
- [ ] The interface's `///` states that iOS is the only implemented and verified platform.
- [ ] `check-service-boundaries.sh lib` and `check_motion_tokens.sh lib` green.

**Commits.**
1. `test: assert haptic gateway contract, failing fake and provider override`
2. `feat: add HapticGateway, LiveHapticGateway and FakeHapticGateway`
3. `test: add the policy grep confining HapticFeedback to one file`
4. `chore: override hapticGatewayProvider in bootstrap`

---

### T06.4 — The one settings gate, and the reduce-motion root fold
**Goal.** Three independent switches (Sound, Haptics, Reduce motion), read in exactly one place each,
with reduce motion folded into `MediaQuery` at the root so no widget ever reads app state to decide
whether to animate.

**One settings value, and it already exists.** `AppSettings` is **E02's** persisted value type in
`lib/core/app_settings.dart`, read through E02's `settingsProvider` (a stream over
`SettingsRepository.watch()`) and written only through `settingsRepositoryProvider.update(...)` by
E08's Settings screen. **There is no `AppSettingsNotifier` at any point** — E02 T02.4 decided that
explicitly, and an in-memory notifier declared here would be the defect. This epic does **not** invent a `FeedbackSettings` beside it: two value types with
three overlapping fields under two spellings is a rename waiting to silently drop a toggle. It reads
`isSoundEnabled`, `isHapticsEnabled` and `isReduceMotionEnabled`; it touches neither the colour-blind
flag (E09's round generator reads it) nor the locale override (E04's). If one of those three fields is
missing when this branch opens, that is an **E02 gap** — add it there with its migration, not here.

**Tests first (TDD).** `test/shared/feedback/feedback_gates_test.dart`
- `hapticsEnabledProvider mirrors the settings flag` — flipping `isHapticsEnabled` through E02's
  notifier flips the derived provider, and flipping an unrelated field does not rebuild it (the
  `select` is doing its job).
- `soundEnabledProvider mirrors the settings flag` — same, for sound.
- `all three off at once is a supported configuration` — sound off, haptics off, reduce motion on;
  nothing throws and every derived read returns `false`/`true` as declared.

`test/shared/motion/motion_preference_scope_test.dart`
- `the app toggle ORs into disableAnimations` — with `isReduceMotionEnabled: true` and a platform
  `disableAnimations: false`, a probe below the scope reads `MediaQuery.disableAnimationsOf == true`.
- `the platform flag wins on its own` — with `isReduceMotionEnabled: false` and platform
  `disableAnimations: true`, the probe still reads `true` (an OR, never an override).
- `every other MediaQuery field is preserved` — `size`, `textScaler`, `padding`, `boldText` and
  `devicePixelRatio` below the scope equal the values above it. (Guards the classic
  `MediaQuery(data: MediaQueryData())` mistake that zeroes the pinned surface.)
- `the scope preserves direction and locale` — pumped under `Locale('fa')`, a probe below the scope
  reads `Directionality.of(context) == TextDirection.rtl` and
  `AppLocalizations.of(context).localeName == 'fa'`; repeated for `Locale('ckb')`. The scope inserts a
  `MediaQuery` and nothing else — it must not introduce a `Directionality`, and this is the test that
  fails the day somebody "helpfully" adds one.
- `the scope rebuilds when the toggle flips` — flipping the notifier rebuilds the probe once.

`test/policy/reduce_motion_reads_test.dart`
- `nothing decides whether to animate from app state` — grep `lib/` for `isReduceMotionEnabled`. The
  permitted files are `lib/core/app_settings.dart`, E02's settings notifier,
  `lib/shared/motion/motion_preference_scope.dart` and **`lib/features/settings/**`** — the Settings
  screen must be able to render and write the toggle, and E08 T08.9 lands exactly that. The assertion
  that carries the meaning is the narrower one: **no file outside `motion_preference_scope.dart` passes
  it to a `Duration`, a `Curve` or an `AnimationController`.** Say that in the `reason:`, so the test
  survives E08 instead of turning red the day the Settings screen exists.

**Implementation.** `lib/shared/feedback/feedback_gates.dart` — derived
`hapticsEnabledProvider` / `soundEnabledProvider` as `Provider<bool>` over
`settingsProvider.select(...)`. `MotionPreferenceScope extends ConsumerWidget` in
`lib/shared/motion/motion_preference_scope.dart`, reading
`settingsProvider.select((s) => s.isReduceMotionEnabled)` and returning
`MediaQuery(data: media.copyWith(disableAnimations: media.disableAnimations || reduce), child: child)`
— built from `MediaQuery.of(context).copyWith`, never a bare `MediaQueryData()`.

**Mounted once, in `lib/app.dart`, below `ProviderScope` and above `MaterialApp`**, and that mounting
point is final: E08 T08.9 adds the Settings row that writes the flag and does not add a second fold in
`MaterialApp.router(builder:)`. Two folds would OR twice, pass every test, and be obviously wrong to
read. It sits above `MaterialApp` because that is where the ambient `MediaQuery` every route inherits
is assembled; it sits *beside*, never *inside*, E04's `locale`/`localizationsDelegates`/
`supportedLocales` wiring, and it adds **no** `Directionality` — direction is a consequence of the
resolved locale (`i18n-rtl-l10n` rule 4), and a root `Directionality` would hide every physical-side
bug in the app.

`accessibility-as-code` rule 3 (never read a11y state from app state) is satisfied because this is the
single, root-level provider read that *produces* the `MediaQuery` everything else reads — say so in a
`//` at the `copyWith`.

**Files.** `lib/shared/feedback/feedback_gates.dart`,
`lib/shared/motion/motion_preference_scope.dart`, `lib/app.dart` (edit),
`test/shared/feedback/feedback_gates_test.dart`,
`test/shared/motion/motion_preference_scope_test.dart`,
`test/policy/reduce_motion_reads_test.dart`.

**Skills.** `state-management-riverpod`, `accessibility-as-code`, `sunburst-motion-and-haptics`,
`i18n-rtl-l10n`, `app-startup-and-bootstrap`, `dart3-idioms-and-coding-standards`,
`widget-golden-and-a11y-testing`.

**Screenshot check.** n/a (no visual surface). The Settings rows that drive these flags are E08's and
are compared there against `08-settings.png` and `design/sunburst-pop/screens/rtl/08-settings.png`.

**Done when.**
- [ ] No new settings type exists; `grep -rn "class .*Settings" lib/` returns only E02's `AppSettings`.
- [ ] `MotionPreferenceScope` is mounted exactly once, in `lib/app.dart`, and the PR body states that
      E08 writes the flag rather than adding a second fold.
- [ ] The fold is an OR; a device with the OS flag on cannot be re-enabled by the app switch.
- [ ] The scope adds no `Directionality`; `grep -rn "Directionality(" lib/app.dart` is empty.
- [ ] `ban-legacy-providers.sh` and `check_i18n_bans.sh lib` green.

**Commits.**
1. `test: assert the derived haptic and sound gate providers over E02 settings`
2. `feat: add the derived feedback gate providers`
3. `test: assert the reduce-motion fold ORs into MediaQuery and preserves direction, locale and size`
4. `feat: add MotionPreferenceScope and mount it once in app.dart`

---

### T06.5 — Replace `SilentFeedbackService` with the real gated implementation
**Goal.** The one API feature code calls — `ref.read(feedbackServiceProvider).fire(Moment.x)` — that
resolves a moment to its verb and sound slot, applies the settings gates once, and can never fire
twice or throw. E05 shipped the interface and a no-op behind `feedbackServiceProvider`; this task makes
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
- `the service is locale-blind` — firing every moment under `en`, `de`, `fa` and `ckb` records the
  identical verb sequence, and the file imports neither `AppLocalizations` nor `package:intl`. A
  haptic is not a string; nothing here has a translation.
- `a throwing gateway does not surface` — `FakeHapticGateway.failing()`, `fire(...)` returns
  normally, the zone records no unhandled error, and the failure is logged once.
- `fire returns void` — a compile-time shape assertion via a `VoidCallback` binding, so the
  arrow-callback Future-drop hole is unreachable from a call site.

`test/shared/feedback/feedback_service_provider_test.dart`
- `the provider rebuilds when a gate flips` — flipping `isHapticsEnabled` through E02's notifier yields
  a service instance that no longer reaches the gateway.

**Implementation.** `lib/shared/feedback/feedback_service.dart` **(edit)**: keep
`abstract interface class FeedbackService` and `feedbackServiceProvider` exactly as E05 declared them —
every E05 component already calls through them. Add `final class LiveFeedbackService implements
FeedbackService` with a `const` constructor taking
`{required HapticGateway gateway, required bool hapticsEnabled, required bool soundEnabled}` — plain
bools, so every test above is a unit test. `void fire(Moment moment)` looks the moment up in
`kMomentCatalog`, returns early if `!hapticsEnabled`, and otherwise
`unawaited(_gateway.play(verb).catchError(_swallow))` where `_swallow` logs with its stack and
returns. `SoundCue? soundCueFor(Moment)` returns the slot or `null` when `soundEnabled` is false — an
enum value, never a string, so no sound slot can ever be accidentally translated or formatted.
`feedbackServiceProvider` is re-pointed — same name, same type — at a plain `Provider<FeedbackService>`
watching `hapticGatewayProvider`, `hapticsEnabledProvider` and `soundEnabledProvider` and returning a
`LiveFeedbackService`. `SilentFeedbackService` stays: it is what `test/support/` and any headless
container use, and deleting it would leave every notifier test needing a gateway. Keep the `//` above
`unawaited` stating why this seam is `void` — `async-safety`'s comment that must survive a tidy-up.

**Files.** `lib/shared/feedback/feedback_service.dart` (edit — E05 created it),
`test/shared/feedback/feedback_service_test.dart`,
`test/shared/feedback/feedback_service_provider_test.dart`.

**Skills.** `sunburst-motion-and-haptics`, `motion-and-haptics`, `async-safety`,
`state-management-riverpod`, `service-boundary-and-native`, `testing-strategy`, `dartdoc-conventions`.

**Screenshot check.** n/a (no visual surface).

**Done when.**
- [ ] `fire` is `void`, gated once, and calls the gateway at most once per invocation.
- [ ] `heavyImpact` reaches the gateway only for `Moment.personalBest`.
- [ ] Reduce motion is nowhere in this file; neither is a locale, a `NumberFormat` or a string.
- [ ] No call site anywhere checks a settings flag before calling `fire` (the second gate is the one
      that gets forgotten).

**Commits.**
1. `test: assert exactly-once firing, the three gates and the failing-gateway path`
2. `feat: add LiveFeedbackService with the single settings gate`
3. `refactor: serve LiveFeedbackService from the existing feedbackServiceProvider`

---

### T06.6 — Replace E05's stub `PressPhysics` with the real controller
**Goal.** One interruptible controller at `durTap`, the state-vs-animation split under reduce motion,
the commit haptic fired exactly once, and a press that travels along the light-source axis in every
locale — handed geometry, never choosing it. E05 shipped
`lib/shared/motion/press_physics.dart` with the `PressGeometry`/`PressBuilder`/`PressPhysics` shapes so
`PopSurface` could be pressable; this task fills in the timing behind the same public signatures.

**Tests first (TDD).** `test/shared/motion/press_physics_test.dart` (`useDevice(390×844)` at DPR 2 +
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
- **`the press does not mirror`** — the same full tap pumped under `Locale('en')` and under
  `Locale('fa')`: at `t == 1` the `Transform.translate` offset is the identical **positive**
  `Offset(travel, travel)` in both, and the pressed shadow is `Offset(1, 1)` in both. The `reason:`
  carries the argument: the surface travels down its own hard offset shadow, and the shadow is a
  light-source constant — mirroring it would detach the object from its shadow and light the Persian
  build from the other side. Repeat once under `Locale('ckb')` so the assertion covers both RTL
  locales, not just the one with a Material delegate of its own.
- `PressPhysics never asks which way the page reads` — the source file contains no `Directionality`
  and no `TextDirection`.
- `the hit area does not move` — `tester.getRect(find.byType(GestureDetector))` is identical before
  and during the press, under `en` and under `fa`.
- `the minimum target is honoured` — the gesture's rect is ≥ `kPopMinTarget` on both axes, in all four
  locales (a German label is the widest, a Persian one the tallest; neither may shrink the target).
- `the controller is disposed` — pump the widget out mid-press; no "ticker was disposed" and no
  pending-timer failure.

**Implementation.** `lib/shared/motion/press_physics.dart` **(edit — E05 created it)**, following
`.claude/skills/sunburst-motion-and-haptics/examples/press_physics.dart`: `@immutable PressGeometry`
(`t`, `shadow`, `isDown`), `typedef PressBuilder`, and `PressPhysics extends ConsumerStatefulWidget`
taking `restShadow`, `pressedShadow`, `travel`, `scale`, `minTarget`, `builder`, `commitMoment`,
`child`, `onPressed`. One `AnimationController` with its duration set in `didChangeDependencies` from
`SunburstMotion.of(context)`; `_drive` sets `value` directly when `resolve` returns `Duration.zero`
and `animateTo` otherwise. `GestureDetector` (opaque) outside the `ConstrainedBox` and both
`Transform`s. **No** `Semantics` here — `PopSurface` owns the button semantics. **No** elevation enum
here — this widget takes the four numbers already resolved. **No** `Directionality` read, and a `//`
above the `Transform.translate` stating why: `MotionAxis.fixed`, light-source constant, never mirrored.

**Files.** `lib/shared/motion/press_physics.dart` (edit), `test/shared/motion/press_physics_test.dart`,
`test/support/harness.dart` (extend E03's file if it lacks a reduce-motion wrapper; never fork it —
E04 T04.10 already added `LocaleCase` and `pumpLocalized` to the same file).

**Skills.** `sunburst-motion-and-haptics` (read `references/press-physics.md` in full),
`sunburst-components`, `sunburst-tokens`, `i18n-rtl-l10n`, `widget-composition`, `async-safety`,
`widget-golden-and-a11y-testing`, `dart3-idioms-and-coding-standards`.

**Screenshot check.** n/a (no visual surface of its own — `PressPhysics` paints nothing and calls
back into a builder). The pressed chrome, LTR and RTL, is checked in T06.7.

**Done when.**
- [ ] Exactly one `AnimationController` and one `GestureDetector` in the file.
- [ ] No `Duration(`, no `Curves.`, no `PopElevation`, no `HapticFeedback`, no `Directionality`.
- [ ] Reduce motion drops the transform and keeps the shadow and `isDown`, on the pointer-down frame.
- [ ] The press geometry under `fa` and `ckb` is identical to the geometry under `en`.
- [ ] `check_motion_tokens.sh lib`, `check_raw_values.sh lib`, `check_i18n_bans.sh lib`,
      `check-widget-composition.sh` green.

**Commits.**
1. `test: assert press commit-once, cancel, interruption and reduce-motion split`
2. `feat: drive PressPhysics with one interruptible controller at durTap`
3. `test: assert the hit area never moves and the press never mirrors under RTL`

---

### T06.7 — Compose `PressPhysics` into `PopSurface`; delete the second press path
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
- `the derived geometry is identical in every locale` — the four assertions above repeated under
  `en`, `de`, `fa` and `ckb`. A German label makes the surface wider and a Persian one makes it
  taller; neither changes the travel, the scale or the pressed shadow.
- `the existing PopSurface contract is unchanged` — E05's `pop_surface_test.dart` passes untouched.

`test/policy/single_press_implementation_test.dart`
- `no component drives its own press` — grep `lib/ui/components/**`: no `AnimationController`, no
  `onTapDown`, no `onTapCancel`. The only permitted file naming them is
  `lib/shared/motion/press_physics.dart`.

**Golden lane.** `test/goldens/press_test.dart`, tagged `@Tags(['golden'])`, `setUpAll(loadAppFonts)`,
following the pinned-phase recipe in `references/press-physics.md`: `startGesture`, `pump()`,
`pump(durTap)`, then `matchesGoldenFile`. Five files:

| Golden | Locale | What it exists to catch |
|---|---|---|
| `pop_button_rest.png` | `en` | the resting frame the rewire must not change |
| `pop_button_pressed.png` | `en` | the pressed chrome at a pinned phase |
| `pop_button_pressed_reduce_motion.png` | `en` | a "simplification" of the reduce-motion branch into a no-op |
| `pop_button_pressed_fa.png` | `fa` | the pressed frame with an RTL label in Arabic script and real bundled fonts — label mirrors, shadow does not |
| `pop_button_pressed_de.png` | `de` | the longest label in the set against the pressed chrome; nothing shrinks to fit |

Plus two assertions that goldens alone cannot make: the reduce-motion golden **differs** from the
resting golden, and the `fa` frame's `Transform.translate` offset **equals** the `en` frame's (the
pixel diff between them is text, not geometry).

**Implementation.** Remove `PopSurface`'s own gesture handling and press controller. `PopSurface`
computes `elevation.restOffset(shape)`, `shape.pressTranslate(rest)`, `SunburstShape.pressedShadow`
and `elevation.pressScale(shape)`, then wraps its decoration builder in `PressPhysics` with
`minTarget: kPopMinTarget` and the caller's `commitMoment` (defaulting to `Moment.buttonCommit`).
`PopSurface`'s public constructor gains one optional `Moment commitMoment` parameter and loses
nothing. The disabled path keeps `onPressed: null` so the controller is never driven. No directional
geometry changes here: E05 authored `PopSurface` with `EdgeInsetsDirectional` and
`AlignmentDirectional` from its first commit, and this task must not introduce a physical side while
moving code.

**Files.** `lib/ui/components/pop_surface.dart` (edit), any component that reimplemented a press
(edit), `test/ui/components/pop_surface_press_test.dart`,
`test/policy/single_press_implementation_test.dart`, `test/goldens/press_test.dart`,
`test/goldens/press/*.png`.

**Skills.** `sunburst-components`, `sunburst-motion-and-haptics`, `sunburst-tokens`, `i18n-rtl-l10n`,
`widget-golden-and-a11y-testing`, `widget-composition`.

**Screenshot check.** Follow **E05's screenshot policy**, for E05's reason: this task renders isolated
components, not screens. Compare the **resting** frames of `PopButton`, `GameCard` and `PopToggle`
against the rendered gallery in `design/sunburst-pop/system.html` §10 — *Primary button*, *Game card*,
*Toggle switch* — in the order structure → spacing rhythm → surface construction → type role → sampled
hex. The rewire must change no resting pixel; any difference is an implementation defect in this task,
not a design question, and the strongest evidence is that E05's committed component goldens still match.

**There is no RTL rendering of the `system.html` gallery.** D7's RTL reference set is a `dir="rtl"`
Persian variant of `app.html`, so it covers the eight screens and not the component gallery. The RTL
comparison for these components is therefore in situ and belongs to E08 — `screens/rtl/01-home.png`
for `GameCard`, `screens/rtl/08-settings.png` for `PopToggle` — and here it is covered by
`pop_button_pressed_fa.png` and the geometry assertion beside it. Record that in the PR body rather
than implying an RTL reference was checked.

Home and Settings do not exist until E08, so **`01-home.png` and `08-settings.png` are not comparable
here** — the in-situ comparison of the same components belongs to E08 T08.5 and T08.9 and is recorded
there. **The pressed and reduce-motion frames have no reference at all** — every reference in this
project is an end state — so they are covered by the golden lane above and by the on-device pass in
E11. Record both limitations in the PR body. If a resting difference turns out to be a genuine
reference error, the change goes into `system.html` (and `app.html` + `capture-screens.sh` where
geometry is at stake, which now regenerates **both** the LTR and the RTL sets) and is committed as a
deliberate design change.

**Done when.**
- [ ] `lib/ui/components/**` contains no `AnimationController`, `onTapDown` or `onTapCancel`.
- [ ] Every press in the app runs through `PressPhysics`.
- [ ] Five goldens committed; the reduce-motion golden differs from the resting golden; the `fa` and
      `en` pressed frames share one `Transform.translate` offset.
- [ ] Resting frames match `system.html` §10; E05's component goldens are unchanged by the rewire.
- [ ] `check_component_hygiene.sh lib`, `check_motion_tokens.sh lib` and `check_i18n_bans.sh lib` green.

**Commits.**
1. `test: assert PopSurface hands PressPhysics derived geometry and the commit moment`
2. `refactor: compose PressPhysics into PopSurface and remove its own press path`
3. `test: add the policy grep for a single press implementation`
4. `test: add pinned-phase press goldens for rest, pressed, reduce motion, fa and de`

---

### T06.8 — The bounded celebration and the bounded shake
**Goal.** The only two multi-phase motions in the app, both with explicit stop conditions:
`PopCelebration` (`personalBest`, `streakMilestone`, `countdownBeat`) and `ShakeOnWrong`
(`answerWrong`, two cycles, no third). Neither mirrors: a scale pop has no reading direction, and the
shake is symmetric about zero.

**`ShakeOnWrong` is created here and nowhere else**, at `lib/shared/motion/shake_on_wrong.dart`. Both
games need it — E09's answer key and E10's tile — so it is shared code by construction. A copy under
`lib/games/stroop_rush/ui/board/` or a third path under `lib/ui/motion/` is a review reject on that
epic; E09 T09.7 and E10 T10.7 wire this widget in and add no file. `lib/shared/motion/` must therefore
be importable from `lib/games/**` under `check_import_boundaries.sh` — assert that in T06.10's policy
test rather than discovering it in E09.

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
- **`the celebration does not mirror`** — pumped under `Locale('fa')` and `Locale('ckb')`, the scale
  sequence values and the −2.5° resting tilt are identical to `Locale('en')`, with no sign flip on the
  rotation. `reason:`: a scale pop is `MotionAxis.none` and the badge tilt is a shape constant of
  `.badge.new`, the same class of decision as the hard offset shadow. The file reads no
  `Directionality`.
- `it imposes no direction on its child` — the celebration wraps a Persian label and adds no
  `textDirection`, so the child inherits the ambient direction from the locale.

`test/shared/motion/shake_on_wrong_test.dart`
- `it runs exactly two cycles` — `pump(durCelebrate * 2 + 1ms)` returns to offset zero; a third cycle
  never starts.
- `reduce motion skips the shake entirely` — zero frames scheduled; the caller's residue carries it.
- `disposal mid-flight stops it` — pump the widget out between cycles; no pending timer, no
  "setState after dispose".
- `a rebuild does not re-trigger it` — `didUpdateWidget` with `isWrong` still true does not start a
  new sweep; only a false→true edge does.
- **`the shake is symmetric, so mirroring it is the identity`** — the sampled offsets under `fa` equal
  those under `en` frame for frame. The sweep is `0 → −4 → +4 → 0`: it is `MotionAxis.inline` because
  it moves along the reading axis, and it is the one inline moment that needs no `Directionality`,
  because negating a symmetric sweep produces the same animation. The `reason:` says exactly that, so
  the next reader does not "fix" it by threading a direction through — and the test fails loudly if
  someone makes the sweep asymmetric without also making it directional.

**Implementation.** `PopCelebration extends ConsumerStatefulWidget` taking `{required Moment moment,
required Widget child, double restingTiltDegrees = 0}`: controller created with `value: 1`, scale as
a `TweenSequence` `0.86 → 1.06 → 1.00` on `curveFor(CurveRole.pop)` at `durationFor(MotionRole.celebrate)`,
a `_hasPlayed` latch set *before* any early return, `fire(moment)` before the stop-condition checks,
then `if (MediaQuery.disableAnimationsOf(context)) return;` and
`if (ModalRoute.of(context)?.isCurrent != true) return;`, `unawaited(_pop.forward(from: 0))`,
`dispose()`. No barrier, no `AbsorbPointer`. `ShakeOnWrong extends StatefulWidget` per
`examples/feedback_moments.dart`: a `TweenSequence` `0 → −4 → +4 → 0` at `durCelebrate` on `easeOut`,
played as two awaited `forward(from: 0)` calls with a `mounted` guard between them — the absence of a
third line is the stop condition, stated in a `//`. Both files carry a `//` naming their `MotionAxis`
and why they read no `Directionality`.

**Files.** `lib/shared/motion/pop_celebration.dart`, `lib/shared/motion/shake_on_wrong.dart`,
`test/shared/motion/pop_celebration_test.dart`, `test/shared/motion/shake_on_wrong_test.dart`.

**Skills.** `sunburst-motion-and-haptics`, `motion-and-haptics`, `i18n-rtl-l10n`, `async-safety`,
`widget-composition`, `widget-golden-and-a11y-testing`, `dartdoc-conventions`.

**Screenshot check.** n/a (no visual surface — both are transform wrappers around a caller's child).
The badge they wrap is `06-results.png`'s personal-best badge and its RTL counterpart
`design/sunburst-pop/screens/rtl/06-results.png`; both are compared in E08.

**Done when.**
- [ ] Neither file contains `.repeat(`; both dispose their controller.
- [ ] The haptic fires above every stop condition in `PopCelebration`.
- [ ] `ShakeOnWrong` has exactly two `forward(from: 0)` calls.
- [ ] Neither file reads `Directionality`; both carry the `//` saying which axis they are and why.
- [ ] The measured peak scale of the celebration is recorded in the test's `reason:` string (see
      Risks — `easePop` over a `TweenSequence` overshoots past 1.06).
- [ ] `check_motion_tokens.sh lib` green (the `.repeat(` arm has nothing to find).

**Commits.**
1. `test: assert the celebration plays once, blocks nothing and rests at its end state`
2. `feat: add PopCelebration with latch, stop conditions and haptic-first ordering`
3. `test: assert the wrong-answer shake runs exactly two cycles and stops on dispose`
4. `feat: add ShakeOnWrong as two bounded forward passes`
5. `test: assert neither celebration nor shake mirrors under fa or ckb`

---

### T06.9 — `DirectionalSlide`: the one motion that mirrors
**Goal.** Exactly one place in the app converts a start-edge offset into a physical one. Everything
that moves along the reading axis — the route transition, and any sheet or affordance that ever slides
horizontally — goes through it; everything else does not, and the policy test in T06.10 makes that
enforceable rather than aspirational.

**Tests first (TDD).** `test/shared/motion/directional_slide_test.dart` (`useDevice(390×844)`,
`pumpLocalized`)
- `an inline slide enters from the end edge under LTR` — with `axis: MotionAxis.inline` and
  `beginStart: Offset(1, 0)` at `t == 0` under `Locale('en')`, `tester.getRect(child).left >= 390`:
  the child is off-screen to the physical **right**.
- `an inline slide enters from the other edge under RTL` — the same widget, same offset, under
  `Locale('fa')`: `tester.getRect(child).right <= 0`, off-screen to the physical **left**. Repeated
  under `Locale('ckb')`.
- `an inline slide lands in the same place in both directions` — at `t == 1` the child's rect is
  identical under `en` and `fa`. Mirroring is about where it comes *from*, never where it ends.
- `a vertical slide is identical in both directions` — with `axis: MotionAxis.vertical` and
  `beginStart: Offset(0, 1)`, the rects at `t == 0` and `t == 0.5` are equal under `en`, `de`, `fa`
  and `ckb`. The pause sheet rises from the bottom edge in every language.
- `a fixed or none axis is rejected at construction` — `DirectionalSlide(axis: MotionAxis.fixed, …)`
  trips its assert. The press does not belong here and cannot be routed here by accident.
- `an inline slide with a zero dx is rejected` — an `inline` axis whose `beginStart.dx == 0` is a
  mis-declared vertical motion; the assert says so.
- `a live locale switch re-mirrors without a restart` — drive the locale `en → fa → ckb → en` through
  E04's `localeProvider` while a slide is mounted; the entry edge follows on each switch, no exception
  is thrown, and no restart is needed. This is the test that exercises E04's `ckb` delegate under a
  motion widget: if the delegate is missing, this is where it throws, loudly, in CI.
- `the duration and curve come from the catalog` — a slide built for `Moment.routeTransition` runs at
  `durMove` on `easeInOut`, and collapses to `Duration.zero` under `disableAnimations: true`.

`test/ui/components/pop_progress_bar_motion_test.dart` — the progress fill is a component E05 built
and a motion this epic governs. E05 already asserts the bar's **resting** geometry mirrors; these
assertions are the motion half and must not restate it.
- `the fill grows from the start edge` — a `PopProgressBar` at 0.24 under `Locale('en')` has its
  filled rect flush with the track's physical **left** edge; under `Locale('fa')` flush with the
  physical **right** edge; the filled width is equal in both, to the pixel. The anchor is
  `AlignmentDirectional.centerStart` and mirrors by construction — no `Directionality` read, no
  conditional, and no `DirectionalSlide` (the fill changes size, it does not travel).
- `an advancing fill animates through SunburstMotion` — driving the value 0.24 → 0.32 tweens over
  `durState` and collapses to `Duration.zero` under `disableAnimations: true`; the end value is
  identical either way.
- `the fill is not driven by a repeating controller` — no `.repeat(` reaches the bar; it renders the
  value it is given, so a backgrounded run costs nothing.

**Implementation.** `lib/shared/motion/directional_slide.dart` —
`final class DirectionalSlide extends StatelessWidget` taking
`{required Animation<double> t, required Offset beginStart, required MotionAxis axis, required Moment moment, required Widget child}`.
It builds one `SlideTransition` and passes
`textDirection: axis.mirrorsUnderRtl ? Directionality.of(context) : null` — `SlideTransition`'s own
`textDirection` parameter applies the x offset in reading order when set and in canvas coordinates
when null, which is why no `dx` is ever negated by hand (`i18n-rtl-l10n`, `references/rtl-and-bidi.md`:
never invert `dx` for RTL). An `assert` rejects `MotionAxis.fixed` and `MotionAxis.none`, and rejects
an `inline` axis with `beginStart.dx == 0`. Duration and curve are read off `kMomentCatalog[moment]`
through `durationFor`/`curveFor`, so a slide cannot pick a timing the catalog did not declare.

This is the **only** `SlideTransition` in the app. E08 wraps it for the route transitions
(`Moment.routeTransition`, `MotionAxis.inline`) and the pause sheet (`Moment.sheetTransition`,
`MotionAxis.vertical`) and adds no file; `PopToggle`'s knob travel (`Moment.toggleFlip`,
`MotionAxis.inline`) is a positioned child rather than a page slide and mirrors through
`AlignmentDirectional` in E05's component — assert that in E05's suite, not here, and say so in a `//`
so the third reader does not add a redundant wrapper.

MindForge has **no horizontal swipe affordance today**: nothing in `app.html` drags sideways, and the
pause sheet is a bottom sheet. If one ever lands, it takes `DirectionalSlide` with
`MotionAxis.inline` and its gesture reads `Directionality.of(context)` at the same seam. Written down
here so the answer exists before the feature does.

**Files.** `lib/shared/motion/directional_slide.dart`,
`test/shared/motion/directional_slide_test.dart`,
`test/ui/components/pop_progress_bar_motion_test.dart`.

**Skills.** `i18n-rtl-l10n` (read `references/rtl-and-bidi.md` in full), `motion-and-haptics` (rule
14), `sunburst-motion-and-haptics`, `sunburst-components`, `widget-composition`,
`widget-golden-and-a11y-testing`, `dartdoc-conventions`.

**Screenshot check.** n/a (no screen of its own — `DirectionalSlide` is a transform wrapper and the
progress bar is a component). The transitions it drives are between screens and have no PNG in either
set; the bar it governs is rendered in `05-schulte-grid.png` and
`design/sunburst-pop/screens/rtl/05-schulte-grid.png`, and the in-situ comparison belongs to E08's play
scaffold and E10's board.

**Done when.**
- [ ] `grep -rn "SlideTransition" lib/` returns exactly `lib/shared/motion/directional_slide.dart`.
- [ ] No `dx` is negated anywhere in `lib/`; the mirroring is `SlideTransition`'s `textDirection`.
- [ ] A vertical slide is pixel-identical in all four locales; an inline slide is not, and lands in
      the same place regardless.
- [ ] The live `en → fa → ckb → en` switch re-mirrors with no restart and no exception.
- [ ] The progress fill grows from the start edge in `en` and `fa`, with equal width, and runs no
      repeating controller.
- [ ] `check_i18n_bans.sh lib` and `check_motion_tokens.sh lib` green.

**Commits.**
1. `test: assert inline slides mirror, vertical slides do not, and a live locale switch re-mirrors`
2. `feat: add DirectionalSlide as the only SlideTransition in the app`
3. `test: assert the progress fill grows from the start edge and animates through SunburstMotion`

---

### T06.10 — Close the gates
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
  render and write the toggle (E08 T08.9); the second *gate* is the thing being banned, not the second
  *mention*. State that distinction in the `reason:` — the naive version of this test goes red the day
  the Settings screen lands and gets deleted rather than fixed.
- `one shake implementation` — `ShakeOnWrong` is declared in exactly one file, and it is
  `lib/shared/motion/shake_on_wrong.dart`; `lib/games/**` may reference it but may not declare it.
- `one slide implementation` — `SlideTransition` is constructed in exactly one file, and it is
  `lib/shared/motion/directional_slide.dart`. This is the assertion `check_i18n_bans.sh` structurally
  cannot make: a slide offset is not physical-side geometry, so the grep gate never sees it.
- `non-directional motion never reads direction` — `press_physics.dart`, `pop_celebration.dart` and
  `shake_on_wrong.dart` contain no `Directionality` and no `TextDirection`, and no file in `lib/`
  negates a `dx` behind a direction check (`grep -nE 'rtl.*-.*dx|dx.*\*.*-1'`).
- `the sensory layer renders no strings` — no file under `lib/shared/feedback/` or
  `lib/shared/motion/` imports `AppLocalizations` or `package:intl`, and `residueNote` is referenced
  nowhere outside `moment_catalog.dart` and its test. A moment is a semantic token; a locale cannot
  change what fires.
- `shared motion is importable from games` — `lib/shared/motion/` appears in
  `check_import_boundaries.sh`'s allowed edges from `lib/games/**`, so E09 and E10 can wrap
  `ShakeOnWrong` without a boundary waiver.

Each assertion strips comment-only lines first, accumulates all hits, and fails once with a message a
stranger can act on (`references/policy-grep-gate.md`).

**Implementation.** Confirm `.github/workflows/ci.yml` (E01) already runs `check_motion_tokens.sh lib`
and `check_i18n_bans.sh lib` through `tool/skill_gates.sh`; add either to the runner's run table if it
is not there, with a comment naming the contract it blocks on. `dart_test.yaml`'s `golden` tag is
**E05's** and already exists — do not add a second one. Never `--update-goldens` in CI.

Add a short **"What CI cannot prove here"** note to the workflow beside the haptic gate:

- **No haptic is real in CI or in a simulator.** The iOS Simulator has no Taptic Engine; the fake
  gateway proves *call count* and nothing about intensity, about a burst that reads as a rattle, or
  about iOS's sleeping Taptic Engine right after foregrounding. Those are physical-iPhone checks and
  belong to E11's `design-review-workflow` sweep, graded BLOCKER.
- **No audio exists at all** — nine named slots, no assets, no player.
- **Nothing here is verified on Android.** Android is deferred; the workflow builds and tests for iOS
  only, and no gate in it implies parity.
- **Translation quality is not a gate.** The `fa` and `de` goldens prove that Arabic-script and long
  German labels render and fit; they say nothing about whether the words are right. Native review is
  E04's open item and E11's sign-off.

**Files.** `test/policy/motion_policy_test.dart`, `.github/workflows/ci.yml` (edit if needed).

**Skills.** `ci-pipeline-and-gates`, `testing-strategy`, `sunburst-motion-and-haptics`,
`i18n-rtl-l10n`, `widget-golden-and-a11y-testing`.

**Screenshot check.** n/a (no visual surface).

**Done when.**
- [ ] Every gate below is a CI step, none `continue-on-error`.
- [ ] `flutter test test/policy/` green.
- [ ] The workflow states the four things it cannot prove, in a comment, next to the haptic gate.

**Commits.**
1. `test: add the motion and haptic source-graph policy gates`
2. `test: add the directional-motion policy gates (one slide, no direction reads)`
3. `ci: wire the motion and i18n gates with an honest limits note`

## Gates that must pass

Run from the repository root, in this order, before the PR:

```bash
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs   # ALWAYS before analyze
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos --fatal-warnings
flutter test --test-randomize-ordering-seed random

# every skill gate, through the one runner E01 built
bash tool/skill_gates.sh

# this epic's named spot-checks, run individually so a failure names itself
.claude/skills/sunburst-motion-and-haptics/scripts/check_motion_tokens.sh lib
.claude/skills/i18n-rtl-l10n/scripts/check_i18n_bans.sh                   lib
.claude/skills/i18n-rtl-l10n/scripts/check_arb_parity.sh                  lib/l10n
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

Then the manual pass, on the canonical device and nothing else:

```bash
xcrun simctl boot C13DDC02-375D-4E1B-8F81-44EB407D09A4     # MindForge iPhone 14, iOS 18.6, 390x844
flutter run -d C13DDC02-375D-4E1B-8F81-44EB407D09A4
```

Press every control in `en`, `de`, `fa` and `ckb`, with Reduce motion on and off. **There is no
Android gate.** Android is deferred; nothing in this list runs on it.

The primary gate for this epic is `check_motion_tokens.sh lib`, and it must print
`OK: motion values tokenized, haptics confined to the feedback service, nothing repeating.` over real
code. A `note: 'lib' not found` line is not a pass.

## Risks and open questions

1. **E05 shipped the seam; this epic must not rebuild it.** E05 T05.3 created `moment.dart`,
   `feedback_service.dart` and `press_physics.dart` because `PopSurface` could not be pressable without
   them. **Decision:** T06.1, T06.5 and T06.6 are *edits*. `PopSurface`'s public constructor is E05's
   contract; E06 may add one optional `commitMoment` parameter and change internals only. **E06 may not
   add a second press controller** — if E05 shipped a second press path anywhere, delete it in T06.7
   rather than leaving it unreferenced. Ask whoever landed E05 before starting T06.6.
2. **Kurdish Sorani (`ckb`) is the sharp technical risk, and it surfaces here first.**
   `flutter_localizations` ships `GlobalMaterialLocalizations`/`GlobalCupertinoLocalizations` for a
   fixed locale list, and `ckb` is very likely not in it; a missing delegate throws at runtime on
   locale switch. E04 owns the fix — a custom `LocalizationsDelegate` serving our ARB strings for `ckb`
   while delegating Material/Cupertino to the nearest script neighbour (`fa`, else `ar`) — and E04
   verifies the actual delegate list at build time rather than assuming. **This epic does not
   re-solve it; it exercises it.** T06.9's live `en → fa → ckb → en` switch and the `ckb` arms of
   T06.1, T06.6 and T06.8 are where a missing delegate becomes a red test in CI instead of a crash in
   somebody's hand. If those tests throw when the branch opens, the fix is in E04.
3. **Sorani glyph coverage is unresolved at the time of writing.** Vazirmatn covers Persian and Sorani
   for body; the display face is the open one — Lalezar is the closest OFL echo of Fredoka, and its
   coverage of the Sorani-specific letters (ڕ ڵ ۆ ێ ھ) is **not** assumed. E04 verifies it and falls
   back to Vazirmatn Bold for display if it fails. **Consequence here:** `pop_button_pressed_fa.png`
   renders with whatever E04 resolved, and a `ckb` label in a display face that lacks those letters
   would show tofu in a golden. If E04's outcome is not recorded in E04's epic when this branch opens,
   stop and get it recorded — do not bless a golden whose font story is unknown.
4. **Be honest that the Fredoka personality does not survive translation.** In `fa` and `ckb` no
   bundled face carries Fredoka's chunky arcade voice. The identity in those locales is carried by the
   **shape language** — the 3px ink border, the hard offset shadow, the press-down, the palette — and
   this epic is where three of those four live. That is a design fact to state in the PR body, not a
   defect to fix with a font swap, and it is the strongest argument for why the press must keep its
   travel and its shadow under RTL rather than being quietly simplified away.
5. **Settings are persisted by E02 and written by E08; this epic only reads them.** In the
   pre-localization sequence this epic shipped an in-memory `AppSettings`. That is no longer true and
   the old text is a trap: creating a settings type here would shadow E02's persisted one and silently
   drop every toggle on relaunch. **Decision:** read E02's `settingsProvider` and write nothing here;
   add the two derived gate providers and the root fold, create no value type and no notifier. If a
   field is missing, fix E02.
6. **Sound has nine named slots and no assets.** `system.html` specifies a Sound settings row and no
   audio at all. **Decision:** `SoundCue` is data; `FeedbackService.soundCueFor` returns the slot and
   nothing plays it. Do **not** add an audio package — a new dependency needs a `dependency-hygiene`
   audit, and no moment may ever depend on its sound (rule 8). The open question, for whoever owns the
   audio decision: does MindForge ship sound at all, or is the Settings row removed? Ask before E11.
   Note the second-order localization cost if the answer is yes: nine cues × four locales is a
   recording problem, not a code problem.
7. **Haptics cannot be verified anywhere in CI, and the iOS Simulator has no haptics at all.**
   "Exactly once" is felt, not screenshotted. **Decision:** the fake-gateway unit tests are the
   automated proof of *call count*; the felt behaviour — intensity, a burst that reads as a rattle,
   iOS's sleeping Taptic Engine right after foregrounding — goes on E11's `design-review-workflow`
   device checklist as a BLOCKER-graded item, on a physical iPhone. Say so in the workflow comment
   (T06.10) so nobody reads a green CI as proof.
8. **The Dart catalog can drift from `references/moment-catalog.md`, and the axis column is not in the
   reference at all.** Two sources of truth for the same eighteen rows, and one column that exists only
   in Dart. **Decision:** transcribe the table in a single commit with the reference open, cite the
   reference line in each row's comment, mark the whole `axis` column **DERIVED** with the sentence it
   was derived from, and treat any future change as a change to *both*. **Open question:** whether the
   axis column should be pushed back into `references/moment-catalog.md` as a ninth column. It probably
   should; that is an edit to a skill, so it is proposed in the PR body rather than done unilaterally
   here.
9. **The personal-best badge's −2.5° resting tilt is decided, not proven.** It is treated as a shape
   constant that does not mirror, on the same argument as the hard offset shadow: it is part of the
   badge's construction, not a reading-direction property. A designer could reasonably argue the
   opposite — that a tilt reads as "leaning into" the text flow and should flip. **Decision:** it does
   not mirror, T06.8 asserts that, and the question goes on E11's RTL sweep with
   `design/sunburst-pop/screens/rtl/06-results.png` in hand. If it flips, it flips in one place.
10. **`easePop` over the celebration `TweenSequence` overshoots past 1.06.** `Cubic(0.2, 1.5, 0.4, 1)`
    returns values above 1.0, so a `0.86 → 1.06` segment driven through it peaks above 1.06 — the
    catalog states the amplitude as 1.06. **Open question:** measure the real peak in T06.8's test and
    record it in the `reason:` string. If it is materially above 1.06, ask whether the sequence should
    take `easeOut` with the overshoot living entirely in the curve, or whether the catalog's `1.06`
    describes the tween endpoint rather than the rendered peak. Do not silently change either.
11. **Text expansion is a first-class test axis, and this epic covers only its pressed row.** German
    runs ~30% longer and Persian and Sorani have taller line boxes and different ascender/descender
    metrics, so a label that fits at rest can stop fitting. The full locale × text scale × width
    overflow matrix belongs to E05 (components) and E11 (the sweep). What is unique here is the
    **pressed** frame, which no resting golden matrix ever renders — hence `pop_button_pressed_de.png`.
    Nothing shrinks to fit: no `FittedBox`, no clamped `textScaler`, no ellipsis on a value. A label
    that stops fitting takes a smaller **base** style, which is a token decision in E03, not a press
    decision here.
12. **`lib/shared/motion/` is load-bearing and already in `CLAUDE.md`.** The split matters —
    `check_motion_tokens.sh` fences `HapticFeedback` to `*/feedback/*`, and `PressPhysics` must not sit
    in the same fence as the gateway. **E01 amended `CLAUDE.md`'s layout block once**, adding `core/`,
    `shared/motion/` and `l10n/`, and `test/policy/project_structure_test.dart` reads that block.
    **Do not propose the amendment again here** — three epics each editing the same eight-line root
    document is the churn that amendment exists to avoid.
13. **`ShakeOnWrong` and `DirectionalSlide` will both be copied if this epic does not claim them
    loudly.** Both games want the shake; every screen wants a transition. **Decision:** they live at
    `lib/shared/motion/shake_on_wrong.dart` and `lib/shared/motion/directional_slide.dart` and nowhere
    else; T06.10's policy tests assert a single declaration of each, and E08/E09/E10 wire them in
    rather than adding a file. Stated in the PR body so all three later epics inherit the constraint.
14. **Translation quality is not proven by anything in this epic.** The Persian and Sorani strings the
    goldens render are E04's, and machine-quality Sorani in particular is a real risk. A golden that
    changes because a native speaker fixed a word is an **expected** re-baseline, not a regression —
    re-baseline it and say so in the PR. Native review before ship is E04's open item and E11's
    sign-off, and this epic must not present it as done.

## Definition of done

- [ ] All ten tasks complete, each with its tests committed alongside the code they cover.
- [ ] `Moment` has eighteen values; `kMomentCatalog` has eighteen rows; every row declares a residue
      **and** a `MotionAxis`, partitioned 3 inline / 3 vertical / 5 fixed / 7 none.
- [ ] `HapticFeedback.*` appears in exactly one file; `heavyImpact` reaches the gateway only for
      `Moment.personalBest`.
- [ ] One press implementation: `lib/ui/components/**` drives no controller and handles no pointer.
- [ ] One slide implementation: `SlideTransition` is constructed only in
      `lib/shared/motion/directional_slide.dart`, and no `dx` is negated anywhere in `lib/`.
- [ ] `Moment`, `FeedbackService` and `PressPhysics` were **edited**, not created;
      `git log --diff-filter=A` on those three paths shows E05's commits, not this epic's.
- [ ] No settings value type was created; the three feedback flags are read from E02's persisted
      `AppSettings` through two derived providers and one root fold.
- [ ] `ShakeOnWrong` is declared once, in `lib/shared/motion/`, and `lib/games/**` can import it.
- [ ] Reduce motion is folded into `MediaQuery` once, at the root; nothing outside
      `motion_preference_scope.dart` turns the flag into a `Duration`; the press keeps its fill and
      shadow and drops its transform; the app mounts no root `Directionality`.
- [ ] Directional motion mirrors and non-directional motion does not, each with its own test: the
      inline slide enters from the opposite edge under `fa` and `ckb`; the vertical slide and the
      progress fill's growth direction behave as declared; the press translate, the pressed shadow,
      the celebration scale, the badge tilt and the symmetric shake are identical in all four locales.
- [ ] Nothing animates longer than 240ms per cycle; nothing repeats; the shake is exactly two cycles
      and the celebration exactly one, latched and disposed.
- [ ] `check_motion_tokens.sh lib` prints `OK:` over real code; `check_i18n_bans.sh lib` and
      `check_arb_parity.sh lib/l10n` pass; `bash tool/skill_gates.sh` is green.
- [ ] Resting frames of `PopButton`, `GameCard` and `PopToggle` compared against `system.html` §10
      (E05's screenshot policy — Home and Settings do not exist until E08); differences resolved as
      implementation defects, or as a deliberate `system.html`/`app.html` change committed with any
      regenerated PNGs from **both** the LTR and RTL sets. The PR body records that the in-situ
      comparison is E08's and that `system.html` has no RTL rendering to compare against.
- [ ] Five press goldens committed — rest, pressed, pressed-under-reduce-motion, pressed-`fa`,
      pressed-`de` — with real bundled fonts loaded (never Ahem for Arabic script); the reduce-motion
      golden differs from the resting one and the `fa` and `en` pressed frames share one translate
      offset.
- [ ] Manually verified on `MindForge iPhone 14` (`C13DDC02-375D-4E1B-8F81-44EB407D09A4`, iOS 18.6,
      390×844): every control acknowledges a press in `en`, `de`, `fa` and `ckb`, with Reduce motion on
      and off, and switching locale from Settings never throws. Android is not checked and is not
      claimed.
- [ ] `/simplify` run and its findings addressed.
- [ ] `/code-review` run and its findings addressed.
- [ ] Branch `epic/06-motion-and-feedback` pushed with granular commits; PR body states what changed,
      why, how it was verified, that the comparison target was `system.html` §10 and why no screen PNG
      (LTR or RTL) applies yet, and what was deliberately left out (the Settings rows → E08, audio
      playback → open question, on-device haptic verification → E11, native translation review → E04
      and E11, Android → deferred).
- [ ] CI green on the PR (the pipeline E01 created).
- [ ] Merged preserving the granular commits, branch deleted, back on `main`, `git pull` done.
