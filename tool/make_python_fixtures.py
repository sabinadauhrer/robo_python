"""Führt Testprogramme mit echtem Python aus und speichert die Ausgaben als Referenz.

Aufruf: python3 tool/make_python_fixtures.py
Ergebnis: test/python/fixtures.json (wird vom Dart-Test gegen den eigenen Interpreter geprüft)
"""
import contextlib, io, json

PROGRAMS = {
 "print_basics": 'print("Hallo Welt")\nprint(3, 4, "x")\nprint("a", "b", sep="-")\nprint("ohne", end="")\nprint("!")\nprint()',
 "comments": '# Kommentar\nprint("x")  # noch einer\n"""kein print"""',
 "variables": 'x = 5\ny = "Mia"\nx = x + 1\na, b = 1, 2\na, b = b, a\nc = d = 7\nprint(x, y, a, b, c, d)',
 "types": 'print(type(1), type(1.5), type("a"), type(True), type(None))\nprint(type([1]), type((1,)), type({1: 2}), type({1}), type(range(3)))',
 "numbers": 'print(7 / 2, 7 // 2, 7 % 2, 2 ** 10, -7 // 2, -7 % 2)\nprint(10 / 2, 3 * 1.5, 0.1 + 0.2, 1e3, 2.5e-3)\nprint(abs(-3), round(2.5), round(3.5), round(3.14159, 2), max(1, 9, 3), min([4, 2, 8]))',
 "casting": 'print(int("42") + 1, float("3.5"), str(10) + "!", int(3.9), float(2), bool(0), bool("a"), bool([]))',
 "strings_index": 's = "Python"\nprint(s[0], s[-1], s[1:4], s[:2], s[3:], s[::-1], s[::2], len(s))',
 "strings_methods": 't = "  Hallo Welt  "\nprint(t.strip(), t.upper(), t.lower())\nprint("a,b,c".split(","), "x y  z".split(), "-".join(["a", "b"]))\nprint("Banane".replace("a", "o"), "Banane".count("a"), "Banane".find("n"), "Hallo".startswith("Ha"))\nprint("hallo welt".title(), "hALLO".capitalize(), "123".isdigit(), "abc".isalpha())',
 "fstrings": 'name = "Mia"\nalter = 9\npreis = 3.14159\nprint(f"{name} ist {alter} Jahre alt.")\nprint(f"Nächstes Jahr: {alter + 1}")\nprint(f"Preis: {preis:.2f} Euro")\nprint(f"{{Klammern}}", f"{1000000:,}")\nprint("Ich bin {} und {}".format(name, alter), "{0}{0}".format("x"), "{n}!".format(n=5))',
 "string_concat": 'a = "Hallo"\nb = "Welt"\nprint(a + " " + b, a * 3, "a" in a, "H" in a)',
 "booleans": 'print(10 > 9, 10 == 9, 10 < 9, True and False, True or False, not True)\nprint(bool(None), bool(0.0), 3 == 3.0, 1 < 2 < 3, "a" < "b")',
 "if_else": 'x = 15\nif x > 20:\n    print("groß")\nelif x > 10:\n    print("mittel")\nelse:\n    print("klein")\nif x: print("kurz")\nprint("A") if x > 100 else print("B")\nergebnis = "ja" if x % 2 == 1 else "nein"\nprint(ergebnis)',
 "nested_if": 'a = 5\nb = 3\nif a > 0:\n    if b > 0:\n        print("beide positiv")\n    else:\n        print("nur a")\nif a > 2 and b > 2:\n    print("und")\nif not a == 4:\n    print("nicht")',
 "while_loop": 'i = 1\nwhile i < 6:\n    print(i)\n    i += 1\nprint("fertig", i)',
 "while_break_continue": 'i = 0\nwhile True:\n    i += 1\n    if i == 3:\n        continue\n    if i > 5:\n        break\n    print(i)',
 "for_loops": 'for f in ["Apfel", "Kiwi"]:\n    print(f)\nfor c in "abc":\n    print(c, end=" ")\nprint()\nfor i in range(2, 10, 3):\n    print(i)\nfor i in range(3):\n    if i == 1:\n        break\n    print("i", i)',
 "nested_for": 'for a in range(1, 3):\n    for b in range(1, 3):\n        print(a * b, end=" ")\nprint()',
 "lists": 'l = ["a", "b", "c"]\nprint(l, len(l), l[1], l[-1], l[0:2])\nl[1] = "x"\nl.append("d")\nl.insert(0, "z")\nprint(l)\nl.remove("x")\nprint(l.pop(), l.pop(0), l)\nl.extend([1, 2])\nprint(l, "a" in l, l.index("a"), l.count(1))',
 "list_sort": 'z = [3, 1, 2]\nz.sort()\nprint(z)\nz.sort(reverse=True)\nprint(z)\nw = ["b", "A", "c"]\nprint(sorted(w), sorted(w, key=str.lower) if False else sorted(w))\nz.reverse()\nprint(z, z.copy(), sum(z))\nz.clear()\nprint(z)',
 "list_loop_comp": 'n = [1, 2, 3, 4]\nq = [x * x for x in n]\ng = [x for x in n if x % 2 == 0]\nprint(q, g)\nfor i, v in enumerate(["a", "b"]):\n    print(i, v)\nprint(list(range(5)), [0] * 3, [1, 2] + [3])\ndel n[0]\nprint(n)',
 "tuples": 't = ("a", "b", "c", "a")\nprint(t, t[1], len(t), t.count("a"), t.index("b"))\nx, y, z, w = t\nprint(x, w)\none = (5,)\nprint(one, type(one))\nl = list(t)\nl[0] = "z"\nt = tuple(l)\nprint(t)',
 "sets": 's = {"apfel"}\ns.add("kiwi")\ns.add("apfel")\nprint(len(s), "kiwi" in s, "mango" in s)\ns.discard("kiwi")\nprint(s)\nprint(set(), len({1, 2, 2, 3}))',
 "dicts": 'auto = {"marke": "Ford", "jahr": 1964}\nprint(auto["marke"], auto.get("farbe"), auto.get("farbe", "?"), len(auto))\nauto["jahr"] = 2020\nauto["farbe"] = "rot"\nprint(auto)\nprint(auto.keys())\nprint(auto.values())\nprint(auto.items())\nprint("marke" in auto)\nauto.pop("farbe")\nauto.update({"jahr": 1999})\nprint(auto)\nfor k in auto:\n    print(k)\nfor k, v in auto.items():\n    print(k, "=", v)\ndel auto["jahr"]\nprint(auto)',
 "dict_multiline": 'person = {\n    "name": "Ali",\n    "alter": 10,\n}\nprint(person["name"], person)\nleer = {}\nleer["x"] = 1\nprint(leer, dict(a=1))',
 "functions": 'def hallo():\n    print("Hallo!")\n\ndef gruss(name, gruss="Hi"):\n    return gruss + " " + name\n\nhallo()\nprint(gruss("Mia"))\nprint(gruss("Tom", "Moin"))\nprint(gruss(gruss="Hey", name="Lu"))\n\ndef summe(a, b):\n    ergebnis = a + b\n    return ergebnis\nx = summe(2, 3)\nprint(x, summe(summe(1, 1), 1))\ndef nichts():\n    pass\nprint(nichts())',
 "recursion": 'def fak(n):\n    if n <= 1:\n        return 1\n    return n * fak(n - 1)\nprint(fak(5))',
 "scope_global": 'x = 300\ndef f():\n    x = 200\n    print(x)\nf()\nprint(x)\ndef g():\n    global x\n    x = 5\ng()\nprint(x)',
 "lambda": 'mal2 = lambda a: a * 2\nadd = lambda a, b: a + b\nprint(mal2(5), add(2, 3))\ndef macher(n):\n    return lambda a: a * n\nverdoppler = macher(2)\nprint(verdoppler(11))\nprint(sorted(["bb", "a", "ccc"], key=lambda s: len(s)))\nprint(list(map(lambda x: x + 1, [1, 2])), list(filter(lambda x: x > 1, [1, 2, 3])))',
 "iterators": 't = ("Apfel", "Kiwi")\nit = iter(t)\nprint(next(it))\nprint(next(it))\ns = iter("ab")\nprint(next(s), next(s))\nfor x in iter([1, 2]):\n    print(x)',
 "misc_builtins": 'print(list(zip([1, 2], ["a", "b"])), list(reversed([1, 2, 3])), isinstance(5, int), isinstance("x", (int, float)))\nprint(len(range(0, 10, 3)), list(range(10, 0, -3)), range(5))',
 "repr_nested": 'print([1, "a", [2, None], (3,), {"k": [True]}])\nprint(("x",), str([1.0, 2.5]), repr("it\'s"))',
 "augassign": 'x = 10\nx -= 3\nx *= 2\nx /= 4\nprint(x)\ny = 7\ny //= 2\ny %= 2\ny **= 3\nprint(y)\ns = "a"\ns += "b"\nprint(s)',
}

