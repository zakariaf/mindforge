import 'package:meta/meta.dart';

/// A game's stable identifier.
///
/// **ASCII lower snake case, enforced at construction.** This value is a route
/// segment, a primary key in the `runs` table, a golden-vector filename
/// fragment and a `RunScope` component. Every one of those is a place localized
/// text is unrepresentable: a Persian id cannot be typed into a URL, cannot be
/// grepped for in a bug report, and is invisible in a diff.
///
/// A wrapper rather than a bare `String` so a `GameId` and a `Difficulty` name
/// cannot be swapped at a call site — they are both lower snake case, so the
/// compiler is the only thing that can tell them apart.
@immutable
final class GameId {
  /// Creates an id from [value], which must be ASCII lower snake case.
  ///
  /// **Not `const`, deliberately.** A const constructor can only assert over
  /// const-evaluable expressions, and a regex match is not one — so a const
  /// `GameId` would be a `GameId` that skipped its only reason for existing.
  /// Validation is worth more here than a compile-time literal: there are two
  /// ids in the whole app and both are written once, in the registry.
  GameId(this.value)
    : assert(value.isNotEmpty, 'a game id cannot be empty'),
      assert(
        _pattern.hasMatch(value),
        'a game id is ASCII lower snake case: stroop_rush, not StroopRush, '
        'stroop-rush or a translated word. It is a route segment, a database '
        'key and a filename fragment.',
      );

  /// The token itself.
  final String value;

  /// Lower snake case, ASCII only, no leading or trailing underscore.
  ///
  /// The character class is spelled out rather than using `\w`, which in Dart
  /// matches only ASCII but reads as though it might not.
  static final RegExp _pattern = RegExp(r'^[a-z][a-z0-9]*(_[a-z0-9]+)*$');

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is GameId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  /// The token, so a log line or a test failure is greppable.
  @override
  String toString() => value;
}
