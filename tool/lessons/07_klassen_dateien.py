# Kapitel Klassen & Objekte + Dateien (neue Inseln)
# Hinweis: Objekte ohne __str__ druckt Python mit Speicheradresse aus – deshalb hier immer Eigenschaften ausgeben.

lesson('oop', 'Objektorientierung', 'hub',
       'Objektorientierte Programmierung (OOP) bündelt Daten und Fähigkeiten zu „Objekten“. Eine Klasse ist der Bauplan, '
       'ein Objekt ist ein Ding, das nach diesem Bauplan gebaut wurde. Beispiel: Die Klasse Auto beschreibt Marke und Farbe – '
       'dein rotes Auto und mein blaues Auto sind zwei Objekte dieser Klasse.', [
    choice('Was ist eine Klasse?',
           'class Auto:\n    pass',
           ['Ein Bauplan für Objekte', 'Ein fertiges Objekt', 'Eine Liste von Zahlen'], 0,
           'Eine Klasse beschreibt, welche Eigenschaften und Fähigkeiten ihre Objekte haben.',
           is_output=False),
    choice('Was gibt dieser Code aus?',
           'class Auto:\n    raeder = 4\n\nmein_auto = Auto()\nprint(mein_auto.raeder)', ['4', 'Auto', 'raeder'], 0,
           'Auto() baut ein neues Objekt nach dem Bauplan. Es hat die Eigenschaft raeder = 4.',
           {1: 'Der Bauplan.', 4: 'Ein Objekt wird gebaut.'}),
    choice('Welche Aussage stimmt?',
           'class Hund:\n    pass\n\nbello = Hund()\nwaldi = Hund()',
           ['bello und waldi sind zwei Objekte derselben Klasse', 'bello ist eine Klasse', 'Es gibt nur ein Objekt'], 0,
           'Aus einer Klasse kann man beliebig viele Objekte bauen. Jedes ist eigenständig.',
           is_output=False),
    fill('Baue ein Objekt der Klasse Katze.',
         'class Katze:\n    beine = 4\n\nmimi = ' + B + '()\nprint(mimi.beine)', ['Katze'],
         'Ein Objekt baut man, indem man die Klasse wie eine Funktion aufruft.'),
    choice('Warum benutzt man Objektorientierung?',
           '# Daten (Name, Alter) und Fähigkeiten (bellen)\n# gehören zusammen in ein Objekt.',
           ['Damit Daten und Fähigkeiten ordentlich zusammengehören', 'Damit der Code länger wird', 'Weil Python sonst nicht läuft'], 0,
           'Mit Klassen wird großer Code übersichtlich: Alles, was zu einem Ding gehört, steckt an einer Stelle.',
           is_output=False),
])

lesson('classes', 'Klassen & Objekte', 'category',
       'Eine Klasse erstellst du mit class Name: (Namen von Klassen schreibt man groß). '
       'Mit name = Klasse() baust du ein Objekt. Mit objekt.eigenschaft liest du seine Eigenschaften. '
       'Mit del objekt löschst du es wieder.', [
    fill('Erstelle eine Klasse namens MeineKlasse.',
         B + ' MeineKlasse:\n    x = 5\n\np1 = MeineKlasse()\nprint(p1.x)', ['class'],
         'Das Schlüsselwort class leitet den Bauplan ein. Darunter steht eingerückt, was dazugehört.'),
    fill('Lies die Eigenschaft x des Objekts.',
         'class MeineKlasse:\n    x = 5\n\np1 = MeineKlasse()\nprint(p1' + B + 'x)', ['.'],
         'Mit einem Punkt greift man auf Eigenschaften und Methoden eines Objekts zu.'),
    choice('Was gibt dieser Code aus?',
           'class Box:\n    inhalt = "Bälle"\n\na = Box()\nb = Box()\nprint(a.inhalt, b.inhalt)', ['Bälle Bälle', 'Bälle', 'a b'], 0,
           'Beide Objekte haben die Eigenschaft aus dem Bauplan.'),
    choice('Was gibt dieser Code aus?',
           'class Box:\n    pass\n\na = Box()\nprint(type(a).__name__)', ['Box', 'object', 'class'], 0,
           'type() verrät die Klasse eines Objekts. __name__ ist ihr Name.'),
    choice('Was passiert bei diesem Code?',
           'class Box:\n    pass\n\na = Box()\ndel a\nprint(a)', ['NameError: a gibt es nicht mehr', 'Box', 'None'], 0,
           'del a löscht den Namen a. Danach kann man das Objekt nicht mehr benutzen.',
           is_output=False),
])

