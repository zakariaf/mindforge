import 'package:flutter/material.dart';

/// Two or three surfaces sharing a row, all the same height.
///
/// **`IntrinsicHeight`, not a stretched Row alone.** Inside a scroll view a
/// stretched Row has no height to stretch to and forces an infinite constraint;
/// with it, the boxes match even when one label wraps to a second line in
/// German and the other does not.
///
/// It exists because the stat duo on game detail, the totals duo on Stats and
/// the results trio were the same eight lines three times — and the gap between
/// them differs by design (12 for a duo, 10 for the trio), which is exactly the
/// kind of number that drifts when it is written out three times.
class EqualRow extends StatelessWidget {
  /// Creates a row of equal-width, equal-height [children].
  const EqualRow({required this.children, this.gap = 12, super.key});

  /// The cells, in reading order.
  final List<Widget> children;

  /// The space between cells.
  final double gap;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final (index, child) in children.indexed) ...<Widget>[
          if (index > 0) SizedBox(width: gap),
          Expanded(child: child),
        ],
      ],
    ),
  );
}
