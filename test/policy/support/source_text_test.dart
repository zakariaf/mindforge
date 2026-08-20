import 'package:flutter_test/flutter_test.dart';

import 'source_text.dart';

void main() {
  group('withoutDartComments', () {
    test('removes a trailing comment', () {
      expect(withoutDartComments('final x = 1; // why'), 'final x = 1; ');
    });

    test('removes a whole-line comment', () {
      expect(withoutDartComments('  // just prose'), '  ');
    });

    test('does not cut a // inside a string literal', () {
      // The regression this helper was rewritten for: a naive indexOf('//')
      // truncates at the scheme separator, so anything after a URL on the same
      // line vanishes before a banned-symbol scan ever sees it.
      const line = "final u = Uri.parse('https://x'); HttpClient();";

      expect(withoutDartComments(line), line);
      expect(
        withoutDartComments(line),
        contains('HttpClient'),
        reason: 'banned_imports_test scans the STRIPPED text',
      );
    });

    test('handles an escaped quote inside a literal', () {
      const line = r"final s = 'it\'s fine'; // trailing";

      expect(withoutDartComments(line), r"final s = 'it\'s fine'; ");
    });
  });

  group('withoutYamlComments', () {
    test('removes a trailing comment', () {
      expect(withoutYamlComments('key: value # why'), 'key: value ');
    });

    test('does not cut a # inside a quoted value', () {
      const line = "colour: '#2B1B4D'";

      expect(withoutYamlComments(line), line);
    });
  });
}
