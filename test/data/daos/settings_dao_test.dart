import 'package:mindforge/core/supported_locale.dart';
import 'package:mindforge/data/daos/settings_dao.dart';
import 'package:mindforge/data/db/app_database.dart';
import 'package:test/test.dart';

import '../../support/test_database.dart';

void main() {
  late AppDatabase db;
  late SettingsDao dao;

  setUp(() {
    db = openTestDatabase();
    dao = SettingsDao(db);
    addTearDown(db.close);
  });

  Future<String?> rawLocaleTag() async {
    final row = await db
        .customSelect("SELECT locale_tag AS t FROM settings WHERE id = 'app'")
        .getSingle();
    return row.data['t'] as String?;
  }

  group('reading', () {
    test(
      'the seeded row maps to the design defaults with no override',
      () async {
        final read = await dao.read();

        expect(read.settings.isSoundEnabled, isTrue);
        expect(read.settings.isHapticsEnabled, isTrue);
        expect(read.settings.isReduceMotionEnabled, isFalse);
        expect(read.settings.isColourBlindPalette, isFalse);
        expect(read.settings.localeOverride, isNull);
        expect(read.unsupportedLocaleTag, isNull);
      },
    );

    test('watch emits immediately on subscribe', () async {
      final first = await dao.watch().first;

      expect(first.settings.localeOverride, isNull);
    });
  });

  group('the locale round-trip stores the ASCII tag', () {
    for (final locale in SupportedLocale.values) {
      test('${locale.tag} survives a write and a read', () async {
        final before = (await dao.read()).settings;

        await dao.write(
          before.withLocaleOverride(locale),
          updatedAtUtcMs: 1,
          rowRevision: 2,
        );

        expect(
          await rawLocaleTag(),
          locale.tag,
          reason:
              'the RAW column matters, not just the mapped value: the '
              'point is that the stored form is the ASCII tag',
        );
        expect((await dao.read()).settings.localeOverride, locale);
      });
    }

    test('withSystemLocale writes SQL NULL, not the old tag', () async {
      final before = (await dao.read()).settings;

      await dao.write(
        before.withLocaleOverride(SupportedLocale.ckb),
        updatedAtUtcMs: 1,
        rowRevision: 2,
      );
      await dao.write(
        before.withSystemLocale(),
        updatedAtUtcMs: 2,
        rowRevision: 3,
      );

      expect(
        await rawLocaleTag(),
        isNull,
        reason:
            'Value(null) writes NULL; Value.absent() would leave ckb in '
            'place, which is exactly the bug withSystemLocale exists to avoid',
      );
      expect((await dao.read()).settings.localeOverride, isNull);
    });
  });

  group('an unrecognised tag degrades rather than throwing', () {
    setUp(() async {
      // 'ar' is legal by the column's shape CHECK and absent from
      // SupportedLocale — exactly the shape of a locale withdrawn in a later
      // build, or of a row written by a newer version.
      await db.customStatement(
        "UPDATE settings SET locale_tag = 'ar' WHERE id = 'app'",
      );
    });

    test('it maps to null, reports the tag, and does not throw', () async {
      final read = await dao.read();

      expect(read.settings.localeOverride, isNull);
      expect(read.unsupportedLocaleTag, 'ar');
    });

    test('it leaves the column untouched', () async {
      await dao.read();

      expect(
        await rawLocaleTag(),
        'ar',
        reason:
            'the read does not self-heal. Rewriting the column would be a '
            'side effect inside a read, and it would permanently destroy a '
            'real preference for someone who downgraded to a build that '
            'dropped a locale and then upgraded again',
      );
    });
  });
}
