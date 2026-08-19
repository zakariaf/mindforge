import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/supported_locale.dart';

void main() {
  group('SupportedLocale', () {
    test('the shipped set is exactly en, de, fa, ckb in that order', () {
      // A frozen literal: adding or removing a locale must be a deliberate
      // edit to this list, in a PR that also updates CFBundleLocalizations,
      // ADR 0001 and the ARB directory.
      expect(
        SupportedLocale.values.map((l) => l.tag).toList(),
        ['en', 'de', 'fa', 'ckb'],
      );
    });

    test('tryParse accepts exactly the shipped tags', () {
      expect(SupportedLocale.tryParse('en'), SupportedLocale.en);
      expect(SupportedLocale.tryParse('de'), SupportedLocale.de);
      expect(SupportedLocale.tryParse('fa'), SupportedLocale.fa);
      expect(SupportedLocale.tryParse('ckb'), SupportedLocale.ckb);
    });

    test('tryParse is exact, total and never throws', () {
      for (final tag in <String>[
        'ar',
        'EN',
        'fa-IR',
        '',
        '۱۲',
        'en_US',
        ' en',
      ]) {
        expect(
          SupportedLocale.tryParse(tag),
          isNull,
          reason:
              'the parse is exact — $tag is not a shipped tag. A near miss '
              'that resolved would silently give a user the wrong language',
        );
      }
    });

    test('exactly fa and ckb are right-to-left', () {
      expect(SupportedLocale.en.isRightToLeft, isFalse);
      expect(SupportedLocale.de.isRightToLeft, isFalse);
      expect(SupportedLocale.fa.isRightToLeft, isTrue);
      expect(SupportedLocale.ckb.isRightToLeft, isTrue);
    });
  });
}
