import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindforge/core/run_config.dart';
import 'package:mindforge/games/false_light/application/light_board_notifier.dart';
import 'package:mindforge/games/false_light/domain/light_board_state.dart';
import 'package:mindforge/games/false_light/domain/light_field.dart';
import 'package:mindforge/games/false_light/domain/tile_depth.dart';
import 'package:mindforge/games/false_light/ui/board/light_tile.dart';
import 'package:mindforge/games/false_light/ui/light_metrics.dart';
import 'package:mindforge/l10n/app_localizations.dart';

/// The board rectangle, and nothing outside it.
///
/// **It draws no chrome and no text.** No `Scaffold`, no `SafeArea`, no HUD
/// pill, no route, no clock — and not one string that reaches the screen. That
/// last one is the differentiator rather than a coincidence: there is nothing
/// on this board for a locale to translate, which `false_light_board_test`
/// asserts by finding no `Text` under it and by comparing the tile depths in
/// traversal order across `en` and `fa`.
///
/// **The grid itself DOES mirror**, and that is correct rather than a leak.
/// Schulte Grid pins its grid left-to-right because 1..25 is ordered and
/// `cells[0]` has to mean a fixed screen position; a False Light field is
/// unordered, so mirroring it yields another equally valid field. The CONTENT
/// is locale-invariant; the layout follows reading direction like every other
/// grid in the app.
///
/// **And no `Directionality` of its own.** The grid mirrors for free because
/// every inset here is directional. The tiles' hard offset shadow does not
/// mirror, and that is the theme's decision rather than this file's — working
/// agreement 11's one exception, which on this board is the mechanic.
class FalseLightBoard extends ConsumerStatefulWidget {
  /// Creates the board for [run].
  const FalseLightBoard({required this.run, super.key});

  /// Which run is being played.
  final RunConfig run;

  @override
  ConsumerState<FalseLightBoard> createState() => _FalseLightBoardState();
}

class _FalseLightBoardState extends ConsumerState<FalseLightBoard> {
  @override
  void initState() {
    super.initState();

    // THE FIELD STARTS WHEN THE BOARD DOES. The notifier is built at the run's
    // `start()`, three seconds before this widget mounts, and it mounts again
    // after a pause — so the field clock is anchored here rather than there.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      ref.read(lightBoardNotifierProvider(widget.run).notifier).markShown();
    });
  }

  @override
  Widget build(BuildContext context) {
    final run = widget.run;
    final state = ref.watch(lightBoardNotifierProvider(run));
    final field = state.current;

    // The board FREEZES when the run ends. The shell decides what happens
    // next; a board that navigated would be the second owner of the run.
    if (field == null) return const SizedBox.expand();

    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = LightMetrics.forField(
          constraints.biggest,
          columns: field.columns,
          rows: field.rows,
        );

        return Center(
          child: SizedBox(
            width: metrics.widthFor(field.columns),
            height: metrics.heightFor(field.rows),
            child: _TileGrid(
              run: run,
              state: state,
              field: field,
              metrics: metrics,
            ),
          ),
        );
      },
    );
  }
}

/// The grid of tiles.
class _TileGrid extends ConsumerWidget {
  const _TileGrid({
    required this.run,
    required this.state,
    required this.field,
    required this.metrics,
  });

  final RunConfig run;
  final LightBoardState state;
  final LightField field;
  final LightMetrics metrics;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      // Clip.none, or the e2 hard shadow is sheared off at the grid's edge —
      // and on THIS board the shadow is the answer, so clipping it would not
      // merely look wrong, it would remove information.
      clipBehavior: Clip.none,
      padding: EdgeInsets.zero,
      itemCount: field.tileCount,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: field.columns,
        crossAxisSpacing: metrics.gap,
        mainAxisSpacing: metrics.gap,
        mainAxisExtent: metrics.tileSize,
      ),
      itemBuilder: (context, index) {
        final depth = field.tiles[index];
        final tileState = state.tileStates[index];

        return Semantics(
          // AUTHORED, not inherited from layout. The grid mirrors under RTL and
          // the traversal order must not: tile 0 is the first tile in both
          // directions, and a reader who learnt the order in one language keeps
          // it in the other.
          sortKey: OrdinalSortKey(index.toDouble()),
          child: LightTile(
            depth: depth,
            state: tileState,
            wrongTapId: state.wrongTapId,
            semanticLabel: switch ((depth, tileState)) {
              (_, LightTileState.swept) => l10n.lightTileSwept,
              (TileDepth.pressed, _) => l10n.lightTilePressed,
              (TileDepth.raised, _) => l10n.lightTileRaised,
            },
            // A RESOLVED TILE DROPS ITS TAP rather than passing enabled: false,
            // which would swap the fill — and on this board the fill IS half
            // the answer.
            onTap:
                tileState == LightTileState.locked ||
                    tileState == LightTileState.swept
                ? null
                : () => ref
                      .read(lightBoardNotifierProvider(run).notifier)
                      .submit(index),
          ),
        );
      },
    );
  }
}
