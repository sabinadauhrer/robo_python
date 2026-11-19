# Kapitel Entscheidungen, Schleifen, Funktionen (neue Inseln)

lesson('if_elif', 'elif', 'alt_route',
       'elif heißt „sonst, wenn“. Ist die if-Bedingung falsch, prüft Python die elif-Bedingung. '
       'Es darf beliebig viele elif geben – aber es läuft immer nur der ERSTE Teil, dessen Bedingung wahr ist.', [
    fill('Ergänze das Schlüsselwort für „sonst, wenn“.',
         'a = 33\nb = 33\nif b > a:\n    print("b ist größer")\n' + B + ' a == b:\n    print("a und b sind gleich")', ['elif'],
         'elif wird nur geprüft, wenn alles darüber falsch war.'),
    choice('Was gibt dieser Code aus?',
           'note = 2\nif note == 1:\n    print("sehr gut")\nelif note == 2:\n    print("gut")\nelif note < 4:\n    print("ok")', ['gut', 'gut\nok', 'ok'], 0,
           'note < 4 wäre auch wahr – aber es läuft nur der erste passende Teil.',
           {4: 'Passt → läuft.', 6: 'Wird gar nicht mehr geprüft.'}),
    choice('Was gibt dieser Code aus?',
           'x = 50\nif x > 100:\n    print("A")\nelif x > 75:\n    print("B")', ['(nichts)', 'A', 'B'], 0,
           'Beide Bedingungen sind falsch, und es gibt kein else. Also wird gar nichts ausgegeben.',
           is_output=False),
    fill('Prüfe, ob die Temperatur über 20 Grad liegt.',
         't = 25\nif t > 30:\n    print("heiß")\nelif t ' + B + ' 20:\n    print("warm")', ['>'],
         'Bei 25 Grad ist die erste Bedingung falsch, die zweite wahr.'),
    order('Ordne die Zeilen: Bei 0 soll „null“ erscheinen, bei einer positiven Zahl „positiv“.',
          ['x = 0', 'if x > 0:', '    print("positiv")', 'elif x == 0:', '    print("null")'],
          'if kommt immer zuerst, elif darunter mit gleicher Einrückung.'),
])

lesson('if_else', 'else', 'call_split',
       'else fängt alle Fälle auf, die vorher nicht gepasst haben. Es hat keine Bedingung und steht immer am Ende. '
       'Man kann else auch direkt nach if benutzen – ganz ohne elif.', [
    fill('Ergänze den Teil für alle anderen Fälle.',
         'a = 200\nb = 33\nif b > a:\n    print("b ist größer")\n' + B + ':\n    print("b ist nicht größer")', ['else'],
         'else hat keine Bedingung – es läuft, wenn nichts davor gepasst hat.'),
    choice('Was gibt dieser Code aus?',
           'a = 200\nb = 33\nif b > a:\n    print("b größer")\nelif a == b:\n    print("gleich")\nelse:\n    print("a größer")', ['a größer', 'b größer', 'gleich'], 0,
           'Weder b > a noch a == b stimmt – also läuft else.'),
    choice('Was passiert bei diesem Code?',
           'x = 5\nif x > 3:\n    print("groß")\nelse x < 3:\n    print("klein")', ['SyntaxError: else hat keine Bedingung', 'groß', 'klein'], 0,
           'else darf keine Bedingung haben. Für eine weitere Bedingung braucht man elif.',
           is_output=False),
    fill('Gib „gerade“ oder „ungerade“ aus.',
         'zahl = 7\nif zahl % 2 == 0:\n    print("gerade")\n' + B + '\n    print("ungerade")', ['else:'],
         'Vergiss den Doppelpunkt hinter else nicht!'),
    choice('Was gibt dieser Code aus?',
           'alter = 16\nif alter >= 18:\n    print("darf wählen")\nelse:\n    print("noch", 18 - alter, "Jahre")', ['noch 2 Jahre', 'darf wählen', 'noch 18 Jahre'], 0,
           'Die Bedingung ist falsch, also läuft else. Dort wird ausgerechnet, wie viele Jahre noch fehlen.'),
])

