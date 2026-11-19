# Kapitel Strings + Booleans & Operatoren (neue Inseln)

lesson('str_slicing', 'Strings schneiden', 'content_cut',
       'Mit text[start:ende] schneidest du ein Stück aus einem Text. Der Start ist dabei, das Ende NICHT mehr. '
       'Lässt du den Start weg, geht es von vorn los; lässt du das Ende weg, bis zum Schluss. Negative Zahlen zählen von hinten.', [
    fill('Schneide „llo“ aus „Hello, World!“ (Position 2 bis vor 5).',
         'b = "Hello, World!"\nprint(b[2:' + B + '])', ['5'],
         'b[2:5] nimmt die Zeichen an Position 2, 3 und 4. Position 5 ist schon nicht mehr dabei.',
         {2: 'Start 2 ist dabei, Ende 5 nicht mehr.'}),
    choice('Was gibt dieser Code aus?',
           'b = "Hello, World!"\nprint(b[:5])', ['Hello', 'Hello,', 'World'], 0,
           'Ohne Startwert beginnt der Ausschnitt ganz vorn (Position 0) und endet vor Position 5.'),
    choice('Was gibt dieser Code aus?',
           'b = "Hello, World!"\nprint(b[7:])', ['World!', ' World!', 'Hello, '], 0,
           'Ohne Endwert geht der Ausschnitt bis zum Ende. Position 7 ist das W.'),
    fill('Nimm die letzten 3 Zeichen mit einer negativen Zahl.',
         'wort = "Python"\nprint(wort[' + B + ':])', ['-3'],
         'Negative Positionen zählen von hinten: -1 ist das letzte Zeichen, -3 das drittletzte.'),
    choice('Was gibt dieser Code aus?',
           'b = "Hello, World!"\nprint(b[-5:-2])', ['orl', 'World', 'rld'], 0,
           '-5 ist das o in World, -2 ist das d. Das Ende ist nicht dabei, also bleibt „orl“.',
           {2: 'Von -5 (o) bis vor -2 (d).'}),
])

lesson('str_concat', 'Strings verbinden', 'link',
       'Mit + hängst du Texte aneinander: "Robo" + "ter" ergibt "Roboter". '
       'Ein Leerzeichen musst du selbst einfügen. Mit * wiederholst du einen Text: "ha" * 3 ergibt "hahaha".', [
    fill('Verbinde a und b zu einem Text.',
         'a = "Hallo"\nb = "Welt"\nc = a ' + B + ' b\nprint(c)', ['+'],
         'Das + verbindet zwei Texte zu einem neuen Text. Ohne Leerzeichen kleben sie direkt zusammen.'),
    fill('Füge ein Leerzeichen zwischen die Wörter.',
         'a = "Hallo"\nb = "Welt"\nc = a + ' + B + ' + b\nprint(c)', [['" "', "' '"]],
         'Ein Leerzeichen ist auch ein Text: " ". Man hängt es einfach in die Mitte.'),
    choice('Was gibt dieser Code aus?',
           'print("ha" * 3)', ['hahaha', 'ha3', 'ha ha ha'], 0,
           'Text mal Zahl wiederholt den Text so oft.'),
    choice('Was gibt dieser Code aus?',
           'vorname = "Ada"\nnachname = "Lovelace"\nprint(vorname + nachname)', ['AdaLovelace', 'Ada Lovelace', 'vorname nachname'], 0,
           'Ohne Leerzeichen dazwischen kleben die Texte direkt aneinander.'),
    choice('Was passiert bei diesem Code?',
           'alter = 12\nprint("Ich bin " + alter)', ['TypeError: Text + Zahl', 'Ich bin 12', 'Ich bin alter'], 0,
           'Text und Zahl kann man nicht mit + verbinden. Lösung: "Ich bin " + str(alter) oder ein f-String.',
           is_output=False),
])

