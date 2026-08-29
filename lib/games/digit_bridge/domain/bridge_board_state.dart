import 'package:meta/meta.dart';
import 'package:mindforge/games/digit_bridge/domain/bridge_round.dart';
import 'package:mindforge/games/digit_bridge/domain/bridge_scoring.dart';

/// What one candidate chip is showing.
///
/// Exhaustive with no `default:` anywhere it is switched, so a fifth state does
/// not compile until every surface that draws a chip has decided what it looks
/// like.
enum BridgeChipState {
  /// Untouched, and tappable.
  idle,

  /// A near-miss, just taken. It sinks, wears an ink strike bar and shakes.
  rejected,

  /// Resolved: the run is over and this chip no longer answers anything.
  ///
  /// A locked chip drops its `onTap` rather than passing `enabled: false` —
  /// `sunburst-components` rule 6 — so it does not read as a control that
  /// failed.
  locked,
}

/// The whole board, as one immutable value.
@immutable
final class BridgeBoardState {
  /// Creates a state.
  const BridgeBoardState({
    required this.rounds,
    required this.index,
    required this.score,
    required this.chipStates,
    this.wrongTapId = 0,
    this.lastMilestone = 0,
  });

  /// The whole run, dealt once at build.
  ///
  /// **Never regenerated.** A live language switch re-renders both numeral runs
  /// and leaves this identical; regenerating would deal a player who switched
  /// to Persian mid-run a different game from the one they started — which for
  /// this game would also silently change the question, since the language
  /// decides which script each side of the bridge is drawn in.
  final List<BridgeRound> rounds;

  /// Which round is being asked, from zero.
  final int index;

  /// The score so far.
  final BridgeScore score;

  /// One state per chip, in the order the round lays them out.
  final List<BridgeChipState> chipStates;

  /// A counter that changes on every wrong tap.
  ///
  /// **The shake latches on this, not on "a wrong answer happened".** Tapping
  /// the same wrong chip twice is two answers and has to feel like two;
  /// without an identity that changes, the second tap looks to the animation
  /// like a rebuild of the first and plays nothing.
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
  BridgeRound? get current => isFinished ? null : rounds[index];

  /// How much of the run is done, from 0 to 1.
  double get progress => rounds.isEmpty ? 0 : index / rounds.length;

  /// A copy with the named parts replaced.
  BridgeBoardState copyWith({
    int? index,
    BridgeScore? score,
    List<BridgeChipState>? chipStates,
    int? wrongTapId,
    int? lastMilestone,
  }) => BridgeBoardState(
    rounds: rounds,
    index: index ?? this.index,
    score: score ?? this.score,
    chipStates: chipStates ?? this.chipStates,
    wrongTapId: wrongTapId ?? this.wrongTapId,
    lastMilestone: lastMilestone ?? this.lastMilestone,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BridgeBoardState &&
          other.index == index &&
          other.score == score &&
          other.wrongTapId == wrongTapId &&
          other.lastMilestone == lastMilestone &&
          _sameChipStates(other.chipStates) &&
          identical(other.rounds, rounds);

  bool _sameChipStates(List<BridgeChipState> other) {
    if (other.length != chipStates.length) return false;

    for (var i = 0; i < chipStates.length; i++) {
      if (other[i] != chipStates[i]) return false;
    }

    return true;
  }

  @override
  int get hashCode => Object.hash(
    index,
    score,
    wrongTapId,
    lastMilestone,
    Object.hashAll(chipStates),
    rounds.length,
  );
}
