import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:robo_python/python/interpreter.dart';

/// Vergleicht den eigenen Interpreter mit echtem Python.
/// Referenzen erzeugt `python3 tool/make_python_fixtures.py`.
void main() {
  final fixtures = (jsonDecode(File('test/python/fixtures.json').readAsStringSync()) as List)
      .cast<Map<String, dynamic>>();

  for (final f in fixtures) {
    test('wie echtes Python: ${f['name']}', () {
      final result = const Interpreter().run(f['code'] as String);
      if (f.containsKey('error')) {
        expect(result.error, isNotNull, reason: 'Fehler erwartet');
        expect(result.error!.type, f['error']);
        expect(result.error!.line, f['line']);
      } else {
        expect(result.error, isNull, reason: result.error?.display);
        expect(result.output, f['output']);
      }
    });
  }
}
