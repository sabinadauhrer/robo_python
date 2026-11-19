"""Quelle aller Lektionen. Erzeugt assets/lessons/*.json.

Jede Musterlösung wird mit echtem Python ausgeführt – so stimmen die
erwarteten Ausgaben garantiert. Aufruf: python3 tool/lessons_source.py
"""
import contextlib, glob, io, json, os, re, shutil, sys, tempfile

OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'lessons')
B = '___'


def run(code, inputs=(), files=None, manual=None):
    """Führt den Code mit echtem Python aus.

    inputs: Was bei input() eingetippt wird. Wie im Spiel erscheint die Eingabe in der Ausgabe.
    files: Dateien, die es beim Start gibt.
    manual: erwartete Ausgabe für Code, den diese Python-Version nicht kann (match ab 3.10).
    """
    if manual is not None and sys.version_info < (3, 10):
        return manual
    feed = list(inputs)

    def fake_input(prompt=''):
        value = feed.pop(0)
        print(str(prompt) + value)
        return value

    buf = io.StringIO()
    old = os.getcwd()
    tmp = tempfile.mkdtemp()
    os.chdir(tmp)
    try:
        for name, content in (files or {}).items():
            with open(name, 'w') as f:
                f.write(content)
        with contextlib.redirect_stdout(buf):
            exec(compile(code, 'aufgabe', 'exec'), {'__name__': '__main__', 'input': fake_input})
    finally:
        os.chdir(old)
        shutil.rmtree(tmp)
    out = buf.getvalue()
    out = out[:-1] if out.endswith('\n') else out
    if manual is not None:
        assert out == manual, (code, out, manual)
    return out


def _extra(ex, inputs, files):
    if inputs:
        ex['inputs'] = list(inputs)
    if files:
        ex['files'] = dict(files)
    return ex


def fill_in(code, answers):
    parts = code.split(B)
    assert len(parts) - 1 == len(answers), (code, answers)
    s = parts[0]
    for a, p in zip(answers, parts[1:]):
        s += (a[0] if isinstance(a, list) else a) + p
    return s


def fill(task, code, answers, explain, notes=None, hint='', why=None, output=True,
         inputs=(), files=None, manual=None):
    answers = [a if isinstance(a, list) else [a] for a in answers]
    ex = {'type': 'fill', 'task': task, 'code': code, 'answers': answers,
          'explain': explain, 'notes': notes or {}, 'hint': hint}
    out = run(fill_in(code, answers), inputs, files, manual)
    if output:
        ex['output'] = out
    if why:
        ex['why'] = why
    return _extra(ex, inputs, files)


def choice(task, code, options, correct, explain, notes=None, hint='', why=None, is_output=True,
           inputs=(), files=None, manual=None):
    assert len(set(options)) == len(options), options
    if is_output:
        actual = run(code, inputs, files, manual)
        assert options[correct] == actual, (task, options[correct], actual)
    ex = {'type': 'choice', 'task': task, 'code': code, 'options': options, 'correct': correct,
          'isOutput': is_output, 'explain': explain, 'notes': notes or {}, 'hint': hint}
    if why:
        ex['why'] = why
    return _extra(ex, inputs, files)


def order(task, lines, explain, hint='', why=None, inputs=(), files=None, manual=None):
    ex = {'type': 'order', 'task': task, 'lines': lines, 'output': run('\n'.join(lines), inputs, files, manual),
          'explain': explain, 'hint': hint}
    if why:
        ex['why'] = why
    return _extra(ex, inputs, files)


LESSONS = {}


def lesson(id, title, icon, intro, exercises):
    assert id not in LESSONS, id
    assert len(exercises) >= 5, id
    LESSONS[id] = {'id': id, 'title': title, 'icon': icon, 'intro': intro, 'exercises': exercises}


# ---------------------------------------------------------------- 1
lesson('l01_print', 'Ausgabe mit print', 'chat',
       'Mit print() zeigt Python etwas auf dem Bildschirm an. Alles, was in den runden Klammern steht, wird ausgegeben. '
       'Texte stehen in Anführungszeichen, Zahlen nicht.', [
    fill('Ergänze den Befehl, damit „Hallo Welt“ angezeigt wird.',
         B + '("Hallo Welt")', ['print'],
         'print ist der Befehl für „zeig das an“. Danach kommen runde Klammern – sie sagen: Hier steht, WAS angezeigt werden soll.',
         {1: 'print(...) gibt den Inhalt der Klammern aus. Die Anführungszeichen zeigen Python: Das ist ein Text.'},
         'Der Befehl heißt wie das englische Wort für „drucken“.'),
    fill('Setze die fehlenden Anführungszeichen, damit der Text ausgegeben wird.',
         'print(' + B + 'Ich lerne Python' + B + ')', [['"', "'"], ['"', "'"]],
         'Texte (Strings) müssen in Anführungszeichen stehen – vorne UND hinten. Sonst denkt Python, Ich, lerne und Python wären Namen von Variablen.',
         {1: 'Zwischen den Anführungszeichen steht der Text genau so, wie er ausgegeben wird.'},
         'Du kannst " oder \' benutzen – aber vorne und hinten das gleiche.', output=False),
    choice('Was gibt dieser Code aus?',
           'print(3 + 4)', ['7', '3 + 4', '34'], 0,
           'Ohne Anführungszeichen ist 3 + 4 eine Rechnung. Python rechnet zuerst und gibt dann das Ergebnis aus.',
           {1: 'Keine Anführungszeichen → Python rechnet.'},
           'Steht da ein Text oder eine Rechnung?',
           why='Mit Anführungszeichen, also print("3 + 4"), würde genau 3 + 4 als Text erscheinen.'),
    choice('Was gibt dieser Code aus?',
           'print("Robo", "mag", "Python")', ['Robo mag Python', 'RobomagPython', 'Robo, mag, Python'], 0,
           'Mehrere Werte in print() trennt man mit Kommas. Python setzt bei der Ausgabe automatisch ein Leerzeichen dazwischen.',
           {1: 'Drei Texte, getrennt durch Kommas. Die Kommas selbst werden NICHT ausgegeben.'}),
    order('Bringe die Zeilen in die richtige Reihenfolge: zuerst „Guten Morgen“, dann „Wie geht es dir?“.',
          ['print("Guten Morgen")', 'print("Wie geht es dir?")'],
          'Python führt den Code immer von oben nach unten aus, Zeile für Zeile. Was zuerst erscheinen soll, muss also oben stehen.'),
])

