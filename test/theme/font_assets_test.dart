import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/theme/font_licences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('font assets', () {
    for (final asset in kBundledFontAssets) {
      test('$asset is a real font file', () async {
        final data = await rootBundle.load(asset);

        expect(
          data.lengthInBytes,
          greaterThan(0),
          reason: 'the asset resolved but is empty',
        );

        // A length check alone would pass a Git-LFS pointer, an HTML 404 body
        // or a truncated download. The magic is what proves it is a font: a
        // 14-byte "404: Not Found" is exactly what one of these downloads
        // returned before the URL was corrected.
        final magic = data.buffer.asUint8List(data.offsetInBytes, 4);
        final isTrueType =
            magic[0] == 0x00 &&
            magic[1] == 0x01 &&
            magic[2] == 0x00 &&
            magic[3] == 0x00;
        final isOpenType = String.fromCharCodes(magic) == 'OTTO';

        expect(
          isTrueType || isOpenType,
          isTrue,
          reason:
              'first four bytes were $magic, which is neither the '
              'TrueType magic 00 01 00 00 nor the OpenType magic OTTO',
        );
      });
    }
  });
}
