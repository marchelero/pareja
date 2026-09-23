import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pareja/controllers/atiempo_controller.dart';

import 'helpers.dart';

void main() {
  Future<ATiempoController> setup(WidgetTester tester,
      {int pointsPerRound = 3,
      int matchRounds = 3,
      double targetTime = 10.0,
      bool wildMode = false}) async {
    final settings = await buildSettings();
    final controller = ATiempoController(
      audioService: buildAudio(),
      settingsProvider: settings,
      pointsPerRound: pointsPerRound,
      matchRounds: matchRounds,
      targetTime: targetTime,
      wildMode: wildMode,
    );
    addTearDown(controller.dispose);
    controller.initGame();
    return controller;
  }

  /// Juega el turno de un jugador esperando tiempo REAL (el Stopwatch del
  /// controller es real, no sujeta al reloj falso de flutter_test).
  Future<void> posicionarTurno(WidgetTester tester, ATiempoController c,
      Duration espera) async {
    c.startTimer();
    await Future<void>.delayed(espera);
    c.stopTimer();
  }

  group('ATiempoController — estado inicial', () {
    testWidgets('initGame carga nombres, colores e iconos', (tester) async {
      final c = await setup(tester);
      expect(c.player1Name, kPlayer1);
      expect(c.player2Name, kPlayer2);
      expect(c.player1Icon, Icons.male);
      expect(c.player2Icon, Icons.female);
      expect(c.currentRound, 1);
      expect(c.phase, ATiempoPhase.waitingTurn);
      expect(c.p1Points, 0);
      expect(c.p2Points, 0);
      expect(c.currentTarget, 10.0);
    });

    testWidgets('setStartingPlayer y startTimer/stopTimer transicionan fase',
        (tester) async {
      final c = await setup(tester);
      c.setStartingPlayer(false);
      expect(c.isPlayer1Turn, isFalse);

      c.startTimer();
      expect(c.phase, ATiempoPhase.running);
      c.stopTimer();
      expect(c.phase, ATiempoPhase.turnDone);
      expect(c.p2Time, isNotNull); // jugador 2 grabo su tiempo

      c.startNextTurn(resetMatch: true);
      expect(c.phase, ATiempoPhase.waitingTurn);
      expect(c.currentTime, 0.0);
      expect(c.p1Time, isNull);
      expect(c.p2Time, isNull);
    });

    testWidgets('evaluateComparison sin ambos tiempos no hace nada',
        (tester) async {
      final c = await setup(tester);
      c.startTimer();
      c.stopTimer();
      expect(c.p1Time, isNotNull);
      expect(c.p2Time, isNull);

      c.evaluateComparison();
      expect(c.phase, ATiempoPhase.turnDone);
      expect(c.winnerName, isNull);
      expect(c.p1Points, 0);
    });

    testWidgets('wild mode genera target entre 1 y 10', (tester) async {
      final c = await setup(tester, wildMode: true);
      expect(c.currentTarget, inInclusiveRange(1.0, 10.0));
    });
  });

  group('ATiempoController — comparación con tiempos reales', () {
    testWidgets('el más cercano al target gana la ronda', (tester) async {
      final c = await setup(tester, targetTime: 0.5, pointsPerRound: 3);

      await tester.runAsync(() async {
        // P1 para en 0.10 (a 0.40 del target), P2 en 0.40 (a 0.10) => gana P2.
        await posicionarTurno(tester, c, const Duration(milliseconds: 100));
        c.startNextTurn();
        await posicionarTurno(tester, c, const Duration(milliseconds: 400));
        c.evaluateComparison();
      });

      expect(c.winnerName, kPlayer2);
      expect(c.p2Points, 1);
      expect(c.p1Points, 0);
      expect(c.roundPointsAwarded, 1);
      expect(c.phase, ATiempoPhase.bothDone); // nadie llega a 3 puntos
    });

    testWidgets('winnerName y puntos para el jugador 1', (tester) async {
      final c = await setup(tester, targetTime: 0.5, pointsPerRound: 3);

      await tester.runAsync(() async {
        // P1 para en 0.60 (a 0.10 del target), P2 en 0.10 (a 0.40) => gana P1.
        await posicionarTurno(tester, c, const Duration(milliseconds: 600));
        c.startNextTurn();
        await posicionarTurno(tester, c, const Duration(milliseconds: 100));
        c.evaluateComparison();
      });

      expect(c.winnerName, kPlayer1);
      expect(c.p1Points, 1);
      expect(c.p2Points, 0);
    });
  });

  group('ATiempoController — partida y rondas', () {
    testWidgets('llega a roundOver y luego a matchOver', (tester) async {
      final c = await setup(tester,
          targetTime: 0.5, pointsPerRound: 1, matchRounds: 3);

      Future<void> rondaConGanadorP1() async {
        c.startTimer();
        await Future<void>.delayed(const Duration(milliseconds: 600));
        c.stopTimer();
        c.startNextTurn();
        c.startTimer();
        await Future<void>.delayed(const Duration(milliseconds: 100));
        c.stopTimer();
        c.evaluateComparison();
      }

      await tester.runAsync(() => rondaConGanadorP1());
      expect(c.winnerName, kPlayer1);
      expect(c.p1Points, 1);
      expect(c.phase, ATiempoPhase.roundOver); // 1 ronda ganada de 2 necesarias
      expect(c.p1Rounds, 1);
      expect(c.isMatchP1Winner, isFalse);

      c.startNewRound();
      expect(c.p1Points, 0);
      expect(c.p2Points, 0);
      expect(c.currentRound, 2);

      await tester.runAsync(() => rondaConGanadorP1());
      expect(c.phase, ATiempoPhase.matchOver);
      expect(c.p1Rounds, 2);
      expect(c.isMatchP1Winner, isTrue);
    });

    testWidgets('resetGame vuelve al estado inicial', (tester) async {
      final c = await setup(tester, targetTime: 0.5, pointsPerRound: 1);
      c.setStartingPlayer(false);
      await tester.runAsync(() async {
        c.startTimer();
        await Future<void>.delayed(const Duration(milliseconds: 600));
        c.stopTimer();
        c.startNextTurn();
        c.startTimer();
        await Future<void>.delayed(const Duration(milliseconds: 100));
        c.stopTimer();
        c.evaluateComparison();
      });
      expect(c.p1Points, 1);

      c.resetGame();
      expect(c.phase, ATiempoPhase.waitingTurn);
      expect(c.p1Points, 0);
      expect(c.p2Points, 0);
      expect(c.p1Rounds, 0);
      expect(c.p2Rounds, 0);
      expect(c.currentRound, 1);
      expect(c.winnerName, isNull);
    });
  });
}