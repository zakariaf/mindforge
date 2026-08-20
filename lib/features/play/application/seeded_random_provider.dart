import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindforge/core/seeded_generator.dart';
import 'package:mindforge/data/data_providers.dart';

/// Draws the entropy one run starts from.
///
/// A typedef rather than a class: there is one operation and no state, and a
/// test overrides it with `() => 42` instead of building a fake.
typedef RunSeedDraw = int Function();

/// The one place a run's entropy is read.
///
/// The generator itself never touches a clock — it is a pure function of a seed
/// — so the reading of "now" happens here, once, through the injected
/// `clockProvider`. That is what lets a test fix an instant and get a
/// reproducible round, and what stops eight call sites each reading the wall
/// clock directly.
///
/// **`toUtc().toIso8601String()` is ASCII Gregorian by construction and reads
/// no ambient locale.** That matters more than it looks: it is the line a
/// well-meaning move toward "localized timestamps" would change, and the moment
/// it produces a Jalali date or Eastern Arabic digits, `seedFrom`'s ASCII
/// assert fires — which is the failure being loud instead of a Persian player
/// silently getting a different game.
final Provider<RunSeedDraw> seededRandomProvider = Provider<RunSeedDraw>((ref) {
  final clock = ref.watch(clockProvider);

  return () => fnv1a64(clock.now().toUtc().toIso8601String());
});
