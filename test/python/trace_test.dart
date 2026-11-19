import 'package:flutter_test/flutter_test.dart';
import 'package:robo_python/python/interpreter.dart';

RunResult run(String code) => const Interpreter().run(code);

void main() {
  test('jeder Schritt hat Zeile, Erklärung und Variablen', () {
    final r = run('x = 3\nx = x + 1\nprint(x)');
    expect(r.trace.map((s) => s.line), [null, 1, 2, 3]);
    expect(r.trace[1].description, contains('Neue Variable x'));
    expect(r.trace[2].description, contains('neuen Wert 4 (vorher 3)'));
    expect(r.trace[3].kind, StepKind.print);
    expect(r.trace[3].output, '4\n');
    final x = r.trace[2].variables.single;
    expect((x.name, x.repr, x.changed), ('x', '4', true));
    expect(r.trace[3].variables.single.changed, isFalse);
  });

  test('Bedingungen werden mit ihrem Text erklärt', () {
    final r = run('alter = 12\nif alter >= 18:\n    print("Erwachsen")\nelse:\n    print("Kind")');
    expect(r.trace[2].description, contains('alter >= 18 ist False'));
    expect(r.output, 'Kind');
  });

  test('Schleifen zeigen die Runden', () {
    final r = run('for f in ["a", "b"]:\n    pass');
    final loop = r.trace.where((s) => s.kind == StepKind.loop).map((s) => s.description).toList();
    expect(loop[0], contains("Runde 1 der for-Schleife: f ist jetzt 'a'"));
    expect(loop.last, contains('fertig (2 Runden)'));
  });

  test('Funktionsaufruf springt in die Funktion und zeigt lokale Variablen', () {
    final r = run('def doppelt(n):\n    return n * 2\nx = doppelt(4)');
    expect(r.trace.map((s) => s.line), [null, 1, 1, 2, 3]);
    final call = r.trace[2];
    expect(call.kind, StepKind.call);
    expect(call.description, contains('doppelt() wird aufgerufen mit n = 4'));
    expect(call.variables.any((v) => v.name == 'n' && v.scope == 'doppelt()'), isTrue);
    expect(r.trace[3].description, contains('return gibt 8 zurück'));
    expect(r.trace.last.variables.any((v) => v.name == 'x' && v.repr == '8'), isTrue);
  });

  test('Listenänderungen werden beschrieben', () {
    final r = run('l = [1]\nl.append(2)');
    expect(r.trace.last.description, contains('l ist jetzt [1, 2]'));
    expect(r.trace.last.variables.single.changed, isTrue);
  });

  test('Fehler stehen am Ende der Trace und sind deutsch', () {
    final r = run('name = "Mia"\nprint(Name)');
    expect(r.trace.last.kind, StepKind.error);
    expect(r.error!.display, startsWith('Zeile 2 – NameError'));
    expect(r.error!.message, contains('meintest du "name"'));
  });

  test('Syntaxfehler: nur der Startschritt', () {
    final r = run('for i in range(3):\nprint(i)');
    expect(r.isSyntaxError, isTrue);
    expect(r.trace, hasLength(1));
    expect(r.error!.message, contains('Einrückung fehlt'));
  });

  test('Endlosschleife wird gestoppt', () {
    final r = const Interpreter(maxSteps: 50).run('while True:\n    pass');
    expect(r.error!.message, contains('Endlosschleife'));
  });

  test('typische Anfängerfehler', () {
    expect(run('if x = 5:\n    pass').error!.message, contains('=='));
    expect(run('print "hi"').error!.type, 'SyntaxError');
    expect(run('x = true').error!.message, contains('True'));
    expect(run('Print("x")').error!.message, contains('"print"'));
    expect(run('else:\n    pass').error!.message, contains('if'));
    expect(run('x = “Hallo”').error!.message, contains('Anführungszeichen'));
    expect(run('input("Name?")').error!.message, contains('input()'));
    expect(run('pront("Hi")').error!.message, contains('Meintest du print()?'));
    expect(run('def hallo():\n    pass\nhalo()').error!.message, contains('Meintest du hallo()?'));
  });
}
