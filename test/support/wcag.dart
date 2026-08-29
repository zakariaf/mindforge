import 'dart:math' as math;
import 'dart:ui';

/// The WCAG relative luminance of [colour].
///
/// Computed over the colour **value**, deliberately, rather than through
/// `textContrastGuideline`: that matcher renders a widget and samples pixels,
/// which has a known false negative on text drawn over a patterned or partly
/// transparent background, and it cannot check a pair no screen renders yet.
///
/// **One copy, here, because three suites need it.** `contrast_test.dart` wrote
/// it first; `shell_contrast_test.dart` and then E12's False Light greyscale
/// lane each grew their own. A luminance formula transcribed three times is
/// three chances to get the 0.03928 knee or the 2.4 exponent wrong, and a wrong
/// one fails open — it reports a ratio that looks plausible.
double relativeLuminance(Color colour) {
  double channel(double component) => component <= 0.03928
      ? component / 12.92
      : math.pow((component + 0.055) / 1.055, 2.4).toDouble();

  return 0.2126 * channel(colour.r) +
      0.7152 * channel(colour.g) +
      0.0722 * channel(colour.b);
}

/// The WCAG contrast ratio between [a] and [b], from 1.0 to 21.0.
double contrastRatio(Color a, Color b) {
  final lighter = math.max(relativeLuminance(a), relativeLuminance(b));
  final darker = math.min(relativeLuminance(a), relativeLuminance(b));

  return (lighter + 0.05) / (darker + 0.05);
}
