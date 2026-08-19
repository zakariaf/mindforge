import 'dart:ui' show Locale;

import 'package:mindforge/core/supported_locale.dart';

/// The locales `MaterialApp` and the test harness both consume.
///
/// **A projection of [SupportedLocale], never a second list.** E02 made that
/// enum the only enumeration of shipped locales in the repository, and gen-l10n
/// independently derives its own list from the ARB filenames — so without this
/// projection, and the test that compares the two, the app could have two
/// different answers to "which locales ship" and neither would be wrong-looking.
///
/// **Order is load-bearing, and this is not theoretical.** Flutter's default
/// resolution falls back to `supportedLocales.first`, and gen-l10n emits its
/// list in ALPHABETICAL order — measured: `[ckb, de, en, fa]`. Handing
/// `AppLocalizations.supportedLocales` to `MaterialApp` would therefore make
/// **Kurdish Sorani** the fallback for every unsupported system locale, which
/// is a wrong-language bug nobody would see on an English device.
///
/// This list is enum order, which ADR 0002 fixes as `en` first.
final List<Locale> supportedLocales = SupportedLocale.values
    .map((locale) => Locale(locale.tag))
    .toList(growable: false);
