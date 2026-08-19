import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The four locales MindForge ships, in the one order every surface repeats.
///
/// `test/policy/l10n_posture_test.dart` asserts the same list against the ARB
/// directory and ADR 0001, so the plist, the decision record and `lib/l10n/`
/// cannot drift apart.
const kSupportedLocaleCodes = <String>['en', 'de', 'fa', 'ckb'];

void main() {
  final plist = File('ios/Runner/Info.plist').readAsStringSync();
  final pbxproj = File(
    'ios/Runner.xcodeproj/project.pbxproj',
  ).readAsStringSync();

  String? plistStringValue(String key) {
    final match = RegExp(
      '<key>${RegExp.escape(key)}</key>\\s*<string>([^<]*)</string>',
    ).firstMatch(plist);
    return match?.group(1);
  }

  group('iOS target', () {
    test('CFBundleDevelopmentRegion is the literal en', () {
      expect(
        plistStringValue('CFBundleDevelopmentRegion'),
        'en',
        reason:
            'the template ships the \$(DEVELOPMENT_LANGUAGE) build-setting '
            'indirection. The literal wins because a build setting is a second '
            'place the answer can live, and a policy test that has to resolve '
            'project.pbxproj to read a plist value is a test nobody trusts',
      );
    });

    test('CFBundleLocalizations lists exactly en, de, fa, ckb in order', () {
      final array = RegExp(
        r'<key>CFBundleLocalizations</key>\s*<array>(.*?)</array>',
        dotAll: true,
      ).firstMatch(plist);

      expect(
        array,
        isNotNull,
        reason:
            'iOS reads CFBundleLocalizations to decide which languages the '
            'app is offered in. A locale absent from this array is unreachable '
            'no matter how complete app_fa.arb is, and nothing in Dart catches '
            'it',
      );

      final entries = RegExp(
        '<string>([^<]*)</string>',
      ).allMatches(array!.group(1)!).map((m) => m.group(1)!).toList();

      expect(entries, kSupportedLocaleCodes);
    });

    test('the bundle identifier is com.mindforge.mindforge', () {
      final ids = RegExp(r'PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);')
          .allMatches(pbxproj)
          .map((m) => m.group(1)!.trim())
          .where((id) => !id.endsWith('.RunnerTests'))
          .toSet();

      expect(
        ids,
        {'com.mindforge.mindforge'},
        reason:
            'a bundle identifier is permanent once the app is first '
            'uploaded; changing it afterwards creates a different app',
      );
    });

    test('the native integration is SwiftPM, with no CocoaPods layer', () {
      // Measured on Flutter 3.44.6 (2026-08-19): Swift Package Manager is the
      // default iOS plugin integration path, so `flutter build ios` generates
      // ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage and
      // never writes an ios/Podfile. The epic plan assumed CocoaPods and a
      // committed Podfile.lock; that assumption is false on this toolchain.
      //
      // Nothing is lost. The generated package declares only path-local
      // dependencies — into the pub cache and the Flutter framework — so there
      // is no remote graph to resolve and no Package.resolved to commit. The
      // native versions are already pinned, by pubspec.lock, which IS committed.
      // Forcing --no-enable-swift-package-manager back on would add a Podfile
      // treadmill and a second lock file for zero additional pinning.
      expect(
        File('ios/Podfile').existsSync(),
        isFalse,
        reason:
            'a Podfile appearing here means the SwiftPM default changed or '
            'a plugin requiring CocoaPods was added. Either is a real decision: '
            'commit ios/Podfile.lock and replace this test',
      );

      expect(
        File(
          'ios/Flutter/ephemeral/Packages/'
          'FlutterGeneratedPluginSwiftPackage/Package.swift',
        ).existsSync(),
        isTrue,
        reason:
            'run `flutter build ios --no-codesign` once to materialise the '
            'generated plugin package',
      );

      final ignored = Process.runSync(
        'git',
        ['check-ignore', '-q', 'ios/Flutter/ephemeral'],
      );
      expect(
        ignored.exitCode,
        0,
        reason:
            'the generated package is build output and must stay '
            'gitignored; ios/.gitignore already lists Flutter/ephemeral/',
      );
    });

    test('every build configuration agrees on one deployment target', () {
      final targets = RegExp(
        r'IPHONEOS_DEPLOYMENT_TARGET = ([0-9.]+);',
      ).allMatches(pbxproj).map((m) => m.group(1)!).toSet();

      expect(
        targets,
        {'13.0'},
        reason:
            'the value is whatever flutter create generated on Flutter '
            '3.44.6 and is pinned here so a later accidental change is a red '
            'test. Raising it is a product decision; lowering it is a bug',
      );
    });
  });
}
