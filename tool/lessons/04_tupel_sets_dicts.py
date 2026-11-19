# Kapitel Tupel, Sets, Dictionaries (neue Inseln)
# Hinweis: Sets mit Texten gibt Python in zufälliger Reihenfolge aus – deshalb hier nur Zahlen-Sets ausgeben oder sorted() benutzen.

lesson('tuple_access', 'Auf Tupel zugreifen', 'search',
       'Auf Tupel greifst du genau wie auf Listen zu: mit Index in eckigen Klammern, mit negativen Zahlen von hinten '
       'und mit Ausschnitten wie tupel[1:3]. Ein Ausschnitt eines Tupels ist wieder ein Tupel.', [
    fill('Gib das zweite Element des Tupels aus.',
         'obst = ("Apfel", "Banane", "Kirsche")\nprint(obst[' + B + '])', ['1'],
         'Auch bei Tupeln beginnt die Zählung bei 0. Das zweite Element hat also den Index 1.'),
    choice('Was gibt dieser Code aus?',
           'obst = ("Apfel", "Banane", "Kirsche")\nprint(obst[-1])', ['Kirsche', 'Apfel', '-1'], 0,
           '-1 ist das letzte Element.'),
    choice('Was gibt dieser Code aus?',
           'obst = ("Apfel", "Banane", "Kirsche", "Orange", "Kiwi")\nprint(obst[2:5])', ["('Kirsche', 'Orange', 'Kiwi')", "['Kirsche', 'Orange', 'Kiwi']", "('Banane', 'Kirsche', 'Orange')"], 0,
           'Ein Ausschnitt eines Tupels ist wieder ein Tupel – erkennbar an den runden Klammern.'),
    fill('Prüfe, ob „Apfel“ im Tupel ist.',
         'obst = ("Apfel", "Banane")\nprint("Apfel" ' + B + ' obst)', ['in'],
         'in funktioniert bei allen Sammlungen – auch bei Tupeln.'),
    choice('Was gibt dieser Code aus?',
           'obst = ("Apfel", "Banane", "Kirsche")\nprint(obst[:2])', ["('Apfel', 'Banane')", "('Apfel',)", "('Kirsche',)"], 0,
           'Ohne Start beginnt der Ausschnitt bei Index 0 und endet vor Index 2.'),
])

lesson('tuple_update', 'Tupel „ändern“', 'published_with_changes',
       'Tupel sind unveränderlich – man kann kein Element ersetzen, anhängen oder löschen. '
       'Der Trick: Wandle das Tupel mit list() in eine Liste um, ändere die Liste und mache mit tuple() wieder ein Tupel daraus. '
       'Oder verbinde zwei Tupel mit + zu einem neuen.', [
    choice('Was passiert bei diesem Code?',
           'obst = ("Apfel", "Banane")\nobst[0] = "Kiwi"', ['TypeError: Tupel sind unveränderlich', 'Kiwi ersetzt Apfel', 'Es passiert nichts'], 0,
           'Tupel kann man nicht verändern. Python meldet einen TypeError.',
           is_output=False),
    fill('Wandle das Tupel zuerst in eine Liste um.',
         'x = ("Apfel", "Banane", "Kirsche")\ny = ' + B + '(x)\ny[1] = "Kiwi"\nx = tuple(y)\nprint(x)', ['list'],
         'Listen sind veränderbar. Also: Tupel → Liste, ändern, Liste → Tupel.',
         {2: 'Aus dem Tupel wird eine Liste.', 3: 'Die Liste darf man ändern.', 4: 'Und wieder zurück in ein Tupel.'}),
    fill('Verbinde die Tupel, um ein Element „hinzuzufügen“.',
         'obst = ("Apfel", "Banane")\nneu = ("Orange",)\nobst = obst ' + B + ' neu\nprint(obst)', ['+'],
         'Mit + entsteht ein neues Tupel aus beiden. Achtung: Ein Tupel mit einem Element braucht ein Komma: ("Orange",).'),
    choice('Was gibt dieser Code aus?',
           'x = ("Apfel",)\ny = ("Apfel")\nprint(type(x))\nprint(type(y))', ["<class 'tuple'>\n<class 'str'>", "<class 'tuple'>\n<class 'tuple'>", "<class 'str'>\n<class 'str'>"], 0,
           'Erst das Komma macht ein Tupel! Ohne Komma sind die Klammern nur normale Klammern um einen Text.'),
    choice('Was gibt dieser Code aus?',
           'x = ("Apfel", "Banane", "Kirsche")\ny = list(x)\ny.remove("Apfel")\nx = tuple(y)\nprint(x)', ["('Banane', 'Kirsche')", "('Apfel', 'Banane', 'Kirsche')", "['Banane', 'Kirsche']"], 0,
           'Auch Entfernen geht nur über den Umweg Liste.'),
])

