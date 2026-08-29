import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindforge/core/board_snapshot.dart';
import 'package:mindforge/core/hud_tone.dart';
import 'package:mindforge/core/result_stat.dart';
import 'package:mindforge/core/run_config.dart';
import 'package:mindforge/core/run_outcome.dart';
import 'package:mindforge/data/data_providers.dart';
import 'package:mindforge/games/false_light/domain/light_board_state.dart';
import 'package:mindforge/games/false_light/domain/light_difficulty_profile.dart';
import 'package:mindforge/games/false_light/domain/light_field_generator.dart';
import 'package:mindforge/games/false_light/domain/light_scoring.dart';
import 'package:mindforge/games/false_light/domain/tile_depth.dart';
import 'package:mindforge/shared/feedback/feedback_service.dart';
import 'package:mindforge/shared/feedback/moment.dart';

/// The board's one owner.
///
/// **It owns no clock and never reads the run.** That is not a rule this game
/// merely obeys; it is the reason the game has the shape it has. An earlier
/// design flipped tiles on an interval, which needs elapsed time inside
/// `lib/games/**` — and there is no legal source of one: `RunConfig` carries
/// `gameId`, `difficulty` and `seed`, `GameBoardBuilder` passes no clock, and
/// `Stopwatch`, `Ticker`, `Timer.periodic` and `AnimationController` are each
/// banned here by two gate scripts and two policy tests. Dealing fields and
/// advancing when one is swept needs none of it.
///
/// Family-keyed by `RunConfig` and auto-disposed, so "play again" with a fresh
/// seed is a fresh notifier and a fresh ladder rather than a reset.
final class LightBoardNotifier extends Notifier<LightBoardState> {
  /// Creates the notifier for [config].
  LightBoardNotifier(this.config);

  /// Which run is being played.
  final RunConfig config;

  /// When the current field was put in front of the player.
  ///
  /// From the injected `Clock`, never an ambient wall-clock read and never a
  /// stopwatch. This is not a run clock: it never decides when the run ends,
  /// and the shell's elapsed time is still the only thing the Time pill shows.
  late DateTime _shownAt;

  @override
  LightBoardState build() {
    final fields = generateLightFields(
      seed: config.seed,
      difficulty: config.difficulty,
    );

    _shownAt = ref.read(clockProvider).now();

    return LightBoardState(
      fields: fields,
      index: 0,
      score: const LightScore.zero(),
      tileStates: List<LightTileState>.filled(
        fields.first.tileCount,
        LightTileState.idle,
      ),
    );
  }

  /// The board is on screen and the field in front of the player starts now.
  void markShown() => _shownAt = ref.read(clockProvider).now();

  /// The player tapped the tile at [tileIndex].
  ///
  /// The one intent method. Everything else on this notifier is derived.
  void submit(int tileIndex) {
    final field = state.current;

    if (field == null) return;
    // An already-swept tile is not a second answer. Without this a player could
    // farm a field by tapping one pressed tile repeatedly, and `correctCount`
    // would climb past the number of tiles that were ever pressed.
    if (state.tileStates[tileIndex] == LightTileState.swept) return;

    final profile = profileFor(config.difficulty);
    final isCorrect = field.tiles[tileIndex] == TileDepth.pressed;
    final score = applySweep(
      state.score,
      isCorrect: isCorrect,
      profile: profile,
    );

    if (!isCorrect) {
      _fire(Moment.answerWrong);

      state = state.copyWith(
        score: score,
        lastMilestone: 0,
        // A NEW IDENTITY on every wrong tap, so tapping the same raised tile
        // twice shakes twice.
        wrongTapId: state.wrongTapId + 1,
        // KEEP THE SWEPT TILES. A wrong tap is a mistake inside a field, not a
        // restart of it: without this the whole field went back to `idle`, the
        // player could sweep the same pressed tile again for full points, and
        // `correctCount` climbed past the number of tiles that were ever
        // pressed — into the row the repository persists. Measured: sweep,
        // tap a raised tile, sweep the same tile again, and correct went 1 -> 2
        // off one tile.
        tileStates: _tileStatesWith(
          tileIndex,
          LightTileState.rejected,
          keep: true,
        ),
      );

      return;
    }

    final milestone = _milestoneCrossed(score.streak, profile);

    // THE MILESTONE REPLACES THE TICK rather than stacking on it. Two haptics
    // on one tap are felt as one longer buzz, which reads as a stutter.
    _fire(milestone == null ? Moment.tileFound : Moment.streakMilestone);

    final next = state.copyWith(
      score: score,
      lastMilestone: milestone ?? state.lastMilestone,
      tileStates: _tileStatesWith(tileIndex, LightTileState.swept, keep: true),
    );

    if (!next.isFieldSwept) {
      state = next;

      return;
    }

    // THE FIELD IS DONE. Advance, or end the run — and bank the time over the
    // whole FIELD rather than per tap, because a sweep is one sustained search
    // and the number a player recognises is how long the search took.
    final now = ref.read(clockProvider).now();

    _reactionMs += now.difference(_shownAt).inMilliseconds.clamp(0, 120000);
    _shownAt = now;
    _fieldsCleared += 1;

    final nextIndex = next.index + 1;
    final isFinished = nextIndex >= next.fields.length;

    state = next.copyWith(
      index: nextIndex,
      tileStates: isFinished
          ? List<LightTileState>.filled(
              next.tileStates.length,
              LightTileState.locked,
            )
          : List<LightTileState>.filled(
              next.fields[nextIndex].tileCount,
              LightTileState.idle,
            ),
    );
  }

  /// Time banked across every cleared field, in milliseconds.
  int _reactionMs = 0;

