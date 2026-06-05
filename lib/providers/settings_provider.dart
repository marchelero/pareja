import 'package:flutter/material.dart';
import '../core/storage/local_storage.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';

enum PlayerGender { male, female }

class SettingsProvider extends ChangeNotifier {
  String _player1Name = AppConstants.defaultHeName;
  String _player2Name = AppConstants.defaultSheName;
  PlayerGender _player1Gender = PlayerGender.male;
  PlayerGender _player2Gender = PlayerGender.female;
  Color _player1Color = AppColors.defaultPlayer1Color;
  Color _player2Color = AppColors.defaultPlayer2Color;
  bool _friendsMode = false;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  int _rouletteSpinCount = 0;
  bool _isLoaded = false;
  bool _namesCustomized = false;

  String get player1Name => _player1Name;
  String get player2Name => _player2Name;
  PlayerGender get player1Gender => _player1Gender;
  PlayerGender get player2Gender => _player2Gender;
  Color get player1Color => _player1Color;
  Color get player2Color => _player2Color;
  bool get friendsMode => _friendsMode;
  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  int get rouletteSpinCount => _rouletteSpinCount;
  bool get isLoaded => _isLoaded;
  bool get namesCustomized => _namesCustomized;

  IconData get player1Icon => _player1Gender == PlayerGender.male ? Icons.male : Icons.female;
  IconData get player2Icon => _player2Gender == PlayerGender.male ? Icons.male : Icons.female;

  static Color _defaultColorForPlayer(int index, PlayerGender p1g, PlayerGender p2g) {
    if (index == 1) {
      return p1g == PlayerGender.male ? AppColors.defaultPlayer1Color : AppColors.defaultPlayer2Color;
    }
    if (p1g == p2g) {
      return p1g == PlayerGender.male ? const Color(0xFF1565C0) : const Color(0xFFC2185B);
    }
    return p2g == PlayerGender.male ? AppColors.defaultPlayer1Color : AppColors.defaultPlayer2Color;
  }

  Future<void> load() async {
    await LocalStorage.migrateOldKeys();

    final p1Name = await LocalStorage.getPlayer1Name();
    final p2Name = await LocalStorage.getPlayer2Name();
    final p1Gender = await LocalStorage.getPlayer1Gender();
    final p2Gender = await LocalStorage.getPlayer2Gender();
    final p1Color = await LocalStorage.getPlayer1Color();
    final p2Color = await LocalStorage.getPlayer2Color();
    final friends = await LocalStorage.isFriendsMode();

    _friendsMode = friends;

    if (p1Name.isNotEmpty || p2Name.isNotEmpty) {
      _namesCustomized = true;
      _player1Name = p1Name.isNotEmpty ? p1Name : _defaultName(1);
      _player2Name = p2Name.isNotEmpty ? p2Name : _defaultName(2);
    } else {
      _player1Name = _defaultName(1);
      _player2Name = _defaultName(2);
    }

    _player1Gender = p1Gender == 'female' ? PlayerGender.female : PlayerGender.male;
    _player2Gender = p2Gender == 'male' ? PlayerGender.male : PlayerGender.female;

    _player1Color = Color(p1Color);
    _player2Color = Color(p2Color);

    _soundEnabled = await LocalStorage.isSoundEnabled();
    _vibrationEnabled = await LocalStorage.isVibrationEnabled();
    _rouletteSpinCount = await LocalStorage.getRouletteSpinCount();
    _isLoaded = true;
    notifyListeners();
  }

  String _defaultName(int player) {
    if (_friendsMode) {
      return player == 1 ? AppConstants.defaultPlayer1Name : AppConstants.defaultPlayer2Name;
    }
    return player == 1 ? AppConstants.defaultHeName : AppConstants.defaultSheName;
  }

  void _assignDefaultColors() {
    _player1Color = _defaultColorForPlayer(1, _player1Gender, _player2Gender);
    _player2Color = _defaultColorForPlayer(2, _player1Gender, _player2Gender);
  }

  Future<void> setPlayer1Name(String name) async {
    _player1Name = name.trim().isEmpty ? _defaultName(1) : name.trim();
    _namesCustomized = true;
    await LocalStorage.savePlayer1Name(_player1Name);
    notifyListeners();
  }

  Future<void> setPlayer2Name(String name) async {
    _player2Name = name.trim().isEmpty ? _defaultName(2) : name.trim();
    await LocalStorage.savePlayer2Name(_player2Name);
    notifyListeners();
  }

  Future<void> setPlayer1Gender(PlayerGender gender) async {
    _player1Gender = gender;
    await LocalStorage.savePlayer1Gender(gender == PlayerGender.male ? 'male' : 'female');
    _assignDefaultColors();
    await LocalStorage.savePlayer1Color(_player1Color.toARGB32());
    await LocalStorage.savePlayer2Color(_player2Color.toARGB32());
    notifyListeners();
  }

  Future<void> setPlayer2Gender(PlayerGender gender) async {
    _player2Gender = gender;
    await LocalStorage.savePlayer2Gender(gender == PlayerGender.male ? 'male' : 'female');
    _assignDefaultColors();
    await LocalStorage.savePlayer1Color(_player1Color.toARGB32());
    await LocalStorage.savePlayer2Color(_player2Color.toARGB32());
    notifyListeners();
  }

  Future<void> setPlayer1Color(Color color) async {
    _player1Color = color;
    await LocalStorage.savePlayer1Color(color.toARGB32());
    notifyListeners();
  }

  Future<void> setPlayer2Color(Color color) async {
    _player2Color = color;
    await LocalStorage.savePlayer2Color(color.toARGB32());
    notifyListeners();
  }

  Future<void> setFriendsMode(bool enabled) async {
    _friendsMode = enabled;
    await LocalStorage.setFriendsMode(enabled);
    if (!_namesCustomized) {
      _player1Name = _defaultName(1);
      _player2Name = _defaultName(2);
      await LocalStorage.savePlayer1Name(_player1Name);
      await LocalStorage.savePlayer2Name(_player2Name);
    }
    notifyListeners();
  }

  Future<void> toggleSound() async {
    _soundEnabled = !_soundEnabled;
    await LocalStorage.setSoundEnabled(_soundEnabled);
    notifyListeners();
  }

  Future<void> toggleVibration() async {
    _vibrationEnabled = !_vibrationEnabled;
    await LocalStorage.setVibrationEnabled(_vibrationEnabled);
    notifyListeners();
  }

  Future<void> incrementRouletteSpin() async {
    _rouletteSpinCount++;
    await LocalStorage.saveRouletteSpinCount(_rouletteSpinCount);
    notifyListeners();
  }

  Future<void> resetRouletteProgress() async {
    _rouletteSpinCount = 0;
    await LocalStorage.resetRouletteProgress();
    notifyListeners();
  }

  Future<Set<String>> getUsedDrinkTasks() async {
    return (await LocalStorage.getUsedDrinkTasks()).toSet();
  }

  Future<void> addUsedDrinkTask(String id) async {
    await LocalStorage.addUsedDrinkTask(id);
    notifyListeners();
  }

  Future<void> clearUsedDrinkTasks() async {
    await LocalStorage.clearUsedDrinkTasks();
    notifyListeners();
  }
}
