import 'package:mindforge/core/result_stat.dart';
import 'package:mindforge/l10n/app_localizations.dart';
import 'package:mindforge/l10n/bidi_text.dart';
import 'package:mindforge/l10n/locale_numbers.dart';

/// How a duration is written, which is the one thing the two call sites differ
/// on.
enum DurationStyle {
  /// `0:23` — a running clock, on the HUD.
  clock,

  /// `640ms` under a second, `18.6s` above it — a measurement, on results.
  ///
  /// A reaction time is the sub-second case and `0.6s` throws away the digit
  /// that matters; a Schulte run time is the other, and `18600ms` is
  /// unreadable. The unit is an ARB string rendered as its own run, never glued
  /// to the number — a value hand-joined to its unit is what breaks in RTL.
  measured,
}

/// One canonical integer, rendered for the active locale.
///
/// **One switch over `StatFormat`, not one per screen.** The HUD and the
/// results screen each had their own, four of five arms identical, so adding
/// `StatFormat.fraction` meant writing the same
/// `BidiText.isolate(l10n.foundOfTotal(...))` body twice — which is precisely
/// the shape `arb_lookup.dart` was created to end one file earlier. The
/// duration style is the genuine difference and it is a parameter.
String statText(
  StatFormat format,
  int canonicalValue, {
  required AppLocalizations l10n,
  required LocaleNumbers numbers,
  required DurationStyle durationStyle,
  int? total,
}) => switch (format) {
  StatFormat.duration => switch (durationStyle) {
    DurationStyle.clock => numbers.clock(canonicalValue),
    DurationStyle.measured =>
      canonicalValue < Duration.millisecondsPerSecond
          ? '${numbers.count(canonicalValue)}${l10n.unitMilliseconds}'
          : '${numbers.seconds(canonicalValue)}${l10n.unitSeconds}',
  },
  StatFormat.percent => numbers.percent(canonicalValue / 1000),
  // NOT ISOLATED, and that is the whole point. The logical order is the sign
  // then the digit in every locale — one ARB message — and the bidi algorithm
  // is what puts the sign on the reading-START side: `x7` in English, `۷×` in
  // Persian, which is what the RTL reference draws. An FSI here resolves to the
  // direction of the first STRONG character, and this run has none, so it would
  // fall back to LTR and pin the sign left everywhere.
  StatFormat.multiplier => l10n.streakMultiplier(
    canonicalValue,
    numbers.count(canonicalValue),
  ),
  // ISOLATED, for the opposite reason. A fraction must keep reading
  // numerator-first in every language, and `۶ / ۲۵` inside an RTL line renders
  // as `۲۵ / ۶` without this: the spaces and the slash are neutrals that take
  // the paragraph direction.
  StatFormat.fraction => BidiText.isolate(
    l10n.foundOfTotal(numbers.count(canonicalValue), numbers.count(total ?? 0)),
  ),
  StatFormat.points || StatFormat.count => numbers.count(canonicalValue),
};