# ---------------------------------------------------------------- 2
lesson('l02_variablen', 'Variablen', 'inventory',
       'Eine Variable ist wie eine beschriftete Box: Sie hat einen Namen und speichert einen Wert. '
       'Mit = legst du einen Wert hinein, z. B. alter = 9. Später kannst du den Namen benutzen, um den Wert wiederzubekommen.', [
    fill('Erstelle eine Variable namens tier mit dem Text „Katze“.',
         B + ' = "Katze"\nprint(tier)', ['tier'],
         'Links vom = steht der Name der Box, rechts der Wert, der hineinkommt. Das = bedeutet hier nicht „ist gleich“, sondern „speichere“.',
         {1: 'Hier wird die Box tier angelegt und „Katze“ hineingelegt.',
          2: 'print(tier) – OHNE Anführungszeichen! Python schaut in die Box und gibt den Inhalt aus.'},
         'In Zeile 2 siehst du, wie die Variable heißen muss.'),
    fill('Speichere die Zahl 10 in der Variablen punkte.',
         'punkte ' + B + ' 10\nprint(punkte)', ['='],
         'Das Zeichen für „speichere in“ ist ein einzelnes Gleichheitszeichen.',
         {1: 'Name = Wert. Die Zahl 10 braucht keine Anführungszeichen.'},
         'Es ist nur ein Zeichen.'),
    choice('Was gibt dieser Code aus?',
           'x = 5\nx = 8\nprint(x)', ['8', '5', '5 8'], 0,
           'Eine Variable merkt sich immer nur EINEN Wert. Wenn du einen neuen Wert hineinlegst, ist der alte weg.',
           {1: 'x bekommt 5.', 2: 'x bekommt 8 – die 5 wird überschrieben.', 3: 'Jetzt ist nur noch 8 in der Box.'},
           why='Starte den Probelauf, um zu sehen, wie sich das Kästchen x verändert.'),
    fill('Erhöhe den Wert von leben um 1.',
         'leben = 3\nleben = ' + B + ' + 1\nprint(leben)', ['leben'],
         'Rechts vom = rechnet Python zuerst: alter Wert + 1. Das Ergebnis wird dann wieder in dieselbe Box gelegt.',
         {2: 'Erst wird rechts gerechnet (3 + 1 = 4), dann kommt das Ergebnis zurück in leben.'},
         'Du brauchst den alten Wert derselben Variablen.'),
    choice('Welcher Variablenname ist in Python ERLAUBT?',
           '# Welche Zeile funktioniert?\n2spieler = "Tom"\nmein-name = "Tom"\nmein_name = "Tom"',
           ['2spieler', 'mein-name', 'mein_name'], 2,
           'Variablennamen dürfen Buchstaben, Ziffern und _ enthalten. Sie dürfen aber NICHT mit einer Ziffer beginnen und keine Bindestriche haben (das wäre ein Minus!).',
           {2: 'Beginnt mit einer Ziffer → nicht erlaubt.', 3: 'Der Bindestrich ist für Python ein Minuszeichen → Fehler.',
            4: 'Unterstrich statt Leerzeichen – so schreibt man es in Python.'},
           is_output=False),
])

# ---------------------------------------------------------------- 3
lesson('l03_datentypen', 'Datentypen', 'category',
       'Jeder Wert hat einen Typ: ganze Zahlen (int), Kommazahlen (float), Texte (str) und Wahrheitswerte (bool, also True oder False). '
       'Mit type(wert) fragst du Python nach dem Typ.', [
    fill('Finde heraus, welchen Typ x hat.',
         'x = 42\nprint(' + B + '(x))', ['type'],
         'type() ist eine eingebaute Funktion. Sie verrät dir, zu welcher Sorte ein Wert gehört.',
         {1: '42 ist eine ganze Zahl ohne Komma.', 2: "Die Ausgabe sieht aus wie <class 'int'> – int steht für integer, ganze Zahl."}),
    choice('Was gibt dieser Code aus?',
           'x = 3.5\nprint(type(x))', ["<class 'float'>", "<class 'int'>", "<class 'str'>"], 0,
           'Zahlen mit Punkt sind Kommazahlen, auf Englisch float. Achtung: In Python schreibt man einen Punkt statt eines Kommas!',
           {1: '3.5 bedeutet drei Komma fünf.'}),
    choice('Was gibt dieser Code aus?',
           'x = "42"\nprint(type(x))', ["<class 'str'>", "<class 'int'>", "<class 'float'>"], 0,
           'Sobald Anführungszeichen drum herum stehen, ist es ein Text (str) – auch wenn Ziffern darin stehen!',
           {1: '"42" ist ein Text aus den Zeichen 4 und 2, keine Zahl.'},
           why='Mit "42" kann man nicht rechnen. "42" + 1 wäre ein Fehler.'),
    fill('Setze den richtigen Wahrheitswert ein, damit True ausgegeben wird.',
         'ist_sonnig = ' + B + '\nprint(ist_sonnig)', ['True'],
         'bool hat nur zwei mögliche Werte: True (wahr) und False (falsch). Sie werden mit großem Anfangsbuchstaben und OHNE Anführungszeichen geschrieben.',
         {1: 'Hier gehört ein Wahrheitswert hin.'},
         'Wahr heißt auf Englisch …'),
    choice('Was gibt dieser Code aus?',
           'a = 10\nb = 2.0\nprint(type(a * b))', ["<class 'float'>", "<class 'int'>", "<class 'str'>"], 0,
           'Rechnet man eine ganze Zahl mit einer Kommazahl, ist das Ergebnis immer eine Kommazahl – damit nichts verloren geht.',
           {3: '10 * 2.0 = 20.0'}),
])