lesson('tuple_unpack', 'Tupel auspacken', 'unarchive',
       'Beim Erstellen eines Tupels „packt“ man Werte hinein. Beim Auspacken verteilt man sie auf Variablen: (a, b, c) = tupel. '
       'Gibt es mehr Werte als Namen, sammelt ein * vor einem Namen den Rest als Liste ein.', [
    fill('Packe das Tupel in drei Variablen aus.',
         'obst = ("Apfel", "Banane", "Kirsche")\n(gruen, gelb, ' + B + ') = obst\nprint(rot)', ['rot'],
         'Jede Variable bekommt der Reihe nach einen Wert: gruen = Apfel, gelb = Banane, rot = Kirsche.'),
    choice('Was gibt dieser Code aus?',
           'obst = ("Apfel", "Banane", "Kirsche", "Erdbeere")\n(gruen, gelb, *rot) = obst\nprint(rot)', ["['Kirsche', 'Erdbeere']", 'Kirsche', "('Kirsche', 'Erdbeere')"], 0,
           'Der * sammelt alle übrigen Werte ein – als Liste.',
           {2: '*rot bekommt alles, was übrig bleibt.'}),
    fill('Sammle mit dem Sternchen die mittleren Werte ein.',
         'obst = ("Apfel", "Mango", "Papaya", "Kirsche")\n(gruen, ' + B + 'tropisch, rot) = obst\nprint(tropisch)', ['*'],
         'Der * darf auch in der Mitte stehen. Dann bekommen die anderen Namen ihre Werte, und der Rest landet in der Mitte.'),
    choice('Was gibt dieser Code aus?',
           'punkt = (3, 7)\nx, y = punkt\nprint(x + y)', ['10', '37', '(3, 7)'], 0,
           'Die Klammern beim Auspacken darf man auch weglassen.'),
    choice('Was passiert bei diesem Code?',
           'a, b = (1, 2, 3)', ['ValueError: zu viele Werte zum Auspacken', 'a = 1, b = 2', 'a = 1, b = (2, 3)'], 0,
           'Ohne * müssen Namen und Werte genau gleich viele sein.',
           is_output=False),
])

lesson('tuple_loop', 'Tupel durchlaufen', 'sync',
       'Tupel durchläufst du wie Listen: mit for x in tupel:, über die Indizes mit range(len(tupel)) oder mit einer while-Schleife.', [
    fill('Gib jedes Element des Tupels aus.',
         'obst = ("Apfel", "Banane", "Kirsche")\n' + B + ' x in obst:\n    print(x)', ['for'],
         'Die for-Schleife holt sich ein Element nach dem anderen.'),
    choice('Was gibt dieser Code aus?',
           'obst = ("Apfel", "Banane")\nfor i in range(len(obst)):\n    print(i, obst[i])', ['0 Apfel\n1 Banane', '1 Apfel\n2 Banane', 'Apfel\nBanane'], 0,
           'range(len(obst)) liefert die Indizes 0 und 1. Damit holt man jedes Element über seine Position.'),
    choice('Was gibt dieser Code aus?',
           'zahlen = (5, 10, 15)\ni = 0\nwhile i < len(zahlen):\n    print(zahlen[i])\n    i += 2', ['5\n15', '5\n10\n15', '10'], 0,
           'i springt in Zweierschritten: 0, dann 2. Bei 4 ist die Bedingung falsch.'),
    choice('Was gibt dieser Code aus?',
           'paare = (("a", 1), ("b", 2))\nfor buchstabe, zahl in paare:\n    print(buchstabe * zahl)', ['a\nbb', 'a1\nb2', 'ab'], 0,
           'Jedes Element ist selbst ein Tupel – es wird direkt in buchstabe und zahl ausgepackt.'),
    order('Ordne die Zeilen, damit alle Zahlen im Tupel addiert werden (Ergebnis 6).',
          ['t = (1, 2, 3)', 'summe = 0', 'for z in t:', '    summe += z', 'print(summe)'],
          'Erst das Tupel und die Summe, dann die Schleife, zum Schluss die Ausgabe.'),
])

lesson('tuple_join', 'Tupel verbinden', 'merge',
       'Zwei Tupel verbindest du mit + zu einem neuen Tupel. Mit * wiederholst du den Inhalt eines Tupels mehrmals.', [
    fill('Verbinde die beiden Tupel.',
         't1 = ("a", "b")\nt2 = (1, 2)\nt3 = t1 ' + B + ' t2\nprint(t3)', ['+'],
         'Mit + entsteht ein neues Tupel – die alten bleiben unverändert.'),
    fill('Verdopple den Inhalt des Tupels.',
         'obst = ("Apfel", "Kiwi")\nmehr = obst ' + B + ' 2\nprint(mehr)', ['*'],
         'Tupel * Zahl wiederholt alle Elemente so oft.'),
    choice('Was gibt dieser Code aus?',
           'print((1, 2) + (3,))', ['(1, 2, 3)', '(1, 2, (3,))', '(4, 2)'], 0,
           'Die Elemente werden einfach aneinandergereiht.'),
    choice('Was gibt dieser Code aus?',
           'print(len((0,) * 4))', ['4', '1', '0'], 0,
           '(0,) * 4 ergibt (0, 0, 0, 0) – also 4 Elemente.'),
    choice('Was passiert bei diesem Code?',
           't = (1, 2)\nt.append(3)', ['AttributeError: Tupel haben kein append', '(1, 2, 3)', 'Es passiert nichts'], 0,
           'Tupel haben keine Methoden zum Verändern. Statt append() benutzt man t = t + (3,).',
           is_output=False),
])

