import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
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

  late String _heName;
  late String _sheName;
  int _heScore = 0;
  int _sheScore = 0;

  String? _lastWinner;

  List<String> get allTasks => _allTasks;
  String? get currentTask => _currentTask;
  bool get isLoading => _isLoading;
  int get currentRound => _currentRound;
  int get maxRoundsValue => maxRounds;
  String get heName => _heName;
  String get sheName => _sheName;
  int get heScore => _heScore;
  int get sheScore => _sheScore;
  String? get lastWinner => _lastWinner;
  bool get isGameOver => _currentRound >= maxRounds || _availableTasks.isEmpty;

  void Function({required String winnerName, required String loserName})? onGameFinished;

  Future<void> initGame() async {
    _heName = settingsProvider.heName;
    _sheName = settingsProvider.sheName;

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
    _heScore++;
    _lastWinner = _heName;
    _nextTurn();
  }

  void claimShe() {
    if (_currentTask == null) return;
    audioService.playClick();
    _sheScore++;
    _lastWinner = _sheName;
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
    if (_heScore > _sheScore) {
      winnerName = _heName;
    } else if (_sheScore > _heScore) {
      winnerName = _sheName;
    } else {
      winnerName = 'EMPATE';
    }
    onGameFinished?.call(
      winnerName: winnerName,
      loserName: winnerName == _heName ? _sheName : _heName,
    );
  }
}