# ---------------------------------------------------------------- 4
lesson('l04_zahlen', 'Zahlen & Rechnen', 'calculate',
       'Python kann rechnen wie ein Taschenrechner: + - * / . Dazu gibt es // (ganzzahlig teilen), % (Rest beim Teilen) und ** (hoch).', [
    fill('Ergänze den Operator, damit 12 ausgegeben wird.',
         'print(3 ' + B + ' 4)', ['*'],
         'Malnehmen schreibt man in Python mit einem Sternchen *, nicht mit x oder ·.',
         {1: '3 ? 4 soll 12 ergeben.'}, 'Welche Rechenart macht aus 3 und 4 die 12?'),
    choice('Was gibt dieser Code aus?',
           'print(7 / 2)', ['3.5', '3', '3 Rest 1'], 0,
           'Der normale Schrägstrich / teilt genau – das Ergebnis ist immer eine Kommazahl.',
           why='Selbst 8 / 2 ergibt 4.0 und nicht 4.'),
    choice('Was gibt dieser Code aus?',
           'print(17 // 5)\nprint(17 % 5)', ['3\n2', '3.4\n2', '2\n3'], 0,
           '// teilt und schneidet die Nachkommastellen ab (wie viele Male passt 5 in 17?). % gibt den Rest, der übrig bleibt.',
           {1: '5 passt 3-mal in 17 (3 · 5 = 15).', 2: '17 - 15 = 2 bleibt übrig.'}),
    fill('Berechne 2 hoch 5 (also 2·2·2·2·2).',
         'print(2 ' + B + ' 5)', ['**'],
         'Für „hoch“ benutzt man zwei Sternchen **. Ein Sternchen wäre nur malnehmen.',
         hint='Zwei Mal das Mal-Zeichen.'),
    fill('Prüfe mit dem Rest-Operator, ob 14 gerade ist (Rest 0 bei Teilen durch 2).',
         'zahl = 14\nprint(zahl ' + B + ' 2)', ['%'],
         'Gerade Zahlen haben beim Teilen durch 2 den Rest 0, ungerade den Rest 1. Das ist ein beliebter Trick!',
         {2: 'Rest von 14 geteilt durch 2.'}, 'Das Zeichen sieht aus wie ein Prozentzeichen.'),
])

# ---------------------------------------------------------------- 5
lesson('l05_casting', 'Umwandeln (Casting)', 'swap',
       'Manchmal muss man einen Wert in einen anderen Typ umwandeln: int() macht eine ganze Zahl, float() eine Kommazahl und str() einen Text.', [
    fill('Wandle den Text „5“ in eine Zahl um, damit gerechnet werden kann.',
         'x = "5"\ny = ' + B + '(x) + 3\nprint(y)', ['int'],
         'Mit einem Text kann man nicht rechnen. int() verwandelt „5“ in die Zahl 5 – danach klappt + 3.',
         {1: 'x ist ein Text!', 2: 'int(x) macht daraus die Zahl 5, dann wird 3 addiert.'},
         'Die Abkürzung für ganze Zahl (integer).'),
    fill('Verbinde Text und Zahl richtig mit +.',
         'alter = 9\nprint("Ich bin " + ' + B + '(alter) + " Jahre alt")', ['str'],
         'Text + Zahl geht nicht – Python weiß nicht, ob du rechnen oder zusammenkleben willst. Mit str() wird die Zahl zum Text, und + klebt Texte zusammen.',
         {2: 'Drei Texte werden mit + zusammengeklebt.'},
         'Die Abkürzung für string (Text).'),
    choice('Was gibt dieser Code aus?',
           'print(int(7.9))', ['7', '8', '7.9'], 0,
           'int() rundet NICHT, sondern schneidet alles nach dem Punkt einfach ab.',
           why='Zum Runden gibt es round(7.9) – das ergibt 8.'),
    choice('Was gibt dieser Code aus?',
           'print("3" + "4")\nprint(int("3") + int("4"))', ['34\n7', '7\n7', '34\n34'], 0,
           'Bei Texten bedeutet + „zusammenkleben“, bei Zahlen „addieren“. Der Typ entscheidet!',
           {1: 'Zwei Texte → zusammenkleben.', 2: 'Zwei Zahlen → addieren.'}),
    fill('Wandle die ganze Zahl in eine Kommazahl um.',
         'x = 4\nprint(' + B + '(x))', ['float'],
         'float() macht aus 4 die Kommazahl 4.0.',
         hint='Kommazahlen heißen in Python …'),
])

# ---------------------------------------------------------------- 6
lesson('l06_strings', 'Strings', 'text',
       'Ein String ist ein Text. Jedes Zeichen hat eine Nummer (Index), und das Zählen beginnt bei 0! '
       'Mit text[0] bekommst du das erste Zeichen, mit text[-1] das letzte, mit len(text) die Länge.', [
    fill('Gib das erste Zeichen von wort aus.',
         'wort = "Banane"\nprint(wort[' + B + '])', ['0'],
         'Python fängt beim Zählen mit 0 an. Das B hat den Index 0, das a den Index 1 usw.',
         {2: 'In den eckigen Klammern steht die Nummer des Zeichens.'},
         'Python zählt nicht ab 1 …'),
    fill('Finde heraus, wie viele Zeichen der Text hat.',
         'text = "Robo"\nprint(' + B + '(text))', ['len'],
         'len kommt von length (Länge). Es zählt alle Zeichen – auch Leerzeichen.'),
    choice('Was gibt dieser Code aus?',
           'tier = "Pinguin"\nprint(tier[-1])', ['n', 'P', 'i'], 0,
           'Negative Zahlen zählen von hinten: -1 ist das letzte Zeichen, -2 das vorletzte.'),
    choice('Was gibt dieser Code aus?',
           'tier = "Pinguin"\nprint(tier[0:4])', ['Ping', 'Pingu', 'ingu'], 0,
           'Mit [start:ende] schneidest du ein Stück heraus. Das Zeichen bei „ende“ gehört NICHT mehr dazu.',
           {2: 'Zeichen 0, 1, 2 und 3 – die 4 nicht mehr.'},
           why='Merke: [0:4] liefert 4 Zeichen, nämlich genau 4 - 0.'),
    fill('Prüfe, ob „lern“ im Text vorkommt.',
         'satz = "Ich lerne Python"\nprint("lern" ' + B + ' satz)', ['in'],
         'Mit in fragst du: Steckt dieser Text irgendwo darin? Die Antwort ist True oder False.'),
])

