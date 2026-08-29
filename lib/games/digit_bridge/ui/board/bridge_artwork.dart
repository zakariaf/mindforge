import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindforge/core/numeral_script.dart';
import 'package:mindforge/l10n/l10n_providers.dart';
import 'package:mindforge/theme/game_accent.dart';
import 'package:mindforge/theme/sunburst_colors.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/theme/sunburst_type.dart';

/// The 64pt tile on Digit Bridge's Home card.
///
/// The same number twice, in the two systems the game bridges: `47` above
/// `۴۷`, with the accent's deep half between them as the crossing. The value is
/// the design's own and is not generated — this is a picture of the game, not a
/// board, and a tile that redealt on every rebuild would be a moving target on
/// a list the player is scanning.
///
/// **PAINTED, not laid out, and that is the accessibility argument rather than
/// a performance one** — the argument `SchulteArtwork` records at length. A
/// digit in an 18pt cell cannot honour the OS text size: at 200% it is larger
/// than the cell that holds it. These digits are not text, they are the
/// contents of a picture, no more reflowable than the strokes of an icon, and
/// they are excluded from semantics for the same reason. The card's title and
/// tagline beside it are the text, and they scale.
///
/// **Both scripts are drawn regardless of locale, which is the one thing this
/// artwork does differently from every other numeral in the app.** A Persian
/// home screen shows Latin digits on this card on purpose: they are half the
/// subject. Every other surface, including this card's own title and BEST pill,
/// still renders the reader's own system.
class BridgeArtwork extends ConsumerWidget {
  /// Creates the tile.
  const BridgeArtwork({super.key});

  /// The number the card shows, in both systems.
  ///
  /// Two digits rather than the three a chill round deals: at 64pt a
  /// three-digit run in two rows is a smear, and the card's job is to say what
  /// the game IS, not to pose a solvable question.
  static const int value = 47;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colours = SunburstColors.of(context);
    final numbers = ref.watch(localeNumbersProvider);

    return ExcludeSemantics(
      child: AspectRatio(
        aspectRatio: 1,
        child: RepaintBoundary(
          child: CustomPaint(
            painter: BridgeArtworkPainter(
              BridgeArtworkScene(
                upper: numbers.digitsInScript(value, NumeralScript.latin),
                lower: numbers.digitsInScript(
                  value,
                  NumeralScript.easternArabic,
                ),
                style: SunburstType.of(context).miniTile,
                cellFill: colours.surfaceSunk,
                spanFill: colours.accentFor(
                  GameAccent.digitBridge,
                  GameColourRole.base,
                ),
                ink: colours.border,
                text: colours.textPrimary,
                radius: SunburstShape.of(context).miniTileRadius.x,
                borderWidth: SunburstShape.of(context).miniTileBorderWidth,
                gap: SunburstShape.of(context).miniTileGapValue,
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
class BridgeArtworkScene {
  /// Creates a scene.
  const BridgeArtworkScene({
    required this.upper,
    required this.lower,
    required this.style,
    required this.cellFill,
    required this.spanFill,
    required this.ink,
    required this.text,
    required this.radius,
    required this.borderWidth,
    required this.gap,
  });

  /// The already-rendered Latin numeral.
  final String upper;

  /// The already-rendered Eastern Arabic numeral.
  final String lower;

  /// The step the digits start from.
  final TextStyle style;

  /// The fill behind each numeral.
  final Color cellFill;

  /// The fill of the span between them.
  final Color spanFill;

  /// The 3px edge every raised surface carries.
  final Color ink;

  /// The digits' colour.
  final Color text;

  /// The corner radius of a cell.
  final double radius;

  /// The edge width.
  final double borderWidth;

  /// The space between the two cells, which the span occupies.
  final double gap;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BridgeArtworkScene &&
          other.upper == upper &&
          other.lower == lower &&
          other.style == style &&
          other.cellFill == cellFill &&
          other.spanFill == spanFill &&
          other.ink == ink &&
          other.text == text &&
          other.radius == radius &&
          other.borderWidth == borderWidth &&
          other.gap == gap;

  @override
  int get hashCode => Object.hash(
    upper,
    lower,
    style,
    cellFill,
    spanFill,
    ink,
    text,
    radius,
    borderWidth,
    gap,
  );
}

/// Draws [BridgeArtworkScene].
///
/// Dumb: it is handed one immutable value and compares it in [shouldRepaint].
/// Every `Paint` is built in the initializer list, so `paint()` allocates
/// nothing but the two `TextPainter`s it cannot avoid.
class BridgeArtworkPainter extends CustomPainter {
  /// Creates a painter for [scene].
  BridgeArtworkPainter(this.scene)
    : _cell = Paint()..color = scene.cellFill,
      _span = Paint()..color = scene.spanFill,
      _edge = Paint()
        ..color = scene.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = scene.borderWidth;

  /// What to draw.
  final BridgeArtworkScene scene;

  final Paint _cell;
  final Paint _span;
  final Paint _edge;

  @override
  void paint(Canvas canvas, Size size) {
    final cellHeight = (size.height - scene.gap) / 2;
    final inset = scene.borderWidth / 2;

    // THE SPAN FIRST, behind both cells, so the crossing reads as one piece of
    // structure the two banks sit on rather than as a line drawn between them.
    canvas.drawRect(
      Rect.fromLTWH(
        size.width / 3,
        cellHeight - scene.gap,
        size.width / 3,
        scene.gap * 3,
      ),
      _span,
    );

    _drawCell(canvas, Rect.fromLTWH(0, 0, size.width, cellHeight), inset);
    _drawCell(
      canvas,
      Rect.fromLTWH(0, cellHeight + scene.gap, size.width, cellHeight),
      inset,
    );

    _drawLabel(
      canvas,
      scene.upper,
      Rect.fromLTWH(0, 0, size.width, cellHeight),
    );
    _drawLabel(
      canvas,
      scene.lower,
      Rect.fromLTWH(0, cellHeight + scene.gap, size.width, cellHeight),
    );
  }

  void _drawCell(Canvas canvas, Rect rect, double inset) {
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(inset),
      Radius.circular(scene.radius),
    );

    canvas
      ..drawRRect(rrect, _cell)
      ..drawRRect(rrect, _edge);
  }

  void _drawLabel(Canvas canvas, String label, Rect rect) {
    // LTR, always. A numeral's most significant end is on the left in both
    // scripts, so the glyph run has its own coordinate space and does not
    // follow the page.
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: scene.style.copyWith(color: scene.text),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    painter
      ..paint(
        canvas,
        Offset(
          rect.left + (rect.width - painter.width) / 2,
          rect.top + (rect.height - painter.height) / 2,
        ),
      )
      ..dispose();
  }

  @override
  bool shouldRepaint(BridgeArtworkPainter oldDelegate) =>
      oldDelegate.scene != scene;
}
