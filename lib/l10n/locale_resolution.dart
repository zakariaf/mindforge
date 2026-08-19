import 'dart:ui' show Locale;

import 'package:flutter/widgets.dart'
    show WidgetsBinding, WidgetsBindingObserver;

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
/// A `Notifier` and not a plain `Provider`, because the list **changes**: iOS
/// and Android both deliver `didChangeLocales` when the user switches system
/// language, and `MindForgeApp` passes an explicit `locale:` so Flutter's own
/// re-resolution is bypassed. A snapshot taken at first read left a user who
/// had set no override in the old language until a cold start — measured.
///
/// A test substitutes a list by overriding this provider; it never touches a
/// platform channel.
final NotifierProvider<SystemLocales, List<Locale>> systemLocalesProvider =
    NotifierProvider<SystemLocales, List<Locale>>(SystemLocales.new);

/// Watches the platform's locale list and republishes it when it changes.
///
/// `base` rather than `final`: a test substitutes a fixed list by extending it,
/// because a pure-Dart test has no `PlatformDispatcher` and no binding to
/// observe. `base` keeps the hierarchy closed to anything that is not itself
/// `base`, `final` or `sealed`, so the substitution stays deliberate.
base class SystemLocales extends Notifier<List<Locale>>
    with WidgetsBindingObserver {
  @override
  List<Locale> build() {
    final binding = WidgetsBinding.instance..addObserver(this);
    ref.onDispose(() => binding.removeObserver(this));

    return _current;
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    // The argument may be null on some platforms; the dispatcher is the source
    // of truth either way.
    state = _current;
  }

  /// Read through the BINDING's dispatcher, not `PlatformDispatcher.instance`.
  ///
  /// They are the same object in the app and different objects under
  /// `flutter_test`, where the binding's is a `TestPlatformDispatcher` that
  /// honours `localesTestValue`. Reading the static one made this notifier
  /// untestable — the test set a locale and the code never saw it.
  List<Locale> get _current =>
      WidgetsBinding.instance.platformDispatcher.locales;
}

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
/// **If the store stops answering, the language does not change.** Riverpod
/// retains the last data value across a stream error, so `.value` keeps
/// returning the settings that were last read successfully and the user stays
/// in the language they chose. Only when nothing has ever been read — the true
/// first frame — does the `??` fall through to the seed, and only when that
/// carries no override does resolution reach the system rule. "The store is
/// broken" is not a reason to also get the language wrong, and it is not a
/// reason to change it either.
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
  /// One transaction, not a read then a write. `update` writes the whole
  /// settings row, so a read-modify-write outside the transaction loses
  /// whichever *other* field a concurrent setter changed in between — and both
  /// callers would get an `Ok`. E08 puts the language row and four toggles on
  /// one screen, which is exactly where that happens.
  Future<Result<AppSettings, DataFailure>> setLocale(SupportedLocale? locale) =>
      _ref
          .read(settingsRepositoryProvider)
          .mutate(
            (current) => locale == null
                ? current.withSystemLocale()
                : current.withLocaleOverride(locale),
          );
}
