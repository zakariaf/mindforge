import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mindforge/core/run_config.dart';
import 'package:mindforge/features/play/application/run_notifier.dart';
import 'package:mindforge/features/shell/widgets/ray_header.dart';
import 'package:mindforge/games/game_registry.dart';
import 'package:mindforge/l10n/app_localizations.dart';
import 'package:mindforge/l10n/l10n_providers.dart';
import 'package:mindforge/routing/routes.dart';
import 'package:mindforge/shared/feedback/feedback_service.dart';
import 'package:mindforge/shared/feedback/moment.dart';
import 'package:mindforge/theme/game_accent.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_motion.dart';
import 'package:mindforge/theme/sunburst_type.dart';

/// The 3-2-1 before a run.
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

  @override
  ConsumerState<CountdownScreen> createState() => _CountdownScreenState();
}

class _CountdownScreenState extends ConsumerState<CountdownScreen> {
  /// How many beats are left. Three, two, one, go.
  int _remaining = 3;
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

    _timer = Timer.periodic(SunburstMotion.of(context).countdownInterval, (
      _,
    ) {
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
    final type = SunburstType.of(context);
    final numbers = ref.watch(localeNumbersProvider);
    final definition = ref.watch(gameDefinitionProvider(widget.config.gameId));

    return ColoredBox(
      color: colours.accentFor(definition.accent, GameColourRole.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          RayHeader(
            fill: colours.accentFor(definition.accent, GameColourRole.base),
            child: Text(
              AppLocalizations.of(context).getReady,
              style: type.sectionLabel.copyWith(color: colours.textPrimary),
            ),
          ),
          Expanded(
            child: Center(
              // ONE live region, updated in place. Three separate announcements
              // would talk over each other at one-second intervals.
              child: Semantics(
                liveRegion: true,
                child: Text(
                  numbers.count(_remaining),
                  style: type.countdownNumeral.copyWith(
                    color: colours.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
