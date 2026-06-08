import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import '../core/models/player.dart';
import '../core/models/question.dart';
import '../data/questions_repository.dart';
import '../services/audio_service.dart';
import '../providers/settings_provider.dart';

class QuestionsController extends ChangeNotifier {
  final AudioService audioService;
  final SettingsProvider settingsProvider;
  final int maxRounds;
  final List<String> categories;
  final bool startingPlayerIsP1;

  QuestionsController({
    required this.repository,
    required this.audioService,
    required this.settingsProvider,
    required this.maxRounds,
    required this.categories,
    required this.startingPlayerIsP1,
  });

  final QuestionsRepository repository;
  List<Question> _allQuestions = [];
  List<Question> _availableQuestions = [];
  late Player _player1;
  late Player _player2;
  Player? _currentPlayer;
  Question? _currentQuestion;
  Color _backgroundColor = const Color(0xFF2196F3);
  bool _isLoading = true;
  int _currentRound = 0;
  bool _isSuddenDeath = false;
  int _suddenDeathRound = 0;

  Player get player1 => _player1;
  Player get player2 => _player2;
  Player? get currentPlayer => _currentPlayer;
  Question? get currentQuestion => _currentQuestion;
  Color get backgroundColor => _backgroundColor;
  bool get isLoading => _isLoading;
  int get currentRound => _currentRound;
  bool get isSuddenDeath => _isSuddenDeath;
  List<Question> get allQuestions => _allQuestions;

  static const Map<String, Color> categoryColors = {
    'General': Color(0xFF1E88E5),
    'Romántico': Color(0xFFE91E63),
    'Picante': Color(0xFFE64A19),
    'Convivencia': Color(0xFF43A047),
    'Futuro': Color(0xFF3949AB),
    'Viajes': Color(0xFF00897B),
    'Pasatiempos': Color(0xFFE65100),
    'Valores': Color(0xFF6D4C41),
    'Humor': Color(0xFFFF8F00),
    'Profundo': Color(0xFF546E7A),
    'Trivia': Color(0xFF8E24AA),
    'Flirteo': Color(0xFFD50000),
  };

  void Function(Player player1, Player player2)? onGameFinished;

  Future<void> initGame() async {
    _player1 = Player(name: settingsProvider.player1Name);
    _player2 = Player(name: settingsProvider.player2Name);

    _allQuestions = await repository.loadQuestions();

    _availableQuestions = _allQuestions.where((q) {
      return categories.contains(q.category);
    }).toList();

    if (_availableQuestions.isEmpty) {
      _availableQuestions = List.from(_allQuestions);
    }

    _currentPlayer = startingPlayerIsP1 ? _player1 : _player2;

    _nextTurn();

    _isLoading = false;
    notifyListeners();
  }

  void _nextTurn() {
    if (_isSuddenDeath) {
      if (_suddenDeathRound >= 2) {
        _finishGame();
        return;
      }
      _suddenDeathRound++;

      _currentPlayer = (_suddenDeathRound == 1)
          ? (startingPlayerIsP1 ? _player1 : _player2)
          : (startingPlayerIsP1 ? _player2 : _player1);

      List<Question> validQuestions = _allQuestions.where((q) {
        bool matchesPlayer = (_currentPlayer == _player1)
            ? (q.target == Target.male || q.target == Target.any)
            : (q.target == Target.female || q.target == Target.any);
        return matchesPlayer && q.isSuddenDeath;
      }).toList();

      if (validQuestions.isEmpty) {
        validQuestions = _allQuestions.where((q) {
          if (_currentPlayer == _player1) {
            return q.target == Target.male || q.target == Target.any;
          } else {
            return q.target == Target.female || q.target == Target.any;
          }
        }).toList();
      }

      _currentQuestion = validQuestions[Random().nextInt(validQuestions.length)];
      _backgroundColor = _currentPlayer == _player1 ? settingsProvider.player1Color : settingsProvider.player2Color;
      notifyListeners();
      return;
    }

    if (_currentRound >= maxRounds || _availableQuestions.isEmpty) {
      _finishGame();
      return;
    }

    _currentRound++;

    if (_currentRound > 1) {
      _currentPlayer = (_currentPlayer == _player1) ? _player2 : _player1;
    }

    List<Question> validQuestions = _availableQuestions.where((q) {
      if (_currentPlayer == _player1) {
        return q.target == Target.male || q.target == Target.any;
      } else {
        return q.target == Target.female || q.target == Target.any;
      }
    }).toList();

    if (validQuestions.isEmpty) {
      _finishGame();
      return;
    }

    _currentQuestion = validQuestions[Random().nextInt(validQuestions.length)];
    _availableQuestions.remove(_currentQuestion);
    _backgroundColor = _currentPlayer == _player1 ? settingsProvider.player1Color : settingsProvider.player2Color;
    notifyListeners();
  }

  String formatQuestionText(String text) {
    return text
        .replaceAll('ELLA', _player2.name)
        .replaceAll('ÉL', _player1.name);
  }

  void addPoints(int points) {
    audioService.playClick();
    if (_isSuddenDeath) {
      if (points == 7) {
        _currentPlayer!.score += 7;
        _currentPlayer!.suddenDeathPoints += 7;
        _currentPlayer!.suddenDeathCorrect = true;
      } else {
        _currentPlayer!.suddenDeathPoints = 0;
        _currentPlayer!.suddenDeathCorrect = false;
      }
    } else {
      if (points == 2) {
        _currentPlayer!.score += 2;
        _currentPlayer!.perfectAnswers++;
      } else if (points == 1) {
        _currentPlayer!.score += 1;
        _currentPlayer!.partialAnswers++;
      } else {
        _currentPlayer!.failedAnswers++;
      }
    }
    _nextTurn();
  }

  void activateSuddenDeath() {
    _isSuddenDeath = true;
    _suddenDeathRound = 0;
    _nextTurn();
  }

  void _finishGame() {
    final callback = onGameFinished;
    if (callback == null) return;
    onGameFinished = null;
    notifyListeners();
    callback(_player1, _player2);
  }

}
