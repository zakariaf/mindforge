# E11 sign-off: accessibility, QA and release readiness

Run on the canonical device — `MindForge iPhone 14`,
`C13DDC02-375D-4E1B-8F81-44EB407D09A4`, iOS 18.6, 390x844 at DPR 3 — and, for
the release configuration, `flutter build ios --release --no-codesign`.

## What is asserted, and by what

| Claim | Where it is proved |
|---|---|
| Four locales, `ckb` included, and the choice persists | `locale_persistence_test` writes through the repository, disposes the container, and rebuilds from the same database |
| The Language row is live and flips the whole app | `language_sheet_test` asserts direction at the app root, not through a `Directionality` a test supplied |
| No user-facing string outside the ARB | `l10n_posture_test` — checked by hardcoding a label on purpose |
| Right digits on every surface, in every language | `numerals_test` walks the RENDERED text of all eleven surfaces × four locales |
| No clamp, no `FittedBox`, no value ellipsis | `a11y_bans_test` — checked by adding an ellipsis on purpose |
| The app requests no permission | `permissions_test`, against the real `Info.plist` and entitlements |
| The privacy manifest is in the BUNDLE | `permissions_test` reads `project.pbxproj`; confirmed present in both the debug and release `Runner.app` |
| The icon is not Flutter's, and carries no alpha | `launch_screen_test` reads the PNG colour-type byte |

Test suite: **2,385 passing**. `flutter analyze --fatal-infos --fatal-warnings`
clean. `tool/skill_gates.sh`: 36 passed, 0 failed, 15 skipped.

## What the sweep found

**`TabularText` was shredding Persian words.** Stats' "time trained" is a whole
sentence — `۰ ساعت و ۰ دقیقه` — and it went through a widget that splits a value
into one box per character so digits keep a fixed pitch. Each box is its own
paragraph, so every Arabic letter was shaped in isolated form, the joins were
gone, and the LTR row reversed the words on top of that. It drew as an
unreadable smear that overflowed its box.

Latin never showed it — `0h 0m` split into boxes reads perfectly — so this is a
defect only an RTL sweep could find, and it had been sitting on a shipped screen
behind two epics of green tests. Fixed in `TabularText`, with the exclusions
that matter written down: both Arabic-Indic digit ranges and the numeric marks
`٪` `٫` `٬` live in the same Unicode block, and a guard that took the whole block
stripped `۱٬۴۸۰` of its fixed pitch.

**The app icon was Flutter's logo and the launch screen was white.** Both now
come from the app's own tokens: `AppIconMark` renders the wordmark's coral tile
at 1024, a golden pins it, and a script fills the appiconset from that one
master — so a palette change reds the golden rather than leaving the icon behind.

## Release configuration

`flutter build ios --release --no-codesign` → **20.1 MB** `Runner.app`.

| Component | Size |
|---|---|
| `Flutter.framework` | 9.9 MB |
| `App.framework` (Dart + assets) | 7.5 MB |
| `sqlite3.framework` | 1.6 MB |
| Everything else | ~1 MB |

All three bundled faces are present — Fredoka, Nunito and Vazirmatn.

> **Three faces, not four.** `CLAUDE.md` says four, and the shipped tree has
> three: E04 measured Lalezar against its own cmap, found it missing five of the
> seven Sorani letters, and refused it, so Vazirmatn serves both the display and
> the body role in Arabic script. The decision is recorded in
> `sunburst_type.dart` and `pubspec.yaml`; the house-rules line is what is out
> of date. Flagged rather than edited — `CLAUDE.md` is the maintainer's file.

## Not done, and why

These are recorded rather than ticked. Each is a task the epic names that this
environment cannot honestly perform.

| Task | Status | Why |
|---|---|---|
| **T11.6 — on-device pass on real iPhone hardware** | **Not done** | No provisioned handset. Requested out of scope by the maintainer. Everything a simulator can genuinely establish — VoiceOver semantics, Dynamic Type, contrast, reduce-motion, RTL — is asserted in the suite and swept on the canonical simulator. |
| **T11.8 — performance and size budgets on real hardware** | **Not done** | Same reason. The SIZE half is measured above from a real release build; the frame-timing half needs a device, because a simulator's timings are its host's. |
| **T11.5 — native-speaker review of Persian and Sorani** | **Not done** | Nobody has reviewed the copy. Every `fa` and `ckb` message is marked `x-review: native-speaker-pending` in its ARB, which is the honest state and is machine-checkable. |
| **Store screenshots and upload** | **Not done** | Capturing is not uploading, and neither has happened. |
| **Tag** | **Not done** | A tag on an unreviewed branch would assert a sign-off that has not happened. |

## Captures

- `e11-stats-fa.png` — Stats in Persian, after the `TabularText` fix
- `e11-springboard.png` — the icon on the home screen
