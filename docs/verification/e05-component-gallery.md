# E05 on-device verification: the catalog in Sorani

Run on the canonical device — `MindForge iPhone 14`,
`C13DDC02-375D-4E1B-8F81-44EB407D09A4`, iOS 18.6, exactly 390x844.

```bash
flutter build ios --simulator --debug -t tool/gallery_main.dart
xcrun simctl install <udid> build/ios/iphonesimulator/Runner.app
xcrun simctl launch <udid> com.mindforge.mindforge -AppleLanguages "(ckb)"
```

The gallery starts in the **device's** language, so the launch flag is the whole
setup. Its switcher is for comparing locales without relaunching.

## What this proves that the golden lane cannot

**iOS's own Arabic shaping.** Every host-side golden renders through the same
Skia the goldens were blessed with; it can prove a rendering *changed* and it
cannot prove the platform will join a Sorani word correctly. That is a device
question.

Observed in `docs/verification/e05-gallery-ckb.png`:

* **Cursive joining is correct** through `دەستپێکردن`, `خێرایی ستروپ` and
  `ڕەنگەکە دابگرە، نەک وشەکە` — including the Sorani-specific ڕ ێ ە ڵ, which
  are the letters that refused Lalezar in E03 and which no other shipped locale
  would have exercised.
* **No tofu anywhere**, at any size, in any component.
* Every numeral is Eastern Arabic: `۱٬۴۸۰`, `۱۸٫۶`, `۲۵`.
* The layout is mirrored — the back chevron flipped, the nav order reversed, the
  best pill and the card text at the start edge — while **the hard offset
  shadow is still down-and-right on every surface**.
* The three nav destinations share the bar's width, so `ڕێکخستن` is not clipped.

## What it does not prove

Translation quality, which is machine-grade here and gated on E11's
native-speaker review; and the press, which is motion and is E06's to verify.