# ---------------------------------------------------------------- 7
lesson('l07_string_methoden', 'String-Methoden', 'auto_fix',
       'Strings haben eingebaute Werkzeuge, sogenannte Methoden. Man schreibt sie mit Punkt: text.upper(). '
       'Wichtig: Sie verändern den alten Text nicht, sondern liefern einen NEUEN.', [
    fill('Gib den Text in GROSSBUCHSTABEN aus.',
         'gruss = "hallo"\nprint(gruss.' + B + '())', ['upper'],
         'Der Punkt bedeutet: „Benutze das Werkzeug von gruss“. upper heißt auf Englisch „oben“ – wie Großbuchstaben auf der Tastatur.',
         {2: 'Methode = Punkt + Name + Klammern.'}),
    fill('Entferne die Leerzeichen am Anfang und Ende.',
         'name = "   Mia   "\nprint(name.' + B + '())', ['strip'],
         'strip() schneidet Leerzeichen an den Rändern ab. Das ist praktisch, wenn jemand aus Versehen Leerzeichen eingetippt hat.'),
    choice('Was gibt dieser Code aus?',
           'text = "Ich mag Äpfel"\nprint(text.replace("Äpfel", "Kekse"))', ['Ich mag Kekse', 'Ich mag Äpfel', 'Kekse'], 0,
           'replace(alt, neu) ersetzt jedes Vorkommen von alt durch neu.'),
    choice('Was gibt dieser Code aus?',
           'obst = "Apfel,Kiwi,Mango"\nprint(obst.split(","))', ["['Apfel', 'Kiwi', 'Mango']", 'Apfel Kiwi Mango', "['Apfel,Kiwi,Mango']"], 0,
           'split() zerteilt einen Text an einem Trennzeichen und liefert eine Liste der Teile.',
           {2: 'Am Komma wird getrennt.'}),
    choice('Was gibt dieser Code aus?',
           'wort = "robo"\nwort.upper()\nprint(wort)', ['robo', 'ROBO', 'Robo'], 0,
           'Ein Text kann nicht verändert werden. upper() erzeugt einen neuen Text – aber in Zeile 2 wird er nirgends gespeichert!',
           {2: 'Das Ergebnis "ROBO" wird nicht gespeichert und geht verloren.', 3: 'wort ist immer noch "robo".'},
           why='Richtig wäre: wort = wort.upper()'),
])

# ---------------------------------------------------------------- 8
lesson('l08_fstrings', 'f-Strings', 'format_quote',
       'Mit einem f vor dem Text kannst du Variablen direkt einsetzen: f"Hallo {name}". '
       'Alles in geschweiften Klammern wird ausgerechnet und eingefügt.', [
    fill('Ergänze den Buchstaben, damit {name} ersetzt wird.',
         'name = "Lea"\nprint(' + B + '"Hallo {name}!")', ['f'],
         'Ohne das f vor dem Anführungszeichen würde Python {name} einfach als Text ausgeben.',
         {2: 'f-String: Variablen in { } werden eingesetzt.'}, 'Ein einziger Buchstabe – f wie format.'),
    fill('Setze die Variable alter in den Text ein.',
         'alter = 10\nprint(f"Ich bin ' + B + ' Jahre alt.")', ['{alter}'],
         'In einem f-String schreibt man den Variablennamen in geschweifte Klammern { }.',
         hint='Geschweifte Klammern um den Namen.'),
    choice('Was gibt dieser Code aus?',
           'a = 4\nb = 5\nprint(f"{a} + {b} = {a + b}")', ['4 + 5 = 9', 'a + b = a + b', '4 + 5 = 45'], 0,
           'In den geschweiften Klammern darf auch gerechnet werden. Außerhalb der Klammern ist alles normaler Text.',
           {3: 'Nur das in { } wird ausgerechnet, das + und = dazwischen ist Text.'}),
    fill('Zeige den Preis mit genau 2 Nachkommastellen.',
         'preis = 2.5\nprint(f"Preis: {preis:' + B + '} Euro")', ['.2f'],
         'Nach einem Doppelpunkt in { } kommt ein Format: .2f bedeutet „Kommazahl mit 2 Stellen nach dem Punkt“.',
         {2: 'Aus 2.5 wird 2.50.'}, 'Punkt, Anzahl der Stellen, f.'),
    choice('Was gibt dieser Code aus?',
           'name = "Max"\nprint("Hallo {name}")', ['Hallo {name}', 'Hallo Max', 'Fehler'], 0,
           'Vorsicht Falle: Hier fehlt das f! Deshalb ist {name} nur ganz normaler Text.',
           why='Mit print(f"Hallo {name}") käme Hallo Max heraus.'),
])

# ---------------------------------------------------------------- 9
lesson('l09_booleans', 'Booleans & Vergleiche', 'toggle',
       'Vergleiche ergeben True oder False: == (gleich), != (ungleich), <, >, <=, >=. '
       'Mit and (beides), or (mindestens eins) und not (Gegenteil) verknüpfst du sie.', [
    choice('Was gibt dieser Code aus?',
           'print(10 > 9)\nprint(10 == 9)', ['True\nFalse', 'False\nTrue', 'True\nTrue'], 0,
           'Ein Vergleich ist wie eine Frage an Python: „Ist 10 größer als 9?“ – Python antwortet mit True oder False.'),
    fill('Prüfe, ob a und b gleich sind.',
         'a = 5\nb = 5\nprint(a ' + B + ' b)', ['=='],
         'Zum Vergleichen braucht man ZWEI Gleichheitszeichen. Eines allein würde etwas speichern.',
         {3: '== fragt: Sind beide Werte gleich?'}, 'Zwei Gleichheitszeichen.'),
    fill('Das Ergebnis soll nur True sein, wenn BEIDE Bedingungen stimmen.',
         'alter = 12\nhat_ticket = True\nprint(alter >= 10 ' + B + ' hat_ticket)', ['and'],
         'and ist nur True, wenn links UND rechts True ist. Wie bei: „Du darfst rein, wenn du alt genug bist und ein Ticket hast.“'),
    choice('Was gibt dieser Code aus?',
           'regen = False\nprint(not regen)', ['True', 'False', 'regen'], 0,
           'not dreht einen Wahrheitswert um: aus False wird True und umgekehrt.'),
    choice('Was gibt dieser Code aus?',
           'print(bool(0), bool(7), bool(""), bool("Hi"))', ['False True False True', 'True True True True', 'False False False False'], 0,
           'Für Python zählen 0 und leere Texte als „falsch“. Alles andere zählt als „wahr“.',
           why='Das ist praktisch bei if: if name: prüft, ob name nicht leer ist.'),
])

