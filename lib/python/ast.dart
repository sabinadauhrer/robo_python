// Syntaxbaum der unterstützten Python-Teilmenge.

// ---------------- Ausdrücke ----------------

sealed class Expr {
  const Expr();
}

/// Zahl, Kommazahl, Text, True/False/None.
class Literal extends Expr {
  const Literal(this.value);
  final Object? value;
}

/// f"Hallo {name}" – Teile sind entweder Text oder [FStringField].
class FStringExpr extends Expr {
  const FStringExpr(this.parts);
  final List<Object> parts;
}

class FStringField {
  const FStringField(this.expr, this.spec);
  final Expr expr;
  final String? spec;
}

class NameExpr extends Expr {
  const NameExpr(this.name);
  final String name;
}

class ListExpr extends Expr {
  const ListExpr(this.items);
  final List<Expr> items;
}

class TupleExpr extends Expr {
  const TupleExpr(this.items);
  final List<Expr> items;
}

class SetExpr extends Expr {
  const SetExpr(this.items);
  final List<Expr> items;
}

class DictExpr extends Expr {
  const DictExpr(this.keys, this.values);
  final List<Expr> keys;
  final List<Expr> values;
}

/// Teil einer Comprehension: `for ziele in iterable` oder `if bedingung`.
sealed class CompClause {
  const CompClause();
}

class CompFor extends CompClause {
  const CompFor(this.targets, this.iterable);
  final List<String> targets;
  final Expr iterable;
}

class CompIf extends CompClause {
  const CompIf(this.condition);
  final Expr condition;
}

enum CompKind { list, set, dict, generator }

/// [x for x in a if b], {x for ...}, {k: v for ...}, (x for ...)
class CompExpr extends Expr {
  const CompExpr(this.kind, this.element, this.clauses, {this.value});
  final CompKind kind;

  /// Element bzw. Schlüssel (bei dict).
  final Expr element;

  /// Wert (nur bei dict).
  final Expr? value;
  final List<CompClause> clauses;
}

/// *liste in einem Aufruf oder links vom "=".
class StarredExpr extends Expr {
  const StarredExpr(this.value);
  final Expr value;
}

class IndexExpr extends Expr {
  const IndexExpr(this.target, this.index);
  final Expr target;
  final Expr index;
}

class SliceExpr extends Expr {
  const SliceExpr(this.target, this.start, this.stop, this.step);
  final Expr target;
  final Expr? start;
  final Expr? stop;
  final Expr? step;
}

/// obj.name
class AttributeExpr extends Expr {
  const AttributeExpr(this.target, this.name);
  final Expr target;
  final String name;
}

class CallExpr extends Expr {
  const CallExpr(this.callee, this.args, this.kwargs, [this.starKwargs = const []]);
  final Expr callee;

  /// Kann [StarredExpr] enthalten (*liste).
  final List<Expr> args;
  final Map<String, Expr> kwargs;

  /// **dict
  final List<Expr> starKwargs;
}

/// + - * / // % ** and or
class BinaryExpr extends Expr {
  const BinaryExpr(this.op, this.left, this.right);
  final String op;
  final Expr left;
  final Expr right;
}

/// Vergleichskette, z. B. `1 < x <= 5` oder `"a" in text`.
class CompareExpr extends Expr {
  const CompareExpr(this.first, this.ops, this.rest);
  final Expr first;
  final List<String> ops;
  final List<Expr> rest;
}

/// - + not
class UnaryExpr extends Expr {
  const UnaryExpr(this.op, this.operand);
  final String op;
  final Expr operand;
}

/// a if bedingung else b
class CondExpr extends Expr {
  const CondExpr(this.condition, this.then, this.otherwise);
  final Expr condition;
  final Expr then;
  final Expr otherwise;
}

class LambdaExpr extends Expr {
  const LambdaExpr(this.params, this.defaults, this.body);
  final List<String> params;
  final Map<String, Expr> defaults;
  final Expr body;
}

// ---------------- Anweisungen ----------------

sealed class Stmt {
  const Stmt(this.line);
  final int line;
}

/// a = b = wert  (Ziele: Name, Index, Tupel aus Namen)
class AssignStmt extends Stmt {
  const AssignStmt(super.line, this.targets, this.value);
  final List<Expr> targets;
  final Expr value;
}

/// x += 1
class AugAssignStmt extends Stmt {
  const AugAssignStmt(super.line, this.target, this.op, this.value);
  final Expr target;
  final String op;
  final Expr value;
}

class ExprStmt extends Stmt {
  const ExprStmt(super.line, this.expr);
  final Expr expr;
}

class IfBranch {
  const IfBranch(this.line, this.keyword, this.condition, this.conditionText, this.body);
  final int line;
  final String keyword;
  final Expr condition;
  final String conditionText;
  final List<Stmt> body;
}

