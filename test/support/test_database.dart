import 'package:clock/clock.dart';
import 'package:drift/native.dart';
import 'package:mindforge/data/db/app_database.dart';
import 'package:mindforge/data/db/connection.dart';

/// The instant every test's fixed clock reports unless it says otherwise.
final DateTime kTestNow = DateTime.utc(2026, 8, 19, 10);

/// Opens an in-memory database through the **same** connection setup the app
/// ships, so pragma-dependent behaviour is not a test-only fiction.
///
/// `NativeDatabase.memory()` over real SQLite, never a mocked DAO: the whole
/// value of these tests is that SQLite is what enforces the constraints
/// (`testing-strategy`).
AppDatabase openTestDatabase({DateTime? now}) => AppDatabase(
  NativeDatabase.memory(setup: applyConnectionPragmas),
  clock: Clock.fixed(now ?? kTestNow),
);