lesson('tuple_methods', 'Tupel-Methoden', 'construction',
       'Tupel haben nur zwei Methoden: count() zählt, wie oft ein Wert vorkommt, und index() sagt, an welcher Position er zum ersten Mal steht.', [
    fill('Zähle, wie oft die 5 vorkommt.',
         't = (1, 3, 7, 8, 7, 5, 4, 6, 8, 5)\nprint(t.' + B + '(5))', ['count'],
         'count() zählt alle Vorkommen eines Werts.'),
    fill('Finde die Position der ersten 8.',
         't = (1, 3, 7, 8, 7, 5, 4, 6, 8, 5)\nprint(t.' + B + '(8))', ['index'],
         'index() liefert die Position des ERSTEN Treffers. Die erste 8 steht bei Index 3.'),
    choice('Was gibt dieser Code aus?',
           'farben = ("rot", "blau", "rot", "grün")\nprint(farben.count("rot"), farben.index("grün"))', ['2 3', '1 3', '2 4'], 0,
           'rot kommt zweimal vor. grün steht an Position 3 (gezählt ab 0).'),
    choice('Was passiert bei diesem Code?',
           't = (1, 2, 3)\nprint(t.index(9))', ['ValueError: 9 ist nicht im Tupel', '-1', 'None'], 0,
           'Anders als find() bei Texten meldet index() einen Fehler, wenn der Wert fehlt.',
           is_output=False),
    choice('Was gibt dieser Code aus?',
           't = (4, 1, 3)\nprint(sorted(t))\nprint(max(t), min(t), sum(t))', ['[1, 3, 4]\n4 1 8', '(1, 3, 4)\n4 1 8', '[4, 3, 1]\n4 1 8'], 0,
           'Eingebaute Funktionen wie sorted(), max(), min() und sum() funktionieren auch mit Tupeln. sorted() liefert aber eine Liste.'),
])

# ---------------------------------------------------------------- Sets

lesson('set_access', 'Auf Sets zugreifen', 'search',
       'Ein Set hat keine Reihenfolge und deshalb keinen Index – set[0] geht nicht. '
       'Du kannst aber mit einer for-Schleife alle Elemente durchgehen oder mit in prüfen, ob ein Wert drin ist.', [
    fill('Prüfe, ob „Banane“ im Set ist.',
         'obst = {"Apfel", "Banane", "Kirsche"}\nprint("Banane" ' + B + ' obst)', ['in'],
         'in ist bei Sets besonders schnell – genau dafür sind Sets gemacht.'),
    choice('Was passiert bei diesem Code?',
           'obst = {"Apfel", "Banane"}\nprint(obst[0])', ['TypeError: Sets haben keinen Index', 'Apfel', 'Banane'], 0,
           'Ein Set hat keine feste Reihenfolge. Deshalb gibt es auch kein „erstes“ Element mit Index 0.',
           is_output=False),
    choice('Was gibt dieser Code aus?',
           'obst = {"Apfel", "Banane"}\nprint("Kiwi" not in obst)', ['True', 'False', 'Kiwi'], 0,
           'not in ist das Gegenteil von in: Kiwi ist NICHT im Set → True.'),
    choice('Was gibt dieser Code aus?',
           'zahlen = {3, 1, 2}\nfor z in sorted(zahlen):\n    print(z)', ['1\n2\n3', '3\n1\n2', '3\n2\n1'], 0,
           'Weil Sets keine Reihenfolge haben, sortiert man sie mit sorted(), wenn man eine feste Reihenfolge braucht.'),
    fill('Finde heraus, wie viele Elemente im Set sind.',
         'farben = {"rot", "grün", "blau", "rot"}\nprint(' + B + '(farben))', ['len'],
         'Doppelte Werte zählen in einem Set nur einmal – deshalb ist die Länge 3.'),
])

lesson('set_add', 'Zu Sets hinzufügen', 'add_circle',
       'Mit add() fügst du EIN Element hinzu. Mit update() kommen alle Elemente aus einer anderen Sammlung dazu. '
       'Ist ein Wert schon drin, passiert nichts – Sets haben keine Doppelten.', [
    fill('Füge die 4 zum Set hinzu.',
         'zahlen = {1, 2, 3}\nzahlen.' + B + '(4)\nprint(zahlen)', ['add'],
         'add() fügt genau ein Element hinzu.'),
    fill('Füge alle Zahlen aus der Liste hinzu.',
         'zahlen = {1, 2}\nzahlen.' + B + '([3, 4, 5])\nprint(zahlen)', ['update'],
         'update() nimmt jede Sammlung (Liste, Tupel, Set) und fügt alle Elemente hinzu.'),
    choice('Was gibt dieser Code aus?',
           'zahlen = {1, 2, 3}\nzahlen.add(2)\nprint(len(zahlen))', ['3', '4', 'Fehler'], 0,
           'Die 2 ist schon im Set. Ein Set speichert jeden Wert nur einmal – die Länge bleibt 3.'),
    choice('Was gibt dieser Code aus?',
           'a = {1, 2}\nb = {3, 4}\na.update(b)\nprint(a)', ['{1, 2, 3, 4}', '{1, 2}', '{3, 4}'], 0,
           'update() verändert a selbst. b bleibt, wie es ist.'),
    choice('Was passiert bei diesem Code?',
           's = {1, 2}\ns.add([3, 4])', ['TypeError: Listen können nicht in ein Set', '{1, 2, 3, 4}', '{1, 2, [3, 4]}'], 0,
           'In einem Set dürfen nur unveränderliche Werte stehen (Zahlen, Texte, Tupel). Eine Liste kann sich ändern – deshalb geht das nicht.',
           is_output=False),
])

