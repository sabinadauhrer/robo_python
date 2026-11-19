import 'dart:convert';

import 'package:flutter/services.dart';

import '../exercises/exercise.dart';

/// Lädt alle Lektionen aus `assets/lessons/` (neue Dateien werden automatisch gefunden).
class LessonRepository {
  LessonRepository(this._bundle);

  final AssetBundle _bundle;
  static const folder = 'assets/lessons/';

  Future<List<Lesson>> loadAll() async {
    final manifest = await AssetManifest.loadFromAssetBundle(_bundle);
    final paths = manifest.listAssets().where((p) => p.startsWith(folder) && p.endsWith('.json'));
    return parse(await Future.wait(paths.map(_bundle.loadString)));
  }

  static List<Lesson> parse(Iterable<String> sources) =>
      [for (final s in sources) Lesson.fromJson(jsonDecode(s) as Map<String, dynamic>)]
        ..sort((a, b) => a.order.compareTo(b.order));
}
