import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Installs a golden comparator that tolerates renderer noise and nothing else.
///
/// **Why a tolerance at all.** A golden blessed on a developer's Mac and
/// compared on a GitHub runner differs by a few pixels of anti-aliasing even
/// with identical Flutter, identical fonts and identical device pixel ratio.
/// Measured on this repository: `numerals-fa.png` came back **0.01%, 3px**.
/// The alternatives are worse — dropping the lane from CI leaves shaping
/// unguarded, and an `--update-goldens` step in CI is a gate that blesses its
/// own output, which `ci-pipeline-and-gates` rule 9 forbids and this pipeline
/// does not contain.
///
/// **Why this tolerance is not a blindfold.** The regressions these six files
/// exist to catch are two to three orders of magnitude larger than the noise.
/// Measured, by breaking each on purpose:
///
/// * `BidiText.isolate` neutered — **4.89%, 2373px**.
/// * a mirroring flip moves whole blocks across a 390pt canvas.
/// * a wrong digit block replaces every numeral in the specimen.
///
/// [_kTolerance] sits an order of magnitude above the observed noise and two
/// below the smallest real signal. A change that lands in between is one this
/// lane genuinely cannot judge, and the honest answer to that is the human
/// comparison against `design/sunburst-pop/screens/rtl/`.
void installTolerantGoldenComparator() {
  final existing = goldenFileComparator;
  if (existing is! LocalFileComparator) return;

  goldenFileComparator = _TolerantComparator(existing.basedir);
}

/// One tenth of one percent of the pixels.
const double _kTolerance = 0.1;

class _TolerantComparator extends LocalFileComparator {
  _TolerantComparator(Uri basedir) : super(Uri.parse('$basedir/x'));

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );

    if (result.passed || result.diffPercent * 100 <= _kTolerance) {
      result.dispose();
      return true;
    }

    final error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    // FlutterError is what every other golden comparator throws, and
    // flutter_test formats it as the failure body.
    throw FlutterError(error);
  }
}

/// Deletes the failure artefacts a previous run left behind.
///
/// `generateFailureOutput` writes into `test/**/failures/`, which is not
/// tracked; clearing it keeps a passing run from being read as a failing one.
void clearGoldenFailures(String directory) {
  final failures = Directory(directory);
  if (failures.existsSync()) failures.deleteSync(recursive: true);
}