lesson('init', '__init__()', 'construction',
       'Die besondere Methode __init__() läuft automatisch, wenn ein neues Objekt gebaut wird. '
       'Dort gibst du dem Objekt seine Startwerte: def __init__(self, name, alter): self.name = name. '
       'Die Werte übergibst du beim Bauen: Person("Mia", 9).', [
    fill('Ergänze den Namen der Methode, die beim Erstellen läuft.',
         'class Person:\n    def ' + B + '(self, name, alter):\n        self.name = name\n        self.alter = alter\n\np1 = Person("John", 36)\nprint(p1.name)', ['__init__'],
         '__init__ (zwei Unterstriche vorn und hinten) wird automatisch aufgerufen, wenn man Person(...) schreibt.',
         {2: 'Läuft automatisch beim Erstellen.', 3: 'Speichert den Namen im Objekt.'},
         hint='Zwei Unterstriche, init, zwei Unterstriche.'),
    choice('Was gibt dieser Code aus?',
           'class Person:\n    def __init__(self, name, alter):\n        self.name = name\n        self.alter = alter\n\np1 = Person("John", 36)\nprint(p1.alter)', ['36', 'John', 'alter'], 0,
           'Beim Erstellen landet 36 im Parameter alter und wird als self.alter gespeichert.'),
    fill('Speichere den Namen im Objekt.',
         'class Hund:\n    def __init__(self, name):\n        ' + B + '.name = name\n\nh = Hund("Bello")\nprint(h.name)', ['self'],
         'self ist das Objekt, das gerade gebaut wird. self.name = name hängt den Namen an dieses Objekt.'),
    choice('Was gibt dieser Code aus?',
           'class Person:\n    def __init__(self, name, alter=18):\n        self.name = name\n        self.alter = alter\n\na = Person("Tom")\nb = Person("Ida", 9)\nprint(a.alter, b.alter)', ['18 9', '9 18', '18 18'], 0,
           'Auch __init__ kann Standardwerte haben.'),
    choice('Was passiert bei diesem Code?',
           'class Person:\n    def __init__(self, name):\n        self.name = name\n\np = Person()', ['TypeError: name fehlt', 'Ein Objekt ohne Namen', 'None'], 0,
           '__init__ braucht einen Wert für name – beim Erstellen wurde aber nichts übergeben.',
           is_output=False),
])

lesson('self', 'self', 'person',
       'self ist der erste Parameter jeder Methode. Es steht für das Objekt, mit dem die Methode gerade arbeitet. '
       'Über self kommt eine Methode an die Eigenschaften „ihres“ Objekts. Beim Aufruf p1.methode() setzt Python self automatisch ein.', [
    fill('Greife in der Methode auf den Namen des Objekts zu.',
         'class Person:\n    def __init__(self, name):\n        self.name = name\n\n    def gruss(self):\n        print("Hallo, ich bin " + ' + B + '.name)\n\np1 = Person("Emil")\np1.gruss()', ['self'],
         'In der Methode ist self das Objekt p1 – also ist self.name „Emil“.'),
    choice('Was gibt dieser Code aus?',
           'class Person:\n    def __init__(self, name):\n        self.name = name\n\n    def gruss(self):\n        print("Hi " + self.name)\n\na = Person("Ali")\nb = Person("Bea")\nb.gruss()', ['Hi Bea', 'Hi Ali', 'Hi self'], 0,
           'b.gruss() → self ist b. Darum wird Beas Name benutzt.'),
    choice('Was gibt dieser Code aus?',
           'class Zaehler:\n    def __init__(self):\n        self.wert = 0\n\n    def plus(self):\n        self.wert += 1\n\nz = Zaehler()\nz.plus()\nz.plus()\nprint(z.wert)', ['2', '1', '0'], 0,
           'Jedes plus() erhöht den Wert DIESES Objekts um 1.'),
    choice('Was gibt dieser Code aus?',
           'class Person:\n    def __init__(ich, name):\n        ich.name = name\n\np = Person("Linus")\nprint(p.name)', ['Linus', 'Fehler', 'ich'], 0,
           '„self“ ist nur ein üblicher Name. Er muss aber der erste Parameter sein – hier heißt er eben ich.'),
    fill('Rufe die Methode des Objekts auf.',
         'class Robo:\n    def piep(self):\n        print("Piep piep!")\n\nr = Robo()\nr.' + B + '()', ['piep'],
         'Beim Aufruf schreibt man self NICHT hin – Python setzt das Objekt automatisch ein.'),
])