ERRORS = {
 "err_name": ('print(x)', 'NameError', 1),
 "err_indent_missing": ('for i in range(3):\nprint(i)', 'IndentationError', 2),
 "err_indent_unexpected": ('x = 1\n    print(x)', 'IndentationError', 2),
 "err_type_concat": ('alter = 9\nprint("Alter: " + alter)', 'TypeError', 2),
 "err_index": ('l = [1, 2]\nprint(l[5])', 'IndexError', 2),
 "err_key": ('d = {"a": 1}\nprint(d["b"])', 'KeyError', 2),
 "err_zero": ('print(5 / 0)', 'ZeroDivisionError', 1),
 "err_value_int": ('int("abc")', 'ValueError', 1),
 "err_colon": ('if True\n    print(1)', 'SyntaxError', 1),
 "err_stop": ('it = iter([1])\nnext(it)\nnext(it)', 'StopIteration', 3),
 "err_attr": ('x = 5\nx.append(1)', 'AttributeError', 2),
 "err_tuple_change": ('t = (1, 2)\nt[0] = 5', 'TypeError', 2),
 "err_unbound": ('x = 1\ndef f():\n    x += 1\nf()', 'UnboundLocalError', 3),
 "err_args": ('def f(a):\n    return a\nf()', 'TypeError', 3),
}

fixtures = []
for name, code in PROGRAMS.items():
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf):
        exec(compile(code, name, 'exec'), {})
    out = buf.getvalue()
    fixtures.append({"name": name, "code": code, "output": out[:-1] if out.endswith("\n") else out})
for name, (code, err, line) in ERRORS.items():
    try:
        with contextlib.redirect_stdout(io.StringIO()):
            exec(compile(code, name, 'exec'), {})
        raise SystemExit(f"{name}: kein Fehler!")
    except SystemExit:
        raise
    except BaseException as e:
        assert type(e).__name__ == err, (name, type(e).__name__)
    fixtures.append({"name": name, "code": code, "error": err, "line": line})

with open('test/python/fixtures.json', 'w') as f:
    json.dump(fixtures, f, ensure_ascii=False, indent=1)
print(len(fixtures), 'Fixtures geschrieben')
