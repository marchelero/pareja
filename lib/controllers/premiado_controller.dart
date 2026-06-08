import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../providers/settings_provider.dart';

class PremiadoController extends ChangeNotifier {
  final AudioService audioService;
  final SettingsProvider settingsProvider;
  final int pointsToWin;

  PremiadoController({
    required this.audioService,
    required this.settingsProvider,
    this.pointsToWin = 2,
  });

  String _player1Name = '';
  String _player2Name = '';
  Color _player1Color = Colors.blueAccent;
  Color _player2Color = Colors.pinkAccent;
  IconData _player1Icon = Icons.male;
  IconData _player2Icon = Icons.female;
  int _scoreP1 = 0;
  int _scoreP2 = 0;

  String get player1Name => _player1Name;
  String get player2Name => _player2Name;
  Color get player1Color => _player1Color;
  Color get player2Color => _player2Color;
  IconData get player1Icon => _player1Icon;
  IconData get player2Icon => _player2Icon;
  int get scoreP1 => _scoreP1;
  int get scoreP2 => _scoreP2;

  void incrementP1() {
    _scoreP1++;
    notifyListeners();
  }

  void incrementP2() {
    _scoreP2++;
    notifyListeners();
  }

  void resetScores() {
    _scoreP1 = 0;
    _scoreP2 = 0;
    notifyListeners();
  }

  bool get hasWinner => _scoreP1 >= pointsToWin || _scoreP2 >= pointsToWin;
  int get winnerIndex => _scoreP1 >= pointsToWin ? 0 : (_scoreP2 >= pointsToWin ? 1 : -1);

  Future<void> initGame() async {
    _player1Name = settingsProvider.player1Name;
    _player2Name = settingsProvider.player2Name;
    _player1Color = settingsProvider.player1Color;
    _player2Color = settingsProvider.player2Color;
    _player1Icon = settingsProvider.player1Icon;
    _player2Icon = settingsProvider.player2Icon;
    notifyListeners();
  }
}
