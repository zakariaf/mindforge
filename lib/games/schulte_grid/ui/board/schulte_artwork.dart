import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindforge/l10n/l10n_providers.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/theme/sunburst_type.dart';

/// The 64pt tile on Schulte Grid's Home card.
///
/// `app.html`: `.gart .mini` — a 3x3 of tiny cells reading `7 1 4 / 9 2 6 /
/// 3 8 5`, with two of them filled turquoise. The scramble is the design's own
/// and is not generated: this is a picture of the game, not a board, and a tile
/// that reshuffled on every rebuild would be a moving target on a list the
/// player is scanning.
///
/// **PAINTED, not laid out, and that is the accessibility argument rather than
/// a performance one.** A digit in an 18pt cell cannot honour the OS text size:
/// at 200% it is larger than the cell that holds it. The rule
/// `check-test-hygiene.sh` enforces is *fix the layout, do not clamp the text*,
/// and the honest reading here is that these digits are not text — they are the
/// contents of a picture, no more reflowable than the strokes of an icon, and
/// they are excluded from semantics for the same reason. The card's title and
/// tagline beside it are the text, and they scale.
///
/// Its digits are still LOCALIZED. They are the only numerals a player meets
/// before starting anything, and a Persian Home screen with Latin digits on one
/// card looks like the card was missed in translation.
class SchulteArtwork extends ConsumerWidget {
  /// Creates the tile.
  const SchulteArtwork({super.key});

  /// The values the design draws, in reading order.
  static const List<int> values = <int>[7, 1, 4, 9, 2, 6, 3, 8, 5];

  /// Which of them are filled. `app.html`: `.mini i.on`.
  static const Set<int> filled = <int>{1, 6};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colours = SunburstColors.of(context);
    final shape = SunburstShape.of(context);
    final numbers = ref.watch(localeNumbersProvider);

    return ExcludeSemantics(
      child: AspectRatio(
        aspectRatio: 1,
        child: RepaintBoundary(
          child: CustomPaint(
            painter: SchulteArtworkPainter(
              SchulteArtworkScene(
                labels: <String>[
                  for (final value in values) numbers.count(value),
                ],
                filled: <bool>[
                  for (final value in values) filled.contains(value),
                ],
                textDirection: Directionality.of(context),
                style: SunburstType.of(context).miniTile,
                cellFill: colours.surface,
                onFill: colours.accentCool,
                ink: colours.border,
                idleText: colours.textSecondary,
                onText: colours.textPrimary,
                gap: shape.miniTileGapValue,
                radius: shape.miniTileRadius.x,
                borderWidth: shape.miniTileBorderWidth,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Everything the tile needs, resolved before `paint()` runs.
@immutable
class SchulteArtworkScene {
  /// Creates a scene.
  const SchulteArtworkScene({
    required this.labels,
    required this.filled,
    required this.textDirection,
    required this.style,
    required this.cellFill,
    required this.onFill,
    required this.ink,
    required this.idleText,
    required this.onText,
    required this.gap,
    required this.radius,
    required this.borderWidth,
  });

  /// Nine already-localized digits, in reading order.
  final List<String> labels;

  /// Which of them are drawn filled.
  final List<bool> filled;

  /// The direction the digits lay out in.
  final TextDirection textDirection;

  /// The step the digits start from.
  final TextStyle style;

  /// An unfilled cell's fill.
  final Color cellFill;

  /// A filled cell's fill.
  final Color onFill;

  /// The edge on every cell.
  final Color ink;

  /// A digit on an unfilled cell.
  final Color idleText;

  /// A digit on a filled cell.
  final Color onText;

  /// The space between cells.
  final double gap;

  /// A cell's corner.
  final double radius;

  /// A cell's edge.
  final double borderWidth;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SchulteArtworkScene &&
          other.textDirection == textDirection &&
          other.style == style &&
          other.cellFill == cellFill &&
          other.onFill == onFill &&
          other.ink == ink &&
          other.idleText == idleText &&
          other.onText == onText &&
          other.gap == gap &&
          other.radius == radius &&
          other.borderWidth == borderWidth &&
          _sameLabels(other.labels, labels);

  @override
  int get hashCode => Object.hash(
    Object.hashAll(labels),
    textDirection,
    style,
    cellFill,
    onFill,
    ink,
    idleText,
    onText,
    gap,
    radius,
    borderWidth,
  );

  static bool _sameLabels(List<String> a, List<String> b) {
    if (a.length != b.length) return false;

    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }

    return true;
  }
}

/// Draws the mini grid.
class SchulteArtworkPainter extends CustomPainter {
  /// Creates a painter for [scene].
  SchulteArtworkPainter(this.scene)
    : _cell = Paint()..color = scene.cellFill,
      _on = Paint()..color = scene.onFill,
      _edge = Paint()
        ..color = scene.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = scene.borderWidth;

  /// What to paint.
  final SchulteArtworkScene scene;

  final Paint _cell;
  final Paint _on;
  final Paint _edge;

  @override
  void paint(Canvas canvas, Size size) {
    final side = (size.width - scene.gap * 2) / 3;

    for (var index = 0; index < scene.labels.length; index++) {
      final rect = Rect.fromLTWH(
        (index % 3) * (side + scene.gap),
        (index ~/ 3) * (side + scene.gap),
        side,
        side,
      );
      final rounded = RRect.fromRectAndRadius(
        rect.deflate(scene.borderWidth / 2),
        Radius.circular(scene.radius),
      );

      canvas
        ..drawRRect(rounded, scene.filled[index] ? _on : _cell)
        ..drawRRect(rounded, _edge);

      // SIZED TO THE CELL, not to the OS text size. See the note on the widget:
      // this is the content of a picture, and it is excluded from semantics.
      final painter = TextPainter(
        text: TextSpan(
          text: scene.labels[index],
          style: scene.style.copyWith(
            color: scene.filled[index] ? scene.onText : scene.idleText,
            fontSize: side * 0.56,
          ),
        ),
        textDirection: scene.textDirection,
        textAlign: TextAlign.center,
      )..layout();

      painter
        ..paint(
          canvas,
          Offset(
            rect.center.dx - painter.width / 2,
            rect.center.dy - painter.height / 2,
          ),
        )
        ..dispose();
    }
  }

  @override
  bool shouldRepaint(SchulteArtworkPainter oldDelegate) =>
      oldDelegate.scene != scene;
}
