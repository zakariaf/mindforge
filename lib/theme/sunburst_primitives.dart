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
  static const coral = Color(0xFFFF6B5A);
  static const coralDeep = Color(0xFFE8452F);
  static const turquoise = Color(0xFF22C7B8);
  static const turquoiseDeep = Color(0xFF12A79A);
  static const grape = Color(0xFF6A45E8);
  static const grapePop = Color(0xFF7C5CFF);
  static const leaf = Color(0xFF4CC86A);
  static const leafDeep = Color(0xFF2FA64F);
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
