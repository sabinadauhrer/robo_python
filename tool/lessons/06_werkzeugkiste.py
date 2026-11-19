# Kapitel Werkzeugkiste (neue Inseln)

lesson('arrays', 'Arrays (Listen)', 'view_array',
       'Viele Programmiersprachen haben „Arrays“: eine Reihe von Werten unter einem Namen. In Python benutzt man dafür Listen. '
       'Mit len() bekommst du die Länge, mit einer Schleife gehst du alle Werte durch, und Methoden wie append() und pop() verändern das Array.', [
    fill('Finde heraus, wie viele Autos im Array sind.',
         'autos = ["Ford", "Volvo", "BMW"]\nx = ' + B + '(autos)\nprint(x)', ['len'],
         'len() liefert die Anzahl der Elemente. Der höchste Index ist immer len() - 1.'),
    choice('Was gibt dieser Code aus?',
           'autos = ["Ford", "Volvo", "BMW"]\nautos[0] = "Toyota"\nprint(autos)', ["['Toyota', 'Volvo', 'BMW']", "['Ford', 'Toyota', 'BMW']", "['Toyota']"], 0,
           'Über den Index kann man einen Wert im Array ersetzen.'),
    choice('Was gibt dieser Code aus?',
           'autos = ["Ford", "Volvo"]\nautos.append("Honda")\nautos.pop(1)\nprint(autos)', ["['Ford', 'Honda']", "['Volvo', 'Honda']", "['Ford', 'Volvo']"], 0,
           'append() hängt Honda an, pop(1) entfernt das Element an Position 1 (Volvo).'),
    fill('Gib jedes Auto aus.',
         'autos = ["Ford", "Volvo"]\nfor x in ' + B + ':\n    print(x)', ['autos'],
         'Die for-Schleife geht das ganze Array durch.'),
    choice('Was gibt dieser Code aus?',
           'werte = [4, 8, 15]\nprint(werte[len(werte) - 1])', ['15', '8', 'IndexError'], 0,
           'len(werte) - 1 ist der letzte gültige Index (hier 2).'),
])

lesson('modules', 'Module', 'extension',
       'Ein Modul ist eine Sammlung fertiger Funktionen, die du mit import laden kannst – wie eine Werkzeugkiste. '
       'import math lädt das Modul math, dann benutzt du math.sqrt(). Mit import math as m gibst du ihm einen kürzeren Namen, '
       'mit from math import sqrt holst du nur eine Funktion. In diesem Spiel gibt es: math, json, datetime, re und os.', [
    fill('Lade das Modul math.',
         B + ' math\nprint(math.sqrt(25))', ['import'],
         'Nach import math stehen alle Funktionen aus math bereit – mit math. davor.'),
    fill('Gib dem Modul den kurzen Namen m.',
         'import math ' + B + ' m\nprint(m.floor(2.7))', ['as'],
         'Mit as bekommt ein Modul einen anderen Namen. Das spart Tipparbeit.'),
    fill('Importiere nur die Funktion sqrt.',
         'from math ' + B + ' sqrt\nprint(sqrt(9))', ['import'],
         'Mit from … import … holst du einzelne Teile. Dann schreibst du sqrt() ohne math. davor.'),
    choice('Was passiert bei diesem Code?',
           'print(math.pi)', ['NameError: math wurde nicht importiert', '3.141592653589793', 'pi'], 0,
           'Ohne import math kennt Python den Namen math nicht.',
           is_output=False),
    choice('Wie heißt die Datei, wenn man ein eigenes Modul „meinmodul“ erstellen will?',
           '# Datei meinmodul.py:\ndef gruss(name):\n    print("Hallo, " + name)',
           ['meinmodul.py', 'meinmodul.txt', 'import.py'], 0,
           'Jede .py-Datei ist ein Modul. In einer anderen Datei im selben Ordner schreibt man dann: import meinmodul.',
           is_output=False),
])