lesson('if_short', 'if in einer Zeile', 'short_text',
       'Kurze if-Anweisungen passen in eine Zeile: if a > b: print("a"). '
       'Für zwei Möglichkeiten gibt es den Bedingungsausdruck: wert1 if bedingung else wert2. '
       'Er liefert einen Wert, den man z. B. speichern kann.', [
    choice('Was gibt dieser Code aus?',
           'a = 200\nb = 33\nif a > b: print("a ist größer als b")', ['a ist größer als b', '(nichts)', 'Fehler'], 0,
           'Steht nur eine Anweisung im if, darf sie direkt hinter den Doppelpunkt.'),
    fill('Ergänze das Wort für die andere Möglichkeit.',
         'a = 2\nb = 330\nprint("A") if a > b ' + B + ' print("B")', ['else'],
         'Die Kurzform: erst das, was bei True passiert, dann if Bedingung, dann else und das andere.'),
    choice('Was gibt dieser Code aus?',
           'x = 7\ntext = "gerade" if x % 2 == 0 else "ungerade"\nprint(text)', ['ungerade', 'gerade', 'True'], 0,
           'Der Ausdruck liefert einen der beiden Werte – hier „ungerade“, weil 7 % 2 nicht 0 ist.'),
    choice('Was gibt dieser Code aus?',
           'a = 330\nb = 330\nprint("A") if a > b else print("=") if a == b else print("B")', ['=', 'A', 'B'], 0,
           'Man kann die Kurzform verketten – das ist aber schnell schwer zu lesen.'),
    fill('Speichere den größeren der beiden Werte.',
         'a = 4\nb = 9\ngroesser = a if a > b else ' + B + '\nprint(groesser)', ['b'],
         'Ist a > b falsch, wird der Wert nach else genommen.'),
])

lesson('if_logic', 'and, or & not im if', 'rule',
       'In einer if-Bedingung kannst du mehrere Prüfungen verbinden: and (beide müssen stimmen), or (eine reicht) und not (dreht um). '
       'So brauchst du oft keine verschachtelten ifs.', [
    fill('Beide Bedingungen sollen stimmen.',
         'a = 200\nb = 33\nc = 500\nif a > b ' + B + ' c > a:\n    print("Beide Bedingungen stimmen")', ['and'],
         'and ist nur wahr, wenn links UND rechts wahr ist.'),
    fill('Es reicht, wenn eine Bedingung stimmt.',
         'a = 200\nb = 33\nc = 500\nif a > b ' + B + ' a > c:\n    print("Mindestens eine stimmt")', ['or'],
         'or ist wahr, sobald eine Seite wahr ist.'),
    choice('Was gibt dieser Code aus?',
           'a = 33\nb = 200\nif not a > b:\n    print("a ist NICHT größer als b")', ['a ist NICHT größer als b', '(nichts)', 'Fehler'], 0,
           'a > b ist False, not macht daraus True.'),
    choice('Was gibt dieser Code aus?',
           'regen = True\nschirm = False\nif regen and not schirm:\n    print("Du wirst nass!")\nelse:\n    print("Alles gut")', ['Du wirst nass!', 'Alles gut', 'Fehler'], 0,
           'regen ist True, not schirm ist auch True – also ist alles True.'),
    choice('Was gibt dieser Code aus?',
           'tag = "Sa"\nif tag == "Sa" or tag == "So":\n    print("Wochenende")\nelse:\n    print("Schule")', ['Wochenende', 'Schule', 'Fehler'], 0,
           'Mit or prüft man, ob einer von mehreren Fällen zutrifft. Achtung: tag == "Sa" or "So" wäre falsch geschrieben!'),
])

