import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mindforge/core/game_id.dart';
import 'package:mindforge/features/home/application/home_notifier.dart';
import 'package:mindforge/features/shell/widgets/daily_mix_card.dart';
import 'package:mindforge/games/game_registry.dart';
import 'package:mindforge/l10n/app_localizations.dart';
import 'package:mindforge/l10n/game_strings.dart';
import 'package:mindforge/routing/routes.dart';

/// The Daily Mix card, or nothing at all.
///
/// **Absent when there is no pick, rather than inert.** A registry with nothing
/// playable — every game feature-flagged off, or only "coming soon" slots left
/// — has no game for the card to lead to, and a card that led nowhere is the
/// dead affordance E11 forbids. Two screens draw it and both would otherwise
/// have had to remember the same conditional.
///
/// It names the ONE game today's seeded pick leads to. `app.html` draws
/// "3 games, 4 minutes"; a curated multi-game mix is a product feature nobody
/// has built, and printing that line would be a sentence about software that
/// does not exist.
class DailyMixCardSlot extends ConsumerWidget {
  /// Creates the slot in [variant]'s skin.
  const DailyMixCardSlot({required this.variant, this.hideFor, super.key});

  /// Which skin: grape on Home, paper on game detail.
  final DailyMixVariant variant;

  /// The game whose screen this is, when it has one.
  ///
  /// **A card that led to the page already on display is a dead affordance.**
  /// `app.html` draws a Daily Mix card on the detail screen and it summarises a
  /// multi-game mix; ours names the ONE game today's pick chose, so on that
  /// game's own screen it read "Today's pick: Stroop Rush" and went nowhere.
  /// Home passes nothing here and always shows it.
  final GameId? hideFor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pick = ref.watch(homeHubProvider).dailyPick;

    if (pick == null || pick == hideFor) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final definition = ref.watch(gameDefinitionProvider(pick));

    return DailyMixCard(
      variant: variant,
      title: l10n.dailyMixTitle,
      summary: l10n.dailyMixTodaysPick(
        ref.watch(gameStringsProvider)(definition).title,
      ),
      onTap: () => context.go(Routes.gameDetail(pick)),
    );
  }
}