lesson('dates', 'Datum & Zeit', 'event',
       'Mit dem Modul datetime arbeitest du mit Datum und Uhrzeit. datetime.datetime(2025, 3, 14) erstellt einen Zeitpunkt, '
       'datetime.date(2025, 3, 14) nur ein Datum. Mit .year, .month, .day liest du Teile aus, mit strftime() formatierst du es: '
       '%d Tag, %m Monat, %Y Jahr, %A Wochentag, %B Monatsname (auf Englisch).', [
    fill('Lies das Jahr aus dem Datum.',
         'import datetime\nx = datetime.datetime(2020, 5, 17)\nprint(x.' + B + ')', ['year'],
         'Ein datetime-Objekt hat Eigenschaften wie year, month, day, hour und minute.'),
    choice('Was gibt dieser Code aus?',
           'import datetime\nx = datetime.datetime(2020, 5, 17)\nprint(x)', ['2020-05-17 00:00:00', '17.05.2020', '2020, 5, 17'], 0,
           'Ohne Uhrzeit ist es 0 Uhr. print() zeigt Jahr-Monat-Tag und Stunden:Minuten:Sekunden.'),
    fill('Zeige das Datum im deutschen Format TT.MM.JJJJ.',
         'import datetime\nx = datetime.date(2024, 12, 24)\nprint(x.strftime("%d.%m.' + B + '"))', ['%Y'],
         '%Y ist das Jahr mit 4 Ziffern, %y wäre nur 24.'),
    choice('Was gibt dieser Code aus?',
           'import datetime\nx = datetime.datetime(2018, 6, 1)\nprint(x.strftime("%B"))', ['June', 'Juni', '06'], 0,
           '%B ist der volle Monatsname – auf Englisch, so wie Python ihn standardmäßig ausgibt.'),
    choice('Was gibt dieser Code aus?',
           'import datetime\na = datetime.date(2025, 1, 1)\nb = datetime.date(2025, 6, 1)\nprint(a < b)\nprint(a.strftime("%A"))', ['True\nWednesday', 'False\nWednesday', 'True\nMonday'], 0,
           'Daten kann man vergleichen: Das frühere ist „kleiner“. Der 1. Januar 2025 war ein Mittwoch (Wednesday).'),
])

lesson('math', 'Mathe', 'functions',
       'Python hat eingebaute Rechenfunktionen: min(), max(), abs() und pow(). '
       'Das Modul math bietet mehr: math.sqrt() (Wurzel), math.ceil() (aufrunden), math.floor() (abrunden) und die Zahl math.pi.', [
    choice('Was gibt dieser Code aus?',
           'print(min(5, 10, 25))\nprint(max(5, 10, 25))', ['5\n25', '25\n5', '5\n10'], 0,
           'min() findet den kleinsten, max() den größten Wert.'),
    fill('Berechne 4 hoch 3 mit einer eingebauten Funktion.',
         'print(' + B + '(4, 3))', ['pow'],
         'pow(4, 3) ist dasselbe wie 4 ** 3 = 64.'),
    fill('Ziehe die Wurzel aus 64.',
         'import math\nprint(math.' + B + '(64))', ['sqrt'],
         'sqrt steht für „square root“ (Quadratwurzel). Das Ergebnis ist eine Kommazahl: 8.0.'),
    choice('Was gibt dieser Code aus?',
           'import math\nprint(math.ceil(1.4))\nprint(math.floor(1.4))', ['2\n1', '1\n1', '1\n2'], 0,
           'ceil() rundet immer AUF (Decke), floor() immer AB (Boden).'),
    choice('Was gibt dieser Code aus?',
           'import math\nprint(abs(-7.25))\nprint(round(math.pi, 2))', ['7.25\n3.14', '-7.25\n3.14', '7\n3.1'], 0,
           'abs() macht eine Zahl positiv. math.pi ist 3.14159…, gerundet auf 2 Stellen: 3.14.'),
])

