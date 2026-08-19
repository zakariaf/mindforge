import 'package:meta/meta.dart';
import 'package:mindforge/core/run_record.dart';

/// What a successful `saveRun` returns: the durable row, and whether it beat
/// everything before it in its scope.
///
/// [isPersonalBest] is part of the commit rather than a separate read because
/// it has to be computed against the pre-write best **inside the same
/// transaction as the insert**. Two runs finishing close together would
/// otherwise both claim the badge, and a caller that reads
/// `watchPersonalBest` after the commit is racing its own write.
@immutable
final class RunCommit {
  /// Creates a commit result.
  const RunCommit({required this.record, required this.isPersonalBest});

  /// The row as it was written, with its minted id and stamped timestamps.
  final RunRecord record;

  /// Whether this run beat every prior run in its scope.
  ///
  /// **True for the first run in a scope** — the case a naive
  /// `value > currentBest` against a null best gets wrong.
  final bool isPersonalBest;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RunCommit &&
          other.record == record &&
          other.isPersonalBest == isPersonalBest;

  @override
  int get hashCode => Object.hash(record, isPersonalBest);

  @override
  String toString() => 'RunCommit(${record.id}, best: $isPersonalBest)';
}
