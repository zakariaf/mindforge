import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// What MindForge asks the operating system for: nothing.
///
/// **This is the product, not a precaution.** The hard constraints say fully
/// offline, no accounts, no analytics, no crash reporting, on-device storage
/// only — and every one of those is a promise a single permission key would
/// break. A `NSUserTrackingUsageDescription` that nobody meant to add is a
/// prompt the player sees and a privacy label the store makes you answer.
///
/// Asserted against the REAL project files, not against a summary of them.
///
/// **Android is deferred, and that is stated here rather than implied by its
/// absence.** There is no `android/` target: E01-E11 ship iOS only, the
/// architecture is deliberately platform-neutral so an Android epic is
/// additive, and when it lands it brings its own manifest assertions —
/// `uses-permission`, `INTERNET` above all, which Flutter's own debug manifest
/// adds by default and which a release manifest must not carry.
void main() {
  final plist = File('ios/Runner/Info.plist').readAsStringSync();

  group('the iOS app requests no permission', () {
    test('no usage-description key of any kind', () {
      // A usage description IS the request: iOS shows the prompt because the
      // key exists. Matched by shape rather than by a list, so a key invented
      // after this test was written still fails it.
      final keys = RegExp(
        r'<key>(NS\w*UsageDescription)</key>',
      ).allMatches(plist).map((match) => match.group(1)).toList();

      expect(
        keys,
        isEmpty,
        reason:
            'a permission prompt contradicts every hard constraint in '
            'CLAUDE.md — offline, no accounts, no telemetry',
      );
    });

    test('and no background execution', () {
      // A background mode is how an app keeps running to do something the
      // player did not ask for. A brain-training game has no such something.
      expect(plist, isNot(contains('UIBackgroundModes')));
      expect(plist, isNot(contains('BGTaskSchedulerPermittedIdentifiers')));
    });

    test('and no entitlements file granting a capability', () {
      // An entitlements file is not required to exist. If one does, it must
      // grant nothing: push, iCloud, keychain sharing and app groups are all
      // ways data leaves the device or is shared off it.
      final entitlements = File('ios/Runner/Runner.entitlements');

      if (!entitlements.existsSync()) return;

      final granted = entitlements.readAsStringSync();

      for (final capability in <String>[
        'aps-environment',
        'com.apple.developer.icloud',
        'com.apple.security.application-groups',
        'keychain-access-groups',
        'com.apple.developer.healthkit',
      ]) {
        expect(granted, isNot(contains(capability)), reason: capability);
      }
    });
  });

  group('the export-compliance answer', () {
    test('is declared, so it is not asked on every upload', () {
      // MindForge performs no encryption — there is no network code for it to
      // encrypt. Declaring it removes the question from every future upload
      // rather than answering it by hand each time.
      expect(
        plist,
        contains('ITSAppUsesNonExemptEncryption'),
        reason: 'an undeclared app is asked the export question every upload',
      );

      final declared = RegExp(
        r'<key>ITSAppUsesNonExemptEncryption</key>\s*<(\w+)/>',
      ).firstMatch(plist)?.group(1);

      expect(declared, 'false');
    });
  });

  group('the bundle localization list', () {
    test('is exactly the four shipped locales, and develops in en', () {
      // The plist half of the pair `l10n_posture_test` asserts from the ARB
      // side. Both are asserted, because a fifth ARB that never reaches the
      // plist is a locale iOS will not offer.
      expect(
        RegExp(
          r'<key>CFBundleDevelopmentRegion</key>\s*<string>(\w+)</string>',
        ).firstMatch(plist)?.group(1),
        'en',
      );

      final block = RegExp(
        r'<key>CFBundleLocalizations</key>\s*<array>(.*?)</array>',
        dotAll: true,
      ).firstMatch(plist)?.group(1);

      expect(block, isNotNull, reason: 'CFBundleLocalizations is missing');
      expect(
        RegExp(
          r'<string>([\w-]+)</string>',
        ).allMatches(block!).map((match) => match.group(1)).toSet(),
        <String>{'en', 'de', 'fa', 'ckb'},
      );
    });
  });

  group('the privacy manifest', () {
    final manifest = File('ios/Runner/PrivacyInfo.xcprivacy');

    test('exists and declares no tracking and no collection', () {
      expect(manifest.existsSync(), isTrue);

      final declared = manifest.readAsStringSync();

      expect(
        RegExp(
          r'<key>NSPrivacyTracking</key>\s*<(\w+)/>',
        ).firstMatch(declared)?.group(1),
        'false',
      );

      for (final array in <String>[
        'NSPrivacyTrackingDomains',
        'NSPrivacyCollectedDataTypes',
        'NSPrivacyAccessedAPITypes',
      ]) {
        expect(
          RegExp('<key>$array</key>\\s*<array/>').hasMatch(declared),
          isTrue,
          reason: '$array is not the empty array this app can honestly claim',
        );
      }
    });

    test('and is in the target, not merely in the repository', () {
      // A MANIFEST THAT IS NOT IN THE BUNDLE IS NOT A MANIFEST. A file can sit
      // beside Info.plist for years without ever being added to the Runner
      // target, and nothing about the repository looks wrong — the build just
      // ships without it and App Review asks for one.
      final project = File(
        'ios/Runner.xcodeproj/project.pbxproj',
      ).readAsStringSync();

      expect(
        project,
        contains('PrivacyInfo.xcprivacy in Resources'),
        reason: 'add it to the Runner target Resources build phase',
      );
    });
  });
}
