import 'dart:math';
import 'dart:async';
import 'package:flutter/foundation.dart';
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

  String _heName = '';
  String _sheName = '';
  int _heScore = 0;
  int _sheScore = 0;

  bool _isShowingSequence = false;
  bool _isPlayerTurn = false;
  bool _isTransitioning = false;
  bool _isHeTurn = true;
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

  String get heName => _heName;
  String get sheName => _sheName;
  int get heScore => _heScore;
  int get sheScore => _sheScore;
  bool get isShowingSequence => _isShowingSequence;
  bool get isPlayerTurn => _isPlayerTurn;
  bool get isTransitioning => _isTransitioning;
  bool get isHeTurn => _isHeTurn;
  int get currentRound => _currentRound;
  int get currentLevel => _currentLevel;
  int get maxRoundsValue => maxRounds;
  List<int> get sequence => _sequence;
  int get inputIndex => _inputIndex;
  int? get highlightedButton => _highlightedButton;
  double get timeLeft => _timeLeft;
  String get activeName => _isHeTurn ? _heName : _sheName;
  bool get isGameOver => _currentRound >= maxRounds;

  void Function({required String winnerName, required String loserName})? onGameFinished;
  void Function({required String loserName})? onRoundLost;

  void setStartingPlayer(bool isHe) {
    _isHeTurn = isHe;
  }

  Future<void> initGame() async {
    _heName = settingsProvider.heName;
    _sheName = settingsProvider.sheName;
    _currentRound = 0;
    _heScore = 0;
    _sheScore = 0;
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
    _isHeTurn = !_isHeTurn;
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
    final loser = _isHeTurn ? _heName : _sheName;

    if (_isHeTurn) {
      _sheScore++;
    } else {
      _heScore++;
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
    _isHeTurn = !_isHeTurn;
    startRound();
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

  @override
  void dispose() {
    _showTimer?.cancel();
    _inputTimer?.cancel();
    audioService.stop();
    super.dispose();
  }
}
