import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindforge/core/app_settings.dart';
import 'package:mindforge/data/data_providers.dart';

/// Whether the player wants haptics.
///
/// Read through `select`, so a screen that flips the sound toggle does not
/// rebuild anything watching this one.
///
/// **There is no `FeedbackSettings` value type.** `AppSettings` is E02's, it
/// already carries all three flags, and a second type with three overlapping
/// fields under two spellings is a rename waiting to silently drop a toggle.
final Provider<bool> hapticsEnabledProvider = Provider<bool>(
  (ref) => ref.watch(_settings.select((settings) => settings.isHapticsEnabled)),
);

/// Whether the player wants sound.
final Provider<bool> soundEnabledProvider = Provider<bool>(
  (ref) => ref.watch(_settings.select((settings) => settings.isSoundEnabled)),
);

/// Whether the player has asked for reduced motion.
///
/// **Read in exactly one place**: `MotionPreferenceScope`, which folds it into
/// `MediaQuery.disableAnimations` at the root. No widget decides whether to
/// animate by reading app state — it reads the platform flag, which by then
/// carries both answers.
final Provider<bool> reduceMotionEnabledProvider = Provider<bool>(
  (ref) =>
      ref.watch(_settings.select((settings) => settings.isReduceMotionEnabled)),
);

/// The settings the gates derive from, with the seed as their pre-stream value.
///
/// The same shape `localeProvider` uses, and for the same reason: the first
/// frame must already be right. A player who turned haptics off does not want
/// one buzz on launch before the stream catches up.
final Provider<AppSettings> _settings = Provider<AppSettings>(
  (ref) =>
      ref.watch(settingsProvider).value ??
      ref.watch(initialAppSettingsProvider),
);
