import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/ui/components/pop_surface.dart';

/// The gap between cells of a [columns]-wide grid in a [side]-point slot.
///
/// **Derived from the tap floor, not tuned to a device.** The design's own step
/// is 12; where 12 would drop the cell under 48pt the grid falls back to 8, and
/// there is deliberately no third value — a gap picked to make one phone look
/// right is a number nobody can re-derive.
double schulteGap(double side, int columns) =>
    schulteCell(side, columns, SunburstShape.space3) >= kPopMinTarget
    ? SunburstShape.space3
    : SunburstShape.space2;

/// One cell's side, for a [board]-wide grid of [size] columns with [gap]
/// between them.
///
/// **The gaps are between the cells, not around them** — `size - 1` of them —
/// which is the off-by-one that makes a hand-checked figure disagree with the
/// screen. Lives beside the rules rather than in the board widget because it is
/// the arithmetic that decides which difficulties exist.
double schulteCell(double board, int size, double gap) =>
    (board - gap * (size - 1)) / size;
