import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindforge/core/board_snapshot.dart';
import 'package:mindforge/core/hud_tone.dart';
import 'package:mindforge/core/result_stat.dart';
import 'package:mindforge/core/run_config.dart';
import 'package:mindforge/core/run_outcome.dart';
import 'package:mindforge/data/data_providers.dart';
import 'package:mindforge/games/stroop_rush/domain/stroop_board_state.dart';
import 'package:mindforge/games/stroop_rush/domain/stroop_difficulty_profile.dart';
import 'package:mindforge/games/stroop_rush/domain/stroop_round_generator.dart';
import 'package:mindforge/games/stroop_rush/domain/stroop_scoring.dart';
import 'package:mindforge/shared/feedback/feedback_service.dart';
import 'package:mindforge/shared/feedback/moment.dart';

/// The board's one owner.
///
/// **It owns no clock and never reads the run.** The elapsed time, the run
/// limit, the phase machine and the decision to navigate are all the shell's;
/// this publishes what the board knows and nothing else. A board that read the
/// run could end it, pause it, or start a second timer — which is the failure
/// `sunburst-shell-screens` rule 3 exists to prevent.
///
/// Family-keyed by `RunConfig` and auto-disposed, so "play again" with a fresh
/// seed is a fresh notifier and a fresh deck rather than a reset.
final class StroopBoardNotifier extends Notifier<StroopBoardState> {
  /// Creates the notifier for [config].
  ///
  /// Riverpod 3 hands a family's argument to the CONSTRUCTOR — `build()` takes
  /// none — so the config is a field.
  StroopBoardNotifier(this.config);

  /// Which run is being played.
  final RunConfig config;

  /// When the current round was put in front of the player.
  ///
  /// **From the injected `Clock`, never an ambient wall-clock read and never a
  /// stopwatch.** A board may measure its own reaction times — that is what
  /// `BoardSnapshot.totalReactionMs` is for — and doing it through the
  /// injected clock is what keeps the measurement testable and the rule
  /// against a second RUN timer intact. This is not a run clock: it never
  /// decides when the run ends, and the shell's elapsed time is still the
  /// only thing the HUD's Time pill shows.
  /// `late` rather than an epoch placeholder: `build()` always assigns before
  /// anything can read it, so a genuine misuse throws instead of banking a
  /// fifty-six-year reaction time.
  late DateTime _shownAt;

  @override
  StroopBoardState build() {
    // READ, not watch. The palette is an input to GENERATION, captured once:
    // watching it would re-deal the deck the moment a player flipped the
    // setting mid-run, rewriting the question they are looking at.
    final isColourBlind = ref.read(appSettingsProvider).isColourBlindPalette;
    final rounds = generateStroopRounds(
      seed: config.seed,
      difficulty: config.difficulty,
      isColourBlindPalette: isColourBlind,
    );

    _shownAt = ref.read(clockProvider).now();

    return StroopBoardState(
      rounds: rounds,
      index: 0,
      score: const StroopScore.zero(),
      keyStates: List<AnswerKeyState>.filled(
        rounds.first.options.length,
        AnswerKeyState.idle,
      ),
      isColourBlindPalette: isColourBlind,
    );
  }

  /// The player tapped the key at [optionIndex].
  ///
  /// The one intent method. Everything else on this notifier is derived.
  void submit(int optionIndex) {
    final round = state.current;

    // A tap after the last round changes nothing. The board freezes when the
    // run ends and the shell decides what happens next.
    if (round == null) return;

    final profile = profileFor(config.difficulty);
    final isCorrect = round.options[optionIndex] == round.ink;
    final now = ref.read(clockProvider).now();
    // Floored at zero. A clock that goes backwards — a manual time change, a
    // fake clock rewound in a test — would otherwise bank a negative reaction
    // and make the average meaningless.
    final reactionMs = now.difference(_shownAt).inMilliseconds.clamp(0, 60000);
    final score = applyAnswer(
      state.score,
      isCorrect: isCorrect,
      profile: profile,
    );

    if (!isCorrect) {
      _fire(Moment.answerWrong);

      state = state.copyWith(
        score: score,
        // THE LATCH RESETS WITH THE STREAK. It exists to stop ONE crossing
        // firing on every frame after it happens — not to stop a rebuilt
        // streak celebrating. Breaking at six and climbing back to five is a
        // new achievement and is felt as one.
        lastMilestone: 0,
        wrongKeyIndex: optionIndex,
        // A NEW IDENTITY on every wrong tap, so tapping the same wrong key
        // twice shakes twice. Without it the second tap looks to the animation
        // like a rebuild of the first.
        wrongTapId: state.wrongTapId + 1,
        keyStates: _keyStatesWith(optionIndex, AnswerKeyState.rejected),
      );

      return;
    }

    // Only a CORRECT answer records a reaction: a wrong tap leaves the round
    // in front of the player, and counting the false start as a measurement
    // would report an average nobody achieved.
    _reactionMs += reactionMs;
    _shownAt = now;

    final milestone = _milestoneCrossed(score.streak, profile);

    // THE MILESTONE REPLACES THE TICK rather than stacking on it. Two haptics
    // on one answer are felt as one longer buzz, which reads as a stutter.
    _fire(milestone == null ? Moment.answerCorrect : Moment.streakMilestone);

    final nextIndex = state.index + 1;
    final isFinished = nextIndex >= state.rounds.length;

    state = state.copyWith(
      index: nextIndex,
      score: score,
      clearWrongKey: true,
      lastMilestone: milestone ?? state.lastMilestone,
      keyStates: isFinished
          ? List<AnswerKeyState>.filled(
              state.keyStates.length,
              AnswerKeyState.locked,
            )
          : List<AnswerKeyState>.filled(
              state.rounds[nextIndex].options.length,
              AnswerKeyState.idle,
            ),
    );
  }

