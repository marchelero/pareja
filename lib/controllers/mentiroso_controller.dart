import 'dart:math';
import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../providers/settings_provider.dart';

enum MentirosoStep { roll, select, handoff, guess, result }

class MentirosoController extends ChangeNotifier {
  final AudioService audioService;
  final int totalRounds;

  MentirosoController({
    required this.audioService,
    this.totalRounds = 5,
  });

  static const List<String> statements = [
    'Suma > 10',
    'Dados iguales',
    'Ambos impares',
    'Ambos pares',
    'Suma par',
    'Al menos un 6',
    'Suma exacta 7',
    'Al menos un 1',
  ];

  int dice1 = 0;
  int dice2 = 0;
  MentirosoStep step = MentirosoStep.roll;
  int? selectedIndex;
  bool? guessIsVerdad;
  int scoreP1 = 0;
  int scoreP2 = 0;
  int round = 1;
  bool _startsWithP1 = true;

  final Map<int, bool> _statementTruth = {};

  bool get isP1Liar => _startsWithP1 ? round.isOdd : round.isEven;

  void setStartingPlayer(bool isP1) {
    _startsWithP1 = isP1;
  }

  String liarName(SettingsProvider s) => isP1Liar ? s.displayName1 : s.displayName2;
  String inquisitorName(SettingsProvider s) => isP1Liar ? s.displayName2 : s.displayName1;

  bool isStatementTrue(int index) => _statementTruth[index] ?? false;
  String get selectedStatementText => selectedIndex != null ? statements[selectedIndex!] : '';
  bool get selectedWasTrue => selectedIndex != null ? _statementTruth[selectedIndex!]! : false;

  void rollDice() {
    final rng = Random();
    dice1 = rng.nextInt(6) + 1;
    dice2 = rng.nextInt(6) + 1;
    _evaluateStatements();
    selectedIndex = null;
    guessIsVerdad = null;
    notifyListeners();
  }

  void revealDice() {
    step = MentirosoStep.select;
    notifyListeners();
  }

  void _evaluateStatements() {
    _statementTruth[0] = dice1 + dice2 > 10;
    _statementTruth[1] = dice1 == dice2;
    _statementTruth[2] = dice1.isOdd && dice2.isOdd;
    _statementTruth[3] = dice1.isEven && dice2.isEven;
    _statementTruth[4] = (dice1 + dice2).isEven;
    _statementTruth[5] = dice1 == 6 || dice2 == 6;
    _statementTruth[6] = dice1 + dice2 == 7;
    _statementTruth[7] = dice1 == 1 || dice2 == 1;
  }

  void selectStatement(int index) {
    selectedIndex = index;
    notifyListeners();
  }

  void confirmBluff() {
    step = MentirosoStep.handoff;
    notifyListeners();
  }

  void startInvestigation() {
    step = MentirosoStep.guess;
    notifyListeners();
  }

  void guess(bool isVerdad) {
    guessIsVerdad = isVerdad;
    _calculatePoints();
    step = MentirosoStep.result;
    notifyListeners();
  }

  void _calculatePoints() {
    if (selectedIndex == null) return;
    final wasTrue = _statementTruth[selectedIndex!]!;
    final wasCorrectGuess = guessIsVerdad == wasTrue;

    if (wasCorrectGuess) {
      if (isP1Liar) { scoreP2++; } else { scoreP1++; }
    } else {
      if (isP1Liar) { scoreP1++; } else { scoreP2++; }
    }
  }

  bool get isGameOver => round >= totalRounds;

  String getRoundResultText(SettingsProvider s) {
    if (selectedIndex == null || guessIsVerdad == null) return '';
    final wasTrue = _statementTruth[selectedIndex!]!;
    final iName = inquisitorName(s);
    final lName = liarName(s);

    if (guessIsVerdad == true && wasTrue) {
      return '$iName acert\u00f3. La afirmaci\u00f3n era verdadera. +1 $iName';
    } else if (guessIsVerdad == true && !wasTrue) {
      return '$iName crey\u00f3 una mentira. +1 $lName';
    } else if (guessIsVerdad == false && !wasTrue) {
      return '$iName descubri\u00f3 la mentira. +1 $iName';
    } else {
      return '$iName acus\u00f3 injustamente. +1 $lName';
    }
  }

  String get finalWinnerName {
    if (scoreP1 > scoreP2) return 'Gana Jugador 1';
    if (scoreP2 > scoreP1) return 'Gana Jugador 2';
    return 'Empate';
  }

  void nextRound() {
    round++;
    step = MentirosoStep.roll;
    dice1 = 1;
    dice2 = 1;
    selectedIndex = null;
    guessIsVerdad = null;
    _statementTruth.clear();
    notifyListeners();
  }

  void resetGame() {
    round = 1;
    scoreP1 = 0;
    scoreP2 = 0;
    dice1 = 1;
    dice2 = 1;
    selectedIndex = null;
    guessIsVerdad = null;
    _statementTruth.clear();
    step = MentirosoStep.roll;
    notifyListeners();
  }
}
