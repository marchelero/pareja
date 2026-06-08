import 'dart:math';
import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../providers/settings_provider.dart';

class CardData {
  final String emoji;
  bool isFlipped = false;
  bool isMatched = false;
  final int pairId;

  CardData({required this.emoji, required this.pairId});
}

class PairsController extends ChangeNotifier {
  final AudioService audioService;
  final SettingsProvider settingsProvider;
  final int maxRounds;
  final int gridRows;
  final int gridCols;
  final int pairCount;

  PairsController({
    required this.audioService,
    required this.settingsProvider,
    this.maxRounds = 3,
    this.gridRows = 4,
    this.gridCols = 5,
  }) : pairCount = (gridRows * gridCols) ~/ 2;

  static const List<String> _emojis = [
    '🍎', '🍊', '🍋', '🍇', '🍓',
    '🍑', '🍒', '🥝', '🍌', '🍍',
    '🥭', '🫐', '🍈', '🍐', '🍏',
  ];

  final List<CardData> _cards = [];
  int? _firstIndex;
  bool _isChecking = false;
  bool _isPlayer1Turn = true;
  int _player1Score = 0;
  int _player2Score = 0;
  int _currentRound = 0;
  int _player1Rounds = 0;
  int _player2Rounds = 0;
  bool _isGameOver = false;
  bool _isLoading = true;
  bool _roundEnded = false;
  String? _lastRoundWinner;
  int _lastRoundP1Score = 0;
  int _lastRoundP2Score = 0;
  String _player1Name = '';
  String _player2Name = '';
  Color _player1Color = Colors.blueAccent;
  Color _player2Color = Colors.pinkAccent;

  List<CardData> get cards => _cards;
  bool get isPlayer1Turn => _isPlayer1Turn;
  int get player1Score => _player1Score;
  int get player2Score => _player2Score;
  int get player1Rounds => _player1Rounds;
  int get player2Rounds => _player2Rounds;
  int get currentRound => _currentRound;
  bool get isGameOver => _isGameOver;
  bool get isLoading => _isLoading;
  bool get roundEnded => _roundEnded;
  String? get lastRoundWinner => _lastRoundWinner;
  int get lastRoundP1Score => _lastRoundP1Score;
  int get lastRoundP2Score => _lastRoundP2Score;
  bool get isChecking => _isChecking;
  String get player1Name => _player1Name;
  String get player2Name => _player2Name;
  Color get player1Color => _player1Color;
  Color get player2Color => _player2Color;
  int get totalPairs => pairCount;
  int get matchedPairs => _cards.where((c) => c.isMatched).length ~/ 2;
  bool get isRoundOver => matchedPairs >= pairCount;

  Future<void> initGame() async {
    _player1Name = settingsProvider.player1Name;
    _player2Name = settingsProvider.player2Name;
    _player1Color = settingsProvider.player1Color;
    _player2Color = settingsProvider.player2Color;
    _player1Score = 0;
    _player2Score = 0;
    _player1Rounds = 0;
    _player2Rounds = 0;
    _currentRound = 0;
    _isGameOver = false;
    _isLoading = false;
    _startNewRound();
    notifyListeners();
  }

  void setStartingPlayer(bool isP1) {
    _isPlayer1Turn = isP1;
    notifyListeners();
  }

  void _startNewRound() {
    _currentRound++;
    _player1Score = 0;
    _player2Score = 0;
    _cards.clear();
    _firstIndex = null;
    _isChecking = false;

    for (int i = 0; i < pairCount; i++) {
      _cards.add(CardData(emoji: _emojis[i], pairId: i));
      _cards.add(CardData(emoji: _emojis[i], pairId: i));
    }
    _cards.shuffle(Random());

    notifyListeners();
  }

  void selectCard(int index) {
    if (_isChecking) return;
    if (index < 0 || index >= _cards.length) return;
    if (_cards[index].isFlipped || _cards[index].isMatched) return;

    _cards[index].isFlipped = true;
    audioService.playClick();

    if (_firstIndex == null) {
      _firstIndex = index;
      notifyListeners();
      return;
    }

    _isChecking = true;
    final secondIndex = index;
    final firstCard = _cards[_firstIndex!];
    final secondCard = _cards[secondIndex];

    if (firstCard.pairId == secondCard.pairId) {
      Future.delayed(const Duration(milliseconds: 400), () {
        firstCard.isMatched = true;
        secondCard.isMatched = true;
        if (_isPlayer1Turn) {
          _player1Score++;
        } else {
          _player2Score++;
        }
        _firstIndex = null;
        _isChecking = false;
        audioService.playLevelUp();

        if (isRoundOver) {
          _endRound();
        }
        notifyListeners();
      });
    } else {
      Future.delayed(const Duration(milliseconds: 900), () {
        firstCard.isFlipped = false;
        secondCard.isFlipped = false;
        _firstIndex = null;
        _isChecking = false;
        _isPlayer1Turn = !_isPlayer1Turn;

        if (isRoundOver) {
          _endRound();
        }
        notifyListeners();
      });
    }
    notifyListeners();
  }

  void _endRound() {
    _lastRoundP1Score = _player1Score;
    _lastRoundP2Score = _player2Score;

    if (_player1Score > _player2Score) {
      _player1Rounds++;
      _lastRoundWinner = _player1Name;
    } else if (_player2Score > _player1Score) {
      _player2Rounds++;
      _lastRoundWinner = _player2Name;
    } else {
      _lastRoundWinner = null;
    }

    if (_currentRound >= maxRounds) {
      _isGameOver = true;
    } else {
      _roundEnded = true;
    }
  }

  void continueToNextRound() {
    _roundEnded = false;
    _startNewRound();
  }
}
