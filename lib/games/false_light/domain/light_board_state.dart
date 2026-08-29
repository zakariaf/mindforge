import 'package:meta/meta.dart';
import 'package:mindforge/games/false_light/domain/light_field.dart';
import 'package:mindforge/games/false_light/domain/light_scoring.dart';
import 'package:mindforge/games/false_light/domain/tile_depth.dart';

/// What one tile is showing.
///
/// **Depth is not one of these.** A tile's depth is a property of the FIELD and
/// never changes; this is what has happened to it since. Keeping the two apart
/// is what lets the golden vectors freeze a field while the board records a
/// sweep over it.
///
/// Exhaustive with no `default:` anywhere it is switched, so a fifth state does
/// not compile until every surface that draws a tile has decided what it looks
/// like.
enum LightTileState {
  /// Untouched, and tappable.
  idle,

  /// Correctly swept. It resolves and stops answering.
  swept,

  /// Tapped while raised. It wears an ink strike bar and shakes.
  rejected,

  /// Resolved: the RUN is over and this tile no longer answers anything.
  ///
  /// Not the field. A swept field deals the next one and every tile goes back
  /// to [idle]; `locked` is only ever set when the last field is cleared.
  locked,
}

/// The whole board, as one immutable value.
@immutable
final class LightBoardState {
  /// Creates a state.
  const LightBoardState({
    required this.fields,
    required this.index,
    required this.score,
    required this.tileStates,
    this.wrongTapId = 0,
    this.lastMilestone = 0,
  });

  /// The whole ladder, dealt once at build.
  ///
  /// **Never regenerated.** A live language switch changes nothing on this
  /// board — it carries no text at all — but regenerating on any rebuild would
  /// still be a different game from the one the player started, and the run's
  /// seed is what a bug report carries.
  final List<LightField> fields;

  /// Which field is being swept, from zero.
  final int index;

  /// The score so far.
  final LightScore score;

  /// One state per tile of the current field, row-major.
  final List<LightTileState> tileStates;

  /// A counter that changes on every wrong tap.
  ///
  /// **The shake latches on this, not on "a wrong tap happened".** Tapping the
  /// same raised tile twice is two mistakes and has to feel like two; without
  /// an identity that changes, the second tap looks to the animation like a
  /// rebuild of the first and plays nothing.
  final int wrongTapId;

  /// The highest streak that has already fired a milestone.
  final int lastMilestone;

  /// Whether every field has been swept.
  bool get isFinished => index >= fields.length;

  /// The field being swept, or `null` once the run is over.
  LightField? get current => isFinished ? null : fields[index];

  /// How much of the run is done, from 0 to 1.
  double get progress => fields.isEmpty ? 0 : index / fields.length;

  /// Whether every pressed tile in the current field has been swept.
  ///
  /// The field's own end condition, and the only one: a raised tile tapped by
  /// mistake costs a streak but never finishes anything.
  bool get isFieldSwept {
    final field = current;

    if (field == null) return false;

    for (var i = 0; i < field.tiles.length; i++) {
      if (field.tiles[i] == TileDepth.pressed &&
          tileStates[i] != LightTileState.swept) {
        return false;
      }
    }

    return true;
  }

  /// A copy with the named parts replaced.
  LightBoardState copyWith({
    int? index,
    LightScore? score,
    List<LightTileState>? tileStates,
    int? wrongTapId,
    int? lastMilestone,
  }) => LightBoardState(
    fields: fields,
    index: index ?? this.index,
    score: score ?? this.score,
    tileStates: tileStates ?? this.tileStates,
    wrongTapId: wrongTapId ?? this.wrongTapId,
    lastMilestone: lastMilestone ?? this.lastMilestone,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LightBoardState &&
          other.index == index &&
          other.score == score &&
          other.wrongTapId == wrongTapId &&
          other.lastMilestone == lastMilestone &&
          _sameTileStates(other.tileStates) &&
          identical(other.fields, fields);

  bool _sameTileStates(List<LightTileState> other) {
    if (other.length != tileStates.length) return false;

    for (var i = 0; i < tileStates.length; i++) {
      if (other[i] != tileStates[i]) return false;
    }

    return true;
  }

  @override
  int get hashCode => Object.hash(
    index,
    score,
    wrongTapId,
    lastMilestone,
    Object.hashAll(tileStates),
    fields.length,
  );
}
