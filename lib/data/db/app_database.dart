import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:mindforge/data/db/tables/runs.dart';
import 'package:mindforge/data/db/tables/settings.dart';

part 'app_database.drift.dart';

/// The schema version this build writes and reads.
///
/// Kept beside [AppDatabase.schemaVersion] so tests and CI have one number to
/// read, and so bumping the version without dumping a snapshot fails a test
/// rather than shipping.
const int kLatestSchemaVersion = 1;

/// The `settings` primary key. There is exactly one row, forever.
const String kSettingsRowId = 'app';

/// The on-device store.
///
/// Two STRICT tables and nothing else. Every invariant SQLite can enforce lives
/// in the schema rather than in Dart, because a Dart guard protects only the
/// code path that remembers to call it.
@DriftDatabase(tables: [Runs, SettingsTable])
class AppDatabase extends _$AppDatabase {
  /// Opens the database over [e], stamping the seeded settings row from
  /// [_clock].
  ///
  /// The clock is injected rather than read from the wall. Reading the wall
  /// clock here would be the one call site that makes a fresh install's
  /// timestamps untestable, and the determinism gate bans it outright.
  AppDatabase(super.e, {this._clock = const Clock()});

  /// Where the seeded settings row's timestamps come from.
  final Clock _clock;

  @override
  int get schemaVersion => kLatestSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    beforeOpen: (details) async {
      // Re-asserted on EVERY open, not assumed: foreign_keys is a
      // per-connection pragma that resets to off, and drift may open more than
      // one connection over the life of the process.
      await customStatement('PRAGMA foreign_keys = ON;');

      if (details.wasCreated) {
        // Seeding lives ONLY here. Doing it unconditionally would silently
        // resurrect a settings row the user had changed.
        final now = _clock.now().toUtc().millisecondsSinceEpoch;
        await into<SettingsTable, SettingsRow>(settingsTable).insert(
          SettingsTableCompanion.insert(
            id: kSettingsRowId,
            createdAtUtcMs: now,
            updatedAtUtcMs: now,
            // The defaults drawn on screens/08-settings.png. localeTag stays
            // NULL, which means FOLLOW THE SYSTEM LOCALE, not English.
            isSoundEnabled: 1,
            isHapticsEnabled: 1,
            isReduceMotionEnabled: 0,
            isColourBlindPalette: 0,
          ),
        );
      }
    },
  );
}
