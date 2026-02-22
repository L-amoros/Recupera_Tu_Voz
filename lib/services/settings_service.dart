import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';
import '../models/frase_item.dart';

class SettingsService {
  static const _keySettings = 'app_settings';
  static const _keyFrases = 'frases_personales';

  Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keySettings);
    if (raw == null) return const AppSettings();
    try {
      return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const AppSettings();
    }
  }

  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySettings, jsonEncode(settings.toJson()));
  }

  Future<List<FraseItem>> loadFrasesPersonales() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_keyFrases) ?? [];
    return raw
        .map((s) => FraseItem.fromJsonString(s))
        .toList();
  }

  Future<void> saveFrasesPersonales(List<FraseItem> frases) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _keyFrases,
      frases.map((f) => f.toJsonString()).toList(),
    );
  }
}
