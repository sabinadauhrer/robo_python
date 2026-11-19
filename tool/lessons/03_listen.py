# Kapitel Listen (neue Inseln)

lesson('list_access', 'Auf Listen zugreifen', 'search',
       'Jedes Element einer Liste hat eine Position (Index), beginnend bei 0. Mit liste[1] holst du das zweite Element, '
       'mit liste[-1] das letzte. Mit liste[2:5] bekommst du einen Ausschnitt, und mit in prüfst du, ob etwas drin ist.', [
    fill('Gib das letzte Element aus – mit einem negativen Index.',
         'obst = ["Apfel", "Banane", "Kirsche"]\nprint(obst[' + B + '])', ['-1'],
         'Negative Indizes zählen von hinten. -1 ist immer das letzte Element, egal wie lang die Liste ist.'),
    choice('Was gibt dieser Code aus?',
           'obst = ["Apfel", "Banane", "Kirsche", "Orange", "Kiwi"]\nprint(obst[2:4])', ["['Kirsche', 'Orange']", "['Banane', 'Kirsche', 'Orange']", "['Kirsche', 'Orange', 'Kiwi']"], 0,
           'Der Ausschnitt [2:4] beginnt bei Index 2 und endet VOR Index 4. Das Ergebnis ist wieder eine Liste.'),
    choice('Was gibt dieser Code aus?',
           'obst = ["Apfel", "Banane", "Kirsche", "Orange"]\nprint(obst[:2])\nprint(obst[2:])', ["['Apfel', 'Banane']\n['Kirsche', 'Orange']", "['Apfel']\n['Kirsche', 'Orange']", "['Apfel', 'Banane', 'Kirsche']\n['Orange']"], 0,
           'Ohne Start geht es ab dem Anfang los, ohne Ende bis zum Schluss.'),
    fill('Prüfe, ob „Apfel“ in der Liste steht.',
         'obst = ["Apfel", "Banane"]\nif "Apfel" ' + B + ' obst:\n    print("Ja, Apfel ist dabei!")', ['in'],
         'Mit in fragst du: Ist dieser Wert irgendwo in der Liste? Das Ergebnis ist True oder False.'),
    choice('Was passiert bei diesem Code?',
           'obst = ["Apfel", "Banane"]\nprint(obst[2])', ['IndexError', 'Banane', 'None'], 0,
           'Die Liste hat nur die Indizes 0 und 1. Index 2 gibt es nicht → IndexError.',
           is_output=False),
])

lesson('list_change', 'Listen ändern', 'edit',
       'Listen sind veränderbar. Mit liste[1] = "neu" ersetzt du ein Element. '
       'Mit einem Ausschnitt wie liste[1:3] = ["a", "b"] ersetzt du gleich mehrere – auch durch mehr oder weniger Elemente.', [
    fill('Ersetze das zweite Element durch „Johannisbeere“.',
         'obst = ["Apfel", "Banane", "Kirsche"]\nobst[' + B + '] = "Johannisbeere"\nprint(obst)', ['1'],
         'Das zweite Element hat den Index 1, weil Python bei 0 zu zählen beginnt.'),
    choice('Was gibt dieser Code aus?',
           'obst = ["Apfel", "Banane", "Kirsche", "Orange"]\nobst[1:3] = ["Kiwi", "Melone"]\nprint(obst)', ["['Apfel', 'Kiwi', 'Melone', 'Orange']", "['Kiwi', 'Melone', 'Kirsche', 'Orange']", "['Apfel', 'Kiwi', 'Melone']"], 0,
           'Der Ausschnitt [1:3] (Banane und Kirsche) wird durch die zwei neuen Elemente ersetzt.'),
    choice('Was gibt dieser Code aus?',
           'obst = ["Apfel", "Banane", "Kirsche"]\nobst[1:2] = ["Kiwi", "Melone"]\nprint(obst)', ["['Apfel', 'Kiwi', 'Melone', 'Kirsche']", "['Apfel', 'Kiwi', 'Kirsche']", "['Apfel', 'Kiwi', 'Melone']"], 0,
           'Ersetzt man EIN Element durch ZWEI, wird die Liste länger. Der Rest rückt nach hinten.'),
    choice('Was gibt dieser Code aus?',
           'obst = ["Apfel", "Banane", "Kirsche"]\nobst[1:3] = ["Kiwi"]\nprint(obst)', ["['Apfel', 'Kiwi']", "['Apfel', 'Kiwi', 'Kirsche']", "['Kiwi']"], 0,
           'Zwei Elemente werden durch eines ersetzt – die Liste wird kürzer.'),
    fill('Füge „Wassermelone“ an Position 2 ein, ohne etwas zu ersetzen.',
         'obst = ["Apfel", "Banane", "Kirsche"]\nobst.' + B + '(2, "Wassermelone")\nprint(obst)', ['insert'],
         'insert(position, wert) schiebt ein neues Element an die Stelle. Alles dahinter rückt eins weiter.'),
])

