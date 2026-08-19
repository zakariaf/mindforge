import 'package:drift/drift.dart';

/// The columns every table carries: identity, lifecycle timestamps, an
/// optimistic-concurrency counter and soft-delete state.
///
/// Timestamps are **UTC epoch milliseconds as integers**, never `DateTime`
/// columns. That is deliberate and permanent: an integer has one
/// representation, sorts correctly, cannot pick up a timezone, and cannot be
/// reinterpreted by a codegen option flipped in a cleanup PR.
mixin AuditColumns on Table {
  /// The row's stable identity, minted by the `IdGenerator` seam.
  TextColumn get id => text().withLength(min: 1, max: 64)();

  /// When the row was first written, as UTC epoch milliseconds.
  IntColumn get createdAtUtcMs => integer()();

  /// When the row was last written, as UTC epoch milliseconds.
  IntColumn get updatedAtUtcMs => integer()();

  /// Bumped by exactly one on every write, so a lost update is detectable.
  IntColumn get rowRevision => integer().withDefault(const Constant(1))();

  /// Whether the row is soft-deleted. `0` or `1`; STRICT has no BOOLEAN type,
  /// so the `CHECK` on the table is what makes this column boolean.
  IntColumn get isDeleted => integer().withDefault(const Constant(0))();

  /// When the row was soft-deleted, as UTC epoch milliseconds, or `NULL`.
  IntColumn get deletedAtUtcMs => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
