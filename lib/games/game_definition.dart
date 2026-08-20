import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/core/game_id.dart';
import 'package:mindforge/core/score_format.dart';
import 'package:mindforge/features/play/domain/board_snapshot.dart';
import 'package:mindforge/features/play/domain/run_config.dart';
import 'package:mindforge/theme/game_accent.dart';

/// Builds a game's board for one run.
typedef GameBoardBuilder = Widget Function(BuildContext context, RunConfig run);

/// Builds a game's home-card artwork.
typedef GameArtworkBuilder = Widget Function(BuildContext context);

/// How long a run lasts at a difficulty, or `null` when it is untimed.
typedef RunLimitLookup = Duration? Function(Difficulty difficulty);

/// Whether hue is part of a board's answer.
///
/// **Not `GameColourRole`** — `lib/theme/game_accent.dart` already owns that
/// name for the two halves of an accent (`base` and `deep`), and two enums with
/// one name in one app is a rename waiting to happen at the worst moment. This
/// one is about the BOARD, so it is named for the board.
enum BoardColourRole {
  /// Hue is part of the answer, as in Stroop Rush.
  ///
  /// A mechanic board may never show a chrome semantic slot: `success`,
  /// `danger`, `accent` and `warning` all belong to the UI tier, and the
  /// colour-blind setting re-points the gameplay tier out from under them.
  /// Correct and wrong are depth, glyph and motion instead.
  mechanic,

  /// Colour is never the answer, as in Schulte Grid.
  decorative,
}

/// What a board is painted on.
///
/// Paired with [BoardColourRole] by a constructor assert, because
/// `sunburst-game-surfaces` names this as the rule no switch can catch: a
/// mechanic board on an accent background puts the game's identity colour
/// behind the hues that ARE the question.
enum BoardBackground {
  /// The sunk surface. Required for a mechanic board.
  surfaceSunk,

  /// The game's own accent. Available to a decorative board.
  gameAccent,
}

/// The ARB keys a game promises to have translated.
///
/// **Keys, not resolved strings, and not a resolver function.** gen-l10n has no
/// dynamic key lookup, so a key cannot be turned into a getter at runtime —
/// E08's `game_strings.dart` maps each [GameId] to typed getters instead. What
/// a key buys is a CHECKABLE DECLARATION: `registry_localization_test.dart`
/// reads these and asserts each one exists in all four ARBs and has a generated
/// getter, which is the drift a convention cannot catch.
@immutable
final class GameStringIds {
  /// Creates the key set.
  const GameStringIds({
    required this.titleKey,
    required this.taglineKey,
    required this.kickerKey,
  });

  /// The game's name.
  final String titleKey;

  /// The one-line description under it on the home card.
  final String taglineKey;

  /// The short line above the board on the detail screen.
  final String kickerKey;

  /// All three, for a test that walks them.
  List<String> get keys => <String>[titleKey, taglineKey, kickerKey];
}

/// Everything the shell needs to render a game it has never heard of.
///
/// A game contributes one of these plus a board widget, and inherits home,
/// detail, difficulty select, countdown, play scaffold, pause, results and
/// stats. **If the shell needs something this does not carry, the fix is a new
/// field here — never a `switch (gameId)` in a shell file.**
@immutable
final class GameDefinition {
  /// Creates a definition.
  GameDefinition({
    required this.id,
    required this.accent,
    required this.colourRole,
    required this.scoreFormat,
    required this.strings,
    required this.difficulties,
    required this.boardBackground,
    required this.buildBoard,
    required this.buildArtwork,
    required this.snapshotOf,
    this.isTimed = true,
    this.isLocked = false,
    RunLimitLookup? runLimitFor,
  }) : _runLimitFor = runLimitFor,
       assert(
         difficulties.isNotEmpty,
         'a game must offer at least one difficulty, or nothing can start it',
       ),
       assert(
         colourRole != BoardColourRole.mechanic ||
             boardBackground == BoardBackground.surfaceSunk,
         'a mechanic board must sit on surfaceSunk. On the game accent, the '
         'identity colour sits behind the hues that ARE the question.',
       ),
       assert(
         isTimed || runLimitFor == null,
         'an untimed game has no run limit. Schulte Grid ends when the last '
         'tile is found, and a shell-imposed limit would cut the player off '
         'mid-board.',
       ) {
    for (final key in strings.keys) {
      assert(
        RegExp(r'^[a-z][a-zA-Z0-9]*$').hasMatch(key),
        'a game declares ARB KEYS, not display strings. "$key" is not '
        'lowerCamelCase ASCII.',
      );
    }
  }

  /// The stable id, used as a route segment and a database key.
  final GameId id;

  /// The identity colour.
  final GameAccent accent;

  /// Whether hue is part of the answer.
  final BoardColourRole colourRole;

  /// How a score is rendered and, through `metric_kind`, how it is ranked.
  final ScoreFormat scoreFormat;

  /// The ARB keys this game promises.
  final GameStringIds strings;

  /// The difficulties it offers, in display order.
  final List<Difficulty> difficulties;

  /// What the board is painted on.
  final BoardBackground boardBackground;

  /// Whether the shell should run a countdown clock for it.
  final bool isTimed;

  /// Whether it is a "coming soon" placeholder.
  ///
  /// A locked game still declares an accent and artwork: unlocking it is a flag
  /// flip, not a new definition.
  final bool isLocked;

  /// Builds the board.
  final GameBoardBuilder buildBoard;

  /// Builds the home-card artwork.
  final GameArtworkBuilder buildArtwork;

  /// Reads this game's current snapshot, watching whatever provider holds it.
  ///
  /// **A callback taking the shell's `ref`, not a `ProviderListenable`.** That
  /// type is the common supertype of every provider shape, and
  /// `flutter_riverpod` does not export it — so naming it would mean importing
  /// riverpod's internals into `lib/games/`. A callback works for any shape a
  /// game chooses, `Provider` or `NotifierProvider` alike, and the shell calls
  /// it inside its own `build`, so the watch registers exactly where it should.
  final BoardSnapshot Function(WidgetRef ref, RunConfig run) snapshotOf;

  final RunLimitLookup? _runLimitFor;

  /// How long a run lasts at [difficulty], or `null` when it is untimed.
  ///
  /// **Here rather than on `Difficulty`.** Stroop Rush is a fixed round count
  /// and Schulte Grid is a race scored by elapsed time; one answer on the enum
  /// would force the shell to cut a Schulte player off mid-board.
  Duration? runLimitFor(Difficulty difficulty) =>
      isTimed ? _runLimitFor?.call(difficulty) : null;
}
