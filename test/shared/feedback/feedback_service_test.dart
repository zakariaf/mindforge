import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/shared/feedback/feedback_service.dart';
import 'package:mindforge/shared/feedback/haptic_verb.dart';
import 'package:mindforge/shared/feedback/moment.dart';
import 'package:mindforge/shared/feedback/moment_catalog.dart';
import 'package:mindforge/shared/feedback/sound_cue.dart';
import 'package:mindforge/shared/feedback/testing/fake_haptic_gateway.dart';

void main() {
  LiveFeedbackService serviceOver(
    FakeHapticGateway gateway, {
    bool haptics = true,
    bool sound = true,
  }) => LiveFeedbackService(
    gateway: gateway,
    hapticsEnabled: haptics,
    soundEnabled: sound,
    onError: (_, _) {},
  );

  group('firing', () {
    test('plays exactly one verb per moment that declares one', () {
      for (final entry in kMomentCatalog.entries) {
        if (entry.value.haptic == null) continue;

        final gateway = FakeHapticGateway();
        serviceOver(gateway).fire(entry.key);

        expect(
          gateway.played,
          <HapticVerb>[entry.value.haptic!],
          reason: '${entry.key}',
        );
      }
    });

    test('and plays nothing for a declared silence', () {
      for (final entry in kMomentCatalog.entries) {
        if (entry.value.haptic != null) continue;

        final gateway = FakeHapticGateway();
        serviceOver(gateway).fire(entry.key);

        expect(gateway.played, isEmpty, reason: '${entry.key}');
      }
    });

    test('firing all eighteen spends heavyImpact exactly once', () {
      // The invariant the catalog declares, asserted end to end through the
      // service rather than only over the table.
      final gateway = FakeHapticGateway();
      final service = serviceOver(gateway);

      Moment.values.forEach(service.fire);

      expect(
        gateway.played.where((verb) => verb == HapticVerb.heavyImpact),
        hasLength(1),
      );
    });
  });

  group('the gates', () {
    test('haptics off silences the gateway entirely', () {
      final gateway = FakeHapticGateway();
      final service = serviceOver(gateway, haptics: false);

      Moment.values.forEach(service.fire);

      expect(gateway.played, isEmpty);
    });

    test('sound off does not silence the haptic', () {
      // Two independent switches. A player who turned sound off in a quiet
      // room still wants to feel their answer land.
      final gateway = FakeHapticGateway();
      final service = serviceOver(gateway, sound: false)
        ..fire(Moment.answerCorrect);

      expect(gateway.played, <HapticVerb>[HapticVerb.lightImpact]);
      expect(
        service.soundCueFor(Moment.answerCorrect),
        isNull,
        reason: 'the sound gate is independent of the haptic one',
      );
    });

    test('and sound on returns the moment its slot', () {
      expect(
        serviceOver(FakeHapticGateway()).soundCueFor(Moment.personalBest),
        SoundCue.fanfare,
      );
    });
  });

  group('reduce motion', () {
    test('is not an input to this service at all', () {
      // THE BUG THIS SHAPE MAKES UNWRITABLE: an early return above fire() for
      // reduced motion. Reduce motion changes what a moment LOOKS like; it does
      // not change whether the device acknowledges a tap, and a player who
      // turned animation off still wants to feel their answer land.
      final source = File(
        'lib/shared/feedback/feedback_service.dart',
      ).readAsStringSync();

      expect(source, isNot(contains('disableAnimations')));
      expect(source, isNot(contains('reduceMotion')));
    });
  });

  group('a failing gateway', () {
    test('does not surface, and is reported once', () async {
      // A device with no taptic engine must not take a screen down over a buzz
      // that did not happen.
      final gateway = FakeHapticGateway.failing();
      final errors = <Object>[];

      LiveFeedbackService(
        gateway: gateway,
        hapticsEnabled: true,
        soundEnabled: true,
        onError: (error, _) => errors.add(error),
      ).fire(Moment.buttonCommit);

      await Future<void>.delayed(Duration.zero);

      expect(errors, hasLength(1));
      expect(gateway.played, <HapticVerb>[HapticVerb.lightImpact]);
    });
  });

  group('the service is locale-blind', () {
    test('it imports no localization and no formatter', () {
      // A haptic is not a string. Nothing here has a translation, and a
      // sequence of verbs that changed with the language would be a bug.
      final source = File(
        'lib/shared/feedback/feedback_service.dart',
      ).readAsStringSync();

      expect(source, isNot(contains('app_localizations')));
      expect(source, isNot(contains('package:intl')));
    });
  });
}
