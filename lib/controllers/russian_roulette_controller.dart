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

  RussianRouletteController({
    required this.audioService,
    required this.settingsProvider,
    required this.bestOf,
  });

  bool _isLoading = true;
  bool _isPlaying = false;
  int _currentChamber = 0;
  int _triggerPulls = 0;
  int _firingPinChamber = 0;  // chamber currently under the firing pin (arrow at top)
  final List<int> _checkedOrder = [];
  bool _isHeTurn = true;
  int _scoreHe = 0;
  int _scoreShe = 0;
  late int _pointsToWin;
  bool _roundOver = false;
  bool _bulletFired = false;

  bool _isSpinning = false;
  bool _isPullingTrigger = false;
  bool _isClickResult = false;
  bool _isBangResult = false;

  late String _heName;
  late String _sheName;
  int _roundNumber = 0;

  // Getters
  bool get isLoading => _isLoading;
  bool get isPlaying => _isPlaying;
  int get currentChamber => _currentChamber;
  int get triggerPulls => _triggerPulls;
  int get firingPinChamber => _firingPinChamber;
  List<int> get checkedOrder => _checkedOrder;
  bool get isHeTurn => _isHeTurn;
  int get scoreHe => _scoreHe;
  int get scoreShe => _scoreShe;
  int get pointsToWin => _pointsToWin;
  bool get roundOver => _roundOver;
  bool get bulletFired => _bulletFired;
  bool get isSpinning => _isSpinning;
  bool get isPullingTrigger => _isPullingTrigger;
  bool get isClickResult => _isClickResult;
  bool get isBangResult => _isBangResult;
  String get heName => _heName;
  String get sheName => _sheName;
  int get roundNumber => _roundNumber;
  String get activeName => _isHeTurn ? _heName : _sheName;
  Color get activeColor => _isHeTurn ? const Color(0xFF448AFF) : const Color(0xFFFF4081);

  void Function({required String loserName})? onRoundResult;
  void Function({required String winnerName, required Color winnerColor})? onWinner;

  Future<void> initGame() async {
    _heName = settingsProvider.heName;
    _sheName = settingsProvider.sheName;
    _pointsToWin = (bestOf / 2).floor() + 1;
    _startNewRound();
    _isLoading = false;
    notifyListeners();
  }

  void _startNewRound() {
    _currentChamber = Random().nextInt(6);
    _triggerPulls = 0;
    _firingPinChamber = Random().nextInt(6);
    _checkedOrder.clear();
    _roundOver = false;
    _bulletFired = false;
    _isSpinning = true;
    _isPlaying = false;
    _isClickResult = false;
    _isBangResult = false;
    _isPullingTrigger = false;
    _roundNumber++;
    notifyListeners();
  }

  void endSpin() {
    _isSpinning = false;
    _isPlaying = true;
    notifyListeners();
  }

  void pullTrigger() {
    if (!_isPlaying || _roundOver) return;

    _isPullingTrigger = true;
    _triggerPulls++;
    _checkedOrder.add(_firingPinChamber);

    if (_firingPinChamber == _currentChamber) {
      // BANG! The bullet fires
      _bulletFired = true;
      _roundOver = true;
      _isPlaying = false;
      _isBangResult = true;
      _isPullingTrigger = false;

      // Award point to the other player
      if (_isHeTurn) {
        _scoreShe++;
      } else {
        _scoreHe++;
      }

      notifyListeners();
      audioService.play(AppConstants.soundShot);

      Future.delayed(const Duration(milliseconds: 1200), () {
        if (!_isBangResult) return;
        _isBangResult = false;
        notifyListeners();

        final loserName = _isHeTurn ? _heName : _sheName;
        final isGameOver = _scoreHe >= _pointsToWin || _scoreShe >= _pointsToWin;

        if (isGameOver) {
          final winnerName = _scoreHe >= _pointsToWin ? _heName : _sheName;
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

      _firingPinChamber = (_firingPinChamber + 5) % 6; // CW 60° advance

      Future.delayed(const Duration(milliseconds: 800), () {
        _isClickResult = false;
        _isPullingTrigger = false;
        _isHeTurn = !_isHeTurn;
        _isPlaying = true;
        notifyListeners();
      });
    }
  }

  void nextRoundAfterDialog() {
    _startNewRound();
  }


}
