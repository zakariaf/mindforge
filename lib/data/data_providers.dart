// specify_nonobvious_property_types wants an explicit type on every provider
// below. Riverpod 3 does not export the concrete family types
// (StreamProviderFamily and friends live behind src/internals.dart), so the
// annotation cannot be written at all for half of these, and the ecosystem
// relies on inference by design. The value type is spelled explicitly in every
// generic argument instead, which is where it actually matters.
// ignore_for_file: specify_nonobvious_property_types

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindforge/core/app_settings.dart';
import 'package:mindforge/core/game_stats.dart';
import 'package:mindforge/core/id_generator.dart';
import 'package:mindforge/core/result.dart';
import 'package:mindforge/core/run_commit.dart';
import 'package:mindforge/core/run_draft.dart';
import 'package:mindforge/core/run_metric.dart';
import 'package:mindforge/core/run_record.dart';
import 'package:mindforge/core/run_scope.dart';
import 'package:mindforge/core/streak_status.dart';
import 'package:mindforge/data/daos/runs_dao.dart';
import 'package:mindforge/data/daos/settings_dao.dart';
import 'package:mindforge/data/data_failure.dart';
import 'package:mindforge/data/db/app_database.dart';
import 'package:mindforge/data/log_sink.dart';
import 'package:mindforge/data/repositories/run_repository.dart';
import 'package:mindforge/data/repositories/settings_repository.dart';
import 'package:mindforge/data/uuid_id_generator.dart';

/// The live database.
///
/// A **throwing placeholder**: a forgotten override must fail loudly at the
/// first read, not quietly construct a second real database inside a test.
/// `bootstrap()` overrides it; every test overrides it with
/// `NativeDatabase.memory()`.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError(
    'appDatabaseProvider was read without an override. Override it in '
    'lib/bootstrap.dart for the app, or with '
    'AppDatabase(NativeDatabase.memory()) in a test.',
  );
});

/// The settings row as it was read **before** the first frame.
///
/// A throwing placeholder for the same reason. `bootstrap()` awaits one bounded
/// read and overrides this, so `MaterialApp` can be built with the persisted
/// locale already resolved — an `AsyncValue` here would paint an English LTR
/// frame and then flip to Persian RTL on a Persian user's cold start.
final initialAppSettingsProvider = Provider<AppSettings>((ref) {
  throw UnimplementedError(
    'initialAppSettingsProvider was read without an override. bootstrap() '
    'sets it from SettingsRepository.read() before runApp.',
  );
});

/// The one time seam. Self-defaults, so only tests override it.
final clockProvider = Provider<Clock>((ref) => const Clock());

/// The one id seam.
final idGeneratorProvider = Provider<IdGenerator>(
  (ref) => const UuidIdGenerator(),
);

/// Where the data layer reports a handled failure.
final logSinkProvider = Provider<LogSink>((ref) => const DebugLogSink());

/// Which `gameId`s this build ships.
///
/// A placeholder that accepts nothing until E07's registry overrides it. It
/// refuses rather than accepts, so a run written against an unregistered game
/// fails in a test rather than in a user's history.
final registeredGameIdsProvider = Provider<Set<String>>((ref) => const {});

/// Single-table queries over `settings`. Not exposed above the repository.
final settingsDaoProvider = Provider<SettingsDao>(
  (ref) => SettingsDao(ref.watch(appDatabaseProvider)),
);

/// Single-table queries over `runs`. Not exposed above the repository.
final runsDaoProvider = Provider<RunsDao>(
  (ref) => RunsDao(ref.watch(appDatabaseProvider)),
);

/// The single settings write path.
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(
    database: ref.watch(appDatabaseProvider),
    dao: ref.watch(settingsDaoProvider),
    clock: ref.watch(clockProvider),
    logSink: ref.watch(logSinkProvider),
  ),
);

/// The single run write path, and the source of every derived number.
final runRepositoryProvider = Provider<RunRepository>(
  (ref) => RunRepository(
    database: ref.watch(appDatabaseProvider),
    dao: ref.watch(runsDaoProvider),
    clock: ref.watch(clockProvider),
    idGenerator: ref.watch(idGeneratorProvider),
    logSink: ref.watch(logSinkProvider),
    isRegisteredGameId: ref.watch(registeredGameIdsProvider).contains,
  ),
);