lesson('set_remove', 'Aus Sets entfernen', 'remove_circle',
       'remove() entfernt ein Element – fehlt es, gibt es einen Fehler. discard() entfernt es auch, meckert aber nicht, wenn es fehlt. '
       'clear() leert das Set, und del set löscht es ganz.', [
    fill('Entferne die 2 aus dem Set.',
         'zahlen = {1, 2, 3}\nzahlen.' + B + '(2)\nprint(zahlen)', [['remove', 'discard']],
         'remove() und discard() entfernen beide ein Element. Der Unterschied zeigt sich, wenn es nicht da ist.'),
    choice('Was passiert bei diesem Code?',
           'zahlen = {1, 2, 3}\nzahlen.remove(9)', ['KeyError: 9 ist nicht im Set', 'Es passiert nichts', '{1, 2, 3}'], 0,
           'remove() meldet einen Fehler, wenn das Element fehlt.',
           is_output=False),
    choice('Was gibt dieser Code aus?',
           'zahlen = {1, 2, 3}\nzahlen.discard(9)\nprint(zahlen)', ['{1, 2, 3}', 'KeyError', '{1, 2}'], 0,
           'discard() entfernt das Element, falls es da ist. Fehlt es, passiert einfach nichts.'),
    fill('Leere das Set.',
         'zahlen = {1, 2, 3}\nzahlen.' + B + '()\nprint(zahlen)', ['clear'],
         'clear() entfernt alle Elemente. Ein leeres Set wird als set() angezeigt – {} wäre ein leeres Dictionary!'),
    choice('Was gibt dieser Code aus?',
           'zahlen = {5, 6}\nx = zahlen.pop()\nprint(len(zahlen))', ['1', '2', '0'], 0,
           'pop() entfernt ein (beliebiges) Element und gibt es zurück. Danach ist noch eins übrig.'),
])

lesson('set_loop', 'Sets durchlaufen', 'sync',
       'Mit for x in set: gehst du alle Elemente durch. Die Reihenfolge ist dabei nicht festgelegt. '
       'Brauchst du eine feste Reihenfolge, benutze sorted(set).', [
    fill('Gehe alle Elemente des Sets durch.',
         'zahlen = {1, 2, 3}\nfor z ' + B + ' zahlen:\n    print(z)', ['in'],
         'Die for-Schleife funktioniert mit jeder Sammlung.'),
    choice('Was gibt dieser Code aus?',
           'namen = {"Zoe", "Ali", "Max"}\nfor n in sorted(namen):\n    print(n)', ['Ali\nMax\nZoe', 'Zoe\nAli\nMax', 'Zoe\nMax\nAli'], 0,
           'sorted() macht aus dem Set eine sortierte Liste – so ist die Reihenfolge immer gleich.'),
    choice('Was gibt dieser Code aus?',
           'zahlen = {1, 2, 3, 4}\nsumme = 0\nfor z in zahlen:\n    summe += z\nprint(summe)', ['10', '4', '1234'], 0,
           'Beim Addieren ist die Reihenfolge egal – das Ergebnis ist immer 10.'),
    choice('Was gibt dieser Code aus?',
           'woerter = ["hi", "du", "hi", "du", "ok"]\nprint(len(set(woerter)))', ['3', '5', '2'], 0,
           'set() entfernt die Doppelten. Übrig bleiben hi, du und ok.'),
    order('Ordne die Zeilen, damit nur die geraden Zahlen (2, dann 4) erscheinen.',
          ['zahlen = {1, 2, 3, 4}', 'for z in sorted(zahlen):', '    if z % 2 == 0:', '        print(z)'],
          'Die Schleife geht alle Zahlen durch, das if lässt nur gerade Zahlen durch.'),
])

