import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindforge/core/game_id.dart';
import 'package:mindforge/games/game_definition.dart';

/// The shipped games, in display order.
///
/// **This is the only file in `lib/` that may enumerate the game registry.**
/// Home cards, BEST pills, difficulty lists and score formatting are all data
/// read off these definitions; a `switch (gameId)` in a shell file is the thing
/// this exists to make unnecessary.
///
/// Deliberately not "the only file that may name a game": E08 adds
/// `lib/l10n/game_strings.dart`, which maps each [GameId] to its ARB-resolved
/// title because gen-l10n has no dynamic key lookup. That is a second file
/// naming games, and it is sanctioned — so this header claims the narrower
/// thing, which stays true.
///
/// The list is returned **unsorted and unfiltered**. Its order is display
/// order, and a locked game still appears — the home hub renders it as a
/// "coming soon" card rather than hiding it.
///
/// It is **empty** between E09's first commit and its last. E08's three
/// placeholders were deleted here — they existed so the eight screens were
/// renderable and screenshot-comparable in four locales before a real game was
/// written — and Stroop Rush is appended by T09.11.
///
/// Empty is a legitimate state and not only a mid-epic one: it is what a build
/// with every game feature-flagged off looks like, and the shell renders it
/// without pretending otherwise.
final Provider<List<GameDefinition>> gameRegistryProvider =
    Provider<List<GameDefinition>>((ref) => const <GameDefinition>[]);

/// The definition registered under [GameId].
///
/// **Throws a `StateError` for an unknown id, and that is deliberate.** An
/// unregistered id reaching this provider is a bug in the caller, not a
/// recoverable failure a screen should render — the recoverable version is
/// `UnknownGame`, returned by the run notifier when a saved row or a deep link
/// names a game that no longer ships.
// The lint wants the family's own type spelled out, and Riverpod 3 does not
// export a name for it: Provider.family returns an internal type and
// ProviderFamily is not in flutter_riverpod's show list. E02's family providers
// are declared the same way, for the same reason.
// ignore: specify_nonobvious_property_types
final gameDefinitionProvider = Provider.family<GameDefinition, GameId>(
  (ref, id) => _lookUp(ref.watch(gameRegistryProvider), id),
);

/// Finds [id] in [registry], or explains what was there instead.
GameDefinition _lookUp(List<GameDefinition> registry, GameId id) {
  for (final definition in registry) {
    if (definition.id == id) return definition;
  }

  throw StateError(
    'no game is registered under "$id". The registry holds '
    '${registry.map((d) => d.id).toList()}.',
  );
}
