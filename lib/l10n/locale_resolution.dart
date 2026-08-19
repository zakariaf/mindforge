import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindforge/core/app_settings.dart';
import 'package:mindforge/core/result.dart';
import 'package:mindforge/core/supported_locale.dart';
import 'package:mindforge/data/data_failure.dart';
import 'package:mindforge/data/data_providers.dart';

/// Resolves which locale the app runs in.
///
/// One rule, applied in one place: **the user's explicit override if there is
/// one, otherwise the first system locale this build ships, otherwise `en`.**
///
/// Pure and total — it takes the system list rather than reading
/// `PlatformDispatcher`, so the whole chain is testable without a platform.
SupportedLocale resolveLocale({
  required SupportedLocale? override,
  required List<Locale> systemLocales,
}) {
  if (override != null) return override;

  for (final locale in systemLocales) {
    // Matched on the language code alone: a device set to `fa-IR` or `de-AT`
    // wants Persian or German, and refusing it because the region differs
    // would drop a user to English for no reason they could act on.
    final supported = SupportedLocale.tryParse(locale.languageCode);
    if (supported != null) return supported;
  }

  return SupportedLocale.en;
}

/// The device's preferred locales, in the order the platform ranks them.
///
/// A provider so a test can substitute a list without touching a platform
/// channel. It self-defaults, so only tests override it.
final systemLocalesProvider = Provider<List<Locale>>(
  (ref) => PlatformDispatcher.instance.locales,
);

/// The locale the app is running in, right now.
///
/// Reads the persisted override off `settingsProvider`, which E02 seeds from
/// the row `bootstrap()` read **before** `runApp` — so the very first frame is
/// already in the right language and the right direction. A Persian user's cold
/// start never paints an English LTR frame and then flips.
///
/// **Before the stream has delivered, it reads the seed directly.** That is the
/// whole point of `bootstrap()` awaiting a settings read: `settingsProvider`'s
/// first emission arrives on the microtask queue, so a `localeProvider` that
/// only watched the stream would answer `en` for the first frame and then flip
/// — reintroducing exactly the defect the seed exists to prevent. Measured: it
/// did, before this line.
///
/// If the store is unreadable the stream carries an error and the seed carries
/// `AppSettings.defaults()`, whose override is null — so resolution falls
/// through to the system rule rather than to `en`. "The store is broken" is not
/// a reason to also get the language wrong.
final localeProvider = Provider<SupportedLocale>((ref) {
  // The explicit type is load-bearing: without it the null-coalesce infers
  // AppSettings? from the left operand and the field access below is a
  // compile error.
  // ignore: omit_local_variable_types
  final AppSettings settings =
      ref.watch(settingsProvider).value ??
      ref.watch(initialAppSettingsProvider);

  return resolveLocale(
    override: settings.localeOverride,
    systemLocales: ref.watch(systemLocalesProvider),
  );
});

/// Changes the persisted locale override, or clears it.
///
/// The **only** write path for the language choice. It goes through
/// `SettingsRepository`, so the value is durable before `localeProvider`
/// re-emits — persist-before-publish, exactly like every other setting.
///
/// `null` clears the override and returns the app to following the system.
final localeControllerProvider = Provider<LocaleController>(
  LocaleController.new,
);

/// Writes the language choice.
final class LocaleController {
  /// Creates the controller over [_ref].
  const LocaleController(this._ref);

  final Ref _ref;

  /// Sets the override to [locale], or clears it when [locale] is `null`.
  ///
  /// Returns the failure rather than throwing, so a Settings row can report a
  /// write that did not land instead of silently showing the new language and
  /// forgetting it on relaunch.
  Future<Result<AppSettings, DataFailure>> setLocale(
    SupportedLocale? locale,
  ) async {
    final current = await _ref.read(settingsRepositoryProvider).read();

    return current.fold(
      onOk: (settings) => _ref
          .read(settingsRepositoryProvider)
          .update(
            locale == null
                ? settings.withSystemLocale()
                : settings.withLocaleOverride(locale),
          ),
      onErr: Err<AppSettings, DataFailure>.new,
    );
  }
}
