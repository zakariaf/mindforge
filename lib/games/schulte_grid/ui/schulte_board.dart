import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindforge/core/run_config.dart';
import 'package:mindforge/games/schulte_grid/application/schulte_board_notifier.dart';

/// The board rectangle, and nothing outside it.
///
/// **It draws no chrome.** No `Scaffold`, no `SafeArea`, no HUD pill, no
/// progress track, no route, no clock. The band above it and the gutter around
/// it are the shell's.
///
/// **And no `Directionality` of its own.** T10.5 records the decision the grid
/// rests on: the numbers run 1..n² in reading order in every locale, and the
/// CHROME around the grid mirrors while the grid itself does not.
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
  Widget build(BuildContext context) => const SizedBox.expand();
}
