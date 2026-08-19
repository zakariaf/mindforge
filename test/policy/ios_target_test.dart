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
  final pbxproj =
      File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();

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
        reason: 'the template ships the \$(DEVELOPMENT_LANGUAGE) build-setting '
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
        reason: 'iOS reads CFBundleLocalizations to decide which languages the '
            'app is offered in. A locale absent from this array is unreachable '
            'no matter how complete app_fa.arb is, and nothing in Dart catches '
            'it',
      );

      final entries = RegExp('<string>([^<]*)</string>')
          .allMatches(array!.group(1)!)
          .map((m) => m.group(1)!)
          .toList();

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
        reason: 'a bundle identifier is permanent once the app is first '
            'uploaded; changing it afterwards creates a different app',
      );
    });

    test('the Podfile and its lock are committed and tracked', () {
      expect(File('ios/Podfile').existsSync(), isTrue);
      expect(File('ios/Podfile.lock').existsSync(), isTrue);

      final result =
          Process.runSync('git', ['check-ignore', '-v', 'ios/Podfile.lock']);
      expect(
        result.exitCode,
        isNot(0),
        reason: 'same rule and same reason as pubspec.lock — a fresh clone must '
            'resolve the native graph that was tested. git check-ignore said: '
            '${result.stdout}',
      );
    });

    test('the Podfile platform matches IPHONEOS_DEPLOYMENT_TARGET', () {
      final targets = RegExp(r'IPHONEOS_DEPLOYMENT_TARGET = ([0-9.]+);')
          .allMatches(pbxproj)
          .map((m) => m.group(1)!)
          .toSet();

      expect(
        targets,
        hasLength(1),
        reason: 'every build configuration must agree on one deployment target',
      );

      final podfilePlatform =
          RegExp(r"platform :ios, '([0-9.]+)'").firstMatch(
        File('ios/Podfile').readAsStringSync(),
      );

      expect(
        podfilePlatform?.group(1),
        targets.single,
        reason: 'the value itself is whatever flutter create generated and is '
            'pinned here so a later accidental change is a red test. Raising it '
            'is a product decision; lowering it is a bug',
      );
    });
  });
}
