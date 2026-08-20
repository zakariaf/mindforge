import 'dart:async';

import 'package:mindforge/core/result.dart';
import 'package:mindforge/core/run_commit.dart';
import 'package:mindforge/core/run_draft.dart';
import 'package:mindforge/core/run_record.dart';
import 'package:mindforge/data/data_failure.dart';

/// Records every save, and what the run's phase was at the moment of the call.
///
/// A bare recording closure rather than a mock: there is nothing to stub and no
/// call-order protocol to verify beyond "was it called before the phase moved",
/// which is a value this fake captures rather than a rule a framework enforces.
final class FakeSaveRun {
  /// Creates a fake that succeeds.
  FakeSaveRun({this.isPersonalBest = false, this.failure});

  /// What a successful commit reports.
  final bool isPersonalBest;

  /// When set, every save fails with this.
  final DataFailure? failure;

  /// Every draft handed to it, in order.
  final List<RunDraft> saved = <RunDraft>[];

  /// What [observePhase] returned at each call.
  final List<Object?> phaseAtSave = <Object?>[];

  /// Called at the moment of a save, so the test can see the phase then.
  Object? Function()? observePhase;

  /// When set, every save waits on it.
  ///
  /// The engine's dangerous window is the await inside `_finish`: the phase
  /// deliberately stays `playing` until the write returns, so a board emission
  /// arriving DURING the save is the one that gets through. A fake that
  /// completes immediately closes that window before a test can use it, which
  /// is why a double-save test written against one passes with or without the
  /// guard.
  Completer<void>? gate;

  /// The function to hand to `saveRunProvider`.
  Future<Result<RunCommit, DataFailure>> call(RunDraft draft) async {
    saved.add(draft);
    phaseAtSave.add(observePhase?.call());

    final pending = gate;
    if (pending != null) await pending.future;

    final error = failure;
    if (error != null) {
      return Err<RunCommit, DataFailure>(error);
    }

    return Ok<RunCommit, DataFailure>(
      RunCommit(
        record: RunRecord(
          id: draft.clientRunKey,
          gameId: draft.gameId,
          difficultyId: draft.difficultyId,
          clientRunKey: draft.clientRunKey,
          startedAtUtcMs: draft.startedAtUtcMs,
          playedOnDay: draft.playedOnDay,
          durationMs: draft.durationMs,
          format: draft.format,
          metricValue: draft.metricValue,
          correctCount: draft.correctCount,
          wrongCount: draft.wrongCount,
          longestCombo: draft.longestCombo,
          totalReactionMs: draft.totalReactionMs,
          createdAtUtcMs: draft.startedAtUtcMs,
        ),
        isPersonalBest: isPersonalBest,
      ),
    );
  }
}