lesson('if_nested', 'Verschachtelte if', 'account_tree',
       'Ein if kann in einem anderen if stehen. Das innere if wird nur geprüft, wenn das äußere wahr ist. '
       'Die Einrückung zeigt, was zu welchem if gehört.', [
    choice('Was gibt dieser Code aus?',
           'x = 41\nif x > 10:\n    print("über zehn")\n    if x > 20:\n        print("und über zwanzig!")\n    else:\n        print("aber nicht über zwanzig")', ['über zehn\nund über zwanzig!', 'über zehn', 'und über zwanzig!'], 0,
           'Das äußere if ist wahr, also wird auch das innere geprüft – und das ist auch wahr.',
           {4: 'Dieses if gehört zum äußeren if (eingerückt).'}),
    choice('Was gibt dieser Code aus?',
           'x = 5\nif x > 10:\n    print("A")\n    if x > 2:\n        print("B")\nprint("C")', ['C', 'B\nC', 'A\nB\nC'], 0,
           'Das äußere if ist falsch – der ganze eingerückte Teil (auch das innere if) wird übersprungen.'),
    fill('Rücke das innere if richtig ein: Ergänze, was am Ende der Zeile fehlt.',
         'alter = 12\nticket = True\nif alter >= 10:\n    if ticket' + B + '\n        print("Willkommen im Kino!")', [':'],
         'Auch das innere if braucht einen Doppelpunkt, danach wird noch weiter eingerückt.'),
    choice('Was gibt dieser Code aus?',
           'a = 5\nb = 0\nif a > 0:\n    if b > 0:\n        print("beide positiv")\n    else:\n        print("nur a")\nelse:\n    print("a nicht positiv")', ['nur a', 'beide positiv', 'a nicht positiv'], 0,
           'Das else in Zeile 6 gehört zum INNEREN if (gleiche Einrückung), das in Zeile 8 zum äußeren.'),
    order('Ordne die Zeilen: „positiv und gerade“ soll erscheinen.',
          ['x = 4', 'if x > 0:', '    if x % 2 == 0:', '        print("positiv und gerade")'],
          'Jede Ebene wird weiter eingerückt.'),
])

lesson('pass', 'pass', 'more_horiz',
       'Ein if, eine Funktion oder eine Schleife darf nicht leer sein. Wenn du noch nicht weißt, was hinein soll, '
       'schreibst du pass. pass bedeutet: „Hier passiert (noch) nichts.“', [
    fill('Ergänze das Wort, damit der leere if-Teil keinen Fehler macht.',
         'a = 33\nb = 200\nif b > a:\n    ' + B + '\nprint("fertig")', ['pass'],
         'pass ist ein Platzhalter. Python springt einfach darüber.'),
    choice('Was passiert bei diesem Code?',
           'if 5 > 2:\n\nprint("fertig")', ['IndentationError: der if-Teil ist leer', 'fertig', 'Es passiert nichts'], 0,
           'Nach dem Doppelpunkt muss etwas Eingerücktes kommen. Ein leerer Block ist verboten – dafür gibt es pass.',
           is_output=False),
    choice('Was gibt dieser Code aus?',
           'for i in range(3):\n    pass\nprint("Schleife fertig", i)', ['Schleife fertig 2', 'Schleife fertig 3', '0\n1\n2'], 0,
           'Die Schleife läuft dreimal, macht aber nichts. Danach hat i den letzten Wert 2.'),
    fill('Definiere eine Funktion, die noch nichts tut.',
         'def spaeter():\n    ' + B + '\n\nspaeter()\nprint("ok")', ['pass'],
         'Auch Funktionen können mit pass erst einmal leer bleiben.'),
    choice('Was gibt dieser Code aus?',
           'x = 7\nif x > 5:\n    pass\nelse:\n    print("klein")\nprint("Ende")', ['Ende', 'klein\nEnde', '(nichts)'], 0,
           'Der if-Teil läuft (macht aber nichts). else wird übersprungen.'),
])

