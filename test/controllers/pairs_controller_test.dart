import 'package:flutter_test/flutter_test.dart';
import 'package:pareja/controllers/pairs_controller.dart';

import 'helpers.dart';

void main() {
  Future<PairsController> setup(WidgetTester tester, {int maxRounds = 3}) async {
    final settings = await buildSettings();
    final controller = PairsController(
      audioService: buildAudio(),
      settingsProvider: settings,
      maxRounds: maxRounds,
      gridRows: 4,
      gridCols: 5,
    );
    addTearDown(controller.dispose);
    await controller.initGame();
    return controller;
  }

  List<int> indicesOfPair(PairsController c, int pairId) {
    return [
      for (var i = 0; i < c.cards.length; i++)
        if (c.cards[i].pairId == pairId && !c.cards[i].isMatched) i,
    ];
  }

  Future<void> matchPair(WidgetTester tester, PairsController c, int pairId) async {
    final idx = indicesOfPair(c, pairId);
    expect(idx.length, 2);
    c.selectCard(idx[0]);
    c.selectCard(idx[1]);
    expect(c.isChecking, isTrue);
    await tester.pump(const Duration(milliseconds: 500));
    expect(c.isChecking, isFalse);
  }

  group('PairsController — tablero', () {
    testWidgets('initGame crea 20 cartas en 10 pares', (tester) async {
      final c = await setup(tester);
      expect(c.cards.length, 20);
      expect(c.totalPairs, 10);
      expect(c.matchedPairs, 0);
      expect(c.currentRound, 1);
      expect(c.isLoading, isFalse);
      expect(c.isGameOver, isFalse);
      expect(c.player1Name, kPlayer1);
      expect(c.player2Name, kPlayer2);
      expect(c.isPlayer1Turn, isTrue);
    });

    testWidgets('setStartingPlayer define quién empieza', (tester) async {
      final c = await setup(tester);
      c.setStartingPlayer(false);
      expect(c.isPlayer1Turn, isFalse);
    });

    testWidgets('voltear la misma carta dos veces es ignorado', (tester) async {
      final c = await setup(tester);
      c.selectCard(0);
      c.selectCard(0); // ya está volteada
      expect(c.isChecking, isFalse);
      expect(c.cards[0].isFlipped, isTrue);
      await tester.pump(const Duration(milliseconds: 500));
      expect(c.player1Score, 0);
    });
  });

  group('PairsController — pares', () {
    testWidgets('acertar una pareja puntúa y NO cambia el turno',
        (tester) async {
      final c = await setup(tester);
      final pairId = c.cards[0].pairId;
      await matchPair(tester, c, pairId);

      expect(c.cards[0].isMatched, isTrue);
      expect(c.player1Score, 1);
      expect(c.player2Score, 0);
      expect(c.isPlayer1Turn, isTrue); // se mantiene tras acierto
      expect(c.matchedPairs, 1);
    });

    testWidgets('fallar una pareja voltea de nuevo y cambia el turno',
        (tester) async {
      final c = await setup(tester);
      // Buscar dos cartas de pares distintos.
      final idxA = 0;
      int idxB = 1;
      while (c.cards[idxB].pairId == c.cards[idxA].pairId) {
        idxB++;
      }
      c.selectCard(idxA);
      c.selectCard(idxB);
      expect(c.isChecking, isTrue);

      await tester.pump(const Duration(milliseconds: 1000));
      expect(c.cards[idxA].isFlipped, isFalse);
      expect(c.cards[idxB].isFlipped, isFalse);
      expect(c.isPlayer1Turn, isFalse); // se cambia el turno tras error
      expect(c.player1Score, 0);
      expect(c.player2Score, 0);
    });
  });

  group('PairsController — fin de partida y rondas', () {
    testWidgets('completar el tablero con maxRounds=1 termina la partida',
        (tester) async {
      final c = await setup(tester, maxRounds: 1);
      for (var p = 0; p < 10; p++) {
        await matchPair(tester, c, p);
      }
      expect(c.matchedPairs, 10);
      expect(c.isGameOver, isTrue);
      expect(c.lastRoundWinner, kPlayer1);
      expect(c.player1Score, 10);
      expect(c.player2Score, 0);
    });

    testWidgets('roundEnded habilita continueToNextRound', (tester) async {
      final c = await setup(tester, maxRounds: 2);
      for (var p = 0; p < 10; p++) {
        await matchPair(tester, c, p);
      }
      expect(c.isGameOver, isFalse);
      expect(c.roundEnded, isTrue);

      c.continueToNextRound();
      expect(c.roundEnded, isFalse);
      expect(c.currentRound, 2);
      expect(c.cards.length, 20);
      expect(c.player1Score, 0);
      expect(c.player2Score, 0);
      expect(c.matchedPairs, 0);
    });

    testWidgets('con maxRounds=2 la segunda ronda completa cierra la partida',
        (tester) async {
      final c = await setup(tester, maxRounds: 2);
      for (var p = 0; p < 10; p++) {
        await matchPair(tester, c, p);
      }
      c.continueToNextRound();
      for (var p = 0; p < 10; p++) {
        await matchPair(tester, c, p);
      }
      expect(c.isGameOver, isTrue);
      expect(c.player1Rounds, 2);
    });
  });
}