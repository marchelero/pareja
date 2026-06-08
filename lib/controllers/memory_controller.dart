import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../providers/settings_provider.dart';

class MemoryController extends ChangeNotifier {
  final AudioService audioService;
  final SettingsProvider settingsProvider;
  final int maxRounds;

  MemoryController({
    required this.audioService,
    required this.settingsProvider,
    this.maxRounds = 5,
  });

  String _player1Name = '';
  String _player2Name = '';
  int _player1Score = 0;
  int _player2Score = 0;
  Color _player1Color = Colors.blueAccent;
  Color _player2Color = Colors.pinkAccent;

  bool _isShowingSequence = false;
  bool _isPlayerTurn = false;
  bool _isTransitioning = false;
  bool _isPlayer1Turn = true;
  int _currentRound = 0;
  int _currentLevel = 1;
  int _inputIndex = 0;

  List<int> _sequence = [];

  int _showingIndex = 0;
  Timer? _showTimer;
  Timer? _inputTimer;
  int? _highlightedButton;
  double _timeLeft = 3.0;
  bool _isTimeout = false;

  static const Duration _tileShowDuration = Duration(milliseconds: 600);
  static const Duration _tileGapDuration = Duration(milliseconds: 300);

  static const _tileSounds = ['c6.mp3', 'd6.mp3', 'e6.mp3', 'f6.mp3'];

  void _playTileSound(int index) {
    audioService.play(_tileSounds[index]);
  }

  String get player1Name => _player1Name;
  String get player2Name => _player2Name;
  int get player1Score => _player1Score;
  int get player2Score => _player2Score;
  Color get player1Color => _player1Color;
  Color get player2Color => _player2Color;
  bool get isShowingSequence => _isShowingSequence;
  bool get isPlayerTurn => _isPlayerTurn;
  bool get isTransitioning => _isTransitioning;
  bool get isHeTurn => _isPlayer1Turn;
  int get currentRound => _currentRound;
  int get currentLevel => _currentLevel;
  int get maxRoundsValue => maxRounds;
  List<int> get sequence => _sequence;
  int get inputIndex => _inputIndex;
  int? get highlightedButton => _highlightedButton;
  double get timeLeft => _timeLeft;
  String get activeName => _isPlayer1Turn ? _player1Name : _player2Name;
  bool get isGameOver => _currentRound >= maxRounds;

  void Function({required String winnerName, required String loserName})? onGameFinished;
  void Function({required String loserName})? onRoundLost;

  void setStartingPlayer(bool isHe) {
    _isPlayer1Turn = isHe;
  }

  Future<void> initGame() async {
    _player1Name = settingsProvider.player1Name;
    _player2Name = settingsProvider.player2Name;
    _player1Color = settingsProvider.player1Color;
    _player2Color = settingsProvider.player2Color;
    _currentRound = 0;
    _player1Score = 0;
    _player2Score = 0;
    notifyListeners();
  }

  void startRound() {
    _currentRound++;
    _currentLevel = 1;
    _sequence = [];
    _nextLevel();
  }

  void _nextLevel() {
    _sequence.add(Random().nextInt(4));
    _inputIndex = 0;
    _isTimeout = false;
    _showSequence();
  }

  void _showSequence() {
    _isShowingSequence = true;
    _isPlayerTurn = false;
    _showingIndex = 0;
    notifyListeners();
    _showNextTile();
  }

  void _showNextTile() {
    if (!_isShowingSequence) return;

    if (_showingIndex >= _sequence.length) {
      _isShowingSequence = false;
      _highlightedButton = null;
      _isPlayerTurn = true;
      _inputIndex = 0;
      _timeLeft = 3.0;
      notifyListeners();
      _startInputTimer();
      return;
    }

    _highlightedButton = _sequence[_showingIndex];
    _playTileSound(_highlightedButton!);
    notifyListeners();

    _showTimer = Timer(_tileShowDuration, () {
      _highlightedButton = null;
      notifyListeners();
      _showingIndex++;
      _showTimer = Timer(_tileGapDuration, () {
        _showNextTile();
      });
    });
  }

  void _startInputTimer() {
    _inputTimer?.cancel();
    _timeLeft = 3.0;
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

  void playerTap(int buttonIndex) {
    if (!_isPlayerTurn || _isTimeout) return;

    _playTileSound(buttonIndex);

    if (buttonIndex != _sequence[_inputIndex]) {
      _onMistake();
      return;
    }

    _inputIndex++;
    _timeLeft = 3.0;
    notifyListeners();

    if (_inputIndex >= _sequence.length) {
      _cancelInputTimer();
      _onSuccess();
    }
  }

  void _onSuccess() {
    _isPlayerTurn = false;
    _cancelInputTimer();
    _currentLevel++;
    _isPlayer1Turn = !_isPlayer1Turn;
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 400), () {
      if (!_isShowingSequence) {
        _isTransitioning = true;
        notifyListeners();
      }
    });

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!_isShowingSequence) {
        _isTransitioning = false;
        _nextLevel();
      }
    });
  }

  void _onTimeout() {
    if (!_isPlayerTurn) return;
    _isTimeout = true;
    _onMistake();
  }

  void _onMistake() {
    _isPlayerTurn = false;
    _cancelInputTimer();
    final loser = _isPlayer1Turn ? _player1Name : _player2Name;

    if (_isPlayer1Turn) {
      _player2Score++;
    } else {
      _player1Score++;
    }

    notifyListeners();
    onRoundLost?.call(loserName: loser);

    if (isGameOver) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _finishGame();
      });
    }
  }

  void startNextRound() {
    _isPlayer1Turn = !_isPlayer1Turn;
    startRound();
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
    _showTimer?.cancel();
    _inputTimer?.cancel();
    audioService.stop();
    super.dispose();
  }
}
