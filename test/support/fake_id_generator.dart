import 'package:mindforge/core/id_generator.dart';

/// A counting [IdGenerator], so every assertion in the data suite can name the
/// id it expects.
///
/// A bare `implements` fake rather than a mock: there is nothing to stub and no
/// call-order protocol to verify.
final class FakeIdGenerator implements IdGenerator {
  /// Creates a generator producing `run-1`, `run-2`, ... from [prefix].
  FakeIdGenerator({this.prefix = 'run-'});

  /// What every id starts with.
  final String prefix;

  int _next = 0;

  /// How many ids have been minted.
  int get mintedCount => _next;

  @override
  String newId() => '$prefix${++_next}';
}
