import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// One bundled font family: the `family:` key in `pubspec.yaml`, the font asset
/// declared under it, and the SIL OFL text shipped alongside it.
typedef BundledFont = ({String family, String asset, String licenceAsset});

/// The font families bundled into the binary, in declaration order.
///
/// One record per family rather than three parallel lists: a face added to the
/// family list and forgotten in the asset list is the exact defect this file
/// exists to prevent, and parallel lists are how that happens.
///
/// **E03 T03.7 appends the Arabic-script faces here.** Fredoka and Nunito have
/// no Arabic-script coverage, so `fa` and `ckb` cannot render from this list
/// alone — that is a stated incompleteness, not a finished font story.
///
/// Two licence files rather than one: the families carry different copyright
/// holders, and a single `OFL.txt` would misattribute one of them.
const kBundledFonts = <BundledFont>[
  (
    family: 'Fredoka',
    asset: 'assets/fonts/Fredoka[wdth,wght].ttf',
    licenceAsset: 'assets/fonts/OFL-Fredoka.txt',
  ),
  (
    family: 'Nunito',
    asset: 'assets/fonts/Nunito[wght].ttf',
    licenceAsset: 'assets/fonts/OFL-Nunito.txt',
  ),
  // Arabic script, for fa and ckb. ONE family serving both the display and the
  // body role, at different weights — see kArabicDisplayWeight in
  // sunburst_type.dart for why Lalezar was refused.
  (
    family: 'Vazirmatn',
    asset: 'assets/fonts/Vazirmatn[wght].ttf',
    licenceAsset: 'assets/fonts/OFL-Vazirmatn.txt',
  ),
];

/// Registers the SIL OFL text of every bundled font family with
/// [LicenseRegistry], so the licences are reachable from the in-app licences
/// page rather than only from the repository.
///
/// Call once, from `bootstrap()`, before `runApp`. There is never a second
/// registration function: every face added later — including E03's
/// Arabic-script pair — is registered through this one.
void registerSunburstFontLicences() {
  LicenseRegistry.addLicense(() async* {
    for (final font in kBundledFonts) {
      yield LicenseEntryWithLineBreaks(
        <String>[font.family],
        await rootBundle.loadString(font.licenceAsset),
      );
    }
  });
}
