import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/l10n/app_localizations.dart';
import 'package:mindforge/l10n/ckb_localizations.dart';
import 'package:mindforge/l10n/supported_locales.dart';

/// Pumps [child] with the **real** delegate list the app ships.
Future<void> pumpWithAppDelegates(
  WidgetTester tester,
  Locale locale,
  Widget child, {
  List<LocalizationsDelegate<dynamic>>? delegates,
}) => tester.pumpWidget(
  MaterialApp(
    locale: locale,
    supportedLocales: supportedLocales,
    localizationsDelegates:
        delegates ??
        localizationsDelegatesFor(AppLocalizations.localizationsDelegates),
    home: child,
  ),
);

void main() {
  group('the SDK gap this file exists for is still real', () {
    // THE VERIFICATION, not the assumption. If a future Flutter adds ckb these
    // go red, and someone deletes the vendored delegates deliberately instead
    // of shipping dead code forever.
    test('kMaterialSupportedLanguages has 82 codes and no ckb or ku', () {
      expect(kMaterialSupportedLanguages, hasLength(82));
      expect(kMaterialSupportedLanguages, isNot(contains('ckb')));
      expect(kMaterialSupportedLanguages, isNot(contains('ku')));
    });

    test('no Global delegate supports ckb, and all three support fa', () {
      const delegates = <String, LocalizationsDelegate<dynamic>>{
        'material': GlobalMaterialLocalizations.delegate,
        'cupertino': GlobalCupertinoLocalizations.delegate,
        'widgets': GlobalWidgetsLocalizations.delegate,
      };

      for (final entry in delegates.entries) {
        expect(
          entry.value.isSupported(const Locale('ckb')),
          isFalse,
          reason: '${entry.key} unexpectedly gained ckb',
        );
        expect(
          entry.value.isSupported(const Locale('fa')),
          isTrue,
          reason: '${entry.key} lost fa, which is the delegation target',
        );
      }
    });
  });

  group('every supported locale mounts', () {
    for (final locale in supportedLocales) {
      testWidgets('${locale.languageCode} mounts without throwing', (
        tester,
      ) async {
        await pumpWithAppDelegates(
          tester,
          locale,
          Builder(
            builder: (context) {
              // Reading it is what asserts when the delegate is missing; a bare
              // Scaffold never touches MaterialLocalizations.
              MaterialLocalizations.of(context);
              return const Scaffold();
            },
          ),
        );

        expect(tester.takeException(), isNull);
      });
    }
  });

  group('direction follows the locale', () {
    testWidgets('ltr, ltr, rtl, rtl for en, de, fa, ckb', (tester) async {
      const expected = <String, TextDirection>{
        'en': TextDirection.ltr,
        'de': TextDirection.ltr,
        'fa': TextDirection.rtl,
        'ckb': TextDirection.rtl,
      };

      for (final entry in expected.entries) {
        late TextDirection resolved;

        await pumpWithAppDelegates(
          tester,
          Locale(entry.key),
          Builder(
            builder: (context) {
              resolved = Directionality.of(context);
              return const SizedBox.shrink();
            },
          ),
        );

        expect(
          resolved,
          entry.value,
          reason:
              'under ckb WITHOUT the vendored widgets delegate this is '
              'ltr — the silent half of the bug, and the one no crash report '
              'would surface',
        );
      }
    });
  });

  group('Material and Cupertino chrome have real strings under ckb', () {
    testWidgets('and they equal the fa values, proving the delegation target', (
      tester,
    ) async {
      Future<(MaterialLocalizations, CupertinoLocalizations)> read(
        String tag,
      ) async {
        late MaterialLocalizations material;
        late CupertinoLocalizations cupertino;

        await pumpWithAppDelegates(
          tester,
          Locale(tag),
          Builder(
            builder: (context) {
              material = MaterialLocalizations.of(context);
              cupertino = CupertinoLocalizations.of(context);
              return const SizedBox.shrink();
            },
          ),
        );
        return (material, cupertino);
      }

      final (ckbMaterial, ckbCupertino) = await read('ckb');
      final (faMaterial, faCupertino) = await read('fa');

      for (final pair in <(String, String, String)>[
        (
          'backButtonTooltip',
          ckbMaterial.backButtonTooltip,
          faMaterial.backButtonTooltip,
        ),
        (
          'closeButtonTooltip',
          ckbMaterial.closeButtonTooltip,
          faMaterial.closeButtonTooltip,
        ),
        ('okButtonLabel', ckbMaterial.okButtonLabel, faMaterial.okButtonLabel),
        (
          'cancelButtonLabel',
          ckbMaterial.cancelButtonLabel,
          faMaterial.cancelButtonLabel,
        ),
        (
          'alertDialogLabel',
          ckbCupertino.alertDialogLabel,
          faCupertino.alertDialogLabel,
        ),
      ]) {
        final (name, ckbValue, faValue) = pair;

        expect(ckbValue, isNotEmpty, reason: '$name is empty under ckb');
        expect(
          ckbValue,
          faValue,
          reason:
              '$name proves the DELEGATION TARGET, not merely the absence '
              'of a crash',
        );
      }
    });
  });

  group('the vendored delegates claim only ckb', () {
    test('so the built-ins keep winning for the locales they cover', () {
      const vendored = <LocalizationsDelegate<dynamic>>[
        CkbMaterialLocalizationsDelegate(),
        CkbCupertinoLocalizationsDelegate(),
        CkbWidgetsLocalizationsDelegate(),
      ];

      for (final delegate in vendored) {
        expect(delegate.isSupported(const Locale('ckb')), isTrue);

        for (final other in <String>['en', 'de', 'fa', 'ar']) {
          expect(
            delegate.isSupported(Locale(other)),
            isFalse,
            reason:
                'the FIRST delegate of a type wins, so one that '
                'over-claimed would hijack $other from the built-in that '
                'actually has $other strings',
          );
        }
      }
    });

    test('and they are listed before the Global ones', () {
      // Ordering IS the mechanism, so it is asserted on the real list rather
      // than eyeballed in app.dart.
      final delegates = localizationsDelegatesFor(
        AppLocalizations.localizationsDelegates,
      );

      int indexOfType(bool Function(LocalizationsDelegate<dynamic>) match) =>
          delegates.indexWhere(match);

      final vendoredMaterial = indexOfType(
        (d) => d is CkbMaterialLocalizationsDelegate,
      );
      final globalMaterial = indexOfType(
        (d) => identical(d, GlobalMaterialLocalizations.delegate),
      );

      expect(vendoredMaterial, greaterThanOrEqualTo(0));
      expect(globalMaterial, greaterThan(vendoredMaterial));

      final vendoredWidgets = indexOfType(
        (d) => d is CkbWidgetsLocalizationsDelegate,
      );
      final globalWidgets = indexOfType(
        (d) => identical(d, GlobalWidgetsLocalizations.delegate),
      );

      expect(globalWidgets, greaterThan(vendoredWidgets));
    });
  });

  group('the app wires them', () {
    test('lib/app.dart builds its list through localizationsDelegatesFor', () {
      expect(
        File('lib/app.dart').readAsStringSync(),
        contains('localizationsDelegatesFor('),
        reason:
            'handing MaterialApp AppLocalizations.localizationsDelegates '
            'directly is exactly the bug this file exists to prevent',
      );
    });
  });
}