lesson('class_props', 'Eigenschaften', 'tune',
       'Eigenschaften (Attribute) sind die Daten eines Objekts, z. B. self.farbe. Man kann sie lesen, ändern (p1.alter = 40) '
       'und mit del p1.alter löschen. Eigenschaften, die direkt in der Klasse stehen, teilen sich alle Objekte (Klassen-Attribute).', [
    fill('Ändere das Alter des Objekts auf 40.',
         'class Person:\n    def __init__(self, name, alter):\n        self.name = name\n        self.alter = alter\n\np1 = Person("John", 36)\np1.alter = ' + B + '\nprint(p1.alter)', ['40'],
         'Eigenschaften kann man jederzeit ändern – einfach einen neuen Wert zuweisen.'),
    choice('Was gibt dieser Code aus?',
           'class Person:\n    def __init__(self, name):\n        self.name = name\n\np = Person("Mia")\ndel p.name\nprint(hasattr(p, "name"))', ['False', 'True', 'Mia'], 0,
           'del p.name löscht die Eigenschaft. hasattr() prüft, ob es sie noch gibt.'),
    choice('Was gibt dieser Code aus?',
           'class Hund:\n    art = "Säugetier"\n    def __init__(self, name):\n        self.name = name\n\na = Hund("Rex")\nb = Hund("Bello")\nprint(a.art, b.art, a.name)', ['Säugetier Säugetier Rex', 'Rex Bello Rex', 'Säugetier Rex Rex'], 0,
           'art steht in der Klasse – alle Hunde teilen sich diesen Wert. name gehört jedem Hund einzeln.'),
    choice('Was gibt dieser Code aus?',
           'class Spiel:\n    anzahl = 0\n    def __init__(self):\n        Spiel.anzahl += 1\n\nSpiel()\nSpiel()\nSpiel()\nprint(Spiel.anzahl)', ['3', '1', '0'], 0,
           'Jedes neue Objekt erhöht das Klassen-Attribut anzahl. So kann man zählen, wie viele Objekte gebaut wurden.'),
    fill('Gib dem Objekt nachträglich eine neue Eigenschaft.',
         'class Leer:\n    pass\n\nx = Leer()\nx.' + B + ' = "blau"\nprint(x.farbe)', ['farbe'],
         'Man kann einem Objekt auch später neue Eigenschaften geben.'),
])

