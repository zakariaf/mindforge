import 'package:meta/meta.dart';
import 'package:mindforge/core/supported_locale.dart';

/// The user's preferences, as one immutable value.
///
/// There is no in-memory settings notifier anywhere in the app: the database
/// row is the only authority, `SettingsRepository` is the only write path, and
/// `settingsProvider` is a stream over it. A cached copy would be a second
/// authority that a failed write silently desynchronises.
@immutable
final class AppSettings {
  /// Creates a settings value.
  const AppSettings({
    required this.isSoundEnabled,
    required this.isHapticsEnabled,
    required this.isReduceMotionEnabled,
    required this.isColourBlindPalette,
    required this.localeOverride,
  });

  /// The state a freshly installed app starts in, matching the toggle positions
  /// drawn on `design/sunburst-pop/screens/08-settings.png`.
  ///
  /// Also the fallback when the settings row cannot be read at all, so a broken
  /// store still boots.
  const AppSettings.defaults()
    : isSoundEnabled = true,
      isHapticsEnabled = true,
      isReduceMotionEnabled = false,
      isColourBlindPalette = false,
      localeOverride = null;

  /// Whether sound effects play.
  final bool isSoundEnabled;

  /// Whether haptics fire.
  final bool isHapticsEnabled;

  /// Whether motion is reduced.
  ///
  /// This is the app's own toggle, independent of the OS accessibility setting;
  /// either one turning motion off is enough. Reduced motion collapses
  /// durations to `Duration.zero`, never to shorter ones.
  final bool isReduceMotionEnabled;

  /// Whether the colour-blind-safe answer palette is in use.
  ///
  /// It re-points gameplay answer slots only. UI colours are a separate tier and
  /// never move with it.
  final bool isColourBlindPalette;

  /// The locale the user explicitly chose, or `null` to **follow the system
  /// locale**.
  ///
  /// `null` does not mean English. English is what the resolver falls back to
  /// when the system locale is not one of the four shipped ones, which is a
  /// different decision made in a different place.
  final SupportedLocale? localeOverride;

  /// A copy with any of the four **toggles** changed.
  ///
  /// There is deliberately no `localeOverride` parameter: a nullable field in a
  /// `copyWith` cannot express "set this to null" without a sentinel, so passing
  /// `null` would be indistinguishable from omitting it — and omitting it is by
  /// far the common case. Clearing the override goes through [withSystemLocale],
  /// which says what it does.
  AppSettings copyWith({
    bool? isSoundEnabled,
    bool? isHapticsEnabled,
    bool? isReduceMotionEnabled,
    bool? isColourBlindPalette,
  }) => AppSettings(
    isSoundEnabled: isSoundEnabled ?? this.isSoundEnabled,
    isHapticsEnabled: isHapticsEnabled ?? this.isHapticsEnabled,
    isReduceMotionEnabled: isReduceMotionEnabled ?? this.isReduceMotionEnabled,
    isColourBlindPalette: isColourBlindPalette ?? this.isColourBlindPalette,
    localeOverride: localeOverride,
  );

  /// A copy whose [localeOverride] is [locale].
  AppSettings withLocaleOverride(SupportedLocale locale) => AppSettings(
    isSoundEnabled: isSoundEnabled,
    isHapticsEnabled: isHapticsEnabled,
    isReduceMotionEnabled: isReduceMotionEnabled,
    isColourBlindPalette: isColourBlindPalette,
    localeOverride: locale,
  );

  /// A copy with no [localeOverride], i.e. following the system locale again.
  AppSettings withSystemLocale() => AppSettings(
    isSoundEnabled: isSoundEnabled,
    isHapticsEnabled: isHapticsEnabled,
    isReduceMotionEnabled: isReduceMotionEnabled,
    isColourBlindPalette: isColourBlindPalette,
    localeOverride: null,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettings &&
          other.isSoundEnabled == isSoundEnabled &&
          other.isHapticsEnabled == isHapticsEnabled &&
          other.isReduceMotionEnabled == isReduceMotionEnabled &&
          other.isColourBlindPalette == isColourBlindPalette &&
          other.localeOverride == localeOverride;

  @override
  int get hashCode => Object.hash(
    isSoundEnabled,
    isHapticsEnabled,
    isReduceMotionEnabled,
    isColourBlindPalette,
    localeOverride,
  );

  @override
  String toString() =>
      'AppSettings(sound: $isSoundEnabled, '
      'haptics: $isHapticsEnabled, reduceMotion: $isReduceMotionEnabled, '
      'colourBlind: $isColourBlindPalette, locale: ${localeOverride?.tag})';
}
