import 'package:flutter/material.dart';

/// A tab screen: its coloured header, then its content.
///
/// **The header is a sliver, not a fixed row above a scroll view.** At rest it
/// looks the same — it sits at the top and the content scrolls under it — and
/// at a large text scale it is the difference between a screen that works and
/// one that overflows. Measured: Home's header in Sorani at text scale 2.0 is
/// 618 points tall on a 320x693 screen, which leaves the pane below it a
/// negative height. A fixed header cannot be told to be shorter without
/// clamping the text, and clamping the text is the one thing the a11y contract
/// forbids; a header that scrolls away simply keeps working.
///
/// This is also what iOS does with a large title, so it is the behaviour a
/// player already expects rather than a workaround wearing a comment.
class ShellPane extends StatelessWidget {
  /// Creates a pane under [header].
  const ShellPane({required this.header, required this.children, super.key});

  /// The coloured region at the top.
  final Widget header;

  /// The pane's content, in order.
  final List<Widget> children;

  /// The pane's gutter. `app.html`: `.pane{padding:20px}`.
  static const EdgeInsetsDirectional gutter = EdgeInsetsDirectional.fromSTEB(
    20,
    20,
    20,
    20,
  );

  @override
  Widget build(BuildContext context) => CustomScrollView(
    slivers: <Widget>[
      SliverToBoxAdapter(child: header),
      SliverPadding(
        padding: gutter,
        sliver: SliverList.list(children: children),
      ),
    ],
  );
}
