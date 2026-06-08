import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/models/drink_task.dart';
import '../services/audio_service.dart';
import '../providers/settings_provider.dart';

class DrinksController extends ChangeNotifier {
  final AudioService audioService;
  final SettingsProvider settingsProvider;
  final int sipsPerGlass;
  final int initialLevel;
  final int levelingSpeed;
  final bool isHotMode;
  final bool freeMode;
  final int totalGlasses;

  DrinksController({
    required this.audioService,
    required this.settingsProvider,
    required this.sipsPerGlass,
    required this.initialLevel,
    required this.levelingSpeed,
    required this.isHotMode,
    this.freeMode = false,
    this.totalGlasses = 5,
  });

  List<DrinkTask> _allTasks = [];
  List<DrinkTask> _availableTasks = [];
  Set<String> _usedTaskIds = {};
  DrinkTask? _currentTask;
  String? _activePlayerName;
  bool _isLoading = true;

  late String _player1Name;
  late String _player2Name;
  Color _player1Color = Colors.blueAccent;
  Color _player2Color = Colors.pinkAccent;
  int _heSipsLeft = 0;
  int _sheSipsLeft = 0;
  int _currentLevel = 1;
  int _turnCount = 0;
  int _heGlassesDrunk = 0;
  int _sheGlassesDrunk = 0;

  DrinkTask? get currentTask => _currentTask;
  String? get activePlayerName => _activePlayerName;
  bool get isLoading => _isLoading;
  String get player1Name => _player1Name;
  String get player2Name => _player2Name;
  Color get player1Color => _player1Color;
  Color get player2Color => _player2Color;
  int get heSipsLeft => _heSipsLeft;
  int get sheSipsLeft => _sheSipsLeft;
  int get currentLevel => _currentLevel;
  int get turnCount => _turnCount;
  int get sipsPerGlassParam => sipsPerGlass;
  int get heGlassesDrunk => _heGlassesDrunk;
  int get sheGlassesDrunk => _sheGlassesDrunk;

  void Function(int level)? onLevelUp;
  void Function(String playerName)? onGameOver;
  void Function(String winnerName)? onGameFinished;

  Future<void> initGame() async {
    _player1Name = settingsProvider.player1Name;
    _player2Name = settingsProvider.player2Name;
    _player1Color = settingsProvider.player1Color;
    _player2Color = settingsProvider.player2Color;
    _heSipsLeft = sipsPerGlass;
    _sheSipsLeft = sipsPerGlass;
    _currentLevel = initialLevel;

    _usedTaskIds = await settingsProvider.getUsedDrinkTasks();

    try {
      final String response = await rootBundle.loadString('assets/data/drinks_tasks.json');
      final List<dynamic> data = json.decode(response);
      _allTasks = data.map((json) => DrinkTask.fromJson(json)).toList();
    } catch (e) {
      _allTasks = [];
    }

    _filterTasks();
    _nextTurn();

    _isLoading = false;
    notifyListeners();
  }

  void _filterTasks() {
    _availableTasks = _allTasks.where((task) {
      if (_usedTaskIds.contains(task.id)) return false;
      if (!isHotMode && task.isHot) return false;

      bool levelMatch = task.intensity <= _currentLevel;
      if (_currentLevel > 3 && task.intensity < _currentLevel - 2) levelMatch = false;

      return levelMatch;
    }).toList();
  }

  void _nextTurn() {
    _turnCount++;
    int turnsToLevelUp = levelingSpeed;

    if (_turnCount % turnsToLevelUp == 0 && _currentLevel < 8) {
      _currentLevel++;
      _filterTasks();
      audioService.playLevelUp();

      if (isHotMode && _currentLevel >= 5) {
        _currentTask = DrinkTask(
          id: 'levelup_clothing_$_currentLevel',
          text: '¡NIVEL $_currentLevel! 🔥\nLa temperatura sube... AMBOS SE QUITAN UNA PRENDA O TOMAN TODO EL VASO.',
          target: DrinkTarget.both,
          type: DrinkType.challenge,
          category: DrinkCategory.challenge,
          intensity: 8,
          isHot: true,
          sips: 99,
          gender: DrinkGender.any,
        );
      } else {
        _currentTask = DrinkTask(
          id: 'levelup_info_$_currentLevel',
          text: '¡NIVEL $_currentLevel ALCANZADO! 🚀\nSubimos la intensidad. Celebren con un trago.',
          target: DrinkTarget.both,
          type: DrinkType.game,
          category: DrinkCategory.decision,
          intensity: 0,
          isHot: false,
          sips: 1,
          gender: DrinkGender.any,
        );
      }
      _activePlayerName = null;
      onLevelUp?.call(_currentLevel);
      notifyListeners();
      return;
    }

    _currentTask = _getNextTask();
    notifyListeners();
  }

