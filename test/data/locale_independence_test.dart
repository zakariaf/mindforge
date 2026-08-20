import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/app_settings.dart';
import 'package:mindforge/core/result.dart';
import 'package:mindforge/core/run_commit.dart';
import 'package:mindforge/core/run_draft.dart';
import 'package:mindforge/core/supported_locale.dart';
import 'package:mindforge/data/data_failure.dart';

import '../support/locale_matrix.dart';
import '../support/run_fixtures.dart';
import '../support/test_database.dart';
import '../support/test_repositories.dart';

/// Writes the same seeded fixture and returns every row of both tables.
///
/// The clock and the id generator are the same in every call, so the ONLY
/// variable across locales is the ambient locale itself.
Future<Map<String, List<Map<String, Object?>>>> writeAndReadBack() async {
  final db = openTestDatabase();
  final repository = testRunRepository(db);

  for (final draft in seededDrafts(seed: 12345, count: 8)) {
    final result = await repository.saveRun(draft);
    expect(result, isA<Ok<RunCommit, DataFailure>>(), reason: '$result');
  }

  final settings = testSettingsRepository(db);
  expect(
    await settings.update(
      const AppSettings.defaults().withLocaleOverride(SupportedLocale.ckb),
    ),
    isA<Ok<AppSettings, DataFailure>>(),
  );

  final runs = (await db.customSelect('SELECT * FROM runs ORDER BY id').get())
      .map((r) => r.data)
      .toList();
  final settingsRows = (await db.customSelect('SELECT * FROM settings').get())
      .map((r) => r.data)
      .toList();

  await db.close();
  return {'runs': runs, 'settings': settingsRows};
}

void main() {
  test('the four locales produce identical row sets', () async {
    final byLocale = <String, Map<String, List<Map<String, Object?>>>>{};

    await forEachLocale((tag) async {
      byLocale[tag] = await writeAndReadBack();
    });

    final baselineTag = localeMatrix.first;
    final baseline = byLocale[baselineTag]!;

    for (final tag in localeMatrix.skip(1)) {
      expect(
        byLocale[tag],
        baseline,
        reason:
            'persistence-drift rule 5: switching locale must leave stored '
            'rows byte-identical. $tag diverged from $baselineTag. A '
            'NumberFormat that crept into a repository, a played_on_day that '
            'started reading a Jalali calendar, or a game_id that became a '
            'translated title would all show up here — and none of them break '
            'an English build',
      );
    }
  });

  test('a score written under fa reads back under en as the integer', () async {
    late Object? faValue;
    late Object? faType;

    await forEachLocale((tag) async {
      if (tag != 'fa') return;
      final db = openTestDatabase();
      final repository = testRunRepository(db);

      final draft = seededDrafts(seed: 1, count: 1).single;
      final scored = draft.copyWith(metricValue: 1480);
      expect(
        await repository.saveRun(scored),
        isA<Ok<RunCommit, DataFailure>>(),
      );

      // Read back with the ambient locale switched to en, inside the same
      // database.
      final row = await db
          .customSelect(
            'SELECT metric_value AS v, typeof(metric_value) AS t FROM runs',
          )
          .getSingle();
      faValue = row.data['v'];
      faType = row.data['t'];
      await db.close();
    });

    expect(faValue, 1480, reason: '۱۴۸۰ must never appear anywhere');
    expect(faType, 'integer');
  });

  test(
    'every TEXT column holds printable ASCII after the four-locale run',
    () async {
      final db = openTestDatabase();
      addTearDown(db.close);

      final repository = testRunRepository(db);
      await forEachLocale((tag) async {
        for (final draft in seededDrafts(seed: 7, count: 2)) {
          expect(
            await repository.saveRun(
              draft.copyWith(clientRunKey: '$tag-${draft.clientRunKey}'),
            ),
            isA<Ok<RunCommit, DataFailure>>(),
          );
        }
      });

      for (final table in <String>['runs', 'settings']) {
        // pragma_table_info rather than a hand-written column list, so a column
        // added by a later task is covered without anyone remembering to extend
        // this test.
        final columns = await db
            .customSelect(
              "SELECT name, type FROM pragma_table_info('$table')",
            )
            .get();

        final textColumns = columns
            .where((c) => (c.data['type']! as String).toUpperCase() == 'TEXT')
            .map((c) => c.data['name']! as String);

        expect(textColumns, isNotEmpty, reason: '$table has no TEXT column?');

        for (final column in textColumns) {
          final row = await db
              .customSelect(
                'SELECT count(*) AS c FROM $table '
                "WHERE $column IS NOT NULL AND $column GLOB '*[^ -~]*'",
              )
              .getSingle();

          expect(
            row.data['c'],
            0,
            reason:
                '$table.$column holds a non-printable-ASCII value. Every '
                'identifier column is a token and every stored string is '
                'canonical; a localized string here is a value no other locale '
                'can read back',
          );
        }
      }
    },
  );

  test('seeded generation is identical under every locale', () async {
    final byLocale = <String, List<RunDraft>>{};

    await forEachLocale((tag) async {
      byLocale[tag] = seededDrafts(seed: 12345, count: 10);
    });

    final baseline = byLocale[localeMatrix.first]!;
    for (final tag in localeMatrix.skip(1)) {
      expect(
        byLocale[tag],
        baseline,
        reason:
            'seed 12345: a golden vector must not move because the locale '
            'moved. $tag diverged',
      );
    }
  });
}
