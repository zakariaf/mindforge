import 'package:drift/drift.dart';
import 'package:mindforge/data/db/tables/audit_columns.dart';

/// The one settings row. Four toggles and the persisted locale override.
@DataClassName('SettingsRow')
class SettingsTable extends Table with AuditColumns {
  /// Whether sound effects play. `0` or `1`.
  IntColumn get isSoundEnabled => integer()();

  /// Whether haptics fire. `0` or `1`.
  IntColumn get isHapticsEnabled => integer()();

  /// Whether motion is reduced. `0` or `1`.
  IntColumn get isReduceMotionEnabled => integer()();

  /// Whether the colour-blind-safe answer palette is in use. `0` or `1`.
  IntColumn get isColourBlindPalette => integer()();

  /// The user's explicit locale choice as a BCP-47 tag, or `NULL` to follow the
  /// system locale.
  TextColumn get localeTag => text().nullable()();

  @override
  String get tableName => 'settings';

  @override
  bool get isStrict => true;

  @override
  List<String> get customConstraints => <String>[
    // Exactly one row, forever.
    "CHECK (id = 'app')",
    // STRICT has no BOOLEAN type; these CHECKs are what make the columns
    // boolean rather than "any integer".
    'CHECK (is_sound_enabled IN (0,1))',
    'CHECK (is_haptics_enabled IN (0,1))',
    'CHECK (is_reduce_motion_enabled IN (0,1))',
    'CHECK (is_colour_blind_palette IN (0,1))',
    'CHECK (is_deleted IN (0,1))',
    // A SHAPE check, deliberately not IN ('en','de','fa','ckb'). A closed
    // list would leave existing rows in permanent violation the day a locale
    // is withdrawn, so every subsequent UPDATE of the settings row would
    // fail for exactly the users who chose it. The supported set is enforced
    // ON READ, where an unrecognised tag can degrade to "follow system"
    // instead of bricking the row. The shape check still does the job that
    // matters here: it makes a localized string, a numeral or a display name
    // unrepresentable in the column.
    "CHECK (locale_tag IS NULL OR (length(locale_tag) BETWEEN 2 AND 35 AND locale_tag NOT GLOB '*[^a-z-]*'))",
  ];
}
