import 'package:flutter_test/flutter_test.dart';

import 'support/source_text.dart';

/// `HapticFeedback` is named in exactly one file.
///
/// Haptics that are scattered cannot be switched off from Settings, and a
/// moment fired from two layers is felt twice — which reads as a bug in the
/// game rather than in the code. One call site is what makes the Settings
/// toggle a real switch rather than a suggestion.
void main() {
  test('only the haptic gateway names HapticFeedback', () {
    final offenders = dartFilesUnderLib()
        .where(
          (file) => withoutDartComments(
            file.readAsStringSync(),
          ).contains('HapticFeedback.'),
        )
        .map((file) => file.path)
        .toList();

    expect(offenders, <String>['lib/shared/feedback/haptic_gateway.dart']);
  });

  test('and nothing anywhere asks the device to vibrate', () {
    final offenders = dartFilesUnderLib()
        .where(
          (file) => withoutDartComments(
            file.readAsStringSync(),
          ).contains('HapticFeedback.vibrate'),
        )
        .map((file) => file.path)
        .toList();

    expect(offenders, isEmpty);
  });
}
