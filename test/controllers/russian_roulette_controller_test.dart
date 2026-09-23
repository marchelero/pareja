import 'package:flutter_test/flutter_test.dart';
import 'package:pareja/controllers/russian_roulette_controller.dart';

import 'helpers.dart';

void main() {
  Future<RussianRouletteController> setup(WidgetTester tester,
      {int bestOf = 3,
      bool wildMode = false,
      int bulletCount = 2}) async {
    final settings = await buildSettings();
    final controller = RussianRouletteController(
      audioService: buildAudio(),
      settingsProvider: settings,
      bestOf: bestOf,
      wildMode: wildMode,
      bulletCount: bulletCount,
    );
    addTearDown(controller.dispose);
    await controller.initGame();
    return controller;
  }

  group('RussianRouletteController — estado inicial', () {
    testWidgets('initGame calcula puntos a ganar y arranca la ronda',
        (tester) async {
      final c = await setup(tester, bestOf: 3);
      expect(c.isLoading, isFalse);
      expect(c.pointsToWin, 2);
      expect(c.roundNumber, 1);
      expect(c.isSpinning, isTrue);
      expect(c.isPlaying, isFalse);
      expect(c.player1Name, kPlayer1);
      expect(c.player2Name, kPlayer2);
      expect(c.triggerPulls, 0);

      c.endSpin();
      expect(c.isSpinning, isFalse);
      expect(c.isPlaying, isTrue);
    });

    testWidgets('pullTrigger sin estar jugando no hace nada', (tester) async {
      final c = await setup(tester);
      c.pullTrigger(); // aun girando / sin endSpin
      expect(c.triggerPulls, 0);
      expect(c.checkedOrder, isEmpty);
    });
  });

  group('RussianRouletteController — wild mode deterministico', () {
    testWidgets('con 6 balas el disparo es BANG garantizado y cierra partida',
        (tester) async {
      final c = await setup(tester, bestOf: 1, wildMode: true, bulletCount: 6);
      expect(c.bulletChambers.length, 6);
      expect(c.bulletChambers.contains(c.firingPinChamber), isTrue);

      String? reportedWinner;
      String? reportedLoser;
      c.onWinner = ({required winnerName, required winnerColor}) {
        reportedWinner = winnerName;
      };
      c.onRoundResult = ({required loserName}) => reportedLoser = loserName;

      c.endSpin();
      final whoPulled = c.isHeTurn;
      c.pullTrigger();

      expect(c.bulletFired, isTrue);
      expect(c.roundOver, isTrue);
      expect(c.isBangResult, isTrue);
      expect(c.isPlaying, isFalse);
      if (whoPulled) {
        expect(c.scoreShe, 1);
      } else {
        expect(c.scoreHe, 1);
      }
      // Un solo tiro accesible despues del bang.
      c.pullTrigger();
      expect(c.triggerPulls, 1);

      await tester.pump(const Duration(milliseconds: 1300));
      expect(c.isBangResult, isFalse);
      expect(reportedWinner, whoPulled ? kPlayer2 : kPlayer1);
      expect(reportedLoser, isNull);
    });

    testWidgets('con 0 balas el disparo es CLICK y no hiere a nadie',
        (tester) async {
      final c = await setup(tester, bestOf: 5, wildMode: true, bulletCount: 0);
      expect(c.bulletChambers, isEmpty);
      expect(c.bulletChambers.contains(c.firingPinChamber), isFalse);

      c.endSpin();
      final whoPulled = c.isHeTurn;
      c.pullTrigger();

      expect(c.isClickResult, isTrue);
      expect(c.bulletFired, isFalse);
      expect(c.roundOver, isFalse);
      expect(c.triggerPulls, 1);
      expect(c.checkedOrder, [c.firingPinChamber]);
      expect(c.scoreHe + c.scoreShe, 0);

      // En wild mode el click NO deja timer pendiente ni re-arma.
      await tester.pump(const Duration(milliseconds: 1300));
      expect(c.isClickResult, isTrue);
      expect(c.isPlaying, isFalse);
      expect(whoPulled ? c.scoreShe : c.scoreHe, 0);

      c.startRespin();
      expect(c.isSpinning, isTrue);
      expect(c.isPlaying, isFalse);
      expect(c.bulletFired, isFalse);
      expect(c.triggerPulls, 0);
    });

    testWidgets('bang en bestOf=5 llama onRoundResult y nextRoundAfterDialog',
        (tester) async {
      final c = await setup(tester, bestOf: 5, wildMode: true, bulletCount: 6);
      String? reportedLoser;
      String? reportedWinner;
      c.onWinner = ({required winnerName, required winnerColor}) {
        reportedWinner = winnerName;
      };
      c.onRoundResult = ({required loserName}) => reportedLoser = loserName;

      c.endSpin();
      final whoPulled = c.isHeTurn;
      c.pullTrigger();

      await tester.pump(const Duration(milliseconds: 1300));
      expect(reportedLoser, whoPulled ? kPlayer1 : kPlayer2);
      expect(reportedWinner, isNull); // aun no hay ganador con bestOf=5

      c.nextRoundAfterDialog();
      expect(c.roundNumber, 2);
      expect(c.roundOver, isFalse);
      expect(c.bulletFired, isFalse);
      expect(c.isSpinning, isTrue);
      expect(c.triggerPulls, 0);
    });
  });

  group('RussianRouletteController — normal mode', () {
    testWidgets('invariantes del disparo (bang o click) con re-arm', (tester) async {
      final c = await setup(tester, bestOf: 5);
      c.endSpin();
      final fpAntes = c.firingPinChamber;
      c.pullTrigger();
      expect(c.triggerPulls, 1);
      expect(c.checkedOrder, [fpAntes]);

      await tester.pump(const Duration(milliseconds: 1300));

      if (c.bulletFired) {
        // BANG: ronda cerrada, punto para el rival.
        expect(c.roundOver, isTrue);
        expect(c.isPlaying, isFalse);
        expect(c.scoreHe + c.scoreShe, 1);
      } else {
        // CLICK: el pin avanza 60° y se re-arma despues de 800ms.
        expect(c.isClickResult, isFalse);
        expect(c.isPlaying, isTrue);
        expect(c.firingPinChamber, (fpAntes + 5) % 6);
        expect(c.roundOver, isFalse);
        expect(c.scoreHe + c.scoreShe, 0);
      }
    });
  });
}