lesson('set_join', 'Sets verbinden', 'join_inner',
       'Sets kann man wie in der Mathematik verbinden: union() bzw. | (alles aus beiden), intersection() bzw. & (nur was in beiden ist), '
       'difference() bzw. - (was nur im ersten ist) und symmetric_difference() bzw. ^ (was nur in einem von beiden ist).', [
    fill('Bilde die Vereinigung beider Sets.',
         'a = {1, 2, 3}\nb = {3, 4}\nprint(a.' + B + '(b))', ['union'],
         'union() liefert ein neues Set mit allen Elementen aus beiden. Die 3 steht nur einmal drin.'),
    choice('Was gibt dieser Code aus?',
           'a = {1, 2, 3}\nb = {2, 3, 4}\nprint(a & b)', ['{2, 3}', '{1, 2, 3, 4}', '{1, 4}'], 0,
           '& ist die Schnittmenge: nur, was in BEIDEN Sets vorkommt.'),
    choice('Was gibt dieser Code aus?',
           'a = {1, 2, 3}\nb = {2, 3, 4}\nprint(a - b)', ['{1}', '{4}', '{1, 4}'], 0,
           '- ist die Differenz: was in a ist, aber nicht in b.'),
    fill('Finde die Zahlen, die nur in EINEM der beiden Sets stehen.',
         'a = {1, 2, 3}\nb = {3, 4, 5}\nprint(a ' + B + ' b)', ['^'],
         '^ (symmetrische Differenz) behält alles, was nicht in beiden gleichzeitig ist. Die 3 fliegt raus.'),
    choice('Was gibt dieser Code aus?',
           'a = {1, 2}\nb = {3, 4}\nprint(a | b)', ['{1, 2, 3, 4}', 'set()', '{1, 2}'], 0,
           '| ist die Kurzform von union().'),
])

lesson('frozenset', 'frozenset', 'ac_unit',
       'Ein frozenset ist ein „eingefrorenes“ Set: Es hat keine Doppelten, aber man kann es nach dem Erstellen nicht mehr ändern. '
       'Man erstellt es mit frozenset(...). Vereinigung, Schnittmenge usw. funktionieren trotzdem – sie liefern ein neues frozenset.', [
    fill('Erstelle ein frozenset aus der Liste.',
         'x = ' + B + '([1, 2, 3])\nprint(x)', ['frozenset'],
         'frozenset() wandelt eine Sammlung in ein unveränderliches Set um.'),
    choice('Was gibt dieser Code aus?',
           'x = frozenset([1, 2, 2, 3])\nprint(len(x), 2 in x)', ['3 True', '4 True', '3 False'], 0,
           'Wie ein normales Set: Doppelte zählen nur einmal, und in funktioniert auch.'),
    choice('Was passiert bei diesem Code?',
           'x = frozenset([1, 2])\nx.add(3)', ['AttributeError: frozenset kann man nicht ändern', 'frozenset({1, 2, 3})', 'Es passiert nichts'], 0,
           'Ein frozenset hat keine Methoden wie add() oder remove() – es ist eingefroren.',
           is_output=False),
    choice('Was gibt dieser Code aus?',
           'a = frozenset([1, 2])\nb = frozenset([2, 3])\nprint(a | b)', ['frozenset({1, 2, 3})', '{1, 2, 3}', 'Fehler'], 0,
           'Verbinden geht trotzdem – das Ergebnis ist ein NEUES frozenset.'),
    fill('Finde heraus, welcher Typ x ist.',
         'x = frozenset([1])\nprint(' + B + '(x))', ['type'],
         'type() verrät den Typ: frozenset.'),
])

lesson('set_methods', 'Set-Methoden', 'construction',
       'Sets können vergleichen: issubset() prüft, ob alle Elemente auch im anderen Set sind (Teilmenge). '
       'issuperset() prüft das Umgekehrte, isdisjoint() prüft, ob sie gar nichts gemeinsam haben. '
       'Und copy() erstellt eine Kopie.', [
    fill('Prüfe, ob a eine Teilmenge von b ist.',
         'a = {1, 2}\nb = {1, 2, 3, 4}\nprint(a.' + B + '(b))', ['issubset'],
         'Alle Elemente von a stecken auch in b – a ist also eine Teilmenge.'),
    choice('Was gibt dieser Code aus?',
           'a = {1, 2, 3}\nprint(a.issuperset({1, 3}))', ['True', 'False', '{1, 3}'], 0,
           'a enthält alle Elemente von {1, 3} – a ist eine Obermenge (superset).'),
    choice('Was gibt dieser Code aus?',
           'a = {1, 2}\nb = {3, 4}\nprint(a.isdisjoint(b))', ['True', 'False', 'set()'], 0,
           'isdisjoint() ist True, wenn die Sets kein einziges gemeinsames Element haben.'),
    fill('Entferne alles aus a, was auch in b vorkommt – direkt in a.',
         'a = {1, 2, 3}\nb = {2}\na.' + B + '(b)\nprint(a)', ['difference_update'],
         'Methoden mit _update verändern das Set selbst, statt ein neues zu liefern.'),
    choice('Was gibt dieser Code aus?',
           'a = {1, 2}\nb = a.copy()\nb.add(3)\nprint(len(a), len(b))', ['2 3', '3 3', '2 2'], 0,
           'copy() erstellt ein unabhängiges Set. Was man zu b hinzufügt, landet nicht in a.'),
])

# ---------------------------------------------------------------- Dictionaries

