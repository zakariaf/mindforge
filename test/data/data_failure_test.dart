import 'package:mindforge/data/data_failure.dart';
import 'package:test/test.dart';

/// The frozen code list. Renaming one is a deliberate edit here, because these
/// strings appear in logs and in every call site's switch.
const kDataFailureCodes = <String>[
  'data.store_unavailable',
  'data.constraint_violated',
  'data.run_already_recorded',
  'data.not_found',
  'data.corrupt_row',
  'data.unsupported_locale_tag',
];

void main() {
  group('DataFailure', () {
    test('every leaf exposes its frozen code', () {
      const failures = <DataFailure>[
        StoreUnavailable(),
        ConstraintViolated('longest_combo'),
        RunAlreadyRecorded('key-1'),
        NotFound('stroop_rush'),
        CorruptRow('runs', 'mixed metric_kind in one scope'),
        UnsupportedLocaleTag('ar'),
      ];

      expect(failures.map((f) => f.code).toList(), kDataFailureCodes);
    });

    test('no leaf carries a user-facing sentence', () {
      // error-handling-typed-results rule 3. A message baked in here is a
      // string the ARB cannot translate and the log cannot parse, and the data
      // layer has no idea which of four locales the reader is in.
      const failure = UnsupportedLocaleTag('ar');

      expect(
        failure.tag,
        'ar',
        reason:
            'the offending tag is carried as a typed param for the log '
            'line, not as "The language ar is not supported."',
      );
    });

    test('the family switches exhaustively with no default', () {
      const DataFailure failure = RunAlreadyRecorded('key-7');

      final described = switch (failure) {
        StoreUnavailable() => 'unavailable',
        ConstraintViolated(:final constraint) => 'constraint $constraint',
        RunAlreadyRecorded(:final clientRunKey) => 'duplicate $clientRunKey',
        NotFound(:final what) => 'missing $what',
        CorruptRow(:final table, :final detail) => 'corrupt $table $detail',
        UnsupportedLocaleTag(:final tag) => 'locale $tag',
      };

      expect(described, 'duplicate key-7');
    });

    test('leaves are const and compare by value', () {
      expect(const StoreUnavailable(), const StoreUnavailable());
      expect(
        const ConstraintViolated('a'),
        isNot(const ConstraintViolated('b')),
      );
    });
  });
}
