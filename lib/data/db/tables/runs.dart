import 'package:drift/drift.dart';
import 'package:mindforge/data/db/tables/audit_columns.dart';

/// One row per completed run. The only authority for everything a player has
/// ever done.
///
/// Every column is canonical and locale-independent: integers, a UTC epoch
/// instant, a local serial day, and ASCII tokens. Accuracy, personal best,
/// aggregates and the streak are **not** columns — they are folds over this
/// table, recomputed on read.
// The idempotency guarantee, in the schema rather than in a Dart guard.
// PARTIAL — `WHERE is_deleted = 0` — so a soft-deleted run does not permanently
// reserve its key, which would make a delete-then-replay impossible.
@TableIndex.sql(
  'CREATE UNIQUE INDEX ux_runs_client_key ON runs (client_run_key) '
  'WHERE is_deleted = 0;',
)
// Equality columns lead, the sort column trails: this is the index every scoped
// read uses, and the order is what lets SQLite satisfy the ORDER BY from the
// index rather than sorting afterwards.
@TableIndex.sql(
  'CREATE INDEX idx_runs_game_difficulty_time ON runs '
  '(game_id, difficulty_id, started_at_utc_ms);',
)
// The streak fold reads distinct days and nothing else.
@TableIndex.sql('CREATE INDEX idx_runs_day ON runs (played_on_day);')
@DataClassName('RunRow')
class Runs extends Table with AuditColumns {
  /// Which game, as an ASCII token such as `stroop_rush`.
  TextColumn get gameId => text()();

  /// Which difficulty, as an ASCII token such as `classic`.
  TextColumn get difficultyId => text()();

  /// The engine's idempotency key for this run.
  TextColumn get clientRunKey => text()();

  /// When the run started, as UTC epoch milliseconds.
  IntColumn get startedAtUtcMs => integer()();

  /// The local civil day the run counts towards, as a serial day number.
  IntColumn get playedOnDay => integer()();

  /// Wall-clock length of the run, in milliseconds.
  IntColumn get durationMs => integer()();

  /// `points` or `duration` — mirrors `ScoreFormat.name` exactly.
  TextColumn get metricKind => text()();

  /// The score, in the unit [metricKind] names.
  IntColumn get metricValue => integer()();

  /// How many answers were correct.
  IntColumn get correctCount => integer()();

  /// How many answers were wrong.
  IntColumn get wrongCount => integer()();

  /// The longest unbroken run of correct answers.
  IntColumn get longestCombo => integer()();

  /// The **sum** of every reaction time, in milliseconds.
  IntColumn get totalReactionMs => integer()();

  @override
  bool get isStrict => true;

  @override
  List<String> get customConstraints => <String>[
    // Identifier columns are ASCII TOKENS, never display names. A translated
    // title here would make every scoped query locale-dependent, so the shape
    // is constrained rather than the value set — the set of game ids is
    // registry data owned by GameDefinition, and a closed CHECK ... IN would
    // turn shipping a third game into a needless migration.
    "CHECK (length(game_id) BETWEEN 1 AND 64 AND game_id NOT GLOB '*[^a-z0-9_]*')",
    "CHECK (length(difficulty_id) BETWEEN 1 AND 64 AND difficulty_id NOT GLOB '*[^a-z0-9_]*')",
    "CHECK (length(client_run_key) BETWEEN 1 AND 128 AND client_run_key NOT GLOB '*[^ -~]*')",
    // This one IS a closed list, because the data layer itself interprets it
    // to decide MAX versus MIN. A test asserts it equals
    // ScoreFormat.values.map((f) => f.name), so adding a third format is a
    // migration rather than a silent constraint violation.
    "CHECK (metric_kind IN ('points','duration'))",
    'CHECK (started_at_utc_ms > 0)',
    'CHECK (duration_ms >= 0)',
    'CHECK (metric_value >= 0)',
    'CHECK (correct_count >= 0)',
    'CHECK (wrong_count >= 0)',
    'CHECK (longest_combo >= 0)',
    'CHECK (longest_combo <= correct_count)',
    'CHECK (total_reaction_ms >= 0)',
    'CHECK (is_deleted IN (0,1))',
  ];
}
