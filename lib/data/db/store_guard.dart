// Imported from isolate.dart rather than remote.dart: the type is identical
// (isolate.dart re-exports it) and remote.dart is marked experimental, while
// the isolate library is the documented surface for exactly the connection
// production uses.
import 'package:drift/isolate.dart' show DriftRemoteException;
import 'package:mindforge/core/result.dart';
import 'package:mindforge/data/data_failure.dart';
import 'package:mindforge/data/log_sink.dart';
import 'package:sqlite3/common.dart' show SqliteException;

/// Runs [action], converting **any** store failure into a typed [DataFailure].
///
/// This is the one conversion-at-boundary site for the data layer, and it exists
/// because catching `SqliteException` alone is wrong in the shipped app.
/// Production opens the store through `NativeDatabase.createInBackground`,
/// which runs it in a drift isolate, and drift wraps every error crossing back
/// from that isolate in a [DriftRemoteException]. A repository that catches only
/// `SqliteException` therefore catches nothing in production while passing every
/// test, because the tests open `NativeDatabase.memory()` directly and there is
/// no isolate hop to wrap anything.
///
/// [StateError] is caught too, for a narrower reason: drift's `getSingle()` and
/// `watchSingle()` throw it when the row is absent. The settings row is seeded
/// only under `wasCreated`, so a database whose `user_version` is already
/// current but whose row is missing — a restored file, a partially applied
/// migration — must degrade to a typed failure rather than take down
/// `bootstrap()`.
///
/// [classify] turns a recognised [SqliteException] into the failure that fits
/// the operation; anything it declines, and anything that is not a
/// [SqliteException] at all, becomes [StoreUnavailable].
Future<Result<T, DataFailure>> guardStore<T>(
  Future<T> Function() action, {
  required LogSink logSink,
  DataFailure? Function(SqliteException error)? classify,
}) async {
  try {
    return Ok<T, DataFailure>(await action());
  } on DriftRemoteException catch (error, stackTrace) {
    // The isolate hop. The interesting exception is inside.
    final cause = error.remoteCause;
    return _fail(
      logSink: logSink,
      classify: classify,
      error: cause,
      // The remote stack trace is the one that names the failing statement; the
      // local one only names the isolate boundary.
      stackTrace: error.remoteStackTrace ?? stackTrace,
    );
  } on SqliteException catch (error, stackTrace) {
    return _fail(
      logSink: logSink,
      classify: classify,
      error: error,
      stackTrace: stackTrace,
    );
    // avoid_catching_errors is right in general and wrong here. This is a
    // boundary conversion of a DOCUMENTED drift behaviour — getSingle() and
    // watchSingle() throw StateError when the row is absent — and the
    // alternative is bootstrap() dying before runApp on a database that is
    // merely missing a row it can re-seed.
    // ignore: avoid_catching_errors
  } on StateError catch (error, stackTrace) {
    return _fail(
      logSink: logSink,
      classify: classify,
      error: error,
      stackTrace: stackTrace,
    );
  }
}

Result<T, DataFailure> _fail<T>({
  required LogSink logSink,
  required DataFailure? Function(SqliteException error)? classify,
  required Object error,
  required StackTrace stackTrace,
}) {
  final failure = error is SqliteException
      ? classify?.call(error) ?? const StoreUnavailable()
      : const StoreUnavailable();

  // Logged BEFORE the typed failure is returned, with the original error and
  // its stack. A DataFailure carries no stack trace by design, so if it is not
  // recorded here it is gone forever.
  logSink.recordFailure(failure, error: error, stackTrace: stackTrace);
  return Err<T, DataFailure>(failure);
}