# ---------------------------------------------------------------- 10
lesson('l10_if', 'if / elif / else', 'call_split',
       'Mit if entscheidet dein Programm: Wenn die Bedingung True ist, läuft der eingerückte Code. '
       'elif prüft eine weitere Bedingung, else fängt alle anderen Fälle auf. Die Einrückung (4 Leerzeichen) zeigt, was dazugehört!', [
    fill('Ergänze das Schlüsselwort, damit die Bedingung geprüft wird.',
         'temperatur = 30\n' + B + ' temperatur > 25:\n    print("Ab ins Freibad!")', ['if'],
         'Nach if kommt die Bedingung und dann ein Doppelpunkt. Der eingerückte Teil läuft nur, wenn die Bedingung True ist.',
         {2: 'Bedingung + Doppelpunkt am Ende.', 3: 'Eingerückt → gehört zum if.'}),
    fill('Ergänze, was am Ende der if-Zeile fehlt.',
         'punkte = 100\nif punkte == 100' + B + '\n    print("Volle Punktzahl!")', [':'],
         'Jede if-Zeile endet mit einem Doppelpunkt. Er sagt: „Jetzt kommt der Block, der dazugehört.“',
         hint='Ein Satzzeichen mit zwei Punkten übereinander.', output=True),
    choice('Was gibt dieser Code aus?',
           'x = 7\nif x > 10:\n    print("groß")\nelif x > 5:\n    print("mittel")\nelse:\n    print("klein")',
           ['mittel', 'groß', 'klein'], 0,
           'Python prüft von oben nach unten. Sobald eine Bedingung True ist, wird NUR dieser Teil ausgeführt – der Rest wird übersprungen.',
           {2: '7 > 10? Nein → weiter.', 4: '7 > 5? Ja! → dieser Teil läuft.', 6: 'else wird übersprungen, weil schon ein Teil gepasst hat.'},
           why='Probier den Probelauf: Du siehst genau, welche Bedingung True ist.'),
    fill('Ergänze den Teil für alle anderen Fälle.',
         'alter = 8\nif alter >= 18:\n    print("Erwachsen")\n' + B + ':\n    print("Kind")', ['else'],
         'else hat KEINE Bedingung. Es läuft immer dann, wenn alle Bedingungen davor False waren.'),
    order('Ordne die Zeilen: Wenn zahl gerade ist, soll „gerade“ erscheinen, sonst „ungerade“.',
          ['zahl = 4', 'if zahl % 2 == 0:', '    print("gerade")', 'else:', '    print("ungerade")'],
          'Zuerst braucht die Variable einen Wert. Dann kommt if mit seinem eingerückten Teil, danach else mit seinem.',
          hint='Die eingerückten Zeilen gehören direkt unter die Zeile mit Doppelpunkt.'),
])

# ---------------------------------------------------------------- 11
lesson('l11_while', 'while-Schleifen', 'loop',
       'Eine while-Schleife wiederholt Code, SOLANGE die Bedingung True ist. '
       'Ganz wichtig: Irgendwann muss die Bedingung False werden – sonst läuft die Schleife für immer! '
       'break beendet eine Schleife sofort, continue springt zur nächsten Runde.', [
    fill('Ergänze das Schlüsselwort für die Schleife.',
         'i = 1\n' + B + ' i <= 3:\n    print(i)\n    i += 1', ['while'],
         'while heißt „solange“. Solange i höchstens 3 ist, wird der eingerückte Teil wiederholt.',
         {1: 'Startwert.', 2: 'Wird vor jeder Runde geprüft.', 4: 'Ohne diese Zeile wäre i immer 1 → Endlosschleife!'}),
    fill('Ohne diese Zeile würde die Schleife nie enden. Ergänze sie.',
         'zaehler = 0\nwhile zaehler < 3:\n    print("Runde", zaehler)\n    zaehler ' + B + ' 1', ['+='],
         'x += 1 ist eine Abkürzung für x = x + 1. So wird zaehler jede Runde größer, bis die Bedingung False ist.',
         hint='Plus und Gleich zusammen.'),
    choice('Was gibt dieser Code aus?',
           'n = 10\nwhile n > 0:\n    n -= 4\nprint(n)', ['-2', '2', '0'], 0,
           'Die Schleife läuft weiter, bis n > 0 nicht mehr stimmt: 10 → 6 → 2 → -2. Bei -2 ist Schluss.',
           {2: 'Diese Bedingung wird vor jeder Runde neu geprüft.'},
           why='Schau im Probelauf, wie n Runde für Runde kleiner wird.'),
    fill('Beende die Schleife sofort, wenn i 3 ist.',
         'i = 0\nwhile i < 10:\n    i += 1\n    if i == 3:\n        ' + B + '\n    print(i)', ['break'],
         'break bricht die Schleife sofort ab – auch wenn die Bedingung noch True wäre.',
         {5: 'Hier soll die Schleife abbrechen.'}),
    choice('Was gibt dieser Code aus?',
           'i = 0\nwhile i < 5:\n    i += 1\n    if i == 2:\n        continue\n    print(i, end=" ")',
           ['1 3 4 5 ', '1 2 3 4 5 ', '1 '], 0,
           'continue überspringt den Rest der aktuellen Runde. Bei i == 2 wird print also ausgelassen, danach geht es normal weiter.',
           {5: 'Springt direkt zurück zur while-Zeile.', 6: 'end=" " schreibt ein Leerzeichen statt einer neuen Zeile.'}),
])

# ---------------------------------------------------------------- 12
lesson('l12_for', 'for-Schleifen', 'repeat',
       'Eine for-Schleife geht der Reihe nach durch alle Elemente – zum Beispiel durch eine Liste, einen Text oder range(). '
       'range(5) liefert die Zahlen 0, 1, 2, 3, 4.', [
    fill('Gib jede Farbe aus der Liste aus.',
         'farben = ["rot", "grün", "blau"]\n' + B + ' farbe in farben:\n    print(farbe)', ['for'],
         'for farbe in farben bedeutet: Nimm nacheinander jedes Element und lege es in die Variable farbe.',
         {2: 'In jeder Runde bekommt farbe den nächsten Wert.', 3: 'Wird für jede Farbe einmal ausgeführt.'}),
    fill('Wiederhole den Gruß 3-mal.',
         'for i in ' + B + '(3):\n    print("Hallo")', ['range'],
         'range(3) erzeugt die Zahlen 0, 1, 2 – also genau 3 Runden.'),
    choice('Was gibt dieser Code aus?',
           'for i in range(1, 4):\n    print(i, end=" ")', ['1 2 3 ', '1 2 3 4 ', '0 1 2 3 '], 0,
           'range(start, ende) beginnt bei start und hört VOR ende auf. Die 4 ist also nicht dabei.'),
    choice('Was gibt dieser Code aus?',
           'summe = 0\nfor zahl in [2, 4, 6]:\n    summe += zahl\nprint(summe)', ['12', '6', '246'], 0,
           'Die Schleife addiert jede Zahl zur Summe: 0 + 2 = 2, 2 + 4 = 6, 6 + 6 = 12.',
           {1: 'Startwert 0 – wichtig, sonst kann man nichts addieren.', 3: 'Jede Runde kommt eine Zahl dazu.', 4: 'Steht NICHT eingerückt → erst nach der Schleife.'},
           why='Würde print eingerückt sein, käme jede Zwischensumme einzeln heraus.'),
    order('Ordne die Zeilen, damit die Buchstaben von „Hi“ einzeln untereinander erscheinen und danach „fertig“.',
          ['for buchstabe in "Hi":', '    print(buchstabe)', 'print("fertig")'],
          'Was eingerückt ist, wiederholt sich. Was danach nicht eingerückt ist, läuft nur einmal am Ende.'),
])

