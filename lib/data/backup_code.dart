import 'dart:convert';

import '../state/profile.dart';

/// Spielstand als Text-Code zum Sichern (z. B. in Notizen) und Wiederherstellen auf jedem Gerät.
abstract final class BackupCode {
  static const _prefix = 'ROBO1-';

  static String encode(Profile profile) =>
      _prefix + base64Url.encode(utf8.encode(jsonEncode(profile.toJson()))).replaceAll('=', '');

  /// Liest einen Code; null, wenn er ungültig ist. Leerzeichen und Zeilenumbrüche werden ignoriert.
  static Profile? decode(String code) {
    var text = code.replaceAll(RegExp(r'\s'), '');
    if (!text.startsWith(_prefix)) return null;
    text = text.substring(_prefix.length);
    text += '=' * ((4 - text.length % 4) % 4);
    try {
      final json = jsonDecode(utf8.decode(base64Url.decode(text)));
      if (json is! Map<String, dynamic>) return null;
      return Profile.fromJson(json);
    } catch (_) {
      return null;
    }
  }
}
