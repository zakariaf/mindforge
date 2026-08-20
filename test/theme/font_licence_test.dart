import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/theme/font_licences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'every bundled family reaches LicenseRegistry with its OFL text',
    () async {
      registerSunburstFontLicences();

      final entries = await LicenseRegistry.licenses.toList();

      for (final font in kBundledFonts) {
        final family = font.family;
        final entry = entries.where((e) => e.packages.contains(family));

        expect(
          entry,
          isNotEmpty,
          reason:
              'no LicenseRegistry entry names the package $family. A bundled '
              'font whose licence is unreachable is a licensing defect, not a '
              'cosmetic one',
        );

        final text = entry.first.paragraphs.map((p) => p.text).join('\n');
        expect(
          text,
          contains('SIL OPEN FONT LICENSE'),
          reason: "$family's registered text is not the OFL",
        );
      }
    },
  );
}
