/// The four taps the app is allowed to ask the device for.
///
/// **There is no `vibrate` value**, deliberately: it is a long buzz with no
/// place in a game whose feedback is meant to feel like something small and
/// physical, and a verb that does not exist cannot be reached by accident.
enum HapticVerb {
  /// The lightest — a tick. For choosing among things.
  selectionClick,

  /// A small knock. For a thing landing.
  lightImpact,

  /// A firmer knock. For a boundary being crossed.
  mediumImpact,

  /// The heaviest, and the app spends it **once**.
  ///
  /// Reserved for a new personal best. A heavy impact that fires often stops
  /// meaning anything, and the catalog test asserts exactly one moment uses it.
  heavyImpact,
}