lesson('list_add', 'Elemente hinzufügen', 'add_circle',
       'Es gibt drei Wege, eine Liste zu vergrößern: append() hängt ein Element hinten an, insert() fügt es an einer Position ein, '
       'und extend() hängt alle Elemente einer anderen Sammlung an.', [
    fill('Hänge „Orange“ hinten an.',
         'obst = ["Apfel", "Banane"]\nobst.' + B + '("Orange")\nprint(obst)', ['append'],
         'append() hängt genau ein Element ans Ende der Liste.'),
    fill('Füge „Kiwi“ ganz vorne (Index 0) ein.',
         'obst = ["Apfel", "Banane"]\nobst.insert(' + B + ', "Kiwi")\nprint(obst)', ['0'],
         'Index 0 ist der Anfang der Liste. Alle anderen Elemente rutschen eins nach hinten.'),
    fill('Hänge alle Elemente von tropisch an obst an.',
         'obst = ["Apfel"]\ntropisch = ["Mango", "Ananas"]\nobst.' + B + '(tropisch)\nprint(obst)', ['extend'],
         'extend() packt die Elemente einzeln an das Ende. Mit append() würde die ganze Liste als EIN Element angehängt.'),
    choice('Was gibt dieser Code aus?',
           'a = [1, 2]\na.append([3, 4])\nprint(a)\nprint(len(a))', ['[1, 2, [3, 4]]\n3', '[1, 2, 3, 4]\n4', '[1, 2, [3, 4]]\n4'], 0,
           'append() hängt die Liste [3, 4] als EIN Element an. Deshalb hat a jetzt 3 Elemente.'),
    choice('Was gibt dieser Code aus?',
           'obst = ["Apfel"]\nobst.extend(("Kiwi", "Feige"))\nprint(obst)', ["['Apfel', 'Kiwi', 'Feige']", "['Apfel', ('Kiwi', 'Feige')]", 'Fehler'], 0,
           'extend() nimmt jede Sammlung – auch ein Tupel – und hängt die Elemente einzeln an.'),
])

