import 'package:flutter/widgets.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/theme/sunburst_type.dart';

/// The panel that rises from the bottom edge.
///
/// Its corners are **top versus bottom**, which has no handedness: the `en` and
/// `fa` renderings differ only in their text. Its actions stack vertically, so
/// their order does not mirror either — and a test asserts that in both
/// directions, so nobody later "fixes" a thing that was never broken.
///
/// The title takes `type.title` and the body `type.body`. The mockup's 23 and
/// 14 sit between scale steps and are deliberately not reproduced: a one-off
/// size is a token nobody can reuse.
class PopSheet extends StatelessWidget {
  /// Creates a sheet titled [title].
  const PopSheet({
    required this.title,
    required this.actions,
    this.body,
    super.key,
  });

  /// The already-localized title.
  final String title;

  /// The already-localized body copy, if any.
  final String? body;

  /// The actions, primary first, stacked full width.
  final List<Widget> actions;

  /// The grab handle's size.
  static const Size _handle = Size(56, 6);

  @override
  Widget build(BuildContext context) {
    final colours = SunburstColors.of(context);
    final shape = SunburstShape.of(context);
    final type = SunburstType.of(context);
    final copy = body;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colours.surface,
        borderRadius: BorderRadiusDirectional.only(
          topStart: shape.radiusXl,
          topEnd: shape.radiusXl,
          bottomStart: shape.radiusMd,
          bottomEnd: shape.radiusMd,
        ).resolve(Directionality.of(context)),
        border: Border.all(color: colours.border, width: shape.borderWidth),
        boxShadow: shape.shadow(shape.e3, colours.border),
      ),
      // SafeArea at the bottom: on the canonical iPhone 14 the last action
      // would otherwise sit under the 34pt home indicator, where it is both
      // hard to hit and partly hidden.
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.all(SunburstShape.space5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: _handle.width,
                  height: _handle.height,
                  decoration: BoxDecoration(
                    color: colours.border,
                    borderRadius: BorderRadius.all(shape.radiusPill),
                  ),
                ),
              ),
              const SizedBox(height: SunburstShape.space4),
              Text(
                title,
                style: type.title.copyWith(color: colours.textPrimary),
                textAlign: TextAlign.start,
              ),
              if (copy != null) ...[
                const SizedBox(height: SunburstShape.space2),
                Text(
                  copy,
                  style: type.body.copyWith(color: colours.textSecondary),
                  textAlign: TextAlign.start,
                ),
              ],
              const SizedBox(height: SunburstShape.space5),
              // THE ACTIONS SCROLL, the sheet does not grow. A modal bottom
              // sheet is given a bounded height, and the language chooser's
              // five options plus a title exceed it — in `fa` the last row was
              // cut off under an overflow stripe, which is the one language a
              // Sorani reader is looking for. `Flexible` keeps a two-action
              // sheet exactly as tall as its content, so the pause sheet is
              // unchanged; only a sheet that would not fit starts scrolling.
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      // Indexed, not `action != actions.last`: that compares by
                      // identity, so reusing one const action instance twice in
                      // a list silently drops the gap before the repeat.
                      for (var i = 0; i < actions.length; i++) ...<Widget>[
                        actions[i],
                        if (i < actions.length - 1)
                          const SizedBox(height: SunburstShape.space3),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
