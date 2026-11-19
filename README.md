# Robo Python

Web-App (Flutter Web, installierbar als PWA) zum spielerischen Python-Lernen:
Auf einer **Abenteuer-Karte** reist man mit Robo von Insel zu Insel. Jede Insel ist ein
Python-Thema (wie bei W3Schools) mit Aufgaben – und Robo erklärt **während** der Aufgabe,
warum der Code so ist.

- **Aufgabentypen:** Lücke füllen · Was passiert? (Auswahl) · Zeilen in Reihenfolge bringen
- **Erklärungen:** Robo-Erklärung zur Aufgabe, antippbare Zeilen (?) mit eigener Erklärung, kostenloser Tipp
- **Probelauf:** spielt den Code Schritt für Schritt ab (markierte Zeile, Variablen-Kästchen, Ausgabe, Erklärung je Schritt)
- **Spiel:** 3 Herzen pro Insel, XP mit Combo-Bonus, Sterne, Münzen, Tages-Serie, Shop mit Outfits für Robo
- **20 Inseln, 100 Aufgaben:** print, Variablen, Datentypen, Zahlen, Casting, Strings, String-Methoden, f-Strings,
  Booleans, if/elif/else, while, for, Listen, Listen-Methoden, Tupel, Sets, Dictionaries, Funktionen, Lambda, Iteratoren

## Starten

```bash
flutter pub get
flutter run -d chrome        # Entwicklung im Browser
flutter test                 # alle Tests
flutter analyze
```

## Veröffentlichen

```bash
flutter build web --release                     # Ergebnis: build/web/ (statische Website)
flutter build web --release --base-href /robo/  # falls die App in einem Unterordner liegt
```

Lokal testen: `cd build/web && python3 -m http.server 8080` → http://localhost:8080

## Architektur

| Ordner | Inhalt |
|---|---|
| `lib/python/` | Eigener Python-Interpreter (reines Dart): Lexer, Parser, Werte, Operatoren, Builtins, Methoden. Zeichnet jeden Schritt mit deutscher Erklärung auf (Trace). |
| `lib/exercises/` | Aufgaben- und Lektions-Modelle, Prüflogik, Punkte/Serie, Outfits (reines Dart). |
| `lib/data/` | Lektionen aus `assets/lessons/` laden, Spielstand in `shared_preferences` (Browser-Speicher). |
| `lib/state/` | Riverpod: Profil, Einstellungen, Ablauf einer Lektion (`LessonSession`). |
| `lib/audio/` | Soundeffekte (`audioplayers`). |
| `lib/ui/` | Karte, Lektion, Probelauf, Shop, Kawaii-Figuren. |

Der Interpreter wird gegen **echtes Python** getestet: `tool/make_python_fixtures.py` erzeugt Referenzausgaben,
`test/python/python_compat_test.dart` vergleicht sie.

## Neue Aufgaben / Inseln hinzufügen

Die Inhalte stehen in **`tool/lessons_source.py`**. Dort eine Lektion mit `lesson(...)` und Aufgaben mit
`fill(...)`, `choice(...)` oder `order(...)` ergänzen und dann ausführen:

```bash
python3 tool/lessons_source.py   # schreibt assets/lessons/*.json
flutter test                     # prüft jede Aufgabe mit dem eigenen Interpreter
```

Das Skript führt jede Musterlösung mit echtem Python aus: Erwartete Ausgaben stimmen damit automatisch, und bei
„Was gibt der Code aus?“ bricht es ab, wenn die richtige Option nicht der echten Ausgabe entspricht.

Beispiele:

```python
fill('Gib „Hallo“ aus.', B + '("Hallo")', ['print'],
     'Erklärung, die Robo WÄHREND der Aufgabe zeigt …',
     {1: 'Erklärung zu Zeile 1 (antippbar)'}, hint='Tipp')

choice('Was gibt dieser Code aus?', 'print(2 * 3)', ['6', '23', '5'], 0, 'Erklärung …')

order('Ordne die Zeilen …', ['x = 1', 'print(x)'], 'Erklärung …')
```

`B` ist die Lücke (`___`). Mehrere erlaubte Antworten pro Lücke: `[['"Ali"', "'Ali'"]]`.
Bei Lückentexten zählt außerdem jede andere Antwort, die dieselbe Ausgabe erzeugt.

## Sounds, Icons, Schriften

- Sounds: `python3 tool/make_sounds.py assets/sounds` (selbst erzeugte Töne)
- App-Icons: `python3 tool/make_icons.py web`
- Schriften: Varela Round und JetBrains Mono (SIL Open Font License, `assets/fonts/OFL-*.txt`)
