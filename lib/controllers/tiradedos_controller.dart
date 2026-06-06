import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../providers/settings_provider.dart';

class TiradedosController extends ChangeNotifier {
  final AudioService audioService;
  final SettingsProvider settingsProvider;

  TiradedosController({
    required this.audioService,
    required this.settingsProvider,
  });

  String _player1Name = '';
  String _player2Name = '';
  Color _player1Color = Colors.blueAccent;
  Color _player2Color = Colors.pinkAccent;
  IconData _player1Icon = Icons.male;
  IconData _player2Icon = Icons.female;

  String get player1Name => _player1Name;
  String get player2Name => _player2Name;
  Color get player1Color => _player1Color;
  Color get player2Color => _player2Color;
  IconData get player1Icon => _player1Icon;
  IconData get player2Icon => _player2Icon;

  void initGame() {
    _player1Name = settingsProvider.player1Name;
    _player2Name = settingsProvider.player2Name;
    _player1Color = settingsProvider.player1Color;
    _player2Color = settingsProvider.player2Color;
    _player1Icon = settingsProvider.player1Icon;
    _player2Icon = settingsProvider.player2Icon;
    notifyListeners();
  }
}
