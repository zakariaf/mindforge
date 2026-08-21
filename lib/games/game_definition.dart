import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindforge/core/board_snapshot.dart';
import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/core/game_id.dart';
import 'package:mindforge/core/run_config.dart';
import 'package:mindforge/core/score_format.dart';
import 'package:mindforge/theme/game_accent.dart';

/// Builds a game's board for one run.
typedef GameBoardBuilder = Widget Function(BuildContext context, RunConfig run);

/// Builds a game's home-card artwork.
typedef GameArtworkBuilder = Widget Function(BuildContext context);

/// How long a run lasts at a difficulty **in milliseconds**, or `null` when it
/// is untimed.
///
/// Milliseconds rather than a `Duration`, and the reason is worth stating: the
/// engine measures in integer milliseconds everywhere it stores or compares a
/// span — `RunDraft.durationMs`, a duration `ResultStat`, the `runs` table.
/// `Duration` appears only where time is being *arithmetic'd* against a clock.
///
/// It also keeps a game's round lengths out of the one place three separate
/// gates insist every `Duration` literal lives, which is `lib/theme/`. A round
/// length is a game rule, not a design token, and neither answer is worse than
/// the other having to bend.
typedef RunLimitLookup = int? Function(Difficulty difficulty);

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

/// Where a run's score comes from.
///
/// **Schulte Grid cannot compute its own score.** It is scored by elapsed time,
/// elapsed time belongs to `RunTicker` inside `RunNotifier`, and `lib/games/**`
/// is fenced from the notifier and from owning a `Stopwatch` — so a Schulte
/// board can count tiles and has no way to know how long it took.
///
/// Without this field the only ways out were for the board to break the fence
/// or for the shell to special-case `ScoreFormat.duration` — a switch on a
/// definition field in a shell file, one step from a switch on the game id.
/// Declaring where the score comes from keeps it data.
enum ScoreSource {
  /// The board reports it, on every snapshot.
  board,

  /// The shell's run clock is the score. Elapsed milliseconds, lower is better.
  runClock,
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
    required this.scoreSource,
    required this.buildBoard,
    required this.buildArtwork,
    required this.buildHeroArt,
    required this.bindBoard,
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
         scoreSource != ScoreSource.runClock ||
             scoreFormat == ScoreFormat.duration,
         'a game scored by the run clock is scored in milliseconds, so its '
         'ScoreFormat is duration. Any other pairing would rank a time as '
         'though higher were better.',
       ),
       assert(
         isTimed || runLimitFor == null,
         'an untimed game has no run limit. Schulte Grid ends when the last '
         'tile is found, and a shell-imposed limit would cut the player off '
         'mid-board.',
       ),
       // Inside the assert, not a loop in the constructor BODY: a body loop
       // runs in release doing nothing, and recompiles the pattern once per
       // key per definition.
       assert(
         strings.keys.every(_isArbKey),
         'a game declares ARB KEYS, not display strings. Every one must be '
         'lowerCamelCase ASCII.',
       );

  /// Whether [key] is a lowerCamelCase ASCII ARB key.
  static bool _isArbKey(String key) => _arbKey.hasMatch(key);

  /// Compiled once, not once per key per definition.
  static final RegExp _arbKey = RegExp(r'^[a-z][a-zA-Z0-9]*$');

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

  /// Where this game's score comes from.
  final ScoreSource scoreSource;

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
  ///
  /// The 64pt tile inside `.gart`'s cream frame. A DIFFERENT drawing from
  /// [buildHeroArt], which is why there are two hooks: `app.html` draws a 2x2
  /// of plain quads on the card and a row of patterned chips on the hero, and
  /// one widget used in both places grew to fill the hero and lost its
  /// patterns on the way.
  final GameArtworkBuilder buildArtwork;

  /// Builds the row of chips under the tagline on the detail hero.
  ///
  /// `app.html`: `.swatchrow`. It is the LEGEND for the second channel — a
  /// player meets the fill patterns here, on a screen with no clock running,
  /// rather than working them out mid-round.
  final GameArtworkBuilder buildHeroArt;

  /// Subscribes the run to this game's board, and returns its current value.
  ///
  /// **A subscription, not a read, and the difference is the whole run.** The
  /// first version of this field was `BoardSnapshot Function(Ref, RunConfig)`,
  /// called from `RunNotifier.build`. A game implements such a thing with
  /// `ref.watch(myBoardProvider)` — which is the natural spelling — and that
  /// makes every board update re-run `build`, which returns a fresh
  /// `RunState.idle`. Measured: the score updated and the phase went from
  /// `playing` back to `idle` on the first tap. Every test passed, because the
  /// fixture returned a CONSTANT snapshot and so never invalidated anything.
  ///
  /// A game implements this by listening and reading:
  ///
  /// ```dart
  /// bindBoard: (ref, run, onChanged) {
  ///   ref.listen(myBoardProvider(run), (_, next) => onChanged(next));
  ///   return ref.read(myBoardProvider(run));
  /// }
  /// ```
  ///
  /// `Ref` rather than `WidgetRef` because the only caller is `RunNotifier`:
  /// the shell reads a snapshot through `RunState`, never directly, so a
  /// board's provider is subscribed to in exactly one place and every screen
  /// sees the same one.
  final BoardSnapshot Function(
    Ref ref,
    RunConfig run,
    void Function(BoardSnapshot snapshot) onChanged,
  )
  bindBoard;

  final RunLimitLookup? _runLimitFor;

  /// How long a run lasts at [difficulty], or `null` when it is untimed.
  ///
  /// **Here rather than on `Difficulty`.** Stroop Rush is a fixed round count
  /// and Schulte Grid is a race scored by elapsed time; one answer on the enum
  /// would force the shell to cut a Schulte player off mid-board.
  ///
  /// No `isTimed` branch: the assert above already guarantees an untimed game
  /// declares no lookup, so `_runLimitFor` is null whenever `isTimed` is false
  /// and the ternary could not change the answer.
  int? runLimitMsFor(Difficulty difficulty) => _runLimitFor?.call(difficulty);
}