lesson('class_methods', 'Methoden', 'settings_suggest',
       'Methoden sind Funktionen, die zu einer Klasse gehören. Sie beschreiben, was ein Objekt KANN. '
       'Sie können Werte zurückgeben und Eigenschaften ändern. Die besondere Methode __str__() legt fest, '
       'was print(objekt) anzeigt.', [
    fill('Definiere die Methode bellen.',
         'class Hund:\n    def __init__(self, name):\n        self.name = name\n\n    ' + B + ' bellen(self):\n        return self.name + " sagt Wuff!"\n\nh = Hund("Rex")\nprint(h.bellen())', ['def'],
         'Methoden werden wie Funktionen mit def definiert – nur eingerückt in der Klasse.'),
    fill('Lege fest, was print() bei einem Objekt zeigt.',
         'class Person:\n    def __init__(self, name, alter):\n        self.name = name\n        self.alter = alter\n\n    def ' + B + '(self):\n        return f"{self.name} ({self.alter})"\n\np1 = Person("John", 36)\nprint(p1)', ['__str__'],
         'Ohne __str__ zeigt print() nur etwas wie <__main__.Person object at 0x…>. Mit __str__ bestimmst du den Text selbst.'),
    choice('Was gibt dieser Code aus?',
           'class Konto:\n    def __init__(self):\n        self.stand = 0\n\n    def einzahlen(self, betrag):\n        self.stand += betrag\n        return self.stand\n\nk = Konto()\nk.einzahlen(50)\nprint(k.einzahlen(20))', ['70', '20', '50'], 0,
           'Die Methode ändert den Kontostand und gibt den neuen Stand zurück.'),
    choice('Was gibt dieser Code aus?',
           'class Rechteck:\n    def __init__(self, b, h):\n        self.b = b\n        self.h = h\n\n    def flaeche(self):\n        return self.b * self.h\n\n    def __str__(self):\n        return f"Rechteck {self.b}x{self.h}"\n\nr = Rechteck(3, 4)\nprint(r, r.flaeche())', ['Rechteck 3x4 12', 'Rechteck 12', '3 4 12'], 0,
           'print(r) benutzt __str__, r.flaeche() rechnet 3 * 4.'),
    choice('Was gibt dieser Code aus?',
           'class Lampe:\n    def __init__(self):\n        self.an = False\n\n    def schalten(self):\n        self.an = not self.an\n\nl = Lampe()\nl.schalten()\nl.schalten()\nl.schalten()\nprint(l.an)', ['True', 'False', '3'], 0,
           'Jedes schalten() dreht an um: False → True → False → True.'),
])

lesson('inheritance', 'Vererbung', 'family_restroom',
       'Mit Vererbung baut eine Klasse auf einer anderen auf: class Schueler(Person): erbt alle Eigenschaften und Methoden von Person. '
       'Person ist die Elternklasse, Schueler die Kindklasse. Mit super() rufst du Methoden der Elternklasse auf. '
       'Die Kindklasse kann eigene Methoden hinzufügen oder geerbte überschreiben.', [
    fill('Lass Schueler von Person erben.',
         'class Person:\n    def __init__(self, vorname):\n        self.vorname = vorname\n\n    def zeige(self):\n        print(self.vorname)\n\nclass Schueler(' + B + '):\n    pass\n\nx = Schueler("Mike")\nx.zeige()', ['Person'],
         'In den Klammern steht die Elternklasse. Schueler hat dann alles, was Person hat – auch zeige().'),
    fill('Rufe das __init__ der Elternklasse auf.',
         'class Person:\n    def __init__(self, name):\n        self.name = name\n\nclass Schueler(Person):\n    def __init__(self, name, jahr):\n        ' + B + '().__init__(name)\n        self.jahr = jahr\n\nx = Schueler("Mia", 2030)\nprint(x.name, x.jahr)', ['super'],
         'super() steht für die Elternklasse. So muss man den Code von Person nicht noch einmal schreiben.'),
    choice('Was gibt dieser Code aus?',
           'class Tier:\n    def laut(self):\n        return "..."\n\nclass Katze(Tier):\n    def laut(self):\n        return "Miau"\n\nclass Fisch(Tier):\n    pass\n\nprint(Katze().laut(), Fisch().laut())', ['Miau ...', '... ...', 'Miau Miau'], 0,
           'Katze überschreibt laut(). Fisch hat keine eigene Version und benutzt die geerbte.'),
    choice('Was gibt dieser Code aus?',
           'class Person:\n    def gruss(self):\n        print("Hallo")\n\nclass Schueler(Person):\n    def gruss(self):\n        super().gruss()\n        print("Ich gehe zur Schule")\n\nSchueler().gruss()', ['Hallo\nIch gehe zur Schule', 'Ich gehe zur Schule', 'Hallo'], 0,
           'Die Kindklasse ruft zuerst die Eltern-Methode auf und ergänzt dann etwas.'),
    choice('Was gibt dieser Code aus?',
           'class A:\n    pass\n\nclass B(A):\n    pass\n\nb = B()\nprint(isinstance(b, A), issubclass(B, A), issubclass(A, B))', ['True True False', 'False True False', 'True True True'], 0,
           'Ein B-Objekt ist auch ein A (wegen der Vererbung). Aber A ist keine Unterklasse von B.'),
])

