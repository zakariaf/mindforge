import 'package:mindforge/core/failure.dart';
import 'package:mindforge/core/result.dart';
import 'package:test/test.dart';

final class _Boom extends Failure {
  const _Boom();

  @override
  String get code => 'test.boom';
}

void main() {
  group('Result', () {
    test('fold maps Ok through onOk and Err through onErr', () {
      const ok = Ok<int, _Boom>(41);
      const err = Err<int, _Boom>(_Boom());

      expect(ok.fold(onOk: (v) => v + 1, onErr: (f) => -1), 42);
      expect(err.fold(onOk: (v) => v + 1, onErr: (f) => -1), -1);
    });

    test('map transforms an Ok value', () {
      const ok = Ok<int, _Boom>(21);

      expect(ok.map((v) => v * 2), isA<Ok<int, _Boom>>());
      expect((ok.map((v) => v * 2) as Ok<int, _Boom>).value, 42);
    });

    test('map passes the identical Err instance through', () {
      const failure = _Boom();
      const err = Err<int, _Boom>(failure);

      final mapped = err.map((v) => v * 2);

      expect(mapped, isA<Err<int, _Boom>>());
      expect(
        identical((mapped as Err<int, _Boom>).failure, failure),
        isTrue,
        reason:
            'reconstructing the failure would discard whatever typed '
            'params the original carried',
      );
    });

    test('a switch over Ok and Err compiles with no wildcard', () {
      // The whole point of the sealed family: adding a third variant must
      // break the build here rather than fall silently into a default arm.
      const Result<int, _Boom> result = Ok<int, _Boom>(7);

      final described = switch (result) {
        Ok<int, _Boom>(value: final v) => 'ok $v',
        Err<int, _Boom>(failure: final f) => 'err ${f.code}',
      };

      expect(described, 'ok 7');
    });
  });
}
