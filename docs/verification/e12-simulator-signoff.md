# E12 on-simulator sign-off: Digit Bridge and False Light, both directions

Run on the canonical device — `MindForge iPhone 14`,
`C13DDC02-375D-4E1B-8F81-44EB407D09A4`, iOS 18.6, exactly 390x844 — on
2026-08-29, against `epic/12-two-original-games`.

```bash
flutter build ios --simulator --debug
xcrun simctl install <udid> build/ios/iphonesimulator/Runner.app
xcrun simctl spawn <udid> defaults write .GlobalPreferences AppleLanguages -array fa
xcrun simctl launch <udid> io.applander.mindforge \
  --route='/game/digit_bridge/play?difficulty=classic&seed=42'
```

Screens compared: `screens/09-digit-bridge.png`, `screens/10-false-light.png`,
`screens/01-home.png` and all three `rtl/` counterparts, region by region.

## What matched

**Home, both directions.** Four unlocked cards in registry order — Stroop Rush
on coral, Schulte Grid on turquoise, Digit Bridge on lilac, False Light on leaf
— the section label reading `4 unlocked` / `۴ باز شده`, and both new artwork
tiles rendering as the reference draws them. False Light's card sits below the
fold, which is correct: the hub is a `CustomScrollView` and always was.

**False Light, both directions.** The leaf band with its ray sweep and dot
lattice, three pills, the progress track in leaf stripes, the ink bottom border,
and a 4x5 field of cream tiles with 3pt ink edges. Pressed tiles are
unmistakable at arm's length: no shadow, translated into where the shadow was,
and a fill two steps darker in value. The board is byte-for-byte the same
content in `fa` as in `en`, because it carries no text at all — the grid mirrors
around it, which is correct and is what every grid in the app does.

**Digit Bridge, both directions.** The lilac band and its rays, the target card
on paper with the board lattice, and a 3x2 of chips. In `fa` the chrome mirrors
— pause at the right, difficulty chip at the left, HUD order reversed — and the
two numeral runs keep their own direction, so `۷۴۷۳۳` reads
most-significant-digit-first exactly as `74733` does.

**The cross-script mechanic, on a real device.** In `en` the target drew Latin
and the chips Eastern Arabic; in `fa` the same round drew the target in Eastern
Arabic and the chips in Latin. The HUD stayed in the reader's own numerals in
both — `0:00 / 0 / x1` against `۰:۰۰ / ۰ / ×۱` — which is the fence the
exemption is scoped to, seen working rather than argued.

## Three defects the simulator found that the test suite did not

**1. The chips were portrait.** `BridgeMetrics` divided the field's leftover
height between two rows, which on a 460pt board drew chips half as wide as they
were tall. The reference has `aspect-ratio:1.6/1`. Fixed by sizing the chip's
height from its own width; the layout tests passed both before and after,
because a tap-target floor and an overflow check cannot see a wrong proportion.

**2. Then the target card sprawled.** With the chips fixed, the target took all
the remaining height and left the numeral floating in a sea of paper. Fixed by
letting the column size to its content and centring it, which is what
`.playfill--bridge{justify-content:center}` says.

**3. The Persian target lost its last digit.** THE ONE THAT MATTERED. At the
`countdownNumeral` step a four-digit Persian target lays out at 326pt inside a
326pt card, and blitz deals five: measured at 447pt inside 280pt on a 320pt
device. Latin fitted at 256pt — the exact shape of a defect that reaches a
release, because the developer's own locale is the one that works.

Fixed by measuring and picking a smaller BASE step (`scoreHero`, falling back to
`displayXl`), never a clamped scaler, a `FittedBox` or an ellipsis.
`app.html`'s `.target b` moved from 56px to 76px in the same commit, because the
reference and the app have to be expressible in the same tokens and 56 was not
one of them.

**The test that would have caught it now exists, and it was vacuous first.**
`bridge_glyph_fit_test.dart` originally read `tester.getSize` on the `Text` —
which returns the size the parent CONSTRAINED it to, so an overflowing run
reports the box width back and the comparison is true by construction. Verified:
that version passed against the very build whose Persian target was clipping. It
now lays the run out with a `TextPainter`, unconstrained, and fails the old
build at 447pt-in-280pt.

## What this pass did not cover

- **No real iPhone.** Same reason E11 recorded: there is no provisioned handset
  in this setup. Everything above is the simulator.
- **No native-speaker reading of the new Persian and Sorani strings.** Seven new
  ARB keys per locale carry `x-review: native-speaker-pending`, the marker E11
  established. The glyphs render, join and fit; whether they read well is a
  question no gate and no screenshot can answer.
- **No haptics.** The simulator has none. The moment wiring is covered by
  `bridge_board_notifier_test` and `light_board_notifier_test` against a fake
  `FeedbackService`;
  whether it FEELS right is a device question.
