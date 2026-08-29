import 'package:mindforge/ui/pop_grid_metrics.dart';

/// The gap between cells of a [columns]-wide grid in a [side]-point slot.
///
/// **Delegates to `popGridGap`.** The derivation moved to `lib/ui/` when a
/// third board needed it; these two names stay because the rules table and its
/// tests read them, and because "which difficulties exist" is a Schulte
/// question that happens to be answered by shared arithmetic.
double schulteGap(double side, int columns) => popGridGap(side, columns);

/// One cell's side, for a [board]-wide grid of [size] columns with [gap]
/// between them.
///
/// Lives beside the rules rather than in the board widget because it is the
/// arithmetic that decides which difficulties exist.
double schulteCell(double board, int size, double gap) =>
    popGridCell(board, size, gap);
