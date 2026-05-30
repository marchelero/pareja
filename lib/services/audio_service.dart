import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';

class AudioService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  bool _enabled = true;

  bool get enabled => _enabled;

  void setEnabled(bool value) {
    _enabled = value;
    notifyListeners();
  }

  Future<void> playClick() async => _play(AppConstants.soundClick);
  Future<void> playLevelUp() async => _play(AppConstants.soundLevelUp);
  Future<void> playGameOver() async => _play(AppConstants.soundGameOver);
  Future<void> playDrink() async => _play(AppConstants.soundDrink);

  Future<void> play(String fileName) async => _play(fileName);

  Future<void> _play(String fileName) async {
    if (!_enabled) return;
    try {
      await _player.play(AssetSource('sounds/$fileName'));
    } catch (e) {
      debugPrint('AudioService error: $e');
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
