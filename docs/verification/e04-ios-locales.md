# E04 on-simulator verification: four locales, two directions

Run on the canonical device — `MindForge iPhone 14`,
`C13DDC02-375D-4E1B-8F81-44EB407D09A4`, iOS 18.6, exactly 390x844 logical
points. Debug build, `flutter build ios --simulator --debug`, installed with
`simctl install` and launched four times:

```bash
xcrun simctl launch <udid> com.mindforge.mindforge -AppleLanguages "(<tag>)" -AppleLocale "<tag>"
```

## What was on screen

The app ships `home: const Scaffold()` — **the eight screens are E08's**, and an
empty Scaffold verifies nothing. So this run used a **temporary, uncommitted**
probe widget in `lib/app.dart` rendering the resolved locale tag and direction,
four ARB strings across the message shapes, and four numbers through
`LocaleNumbers`. It was reverted immediately afterwards and is not in any
commit. `git diff lib/app.dart` is empty.

That is the honest scope of this check: it proves the **resolution chain and the
rendering stack** work on a real device under all four system languages. It does
not prove any layout, because there is no layout yet.

## Observed

| Locale | Header | Numbers | Notes |
|---|---|---|---|
| `en` | `en / ltr` | `1,480` `1:05` `92%` | Fredoka + Nunito |
| `de` | `de / ltr` | `1.480` `1:05` `92 %` | CLDR puts a narrow no-break space before the German percent sign; it is the locale's pattern, not a concatenation |
| `fa` | `fa / rtl` | `۱٬۴۸۰` `۱:۰۵` `۹۲٪` | Vazirmatn, Eastern Arabic U+06F0–U+06F9, U+066C group separator, U+066A percent sign |
| `ckb` | `ckb / rtl` | `۱٬۴۸۰` `۱:۰۵` `۹۲٪` | Same, through the vendored delegates borrowing `fa` |

Re-run after the code-review fixes, with the probe extended to the values those
fixes changed. Under `ckb`, on the device:

| Checked | Renders | Was |
|---|---|---|
| `navPlay` | `یاری` | `شروع` — the nav tab was keyed to `playButton` |
| `gameSchulteGridTagline` | `۱ تا ۲۵ …` | `١ تا ٢٥ …` — Arabic-Indic, the forbidden block |
| `clock(-1500)` | `۰:۰۰` | `۰:۵۹` — a timer gaining a minute as the round ended |
| `seconds(59999)` | `۵۹٫۹` | `۶۰٫۰` — while `clock` said `۰:۵۹` for the same run |
| `percent(0.996)` | `۹۹%` | `۱۰۰%` — beside `newPersonalBest`, for a run that dropped one |
| `foundOfTotal(6, 25)` | `۶` at the start, `۲۵` at the end | the arguments were swapped in the reference |

Every one of these matters:

* **`ckb` resolved to `rtl` on the device.** Without `CkbWidgetsLocalizationsDelegate`
  it resolves to `ltr` and the app runs perfectly while reading backwards — the
  silent half of the bug, and the one no crash report would surface.
* **No tofu, in either RTL locale.** Every Persian and Sorani glyph drew,
  including ڕ ڵ ۆ ێ ھ ە, which is what refused Lalezar in E03.
* **The plural rendered `زنجیره‌ی ۴ روزه` / `زنجیرەی ۴ ڕۆژە`** — a Persian and a
  Sorani sentence with an Eastern Arabic digit in it. Before the placeholders
  became pre-formatted strings this read `4`, because gen-l10n interpolates an
  `int` with Dart `toString()`.
* **The `MindForge` wordmark reads left-to-right inside the RTL text**, in
  Fredoka, and the sentence around it still reads right-to-left.
* **The German percent has its space and the Persian percent sign is on the
  other side of the number.** Both come from the locale's own pattern. A hand-
  concatenated `'$value%'` would have been wrong in two languages at once.

The iOS status bar clock stays in Latin digits under `fa` and `ckb`. That is
system chrome rendered by iOS, not by the app.

## What this does not cover

Layout, mirroring of real components, and translation quality. Mirroring is
covered by `design/sunburst-pop/screens/rtl/` and by the six goldens under
`test/goldens/rtl/`; translation quality is machine-grade and gated on E11's
native-speaker review, which is a BLOCKER there.