# ---------------------------------------------------------------- 13
lesson('l13_listen', 'Listen', 'list',
       'Eine Liste speichert mehrere Werte in einer Variablen: tiere = ["Hund", "Katze"]. '
       'Wie bei Texten beginnt der Index bei 0. Listen kann man verändern.', [
    fill('Erstelle eine Liste mit drei Zahlen.',
         'zahlen = ' + B + '1, 2, 3]\nprint(zahlen)', ['['],
         'Listen stehen in eckigen Klammern [ ]. Die Elemente werden durch Kommas getrennt.',
         hint='Schau dir das Zeichen am Ende an.'),
    fill('Gib das zweite Element („Katze“) aus.',
         'tiere = ["Hund", "Katze", "Maus"]\nprint(tiere[' + B + '])', ['1'],
         'Das erste Element hat den Index 0, das zweite also den Index 1.',
         {1: 'Index:  0       1        2'}),
    fill('Ersetze „Maus“ durch „Hamster“.',
         'tiere = ["Hund", "Katze", "Maus"]\ntiere[' + B + '] = "Hamster"\nprint(tiere)', [['2', '-1']],
         'Mit liste[index] = neuer_wert tauschst du ein Element aus. Bei Texten geht das nicht – bei Listen schon!'),
    choice('Was gibt dieser Code aus?',
           'l = ["a", "b", "c", "d"]\nprint(len(l))\nprint(l[1:3])', ["4\n['b', 'c']", "3\n['b', 'c', 'd']", "4\n['a', 'b', 'c']"], 0,
           'len() zählt die Elemente. [1:3] schneidet Index 1 und 2 heraus – genau wie bei Texten.'),
    choice('Was gibt dieser Code aus?',
           'einkauf = ["Milch", "Brot"]\nprint("Käse" in einkauf)', ['False', 'True', 'Käse'], 0,
           'Mit in prüfst du, ob ein Element in der Liste steht.'),
])

# ---------------------------------------------------------------- 14
lesson('l14_listen_methoden', 'Listen-Methoden', 'playlist_add',
       'Listen haben viele Methoden: append() hängt hinten an, insert() fügt an einer Stelle ein, remove() entfernt, '
       'pop() nimmt ein Element heraus und sort() sortiert. Anders als bei Texten ändern sie die Liste direkt!', [
    fill('Hänge „Kiwi“ hinten an die Liste an.',
         'obst = ["Apfel", "Banane"]\nobst.' + B + '("Kiwi")\nprint(obst)', ['append'],
         'append heißt „anhängen“. Das neue Element kommt immer ans Ende.',
         {2: 'Die Liste obst wird direkt verändert.'}),
    fill('Entferne „Banane“ aus der Liste.',
         'obst = ["Apfel", "Banane", "Kiwi"]\nobst.' + B + '("Banane")\nprint(obst)', ['remove'],
         'remove(wert) sucht den Wert und entfernt ihn. Gibt es ihn nicht, meldet Python einen Fehler.'),
    choice('Was gibt dieser Code aus?',
           'z = [5, 2, 9, 1]\nz.sort()\nprint(z)', ['[1, 2, 5, 9]', '[9, 5, 2, 1]', '[5, 2, 9, 1]'], 0,
           'sort() sortiert die Liste aufsteigend – also vom kleinsten zum größten Wert.',
           why='Für absteigend: z.sort(reverse=True)'),
    choice('Was gibt dieser Code aus?',
           'l = ["a", "b", "c"]\nx = l.pop()\nprint(x, l)', ["c ['a', 'b']", "a ['b', 'c']", "c ['a', 'b', 'c']"], 0,
           'pop() ohne Index nimmt das LETZTE Element heraus und gibt es zurück. Die Liste wird dabei kürzer.'),
    order('Ordne: Erst eine leere Liste, dann zwei Namen anhängen, dann ausgeben – sodass [\'Ali\', \'Bea\'] herauskommt.',
          ['namen = []', 'namen.append("Ali")', 'namen.append("Bea")', 'print(namen)'],
          'Eine Variable muss existieren, bevor man sie benutzt. Und append() hängt immer hinten an – die Reihenfolge der Zeilen bestimmt die Reihenfolge in der Liste.'),
])

# ---------------------------------------------------------------- 15
lesson('l15_tupel', 'Tupel', 'lock',
       'Ein Tupel ist wie eine Liste, aber in runden Klammern – und es kann NICHT verändert werden. '
       'Das ist praktisch für Werte, die zusammengehören und gleich bleiben sollen, z. B. Koordinaten.', [
    fill('Erstelle ein Tupel mit drei Farben.',
         'farben = ' + B + '"rot", "gelb", "grün")\nprint(farben)', ['('],
         'Tupel stehen in runden Klammern ( ). Listen dagegen in eckigen [ ].'),
    choice('Was gibt dieser Code aus?',
           'punkt = (3, 7)\nprint(punkt[1])', ['7', '3', '(3, 7)'], 0,
           'Auf Elemente eines Tupels greift man genauso zu wie bei einer Liste – mit Index ab 0.'),
    choice('Was passiert bei diesem Code?',
           'punkt = (3, 7)\npunkt[0] = 5',
           ['Python meldet einen TypeError', 'punkt wird zu (5, 7)', 'punkt wird zu (3, 5)'], 0,
           'Tupel sind unveränderlich. Der Versuch, ein Element zu ändern, führt zu einem Fehler.',
           {2: 'Hier versucht der Code, das Tupel zu ändern.'},
           why='Wenn du doch etwas ändern musst: liste = list(punkt), ändern, dann punkt = tuple(liste).',
           is_output=False),
    fill('Packe das Tupel in zwei Variablen aus.',
         'tier = ("Hund", 4)\nname, ' + B + ' = tier\nprint(name, "hat", beine, "Beine")', ['beine'],
         'Beim Auspacken bekommt jede Variable links der Reihe nach einen Wert aus dem Tupel. Links müssen gleich viele Namen stehen wie Werte im Tupel.',
         {2: 'name bekommt "Hund", die zweite Variable bekommt 4.'}),
    choice('Was gibt dieser Code aus?',
           'x = ("allein",)\nprint(type(x))', ["<class 'tuple'>", "<class 'str'>", "<class 'list'>"], 0,
           'Ein Tupel mit nur einem Element braucht ein Komma! Ohne Komma wären die Klammern nur normale Klammern um einen Text.'),
])

