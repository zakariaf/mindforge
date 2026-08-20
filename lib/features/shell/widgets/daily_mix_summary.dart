import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindforge/features/home/application/home_notifier.dart';
import 'package:mindforge/games/game_registry.dart';
import 'package:mindforge/l10n/app_localizations.dart';
import 'package:mindforge/l10n/game_strings.dart';

/// The line under "Daily Mix", in v1.
///
/// **It names the one game today's pick leads to, and does not say "3 games, 4
/// minutes".** `app.html` draws that summary and a curated three-game mix is a
/// product feature nobody has built; a card that printed it would be a sentence
/// about software that does not exist, in a public repository, which is exactly
/// what CLAUDE.md forbids. `dailyMixSummary` stays in the ARB, unused, for the
/// epic that ships the real mix.
///
/// One function shared by Home and game detail, because the two cards differ in
/// skin and in nothing else — and a summary that drifted between them would be
/// two answers to "what is today's mix".
String dailyMixSummary(BuildContext context, WidgetRef ref) {
  final pick = ref.watch(homeHubProvider).dailyPick;
  final definition = ref.watch(gameDefinitionProvider(pick));

  return AppLocalizations.of(
    context,
  ).dailyMixTodaysPick(ref.watch(gameStringsProvider)(definition).title);
}
