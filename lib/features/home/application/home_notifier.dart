import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:mindforge/core/calendar_day.dart';
import 'package:mindforge/core/game_id.dart';
import 'package:mindforge/core/seeded_generator.dart';
import 'package:mindforge/data/data_providers.dart';
import 'package:mindforge/games/game_definition.dart';
import 'package:mindforge/games/game_registry.dart';

/// Which greeting the hub shows, as an ARB **select** value.
///
/// A key, not a sentence. The notifier decides which part of the day it is; the
/// ARB decides what that sounds like — which is what lets a locale greet
/// differently at different hours in its own file rather than in a Dart switch
/// inside a widget.
enum Daypart {
  /// Before noon.
  morning,

  /// Noon to evening.
  afternoon,

  /// Evening onward.
  evening;

  /// The value `homeGreeting`'s `select` matches on.
  String get selector => name;
}

/// Everything the hub renders, with no rendered string in it.
@immutable
final class HomeState {
  /// Creates the state.
  const HomeState({
    required this.daypart,
    required this.games,
    required this.dailyPick,
    required this.unlockedCount,
  });

  /// Which greeting to resolve.
  final Daypart daypart;

  /// The registry, in display order, unfiltered.
  final List<GameDefinition> games;

  /// The game the Daily Mix card leads to.
  final GameId dailyPick;

  /// How many games are playable today.
  final int unlockedCount;
}

/// The hub's state.
///
/// **It produces keys and ids, never text.** The greeting is a `Daypart`, the
/// games are definitions carrying ARB keys, and the daily pick is a `GameId`.
/// Everything a person reads is resolved by the screen, at render, in whatever
/// locale is active then.
final Provider<HomeState> homeStateProvider = Provider<HomeState>((ref) {
  final games = ref.watch(gameRegistryProvider);
  final now = ref.watch(clockProvider).now();

  return HomeState(
    daypart: daypartAt(now.hour),
    games: games,
    dailyPick: dailyPickFrom(games, CalendarDay.fromLocal(now)),
    unlockedCount: games.where((game) => !game.isLocked).length,
  );
});

/// Which greeting [hour] falls under.
///
/// Pure and hour-only, so a test states the boundary rather than building a
/// `DateTime` to imply it.
Daypart daypartAt(int hour) {
  if (hour < 12) return Daypart.morning;
  if (hour < 18) return Daypart.afternoon;

  return Daypart.evening;
}

/// The game the Daily Mix leads to on [day].
///
/// **Seeded off a civil date and nothing else.** The key handed to the
/// generator is the day's integer serial rendered in ASCII, so the pick is
/// identical in all four locales — a daily pick that moved with the language
/// would mean localisation had leaked into generation, which is the one thing
/// the seeded-generator gate exists to prevent.
///
/// Locked games are skipped: pointing the hub's one call to action at a
/// "coming soon" card would be a dead chevron.
GameId dailyPickFrom(List<GameDefinition> games, CalendarDay day) {
  final playable = games.where((game) => !game.isLocked).toList();

  if (playable.isEmpty) return games.first.id;

  final generator = seedFrom('${day.serial}', featureSalt: _dailyMixSalt);

  return playable[generator.nextInt(playable.length)].id;
}

/// Frozen forever. Changing it reshuffles every past day's pick.
const int _dailyMixSalt = 0x4441494C59; // 'DAILY'
