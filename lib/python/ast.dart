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

/// [ausdruck for ziel in iterable if bedingung]
class ListCompExpr extends Expr {
  const ListCompExpr(this.element, this.targets, this.iterable, this.condition);
  final Expr element;
  final List<String> targets;
  final Expr iterable;
  final Expr? condition;
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

/// obj.name – nur als Methodenaufruf erlaubt.
class AttributeExpr extends Expr {
  const AttributeExpr(this.target, this.name);
  final Expr target;
  final String name;
}

class CallExpr extends Expr {
  const CallExpr(this.callee, this.args, this.kwargs);
  final Expr callee;
  final List<Expr> args;
  final Map<String, Expr> kwargs;
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
  const WhileStmt(super.line, this.condition, this.conditionText, this.body);
  final Expr condition;
  final String conditionText;
  final List<Stmt> body;
}

class ForStmt extends Stmt {
  const ForStmt(super.line, this.targets, this.iterable, this.body);
  final List<String> targets;
  final Expr iterable;
  final List<Stmt> body;
}

class DefStmt extends Stmt {
  const DefStmt(super.line, this.name, this.params, this.defaults, this.body);
  final String name;
  final List<String> params;
  final Map<String, Expr> defaults;
  final List<Stmt> body;
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
