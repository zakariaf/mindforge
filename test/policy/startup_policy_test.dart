import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('startup policy', () {
    test('runZonedGuarded appears nowhere under lib/', () {
      final offenders = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          // Comments are stripped: bootstrap.dart's doc comment names the
          // construct in order to say why it is absent, and a gate that fires
          // on its own rationale gets deleted rather than obeyed.
          .where(
            (f) => f
                .readAsLinesSync()
                .map((line) => line.replaceFirst(RegExp('//.*'), ''))
                .join('\n')
                .contains('runZonedGuarded'),
          )
          .map((f) => f.path)
          .toList();

      expect(
        offenders,
        isEmpty,
        reason:
            'app-startup-and-bootstrap rule 2: exactly two error handlers, '
            'and runZonedGuarded is neither. It adds a third capture point '
            'that swallows what the other two were installed to report. '
            'Offenders: $offenders',
      );
    });

    test('main.dart stayed thin', () {
      final main = File('lib/main.dart').readAsStringSync();

      expect(
        main,
        contains('bootstrap()'),
        reason: 'the entrypoint delegates to the one composition root',
      );

      for (final forbidden in <String>['runApp(', 'WidgetsFlutterBinding']) {
        expect(
          main.contains(forbidden),
          isFalse,
          reason:
              '$forbidden belongs in bootstrap(), where the ordering is '
              'visible in one place. An entrypoint that grows a second step '
              'grows a third',
        );
      }
    });
  });
}
