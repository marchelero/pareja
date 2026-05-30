import 'package:flutter/foundation.dart';
import '../core/storage/local_storage.dart';
import '../core/constants/app_constants.dart';

class SettingsProvider extends ChangeNotifier {
  String _heName = AppConstants.defaultHeName;
  String _sheName = AppConstants.defaultSheName;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  int _rouletteSpinCount = 0;
  bool _isLoaded = false;

  String get heName => _heName;
  String get sheName => _sheName;
  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  int get rouletteSpinCount => _rouletteSpinCount;
  bool get isLoaded => _isLoaded;

  Future<void> load() async {
    _heName = await LocalStorage.getHeName();
    _sheName = await LocalStorage.getSheName();
    if (_heName.isEmpty) _heName = AppConstants.defaultHeName;
    if (_sheName.isEmpty) _sheName = AppConstants.defaultSheName;
    _soundEnabled = await LocalStorage.isSoundEnabled();
    _vibrationEnabled = await LocalStorage.isVibrationEnabled();
    _rouletteSpinCount = await LocalStorage.getRouletteSpinCount();
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> saveNames(String he, String she) async {
    _heName = he.trim().isEmpty ? AppConstants.defaultHeName : he.trim();
    _sheName = she.trim().isEmpty ? AppConstants.defaultSheName : she.trim();
    await LocalStorage.saveNames(_heName, _sheName);
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