lesson('match', 'match', 'rule_folder',
       'Mit match vergleichst du einen Wert mit mehreren Möglichkeiten (case). Das ist übersichtlicher als viele elif. '
       'Mit | verbindest du mehrere Werte in einem case, und case _ fängt alle übrigen Fälle auf (wie else).', [
    fill('Ergänze das Schlüsselwort für einen Fall.',
         'tag = 4\nmatch tag:\n    ' + B + ' 4:\n        print("Donnerstag")\n    case 5:\n        print("Freitag")', ['case'],
         'match vergleicht tag mit jedem case – der erste passende wird ausgeführt.',
         manual='Donnerstag'),
    choice('Was gibt dieser Code aus?',
           'tag = 9\nmatch tag:\n    case 6:\n        print("Samstag")\n    case 7:\n        print("Sonntag")\n    case _:\n        print("Werktag?")', ['Werktag?', 'Samstag', '(nichts)'], 0,
           'Kein case passt zur 9, also läuft case _ – der Platzhalter für alle anderen Fälle.',
           manual='Werktag?'),
    fill('Verbinde die beiden Werte, damit 6 UND 7 „Wochenende“ ergeben.',
         'tag = 7\nmatch tag:\n    case 6 ' + B + ' 7:\n        print("Wochenende")\n    case _:\n        print("Unter der Woche")', ['|'],
         'Mit | (sprich „oder“) passt ein case zu mehreren Werten.',
         manual='Wochenende'),
    choice('Was gibt dieser Code aus?',
           'befehl = "stop"\nmatch befehl:\n    case "start":\n        print("Los!")\n    case "stop":\n        print("Halt!")', ['Halt!', 'Los!', 'Los!\nHalt!'], 0,
           'match funktioniert auch mit Texten.',
           manual='Halt!'),
    choice('Was gibt dieser Code aus?',
           'monat = 5\ntag = 4\nmatch tag:\n    case 1 | 2 | 3 | 4 | 5 if monat == 4:\n        print("Werktag im April")\n    case 1 | 2 | 3 | 4 | 5 if monat == 5:\n        print("Werktag im Mai")\n    case _:\n        print("Kein Treffer")', ['Werktag im Mai', 'Werktag im April', 'Kein Treffer'], 0,
           'Hinter einem case darf ein if stehen (eine „Wache“). Der case passt nur, wenn auch diese Bedingung stimmt.',
           manual='Werktag im Mai'),
])

# ---------------------------------------------------------------- Schleifen

lesson('while_more', 'while: break, continue, else', 'loop',
       'break beendet eine Schleife sofort. continue überspringt den Rest der aktuellen Runde. '
       'Ein else nach der Schleife läuft, wenn die Bedingung falsch geworden ist – aber nicht nach einem break.', [
    fill('Beende die Schleife, wenn i 3 ist.',
         'i = 1\nwhile i < 6:\n    print(i)\n    if i == 3:\n        ' + B + '\n    i += 1', ['break'],
         'break springt sofort aus der Schleife – egal, was die Bedingung sagt.'),
    choice('Was gibt dieser Code aus?',
           'i = 0\nwhile i < 5:\n    i += 1\n    if i == 3:\n        continue\n    print(i)', ['1\n2\n4\n5', '1\n2\n3\n4\n5', '1\n2'], 0,
           'Bei i == 3 überspringt continue das print – es geht direkt mit der nächsten Runde weiter.'),
    fill('Ergänze den Teil, der läuft, wenn die Bedingung falsch wird.',
         'i = 1\nwhile i < 3:\n    print(i)\n    i += 1\n' + B + ':\n    print("i ist nicht mehr kleiner als 3")', ['else'],
         'else bei Schleifen läuft einmal am Ende – wenn die Schleife normal endet.'),
    choice('Was gibt dieser Code aus?',
           'i = 0\nwhile i < 10:\n    i += 1\n    if i == 2:\n        break\nelse:\n    print("normal zu Ende")\nprint("i =", i)', ['i = 2', 'normal zu Ende\ni = 2', 'normal zu Ende\ni = 10'], 0,
           'Wegen break endet die Schleife vorzeitig – dann wird das else übersprungen.'),
    order('Ordne die Zeilen für einen Countdown 3, 2, 1 und dann „Start!“.',
          ['n = 3', 'while n > 0:', '    print(n)', '    n -= 1', 'print("Start!")'],
          'Die Zahl wird ausgegeben und dann verkleinert. Nach der Schleife kommt „Start!“.'),
])

