import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/audio_service.dart';
import '../services/haptics_service.dart';
import '../providers/settings_provider.dart';
import '../core/constants/app_constants.dart';

class RouletteController extends ChangeNotifier {
  final AudioService audioService;
  final SettingsProvider settingsProvider;
  final bool isDareMode;
  final bool startingPlayerIsP1;

  RouletteController({
    required this.audioService,
    required this.settingsProvider,
    required this.isDareMode,
    required this.startingPlayerIsP1,
  });

  List<String> _options = [];
  bool _isLoading = true;
  late String _player1Name;
  late String _player2Name;
  Color _player1Color = Colors.blueAccent;
  Color _player2Color = Colors.pinkAccent;
  late String _currentPlayerName;
  late bool _isPlayer1Turn;
  int _spinCount = 0;

  double _currentRotation = 0;
  String? _result;
  int _selectedIndex = -1;

  bool _isSpinning = false;
  int _lastHapticSection = -1;

  List<String> get options => _options;
  bool get isLoading => _isLoading;
  String get currentPlayerName => _currentPlayerName;
  bool get isHeTurn => _isPlayer1Turn;
  int get spinCount => _spinCount;
  String? get result => _result;
  int get selectedIndex => _selectedIndex;
  bool get isSpinning => _isSpinning;
  double get currentRotation => _currentRotation;
  int get maxSpinsForHot => AppConstants.rouletteMaxSpinsForHot;
  Color get player1Color => _player1Color;
  Color get player2Color => _player2Color;

  void Function()? onSpinComplete;

  Future<void> initGame() async {
    _player1Name = settingsProvider.player1Name;
    _player2Name = settingsProvider.player2Name;
    _player1Color = settingsProvider.player1Color;
    _player2Color = settingsProvider.player2Color;
    _isPlayer1Turn = startingPlayerIsP1;
    _currentPlayerName = _isPlayer1Turn ? _player1Name : _player2Name;
    _spinCount = settingsProvider.rouletteSpinCount;

    final String fileName = isDareMode ? 'roulette_dare.json' : 'roulette_normal.json';
    try {
      final String response = await rootBundle.loadString('assets/data/$fileName');
      final List<dynamic> data = json.decode(response);
      _options = data.cast<String>().take(10).toList();
    } catch (e) {
      _options = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  void toggleMode(bool value) {
    _isLoading = true;
    _result = null;
    _selectedIndex = -1;
    notifyListeners();
    initGame();
  }

  void spin() {
    if (_isSpinning) return;
    audioService.playClick();

    if (_result != null) {
      _nextTurn();
    }

    _isSpinning = true;
    _result = null;
    _selectedIndex = -1;

    notifyListeners();
  }

  void onSpinFinished(double finalRotation) {
    final double sectionAngle = 2 * pi / _options.length;

    int foundIndex = 0;
    double minDiff = double.infinity;

    for (int i = 0; i < _options.length; i++) {
      double currentCenter = i * sectionAngle - pi / 2 + finalRotation;
      double diff = (currentCenter - (-pi / 2));
      double normalizedDiff = (diff + pi) % (2 * pi) - pi;

      if (normalizedDiff.abs() < minDiff) {
        minDiff = normalizedDiff.abs();
        foundIndex = i;
      }
    }

    _isSpinning = false;
    _currentRotation = finalRotation % (2 * pi);
    _selectedIndex = foundIndex;
    _result = _options[foundIndex];
    _spinCount++;
    settingsProvider.incrementRouletteSpin();

    HapticsService.vibrate();
    notifyListeners();
    onSpinComplete?.call();
  }

  void handleHaptics(double animationValue) {
    if (!_isSpinning) return;
    final double sectionAngle = 2 * pi / _options.length;
    final int currentSection = (animationValue / sectionAngle).floor();
    if (currentSection != _lastHapticSection) {
      HapticsService.light();
      _lastHapticSection = currentSection;
    }
  }

  String formatResultText(String text) {
    final String targetName = _isPlayer1Turn ? _player2Name : _player1Name;
    return text.replaceAll('{PAREJA}', targetName);
  }

  void _nextTurn() {
    _isPlayer1Turn = !_isPlayer1Turn;
    _currentPlayerName = _isPlayer1Turn ? _player1Name : _player2Name;
    _result = null;
    _selectedIndex = -1;
    notifyListeners();
  }

  void nextTurnFromUI() {
    _nextTurn();
  }

}