class IfStmt extends Stmt {
  IfStmt(this.branches, this.elseBody) : super(branches.first.line);
  final List<IfBranch> branches;
  final List<Stmt>? elseBody;
}

class WhileStmt extends Stmt {
  const WhileStmt(super.line, this.condition, this.conditionText, this.body, [this.elseBody]);
  final Expr condition;
  final String conditionText;
  final List<Stmt> body;

  /// läuft, wenn die Schleife ohne break endet
  final List<Stmt>? elseBody;
}

class ForStmt extends Stmt {
  const ForStmt(super.line, this.targets, this.iterable, this.body, [this.elseBody]);
  final List<String> targets;
  final Expr iterable;
  final List<Stmt> body;
  final List<Stmt>? elseBody;
}

class DefStmt extends Stmt {
  DefStmt(
    super.line,
    this.name,
    this.params,
    this.defaults,
    this.body, {
    this.varArgs,
    this.kwArgs,
    this.positionalOnly = 0,
    this.keywordOnly = const {},
    this.decorators = const [],
  });
  final String name;
  final List<String> params;
  final Map<String, Expr> defaults;
  final List<Stmt> body;
  final String? varArgs;
  final String? kwArgs;
  final int positionalOnly;
  final Set<String> keywordOnly;
  List<Expr> decorators;
}

class ClassStmt extends Stmt {
  ClassStmt(super.line, this.name, this.bases, this.body, {this.decorators = const []});
  final String name;
  final List<Expr> bases;
  final List<Stmt> body;
  List<Expr> decorators;
}

class ExceptClause {
  const ExceptClause(this.line, this.types, this.name, this.body);
  final int line;

  /// null = fängt alle Fehler (except:)
  final Expr? types;
  final String? name;
  final List<Stmt> body;
}

class TryStmt extends Stmt {
  const TryStmt(super.line, this.body, this.handlers, this.elseBody, this.finallyBody, this.finallyLine);
  final List<Stmt> body;
  final List<ExceptClause> handlers;
  final List<Stmt>? elseBody;
  final List<Stmt>? finallyBody;
  final int? finallyLine;
}

class RaiseStmt extends Stmt {
  const RaiseStmt(super.line, this.value);

  /// null = den gerade behandelten Fehler erneut auslösen.
  final Expr? value;
}

class AssertStmt extends Stmt {
  const AssertStmt(super.line, this.condition, this.message);
  final Expr condition;
  final Expr? message;
}

/// Ein Muster in `case`: Wert, Name (fängt alles und speichert) oder _.
sealed class MatchPattern {
  const MatchPattern();
}

class ValuePattern extends MatchPattern {
  const ValuePattern(this.value);
  final Expr value;
}

class CapturePattern extends MatchPattern {
  const CapturePattern(this.name);

  /// null = _ (Platzhalter)
  final String? name;
}

class MatchCase {
  const MatchCase(this.line, this.patterns, this.patternText, this.guard, this.body);
  final int line;

  /// Alternativen, getrennt durch |
  final List<MatchPattern> patterns;
  final String patternText;
  final Expr? guard;
  final List<Stmt> body;
}

class MatchStmt extends Stmt {
  const MatchStmt(super.line, this.subject, this.subjectText, this.cases);
  final Expr subject;
  final String subjectText;
  final List<MatchCase> cases;
}

/// import math, import math as m, from math import sqrt
class ImportStmt extends Stmt {
  const ImportStmt(super.line, this.module, this.names, {this.alias});
  final String module;

  /// null = ganzes Modul importieren; sonst Name → Alias (Name "*" = alles).
  final Map<String, String>? names;
  final String? alias;
}

/// with ausdruck as name:
class WithStmt extends Stmt {
  const WithStmt(super.line, this.value, this.name, this.body);
  final Expr value;
  final String? name;
  final List<Stmt> body;
}

class YieldStmt extends Stmt {
  const YieldStmt(super.line, this.value);
  final Expr? value;
}

class NonlocalStmt extends Stmt {
  const NonlocalStmt(super.line, this.names);
  final List<String> names;
}

class ReturnStmt extends Stmt {
  const ReturnStmt(super.line, this.value);
  final Expr? value;
}

class BreakStmt extends Stmt {
  const BreakStmt(super.line);
}

class ContinueStmt extends Stmt {
  const ContinueStmt(super.line);
}

class PassStmt extends Stmt {
  const PassStmt(super.line);
}

class DelStmt extends Stmt {
  const DelStmt(super.line, this.targets);
  final List<Expr> targets;
}

class GlobalStmt extends Stmt {
  const GlobalStmt(super.line, this.names);
  final List<String> names;
}
