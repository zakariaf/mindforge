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
import 'package:mindforge/ui/halftone_dots.dart';

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
class StroopBoard extends ConsumerStatefulWidget {
  /// Creates the board for [run].
  const StroopBoard({required this.run, super.key});

  /// Which run is being played.
  final RunConfig run;

  /// The gap between the stimulus card and the answer grid.
  ///
  /// `app.html`: `.playfill--stroop{gap:16px}`.
  static const double cardToGridGap = 16;

  /// The most of a cramped field the answer grid may take.
  ///
  /// DERIVED. app.html has no such rule because it renders one size, where the
  /// keys sit at their token height and the question does not arise. It arises
  /// at x2.0 on a 320pt phone, and the answer is that the WORD keeps the
  /// majority: reading it is the task, and the keys still clear 48pt.
  static const double gridShareWhenCramped = 0.45;

  /// How tall one answer key draws in a field of [available] points.
  ///
  /// Its token height when there is room, never more; the 48pt tap floor when
  /// there is not, never less. Between the two it takes a share of the field
  /// rather than all of it, so the stimulus card is not squeezed to nothing by
  /// a grid that fits on its own terms.
  static double keyHeight(BuildContext context, double available) {
    final design = SunburstShape.of(context).answerKeyHeight;

    if (!available.isFinite) return design;

    // The share is the GRID's, and the grid is two rows and the space between
    // them — so the per-key height is that share minus the gap, halved. The
    // first version divided nothing and handed 0.45 to each ROW, which let the
    // grid claim about nine tenths of a cramped field while the doc comment
    // promised the word would keep the majority.
    final forGrid =
        (available - StroopBoard.cardToGridGap) * gridShareWhenCramped;

    return ((forGrid - SunburstShape.space3) / 2).clamp(kPopMinTarget, design);
  }

  @override
  ConsumerState<StroopBoard> createState() => _StroopBoardState();
}

