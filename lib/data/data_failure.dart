import 'package:meta/meta.dart';
import 'package:mindforge/core/failure.dart';

/// Everything the data boundary can fail with.
///
/// Sealed, so a call site switches exhaustively with no `default:` and adding a
/// case is a compile error everywhere it matters. Every leaf carries **typed
/// parameters and no sentence** — the data layer has no idea which of four
/// locales the reader is in, and a message baked in here is a string the ARB
/// cannot translate and the log cannot parse.
@immutable
sealed class DataFailure extends Failure {
  /// Creates a data failure.
  const DataFailure();
}

/// The store could not be reached at all — closed, locked, or missing.
@immutable
final class StoreUnavailable extends DataFailure {
  /// Creates the failure.
  const StoreUnavailable();

  @override
  String get code => 'data.store_unavailable';

  @override
  bool operator ==(Object other) => other is StoreUnavailable;

  @override
  int get hashCode => code.hashCode;
}

/// A schema constraint rejected the row.
@immutable
final class ConstraintViolated extends DataFailure {
  /// Creates the failure, naming the [constraint] that rejected the write.
  const ConstraintViolated(this.constraint);

  /// The column or constraint SQLite named, such as `longest_combo`.
  final String constraint;

  @override
  String get code => 'data.constraint_violated';

  @override
  bool operator ==(Object other) =>
      other is ConstraintViolated && other.constraint == constraint;

  @override
  int get hashCode => Object.hash(code, constraint);
}

/// A run with this client key is already recorded.
///
/// This is the **success** shape of idempotency, not a bug: the engine retried
/// a write it could not confirm, and the store is telling it the first attempt
/// landed.
@immutable
final class RunAlreadyRecorded extends DataFailure {
  /// Creates the failure for [clientRunKey].
  const RunAlreadyRecorded(this.clientRunKey);

  /// The idempotency key that already exists.
  final String clientRunKey;

  @override
  String get code => 'data.run_already_recorded';

  @override
  bool operator ==(Object other) =>
      other is RunAlreadyRecorded && other.clientRunKey == clientRunKey;

  @override
  int get hashCode => Object.hash(code, clientRunKey);
}

/// The thing asked for does not exist.
@immutable
final class NotFound extends DataFailure {
  /// Creates the failure, naming [what] was looked for.
  const NotFound(this.what);

  /// The identifier that matched nothing, such as an unregistered `gameId`.
  final String what;

  @override
  String get code => 'data.not_found';

  @override
  bool operator ==(Object other) => other is NotFound && other.what == what;

  @override
  int get hashCode => Object.hash(code, what);
}

/// A stored row cannot be interpreted, even though the schema accepted it.
///
/// The case this exists for: one scope holding rows of two different
/// `ScoreFormat`s, where comparing them would silently rank a point total
/// against a millisecond count.
@immutable
final class CorruptRow extends DataFailure {
  /// Creates the failure for [table], describing the inconsistency in [detail].
  const CorruptRow(this.table, this.detail);

  /// Which table the row is in.
  final String table;

  /// A short machine-oriented description of the inconsistency. Not a sentence
  /// for a user.
  final String detail;

  @override
  String get code => 'data.corrupt_row';

  @override
  bool operator ==(Object other) =>
      other is CorruptRow && other.table == table && other.detail == detail;

  @override
  int get hashCode => Object.hash(code, table, detail);
}

/// The stored `locale_tag` is well-formed but is not a locale this build ships.
///
/// Reported rather than repaired: see `SettingsRepository`, which degrades the
/// read to "follow the system locale" and leaves the column alone.
@immutable
final class UnsupportedLocaleTag extends DataFailure {
  /// Creates the failure for the offending [tag].
  const UnsupportedLocaleTag(this.tag);

  /// The raw tag as stored, carried for the log line.
  final String tag;

  @override
  String get code => 'data.unsupported_locale_tag';

  @override
  bool operator ==(Object other) =>
      other is UnsupportedLocaleTag && other.tag == tag;

  @override
  int get hashCode => Object.hash(code, tag);
}
