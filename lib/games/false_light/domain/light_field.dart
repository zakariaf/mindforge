import 'package:meta/meta.dart';
import 'package:mindforge/games/false_light/domain/tile_depth.dart';

/// One dealt field: a rectangle of tiles, some of them pressed.
///
/// **It carries no string and no colour.** Every member here is an integer or a
/// [TileDepth], which is what lets a golden vector be byte-identical in four
/// locales while the screen paints the same board in two reading directions.
/// There is nothing on this type for a translator to touch.
///
/// **And no clock.** A field is finished when its last pressed tile is swept,
/// not when a timer expires, so nothing here needs to know what time it is —
/// which is what keeps `lib/games/false_light/` free of the run timer the shell
/// owns.
@immutable
final class LightField {
  /// Creates a field.
  const LightField({
    required this.index,
    required this.columns,
    required this.rows,
    required this.tiles,
  });

  /// Where this field sits in the run, from zero.
  final int index;

  /// How many tiles across.
  final int columns;

  /// How many tiles down.
  final int rows;

  /// Every tile's depth, **row-major**: index `row * columns + column`.
  ///
  /// One flat list rather than a list of lists. A nested list would make the
  /// row the unit of equality and of the canonical form, and a field whose rows
  /// were equal pairwise but whose nesting differed would compare unequal to
  /// itself after a round-trip.
  final List<TileDepth> tiles;

  /// How many tiles the field holds.
  int get tileCount => tiles.length;

  /// How many tiles the player has to sweep to finish this field.
  ///
  /// **Derived, never stored.** A `pressedCount` field would be a second copy
  /// of [tiles] that can disagree with it, and the disagreement would surface
  /// as a field that never completes — the worst possible failure for a game
  /// whose only end condition is completion.
  int get pressedCount =>
      tiles.where((depth) => depth == TileDepth.pressed).length;

  /// The depth at [column], [row].
  ///
  /// The board hit-tests in grid coordinates, so the row-major arithmetic lives
  /// here once instead of at every call site that could get it backwards.
  TileDepth depthAt(int column, int row) => tiles[row * columns + column];

  /// This field as a stable string, for a golden vector.
  ///
  /// **Enum INDICES, never `name` and never `toString()`.** Both are one
  /// refactor away from a translated string, and a vector that moved with the
  /// language would mean localisation had leaked into generation. The field
  /// order is part of the contract: changing it invalidates every frozen row.
  String canonical() =>
      '$index:$columns:$rows:'
      '${tiles.map((depth) => depth.index).join(',')}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LightField &&
          other.index == index &&
          other.columns == columns &&
          other.rows == rows &&
          _sameTiles(other.tiles);

  bool _sameTiles(List<TileDepth> other) {
    if (other.length != tiles.length) return false;

    for (var i = 0; i < tiles.length; i++) {
      if (other[i] != tiles[i]) return false;
    }

    return true;
  }

  @override
  int get hashCode => Object.hash(index, columns, rows, Object.hashAll(tiles));

  @override
  String toString() => 'LightField(${canonical()})';
}
