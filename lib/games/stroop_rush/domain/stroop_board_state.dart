import 'package:meta/meta.dart';
import 'package:mindforge/games/stroop_rush/domain/stroop_round.dart';
import 'package:mindforge/games/stroop_rush/domain/stroop_scoring.dart';

/// What one answer key is showing.
///
/// Exhaustive with no `default:` anywhere it is switched, so a fifth state does
/// not compile until every surface that draws a key has decided what it looks
/// like.
enum AnswerKeyState {
  /// Untouched, and tappable.
  idle,

  /// The right answer, just taken. It lifts and holds.
  accepted,

  /// The wrong answer, just taken. It sinks, wears an ink strike bar and
  /// shakes.
  rejected,

  /// Resolved: the round is over and this key no longer answers anything.
  ///
  /// A locked key drops its `onTap` rather than passing `enabled: false` —
  /// `sunburst-components` rule 6 — so it does not read as a control that
  /// failed.
  locked,
}

/// The whole board, as one immutable value.
@immutable
final class StroopBoardState {
  /// Creates a state.
  const StroopBoardState({
    required this.rounds,
    required this.index,
    required this.score,
    required this.keyStates,
    required this.isColourBlindPalette,
    this.wrongKeyIndex,
    this.wrongTapId = 0,
    this.lastMilestone = 0,
  });

  /// The whole deck, dealt once at build.
  ///
  /// **Never regenerated.** A live language switch re-formats the pills and
  /// leaves this identical; regenerating would deal a Persian player a
  /// different game from the one they started.
  final List<StroopRound> rounds;

  /// Which round is being asked, from zero.
  final int index;

  /// The score so far.
  final StroopScore score;

  /// One state per offered key, in the order the round offers them.
  final List<AnswerKeyState> keyStates;

  /// Whether this run was dealt for the colour-blind palette.
  ///
  /// Read off the STATE at paint time rather than off the setting, so a player
  /// who flips it mid-run keeps the palette they were dealt.
  final bool isColourBlindPalette;

  /// Which key was tapped wrongly, or `null` when none was.
  final int? wrongKeyIndex;

  /// A counter that changes on every wrong tap.
  ///
  /// **The shake latches on this, not on "a wrong answer happened".** Tapping
  /// the same wrong key twice is two answers and has to feel like two; without
  /// an identity that changes, the second tap looks to the animation like a
  /// rebuild of the first and plays nothing.
  final int wrongTapId;

  /// The highest streak that has already fired a milestone.
  ///
  /// The latch `sunburst-motion-and-haptics` names `lastMilestone`: a boundary
  /// condition is true on every frame AFTER it happens, so something has to
  /// remember it already fired.
  final int lastMilestone;

  /// Whether every round has been answered.
  bool get isFinished => index >= rounds.length;

  /// The round being asked, or `null` once the run is over.
  StroopRound? get current => isFinished ? null : rounds[index];

  /// How much of the run is done, from 0 to 1.
  double get progress => rounds.isEmpty ? 0 : index / rounds.length;

  /// A copy with the named parts replaced.
  ///
  /// `wrongKeyIndex` takes a `clearWrongKey` flag rather than a nullable
  /// sentinel: `copyWith(wrongKeyIndex: null)` cannot mean "clear it" and
  /// "leave it" at once, and a correct answer needs the first.
  StroopBoardState copyWith({
    int? index,
    StroopScore? score,
    List<AnswerKeyState>? keyStates,
    int? wrongKeyIndex,
    bool clearWrongKey = false,
    int? wrongTapId,
    int? lastMilestone,
  }) => StroopBoardState(
    rounds: rounds,
    index: index ?? this.index,
    score: score ?? this.score,
    keyStates: keyStates ?? this.keyStates,
    isColourBlindPalette: isColourBlindPalette,
    wrongKeyIndex: clearWrongKey ? null : (wrongKeyIndex ?? this.wrongKeyIndex),
    wrongTapId: wrongTapId ?? this.wrongTapId,
    lastMilestone: lastMilestone ?? this.lastMilestone,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StroopBoardState &&
          other.index == index &&
          other.score == score &&
          other.wrongKeyIndex == wrongKeyIndex &&
          other.wrongTapId == wrongTapId &&
          other.lastMilestone == lastMilestone &&
          other.isColourBlindPalette == isColourBlindPalette &&
          _sameKeyStates(other.keyStates) &&
          identical(other.rounds, rounds);

  bool _sameKeyStates(List<AnswerKeyState> other) {
    if (other.length != keyStates.length) return false;

    for (var i = 0; i < keyStates.length; i++) {
      if (other[i] != keyStates[i]) return false;
    }

    return true;
  }

  @override
  int get hashCode => Object.hash(
    index,
    score,
    wrongKeyIndex,
    wrongTapId,
    lastMilestone,
    isColourBlindPalette,
    Object.hashAll(keyStates),
    rounds.length,
  );
}