lesson('json', 'JSON', 'data_object',
       'JSON ist ein Textformat, um Daten zu speichern und zu verschicken – es sieht fast aus wie ein Python-Dictionary. '
       'Mit json.loads() wird aus einem JSON-Text ein Dictionary, mit json.dumps() wird aus Python-Daten ein JSON-Text. '
       'Dabei wird True zu true und None zu null.', [
    fill('Wandle den JSON-Text in ein Dictionary um.',
         'import json\nx = \'{"name": "John", "alter": 30}\'\ny = json.' + B + '(x)\nprint(y["alter"])', ['loads'],
         'loads = „load string“: Liest einen JSON-Text und macht Python-Daten daraus.'),
    fill('Wandle das Dictionary in einen JSON-Text um.',
         'import json\nx = {"name": "John", "alter": 30}\nprint(json.' + B + '(x))', ['dumps'],
         'dumps = „dump string“: Schreibt Python-Daten als JSON-Text.'),
    choice('Was gibt dieser Code aus?',
           'import json\nprint(json.dumps({"ok": True, "wert": None}))', ['{"ok": true, "wert": null}', "{'ok': True, 'wert': None}", '{"ok": True, "wert": None}'], 0,
           'In JSON heißt True klein true und None heißt null. Texte stehen immer in doppelten Anführungszeichen.'),
    choice('Was gibt dieser Code aus?',
           'import json\nprint(json.dumps({"b": 1, "a": 2}, sort_keys=True))', ['{"a": 2, "b": 1}', '{"b": 1, "a": 2}', '[2, 1]'], 0,
           'sort_keys=True sortiert die Schlüssel alphabetisch.'),
    choice('Was gibt dieser Code aus?',
           'import json\nprint(json.dumps([1, 2], indent=2))', ['[\n  1,\n  2\n]', '[1, 2]', '[  1,  2]'], 0,
           'indent rückt den JSON-Text ein – so wird er für Menschen leichter lesbar.'),
])

lesson('regex', 'RegEx (Suchmuster)', 'manage_search',
       'Eine RegEx (regular expression) ist ein Suchmuster für Texte. Das Modul re kann damit suchen und ersetzen: '
       're.findall() findet alle Treffer, re.search() den ersten, re.split() teilt, re.sub() ersetzt. '
       'Wichtige Zeichen: \\d Ziffer, \\s Leerzeichen, \\w Buchstabe/Ziffer, + „ein- oder mehrmals“, ^ Anfang, $ Ende.', [
    fill('Finde alle Vorkommen von „ai“.',
         'import re\ntxt = "The rain in Spain"\nprint(re.' + B + '("ai", txt))', ['findall'],
         'findall() liefert eine Liste mit allen Treffern.'),
    choice('Was gibt dieser Code aus?',
           'import re\nprint(re.findall(r"\\d+", "3 Äpfel und 12 Birnen"))', ["['3', '12']", "['3', '1', '2']", '[3, 12]'], 0,
           '\\d+ heißt „eine oder mehrere Ziffern hintereinander“. Die Treffer sind Texte.'),
    fill('Ersetze jedes Leerzeichen durch einen Bindestrich.',
         'import re\nprint(re.' + B + '(r"\\s", "-", "Ich lerne Python"))', ['sub'],
         'sub() = substitute (ersetzen): Muster, Ersatz, Text.'),
    choice('Was gibt dieser Code aus?',
           'import re\nx = re.search("Spain$", "The rain in Spain")\nprint(x.span())', ['(12, 17)', '(0, 17)', 'True'], 0,
           'search() liefert ein Treffer-Objekt. span() zeigt Start- und Endposition. $ heißt: am Ende des Texts.'),
    choice('Was gibt dieser Code aus?',
           'import re\nprint(re.split(r"\\s", "eins zwei drei"))\nprint(re.search("xyz", "abc"))', ["['eins', 'zwei', 'drei']\nNone", "['eins zwei drei']\nNone", "['eins', 'zwei', 'drei']\nFalse"], 0,
           'split() teilt bei jedem Treffer. Findet search() nichts, kommt None zurück.'),
])