# ---------------------------------------------------------------- 16
lesson('l16_sets', 'Sets', 'bubble_chart',
       'Ein Set (Menge) speichert jeden Wert nur EINMAL und hat keine feste Reihenfolge. '
       'Man schreibt es in geschweiften Klammern: {"a", "b"}. Praktisch zum Entfernen von Doppelten!', [
    choice('Was gibt dieser Code aus?',
           'zahlen = {1, 2, 2, 3, 3, 3}\nprint(len(zahlen))', ['3', '6', '1'], 0,
           'In einem Set gibt es keine Doppelten. Aus 1, 2, 2, 3, 3, 3 bleiben nur 1, 2 und 3 übrig.'),
    fill('Füge „Kiwi“ zum Set hinzu.',
         'obst = {"Apfel"}\nobst.' + B + '("Kiwi")\nprint(len(obst))', ['add'],
         'Bei Sets heißt die Methode add() – nicht append(), weil es kein „hinten“ gibt.'),
    fill('Prüfe, ob „Mango“ im Set ist.',
         'obst = {"Apfel", "Kiwi"}\nprint("Mango" ' + B + ' obst)', ['in'],
         'Mit in kann man sehr schnell prüfen, ob etwas in einem Set enthalten ist.'),
    fill('Entferne die doppelten Namen, indem du die Liste in ein Set umwandelst.',
         'namen = ["Ali", "Bea", "Ali"]\neinmalig = ' + B + '(namen)\nprint(len(einmalig))', ['set'],
         'set(liste) macht aus einer Liste ein Set – dabei verschwinden alle Doppelten automatisch.'),
    choice('Was passiert bei diesem Code?',
           'farben = {"rot", "blau"}\nprint(farben[0])',
           ['Python meldet einen TypeError', 'rot', 'blau'], 0,
           'Sets haben keine Reihenfolge – deshalb gibt es auch keinen Index wie [0].',
           why='Um alle Elemente zu sehen, nimmst du eine for-Schleife: for f in farben: print(f)',
           is_output=False),
])

# ---------------------------------------------------------------- 17
lesson('l17_dicts', 'Dictionaries', 'menu_book',
       'Ein Dictionary (Wörterbuch) speichert Paare aus Schlüssel und Wert: {"name": "Mia", "alter": 9}. '
       'Über den Schlüssel findest du den Wert – wie in einem Wörterbuch über das Stichwort.', [
    fill('Gib den Wert zum Schlüssel „name“ aus.',
         'person = {"name": "Mia", "alter": 9}\nprint(person[' + B + '])', [['"name"', "'name'"]],
         'Statt einer Nummer steht in den eckigen Klammern der Schlüssel – hier ein Text, also mit Anführungszeichen.',
         {1: 'Schlüssel : Wert, getrennt durch Kommas.'}),
    fill('Ändere das Alter auf 10.',
         'person = {"name": "Mia", "alter": 9}\nperson["alter"] ' + B + ' 10\nprint(person)', ['='],
         'Mit dict[schlüssel] = wert änderst du einen Wert. Gibt es den Schlüssel noch nicht, wird er neu angelegt.'),
    choice('Was gibt dieser Code aus?',
           'tier = {"art": "Hund"}\ntier["farbe"] = "braun"\nprint(len(tier))', ['2', '1', '3'], 0,
           'Den Schlüssel „farbe“ gab es noch nicht – also wird ein neues Paar hinzugefügt. Jetzt sind es zwei Paare.'),
    fill('Hole den Wert sicher – ohne Fehler, falls der Schlüssel fehlt.',
         'auto = {"marke": "VW"}\nprint(auto.' + B + '("farbe"))', ['get'],
         'auto["farbe"] würde einen KeyError auslösen. get() gibt stattdessen None zurück, wenn der Schlüssel fehlt.',
         why='Mit auto.get("farbe", "unbekannt") bekommst du statt None einen eigenen Ersatzwert.'),
    order('Ordne die Zeilen, damit jedes Paar als „name: Mia“ und „alter: 9“ erscheint.',
          ['person = {"name": "Mia", "alter": 9}', 'for schluessel, wert in person.items():', '    print(f"{schluessel}: {wert}")'],
          'items() liefert alle Paare. In der for-Schleife packst du jedes Paar in zwei Variablen aus: Schlüssel und Wert.'),
])

# ---------------------------------------------------------------- 18
lesson('l18_funktionen', 'Funktionen', 'functions',
       'Eine Funktion ist ein Stück Code mit Namen, das du immer wieder aufrufen kannst. '
       'Mit def definierst du sie, mit name() rufst du sie auf. Parameter sind Werte, die du mitgibst, '
       'und return gibt ein Ergebnis zurück.', [
    fill('Ergänze das Schlüsselwort, mit dem man eine Funktion definiert.',
         B + ' winken():\n    print("Hallo! *wink*")\n\nwinken()', ['def'],
         'def kommt von define (festlegen). Der Code in der Funktion läuft erst, wenn sie aufgerufen wird – hier in Zeile 4.',
         {1: 'Hier wird die Funktion nur festgelegt – noch nicht ausgeführt!', 4: 'Erst hier wird sie aufgerufen.'},
         why='Im Probelauf siehst du: Python springt von Zeile 4 in die Funktion hinein.'),
    fill('Rufe die Funktion mit dem Namen „Ali“ auf.',
         'def begruesse(name):\n    print("Hallo", name)\n\nbegruesse(' + B + ')', [['"Ali"', "'Ali'"]],
         'Der Wert in den Klammern beim Aufruf landet im Parameter name. So kann dieselbe Funktion verschiedene Leute begrüßen.',
         {1: 'name ist ein Parameter – ein Platzhalter für den Wert beim Aufruf.'}),
    fill('Gib das Ergebnis der Rechnung aus der Funktion zurück.',
         'def doppelt(zahl):\n    ' + B + ' zahl * 2\n\nprint(doppelt(21))', ['return'],
         'return schickt einen Wert zurück an die Stelle, wo die Funktion aufgerufen wurde. Ohne return käme None zurück.'),
    choice('Was gibt dieser Code aus?',
           'def plus(a, b=10):\n    return a + b\n\nprint(plus(5))\nprint(plus(5, 1))', ['15\n6', '5\n6', '15\n15'], 0,
           'b=10 ist ein Standardwert. Wird beim Aufruf nichts für b angegeben, nimmt Python die 10.',
           {1: 'b hat den Standardwert 10.', 4: 'Nur a wird übergeben → b ist 10.', 5: 'b wird übergeben → b ist 1.'}),
    choice('Was gibt dieser Code aus?',
           'x = 1\ndef aendern():\n    x = 99\n\naendern()\nprint(x)', ['1', '99', 'None'], 0,
           'Eine Variable, die IN einer Funktion einen Wert bekommt, ist lokal – sie existiert nur in der Funktion. Das x draußen bleibt unverändert.',
           {3: 'Dieses x ist ein neues, lokales x – nur innerhalb von aendern().'},
           why='Möchtest du das äußere x ändern, schreibe in der Funktion zuerst: global x'),
])

