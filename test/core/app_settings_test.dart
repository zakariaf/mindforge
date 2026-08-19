import 'dart:io';

import 'package:mindforge/core/app_settings.dart';
import 'package:mindforge/core/supported_locale.dart';
import 'package:test/test.dart';

void main() {
  group('AppSettings', () {
    test('the const defaults match screen 08', () {
      const settings = AppSettings.defaults();

      expect(settings.isSoundEnabled, isTrue);
      expect(settings.isHapticsEnabled, isTrue);
      expect(settings.isReduceMotionEnabled, isFalse);
      expect(settings.isColourBlindPalette, isFalse);
      expect(
        settings.localeOverride,
        isNull,
        reason: 'null means FOLLOW THE SYSTEM LOCALE. It does not mean English',
      );
    });

    test('copyWith flips one toggle and leaves the rest, locale included', () {
      const settings = AppSettings.defaults();

      final quiet = settings.copyWith(isSoundEnabled: false);

      expect(quiet.isSoundEnabled, isFalse);
      expect(quiet.isHapticsEnabled, isTrue);
      expect(quiet.isReduceMotionEnabled, isFalse);
      expect(quiet.isColourBlindPalette, isFalse);
      expect(quiet.localeOverride, isNull);
    });

    test('withLocaleOverride sets it and withSystemLocale clears it', () {
      const settings = AppSettings.defaults();

      final sorani = settings.withLocaleOverride(SupportedLocale.ckb);
      expect(sorani.localeOverride, SupportedLocale.ckb);
      expect(sorani.isSoundEnabled, isTrue);

      expect(sorani.withSystemLocale().localeOverride, isNull);
    });

    test('copyWith offers no locale parameter at all', () {
      // A nullable copyWith field cannot express "set this to null" without a
      // sentinel, so the type does not offer the broken option — clearing goes
      // through withSystemLocale(). Asserted over the source because the
      // property being protected is that nobody may ADD the parameter.
      final source = File('lib/core/app_settings.dart').readAsStringSync();
      final copyWithBody = source.substring(
        source.indexOf('AppSettings copyWith'),
      );

      expect(
        copyWithBody.substring(0, copyWithBody.indexOf('}')),
        isNot(contains('localeOverride')),
        reason:
            'make illegal states unrepresentable: copyWith(localeOverride: '
            'null) would be indistinguishable from omitting it',
      );
    });

    test('value equality covers every field', () {
      const a = AppSettings.defaults();

      expect(a, const AppSettings.defaults());
      expect(a, isNot(a.copyWith(isHapticsEnabled: false)));
      expect(a, isNot(a.withLocaleOverride(SupportedLocale.fa)));
      expect(a.hashCode, const AppSettings.defaults().hashCode);
    });
  });
}