lesson('dict_access', 'Auf Dictionaries zugreifen', 'search',
       'Werte holst du über ihren Schlüssel: auto["marke"]. Mit get() geht es auch – ohne Fehler, wenn der Schlüssel fehlt. '
       'keys() liefert alle Schlüssel, values() alle Werte und items() alle Paare.', [
    fill('Hole den Wert zum Schlüssel „modell“.',
         'auto = {"marke": "Ford", "modell": "Mustang", "jahr": 1964}\nprint(auto[' + B + '])', [['"modell"', "'modell'"]],
         'In die eckigen Klammern kommt der Schlüssel – als Text in Anführungszeichen.'),
    choice('Was gibt dieser Code aus?',
           'auto = {"marke": "Ford", "jahr": 1964}\nprint(auto.keys())', ["dict_keys(['marke', 'jahr'])", "['Ford', 1964]", "dict_values(['Ford', 1964])"], 0,
           'keys() liefert eine Sicht auf alle Schlüssel.'),
    choice('Was gibt dieser Code aus?',
           'auto = {"marke": "Ford", "jahr": 1964}\nx = auto.values()\nauto["jahr"] = 2020\nprint(x)', ["dict_values(['Ford', 2020])", "dict_values(['Ford', 1964])", "['Ford', 2020]"], 0,
           'values() ist eine lebendige Sicht: Ändert sich das Dictionary, sieht man das auch in x.'),
    fill('Prüfe, ob der Schlüssel „jahr“ existiert.',
         'auto = {"marke": "Ford", "jahr": 1964}\nif "jahr" ' + B + ' auto:\n    print("Ja, jahr ist ein Schlüssel")', ['in'],
         'in prüft bei Dictionaries die SCHLÜSSEL, nicht die Werte.'),
    choice('Was gibt dieser Code aus?',
           'auto = {"marke": "Ford"}\nprint(auto.items())', ["dict_items([('marke', 'Ford')])", "[('marke', 'Ford')]", "dict_items(['marke', 'Ford'])"], 0,
           'items() liefert Paare (Tupel) aus Schlüssel und Wert.'),
])

lesson('dict_change', 'Dictionaries ändern', 'edit',
       'Einen Wert änderst du, indem du dem Schlüssel einen neuen Wert zuweist: auto["jahr"] = 2020. '
       'Mit update() kannst du gleich mehrere Werte auf einmal ändern.', [
    fill('Ändere das Jahr auf 2018.',
         'auto = {"marke": "Ford", "jahr": 1964}\nauto["jahr"] = ' + B + '\nprint(auto)', ['2018'],
         'Gibt es den Schlüssel schon, wird sein Wert überschrieben.'),
    fill('Ändere das Jahr mit einer Methode.',
         'auto = {"marke": "Ford", "jahr": 1964}\nauto.' + B + '({"jahr": 2020})\nprint(auto)', ['update'],
         'update() bekommt ein Dictionary mit den neuen Werten.'),
    choice('Was gibt dieser Code aus?',
           'd = {"a": 1, "b": 2}\nd.update({"a": 10, "c": 3})\nprint(d)', ["{'a': 10, 'b': 2, 'c': 3}", "{'a': 1, 'b': 2, 'c': 3}", "{'a': 10, 'c': 3}"], 0,
           'update() überschreibt vorhandene Schlüssel und fügt neue hinzu.'),
    choice('Was gibt dieser Code aus?',
           'punkte = {"Mia": 5}\npunkte["Mia"] += 3\nprint(punkte["Mia"])', ['8', '53', '5'], 0,
           'Man kann mit dem Wert direkt rechnen: += 3 erhöht ihn.'),
    order('Ordne die Zeilen, damit {\'farbe\': \'blau\'} ausgegeben wird.',
          ['d = {"farbe": "rot"}', 'd["farbe"] = "blau"', 'print(d)'],
          'Erst das Dictionary erstellen, dann ändern, dann ausgeben.'),
])

lesson('dict_add', 'Zu Dictionaries hinzufügen', 'add_circle',
       'Ein neues Paar fügst du hinzu, indem du einem NEUEN Schlüssel einen Wert gibst: auto["farbe"] = "rot". '
       'update() kann ebenfalls neue Paare hinzufügen.', [
    fill('Füge den Schlüssel „farbe“ mit dem Wert „rot“ hinzu.',
         'auto = {"marke": "Ford"}\nauto[' + B + '] = "rot"\nprint(auto)', [['"farbe"', "'farbe'"]],
         'Gibt es den Schlüssel noch nicht, wird ein neues Paar angelegt.'),
    choice('Was gibt dieser Code aus?',
           'd = {}\nd["x"] = 1\nd["y"] = 2\nprint(d, len(d))', ["{'x': 1, 'y': 2} 2", '{} 0', "{'y': 2} 1"], 0,
           'Ein leeres Dictionary {} kann man nach und nach füllen.'),
    fill('Füge mit einer Methode die Farbe hinzu.',
         'auto = {"marke": "Ford"}\nauto.update({"farbe": ' + B + '})\nprint(auto)', [['"rot"', "'rot'"]],
         'update() legt neue Schlüssel an und ändert vorhandene.'),
    choice('Was gibt dieser Code aus?',
           'zaehler = {}\nfor b in "abba":\n    zaehler[b] = zaehler.get(b, 0) + 1\nprint(zaehler)', ["{'a': 2, 'b': 2}", "{'a': 1, 'b': 1}", "{'abba': 4}"], 0,
           'Ein klassischer Trick zum Zählen: get(b, 0) liefert 0, wenn der Buchstabe noch nicht gezählt wurde.'),
    choice('Was gibt dieser Code aus?',
           'd = {"a": 1}\nd.setdefault("b", 5)\nd.setdefault("a", 99)\nprint(d)', ["{'a': 1, 'b': 5}", "{'a': 99, 'b': 5}", "{'a': 1}"], 0,
           'setdefault() fügt einen Schlüssel nur hinzu, wenn es ihn noch NICHT gibt.'),
])

