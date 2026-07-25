import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static const String _keyPlayer1Name = 'player1_name';
  static const String _keyPlayer2Name = 'player2_name';
  static const String _keyPlayer1Gender = 'player1_gender';
  static const String _keyPlayer2Gender = 'player2_gender';
  static const String _keyPlayer1Color = 'player1_color';
  static const String _keyPlayer2Color = 'player2_color';
  static const String _keyFriendsMode = 'friends_mode';
  static const String _keySoundEnabled = 'sound_enabled';
  static const String _keyVibrationEnabled = 'vibration_enabled';
  static const String _keyRouletteSpinCount = 'roulette_spin_count';
  static const String _keyGuestMode = 'guest_mode';

  static const String _keyGamesPlayed = 'stats_games_played';
  static const String _keyFavoriteGame = 'stats_favorite_game';
  static const String _keyPlayTimeMinutes = 'stats_play_time_minutes';

  // ── Monetization (Phase 3) ──
  static const String _keyIsPremium = 'monetization_is_premium';
  static const String _keyPlayCounts = 'monetization_play_counts';
  static const String _keyLastResetDate = 'monetization_last_reset_date';

  // ── Migration from old keys ──
  static const String _keyHeName = 'he_name';
  static const String _keySheName = 'she_name';

  static Future<void> migrateOldKeys() async {
    final prefs = await SharedPreferences.getInstance();
    final hasOldHe = prefs.containsKey(_keyHeName);
    if (!hasOldHe) return;
    final he = prefs.getString(_keyHeName) ?? '';
    final she = prefs.getString(_keySheName) ?? '';
    if (he.isNotEmpty) {
      await prefs.setString(_keyPlayer1Name, he);
    }
    if (she.isNotEmpty) {
      await prefs.setString(_keyPlayer2Name, she);
    }
    if (!prefs.containsKey(_keyPlayer1Gender)) {
      await prefs.setString(_keyPlayer1Gender, 'male');
    }
    if (!prefs.containsKey(_keyPlayer2Gender)) {
      await prefs.setString(_keyPlayer2Gender, 'female');
    }
    if (!prefs.containsKey(_keyPlayer1Color)) {
      await prefs.setInt(_keyPlayer1Color, 0xFF448AFF); // blueAccent
    }
    if (!prefs.containsKey(_keyPlayer2Color)) {
      await prefs.setInt(_keyPlayer2Color, 0xFFFF4081); // pinkAccent
    }
    await prefs.remove(_keyHeName);
    await prefs.remove(_keySheName);
  }

  static Future<void> savePlayer1Name(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPlayer1Name, name.trim());
  }

  static Future<String> getPlayer1Name() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPlayer1Name) ?? '';
  }

  static Future<void> savePlayer2Name(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPlayer2Name, name.trim());
  }

  static Future<String> getPlayer2Name() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPlayer2Name) ?? '';
  }

  static Future<void> savePlayer1Gender(String gender) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPlayer1Gender, gender);
  }

  static Future<String> getPlayer1Gender() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPlayer1Gender) ?? '';
  }

  static Future<void> savePlayer2Gender(String gender) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPlayer2Gender, gender);
  }

  static Future<String> getPlayer2Gender() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPlayer2Gender) ?? '';
  }

  static Future<void> savePlayer1Color(int colorValue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyPlayer1Color, colorValue);
  }

  static Future<int> getPlayer1Color() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyPlayer1Color) ?? 0xFF448AFF;
  }

  static Future<void> savePlayer2Color(int colorValue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyPlayer2Color, colorValue);
  }

  static Future<int> getPlayer2Color() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyPlayer2Color) ?? 0xFFFF4081;
  }

  static Future<void> setFriendsMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFriendsMode, enabled);
  }

  static Future<bool> isFriendsMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyFriendsMode) ?? false;
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

  // ── Guest mode ──

  static Future<void> setGuestMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyGuestMode, enabled);
  }

  static Future<bool> isGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyGuestMode) ?? false;
  }

  // ── Stats ──

  static Future<void> saveGamesPlayed(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyGamesPlayed, count);
  }

  static Future<int> getGamesPlayed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyGamesPlayed) ?? 0;
  }

  static Future<void> saveFavoriteGame(String gameName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFavoriteGame, gameName);
  }

  static Future<String> getFavoriteGame() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyFavoriteGame) ?? '';
  }

  static Future<void> savePlayTimeMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyPlayTimeMinutes, minutes);
  }

  static Future<int> getPlayTimeMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyPlayTimeMinutes) ?? 0;
  }

  // ── Reset all data ──

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// Borra todo MENOS las keys de monetizacion (`monetization_*`).
  /// Usado por `SettingsProvider.resetAllData()` — el user pide "reset"
  /// pero su compra premium no debe evaporarse.
  static Future<void> clearAllExceptMonetization() async {
    final prefs = await SharedPreferences.getInstance();
    final keysToKeep = <String>{
      _keyIsPremium,
      _keyPlayCounts,
      _keyLastResetDate,
    };
    for (final key in prefs.getKeys()) {
      if (!keysToKeep.contains(key)) {
        await prefs.remove(key);
      }
    }
  }

  // ── Monetization (Phase 3) ──
  //
  // IMPORTANTE: clearAll() borra isPremium. La razon: resetAllData() del
  // SettingsProvider NO debe borrar premium (decision de diseno), pero un
  // uninstall+reinstall o un debug reset debe arrancar como free. Quien
  // llama a clearAll es responsable de re-marcar premium si corresponde.

  static Future<void> setIsPremium(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsPremium, value);
  }

  static Future<bool> isPremium() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsPremium) ?? false;
  }

  /// Guarda el mapa de plays de hoy: { gameName: count }.
  /// Usar una sola key (string JSON) es mas simple que una key por juego.
  static Future<void> savePlayCounts(Map<String, int> counts) async {
    final prefs = await SharedPreferences.getInstance();
    final json = counts.entries.map((e) => '${e.key}:${e.value}').join(',');
    await prefs.setString(_keyPlayCounts, json);
  }

  static Future<Map<String, int>> getPlayCounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyPlayCounts) ?? '';
    if (raw.isEmpty) return <String, int>{};
    final out = <String, int>{};
    for (final pair in raw.split(',')) {
      final parts = pair.split(':');
      if (parts.length == 2) {
        final name = parts[0];
        final count = int.tryParse(parts[1]) ?? 0;
        if (name.isNotEmpty) out[name] = count;
      }
    }
    return out;
  }

  /// Guarda la fecha del ultimo reset diario (string YYYY-MM-DD local).
  static Future<void> setLastResetDate(String dayKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastResetDate, dayKey);
  }

  static Future<String> getLastResetDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastResetDate) ?? '';
  }
}
