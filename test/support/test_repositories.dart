import 'package:clock/clock.dart';
import 'package:mindforge/data/daos/runs_dao.dart';
import 'package:mindforge/data/daos/settings_dao.dart';
import 'package:mindforge/data/db/app_database.dart';
import 'package:mindforge/data/repositories/run_repository.dart';
import 'package:mindforge/data/repositories/settings_repository.dart';

import 'fake_id_generator.dart';
import 'fake_log_sink.dart';
import 'test_database.dart';

/// The registered game ids most tests use.
const kTestGameIds = <String>{'stroop_rush', 'schulte_grid'};

/// A [RunRepository] over [db] with the standard fakes.
///
/// The six-argument construction had been copied into eight test files, which
/// is how one of them ends up quietly using a different clock.
RunRepository testRunRepository(
  AppDatabase db, {
  DateTime? now,
  FakeIdGenerator? idGenerator,
  FakeLogSink? logSink,
  Set<String> registeredGameIds = kTestGameIds,
}) => RunRepository(
  database: db,
  dao: RunsDao(db),
  clock: Clock.fixed(now ?? kTestNow),
  idGenerator: idGenerator ?? FakeIdGenerator(),
  logSink: logSink ?? FakeLogSink(),
  isRegisteredGameId: registeredGameIds.contains,
);

/// A [SettingsRepository] over [db] with the standard fakes.
SettingsRepository testSettingsRepository(
  AppDatabase db, {
  DateTime? now,
  FakeLogSink? logSink,
}) => SettingsRepository(
  database: db,
  dao: SettingsDao(db),
  clock: Clock.fixed(now ?? kTestNow),
  logSink: logSink ?? FakeLogSink(),
);
