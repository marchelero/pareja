import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';
import '../core/storage/local_storage.dart';

class AudioService extends ChangeNotifier {
  /// Player creado perezosamente: solo existe si hay sonido habilitado y se
  /// reproduce algo. Evita tocar el canal del plugin (inexistente en tests)
  /// cuando el sonido está apagado.
  AudioPlayer? _player;
  bool _enabled = true;

  AudioService() {
    _initFromStorage();
  }

  Future<void> _initFromStorage() async {
    _enabled = await LocalStorage.isSoundEnabled();
  }

  bool get enabled => _enabled;

  void setEnabled(bool value) {
    _enabled = value;
    notifyListeners();
  }

  Future<void> stop() async {
    await _player?.stop();
  }

  Future<void> playClick() async => _play(AppConstants.soundClick);
  Future<void> playLevelUp() async => _play(AppConstants.soundLevelUp);
  Future<void> playGameOver() async => _play(AppConstants.soundGameOver);
  Future<void> playDrink() async => _play(AppConstants.soundDrink);
  Future<void> playDice() async => _play(AppConstants.soundDice);

  Future<void> play(String fileName) async => _play(fileName);

  Future<void> _play(String fileName) async {
    if (!_enabled) return;
    final player = _player ??= AudioPlayer();
    try {
      await player.stop();
      await player.play(AssetSource('sounds/$fileName'));
    } catch (e) {
      debugPrint('AudioService error: $e');
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }
}
