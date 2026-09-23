import 'package:flutter/material.dart' show Icons;
import 'package:flutter_test/flutter_test.dart';
import 'package:pareja/controllers/premiado_controller.dart';

import 'helpers.dart';

void main() {
  Future<PremiadoController> setup(WidgetTester tester,
      {int pointsToWin = 2}) async {
    final settings = await buildSettings();
    final controller = PremiadoController(
      audioService: buildAudio(),
      settingsProvider: settings,
      pointsToWin: pointsToWin,
    );
    addTearDown(controller.dispose);
    await controller.initGame();
    return controller;
  }

  group('PremiadoController — estado inicial', () {
    testWidgets('initGame carga nombres, colores e iconos', (tester) async {
      final c = await setup(tester);
      expect(c.player1Name, kPlayer1);
      expect(c.player2Name, kPlayer2);
      expect(c.player1Color, c.settingsProvider.player1Color);
      expect(c.player2Color, c.settingsProvider.player2Color);
      expect(c.player1Icon, Icons.male);
      expect(c.player2Icon, Icons.female);
      expect(c.scoreP1, 0);
      expect(c.scoreP2, 0);
      expect(c.hasWinner, isFalse);
      expect(c.winnerIndex, -1);
    });

    testWidgets('setStartingPlayer no existe, el turno lo gestiona el UI',
        (tester) async {
      // Premiado es trivial: los puntos se reparten por botón.
      final c = await setup(tester);
      expect(c.scoreP1, 0);
    });
  });

  group('PremiadoController — puntuación', () {
    testWidgets('incrementP1 llega a la meta con pointsToWin=2',
        (tester) async {
      final c = await setup(tester);
      c.incrementP1();
      expect(c.scoreP1, 1);
      expect(c.hasWinner, isFalse);

      c.incrementP1();
      expect(c.scoreP1, 2);
      expect(c.hasWinner, isTrue);
      expect(c.winnerIndex, 0);
    });

    testWidgets('incrementP2 hace ganar al segundo jugador', (tester) async {
      final c = await setup(tester);
      c.incrementP2();
      c.incrementP2();
      expect(c.hasWinner, isTrue);
      expect(c.winnerIndex, 1);
    });

    testWidgets('pointsToWin custom', (tester) async {
      final c = await setup(tester, pointsToWin: 3);
      c.incrementP1();
      c.incrementP1();
      expect(c.hasWinner, isFalse);
      c.incrementP1();
      expect(c.hasWinner, isTrue);
    });

    testWidgets('resetScores vuelve a cero', (tester) async {
      final c = await setup(tester);
      c.incrementP1();
      c.incrementP2();
      c.incrementP2();
      expect(c.hasWinner, isTrue);

      c.resetScores();
      expect(c.scoreP1, 0);
      expect(c.scoreP2, 0);
      expect(c.hasWinner, isFalse);
      expect(c.winnerIndex, -1);
    });
  });
}