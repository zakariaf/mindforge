import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mindforge/core/run_config.dart';
import 'package:mindforge/features/play/application/run_notifier.dart';
import 'package:mindforge/features/shell/widgets/halftone_dots.dart';
import 'package:mindforge/games/game_registry.dart';
import 'package:mindforge/l10n/app_localizations.dart';
import 'package:mindforge/l10n/difficulty_strings.dart';
import 'package:mindforge/l10n/game_strings.dart';
import 'package:mindforge/l10n/l10n_providers.dart';
import 'package:mindforge/routing/routes.dart';
import 'package:mindforge/shared/feedback/feedback_service.dart';
import 'package:mindforge/shared/feedback/moment.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_motion.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/theme/sunburst_type.dart';
import 'package:mindforge/ui/components/pop_icon_button.dart';
import 'package:mindforge/ui/components/pop_surface.dart';
import 'package:mindforge/ui/glyphs/sunburst_glyph.dart';

/// The 3-2-1 before a run.
///
/// **The one screen in the app whose fill reaches y=0.** It is the hand-off
/// from menu to game and it is loud on purpose: a full-bleed grape burst, one
/// enormous numeral, and no chrome to look at. Everything else in MindForge
/// sits under a header.
///
/// **It drives the run notifier rather than owning a second clock.** The
/// notifier owns the phase machine; this counts three beats and then tells it
/// to begin. A countdown that started the board itself would be the second
/// timer `sunburst-shell-screens` rule 3 forbids.
///
/// The numeral is rendered through `LocaleNumbers`, so `fa` and `ckb` count
/// down in Eastern Arabic digits rather than Latin ones.
class CountdownScreen extends ConsumerStatefulWidget {
  /// Creates the countdown for [config].
  const CountdownScreen({required this.config, super.key});

  /// The run about to start.
  final RunConfig config;

  /// How many beats the count runs for.
  static const int beats = 3;

  @override
  ConsumerState<CountdownScreen> createState() => _CountdownScreenState();
}

class _CountdownScreenState extends ConsumerState<CountdownScreen> {
  /// How many beats are left. Three, two, one, go.
  int _remaining = CountdownScreen.beats;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // The run enters `countdown` here, not on the previous screen: the phase
    // and the thing the player is looking at stay in step.
    WidgetsBinding.instance.addPostFrameCallback((_) => _begin());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _begin() {
    if (!mounted) return;

    ref.read(runNotifierProvider(widget.config).notifier).start();
    _beat();

    _timer = Timer.periodic(SunburstMotion.of(context).countdownInterval, (_) {
      if (!mounted) return;

      if (_remaining <= 1) {
        _timer?.cancel();
        ref.read(runNotifierProvider(widget.config).notifier).beginPlaying();
        context.go(Routes.play(widget.config));

        return;
      }

      setState(() => _remaining--);
      _beat();
    });
  }

  /// One tick of the count, felt and heard.
  void _beat() => ref.read(feedbackServiceProvider).fire(Moment.countdownBeat);