lesson('for_more', 'for: break, continue, else', 'repeat_on',
       'Auch for-Schleifen kennen break, continue und else. Und Schleifen kann man verschachteln: '
       'Die innere Schleife läuft dann für jede Runde der äußeren komplett durch.', [
    fill('Brich ab, sobald „Banane“ erreicht ist.',
         'obst = ["Apfel", "Banane", "Kirsche"]\nfor x in obst:\n    print(x)\n    if x == "Banane":\n        ' + B, ['break'],
         'break beendet die for-Schleife sofort. Kirsche wird nicht mehr ausgegeben.'),
    choice('Was gibt dieser Code aus?',
           'obst = ["Apfel", "Banane", "Kirsche"]\nfor x in obst:\n    if x == "Banane":\n        continue\n    print(x)', ['Apfel\nKirsche', 'Apfel', 'Apfel\nBanane\nKirsche'], 0,
           'continue überspringt nur die Runde mit der Banane.'),
    choice('Was gibt dieser Code aus?',
           'for x in range(3):\n    print(x)\nelse:\n    print("Fertig!")', ['0\n1\n2\nFertig!', '0\n1\n2', 'Fertig!'], 0,
           'Das else läuft, nachdem die Schleife komplett durchgelaufen ist.'),
    choice('Was gibt dieser Code aus?',
           'for farbe in ["rot", "blau"]:\n    for ding in ["Ball", "Hut"]:\n        print(farbe, ding)', ['rot Ball\nrot Hut\nblau Ball\nblau Hut', 'rot Ball\nblau Hut', 'rot blau\nBall Hut'], 0,
           'Für jede Farbe läuft die innere Schleife einmal ganz durch.'),
    fill('Ergänze das Wort, damit die leere Schleife keinen Fehler macht.',
         'for x in [0, 1, 2]:\n    ' + B + '\nprint("ok")', ['pass'],
         'Auch eine for-Schleife darf nicht leer sein – pass hilft.'),
])

lesson('range', 'range()', 'linear_scale',
       'range() erzeugt eine Folge von Zahlen. range(5) ist 0 bis 4, range(2, 6) ist 2 bis 5, range(0, 10, 2) zählt in Zweierschritten. '
       'Die Endzahl ist nie dabei! Mit einer negativen Schrittweite zählt range rückwärts.', [
    choice('Was gibt dieser Code aus?',
           'print(list(range(5)))', ['[0, 1, 2, 3, 4]', '[1, 2, 3, 4, 5]', '[0, 1, 2, 3, 4, 5]'], 0,
           'range(5) beginnt bei 0 und endet VOR 5.'),
    fill('Zähle von 3 bis 7.',
         'for x in range(3, ' + B + '):\n    print(x)', ['8'],
         'Die Endzahl ist nicht mehr dabei – für 7 muss also 8 dort stehen.'),
    fill('Zähle in Dreierschritten.',
         'print(list(range(0, 10, ' + B + ')))', ['3'],
         'Der dritte Wert ist die Schrittweite: 0, 3, 6, 9.'),
    choice('Was gibt dieser Code aus?',
           'print(list(range(5, 0, -1)))', ['[5, 4, 3, 2, 1]', '[5, 4, 3, 2, 1, 0]', '[]'], 0,
           'Mit Schrittweite -1 zählt range rückwärts. Die 0 ist als Endwert nicht mehr dabei.'),
    choice('Was gibt dieser Code aus?',
           'r = range(10)\nprint(len(r), r[3], 7 in r, 10 in r)', ['10 3 True False', '9 3 True True', '10 4 True False'], 0,
           'range verhält sich wie eine Liste: Es hat eine Länge, man kann Indizes benutzen und mit in suchen.'),
])

# ---------------------------------------------------------------- Funktionen

