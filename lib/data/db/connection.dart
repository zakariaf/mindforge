import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/common.dart';

/// The database file name inside the application-support directory.
const String kDatabaseFileName = 'mindforge.sqlite';

/// Opens the on-device database, lazily, with the per-connection pragmas set
/// **before** any statement runs.
///
/// The pragmas are configured in `setup:` rather than in `beforeOpen` because
/// `journal_mode` and `foreign_keys` are per-connection state that resets to
/// SQLite's defaults on every new connection, and drift may open more than one
/// over the life of the process. Setting them once at open time would leave a
/// later connection silently running with foreign keys off.
///
/// On iOS this resolves inside the app container's
/// `Library/Application Support`, deliberately, on two counts: it is included
/// in the iCloud and Finder device backup — and this database is the only copy
/// of a player's history, so it should survive a device restore — and it is not
/// exposed through the Files app the way `Documents` is under
/// `UIFileSharingEnabled`.
///
/// The container UUID changes on reinstall and on restore, so **no absolute
/// path is ever persisted**: the directory is resolved at open time and the
/// schema holds no path column.
QueryExecutor openDatabaseConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationSupportDirectory();
    final file = File(p.join(directory.path, kDatabaseFileName));

    return NativeDatabase.createInBackground(
      file,
      setup: applyConnectionPragmas,
    );
  });
}

/// Applies the per-connection pragmas MindForge relies on.
///
/// Exposed so the test suite can open an in-memory database through exactly the
/// same configuration the app uses, rather than asserting against a connection
/// nobody ships.
void applyConnectionPragmas(CommonDatabase database) {
  database
    // WAL: a reader never blocks the writer, which matters because every screen
    // holds a .watch() stream open while a run is being committed.
    ..execute('PRAGMA journal_mode = WAL;')
    // FULL, not NORMAL. This database is the only copy of a player's history
    // and there is no server to re-fetch from, so a power loss that costs the
    // last commit is worse than the write being slower.
    ..execute('PRAGMA synchronous = FULL;')
    ..execute('PRAGMA foreign_keys = ON;')
    // Five seconds rather than failing instantly: a background write finishing
    // while the UI reads should wait, not surface a typed failure to the
    // player.
    ..execute('PRAGMA busy_timeout = 5000;');
}