lesson('polymorphism', 'Polymorphie', 'diversity_3',
       'Polymorphie heißt „Vielgestaltigkeit“: Verschiedene Klassen haben Methoden mit gleichem Namen, die aber Unterschiedliches tun. '
       'So kannst du alle Objekte gleich behandeln: for x in (auto, boot): x.bewegen() – jedes bewegt sich auf seine Art. '
       'Auch eingebaute Funktionen wie len() sind polymorph: Sie funktionieren mit Texten, Listen und Dictionaries.', [
    choice('Was gibt dieser Code aus?',
           'print(len("Hallo"))\nprint(len(["a", "b"]))\nprint(len({"x": 1}))', ['5\n2\n1', '5\n5\n5', '1\n1\n1'], 0,
           'len() funktioniert mit vielen Typen – und zählt jeweils das Passende: Zeichen, Elemente, Paare.'),
    fill('Rufe bei jedem Fahrzeug dieselbe Methode auf.',
         'class Auto:\n    def bewegen(self):\n        print("Fahren!")\n\nclass Boot:\n    def bewegen(self):\n        print("Segeln!")\n\nfor x in (Auto(), Boot()):\n    x.' + B + '()', ['bewegen'],
         'Beide Klassen haben bewegen(). Die Schleife muss nicht wissen, welches Fahrzeug gerade dran ist.'),
    choice('Was gibt dieser Code aus?',
           'class Hund:\n    def laut(self):\n        return "Wuff"\n\nclass Kuh:\n    def laut(self):\n        return "Muh"\n\nfor tier in [Kuh(), Hund(), Kuh()]:\n    print(tier.laut())', ['Muh\nWuff\nMuh', 'Wuff\nMuh\nWuff', 'Muh\nMuh\nMuh'], 0,
           'Jedes Objekt antwortet mit seiner eigenen Version von laut().'),
    choice('Was gibt dieser Code aus?',
           'class Fahrzeug:\n    def __init__(self, marke):\n        self.marke = marke\n\n    def bewegen(self):\n        print("Bewegen!")\n\nclass Auto(Fahrzeug):\n    pass\n\nclass Flugzeug(Fahrzeug):\n    def bewegen(self):\n        print("Fliegen!")\n\nfor x in (Auto("Ford"), Flugzeug("Boeing")):\n    print(x.marke)\n    x.bewegen()', ['Ford\nBewegen!\nBoeing\nFliegen!', 'Ford\nFliegen!\nBoeing\nFliegen!', 'Ford\nBoeing'], 0,
           'Auto erbt bewegen() unverändert, Flugzeug überschreibt es. Beide haben die geerbte Eigenschaft marke.'),
    choice('Was gibt dieser Code aus?',
           'print(3 + 4)\nprint("3" + "4")\nprint([3] + [4])', ["7\n34\n[3, 4]", '7\n7\n7', "7\n34\n[7]"], 0,
           'Auch + ist polymorph: Bei Zahlen rechnet es, bei Texten und Listen hängt es an.'),
])

lesson('encapsulation', 'Kapselung', 'lock',
       'Kapselung schützt die Daten eines Objekts. Eigenschaften mit zwei Unterstrichen (self.__stand) sind privat: '
       'Von außen kommt man nicht heran, nur Methoden der Klasse dürfen sie benutzen. '
       'Ein Unterstrich (self._hinweis) bedeutet „bitte nur intern benutzen“ – ist aber nur eine Absprache.', [
    fill('Mache den Kontostand privat.',
         'class Konto:\n    def __init__(self, stand):\n        self.' + B + 'stand = stand\n\n    def zeige(self):\n        return self.__stand\n\nk = Konto(100)\nprint(k.zeige())', ['__'],
         'Zwei Unterstriche vor dem Namen machen die Eigenschaft privat.'),
    choice('Was passiert bei diesem Code?',
           'class Konto:\n    def __init__(self):\n        self.__stand = 100\n\nk = Konto()\nprint(k.__stand)', ['AttributeError: privat', '100', 'None'], 0,
           'Von außen gibt es k.__stand nicht – Python versteckt private Eigenschaften.',
           is_output=False),
    choice('Was gibt dieser Code aus?',
           'class Konto:\n    def __init__(self):\n        self.__stand = 0\n\n    def einzahlen(self, betrag):\n        if betrag > 0:\n            self.__stand += betrag\n\n    def stand(self):\n        return self.__stand\n\nk = Konto()\nk.einzahlen(50)\nk.einzahlen(-20)\nprint(k.stand())', ['50', '30', '0'], 0,
           'Weil man nur über einzahlen() an den Stand kommt, kann die Klasse ungültige Werte (negative Beträge) abwehren.'),
    fill('Erstelle eine Methode, die das private Alter zurückgibt (ein „Getter“).',
         'class Person:\n    def __init__(self, alter):\n        self.__alter = alter\n\n    def get_alter(self):\n        ' + B + ' self.__alter\n\np = Person(25)\nprint(p.get_alter())', ['return'],
         'Getter-Methoden geben private Werte kontrolliert heraus.'),
    choice('Was gibt dieser Code aus?',
           'class Spiel:\n    def __init__(self):\n        self._level = 1\n\ns = Spiel()\nprint(s._level)', ['1', 'AttributeError', 'None'], 0,
           'Ein einzelner Unterstrich ist nur ein Hinweis („intern“). Python verhindert den Zugriff nicht.'),
])

