// Stroop Rush board — the GameColourRole.mechanic case. The hue of a key IS the
// answer, so no chrome slot (accent / success / warning / danger / the game
// accent) may appear in this rectangle, and no play* slot may leave it. The 3px
// ink border under the play band is that boundary.
//
// Owned elsewhere: tokens -> sunburst-tokens; PopSurface, border, shadow, press
// -> sunburst-components; play band, GameHud, RunNotifier -> sunburst-shell-
// screens; durations, shake, haptics -> sunburst-motion-and-haptics.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindforge/features/play/domain/run_config.dart';
import 'package:mindforge/games/stroop_rush/application/stroop_board_notifier.dart'
    show stroopBoardNotifierProvider;
import 'package:mindforge/ui/components/pop_surface.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/theme/sunburst_type.dart';

/// Colour is NOT one of these channels: accepted lifts, rejected sinks and gains
/// an ink strike bar, locked goes flat. All four keep their own fill.
enum AnswerKeyState { idle, accepted, rejected, locked }

/// Precomputed by `StroopBoardNotifier`; declared here so the example reads end
/// to end. [stimulusInk] is the INK the word is printed in — that is the answer.
/// [options]/[optionLabels] are parallel: under the colour-blind flag
/// `PlayAnswer.green` paints orange and is labelled "Orange", because the case is
/// the SLOT, not the hue. [isColourBlindPalette] is captured ONCE at round start
/// and read by the generator as well as by every paint, so a mid-run Settings
/// change cannot alter what this round is asking.
@immutable
class StroopBoardView {
  const StroopBoardView({
    required this.promptLabel,
    required this.stimulusWord,
    required this.stimulusInk,
    required this.stimulusInkLabel,
    required this.options,
    required this.optionLabels,
    required this.isColourBlindPalette,
    required this.keyStates,
  });

  final String promptLabel, stimulusWord, stimulusInkLabel;
  final PlayAnswer stimulusInk;
  final List<PlayAnswer> options;
  final List<String> optionLabels;
  final bool isColourBlindPalette;
  final List<AnswerKeyState> keyStates;
}

/// The board region. Neutral by construction.
class StroopBoard extends ConsumerWidget {
  const StroopBoard({required this.config, super.key});

  /// Handed down by `GameDefinition.buildBoard`; it keys the notifier family.
  final RunConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view =
        ref.watch(stroopBoardNotifierProvider(config).select((s) => s.view));

