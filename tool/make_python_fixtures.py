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

 # ---- Erweiterungen (Klassen, Fehler, Module, ...)
 "classes_basic": 'class Hund:\n    art = "Säugetier"\n    def __init__(self, name, alter):\n        self.name = name\n        self.alter = alter\n    def bellen(self):\n        return self.name + " sagt Wuff"\n    def __str__(self):\n        return f"{self.name} ({self.alter})"\nh = Hund("Bello", 3)\nprint(h.name, h.alter, h.art, Hund.art)\nprint(h.bellen())\nprint(h)\nprint(str(h), f"{h}")\nh.alter = 4\nprint(h.alter)\ndel h.alter\nprint(hasattr(h, "alter"), hasattr(h, "name"))\nprint(type(h), type(h).__name__, isinstance(h, Hund))',
 "inheritance": 'class Person:\n    def __init__(self, vorname, nachname):\n        self.vorname = vorname\n        self.nachname = nachname\n    def gruss(self):\n        print("Hallo,", self.vorname, self.nachname)\nclass Schueler(Person):\n    def __init__(self, vorname, nachname, jahr):\n        super().__init__(vorname, nachname)\n        self.jahr = jahr\n    def gruss(self):\n        super().gruss()\n        print("Abschluss:", self.jahr)\nclass Lehrer(Person):\n    pass\ns = Schueler("Mia", "Berg", 2030)\ns.gruss()\nLehrer("Tom", "Klein").gruss()\nprint(isinstance(s, Person), issubclass(Schueler, Person), issubclass(Person, Schueler))\nclass Alt(Person):\n    def __init__(self, v, n):\n        Person.__init__(self, v, n)\nAlt("A", "B").gruss()',
 "polymorphism": 'class Auto:\n    def bewegen(self):\n        print("Fahren!")\nclass Boot:\n    def bewegen(self):\n        print("Segeln!")\nclass Flugzeug:\n    def bewegen(self):\n        print("Fliegen!")\nfor x in (Auto(), Boot(), Flugzeug()):\n    x.bewegen()\nprint(len("Hallo"), len([1, 2]), len({"a": 1}))',
 "encapsulation": 'class Konto:\n    def __init__(self, stand):\n        self.__stand = stand\n        self._hinweis = "intern"\n    def stand(self):\n        return self.__stand\n    def einzahlen(self, b):\n        if b > 0:\n            self.__stand += b\nk = Konto(100)\nk.einzahlen(50)\nk.einzahlen(-5)\nprint(k.stand(), k._hinweis)\ntry:\n    print(k.__stand)\nexcept AttributeError:\n    print("privat!")',
 "inner_class": 'class Aussen:\n    def __init__(self):\n        self.name = "außen"\n    class Innen:\n        def __init__(self):\n            self.name = "innen"\n        def zeige(self):\n            print("Ich bin", self.name)\na = Aussen()\ni = a.Innen()\ni.zeige()\nj = Aussen.Innen()\nprint(j.name, a.name)',
 "class_counter": 'class Zaehler:\n    anzahl = 0\n    def __init__(self):\n        Zaehler.anzahl += 1\nZaehler()\nZaehler()\nprint(Zaehler.anzahl)\nclass Leer:\n    pass\nx = Leer()\nx.farbe = "blau"\nprint(x.farbe)',
 "iterator_class": 'class Zahlen:\n    def __iter__(self):\n        self.a = 1\n        return self\n    def __next__(self):\n        if self.a <= 4:\n            x = self.a\n            self.a += 1\n            return x\n        raise StopIteration\nfor z in Zahlen():\n    print(z, end=" ")\nprint()\nit = iter(Zahlen())\nprint(next(it), next(it))\nprint(list(Zahlen()), sum(Zahlen()))',
 "try_except": 'try:\n    print(x)\nexcept NameError:\n    print("x fehlt")\nexcept:\n    print("anderer Fehler")\ntry:\n    print("ok")\nexcept:\n    print("nein")\nelse:\n    print("kein Fehler")\nfinally:\n    print("immer")\ntry:\n    1 / 0\nexcept (ValueError, ZeroDivisionError):\n    print("gefangen")\ntry:\n    int("abc")\nexcept ValueError as e:\n    print(type(e).__name__)\ntry:\n    [1][5]\nexcept LookupError:\n    print("lookup")\ntry:\n    {}["k"]\nexcept Exception as e:\n    print(type(e).__name__, isinstance(e, KeyError))',
 "raise": 'def pruefe(x):\n    if x < 0:\n        raise ValueError("Nur positive Zahlen!")\n    return x\ntry:\n    pruefe(-1)\nexcept ValueError as e:\n    print("Fehler:", e)\n    print(e.args)\nclass ZuKlein(Exception):\n    pass\ntry:\n    raise ZuKlein("winzig")\nexcept Exception as e:\n    print(type(e).__name__, e, isinstance(e, ZuKlein))\nclass MeinFehler(Exception):\n    def __init__(self, wert):\n        super().__init__(f"Wert {wert} ist falsch")\n        self.wert = wert\ntry:\n    raise MeinFehler(7)\nexcept MeinFehler as e:\n    print(e, e.wert)\ntry:\n    try:\n        raise TypeError("innen")\n    except TypeError:\n        print("weiter")\n        raise\nexcept TypeError as e:\n    print("außen:", e)\ndef f():\n    try:\n        return "aus try"\n    finally:\n        print("finally zuerst")\nprint(f())',
 "match_case": 'def tag(n):\n    match n:\n        case 1:\n            return "Montag"\n        case 2 | 3:\n            return "Di/Mi"\n        case 6 | 7:\n            return "Wochenende"\n        case x if x > 7:\n            return "zu groß"\n        case _:\n            return "anderer Tag"\nfor n in [1, 3, 7, 9, 5]:\n    print(tag(n))\nbefehl = "start"\nmatch befehl:\n    case "start":\n        print("Los!")\n    case "stop":\n        print("Halt!")',
 "args_kwargs": 'def kinder(*kids):\n    print("Das jüngste Kind ist", kids[2], len(kids))\nkinder("Emil", "Tobias", "Linus")\ndef kind(**kid):\n    print("Nachname:", kid["nachname"], kid)\nkind(vorname="Tobias", nachname="Refsnes")\ndef alles(a, *rest, b=2, **extra):\n    print(a, rest, b, extra)\nalles(1)\nalles(1, 2, 3, b=4, c=5)\nwerte = [1, 2, 3]\nprint(*werte)\nprint(*werte, sep="-")\ndef summe(x, y, z):\n    return x + y + z\nprint(summe(*werte), summe(**{"x": 1, "y": 2, "z": 3}))\ndef nur_name(*, x):\n    print(x)\nnur_name(x=3)\ndef nur_pos(x, /):\n    print(x)\nnur_pos(4)',
 "decorators": 'def gross(f):\n    def innen():\n        return f().upper()\n    return innen\n@gross\ndef hallo():\n    return "hallo sally"\nprint(hallo())\ndef logge(f):\n    def wrapper(*args, **kwargs):\n        print("Aufruf von", f.__name__, args)\n        return f(*args, **kwargs)\n    return wrapper\n@logge\ndef plus(a, b):\n    return a + b\nprint(plus(2, 3))\ndef zweimal(f):\n    def w(x):\n        return f(f(x))\n    return w\n@zweimal\n@zweimal\ndef inc(x):\n    return x + 1\nprint(inc(0))',
 "generators": 'def zaehle(n):\n    i = 1\n    while i <= n:\n        yield i\n        i += 1\nfor x in zaehle(3):\n    print(x)\ng = zaehle(2)\nprint(next(g), next(g))\nprint(list(zaehle(4)), sum(zaehle(4)))\nq = (x * x for x in range(4))\nprint(list(q))\nprint(sum(x for x in range(5)), max(len(w) for w in ["a", "abc"]))\ndef fib():\n    a, b = 0, 1\n    for _ in range(7):\n        yield a\n        a, b = b, a + b\nprint(list(fib()))',
 "scope_nested": 'def aussen():\n    x = "lokal"\n    def innen():\n        print(x)\n    innen()\naussen()\ndef zaehler():\n    n = 0\n    def plus():\n        nonlocal n\n        n += 1\n        return n\n    plus()\n    return plus()\nprint(zaehler())\ndef macher():\n    a = 1\n    def m1():\n        def m2():\n            return a + 1\n        return m2()\n    return m1()\nprint(macher())',
 "comprehensions": 'print({x: x * x for x in range(4)}, {x % 3 for x in range(6)})\nprint([(a, b) for a in range(2) for b in range(2)])\nprint([x for x in range(10) if x % 2 == 0 if x > 3])\nm = [[1, 2], [3, 4]]\nprint([v for row in m for v in row])\nprint([x if x > 1 else 0 for x in [1, 2, 3]])\nprint({k: v for k, v in [("a", 1), ("b", 2)]})',
 "unpack_star": 'obst = ("Apfel", "Banane", "Kirsche", "Mango")\n(gruen, gelb, *rot) = obst\nprint(gruen, gelb, rot)\n(a, *mitte, z) = obst\nprint(a, mitte, z)\nx, y = [1, 2]\nprint([*obst[:2], "Kiwi"])\nl = [1, 2, 3, 4]\nl[1:3] = ["x"]\nprint(l)\nl[1:2] = ["a", "b"]\nprint(l)\ndel l[0:2]\nprint(l)',
 "bitwise": 'print(6 & 3, 6 | 3, 6 ^ 3, ~6, 6 << 1, 6 >> 1)\nprint(True & False, True | False, True ^ True)\nprint({1, 2, 3} | {3, 4}, {1, 2, 3} & {2, 3, 4}, {1, 2, 3} ^ {3, 4, 5}, {1, 2, 3} - {2})\nx = 5\nx |= 2\nx &= 6\nx ^= 1\nx <<= 2\nprint(x)\nprint(2 + 3 * 4 ** 2, (2 + 3) * 4, 10 - 4 - 3, 2 ** 3 ** 2, 5 > 3 and 2 > 1 or False, not 1 == 2)\nprint(bin(10), hex(255), oct(8), 0 == 0.0, "is")',
 "sets_more": 's = {1, 2, 3}\nt = {3, 4, 5}\nprint(s.union(t), s.intersection(t), s.difference(t), s.symmetric_difference(t))\nprint({1, 2}.issubset(s), s.issuperset({1}), s.isdisjoint({7}))\nf = frozenset([1, 2, 3])\nprint(f, type(f), 2 in f, len(f))\ntry:\n    f.add(4)\nexcept AttributeError:\n    print("unveränderlich")\nu = {1, 2}\nu.update([3, 4])\nu.intersection_update({2, 3, 4, 9})\nprint(u)\nv = {1, 2, 3}\nv.difference_update({1})\nprint(v, v.copy(), {1, 2} <= {1, 2, 3}, {1, 2} < {1, 2})',
 "strings_more": 'print("hallo".center(11, "*"), "ab".ljust(4, "."), "ab".rjust(4), "42".zfill(5), "-7".zfill(4))\nprint("Hallo Welt".swapcase(), "abc123".isalnum(), "   ".isspace(), "Hallo Welt".istitle(), "Straße".casefold())\nprint("a-b-c".partition("-"), "a-b-c".rpartition("-"), "a b c".split(" ", 1), "a b c".rsplit(" ", 1))\nprint("eins\\nzwei".splitlines(), "banane".rfind("n"), "banane".replace("a", "o", 1))\ntext = """Zeile 1\nZeile 2"""\nprint(text)\nprint(len(text), \'Er sagte: "Hi"\', "Tab:\\tEnde", "Back\\\\slash", \'It\\\'s\')\nx = "Hallo"\nprint(x[-4:-1], x[2:], x[:-2])',
 "format_more": 'print("{:>6}|{:<6}|{:^6}|".format("ab", "cd", "ef"))\nprint(f"{42:05d} {3.14159:8.3f} {0.25:.0%} {1234567.891:,.2f} {255:x} {5:b}")\nprint("{name} ist {alter}".format(name="Ida", alter=7), "{1} {0}".format("a", "b"))\nprint(f"{-5:+} {5:+} {7:*^9}", format(3.5, ".1f"), f"{\'hi\':>4}")\npreis = 49\nprint(f"Preis: {preis:.2f} Euro")',
 "builtins_more": 'print(pow(2, 5), pow(2, 5, 3), any([0, 1]), all([1, 0]), divmod(17, 5))\nprint(max(["aa", "b"], key=len), min([3, 1, 2]), sorted([3, 1, 2], reverse=True))\nprint(callable(len), callable(5), getattr("x", "upper")(), dict.fromkeys(["a", "b"], 0))\nprint(round(7.456, 1), abs(-2.5), int(True), float("1e2"), str(None))',
 "math_module": 'import math\nprint(math.sqrt(64), math.ceil(1.4), math.floor(1.4), math.pi)\nprint(math.pow(2, 3), math.factorial(5), math.gcd(12, 18), math.fabs(-3))\nfrom math import sqrt, pi as PI\nprint(sqrt(9), round(PI, 2))\nimport math as m\nprint(m.floor(-1.5), m.trunc(-1.5), m.isqrt(10))',
 "json_module": 'import json\nx = \'{ "name":"John", "age":30, "city":"New York"}\'\ny = json.loads(x)\nprint(y["age"], y)\nd = {"name": "John", "age": 30, "married": True, "divorced": False, "children": ("Ann", "Billy"), "pets": None, "cars": [{"model": "BMW 230", "mpg": 27.5}]}\nprint(json.dumps(d))\nprint(json.dumps(d, indent=4))\nprint(json.dumps({"b": 1, "a": 2}, sort_keys=True), json.dumps([1, 2], separators=(",", ":")))\nprint(json.dumps({"name": "Jöhn"}), json.dumps("text"), json.dumps(3.0), json.dumps(None))\nprint(json.loads("[1, 2.5, true, null]"))',
 "datetime_module": 'import datetime\nx = datetime.datetime(2020, 5, 17)\nprint(x)\nprint(x.year, x.month, x.day, x.strftime("%A"), x.strftime("%B"), x.strftime("%d.%m.%Y"))\ny = datetime.datetime(2018, 6, 1, 14, 5)\nprint(y.strftime("%a %b %y %H:%M %p %I %j"), y)\nd = datetime.date(2024, 12, 24)\nprint(d, d.strftime("%A"), d.weekday(), d.year)\nprint(repr(d), repr(y))\nprint(datetime.date(2024, 1, 1) < datetime.date(2024, 6, 1))',
 "re_module": 'import re\ntxt = "The rain in Spain"\nx = re.search("^The.*Spain$", txt)\nprint(bool(x))\nprint(re.findall("ai", txt))\nprint(re.findall("Portugal", txt))\nm = re.search("\\\\s", txt)\nprint("Erstes Leerzeichen bei:", m.start())\nprint(re.split("\\\\s", txt), re.split("\\\\s", txt, 1))\nprint(re.sub("\\\\s", "9", txt), re.sub("\\\\s", "9", txt, 2))\nm = re.search(r"\\bS\\w+", txt)\nprint(m.span(), m.string, m.group())\nprint(m)\nprint(re.search("xyz", txt))\nprint(re.findall(r"(\\w)(\\d)", "a1 b2"), re.findall(r"\\d+", "12 Äpfel und 7 Birnen"))',
 "with_files": 'with open("demo.txt", "w") as f:\n    f.write("Hallo!\\nZeile zwei\\n")\nwith open("demo.txt", "a") as f:\n    f.write("Ende")\nwith open("demo.txt") as f:\n    print(f.read())\nf = open("demo.txt", "r")\nprint(f.readline(), end="")\nprint(f.read(4))\nf.close()\nprint(f.closed)\nwith open("demo.txt") as f:\n    for zeile in f:\n        print(zeile.strip())\nwith open("demo.txt") as f:\n    print(f.readlines())\nimport os\nprint(os.path.exists("demo.txt"))\nos.remove("demo.txt")\nprint(os.path.exists("demo.txt"))\ntry:\n    open("weg.txt")\nexcept FileNotFoundError:\n    print("nicht da")\nf = open("neu.txt", "x")\nf.close()\ntry:\n    open("neu.txt", "x")\nexcept FileExistsError:\n    print("gibt es schon")\nos.remove("neu.txt")',
 "none_misc": 'x = None\nprint(x, type(x), x is None, x is not None, x == None, bool(x))\ndef f():\n    pass\nprint(f() is None)\nassert 1 + 1 == 2\nprint("""mehrere\nZeilen""")\n"""\nDas ist ein\nKommentar\n"""\nprint("weiter")',
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
 "err_raise": ('x = -1\nif x < 0:\n    raise Exception("Keine Zahlen unter 0")', 'Exception', 3),
 "err_assert": ('assert 1 > 2, "falsch"', 'AssertionError', 1),
 "err_private": ('class A:\n    def __init__(self):\n        self.__x = 1\na = A()\nprint(a.__x)', 'AttributeError', 5),
 "err_no_attr": ('class A:\n    pass\nprint(A().y)', 'AttributeError', 3),
 "err_init_args": ('class A:\n    pass\nA(1)', 'TypeError', 3),
 "err_frozen": ('f = frozenset([1])\nf.add(2)', 'AttributeError', 2),
 "err_file": ('open("fehlt.txt")', 'FileNotFoundError', 1),
 "err_module": ('import numpy', 'ModuleNotFoundError', 1),
 "err_kwonly": ('def f(*, x):\n    pass\nf(1)', 'TypeError', 3),
 "err_posonly": ('def f(x, /):\n    pass\nf(x=1)', 'TypeError', 3),
 "err_uncaught_in_try": ('try:\n    1 / 0\nexcept ValueError:\n    print("nein")', 'ZeroDivisionError', 2),
}