lesson('list_remove', 'Elemente entfernen', 'remove_circle',
       'remove("x") entfernt das erste Element mit diesem Wert. pop(i) entfernt das Element an Position i (ohne Zahl: das letzte) '
       'und gibt es zurück. del liste[i] löscht eine Position, und clear() leert die ganze Liste.', [
    fill('Entferne „Banane“ über ihren Wert.',
         'obst = ["Apfel", "Banane", "Kirsche"]\nobst.' + B + '("Banane")\nprint(obst)', ['remove'],
         'remove() sucht den Wert und entfernt das erste passende Element.'),
    choice('Was gibt dieser Code aus?',
           'obst = ["Apfel", "Banane", "Kirsche", "Banane"]\nobst.remove("Banane")\nprint(obst)', ["['Apfel', 'Kirsche', 'Banane']", "['Apfel', 'Kirsche']", "['Apfel', 'Banane', 'Kirsche']"], 0,
           'remove() entfernt nur das ERSTE passende Element. Die zweite Banane bleibt.'),
    choice('Was gibt dieser Code aus?',
           'obst = ["Apfel", "Banane", "Kirsche"]\nweg = obst.pop()\nprint(weg)\nprint(obst)', ["Kirsche\n['Apfel', 'Banane']", "Apfel\n['Banane', 'Kirsche']", "None\n['Apfel', 'Banane']"], 0,
           'pop() ohne Zahl entfernt das letzte Element und gibt es zurück – man kann es also noch benutzen.'),
    fill('Lösche das erste Element mit del.',
         'obst = ["Apfel", "Banane", "Kirsche"]\n' + B + ' obst[0]\nprint(obst)', ['del'],
         'del liste[i] löscht das Element an Position i. Mit del liste würde sogar die ganze Variable verschwinden.'),
    fill('Leere die Liste komplett – die Liste selbst soll bleiben.',
         'obst = ["Apfel", "Banane"]\nobst.' + B + '()\nprint(obst)', ['clear'],
         'clear() entfernt alle Elemente. Übrig bleibt eine leere Liste [].'),
])

lesson('list_loop', 'Listen durchlaufen', 'sync',
       'Mit for x in liste: gehst du jedes Element einmal durch. Brauchst du die Position, nimm for i in range(len(liste)): '
       'oder enumerate(). Auch eine while-Schleife mit einem Zähler funktioniert.', [
    fill('Gib jedes Obst einzeln aus.',
         'obst = ["Apfel", "Banane", "Kirsche"]\nfor x ' + B + ' obst:\n    print(x)', ['in'],
         'In jeder Runde bekommt x das nächste Element der Liste.'),
    fill('Laufe über die Indizes der Liste.',
         'obst = ["Apfel", "Banane"]\nfor i in range(' + B + '(obst)):\n    print(i, obst[i])', ['len'],
         'len(obst) ist 2, range(2) liefert 0 und 1 – genau die Indizes der Liste.'),
    choice('Was gibt dieser Code aus?',
           'obst = ["Apfel", "Banane"]\ni = 0\nwhile i < len(obst):\n    print(obst[i])\n    i = i + 1', ['Apfel\nBanane', 'Apfel', 'Banane\nApfel'], 0,
           'Die while-Schleife läuft, solange i kleiner als die Länge ist. Nach jedem Element wird i um 1 erhöht.'),
    choice('Was gibt dieser Code aus?',
           'for nr, tier in enumerate(["Hund", "Katze"]):\n    print(nr, tier)', ['0 Hund\n1 Katze', '1 Hund\n2 Katze', 'Hund 0\nKatze 1'], 0,
           'enumerate() liefert zu jedem Element seine Position mit – beginnend bei 0.'),
    order('Ordne die Zeilen, damit die Summe aller Zahlen (6) ausgegeben wird.',
          ['zahlen = [1, 2, 3]', 'summe = 0', 'for z in zahlen:', '    summe = summe + z', 'print(summe)'],
          'Zuerst braucht man die Liste und eine Summe bei 0. In der Schleife wird jede Zahl addiert, erst danach (nicht eingerückt) wird ausgegeben.'),
])