lesson('str_escape', 'Sonderzeichen (Escape)', 'keyboard_return',
       'Manche Zeichen kann man nicht einfach in einen Text schreiben – z. B. ein Anführungszeichen mitten im Text. '
       'Dafür gibt es den Backslash \\. \\" ist ein Anführungszeichen, \\n eine neue Zeile, \\t ein Tabulator und \\\\ ein Backslash.', [
    fill('Setze die Anführungszeichen im Text mit Backslash richtig.',
         'txt = "Wir sind die sogenannten ' + B + 'Wikinger' + B + ' aus dem Norden."\nprint(txt)', ['\\"', '\\"'],
         'Mit \\" weiß Python: Dieses Anführungszeichen gehört zum Text und beendet ihn nicht.',
         hint='Backslash + Anführungszeichen.'),
    choice('Was gibt dieser Code aus?',
           'print("Hallo\\nWelt")', ['Hallo\nWelt', 'Hallo\\nWelt', 'HalloWelt'], 0,
           '\\n bedeutet „neue Zeile“. Deshalb steht Welt in der nächsten Zeile.'),
    choice('Was gibt dieser Code aus?',
           "print('It\\'s Robo')", ["It's Robo", "It\\'s Robo", 'Its Robo'], 0,
           "Im Text mit einfachen Anführungszeichen braucht ein Apostroph einen Backslash: \\'."),
    fill('Füge zwischen die Wörter einen Tabulator ein.',
         'print("Name' + B + 'Alter")', ['\\t'],
         '\\t ist ein Tabulator – ein großer Abstand, wie mit der Tab-Taste.'),
    choice('Was gibt dieser Code aus?',
           'print("C:\\\\Ordner")', ['C:\\Ordner', 'C:\\\\Ordner', 'C:Ordner'], 0,
           'Ein einzelner Backslash wird als \\\\ geschrieben, weil der Backslash sonst ein Sonderzeichen einleitet.'),
])

lesson('str_methods', 'Weitere String-Methoden', 'build',
       'Texte haben viele nützliche Methoden: count() zählt, find() sucht, startswith() prüft den Anfang, '
       'isdigit() prüft, ob nur Ziffern drin sind, title() macht Wortanfänge groß und zfill() füllt mit Nullen auf. '
       'Wichtig: Methoden ändern den Text nicht – sie liefern einen neuen.', [
    fill('Zähle, wie oft „a“ in „Banana“ vorkommt.',
         'print("Banana".' + B + '("a"))', ['count'],
         'count() zählt, wie oft ein Text darin vorkommt. In Banana steht a dreimal.'),
    choice('Was gibt dieser Code aus?',
           'print("Hallo Welt".find("W"))', ['6', '7', '-1'], 0,
           'find() liefert die Position des ersten Treffers. Gezählt wird ab 0: H=0, a=1, … W=6. Gibt es keinen Treffer, kommt -1.'),
    choice('Was gibt dieser Code aus?',
           'print("hallo welt".title())', ['Hallo Welt', 'HALLO WELT', 'Hallo welt'], 0,
           'title() schreibt den Anfang jedes Wortes groß – wie bei einer Überschrift.'),
    fill('Prüfe, ob der Text nur aus Ziffern besteht.',
         'pin = "4711"\nprint(pin.' + B + '())', ['isdigit'],
         'isdigit() gibt True zurück, wenn ALLE Zeichen Ziffern sind. Sehr praktisch, bevor man mit int() umwandelt.'),
    choice('Was gibt dieser Code aus?',
           'nummer = "7"\nprint(nummer.zfill(3))\nprint("Hi".center(6, "*"))', ['007\n**Hi**', '7\nHi', '700\n*Hi*'], 0,
           'zfill(3) füllt vorne mit Nullen auf 3 Zeichen auf. center(6, "*") setzt den Text in die Mitte und füllt mit * auf.'),
])

# ---------------------------------------------------------------- Operatoren

lesson('operators', 'Operatoren', 'calculate',
       'Operatoren sind Zeichen für Rechnungen und Zuweisungen: + - * / für die Grundrechenarten, // für ganzzahliges Teilen, '
       '% für den Rest und ** für hoch. Mit += -= *= usw. veränderst du eine Variable direkt: x += 3 heißt x = x + 3.', [
    choice('Was gibt dieser Code aus?',
           'print(10 // 3)\nprint(10 % 3)', ['3\n1', '3.33\n1', '3\n0'], 0,
           '// teilt und wirft den Rest weg (10 // 3 = 3). % liefert genau diesen Rest (10 = 3·3 + 1).'),
    fill('Erhöhe x um 3 – in Kurzschreibweise.',
         'x = 5\nx ' + B + ' 3\nprint(x)', ['+='],
         'x += 3 ist die Kurzform von x = x + 3.'),
    fill('Verdopple x mit dem passenden Zuweisungs-Operator.',
         'x = 7\nx ' + B + ' 2\nprint(x)', ['*='],
         'x *= 2 bedeutet x = x * 2.'),
    choice('Was gibt dieser Code aus?',
           'print(2 + 3 * 4)\nprint((2 + 3) * 4)', ['14\n20', '20\n14', '20\n20'], 0,
           'Wie in Mathe: Punkt vor Strich. Klammern werden zuerst ausgerechnet.',
           {1: 'Erst 3 * 4 = 12, dann + 2.', 2: 'Erst die Klammer (5), dann * 4.'}),
    choice('Was gibt dieser Code aus?',
           'print(2 ** 3)\nprint(9 / 3)', ['8\n3.0', '6\n3', '8\n3'], 0,
           '** heißt „hoch“: 2·2·2 = 8. Normales Teilen mit / ergibt immer eine Kommazahl (float), also 3.0.'),
])

