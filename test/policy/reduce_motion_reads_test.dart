import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/source_text.dart';

/// Nothing decides whether to animate by reading app state.
///
/// `MotionPreferenceScope` folds the app's toggle into
/// `MediaQuery.disableAnimations` at the root, so every widget below it asks
/// the platform flag and gets an answer that already carries both. A widget
/// that read `isReduceMotionEnabled` itself would be right on the app toggle
/// and **wrong on the OS one** — the accessibility setting, the one that
/// matters — and the mistake is invisible on a developer device with motion on.
void main() {
  /// Where the setting may legitimately appear, and why.
  const permitted = <String, String>{
    'lib/core/app_settings.dart': 'the field itself',
    'lib/data/db/tables/settings.dart': 'the column',
    'lib/data/db/app_database.dart': 'the schema',
    'lib/data/daos/settings_dao.dart': 'the read and the write',
    'lib/shared/feedback/feedback_gates.dart': 'the one provider exposing it',
    'lib/shared/motion/motion_preference_scope.dart':
        'the one place it is '
        'read, folded into MediaQuery',
  };

  /// Plus the screen that lets a player change it, which does not exist yet.
  bool isSettingsFeature(String path) =>
      path.startsWith('lib/features/settings/');

  test('the setting is read in exactly one place outside its own plumbing', () {
    final offenders = <String>[];

    for (final file in dartFilesUnderLib()) {
      if (permitted.containsKey(file.path)) continue;
      if (isSettingsFeature(file.path)) continue;

      // Stripped, so a comment about the setting is not a read of it.
      if (withoutDartComments(
        file.readAsStringSync(),
      ).contains('isReduceMotionEnabled')) {
        offenders.add(file.path);
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'these read the app setting directly; ask '
          'MediaQuery.disableAnimationsOf(context) instead, which carries both '
          'the app toggle and the OS one',
    );
  });

  test('and every permitted file still exists, so the list cannot rot', () {
    // An allowlist naming a deleted file is an allowlist nobody is maintaining.
    for (final entry in permitted.entries) {
      expect(
        File(entry.key).existsSync(),
        isTrue,
        reason: '${entry.key} is permitted for "${entry.value}" but is gone',
      );
    }
  });

  test('nothing animates off the provider either', () {
    // The provider is the same leak wearing a different name: a widget that
    // watches it is still deciding from app state.
    final offenders = <String>[];

    const owners = <String>{
      'lib/shared/feedback/feedback_gates.dart',
      'lib/shared/motion/motion_preference_scope.dart',
    };

    for (final file in dartFilesUnderLib()) {
      if (owners.contains(file.path)) continue;

      if (withoutDartComments(
        file.readAsStringSync(),
      ).contains('reduceMotionEnabledProvider')) {
        offenders.add(file.path);
      }
    }

    expect(offenders, isEmpty);
  });
}
