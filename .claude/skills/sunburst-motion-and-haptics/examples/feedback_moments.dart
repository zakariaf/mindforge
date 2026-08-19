// Five catalog rows implemented end to end — answerCorrect, answerWrong,
// streakMilestone, tileFound + tileNextCue, and the personalBest celebration.
// In the app each lives beside its own surface (stroop_run_notifier.dart,
// stroop_stimulus_card.dart, schulte_tile.dart, personal_best_badge.dart);
// they are collected here so the pattern reads in one pass.
//
// Owned elsewhere: SunburstColors/SunburstShape/SunburstMotion -> sunburst-tokens;
// SchulteTileState -> sunburst-game-surfaces; PopSurface and the chrome ->
// sunburst-components; the RunPhase machine -> sunburst-shell-screens.

import 'dart:async' show unawaited;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindforge/features/results/ui/celebration_badge.dart';
import 'package:mindforge/games/schulte_grid/domain/schulte_tile_state.dart';
import 'package:mindforge/games/schulte_grid/ui/tile_glyph.dart';
import 'package:mindforge/games/stroop_rush/domain/stroop_run_state.dart';
import 'package:mindforge/games/stroop_rush/ui/stimulus_glyph.dart';
import 'package:mindforge/shared/feedback/feedback_service.dart';
import 'package:mindforge/shared/feedback/moment.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_motion.dart';
import 'package:mindforge/theme/sunburst_shape.dart';

// answerCorrect / answerWrong / streakMilestone — the commit path. One state
// write, one haptic, one latch. Nothing here knows that animation exists.
class StroopRunNotifier extends Notifier<StroopRunState> {
  @override
  StroopRunState build() => StroopRunState.initial();

  FeedbackService get _feedback => ref.read(feedbackServiceProvider);

  void answer(int keyId) {
    if (keyId != state.stimulus.inkColourId) {
      // The wrong key is named in state so exactly one key shakes, and so the
      // shake survives a rebuild without re-triggering.
      state = state.copyWith(streak: 0, wrongKeyId: keyId);
      _feedback.fire(Moment.answerWrong); // lightImpact — never heavyImpact
      return;
    }

    final streak = state.streak + 1;
    // Boundary latch: the milestone fires once per crossing, not once per
    // rebuild, and not again if the streak dips back and returns.
    final crossed = streak % 5 == 0 && streak > state.lastMilestone;

    state = state.copyWith(
      stimulus: state.deck.next(),
      score: state.score + 20,
      streak: streak,
      lastMilestone: crossed ? streak : state.lastMilestone,
      wrongKeyId: null,
    );
    // One committed event, one haptic: the milestone REPLACES the correct-answer
    // tick rather than stacking on top of it.
    _feedback.fire(crossed ? Moment.streakMilestone : Moment.answerCorrect);
  }
}

// answerCorrect, seen — the stimulus cross-fades IN PLACE. No slide, no scale:
// a reaction-time game may not spend the player's milliseconds on entrances.
class StroopStimulusCard extends StatelessWidget {
  const StroopStimulusCard({required this.stimulus, super.key});

  final StroopStimulus stimulus;

  @override
  Widget build(BuildContext context) {
    final motion = SunburstMotion.of(context);
    return AnimatedSwitcher(
      duration: motion.resolve(context, motion.durState),
      // easeOut, not easePop: easePop overshoots past 1.0, and an opacity of
      // 1.06 is not a value anyone chose. WRONG here would also be a
      // SlideTransition or a ScaleTransition builder.
      switchInCurve: motion.easeOut,
      switchOutCurve: motion.easeOut,
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: StimulusGlyph(key: ValueKey(stimulus.id), stimulus: stimulus),
    );
  }
}

// answerWrong — 240ms x 2, +/-4px on X, transcribed from @keyframes shake, as
// two explicit forwards so the stop condition is the absence of a third line.
class ShakeOnWrong extends StatefulWidget {
  const ShakeOnWrong({required this.isWrong, required this.child, super.key});

  final bool isWrong;
  final Widget child;

  @override
  State<ShakeOnWrong> createState() => _ShakeOnWrongState();
}

class _ShakeOnWrongState extends State<ShakeOnWrong>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(vsync: this);
  Animation<double> _dx = const AlwaysStoppedAnimation<double>(0);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final motion = SunburstMotion.of(context);
    _shake.duration = motion.durCelebrate;
    _dx = TweenSequence<double>(<TweenSequenceItem<double>>[ // 0 → −4 → +4 → 0
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -4.0), weight: 25),
      TweenSequenceItem(tween: Tween(begin: -4.0, end: 4.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 4.0, end: 0.0), weight: 25),
    ]).animate(CurvedAnimation(parent: _shake, curve: motion.easeOut));
  }

  @override
  void didUpdateWidget(ShakeOnWrong oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isWrong && !oldWidget.isWrong) unawaited(_playTwice());
  }

  Future<void> _playTwice() async {
    // Reduce motion: the residue carries it and the haptic already fired in the
    // notifier, so nothing is lost. On a Schulte tile the residue is the
    // `danger` fill + paper glyph; on a Stroop answer key it is the drop to
    // flat plus the ink strike bar, because a mechanic board may never recolour
    // a key (sunburst-game-surfaces rule 3). The shake is shared; the residue
    // is not.
    if (MediaQuery.disableAnimationsOf(context)) return;
    await _shake.forward(from: 0);
    // Disposing mid-flight cancels the TickerFuture, so this never resumes —
    // that is the stop condition. The guard covers the surviving-widget case.
    if (!mounted) return;
    await _shake.forward(from: 0);
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _dx,
        builder: (context, child) =>
            Transform.translate(offset: Offset(_dx.value, 0), child: child),
        child: widget.child,
      );
}

