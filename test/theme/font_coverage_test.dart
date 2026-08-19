import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/theme/font_licences.dart';

import '../support/font_tables.dart';

/// Which bundled family must be able to draw which script.
///
/// Measured from each font's own `cmap`, never from a foundry page. This is the
/// test that refused Lalezar: it draws Persian perfectly and is missing five of
/// the seven Sorani letters, which no specimen image would have shown.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<Set<int>> coverageOf(String family) async {
    final font = kBundledFonts.firstWhere((f) => f.family == family);
    final bytes = await rootBundle.load(font.asset);
    return FontTables.mappedCodepoints(bytes.buffer.asUint8List());
  }

  group('Vazirmatn covers every script fa and ckb need', () {
    test('all seven Sorani letters', () async {
      final coverage = await coverageOf('Vazirmatn');

      final missing = kSoraniLetters.entries
          .where((e) => !coverage.contains(e.value))
          .map((e) => '${e.key} U+${e.value.toRadixString(16).toUpperCase()}')
          .toList();

      expect(
        missing,
        isEmpty,
        reason:
            'a face that draws Persian is NOT thereby a face that draws '
            'Sorani. Missing: $missing',
      );
    });

    test('all ten Eastern Arabic digits', () async {
      final coverage = await coverageOf('Vazirmatn');

      expect(
        kEasternArabicDigits.where(coverage.contains),
        hasLength(kEasternArabicDigits.length),
        reason:
            'the Schulte Grid tiles ARE the numbers. A face that cannot '
            'draw U+06F0-U+06F9 cannot ship that game in fa or ckb',
      );
    });

    test('the Arabic decimal and group separators', () async {
      final coverage = await coverageOf('Vazirmatn');

      expect(
        kArabicSeparators.where(coverage.contains),
        hasLength(kArabicSeparators.length),
        reason: 'E04 LocaleNumbers pins U+066B and U+066C for fa and ckb',
      );
    });
  });

  group('the Latin faces are Latin-only, and that is why Vazirmatn ships', () {
    for (final family in <String>['Fredoka', 'Nunito']) {
      test('$family draws no Sorani', () async {
        final coverage = await coverageOf(family);

        expect(
          kSoraniLetters.values.where(coverage.contains),
          isEmpty,
          reason:
              'if this ever stops being true the Arabic face may still be '
              'the right choice, but the REASON in the type layer has changed '
              'and should be re-read',
        );
      });
    }
  });

  group('the display-face decision, recorded', () {
    test('Vazirmatn serves both roles because Lalezar cannot', () async {
      // Measured 2026-08-19 against Lalezar-Regular.ttf's own cmap: it maps
      // Persian and the Eastern digits, and is MISSING
      //   ڕ U+0695, ڵ U+06B5, ۆ U+06C6, ێ U+06CE, ە U+06D5
      // — five of the seven letters that distinguish Sorani from Persian.
      //
      // Lalezar is the closest OFL echo of Fredoka's chunky display voice, so
      // this was the hoped-for outcome and it did not survive measurement. The
      // font is therefore NOT bundled, and Vazirmatn carries the display role
      // at its heaviest weight.
      //
      // This test asserts the consequence rather than re-measuring an absent
      // file: exactly one Arabic-script family ships, and both type roles
      // resolve to it.
      final arabicFamilies = kBundledFonts
          .where((f) => f.family != 'Fredoka' && f.family != 'Nunito')
          .map((f) => f.family)
          .toList();

      expect(
        arabicFamilies,
        <String>['Vazirmatn'],
        reason:
            'if a second Arabic family is ever added, the display-role '
            'decision above was revisited and this test should say so',
      );
    });
  });
}
