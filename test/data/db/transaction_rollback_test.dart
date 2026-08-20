import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/data/db/app_database.dart';

import '../../support/test_database.dart';

/// The guarantee `RunRepository.saveRun` rests on, asserted directly against
/// real SQLite rather than through a fake.
///
/// A killed process mid-save must leave either zero rows or one complete row.
void main() {
  late AppDatabase db;

  setUp(() {
    db = openTestDatabase();
    addTearDown(db.close);
  });

  String insert(String id, {int correctCount = 46, int longestCombo = 11}) =>
      '''
INSERT INTO runs (id, created_at_utc_ms, updated_at_utc_ms, row_revision,
                  is_deleted, game_id, difficulty_id, client_run_key,
                  started_at_utc_ms, played_on_day, duration_ms, metric_kind,
                  metric_value, correct_count, wrong_count, longest_combo,
                  total_reaction_ms)
VALUES ('$id', 1, 1, 1, 0, 'stroop_rush', 'classic', 'key-$id',
        1755600000000, 20685, 90000, 'points', 1480, $correctCount, 4,
        $longestCombo, 32000)
''';

  test('a throwing transaction leaves no partial row behind', () async {
    await expectLater(
      db.transaction(() async {
        await db.customStatement(insert('run-1'));
        // Violates CHECK (longest_combo <= correct_count).
        await db.customStatement(
          insert('run-2', correctCount: 5, longestCombo: 6),
        );
      }),
      throwsA(isA<Object>()),
    );

    final row = await db
        .customSelect('SELECT COUNT(*) AS c FROM runs')
        .getSingle();

    expect(
      row.data['c'],
      0,
      reason:
          'the valid first insert must roll back with the invalid second. '
          'One transaction per mutation is what makes a killed process leave '
          'either zero rows or one complete row',
    );
  });
}