lesson('pip', 'PIP', 'inventory_2',
       'PIP ist der Paket-Manager von Python. Damit installierst du Pakete (Module von anderen Leuten) aus dem Internet, '
       'z. B. mit pip install camelcase im Terminal. Danach kannst du sie mit import benutzen. '
       'pip list zeigt alle installierten Pakete, pip uninstall entfernt eines. (Im Spiel kannst du nichts installieren.)', [
    choice('Mit welchem Befehl installiert man das Paket „camelcase“?',
           '# im Terminal (nicht in Python):\n# pip install camelcase',
           ['pip install camelcase', 'import camelcase', 'python camelcase'], 0,
           'pip install lädt das Paket herunter und installiert es. Danach kann man es in Python importieren.',
           is_output=False),
    choice('Was ist ein Paket?',
           '# Ein Paket enthält fertigen Code,\n# den andere geschrieben haben.',
           ['Fertiger Code zum Wiederverwenden', 'Ein Fehler im Programm', 'Eine Python-Version'], 0,
           'Pakete enthalten Module, die man nicht selbst schreiben muss – z. B. für Bilder, Spiele oder Webseiten.',
           is_output=False),
    choice('Welcher Befehl zeigt alle installierten Pakete?',
           '# im Terminal:\n# pip ...',
           ['pip list', 'pip show all', 'pip print'], 0,
           'pip list zeigt eine Liste aller Pakete mit ihren Versionen.',
           is_output=False),
    choice('Wie benutzt man ein installiertes Paket im Code?',
           '# Das Paket camelcase ist installiert.\n# Wie lädt man es?',
           ['import camelcase', 'pip camelcase', 'load camelcase'], 0,
           'Installierte Pakete lädt man wie jedes Modul mit import.',
           is_output=False),
    fill('Lade das eingebaute Modul json – dafür braucht man kein pip.',
         B + ' json\nprint(json.dumps([1, 2]))', ['import'],
         'Module wie json, math oder datetime sind schon in Python eingebaut. pip braucht man nur für zusätzliche Pakete.'),
])

lesson('try_except', 'try / except', 'healing',
       'Mit try probiert Python einen Code aus. Passiert dabei ein Fehler, stürzt das Programm nicht ab, sondern springt zu except. '
       'Du kannst bestimmte Fehler abfangen (except ValueError:), else läuft nur ohne Fehler, finally läuft IMMER. '
       'Mit raise löst du selbst einen Fehler aus.', [
    fill('Fange den Fehler ab, damit das Programm nicht abstürzt.',
         'try:\n    print(x)\n' + B + ':\n    print("Ein Fehler ist passiert")', ['except'],
         'x gibt es nicht → NameError. Statt abzustürzen springt Python zu except.',
         {1: 'try: Python probiert es mal.', 3: 'Wird nur bei einem Fehler ausgeführt.'}),
    choice('Was gibt dieser Code aus?',
           'try:\n    print(10 / 0)\nexcept ZeroDivisionError:\n    print("Durch 0 geht nicht!")\nexcept:\n    print("Anderer Fehler")', ['Durch 0 geht nicht!', 'Anderer Fehler', 'Durch 0 geht nicht!\nAnderer Fehler'], 0,
           'Python nimmt den ERSTEN passenden except-Teil. Ein except ohne Fehlernamen fängt alles andere.'),
    choice('Was gibt dieser Code aus?',
           'try:\n    print("Hallo")\nexcept:\n    print("Fehler")\nelse:\n    print("Kein Fehler")\nfinally:\n    print("Fertig")', ['Hallo\nKein Fehler\nFertig', 'Hallo\nFertig', 'Fehler\nFertig'], 0,
           'Es gibt keinen Fehler, also läuft else. finally läuft sowieso immer.'),
    fill('Löse selbst einen Fehler aus, wenn x negativ ist.',
         'x = -1\ntry:\n    if x < 0:\n        ' + B + ' ValueError("Keine negativen Zahlen!")\nexcept ValueError as e:\n    print("Fehler:", e)', ['raise'],
         'raise löst einen Fehler aus. Mit except … as e bekommt man das Fehler-Objekt – print(e) zeigt die Nachricht.'),
    choice('Was gibt dieser Code aus?',
           'def teile(a, b):\n    try:\n        return a / b\n    except ZeroDivisionError:\n        return "unmöglich"\n    finally:\n        print("geprüft")\n\nprint(teile(6, 0))', ['geprüft\nunmöglich', 'unmöglich\ngeprüft', 'unmöglich'], 0,
           'finally läuft, bevor die Funktion ihren Wert zurückgibt. Deshalb erscheint „geprüft“ zuerst.'),
])

