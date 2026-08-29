import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/ui/components/pop_surface.dart';

/// One cell's side, for a [extent]-wide grid of [count] cells with [gap]
/// between them.
///
/// **The gaps are between the cells, not around them** — `count - 1` of them —
/// which is the off-by-one that makes a hand-checked figure disagree with the
/// screen.
double popGridCell(double extent, int count, double gap) =>
    (extent - gap * (count - 1)) / count;

/// The gap between cells of a [count]-wide grid in an [extent]-point slot.
///
/// **Derived from the tap floor, not tuned to a device.** The design's own step
/// is 12; where 12 would drop the cell under [kPopMinTarget] the grid falls back
/// to 8, and there is deliberately no third value — a gap picked to make one
/// phone look right is a number nobody can re-derive.
///
/// **One copy, in `lib/ui/`, because three boards need it.** Schulte Grid wrote
/// it first and Digit Bridge and False Light each copied it, which is how a
/// 48pt accessibility floor ends up with three places to change and one test.
/// `lib/games/**` may not import another game, but `lib/ui/` is shared and both
/// new boards already import `pop_surface.dart` for the floor itself.
///
/// The per-game constants — how many columns, what aspect a cell takes, whether
/// the height axis can bind — stay with each board. Only the derivation is here.
double popGridGap(double extent, int count) =>
    popGridCell(extent, count, SunburstShape.space3) >= kPopMinTarget
    ? SunburstShape.space3
    : SunburstShape.space2;
