# E11 · Accessibility, QA and release

| | |
|---|---|
| **Branch** | `epic/11-accessibility-qa-and-release` |
| **Depends on** | E08, E09, E10 |
| **Unblocks** | nothing — this is the last epic in the v1 sequence |
| **Status** | Not started |

## The epic

The end-of-build sweep and the first shippable build. Every screen exists, both games run, four
locales ship, CI is green — this epic is where we find out whether the thing is actually usable by
someone reading Sorani at 200% system font with reduce-motion on and a colour-vision deficiency, on
an old iPhone. It runs the one structured design/QA pass `design-review-workflow` specifies: a
deterministic screenshot sweep matrix compared against `design/sunburst-pop/screens/*.png` **and**
`design/sunburst-pop/screens/rtl/*.png`, an on-device pass on real hardware, findings graded
BLOCKER/FIX/NOTE with every accessibility-floor violation a mandatory BLOCKER, exactly one scoped fix
round, and a dated sign-off artifact that gates the release.

Two things make this epic different from the one the pre-localization plan described.

**The sweep multiplies by locale.** Eleven surfaces × four locales × two text scales × two palettes
is **176 stills**, not 36. Two of the four locales are right-to-left Arabic script, so half the sweep
is checking things an LTR-only pass never had a name for: reversed or clipped glyphs, Latin runs
reordering inside RTL paragraphs, the wrong numeral block, affordances that mirrored when they should
not, and the hard offset shadow — which must **not** mirror, because it is a light-source constant.

**A native-speaker review of the `fa` and `ckb` copy is a BLOCKER-grade sign-off item.** Machine-
quality Persian and especially Sorani in a shipped UI is a defect, not a polish note. `check_arb_parity.sh`
proves every key exists in every locale; nothing in the pipeline can tell a correct Persian sentence
from a wrong one, and nobody on this team reads Sorani. That gap is closed by a person or the release
does not sign off.

Then it ships **to iOS only**. Android is deferred and this epic makes no claim about it: no `.aab`,
no merged Android manifest, no Play Data Safety form, no Play App Signing. What ships is an App Store
build: a profile-mode performance and size measurement on real iPhone hardware, an app icon and a
native launch screen, `version: 1.0.0+1` in `pubspec.yaml` as the single source of
`CFBundleShortVersionString`/`CFBundleVersion`, signing material kept out of the repo, an obfuscated
build with `--split-debug-info` symbols archived, a permission audit asserting the app requests
**nothing** (zero `NS*UsageDescription` keys, no entitlements, no background modes),
`CFBundleLocalizations` proved equal to the set of shipped ARBs, `PrivacyInfo.xcprivacy` transcribed
from the Pods' own manifests rather than reasoned about, App Store metadata in every locale the store
supports, and a recorded size/cold-start budget that later releases are measured against.

**The localisation posture is not decided here.** E04 decided it — four locales (`en` template, `de`,
`fa`, `ckb`), system locale if supported else `en`, a persisted in-app override, a custom `ckb`
delegate, Eastern Arabic numerals for `fa`/`ckb`, directional-only geometry — and built it. This epic
**verifies** that the shipped tree still matches, and closes the loop the decision opened: the
Language sheet, the numerals on every surface, the fonts inside the shipped IPA, and the copy quality
in the two languages no gate can read.

## Why we need it

Ten epics of green CI prove the Dart compiled and the widget tree matched an assertion. They prove
none of the things that get an app rejected, uninstalled or unusable: real Arabic-script shaping at
the largest system text scale, haptics, whether a Schulte tile is still identifiable in greyscale,
first frame time on old silicon, whether a transitive plugin quietly added a usage-description key to
an app whose entire product promise is that it asks for nothing — and whether the Persian a Persian
speaker reads is a sentence or a machine's guess at one.

`ci-pipeline-and-gates` rule 10 requires the pipeline to state what it cannot prove; this epic is the
load-bearing manual pass that covers exactly that gap, and the sign-off artifact is what makes it a
release blocker rather than a chore someone remembers doing.

Without it: the app ships with an unaudited permission set and a privacy label nobody can defend from
the repo; the release is built without `--split-debug-info`, so the first crash report from a real
user is permanently unreadable; an IPA built straight after a screenshot run carries a simulator slice
and is rejected 90087 after a ten-minute upload; `ckb` throws on locale switch on a device nobody
tested because no iOS system language can select it; and there is no recorded baseline, so the v1.1
size and cold-start numbers can regress with nothing to regress *against*.

## Current state

Verified with `ls` and a toolchain check on 2026-08-19, before E01–E10 have run:

- **No Flutter app.** No `pubspec.yaml`, no `lib/`, no `test/`, no `ios/`, no `.github/`. Four commits
  on `main` (`cb1c3e2`, `4e7e988`, `e8e0f3a`, `2b6fff1`).
- Toolchain on this machine: Flutter **3.44.6** stable · Dart **3.12.2** · DevTools 2.57.0 ·
  Xcode **26.6** (build 17F113) · CocoaPods **1.15.2**. Simulator runtimes: iOS 18.0, 18.6, 26.5.
- **The canonical simulator already exists and is the only honest screenshot target:**
  `MindForge iPhone 14`, UDID `C13DDC02-375D-4E1B-8F81-44EB407D09A4`, iOS 18.6, **exactly 390×844
  logical points** — the size every reference PNG was rendered at. iPhone 16 is 393×852 and 16 Pro is
  402×874; neither can be compared against a 390×844 reference. Boot with
  `xcrun simctl boot C13DDC02-375D-4E1B-8F81-44EB407D09A4`, run with
  `flutter run -d C13DDC02-375D-4E1B-8F81-44EB407D09A4`.
- `.claude/skills/` — 45 skills. **49** gate scripts under `.claude/skills/*/scripts/*.sh`, including
  `release-and-store-shipping/scripts/check-release-hygiene.sh` (usage: `[PROJECT_DIR]`, default `.`),
  `release-and-store-shipping/scripts/check-ipa-slices.sh` (usage: `[IPA_PATH]`, default the newest
  under `build/ios/ipa/`), `i18n-rtl-l10n/scripts/check_i18n_bans.sh` (usage: `[target-dir]`, default
  `lib`) and `i18n-rtl-l10n/scripts/check_arb_parity.sh` (usage: `[arb-dir]`, default `lib/l10n`;
  exits 2 on a directory holding only the template). `design-review-workflow` and
  `accessibility-as-code` ship **no** scripts — their halves are manual by construction.
- `design/sunburst-pop/` — `system.html`, `app.html`, `README.md`, `capture-screens.sh`,
  `screens/01-home.png` … `screens/08-settings.png`, `screens/README.md`, `screens/contact-sheet.html`.
  All eight PNGs are 390×844 @2×, rendered from `app.html` by headless Chrome. `screens/README.md`
  carries the comparison procedure and states the limit plainly: these are **end states only**.
- **`design/sunburst-pop/screens/rtl/` does not exist today.** E04 produces it (D7): a `dir="rtl"`
  Persian variant of `app.html` captured by an extended `capture-screens.sh`. Its eight PNGs are a
  hard input to this epic — without them there is no RTL comparison target and half the sweep is
  judged against nothing.
- `design/sunburst-pop/app.html:1366` is the Settings "Language / English" row: an `.srow` with a
  label, an `.sv` value of `English` and a chevron glyph. The row below it, "About MindForge", carries
  a chevron too. Both are navigable rows in the mock, and both are surfaces this epic's sweep must
  cover — the earlier nine-surface plan omitted them.
- No `design/review/`, no `docs/`, no `store/`, no ADRs.

By the time this epic starts, E01–E10 will have delivered the following. **Verify each before the
first commit; stop and fix the owning epic rather than building a second copy here.**

| From | Must exist |
|---|---|
| E01 (foundation, CI, iOS target) | `pubspec.yaml`, `analysis_options.yaml`, `.github/workflows/ci.yml`, `tool/skill_gates.sh` + `test/policy/skill_gates_coverage_test.dart`, `test/policy/banned_imports_test.dart`, the `ios/` runner and its pinned deployment target |
| E02 (persistence) | `lib/data/` drift database, the settings rows the locale override and the three feedback toggles persist to, `lib/core/score_format.dart` |
| E03 (tokens) | `lib/theme/` — `SunburstColors`/`SunburstShape`/`SunburstMotion`/`SunburstType` with `SunburstScript`/`scriptOf`/`forScript`/`arabicLineFactor`, `game_accent.dart`, and **all four bundled faces** (Fredoka + Nunito from E01, Vazirmatn + the selected display face from T03.7) with their OFL licences registered through `registerSunburstFontLicences()` |
| E04 (localization and RTL) | `l10n.yaml` (`nullable-getter: false`, `arb-dir: lib/l10n`), `lib/l10n/app_en.arb` + `app_de.arb` + `app_fa.arb` + `app_ckb.arb`, `appLocalizationsProvider`, `localeProvider`, the **`ckb` `LocalizationsDelegate`**, `LocaleNumbers.forLocale(Locale)`, `AsciiNumerals.normalize(String)`, `Bidi.isolate` / `Bidi.isolateLtr` / `Bidi.isolateRtl`, `design/sunburst-pop/screens/rtl/*.png`, `test/support/harness.dart`'s `LocaleCase` / `LocaleCase.all` / `pumpLocalized` (E04 T04.10 extended E03's one harness; **there is no `test/support/locales.dart`**), and the ADR recording D1–D9 under `docs/decisions/` |
| E03 (tokens) | `test/support/harness.dart` (`Device`, `Device.all` at DPR 2, `pumpApp`), `test/support/load_app_fonts.dart` (Latin **and** Arabic-script faces) and `dart_test.yaml`'s `golden` tag — all three created in E03 T03.7/T03.9 beside the faces, extended by E04 and E05, never forked |
| E05 (components) | `lib/ui/components/` on `PopSurface`, `PopElevation`, `kPopMinTarget`; `test/support/component_harness.dart` (`pumpPopComponent`) |
| E06 (motion) | `lib/shared/feedback/` — `HapticGateway`, `FeedbackService`, `Moment`, `PressPhysics`, `ShakeOnWrong` |
| E07 (engine core) | `RunNotifier`, `RunPhase`, `RunConfig`, `GameDefinition`, `BoardSnapshot`, `GameHud`, `HudSlot`, `gameRegistryProvider`, `clockProvider` |
| E08 (shell screens) | the eight shell screens under `lib/features/`, plus the destinations the Settings chevrons imply — `language_row.dart` and the `language_sheet.dart` **sheet** (not a route), and the About destination |
| E09 / E10 (games) | `lib/games/stroop_rush/`, `lib/games/schulte_grid/` |

**If E04 named any of its files differently, use E04's names.** A second `LocaleNumbers`, a second
bidi helper, a second locale list or a per-epic copy of the `ckb` delegate is the divergence every
locale assertion in this epic would then be measuring against the wrong thing.

## What we will achieve

A reader can tell this epic is done by checking, in order:

1. The Settings Language row is a live control with a real destination; the Language **sheet** lists
   exactly four options in their own names and scripts — `English`, `Deutsch`, `فارسی`,
   `کوردیی ناوەندی` — the choice survives a cold restart, and switching to `ckb` does not throw.
   `flutter test` fails if the row's `onTap` is null, and `test/policy/l10n_posture_test.dart` fails
   if the shipped tree stops matching E04's ADR.
2. `design/review/<date>/` holds **176** stills named
   `NN-<surface>--<locale>--scale<one|max>--cvd<off|on>.png` plus 16 motion recordings, and
   `dart run tool/verify_review_folder.dart design/review/<date>` exits 0 — including the assertion
   that no `fa`/`ckb` still is pixel-identical to its `en` twin, which is what catches a sweep that
   captured 176 English screens.
3. `docs/review/design-review-<date>.md` exists: date, reviewer, commit sha, build mode, device, the
   176-row matrix inventory, the RTL checklist result, the on-device checklist result, a findings
   table where every row carries a grade and a resolution, and a final line matching
   `^VERDICT: SIGNED OFF$`. No BLOCKER row is unresolved.
4. `docs/review/l10n-review-<date>.md` records a named native speaker per RTL locale, the date, what
   they checked, and their verdict; `test/policy/l10n_review_test.dart` is green, which it cannot be
   while any `app_fa.arb` or `app_ckb.arb` entry still carries the `native-speaker-pending` marker
   E09/E10 committed their drafts under.
5. `docs/release/budgets.md` records, for a named iPhone and iOS version on a named date: cold-start
   first-frame ms, Schulte-grid p95 UI-thread and raster-thread frame ms, Stroop stimulus swap p95
   frame ms, IPA size, and the `--analyze-size` asset breakdown with the Arabic-script font cost
   called out. No metric reads `TBD`.
6. `flutter build ipa --release` produces a build whose `NS*UsageDescription` key set is **empty**,
   whose entitlements request nothing, and whose `CFBundleLocalizations` equals
   `{en, de, fa, ckb}` — the set of shipped `lib/l10n/app_*.arb` files — and `flutter test` proves all
   three.
7. `store/privacy-labels.md`, `store/listing.md`, `store/metadata/<locale>/` and
   `ios/Runner/PrivacyInfo.xcprivacy` exist, agree with each other, and contain no absolute privacy
   claim — a grep test enforces that for the locales the team can read, and the native review covers
   the two it cannot.
8. `git ls-files` returns no `.jks`, `.p12`, `.p8`, `key.properties` or service-account JSON, and
   `.claude/skills/release-and-store-shipping/scripts/check-release-hygiene.sh .` exits 0.
9. A release IPA built with `--obfuscate --split-debug-info=build/symbols/1.0.0+1` — from a tree
   cleaned after the screenshot sweep — passes `check-ipa-slices.sh`, contains the Arabic-script font
   assets, installs on a real iPhone, launches, force-quits and relaunches, and
   `build/symbols/1.0.0+1/` is archived off-machine.
10. The commit is tagged `v1.0.0+1`.

