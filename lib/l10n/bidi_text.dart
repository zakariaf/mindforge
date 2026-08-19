/// Unicode bidi isolation for a run of text whose direction differs from the
/// paragraph around it.
///
/// The problem this solves is specific and easy to dismiss until it is seen:
/// inside RTL copy, a Latin run — `MindForge`, `N-Back`, a version string — is
/// laid out by the Unicode bidi algorithm using the surrounding context, and
/// adjacent punctuation gets pulled to the wrong side. `MindForge.` becomes
/// `.MindForge`, and a parenthesised run has its brackets swapped.
///
/// FSI/PDI rather than LRM/RLM: the isolate characters bound the run's
/// influence in **both** directions, so neither the run nor the text around it
/// can reorder the other. The marks only nudge a single boundary.
abstract final class BidiText {
  /// FIRST STRONG ISOLATE — direction inferred from the run's own first strong
  /// character, which is what makes one helper serve both scripts.
  // Written as an escape, not as the literal character. The analyzer's
  // text_direction_code_point_in_literal is right: an invisible bidi control
  // in source changes how the surrounding code READS to a human while meaning
  // something else to the compiler, which is a review hazard in exactly the
  // file that exists to handle bidi.
  static const String _firstStrongIsolate = '\u2068';

  /// POP DIRECTIONAL ISOLATE.
  static const String _popDirectionalIsolate = '\u2069';

  /// [text] wrapped so it cannot reorder, or be reordered by, its surroundings.
  ///
  /// Applied to any run whose script may differ from the paragraph: the
  /// wordmark, a game id, a technical reference.
  ///
  /// A no-op for an empty string and for one that is **already** isolated, so
  /// neither a caller nor two layers of callers need to guard. Double-wrapping
  /// is invisible on screen and survives into any value built from the result.
  static String isolate(String text) => text.isEmpty || isIsolated(text)
      ? text
      : '$_firstStrongIsolate$text$_popDirectionalIsolate';

  /// Whether [text] is already isolated, so [isolate] cannot double-wrap.
  static bool isIsolated(String text) =>
      text.startsWith(_firstStrongIsolate) &&
      text.endsWith(_popDirectionalIsolate);

  /// [text] with any isolation removed.
  ///
  /// **Normalise through this before any comparison or write.** An isolated
  /// string is a *rendering*, and storing one would put invisible control
  /// characters in a database column that every later read has to strip.
  static String strip(String text) => text
      .replaceAll(_firstStrongIsolate, '')
      .replaceAll(_popDirectionalIsolate, '');
}
