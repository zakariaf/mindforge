// The game hub — screen 01. Composed only from Sunburst components; every game
// on it comes out of `gameRegistryProvider` as data, so shipping a third game
// adds ZERO lines to this file (SKILL.md rule 12).
//
// Owned elsewhere: PopChip/GameCard (`sunburst-components`), RayHeader/DailyMixCard/
// Wordmark (shell composites, lib/features/shell/widgets/), SunburstColors/
// SunburstShape/SunburstType (`sunburst-tokens`).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/sunburst_theme.dart';
import '../../../ui/components/game_card.dart';
import '../../../ui/components/pop_chip.dart';
import '../../../ui/glyphs/sunburst_glyph.dart';
import '../../shell/widgets/daily_mix_card.dart';
import '../../shell/widgets/ray_header.dart';
import '../../shell/widgets/wordmark.dart';
import '../application/home_notifier.dart'; // HomeGameEntry, homeNotifierProvider

/// Branch 1 of the nav shell. The 90pt `PopBottomNav` belongs to the
/// `StatefulShellRoute`, not to this screen (rule 10).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = SunburstColors.of(context);
    final home = ref.watch(homeNotifierProvider); // one Notifier, ready to render

    return Scaffold(
      // Cream behind the status-bar strip; the sunshine header starts below the
      // top inset, carrying its 3px ink bottom border only (rule 6).
      backgroundColor: colors.surface,
      body: SafeArea(
        bottom: false, // the nav bar in the branch shell owns the bottom inset
        child: Column(
          children: [
            _HomeHeader(greeting: home.greetingLabel, streakDays: home.streakDays),
            Expanded(
              child: ListView(
                // `.body-pad`: pad 16/20/0, stacked gap 16.
                padding: const EdgeInsetsDirectional.fromSTEB(
                  SunburstShape.gutter,
                  SunburstShape.cardGap,
                  SunburstShape.gutter,
                  SunburstShape.cardGap,
                ),
                children: [
                  DailyMixCard(
                    subtitle: home.dailyMixLabel,
                    onTap: () =>
                        ref.read(homeNotifierProvider.notifier).startDailyMix(),
                  ),
                  const SizedBox(height: SunburstShape.cardGap),
                  _SectionLabel(unlockedCount: home.unlockedCount),
                  const SizedBox(height: SunburstShape.cardGap),
                  for (final entry in home.games) ...[
                    _GameEntry(entry: entry),
                    const SizedBox(height: SunburstShape.cardGap),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sunshine header: rays .5 + dots .16, pad 6/20/22. Holds the screen's only h1.
class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.greeting, required this.streakDays});

  final String greeting; // already localized AND already time-resolved by the
  final int streakDays; //  Notifier — no DateTime.now() in the widget layer.

  @override
  Widget build(BuildContext context) {
    final colors = SunburstColors.of(context);
    final type = SunburstType.of(context);
    final l10n = AppLocalizations.of(context);

    return RayHeader(
      fill: colors.accent,
      rayFill: colors.accentDeep,
      rayOpacity: 0.5,
      dotOpacity: 0.16,
      padding: const EdgeInsetsDirectional.fromSTEB(
        SunburstShape.gutter, 6, SunburstShape.gutter, 22,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Wordmark(),
              PopChip(
                glyph: SunburstGlyph.flame,
                label: l10n.streakDays(streakDays),
              ),
            ],
          ),
          const SizedBox(height: SunburstShape.cardGap),
          Text(
            greeting,
            // `greeting` is Nunito 800/14 and INK, never textSecondary: sunshine
            // + rays + dots composite to 3.2:1 under ink-2, which fails AA.
            style: type.greeting.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: 2), // `.ask` margin-top, an optical nudge
          // The screen's ONE header. Focus lands here on entry (rule 9).
          Semantics(
            header: true,
            child: Text(l10n.homeTitle, style: type.displayL),
          ),
        ],
      ),
    );
  }
}

/// `.seclab` — "Your games" / "2 unlocked", baseline-aligned.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.unlockedCount});

  final int unlockedCount;

  @override
  Widget build(BuildContext context) {
    final colors = SunburstColors.of(context);
    final type = SunburstType.of(context);
    final l10n = AppLocalizations.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(l10n.yourGames, style: type.sectionLabel),
        Text(
          l10n.gamesUnlocked(unlockedCount),
          // ink-2 is legal here: this line sits on cream, not on a saturated fill.
          style: type.caption.copyWith(color: colors.textSecondary),
        ),
      ],
    );
  }
}

/// One registry entry → one card. No `switch (gameId)` anywhere: everything the
/// card renders is a `GameDefinition` field or a repository value.
class _GameEntry extends ConsumerWidget {
  const _GameEntry({required this.entry});

  final HomeGameEntry entry; // { definition, bestLabel } — precomputed by the Notifier

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final definition = entry.definition;
    final id = definition.id;

    return GameCard(
      // Locked renders as cream-2 + a 3px DASHED ink border and NO shadow —
      // a state of the same widget, not a second widget.
      isLocked: definition.isLocked,
      accent: definition.accent,
      title: l10n.gameTitle(id.value),
      tagline: definition.isLocked ? l10n.comingSoon : l10n.gameTagline(id.value),
      bestLabel: entry.bestLabel, // formatted by ScoreFormat: "1,480" or "18.6s"
      artwork: definition.buildArtwork(context),
      // Resolve the stable id in the callback, never a captured content value.
      onTap: definition.isLocked
          ? null
          : () => ref.read(homeNotifierProvider.notifier).openGame(id),
    );
  }
}