// tileFound + tileNextCue — two visuals, ONE committed event, ONE haptic. A
// found tile stays where the press put it, at translate(2,2): the press already
// did the movement, and "found" only drops the last 1px of shadow.
class SchulteTile extends StatelessWidget {
  const SchulteTile({required this.value, required this.state, super.key});

  final int value;
  final SchulteTileState state;

  @override
  Widget build(BuildContext context) {
    final colors = SunburstColors.of(context);
    final shape = SunburstShape.of(context);
    final motion = SunburstMotion.of(context);
    // Where a found tile LIVES: exactly where an e1 press put it, derived, not
    // typed. It is a resting state, so reduce-motion never drops it — only the
    // tween collapses.
    final sunk = state == SchulteTileState.found
        ? shape.pressTranslate(shape.e1)
        : Offset.zero;

    return AnimatedContainer(
      duration: motion.resolve(context, motion.durState),
      curve: motion.easeOut,
      transform: Matrix4.translationValues(sunk.dx, sunk.dy, 0),
      decoration: BoxDecoration(
        // Never Opacity: it fades the 3px ink border, and the border is the
        // brand. Recede by changing the fill.
        // Fills and border are sunburst-game-surfaces' state matrix, not this
        // skill's: idle is `surface` cream (app.html `.tile{background:cream}`,
        // which beats the §10 gallery's paper), and a disabled tile drops its
        // edge to `borderDisabled` as well as its fill. `danger` is legal here
        // ONLY because Schulte declares GameColourRole.decorative — a Stroop
        // answer key keeps its hue and spends the strike bar instead.
        color: switch (state) {
          SchulteTileState.idle => colors.surface,
          SchulteTileState.next => colors.accent,
          SchulteTileState.found => colors.gameSchulteDeep,
          SchulteTileState.wrong => colors.danger,
          SchulteTileState.disabled => colors.surfaceSunk,
        },
        border: Border.all(
          color: state == SchulteTileState.disabled
              ? colors.borderDisabled
              : colors.border,
          width: shape.borderWidth,
        ),
        borderRadius: BorderRadius.all(shape.radiusMd),
        // found drops the shadow entirely — stamped into the page. next lifts
        // to e2 and takes the cream-then-ink ring sunburst-game-surfaces paints.
        // disabled KEEPS an e1 shadow and repaints it in borderDisabled,
        // matching `.btn[disabled]{box-shadow:3px 3px 0 ink-3}` and PopSurface.
        boxShadow: switch (state) {
          SchulteTileState.found => const <BoxShadow>[],
          SchulteTileState.disabled =>
            shape.shadow(shape.e1, colors.borderDisabled),
          SchulteTileState.next => shape.shadow(shape.e2, colors.border),
          SchulteTileState.idle ||
          SchulteTileState.wrong =>
            shape.shadow(shape.e1, colors.border),
        },
      ),
      child: Center(child: TileGlyph(value: value, state: state)),
    );
  }
}

// personalBest — the ONLY heavyImpact and the only celebration. Bounded at
// 240ms, plays once behind _hasPlayed, never loops, never blocks input, and
// stops on reduce motion, on a non-current route, and on dispose.
class PersonalBestBadge extends ConsumerStatefulWidget {
  const PersonalBestBadge({required this.label, super.key});

  final String label;

  @override
  ConsumerState<PersonalBestBadge> createState() => _PersonalBestBadgeState();
}

class _PersonalBestBadgeState extends ConsumerState<PersonalBestBadge>
    with SingleTickerProviderStateMixin {
  // Rests at 1 — the finished state — so an interruption resolves TO the end
  // state rather than away from it.
  late final AnimationController _pop = AnimationController(vsync: this, value: 1);
  Animation<double> _scale = const AlwaysStoppedAnimation<double>(1);
  bool _hasPlayed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final motion = SunburstMotion.of(context);
    _pop.duration = motion.durCelebrate;
    _scale = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem(tween: Tween(begin: 0.86, end: 1.06), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.06, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(parent: _pop, curve: motion.easePop));

    if (_hasPlayed) return;
    _hasPlayed = true; // latch first: didChangeDependencies can fire again

    // The haptic is NOT gated on reduce motion — it is what survives it. Only
    // the animation is. Getting this order backwards is the common bug.
    ref.read(feedbackServiceProvider).fire(Moment.personalBest);

    // Stop conditions, checked before a single frame is scheduled.
    if (MediaQuery.disableAnimationsOf(context)) return;
    if (ModalRoute.of(context)?.isCurrent != true) return;
    unawaited(_pop.forward(from: 0));
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // No barrier, no AbsorbPointer: a tap anywhere goes straight through. The
    // -2.5 degree tilt is the badge's RESTING state (system.html .badge.new),
    // not a wobble — applied outside the animation, so it is never dropped.
    return Transform.rotate(
      angle: -2.5 * math.pi / 180,
      child: ScaleTransition(
        scale: _scale,
        child: CelebrationBadge(label: widget.label),
      ),
    );
  }
}
