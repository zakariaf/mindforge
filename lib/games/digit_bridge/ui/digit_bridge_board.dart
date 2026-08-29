import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindforge/core/numeral_script.dart';
import 'package:mindforge/core/run_config.dart';
import 'package:mindforge/core/supported_locale.dart';
import 'package:mindforge/games/digit_bridge/application/bridge_board_notifier.dart';
import 'package:mindforge/games/digit_bridge/domain/bridge_board_state.dart';
import 'package:mindforge/games/digit_bridge/ui/board/bridge_chip.dart';
import 'package:mindforge/games/digit_bridge/ui/board/bridge_target.dart';
import 'package:mindforge/games/digit_bridge/ui/bridge_metrics.dart';
import 'package:mindforge/l10n/app_localizations.dart';
import 'package:mindforge/l10n/locale_numbers.dart';

/// The board rectangle, and nothing outside it.
///
/// **It draws no chrome.** No `Scaffold`, no `SafeArea`, no HUD pill, no
/// progress track, no route, no clock. The band above it and the gutter around
/// it are the shell's.
///
/// **And no `Directionality` of its own at this level.** Direction is a
/// consequence of the locale, and the chip grid mirrors for free because every
/// inset in here is directional. The one LTR pin in this game is inside a
/// numeral run, which has its own coordinate space and is documented there.
class DigitBridgeBoard extends ConsumerStatefulWidget {
  /// Creates the board for [run].
  const DigitBridgeBoard({required this.run, super.key});

  /// Which run is being played.
  final RunConfig run;

  @override
  ConsumerState<DigitBridgeBoard> createState() => _DigitBridgeBoardState();
}

class _DigitBridgeBoardState extends ConsumerState<DigitBridgeBoard> {
  @override
  void initState() {
    super.initState();

    // THE ROUND STARTS WHEN THE BOARD DOES. The notifier is built at the run's
    // `start()`, three seconds before this widget mounts, and it mounts again
    // after a pause — so the reaction clock is anchored here rather than there.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      ref.read(bridgeBoardNotifierProvider(widget.run).notifier).markShown();
    });
  }

  @override
  Widget build(BuildContext context) {
    final run = widget.run;
    final state = ref.watch(bridgeBoardNotifierProvider(run));
    final round = state.current;

    // The board FREEZES when the run ends. The shell decides what happens
    // next; a board that navigated would be the second owner of the run.
    if (round == null) return const SizedBox.expand();

    // WHICH SCRIPT GOES WHERE, resolved once per build and never per chip.
    // The round decides which SIDE the reader's own numerals sit on; the
    // locale decides what "the reader's own" means. Neither alone is enough,
    // and doing it here keeps `LocaleNumbers` out of every chip's `build`.
    final locale =
        SupportedLocale.tryParse(
          Localizations.localeOf(context).languageCode,
        ) ??
        SupportedLocale.en;
    final reader = NumeralScript.of(locale);
    final targetScript = round.targetOnReaderScript ? reader : reader.other;
    final chipScript = targetScript.other;

    final numbers = LocaleNumbers(locale);
    final l10n = AppLocalizations.of(context);

    // FORMATTED ONCE PER (ROUND, LOCALE), above the chips. `widget-composition`
    // rule 5: a formatter constructed inside `build()` is constructed six times
    // a frame, and this board rebuilds on every tap.
    final targetLabel = numbers.digitsInScript(round.target, targetScript);
    final chipLabels = <String>[
      for (final value in round.candidates)
        numbers.digitsInScript(value, chipScript),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = BridgeMetrics.forField(constraints.biggest);

        // CENTRED, and the column is only as tall as its content.
        // `app.html`: `.playfill--bridge{justify-content:center}`. Two earlier
        // shapes were wrong on the simulator and right in every test: dividing
        // the field between the two children drew portrait chips, and then
        // handing the target the leftover height drew a card with the numeral
        // floating in a sea of paper. The card sizes to its glyph, the grid
        // sizes to its chips, and the slack is whitespace above and below.
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              BridgeTarget(
                label: targetLabel,
                semanticLabel: l10n.bridgeTargetValue(targetLabel),
              ),
              const SizedBox(height: BridgeMetrics.targetToGridGap),
              _ChipGrid(
                run: run,
                state: state,
                labels: chipLabels,
                metrics: metrics,
                scriptName: _scriptName(chipScript, l10n),
              ),
            ],
          ),
        );
      },
    );
  }

  /// What a screen reader calls [script].
  ///
  /// Announced because depth of information a sighted player gets from the
  /// glyph shapes has to reach a screen-reader user some other way: "four seven
  /// two" alone does not say which of the two systems it was written in, and on
  /// this board that is half the question.
  String _scriptName(NumeralScript script, AppLocalizations l10n) =>
      switch (script) {
        NumeralScript.latin => l10n.bridgeScriptLatin,
        NumeralScript.easternArabic => l10n.bridgeScriptEasternArabic,
      };
}

/// The 3x2 candidate grid.
class _ChipGrid extends ConsumerWidget {
  const _ChipGrid({
    required this.run,
    required this.state,
    required this.labels,
    required this.metrics,
    required this.scriptName,
  });

  final RunConfig run;
  final BridgeBoardState state;

  /// The six numerals, already rendered in the chips' script.
  final List<String> labels;

  /// The geometry the field negotiated.
  final BridgeMetrics metrics;

  /// What the chips' numbering system is called, for a screen reader.
  final String scriptName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      // Clip.none, or the e2 hard shadow is sheared off at the grid's edge —
      // and a shadow that stops at a bounding box is the one defect that looks
      // like a rendering glitch rather than a layout mistake.
      clipBehavior: Clip.none,
      padding: EdgeInsets.zero,
      itemCount: labels.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: BridgeMetrics.columns,
        crossAxisSpacing: metrics.gap,
        mainAxisSpacing: metrics.gap,
        mainAxisExtent: metrics.chipHeight,
      ),
      itemBuilder: (context, index) => Semantics(
        // AUTHORED, not inherited from layout. The grid mirrors under RTL and
        // the traversal order must not: chip 0 is the first chip in both
        // directions, and a reader who learnt the order in one language keeps
        // it in the other.
        sortKey: OrdinalSortKey(index.toDouble()),
        child: BridgeChip(
          label: labels[index],
          semanticLabel: l10n.bridgeChipValue(labels[index], scriptName),
          state: state.chipStates[index],
          wrongTapId: state.wrongTapId,
          // A RESOLVED CHIP DROPS ITS TAP rather than passing enabled: false,
          // which would swap the fill and read as a control that failed.
          onTap: state.chipStates[index] == BridgeChipState.locked
              ? null
              : () => ref
                    .read(bridgeBoardNotifierProvider(run).notifier)
                    .submit(index),
        ),
      ),
    );
  }
}
