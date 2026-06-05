import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/audio_service.dart';
import '../providers/settings_provider.dart';

class DuelController extends ChangeNotifier {
  final AudioService audioService;
  final SettingsProvider settingsProvider;
  final int maxRounds;

  DuelController({
    required this.audioService,
    required this.settingsProvider,
    this.maxRounds = 10,
  });

  List<String> _allTasks = [];
  List<String> _availableTasks = [];
  String? _currentTask;
  bool _isLoading = true;
  int _currentRound = 0;

  late String _player1Name;
  late String _player2Name;
  int _player1Score = 0;
  int _player2Score = 0;
  Color _player1Color = Colors.blueAccent;
  Color _player2Color = Colors.pinkAccent;

  String? _lastWinner;

  List<String> get allTasks => _allTasks;
  String? get currentTask => _currentTask;
  bool get isLoading => _isLoading;
  int get currentRound => _currentRound;
  int get maxRoundsValue => maxRounds;
  String get player1Name => _player1Name;
  String get player2Name => _player2Name;
  int get player1Score => _player1Score;
  int get player2Score => _player2Score;
  Color get player1Color => _player1Color;
  Color get player2Color => _player2Color;
  String? get lastWinner => _lastWinner;
  bool get isGameOver => _currentRound >= maxRounds || _availableTasks.isEmpty;

  void Function({required String winnerName, required String loserName})? onGameFinished;

  Future<void> initGame() async {
    _player1Name = settingsProvider.player1Name;
    _player2Name = settingsProvider.player2Name;
    _player1Color = settingsProvider.player1Color;
    _player2Color = settingsProvider.player2Color;

    try {
      final String response = await rootBundle.loadString('assets/data/duel_questions.json');
      final List<dynamic> data = json.decode(response);
      _allTasks = data.cast<String>();
      _availableTasks = List.from(_allTasks);
    } catch (e) {
      _allTasks = [];
      _availableTasks = [];
    }

    _nextTurn();

    _isLoading = false;
    notifyListeners();
  }

  void _nextTurn() {
    if (isGameOver) {
      _finishGame();
      return;
    }

    _currentRound++;
    _currentTask = _getNextTask();
    notifyListeners();
  }

  String? _getNextTask() {
    if (_availableTasks.isEmpty) {
      _availableTasks = List.from(_allTasks);
    }
    if (_availableTasks.isEmpty) return null;

    final index = Random().nextInt(_availableTasks.length);
    final task = _availableTasks[index];
    _availableTasks.removeAt(index);
    return task;
  }

  void claimHe() {
    if (_currentTask == null) return;
    audioService.playClick();
    _player1Score++;
    _lastWinner = _player1Name;
    _nextTurn();
  }

  void claimShe() {
    if (_currentTask == null) return;
    audioService.playClick();
    _player2Score++;
    _lastWinner = _player2Name;
    _nextTurn();
  }

  void skipTask() {
    if (_currentTask == null) return;
    audioService.playClick();
    _lastWinner = null;
    _nextTurn();
  }

  void _finishGame() {
    final String winnerName;
    if (_player1Score > _player2Score) {
      winnerName = _player1Name;
    } else if (_player2Score > _player1Score) {
      winnerName = _player2Name;
    } else {
      winnerName = 'EMPATE';
    }
    onGameFinished?.call(
      winnerName: winnerName,
      loserName: winnerName == _player1Name ? _player2Name : _player1Name,
    );
  }
}
