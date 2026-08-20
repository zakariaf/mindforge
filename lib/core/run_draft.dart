import 'package:meta/meta.dart';
import 'package:mindforge/core/calendar_day.dart';
import 'package:mindforge/core/score_format.dart';

/// A finished run as the engine hands it to the repository, before the store
/// has stamped it.
///
/// Deliberately carries **no id and no timestamps**: those are the repository's
/// to mint from the injected `IdGenerator` and `Clock`. A draft that arrived
/// with its own id would make the write path untestable and let two callers
/// disagree about what "now" is.
@immutable
final class RunDraft {
  /// Creates a draft.
  const RunDraft({
    required this.gameId,
    required this.difficultyId,
    required this.clientRunKey,
    required this.startedAtUtcMs,
    required this.playedOnDay,
    required this.durationMs,
    required this.format,
    required this.metricValue,
    required this.correctCount,
    required this.wrongCount,
    required this.longestCombo,
    required this.totalReactionMs,
  });

  /// Which game, as an ASCII token. Never a display title.
  final String gameId;

  /// Which difficulty, as an ASCII token. Never a display title.
  final String difficultyId;

  /// The idempotency key, minted once per run by the engine, so a retried write
  /// cannot record the run twice.
  final String clientRunKey;

  /// When the run started, as UTC epoch milliseconds.
  final int startedAtUtcMs;

  /// The local civil day the run counts towards.
  final CalendarDay playedOnDay;

  /// How long the run lasted, in milliseconds.
  final int durationMs;

  /// How to read [metricValue].
  final ScoreFormat format;

  /// The score, in the unit [format] names.
  final int metricValue;

  /// How many answers were correct.
  final int correctCount;

  /// How many answers were wrong.
  final int wrongCount;

  /// The longest unbroken run of correct answers. Never more than
  /// [correctCount].
  final int longestCombo;

  /// The **sum** of every reaction time in milliseconds.
  final int totalReactionMs;

  /// A copy with any field replaced.
  ///
  /// Unlike `AppSettings.copyWith`, every field here is non-nullable, so
  /// `null` unambiguously means "leave it alone" and there is no sentinel
  /// problem to design around.
  RunDraft copyWith({
    String? gameId,
    String? difficultyId,
    String? clientRunKey,
    int? startedAtUtcMs,
    CalendarDay? playedOnDay,
    int? durationMs,
    ScoreFormat? format,
    int? metricValue,
    int? correctCount,
    int? wrongCount,
    int? longestCombo,
    int? totalReactionMs,
  }) => RunDraft(
    gameId: gameId ?? this.gameId,
    difficultyId: difficultyId ?? this.difficultyId,
    clientRunKey: clientRunKey ?? this.clientRunKey,
    startedAtUtcMs: startedAtUtcMs ?? this.startedAtUtcMs,
    playedOnDay: playedOnDay ?? this.playedOnDay,
    durationMs: durationMs ?? this.durationMs,
    format: format ?? this.format,
    metricValue: metricValue ?? this.metricValue,
    correctCount: correctCount ?? this.correctCount,
    wrongCount: wrongCount ?? this.wrongCount,
    longestCombo: longestCombo ?? this.longestCombo,
    totalReactionMs: totalReactionMs ?? this.totalReactionMs,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RunDraft &&
          other.gameId == gameId &&
          other.difficultyId == difficultyId &&
          other.clientRunKey == clientRunKey &&
          other.startedAtUtcMs == startedAtUtcMs &&
          other.playedOnDay == playedOnDay &&
          other.durationMs == durationMs &&
          other.format == format &&
          other.metricValue == metricValue &&
          other.correctCount == correctCount &&
          other.wrongCount == wrongCount &&
          other.longestCombo == longestCombo &&
          other.totalReactionMs == totalReactionMs;

  @override
  int get hashCode => Object.hashAll(<Object?>[
    gameId,
    difficultyId,
    clientRunKey,
    startedAtUtcMs,
    playedOnDay,
    durationMs,
    format,
    metricValue,
    correctCount,
    wrongCount,
    longestCombo,
    totalReactionMs,
  ]);

  @override
  String toString() =>
      'RunDraft($gameId/$difficultyId, $clientRunKey, $metricValue)';
}