lesson('inner_classes', 'Innere Klassen', 'layers',
       'Eine Klasse kann in einer anderen Klasse stehen – das ist eine innere Klasse. '
       'Das ist praktisch, wenn sie nur zusammen mit der äußeren Klasse Sinn ergibt, z. B. ein Motor in einem Auto. '
       'Erstellen kann man sie über die äußere Klasse: Auto.Motor().', [
    fill('Erstelle ein Objekt der inneren Klasse.',
         'class Aussen:\n    class Innen:\n        def zeige(self):\n            print("Ich bin die innere Klasse")\n\ni = Aussen.' + B + '()\ni.zeige()', ['Innen'],
         'Die innere Klasse erreicht man über den Namen der äußeren Klasse und einen Punkt.'),
    choice('Was gibt dieser Code aus?',
           'class Auto:\n    def __init__(self, marke):\n        self.marke = marke\n        self.motor = self.Motor()\n\n    class Motor:\n        def __init__(self):\n            self.ps = 150\n\na = Auto("Toyota")\nprint(a.marke, a.motor.ps)', ['Toyota 150', 'Toyota', '150'], 0,
           'Beim Bauen des Autos wird auch ein Motor gebaut und im Auto gespeichert.'),
    choice('Was gibt dieser Code aus?',
           'class Aussen:\n    def __init__(self):\n        self.name = "außen"\n\n    class Innen:\n        def __init__(self):\n            self.name = "innen"\n\na = Aussen()\ni = a.Innen()\nprint(a.name, i.name)', ['außen innen', 'innen innen', 'außen außen'], 0,
           'Jede Klasse hat ihre eigenen Eigenschaften. Die innere Klasse kann man auch über ein Objekt erreichen: a.Innen().'),
    fill('Rufe die Methode der inneren Klasse auf.',
         'class Computer:\n    class Prozessor:\n        def rechne(self):\n            return 2 + 2\n\np = Computer.Prozessor()\nprint(p.' + B + '())', ['rechne'],
         'Ein Objekt der inneren Klasse funktioniert wie jedes andere Objekt.'),
    choice('Was gibt dieser Code aus?',
           'class Spiel:\n    class Level:\n        def __init__(self, nr):\n            self.nr = nr\n\n    def __init__(self):\n        self.levels = [self.Level(1), self.Level(2)]\n\ns = Spiel()\nprint(len(s.levels), s.levels[1].nr)', ['2 2', '2 1', '1 2'], 0,
           'Das Spiel baut beim Start zwei Level-Objekte und speichert sie in einer Liste.'),
])

# ---------------------------------------------------------------- Dateien

