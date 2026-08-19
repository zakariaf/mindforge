import 'package:clock/clock.dart';
import 'package:mindforge/core/app_settings.dart';
import 'package:mindforge/core/result.dart';
import 'package:mindforge/core/supported_locale.dart';
import 'package:mindforge/data/daos/settings_dao.dart';
import 'package:mindforge/data/data_failure.dart';
import 'package:mindforge/data/db/app_database.dart';
import 'package:mindforge/data/repositories/settings_repository.dart';
import 'package:test/test.dart';

import '../../support/fake_log_sink.dart';
import '../../support/test_database.dart';

void main() {
  late AppDatabase db;
  late SettingsRepository repository;
  late FakeLogSink logSink;

  setUp(() {
    db = openTestDatabase();
    logSink = FakeLogSink();
    repository = SettingsRepository(
      database: db,
      dao: SettingsDao(db),
      clock: Clock.fixed(kTestNow),
      logSink: logSink,
    );
    addTearDown(db.close);
  });

  /// Awaits [result] and asserts it is an [Ok], returning the value.
  ///
  /// Used for every arrange step. `@useResult` on the repository is what forces
  /// this, and it is right to: an arrange step whose write silently failed
  /// would leave the assertion afterwards testing nothing.
  Future<AppSettings> arrange(
    Future<Result<AppSettings, DataFailure>> result,
  ) async {
    final settled = await result;
    expect(
      settled,
      isA<Ok<AppSettings, DataFailure>>(),
      reason: 'the step being arranged did not succeed: $settled',
    );
    return (settled as Ok<AppSettings, DataFailure>).value;
  }

  Future<Map<String, Object?>> rawRow() async {
    final row = await db
        .customSelect("SELECT * FROM settings WHERE id = 'app'")
        .getSingle();
    return row.data;
  }

  group('read', () {
    test('returns Ok with the seeded defaults', () async {
      expect(await arrange(repository.read()), const AppSettings.defaults());
    });

    test('the result switches exhaustively with no default', () async {
      final result = await repository.read();

      // A compile-time proof the family is sealed: adding a variant breaks this
      // switch rather than falling into a wildcard arm.
      final described = switch (result) {
        Ok<AppSettings, DataFailure>(:final value) =>
          'ok ${value.isSoundEnabled}',
        Err<AppSettings, DataFailure>(:final failure) => 'err ${failure.code}',
      };

      expect(described, 'ok true');
    });
  });

  group('update', () {
    test('resolves only after the row is durable', () async {
      await arrange(
        repository.update(
          const AppSettings.defaults().copyWith(isSoundEnabled: false),
        ),
      );

      expect(
        (await rawRow())['is_sound_enabled'],
        0,
        reason:
            'reading the raw row in the same tick already sees the write, '
            'so the future resolved after the commit rather than before it',
      );
    });

    test('watch re-emits with no manual republish', () async {
      final emissions = <AppSettings>[];
      final subscription = repository.watch().listen(emissions.add);
      addTearDown(subscription.cancel);

      await pumpEventQueue();
      await arrange(
        repository.update(
          const AppSettings.defaults().copyWith(isHapticsEnabled: false),
        ),
      );
      await pumpEventQueue();

      expect(
        emissions.map((s) => s.isHapticsEnabled).toList(),
        [true, false],
        reason:
            'persist-before-publish: the stream re-emits because the row '
            'changed, not because a writer pushed an optimistic value at it',
      );
    });

    test(
      'bumps row_revision by exactly one and stamps from the Clock',
      () async {
        final before = (await rawRow())['row_revision']! as int;

        await arrange(
          repository.update(
            const AppSettings.defaults().copyWith(isColourBlindPalette: true),
          ),
        );

        final after = await rawRow();
        expect(after['row_revision'], before + 1);
        expect(
          after['updated_at_utc_ms'],
          kTestNow.millisecondsSinceEpoch,
          reason: 'stamped from the injected Clock, not the wall',
        );
      },
    );

    test(
      'a missing table returns Err(StoreUnavailable) and logs first',
      () async {
        // Not `await db.close()`: measured, drift silently REOPENS an in-memory
        // database on the next statement, so closing it provokes no failure at
        // all. Dropping the table is a real store failure SQLite reports.
        await db.customStatement('DROP TABLE settings');

        final result = await repository.update(const AppSettings.defaults());

        expect(result, const Err<AppSettings, DataFailure>(StoreUnavailable()));
        expect(
          logSink.codes,
          ['data.store_unavailable'],
          reason:
              'the original SqliteException is logged BEFORE the typed Err is '
              'returned, or the stack trace is gone forever',
        );
      },
    );
  });

  group('an unrecognised stored tag', () {
    setUp(() async {
      // Legal by the column's shape CHECK and absent from SupportedLocale —
      // exactly the shape of a locale withdrawn in a later build, or of a row
      // written by a newer version of the app.
      await db.customStatement(
        "UPDATE settings SET locale_tag = 'ar' WHERE id = 'app'",
      );
    });

    test('degrades to follow-system and is logged once per emission', () async {
      final settings = await arrange(repository.read());

      expect(settings.localeOverride, isNull);
      expect(logSink.codes, ['data.unsupported_locale_tag']);
      expect(
        (logSink.recorded.single as UnsupportedLocaleTag).tag,
        'ar',
        reason:
            'the raw tag is carried as a typed param so a withdrawn locale '
            'shows up in a diagnostics export instead of vanishing',
      );
    });

    test('does not throw and does not rewrite the column', () async {
      await arrange(repository.read());

      expect((await rawRow())['locale_tag'], 'ar');
    });
  });

  group('the locale override survives a round trip', () {
    for (final locale in SupportedLocale.values) {
      test(locale.tag, () async {
        await arrange(
          repository.update(
            const AppSettings.defaults().withLocaleOverride(locale),
          ),
        );

        expect((await rawRow())['locale_tag'], locale.tag);
        expect(
          (await arrange(repository.read())).localeOverride,
          locale,
        );
      });
    }

    test('clearing it writes SQL NULL', () async {
      await arrange(
        repository.update(
          const AppSettings.defaults().withLocaleOverride(SupportedLocale.fa),
        ),
      );
      await arrange(
        repository.update(const AppSettings.defaults().withSystemLocale()),
      );

      expect((await rawRow())['locale_tag'], isNull);
    });
  });
}
