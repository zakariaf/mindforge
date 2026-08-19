import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// The locales `flutter_localizations` actually ships Material and Cupertino
/// strings for that are nearest to Kurdish Sorani.
///
/// Persian first — same script, same numerals, closest vocabulary — then
/// Arabic.
///
/// **Measured on Flutter 3.44.6**: `kMaterialSupportedLanguages` holds 82
/// language codes and contains neither `ckb` nor `ku`.
/// `test/l10n/ckb_delegate_test.dart` re-asserts that on every run, so this
/// whole file becomes a deliberate deletion the day the SDK covers Sorani —
/// rather than dead code nobody dares remove.
const List<Locale> _scriptNeighbours = <Locale>[Locale('fa'), Locale('ar')];

Locale _resolveNeighbour(LocalizationsDelegate<dynamic> delegate) {
  for (final neighbour in _scriptNeighbours) {
    if (delegate.isSupported(neighbour)) return neighbour;
  }
  // Unreachable while flutter_localizations ships fa and ar, and asserted in
  // the test. If it ever is reached, English chrome in an RTL app is a visible
  // bug rather than a crash, which is the right failure of the two.
  return const Locale('en');
}

/// Serves `MaterialLocalizations` for `ckb` by delegating to its nearest
/// script neighbour.
///
/// Without it, `Localizations._loadAll` filters every Material delegate out
/// under `ckb` and any `Tooltip`, `SnackBar` or `AppBar` back button asserts —
/// a crash, in one locale, that an English test run never sees.
class CkbMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  /// Creates the delegate.
  const CkbMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ckb';

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      GlobalMaterialLocalizations.delegate.load(
        _resolveNeighbour(GlobalMaterialLocalizations.delegate),
      );

  @override
  bool shouldReload(CkbMaterialLocalizationsDelegate old) => false;
}

/// Serves `CupertinoLocalizations` for `ckb`, the same way.
class CkbCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  /// Creates the delegate.
  const CkbCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ckb';

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      GlobalCupertinoLocalizations.delegate.load(
        _resolveNeighbour(GlobalCupertinoLocalizations.delegate),
      );

  @override
  bool shouldReload(CkbCupertinoLocalizationsDelegate old) => false;
}

/// Supplies `WidgetsLocalizations` — and therefore the ambient
/// `TextDirection` — for `ckb`.
///
/// **It cannot be omitted.** `_WidgetsLocalizationsDelegate.isSupported`
/// returns `true` for **every** locale — measured, including the nonsense code
/// `zz` — and `DefaultWidgetsLocalizations.textDirection` is hardcoded
/// `TextDirection.ltr`. So a build that vendors only the Material half runs
/// fine and **reads backwards**: the silent half of the same bug, and the one
/// no crash report would ever surface.
///
/// It delegates like the other two rather than hand-rolling a direction,
/// because `GlobalWidgetsLocalizations` derives direction from the locale and
/// the neighbour is Persian — so the neighbour already reports `rtl`, and its
/// reorder strings arrive in a script a Sorani reader can read. Hand-writing a
/// direction here would be a second place the answer lives.
class CkbWidgetsLocalizationsDelegate
    extends LocalizationsDelegate<WidgetsLocalizations> {
  /// Creates the delegate.
  const CkbWidgetsLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ckb';

  @override
  Future<WidgetsLocalizations> load(Locale locale) =>
      GlobalWidgetsLocalizations.delegate.load(
        _resolveNeighbour(GlobalWidgetsLocalizations.delegate),
      );

  @override
  bool shouldReload(CkbWidgetsLocalizationsDelegate old) => false;
}

/// The delegate list `MaterialApp` is handed.
///
/// **Order is the mechanism.** `Localizations._loadAll` takes the **first**
/// delegate of a type that reports the locale supported, so the vendored `ckb`
/// delegates must come before the `Global*` ones. They claim only `ckb` — a
/// delegate that over-claimed would hijack Persian from the built-in that
/// actually has Persian strings — and `ckb_delegate_test.dart` asserts both the
/// narrow claim and the ordering.
///
/// `MaterialApp` appends its own English/LTR defaults **after** whatever it is
/// given, so anything reaching them is a locale nobody wired.
///
/// [appDelegates] is `AppLocalizations.localizationsDelegates`, which **already
/// contains the three `Global*` delegates** — measured, gen-l10n emits them.
/// They are stripped out and re-added at the end rather than spread as-is,
/// because spreading would put them ahead of the vendored ones. That happens to
/// work today only because they decline `ckb`, and "it works because the wrong
/// delegate says no" is not an ordering guarantee.
List<LocalizationsDelegate<dynamic>> localizationsDelegatesFor(
  Iterable<LocalizationsDelegate<dynamic>> appDelegates,
) {
  const globals = <LocalizationsDelegate<dynamic>>[
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  return <LocalizationsDelegate<dynamic>>[
    ...appDelegates.where(
      (delegate) => !globals.any((global) => identical(global, delegate)),
    ),
    const CkbWidgetsLocalizationsDelegate(),
    const CkbMaterialLocalizationsDelegate(),
    const CkbCupertinoLocalizationsDelegate(),
    ...globals,
  ];
}