lesson('list_comp', 'List Comprehension', 'auto_awesome',
       'Eine List Comprehension baut eine neue Liste in einer einzigen Zeile: [ausdruck for x in liste if bedingung]. '
       'Das ist kürzer als eine Schleife mit append(). Die Bedingung am Ende ist optional.', [
    fill('Baue eine Liste mit allen Früchten, die ein „a“ enthalten.',
         'obst = ["Apfel", "Banane", "Kiwi", "Mango"]\nneu = [x for x in obst ' + B + ' "a" in x]\nprint(neu)', ['if'],
         'Das if am Ende ist ein Filter: Nur Elemente, für die die Bedingung wahr ist, kommen in die neue Liste.'),
    choice('Was gibt dieser Code aus?',
           'zahlen = [1, 2, 3, 4]\nquadrate = [z * z for z in zahlen]\nprint(quadrate)', ['[1, 4, 9, 16]', '[1, 2, 3, 4]', '[2, 4, 6, 8]'], 0,
           'Vorne steht, was mit jedem Element passiert: z * z. So entsteht eine neue Liste mit den Quadratzahlen.'),
    fill('Mache aus jedem Wort eines in Großbuchstaben.',
         'woerter = ["hi", "du"]\ngross = [w.' + B + '() for w in woerter]\nprint(gross)', ['upper'],
         'Der Ausdruck vorne darf alles sein – auch ein Methodenaufruf.'),
    choice('Was gibt dieser Code aus?',
           'print([x for x in range(10) if x < 5])', ['[0, 1, 2, 3, 4]', '[5, 6, 7, 8, 9]', '[0, 1, 2, 3, 4, 5]'], 0,
           'range(10) liefert 0 bis 9. Der Filter behält nur die Zahlen kleiner als 5.'),
    choice('Was gibt dieser Code aus?',
           'obst = ["Apfel", "Banane", "Kiwi"]\nprint([x if x != "Banane" else "Orange" for x in obst])', ["['Apfel', 'Orange', 'Kiwi']", "['Apfel', 'Kiwi']", "['Orange']"], 0,
           'Vorne darf auch ein „wert if bedingung else anderer_wert“ stehen. So wird Banane durch Orange ersetzt, statt sie zu entfernen.'),
])

lesson('list_sort', 'Listen sortieren', 'sort',
       'sort() sortiert eine Liste – Texte alphabetisch, Zahlen der Größe nach. Mit sort(reverse=True) wird absteigend sortiert. '
       'Mit key= bestimmst du, WONACH sortiert wird. Achtung: Großbuchstaben kommen vor Kleinbuchstaben!', [
    fill('Sortiere die Liste alphabetisch.',
         'obst = ["Orange", "Mango", "Kiwi", "Ananas"]\nobst.' + B + '()\nprint(obst)', ['sort'],
         'sort() verändert die Liste selbst – danach steht alles in der richtigen Reihenfolge.'),
    fill('Sortiere die Zahlen absteigend (größte zuerst).',
         'zahlen = [100, 50, 65, 82, 23]\nzahlen.sort(reverse=' + B + ')\nprint(zahlen)', ['True'],
         'reverse=True dreht die Sortierreihenfolge um.'),
    choice('Was gibt dieser Code aus?',
           'tiere = ["zebra", "Affe", "biber"]\ntiere.sort()\nprint(tiere)', ["['Affe', 'biber', 'zebra']", "['biber', 'zebra', 'Affe']", "['Affe', 'zebra', 'biber']"], 0,
           'Großbuchstaben stehen im Alphabet des Computers VOR allen Kleinbuchstaben. Hier ist das zufällig auch alphabetisch.'),
    fill('Sortiere ohne Rücksicht auf Groß- und Kleinschreibung.',
         'tiere = ["banane", "Orange", "Kiwi", "kirsche"]\ntiere.sort(key=str.' + B + ')\nprint(tiere)', ['lower'],
         'key=str.lower vergleicht alle Wörter kleingeschrieben – die Liste selbst behält aber ihre Schreibweise.'),
    choice('Was gibt dieser Code aus?',
           'z = [3, 1, 2]\nz.reverse()\nprint(z)\nprint(sorted(z))', ['[2, 1, 3]\n[1, 2, 3]', '[3, 2, 1]\n[1, 2, 3]', '[1, 2, 3]\n[3, 2, 1]'], 0,
           'reverse() dreht die Reihenfolge einfach um (ohne zu sortieren). sorted() liefert eine NEUE sortierte Liste.'),
])