    // RULE 2. surfaceSunk, never gameStroop: coral is one hue step from playRed
    // and playOrange, and a player being timed takes the hint. Schulte's field IS
    // its accent because Schulte is decorative — see accent-contract.md.
    return ColoredBox(
      color: SunburstColors.of(context).surfaceSunk,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(SunburstShape.gutter,
            SunburstShape.gutter, SunburstShape.gutter, SunburstShape.space6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StroopStimulusCard(view: view),
            const SizedBox(height: SunburstShape.cardGap),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              clipBehavior: Clip.none, // the e2 shadow paints OUTSIDE the cell
              // 2x2, 12pt gap, 92pt keys — app.html screen 04.
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: SunburstShape.space3,
                mainAxisSpacing: SunburstShape.space3,
                mainAxisExtent: 92,
              ),
              itemCount: view.options.length,
              itemBuilder: (context, i) => StroopAnswerKey(
                answer: view.options[i],
                label: view.optionLabels[i],
                state: view.keyStates[i],
                isColourBlindPalette: view.isColourBlindPalette,
                onTap: () => ref
                    .read(stroopBoardNotifierProvider(config).notifier)
                    .submit(view.options[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Paper slab, e3 hard shadow, radiusXl, holding the stimulus glyph.
class StroopStimulusCard extends StatelessWidget {
  const StroopStimulusCard({required this.view, super.key});

  final StroopBoardView view;

  @override
  Widget build(BuildContext context) {
    final colors = SunburstColors.of(context);
    final shape = SunburstShape.of(context);
    final type = SunburstType.of(context);
    final scaler = MediaQuery.textScalerOf(context);

    return PopSurface(
      fill: colors.surfaceRaised,
      radius: shape.radiusXl,
      elevation: PopElevation.e3,
      padding: const EdgeInsetsDirectional.fromSTEB(16, 52, 16, 58),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(view.promptLabel,
            textAlign: TextAlign.center,
            style: type.label.copyWith(color: colors.textSecondary)),
        const SizedBox(height: 18),
        // Announcing the ink is the only way this board is operable with a
        // screen reader at all. That it also makes the task trivial is a
        // recorded product decision — do not "fix" it by hiding the value.
        Semantics(
          label: view.promptLabel,
          value: '${view.stimulusWord}, ${view.stimulusInkLabel}',
          child: ExcludeSemantics(
            child: SizedBox(
              // DERIVED: at scale 2.0 a six-letter word at 78pt needs roughly
              // 580pt against ~320pt available, so SunburstType owes a
              // `stimulusCompact` (~54pt) chosen by the same measured rule the
              // tile glyph uses. Until then the word wraps — never shrunk to
              // fit, never truncated. Every type slot declares a fontSize.
              height: scaler.scale(type.stimulus.fontSize!) + shape.e3.dy,
              child: CustomPaint(
                size: Size.infinite,
                painter: StroopWordPainter(
                  word: view.stimulusWord,
                  style: type.stimulus,
                  textScaler: scaler,
                  shadowOffset: shape.e3,
                  stripePitch: shape.stripePitch,
                  fill: colors.answerColour(view.stimulusInk,
                      colourBlind: view.isColourBlindPalette),
                  ink: colors.border,
                  pattern: view.stimulusInk.fill,
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

/// A hard ink shadow, then the three passes from system.html §12: a 6pt ink
/// stroke (the only reason a yellow stimulus is legible — playYellow is 1.76:1 on
/// cream), the hue fill, and the ink PlayFill masked to the glyph. A single
/// `Text` in an answer colour is the bug this prevents.
class StroopWordPainter extends CustomPainter {
  StroopWordPainter({
    required this.word,
    required TextStyle style,
    required this.textScaler,
    required this.shadowOffset,
    required this.stripePitch,
    required this.fill,
    required this.ink,
    required this.pattern,
  })  : _shadow = _pass(word, style.copyWith(color: ink), textScaler),
        _outline = _pass(
            word,
            style.copyWith(
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 6
                ..strokeJoin = StrokeJoin.round
                ..color = ink,
            ),
            textScaler),
        _body = _pass(word, style.copyWith(color: fill), textScaler);

  static TextPainter _pass(String w, TextStyle s, TextScaler t) => TextPainter(
      text: TextSpan(text: w, style: s),
      textDirection: TextDirection.ltr,
      textScaler: t);

  final String word;
  final TextScaler textScaler;
  final Offset shadowOffset;
  final double stripePitch;
  final Color fill, ink;
  final PlayFill pattern;
  final TextPainter _shadow, _outline, _body;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in [_shadow, _outline, _body]) {
      p.layout(maxWidth: size.width);
    }
    final origin = Offset((size.width - _body.width) / 2, 0);
    final box = origin & _body.size;

    _shadow.paint(canvas, origin + shadowOffset); // hard shadow, zero blur
    _outline.paint(canvas, origin); // 14.55:1 ink-on-cream, whatever the hue
    canvas.saveLayer(box, Paint());
    _body.paint(canvas, origin);
    paintPlayFill(canvas, box, pattern, fill, ink,
        stripePitch: stripePitch, maskToExisting: true);
    canvas.restore();
  }

  @override
  bool shouldRepaint(StroopWordPainter old) =>
      old.word != word ||
      old.fill != fill ||
      old.ink != ink ||
      old.pattern != pattern ||
      old.textScaler != textScaler;
}

/// The non-hue channel, in ink, at the pitches from system.html §03. Shared by
/// the glyph and the 56pt key panel so the two can never disagree — that
/// agreement is what a player matches on in greyscale, where playRed and playBlue
/// sit 1.02:1 apart.
void paintPlayFill(
  Canvas canvas,
  Rect box,
  PlayFill pattern,
  Color fill,
  Color ink, {
  required double stripePitch,
  required bool maskToExisting,
}) {
  final paint = Paint()
    ..color = ink
    ..blendMode = maskToExisting ? BlendMode.srcATop : BlendMode.srcOver;
  switch (pattern) {
    case PlayFill.solid:
      return; // solid IS a pattern: the absence of one, and it is claimed.
    case PlayFill.stripe:
      // 45 degrees: the gradient VECTOR is the pitch, so each leg is p / sqrt2.
      final leg = stripePitch / math.sqrt2;
      paint.shader = ui.Gradient.linear(
          box.topLeft,
          box.topLeft + Offset(leg, leg),
          [fill, fill, ink, ink],
          const [0, 5 / 9, 5 / 9, 1], // 5pt hue / 4pt ink, per system.html
          TileMode.repeated);
      canvas.drawRect(box, paint);
    case PlayFill.dot: // ink 2.6pt radius on a 10pt lattice
      for (var y = box.top; y < box.bottom; y += 10) {
        for (var x = box.left; x < box.right; x += 10) {
          canvas.drawCircle(Offset(x, y), 2.6, paint);
        }
      }
    case PlayFill.ring: // 3pt ink band r=4..7 of each 7pt period
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      for (var r = 5.5; r < box.longestSide; r += 7) {
        canvas.drawCircle(box.center, r, paint);
      }
  }
}

/// One answer. Fill = the answer's hue; every state channel is hue-free.
class StroopAnswerKey extends StatelessWidget {
  const StroopAnswerKey({
    required this.answer,
    required this.label,
    required this.state,
    required this.isColourBlindPalette,
    required this.onTap,
    super.key,
  });

  final PlayAnswer answer;
  final String label;
  final AnswerKeyState state;
  final bool isColourBlindPalette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = SunburstColors.of(context);
    final shape = SunburstShape.of(context);
    final type = SunburstType.of(context);
    // Colour is derived LAST, from the slot, and never encodes the state.
    final fill = colors.answerColour(answer, colourBlind: isColourBlindPalette);

    // RULE 3. No success, no danger — `danger` IS the red the key next to this
    // one may be wearing. Accepted lifts to e3 and holds; rejected sinks flat,
    // shifts 2pt and wears an ink strike bar. The shake and the haptic belong to
    // sunburst-motion-and-haptics.
    final (PopElevation elevation, Offset shift, bool isStruck) =
        switch (state) {
      AnswerKeyState.idle => (PopElevation.e2, Offset.zero, false),
      AnswerKeyState.accepted => (PopElevation.e3, Offset.zero, false),
      AnswerKeyState.rejected => (PopElevation.flat, const Offset(2, 2), true),
      AnswerKeyState.locked => (PopElevation.flat, Offset.zero, false),
    };

    return Transform.translate(
      offset: shift,
      child: PopSurface(
        fill: fill,
        radius: shape.radiusLg,
        elevation: elevation,
        // NOT `enabled: false`: PopSurface's disabled shape swaps the fill to
        // surfaceSunk, which would erase the hue that IS the answer. A resolved
        // key stops taking taps by dropping onTap and reads as resolved from its
        // depth and its strike bar.
        onTap: state == AnswerKeyState.idle ? onTap : null,
        semanticLabel: label,
        child: Row(children: [
          // The pattern panel, closed by the same 3pt ink as the outer edge so it
          // reads as part of the object rather than a sticker on it.
          SizedBox(
            width: 56,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: BorderDirectional(
                  end:
                      BorderSide(color: colors.border, width: shape.borderWidth),
                ),
              ),
              child: Stack(fit: StackFit.expand, children: [
                CustomPaint(
                  painter: PlayFillPainter(
                    pattern: answer.fill,
                    fill: fill,
                    ink: colors.border,
                    stripePitch: shape.stripePitch,
                  ),
                ),
                // The rejection channel: an ink bar, not a colour change.
                if (isStruck)
                  Center(
                    child: SizedBox(
                        height: 6, child: ColoredBox(color: colors.border)),
                  ),
              ]),
            ),
          ),
          Expanded(
            child: Center(
              // Never "pick a label colour at the call site": yellow takes ink at
              // 8.3:1, every other slot paper at >= 4.96:1.
              child: Text(label,
                  style:
                      type.button.copyWith(color: colors.answerLabel(answer))),
            ),
          ),
        ]),
      ),
    );
  }
}

/// The 56pt pattern panel on an answer key.
class PlayFillPainter extends CustomPainter {
  const PlayFillPainter({
    required this.pattern,
    required this.fill,
    required this.ink,
    required this.stripePitch,
  });

  final PlayFill pattern;
  final Color fill, ink;
  final double stripePitch;

  @override
  void paint(Canvas canvas, Size size) => paintPlayFill(
      canvas, Offset.zero & size, pattern, fill, ink,
      stripePitch: stripePitch, maskToExisting: false);

  @override
  bool shouldRepaint(PlayFillPainter old) =>
      old.pattern != pattern ||
      old.fill != fill ||
      old.ink != ink ||
      old.stripePitch != stripePitch;
}