lesson('str_format', 'String-Formatierung', 'format_shapes',
       'Mit f-Strings und format() setzt du Werte in Texte ein und formatierst sie: '
       ':.2f zeigt 2 Nachkommastellen, :, setzt Tausender-Kommas, :>10 richtet rechts aus, :^10 zentriert, :05 füllt mit Nullen. '
       'Bei format() stehen {} als Platzhalter, die der Reihe nach, per Nummer {0} oder per Name {name} gefüllt werden.', [
    fill('Zeige den Preis mit 2 Nachkommastellen.',
         'preis = 59\nprint(f"Der Preis ist {preis:' + B + '} Euro")', ['.2f'],
         ':.2f macht aus 59 die Kommazahl 59.00.'),
    fill('Fülle die Platzhalter mit format().',
         'menge = 3\nnr = 567\ntext = "Ich will {} Stück von Artikel {}."\nprint(text.' + B + '(menge, nr))', ['format'],
         'format() setzt die Werte der Reihe nach in die {} ein.'),
    choice('Was gibt dieser Code aus?',
           'print("{1} {0}".format("Welt", "Hallo"))', ['Hallo Welt', 'Welt Hallo', '{1} {0}'], 0,
           'Mit Nummern in den Klammern bestimmst du, welcher Wert wohin kommt. {1} ist der zweite Wert.'),
    choice('Was gibt dieser Code aus?',
           'print(f"[{\'Robo\':>6}]")\nprint(f"[{7:03}]")', ['[  Robo]\n[007]', '[Robo  ]\n[700]', '[ Robo ]\n[007]'], 0,
           ':>6 richtet den Text rechts aus (6 Zeichen breit). :03 füllt eine Zahl vorne mit Nullen auf 3 Stellen auf.'),
    choice('Was gibt dieser Code aus?',
           'x = 1234567\nprint(f"{x:,}")\nprint("{name} ist {alter}".format(name="Ida", alter=8))', ['1,234,567\nIda ist 8', '1234567\nIda ist 8', '1.234.567\nIda ist 8'], 0,
           ':, setzt Kommas als Tausendertrenner (englische Schreibweise). Benannte Platzhalter füllt man mit name=…'),
])

lesson('none', 'None', 'block',
       'None bedeutet „nichts“ oder „kein Wert“. Eine Funktion ohne return gibt None zurück. '
       'Ob etwas None ist, prüft man mit is None (nicht mit ==). None ist bei if wie False.', [
    choice('Was gibt dieser Code aus?',
           'x = None\nprint(x)\nprint(type(x))', ["None\n<class 'NoneType'>", "\n<class 'NoneType'>", "None\n<class 'None'>"], 0,
           'None hat seinen eigenen Typ: NoneType.'),
    fill('Prüfe, ob ergebnis None ist.',
         'ergebnis = None\nif ergebnis ' + B + ' None:\n    print("Noch kein Ergebnis")', ['is'],
         'Für None benutzt man is. Es gibt nur ein einziges None-Objekt.'),
    choice('Was gibt dieser Code aus?',
           'def nichts():\n    print("Hallo")\n\nx = nichts()\nprint(x)', ['Hallo\nNone', 'None', 'Hallo'], 0,
           'Die Funktion gibt „Hallo“ aus, hat aber kein return – deshalb ist x None.'),
    choice('Was gibt dieser Code aus?',
           'x = None\nif x:\n    print("Wahr")\nelse:\n    print("Falsch")', ['Falsch', 'Wahr', 'None'], 0,
           'In einer Bedingung verhält sich None wie False.'),
    fill('Prüfe, ob wert NICHT None ist.',
         'wert = 0\nif wert is ' + B + ' None:\n    print("Es gibt einen Wert:", wert)', ['not'],
         'is not None ist True für alles außer None – auch für 0!'),
])

