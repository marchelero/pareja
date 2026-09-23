import 'package:flutter_test/flutter_test.dart';
import 'package:pareja/controllers/memory_controller.dart';

import 'helpers.dart';

void main() {
  Future<MemoryController> setup(WidgetTester tester, {int maxRounds = 5}) async {
    final settings = await buildSettings();
    final controller = MemoryController(
      audioService: buildAudio(),
      settingsProvider: settings,
      maxRounds: maxRounds,
    );
    addTearDown(controller.dispose);
    await controller.initGame();
    return controller;
  }

  group('MemoryController — iniciar partida', () {
    testWidgets('initGame carga nombres, colores y puntuación en cero',
        (tester) async {
      final c = await setup(tester);
      expect(c.player1Name, kPlayer1);
      expect(c.player2Name, kPlayer2);
      expect(c.player1Score, 0);
      expect(c.player2Score, 0);
      expect(c.currentRound, 0);
      expect(c.isPlayerTurn, isFalse);
      expect(c.maxRoundsValue, 5);
    });

    testWidgets('setStartingPlayer fija quién empieza', (tester) async {
      final c = await setup(tester);
      c.setStartingPlayer(false);
      expect(c.isHeTurn, isFalse);
      expect(c.activeName, kPlayer2);
      c.setStartingPlayer(true);
      expect(c.isHeTurn, isTrue);
    });

    testWidgets('startRound genera secuencia y muestra el tile',
        (tester) async {
      final c = await setup(tester);
      c.startRound();
      expect(c.currentRound, 1);
      expect(c.sequence.length, 1);
      expect(c.isShowingSequence, isTrue);
      expect(c.isPlayerTurn, isFalse);

      await tester.pump(const Duration(milliseconds: 100));
      expect(c.highlightedButton, c.sequence[0]);
    });

    testWidgets('tras mostrar la secuencia pasa al input del jugador',
        (tester) async {
      final c = await setup(tester);
      c.startRound();
      await tester.pump(const Duration(milliseconds: 650));
      await tester.pump(const Duration(milliseconds: 350));
      expect(c.isShowingSequence, isFalse);
      expect(c.isPlayerTurn, isTrue);
      expect(c.inputIndex, 0);
      expect(c.timeLeft, closeTo(3.0, 0.01));
    });

    testWidgets('tap fuera del turno no hace nada', (tester) async {
      final c = await setup(tester);
      c.startRound();
      // Durante la exhibicion no es turno del jugador.
      c.playerTap(0);
      expect(c.inputIndex, 0);
      expect(c.currentLevel, 1);
    });
  });

  group('MemoryController — success', () {
    testWidgets('tap correcto sube de nivel y cambia de jugador',
        (tester) async {
      final c = await setup(tester);
      c.startRound();
      await tester.pump(const Duration(milliseconds: 650));
      await tester.pump(const Duration(milliseconds: 350));

      final right = c.sequence[0];
      c.playerTap(right);

      expect(c.inputIndex, 1);
      expect(c.currentLevel, 2);
      expect(c.isPlayerTurn, isFalse);
      expect(c.isHeTurn, isFalse); // cambio de jugador tras exito
      expect(c.isGameOver, isFalse);
    });

    testWidgets('tras 1.4s el nivel siguiente empieza a mostrarse',
        (tester) async {
      final c = await setup(tester);
      c.startRound();
      await tester.pump(const Duration(milliseconds: 650));
      await tester.pump(const Duration(milliseconds: 350));
      c.playerTap(c.sequence[0]);

      await tester.pump(const Duration(milliseconds: 1500));
      expect(c.sequence.length, 2);
      expect(c.isShowingSequence, isTrue);
      expect(c.currentLevel, 2);
    });
  });

  group('MemoryController — mistake / finish', () {
    testWidgets('tap incorrecto pierde la ronda y termina la partida',
        (tester) async {
      final c = await setup(tester, maxRounds: 1);
      String? reportedLoser;
      ({String winnerName, String loserName})? finished;
      c.onRoundLost = ({required loserName}) => reportedLoser = loserName;
      c.onGameFinished = ({required winnerName, required loserName}) =>
          finished = (winnerName: winnerName, loserName: loserName);

      c.startRound();
      await tester.pump(const Duration(milliseconds: 650));
      await tester.pump(const Duration(milliseconds: 350));

      final wrong = (c.sequence[0] + 1) % 4;
      c.playerTap(wrong);

      // El perdedor (P1, turno inicial) cede un punto al rival.
      expect(c.player2Score, 1);
      expect(c.player1Score, 0);
      expect(reportedLoser, kPlayer1);
      expect(c.isGameOver, isTrue);

      await tester.pump(const Duration(milliseconds: 600));
      expect(finished, isNotNull);
      expect(finished!.winnerName, kPlayer2);
      expect(finished!.loserName, kPlayer1);
    });

    testWidgets('timeout pierde la ronda y reparte el punto', (tester) async {
      final c = await setup(tester, maxRounds: 1);
      String? reportedLoser;
      ({String winnerName, String loserName})? finished;
      c.onRoundLost = ({required loserName}) => reportedLoser = loserName;
      c.onGameFinished = ({required winnerName, required loserName}) =>
          finished = (winnerName: winnerName, loserName: loserName);

      c.startRound();
      await tester.pump(const Duration(milliseconds: 650));
      await tester.pump(const Duration(milliseconds: 350));

      // El input timer otorga 3.0s; pasan 3.1s => timeout.
      await tester.pump(const Duration(milliseconds: 3100));

      expect(c.timeLeft, 0);
      expect(c.player2Score, 1);
      expect(reportedLoser, kPlayer1);

      await tester.pump(const Duration(milliseconds: 600));
      expect(finished!.winnerName, kPlayer2);
    });

    testWidgets('startNextRound abre ronda nueva con turno invertido',
        (tester) async {
      final c = await setup(tester);
      c.startRound();
      c.startNextRound();
      expect(c.currentRound, 2);
      expect(c.currentLevel, 1);
      expect(c.sequence.length, 1);
      expect(c.isHeTurn, isFalse); // empezo P1, startNextRound invierte
      expect(c.isGameOver, isFalse);
    });
  });
}