# ---------------------------------------------------------------- 19
lesson('l19_lambda', 'Lambda', 'bolt',
       'Ein lambda ist eine kleine Funktion ohne Namen in einer einzigen Zeile: lambda x: x * 2. '
       'Vor dem Doppelpunkt stehen die Parameter, dahinter das Ergebnis – ganz ohne return.', [
    fill('Ergänze das Schlüsselwort für eine Mini-Funktion.',
         'mal3 = ' + B + ' x: x * 3\nprint(mal3(4))', ['lambda'],
         'Mit lambda baust du eine Funktion in einer Zeile. Sie wird hier in der Variable mal3 gespeichert und dann wie eine normale Funktion aufgerufen.',
         {1: 'x ist der Parameter, x * 3 das Ergebnis.'}),
    fill('Die Funktion soll zwei Zahlen addieren.',
         'addiere = lambda a, ' + B + ': a + b\nprint(addiere(2, 5))', ['b'],
         'Ein lambda kann mehrere Parameter haben. Sie werden durch Kommas getrennt – genau wie bei def.'),
    choice('Was gibt dieser Code aus?',
           'quadrat = lambda n: n * n\nprint(quadrat(6))', ['36', '12', '66'], 0,
           'Das lambda rechnet n * n. Mit 6 aufgerufen ergibt das 36.'),
    choice('Was gibt dieser Code aus?',
           'def macher(n):\n    return lambda a: a * n\n\nverdreifacher = macher(3)\nprint(verdreifacher(5))', ['15', '8', '3'], 0,
           'macher(3) liefert ein lambda, das sich n = 3 merkt. Ruft man es mit 5 auf, rechnet es 5 * 3.',
           {2: 'Das lambda wird zurückgegeben – und merkt sich n.', 4: 'verdreifacher ist jetzt eine Funktion!'}),
    fill('Sortiere die Wörter nach ihrer Länge.',
         'woerter = ["Elefant", "Hai", "Katze"]\nprint(sorted(woerter, key=lambda w: ' + B + '(w)))', ['len'],
         'key= sagt sorted(), wonach sortiert werden soll. Das lambda liefert für jedes Wort seine Länge.'),
])

# ---------------------------------------------------------------- 20
lesson('l20_iteratoren', 'Iteratoren', 'skip_next',
       'Ein Iterator gibt dir die Elemente einer Sammlung einzeln, eines nach dem anderen. '
       'Mit iter() erstellst du ihn, mit next() holst du das nächste Element. Eine for-Schleife macht genau das im Hintergrund!', [
    fill('Erstelle einen Iterator aus dem Tupel.',
         'obst = ("Apfel", "Kiwi", "Mango")\nmein_iter = ' + B + '(obst)\nprint(next(mein_iter))', ['iter'],
         'iter() verwandelt eine Sammlung in einen Iterator. Er merkt sich, wie weit er schon gekommen ist.'),
    fill('Hole das nächste Element aus dem Iterator.',
         'it = iter(["a", "b"])\nprint(next(it))\nprint(' + B + '(it))', ['next'],
         'Jedes next() holt das nächste Element. Der Iterator merkt sich die Position – deshalb kommt beim zweiten Mal „b“.'),
    choice('Was gibt dieser Code aus?',
           'it = iter("Hey")\nnext(it)\nprint(next(it))', ['e', 'H', 'y'], 0,
           'Auch Texte kann man durchlaufen. Das erste next() holt „H“ (wird aber nicht ausgegeben), das zweite holt „e“.',
           {2: 'Holt "H" – das Ergebnis wird nicht gespeichert.', 3: 'Holt das nächste Zeichen.'}),
    choice('Was passiert bei diesem Code?',
           'it = iter([1])\nprint(next(it))\nprint(next(it))',
           ['Erst 1, dann StopIteration-Fehler', '1 und dann nochmal 1', '1 und dann None'], 0,
           'Wenn ein Iterator leer ist, meldet next() den Fehler StopIteration. Eine for-Schleife fängt das automatisch ab und hört einfach auf.',
           is_output=False),
    order('Ordne die Zeilen, damit „rot“ und dann „blau“ ausgegeben wird.',
          ['farben = ["rot", "blau"]', 'it = iter(farben)', 'print(next(it))', 'print(next(it))'],
          'Zuerst braucht man die Liste, dann den Iterator daraus. Erst dann kann next() Elemente holen.'),
])


# Weitere Inseln stehen in tool/lessons/*.py (gleiche Hilfsfunktionen).
for _path in sorted(glob.glob(os.path.join(os.path.dirname(__file__), 'lessons', '*.py'))):
    exec(compile(open(_path, encoding='utf-8').read(), _path, 'exec'), globals())


def ordered():
    """Reihenfolge wie im W3Schools-Python-Tutorial, gruppiert in Kapitel."""
    result = []
    seen = set()
    for chapter, ids in CURRICULUM:
        for i in ids:
            assert i in LESSONS, f'Insel {i} fehlt'
            assert i not in seen, i
            seen.add(i)
            result.append(dict(LESSONS[i], order=len(result) + 1, chapter=chapter))
    missing = set(LESSONS) - seen
    assert not missing, f'Nicht im Lehrplan: {missing}'
    return result


def main():
    os.makedirs(OUT, exist_ok=True)
    for f in os.listdir(OUT):
        if f.endswith('.json'):
            os.remove(os.path.join(OUT, f))
    total = 0
    lessons = ordered()
    for l in lessons:
        for ex in l['exercises']:
            ex['notes'] = {str(k): v for k, v in ex.get('notes', {}).items()}
        with open(os.path.join(OUT, f"{l['id']}.json"), 'w') as f:
            json.dump(l, f, ensure_ascii=False, indent=2)
        total += len(l['exercises'])
    print(f'{len(lessons)} Lektionen mit {total} Aufgaben geschrieben.')


if __name__ == '__main__':
    main()