Explicitly **not** in scope: uploading to TestFlight or the App Store, creating the app record, the
App Privacy questionnaire, the Paid Applications Agreement, hosting the privacy policy URL, and the
phased release. Those are account-holder actions with no API (`release-and-store-shipping` rule 14);
the epic produces the artifact and the evidence, a human ships it. Also not in scope: **Android**. It
is deferred, not implied. Adding it later means a new epic that re-runs this entire sweep on Android
hardware, re-verifies the fonts, the numerals and the RTL rendering there, and adds the merged-manifest
whole-set permission assertion this epic has no manifest to make.

## Skills to load

| Skill | Why, for this epic |
|---|---|
| `design-review-workflow` | Owns the whole pass: the matrix (its rule 4 axes are screen × theme × **LTR+RTL**, applied at the largest text scale), the four grading lenses, BLOCKER/FIX/NOTE, the exactly-one-fix-round rule, the destructive-steps-last ordering, and the dated sign-off artifact's required fields. Its RTL cell definition — chrome mirrors, directional insets applied, no bidi garbling, locale-correct numerals, no tofu — is this epic's RTL checklist. Its anti-pattern list names ours directly: "skipping RTL because the OS has no device locale for it" is exactly the `ckb` situation. |
| `release-and-store-shipping` | Owns `version: x.y.z+N` as the only version source, no signing material in git, `--obfuscate --split-debug-info` + archived symbols, the whole-set permission assertion, privacy manifests, the ban on absolute privacy claims, and the size/cold-start budget rule. `references/ios-app-store.md` owns the IPA build, the two symbol layers, and the **simulator-slice rejection** that a screenshot sweep sets up; `references/app-store-connect-submission.md` owns the three account-holder gates, per-display-type screenshots and locale-scoped metadata; `references/privacy-permissions-and-claims.md` owns reading the Pods' own privacy manifests instead of reasoning about them. Supplies both gate scripts. |
| `i18n-rtl-l10n` | Co-owns this epic. Rule 2 (key + placeholder parity, gated by `check_arb_parity.sh` — which now actually runs), rule 5 (directional-only geometry, gated by `check_i18n_bans.sh`), rule 6 (canonical UTC + ASCII storage), rule 7 (normalize before any parse), rule 8 (FSI/PDI isolation for mixed runs, isolates never reaching storage or export), rule 9 (bundled fonts covering every shipped script, with fallback, no runtime fetch). `references/numerals-and-calendars.md` owns the `fa` (U+06Fx) vs `ar` (U+066x) block distinction and the `ckb`-has-no-`intl`-symbols trap; the anti-pattern "rendering RTL/numeral goldens with Ahem" is why every lane here calls `loadAppFonts`. |
| `accessibility-as-code` | Defines the floor every BLOCKER enforces: `Semantics(button/label)`, a11y flags read from `MediaQuery`, the ban on `withClampedTextScaling`/`textScaleFactor`/`FittedBox`/`ellipsis`, never-colour-alone, 4.5:1 / 3:1 against the composited background, 44px single-tap targets, `OrdinalSortKey`, and its honest limit: Flutter publishes no Switch Control support statement and no API simulates scanning, so a device pass is the only conformance evidence that exists. |
| `widget-golden-and-a11y-testing` | Owns the machine-checkable half: the `Device`/`useDevice`/`pumpApp` harness, one `testWidgets` per tuple (rule 6 — overflow reports once per `RenderObject`), the fit assertion `takeException` cannot make, the explicit `getSize` tap-target loop, `isSemantics`, pure-Dart WCAG/APCA contrast instead of the false-passing `textContrastGuideline`, and rule 11's two golden lanes — the real-font lane being the only thing that proves Arabic script joins. |
| `flutter-performance` | Owns the measurement discipline for T11.8: profile mode on real hardware, DevTools, UI **and** raster thread, and rule 11's bar — a frame-budget number must be measured, never asserted. |
| `ci-pipeline-and-gates` | Owns wiring `check-release-hygiene.sh`, the permission test, the localization tests and the banned-import test into `.github/workflows/ci.yml` as named contracts, the three-criteria bar for a grep gate (rule 7), the verify-never-bless rule (9), and rule 10's requirement that the workflow state what it cannot prove — which now has a new line about Persian. |
| `dependency-hygiene` | `scripts/audit-deps.sh` walking the resolved transitive tree is the evidence behind the privacy labels; it separates dev-only tooling (icon/splash generators, `integration_test`) from what reaches the binary; and its "green CI is not evidence of a native capability" rule is why the on-device pass exists at all. |
| `sunburst-shell-screens` | Names the surfaces, the pause sheet as a state of the play scaffold, rule 9's seven h1 strings and the single run-over announcement, rule 11's nothing-shrinks-to-fit, and rule 13's comparison order (structure → spacing rhythm → surface construction → type role → sampled hex). |
| `sunburst-game-surfaces` | The colour-blind axis: rule 4 — the flag is captured at round start and drives GENERATION, red→`cbPink`, green→`cbOrange`; rule 5 — `PlayFill` on key and glyph in both palettes; rule 7 — the ≥3-non-hue-channel rule the greyscale check tests; rule 9 — large text is absorbed by a smaller BASE style, never a clamp. |
| `sunburst-motion-and-haptics` | The eighteen moments, each with a reduce-motion residue, are the checklist for the motion recordings and the on-device Sound-off + Haptics-off + Reduce-motion-on pass. Rule 3's split (transform dropped, fill and shadow kept) is the subtle thing the sweep looks for; rule 6's latches are why a boundary haptic must be felt, not inferred; rule 7 puts `heavyImpact` on `personalBest` exactly once. |
| `sunburst-tokens` | Rule 11 (light theme only) is why the sweep matrix has **no** light/dark axis — say so rather than silently omitting it. Rule 4 fixes the hard shadow as an ink offset at zero blur, which is the value the RTL check proves does **not** mirror. `check_palette_contrast.sh` recomputes every `// @contrast` pair from the shipped hexes. |
| `sunburst-components` | T11.7's fix round is the only place this epic edits `lib/ui/components/`. Any fix there must keep `PopSurface` the one surface constructor, the press law (hit area still, transform moves), the ≥48px floor on the fill box and the hard-shadow-with-zero-blur rule — a "quick" a11y fix that hand-rolls a decoration undoes E05. Supplies `check_component_hygiene.sh`. |
| `app-startup-and-bootstrap` | The cold-start half of T11.8: rule 5 (settings — including the persisted locale — are read before `runApp` so frame one paints in the right language and direction), rule 8 (do not block the first frame), and why the native launch screen is the platform's window background and never a Dart route. |

## Tasks

### T11.1 — Verify the four-locale posture end to end and prove the Language row is live

**Goal.** Prove E04's ADR still describes the shipped tree across all four locales, and that the
Settings "Language" chevron leads to a real screen that actually switches the app — including to
`ckb`, which no iOS system language can select.

**Tests first (TDD).**
- `test/features/settings/language_row_test.dart`
  - `isSemantics(label: <l10n.settingsLanguage>, value: <the active locale's endonym>, isButton: true, hasEnabledState: true, isEnabled: true, hasTapAction: true)` on the row — a row exposed as static text fails here. Run under all four `LocaleCase.all`; the expected `value` is `English` / `Deutsch` / `فارسی` / `کوردیی ناوەندی`, i.e. each locale's **endonym**, never a translation of the language name into the active locale.
  - Tapping it opens E08 T08.9's `LanguageSheet` — a `PopSheet`, **not a route**. Assert on the
    presented sheet's contents and its dismissal, not on `find.byType(LanguageSheet)` and not through
    the router: E08 built a sheet because a four-item mutually-exclusive choice does not earn a
    navigation stack entry, and this task asserts what E08 shipped rather than a second destination.
  - The row's `onTap` is non-null (the explicit no-dead-control assertion). Same for the "About MindForge" row — `app.html` draws a chevron on both.
- `test/features/settings/language_sheet_test.dart` (**edit** — E08 T08.9's file, extended here, not
  re-authored)
  - The sheet renders exactly four options, in the order `en`, `de`, `fa`, `ckb`, each labelled by its endonym in its own script, in a mutually exclusive group.
  - The selected option carries a non-colour channel: a check glyph **and** `Semantics.value` reading the localized `Selected` (`accessibility-as-code` rule 6).
  - `getSize` on each option row is ≥ `kPopMinTarget` (48), under `TextScaler.linear(2.0)` as well as 1.0 — `کوردیی ناوەندی` is the longest label and the tallest line box.
  - Selecting `fa` closes the sheet and flips `Directionality.of(context)` to `TextDirection.rtl` for the whole app, and selecting `de` flips it back — asserted on the app root, not on a hardcoded `Directionality` anywhere (`i18n-rtl-l10n` rule 4).
- `test/features/settings/locale_persistence_test.dart` — set the locale to `ckb`, dispose the container, rebuild from the same in-memory `AppDatabase`, and assert the app comes up in `ckb`. This is the D1 promise ("the user can override in Settings and the choice persists") and it crosses E02 and E04, so it is asserted where both are present.
- `test/l10n/ckb_delegate_test.dart` — **the sharp one, and it is E04 T04.4's file extended here, not
  a new one.** Pump the app under `Locale('ckb')` and assert it does not throw; then assert the resolved `MaterialLocalizations` and `CupertinoLocalizations` are non-null and came from the nearest supported script neighbour (`fa`, else `ar`), while `AppLocalizations` came from `app_ckb.arb`. Assert against the **actual** delegate list at build time — read `GlobalMaterialLocalizations.delegate.isSupported(Locale('ckb'))` and record the result in the test's `reason:` rather than assuming it. E04 owns the delegate; this test is the release-time proof it survived three epics of screens.
- `test/policy/l10n_posture_test.dart` — **E04's file, extended here rather than re-authored.** It
  already pins the adopted posture (`l10n.yaml` present with `nullable-getter: false` and
  `arb-dir: lib/l10n`; `flutter: generate: true`; four ARBs present; the delegates and
  `supportedLocales` wired in `lib/app.dart`). This task adds the assertions that only make sense once
  the whole app exists:
  - **no user-facing literal survives outside the ARB** — walk `lib/features/**`, `lib/ui/**` and
    `lib/games/**`, strip comments, and fail on a `Text('…')`, `semanticLabel: '…'`, `label:`,
    `tooltip:` or `hint:` whose argument is a string literal rather than an `AppLocalizations`
    getter. Accumulate, fail once. This is the assertion that would have caught a screen quietly
    hardcoding a label in E08–E10.
  - **the four ARB locale sets are exactly `{en, de, fa, ckb}`** and equal `supportedLocales`, and
    equal the `CFBundleLocalizations` array in `ios/Runner/Info.plist` (T11.10 owns the plist side;
    the equality is asserted once, here, so a fifth ARB cannot land without the plist moving).
  - **`check_i18n_bans.sh lib` and `check_arb_parity.sh lib/l10n` are both CI steps.**
  - the reason string on every expectation cites E04's ADR, so re-opening the decision reds this test
    instead of drifting.

**Implementation.** Read E04's ADR and confirm it still describes the tree; if E08–E10 diverged from
it, that divergence is a finding for T11.4's table, not a quiet ADR rewrite. Then verify the Language
control is live — **E08 T08.9 owns the Settings screen, the `language_row.dart` control and the
`language_sheet.dart` destination**, and ships them working. **Check before building.** Expect to write
tests only. If E08 shipped the row as a dead chevron, fixing it is this task's implementation, in
E08's files:

- `lib/features/settings/presentation/language_sheet.dart` — four options, endonyms, the active one
  selected, writing through `localeProvider` and the settings repository's single write path.
- The row wired in `lib/features/settings/presentation/settings_screen.dart`.

**No `/settings/language` route and no `language_screen.dart`.** An earlier draft of this task asserted
a route; E08 ships a sheet, and two destinations for one control is the divergence this file exists to
catch.

**What this task does not do.** It does not re-decide the posture, does not add or remove a locale,
and does not touch translation *content* — that is T11.5. It also does not re-implement anything E04
owns; a bug in `LocaleNumbers` or the `ckb` delegate found here is fixed in its own file with a
regression test, not shadowed by a local workaround.

