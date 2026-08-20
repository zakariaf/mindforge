import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/features/play/domain/result_stat.dart';

import '../../../policy/support/source_text.dart';
import '../../../support/design_source.dart';

void main() {
  group('a result stat', () {
    test('carries an ARB key and a canonical integer', () {
      const stat = ResultStat(
        labelKey: 'statAccuracy',
        canonicalValue: 923,
        format: StatFormat.percent,
      );

      expect(RegExp(r'^[a-z][a-zA-Z0-9_]*$').hasMatch(stat.labelKey), isTrue);
      expect(stat.canonicalValue, isA<int>());
      for (final rune in stat.labelKey.runes) {
        expect(rune, lessThan(0x80));
      }
    });

    test('and declares exactly one String field, which is the key', () {
      // The rule is about what a stat can HOLD, not about every literal in the
      // file: an import URI and a debug toString are both string literals and
      // neither reaches a screen. A second String field is the thing that
      // would — a stat holding "18.6s" is an English sentence in four locales,
      // and one holding "۱۸٫۶ ثانیه" goes stale the moment the player changes
      // language.
      expect(
        DesignSource.dartFieldNames(
          'lib/features/play/domain/result_stat.dart',
          'ResultStat',
        ),
        <String>['labelKey', 'canonicalValue', 'format'],
      );
    });

    test('and no field value carries prose or a non-ASCII rune', () {
      const stat = ResultStat(
        labelKey: 'statAccuracy',
        canonicalValue: 923,
        format: StatFormat.percent,
      );

      expect(stat.labelKey, isNot(contains(' ')));
      expect(stat.labelKey[0], stat.labelKey[0].toLowerCase());
    });
  });

  group('each StatFormat declares its canonical unit', () {
    test('as a table, so the doc and the enum cannot drift', () {
      // The unit is the whole contract: E08 formats canonicalValue by reading
      // this, and a percent stored as 92 instead of 923 is a stat that reads
      // 9.2% forever.
      const units = <StatFormat, String>{
        StatFormat.points: 'points',
        StatFormat.duration: 'milliseconds',
        StatFormat.percent: 'per mille',
        StatFormat.count: 'items',
      };

      expect(units.keys.toSet(), StatFormat.values.toSet());

      final doc = File(
        'lib/features/play/domain/result_stat.dart',
      ).readAsStringSync();

      for (final entry in units.entries) {
        expect(
          doc,
          contains(entry.value),
          reason: '${entry.key.name} should document "${entry.value}"',
        );
      }
    });
  });

  group('StatFormat never reaches the database', () {
    test('it is a presentation enum and ScoreFormat is the persisted one', () {
      // Merging them would make adding `percent` a schema migration: E02's
      // ScoreFormat is mirrored by the runs.metric_kind CHECK constraint.
      final offenders = <String>[];

      for (final file in dartFilesUnderLib()) {
        if (!file.path.startsWith('lib/data/')) continue;

        if (withoutDartComments(
          file.readAsStringSync(),
        ).contains('StatFormat')) {
          offenders.add(file.path);
        }
      }

      expect(offenders, isEmpty);
    });
  });
}