  DrinkTask? _getNextTask() {
    if (_availableTasks.isNotEmpty) {
      final task = _availableTasks[Random().nextInt(_availableTasks.length)];
      _usedTaskIds.add(task.id);
      settingsProvider.addUsedDrinkTask(task.id);
      _availableTasks.remove(task);

      _assignActivePlayer(task);
      return task;
    }

    _usedTaskIds.clear();
    settingsProvider.clearUsedDrinkTasks();
    _filterTasks();

    if (_availableTasks.isNotEmpty) {
      final task = _availableTasks[Random().nextInt(_availableTasks.length)];
      _usedTaskIds.add(task.id);
      settingsProvider.addUsedDrinkTask(task.id);
      _availableTasks.remove(task);

      _assignActivePlayer(task);
      return task;
    }

    return null;
  }

  void _assignActivePlayer(DrinkTask task) {
    if (task.target == DrinkTarget.he) {
      _activePlayerName = _player1Name;
    } else if (task.target == DrinkTarget.she) {
      _activePlayerName = _player2Name;
    } else if (task.target == DrinkTarget.both) {
      _activePlayerName = null;
    }
    else {
      if (task.gender == DrinkGender.male) {
        _activePlayerName = _player1Name;
      } else if (task.gender == DrinkGender.female) {
        _activePlayerName = _player2Name;
      } else {
        _activePlayerName = Random().nextBool() ? _player1Name : _player2Name;
      }
    }
  }

  void applySips(DrinkTarget target, int sips) {
    int sipsToApply = sips;

    if (target == DrinkTarget.he || target == DrinkTarget.both) {
      if (sips == 99) {
        _heSipsLeft = 0;
      } else {
        _heSipsLeft = max(0, _heSipsLeft - sipsToApply);
      }
    }
    if (target == DrinkTarget.she || target == DrinkTarget.both) {
      if (sips == 99) {
        _sheSipsLeft = 0;
      } else {
        _sheSipsLeft = max(0, _sheSipsLeft - sipsToApply);
      }
    }
    if (target == DrinkTarget.random) {
      bool targetHe = Random().nextBool();
      if (targetHe) {
        _heSipsLeft = max(0, _heSipsLeft - sipsToApply);
      } else {
        _sheSipsLeft = max(0, _sheSipsLeft - sipsToApply);
      }
    }

    notifyListeners();

    // Reproducir sonido cuando un vaso se vacía
    if (_heSipsLeft <= 0 || _sheSipsLeft <= 0) {
      audioService.playDrink();
      _checkGameOver();
    }
  }

  void _checkGameOver() {
    String? emptyPlayer;
    bool heFinished = false;
    bool sheFinished = false;

    if (_heSipsLeft <= 0) {
      emptyPlayer = _player1Name;
      heFinished = true;
      _heGlassesDrunk++;
    }
    if (_sheSipsLeft <= 0) {
      emptyPlayer ??= _player2Name;
      sheFinished = true;
      _sheGlassesDrunk++;
    }

    if (emptyPlayer == null) return;

    if (!freeMode && ((heFinished && _heGlassesDrunk >= totalGlasses) || (sheFinished && _sheGlassesDrunk >= totalGlasses))) {
      final String winner = heFinished && _heGlassesDrunk >= totalGlasses ? _player2Name : _player1Name;
      onGameFinished?.call(winner);
    } else {
      onGameOver?.call(emptyPlayer);
    }
  }

  void resetPlayerGlasses(String playerName) {
    bool isHe = playerName == _player1Name;
    if (isHe) {
      _heSipsLeft = sipsPerGlass;
    } else {
      _sheSipsLeft = sipsPerGlass;
    }
    notifyListeners();
  }

  void advanceAfterGameOver() {
    _nextTurn();
  }

  void nextTurnFromUI() {
    _nextTurn();
  }

}
