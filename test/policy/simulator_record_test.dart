import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final record =
      jsonDecode(File('.toolchain.json').readAsStringSync())
          as Map<String, dynamic>;
  final simulator = record['simulator'] as Map<String, dynamic>;

  group('simulator record', () {
    test('the UDID has the shape simctl emits', () {
      expect(
        RegExp(r'^[0-9A-F-]{36}$').hasMatch(simulator['udid'] as String),
        isTrue,
      );
    });

    test('the logical size is 390x844', () {
      expect(
        simulator['logicalSize'],
        '390x844',
        reason:
            'every reference PNG under design/sunburst-pop/screens/ is '
            '780x1688 — 390x844 at 2x. iPhone 16 is 393x852 and 16 Pro is '
            '402x874, so a comparison run on either is a comparison against a '
            'different canvas',
      );
    });

    test('tool/ios_simulator.sh hard-codes no UDID of its own', () {
      final script = File('tool/ios_simulator.sh').readAsStringSync();

      expect(
        RegExp(
          '[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}',
        ).hasMatch(script),
        isFalse,
        reason:
            'the script reads .toolchain.json, so there is exactly one '
            'place the canonical device is named',
      );
    });
  });
}
