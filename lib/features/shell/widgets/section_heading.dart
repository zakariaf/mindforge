import 'package:flutter/material.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_type.dart';

/// A section's name, with its count or subtitle at the end edge.
///
/// `app.html`'s `.seclab`: baseline-aligned, the heading at the start and the
/// trailing value at the end. Not a title with a caption stacked under it — the
/// count belongs BESIDE the thing it counts.
///
/// **The heading gives way when they do not fit, never the trailing value.**
/// "Deine Spiele" and "2 freigeschaltet" together are wider than a 350pt pane,
/// and of the two a truncated count is worse: it would state the wrong number.
class SectionHeading extends StatelessWidget {
  /// Creates a heading.
  const SectionHeading({required this.title, this.trailing, super.key});

  /// The already-localized section name.
  final String title;

  /// The already-localized count or subtitle, if any.
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final colours = SunburstColors.of(context);
    final type = SunburstType.of(context);
    final trailing = this.trailing;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            style: type.sectionTitle.copyWith(color: colours.textPrimary),
          ),
        ),
        if (trailing != null) ...<Widget>[
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              trailing,
              textAlign: TextAlign.end,
              style: type.sectionCount.copyWith(color: colours.textSecondary),
            ),
          ),
        ],
      ],
    );
  }
}