**Files.** `lib/features/settings/presentation/language_sheet.dart` and
`lib/features/settings/presentation/settings_screen.dart` (**edits, and only if E08 left the control
dead**), `lib/l10n/app_{en,de,fa,ckb}.arb` (any Language keys still missing, all four in one commit),
`test/features/settings/language_row_test.dart` (edit — E08 T08.9's),
`test/features/settings/language_sheet_test.dart` (edit — E08 T08.9's),
`test/features/settings/locale_persistence_test.dart` (new),
`test/l10n/ckb_delegate_test.dart` (edit — E04 T04.4's),
`test/policy/l10n_posture_test.dart` (edit — E04 T04.1's), `.github/workflows/ci.yml`.

**Skills.** `i18n-rtl-l10n`, `sunburst-shell-screens`, `accessibility-as-code`,
`widget-golden-and-a11y-testing`, `ci-pipeline-and-gates`.

**Screenshot check.** `design/sunburst-pop/screens/08-settings.png` and
`design/sunburst-pop/screens/rtl/08-settings.png` — the Language row must keep the mock's `.srow`
construction in both directions: glyph, label, `.sv` value in `textSecondary`, chevron in `ink-3`,
and the group's card gap of 16. In RTL the glyph, label and value order mirrors and the chevron
points the other way (`Icons.adaptive`), while the row's hard shadow still falls down-and-right. The
Language sheet itself has **no** reference PNG in either direction; it composes existing `PopSurface`
rows only, so any new visual vocabulary there is out of scope and belongs in `app.html` first.

**Done when.**
- [ ] E04's ADR still describes the shipped tree; any divergence is a graded finding in T11.4, not an ADR edit.
- [ ] All six test files above are green; `l10n_posture_test.dart` fails if a user-facing literal appears outside the ARB.
- [ ] `ckb_delegate_test.dart` records the measured `GlobalMaterialLocalizations` support answer in its `reason:` string rather than assuming it.
- [ ] The Language row and the About row both navigate; **no chevron or card in the app leads nowhere** — the same rule that gave the Daily Mix card its destination in E08.
- [ ] `check_i18n_bans.sh lib` and `check_arb_parity.sh lib/l10n` both run in CI and are clean.

**Commits.**
1. `Add failing tests for a live Settings Language row in four locales`
2. `Add the ckb delegate and locale-persistence regression tests`
3. `Fix the Settings Language row and sheet if E08 left either dead`
4. `Extend the l10n posture test to ban user-facing literals outside the ARB`

---

### T11.2 — Complete the app-wide accessibility floor test matrix, across locales

**Goal.** Get every machine-checkable part of the a11y floor asserted across all eleven surfaces in
all four locales before a human looks at a single pixel, so the review pass spends its time on what
only a human can see.

**Tests first (TDD).** This task is nothing but tests.
- `test/support/sweep_surfaces.dart` — a `SweepSurface` enum with the eleven cases (`home`,
  `gameDetail`, `countdown`, `stroopRush`, `schulteGrid`, `pauseSheet`, `results`, `stats`,
  `settings`, `language`, `about`) and
  `pumpSurface(SweepSurface, {Locale locale, TextScaler textScaler, bool boldText, bool colourBlind})`
  built on E04's locale-aware `pumpApp` and E05's `useDevice`. One enum, consumed by this task and by
  T11.3 — two lists of screens drift, and a screen missing from one list is a screen nobody swept.
- `test/a11y/overflow_matrix_test.dart` — `setUpAll(loadAppFonts)` loading the Latin **and**
  Arabic-script faces, then one `testWidgets` per tuple. Never a loop inside a test — overflow reports
  once per `RenderObject`. The matrix, stated as two lanes so the cost is visible:
  - **scale lane:** `Device.all` × `[1.0, 1.3, 1.5, 2.0, 3.0]` × `LocaleCase.all` per surface.
  - **bold lane:** `Device.all` × `LocaleCase.all` at scale 2.0 with `boldText: true` per surface. Bold
    is a weight change whose worst case is the largest scale, so it is not crossed with the whole
    scale axis; that trade is stated in the file header, not left implicit.

  Each case asserts `tester.takeException()` is null **and** a `getRect` fit assertion: the three
  `HudSlot` values sit inside their pills, `scoreHero` sits inside the results pane, and each Settings
  row label sits inside its row. `de` is the length stress case (~30% longer); `fa` and `ckb` are the
  line-box-height stress case — Arabic-script ascenders and descenders are taller, so a row that fits
  `de` at 2.0 is not evidence for `ckb` at 2.0. Where a genuine ceiling exists, record the number and
  hand it to T11.4 as a finding; **do not clamp, do not `FittedBox`, do not ellipsize a value** — a
  label that stops fitting takes a smaller BASE style (`sunburst-game-surfaces` rule 9).
- `test/a11y/tap_targets_test.dart` — an explicit `getSize` loop over every interactive node on each
  surface in each locale, each ≥ `kPopMinTarget` 48. Not `meetsGuideline` — it skips nodes flush with
  the view edge, which is exactly where `PopBottomNav` lives. Run per locale because a mirrored row
  can push a target under a safe-area inset that only exists on one side.
- `test/a11y/semantics_test.dart` — exactly one `Semantics(header: true)` per surface with the h1
  strings `sunburst-shell-screens` rule 9 fixes (the play scaffold has none), read from
  `AppLocalizations` per locale rather than compared against English literals; `isSemantics(...)` on
  every nav tab, toggle, answer key and button; traversal from `simulatedAccessibilityTraversal`
  equals authored `OrdinalSortKey` order, not layout order, **and is identical under LTR and RTL** —
  traversal is authored from priority, so mirroring the layout must not reorder it; the HUD is **not**
  a `liveRegion`; the run-over announcement fires exactly once and is the localized sentence.
- `test/a11y/numerals_test.dart` — **new, and the one that catches the most likely silent defect.**
  Walk the rendered text of every surface and assert:
  - under `en`/`de`, no rune in U+0660–U+0669 (Arabic-Indic) or U+06F0–U+06F9 (Extended Arabic-Indic)
    appears anywhere;
  - under `fa`/`ckb`, no ASCII digit `[0-9]` appears outside a run wrapped by `Bidi.isolateLtr` — scores,
    durations, streaks, the countdown, the Stats numbers and **the Schulte tiles** all read
    ۰۱۲۳۴۵۶۷۸۹;
  - `fa` and `ckb` use the **same** block (U+06Fx), never the `ar` block (U+066x) — they are distinct
    Unicode ranges and mixing them is the anti-pattern `i18n-rtl-l10n` names;
  - German grouping separators are `de`'s own, not `en`'s: `1.480`, not `1,480`;
  - every formatted string round-trips through `AsciiNumerals.normalize` back to the ASCII value the
    generator produced.
- `test/a11y/rtl_geometry_test.dart` — **new.** For each surface, pump under `en` and under `fa` and
  assert: the horizontal order of a keyed probe row is exactly reversed; `TextAlign.start` resolved to
  `right` under RTL; **the hard offset shadow is identical in both directions** — read the resolved
  `BoxShadow.offset` off a `PopSurface` in each direction and assert equality, because the shadow is a
  light-source constant, not a reading-direction property, and this is the single thing a reviewer will
  query. Also assert no widget in the tree sets a literal `TextDirection` (a hardcoded root
  `Directionality` hides every physical-side bug — `i18n-rtl-l10n` rule 4).
- `test/theme/contrast_test.dart` — pure-Dart WCAG + APCA over every `// @contrast` pair declared on
  `SunburstColors`, plus the chroma-only board-state pairs (`gameSchulte` vs `gameSchulteDeep`,
  `accent` vs `surfaceRaised`) asserted directly. Locale-independent by construction; say so in the
  file header so nobody adds a pointless locale axis to it.
- `test/a11y/board_state_channels_test.dart` — for every Schulte tile state and every Stroop answer
  key state, assert ≥3 differing non-hue channels by comparing the resolved state descriptor's
  `PopElevation`, translate, ring, border slot and glyph fields. A value comparison, not a pixel one —
  a greyscale golden cannot fail loudly.
- `test/policy/a11y_bans_test.dart` — comment-stripped, structure-anchored grep over `lib/` for
  `withClampedTextScaling`, `textScaleFactor`, `FittedBox`, `TextOverflow.ellipsis`, and
  `copyWith(fontSize:`. Accumulate every offender, fail once, with a reason a stranger understands.

**Implementation.** Only what the tests need: `test/support/sweep_surfaces.dart`, and any missing
`Semantics`/`sortKey`/target-size/numeral-format fix the new tests turn red. A fix that reaches for a
clamp, a `FittedBox` or an ellipsis is the defect, not the fix — change the layout or the base style.
A numeral fix belongs in the one `LocaleNumbers` E04 owns, never in a widget.

**Files.** `test/support/sweep_surfaces.dart`, `test/a11y/overflow_matrix_test.dart`,
`test/a11y/tap_targets_test.dart`, `test/a11y/semantics_test.dart`, `test/a11y/numerals_test.dart`,
`test/a11y/rtl_geometry_test.dart`, `test/theme/contrast_test.dart`,
`test/a11y/board_state_channels_test.dart`, `test/policy/a11y_bans_test.dart`, plus whichever files
under `lib/features/**`, `lib/ui/**`, `lib/games/**` and `lib/l10n/` the failures name.

**Skills.** `widget-golden-and-a11y-testing`, `accessibility-as-code`, `i18n-rtl-l10n`,
`sunburst-game-surfaces`, `sunburst-shell-screens`, `sunburst-tokens`.

**Screenshot check.** n/a (no visual surface — this task adds tests and a11y fixes only; any layout
change it forces is re-compared in T11.3's sweep against both the LTR and RTL references).

**Done when.**
- [ ] `flutter test --test-randomize-ordering-seed random` green with all nine files present.
- [ ] The matrix's total case count and wall-clock run time are recorded in the PR body. If it is the slowest file in the suite, say so rather than trimming the locale axis.
- [ ] `.claude/skills/widget-golden-and-a11y-testing/scripts/check-test-hygiene.sh` clean — no `takeException()` in a `tearDown`, no `ignoreOverflowErrors`, no assigned `FlutterError.onError` in `test/`.
- [ ] `check_palette_contrast.sh lib/theme/sunburst_colors.dart` clean.
- [ ] Any per-locale text-scale ceiling found is written down as a number and handed to T11.4 as a finding — never absorbed by a clamp.
- [ ] The honest-limits paragraph is added to `.github/workflows/ci.yml` as a comment block: CI cannot prove real-font rendering on device, haptics, audio, screen-reader behaviour, frame timing — **or that a translation is correct, idiomatic, or even in the right language. No pipeline reads Persian or Sorani.**

**Commits.**
1. `Add SweepSurface enum and locale-aware pumpSurface for the eleven review surfaces`
2. `Add the app-wide overflow, fit and text-scale matrix across four locales`
3. `Add explicit tap-target, semantics and traversal assertions per locale`
4. `Add the numeral-system and RTL-geometry assertions`
5. `Add pure-Dart contrast and board-state channel assertions`
6. `Add the a11y banned-construct policy test`
7. `Fix the a11y floor violations the matrix exposed`
8. `State in ci.yml what CI cannot prove, including that it cannot read Persian`

---

### T11.3 — Build the deterministic review-sweep capture harness

**Goal.** One command produces the whole stills matrix into `design/review/<date>/`, reproducibly,
with a machine-checkable inventory — so the review compares evidence rather than someone's memory of
tapping around in a language they do not read.

**The matrix, stated in full.** Nothing here is sampled; the count is the count.

```
surfaces  11   home gameDetail countdown stroopRush schulteGrid pauseSheet
               results stats settings language about
locales    4   en de fa ckb
textScale  2   one = 1.0            max = 2.0 + boldText
palette    2   cvd off              cvd on
                                            = 11 x 4 x 2 x 2 = 176 stills
```

Two axes are deliberately absent and each says why, in the matrix test's `reason:` string:

- **No light/dark axis.** `sunburst-tokens` rule 11: there is one `ThemeData` and adding a dark one is
  a new design direction, not a token flip. An axis omitted with no recorded reason is how a sweep
  quietly stops covering something.
- **No reduce-motion still axis.** Motion decorates state and never *is* the state, so every settled
  end state is identical with animations off — that property is itself asserted (T11.2's board-state
  channels, `sunburst-motion-and-haptics`' residue column). With the axis, the matrix would be 352
  stills of which 176 are duplicates. Reduce-motion is carried by video instead, where the difference
  actually lives.

**Human review is scoped by mechanical discharge, not by sampling.** All 176 are captured; the eye is
spent as follows, and the sign-off records this partition verbatim:

| Group | Cells | How it is judged |
|---|---|---|
| Reference cells — the 8 screens with a PNG, `en` and `fa`, scale one, cvd off | 16 | Pixel comparison against `screens/NN.png` and `screens/rtl/NN.png`, in the five-step order |
| Structural-parity cells — the same 8 screens in `de` and `ckb`, plus all 4 locales of `pauseSheet`/`language`/`about`, scale one, cvd off | 28 | Judged against the same-direction reference (`de`→`en` PNG, `ckb`→`fa` PNG) for structure and rhythm only; longer strings are expected, structural drift is a defect. The three no-reference surfaces are judged against `system.html` §10 and the components |
| Text-scale cells — everything at scale max | 88 | Fit is already asserted by T11.2; the eye looks for rhythm collapse, a line box colliding with a border, and a value that wrapped where it should have taken a smaller base style |
| Colour-blind cells — everything at cvd on | 44 | 32 of these (the 8 chrome-only surfaces × 4 locales × 2 scales) are asserted **pixel-identical** to their cvd-off twin by `verify_review_folder.dart` and need no human look; the 12 remaining belong to `stroopRush`, `schulteGrid` and `settings`, where the palette legitimately changes |

Human-viewed: 112. Mechanically discharged: 64. Overlap is none — the four groups partition the 176.

**Tests first (TDD).**
- `test/policy/review_matrix_test.dart` — pure, no device needed. Asserts `reviewMatrix` in
  `tool/review_matrix.dart` has exactly **176** `ReviewCell(surface, locale, scale, colourBlind)`
  entries; every `cell.fileName` is unique and matches
  `^\d\d-[a-z-]+--(en|de|fa|ckb)--scale(one|max)--cvd(off|on)\.png$`; the surface list equals
  `SweepSurface.values` from T11.2 (one list, two consumers); the locale list equals `LocaleCase.all`
  from E04 (one list, every consumer); and **the eight surfaces that have a reference PNG carry that
  PNG's numeric prefix** — `01-home` … `08-settings`. `pauseSheet` is a state of the play scaffold,
  not a screen `capture-screens.sh` renders, and `language`/`about` are destinations the mock only
  draws chevrons to, so they take the reserved prefixes `09-pause-sheet`, `10-language`, `11-about`
  and the reference assertion is scoped to the eight, with the `reason:` string recording why the
  other three are exempt. Asserting all eleven against `screens/` would be unsatisfiable.
- The same file asserts the matrix declares **no** theme axis and **no** reduce-motion still axis,
  each with its reason in the `reason:` string, and asserts the four-group partition above sums to
  the cell count — so a surface added without a review plan reds the test.

**Implementation.**
- `tool/review_matrix.dart` — the `ReviewCell` value type, the `reviewMatrix` const list, and the
  `ReviewGroup` enum that carries the partition above.
- `integration_test/review_sweep_test.dart` — walks `reviewMatrix`, pumps each cell via `pumpSurface`
  under an `IntegrationTestWidgetsFlutterBinding`, and writes each still with
  `binding.takeScreenshot(cell.fileName)`. Scale `max` is `TextScaler.linear(2.0)` plus
  `boldText: true`; `colourBlind` and the locale are seeded into the in-memory `AppDatabase` **before**
  the surface is pumped, so the palette is captured at round start exactly as `sunburst-game-surfaces`
  rule 4 requires and the locale is resolved before the first frame exactly as
  `app-startup-and-bootstrap` rule 5 requires — neither is toggled at paint time.
- Alongside each PNG the harness writes a sidecar `cell.json`: the locale, the resolved
  `TextDirection`, the text scaler, the palette flag, and the `Rect` of one keyed probe element per
  surface. The sidecars are what make the locale assertions below checkable without image recognition.
- `test_driver/review_sweep.dart` — writes the returned bytes and sidecars to `design/review/<date>/`.
- Run:
  ```bash
  xcrun simctl boot C13DDC02-375D-4E1B-8F81-44EB407D09A4
  flutter drive --driver=test_driver/review_sweep.dart \
    --target=integration_test/review_sweep_test.dart \
    -d C13DDC02-375D-4E1B-8F81-44EB407D09A4 --profile
  ```
  **Only** on that UDID. It is exactly 390×844, which is what every reference PNG was rendered at; a
  capture on an iPhone 16 (393×852) or 16 Pro (402×874) invalidates all 176 and the comparison stops
  being honest.
- `tool/verify_review_folder.dart <dir>` — asserts:
  1. All 176 files exist, are non-empty, and are 390×844 at the device's DPR.
  2. **Colour-blind identity.** The eight surfaces where the gameplay palette never appears (`home`,
     `gameDetail`, `countdown`, `pauseSheet`, `results`, `stats`, `language`, `about`) render
     identically with the palette off and on, in every locale and at both scales. A difference means a
     `play*`/`cb*` slot leaked into chrome — `sunburst-tokens` rule 5 — and is a BLOCKER. `settings`
     is excluded on purpose: `app.html`'s `.cbprev` swatch row is a live preview of the palette and
     legitimately changes.
     **Compare decoded pixels, not bytes.** The stills come from separate `flutter drive` passes over
     surfaces that animate (halftone layers, press chrome, the countdown ring), so byte-identity is
     not a property the capture method has — PNG encoding alone can differ. Decode both images and
     assert a **maximum per-pixel channel delta of 0**, with the sweep run under
     `disableAnimations: true` and each surface pumped to a settled frame before capture. That is the
     same guarantee stated in terms the method can deliver; a byte comparison would fail for reasons
     that are not tier violations and get relaxed away.
  3. **Locale non-identity.** For every (surface, scale, cvd), the `de`, `fa` and `ckb` stills are each
     **not** pixel-identical to the `en` still. A sweep that ran but never switched locale produces 176
     English screens and passes every other check; this is the assertion that catches it.
  4. **Direction from the sidecar.** Every `en`/`de` cell records `TextDirection.ltr` and every
     `fa`/`ckb` cell records `rtl`; and the probe `Rect` of each RTL cell is the horizontal mirror of
     its LTR twin's, within 1px. This is the cheap mechanical half of "the chrome mirrored"; the rest
     is the eye's job.
- `docs/review/sweep-procedure.md` — the exact command, the UDID, the four-group partition, and the
  three honest limits below.

**Three limits to write down, not paper over.** (a) `flutter drive` needs a VM service, so the stills
are captured in **profile** mode, not release. Profile and release render identically and profile has
no debug banner, but obfuscation and stripped asserts only exist in release — so the release build is
verified in T11.6 and T11.11 instead, on device, and the sign-off says so. (b) Motion, press physics
and haptics are not stills; they are recordings, judged by eye —
`design/sunburst-pop/screens/README.md` already states screenshots are end states only. (c) Before
building the harness, confirm `IntegrationTestWidgetsFlutterBinding.takeScreenshot` works on the iOS
simulator on the pinned Flutter version. If it does not, the sanctioned fallback is
`xcrun simctl io C13DDC02-375D-4E1B-8F81-44EB407D09A4 screenshot` driven by the same
`reviewMatrix` — `design-review-workflow` names simulator capture as a legitimate mechanism — with the
app driven by `integration_test` and the sidecars written by the test. Verify first; do not discover
it after writing the driver.

**Files.** `tool/review_matrix.dart`, `tool/verify_review_folder.dart`,
`integration_test/review_sweep_test.dart`, `test_driver/review_sweep.dart`,
`test/policy/review_matrix_test.dart`, `docs/review/sweep-procedure.md`, `pubspec.yaml`
(`integration_test` from the Flutter SDK as a `dev_dependency`).

**Skills.** `design-review-workflow`, `widget-golden-and-a11y-testing`, `i18n-rtl-l10n`,
`sunburst-game-surfaces`, `sunburst-tokens`, `dependency-hygiene`.

**Screenshot check.** This task *produces* the shots; the comparison happens in T11.4. Verify here
only that two spot-check cells — `01-home--en--scaleone--cvdoff.png` and
`01-home--fa--scaleone--cvdoff.png` — are 390×844 at the device DPR and sit beside
`design/sunburst-pop/screens/01-home.png` and `design/sunburst-pop/screens/rtl/01-home.png` at the
same size. A capture at the wrong logical size invalidates all 176.

**Done when.**
- [ ] `flutter test test/policy/review_matrix_test.dart` green; the 176 count and the four-group partition are asserted, not narrated.
- [ ] The drive command produces 176 PNGs + 176 sidecars on the canonical UDID; `dart run tool/verify_review_folder.dart design/review/<date>` exits 0 with all four assertion classes.
- [ ] The capture wall-clock time is recorded in `sweep-procedure.md`.
- [ ] `audit-deps.sh` confirms `integration_test` is dev-only and reaches no shipped binary.
- [ ] `docs/review/sweep-procedure.md` names the UDID, the command, the partition and all three limits.
- [ ] **A `flutter clean` reminder is written into `sweep-procedure.md`'s last line**, because a screenshot run leaves the tree built for the simulator and the next `flutter build ipa` would embed a simulator slice (T11.11).

**Commits.**
1. `Add the review matrix value type and its 176-cell inventory test`
2. `Add the integration_test sweep harness, driver and per-cell sidecars`
3. `Add tool/verify_review_folder.dart with the cvd, locale and direction assertions`
4. `Document the sweep procedure, its partition and its three limits`

---

### T11.4 — Run the sweep and grade every finding, LTR and RTL

**Goal.** Produce the deduped, graded findings table that the fix round and the sign-off both read
from.

**Tests first (TDD).** Not possible for this task, and saying so is the point: grading is human
judgement over rendered pixels, and no assertion can express "the spacing rhythm is wrong here" or
"this line box collides with the border". The machine-checkable half already ran — T11.2's suite and
every gate script are a **precondition** for starting this task, per `design-review-workflow` rule 2,
never part of its rubric. Do not re-litigate lint, determinism, ARB parity or layer gates in the
findings table.

**Implementation.**
1. Confirm the trigger: E10 merged, CI green on the sweep commit, all gate scripts clean.
2. Capture the 176 stills (T11.3) and the motion recordings: one per moment group, each with
   reduce-motion **off** and **on** — press (`buttonPress`/`buttonCommit`), countdown
   (`countdownBeat`/`runStart`), answers
   (`answerCorrect`/`answerWrong`/`tileFound`/`tileNextCue`), boundaries
   (`streakMilestone`/`timerAlarm`/`runEnd`), results (`resultsReveal`/`personalBest`), chrome
   (`toggleFlip`/`sheetTransition`/`routeTransition`/`difficultySelect`/`homeCardEnter`) — twelve in
   `en`, plus the answers and chrome groups re-recorded in `fa` (four more) because route and sheet
   transitions follow the resolved direction and the answer keys are mirrored. **16 recordings.**
3. Compare the 16 reference cells against their PNGs in this order: **structure** → **spacing rhythm**
   → **surface construction** (3px ink border, correct hard-shadow step, `blurRadius`/`spreadRadius`
   0) → **type role** → **sampled hex**. Then the 28 structural-parity cells against the
   same-direction reference for structure and rhythm only. The pause sheet has no reference — judge
   it against `system.html` §10's two-action specification and the `PopSheet` component; Language and
   About against the components they compose.
4. Apply the four lenses per surface — floor compliance, identity fidelity, parity-or-better, motion
   moments — and grade every finding BLOCKER / FIX / NOTE. **Every accessibility-floor violation is a
   BLOCKER regardless of how good the screen looks.** Check the reduce-motion recordings against the
   residue column of `sunburst-motion-and-haptics`' catalog: a moment whose residue is "nothing" is a
   BLOCKER; the press keeping its `(1,1)` shadow and deep fill while dropping its transform is the
   specific thing to look for.
5. **Run the RTL checklist over every `fa` and `ckb` cell**, and record its result as a named section
   of the review doc rather than folding it into general impressions:
   - **No tofu and no broken joins.** Every glyph renders; Arabic-script letters *join* — a face
     without proper shaping produces disconnected letterforms that are technically legible and
     obviously wrong. Check the Sorani-specific letters ڕ ڵ ۆ ێ ھ specifically, on the display face as
     well as the body face; E04 chose that face and this is where the choice is verified in situ.
   - **No clipped or reversed glyphs.** A descender cut by a border, a comma that rendered as its
     LTR mirror, a parenthesis pointing the wrong way.
   - **No Latin run reordering.** The "MindForge" wordmark inside Persian copy, `18.6s`, a game id, a
     version string: each must sit where it was written. A run that jumps to the other end of the
     paragraph means it skipped the FSI/PDI helper (D6).
   - **Correct numeral system everywhere**, including inside the Schulte board — tiles read ۱–۲۵ and
     the "Next" cue matches. T11.2 asserts this in the widget tree; the sweep is where a numeral
     baked into a painter or an asset shows up.
   - **Mirrored affordances.** Chevrons, back arrows, progress fill direction, the segmented control,
     the nav row order, the HUD pill order.
   - **Unmirrored shadows.** Every hard offset shadow still falls down-and-right. It is a light-source
     constant, not a reading-direction property. A mirrored shadow is a FIX; an *inconsistently*
     mirrored one — some surfaces flipped, some not — is a BLOCKER, because it means the offset is
     being derived per widget instead of from `SunburstShape.shadow()`.
6. Consolidate into one deduped table in `docs/review/design-review-<date>.md`: id, surface, cell
   (surface + locale + scale + cvd), grade, what is wrong, expected source (`system.html` §,
   `app.html` line, or reference PNG). A finding that reproduces in three locales is one row naming
   three cells, not three rows.

**Files.** `docs/review/design-review-<date>.md`, `design/review/<date>/` (176 stills + 176 sidecars
+ 16 recordings).

**Skills.** `design-review-workflow`, `accessibility-as-code`, `i18n-rtl-l10n`,
`sunburst-shell-screens`, `sunburst-game-surfaces`, `sunburst-motion-and-haptics`, `sunburst-tokens`.

**Screenshot check.** All sixteen references: `01-home.png` … `08-settings.png` under
`design/sunburst-pop/screens/` for the `en` cells, and the same eight names under
`design/sunburst-pop/screens/rtl/` for the `fa` cells. A difference is an implementation defect. If a
reference is genuinely wrong, edit `design/sunburst-pop/app.html`, re-run
`design/sunburst-pop/capture-screens.sh` (which regenerates **both** directions), and commit the
regenerated PNGs as a deliberate design change in its own commit — never let code and reference drift
silently.

**Done when.**
- [ ] All 176 stills, 176 sidecars and 16 recordings exist under `design/review/<date>/`.
- [ ] Each of the eight screens has a written comparison result against its LTR **and** its RTL PNG, in the five-step order.
- [ ] The RTL checklist is a named section with a per-item result, not a sentence saying "RTL looks fine".
- [ ] Every finding has an id, a grade, a source and the cells it reproduces in; no finding is ungraded.
- [ ] Every floor violation is graded BLOCKER; no aesthetic argument downgrades one.
- [ ] Any reference change is a separate commit containing both the `app.html` edit and the regenerated LTR **and** RTL PNGs.

**Commits.**
1. `Capture the 176-cell review sweep and the 16 motion recordings`
2. `Add the graded findings table for the <date> design review`
3. `Record the RTL checklist result for the fa and ckb cells`
4. *(only if a reference is genuinely wrong)* `Correct app.html <screen> and regenerate both reference sets`

---

### T11.5 — Native-speaker review of the Persian and Sorani copy

**Goal.** Get every `fa` and `ckb` string read by someone who speaks it, before release. This is a
BLOCKER-grade sign-off item, not a polish note: shipping machine-quality translation in a UI is a
defect.

**Start this task on day one of the epic.** Its latency is a person's calendar, not a build. It
blocks T11.11 and nothing about it goes faster by being started late — the same reason
`release-and-store-shipping` rule 14 says to raise the account-holder gates on day one.

**Tests first (TDD).** The review itself is human; what is testable is that its output landed.
- `test/policy/l10n_review_test.dart`
  - **No shipped ARB entry still carries the `native-speaker-pending` marker.** E09 and E10 committed
    their `fa`/`ckb` drafts with that marker in each key's `@`-metadata so the layout could be built
    against real string lengths. The marker is the debt; this test is the collection notice. It fails
    while any remains, which is the behaviour we want.
  - `docs/review/l10n-review-<date>.md` exists and contains, per RTL locale: a reviewer name, their
    relationship to the language (native / fluent), the date, the app version reviewed, and a verdict
    line matching `^VERDICT: (APPROVED|CHANGES REQUESTED — .+)$`.
  - The key set reviewed equals the key set in `app_en.arb` — a review that covered 80% of the keys is
    a review of a different app.
- `test/policy/privacy_claims_test.dart` (T11.10's file) gains a row asserted here: the claim-strength
  check for `fa`/`ckb` is an explicit line item in the review form, because the banned-absolutes grep
  can only be authored in languages the team reads.

**Implementation.**
1. Generate the review artifact from the ARBs rather than hand-writing it:
   `dart run tool/export_l10n_review.dart --locale fa --locale ckb > docs/review/l10n-review-<date>.md`.
   Each row carries the key, the `en` source, the `@description` written for translators, the current
   `fa`/`ckb` string, the screen it appears on, and the **character budget** measured from T11.2's fit
   assertions — a reviewer who does not know the label has 14 characters will hand back a correct
   phrase that overflows.
2. Ask for four specific things, not "does this read well":
   - **Register.** MindForge speaks plainly and warmly. Persian and Sorani both have a formal register
     that reads as bureaucratic in a game.
   - **Terminology.** The colour vocabulary above all — Stroop Rush *is* colour words. A word that
     names a shade rather than a colour breaks the game. Also: "streak", "best", "run", "grid",
     "difficulty".
   - **Numerals and plurals.** Confirm Eastern Arabic numerals read naturally in context, that the
     grouping and decimal separators are the ones a reader expects, and that every ICU plural branch
     is grammatical — Persian and Sorani plural behaviour is not English's, and the branch bodies are
     the translator's contract.
   - **Claim strength.** Confirm no privacy sentence is *stronger* in translation than in English.
     "The app has no network access" must not have become "nothing ever leaves your device"
     (`release-and-store-shipping` rule 9).
3. Apply the changes as ARB edits, one commit per locale, with `check_arb_parity.sh` green after each
   — a reviewer's rewrite that drops a placeholder breaks that string at runtime, silently.
4. Remove the `native-speaker-pending` markers **only** for keys the reviewer actually saw.
5. Re-run T11.2's overflow matrix afterwards. A corrected translation is usually longer, and the fit
   assertions are the only thing standing between a good translation and a clipped one.

**If no native speaker can be found**, there are exactly two honest outcomes, and picking neither is
not one of them:
- `VERDICT: NOT SIGNED OFF — fa/ckb copy unreviewed`, and the release waits; or
- ship `en` and `de` only for v1: remove `fa` and `ckb` from `supportedLocales`,
  `CFBundleLocalizations` and the ARB set, keep every line of RTL machinery E04 built (it costs
  nothing to keep and everything to re-derive), and record the removal in the release notes with the
  re-entry condition. This is a decision for Zakaria, not for whoever is running the epic that day.

**Files.** `docs/review/l10n-review-<date>.md`, `tool/export_l10n_review.dart`,
`test/policy/l10n_review_test.dart`, `lib/l10n/app_fa.arb`, `lib/l10n/app_ckb.arb`.

**Skills.** `i18n-rtl-l10n`, `design-review-workflow`, `ci-pipeline-and-gates`,
`release-and-store-shipping`.

**Screenshot check.** n/a (no visual surface) — with one exception: any string the reviewer lengthens
by more than its measured budget forces a re-shoot of the cells that show it in T11.7's fix round,
against both the LTR and RTL references.

**Done when.**
- [ ] `docs/review/l10n-review-<date>.md` names a reviewer per RTL locale with a date and a verdict line.
- [ ] Zero `native-speaker-pending` markers remain in `app_fa.arb` and `app_ckb.arb`; `test/policy/l10n_review_test.dart` green.
- [ ] `check_arb_parity.sh lib/l10n` green after every reviewer-driven edit.
- [ ] T11.2's overflow matrix re-run and green against the corrected strings.
- [ ] The claim-strength question was asked explicitly and its answer recorded.
- [ ] If no reviewer was available, one of the two honest outcomes above is recorded as a decision with a name and a date — not left implicit.

**Commits.**
1. `Add the ARB review export tool and its completeness test`
2. `Record the <date> native-speaker review of fa and ckb`
3. `Apply the Persian reviewer's corrections`
4. `Apply the Sorani reviewer's corrections`
5. `Clear the native-speaker-pending markers from the reviewed ARBs`

---

### T11.6 — On-device pass on real iPhone hardware

**Goal.** Prove the things a simulator cannot: real fonts, haptics, VoiceOver traversal in four
languages, system font + bold + display zoom, and the data-durability behaviours — on real
target-class hardware in its real state, with the destructive steps last.

**Tests first (TDD).** The pass itself is manual — no test can drive VoiceOver or feel a haptic. What
*is* testable is the artifact's completeness, and that is written first:
- `test/policy/on_device_checklist_test.dart` — asserts `docs/review/on-device-checklist.md` contains
  every required section heading (device header, reader traversal **per locale**, Switch Control,
  text scale + bold + display zoom, feedback-channels matrix, colour-blind runs, the four-locale walk,
  fresh-install persistence, crash-log line of sight), and that the executed copy at
  `design/review/<date>/on-device.md` has a filled device/iOS/date/build header and **zero** unticked
  `- [ ]` boxes. It fails while the pass is incomplete, which is the behaviour we want. There is **no
  export/import section**: v1 ships no export path (see below), and a checklist heading for a feature
  that does not exist is a box someone ticks without doing anything.

**Implementation.** Run on the release build where possible — install the exact IPA on a real iPhone
via Xcode's Devices window or a TestFlight internal build; note in the header which build mode each
section ran in. Non-destructive first:

1. **What the simulator cannot do, stated before the pass so nobody substitutes it.** The iOS
   Simulator has **no haptics at all** — the Taptic Engine does not exist there, so `HapticGateway` is
   silent and section 4 below is meaningless on it. It also renders with the Mac's fonts, memory and
   thermal envelope. Xcode's **Accessibility Inspector** (Xcode → Open Developer Tool) can drive and
   audit the simulator's accessibility tree and is a genuine tool for section 2's first pass — but it
   is not VoiceOver, and the sign-off must not present it as one.
2. **VoiceOver traversal** over Home → Game detail → Countdown → both boards → Pause → Results →
   Stats → Settings → Language → About. Every interactive element reachable and correctly labelled;
   no focus trap; the run-over announcement speaks the whole outcome sentence once; the HUD does not
   re-read every tick. **Run it in `en`, then in `fa`.** Then attempt it in `ckb` and record what
   happens: iOS ships a Persian voice; it is unlikely to ship a Sorani one, so VoiceOver will read
   `ckb` text with a fallback voice or spell it out. That is a platform limit, not a defect we can
   fix — record it in the sign-off as a known limit with the exact behaviour observed, and confirm
   the *semantics* are still correct (labels, roles, order) even where the pronunciation is not.
3. **The `ckb` reachability fact.** `ckb` is not an iOS system language, so the device language
   picker cannot select it. The **in-app Language sheet is the only path**, which makes it the
   shipping path for a whole locale and not a convenience — `design-review-workflow` names skipping
   RTL for want of a device locale as an anti-pattern. Walk the app in `ckb` end to end from the
   in-app picker, including a cold restart to prove the override survives.
4. **Switch Control** — the same walk. `accessibility-as-code` is explicit that Flutter publishes no
   support statement and no API simulates scanning, so a device pass is the only evidence that exists.
5. **Largest system font + bold text + display zoom** on the smallest supported iPhone — nothing
   clipped, the HUD reflows 3-across → 2+1 above scale 1.3, Results and Stats scroll. Run it in `de`
   (longest strings) and `ckb` (tallest line boxes); those are the two worst cases and they are worst
   for different reasons.
6. **The feedback-channel matrix** — all eight combinations of Sound / Haptics / Reduce motion.
   `sunburst-motion-and-haptics` rule 8 says all-three-off is a supported configuration: walk one full
   Stroop run and one full Schulte run in it and confirm every moment still lands. Confirm
   `heavyImpact` fires exactly once, on `personalBest`, and that no boundary haptic (`timerAlarm`,
   `streakMilestone`) buzzes continuously — the unlatched-boundary bug is invisible on a simulator and
   unmistakable in the hand.
7. **Colour-blind palette on** — a full run of each game, confirming the answer set is generated from
   the four-colour live set and no two live keys share a `PlayFill`.
8. **Real-font check in the shipped binary.** Read a Persian and a Sorani screen on the device and
   confirm no tofu, correct joining, and that the Sorani-specific letters ڕ ڵ ۆ ێ ھ render on both
   the body and display faces. The simulator uses the same bundled assets, but this is the pass where
   a font that failed to bundle shows up as boxes.

Destructive, last:

9. **Fresh install → create data → force-quit → relaunch → data intact**, then delete the app and
   confirm a clean first run resolving to the system locale (or `en` where the system locale is
   unsupported — D1). There is **no previous release** to upgrade from, so the upgrade-over-previous-
   version rehearsal has nothing to rehearse; record that plainly in the header and note that the real
   migration rehearsal is a v1.1 precondition (E02 built the harness for it).
10. **Crash-log line of sight** — trigger a known crash on the obfuscated build, capture the trace
    from the device log (Console.app or Xcode's Devices → View Device Logs — v1 has no in-app crash
    sink and no export path, so the device log *is* the channel), symbolize with
    `flutter symbolize -i crash.txt -d build/symbols/1.0.0+1/app.ios-arm64.symbols`, and confirm
    readable Dart frames and that the trace carries no user content. Remember the two symbol layers:
    the dSYM Xcode uploads with the build symbolicates the native frames, and Apple never sees the
    Dart symbols — discard them and every Dart frame of that release is unreadable forever.
    *(Depends on T11.9's symbols existing — run this step after T11.9 if the ordering demands it.)*

**Two things this pass deliberately does not exercise, because v1 does not ship them.** Export → wipe
→ import: E02's Definition of done lists "any backup/export path" under deliberately-left-out, E08's
Settings screen has four toggles, a Language row and an About row and no export control, and
`data-export-and-restore` is out of scope for v1. A durable on-device crash sink: E01 deferred it
(there was nowhere to write until E02 opened the database) and E02 did not pick it up. Both are
recorded in this epic's "deliberately left out" and in `docs/release/notes-1.0.0.md` as v1.1
candidates. Testing a feature the app does not have is how a checklist starts lying.

**Files.** `docs/review/on-device-checklist.md` (the template),
`design/review/<date>/on-device.md` (the executed copy),
`test/policy/on_device_checklist_test.dart`.

**Skills.** `design-review-workflow`, `accessibility-as-code`, `i18n-rtl-l10n`,
`sunburst-motion-and-haptics`, `sunburst-game-surfaces`, `release-and-store-shipping`.

**Screenshot check.** n/a (no visual surface — device photos of any failure go into
`design/review/<date>/` alongside the finding, but there is nothing to compare against a reference
PNG here).

**Done when.**
- [ ] `design/review/<date>/on-device.md` names the iPhone model, iOS version, build mode and date, and has zero unticked boxes.
- [ ] `test/policy/on_device_checklist_test.dart` green.
- [ ] VoiceOver walked in `en` and `fa`; the `ckb` voice situation is recorded as observed behaviour, not assumed.
- [ ] `ckb` was reached through the in-app Language sheet and survived a cold restart.
- [ ] Haptics were verified on hardware, never on the simulator; `heavyImpact` fired exactly once.
- [ ] Every failure found is appended to T11.4's findings table with a grade.
- [ ] The missing-previous-release substitution is recorded, not silently skipped.
- [ ] Export/import and the durable crash sink are recorded as **not shipped in v1**, in this epic's "deliberately left out" and in the release notes — not as unticked boxes.

**Commits.**
1. `Add the on-device pass checklist template and its completeness test`
2. `Record the <date> on-device pass results`
3. `Append on-device findings to the design review table`

---

### T11.7 — The single scoped fix round

**Goal.** Fix every BLOCKER and every FIX as one unit, prove each fix, re-shoot only the affected
cells, and open no new critique.

**Tests first (TDD).** Per finding, before its fix:
- Machine-observable findings (contrast, tap target, overflow at scale, missing `Semantics`, a
  colour-only state, a wrong numeral block, a mirrored shadow, a permission, a raw token value) get a
  **failing** assertion added to the file that owns that class — `test/a11y/*`,
  `test/theme/contrast_test.dart`, `test/policy/*` — named after the finding id, e.g.
  `test('F-07: schulte next-tile ring survives greyscale', …)` or
  `test('F-12: fa results score uses U+06Fx digits', …)`.
- Purely optical findings (spacing rhythm, a wrong shadow step, a type role, a Persian line box that
  crowds its border) cannot be asserted; their proof is the re-shot cell placed beside the reference.
  Say which findings fall in this class in the review doc rather than inventing a test that asserts
  nothing.
- A finding that only reproduces in one locale still gets its test parameterised over all four — a
  fix that repairs `fa` and breaks `de` is the second most common outcome of a locale fix round.

**Implementation.** One round. Fix BLOCKERs and FIXes together; NOTEs go to a backlog list at the
bottom of the review doc and are not touched. Re-run `flutter test` and every gate script. Re-shoot
**only** the affected cells by running the drive command and overwriting those files — the review
folder stays one truth. Verify each finding against its new shot and mark it resolved in the table.
Any new observation made during verification becomes a NOTE, never a new FIX. A BLOCKER that survives
the round means **no sign-off** and an escalation written into the verdict line — not a second round.

A translation change requested by T11.5's reviewer is handled here if it arrives after the sweep: it
is an ARB edit plus a re-shot cell, and it must pass `check_arb_parity.sh` and the overflow matrix
before it is called resolved.

**Files.** Whatever `lib/**` and `lib/l10n/**` files the findings name; the affected files under
`design/review/<date>/`; `docs/review/design-review-<date>.md` (resolutions column);
`test/a11y/*`, `test/theme/contrast_test.dart`, `test/policy/*`.

**Skills.** `design-review-workflow`, `accessibility-as-code`, `i18n-rtl-l10n`,
`widget-golden-and-a11y-testing`, `sunburst-components` (a fix that reaches into `lib/ui/components/`
must keep `PopSurface` the only surface constructor and the press law intact), `sunburst-shell-screens`,
`sunburst-game-surfaces`.

**Screenshot check.** Only the re-shot cells, each against its reference PNG — LTR cells against
`design/sunburst-pop/screens/`, RTL cells against `design/sunburst-pop/screens/rtl/` — in the same
five-step order. `dart run tool/verify_review_folder.dart design/review/<date>` must still exit 0
afterwards, including the cvd identity, locale non-identity and mirrored-probe assertions, any of
which a careless fix can break.

**Done when.**
- [ ] Every BLOCKER and FIX has a resolution in the table; every NOTE is in the backlog list untouched.
- [ ] Every machine-observable finding has a test that failed before the fix and passes after, parameterised over all four locales.
- [ ] Affected cells re-shot and overwritten; `verify_review_folder.dart` exits 0.
- [ ] `flutter test`, `flutter analyze --fatal-infos --fatal-warnings`, `dart format --set-exit-if-changed .` and every gate script green.
- [ ] No second round opened; any surviving BLOCKER is escalated in writing.

**Commits.** One per finding or per tight group of findings, each carrying its test:
1. `Add failing test for <finding id> and fix it` (repeat)
2. `Re-shoot the review cells affected by the fix round`
3. `Mark fix-round findings resolved in the design review`

---

### T11.8 — Performance and size budgets on real iPhone hardware

**Goal.** Measure cold start, the two frame-time hot paths and the artifact size in profile/release on
a real iPhone, and record the numbers as v1's baseline.

**Tests first (TDD).**
- `test/policy/budgets_test.dart` — parses `docs/release/budgets.md` and asserts: a header naming
  iPhone model, iOS version, build mode and date; exactly seven named metrics present
  (`cold_start_first_frame_ms`, `schulte_ui_p95_ms`, `schulte_raster_p95_ms`,
  `stroop_stimulus_p95_ms`, `ipa_size_bytes`, `font_assets_bytes`, `app_store_thinned_size_bytes`);
  each has a value and a unit; **no value is `TBD`**; every metric carries a `budget` alongside its
  `measured`; and `app_store_thinned_size_bytes` is either numeric or exactly the token
  `not-measurable-pre-upload`, because App Store thinned sizes come from App Store Connect's App
  File Sizes report after a build is processed and no local command produces them. This test cannot
  verify the numbers are *true* — only that a release cannot proceed with the file half-filled. Say
  that in the test's `reason:`.

**Implementation.**
```bash
flutter run --profile --trace-startup -d <realIPhoneId>   # build/start_up_info.json
flutter build ipa --release --analyze-size
```
- **Cold start:** read `timeToFirstFrameMicros` from `build/start_up_info.json`, three runs after a
  force-quit, record the median. `app-startup-and-bootstrap`'s anti-pattern list applies: the only
  lever we own is not blocking the first frame. If the number is bad, look for an `await` that crept
  into `main()` past `bootstrap()` — and note that the locale and theme reads are *supposed* to be on
  the launch path (rule 5), because a frame painted in the wrong direction is a visible defect.
- **Frame times:** DevTools → Performance, profile mode, recording a full Schulte run and a full
  Stroop run. Record **UI thread and raster thread** p95 separately — the play band's ray layers and
  the three-pass stimulus paint cost shows on raster, not in Dart. Confirm the board sits under a
  `RepaintBoundary` (`sunburst-shell-screens` puts one around `buildBoard`) so a HUD tick does not
  re-raster it. **Record the Schulte numbers in `fa` as well as `en`**: the tiles are text, Arabic-
  script shaping is more expensive than Latin, and the grid repaints on every tap. If the RTL numbers
  are materially worse, that is a finding, not a footnote.
- **Size:** `--analyze-size` output by library and asset; record the IPA size and break out
  `font_assets_bytes`. The fonts are the largest asset line and they roughly doubled in E04 — Fredoka
  and Nunito for Latin, plus the Arabic-script body and display faces. Confirm no unused weight ships
  and record the byte cost of Arabic-script coverage explicitly; it is the single largest size
  consequence of the four-locale decision and the number belongs on the record.
- Write `docs/release/budgets.md`. There is no previous release, so **v1's measured numbers are the
  budget**: record `measured` and set `budget` to measured + 10% headroom, and state that a v1.1
  regression past it is a release blocker, not a note.

**Files.** `docs/release/budgets.md`, `test/policy/budgets_test.dart`, and any `lib/**` change a
measurement forces (each with its own commit and its own before/after number — never an optimisation
without a measurement).

**Skills.** `flutter-performance`, `release-and-store-shipping`, `app-startup-and-bootstrap`.

**Screenshot check.** n/a (no visual surface).

**Done when.**
- [ ] `docs/release/budgets.md` complete; `test/policy/budgets_test.dart` green.
- [ ] Cold start is a median of three force-quit runs on the named iPhone, in profile mode — not on the simulator.
- [ ] Frame p95 recorded for UI **and** raster on both game surfaces, and for Schulte in `fa` as well as `en`; the recordings are saved beside the numbers.
- [ ] `font_assets_bytes` is broken out and the Arabic-script cost is stated.
- [ ] `app_store_thinned_size_bytes` carries a real number or the sanctioned token, never `TBD`.
- [ ] Any optimisation commit names its before and after number.
- [ ] The iPhone model and iOS version are named in the file, not "an old iPhone".

**Commits.**
1. `Add the release budget file schema test`
2. `Record v1 cold-start, frame-time and size measurements on the floor iPhone`
3. *(optional)* `Reduce <specific cost> on the Schulte board — raster p95 <before> to <after>`

---

### T11.9 — Icon, launch screen, version, signing material and obfuscated symbols

**Goal.** Make the artifact identifiable and reproducible: a real app icon, a native launch screen in
the app's own cream, `version: 1.0.0+1` as the single version source, no signing material anywhere in
git, and an obfuscated build whose symbols are archived.

**Tests first (TDD).**
- `test/policy/release_assets_test.dart`
  - Every image entry in `ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json` names a file
    that exists on disk — a missing size blocks upload with a message that names a device class, not
    a file.
  - The native launch background is `#FFF8EC` (`surface`) in
    `ios/Runner/Base.lproj/LaunchScreen.storyboard` — so the platform window, the first Flutter frame
    and every screen are one continuous colour with no flash.
  - No Dart splash: `lib/` contains no route path `/splash` and no widget class matching
    `Splash|Onboarding` (`app-startup-and-bootstrap` anti-pattern — a launch screen is the platform's
    window background, never a route on the critical path).
  - The launch screen carries **no text**. It is shown before `AppLocalizations` exists and there is
    no locale to render it in; a translated splash string is a string that cannot be translated.
  - **No Android assets are asserted, and none exist.** State the deferral in the test file header so
    a reader does not think the Android half was forgotten.
- `test/policy/version_and_secrets_test.dart`
  - `pubspec.yaml` `version:` matches `^version:\s*\d+\.\d+\.\d+\+\d+\s*$`.
  - `ios/Runner/Info.plist`'s `CFBundleShortVersionString` and `CFBundleVersion` read
    `$(FLUTTER_BUILD_NAME)` / `$(FLUTTER_BUILD_NUMBER)` — no literal version anywhere in the iOS
    project.
  - `.gitignore` contains `*.p12`, `*.p8`, `*.mobileprovision`, `*.jks`, `*.keystore`,
    `**/*service-account*.json` and `ios/Runner/GoogleService-Info.plist`.
  - `git ls-files` matches none of those patterns. (This duplicates `check-release-hygiene.sh` rule 1
    on purpose — a tracked signing key is unrecoverable, and one of the two gates will always be
    running.)
  - `ios/ExportOptions.plist` **is** tracked (it contains no secrets) and pins
    `method = app-store-connect`, an explicit `teamID`, `uploadSymbols = true` and
    `signingStyle = automatic`.

**Implementation.**
- Design the icon from the Sunburst Pop vocabulary: the wordmark glyph on `accent` `#FFC53D` with the
  3px ink `#2B1B4D` border read as a die-cut edge. No emoji, no icon font. The icon carries **no
  script** — a mark that reads in every locale, because there is one icon for four languages.
  Generate the sizes with `flutter_launcher_icons` and the launch screen with `flutter_native_splash`,
  both as **dev_dependencies** — confirm with `audit-deps.sh` that neither reaches the shipped binary.
- Set `version: 1.0.0+1` in `pubspec.yaml`, in its own commit (`release-and-store-shipping` step 2).
- **Decide `TARGETED_DEVICE_FAMILY`** and record the decision in `docs/release/signing.md`. `"1"`
  (iPhone only) removes the mandatory iPad screenshot set from submission and avoids shipping a
  phone-shaped layout rendered sparsely on a tablet; `"1,2"` makes the iPad set mandatory. MindForge's
  eight screens are drawn at 390×844 and nothing about them was designed for a tablet, so `"1"` is the
  recommended value — but it is a decision, and it is visible to users.
- Signing: enroll the app with the team's certificates and provisioning; keep the App Store Connect
  API key (`.p8` + Key ID + Issuer ID) **outside** the repo and injected from a secret store. Note in
  `docs/release/signing.md` that on iOS the recovery asymmetry is different from Android's: there is no
  Play-App-Signing-style escrow, the distribution certificate is regenerable from the developer
  account, and the thing that is truly unrecoverable is the **bundle identifier** — it is fixed for
  the life of the listing (see risks).
- Build with obfuscation and per-build symbols, **from a clean tree**:
  ```bash
  flutter clean && rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*
  flutter build ipa --release --obfuscate --split-debug-info=build/symbols/1.0.0+1 \
    --export-options-plist=ios/ExportOptions.plist
  .claude/skills/release-and-store-shipping/scripts/check-ipa-slices.sh build/ios/ipa/mindforge.ipa
  ```
  The `flutter clean` is not hygiene theatre. T11.3's sweep leaves the tree built for the simulator,
  and `flutter build ipa` from that tree embeds a simulator framework slice that Apple rejects with
  **90087** or **91169**. Thinning the fat binary does not fix it — the remaining arm64 slice still
  targets the simulator, because the device slice was never built. `check-ipa-slices.sh` reads each
  Mach-O's build-version load command (architecture alone proves nothing on Apple Silicon, where the
  simulator slice is also arm64) and costs five seconds against a ten-minute upload round trip.
- Archive `build/symbols/1.0.0+1/` off-machine **before** anything else happens to it. Keep both
  symbol layers straight: Xcode uploads the dSYM with the build so App Store Connect symbolicates
  native frames; the Dart symbols are ours alone and Apple never sees them.
- **Verify the fonts survived into the IPA:** `unzip -l build/ios/ipa/mindforge.ipa | grep -i -E 'vazirmatn|lalezar|fredoka|nunito'`
  and confirm every declared face is present. A font that fails to bundle is invisible in every test
  that runs against the source tree and produces boxes on the two locales nobody on the team reads.
- Wire `check-release-hygiene.sh .` into `.github/workflows/ci.yml` as a named gate: "no unrecoverable
  release mistake is tracked in the repo".

**Files.** `pubspec.yaml`, `ios/Runner/Info.plist`,
`ios/Runner/Assets.xcassets/AppIcon.appiconset/`, `ios/Runner/Base.lproj/LaunchScreen.storyboard`,
`ios/Runner.xcodeproj/project.pbxproj` (`TARGETED_DEVICE_FAMILY`), `ios/ExportOptions.plist`,
`.gitignore`, `docs/release/signing.md`, `test/policy/release_assets_test.dart`,
`test/policy/version_and_secrets_test.dart`, `.github/workflows/ci.yml`.

**Skills.** `release-and-store-shipping`, `app-startup-and-bootstrap`, `sunburst-tokens`,
`dependency-hygiene`, `ci-pipeline-and-gates`.

**Screenshot check.** n/a (no visual surface — the icon and launch screen have no reference PNG in
`design/sunburst-pop/screens/`). Sanity-check by eye instead: the launch screen colour must be
indistinguishable from the first painted frame of `01-home.png`; a visible flash means the two values
disagree. Check it in `fa` too — the first frame is RTL there, and a launch screen that is a solid
colour with no text is the reason that is a non-event.

**Done when.**
- [ ] Both policy tests green; `check-release-hygiene.sh .` exits 0 and runs in CI.
- [ ] Icon renders correctly at every size; launch screen shows no colour flash on the device, in LTR and RTL.
- [ ] `version: 1.0.0+1` is the only version literal in the repo.
- [ ] The IPA was built from a cleaned tree; `check-ipa-slices.sh` exits 0 **before** any upload is spent.
- [ ] All four bundled font families are present inside the IPA.
- [ ] `build/symbols/1.0.0+1/` archived off-machine; both symbol layers documented.
- [ ] `TARGETED_DEVICE_FAMILY` decided and recorded with its consequence.
- [ ] `audit-deps.sh` exits 0 with the icon/splash generators confirmed dev-only.

**Commits.**
1. `Add release asset, version and secret-handling policy tests`
2. `Add the MindForge app icon at every iOS size`
3. `Set the native launch screen to surface #FFF8EC`
4. `Set version to 1.0.0+1`
5. `Ignore signing material and document the iOS signing posture`
6. `Wire check-release-hygiene.sh into CI`

---

### T11.10 — Permission audit and store declarations, proved from the repo — iOS only

**Goal.** Assert, mechanically, that the shipped app requests nothing — and that every sentence in the
store declarations is checkable against this repository, in every locale it ships in.

**Tests first (TDD).**
- `test/policy/permissions_test.dart` — whole-set assertions, not forbidden-list ones, because only a
  whole-set assertion catches a *newly added* permission from a plugin bump.
  - `ios/Runner/Info.plist` has **zero** keys matching `NS.*UsageDescription`. Expect the empty set,
    not "none of these five".
  - `ios/Runner/Info.plist` declares no `UIBackgroundModes` and no `UIRequiredDeviceCapabilities`
    beyond the default.
  - `ios/Runner/Runner.entitlements` either does not exist or is an empty dict — no push, no
    HealthKit, no App Groups, no iCloud.
  - `ios/Runner/PrivacyInfo.xcprivacy`: `NSPrivacyTracking` is `false`, the `NSPrivacyTrackingDomains`
    key is **absent** (present-with-`true` is ITMS-91064; present at all has a runtime cost, because
    iOS blocks every listed domain when tracking authorization is not granted), and
    `NSPrivacyCollectedDataTypes` is an empty array.
  - **Android is deferred and asserts nothing.** The test file states that in its header: when Android
    lands, the merged-manifest whole-set assertion
    (`build/app/intermediates/merged_manifests/release/AndroidManifest.xml`, `uses-permission` set
    equal to empty, INTERNET stripped with `tools:node="remove"`) is a new task in that epic, and this
    file is where it goes. A commented-out Android assertion would be a gate that asserts nothing.
- `test/policy/ios_localizations_test.dart` — **new.** `CFBundleLocalizations` in
  `ios/Runner/Info.plist` equals exactly the set of `lib/l10n/app_*.arb` locales,
  `{en, de, fa, ckb}`, and `CFBundleDevelopmentRegion` is `en`. This is what the App Store listing
  reads as the app's supported languages and what iOS uses to resolve the app's preferred
  localization and to offer a per-app language in Settings; an ARB that ships without its plist entry
  is a locale the platform does not believe in. Asserted against the same source of truth as
  `supportedLocales` in T11.1, so the three can never drift apart in pairs.
- `test/policy/banned_imports_test.dart` — **E01's file, extended here, not re-authored.** E01 already
  walks `lib/`, strips comments and matches import URIs against the no-network set; this task widens
  the list with `package:grpc/`, `package:device_info_plus/`, `package:google_fonts/` and anything
  matching `analytics|crashlytics|amplitude|mixpanel`, and sharpens the reason string to name what now
  depends on it: "these break the no-network, no-telemetry promise the privacy labels are built on,
  and `google_fonts` additionally breaks the offline-font promise the four bundled families exist to
  keep." Two files with two overlapping ban lists is how one of them stops being maintained.
- `test/policy/privacy_claims_test.dart` — grep `store/listing.md`, `store/privacy-labels.md`,
  `store/metadata/en/`, `store/metadata/de/` and the About screen copy in `app_en.arb`/`app_de.arb`
  for banned absolutes: `nothing ever leaves your device`, `completely private`,
  `100% (private|secure|offline)`, `we can't see anything`, `we never see`, and their German
  equivalents. Note that the mock's own footer copy, "Train your brain. No wifi needed."
  (`app.html`), is a *mechanism* statement and passes — the test must not flag it, which is the test
  for the test. **State the limit in the test's `reason:`**: this gate covers `en` and `de` only,
  because a ban list can only be authored in a language its author reads. The `fa` and `ckb`
  claim-strength check is a line item on T11.5's native review form, and the sign-off records it as
  human evidence, not machine evidence.

**Implementation.**
- Write `ios/Runner/PrivacyInfo.xcprivacy` with `NSPrivacyTracking = false`, no
  `NSPrivacyTrackingDomains`, empty `NSPrivacyCollectedDataTypes`, and the required-reason API codes
  for whatever `drift`/`sqlite3_flutter_libs`/`path_provider`/`shared_preferences` actually use.
  **Transcribe, do not reason:**
  ```bash
  find ios/Pods -name 'PrivacyInfo.xcprivacy' -print
  plutil -p ios/Pods/<Pod>/.../PrivacyInfo.xcprivacy
  ```
  Each SDK on Apple's list ships its own manifest declaring exactly what it accesses and why; copying
  from it is correct and guessing is a rejection. Also confirm every such pod ships a manifest **and a
  valid signature** — an outdated plugin without one blocks the upload, and that is a dependency
  problem you want to find here rather than at submission.
- Write `store/privacy-labels.md` — every App Store privacy nutrition-label answer with, beside it,
  the repo evidence that proves it: the empty usage-description set, the empty entitlements, the
  banned-imports test, `audit-deps.sh` output showing no telemetry package anywhere in the transitive
  tree, and the drift database being the only storage. "Collect" means transmitted off the device;
  local storage is not collection — say that in the file. Note that v1 ships **no** export path at
  all, so there is not even a share-sheet hand-off to describe; when one lands, this file changes in
  the same PR.
- Write `store/listing.md` with mechanism copy, not absolutes. The sanctioned shape:
  > Your runs are stored in a database on this device. The app requests no permissions and has no
  > network access, so nothing is uploaded.
- Write `store/metadata/<locale>/` — name, subtitle, description, keywords, promotional text, per
  store locale. **Check App Store Connect's current supported-localization list first.** The app
  ships four locales; the store may not offer metadata in all four — Persian and Kurdish are, to the
  best of our knowledge, not App Store Connect metadata localizations, and Kurdish certainly is not.
  Verify it rather than assuming either way, and record the answer in `store/listing.md`. If the store
  cannot carry `fa`/`ckb`, the app still ships them and the *listing* says so in the English and
  German descriptions ("Also available in Persian and Kurdish Sorani") — that is the honest resolution,
  not quietly dropping the locales or quietly pretending the listing covers them.
- **App Store screenshots are a different artifact from the review stills.** Apple blocks submission
  per display type, and the required sizes (6.7-inch and 6.5-inch iPhone at the time of writing —
  re-check the current specifications page, they move) are **not** 390×844. The canonical review
  simulator cannot produce them. Capture store screenshots on a separate simulator per required
  display type, with `xcrun simctl status_bar … override` for a standardized status bar, into
  `store/screenshots/<display-type>/<locale>/`. Two facts worth knowing before they cost a
  submission: a committed screenshot folder is not an uploaded screenshot set, and a retried upload
  can append rather than replace — so the last step of any upload is a query listing what is attached
  per display type. Upload itself is out of scope (T11.11's exclusion list).
- Set `ITSAppUsesNonExemptEncryption = false` in `Info.plist`. MindForge performs no encryption; the
  key removes the export-compliance question from every future upload.
- Wire the permission, localization, import and claims tests into the fast `verify` CI job — none of
  them needs a build, which is the difference from the Android-era version of this task.

**Files.** `ios/Runner/Info.plist`, `ios/Runner/PrivacyInfo.xcprivacy`,
`ios/Runner/Runner.entitlements`, `store/privacy-labels.md`, `store/listing.md`,
`store/metadata/<locale>/`, `store/screenshots/<display-type>/<locale>/`,
`test/policy/permissions_test.dart`, `test/policy/ios_localizations_test.dart`,
`test/policy/banned_imports_test.dart`, `test/policy/privacy_claims_test.dart`,
`.github/workflows/ci.yml`.

**Skills.** `release-and-store-shipping`, `dependency-hygiene`, `ci-pipeline-and-gates`,
`i18n-rtl-l10n` (claims live as strings in four ARBs and must be flagged so a translation cannot be
stronger than its source).

**Screenshot check.** n/a (no visual surface). One exception if the About screen copy changes:
re-compare `design/sunburst-pop/screens/08-settings.png` and
`design/sunburst-pop/screens/rtl/08-settings.png` for the Settings footer block, which the mock
renders as `.setfoot` with the wordmark and tagline — and confirm the wordmark is bidi-isolated inside
the Persian and Sorani taglines (D6), which is exactly the mixed-script run that reorders when nobody
isolated it.

**Done when.**
- [ ] Zero `NS*UsageDescription` keys; no background modes; entitlements empty; all asserted by tests against the real project files.
- [ ] `PrivacyInfo.xcprivacy` present and correct, with required-reason codes transcribed from the Pods' own manifests — not reasoned about.
- [ ] `CFBundleLocalizations` equals the shipped ARB set and `CFBundleDevelopmentRegion` is `en`, asserted by test.
- [ ] `store/privacy-labels.md` maps every answer to repo evidence; `store/listing.md` contains no absolute claim in any language the gate can read, and the two it cannot are covered by T11.5.
- [ ] The store's supported-localization answer is verified and recorded, not assumed.
- [ ] Store screenshots captured at the current required display types, per store locale, on a simulator that is **not** the review device — with a note that capturing is not uploading.
- [ ] All four policy tests green and wired into the CI `verify` job.
- [ ] The Android deferral is stated in the permissions test file, not implied by its absence.

**Commits.**
1. `Add iOS permission, localization, banned-import and privacy-claim policy tests`
2. `Add PrivacyInfo.xcprivacy declaring no tracking and no collection`
3. `Add CFBundleLocalizations for en, de, fa and ckb`
4. `Add App Store privacy labels and listing copy with repo evidence for every claim`
5. `Capture App Store screenshots per required display type and store locale`

---

### T11.11 — Sign-off artifact, verified release build, tag

**Goal.** Produce the dated artifact that gates the release, verify the exact shipping build on real
hardware, and tag the commit that ships.

**Tests first (TDD).**
- `test/policy/signoff_test.dart` — parses `docs/review/design-review-<date>.md` and asserts:
  a header with date, reviewer, commit sha (40 hex chars), build mode and device; a matrix inventory
  of exactly **176** rows matching `reviewMatrix`, plus the four-group review partition and its
  counts; a findings table where every row has a grade in `{BLOCKER, FIX, NOTE}` and a non-empty
  resolution; **no** row graded BLOCKER whose resolution is not `resolved`; a named RTL-checklist
  section with a per-item result; a line naming `docs/review/l10n-review-<date>.md` and its verdict;
  and a final line matching `^VERDICT: (SIGNED OFF|NOT SIGNED OFF — .+)$`. Release tasks read this
  file, so a half-written sign-off must fail the suite rather than pass silently.
- The same test asserts `test/policy/l10n_review_test.dart` exists and is not skipped — the native
  review is a release gate and a gate that can be skipped is not one.

**Implementation.** Run only when a release is explicitly requested by name — building, signing and
tagging are side-effecting and partly irreversible, and a published `CFBundleVersion` is burned
forever.
1. Preconditions: working tree clean; CI green on the release commit; T11.7's fix round closed;
   T11.5's native review APPROVED; `docs/release/budgets.md` complete.
2. Write `docs/review/design-review-<date>.md`'s header, inventory, partition, RTL section,
   resolutions and verdict line.
3. `flutter clean`, then rebuild the artifact with obfuscation and the same `build/symbols/1.0.0+1/`
   directory (T11.9), confirm the symbol archive is off-machine, and run `check-ipa-slices.sh` on the
   IPA **before** an upload is spent.
4. Install the exact release IPA on a real iPhone (Xcode Devices or a TestFlight internal build — not
   a local debug or profile build; obfuscation and stripped asserts only exist here). Walk both games
   end to end in `en` and in `fa`, switch to `ckb` from the Language sheet, force-quit, relaunch,
   confirm data and locale intact. Confirm no debug affordance is reachable.
5. Reconcile: the usage-description and entitlement sets (T11.10), `CFBundleLocalizations` against the
   shipped ARBs, `PrivacyInfo.xcprivacy` and the listing copy against the current `pubspec.lock`, and
   the budgets against the measurements.
6. Tag `v1.0.0+1` on the exact commit and publish release notes.

**Files.** `docs/review/design-review-<date>.md`, `test/policy/signoff_test.dart`,
`docs/release/notes-1.0.0.md`, `build/symbols/1.0.0+1/` (archived off-machine, not committed).

**Skills.** `design-review-workflow`, `release-and-store-shipping`, `ci-pipeline-and-gates`.

**Screenshot check.** n/a (no visual surface — the sweep's comparisons, both LTR and RTL, are already
recorded in the inventory this artifact carries).

**Done when.**
- [ ] `test/policy/signoff_test.dart` green; verdict line reads `VERDICT: SIGNED OFF`.
- [ ] No unresolved BLOCKER; NOTEs listed in the backlog section.
- [ ] The native-review verdict is `APPROVED` for both `fa` and `ckb`, or the release did not sign off.
- [ ] The exact release IPA was installed on a real iPhone, walked in `en`, `fa` and `ckb`, force-quit and relaunched.
- [ ] `check-ipa-slices.sh` exited 0 on the IPA built from a cleaned tree.
- [ ] Symbols archived off-machine before any upload; `flutter symbolize` verified against a real crash log (T11.6 step 10).
- [ ] Commit tagged `v1.0.0+1`; release notes published, naming the four shipped locales and the deferred Android target.
- [ ] Upload, the app record, the App Privacy questionnaire, the privacy policy URL, store metadata entry and the phased release are explicitly recorded as out of scope and pending a human account holder.

**Commits.**
1. `Add the sign-off artifact schema test`
2. `Write the <date> design review sign-off`
3. `Add v1.0.0 release notes`
4. *(on explicit request)* `Tag v1.0.0+1`

## Gates that must pass

```bash
# codegen BEFORE analyze — never after
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos --fatal-warnings
flutter test --test-randomize-ordering-seed random

# every skill gate, through the one runner E01 built
bash tool/skill_gates.sh
```

**Not** `for s in .claude/skills/*/scripts/*.sh; do bash "$s" || exit 1; done`. Measured against this
repository, that loop fails on 29 of the 49 scripts: five take a required argument and can never pass
argument-less (`scaffold_feature.sh`, `verify_feature.sh`, `check-ipa-slices.sh`,
`check-flavor-graph.sh`, plus `check_arb_parity.sh` before E04 shipped a second ARB), five are runners
rather than gates (`regen.sh`, `run_tests.sh`, `ci-gates.sh`, `lint-gates.sh`, `analyze.sh`), and
`check-scheduler-purity.sh` exits 127 on macOS bash 3.2. `tool/skill_gates.sh` carries the run table,
the skip table and a reason per skipped row, and `test/policy/skill_gates_coverage_test.dart` fails if
a script is in neither — which is what makes the sweep a gate instead of noise.

The ones this epic depends on directly, with their real arguments:

```bash
.claude/skills/sunburst-tokens/scripts/check_raw_values.sh                lib
.claude/skills/sunburst-tokens/scripts/check_palette_contrast.sh          lib/theme/sunburst_colors.dart
.claude/skills/sunburst-components/scripts/check_component_hygiene.sh     lib
.claude/skills/sunburst-shell-screens/scripts/check_shell_boundaries.sh   lib
.claude/skills/sunburst-game-surfaces/scripts/check_game_palette.sh       lib
.claude/skills/sunburst-motion-and-haptics/scripts/check_motion_tokens.sh lib
.claude/skills/i18n-rtl-l10n/scripts/check_i18n_bans.sh                   lib
.claude/skills/i18n-rtl-l10n/scripts/check_arb_parity.sh                  lib/l10n
.claude/skills/widget-golden-and-a11y-testing/scripts/check-test-hygiene.sh
.claude/skills/testing-strategy/scripts/check_test_hygiene.sh
.claude/skills/dependency-hygiene/scripts/audit-deps.sh                   .
.claude/skills/ci-pipeline-and-gates/scripts/ci-gates.sh
.claude/skills/ci-pipeline-and-gates/scripts/banned-strings.sh
.claude/skills/release-and-store-shipping/scripts/check-release-hygiene.sh .
.claude/skills/release-and-store-shipping/scripts/check-ipa-slices.sh     build/ios/ipa/mindforge.ipa
```

`check_arb_parity.sh` **is** in the list now, and that is the visible consequence of E04. Under the
one-locale plan it sat in `tool/skill_gates.sh`'s skip table with a measured reason (it exits 2 on a
directory holding only the template: `FAIL: no locale ARB files (app_*.arb) beside the template` —
verified). E04 moved it to the run table the day `app_de.arb`, `app_fa.arb` and `app_ckb.arb` landed.
It is now a hard gate on every key this epic adds: parity in all four locales, in the same commit as
the template. `check_i18n_bans.sh lib` is the other half — directional geometry, adaptive icons, no
raw-ASCII digit splices, no legacy bidi embeddings, no runtime font fetch.

Epic-specific:

```bash
xcrun simctl boot C13DDC02-375D-4E1B-8F81-44EB407D09A4
flutter drive --driver=test_driver/review_sweep.dart \
  --target=integration_test/review_sweep_test.dart \
  -d C13DDC02-375D-4E1B-8F81-44EB407D09A4 --profile     # the 176 stills + sidecars

dart run tool/verify_review_folder.dart design/review/<date>   # inventory, cvd, locale, direction

flutter clean && rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*   # BEFORE the release build
flutter build ipa --release --analyze-size                     # size, by library and asset
flutter run --profile --trace-startup -d <realIPhoneId>        # build/start_up_info.json
```

**Android runs no gate here and is not built.** Adding it later means re-running this entire list on
an Android target, re-verifying the fonts, numerals and RTL rendering there, and adding the
merged-manifest whole-set permission assertion that has no iOS equivalent. It is not implied by an
iOS pass.

## Risks and open questions

- **No physical iPhone.** `design-review-workflow` and `flutter-performance` rule 11 both require real
  target-class hardware. The simulator has **no haptics at all**, renders with the Mac's fonts and
  memory, and has no thermal envelope — so it cannot prove the frame budget, the cold start, the
  boundary-haptic latches or real memory pressure. *Decision needed from Zakaria before T11.6:* which
  physical iPhone is the floor device, and confirm the deployment target E01 pinned by reading it out
  of the Xcode project rather than assuming a value. If no device exists, the honest outcome is
  `VERDICT: NOT SIGNED OFF — no on-device pass`, not a sign-off with a simulator note.
- **No native speaker for `fa` or `ckb`.** This is the highest-risk unknown in the epic, because its
  latency is a person's calendar and it gates the tag. Sorani is the harder half: the pool of
  reviewers is smaller and no machine check substitutes. *Raise it on day one alongside the
  account-holder gates.* The two sanctioned outcomes are in T11.5; a third — shipping unreviewed
  machine translation — is not one of them.
- **The `ckb` Material/Cupertino delegate.** `GlobalMaterialLocalizations`/`GlobalCupertinoLocalizations`
  ship a fixed locale list and `ckb` is very likely not on it; a missing delegate throws at runtime on
  locale switch. E04 owns the custom delegate that serves our ARB for `ckb` while delegating
  Material/Cupertino to the nearest script neighbour (`fa`, else `ar`), and owns verifying the actual
  delegate list at build time. T11.1's `ckb_delegate_test.dart` is the release-time proof it survived
  three epics of screens. If it is missing, every `ckb` cell in the sweep throws and the failure looks
  like a screen bug.
- **`intl` may have no `ckb` number symbols.** `LocaleNumbers` pins `ckb` to the `fa` symbol set —
  same Extended Arabic-Indic block (U+06Fx), same separators. Anything that resolves a formatter
  implicitly falls back to Latin digits with **no error**, which is the localization defect most
  likely to ship silently. T11.2's `numerals_test.dart` is the only thing standing in front of it, and
  it must run on every surface, not a sample.
- **The Sorani display face is E04's verdict and this epic inherits it.** D4 names Vazirmatn for body
  and Lalezar as the closest OFL chunky display candidate, but Lalezar's coverage of ڕ ڵ ۆ ێ ھ is
  **not assumed**. If E04's answer is "Lalezar fails on Sorani", then `fa` and `ckb` do not look
  identical — `fa` gets the display face and `ckb` falls back to Vazirmatn Bold. Record whichever
  outcome E04 measured in the sign-off; do not paper over it by demoting both, and do not re-open the
  choice here.
- **The Fredoka personality does not survive translation.** Fredoka and Nunito have no Arabic-script
  coverage, and no Arabic face is a Fredoka. In `fa` and `ckb` the identity is carried entirely by the
  **shape language** — the 3px ink border, the hard offset shadow at zero blur, the press-down, the
  saturated palette on cream — not by the typeface. The sweep's identity-fidelity lens must be applied
  on those terms in the RTL cells: judge whether the *shape* language delivered, not whether the type
  looks like the English screens. A reviewer grading `fa` down for "not looking like Fredoka" is
  grading the wrong thing, and pretending a font swap is neutral is the other half of the same error.
- **App Store metadata may not support `fa` or `ckb`.** App Store Connect offers a fixed list of
  metadata localizations; Kurdish is certainly not on it and Persian, to the best of our knowledge, is
  not either — but this was **not verified on this machine** and it moves. Verify before writing
  `store/metadata/`. If the store cannot carry them, the app ships four locales and the listing
  carries two, and the English and German descriptions say so. Do not quietly drop the app locales to
  match the store's.
- **A privacy policy URL is required for App Store submission**, including for an app that collects
  nothing — and hosting a URL is the one piece of infrastructure an entirely offline product has no
  reason to own. `store/privacy-policy.md` is the source of truth in the repo; where it is hosted is
  an account-holder decision. *Raise it with the account-holder gates on day one*, not at submission.
- **The bundle identifier is forever.** Whatever E01's `flutter create --org` set is fixed for the
  life of the listing; changing it later creates a *new* app and strands every user. *Confirm the
  value with Zakaria before the first upload* — after the first upload it is unfixable. This replaces
  the Android `applicationId` risk one-for-one; the asymmetry is identical.
- **Account-holder-only store gates have no API.** The app record, the App Privacy questionnaire and
  the Paid Applications Agreement block submission and need a human. MindForge has no in-app purchase,
  so the Paid Applications Agreement is not load-bearing here — but the first two are, and the final
  *Submit for Review* click is the account holder's. Raise them on day one of this epic, not at the
  end; they are why "upload" is out of scope.
- **The screenshot sweep sets up a simulator-slice rejection.** T11.3 leaves the tree built for the
  simulator; a `flutter build ipa` from that tree is rejected 90087/91169 and thinning the binary does
  not fix it, because the device slice was never built. The mitigation is a `flutter clean` written
  into `sweep-procedure.md`'s last line and `check-ipa-slices.sh` run before the upload is spent — it
  reads each Mach-O's build-version load command, because on Apple Silicon architecture alone proves
  nothing.
- **Store screenshots are a different device and a different artifact from the review stills.** The
  review sweep runs at 390×844 to match the references; the App Store's required display types are
  larger and change over time. Capturing them is not uploading them, submission blocks per display
  type with a message that names a device class rather than a file, and a retried upload can append
  rather than replace. Query what is attached before calling it done.
- **Profile-mode stills vs a release-build review.** `flutter drive` needs a VM service, so the 176
  stills are profile, not release. Mitigation: T11.6 and T11.11 both run on the installed release IPA,
  and the sign-off states which evidence came from which build mode. Do not describe the sweep as a
  release-build review.
- **`flutter_launcher_icons` / `flutter_native_splash` are third-party build tooling.** Dev-only, so
  they never reach the binary, but they write into `ios/`. Decision: run them once, commit the
  *generated assets*, and treat the generators as reproducible tooling — not as something the build
  depends on. `audit-deps.sh` must confirm dev-only placement.
- **The 176-cell matrix omits a dark-theme axis and a reduce-motion still axis.** Both omissions are
  deliberate, recorded (`sunburst-tokens` rule 11; the end-state-identity property motion never
  violates) and asserted in `test/policy/review_matrix_test.dart`. Risk: a future dark mode silently
  inherits a sweep that never covered it. Mitigation: the test's `reason:` string names the rule, so
  re-opening either decision reds the matrix test. **The RTL axis is no longer an omission** — it is
  half the matrix, and the earlier one-locale, LTR posture that justified leaving it out no longer
  exists.
- **The colour-blind identity assertion is deliberately strict, and deliberately not a byte compare.**
  If any chrome surface legitimately reads a gameplay slot — it should not, per `sunburst-tokens` rule
  5 — it fails on eight surfaces × four locales at once. Treat a failure as a tier violation to fix,
  not a test to relax; a genuinely legitimate exception is recorded in the review doc with its reason,
  never silently removed from `verify_review_folder.dart`. The comparison is max-per-pixel-delta-0 on
  **decoded** images with animations disabled and each surface settled, because two `flutter drive`
  passes over animated surfaces cannot promise identical PNG bytes and a strictness nobody can satisfy
  gets deleted rather than honoured.
- **VoiceOver probably has no Sorani voice.** iOS ships Persian; Sorani is very unlikely to have a
  voice, so VoiceOver on `ckb` will read with a fallback or spell out. That is a platform limit, not
  something this epic can fix — but it must be *observed and recorded*, not assumed in either
  direction, and the semantics (labels, roles, traversal order) must still be correct where the
  pronunciation is not.
- **No previous release to upgrade from.** The data-durability rehearsal loses its most valuable step.
  Recorded in T11.6; the real migration rehearsal becomes a v1.1 precondition, written into
  `docs/release/notes-1.0.0.md` so it is not forgotten.
- **Two v1 omissions the checklist must not pretend to cover.** There is no export/import path (E02's
  Definition of done lists it as left out; E08's Settings screen has no export row) and no durable
  on-device crash sink (E01 deferred it; E02 did not pick it up). T11.6 tests neither and records both,
  and `docs/release/notes-1.0.0.md` carries them as v1.1 candidates. If either should ship in v1, that
  is two new tasks in E02 and E08 — raise it before T11.6, not during it.

## Definition of done

- [ ] Branch `epic/11-accessibility-qa-and-release` cut off `main`; granular commits, tests committed with the code they cover.
- [ ] E04's localization ADR verified against the shipped tree; the Settings Language row navigates to a real four-option screen; the choice persists; `ckb` does not throw; no dead control ships anywhere, including the About row and Home's Daily Mix card.
- [ ] T11.2's a11y floor suite green across all eleven surfaces × four locales at every (device, scale, bold) tuple, including the numeral-block and RTL-geometry assertions.
- [ ] 176 stills + 176 sidecars + 16 motion recordings captured on `C13DDC02-375D-4E1B-8F81-44EB407D09A4`; `verify_review_folder.dart` exits 0 on all four assertion classes.
- [ ] All eight screens compared against `design/sunburst-pop/screens/*.png` **and** `design/sunburst-pop/screens/rtl/*.png` in the five-step order; every reference change is a committed `app.html` edit plus both regenerated PNG sets.
- [ ] The RTL checklist — glyphs, joins, Latin-run order, numeral system, mirrored affordances, unmirrored shadows — recorded per item, not summarised.
- [ ] Native-speaker review of `fa` and `ckb` completed and APPROVED; zero `native-speaker-pending` markers remain; `check_arb_parity.sh lib/l10n` green after every reviewer edit.
- [ ] On-device pass executed on a named iPhone with zero unticked boxes; VoiceOver walked in `en` and `fa`; `ckb` reached through the in-app picker; haptics verified on hardware; destructive steps ran last.
- [ ] Every finding graded; every floor violation graded BLOCKER; exactly one fix round; no surviving BLOCKER.
- [ ] `docs/release/budgets.md` complete with measured values, budgets, the Arabic-script font cost and Schulte's `fa` raster numbers, on named hardware.
- [ ] Zero `NS*UsageDescription` keys, no background modes, empty entitlements, `PrivacyInfo.xcprivacy` declaring no tracking and no collection, and `CFBundleLocalizations` equal to the shipped ARB set — all asserted by tests.
- [ ] `store/privacy-labels.md`, `store/listing.md` and `store/metadata/<locale>/` written, every claim backed by repo evidence, no absolute privacy claim; the store's supported-localization answer verified and recorded.
- [ ] No signing material tracked; `check-release-hygiene.sh .` exits 0; the IPA was built from a cleaned tree and `check-ipa-slices.sh` exits 0 before any upload.
- [ ] Release built `--obfuscate --split-debug-info=build/symbols/1.0.0+1`; symbols archived off-machine; all four font families verified present inside the IPA; a real crash log symbolized successfully.
- [ ] `docs/review/design-review-<date>.md` signed off; `test/policy/signoff_test.dart` and `test/policy/l10n_review_test.dart` green.
- [ ] `/simplify` run and its findings addressed.
- [ ] `/code-review` run and its findings addressed.
- [ ] All gates green: `dart format --set-exit-if-changed .`, `flutter analyze --fatal-infos`, `flutter test`, `bash tool/skill_gates.sh`.
- [ ] PR opened explaining what changed, why, how it was verified, which screens were compared in which direction, and what was deliberately left out: **Android entirely**, store upload, the app record, the App Privacy questionnaire, the privacy policy URL, the phased release, dark mode, a fifth locale, the migration rehearsal, **export/import and the durable crash sink**.
- [ ] CI green on the PR; merged preserving the granular commits; branch deleted; back on `main` and pulled.
- [ ] Commit tagged `v1.0.0+1` on explicit request.
