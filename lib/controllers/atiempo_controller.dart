import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../providers/settings_provider.dart';

enum ATiempoPhase {
  waitingTurn,
  running,
  turnDone,
  bothDone,
  roundOver,
  matchOver,
}

class ATiempoController extends ChangeNotifier {
  final AudioService audioService;
  final SettingsProvider settingsProvider;
  final int pointsPerRound;
  final int matchRounds;
  final double targetTime;
  final bool wildMode;
  double _wildTarget = 10.0;

  ATiempoController({
    required this.audioService,
    required this.settingsProvider,
    this.pointsPerRound = 3,
    this.matchRounds = 3,
    this.targetTime = 10.0,
    this.wildMode = false,
  });

  double get currentTarget => wildMode ? _wildTarget : targetTime;

  void _generateWildTarget() {
    if (wildMode) {
      _wildTarget = (Random().nextInt(10) + 1).toDouble();
    }
  }

  String _player1Name = '';
  String _player2Name = '';
  Color _player1Color = Colors.blueAccent;
  Color _player2Color = Colors.pinkAccent;
  IconData _player1Icon = Icons.male;
  IconData _player2Icon = Icons.female;

  ATiempoPhase _phase = ATiempoPhase.waitingTurn;
  double _currentTime = 0.0;
  double? _p1Time;
  double? _p2Time;
  bool _isPlayer1Turn = true;
  int _p1Points = 0;
  int _p2Points = 0;
  int _p1Rounds = 0;
  int _p2Rounds = 0;
  int _currentRound = 1;
  Timer? _timer;
  final Stopwatch _stopwatch = Stopwatch();
  String? _winnerName;
  int _roundPointsAwarded = 1;
  bool _isDouble = false;
  bool _needsNewTarget = true;

  String get player1Name => _player1Name;
  String get player2Name => _player2Name;
  Color get player1Color => _player1Color;
  Color get player2Color => _player2Color;
  IconData get player1Icon => _player1Icon;
  IconData get player2Icon => _player2Icon;
  ATiempoPhase get phase => _phase;
  double get currentTime => _currentTime;
  double? get p1Time => _p1Time;
  double? get p2Time => _p2Time;
  bool get isPlayer1Turn => _isPlayer1Turn;
  int get p1Points => _p1Points;
  int get p2Points => _p2Points;
  int get p1Rounds => _p1Rounds;
  int get p2Rounds => _p2Rounds;
  int get currentRound => _currentRound;
  String? get winnerName => _winnerName;
  int get roundPointsAwarded => _roundPointsAwarded;
  bool get isDouble => _isDouble;
  bool get isTie => _p1Time != null && _p2Time != null && (_p1Time! - targetTime).abs() == (_p2Time! - targetTime).abs();

  bool get isMatchP1Winner => _p1Rounds > _p2Rounds;

  void initGame() {
    _player1Name = settingsProvider.player1Name;
    _player2Name = settingsProvider.player2Name;
    _player1Color = settingsProvider.player1Color;
    _player2Color = settingsProvider.player2Color;
    _player1Icon = settingsProvider.player1Icon;
    _player2Icon = settingsProvider.player2Icon;
    _p1Points = 0;
    _p2Points = 0;
    _p1Rounds = 0;
    _p2Rounds = 0;
    _currentRound = 1;
    _phase = ATiempoPhase.waitingTurn;
    _currentTime = 0.0;
    _p1Time = null;
    _p2Time = null;
    _winnerName = null;
    _isDouble = false;
    _roundPointsAwarded = 1;
    _stopwatch
      ..reset()
      ..stop();
    if (wildMode) _generateWildTarget();
    _needsNewTarget = false;
    notifyListeners();
  }

  void setStartingPlayer(bool isP1) {
    _isPlayer1Turn = isP1;
    notifyListeners();
  }

  void startTimer() {
    if (wildMode && _needsNewTarget) {
      _generateWildTarget();
      _needsNewTarget = false;
    }
    _currentTime = 0.0;
    _phase = ATiempoPhase.running;
    _timer?.cancel();
    _stopwatch.reset();
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      _currentTime = _stopwatch.elapsedMilliseconds / 1000.0;
      notifyListeners();
    });
    notifyListeners();
  }

  void stopTimer() {
    _timer?.cancel();
    _timer = null;
    _stopwatch.stop();
    if (_isPlayer1Turn) {
      _p1Time = _currentTime;
    } else {
      _p2Time = _currentTime;
    }
    _phase = ATiempoPhase.turnDone;
    notifyListeners();
  }

  void startNextTurn({bool resetMatch = false}) {
    _isPlayer1Turn = !_isPlayer1Turn;
    _currentTime = 0.0;
    _stopwatch
      ..reset()
      ..stop();
    if (resetMatch) {
      _p1Time = null;
      _p2Time = null;
    }
    _phase = ATiempoPhase.waitingTurn;
    notifyListeners();
  }

  void evaluateComparison() {
    if (_p1Time == null || _p2Time == null) return;

    final p1Diff = (_p1Time! - currentTarget).abs();
    final p2Diff = (_p2Time! - currentTarget).abs();

    if (p1Diff < p2Diff) {
      _winnerName = _player1Name;
      _isDouble = (_p1Time! - currentTarget).abs() < 0.02;
      _roundPointsAwarded = _isDouble ? 2 : 1;
      _p1Points += _roundPointsAwarded;
    } else if (p2Diff < p1Diff) {
      _winnerName = _player2Name;
      _isDouble = (_p2Time! - currentTarget).abs() < 0.02;
      _roundPointsAwarded = _isDouble ? 2 : 1;
      _p2Points += _roundPointsAwarded;
    } else {
      _p1Time = null;
      _p2Time = null;
      _needsNewTarget = true;
      _phase = ATiempoPhase.waitingTurn;
      notifyListeners();
      return;
    }

    _needsNewTarget = true;

    if (_p1Points >= pointsPerRound || _p2Points >= pointsPerRound) {
      if (_p1Points > _p2Points) {
        _p1Rounds++;
      } else {
        _p2Rounds++;
      }
      final needed = (matchRounds ~/ 2) + 1;
      if (_p1Rounds >= needed || _p2Rounds >= needed) {
        _phase = ATiempoPhase.matchOver;
      } else {
        _phase = ATiempoPhase.roundOver;
      }
    } else {
      _phase = ATiempoPhase.bothDone;
    }
    notifyListeners();
  }

  void startNewRound() {
    _p1Points = 0;
    _p2Points = 0;
    _p1Time = null;
    _p2Time = null;
    _currentRound++;
    _needsNewTarget = true;
    _phase = ATiempoPhase.waitingTurn;
    audioService.playLevelUp();
    notifyListeners();
  }

  void resetGame() {
    _winnerName = null;
    initGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }
}
