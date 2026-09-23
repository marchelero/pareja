import 'package:flutter_test/flutter_test.dart';
import 'package:pareja/controllers/duel_controller.dart';

import 'helpers.dart';

void main() {
  Future<DuelController> setup(WidgetTester tester, {int maxRounds = 10}) async {
    final settings = await buildSettings();
    final controller = DuelController(
      audioService: buildAudio(),
      settingsProvider: settings,
      maxRounds: maxRounds,
    );
    await tester.runAsync(() => controller.initGame());
    return controller;
  }

  group('DuelController — estado inicial y afirmaciones', () {
    testWidgets('carga retos reales del JSON', (tester) async {
      final c = await setup(tester);
      expect(c.isLoading, isFalse);
      expect(c.allTasks, isNotEmpty);
      expect(c.currentTask, isNotNull);
      expect(c.currentRound, 1);
      expect(c.isGameOver, isFalse);
      expect(c.player1Name, kPlayer1);
      expect(c.player2Name, kPlayer2);
    });

    testWidgets('claimHe suma punto y avanza de ronda', (tester) async {
      final c = await setup(tester);
      c.claimHe();
      expect(c.player1Score, 1);
      expect(c.player2Score, 0);
      expect(c.lastWinner, kPlayer1);
      expect(c.currentRound, 2);
    });

    testWidgets('claimShe suma punto al otro jugador', (tester) async {
      final c = await setup(tester);
      c.claimShe();
      expect(c.player2Score, 1);
      expect(c.lastWinner, kPlayer2);
    });

    testWidgets('skipTask no puntúa y deja lastWinner nulo', (tester) async {
      final c = await setup(tester);
      c.skipTask();
      expect(c.player1Score, 0);
      expect(c.player2Score, 0);
      expect(c.lastWinner, isNull);
      expect(c.currentRound, 2);
    });
  });

  group('DuelController — fin de partida', () {
    testWidgets('al agotar rondas llama onGameFinished con el ganador',
        (tester) async {
      final c = await setup(tester, maxRounds: 2);
      String? winner;
      String? loser;
      c.onGameFinished = ({required winnerName, required loserName}) {
        winner = winnerName;
        loser = loserName;
      };

      c.claimHe();
      c.claimHe();
      expect(c.isGameOver, isTrue);
      expect(winner, kPlayer1);
      expect(loser, kPlayer2);
    });

    testWidgets('EMPATE si nadie puntúa', (tester) async {
      final c = await setup(tester, maxRounds: 1);
      String? winner;
      c.onGameFinished = ({required winnerName, required loserName}) {
        winner = winnerName;
      };
      c.skipTask();
      expect(c.isGameOver, isTrue);
      expect(winner, 'EMPATE');
    });

    testWidgets('los empates en puntuación reportan EMPATE', (tester) async {
      final c = await setup(tester, maxRounds: 3);
      String? winner;
      c.onGameFinished = ({required winnerName, required loserName}) {
        winner = winnerName;
      };
      c.claimHe();
      c.claimShe();
      expect(winner, isNull); // ronda 3 en curso... 
      c.skipTask();
      expect(c.isGameOver, isTrue);
      expect(winner, 'EMPATE'); // 1-1 tras 3 rondas
    });
  });
}