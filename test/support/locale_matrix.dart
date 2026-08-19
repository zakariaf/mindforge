import 'package:intl/intl.dart';
import 'package:mindforge/core/supported_locale.dart';

/// The four shipped locale tags, **derived** from [SupportedLocale] rather than
/// typed as a second literal.
///
/// T02.2 made `SupportedLocale` the only list of shipped locales in `lib/`, and
/// this keeps that true on the test side: there is no `kTestLocales` and no
/// `test/support/locales.dart` anywhere in the sequence. E04's widget-tier
/// `LocaleCase.all` is another projection of the same enum.
final List<String> localeMatrix = SupportedLocale.values
    .map((l) => l.tag)
    .toList();

/// Runs [body] once per shipped locale, with `Intl.defaultLocale` set to it.
///
/// The ambient locale is restored afterwards even if [body] throws, so a
/// failure in one locale cannot leak into the next test in a randomly ordered
/// suite.
Future<void> forEachLocale(
  Future<void> Function(String tag) body,
) async {
  for (final tag in localeMatrix) {
    final previous = Intl.defaultLocale;
    Intl.defaultLocale = tag;
    try {
      await body(tag);
    } finally {
      Intl.defaultLocale = previous;
    }
  }
}
