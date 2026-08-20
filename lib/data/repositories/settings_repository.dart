import 'package:clock/clock.dart';
import 'package:meta/meta.dart';
import 'package:mindforge/core/app_settings.dart';
import 'package:mindforge/core/result.dart';
import 'package:mindforge/data/daos/settings_dao.dart';
import 'package:mindforge/data/data_failure.dart';
import 'package:mindforge/data/db/app_database.dart';
import 'package:mindforge/data/db/store_guard.dart';
import 'package:mindforge/data/db/write_stamp.dart';
import 'package:mindforge/data/log_sink.dart';

/// The **single write path** for settings, and the single source of truth for
/// reading them.
///
/// There is no `AppSettingsNotifier` and no in-memory settings state anywhere
/// in the app: `settingsProvider` is a stream over [watch], and every write is
/// [update]. A cached copy would be a second authority that a failed write
/// silently desynchronises.
///
/// No Drift symbol appears in this class's public signature — callers see
/// [AppSettings] and [Result] only.
final class SettingsRepository {
  /// Creates the repository.
  SettingsRepository({
    required AppDatabase database,
    required SettingsDao dao,
    required Clock clock,
    required LogSink logSink,
  }) : _database = database,
       _dao = dao,
       _clock = clock,
       _logSink = logSink;

  /// Owns the transaction every write runs in.
  final AppDatabase _database;

  /// The single-table queries this repository composes.
  final SettingsDao _dao;

  /// Where "now" comes from. Never the wall clock.
  final Clock _clock;

  /// Where a handled failure is reported.
  final LogSink _logSink;

  /// The current settings, re-emitting after every committed write.
  ///
  /// Persist-before-publish: the stream re-emits because the row changed, not
  /// because a writer pushed an optimistic value at it.
  Stream<AppSettings> watch() => _dao.watch().map(_reportDegradation);

  /// Reads the settings once, without opening a stream.
  ///
  /// This is the bounded call `bootstrap()` awaits before `runApp`, so the
  /// first frame paints in the right language and with reduce-motion already
  /// honoured.
  @useResult
  Future<Result<AppSettings, DataFailure>> read() => guardStore(
    () async => _reportDegradation(await _dao.read()),
    logSink: _logSink,
  );

  /// Persists [settings], then lets [watch] re-emit.
  ///
  /// Exactly one `db.transaction`, and the returned future resolves only after
  /// the row is durable.
  @useResult
  Future<Result<AppSettings, DataFailure>> update(AppSettings settings) =>
      guardStore(() async {
        await _database.transaction(() async {
          final stamp = nextWriteStamp(_clock, await _dao.readRevision());
          await _dao.write(
            settings,
            updatedAtUtcMs: stamp.updatedAtUtcMs,
            rowRevision: stamp.rowRevision,
          );
        });
        return settings;
      }, logSink: _logSink);

  /// Applies [change] to the stored settings **inside one transaction**.
  ///
  /// The read-modify-write every single-field setter needs. Doing it as
  /// `read()` then `update()` is two round trips outside any transaction, and
  /// [update] writes the whole row rather than one column — so two settings
  /// changed close together lose one of each other. Measured shape: on E08's
  /// Settings screen, tapping a language and then a toggle before the first
  /// write lands makes whichever commits second write back the other field's
  /// stale value, silently, with both callers holding an `Ok`.
  ///
  /// [change] runs on the value read inside the transaction and must be pure —
  /// it may be called with settings that differ from anything the caller saw.
  @useResult
  Future<Result<AppSettings, DataFailure>> mutate(
    AppSettings Function(AppSettings current) change,
  ) => guardStore(() async {
    return _database.transaction(() async {
      final updated = change(_reportDegradation(await _dao.read()));
      final stamp = nextWriteStamp(_clock, await _dao.readRevision());
      await _dao.write(
        updated,
        updatedAtUtcMs: stamp.updatedAtUtcMs,
        rowRevision: stamp.rowRevision,
      );
      return updated;
    });
  }, logSink: _logSink);

  /// Reports an unrecognised stored `locale_tag` and returns the degraded
  /// value.
  ///
  /// Once per emission, so a withdrawn locale shows up in a diagnostics export
  /// instead of vanishing — and so it is not logged once per subscriber.
  AppSettings _reportDegradation(SettingsRead read) {
    final tag = read.unsupportedLocaleTag;
    if (tag != null) {
      _logSink.recordFailure(UnsupportedLocaleTag(tag));
    }
    return read.settings;
  }
}
