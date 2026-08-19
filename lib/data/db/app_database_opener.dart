import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:mindforge/data/db/app_database.dart';
import 'package:mindforge/data/db/connection.dart';

/// Opens the database at [file], **snapshotting it first** and restoring the
/// snapshot if the open throws.
///
/// This path only ever runs when something has already gone wrong: a migration
/// that fails halfway leaves a database that is neither the old schema nor the
/// new one, and MindForge has no server to re-fetch from. Restoring the bytes
/// is the difference between "the update failed, try again" and "your history
/// is gone".
///
/// The snapshot is taken **before** the connection is opened and restored with
/// **nothing open**, which is the whole trick: copying a file that a live
/// connection is writing to captures a torn WAL, and writing over a file a live
/// connection holds corrupts it outright.
///
/// The executor is `NativeDatabase.createInBackground`, the same one
/// production would otherwise build directly. That matters: a store opened on
/// a different executor here and a different one in `bootstrap()` would mean
/// the restore path was never exercised against the connection the app
/// actually uses, and drift's isolate hop changes which exception type
/// surfaces.
///
/// [openDatabase] exists so a test can supply a database whose migration
/// throws; production passes nothing and gets [AppDatabase].
Future<AppDatabase> openMigratedDatabase(
  File file, {
  AppDatabase Function(QueryExecutor executor)? openDatabase,
}) async {
  final build = openDatabase ?? AppDatabase.new;
  final snapshot = await _snapshot(file);

  AppDatabase? database;
  try {
    database = build(
      NativeDatabase.createInBackground(file, setup: applyConnectionPragmas),
    );
    // Forces the migration to actually run. Opening alone is lazy, so without
    // this the throw would surface later — at the first query, with the file
    // fallback already discarded.
    await database.customSelect('PRAGMA user_version;').getSingle();
    return database;
  } on Object {
    // Close the dead connection FIRST. Restoring underneath a live connection
    // is how a recoverable failure becomes an unrecoverable one.
    await database?.close();
    await _restore(snapshot, file);
    rethrow;
  }
}

/// The database file and its sidecars, as bytes.
typedef _Snapshot = Map<String, List<int>?>;

/// SQLite's WAL and shared-memory sidecars. A snapshot of the main file alone
/// is not a snapshot: in WAL mode the most recent commits live in `-wal`.
const List<String> _sidecarSuffixes = <String>['', '-wal', '-shm'];

Future<_Snapshot> _snapshot(File file) async {
  final snapshot = <String, List<int>?>{};
  for (final suffix in _sidecarSuffixes) {
    final sidecar = File('${file.path}$suffix');
    snapshot['${file.path}$suffix'] = sidecar.existsSync()
        ? await sidecar.readAsBytes()
        : null;
  }
  return snapshot;
}

Future<void> _restore(_Snapshot snapshot, File file) async {
  for (final entry in snapshot.entries) {
    final target = File(entry.key);
    final bytes = entry.value;

    if (bytes == null) {
      // The file did not exist before the attempt, so a file existing now is
      // something the failed open created. Removing it is part of restoring.
      if (target.existsSync()) await target.delete();
      continue;
    }
    await target.writeAsBytes(bytes, flush: true);
  }
}