/// The current settings, re-emitting after every committed write.
///
/// **Seeded** with [initialAppSettingsProvider], so the first frame carries the
/// persisted value rather than an `AsyncLoading`.
///
/// Reading this therefore requires [initialAppSettingsProvider] to be
/// overridden. `bootstrap()` does it; every test must too.
final StreamProvider<AppSettings> settingsProvider =
    StreamProvider<AppSettings>((ref) async* {
      // Seeded first, so the very first frame carries the persisted value
      // rather than an AsyncLoading. That is the whole reason bootstrap()
      // awaits a read before runApp: a Persian user's cold start must not paint
      // an English LTR frame and then flip to Persian RTL.
      yield ref.watch(initialAppSettingsProvider);
      yield* ref.watch(settingsRepositoryProvider).watch();
    });

/// The best score in one scope.
final personalBestProvider = StreamProvider.autoDispose
    .family<Result<RunMetric?, DataFailure>, RunScope>(
      (ref, scope) => ref.watch(runRepositoryProvider).watchPersonalBest(scope),
    );

/// The best score for every game that has any run.
///
/// Unscoped, and therefore **not** a family: it is one `GROUP BY` behind Home's
/// BEST pills.
final allBestsProvider =
    StreamProvider.autoDispose<Map<String, Result<RunMetric?, DataFailure>>>(
      (ref) => ref.watch(runRepositoryProvider).watchBestsByGame(),
    );

/// The aggregate numbers for one scope.
final runStatsProvider = StreamProvider.autoDispose.family<GameStats, RunScope>(
  (ref, scope) => ref.watch(runRepositoryProvider).watchStats(scope),
);

/// The recent-runs series for one scope.
final chartSeriesProvider = StreamProvider.autoDispose
    .family<List<RunRecord>, RunScope>(
      (ref, scope) => ref.watch(runRepositoryProvider).watchChartSeries(scope),
    );

/// The daily streak.
final streakProvider = StreamProvider.autoDispose<StreakStatus>(
  (ref) => ref.watch(runRepositoryProvider).watchStreak(),
);

/// The settings the app reads, with the seed as their pre-stream value.
///
/// **One fold, not one per consumer.** `localeProvider` and the three feedback
/// gates had each written `settingsProvider.value ?? initialAppSettingsProvider`
/// out, with a paragraph each explaining the same policy — two places to change
/// it and two provider instances doing identical work.
///
/// The seed matters for exactly the reason both paragraphs gave: the first
/// frame has to already be right. A Persian player's cold start must not paint
/// an English LTR frame and flip, and a player who turned haptics off must not
/// get one buzz on launch while the stream catches up.
final Provider<AppSettings> appSettingsProvider = Provider<AppSettings>(
  (ref) =>
      ref.watch(settingsProvider).value ??
      ref.watch(initialAppSettingsProvider),
);

/// The engine's write path: one function, this repository's contract.
typedef SaveRun =
    Future<Result<RunCommit, DataFailure>> Function(RunDraft draft);

/// Where a finished run is written.
///
/// **A narrow seam over [runRepositoryProvider], not a second write path.** It
/// forwards to `RunRepository.saveRun` and does nothing else; this file remains
/// the single owner of the transaction, the personal-best computation and the
/// canonical row.
///
/// It exists because `RunRepository` is a `final class` — implementable only
/// inside its own library — so a test cannot substitute one. The alternative
/// was loosening a shipped boundary to an interface purely so a later epic
/// could observe a call.
///
/// It lives HERE, beside `personalBestProvider`, `allBestsProvider`,
/// `runStatsProvider`, `chartSeriesProvider` and `streakProvider`, rather than
/// in a feature folder. Those five are the read seams over the same repository;
/// a write seam filed somewhere else is one the next feature does not find, and
/// then reaches `runRepositoryProvider` directly — bypassing the observability
/// that makes persist-then-transition testable.
final Provider<SaveRun> saveRunProvider = Provider<SaveRun>(
  (ref) => ref.watch(runRepositoryProvider).saveRun,
);
