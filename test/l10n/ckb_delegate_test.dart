import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/supported_locale.dart';
import 'package:mindforge/l10n/app_localizations.dart';
import 'package:mindforge/l10n/ckb_localizations.dart';

import '../policy/support/source_text.dart';
import '../support/harness.dart';
import '../support/locale_cases.dart';

/// The vendored `ckb` delegate trio: that it is needed, that it works, and
/// that it claims nothing it should not.
///
/// **The SDK measurements that justify it live in
/// `material_delegate_support_test.dart`** — that file is the characterization
/// owner, and stating "82 codes, no ckb" in two places means two places to
/// update the day Flutter adds Sorani. This file asserts the behaviour of the
/// code written in response.
void main() {
  group('every supported locale mounts and reads the right way', () {
    for (final localeCase in LocaleCase.all) {
      testWidgets('${localeCase.tag} mounts and resolves its direction', (
        tester,
      ) async {
        // pumpLocalized uses the REAL delegate list and asserts the resolved
        // direction internally, so this test is the mounting half; the
        // direction half is the harness refusing to return.
        await tester.pumpLocalized(
          Builder(
            builder: (context) {
              // Reading it is what asserts when the delegate is missing. A
              // bare Scaffold never touches MaterialLocalizations, so a test
              // that pumps one proves nothing.
              MaterialLocalizations.of(context);
              CupertinoLocalizations.of(context);
              return const Scaffold();
            },
          ),
          localeCase,
        );

        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Material and Cupertino chrome under ckb', () {
    testWidgets('carries the fa strings, proving the delegation target', (
      tester,
    ) async {
      Future<(MaterialLocalizations, CupertinoLocalizations)> read(
        SupportedLocale locale,
      ) => tester.readInLocale(
        LocaleCase(locale),
        (context) => (
          MaterialLocalizations.of(context),
          CupertinoLocalizations.of(context),
        ),
      );

      final (ckbMaterial, ckbCupertino) = await read(SupportedLocale.ckb);
      final (faMaterial, faCupertino) = await read(SupportedLocale.fa);

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

      expect(
        delegates.indexWhere((d) => d is CkbMaterialLocalizationsDelegate),
        allOf(
          greaterThanOrEqualTo(0),
          lessThan(
            delegates.indexWhere(
              (d) => identical(d, GlobalMaterialLocalizations.delegate),
            ),
          ),
        ),
      );
      expect(
        delegates.indexWhere((d) => d is CkbWidgetsLocalizationsDelegate),
        lessThan(
          delegates.indexWhere(
            (d) => identical(d, GlobalWidgetsLocalizations.delegate),
          ),
        ),
      );
    });
  });

  group('the app wires them', () {
    test('lib/app.dart builds its list through localizationsDelegatesFor', () {
      expect(
        withoutDartComments(File('lib/app.dart').readAsStringSync()),
        contains('localizationsDelegatesFor('),
        reason:
            'handing MaterialApp AppLocalizations.localizationsDelegates '
            'directly is exactly the bug this file exists to prevent',
      );
    });
  });
}