lesson('func_args', 'Argumente', 'input',
       'Werte, die du einer Funktion übergibst, heißen Argumente. Du kannst sie der Reihe nach übergeben (Position) '
       'oder mit Namen: f(name="Mia"). Parameter können Standardwerte haben, und man kann auch Listen übergeben.', [
    fill('Übergib das Argument mit Namen.',
         'def tier(art, name):\n    print(name, "ist ein", art)\n\ntier(art="Hund", ' + B + '="Bello")', ['name'],
         'Mit Namen ist die Reihenfolge egal – Python weiß genau, welcher Wert wohin gehört.'),
    choice('Was gibt dieser Code aus?',
           'def herkunft(land="Norwegen"):\n    print("Ich komme aus", land)\n\nherkunft("Schweden")\nherkunft()', ['Ich komme aus Schweden\nIch komme aus Norwegen', 'Ich komme aus Schweden\nIch komme aus Schweden', 'Fehler'], 0,
           'Ohne Argument nimmt die Funktion den Standardwert "Norwegen".'),
    choice('Was gibt dieser Code aus?',
           'def essen(liste):\n    for x in liste:\n        print(x)\n\nessen(["Apfel", "Brot"])', ['Apfel\nBrot', "['Apfel', 'Brot']", 'liste'], 0,
           'Man kann jeden Datentyp übergeben – auch eine Liste. In der Funktion ist sie dann ganz normal benutzbar.'),
    fill('Gib das Ergebnis zurück.',
         'def mal5(x):\n    ' + B + ' 5 * x\n\nprint(mal5(3))', ['return'],
         'return liefert den Wert an den Aufrufer zurück.'),
    choice('Was passiert bei diesem Code?',
           'def plus(a, b):\n    return a + b\n\nprint(plus(1))', ['TypeError: b fehlt', '1', 'None'], 0,
           'Die Funktion hat zwei Parameter ohne Standardwert. Wird nur einer übergeben, fehlt b.',
           is_output=False),
])

lesson('func_star', '*args & **kwargs', 'star',
       'Mit *args nimmt eine Funktion beliebig viele Argumente an – sie landen in einem Tupel. '
       'Mit **kwargs nimmt sie beliebig viele benannte Argumente an – sie landen in einem Dictionary. '
       'Beim Aufruf „entpackt“ * eine Liste und ** ein Dictionary.', [
    fill('Die Funktion soll beliebig viele Kinder annehmen.',
         'def kinder(' + B + 'kids):\n    print("Das jüngste Kind ist", kids[2])\n\nkinder("Emil", "Tobias", "Linus")', ['*'],
         'Mit * vor dem Parameter sammelt Python alle Argumente in einem Tupel.'),
    choice('Was gibt dieser Code aus?',
           'def summe(*zahlen):\n    print(len(zahlen), sum(zahlen))\n\nsumme(1, 2, 3, 4)', ['4 10', '1 1', '4 4'], 0,
           'zahlen ist das Tupel (1, 2, 3, 4) – mit 4 Elementen und der Summe 10.'),
    fill('Die Funktion soll beliebig viele benannte Argumente annehmen.',
         'def kind(' + B + 'kid):\n    print("Sein Nachname ist", kid["nachname"])\n\nkind(vorname="Tobias", nachname="Refsnes")', ['**'],
         'Mit ** landen alle benannten Argumente in einem Dictionary.'),
    choice('Was gibt dieser Code aus?',
           'def info(**daten):\n    for k, v in daten.items():\n        print(k, "=", v)\n\ninfo(name="Robo", alter=3)', ['name = Robo\nalter = 3', "{'name': 'Robo', 'alter': 3}", 'Robo\n3'], 0,
           'daten ist ein ganz normales Dictionary – man kann es mit items() durchlaufen.'),
    fill('Entpacke die Liste beim Aufruf, damit jede Zahl ein eigenes Argument wird.',
         'def plus(a, b, c):\n    return a + b + c\n\nzahlen = [1, 2, 3]\nprint(plus(' + B + 'zahlen))', ['*'],
         '* beim Aufruf verteilt die Liste auf a, b und c.'),
])

