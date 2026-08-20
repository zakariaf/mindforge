import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindforge/core/result.dart';
import 'package:mindforge/core/run_commit.dart';
import 'package:mindforge/core/run_draft.dart';
import 'package:mindforge/data/data_failure.dart';
import 'package:mindforge/data/data_providers.dart';

/// The engine's write path: one function, E02's contract.
typedef SaveRun =
    Future<Result<RunCommit, DataFailure>> Function(RunDraft draft);

/// Where a finished run is written.
///
/// **A narrow seam over `runRepositoryProvider`, not a second write path.** It
/// forwards to `RunRepository.saveRun` and does nothing else; E02 remains the
/// single owner of the transaction, the personal-best computation and the
/// canonical row.
///
/// It exists because `RunRepository` is a `final class` — implementable only
/// inside its own library — so a test cannot substitute one. The alternative
/// was to loosen E02's class to an interface purely so this epic could observe
/// a call, which is a change to a shipped boundary for a testing convenience.
/// A one-line function seam is smaller and says what it is for.
///
/// It is what lets `run_notifier_test` assert the thing that matters most here:
/// that the row is written BEFORE the phase becomes `over`.
final Provider<SaveRun> saveRunProvider = Provider<SaveRun>(
  (ref) => ref.watch(runRepositoryProvider).saveRun,
);
