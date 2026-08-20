import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindforge/core/run_config.dart';
import 'package:mindforge/games/stroop_rush/application/stroop_answer_labels.dart';
import 'package:mindforge/games/stroop_rush/application/stroop_board_notifier.dart';
import 'package:mindforge/games/stroop_rush/domain/stroop_board_state.dart';
import 'package:mindforge/games/stroop_rush/ui/board/answer_key.dart';
import 'package:mindforge/games/stroop_rush/ui/board/play_fill.dart';
import 'package:mindforge/games/stroop_rush/ui/board/stroop_word_painter.dart';
import 'package:mindforge/l10n/app_localizations.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/theme/sunburst_type.dart';
import 'package:mindforge/ui/components/pop_surface.dart';

/// The board rectangle, and nothing outside it.
///
/// **It draws no chrome.** No `Scaffold`, no `SafeArea`, no HUD pill, no
/// progress track, no route, no clock. The band above it and the gutter around
/// it are the shell's; this is the rectangle below the play band's ink border.
///
/// **And no `Directionality` of its own.** Direction is a consequence of the
/// locale, and the 2x2 grid mirrors for free because every inset in here is
/// directional. The hard offset shadow does not mirror, and that is the theme's
/// decision rather than this file's.
class StroopBoard extends ConsumerWidget {
  /// Creates the board for [run].
  const StroopBoard({required this.run, super.key});

  /// Which run is being played.
  final RunConfig run;

  /// The gap between the stimulus card and the answer grid.
  ///
  /// `app.html`: `.playfill--stroop{gap:16px}`.
  static const double cardToGridGap = 16;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colours = SunburstColors.of(context);
    final state = ref.watch(stroopBoardNotifierProvider(run));
    final round = state.current;

    // The board FREEZES when the run ends. The shell decides what happens
    // next; a board that navigated would be the second owner of the run.
    if (round == null) return const SizedBox.expand();

    return ColoredBox(
      color: colours.surfaceSunk,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(child: _StimulusCard(state: state)),
          const SizedBox(height: cardToGridGap),
          _AnswerGrid(run: run, state: state),
        ],
      ),
    );
  }
}

/// The white card carrying the prompt and the painted word.
class _StimulusCard extends ConsumerWidget {
  const _StimulusCard({required this.state});

  final StroopBoardState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colours = SunburstColors.of(context);
    final shape = SunburstShape.of(context);
    final type = SunburstType.of(context);
    final l10n = AppLocalizations.of(context);
    final round = state.current!;

    final word = stimulusWord(
      round.word,
      colourBlind: state.isColourBlindPalette,
      l10n: l10n,
    );
    final inkWord = stimulusWord(
      round.ink,
      colourBlind: state.isColourBlindPalette,
      l10n: l10n,
    );

    return PopSurface(
      fill: colours.surfaceRaised,
      radius: BorderRadiusDirectional.all(shape.radiusXl),
      elevation: PopElevation.e3,
      minTarget: 0,
      padding: const EdgeInsetsDirectional.fromSTEB(16, 24, 16, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            l10n.stroopPrompt,
            textAlign: TextAlign.center,
            style: type.label.copyWith(color: colours.textSecondary),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // A SMALLER BASE STYLE, chosen once, never a shrink. The full
                // step does not fit the longest word on the narrowest device —
                // measured in sunburst_type.dart — so the board picks the step
                // that does rather than scaling glyphs down to whatever is
                // left.
                final style = _fits(word, type.stimulus, constraints.maxWidth)
                    ? type.stimulus
                    : type.stimulusCompact;

                return Semantics(
                  // ANNOUNCED, NEVER DRAWN. A screen reader gets the word and
                  // the colour it is printed in; the painting says the same
                  // thing to everyone else.
                  label: l10n.stroopStimulusValue(word, inkWord),
                  child: ExcludeSemantics(
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: StroopWordPainter(
                        StroopWordScene(
                          word: word,
                          textDirection: Directionality.of(context),
                          style: style,
                          fill: round.ink.fill,
                          hue: colours.answerColour(
                            round.ink,
                            colourBlind: state.isColourBlindPalette,
                          ),
                          ink: colours.border,
                          strokeWidth: shape.glyphStrokeWidth,
                          geometry: PlayFillGeometry(
                            stripePitch: shape.stripePitch,
                            stripeAngle: shape.stripeAngle,
                            dotPitch: shape.dotPitch,
                            dotRadius: shape.dotRadius,
                            ringPitch: shape.ringPitch,
                            ringBandWidth: shape.ringBandWidth,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Whether [word] draws on one line at [style] within [width].
  ///
  /// Measured with a `TextPainter` rather than estimated: the answer differs
  /// per script, per face and per text scale, and the only honest way to ask
  /// is to lay it out.
  bool _fits(String word, TextStyle style, double width) {
    final painter = TextPainter(
      text: TextSpan(text: word, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final fits = painter.width <= width;

    painter.dispose();

    return fits;
  }
}

/// The 2x2 answer grid.
class _AnswerGrid extends ConsumerWidget {
  const _AnswerGrid({required this.run, required this.state});

  final RunConfig run;
  final StroopBoardState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shape = SunburstShape.of(context);
    final l10n = AppLocalizations.of(context);
    final round = state.current!;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      // Clip.none, or the e2 hard shadow is sheared off at the grid's edge —
      // and a shadow that stops at a bounding box is the one defect that looks
      // like a rendering glitch rather than a layout mistake.
      clipBehavior: Clip.none,
      padding: EdgeInsets.zero,
      itemCount: round.options.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: SunburstShape.space3,
        mainAxisSpacing: SunburstShape.space3,
        mainAxisExtent: shape.answerKeyHeight,
      ),
      itemBuilder: (context, index) {
        final answer = round.options[index];

        return Semantics(
          // AUTHORED, not inherited from layout. The grid mirrors under RTL
          // and the traversal order must not: option 0 is the first key in
          // both directions, and a reader who learnt the order in one language
          // keeps it in the other.
          sortKey: OrdinalSortKey(index.toDouble()),
          child: StroopAnswerKey(
            answer: answer,
            label: answerWord(
              answer,
              colourBlind: state.isColourBlindPalette,
              l10n: l10n,
            ),
            state: state.keyStates[index],
            isColourBlindPalette: state.isColourBlindPalette,
            wrongTapId: state.wrongTapId,
            // A RESOLVED KEY DROPS ITS TAP rather than passing enabled: false,
            // which would swap the fill and erase the answer.
            onTap: state.keyStates[index] == AnswerKeyState.locked
                ? null
                : () => ref
                      .read(stroopBoardNotifierProvider(run).notifier)
                      .submit(index),
          ),
        );
      },
    );
  }
}
