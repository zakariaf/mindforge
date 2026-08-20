import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindforge/core/run_config.dart';
import 'package:mindforge/games/schulte_grid/application/schulte_board_notifier.dart';
import 'package:mindforge/games/schulte_grid/domain/schulte_board_state.dart';
import 'package:mindforge/games/schulte_grid/domain/schulte_tile_state.dart';
import 'package:mindforge/games/schulte_grid/ui/board/schulte_tile.dart';
import 'package:mindforge/games/schulte_grid/ui/schulte_grid_metrics.dart';
import 'package:mindforge/games/schulte_grid/ui/schulte_tile_label.dart';
import 'package:mindforge/l10n/app_localizations.dart';
import 'package:mindforge/l10n/l10n_providers.dart';

/// The board rectangle, and nothing outside it.
///
/// **It draws no chrome.** No `Scaffold`, no `SafeArea`, no HUD pill, no
/// progress track, no route, no clock, and no background — the shell has
/// already painted turquoise behind it, because the definition asked for
/// `BoardBackground.gameAccent`. A board that painted its own would be the
/// second owner of a colour.
///
/// **The grid is pinned LTR and the chrome around it is not.** A Schulte grid
/// is a visual SEARCH FIELD, not a text flow: the scramble is uniform over
/// positions, there is no reading order, and the whole exercise is that a
/// systematic scan does not help. Mirroring it would convey nothing a Persian
/// or Sorani player does not already have — a mirrored scramble is just another
/// scramble — while costing three real things: `cells[0]` would stop meaning a
/// screen position, so every geometry assertion and the reference PNG fork per
/// direction; the board interior, the one part of this screen that is supposed
/// to be identical everywhere, would become locale-dependent; and the numeral
/// itself does not mirror anyway, since `۲۵` is written most-significant-digit
/// first exactly like `25`.
///
/// The counter-argument is recorded rather than dismissed: a Persian reader's
/// habitual first glance is top-right, so under `fa` the eye starts on a
/// different cell. That is a difference in where a BAD strategy starts —
/// Schulte is practised with a fixed central gaze — and if a native reviewer
/// disagrees the change is this one `Directionality` and a second reference
/// PNG, which is E11's to make.
class SchulteBoard extends ConsumerStatefulWidget {
  /// Creates the board for [run].
  const SchulteBoard({required this.run, super.key});

  /// Which run is being played.
  final RunConfig run;

  @override
  ConsumerState<SchulteBoard> createState() => _SchulteBoardState();
}

class _SchulteBoardState extends ConsumerState<SchulteBoard> {
  @override
  void initState() {
    super.initState();

    // THE BOARD OPENS WHEN IT IS ON SCREEN. The notifier is built at the run's
    // `start()`, three seconds before the countdown ends, and every tile is
    // `disabled` until this fires — otherwise a tap during 3-2-1 would count.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      ref.read(schulteBoardNotifierProvider(widget.run).notifier).start();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(schulteBoardNotifierProvider(widget.run));
    final l10n = AppLocalizations.of(context);
    // ONCE PER BOARD, not once per tile: twenty-five tiles each formatting
    // their own value is twenty-five allocations a frame for a list that only
    // changes when the locale does.
    final labels = schulteTileLabels(
      state.cells,
      ref.watch(localeNumbersProvider),
    );

    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: LayoutBuilder(
          builder: (context, constraints) => Directionality(
            // The sanctioned locale-invariant coordinate space: this subtree
            // pins its own direction, and the chrome outside it still mirrors
            // from the resolved locale. See the note on this class for why,
            // and for what changing it would cost.
            textDirection: TextDirection.ltr,
            child: _Grid(
              state: state,
              labels: labels,
              l10n: l10n,
              side: constraints.biggest.shortestSide,
              onTap: (index) => ref
                  .read(schulteBoardNotifierProvider(widget.run).notifier)
                  .tapCell(index),
            ),
          ),
        ),
      ),
    );
  }
}

/// The tiles, laid out square.
class _Grid extends StatelessWidget {
  const _Grid({
    required this.state,
    required this.labels,
    required this.l10n,
    required this.side,
    required this.onTap,
  });

  final SchulteBoardState state;
  final List<String> labels;
  final AppLocalizations l10n;
  final double side;
  final void Function(int index) onTap;

  @override
  Widget build(BuildContext context) {
    final columns = state.columnCount;
    final gap = schulteGap(side, columns);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      // Clip.none, or the e1 shadow and the next tile's 5pt ring are sheared
      // off at the grid's edge — a ring that stops at a bounding box looks
      // like a rendering glitch rather than a layout mistake.
      clipBehavior: Clip.none,
      padding: EdgeInsets.zero,
      itemCount: state.cellCount,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: gap,
        mainAxisSpacing: gap,
      ),
      itemBuilder: (context, index) {
        final tileState = state.stateOf(index);

        return Semantics(
          // AUTHORED, so the reading order is the board's own order in both
          // directions — the grid is pinned LTR and traversal follows it.
          sortKey: OrdinalSortKey(index.toDouble()),
          child: SchulteTile(
            // KEYED BY VALUE, not by index: a re-tap cannot act on a stale
            // capture, and the value is what identifies a tile to a player.
            key: ValueKey<int>(state.cells[index]),
            label: labels[index],
            semanticLabel: labels[index],
            state: tileState,
            wrongTapId: state.wrongTapId,
            onTap:
                tileState == SchulteTileState.found ||
                    tileState == SchulteTileState.disabled
                ? null
                : () => onTap(index),
          ),
        );
      },
    );
  }
}