  /// How many fields were cleared.
  int _fieldsCleared = 0;

  /// The streak this sweep just crossed, or `null` if it crossed none.
  int? _milestoneCrossed(int streak, LightDifficultyProfile profile) {
    if (streak == 0 || streak % kFalseLightStreakStep != 0) return null;
    if (streak <= state.lastMilestone) return null;

    final cap = profile.multiplierCap;
    final moved =
        streakMultiplier(streak, cap: cap) >
        streakMultiplier(streak - kFalseLightStreakStep, cap: cap);

    return moved ? streak : null;
  }

  /// The tile states with [index] set to [value].
  ///
  /// [keep] preserves the tiles already swept.
  ///
  /// **Every caller passes it.** It survives as a parameter rather than as
  /// unconditional behaviour because the reset it guards against is genuinely
  /// what the other tile states want — a rejected tile clears when the next tap
  /// lands — and naming the exception is what makes the field's end condition
  /// legible: every pressed tile swept, which resetting them would make
  /// unreachable.
  List<LightTileState> _tileStatesWith(
    int index,
    LightTileState value, {
    bool keep = false,
  }) {
    final states = <LightTileState>[
      for (final existing in state.tileStates)
        if (keep && existing == LightTileState.swept)
          LightTileState.swept
        else
          LightTileState.idle,
    ];

    states[index] = value;

    return states;
  }

  /// Time banked across every cleared field, in milliseconds.
  ///
  /// **A SUM, because that is what the column holds.** `RunRecord` documents
  /// `totalReactionMs` as "the sum of every reaction time, not the average",
  /// and both `RunRecord.averageReactionMs` and `GameStats.averageReactionMs`
  /// divide it by the answered count. Publishing an average here stored one and
  /// then divided it again, so a run averaging eight seconds a field reported a
  /// ~114ms reaction and skewed every cross-run aggregate with it.
  int get totalFieldMs => _reactionMs;

  /// Average time to clear one field, in milliseconds.
  ///
  /// The results cell's number, derived here and never stored.
  int get averageFieldMs =>
      _fieldsCleared == 0 ? 0 : _reactionMs ~/ _fieldsCleared;

  /// How many fields have been cleared.
  int get fieldsCleared => _fieldsCleared;

  /// One moment, on the commit frame, once.
  void _fire(Moment moment) => ref.read(feedbackServiceProvider).fire(moment);
}

/// The board's state, per run.
// The lint wants the family's own type spelled out and Riverpod 3 exports no
// name for it — the same reason the run family is declared this way.
// ignore: specify_nonobvious_property_types
final lightBoardNotifierProvider = NotifierProvider.autoDispose
    .family<LightBoardNotifier, LightBoardState, RunConfig>(
      LightBoardNotifier.new,
    );

/// What the shell reads: three HUD slots, a progress value and an outcome.
///
/// **Derived, never stored.** Every value is a canonical INTEGER; the shell
/// formats. This board draws no numerals of its own at all, so the HUD is the
/// only place a digit appears on screen while the game is being played.
// ignore: specify_nonobvious_property_types
final lightBoardSnapshotProvider = Provider.autoDispose
    .family<BoardSnapshot, RunConfig>((ref, config) {
      final state = ref.watch(lightBoardNotifierProvider(config));
      final profile = profileFor(config.difficulty);
      final multiplier = streakMultiplier(
        state.score.streak,
        cap: profile.multiplierCap,
      );
      final notifier = ref.watch(lightBoardNotifierProvider(config).notifier);

      return BoardSnapshot(
        hud: GameHud(
          // TIME is the SHELL's clock, and the slot SAYS SO.
          leading: const HudSlot(
            labelKey: 'hudTime',
            canonicalValue: 0,
            format: StatFormat.duration,
            source: HudSource.runClock,
          ),
          middle: HudSlot(
            labelKey: 'hudScore',
            canonicalValue: state.score.points,
            format: StatFormat.points,
          ),
          trailing: HudSlot(
            labelKey: 'hudStreak',
            canonicalValue: multiplier,
            format: StatFormat.multiplier,
            tone: multiplier > 1 ? HudTone.highlight : HudTone.neutral,
          ),
        ),
        progress: state.progress,
        score: state.score.points,
        correctCount: state.score.correct,
        wrongCount: state.score.wrong,
        longestCombo: state.score.bestStreak,
        totalReactionMs: notifier.totalFieldMs,
        outcome: state.isFinished
            ? _outcomeOf(state.score, notifier.averageFieldMs)
            : null,
      );
    });

/// The three cells the results screen shows.
///
/// Accuracy, average field time and longest streak. The middle one is where
/// this game differs from the other three: a sweep is not a reflex, so an
/// average per TAP would measure nothing a player recognises — the number they
/// feel is how long a whole field took to clear.
RunOutcome _outcomeOf(LightScore score, int averageFieldMs) {
  final tapped = score.correct + score.wrong;

  return RunOutcome.completed(
    // PER MILLE, which is StatFormat.percent's canonical unit: a rounded
    // percentage is a display decision and making it here would freeze one
    // locale's idea of precision.
    first: ResultStat(
      labelKey: 'accuracyLabel',
      format: StatFormat.percent,
      canonicalValue: tapped == 0 ? 0 : (score.correct * 1000) ~/ tapped,
    ),
    second: ResultStat(
      labelKey: 'lightFieldTimeLabel',
      format: StatFormat.duration,
      canonicalValue: averageFieldMs,
    ),
    third: ResultStat(
      labelKey: 'longestStreakLabel',
      format: StatFormat.multiplier,
      canonicalValue: score.bestStreak,
    ),
  );
}
