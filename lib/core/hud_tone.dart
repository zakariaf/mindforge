/// The tone a HUD value carries, so the shell can style it without knowing what
/// the value means.
///
/// Payload-free and Flutter-free, and it lives in `lib/core/` rather than in
/// `lib/ui/` because **both** sides need it and neither may import the other:
/// E05's `HudPill` renders it, E07's `GameHud`/`HudSlot` carries it, `lib/ui/`
/// may not import `lib/features/`, and E07 depends on E02 but not on E05.
/// `lib/core/` is the one layer both reach.
enum HudTone {
  /// The ordinary state. No emphasis.
  neutral,

  /// Something good just happened — a combo, a new best in progress.
  highlight,

  /// Something is running out. Time, lives, remaining answers.
  ///
  /// Wired to the alarm **primitive**, never to a gameplay colour slot: the
  /// colour-blind setting re-points answer slots, and an alarm aliased to one
  /// would change hue for exactly the players who need it most
  /// (`CLAUDE.md` working agreement 3).
  alarm,
}
