import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:mindforge/games/game_definition.dart';
import 'package:mindforge/l10n/arb_lookup.dart';
import 'package:mindforge/l10n/l10n_providers.dart';

/// One game's three resolved strings.
@immutable
final class GameStrings {
  /// Creates a resolved set.
  const GameStrings({
    required this.title,
    required this.tagline,
    required this.kicker,
  });

  /// The game's name, in the active locale.
  final String title;

  /// Its one-line description.
  final String tagline;

  /// The section kicker above its hero.
  final String kicker;
}

/// Resolves a [GameDefinition]'s ARB keys to text.
///
/// **This is the SECOND file in `lib/` that names games, and it is sanctioned.**
/// gen-l10n has no dynamic key lookup — a key held as a string cannot be turned
/// into a getter at runtime — so something has to map one to the other, and
/// doing it here means one file to extend rather than a lookup scattered across
/// eight screens.
///
/// The keys on `GameDefinition` are still the CHECKABLE DECLARATION of what a
/// game promises to have translated; `registry_localization_test` reads them
/// and asserts each exists in all four ARBs and has a generated getter. This is
/// the resolution path, and that test is what keeps the two in step.
final Provider<GameStrings Function(GameDefinition)> gameStringsProvider =
    Provider<GameStrings Function(GameDefinition)>((ref) {
      final l10n = ref.watch(appLocalizationsProvider);

      // BY THE KEYS THE DEFINITION DECLARES, not by the game's id. Switching
      // on the id made this file know every game by name — a `switch (gameId)`
      // in all but location, and the one the engine claim forbids. The keys
      // are already on the definition; resolving them is all this needs to do.
      return (definition) => GameStrings(
        title: arbString(l10n, definition.strings.titleKey),
        tagline: arbString(l10n, definition.strings.taglineKey),
        kicker: arbString(l10n, definition.strings.kickerKey),
      );
    });