import os, tempfile
os.chdir(tempfile.mkdtemp())
OUTFILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'test', 'python', 'fixtures.json')

# Python < 3.10 kennt match noch nicht: erwartete Ausgabe von Hand (wird ab 3.10 geprüft).
import sys
MANUAL = {"match_case": "Montag\nDi/Mi\nWochenende\nzu groß\nanderer Tag\nLos!"}

fixtures = []
for name, code in PROGRAMS.items():
    if name in MANUAL and sys.version_info < (3, 10):
        fixtures.append({"name": name, "code": code, "output": MANUAL[name]})
        continue
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf):
        exec(compile(code, name, 'exec'), {'__name__': '__main__'})
    out = buf.getvalue()
    if name in MANUAL:
        assert out.rstrip("\n") == MANUAL[name], (name, out)
    fixtures.append({"name": name, "code": code, "output": out[:-1] if out.endswith("\n") else out})
for name, (code, err, line) in ERRORS.items():
    try:
        with contextlib.redirect_stdout(io.StringIO()):
            exec(compile(code, name, 'exec'), {'__name__': '__main__'})
        raise SystemExit(f"{name}: kein Fehler!")
    except SystemExit:
        raise
    except BaseException as e:
        assert type(e).__name__ == err, (name, type(e).__name__)
    fixtures.append({"name": name, "code": code, "error": err, "line": line})

with open(OUTFILE, 'w') as f:
    json.dump(fixtures, f, ensure_ascii=False, indent=1)
print(len(fixtures), 'Fixtures geschrieben')
