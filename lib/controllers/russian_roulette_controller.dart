import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../services/audio_service.dart';
import '../providers/settings_provider.dart';

class RussianRouletteController extends ChangeNotifier {
  final AudioService audioService;
  final SettingsProvider settingsProvider;
  final int bestOf;
  final bool wildMode;
  final int bulletCount;

  RussianRouletteController({
    required this.audioService,
    required this.settingsProvider,
    required this.bestOf,
    this.wildMode = false,
    this.bulletCount = 2,
  });

  bool _isLoading = true;
  bool _isPlaying = false;
  int _currentChamber = 0;
  int _triggerPulls = 0;
  int _firingPinChamber = 0;  // chamber currently under the firing pin (arrow at top)
  final List<int> _checkedOrder = [];
  bool _isPlayer1Turn = true;
  int _scoreHe = 0;
  int _scoreShe = 0;
  late int _pointsToWin;
  bool _roundOver = false;
  bool _bulletFired = false;

  Set<int> _bulletChambers = {};

  bool _isSpinning = false;
  bool _isPullingTrigger = false;
  bool _isClickResult = false;
  bool _isBangResult = false;

  late String _player1Name;
  late String _player2Name;
  Color _player1Color = Colors.blueAccent;
  Color _player2Color = Colors.pinkAccent;
  int _roundNumber = 0;

  // Getters
  bool get isLoading => _isLoading;
  bool get isPlaying => _isPlaying;
  int get currentChamber => _currentChamber;
  int get triggerPulls => _triggerPulls;
  int get firingPinChamber => _firingPinChamber;
  List<int> get checkedOrder => _checkedOrder;
  Set<int> get bulletChambers => _bulletChambers;
  bool get isHeTurn => _isPlayer1Turn;
  int get scoreHe => _scoreHe;
  int get scoreShe => _scoreShe;
  int get pointsToWin => _pointsToWin;
  bool get roundOver => _roundOver;
  bool get bulletFired => _bulletFired;
  bool get isSpinning => _isSpinning;
  bool get isPullingTrigger => _isPullingTrigger;
  bool get isClickResult => _isClickResult;
  bool get isBangResult => _isBangResult;
  bool get isWildMode => wildMode;
  String get player1Name => _player1Name;
  String get player2Name => _player2Name;
  int get roundNumber => _roundNumber;
  String get activeName => _isPlayer1Turn ? _player1Name : _player2Name;
  Color get activeColor => _isPlayer1Turn ? _player1Color : _player2Color;
  Color get player1Color => _player1Color;
  Color get player2Color => _player2Color;

  void Function({required String loserName})? onRoundResult;
  void Function({required String winnerName, required Color winnerColor})? onWinner;

  Future<void> initGame() async {
    _player1Name = settingsProvider.player1Name;
    _player2Name = settingsProvider.player2Name;
    _player1Color = settingsProvider.player1Color;
    _player2Color = settingsProvider.player2Color;
    _pointsToWin = (bestOf / 2).floor() + 1;
    _startNewRound();
    _isLoading = false;
    notifyListeners();
  }

  void _startNewRound() {
    _triggerPulls = 0;
    _checkedOrder.clear();
    _roundOver = false;
    _bulletFired = false;
    _isSpinning = true;
    _isPlaying = false;
    _isClickResult = false;
    _isBangResult = false;
    _isPullingTrigger = false;
    _roundNumber++;

    final rng = Random();
    if (wildMode) {
      _bulletChambers = {};
      while (_bulletChambers.length < bulletCount) {
        _bulletChambers.add(rng.nextInt(6));
      }
      _firingPinChamber = rng.nextInt(6);
    } else {
      _currentChamber = rng.nextInt(6);
      _firingPinChamber = rng.nextInt(6);
    }

    notifyListeners();
  }

  void endSpin() {
    _isSpinning = false;
    _isPlaying = true;
    notifyListeners();
  }

  void startRespin() {
    _isClickResult = false;
    _isPullingTrigger = false;
    _isPlayer1Turn = !_isPlayer1Turn;

    final rng = Random();
    _bulletChambers = {};
    while (_bulletChambers.length < bulletCount) {
      _bulletChambers.add(rng.nextInt(6));
    }
    _firingPinChamber = rng.nextInt(6);
    _checkedOrder.clear();

    _isSpinning = true;
    _isPlaying = false;
    notifyListeners();
  }

  void pullTrigger() {
    if (!_isPlaying || _roundOver) return;

    _isPullingTrigger = true;
    _triggerPulls++;
    _checkedOrder.add(_firingPinChamber);

    final bool hitBullet = wildMode
        ? _bulletChambers.contains(_firingPinChamber)
        : _firingPinChamber == _currentChamber;

    if (hitBullet) {
      // BANG! The bullet fires
      _currentChamber = _firingPinChamber; // for painter
      _bulletFired = true;
      _roundOver = true;
      _isPlaying = false;
      _isBangResult = true;
      _isPullingTrigger = false;

      // Award point to the other player
      if (_isPlayer1Turn) {
        _scoreShe++;
      } else {
        _scoreHe++;
      }

      final bool previousTurn = _isPlayer1Turn;
      if (wildMode) _isPlayer1Turn = !_isPlayer1Turn;

      notifyListeners();
      audioService.play(AppConstants.soundShot);

      Future.delayed(const Duration(milliseconds: 1200), () {
        if (!_isBangResult) return;
        _isBangResult = false;
        notifyListeners();

        final loserName = previousTurn ? _player1Name : _player2Name;
        final isGameOver = _scoreHe >= _pointsToWin || _scoreShe >= _pointsToWin;

        if (isGameOver) {
          final winnerName = _scoreHe >= _pointsToWin ? _player1Name : _player2Name;
          onWinner?.call(winnerName: winnerName, winnerColor: AppColors.modeRussianRoulette);
        } else {
          onRoundResult?.call(loserName: loserName);
        }
      });
    } else {
      // Click! Empty chamber
      _isClickResult = true;
      _isPlaying = false;
      notifyListeners();
      audioService.play(AppConstants.soundEmptyShot);

      if (wildMode) {
        // Game screen will call startRespin() after showing result
      } else {
        _firingPinChamber = (_firingPinChamber + 5) % 6; // CW 60° advance

        Future.delayed(const Duration(milliseconds: 800), () {
          _isClickResult = false;
          _isPullingTrigger = false;
          _isPlayer1Turn = !_isPlayer1Turn;
          _isPlaying = true;
          notifyListeners();
        });
      }
    }
  }

  void nextRoundAfterDialog() {
    _startNewRound();
  }


}
