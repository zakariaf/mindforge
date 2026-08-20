import 'package:flutter/material.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_motion.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/theme/sunburst_type.dart';

/// The Material `ColorScheme`, hand-authored from the Sunburst slots.
///
/// **Never `ColorScheme.fromSeed`.** A seed derives roughly forty roles from
/// one hue, and every one of them would be a colour nobody in this system
/// measured or declared a contrast floor for.
///
/// The M3 role names are kept so Material's own widgets — `TextField`,
/// `SnackBar`, `Dialog` — theme themselves without per-widget patching.
ColorScheme _sunburstColorScheme(SunburstColors colours) => ColorScheme(
  brightness: Brightness.light,
  primary: colours.accent,
  onPrimary: colours.textPrimary,
  secondary: colours.accentAlt,
  onSecondary: colours.textInvert,
  tertiary: colours.success,
  onTertiary: colours.textPrimary,
  error: colours.danger,
  onError: colours.surfaceRaised,
  surface: colours.surface,
  onSurface: colours.textPrimary,
  surfaceContainerLowest: colours.surfaceRaised,
  surfaceContainerLow: colours.surfaceRaised,
  surfaceContainer: colours.surfaceSunk,
  surfaceContainerHigh: colours.surfaceSunk,
  surfaceContainerHighest: colours.surfaceSunk,
  onSurfaceVariant: colours.textSecondary,
  outline: colours.border,
  outlineVariant: colours.border,
  inverseSurface: colours.surfaceInvert,
  onInverseSurface: colours.textInvert,
  shadow: colours.border,
  scrim: colours.border,
  // M3's elevation tint would wash a translucent primary over cream and paper.
  // This system expresses elevation as an ink rectangle at zero blur, so the
  // tint must be nothing at all rather than merely subtle.
  surfaceTint: Colors.transparent,
);

/// The one `ThemeData` MindForge ships.
///
/// **Light only.** There is no `darkTheme`, no `themeMode` and no
/// `Brightness.dark` scheme anywhere: adding a dark mode is a new design
/// direction, not a token flip (`CLAUDE.md` working agreement 1).
///
/// All four extensions are attached here, which is what makes every
/// `Sunburst*.of(context)` resolve. Their asserting accessors are the reason a
/// screen built outside this theme fails loudly rather than rendering a
/// fallback palette no golden has ever seen.
ThemeData buildSunburstTheme({
  SunburstColors colours = SunburstColors.sunburstPop,
  SunburstShape shape = SunburstShape.sunburstPop,
  SunburstMotion motion = SunburstMotion.sunburstPop,
  SunburstType type = SunburstType.sunburstPop,
}) {
  final scheme = _sunburstColorScheme(colours);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: colours.surface,
    // Material's own ripple and highlight are the wrong feedback language here:
    // Sunburst Pop acknowledges a press by translating the surface down onto
    // its shadow, which E05's PopSurface owns. A ripple on top of that reads as
    // two different systems arguing.
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    extensions: <ThemeExtension<dynamic>>[colours, shape, motion, type],
  );
}