class _StroopBoardState extends ConsumerState<StroopBoard> {
  @override
  void initState() {
    super.initState();

    // THE ROUND STARTS WHEN THE BOARD DOES. The notifier is built at the run's
    // `start()`, three seconds before this widget mounts, and it mounts again
    // after a pause — so the reaction clock is anchored here rather than there.
    // Deferred one frame because the notifier may still be building while this
    // widget's own first build runs.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      ref.read(stroopBoardNotifierProvider(widget.run).notifier).markShown();
    });
  }

  @override
  Widget build(BuildContext context) {
    final run = widget.run;
    final state = ref.watch(stroopBoardNotifierProvider(run));
    final round = state.current;

    // The board FREEZES when the run ends. The shell decides what happens
    // next; a board that navigated would be the second owner of the run.
    if (round == null) return const SizedBox.expand();

    // NO FILL AND NO LATTICE OF ITS OWN. The definition asked for
    // `BoardBackground.surfaceSunk` and the shell paints it, dots and all.
    // This board used to paint both again on top, which occluded the shell's
    // and paid for the raster twice on every frame.
    return Stack(
      children: <Widget>[
        // CENTRED, and the card is sized by its CONTENT. app.html:
        // `.playfill{justify-content:center}` with a 16pt gap. The first
        // draft stretched the card to fill the field, which made it twice
        // the height of the reference and left the word floating in a sea of
        // paper — caught on the canonical simulator, not by a test, because
        // nothing was overflowing.
        LayoutBuilder(
          builder: (context, constraints) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Flexible(child: _StimulusCard(state: state)),
              const SizedBox(height: StroopBoard.cardToGridGap),
              _AnswerGrid(
                run: run,
                state: state,
                keyHeight: StroopBoard.keyHeight(
                  context,
                  constraints.maxHeight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The white card carrying the prompt and the painted word.
///
/// **Its padding is the design's, until the field is too short to pay for it.**
/// `app.html` says `.stim{padding:52px 16px 58px}` and at 390x844 with no text
/// scaling that is exactly what it takes. Below that the card gives up its own
/// whitespace before it gives up any of the word: at x2.0 on a 320pt phone the
/// prompt, the glyph and the answer grid together want more than the field has,
/// and the thing the player has to READ is the last thing that should shrink.
class _StimulusCard extends StatelessWidget {
  const _StimulusCard({required this.state});

  final StroopBoardState state;

  /// The padding app.html states, and the most this card ever takes.
  static const double padTop = 52;
  static const double padBottom = 58;

  /// app.html: `.stim .ask{margin:0 0 18px}`.
  static const double promptToWord = 18;

  /// How many lines the prompt may take, measured and drawn. It is one short
  /// sentence; two lines is already the x3.0 case, and a third would be
  /// spending the word's height on it.
  static const int promptMaxLines = 2;

  @override
  Widget build(BuildContext context) {
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

    return LayoutBuilder(
      builder: (context, constraints) {
        // `Flexible` above hands this card the space the answer grid did not
        // take, so `maxHeight` IS the budget — nothing else has to be guessed.
        final inner = constraints.maxWidth - 32;
        final prompt = _measure(
          context,
          l10n.stroopPrompt,
          type.label,
          inner,
          maxLines: promptMaxLines,
        );

        // A SMALLER BASE STYLE, chosen once, never a shrink. The full step does
        // not fit the longest word on the narrowest device — measured in
        // sunburst_type.dart — so the board picks the step that does rather
        // than scaling glyphs down to whatever is left.
        final full = _measure(context, word, type.stimulus, inner);
        final style = full.fits ? type.stimulus : type.stimulusCompact;
        final glyph = full.fits
            ? full
            : _measure(context, word, type.stimulusCompact, inner);

        // WHITESPACE IS WHAT IS LEFT OVER, capped at the design's numbers and
        // kept in their own 52:18:58 proportion. At the reference there is
        // slack to spare and all three land on their cap, so the screenshot
        // comparison is against app.html's own figures and not against a
        // derivation. The gap under the prompt scales with the padding rather
        // than holding at 18: it is the same kind of whitespace, and a card
        // that had surrendered all its padding and still kept that gap would
        // be defending the wrong 18 points.
        const whitespace = padTop + padBottom + promptToWord;
        final slack = constraints.maxHeight.isFinite
            ? constraints.maxHeight - prompt.height - glyph.height
            : whitespace;
        final ratio = (slack / whitespace).clamp(0.0, 1.0);
        final top = padTop * ratio;
        final bottom = padBottom * ratio;
        final gap = promptToWord * ratio;

        // And when even a padding-less card does not fit, the glyph box takes
        // the cut. The painter centres its paragraph, so a box shorter than
        // the line trims the ascender and the descender evenly rather than
        // beheading the word.
        final height = constraints.maxHeight.isFinite
            ? glyph.height.clamp(
                0.0,
                (constraints.maxHeight -
                        top -
                        bottom -
                        prompt.height -
                        promptToWord)
                    .clamp(0.0, double.infinity),
              )
            : glyph.height;

        return PopSurface(
          fill: colours.surfaceRaised,
          radius: BorderRadiusDirectional.all(shape.radiusXl),
          elevation: PopElevation.e3,
          minTarget: 0,
          padding: EdgeInsetsDirectional.fromSTEB(16, top, 16, bottom),
          child: Stack(
            children: <Widget>[
              // The card carries the same lattice at the same strength.
              // `app.html`: `.stim .dots{opacity:.14}`.
              Positioned.fill(
                child: HalftoneLayer(
                  scene: HalftoneScene(
                    ink: colours.boardDots,
                    ray: null,
                    pitch: kBoardDotPitch,
                  ),
                ),
              ),
              _StimulusContent(
                state: state,
                word: word,
                style: style,
                glyphHeight: height,
                promptGap: gap,
              ),
            ],
          ),
        );
      },
    );
  }

  /// Whether [word] draws on one line at [style], and how tall it draws.
  ///
  /// Measured with a `TextPainter` rather than estimated: the answer differs
  /// per script, per face and per text scale — Arabic ascenders are taller
  /// than Latin capitals at the same point size — and the only honest way to
  /// ask is to lay it out. The SCALER is passed in, or the measurement is a
  /// different question from the one the painter will answer.
  ({bool fits, double height}) _measure(
    BuildContext context,
    String word,
    TextStyle style,
    double width, {
    int maxLines = 1,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: word, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: maxLines,
      // UNCONSTRAINED WHEN THE QUESTION IS "DOES IT FIT". A layout capped at
      // the available width reports a width that is never wider than it, so
      // `painter.width <= width` is true by construction and the fit check
      // decides nothing. `check_painter_hygiene.sh` warns on exactly this
      // shape. A multi-line measurement is a HEIGHT question and does want the
      // cap, because where the lines break is what makes it tall.
    )..layout(maxWidth: maxLines == 1 ? double.infinity : width);
    final result = (fits: painter.width <= width, height: painter.height);

    painter.dispose();

    return result;
  }
}

/// The prompt and the painted word, at the size the card resolved.
class _StimulusContent extends StatelessWidget {
  const _StimulusContent({
    required this.state,
    required this.word,
    required this.style,
    required this.glyphHeight,
    required this.promptGap,
  });

  final StroopBoardState state;

  /// The stimulus word, already localized.
  final String word;

  /// The step the card measured as fitting.
  final TextStyle style;

  /// How tall the glyph may draw.
  final double glyphHeight;

  /// The space under the prompt, at the card's resolved whitespace ratio.
  final double promptGap;

  @override
  Widget build(BuildContext context) {
    final colours = SunburstColors.of(context);
    final shape = SunburstShape.of(context);
    final type = SunburstType.of(context);
    final l10n = AppLocalizations.of(context);
    final round = state.current!;

    final inkWord = stimulusWord(
      round.ink,
      colourBlind: state.isColourBlindPalette,
      l10n: l10n,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          l10n.stroopPrompt,
          textAlign: TextAlign.center,
          // BOUNDED TO WHAT THE CARD MEASURED. `_measure` lays the prompt out
          // at two lines to decide how much whitespace is affordable; a Text
          // free to take a third would make that budget a fiction, which is
          // exactly what overflowed the field at x3.0.
          maxLines: _StimulusCard.promptMaxLines,
          overflow: TextOverflow.ellipsis,
          style: type.label.copyWith(color: colours.textSecondary),
        ),
        SizedBox(height: promptGap),
        Semantics(
          // ANNOUNCED, NEVER DRAWN. A screen reader gets the word and the
          // colour it is printed in; the painting says the same thing to
          // everyone else.
          label: l10n.stroopStimulusValue(word, inkWord),
          child: ExcludeSemantics(
            child: SizedBox(
              // SIZED TO THE GLYPH, so the card is as tall as its content. A
              // CustomPaint with no size and no child measures zero and paints
              // nothing; one that filled the field made the card twice the
              // reference height.
              height: glyphHeight,
              width: double.infinity,
              // ITS OWN LAYER. The glyph is the expensive paint on this
              // screen — two saveLayers and three text draws — and without a
              // boundary it shares a layer with the card's PopSurface and
              // halftone stack, so any repaint of the card re-runs it.
              // `check_painter_hygiene.sh` warns on exactly this.
              child: RepaintBoundary(
                child: CustomPaint(
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
                      geometry: PlayFillGeometry.of(context),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The 2x2 answer grid.
class _AnswerGrid extends ConsumerWidget {
  const _AnswerGrid({
    required this.run,
    required this.state,
    required this.keyHeight,
  });

  final RunConfig run;
  final StroopBoardState state;

  /// How tall one key draws. Resolved by the field, not by the token, because
  /// only the field knows how much height there is to spend.
  final double keyHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        mainAxisExtent: keyHeight,
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
