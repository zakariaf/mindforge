import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/supported_locale.dart';
import 'package:mindforge/l10n/app_localizations.dart';
import 'package:mindforge/l10n/supported_locales.dart';

import 'support/source_text.dart';

/// Pins the posture recorded in `docs/decisions/0001-localisation.md`, so
/// re-opening the decision reds this test rather than drifting half-adopted.
void main() {
  final l10nYaml = File('l10n.yaml').readAsStringSync();

  /// `l10n.yaml` with its `#` comments removed. The absence assertions below
  /// are about the declared options; the file explains in prose why each
  /// omitted option is omitted, and a gate that fires on its own rationale
  /// gets deleted rather than obeyed.
  final l10nOptions = withoutYamlComments(l10nYaml);
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
        supportedLocales.map((l) => l.languageCode).toList(),
        expected,
        reason:
            'the list MaterialApp is handed must be en-first, because '
            'Flutter falls back to supportedLocales.first',
      );

      expect(
        AppLocalizations.supportedLocales.map((l) => l.languageCode).toList()
          ..sort(),
        [...expected]..sort(),
        reason:
            'gen-l10n derives its own list from the ARB FILENAMES, so the '
            'two must hold the same SET even though they differ in order. '
            'Without this a fifth ARB or a dropped enum case would give the '
            'app two different answers to "which locales ship"',
      );

      expect(
        AppLocalizations.supportedLocales.first.languageCode,
        'ckb',
        reason:
            'measured: gen-l10n emits ALPHABETICAL order. This assertion '
            'exists so that if it ever becomes en-first, someone re-reads why '
            'lib/l10n/supported_locales.dart exists at all rather than '
            'deleting it',
      );
    });
  });

  group('the shipped locale set has exactly one source', () {
    test('lib/l10n/supported_locales.dart is a projection of the enum', () {
      expect(
        supportedLocales.map((l) => l.languageCode).toList(),
        SupportedLocale.values.map((l) => l.tag).toList(),
      );
    });

    test('the ARB files map 1:1 onto SupportedLocale', () {
      final arbTags =
          Directory('lib/l10n')
              .listSync()
              .whereType<File>()
              .map((f) => f.uri.pathSegments.last)
              .where((name) => RegExp(r'^app_\w+\.arb$').hasMatch(name))
              .map((name) => name.substring(4, name.length - 4))
              .toList()
            ..sort();

      expect(
        arbTags,
        (SupportedLocale.values.map((l) => l.tag).toList())..sort(),
        reason:
            'a fifth ARB nobody translated fails here, and so does an enum '
            'case with no ARB',
      );
    });

    test('every ARB declares an @@locale matching its filename', () {
      for (final locale in SupportedLocale.values) {
        final arb =
            jsonDecode(
                  File('lib/l10n/app_${locale.tag}.arb').readAsStringSync(),
                )
                as Map<String, dynamic>;

        expect(arb['@@locale'], locale.tag);
      }
    });
  });

  group('the decision record', () {
    test('ADR 0001 is superseded and ADR 0002 exists', () {
      expect(
        File('docs/decisions/0001-localisation.md').readAsStringSync(),
        contains('Superseded by'),
      );
      expect(
        File('docs/decisions/0002-four-locales-and-rtl.md').existsSync(),
        isTrue,
      );
    });
  });

  group('the delegates are wired', () {
    // The EXECUTABLE text. This group asserted `contains` over the raw file and
    // went on passing after E04 stopped handing MaterialApp
    // AppLocalizations.supportedLocales — because the only remaining occurrence
    // is the comment saying why it must not be used. A policy test satisfied by
    // the prose explaining its own violation is worse than no policy test.
    final app = withoutDartComments(File('lib/app.dart').readAsStringSync());

    test(
      'the app delegate list is built through localizationsDelegatesFor',
      () {
        expect(
          app,
          contains('localizationsDelegatesFor('),
          reason:
              'handing MaterialApp AppLocalizations.localizationsDelegates '
              'directly puts the Global delegates ahead of the vendored ckb '
              'ones, and the first delegate of a type wins',
        );
        expect(app, contains('AppLocalizations.localizationsDelegates'));
      },
    );

    test(
      'supportedLocales is the enum-order projection, not the gen-l10n one',
      () {
        expect(
          app,
          contains('supportedLocales: supportedLocales'),
          reason:
              'lib/l10n/supported_locales.dart is the list MaterialApp gets',
        );
        expect(
          app,
          isNot(contains('AppLocalizations.supportedLocales')),
          reason:
              'gen-l10n emits that list ALPHABETICALLY, so its first entry is '
              'ckb — and Flutter falls back to the first supported locale, which '
              'would make Kurdish Sorani the language of every unsupported '
              'device',
        );
      },
    );
  });
}
