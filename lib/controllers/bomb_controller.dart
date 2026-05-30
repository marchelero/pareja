import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../core/models/bomb_category.dart';
import '../services/audio_service.dart';
import '../providers/settings_provider.dart';

class BombController extends ChangeNotifier {
  final AudioService audioService;
  final SettingsProvider settingsProvider;
  final bool isHotMode;
  final int bestOf;
  final int timerSeconds;
  final bool optPanic;
  final bool optGold;
  final bool optWild;
  final bool optAccel;

  BombController({
    required this.audioService,
    required this.settingsProvider,
    required this.isHotMode,
    required this.bestOf,
    required this.timerSeconds,
    required this.optPanic,
    required this.optGold,
    required this.optWild,
    required this.optAccel,
  });

  List<BombCategory> _allCategories = [];
  List<BombCategory> _availableCategories = [];
  BombCategory? _currentCategory;

  bool _isLoading = true;
  bool _isPlaying = false;

  late double _currentLimit;
  late int _timeLeft;
  Timer? _timer;

  late String _heName;
  late String _sheName;
  int _scoreHe = 0;
  int _scoreShe = 0;
  late int _pointsToWin;
  bool _isHeTurn = true;

  bool _isGoldenRound = false;
  bool _heHasWildcard = false;
  bool _sheHasWildcard = false;

  bool get isLoading => _isLoading;
  bool get isPlaying => _isPlaying;
  int get timeLeft => _timeLeft;
  BombCategory? get currentCategory => _currentCategory;
  int get scoreHe => _scoreHe;
  int get scoreShe => _scoreShe;
  bool get isHeTurn => _isHeTurn;
  bool get isGoldenRound => _isGoldenRound;
  bool get activeHasWildcard => _isHeTurn ? _heHasWildcard : _sheHasWildcard;
  String get activeName => _isHeTurn ? _heName : _sheName;
  int get pointsToWin => _pointsToWin;

  void Function({required String loserName, required int pointsEarned})? onRoundResult;
  void Function({required String winnerName, required Color winnerColor})? onWinner;

  Future<void> initGame() async {
    _heName = settingsProvider.heName;
    _sheName = settingsProvider.sheName;
    _currentLimit = timerSeconds.toDouble();
    _timeLeft = _currentLimit.ceil();
    _pointsToWin = (bestOf / 2).floor() + 1;

    if (optWild) {
      _heHasWildcard = true;
      _sheHasWildcard = true;
    }

    try {
      final String categoriesStr = await rootBundle.loadString('assets/data/bomb_categories.json');
      final List<dynamic> catData = json.decode(categoriesStr);
      _allCategories = catData.map((json) => BombCategory.fromJson(json)).toList();
    } catch (e) {
      _allCategories = [];
    }

    _availableCategories = _allCategories.where((c) => c.isHot == isHotMode).toList();

    _nextRound();

    _isLoading = false;
    notifyListeners();
  }

  void _nextCategory({bool isWildcard = false}) {
    if (_availableCategories.isEmpty) {
      _availableCategories = _allCategories.where((c) => c.isHot == isHotMode).toList();
    }

    final randomIndex = Random().nextInt(_availableCategories.length);
    _currentCategory = _availableCategories[randomIndex];
    _availableCategories.removeAt(randomIndex);

    if (!isWildcard) {
      _currentLimit = timerSeconds.toDouble();
      _timeLeft = _currentLimit.ceil();
    }
  }

  void _nextRound() {
    _nextCategory();
    _isPlaying = false;
    _isHeTurn = Random().nextBool();

    if (optGold) {
      _isGoldenRound = Random().nextDouble() < 0.35;
    } else {
      _isGoldenRound = false;
    }
    notifyListeners();
  }

  void startGame() {
    _isPlaying = true;
    audioService.playClick();
    _startTimer();
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        _timeLeft--;
        audioService.playClick();
        notifyListeners();
      } else {
        _explode();
      }
    });
  }

  void passTurn() {
    if (!_isPlaying) return;
    audioService.playClick();
    if (optAccel) {
      _currentLimit = max(1.5, _currentLimit - 0.5);
    }
    _timeLeft = _currentLimit.ceil();
    _isHeTurn = !_isHeTurn;
    notifyListeners();
  }

  void useWildcard() {
    if (!_isPlaying) return;

    if (_isHeTurn && _heHasWildcard) {
      _heHasWildcard = false;
    } else if (!_isHeTurn && _sheHasWildcard) {
      _sheHasWildcard = false;
    } else {
      return;
    }

    audioService.playClick();
    _nextCategory(isWildcard: true);
    notifyListeners();
  }

  void _explode() {
    _timer?.cancel();
    audioService.playGameOver();

    bool heLost = _isHeTurn;
    int pointsEarned = _isGoldenRound ? 2 : 1;

    if (heLost) {
      _scoreShe += pointsEarned;
    } else {
      _scoreHe += pointsEarned;
    }

    notifyListeners();

    bool isGameOver = _scoreHe >= _pointsToWin || _scoreShe >= _pointsToWin;

    if (isGameOver) {
      final winnerName = _scoreHe >= _pointsToWin ? _heName : _sheName;
      final winnerColor = _scoreHe >= _pointsToWin ? const Color(0xFF448AFF) : const Color(0xFFFF4081);
      onWinner?.call(winnerName: winnerName, winnerColor: winnerColor);
    } else {
      final loserName = heLost ? _heName : _sheName;
      onRoundResult?.call(loserName: loserName, pointsEarned: pointsEarned);
    }
  }

  void nextRoundAfterDialog() {
    _nextRound();
  }

  void cancelTimer() {
    _timer?.cancel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