lesson('files', 'Dateien öffnen', 'folder_open',
       'Mit open(dateiname, modus) öffnest du eine Datei. Die Modi: "r" lesen (Standard), "a" anhängen, "w" überschreiben, '
       '"x" neu erstellen. Am besten benutzt du with open(...) as f: – dann wird die Datei am Ende automatisch geschlossen. '
       '(Im Spiel gibt es eine kleine eingebaute Festplatte nur für dein Programm.)', [
    fill('Öffne die Datei zum Lesen.',
         'f = open("demo.txt", "' + B + '")\nprint(f.read())\nf.close()', ['r'],
         '"r" steht für read (lesen). Lässt man den Modus weg, ist "r" der Standard.',
         files={'demo.txt': 'Hallo aus der Datei!'}),
    fill('Öffne die Datei mit with, damit sie automatisch geschlossen wird.',
         B + ' open("demo.txt") as f:\n    print(f.read())', ['with'],
         'Mit with muss man close() nicht selbst aufrufen – das passiert am Ende des Blocks automatisch.',
         files={'demo.txt': 'Hallo aus der Datei!'}),
    choice('Was passiert bei diesem Code? (Die Datei gibt es nicht.)',
           'f = open("gibtsnicht.txt", "r")', ['FileNotFoundError', 'Eine leere Datei wird erstellt', 'Es passiert nichts'], 0,
           'Zum Lesen muss die Datei existieren, sonst meldet Python FileNotFoundError.',
           is_output=False),
    choice('Welcher Modus hängt Text ans Ende an, ohne den alten Inhalt zu löschen?',
           '# open("notizen.txt", ???)',
           ['"a"', '"w"', '"r"'], 0,
           '"a" steht für append (anhängen). "w" würde den alten Inhalt überschreiben.',
           is_output=False),
    choice('Was gibt dieser Code aus?',
           'with open("demo.txt") as f:\n    print(f.closed)\nprint(f.closed)', ['False\nTrue', 'True\nTrue', 'False\nFalse'], 0,
           'Innerhalb von with ist die Datei offen. Danach hat with sie automatisch geschlossen.',
           files={'demo.txt': 'x'}),
])

lesson('files_read', 'Dateien lesen', 'menu_book',
       'read() liest die ganze Datei als Text, read(5) nur die ersten 5 Zeichen. readline() liest eine Zeile. '
       'Mit for zeile in f: gehst du Zeile für Zeile durch. Jede Zeile endet mit \\n – mit strip() entfernst du es.', [
    fill('Lies die ganze Datei.',
         'with open("gedicht.txt") as f:\n    print(f.' + B + '())', ['read'],
         'read() liefert den kompletten Inhalt als einen Text.',
         files={'gedicht.txt': 'Rosen sind rot,\nVeilchen sind blau.'}),
    choice('Was gibt dieser Code aus?',
           'with open("gedicht.txt") as f:\n    print(f.read(5))', ['Rosen', 'Rosen sind rot,', 'R'], 0,
           'read(5) liest nur die ersten 5 Zeichen.',
           files={'gedicht.txt': 'Rosen sind rot,\nVeilchen sind blau.'}),
    fill('Lies nur die erste Zeile.',
         'with open("gedicht.txt") as f:\n    print(f.' + B + '(), end="")', ['readline'],
         'readline() liest bis einschließlich zum nächsten Zeilenumbruch.',
         files={'gedicht.txt': 'Rosen sind rot,\nVeilchen sind blau.'}),
    choice('Was gibt dieser Code aus?',
           'with open("liste.txt") as f:\n    for zeile in f:\n        print(zeile.strip().upper())', ['MILCH\nBROT', 'milch\nbrot', 'MILCH BROT'], 0,
           'Die Schleife liefert jede Zeile. strip() entfernt das \\n am Ende, upper() macht alles groß.',
           files={'liste.txt': 'milch\nbrot\n'}),
    choice('Was gibt dieser Code aus?',
           'with open("liste.txt") as f:\n    zeilen = f.readlines()\nprint(len(zeilen), zeilen[0])', ["2 milch\n", '2 milch', "1 milch\n"], 0,
           'readlines() liefert eine Liste aller Zeilen – jede noch mit \\n am Ende. Darum folgt nach „milch“ ein Zeilenumbruch.',
           files={'liste.txt': 'milch\nbrot\n'}),
])

