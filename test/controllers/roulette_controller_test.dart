import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pareja/controllers/roulette_controller.dart';

import 'helpers.dart';

void main() {
  Future<RouletteController> setup(WidgetTester tester,
      {bool isDareMode = false,
      bool startingPlayerIsP1 = true,
      int rouletteSpinCount = 0}) async {
    final settings = await buildSettings(rouletteSpinCount: rouletteSpinCount);
    final controller = RouletteController(
      audioService: buildAudio(),
      settingsProvider: settings,
      isDareMode: isDareMode,
      startingPlayerIsP1: startingPlayerIsP1,
    );
    addTearDown(controller.dispose);
    await tester.runAsync(() => controller.initGame());
    return controller;
  }

  group('RouletteController — estado inicial', () {
    testWidgets('carga opciones del JSON normal', (tester) async {
      final c = await setup(tester);
      expect(c.isLoading, isFalse);
      expect(c.options.length, 10);
      expect(c.isHeTurn, isTrue);
      expect(c.currentPlayerName, kPlayer1);
      expect(c.isSpinning, isFalse);
      expect(c.selectedIndex, -1);
    });

    testWidgets('startingPlayerIsP1=false hace comenzar a la jugadora 2',
        (tester) async {
      final c = await setup(tester, startingPlayerIsP1: false);
      expect(c.isHeTurn, isFalse);
      expect(c.currentPlayerName, kPlayer2);
    });

    testWidgets('spinCount se precarga desde settings', (tester) async {
      final c = await setup(tester, rouletteSpinCount: 7);
      expect(c.spinCount, 7);
    });
  });

  group('RouletteController — giro', () {
    testWidgets('spin activa isSpinning y bloquea un segundo giro',
        (tester) async {
      final c = await setup(tester);
      c.spin();
      expect(c.isSpinning, isTrue);
      expect(c.result, isNull);

      c.spin(); // reentrada mientras gira => ignorada
      expect(c.isSpinning, isTrue);
      await tester.pump(const Duration(milliseconds: 50));
      expect(c.spinCount, 0); // aun no termino
    });

    testWidgets('onSpinFinished calcula el índice seleccionado (rotación 0)',
        (tester) async {
      final c = await setup(tester);
      int spins = 0;
      c.onSpinComplete = () => spins++;

      c.spin();
      c.onSpinFinished(0);

      expect(c.isSpinning, isFalse);
      expect(c.selectedIndex, 0);
      expect(c.result, c.options[0]);
      expect(c.spinCount, 1);
      expect(spins, 1);
      expect(c.settingsProvider.rouletteSpinCount, 1); // persistido
    });

    testWidgets('onSpinFinished con rotación π apunta a la mitad (índice 5)',
        (tester) async {
      final c = await setup(tester);
      c.spin();
      c.onSpinFinished(pi);
      expect(c.selectedIndex, 5);
      expect(c.result, c.options[5]);
    });
  });

  group('RouletteController — turnos y modos', () {
    testWidgets('formatResultText reemplaza {PAREJA} con el rival',
        (tester) async {
      final c = await setup(tester);
      c.spin();
      c.onSpinFinished(0);
      // En turno de P1 el target es P2.
      expect(c.formatResultText('Toma {PAREJA}'), 'Toma $kPlayer2');

      c.nextTurnFromUI();
      expect(c.isHeTurn, isFalse);
      expect(c.currentPlayerName, kPlayer2);
      expect(c.formatResultText('Toma {PAREJA}'), 'Toma $kPlayer1');
    });

    testWidgets('handleHaptics no hace nada fuera del giro', (tester) async {
      final c = await setup(tester);
      c.handleHaptics(1.0); // sin giro activo
      expect(c.isSpinning, isFalse);

      c.spin();
      c.handleHaptics(0.1); // durante el giro no debe arrojar
      c.onSpinFinished(0);
      expect(c.selectedIndex, 0);
    });

    testWidgets('toggleMode recarga con otro dataset', (tester) async {
      final c = await setup(tester, isDareMode: false);
      c.spin();
      c.onSpinFinished(0);
      expect(c.result, isNotNull);

      await tester.runAsync(() async {
      c.toggleMode(true); // initGame interna arranca en modo fire-and-forget
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
      expect(c.isLoading, isFalse);
      expect(c.options, isNotEmpty);
      expect(c.result, isNull);
      expect(c.selectedIndex, -1);
    });
  });
}