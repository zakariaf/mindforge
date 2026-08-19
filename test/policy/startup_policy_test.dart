import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('startup policy', () {
    test('runZonedGuarded appears nowhere under lib/', () {
      final offenders = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) => f.readAsStringSync().contains('runZonedGuarded'))
          .map((f) => f.path)
          .toList();

      expect(
        offenders,
        isEmpty,
        reason: 'app-startup-and-bootstrap rule 2: exactly two error handlers, '
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

      for (const forbidden in <String>['runApp(', 'WidgetsFlutterBinding']) {
        expect(
          main.contains(forbidden),
          isFalse,
          reason: '$forbidden belongs in bootstrap(), where the ordering is '
              'visible in one place. An entrypoint that grows a second step '
              'grows a third',
        );
      }
    });
  });
}
