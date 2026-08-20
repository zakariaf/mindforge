import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/source_text.dart';

/// Provider shapes and DI containers this project does not use.
const kBannedProviderShapes = <String, String>{
  'StateProvider':
      'CLAUDE.md: Notifier/AsyncNotifier over immutable state, no legacy '
      'providers',
  'StateNotifierProvider': 'same — StateNotifier is the legacy shape',
  'ChangeNotifierProvider': 'same — mutable state with manual notification',
  'package:get_it':
      'Riverpod 3.x is both state and DI; a second container is a second '
      'wiring nobody reconciles',
  'package:provider/': 'same reason as get_it',
};

void main() {
  test('no banned provider shape or DI container appears under lib/', () {
    final offenders = <String>[];

    final dartFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

    for (final file in dartFiles) {
      final source = withoutDartComments(file.readAsStringSync());

      for (final banned in kBannedProviderShapes.entries) {
        if (source.contains(banned.key)) {
          offenders.add('${file.path}: ${banned.key} — ${banned.value}');
        }
      }
    }

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
