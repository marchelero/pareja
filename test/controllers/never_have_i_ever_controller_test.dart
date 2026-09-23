import 'package:flutter_test/flutter_test.dart';
import 'package:pareja/controllers/never_have_i_ever_controller.dart';

import 'helpers.dart';

void main() {
  Future<NeverHaveIEverController> setup(WidgetTester tester,
      {int rounds = 5,
      int pointsToWin = 3,
      int strikesForPenance = 2,
      bool isHotMode = false}) async {
    final settings = await buildSettings();
    final controller = NeverHaveIEverController(
      audioService: buildAudio(),
      settingsProvider: settings,
      rounds: rounds,
      pointsToWin: pointsToWin,
      strikesForPenance: strikesForPenance,
      isHotMode: isHotMode,
    );
    addTearDown(controller.dispose);
    await tester.runAsync(() => controller.initGame());
    return controller;
  }

  group('NeverHaveIEverController — carga', () {
    testWidgets('carga preguntas y la primera pregunta', (tester) async {
      final c = await setup(tester);
      expect(c.isLoading, isFalse);
      expect(c.currentQuestion, isNotNull);
      expect(c.player1Name, kPlayer1);
      expect(c.player2Name, kPlayer2);
      expect(c.roundNumber, 1);
    });

    testWidgets('modo caliente filtra preguntas hot', (tester) async {
      final c = await setup(tester, isHotMode: true);
      expect(c.currentQuestion!.isHot, isTrue);
    });
  });

  group('NeverHaveIEverController — respuestas y revelación', () {
    testWidgets('reveal sin ambas respuestas no hace nada', (tester) async {
      final c = await setup(tester);
      c.answerPlayer1(true);
      c.reveal();
      expect(c.isRevealed, isFalse);
      expect(c.strikesPlayer1 + c.strikesPlayer2, 0);
    });

    testWidgets('respuestas iguales no generan strike', (tester) async {
      final c = await setup(tester);
      c.answerPlayer1(false);
      expect(c.player1Answered, isTrue);
      expect(c.phaseReadyToReveal, isFalse);
      c.answerPlayer2(false);
      expect(c.phaseReadyToReveal, isTrue);

      c.reveal();
      expect(c.isRevealed, isTrue);
      expect(c.disparity, isFalse);
      expect(c.strikesPlayer1, 0);
      expect(c.strikesPlayer2, 0);
      expect(c.scorePlayer1, 0);
      expect(c.scorePlayer2, 0);
    });

    testWidgets('respuestas distintas generan strike y punto al otro',
        (tester) async {
      final c = await setup(tester);
      c.answerPlayer1(true); // dijo sí
      c.answerPlayer2(false); // dijo no
      c.reveal();

      expect(c.disparity, isTrue);
      expect(c.strikePlayerName, kPlayer1);
      expect(c.strikesPlayer1, 1);
      expect(c.scorePlayer2, 1);
    });
  });

  group('NeverHaveIEverController — penitencias y final', () {
    testWidgets('al cruzar strikesForPenance asigna penitencia real',
        (tester) async {
      final c = await setup(tester, strikesForPenance: 1);
      c.answerPlayer1(true);
      c.answerPlayer2(false);
      c.reveal();

      expect(c.strikesPlayer1, 1);
      expect(c.penanceText, isNotNull);
      expect(c.penanceText, isNotEmpty);

      c.clearPenance();
      expect(c.penanceText, isNull);
      expect(c.strikesPlayer1, 0);
      expect(c.strikesPlayer2, 0);
    });

    testWidgets('gana por puntos: nextRound llama onWinner', (tester) async {
      final c = await setup(tester, pointsToWin: 1, rounds: 5);
      String? winner;
      c.onWinner = (name) => winner = name;

      c.answerPlayer1(true);
      c.answerPlayer2(false);
      c.reveal();
      expect(c.scorePlayer2, 1);

      c.nextRound();
      expect(winner, kPlayer2);
    });

    testWidgets('al agotar rondas elige al de mayor puntaje o EMPATE',
        (tester) async {
      final c = await setup(tester, rounds: 1, pointsToWin: 10);
      String? winner;
      c.onWinner = (name) => winner = name;

      c.answerPlayer1(false);
      c.answerPlayer2(false);
      c.reveal();
      c.nextRound();
      expect(winner, 'EMPATE');
    });

    testWidgets('nextRound resetea las respuestas y avanza de ronda',
        (tester) async {
      final c = await setup(tester, rounds: 3, pointsToWin: 10);
      c.answerPlayer1(false);
      c.answerPlayer2(false);
      c.reveal();
      c.nextRound();

      expect(c.roundNumber, 2);
      expect(c.player1Answered, isFalse);
      expect(c.player2Answered, isFalse);
      expect(c.phaseReadyToReveal, isFalse);
      expect(c.isRevealed, isFalse);
      expect(c.currentQuestion, isNotNull);
    });
  });
}