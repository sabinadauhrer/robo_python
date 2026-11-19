import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../state/profile.dart';

/// Speichert Spielstand und Einstellungen im Browser (localStorage).
class ProfileRepository {
  ProfileRepository(this._prefs);

  final SharedPreferences _prefs;
  static const _profileKey = 'profile.v1';
  static const _soundKey = 'settings.sound';

  Profile load() {
    final raw = _prefs.getString(_profileKey);
    if (raw == null) return const Profile();
    try {
      return Profile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const Profile(); // beschädigte Daten ignorieren
    }
  }

  Future<void> save(Profile profile) => _prefs.setString(_profileKey, jsonEncode(profile.toJson()));

  bool loadSoundEnabled() => _prefs.getBool(_soundKey) ?? true;

  Future<void> saveSoundEnabled(bool value) => _prefs.setBool(_soundKey, value);
}
