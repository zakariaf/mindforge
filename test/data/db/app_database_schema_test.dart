import 'package:clock/clock.dart';
import 'package:drift/native.dart';
import 'package:mindforge/core/score_format.dart';
import 'package:mindforge/data/db/app_database.dart';
import 'package:mindforge/data/db/connection.dart';
import 'package:test/test.dart';

/// A minimally valid `runs` insert, so each test below can violate exactly one
/// constraint and prove SQLite is what rejects it.
String _insertRun({
  String id = 'run-1',
  String gameId = 'stroop_rush',
  String difficultyId = 'classic',
  String clientRunKey = 'key-1',
  int startedAtUtcMs = 1755600000000,
  int playedOnDay = 20685,
  int durationMs = 90000,
  String metricKind = 'points',
  int metricValue = 1480,
  int correctCount = 46,
  int wrongCount = 4,
  int longestCombo = 11,
  int totalReactionMs = 32000,
}) =>
    '''
INSERT INTO runs (id, created_at_utc_ms, updated_at_utc_ms, row_revision,
                  is_deleted, game_id, difficulty_id, client_run_key,
                  started_at_utc_ms, played_on_day, duration_ms, metric_kind,
                  metric_value, correct_count, wrong_count, longest_combo,
                  total_reaction_ms)
VALUES ('$id', 1755600090000, 1755600090000, 1, 0, '$gameId', '$difficultyId',
        '$clientRunKey', $startedAtUtcMs, $playedOnDay, $durationMs,
        '$metricKind', $metricValue, $correctCount, $wrongCount, $longestCombo,
        $totalReactionMs)
''';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(
      // Opened through the SAME setup the app ships, so the pragma assertions
      // below are about the real connection rather than a test-only one.
      NativeDatabase.memory(setup: applyConnectionPragmas),
      clock: Clock.fixed(DateTime.utc(2026, 8, 19, 10)),
    );
    addTearDown(db.close);
  });

  Future<int> scalar(String sql) async {
    final row = await db.customSelect(sql).getSingle();
    return row.data.values.first! as int;
  }

  group('the host SQLite', () {
    test('is new enough for STRICT tables', () async {
      final row = await db
          .customSelect('SELECT sqlite_version() AS v')
          .getSingle();
      final version = row.read<String>('v');
      final parts = version.split('.').map(int.parse).toList();

      expect(
        parts[0] * 1000 + parts[1],
        greaterThanOrEqualTo(3037),
        reason:
            'STRICT tables need SQLite 3.37+. Asserted FIRST and by itself, '
            'because a stale host otherwise fails as a wall of confusing '
            'constraint errors rather than as one legible message. Found '
            '$version',
      );
    });
  });

  group('schema shape', () {
    test('both tables are declared STRICT', () async {
      for (final table in <String>['runs', 'settings']) {
        final row = await db
            .customSelect(
              "SELECT sql FROM sqlite_master WHERE name = '$table'",
            )
            .getSingle();

        expect(
          row.read<String>('sql').toUpperCase(),
          contains('STRICT'),
          reason:
              'without STRICT, SQLite accepts a string in an INTEGER '
              'column and every CHECK below becomes advisory',
        );
      }
    });

    test('the metric_kind CHECK lists exactly the ScoreFormat names', () async {
      final row = await db
          .customSelect("SELECT sql FROM sqlite_master WHERE name = 'runs'")
          .getSingle();

      final expected = ScoreFormat.values.map((f) => "'${f.name}'").join(',');

      expect(
        row.read<String>('sql'),
        contains('metric_kind IN ($expected)'),
        reason:
            'there is one score vocabulary. Adding a third ScoreFormat '
            'must be a migration, not a silent constraint violation on the '
            'single column that decides MAX versus MIN',
      );
    });
  });

  group('runs range constraints', () {
    const violations = <String, String>{
      'duration_ms = -1': 'a run cannot last negative time',
      'metric_value < 0': 'a score cannot be negative',
      'longest_combo > correct_count':
          'a combo cannot be longer than the correct answers that built it',
      'empty game_id': 'a game id is a token, and the empty token is not one',
      'empty difficulty_id': 'same reason as game_id',
      "metric_kind = 'elo'": 'the score vocabulary is closed',
    };

    test('each is rejected by SQLite, not by a Dart guard', () async {
      final statements = <String, String>{
        'duration_ms = -1': _insertRun(durationMs: -1),
        'metric_value < 0': _insertRun(metricValue: -1),
        'longest_combo > correct_count': _insertRun(
          correctCount: 5,
          longestCombo: 6,
        ),
        'empty game_id': _insertRun(gameId: ''),
        'empty difficulty_id': _insertRun(difficultyId: ''),
        "metric_kind = 'elo'": _insertRun(metricKind: 'elo'),
      };

      for (final entry in statements.entries) {
        await expectLater(
          db.customStatement(entry.value),
          throwsA(isA<SqliteException>()),
          reason: '${entry.key}: ${violations[entry.key]}',
        );
      }
    });
  });

  group('ASCII-tag constraints keep a localized string out of a column', () {
    test('game_id rejects Persian text', () async {
      await expectLater(
        db.customStatement(_insertRun(gameId: 'ستروپ')),
        throwsA(isA<SqliteException>()),
      );
    });

    test('game_id rejects a display name with a space and capitals', () async {
      await expectLater(
        db.customStatement(_insertRun(gameId: 'Stroop Rush')),
        throwsA(isA<SqliteException>()),
        reason: 'the token is stroop_rush; Stroop Rush is an ARB string',
      );
    });

    test('difficulty_id rejects Sorani text', () async {
      await expectLater(
        db.customStatement(_insertRun(difficultyId: 'کلاسیک')),
        throwsA(isA<SqliteException>()),
      );
    });

    test('client_run_key rejects non-ASCII', () async {
      await expectLater(
        db.customStatement(_insertRun(clientRunKey: 'کلید۱')),
        throwsA(isA<SqliteException>()),
      );
    });

    test('locale_tag rejects Persian text', () async {
      await expectLater(
        db.customStatement(
          "UPDATE settings SET locale_tag = 'فا' WHERE id = 'app'",
        ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('locale_tag rejects uppercase', () async {
      await expectLater(
        db.customStatement(
          "UPDATE settings SET locale_tag = 'EN' WHERE id = 'app'",
        ),
        throwsA(isA<SqliteException>()),
        reason:
            'BCP-47 tags are stored lowercase, and SupportedLocale.tryParse '
            'is exact',
      );
    });

    test('locale_tag accepts NULL and each shipped tag', () async {
      for (final tag in <String?>[null, 'en', 'de', 'fa', 'ckb']) {
        final literal = tag == null ? 'NULL' : "'$tag'";
        await db.customStatement(
          "UPDATE settings SET locale_tag = $literal WHERE id = 'app'",
        );

        final row = await db
            .customSelect(
              "SELECT locale_tag AS t FROM settings WHERE id = 'app'",
            )
            .getSingle();

        expect(row.data['t'], tag, reason: 'round-trip of $literal');
      }
    });
  });

  group('settings singleton', () {
    test('a second row with any other id is rejected', () async {
      await expectLater(
        db.customStatement('''
INSERT INTO settings (id, created_at_utc_ms, updated_at_utc_ms, row_revision,
                      is_deleted, is_sound_enabled, is_haptics_enabled,
                      is_reduce_motion_enabled, is_colour_blind_palette)
VALUES ('preferences', 1, 1, 1, 0, 1, 1, 0, 0)
'''),
        throwsA(isA<SqliteException>()),
      );
    });

    test(
      'a fresh database seeds exactly one row at the design defaults',
      () async {
        expect(await scalar('SELECT COUNT(*) AS c FROM settings'), 1);

        final row = await db
            .customSelect("SELECT * FROM settings WHERE id = 'app'")
            .getSingle();

        expect(row.data['is_sound_enabled'], 1);
        expect(row.data['is_haptics_enabled'], 1);
        expect(row.data['is_reduce_motion_enabled'], 0);
        expect(row.data['is_colour_blind_palette'], 0);
        expect(
          row.data['locale_tag'],
          isNull,
          reason: 'NULL means follow the system locale, not English',
        );
        expect(
          row.data['created_at_utc_ms'],
          DateTime.utc(2026, 8, 19, 10).millisecondsSinceEpoch,
          reason: 'the seed is stamped from the injected Clock, not the wall',
        );
      },
    );
  });

  group('the idempotency index', () {
    test('a duplicate client_run_key is rejected', () async {
      await db.customStatement(_insertRun());

      await expectLater(
        db.customStatement(_insertRun(id: 'run-2')),
        throwsA(isA<SqliteException>()),
      );
    });

    test('soft-deleting the first frees the key', () async {
      await db.customStatement(_insertRun());
      await db.customStatement(
        "UPDATE runs SET is_deleted = 1, deleted_at_utc_ms = 1 WHERE id = 'run-1'",
      );

      await db.customStatement(_insertRun(id: 'run-2'));

      expect(
        await scalar('SELECT COUNT(*) AS c FROM runs'),
        2,
        reason:
            'the UNIQUE index is partial — WHERE is_deleted = 0 — so a '
            'soft-deleted row does not permanently reserve its key',
      );
    });
  });

  group('integrity', () {
    test('integrity_check is ok and foreign_key_check is empty', () async {
      final integrity = await db
          .customSelect('PRAGMA integrity_check')
          .getSingle();
      expect(integrity.data.values.first, 'ok');

      final fks = await db.customSelect('PRAGMA foreign_key_check').get();
      expect(fks, isEmpty);
    });

    test('every per-connection pragma is set', () async {
      // journal_mode is the one that reports a string.
      final journal = await db.customSelect('PRAGMA journal_mode').getSingle();
      expect(
        journal.data.values.first,
        // An in-memory database cannot use WAL and reports `memory`; on a file
        // database this is `wal`. Both are asserted rather than one, because
        // silently accepting whatever came back would make this test vacuous.
        anyOf('wal', 'memory'),
      );

      expect(await scalar('PRAGMA foreign_keys'), 1);
      expect(
        await scalar('PRAGMA synchronous'),
        2,
        reason:
            'FULL. This database is the only copy of a player history and '
            'there is no server to re-fetch from',
      );
      expect(await scalar('PRAGMA busy_timeout'), 5000);
    });
  });
}
