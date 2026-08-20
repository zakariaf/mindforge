import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindforge/shared/feedback/feedback_gates.dart';

/// Folds the app's reduce-motion setting into `MediaQuery`.
///
/// **The only place `isReduceMotionEnabled` is read outside Settings itself.**
/// Every widget in the app asks `MediaQuery.disableAnimationsOf(context)`,
/// which by then carries both answers — so no component holds an opinion about
/// app state, and a screen cannot animate because it forgot to check.
///
/// It is an **OR, never an override**: a player who has switched motion off at
/// the OS level gets stillness whatever the app's own toggle says. Turning the
/// app's toggle off cannot re-enable animation.
///
/// It inserts a `MediaQuery` and nothing else. In particular it does not
/// introduce a `Directionality` — direction comes from the locale, and a scope
/// that quietly pinned one would make every RTL screen below it read
/// left-to-right.
class MotionPreferenceScope extends ConsumerWidget {
  /// Wraps [child] with the folded preference.
  const MotionPreferenceScope({required this.child, super.key});

  /// The subtree that reads the folded flag.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final existing = MediaQuery.of(context);

    return MediaQuery(
      // copyWith, never a bare MediaQueryData(): constructing one from scratch
      // drops the size, the text scaler, the padding and every accessibility
      // flag the app reads.
      data: existing.copyWith(
        disableAnimations:
            existing.disableAnimations ||
            ref.watch(reduceMotionEnabledProvider),
      ),
      child: child,
    );
  }
}