lesson('files_write', 'Dateien schreiben', 'edit_note',
       'Zum Schreiben öffnest du die Datei mit "w" (überschreibt alles) oder "a" (hängt hinten an). '
       'Mit f.write(text) schreibst du hinein – Zeilenumbrüche musst du selbst mit \\n einfügen. '
       '"w" und "a" erstellen die Datei, falls es sie noch nicht gibt. "x" erstellt nur eine neue und meckert, wenn es sie schon gibt.', [
    fill('Hänge Text an die Datei an.',
         'with open("tagebuch.txt", "' + B + '") as f:\n    f.write("\\nHeute: Python gelernt!")\n\nwith open("tagebuch.txt") as f:\n    print(f.read())', ['a'],
         '"a" (append) hängt neuen Text ans Ende. Der alte Inhalt bleibt.',
         files={'tagebuch.txt': 'Liebes Tagebuch,'}),
    fill('Schreibe den Text in die Datei.',
         'with open("neu.txt", "w") as f:\n    f.' + B + '("Hallo, Datei!")\n\nwith open("neu.txt") as f:\n    print(f.read())', ['write'],
         'write() schreibt Text in die Datei. Weil "neu.txt" noch nicht existierte, wird sie erstellt.'),
    choice('Was gibt dieser Code aus?',
           'with open("notiz.txt", "w") as f:\n    f.write("Neu!")\n\nwith open("notiz.txt") as f:\n    print(f.read())', ['Neu!', 'Alt.Neu!', 'Alt.'], 0,
           '"w" überschreibt den alten Inhalt komplett.',
           files={'notiz.txt': 'Alt.'}),
    choice('Was gibt dieser Code aus?',
           'with open("zahlen.txt", "w") as f:\n    for i in range(3):\n        f.write(str(i) + "\\n")\n\nwith open("zahlen.txt") as f:\n    print(f.read().split())', ["['0', '1', '2']", "['012']", '[0, 1, 2]'], 0,
           'Jede Zahl wird als Text mit \\n geschrieben. Beim Lesen teilt split() an den Zeilenumbrüchen.'),
    choice('Was passiert bei diesem Code? (Die Datei gibt es schon.)',
           'f = open("da.txt", "x")', ['FileExistsError', 'Die Datei wird geleert', 'Es passiert nichts'], 0,
           '"x" erstellt nur NEUE Dateien. Gibt es die Datei schon, meldet Python FileExistsError.',
           is_output=False, files={'da.txt': 'schon da'}),
])

lesson('files_delete', 'Dateien löschen', 'delete',
       'Zum Löschen brauchst du das Modul os: import os und dann os.remove("datei.txt"). '
       'Damit es keinen Fehler gibt, prüfst du vorher mit os.path.exists(), ob die Datei existiert.', [
    fill('Lösche die Datei.',
         'import os\nos.' + B + '("alt.txt")\nprint(os.path.exists("alt.txt"))', ['remove'],
         'os.remove() löscht eine Datei. Danach gibt es sie nicht mehr.',
         files={'alt.txt': 'weg damit'}),
    fill('Prüfe, ob die Datei existiert.',
         'import os\nprint(os.path.' + B + '("alt.txt"))', ['exists'],
         'os.path.exists() liefert True oder False.',
         files={'alt.txt': 'noch da'}),
    choice('Was gibt dieser Code aus?',
           'import os\nif os.path.exists("demo.txt"):\n    os.remove("demo.txt")\n    print("gelöscht")\nelse:\n    print("Die Datei gibt es nicht")', ['Die Datei gibt es nicht', 'gelöscht', 'FileNotFoundError'], 0,
           'Weil demo.txt nicht existiert, läuft der else-Teil – und es gibt keinen Fehler.'),
    choice('Was passiert bei diesem Code? (Die Datei gibt es nicht.)',
           'import os\nos.remove("weg.txt")', ['FileNotFoundError', 'Es passiert nichts', 'Die Datei wird erstellt'], 0,
           'Eine Datei, die es nicht gibt, kann man nicht löschen.',
           is_output=False),
    order('Ordne die Zeilen: Datei erstellen, prüfen, löschen, nochmal prüfen (True, dann False).',
          ['import os', 'open("test.txt", "w").close()', 'print(os.path.exists("test.txt"))', 'os.remove("test.txt")', 'print(os.path.exists("test.txt"))'],
          'Erst das Modul laden, dann die Datei anlegen – erst danach kann man sie finden und löschen.'),
])
