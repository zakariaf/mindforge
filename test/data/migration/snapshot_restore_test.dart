import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/data/db/app_database.dart';
import 'package:mindforge/data/db/app_database_opener.dart';

/// An [AppDatabase] whose migration always throws, so the restore path can be
/// exercised without corrupting anything for real.
class _ThrowingDatabase extends AppDatabase {
  _ThrowingDatabase(super.e);

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (_) async {
      throw StateError('deliberate mid-migration failure');
    },
  );
}

void main() {
  late Directory directory;
  late File file;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('mindforge-restore');
    file = File('${directory.path}/mindforge.sqlite');
    addTearDown(() => directory.deleteSync(recursive: true));
  });

  Future<void> seedOneRun() async {
    final db = await openMigratedDatabase(file);
    await db.customStatement('''
INSERT INTO runs (id, created_at_utc_ms, updated_at_utc_ms, row_revision,
                  is_deleted, game_id, difficulty_id, client_run_key,
                  started_at_utc_ms, played_on_day, duration_ms, metric_kind,
                  metric_value, correct_count, wrong_count, longest_combo,
                  total_reaction_ms)
VALUES ('run-1', 1, 1, 1, 0, 'stroop_rush', 'classic', 'key-1',
        1755600000000, 20685, 90000, 'points', 1480, 46, 4, 11, 32000)
''');
    await db.close();
  }

  test('a healthy open creates the file and its schema', () async {
    final db = await openMigratedDatabase(file);
    addTearDown(db.close);

    expect(file.existsSync(), isTrue);
    final row = await db
        .customSelect('SELECT COUNT(*) AS c FROM settings')
        .getSingle();
    expect(row.data['c'], 1, reason: 'the seeding ran');
  });

  test(
    'a forced mid-migration throw restores the file byte for byte',
    () async {
      await seedOneRun();

      final before = file.readAsBytesSync();
      final walBefore = File('${file.path}-wal');
      final walBytesBefore = walBefore.existsSync()
          ? walBefore.readAsBytesSync()
          : null;

      await expectLater(
        openMigratedDatabase(file, openDatabase: _ThrowingDatabase.new),
        throwsA(isA<StateError>()),
        reason:
            'the failure must RETHROW after restoring — swallowing it would '
            'hand back a database nobody can trust',
      );

      expect(
        file.readAsBytesSync(),
        before,
        reason:
            'the snapshot is taken BEFORE the connection is opened and '
            'restored with NOTHING open. Copying a file a live connection is '
            'writing to captures a torn WAL, and writing over a file a live '
            'connection holds corrupts it outright',
      );

      if (walBytesBefore != null) {
        expect(File('${file.path}-wal').readAsBytesSync(), walBytesBefore);
      }
    },
  );

  test('the row set survives the failed attempt', () async {
    await seedOneRun();

    await expectLater(
      openMigratedDatabase(file, openDatabase: _ThrowingDatabase.new),
      throwsA(isA<StateError>()),
    );

    final db = await openMigratedDatabase(file);
    addTearDown(db.close);

    final row = await db
        .customSelect("SELECT metric_value AS v FROM runs WHERE id = 'run-1'")
        .getSingle();
    expect(
      row.data['v'],
      1480,
      reason:
          'MindForge has no server to re-fetch from, so this is the '
          'difference between "the update failed, try again" and "your '
          'history is gone"',
    );
  });

  test('a failed FIRST open leaves no file behind', () async {
    expect(file.existsSync(), isFalse);

    await expectLater(
      openMigratedDatabase(file, openDatabase: _ThrowingDatabase.new),
      throwsA(isA<StateError>()),
    );

    expect(
      file.existsSync(),
      isFalse,
      reason:
          'the file did not exist before the attempt, so removing what the '
          'failed open created is part of restoring',
    );
  });
}