lesson('user_input', 'Benutzereingabe', 'keyboard',
       'Mit input() wartet Python, bis jemand etwas eintippt, und liefert es als Text. In Klammern steht eine Frage. '
       'Achtung: input() liefert IMMER einen Text – für Zahlen musst du int() oder float() benutzen. '
       'Im Spiel ist die Eingabe schon vorgegeben – sie erscheint in der Ausgabe direkt hinter der Frage.', [
    fill('Frage nach dem Namen.',
         'name = ' + B + '("Wie heißt du? ")\nprint("Hallo", name)', ['input'],
         'input() zeigt die Frage an und wartet auf die Eingabe. Hier tippt „jemand“ Mia ein.',
         inputs=['Mia']),
    choice('Was gibt dieser Code aus? (Eingabe: 7)',
           'zahl = input("Zahl: ")\nprint(zahl * 2)', ['Zahl: 7\n77', 'Zahl: 7\n14', 'Zahl: 7\n7 7'], 0,
           'input() liefert den Text "7". Text mal 2 wiederholt den Text → "77".',
           inputs=['7']),
    fill('Wandle die Eingabe in eine Zahl um, damit gerechnet wird.',
         'alter = ' + B + '(input("Alter: "))\nprint("Nächstes Jahr bist du", alter + 1)', ['int'],
         'int() macht aus dem Text "9" die Zahl 9 – jetzt kann man rechnen.',
         inputs=['9']),
    choice('Was gibt dieser Code aus? (Eingaben: 3 und 4)',
           'a = int(input("a = "))\nb = int(input("b = "))\nprint("Summe:", a + b)', ['a = 3\nb = 4\nSumme: 7', 'a = 3\nb = 4\nSumme: 34', 'Summe: 7'], 0,
           'Jedes input() holt die nächste Eingabe. Nach int() sind es Zahlen, die man addieren kann.',
           inputs=['3', '4']),
    choice('Was gibt dieser Code aus? (Eingabe: Kiwi)',
           'obst = input("Lieblingsobst? ")\nif obst == "Kiwi":\n    print("Lecker und grün!")\nelse:\n    print("Auch gut!")', ['Lieblingsobst? Kiwi\nLecker und grün!', 'Lieblingsobst? Kiwi\nAuch gut!', 'Lecker und grün!'], 0,
           'Die Eingabe ist ein ganz normaler Text, mit dem man vergleichen kann.',
           inputs=['Kiwi']),
])

lesson('venv', 'Virtuelle Umgebung', 'inventory',
       'Eine virtuelle Umgebung (venv) ist ein eigener, abgeschotteter Ordner für ein Projekt mit eigenen Paketen. '
       'So stören sich Projekte nicht gegenseitig. Man erstellt sie im Terminal mit python -m venv meinordner '
       'und aktiviert sie dann. (Das passiert im Terminal, nicht im Python-Code.)', [
    choice('Wofür ist eine virtuelle Umgebung gut?',
           '# Projekt A braucht Paket Version 1,\n# Projekt B braucht Version 2 ...',
           ['Jedes Projekt bekommt seine eigenen Pakete', 'Python läuft schneller', 'Man braucht kein Internet mehr'], 0,
           'In einer venv installierte Pakete gelten nur für dieses Projekt. So gibt es keine Versions-Streitereien.',
           is_output=False),
    choice('Mit welchem Befehl erstellt man eine virtuelle Umgebung namens „umgebung“?',
           '# im Terminal:\n# python -m venv umgebung',
           ['python -m venv umgebung', 'pip install umgebung', 'import venv'], 0,
           'python -m venv startet das eingebaute venv-Modul und legt den Ordner an.',
           is_output=False),
    choice('Was passiert nach dem Aktivieren der Umgebung mit pip install?',
           '# (umgebung) $ pip install camelcase',
           ['Das Paket landet nur in dieser Umgebung', 'Das Paket wird überall installiert', 'Es kommt ein Fehler'], 0,
           'Ist die Umgebung aktiv, installiert pip nur in ihren Ordner. Das (umgebung) vorne zeigt, dass sie aktiv ist.',
           is_output=False),
    choice('Wie verlässt man die virtuelle Umgebung wieder?',
           '# im Terminal:\n# deactivate',
           ['deactivate', 'exit()', 'pip uninstall'], 0,
           'deactivate schaltet zurück auf das normale Python.',
           is_output=False),
    fill('Python-Code läuft in jeder Umgebung gleich. Ergänze den Befehl.',
         B + '("Läuft auch in der venv!")', ['print'],
         'Die Umgebung ändert nur, welche Pakete verfügbar sind – der Code selbst bleibt gleich.'),
])
