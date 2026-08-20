/// Where a new row's identity comes from.
///
/// A seam, not a utility: a random id makes every repository assertion
/// unwritable, so a test substitutes a counting fake. That is the named thing
/// this interface buys.
abstract interface class IdGenerator {
  /// A fresh, unique identifier.
  String newId();
}