lesson('dict_remove', 'Aus Dictionaries entfernen', 'remove_circle',
       'pop("schlüssel") entfernt ein Paar und gibt den Wert zurück. popitem() entfernt das zuletzt hinzugefügte Paar. '
       'del d["schlüssel"] löscht ein Paar, und clear() leert das ganze Dictionary.', [
    fill('Entferne das Modell mit einer Methode.',
         'auto = {"marke": "Ford", "modell": "Mustang"}\nauto.' + B + '("modell")\nprint(auto)', ['pop'],
         'pop() entfernt das Paar mit diesem Schlüssel.'),
    choice('Was gibt dieser Code aus?',
           'auto = {"marke": "Ford", "modell": "Mustang", "jahr": 1964}\nauto.popitem()\nprint(auto)', ["{'marke': 'Ford', 'modell': 'Mustang'}", "{'modell': 'Mustang', 'jahr': 1964}", '{}'], 0,
           'popitem() entfernt das zuletzt hinzugefügte Paar – hier das Jahr.'),
    fill('Lösche das Paar mit dem Schlüssel „jahr“.',
         'auto = {"marke": "Ford", "jahr": 1964}\n' + B + ' auto["jahr"]\nprint(auto)', ['del'],
         'del entfernt ein Paar direkt über den Schlüssel.'),
    choice('Was gibt dieser Code aus?',
           'd = {"a": 1, "b": 2}\nwert = d.pop("a")\nprint(wert, d)', ["1 {'b': 2}", "a {'b': 2}", "1 {'a': 1, 'b': 2}"], 0,
           'pop() gibt den entfernten Wert zurück.'),
    choice('Was gibt dieser Code aus?',
           'd = {"a": 1}\nd.clear()\nprint(d)', ['{}', 'None', 'set()'], 0,
           'clear() leert das Dictionary. Übrig bleibt ein leeres {}.'),
])

lesson('dict_loop', 'Dictionaries durchlaufen', 'sync',
       'for k in d: läuft über die Schlüssel. Mit d[k] bekommst du den Wert dazu. '
       'for v in d.values(): läuft über die Werte, und for k, v in d.items(): über beides gleichzeitig.', [
    fill('Gib alle Werte aus.',
         'auto = {"marke": "Ford", "jahr": 1964}\nfor x in auto.' + B + '():\n    print(x)', ['values'],
         'values() liefert nur die Werte.'),
    choice('Was gibt dieser Code aus?',
           'auto = {"marke": "Ford", "jahr": 1964}\nfor x in auto:\n    print(x)', ['marke\njahr', 'Ford\n1964', "('marke', 'Ford')\n('jahr', 1964)"], 0,
           'Läuft man direkt über ein Dictionary, bekommt man die SCHLÜSSEL.'),
    fill('Laufe über Schlüssel und Werte gleichzeitig.',
         'auto = {"marke": "Ford", "jahr": 1964}\nfor k, v in auto.' + B + '():\n    print(k, v)', ['items'],
         'items() liefert Paare, die direkt in k und v ausgepackt werden.'),
    choice('Was gibt dieser Code aus?',
           'preise = {"Apfel": 2, "Kiwi": 3}\nfor obst in preise:\n    print(obst, preise[obst] * 2)', ['Apfel 4\nKiwi 6', 'Apfel 2\nKiwi 3', '4\n6'], 0,
           'Mit dem Schlüssel holt man in der Schleife den Wert: preise[obst].'),
    order('Ordne die Zeilen, damit die Summe aller Werte (10) ausgegeben wird.',
          ['punkte = {"a": 3, "b": 7}', 'summe = 0', 'for p in punkte.values():', '    summe += p', 'print(summe)'],
          'Für die Summe braucht man nur die Werte – values() liefert sie.'),
])

