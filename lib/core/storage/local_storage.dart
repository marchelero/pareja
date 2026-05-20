import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static const String _keyHeName = 'he_name';
  static const String _keySheName = 'she_name';
  static const String _keySoundEnabled = 'sound_enabled';
  static const String _keyVibrationEnabled = 'vibration_enabled';
  static const String _keyRouletteSpinCount = 'roulette_spin_count';

  static Future<void> saveNames(String heName, String sheName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyHeName, heName.trim());
    await prefs.setString(_keySheName, sheName.trim());
  }

  static Future<String> getHeName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyHeName) ?? '';
  }

  static Future<String> getSheName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySheName) ?? '';
  }

  static Future<void> setSoundEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySoundEnabled, enabled);
  }

  static Future<bool> isSoundEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keySoundEnabled) ?? true;
  }

  static Future<void> setVibrationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyVibrationEnabled, enabled);
  }

  static Future<bool> isVibrationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyVibrationEnabled) ?? true;
  }

  static Future<void> saveRouletteSpinCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyRouletteSpinCount, count);
  }

  static Future<int> getRouletteSpinCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyRouletteSpinCount) ?? 0;
  }

  static Future<void> resetRouletteProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyRouletteSpinCount, 0);
  }

  static const String _keyUsedDrinkTasks = 'used_drink_tasks';

  static Future<List<String>> getUsedDrinkTasks() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyUsedDrinkTasks) ?? [];
  }

  static Future<void> addUsedDrinkTask(String id) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> used = prefs.getStringList(_keyUsedDrinkTasks) ?? [];
    if (!used.contains(id)) {
      used.add(id);
      await prefs.setStringList(_keyUsedDrinkTasks, used);
    }
  }

  static Future<void> clearUsedDrinkTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUsedDrinkTasks);
  }
}
