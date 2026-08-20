import 'package:mindforge/core/id_generator.dart';
import 'package:uuid/uuid.dart';

/// The live [IdGenerator], minting UUID v7.
///
/// v7 rather than v4: it is time-ordered, so ids sort in insertion order and an
/// index over them stays dense instead of scattering every insert across the
/// B-tree.
final class UuidIdGenerator implements IdGenerator {
  /// Creates the generator.
  const UuidIdGenerator();

  static const Uuid _uuid = Uuid();

  @override
  String newId() => _uuid.v7();
}