lesson('func_scope', 'Gültigkeitsbereich (Scope)', 'visibility',
       'Eine Variable, die in einer Funktion entsteht, ist lokal: Es gibt sie nur dort. Eine Funktion in einer Funktion kann '
       'die Variablen der äußeren lesen. Mit global meinst du die Variable des Hauptprogramms, mit nonlocal die der äußeren Funktion.', [
    choice('Was passiert bei diesem Code?',
           'def f():\n    x = 300\n\nf()\nprint(x)', ['NameError: x gibt es außerhalb nicht', '300', 'None'], 0,
           'x ist lokal in f(). Außerhalb der Funktion existiert es nicht.',
           is_output=False),
    choice('Was gibt dieser Code aus?',
           'def aussen():\n    x = 300\n    def innen():\n        print(x)\n    innen()\n\naussen()', ['300', 'Fehler', 'None'], 0,
           'Die innere Funktion darf die Variablen der äußeren Funktion lesen.'),
    choice('Was gibt dieser Code aus?',
           'x = 300\n\ndef f():\n    x = 200\n    print(x)\n\nf()\nprint(x)', ['200\n300', '200\n200', '300\n300'], 0,
           'Innen gibt es ein eigenes, lokales x. Das globale x bleibt 300.'),
    fill('Ändere die Variable der äußeren Funktion.',
         'def aussen():\n    x = "Jane"\n    def innen():\n        ' + B + ' x\n        x = "hallo"\n    innen()\n    return x\n\nprint(aussen())', ['nonlocal'],
         'nonlocal x bedeutet: Gemeint ist das x der äußeren Funktion. Dadurch ändert innen() es wirklich.'),
    fill('Ändere die globale Variable in der Funktion.',
         'x = 300\n\ndef f():\n    ' + B + ' x\n    x = 200\n\nf()\nprint(x)', ['global'],
         'global x verbindet die Funktion mit dem x des Hauptprogramms.'),
])

lesson('decorators', 'Dekoratoren', 'wrap_text',
       'Ein Dekorator ist eine Funktion, die eine andere Funktion „einpackt“ und ihr Extra-Verhalten gibt – ohne sie selbst zu ändern. '
       'Man schreibt @name direkt über die Funktion. @gross über def hallo() bedeutet: hallo = gross(hallo).', [
    fill('Wende den Dekorator auf die Funktion an.',
         'def gross(f):\n    def innen():\n        return f().upper()\n    return innen\n\n' + B + 'gross\ndef hallo():\n    return "hallo sally"\n\nprint(hallo())', ['@'],
         'Mit @gross wird hallo eingepackt. Ruft man hallo() auf, läuft in Wahrheit innen() – und die macht das Ergebnis groß.',
         {2: 'innen() ist die neue Version der Funktion.', 7: 'Das @ wendet den Dekorator an.'}),
    choice('Was gibt dieser Code aus?',
           'def laut(f):\n    def neu():\n        print("Achtung!")\n        f()\n    return neu\n\n@laut\ndef sag_hallo():\n    print("Hallo")\n\nsag_hallo()', ['Achtung!\nHallo', 'Hallo', 'Hallo\nAchtung!'], 0,
           'Die eingepackte Version gibt zuerst „Achtung!“ aus und ruft dann die ursprüngliche Funktion auf.'),
    choice('Was gibt dieser Code aus?',
           'def doppelt(f):\n    def neu(x):\n        return f(x) * 2\n    return neu\n\n@doppelt\ndef plus1(x):\n    return x + 1\n\nprint(plus1(4))', ['10', '5', '9'], 0,
           'plus1(4) ergibt eigentlich 5. Der Dekorator verdoppelt das Ergebnis → 10.'),
    fill('Der Dekorator soll Funktionen mit beliebigen Argumenten einpacken.',
         'def logge(f):\n    def neu(*args, **kwargs):\n        print("Aufruf mit", args)\n        return f(' + B + 'args, **kwargs)\n    return neu\n\n@logge\ndef plus(a, b):\n    return a + b\n\nprint(plus(2, 3))', ['*'],
         'Mit *args und **kwargs reicht der Dekorator alle Argumente einfach an die echte Funktion weiter.'),
    choice('Was gibt dieser Code aus?',
           'def gross(f):\n    def neu():\n        return f().upper()\n    return neu\n\ndef hallo():\n    return "hi"\n\nhallo = gross(hallo)\nprint(hallo())', ['HI', 'hi', 'Fehler'], 0,
           'Das macht @gross im Hintergrund: hallo = gross(hallo).'),
])

