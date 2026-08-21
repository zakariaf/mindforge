import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/games/schulte_grid/domain/schulte_rules.dart';
import 'package:mindforge/games/schulte_grid/ui/schulte_grid_metrics.dart';
import 'package:mindforge/theme/sunburst_shape.dart';
import 'package:mindforge/ui/components/pop_surface.dart';

/// How big a cell is. Locale-invariant: derived from the slot, not a glyph.
void main() {
  group('the cell table', () {
    const cases = <({double side, int columns, double gap, double cell})>[
      (side: 280, columns: 5, gap: 8, cell: 49.6),
      (side: 320, columns: 5, gap: 12, cell: 54.4),
      (side: 335, columns: 5, gap: 12, cell: 57.4),
      (side: 350, columns: 5, gap: 12, cell: 60.4),
      (side: 390, columns: 5, gap: 12, cell: 68.4),
      (side: 280, columns: 4, gap: 12, cell: 61.0),
      (side: 280, columns: 6, gap: 8, cell: 40.0),
      (side: 335, columns: 6, gap: 8, cell: 49.17),
    ];

    for (final row in cases) {
      test('${row.side} at ${row.columns} columns is ${row.cell}', () {
        expect(schulteGap(row.side, row.columns), row.gap);
        expect(
          schulteCell(row.side, row.columns, row.gap),
          closeTo(row.cell, 0.01),
        );
      });
    }
  });

  group('the gap step', () {
    test('is derived from the tap floor, not from a width', () {
      // 12 wherever 12 still leaves a 48pt cell, 8 otherwise — and never a
      // third value tuned to one device. Swept rather than sampled.
      for (var side = 240.0; side <= 440.0; side += 1) {
        for (final columns in <int>[4, 5, 6]) {
          final gap = schulteGap(side, columns);
          final roomy = schulteCell(side, columns, SunburstShape.space3);

          expect(
            gap,
            roomy >= kPopMinTarget
                ? SunburstShape.space3
                : SunburstShape.space2,
            reason: 'side $side at $columns columns',
          );
        }
      }
    });

    test('and never invents a value outside the two the design has', () {
      for (var side = 240.0; side <= 440.0; side += 1) {
        expect(
          schulteGap(side, 5),
          anyOf(SunburstShape.space2, SunburstShape.space3),
        );
      }
    });
  });

  group('the shipping sizes', () {
    test('clear the tap floor on the canonical simulator', () {
      // 390pt device, 20pt gutters: 350 of board.
      for (final difficulty in schulteDifficulties) {
        final columns = SchulteRules.forDifficulty(difficulty).gridSize;

        expect(
          schulteCell(350, columns, schulteGap(350, columns)),
          greaterThanOrEqualTo(kPopMinTarget),
          reason: '$difficulty',
        );
      }
    });
  });
}