lesson('operators_logic', 'Logik, is & in', 'rule',
       'Logische Operatoren verbinden Bedingungen: and (beide wahr), or (mindestens eine wahr), not (dreht um). '
       'Mit in prüfst du, ob etwas in einer Sammlung steckt. is prüft, ob zwei Namen auf GENAU dasselbe Objekt zeigen – '
       '== prüft nur, ob die Werte gleich sind.', [
    choice('Was gibt dieser Code aus?',
           'x = 5\nprint(x > 3 and x < 10)\nprint(x > 3 and x > 10)', ['True\nFalse', 'True\nTrue', 'False\nFalse'], 0,
           'and ist nur True, wenn BEIDE Seiten True sind. In der zweiten Zeile ist x > 10 falsch.'),
    fill('Das Ergebnis soll True sein, wenn MINDESTENS eine Bedingung stimmt.',
         'x = 5\nprint(x < 3 ' + B + ' x > 4)', ['or'],
         'or ist True, sobald eine Seite True ist. Hier ist x > 4 wahr.'),
    choice('Was gibt dieser Code aus?',
           'x = 5\nprint(not(x > 3 and x < 10))', ['False', 'True', 'Fehler'], 0,
           'Die Klammer ergibt True. not dreht das Ergebnis um → False.'),
    fill('Prüfe, ob „Banane“ in der Liste ist.',
         'obst = ["Apfel", "Banane"]\nprint("Banane" ' + B + ' obst)', ['in'],
         'in prüft die Zugehörigkeit: Steckt der Wert in der Sammlung? Das Gegenteil ist not in.'),
    choice('Was gibt dieser Code aus?',
           'a = ["x", "y"]\nb = ["x", "y"]\nc = a\nprint(a == b)\nprint(a is b)\nprint(a is c)', ['True\nFalse\nTrue', 'True\nTrue\nTrue', 'False\nFalse\nTrue'], 0,
           'a und b haben denselben Inhalt (==), sind aber zwei verschiedene Listen. c ist nur ein zweiter Name für a – deshalb ist a is c True.',
           {3: 'c zeigt auf dieselbe Liste wie a.', 5: 'Zwei verschiedene Listen → False.'}),
])

lesson('operators_bit', 'Bit-Operatoren & Rangfolge', 'memory',
       'Computer speichern Zahlen als Bits (0 und 1). Bit-Operatoren arbeiten direkt damit: & (UND), | (ODER), ^ (entweder-oder), '
       '~ (umdrehen), << und >> (verschieben). Und: Es gibt eine feste Rangfolge – ** vor * / vor + - vor Vergleichen vor not, and, or.', [
    choice('Was gibt dieser Code aus?',
           'print(bin(5))\nprint(bin(3))', ['0b101\n0b11', '101\n11', '0b5\n0b3'], 0,
           'bin() zeigt eine Zahl als Bits. 5 ist 4 + 1 → 101. 3 ist 2 + 1 → 11. Das 0b davor bedeutet „binär“.'),
    choice('Was gibt dieser Code aus?',
           'print(6 & 3)', ['2', '9', '7'], 0,
           '6 ist 110, 3 ist 011. & behält nur die Bits, die in BEIDEN 1 sind: 010 = 2.'),
    fill('Verbinde die Bits mit ODER, sodass 7 herauskommt.',
         'print(6 ' + B + ' 3)', ['|'],
         '| setzt ein Bit, wenn es in mindestens einer Zahl 1 ist: 110 | 011 = 111 = 7.'),
    choice('Was gibt dieser Code aus?',
           'print(3 << 2)', ['12', '6', '1'], 0,
           '<< schiebt die Bits nach links. Jede Stelle verdoppelt die Zahl: 3 → 6 → 12.'),
    choice('Was gibt dieser Code aus?',
           'print(100 + 5 * 3)\nprint(5 > 3 or 1 > 2 and 1 > 2)', ['115\nTrue', '315\nTrue', '115\nFalse'], 0,
           '* kommt vor +. Und and wird vor or ausgewertet: erst 1 > 2 and 1 > 2 (False), dann 5 > 3 or False → True.'),
])
