import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/audio_service.dart';
import '../providers/settings_provider.dart';

enum RapidFireState { idle, buzzed, showingResult, finished }

class RapidFireController extends ChangeNotifier {
  final AudioService audioService;
  final SettingsProvider settingsProvider;
  final int targetScore;

  RapidFireController({
    required this.audioService,
    required this.settingsProvider,
    this.targetScore = 10,
  });

  List<Map<String, dynamic>> _allQuestions = [];
  Set<String> _allCategories = {};
  Set<String> _selectedCategories = {};
  final List<Map<String, dynamic>> _availableQuestions = [];
  Map<String, dynamic>? _currentQuestion;
  RapidFireState _state = RapidFireState.idle;

  String _player1Name = '';
  String _player2Name = '';
  int _player1Score = 0;
  int _player2Score = 0;
  Color _player1Color = Colors.blueAccent;
  Color _player2Color = Colors.pinkAccent;
  int _questionIndex = 0;

  String? _buzzerPlayer;
  int? _selectedAnswer;
  double _timeLeft = 5.0;
  double _buzzTimeLeft = 10.0;
  Timer? _inputTimer;
  Timer? _buzzTimer;
  String? _lastCorrectAnswer;

  bool get isHeTurn => _buzzerPlayer == 'he';
  String get player1Name => _player1Name;
  String get player2Name => _player2Name;
  int get player1Score => _player1Score;
  int get player2Score => _player2Score;
  Color get player1Color => _player1Color;
  Color get player2Color => _player2Color;
  int get targetScoreValue => targetScore;
  int get questionIndex => _questionIndex;
  RapidFireState get state => _state;
  Map<String, dynamic>? get currentQuestion => _currentQuestion;
  String? get buzzerPlayer => _buzzerPlayer;
  int? get selectedAnswer => _selectedAnswer;
  double get timeLeft => _timeLeft;
  double get buzzTimeLeft => _buzzTimeLeft;
  int get correctAnswerIndex => (_currentQuestion?['a'] as int?) ?? 0;
  String? get lastCorrectAnswer => _lastCorrectAnswer;
  bool get isGameOver => _state == RapidFireState.finished;
  Set<String> get allCategories => _allCategories;
  Set<String> get selectedCategories => _selectedCategories;
  String get currentCategory => _currentQuestion?['c'] as String? ?? '';
  int get totalQuestions => _availableQuestions.length;

  void Function({required String winnerName, required String loserName})? onGameFinished;

  void setSelectedCategories(Set<String> categories) {
    _selectedCategories = categories;
    _rebuildAvailable();
  }

  void _rebuildAvailable() {
    _availableQuestions.clear();
    for (final q in _allQuestions) {
      final cat = q['c'] as String? ?? '';
      if (_selectedCategories.isEmpty || _selectedCategories.contains(cat)) {
        _availableQuestions.add(q);
      }
    }
  }

  Future<void> initGame() async {
    _player1Name = settingsProvider.player1Name;
    _player2Name = settingsProvider.player2Name;
    _player1Color = settingsProvider.player1Color;
    _player2Color = settingsProvider.player2Color;
    _player1Score = 0;
    _player2Score = 0;
    _questionIndex = 0;
    _state = RapidFireState.idle;
    _buzzerPlayer = null;
    _selectedAnswer = null;

    try {
      final String response = await rootBundle.loadString('assets/data/rapid_fire_questions.json');
      final List<dynamic> data = json.decode(response);
      _allQuestions = data.cast<Map<String, dynamic>>();
      final cats = <String>{};
      for (final q in _allQuestions) {
        final c = q['c'] as String?;
        if (c != null && c.isNotEmpty) cats.add(c);
      }
      _allCategories = cats;
      if (_selectedCategories.isEmpty) {
        _selectedCategories = Set.from(_allCategories);
      }
      _rebuildAvailable();
    } catch (e) {
      _allQuestions = [];
      _allCategories = {};
      _availableQuestions.clear();
    }

    _selectNextQuestion();
    _startBuzzTimer();
    notifyListeners();
  }

  void _selectNextQuestion() {
    if (_availableQuestions.isEmpty) {
      _currentQuestion = null;
      _state = RapidFireState.finished;
      return;
    }
    final idx = Random().nextInt(_availableQuestions.length);
    _currentQuestion = _availableQuestions[idx];
    _availableQuestions.removeAt(idx);
    _questionIndex++;
  }

  void buzz(String player) {
    if (_state != RapidFireState.idle) return;
    _cancelBuzzTimer();
    _state = RapidFireState.buzzed;
    _buzzerPlayer = player;
    _selectedAnswer = null;
    _timeLeft = 5.0;
    audioService.playClick();
    _startInputTimer();
    notifyListeners();
  }

  void _startBuzzTimer() {
    _cancelBuzzTimer();
    _buzzTimeLeft = 10.0;
    _buzzTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      _buzzTimeLeft -= 0.05;
      if (_buzzTimeLeft <= 0) {
        _buzzTimeLeft = 0;
        timer.cancel();
        _onBuzzTimeout();
      }
      notifyListeners();
    });
  }

  void _cancelBuzzTimer() {
    _buzzTimer?.cancel();
    _buzzTimer = null;
  }

  void _onBuzzTimeout() {
    _state = RapidFireState.buzzed;
    _buzzerPlayer = Random().nextBool() ? 'he' : 'she';
    _selectedAnswer = null;
    _timeLeft = 5.0;
    _startInputTimer();
    notifyListeners();
  }

  void _startInputTimer() {
    _inputTimer?.cancel();
    _timeLeft = 5.0;
    _inputTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      _timeLeft -= 0.05;
      if (_timeLeft <= 0) {
        _timeLeft = 0;
        timer.cancel();
        _onTimeout();
      }
      notifyListeners();
    });
  }

  void _cancelInputTimer() {
    _inputTimer?.cancel();
    _inputTimer = null;
  }

  void _onTimeout() {
    if (_buzzerPlayer == 'he') {
      _player2Score++;
    } else {
      _player1Score++;
    }
    _lastCorrectAnswer = _currentQuestion?['o'][correctAnswerIndex] as String? ?? '';
    _state = RapidFireState.showingResult;
    notifyListeners();
    _startNextTimer();
  }

  void selectAnswer(int index) {
    if (_state != RapidFireState.buzzed) return;
    _cancelInputTimer();
    _selectedAnswer = index;
    _lastCorrectAnswer = _currentQuestion?['o'][correctAnswerIndex] as String? ?? '';

    if (index == correctAnswerIndex) {
      if (_buzzerPlayer == 'he') {
        _player1Score++;
      } else {
        _player2Score++;
      }
    } else {
      if (_buzzerPlayer == 'he') {
        _player2Score++;
      } else {
        _player1Score++;
      }
    }

    _state = RapidFireState.showingResult;
    notifyListeners();
    _startNextTimer();
  }

  void _startNextTimer() {
    Future.delayed(const Duration(seconds: 2), () {
      if (_player1Score >= targetScore || _player2Score >= targetScore) {
        _cancelInputTimer();
        _cancelBuzzTimer();
        _state = RapidFireState.finished;
        notifyListeners();
        _finishGame();
      } else {
        _selectNextQuestion();
        _state = RapidFireState.idle;
        _buzzerPlayer = null;
        _startBuzzTimer();
        notifyListeners();
      }
    });
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

  @override
  void dispose() {
    _cancelInputTimer();
    _cancelBuzzTimer();
    super.dispose();
  }
}
