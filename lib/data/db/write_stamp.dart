import 'package:clock/clock.dart';

/// The audit-column values every write stamps.
///
/// One place, so a repository cannot forget to bump `rowRevision` or stamp
/// `updatedAtUtcMs` — and so "now" comes from the injected `Clock` at every
/// write site rather than from whichever one remembered.
typedef WriteStamp = ({int updatedAtUtcMs, int rowRevision});

/// The stamp for a write that supersedes a row currently at [currentRevision].
///
/// `rowRevision` is bumped by exactly one, so a lost update is detectable.
WriteStamp nextWriteStamp(Clock clock, int currentRevision) => (
  updatedAtUtcMs: clock.now().toUtc().millisecondsSinceEpoch,
  rowRevision: currentRevision + 1,
);
