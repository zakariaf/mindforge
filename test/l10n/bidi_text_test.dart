import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/l10n/bidi_text.dart';

void main() {
  // Escapes, not literals: an invisible bidi control in source misleads a
  // human reader while meaning something else to the compiler.
  const fsi = '\u2068';
  const pdi = '\u2069';

  group('isolate', () {
    test('wraps a run in FSI and PDI', () {
      expect(BidiText.isolate('MindForge'), '${fsi}MindForge$pdi');
    });

    test('uses FIRST STRONG, so one helper serves both scripts', () {
      // The direction is inferred from the run's own first strong character.
      // An LRI would force LTR and mangle a Persian run passed through the
      // same call site.
      expect(BidiText.isolate('فارسی').codeUnitAt(0), 0x2068);
      expect(BidiText.isolate('MindForge').codeUnitAt(0), 0x2068);
    });

    test('is a no-op on an empty string, so callers need no guard', () {
      expect(BidiText.isolate(''), '');
    });
  });

  group('strip', () {
    test('round-trips', () {
      for (final text in <String>['MindForge', 'N-Back', 'فارسی', '']) {
        expect(BidiText.strip(BidiText.isolate(text)), text);
      }
    });

    test('is what a caller must use before comparing or writing', () {
      // An isolated string is a RENDERING. Storing one puts invisible control
      // characters in a column every later read has to strip, and makes an
      // equality check against the stored form fail for no visible reason.
      const isolated = '\u2068stroop_rush\u2069';

      expect(isolated == 'stroop_rush', isFalse);
      expect(BidiText.strip(isolated), 'stroop_rush');
    });
  });

  group('isIsolated', () {
    test('detects a wrapped run so a caller cannot double-wrap', () {
      expect(BidiText.isIsolated(BidiText.isolate('MindForge')), isTrue);
      expect(BidiText.isIsolated('MindForge'), isFalse);
    });

    test('and isolate is idempotent, so two layers cannot double-wrap', () {
      final once = BidiText.isolate('MindForge');

      expect(
        BidiText.isolate(once),
        once,
        reason:
            'a double wrap is invisible on screen and survives into every '
            'value built from the result',
      );
    });
  });
}
