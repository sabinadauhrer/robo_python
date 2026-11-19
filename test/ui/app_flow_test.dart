import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:robo_python/audio/sfx.dart';
import 'package:robo_python/audio/sound_player.dart';
import 'package:robo_python/state/providers.dart';
import 'package:robo_python/ui/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SilentSoundPlayer sounds;

  Future<SharedPreferences> pumpApp(WidgetTester tester, {Size size = const Size(1280, 900), Map<String, Object> prefs = const {}}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    rootBundle.clear(); // gecachte Asset-Futures aus anderen Tests würden hängen
    SharedPreferences.setMockInitialValues(prefs);
    final p = await SharedPreferences.getInstance();
    sounds = SilentSoundPlayer();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(p),
        soundPlayerProvider.overrideWithValue(sounds),
        clockProvider.overrideWithValue(() => DateTime(2026, 11, 19)),
      ],
      child: const RoboPythonApp(),
    ));
    await tester.pumpAndSettle();
    return p;
  }

  /// Die ersten drei Inseln sind geschafft – so ist „Ausgabe mit print“ (Insel 4) offen.
  final unlockedPrint = {
    'profile.v1': jsonEncode({
      'lessonStars': {'intro': 1, 'get_started': 1, 'syntax': 1},
    }),
  };

  Future<void> openFirstLesson(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Ausgabe mit print'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ausgabe mit print'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Mit print() zeigt Python'), findsOneWidget);
    await tester.tap(find.byKey(const Key('start-lesson')));
    await tester.pumpAndSettle();
  }

  Future<void> checkAndNext(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('check')));
    await tester.pumpAndSettle();
    expect(find.text('Super!'), findsOneWidget);
    await tester.tap(find.byKey(const Key('next')));
    await tester.pumpAndSettle();
  }

  testWidgets('Neue Spieler starten bei Insel 1, Kapitel stehen auf der Karte', (tester) async {
    await pumpApp(tester);
    expect(find.textContaining('Hallo, ich bin Robo'), findsOneWidget);
    expect(find.text('Was ist Python?'), findsOneWidget);
    expect(find.text('Grundlagen'), findsOneWidget);
    expect(find.textContaining('0 von 107 Inseln geschafft'), findsOneWidget);
  });

  testWidgets('Print-Insel komplett lösen: Lücken, Auswahl, Reihenfolge → Belohnung', (tester) async {
    final prefs = await pumpApp(tester, prefs: unlockedPrint);
    await openFirstLesson(tester);

    // 1) Lücke: print
    expect(find.text('Lücke füllen'), findsOneWidget);
    expect(find.textContaining('print ist der Befehl'), findsOneWidget); // Erklärung WÄHREND der Aufgabe
    await tester.enterText(find.byType(TextField).first, 'print');
    await tester.pump();
    await checkAndNext(tester);

    // 2) Zwei Lücken: Anführungszeichen
    await tester.enterText(find.byType(TextField).at(0), '"');
    await tester.enterText(find.byType(TextField).at(1), '"');
    await tester.pump();
    await checkAndNext(tester);

    // 3) + 4) Auswahl
    await tester.tap(find.text('7'));
    await tester.pump();
    await checkAndNext(tester);
    await tester.tap(find.text('Robo mag Python'));
    await tester.pump();
    await checkAndNext(tester);

    // 5) Reihenfolge
    await tester.tap(find.text('print("Guten Morgen")'));
    await tester.pump();
    await tester.tap(find.text('print("Wie geht es dir?")'));
    await tester.pump();
    await checkAndNext(tester);

    expect(find.text('Insel geschafft!'), findsOneWidget);
    expect(find.text('+70'), findsOneWidget); // 10 + 12 + 14 + 16 + 18 XP (Combo-Bonus)
    expect(sounds.played.where((s) => s == Sfx.correct), hasLength(5));
    expect(sounds.played.last, Sfx.success);

    final saved = jsonDecode(prefs.getString('profile.v1')!) as Map<String, dynamic>;
    expect(saved['lessonStars'], {'intro': 1, 'get_started': 1, 'syntax': 1, 'l01_print': 3});
    expect(saved['coins'], 20);
    expect(saved['streak'], 1);

    await tester.tap(find.byKey(const Key('done')));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 3000)); // nach oben scrollen
    await tester.pumpAndSettle();
    expect(find.text('4 von 107 Inseln geschafft · 6 von 321 Sternen'), findsOneWidget);
  });

  testWidgets('Zeilen-Erklärung antippen, falsche Antwort kostet ein Herz, Lösung zeigen', (tester) async {
    await pumpApp(tester, prefs: unlockedPrint);
    await openFirstLesson(tester);

    // Zeile 1 hat eine Notiz → antippen zeigt die Zeilen-Erklärung
    await tester.tap(find.text('?').first);
    await tester.pumpAndSettle();
    expect(find.text('Zeile 1'), findsOneWidget);
    expect(find.textContaining('gibt den Inhalt der Klammern aus'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'pront');
    await tester.pump();
    await tester.tap(find.byKey(const Key('check')));
    await tester.pumpAndSettle();
    expect(find.text('Noch nicht ganz'), findsOneWidget);
    expect(find.textContaining('NameError'), findsOneWidget); // echte Python-Meldung
    expect(find.byIcon(Icons.favorite_rounded), findsNWidgets(2));

    await tester.tap(find.text('Lösung zeigen'));
    await tester.pumpAndSettle();
    expect(find.text('So geht’s'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'print'), findsOneWidget);
  });

  testWidgets('viele Fehler: kein Neustart, sondern immer bessere Tipps', (tester) async {
    await pumpApp(tester, prefs: unlockedPrint);
    await openFirstLesson(tester);
    Future<void> wrong(int i) async {
      await tester.enterText(find.byType(TextField).first, 'falsch$i');
      await tester.pump();
      await tester.tap(find.byKey(const Key('check')));
      await tester.pumpAndSettle();
    }

    await wrong(1);
    expect(find.textContaining('Tipp: Der Befehl heißt wie das englische Wort'), findsOneWidget);
    await tester.tap(find.byKey(const Key('retry')));
    await tester.pumpAndSettle();

    await wrong(2);
    expect(find.textContaining('Großer Tipp: Die Lücke beginnt mit „pr…“ (5 Zeichen)'), findsOneWidget);
    await tester.tap(find.byKey(const Key('retry')));
    await tester.pumpAndSettle();

    await wrong(3);
    expect(find.textContaining('Tippe auf „Lösung zeigen“'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_rounded), findsNothing); // keine Herzen mehr …
    await tester.tap(find.byKey(const Key('retry'))); // … aber man darf weiter probieren
    await tester.pumpAndSettle();
    await wrong(4);
    await tester.tap(find.byKey(const Key('reveal')));
    await tester.pumpAndSettle();
    expect(find.text('So geht’s'), findsOneWidget);
    await tester.tap(find.byKey(const Key('next')));
    await tester.pumpAndSettle();
    expect(find.text('Lücke füllen'), findsOneWidget); // nächste Aufgabe statt Neustart
  });

  testWidgets('gesperrte Insel: trotzdem starten oder alle freischalten', (tester) async {
    final prefs = await pumpApp(tester);
    await tester.ensureVisible(find.text('Ausgabe mit print'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ausgabe mit print'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Diese Insel ist noch gesperrt'), findsOneWidget);
    await tester.tap(find.byKey(const Key('start-anyway')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Mit print() zeigt Python'), findsOneWidget); // Einführung der Insel
    expect(prefs.getBool('settings.allUnlocked'), isNull); // nur einmalig

    await tester.tapAt(const Offset(5, 5)); // Einführung schließen
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ausgabe mit print'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('unlock-all')));
    await tester.pumpAndSettle();
    expect(prefs.getBool('settings.allUnlocked'), isTrue);
    expect(find.byIcon(Icons.lock_rounded), findsNothing);
  });

  testWidgets('Spielstand-Code sichern und wiederherstellen', (tester) async {
    final prefs = await pumpApp(tester, prefs: unlockedPrint);
    await tester.tap(find.byTooltip('Spielstand sichern'));
    await tester.pumpAndSettle();
    final code = tester.widget<SelectableText>(find.byKey(const Key('backup-code'))).data!;
    expect(code, startsWith('ROBO1-'));

    await tester.enterText(find.byKey(const Key('restore-input')), 'Quatsch');
    await tester.tap(find.byKey(const Key('restore')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Dieser Code passt nicht'), findsOneWidget);

    await prefs.clear();
    await tester.enterText(find.byKey(const Key('restore-input')), code);
    await tester.tap(find.byKey(const Key('restore')));
    await tester.pumpAndSettle();
    expect(find.textContaining('3 Inseln, 3 Sterne'), findsOneWidget);
    final saved = jsonDecode(prefs.getString('profile.v1')!) as Map<String, dynamic>;
    expect(saved['lessonStars'], {'intro': 1, 'get_started': 1, 'syntax': 1});
  });

  testWidgets('Probelauf zeigt Schritte mit Erklärung', (tester) async {
    await pumpApp(tester, prefs: unlockedPrint);
    await openFirstLesson(tester);
    await tester.enterText(find.byType(TextField).first, 'print');
    await tester.pump();
    await tester.tap(find.text('Probelauf starten'));
    await tester.pumpAndSettle();
    expect(find.text('Schritt 0 von 1'), findsOneWidget);
    await tester.tap(find.byTooltip('Schritt vor'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Zeile 1: print() schreibt in die Ausgabe: Hallo Welt'), findsOneWidget);
    expect(sounds.played, contains(Sfx.move));
  });

  testWidgets('Shop: Outfit kaufen und anziehen', (tester) async {
    await pumpApp(tester, prefs: {'profile.v1': jsonEncode({'coins': 30})});
    await tester.tap(find.byTooltip('Robos Shop'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '20'));
    await tester.pumpAndSettle();
    expect(find.text('Angezogen'), findsOneWidget);
    expect(find.text('10'), findsOneWidget); // Münzen übrig
    expect(sounds.played, [Sfx.coin]);
  });

  testWidgets('Handy-Layout funktioniert ohne Überlauf', (tester) async {
    await pumpApp(tester, size: const Size(390, 844), prefs: unlockedPrint);
    await openFirstLesson(tester);
    expect(find.text('Lücke füllen'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