  /// Reaction time banked across every correct answer, in milliseconds.
  int _reactionMs = 0;

  /// The streak this answer just crossed, or `null` if it crossed none.
  ///
  /// Latched on the highest milestone already reached, because a boundary
  /// condition is true on every frame after it happens. A streak that breaks
  /// and rebuilds past the same step fires again — that is a new achievement,
  /// not a re-fire — and the latch resets with the streak.
  int? _milestoneCrossed(int streak, StroopDifficultyProfile profile) {
    if (streak == 0 || streak % kStroopStreakStep != 0) return null;
    if (streak <= state.lastMilestone) return null;
    // Past the cap the multiplier stops moving, so there is nothing to
    // celebrate: a milestone that fires every five answers forever stops
    // meaning anything.
    if (streakMultiplier(streak, cap: profile.multiplierCap) >=
        streakMultiplier(
              streak - kStroopStreakStep,
              cap: profile.multiplierCap,
            ) +
            1) {
      return streak;
    }

    return null;
  }

  List<AnswerKeyState> _keyStatesWith(int index, AnswerKeyState value) {
    final states = List<AnswerKeyState>.filled(
      state.keyStates.length,
      AnswerKeyState.idle,
    );

    states[index] = value;

    return states;
  }

  /// Reaction time banked across every correct answer.
  int get totalReactionMs => _reactionMs;

  /// One moment, on the commit frame, once.
  void _fire(Moment moment) => ref.read(feedbackServiceProvider).fire(moment);
}

/// The board's state, per run.
// The lint wants the family's own type spelled out and Riverpod 3 exports no
// name for it — the same reason the run family is declared this way.
// ignore: specify_nonobvious_property_types
final stroopBoardNotifierProvider = NotifierProvider.autoDispose
    .family<StroopBoardNotifier, StroopBoardState, RunConfig>(
      StroopBoardNotifier.new,
    );

/// What the shell reads: three HUD slots, a progress value and an outcome.
///
/// **Derived, never stored.** A snapshot field on the state would be a second
/// copy of the score that can disagree with it.
///
/// Every value is a canonical INTEGER. The shell formats — a board that
/// published `۱٬۲۴۰` would make the Stats table unsortable and would go stale
/// the moment the language changed mid-run.
// ignore: specify_nonobvious_property_types
final stroopBoardSnapshotProvider = Provider.autoDispose
    .family<BoardSnapshot, RunConfig>((ref, config) {
      final state = ref.watch(stroopBoardNotifierProvider(config));
      final profile = profileFor(config.difficulty);
      final multiplier = streakMultiplier(
        state.score.streak,
        cap: profile.multiplierCap,
      );

      return BoardSnapshot(
        hud: GameHud(
          // TIME is the SHELL's clock, published with an empty value. The
          // board does not know how long the run has been going and must not:
          // a second timer is the thing rule 3 forbids.
          leading: const HudSlot(
            labelKey: 'hudTime',
            canonicalValue: 0,
            format: StatFormat.duration,
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
            // DERIVED, matching screen 04's sunshine STREAK pill: the pill
            // lights up once the streak is actually paying more than ×1.
            tone: multiplier > 1 ? HudTone.highlight : HudTone.neutral,
          ),
        ),
        progress: state.progress,
        score: state.score.points,
        correctCount: state.score.correct,
        wrongCount: state.score.wrong,
        longestCombo: state.score.bestStreak,
        totalReactionMs: ref
            .watch(stroopBoardNotifierProvider(config).notifier)
            .totalReactionMs,
        outcome: state.isFinished
            ? _outcomeOf(
                state.score,
                ref
                    .watch(stroopBoardNotifierProvider(config).notifier)
                    .totalReactionMs,
              )
            : null,
      );
    });

/// The three cells the results screen shows.
///
/// Accuracy, average reaction and longest streak — the three `06-results.png`
/// draws, and the three the shell has ARB rows for.
RunOutcome _outcomeOf(StroopScore score, int totalReactionMs) {
  final answered = score.correct + score.wrong;

  return RunOutcome.completed(
    // PER MILLE, which is StatFormat.percent's canonical unit: a rounded
    // percentage is a display decision and making it here would freeze one
    // locale's idea of precision.
    first: ResultStat(
      labelKey: 'accuracyLabel',
      format: StatFormat.percent,
      canonicalValue: answered == 0 ? 0 : (score.correct * 1000) ~/ answered,
    ),
    // AVERAGED OVER CORRECT ANSWERS ONLY. A wrong tap leaves the round in
    // front of the player, so counting it would fold thinking time into a
    // number that is supposed to be a reflex.
    second: ResultStat(
      labelKey: 'avgReactionLabel',
      format: StatFormat.duration,
      canonicalValue: score.correct == 0 ? 0 : totalReactionMs ~/ score.correct,
    ),
    third: ResultStat(
      labelKey: 'longestStreakLabel',
      format: StatFormat.multiplier,
      canonicalValue: score.bestStreak,
    ),
  );
}