lesson('recursion', 'Rekursion', 'all_inclusive',
       'Eine rekursive Funktion ruft sich selbst auf – jedes Mal mit einem kleineren Problem. '
       'Wichtig ist eine Abbruchbedingung (Basisfall), sonst ruft sie sich endlos auf.', [
    choice('Was gibt dieser Code aus?',
           'def countdown(n):\n    if n <= 0:\n        print("Start!")\n    else:\n        print(n)\n        countdown(n - 1)\n\ncountdown(3)', ['3\n2\n1\nStart!', '1\n2\n3\nStart!', 'Start!'], 0,
           'countdown(3) gibt 3 aus und ruft countdown(2) auf, usw. Bei 0 greift der Basisfall.',
           {2: 'Der Basisfall: Hier hört die Rekursion auf.', 6: 'Die Funktion ruft sich selbst auf – mit n - 1.'}),
    fill('Ergänze den rekursiven Aufruf für die Fakultät (5! = 5·4·3·2·1).',
         'def fakultaet(n):\n    if n == 1:\n        return 1\n    return n * ' + B + '(n - 1)\n\nprint(fakultaet(5))', ['fakultaet'],
         'n! = n · (n-1)!. Die Funktion berechnet den kleineren Teil, indem sie sich selbst aufruft.'),
    choice('Was gibt dieser Code aus?',
           'def summe(n):\n    if n == 0:\n        return 0\n    return n + summe(n - 1)\n\nprint(summe(4))', ['10', '4', '0'], 0,
           '4 + 3 + 2 + 1 + 0 = 10.'),
    fill('Ergänze die Abbruchbedingung.',
         'def zaehle(n):\n    if n ' + B + ' 0:\n        return\n    print(n)\n    zaehle(n - 1)\n\nzaehle(2)', [['==', '<=']],
         'Ohne Abbruch würde die Funktion sich unendlich oft aufrufen (RecursionError).'),
    choice('Was gibt dieser Code aus?',
           'def fib(n):\n    if n < 2:\n        return n\n    return fib(n - 1) + fib(n - 2)\n\nprint(fib(6))', ['8', '6', '13'], 0,
           'Die Fibonacci-Zahlen: 0, 1, 1, 2, 3, 5, 8 – jede ist die Summe der zwei davor.'),
])

lesson('generators', 'Generatoren', 'factory',
       'Ein Generator liefert Werte einen nach dem anderen – statt alle auf einmal. Man baut ihn wie eine Funktion, '
       'aber mit yield statt return. Jedes yield gibt den nächsten Wert heraus. Mit for oder next() holst du die Werte ab.', [
    fill('Ergänze das Schlüsselwort, das einen Wert herausgibt.',
         'def meine_zahlen():\n    ' + B + ' 1\n    yield 2\n    yield 3\n\nfor z in meine_zahlen():\n    print(z)', ['yield'],
         'Jedes yield liefert einen Wert. Die for-Schleife holt sie der Reihe nach ab.'),
    choice('Was gibt dieser Code aus?',
           'def bis(n):\n    i = 1\n    while i <= n:\n        yield i\n        i += 1\n\nprint(list(bis(4)))', ['[1, 2, 3, 4]', '[4]', '[1, 2, 3]'], 0,
           'list() holt alle Werte aus dem Generator ab und packt sie in eine Liste.'),
    fill('Hole den nächsten Wert aus dem Generator.',
         'def farben():\n    yield "rot"\n    yield "grün"\n\ng = farben()\nprint(next(g))\nprint(' + B + '(g))', ['next'],
         'next() holt immer den nächsten Wert. Der Generator merkt sich, wo er war.'),
    choice('Was gibt dieser Code aus?',
           'quadrate = (x * x for x in range(4))\nprint(sum(quadrate))', ['14', '[0, 1, 4, 9]', '6'], 0,
           'In runden Klammern ist das ein Generator-Ausdruck. sum() addiert 0 + 1 + 4 + 9 = 14.'),
    choice('Was gibt dieser Code aus?',
           'def fib():\n    a, b = 0, 1\n    for _ in range(6):\n        yield a\n        a, b = b, a + b\n\nprint(list(fib()))', ['[0, 1, 1, 2, 3, 5]', '[1, 1, 2, 3, 5, 8]', '[0, 1, 2, 3, 4, 5]'], 0,
           'Der Generator liefert die ersten 6 Fibonacci-Zahlen.'),
])
