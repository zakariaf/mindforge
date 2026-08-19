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
  static const String _firstStrongIsolate = '⁨';

  /// POP DIRECTIONAL ISOLATE.
  static const String _popDirectionalIsolate = '⁩';

  /// [text] wrapped so it cannot reorder, or be reordered by, its surroundings.
  ///
  /// Applied to any run whose script may differ from the paragraph: the
  /// wordmark, a game id, a technical reference. It is a no-op for an empty
  /// string, so a caller need not guard.
  static String isolate(String text) =>
      text.isEmpty ? text : '$_firstStrongIsolate$text$_popDirectionalIsolate';

  /// Whether [text] is already isolated, so a caller cannot double-wrap.
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
