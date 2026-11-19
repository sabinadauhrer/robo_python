/// Outfits für Robo – mit Münzen im Shop kaufbar.
enum Outfit {
  none('Ohne', 0),
  bow('Schleife', 20),
  flower('Blumenkranz', 40),
  headphones('Kopfhörer', 50),
  catEars('Katzenohren', 60),
  wizardHat('Zauberhut', 80),
  crown('Krone', 120);

  const Outfit(this.label, this.price);

  final String label;
  final int price;
}
