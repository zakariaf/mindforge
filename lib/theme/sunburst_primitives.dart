part of 'sunburst_colors.dart';

/// Tier 1 — primitives. **The one place in MindForge a raw colour may appear.**
///
/// Named by the design system's own primitive names, not by rank or appearance,
/// because those names are how designers and this file stay in sync.
///
/// `_P` is private to its **library**, not its file, which is why this is a
/// `part of 'sunburst_colors.dart'` rather than its own library. That is the
/// only arrangement satisfying all three constraints at once: `_P` unreachable
/// from every other library, the hexes in their own file so
/// `check_palette_contrast.sh`'s two-file invocation resolves, and the
/// `*/theme/*` exemption in `check_raw_values.sh` intact.
///
/// Ordered exactly as `system.html`'s `:root` orders them.
abstract final class _P {
  // --- cream family ---
  static const cream = Color(0xFFFFF8EC);
  static const creamSunk = Color(0xFFFFEEDA);
  static const creamEdge = Color(0xFFF6E3C6);
  static const paper = Color(0xFFFFFFFF);

  // --- ink family ---
  static const ink = Color(0xFF2B1B4D);
  static const inkSoft = Color(0xFF5A4A7D);
  static const inkMuted = Color(0xFF8E80AE);

  // --- hue families, each with its -deep partner ---
  static const sunshine = Color(0xFFFFC53D);
  static const sunshineDeep = Color(0xFFF2A81E);

  /// [sunshineDeep] at 50%, the ray sweep behind a header.
  ///
  /// A primitive rather than an alpha applied at the painter, because every
  /// slot binds to a named primitive and a composited colour is still a
  /// colour. `app.html`: `.hdr .rays{...var(--sunshine-deep)...;opacity:.5}`.
  static const sunshineDeepHalf = Color(0x80F2A81E);

  /// [ink] at 16%, the dot lattice behind a header.
  ///
  /// `app.html`: `.hdr .dots{opacity:.16}` over `var(--ink)`.
  static const inkHalftone = Color(0x292B1B4D);

  /// [ink] at 8%, the dot lattice inside the game hero panel.
  ///
  /// **.08, not .16, and app.html says why on the rule itself:** ink text on
  /// the accent-plus-dots composite needs 4.5:1, and the header's stronger
  /// lattice takes it below the floor.
  static const inkHalftoneSoft = Color(0x142B1B4D);
  static const coral = Color(0xFFFF6B5A);
  static const coralDeep = Color(0xFFE8452F);

  /// [coralDeep] at 45%, the ray sweep behind Stroop Rush's play band.
  ///
  /// `app.html`: `.playband .rays{opacity:.45}` over `var(--coral-deep)`.
  static const coralDeepBand = Color(0x73E8452F);
  static const turquoise = Color(0xFF22C7B8);
  static const turquoiseDeep = Color(0xFF12A79A);

  /// [turquoiseDeep] at 45%, the ray sweep behind Schulte Grid's play band.
  ///
  /// `app.html`: `.playband--schulte .rays` at `opacity:.45`.
  static const turquoiseDeepBand = Color(0x7312A79A);
  static const grape = Color(0xFF6A45E8);
  static const grapePop = Color(0xFF7C5CFF);

  /// [grapePop] at 30%, the deliberately dimmer ray sweep behind Settings.
  ///
  /// `app.html`: `.set-hdr .rays{opacity:.3}`. A ray opacity that is uniformly
  /// .5 across all three headers is the defect this separate primitive exists
  /// to make impossible.
  static const grapePopSoft = Color(0x4D7C5CFF);

  /// [grapePop] at 55%, the full-bleed burst behind the countdown.
  ///
  /// `app.html`: `.count .rays{opacity:.55}`.
  static const grapePopStrong = Color(0x8C7C5CFF);
  static const leaf = Color(0xFF4CC86A);
  static const leafDeep = Color(0xFF2FA64F);

  /// [leafDeep] at 55%, the ray sweep behind the results header.
  ///
  /// `app.html`: `.res-hdr .rays{opacity:.55}`.
  static const leafDeepStrong = Color(0x8C2FA64F);
  static const tangerine = Color(0xFFFF9330);

  static const dot = Color(0xFFF2DFC0);

  // --- gameplay tier ---
  //
  // Tuned for telling-apart-at-speed on cream, NOT for brand harmony. Never
  // wire one of these into a chrome slot BY SLOT NAME; wire the primitive, so
  // the colour-blind swap cannot reach it.
  static const playRed = Color(0xFFD81E2C);
  static const playBlue = Color(0xFF1F6BE0);
  static const playGreen = Color(0xFF157A39);
  static const playYellow = Color(0xFFF5B301);
  static const playPurple = Color(0xFF6A45E8);
  static const playOrange = Color(0xFFC24409);
  static const playPink = Color(0xFFC2185B);
}
