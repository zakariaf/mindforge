import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The font families bundled into the binary, in declaration order.
///
/// Each name is the `family:` key in `pubspec.yaml` and the package name the
/// family's licence is registered under. **E03 T03.7 appends the Arabic-script
/// faces here**; Fredoka and Nunito have no Arabic-script coverage, so `fa` and
/// `ckb` cannot render from this list alone.
const kBundledFontFamilies = <String>['Fredoka', 'Nunito'];

/// The font asset paths declared under `flutter: fonts:` in `pubspec.yaml`.
///
/// Kept beside [kBundledFontFamilies] so a face added to one and forgotten in
/// the other is a failing test rather than a missing glyph on a device nobody
/// checked.
const kBundledFontAssets = <String>[
  'assets/fonts/Fredoka[wdth,wght].ttf',
  'assets/fonts/Nunito[wght].ttf',
];

/// The SIL OFL text shipped for each bundled family.
///
/// Two files rather than one: the families carry different copyright holders,
/// and a single `OFL.txt` would misattribute one of them.
const _licenceAssetByFamily = <String, String>{
  'Fredoka': 'assets/fonts/OFL-Fredoka.txt',
  'Nunito': 'assets/fonts/OFL-Nunito.txt',
};

/// Registers the SIL OFL text of every bundled font family with
/// [LicenseRegistry], so the licences are reachable from the in-app licences
/// page rather than only from the repository.
///
/// Call once, from `bootstrap()`, before `runApp`. There is never a second
/// registration function: every face added later — including E03's
/// Arabic-script pair — is registered through this one.
void registerSunburstFontLicences() {
  LicenseRegistry.addLicense(() async* {
    for (final family in kBundledFontFamilies) {
      final asset = _licenceAssetByFamily[family];
      if (asset == null) continue;

      final text = await rootBundle.loadString(asset);
      yield LicenseEntryWithLineBreaks(<String>[family], text);
    }
  });
}
