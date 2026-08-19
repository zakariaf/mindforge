import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/data/db/app_database.dart';

import '../../drift/generated/schema.dart';
import '../../drift/generated/schema_v1.dart' as v1;

/// The one settings row, inserted by hand because the era-correct classes are
/// the schema alone.
const String _insertSettingsRow = '''
INSERT INTO settings (id, created_at_utc_ms, updated_at_utc_ms, row_revision,
                      is_deleted, is_sound_enabled, is_haptics_enabled,
                      is_reduce_motion_enabled, is_colour_blind_palette)
VALUES ('app', 1, 1, 1, 0, 1, 1, 0, 0)
''';

void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('the version guard', () {
    test('schemaVersion equals kLatestSchemaVersion', () {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      expect(db.schemaVersion, kLatestSchemaVersion);
    });

    test('a snapshot exists for every version up to the latest', () {
      for (var version = 1; version <= kLatestSchemaVersion; version++) {
        expect(
          File('drift_schemas/drift_schema_v$version.json').existsSync(),
          isTrue,
          reason:
              'bumping schemaVersion without dumping the snapshot must '
              'fail HERE as well as in CI. Run: dart run drift_dev schema dump '
              'lib/data/db/app_database.dart '
              'drift_schemas/drift_schema_v$version.json',
        );
      }
    });

    test('the v1 snapshot contains locale_tag, so E04 ships no migration', () {
      final snapshot = jsonDecode(
        File('drift_schemas/drift_schema_v1.json').readAsStringSync(),
      );

      expect(
        jsonEncode(snapshot),
        contains('locale_tag'),
        reason:
            'the column ships in v1 precisely so that adding three locales '
            'is a string job rather than the first migration on a database '
            'that already holds user history',
      );
    });
  });

  group('a hostile fixture survives the v1 schema byte for byte', () {
    test('every extreme value round-trips', () async {
      final connection = await verifier.startAt(1);
      final db = v1.DatabaseAtV1(connection);
      addTearDown(db.close);

      // Hostile where the schema still allows it. Every value below is legal
      // and awkward: the boundaries, not the comfortable middle.
      const rows = <({String id, int metricValue, int durationMs, int day})>[
        (id: 'zero', metricValue: 0, durationMs: 0, day: 0),
        (
          id: 'huge',
          metricValue: 9007199254740991,
          durationMs: 9007199254740991,
          day: 2147483647,
        ),
        (id: 'negative-day', metricValue: 7, durationMs: 1, day: -25567),
      ];

      for (final row in rows) {
        await db
            .into(db.runs)
            .insert(
              v1.RunsCompanion.insert(
                id: row.id,
                createdAtUtcMs: 1,
                updatedAtUtcMs: 1,
                gameId: 'stroop_rush',
                difficultyId: 'classic',
                // Printable-ASCII punctuation, which the shape CHECK allows.
                clientRunKey: r'key/{|}~!"#$%&*+,-.:;<=>?@[\]^_`',
                startedAtUtcMs: 1755600000000,
                playedOnDay: row.day,
                durationMs: row.durationMs,
                metricKind: 'points',
                metricValue: row.metricValue,
                // total_reaction_ms at zero with a non-zero correct_count.
                correctCount: 3,
                wrongCount: 0,
                longestCombo: 0,
                totalReactionMs: 0,
                rowRevision: const Value(1),
                isDeleted: const Value(0),
              ).copyWith(clientRunKey: Value('key-${row.id}')),
            );
      }

      // DatabaseAtV1 is the bare era-correct SCHEMA; it does not run
      // AppDatabase's beforeOpen seeding, which is app behaviour rather than
      // schema. The fixture therefore inserts its own settings row.
      await db.customStatement(_insertSettingsRow);

      for (final tag in <String?>[null, 'en', 'de', 'fa', 'ckb']) {
        await db.customStatement(
          'UPDATE settings SET locale_tag = ${tag == null ? 'NULL' : "'$tag'"}',
        );
        final read = await db
            .customSelect('SELECT locale_tag AS t FROM settings')
            .getSingle();
        expect(read.data['t'], tag, reason: 'locale_tag round-trip of $tag');
      }

      final stored = await db.select(db.runs).get();
      expect(stored, hasLength(rows.length));

      for (final row in rows) {
        final found = stored.firstWhere((r) => r.id == row.id);
        expect(
          found.metricValue,
          row.metricValue,
          reason: 'metricValue @${row.id}',
        );
        expect(
          found.durationMs,
          row.durationMs,
          reason: 'durationMs @${row.id}',
        );
        expect(found.playedOnDay, row.day, reason: 'playedOnDay @${row.id}');
        expect(found.totalReactionMs, 0, reason: 'totalReactionMs @${row.id}');
      }
    });

    test('the era-correct schema rejects non-ASCII tags', () async {
      // The pre-i18n version of this fixture carried an em dash and non-ASCII
      // text in game_id. The ASCII CHECK from T02.3 makes that row illegal,
      // which is the point — so the fixture proves the REJECTION instead, and
      // proves it against the v1-era classes so a later migration cannot
      // silently relax the constraint.
      final connection = await verifier.startAt(1);
      final db = v1.DatabaseAtV1(connection);
      addTearDown(db.close);

      await db.customStatement(_insertSettingsRow);

      await expectLater(
        db.customStatement("UPDATE settings SET locale_tag = 'فا'"),
        throwsA(isA<SqliteException>()),
      );

      await expectLater(
        db.customStatement("UPDATE settings SET locale_tag = 'EN'"),
        throwsA(isA<SqliteException>()),
      );
    });

    test('integrity_check is ok and foreign_key_check is empty', () async {
      final connection = await verifier.startAt(1);
      final db = v1.DatabaseAtV1(connection);
      addTearDown(db.close);

      final integrity = await db
          .customSelect('PRAGMA integrity_check')
          .getSingle();
      expect(integrity.data.values.first, 'ok');
      expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
    });
  });

  group('every migration pair', () {
    test('migrates and validates', () async {
      // Vacuous at v1 — the loop runs zero iterations — and written now so the
      // next bump cannot forget a skip path.
      for (var from = 1; from <= kLatestSchemaVersion; from++) {
        for (var to = from + 1; to <= kLatestSchemaVersion; to++) {
          final connection = await verifier.startAt(from);
          final db = AppDatabase(connection.executor);
          addTearDown(db.close);

          await verifier.migrateAndValidate(db, to);
        }
      }
    });
  });
}
