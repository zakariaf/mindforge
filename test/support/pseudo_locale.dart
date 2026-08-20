/// A **test-only** string expander, for finding a truncation German has not
/// reached yet.
///
/// It is deliberately not an ARB. An `app_en_XA.arb` would fail
/// `check_arb_parity.sh`, put a fake language into `supportedLocales`, and ship
/// it — a pseudo-locale is a measuring instrument, not a translation.
///
/// The rule is the conventional one: stretch the string so it is materially
/// longer than any real translation is likely to be, and bracket it so a
/// missing expansion (a hardcoded English string that never went through the
/// ARB) is visible on sight.
abstract final class PseudoLocale {
  /// Roughly how much longer the expanded string is than the original.
  ///
  /// 1.4 is the usual planning figure for English into German, and Persian and
  /// Sorani run near it. Expanding beyond a real translation's worst case is
  /// the point: this lane fails first, in a test, rather than in a screenshot.
  static const double expansionFactor = 1.4;

  /// The characters padding is drawn from.
  ///
  /// Latin with diacritics, so the padded string still shapes and measures like
  /// real text rather than like a run of one repeated glyph, and so a face with
  /// a thin Latin-1 Supplement shows up as tofu here.
  static const String _padding = 'áéíóúàèìòùâêîôûäëïöüçñãõåø';

  /// [input], stretched to [expansionFactor] of its length and bracketed.
  ///
  /// Bracketing is unconditional, including for the empty string: a label that
  /// renders as `[]` is a key with no value, which is worth seeing.
  static String expand(String input) {
    final target = (input.length * expansionFactor).ceil();
    final buffer = StringBuffer('[')..write(input);

    for (var i = input.length; i < target; i++) {
      buffer.write(_padding[i % _padding.length]);
    }

    return (buffer..write(']')).toString();
  }
}
