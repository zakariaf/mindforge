import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/l10n/app_localizations.dart';

/// Pins the posture recorded in `docs/decisions/0001-localisation.md`, so
/// re-opening the decision reds this test rather than drifting half-adopted.
void main() {
  final l10nYaml = File('l10n.yaml').readAsStringSync();

  /// `l10n.yaml` with its `#` comments removed. The absence assertions below
  /// are about the declared options; the file explains in prose why each
  /// omitted option is omitted, and a gate that fires on its own rationale
  /// gets deleted rather than obeyed.
  final l10nOptions = l10nYaml
      .split('\n')
      .map((line) => line.replaceFirst(RegExp('#.*'), ''))
      .join('\n');
  final pubspec = File('pubspec.yaml').readAsStringSync();

  group('l10n.yaml', () {
    const required = <String, String>{
      'arb-dir': 'lib/l10n',
      'template-arb-file': 'app_en.arb',
      'output-dir': 'lib/l10n',
      'output-localization-file': 'app_localizations.dart',
      'output-class': 'AppLocalizations',
      'nullable-getter': 'false',
      'required-resource-attributes': 'true',
      'format': 'true',
    };

    for (final entry in required.entries) {
      test('declares ${entry.key}: ${entry.value}', () {
        expect(
          RegExp(
            '^${entry.key}:\\s*${entry.value}\\s*\$',
            multiLine: true,
          ).hasMatch(l10nYaml),
          isTrue,
          reason:
              'ADR 0001. nullable-getter: false in particular is '
              'load-bearing: it turns a missing key into a compile error, '
              'which is a stronger guarantee than any grep over hardcoded '
              'literals',
        );
      });
    }

    test('synthetic-package appears nowhere', () {
      expect(
        l10nOptions.contains('synthetic-package'),
        isFalse,
        reason:
            'measured on Flutter 3.44.6: `flutter gen-l10n --help` prints '
            '"DEPRECATED. This flag cannot be enabled and should be removed." '
            'output-dir: lib/l10n is what keeps the generated class real, '
            'greppable source instead of hiding it in .dart_tool/',
      );
    });

    test('suppress-warnings appears nowhere', () {
      expect(
        l10nOptions.contains('suppress-warnings'),
        isFalse,
        reason:
            'the untranslated-message warning is the signal E04 depends on '
            'to know which of three locales is incomplete',
      );
    });
  });

  group('pubspec', () {
    test('generate: true is set under flutter:', () {
      expect(
        RegExp(
          r'^\s{2}generate:\s*true\s*$',
          multiLine: true,
        ).hasMatch(pubspec),
        isTrue,
      );
    });

    test('flutter_localizations and intl are both declared', () {
      expect(pubspec, contains('flutter_localizations:'));
      expect(RegExp(r'^\s{2}intl:', multiLine: true).hasMatch(pubspec), isTrue);
    });
  });

  group('the template ARB', () {
    final arb =
        jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
            as Map<String, dynamic>;

    test('declares @@locale: en', () {
      expect(arb['@@locale'], 'en');
    });

    test('every message key is lowerCamelCase', () {
      final bad = arb.keys
          .where((k) => !k.startsWith('@'))
          .where((k) => !RegExp(r'^[a-z][a-zA-Z0-9_]*$').hasMatch(k))
          .toList();

      expect(bad, isEmpty, reason: 'not lowerCamelCase: $bad');
    });

    test('every message key has a non-empty @key description', () {
      final missing = <String>[];
      for (final key in arb.keys.where((k) => !k.startsWith('@'))) {
        final meta = arb['@$key'];
        if (meta is! Map<String, dynamic>) {
          missing.add('$key (no @$key object)');
          continue;
        }
        final description = meta['description'];
        if (description is! String || description.trim().isEmpty) {
          missing.add('$key (empty description)');
        }
      }

      expect(
        missing,
        isEmpty,
        reason:
            'required-resource-attributes: true enforces this at '
            'generation time; this test enforces it at review time. A '
            'translator working into Sorani cannot guess context: $missing',
      );
    });
  });

  group('the supported-locale set', () {
    test('is exactly en, de, fa, ckb and matches CFBundleLocalizations', () {
      // The one constant, asserted from two directions, so the plist, the ADR
      // and lib/l10n/ cannot drift apart. The literal is repeated here rather
      // than imported from the iOS test because a shared helper that both
      // import would let one edit move both assertions at once.
      const expected = <String>['en', 'de', 'fa', 'ckb'];

      final plistArray = RegExp(
        r'<key>CFBundleLocalizations</key>\s*<array>(.*?)</array>',
        dotAll: true,
      ).firstMatch(File('ios/Runner/Info.plist').readAsStringSync())!;

      expect(
        RegExp(
          '<string>([^<]*)</string>',
        ).allMatches(plistArray.group(1)!).map((m) => m.group(1)).toList(),
        expected,
      );

      expect(
        AppLocalizations.supportedLocales
            .map((l) => l.toLanguageTag())
            .toList(),
        // E01 ships the template alone; E04 lands the other three ARBs and
        // this expectation grows to the full set in the same PR.
        ['en'],
        reason:
            'gen-l10n derives supportedLocales from the ARB files present. '
            'When E04 adds app_de.arb, app_fa.arb and app_ckb.arb this becomes '
            'the full four and the CFBundleLocalizations claim stops being '
            'ahead of the implementation',
      );
    });
  });

  group('the delegates are wired', () {
    final app = File('lib/app.dart').readAsStringSync();

    test('MindForgeApp names both AppLocalizations statics', () {
      expect(app, contains('AppLocalizations.localizationsDelegates'));
      expect(app, contains('AppLocalizations.supportedLocales'));
    });
  });
}
