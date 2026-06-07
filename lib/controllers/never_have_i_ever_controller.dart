import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/models/never_have_i_ever_question.dart';
import '../services/audio_service.dart';
import '../providers/settings_provider.dart';

class NeverHaveIEverController extends ChangeNotifier {
  final AudioService audioService;
  final SettingsProvider settingsProvider;
  final int rounds;
  final int pointsToWin;
  final int strikesForPenance;
  final bool isHotMode;

  NeverHaveIEverController({
    required this.audioService,
    required this.settingsProvider,
    required this.rounds,
    required this.pointsToWin,
    required this.strikesForPenance,
    required this.isHotMode,
  });

  List<NeverHaveIEverQuestion> _allQuestions = [];
  List<NeverHaveIEverQuestion> _availableQuestions = [];
  NeverHaveIEverQuestion? _currentQuestion;

  bool _isLoading = true;
  int _roundNumber = 1;
  int _scorePlayer1 = 0;
  int _scorePlayer2 = 0;
  int _strikesPlayer1 = 0;
  int _strikesPlayer2 = 0;

  bool _player1Answered = false;
  bool _player2Answered = false;
  bool? _player1SaidYes;
  bool? _player2SaidYes;

  bool _phaseReadyToReveal = false;
  bool _isRevealed = false;
  String? _penanceText;

  bool _disparity = false;
  String? _strikePlayerName;

  void Function(String winnerName)? onWinner;

  List<String> _penanceList = [];
  Color _player1Color = Colors.blueAccent;
  Color _player2Color = Colors.pinkAccent;

  bool get isLoading => _isLoading;
  NeverHaveIEverQuestion? get currentQuestion => _currentQuestion;
  int get scorePlayer1 => _scorePlayer1;
  int get scorePlayer2 => _scorePlayer2;
  int get strikesPlayer1 => _strikesPlayer1;
  int get strikesPlayer2 => _strikesPlayer2;
  bool get player1Answered => _player1Answered;
  bool get player2Answered => _player2Answered;
  bool? get player1SaidYes => _player1SaidYes;
  bool? get player2SaidYes => _player2SaidYes;
  bool get phaseReadyToReveal => _phaseReadyToReveal;
  bool get isRevealed => _isRevealed;
  int get roundNumber => _roundNumber;
  String? get penanceText => _penanceText;
  String get player1Name => settingsProvider.player1Name;
  String get player2Name => settingsProvider.player2Name;
  bool get disparity => _disparity;
  String? get strikePlayerName => _strikePlayerName;
  Color get player1Color => _player1Color;
  Color get player2Color => _player2Color;

  Future<void> initGame() async {
    _player1Color = settingsProvider.player1Color;
    _player2Color = settingsProvider.player2Color;
    try {
      final String jsonStr = await rootBundle.loadString('assets/data/never_have_i_ever.json');
      final List<dynamic> data = json.decode(jsonStr);
      _allQuestions = data.map((e) => NeverHaveIEverQuestion.fromJson(e)).toList();
    } catch (e) {
      _allQuestions = [];
    }

    try {
      final String dareStr = await rootBundle.loadString('assets/data/roulette_dare.json');
      final List<dynamic> dareData = json.decode(dareStr);
      _penanceList = dareData.map((e) => e.toString()).toList();
    } catch (e) {
      _penanceList = [];
    }

    if (isHotMode) {
      _availableQuestions = _allQuestions.where((q) => q.isHot).toList();
    } else {
      _availableQuestions = _allQuestions.where((q) => !q.isHot).toList();
      if (_availableQuestions.length < 10) {
        _availableQuestions = List.from(_allQuestions);
      }
    }

    _availableQuestions.shuffle(Random());
    _pickQuestion();

    _isLoading = false;
    notifyListeners();
  }

  void _pickQuestion() {
    if (_availableQuestions.isEmpty) {
      _availableQuestions = List.from(_allQuestions);
      _availableQuestions.shuffle(Random());
    }
    _currentQuestion = _availableQuestions.removeAt(0);
  }

  void answerPlayer1(bool saidYes) {
    _player1Answered = true;
    _player1SaidYes = saidYes;
    notifyListeners();

    if (_player2Answered) {
      _phaseReadyToReveal = true;
      notifyListeners();
    }
  }

  void answerPlayer2(bool saidYes) {
    _player2Answered = true;
    _player2SaidYes = saidYes;
    notifyListeners();

    if (_player1Answered) {
      _phaseReadyToReveal = true;
      notifyListeners();
    }
  }

  void reveal() {
    if (_player1SaidYes == null || _player2SaidYes == null) return;

    _disparity = _player1SaidYes != _player2SaidYes;

    if (_disparity) {
      if (_player1SaidYes == true && _player2SaidYes == false) {
        _strikesPlayer1++;
        _strikePlayerName = player1Name;
        _scorePlayer2++;
      } else {
        _strikesPlayer2++;
        _strikePlayerName = player2Name;
        _scorePlayer1++;
      }
    }

    _isRevealed = true;
    notifyListeners();

    _checkPenance();
  }

  void _checkPenance() {
    if (_strikesPlayer1 >= strikesForPenance) {
      _assignPenance();
    } else if (_strikesPlayer2 >= strikesForPenance) {
      _assignPenance();
    }
  }

  void _assignPenance() {
    if (_penanceList.isNotEmpty) {
      final random = Random();
      _penanceText = _penanceList[random.nextInt(_penanceList.length)];
      _penanceText = _penanceText!.replaceAll('{PAREJA}', player2Name);
    } else {
      _penanceText = 'Penitencia: haz algo especial para tu pareja.';
    }
    notifyListeners();
  }

  void clearPenance() {
    _penanceText = null;
    _strikesPlayer1 = 0;
    _strikesPlayer2 = 0;
    notifyListeners();
  }

  void nextRound() {
    if (_scorePlayer1 >= pointsToWin) {
      onWinner?.call(player1Name);
      return;
    }
    if (_scorePlayer2 >= pointsToWin) {
      onWinner?.call(player2Name);
      return;
    }

    if (_roundNumber >= rounds) {
      final winnerName = _scorePlayer1 > _scorePlayer2
          ? player1Name
          : (_scorePlayer2 > _scorePlayer1 ? player2Name : 'EMPATE');
      onWinner?.call(winnerName);
      return;
    }

    _roundNumber++;
    _player1Answered = false;
    _player2Answered = false;
    _player1SaidYes = null;
    _player2SaidYes = null;
    _phaseReadyToReveal = false;
    _isRevealed = false;
    _disparity = false;
    _strikePlayerName = null;

    _pickQuestion();
    notifyListeners();
  }
}
