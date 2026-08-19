/// The base of every failure family in the app.
///
/// A `Failure` is a **value**, not a thrown thing: recoverable failures are
/// returned through `Result` (`lib/core/result.dart`) and switched exhaustively
/// at the call site. Only bugs throw.
///
/// A leaf carries typed parameters, never a localized sentence. The UI decides
/// what to say about `data.run_already_recorded`; the data layer only reports
/// that it happened, and to which key. A message baked in here would be a
/// string the ARB cannot translate and the log cannot parse.
abstract class Failure {
  /// Creates a failure. Leaves are `const`.
  const Failure();

  /// A stable, machine-readable identifier, namespaced by boundary —
  /// `data.not_found`, `run.already_over`.
  ///
  /// Stable means it appears in logs and in tests and does not change when the
  /// class is renamed. Frozen per family by a policy test.
  String get code;
}
