import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
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
  int _scoreHe = 0;
  int _scoreShe = 0;
  int _strikesHe = 0;
  int _strikesShe = 0;

  bool _heAnswered = false;
  bool _sheAnswered = false;
  bool? _heSaidYo;
  bool? _sheSaidYo;

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
  int get scoreHe => _scoreHe;
  int get scoreShe => _scoreShe;
  int get strikesHe => _strikesHe;
  int get strikesShe => _strikesShe;
  bool get heAnswered => _heAnswered;
  bool get sheAnswered => _sheAnswered;
  bool? get heSaidYo => _heSaidYo;
  bool? get sheSaidYo => _sheSaidYo;
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

  void answerHe(bool saidYo) {
    _heAnswered = true;
    _heSaidYo = saidYo;
    notifyListeners();

    if (_sheAnswered) {
      _phaseReadyToReveal = true;
      notifyListeners();
    }
  }

  void answerShe(bool saidYo) {
    _sheAnswered = true;
    _sheSaidYo = saidYo;
    notifyListeners();

    if (_heAnswered) {
      _phaseReadyToReveal = true;
      notifyListeners();
    }
  }

  void reveal() {
    if (_heSaidYo == null || _sheSaidYo == null) return;

    _disparity = _heSaidYo != _sheSaidYo;

    if (_disparity) {
      // Quien dijo YO (lo ha hecho) recibe strike
      // Quien dijo NUNCA (no lo ha hecho) suma punto por ganar la ronda
      if (_heSaidYo == true && _sheSaidYo == false) {
        _strikesHe++;
        _strikePlayerName = player1Name;
        _scoreShe++; // Ella gana la ronda
      } else {
        _strikesShe++;
        _strikePlayerName = player2Name;
        _scoreHe++; // Él gana la ronda
      }
    }
    // Si hay paridad (ambos YO o ambos NUNCA), nadie suma puntos

    _isRevealed = true;
    notifyListeners();

    _checkPenance();
  }

  void _checkPenance() {
    if (_strikesHe >= strikesForPenance) {
      _assignPenance();
    } else if (_strikesShe >= strikesForPenance) {
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
    _strikesHe = 0;
    _strikesShe = 0;
    notifyListeners();
  }

  void nextRound() {
    if (_scoreHe >= pointsToWin) {
      onWinner?.call(player1Name);
      return;
    }
    if (_scoreShe >= pointsToWin) {
      onWinner?.call(player2Name);
      return;
    }

    if (_roundNumber >= rounds) {
      final winnerName = _scoreHe > _scoreShe
          ? player1Name
          : (_scoreShe > _scoreHe ? player2Name : 'EMPATE');
      onWinner?.call(winnerName);
      return;
    }

    _roundNumber++;
    _heAnswered = false;
    _sheAnswered = false;
    _heSaidYo = null;
    _sheSaidYo = null;
    _phaseReadyToReveal = false;
    _isRevealed = false;
    _disparity = false;
    _strikePlayerName = null;

    _pickQuestion();
    notifyListeners();
  }
}