  @override
  Widget build(BuildContext context) {
    final colours = SunburstColors.of(context);
    final shape = SunburstShape.of(context);
    final type = SunburstType.of(context);
    final l10n = AppLocalizations.of(context);
    final numbers = ref.watch(localeNumbersProvider);
    final definition = ref.watch(gameDefinitionProvider(widget.config.gameId));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // The status glyphs go cream: this is the only screen dark enough at the
      // very top for the default ink ones to disappear into it.
      value: SystemUiOverlayStyle.light,
      child: ColoredBox(
        color: colours.accentAlt,
        child: Stack(
          children: <Widget>[
            // THE BURST IS BEHIND THE SAFE AREA, not inside it. The fill and
            // its texture reach y=0; the content does not.
            Positioned.fill(
              child: HalftoneLayer(
                scene: HalftoneScene(
                  // No dot lattice here — `.count` has the burst alone.
                  ink: null,
                  ray: colours.countdownRay,
                  origin: RayOrigin.centre,
                  spokeDegrees: 6,
                  pitchDegrees: 14,
                ),
              ),
            ),
            SafeArea(
              // top: false. The grape has to reach the top of the display, and
              // the content below still respects the inset.
              top: false,
              child: Padding(
                padding: EdgeInsetsDirectional.only(
                  top: MediaQuery.paddingOf(context).top,
                ),
                child: Column(
                  children: <Widget>[
                    Padding(
                      // app.html: `.count .cgame{padding:2px 20px 0}`.
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        20,
                        2,
                        20,
                        0,
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              l10n.gameAndDifficulty(
                                ref
                                    .watch(gameStringsProvider)(definition)
                                    .title,
                                difficultyLabel(
                                  l10n,
                                  widget.config.difficulty,
                                ),
                              ),
                              // DERIVED: `.count .cgame .nm` is 16/600 and the
                              // scale's nearest step is titleBar at 17/600. A
                              // point apart on one line, against a new step
                              // that would exist to hold one string.
                              style: type.titleBar.copyWith(
                                color: colours.textInvert,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          PopIconButton(
                            // The cross is not a direction and does not
                            // mirror.
                            glyph: SunburstGlyph.close,
                            semanticLabel: l10n.pauseQuit,
                            onPressed: () {
                              ref
                                  .read(
                                    runNotifierProvider(
                                      widget.config,
                                    ).notifier,
                                  )
                                  .abandon();
                              context.go(
                                Routes.gameDetail(widget.config.gameId),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // THE RING FOLLOWS THE NUMERAL, and both are bounded
                          // by the screen. At text scale 2.0 a 132pt numeral is
                          // 264 points tall and the design's 238pt ring cannot
                          // hold it; growing the ring to fit is right until the
                          // ring is wider than a 320pt phone. So it takes the
                          // larger of the token and the scaled numeral, capped
                          // at what the screen actually has. Nothing is
                          // clamped and nothing is scaled down — the ring is
                          // geometry and it is allowed to move.
                          final scaled =
                              MediaQuery.textScalerOf(context).scale(
                                type.countdownNumeral.fontSize!,
                              ) *
                              _ringToNumeral;
                          final ring = math.min(
                            constraints.maxWidth - _ringGutter,
                            math.max(shape.countdownRing, scaled),
                          );

                          // IT SCROLLS RATHER THAN CLIPPING. At text scale
                          // 2.0 the ring, the gap and a two-line "Get ready"
                          // are taller than the band between the title row and
                          // the beat dots. Centred while it fits, pannable when
                          // it does not — nothing is scaled down and nothing is
                          // cut off.
                          return SingleChildScrollView(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  PopSurface(
                                    fill: colours.accent,
                                    radius: BorderRadiusDirectional.all(
                                      shape.radiusPill,
                                    ),
                                    elevation: PopElevation.e4,
                                    minTarget: 0,
                                    child: SizedBox(
                                      width: ring,
                                      height: ring,
                                      // ONE live region, updated in place. Three
                                      // separate announcements would talk over each
                                      // other at one-second intervals.
                                      child: Semantics(
                                        liveRegion: true,
                                        child: Center(
                                          child: Text(
                                            numbers.count(_remaining),
                                            style: type.countdownNumeral
                                                .copyWith(
                                                  color: colours.textPrimary,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 26),
                                  // The screen's one h1. "Get ready" is what this
                                  // screen IS, and a screen with no heading is one a
                                  // screen-reader user arrives on with no idea where
                                  // they are.
                                  Semantics(
                                    header: true,
                                    child: Text(
                                      l10n.getReady,
                                      style: type.countdownReady.copyWith(
                                        color: colours.textInvert,
                                        shadows: <Shadow>[
                                          Shadow(
                                            color: colours.border,
                                            offset: shape.countdownReadyShadow,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsetsDirectional.only(bottom: 52),
                      child: _BeatDots(
                        filled: CountdownScreen.beats - _remaining + 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// How much wider the ring is than the numeral it holds.
///
/// 238 / 132, the design's own proportion, kept when either moves.
const double _ringToNumeral = 238 / 132;

/// How much of the screen's width the ring leaves on either side.
const double _ringGutter = 40;

/// Three dots, one filling per beat.
///
/// **The row does not mirror.** It is a progress meter for a count that is
/// about to reach zero, not a sentence; and each dot is a circle, so there is
/// nothing in it a reading direction could be about. It announces nothing —
/// the numeral above it is the live region, and a second one would talk over
/// the first.
class _BeatDots extends StatelessWidget {
  const _BeatDots({required this.filled});

  final int filled;

  @override
  Widget build(BuildContext context) {
    final colours = SunburstColors.of(context);
    final shape = SunburstShape.of(context);

    return ExcludeSemantics(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          for (var index = 0; index < CountdownScreen.beats; index++)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 10),
              child: Container(
                width: shape.countdownDot,
                height: shape.countdownDot,
                decoration: BoxDecoration(
                  color: index < filled
                      ? colours.accent
                      : colours.countdownDotIdle,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colours.border,
                    width: shape.borderWidth,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