lesson('dict_copy', 'Dictionaries kopieren', 'content_copy',
       'd2 = d1 macht keine Kopie, sondern nur einen zweiten Namen für DASSELBE Dictionary. '
       'Eine echte Kopie bekommst du mit d1.copy() oder dict(d1).', [
    choice('Was gibt dieser Code aus?',
           'a = {"x": 1}\nb = a\nb["y"] = 2\nprint(a)', ["{'x': 1, 'y': 2}", "{'x': 1}", "{'y': 2}"], 0,
           'b ist dasselbe Dictionary wie a. Was man in b ändert, steht auch in a.'),
    fill('Erstelle eine echte Kopie mit einer Methode.',
         'a = {"x": 1}\nb = a.' + B + '()\nb["y"] = 2\nprint(a)', ['copy'],
         'copy() erstellt ein neues, unabhängiges Dictionary.'),
    fill('Erstelle eine Kopie mit der eingebauten Funktion.',
         'a = {"x": 1}\nb = ' + B + '(a)\nprint(b)', ['dict'],
         'dict(a) baut ein neues Dictionary aus a.'),
    choice('Was gibt dieser Code aus?',
           'a = {"x": 1}\nb = a.copy()\nprint(a == b, a is b)', ['True False', 'True True', 'False False'], 0,
           'Die Kopie hat den gleichen Inhalt (==), ist aber ein anderes Objekt (is).'),
    choice('Was gibt dieser Code aus?',
           'original = {"farbe": "rot"}\nkopie = dict(original)\nkopie["farbe"] = "blau"\nprint(original["farbe"])', ['rot', 'blau', 'Fehler'], 0,
           'Weil kopie eine echte Kopie ist, bleibt das Original rot.'),
])

lesson('dict_nested', 'Verschachtelte Dictionaries', 'account_tree',
       'Ein Wert in einem Dictionary darf selbst wieder ein Dictionary sein. So kannst du z. B. eine ganze Familie speichern. '
       'Zugreifen kannst du dann mit zwei Schlüsseln hintereinander: familie["kind1"]["name"].', [
    fill('Gib den Namen von kind2 aus.',
         'familie = {\n    "kind1": {"name": "Emil", "jahr": 2004},\n    "kind2": {"name": "Tobias", "jahr": 2007},\n}\nprint(familie["kind2"][' + B + '])', [['"name"', "'name'"]],
         'Der erste Schlüssel holt das innere Dictionary, der zweite den Wert darin.'),
    choice('Was gibt dieser Code aus?',
           'familie = {\n    "kind1": {"name": "Emil", "jahr": 2004},\n    "kind2": {"name": "Tobias", "jahr": 2007},\n}\nprint(familie["kind1"]["jahr"])', ['2004', '2007', 'Emil'], 0,
           'familie["kind1"] ist {"name": "Emil", "jahr": 2004} – daraus wird das Jahr geholt.'),
    choice('Was gibt dieser Code aus?',
           'kind1 = {"name": "Emil"}\nkind2 = {"name": "Linus"}\nfamilie = {"k1": kind1, "k2": kind2}\nprint(familie["k2"])', ["{'name': 'Linus'}", 'Linus', 'k2'], 0,
           'Man kann auch fertige Dictionaries in ein neues Dictionary stecken.'),
    choice('Was gibt dieser Code aus?',
           'familie = {"k1": {"name": "Emil"}, "k2": {"name": "Ida"}}\nfor k, person in familie.items():\n    print(k, person["name"])', ['k1 Emil\nk2 Ida', 'Emil\nIda', 'k1\nk2'], 0,
           'In der Schleife ist person jeweils das innere Dictionary.'),
    fill('Ändere das Jahr von kind1 auf 2005.',
         'familie = {"kind1": {"name": "Emil", "jahr": 2004}}\nfamilie["kind1"][' + B + '] = 2005\nprint(familie)', [['"jahr"', "'jahr'"]],
         'Auch beim Ändern geht man Schlüssel für Schlüssel nach innen.'),
])

lesson('dict_methods', 'Dictionary-Methoden', 'construction',
       'Weitere nützliche Methoden: fromkeys() baut ein Dictionary aus einer Liste von Schlüsseln, setdefault() setzt einen Wert nur, '
       'wenn der Schlüssel fehlt, und get() liefert einen Ersatzwert. Auch len() und in funktionieren.', [
    fill('Baue ein Dictionary, in dem jeder Schlüssel den Wert 0 hat.',
         'schluessel = ["a", "b", "c"]\nd = dict.' + B + '(schluessel, 0)\nprint(d)', ['fromkeys'],
         'dict.fromkeys(schlüssel, wert) gibt jedem Schlüssel denselben Startwert.'),
    choice('Was gibt dieser Code aus?',
           'd = {"a": 1}\nprint(d.get("b", "fehlt"))', ['fehlt', 'None', 'KeyError'], 0,
           'get() mit zweitem Wert liefert diesen Ersatz, wenn der Schlüssel fehlt.'),
    choice('Was gibt dieser Code aus?',
           'd = {"a": 1, "b": 2, "c": 3}\nprint(len(d), list(d.keys())[-1])', ['3 c', '3 3', '6 c'], 0,
           'len() zählt die Paare. list(d.keys()) macht aus den Schlüsseln eine Liste – davon das letzte Element.'),
    fill('Baue mit einer Dictionary Comprehension die Quadratzahlen.',
         'quadrate = {x: x * x ' + B + ' x in range(1, 4)}\nprint(quadrate)', ['for'],
         'Wie bei Listen gibt es auch Dictionary Comprehensions: {schlüssel: wert for …}.'),
    choice('Was gibt dieser Code aus?',
           'd = {"a": 1}\nx = d.setdefault("a", 50)\nprint(x)', ['1', '50', 'None'], 0,
           'Den Schlüssel gibt es schon – setdefault() ändert nichts und gibt den vorhandenen Wert zurück.'),
])
