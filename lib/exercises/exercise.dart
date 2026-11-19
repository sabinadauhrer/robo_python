/// Aufgaben-Modelle (reines Dart). Beschrieben in `assets/lessons/*.json`.
library;

/// Markierung einer Lücke im Code.
const blankMarker = '___';

sealed class Exercise {
  const Exercise({
    required this.task,
    required this.explain,
    required this.notes,
    required this.hint,
    this.why,
    this.inputs = const [],
    this.files = const {},
  });

  /// Was bei input() „eingetippt“ wird (der Reihe nach).
  final List<String> inputs;

  /// Dateien, die es beim Start schon gibt (Name → Inhalt).
  final Map<String, String> files;

  /// Was zu tun ist, z. B. "Ergänze die Lücke, damit Hallo ausgegeben wird."
  final String task;

  /// Robos Erklärung WÄHREND der Aufgabe: warum der Code so aussieht.
  final String explain;

  /// Erklärung einzelner Zeilen (Zeilennummer → Text), antippbar.
  final Map<int, String> notes;
  final String hint;

  /// Zusätzliche Erklärung nach der Antwort (optional).
  final String? why;

  /// Der Code, wie er angezeigt wird (bei Lückentext mit ___).
  String get displayCode;

  factory Exercise.fromJson(Map<String, dynamic> json) {
    final task = json['task'] as String;
    final explain = json['explain'] as String;
    final hint = json['hint'] as String? ?? '';
    final why = json['why'] as String?;
    final inputs = ((json['inputs'] as List?) ?? const []).cast<String>();
    final files = ((json['files'] as Map<String, dynamic>?) ?? const {}).cast<String, String>();
    final notes = {
      for (final e in ((json['notes'] as Map<String, dynamic>?) ?? {}).entries) int.parse(e.key): e.value as String,
    };
    return switch (json['type']) {
      'fill' => FillExercise(
        task: task,
        explain: explain,
        notes: notes,
        hint: hint,
        why: why,
        inputs: inputs,
        files: files,
        code: json['code'] as String,
        answers: [for (final a in json['answers'] as List) (a as List).cast<String>()],
        expectedOutput: json['output'] as String?,
      ),
      'choice' => ChoiceExercise(
        task: task,
        explain: explain,
        notes: notes,
        hint: hint,
        why: why,
        inputs: inputs,
        files: files,
        code: json['code'] as String,
        options: (json['options'] as List).cast<String>(),
        correct: json['correct'] as int,
        isOutputQuestion: json['isOutput'] as bool? ?? false,
      ),
      'order' => OrderExercise(
        task: task,
        explain: explain,
        notes: notes,
        hint: hint,
        why: why,
        inputs: inputs,
        files: files,
        lines: (json['lines'] as List).cast<String>(),
        expectedOutput: json['output'] as String,
      ),
      _ => throw FormatException('Unbekannter Aufgabentyp: ${json['type']}'),
    };
  }
}

/// Lückentext wie bei W3Schools: Code mit ___, die ausgefüllt werden.
class FillExercise extends Exercise {
  const FillExercise({
    required super.task,
    required super.explain,
    required super.notes,
    required super.hint,
    super.why,
    super.inputs,
    super.files,
    required this.code,
    required this.answers,
    this.expectedOutput,
  });

  final String code;

  /// Erlaubte Antworten je Lücke; die erste ist die Musterlösung.
  final List<List<String>> answers;

  /// Falls gesetzt, zählt auch jede andere Antwort, die genau diese Ausgabe erzeugt.
  final String? expectedOutput;

  int get blankCount => blankMarker.allMatches(code).length;

  List<String> get solution => [for (final a in answers) a.first];

  @override
  String get displayCode => code;

  /// Setzt die Eingaben in die Lücken ein.
  String fill(List<String> inputs) {
    var i = 0;
    return code.replaceAllMapped(blankMarker, (_) => i < inputs.length ? inputs[i++] : blankMarker);
  }
}

/// Auswahl aus mehreren Antworten, z. B. "Was gibt der Code aus?".
class ChoiceExercise extends Exercise {
  const ChoiceExercise({
    required super.task,
    required super.explain,
    required super.notes,
    required super.hint,
    super.why,
    super.inputs,
    super.files,
    required this.code,
    required this.options,
    required this.correct,
    required this.isOutputQuestion,
  });

  final String code;
  final List<String> options;
  final int correct;

  /// True: Die richtige Antwort ist genau die Ausgabe des Codes (wird getestet).
  final bool isOutputQuestion;

  @override
  String get displayCode => code;
}

/// Zeilen in die richtige Reihenfolge bringen.
class OrderExercise extends Exercise {
  const OrderExercise({
    required super.task,
    required super.explain,
    required super.notes,
    required super.hint,
    super.why,
    super.inputs,
    super.files,
    required this.lines,
    required this.expectedOutput,
  });

  /// Zeilen in der richtigen Reihenfolge (mit Einrückung).
  final List<String> lines;
  final String expectedOutput;

  @override
  String get displayCode => lines.join('\n');

  String arrange(List<int> order) => [for (final i in order) lines[i]].join('\n');
}

/// Eine Insel auf der Karte = ein Thema mit mehreren Aufgaben.
class Lesson {
  const Lesson({
    required this.id,
    required this.order,
    required this.title,
    required this.icon,
    required this.intro,
    required this.exercises,
    this.chapter,
  });

  /// Kapitel, zu dem die Insel gehört (z. B. "Grundlagen").
  final String? chapter;

  final String id;
  final int order;
  final String title;

  /// Name eines Symbols (siehe `lesson_icons.dart`).
  final String icon;

  /// Kurze Einführung ins Thema (vor dem Start).
  final String intro;
  final List<Exercise> exercises;

  factory Lesson.fromJson(Map<String, dynamic> json) => Lesson(
    id: json['id'] as String,
    order: json['order'] as int,
    title: json['title'] as String,
    icon: json['icon'] as String? ?? 'star',
    intro: json['intro'] as String,
    chapter: json['chapter'] as String?,
    exercises: [for (final e in json['exercises'] as List) Exercise.fromJson(e as Map<String, dynamic>)],
  );

  @override
  bool operator ==(Object other) => other is Lesson && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
