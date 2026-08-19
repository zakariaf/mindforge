import 'dart:ui' show Locale;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindforge/l10n/app_localizations.dart';
import 'package:mindforge/l10n/locale_numbers.dart';
import 'package:mindforge/l10n/locale_resolution.dart';

export 'package:mindforge/l10n/locale_numbers.dart' show LocaleNumbers;
export 'package:mindforge/l10n/locale_resolution.dart'
    show LocaleController, localeControllerProvider, localeProvider;

/// The [AppLocalizations] for the active locale, reachable without a
/// `BuildContext`.
///
/// E07's `BoardSnapshot` projection and E10's Schulte painter run outside the
/// widget tree and cannot call `AppLocalizations.of(context)`. They read this
/// instead, so there is still exactly one string source and one locale
/// authority in the app.
///
/// A widget that **has** a `BuildContext` keeps using
/// `AppLocalizations.of(context)`: this is for the code that genuinely cannot,
/// not a second way of doing the same thing.
///
/// It is a `Provider` and not a `Notifier` because it holds nothing —
/// it is a derivation of [localeProvider], which is itself a derivation of the
/// persisted settings row. Derive, do not store.
final Provider<AppLocalizations> appLocalizationsProvider =
    Provider<AppLocalizations>(
      (ref) => lookupAppLocalizations(Locale(ref.watch(localeProvider).tag)),
    );

/// The [LocaleNumbers] for the active locale, reachable without a
/// `BuildContext`.
///
/// The number half of [appLocalizationsProvider], for the same callers and the
/// same reason. `LocaleNumbers` is a value type, so this rebuilds to an equal
/// instance when the locale has not changed and watchers do not churn.
final Provider<LocaleNumbers> localeNumbersProvider = Provider<LocaleNumbers>(
  (ref) => LocaleNumbers(ref.watch(localeProvider)),
);
