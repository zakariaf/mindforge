import 'package:drift/drift.dart';
import 'package:meta/meta.dart';
import 'package:mindforge/core/app_settings.dart';
import 'package:mindforge/core/supported_locale.dart';
import 'package:mindforge/data/db/app_database.dart';
import 'package:mindforge/data/db/tables/settings.dart';

part 'settings_dao.drift.dart';

/// The outcome of mapping the stored settings row.
///
/// Carries the mapped value **and** whether the stored `locale_tag` was
/// unrecognised, so the repository can report the degradation without the DAO
/// needing a log sink of its own.
typedef SettingsRead = ({AppSettings settings, String? unsupportedLocaleTag});

/// Single-table queries over `settings`, and the row-to-[AppSettings] mapping.
///
/// Holds no business rules and no transactions: those are the repository's.
@DriftAccessor(tables: [SettingsTable])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  /// Creates the accessor over [db].
  SettingsDao(super.attachedDatabase);

  SimpleSelectStatement<SettingsTable, SettingsRow> _selectTheRow() =>
      select(settingsTable)..where((t) => t.id.equals(kSettingsRowId));

  /// Watches the one settings row.
  Stream<SettingsRead> watch() => _selectTheRow().watchSingle().map(mapRow);

  /// Reads the one settings row once.
  Future<SettingsRead> read() async =>
      mapRow(await _selectTheRow().getSingle());

  /// The current `row_revision`, so a write can bump it by exactly one.
  Future<int> readRevision() async =>
      (await _selectTheRow().getSingle()).rowRevision;

  /// Maps a stored row to [AppSettings].
  ///
  /// **This is where the supported-locale set is enforced.** A `NULL` tag means
  /// "follow the system locale" and maps straight through; a non-null tag that
  /// does not parse also maps to `null`, and is reported in
  /// the returned record's `unsupportedLocaleTag` field, so the caller can log it.
  ///
  /// The read deliberately does **not** self-heal by rewriting the column. That
  /// would be a side effect inside a read, and it would permanently destroy a
  /// real preference for someone who downgraded to a build that dropped a
  /// locale and then upgraded again — their choice comes back on its own if the
  /// column is left alone.
  @visibleForTesting
  SettingsRead mapRow(SettingsRow row) {
    final tag = row.localeTag;
    final parsed = tag == null ? null : SupportedLocale.tryParse(tag);

    return (
      settings: AppSettings(
        isSoundEnabled: row.isSoundEnabled == 1,
        isHapticsEnabled: row.isHapticsEnabled == 1,
        isReduceMotionEnabled: row.isReduceMotionEnabled == 1,
        isColourBlindPalette: row.isColourBlindPalette == 1,
        localeOverride: parsed,
      ),
      unsupportedLocaleTag: tag != null && parsed == null ? tag : null,
    );
  }

  /// Writes [settings] into the one row, with the given audit stamp.
  ///
  /// Called only from inside `SettingsRepository`'s transaction.
  Future<void> write(
    AppSettings settings, {
    required int updatedAtUtcMs,
    required int rowRevision,
  }) async {
    await (update(
      settingsTable,
    )..where((t) => t.id.equals(kSettingsRowId))).write(
      SettingsTableCompanion(
        isSoundEnabled: Value(settings.isSoundEnabled ? 1 : 0),
        isHapticsEnabled: Value(settings.isHapticsEnabled ? 1 : 0),
        isReduceMotionEnabled: Value(settings.isReduceMotionEnabled ? 1 : 0),
        isColourBlindPalette: Value(settings.isColourBlindPalette ? 1 : 0),
        // Value(null) writes SQL NULL; Value.absent() would leave the old
        // tag in place, which is exactly the bug withSystemLocale() exists
        // to avoid.
        localeTag: Value(settings.localeOverride?.tag),
        updatedAtUtcMs: Value(updatedAtUtcMs),
        rowRevision: Value(rowRevision),
      ),
    );
  }
}
