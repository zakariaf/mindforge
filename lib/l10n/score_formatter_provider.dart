import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindforge/core/score_formatter.dart';
import 'package:mindforge/l10n/l10n_providers.dart';

/// The active locale's score formatter.
///
/// This is the seam: `lib/core/` declares what a formatter DOES and `lib/l10n/`
/// supplies the closures that know how. Everything locale-aware lives on this
/// side of it, so `ScoreFormatter` itself stays a pure composition that a unit
/// test can build with two lambdas.
final Provider<ScoreFormatter> scoreFormatterProvider =
    Provider<ScoreFormatter>(
      (ref) {
        final numbers = LocaleNumbers(ref.watch(localeProvider));
        final l10n = ref.watch(appLocalizationsProvider);

        return ScoreFormatter(
          formatPoints: numbers.count,
          formatSeconds: numbers.seconds,
          // The unit is a separate ARB key composed here, never glued to the
          // number in a template: `18.6` and `s` are two runs, and a value
          // hand-joined to its unit is what breaks in RTL.
          durationLabel: (seconds) => '$seconds${l10n.unitSeconds}',
        );
      },
    );
