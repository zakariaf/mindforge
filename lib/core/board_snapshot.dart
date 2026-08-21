import 'package:meta/meta.dart';
import 'package:mindforge/core/hud_tone.dart';
import 'package:mindforge/core/result_stat.dart';
import 'package:mindforge/core/run_outcome.dart';

/// One value a HUD pill shows.
///
/// `(labelKey, canonicalValue, format, tone)` — a key and an integer, never a
/// display string. The shell/game reference declares this slot with a rendered
/// label and value; widening it is deliberate. A slot built inside a board
/// would otherwise need `AppLocalizations` in domain code, and a slot holding
/// `"۱۸٫۶ ثانیه"` goes stale the instant the player changes language.
///
/// E08's `HudPill` resolves the key and formats the value at render.
@immutable
final class HudSlot {
  /// Creates a slot.
  const HudSlot({
    required this.labelKey,
    required this.canonicalValue,
    required this.format,
    this.tone = HudTone.neutral,
    this.source = HudSource.board,
  });

  /// The ARB key naming this slot.
  final String labelKey;

  /// The value, in [format]'s canonical unit.
  final int canonicalValue;

  /// How to render [canonicalValue].
  final StatFormat format;

  /// How the shell should style it.
  ///
  /// Defaults to [HudTone.neutral]: a game never reaches for `alarm` itself.
  /// Whether time is running out is the shell's judgement, made against the
  /// run limit the shell owns.
  final HudTone tone;

  /// Who fills [canonicalValue].
  final HudSource source;

  /// A copy of this slot showing [canonicalValue] instead.
  HudSlot withValue(int canonicalValue) => HudSlot(
    labelKey: labelKey,
    canonicalValue: canonicalValue,
    format: format,
    tone: tone,
    source: source,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HudSlot &&
          other.labelKey == labelKey &&
          other.canonicalValue == canonicalValue &&
          other.format == format &&
          other.tone == tone &&
          other.source == source;

  @override
  int get hashCode =>
      Object.hash(labelKey, canonicalValue, format, tone, source);

  @override
  String toString() => 'HudSlot($labelKey, $canonicalValue, ${tone.name})';
}

/// Who fills a [HudSlot]'s value.
///
/// **A game has no clock of its own** — `sunburst-shell-screens` rule 3 — so a
/// board that wants to show elapsed time cannot supply it. It declares the slot
/// and names the shell as its source; the run state substitutes the run's own
/// elapsed before anything renders.
///
/// The alternative was for the shell to recognise a magic label key, which is
/// the `switch (gameId)` argument one level down: the second game would spell
/// its time key differently and the pill would silently freeze again.
enum HudSource {
  /// The board's own number, passed through untouched.
  board,

  /// The run's elapsed time, in milliseconds, filled in by the shell.
  runClock,
}

/// The HUD, which is exactly three slots.
///
/// Three because the play band is a three-column strip in `app.html`, and the
/// type is what makes a fourth unrepresentable — a list would let a game push
/// one more and discover the overflow on a 320pt phone in German.
///
/// [trailing] is nullable: Schulte Grid has nothing to put there.
@immutable
final class GameHud {
  /// Creates a HUD.
  const GameHud({required this.leading, required this.middle, this.trailing});

  /// The start-edge slot.
  final HudSlot leading;

  /// The centre slot.
  final HudSlot middle;

  /// The end-edge slot, or `null` when the game has only two values.
  final HudSlot? trailing;

  /// The slots that are present, in reading order.
  List<HudSlot> get slots => <HudSlot>[leading, middle, ?trailing];

  /// A copy with every [HudSource.runClock] slot showing [elapsedMs].
  GameHud withRunClock(int elapsedMs) => GameHud(
    leading: _filled(leading, elapsedMs),
    middle: _filled(middle, elapsedMs),
    trailing: trailing == null ? null : _filled(trailing!, elapsedMs),
  );

  static HudSlot _filled(HudSlot slot, int elapsedMs) => switch (slot.source) {
    HudSource.board => slot,
    HudSource.runClock => slot.withValue(elapsedMs),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameHud &&
          other.leading == leading &&
          other.middle == middle &&
          other.trailing == trailing;

  @override
  int get hashCode => Object.hash(leading, middle, trailing);
}

/// What a board reports upward on every frame it changes.
///
/// The **only** channel from a game to the shell. A board does not navigate,
/// does not end the run and does not touch the clock; it publishes one of these
/// and the shell decides what that means.
///
/// [outcome] is `null` for a live run — the shell reads that as "keep going".
@immutable
final class BoardSnapshot {
  /// Creates a snapshot.
  const BoardSnapshot({
    required this.hud,
    this.progress,
    this.outcome,
    this.score = 0,
    this.correctCount = 0,
    this.wrongCount = 0,
    this.longestCombo = 0,
    this.totalReactionMs = 0,
  }) : assert(
         progress == null || (progress >= 0 && progress <= 1),
         'progress is a ratio in [0, 1] or null for a board with no measurable '
         'progress. A count belongs in a HUD slot.',
       );

  /// The three values the shell renders above the board.
  final GameHud hud;

  /// How far through the board is, from 0 to 1, or `null` when it cannot say.
  final double? progress;

  /// The run's result, or `null` while it is still going.
  final RunOutcome? outcome;

  /// The score so far, in the game's `ScoreFormat` canonical unit.
  ///
  /// **The snapshot is the one authority for a run's numbers**, and it carries
  /// them on every frame rather than only at the end. That is what lets the
  /// shell end a timed run when the clock expires: a Blitz round's normal
  /// ending is the timer, the board never gets to declare an outcome, and
  /// before this field existed that run was persisted as ABANDONED with a
  /// score of zero. Measured — it was the only ending Stroop Blitz had.
  final int score;

  /// How many answers were right.
  ///
  /// One of four canonical counters E02's `runs` table stores and E08's stats
  /// screen aggregates. They live here rather than on the outcome for the same
  /// reason [score] does: a run can end without the board declaring anything,
  /// and the counters still have to reach the row.
  ///
  /// Zero is a legitimate value for a game that has no notion of wrong answers
  /// — Schulte Grid does not — which is why they default rather than being
  /// required.
  final int correctCount;

  /// How many answers were wrong.
  final int wrongCount;

  /// The longest unbroken run of right answers.
  final int longestCombo;

  /// The total time spent answering, in milliseconds.
  final int totalReactionMs;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoardSnapshot &&
          other.hud == hud &&
          other.progress == progress &&
          other.outcome == outcome &&
          other.score == score &&
          other.correctCount == correctCount &&
          other.wrongCount == wrongCount &&
          other.longestCombo == longestCombo &&
          other.totalReactionMs == totalReactionMs;

  @override
  int get hashCode => Object.hash(
    hud,
    progress,
    outcome,
    score,
    correctCount,
    wrongCount,
    longestCombo,
    totalReactionMs,
  );
}