lesson('list_copy', 'Listen kopieren', 'content_copy',
       'Mit liste2 = liste1 entsteht KEINE Kopie – beide Namen zeigen auf dieselbe Liste! Ändert man eine, ändert sich die andere mit. '
       'Eine echte Kopie bekommst du mit liste1.copy(), list(liste1) oder liste1[:].', [
    choice('Was gibt dieser Code aus?',
           'a = ["Apfel", "Banane"]\nb = a\nb.append("Kiwi")\nprint(a)', ["['Apfel', 'Banane', 'Kiwi']", "['Apfel', 'Banane']", "['Kiwi']"], 0,
           'b = a macht nur einen zweiten Namen für DIESELBE Liste. Deshalb sieht man die Kiwi auch in a.',
           {2: 'Keine Kopie! b und a sind dieselbe Liste.'},
           why='Probier den Probelauf: a und b ändern sich gleichzeitig.'),
    fill('Erstelle eine echte Kopie mit einer Methode.',
         'a = ["Apfel", "Banane"]\nb = a.' + B + '()\nb.append("Kiwi")\nprint(a)', ['copy'],
         'copy() erstellt eine neue, unabhängige Liste mit denselben Elementen. Änderungen an b betreffen a nicht.'),
    fill('Erstelle eine Kopie mit der eingebauten Funktion.',
         'a = ["Apfel", "Banane"]\nb = ' + B + '(a)\nprint(b)', ['list'],
         'list(a) baut eine neue Liste aus den Elementen von a.'),
    choice('Was gibt dieser Code aus?',
           'a = [1, 2, 3]\nb = a[:]\nb[0] = 99\nprint(a, b)', ['[1, 2, 3] [99, 2, 3]', '[99, 2, 3] [99, 2, 3]', '[1, 2, 3] [1, 2, 3]'], 0,
           'a[:] ist ein Ausschnitt von Anfang bis Ende – also eine Kopie. Deshalb bleibt a unverändert.'),
    choice('Was gibt dieser Code aus?',
           'a = [1, 2]\nb = a\nc = a.copy()\nprint(a is b, a is c)', ['True False', 'True True', 'False False'], 0,
           'is prüft, ob es dasselbe Objekt ist. b ist dieselbe Liste wie a, c ist eine Kopie.'),
])

lesson('list_join', 'Listen verbinden', 'merge',
       'Zwei Listen verbindest du mit +. Oder du hängst mit extend() alle Elemente an eine bestehende Liste an. '
       'Auch mit einer Schleife und append() geht es – Schritt für Schritt.', [
    fill('Verbinde die beiden Listen zu einer neuen.',
         'a = ["a", "b"]\nb = [1, 2]\nc = a ' + B + ' b\nprint(c)', ['+'],
         'Mit + entsteht eine neue Liste: erst alle Elemente von a, dann alle von b.'),
    fill('Hänge b an a an – mit einer Methode.',
         'a = ["a", "b"]\nb = [1, 2]\na.' + B + '(b)\nprint(a)', ['extend'],
         'extend() verändert a selbst und hängt alle Elemente von b an.'),
    choice('Was gibt dieser Code aus?',
           'a = ["a", "b"]\nb = [1, 2]\nfor x in b:\n    a.append(x)\nprint(a)', ["['a', 'b', 1, 2]", "['a', 'b', [1, 2]]", '[1, 2]'], 0,
           'Die Schleife hängt jedes Element von b einzeln an a – das Ergebnis ist dasselbe wie mit extend().'),
    choice('Was gibt dieser Code aus?',
           'print([0] * 3 + [1])', ['[0, 0, 0, 1]', '[0, 1, 0, 1, 0, 1]', '[1, 0, 0, 0]'], 0,
           '[0] * 3 ergibt [0, 0, 0]. Dann wird [1] angehängt.'),
    order('Ordne die Zeilen, damit [1, 2, 3, 4] ausgegeben wird.',
          ['a = [1, 2]', 'b = [3, 4]', 'c = a + b', 'print(c)'],
          'Erst müssen beide Listen existieren, dann kann man sie verbinden und ausgeben.'),
])
