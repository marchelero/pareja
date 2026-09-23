import 'package:flutter_test/flutter_test.dart';
import 'package:pareja/controllers/bomb_controller.dart';

import 'helpers.dart';

void main() {
  Future<BombController> setup(WidgetTester tester,
      {bool isHotMode = false,
      int bestOf = 3,
      int timerSeconds = 5,
      bool optPanic = false,
      bool optGold = false,
      bool optWild = false,
      bool optAccel = false}) async {
    final settings = await buildSettings();
    final controller = BombController(
      audioService: buildAudio(),
      settingsProvider: settings,
      isHotMode: isHotMode,
      bestOf: bestOf,
      timerSeconds: timerSeconds,
      optPanic: optPanic,
      optGold: optGold,
      optWild: optWild,
      optAccel: optAccel,
    );
    addTearDown(controller.dispose);
    await tester.runAsync(() => controller.initGame());
    return controller;
  }

  group('BombController — carga y opciones', () {
    testWidgets('carga categorías reales y calcula puntos a ganar',
        (tester) async {
      final c = await setup(tester, bestOf: 3);
      expect(c.isLoading, isFalse);
      expect(c.currentCategory, isNotNull);
      expect(c.pointsToWin, 2);
      expect(c.activeName, anyOf(kPlayer1, kPlayer2));
      expect(c.isPlaying, isFalse);
      expect(c.isGoldenRound, isFalse); // optGold=false
    });

    testWidgets('modo caliente filtra solo categorías hot', (tester) async {
      final c = await setup(tester, isHotMode: true);
      expect(c.currentCategory!.isHot, isTrue);
    });

    testWidgets('modo normal filtra solo categorías no-hot', (tester) async {
      final c = await setup(tester, isHotMode: false);
      expect(c.currentCategory!.isHot, isFalse);
    });

    testWidgets('optWild entrega comodín al jugador activo', (tester) async {
      final c = await setup(tester, optWild: true);
      expect(c.activeHasWildcard, isTrue);
    });
  });

  group('BombController — turnos y temporizador', () {
    testWidgets('startGame activa el juego y descuenta el tiempo',
        (tester) async {
      final c = await setup(tester, timerSeconds: 5);
      c.startGame();
      expect(c.isPlaying, isTrue);
      expect(c.timeLeft, 5);

      await tester.pump(const Duration(seconds: 2));
      expect(c.timeLeft, 3);
    });

    testWidgets('passTurn resetea el tiempo y cambia de jugador',
        (tester) async {
      final c = await setup(tester, timerSeconds: 5);
      c.startGame();
      await tester.pump(const Duration(seconds: 2));
      expect(c.timeLeft, 3);

      final turnoAntes = c.isHeTurn;
      c.passTurn();
      expect(c.timeLeft, 5);
      expect(c.isHeTurn, !turnoAntes);
    });

    testWidgets('passTurn sin estar jugando no hace nada', (tester) async {
      final c = await setup(tester, timerSeconds: 5);
      expect(c.isPlaying, isFalse);
      final turnoAntes = c.isHeTurn;
      final tiempoAntes = c.timeLeft;
      c.passTurn();
      expect(c.isHeTurn, turnoAntes);
      expect(c.timeLeft, tiempoAntes);
    });

    testWidgets('optAccel recorta el límite en cada passTurn', (tester) async {
      final c = await setup(tester, timerSeconds: 5, optAccel: true);
      c.startGame();
      await tester.pump(const Duration(seconds: 2));
      c.passTurn(); // limite 5.0 -> 4.5 -> timeLeft 5
      expect(c.timeLeft, 5);
      c.passTurn(); // limite 4.5 -> 4.0 -> timeLeft 4
      expect(c.timeLeft, 4);
    });

    testWidgets('useWildcard consume el comodín y cambia de categoría',
        (tester) async {
      final c = await setup(tester, timerSeconds: 5, optWild: true);
      final catAntes = c.currentCategory;
      c.startGame();
      c.useWildcard();
      expect(c.activeHasWildcard, isFalse);
      expect(c.currentCategory!.id, isNot(catAntes!.id));
      expect(c.timeLeft, 5); // el wildcard no reinicia el tiempo

      final catTras = c.currentCategory;
      c.useWildcard(); // sin comodín => ignorado
      expect(c.currentCategory!.id, catTras!.id);
    });

    testWidgets('useWildcard sin comodines activos es un no-op',
        (tester) async {
      final c = await setup(tester, timerSeconds: 5, optWild: false);
      c.startGame();
      final catAntes = c.currentCategory;
      c.useWildcard();
      expect(c.activeHasWildcard, isFalse);
      expect(c.currentCategory!.id, catAntes!.id);
    });

    testWidgets('cancelTimer detiene la cuenta atrás', (tester) async {
      final c = await setup(tester, timerSeconds: 5);
      c.startGame();
      await tester.pump(const Duration(seconds: 2));
      expect(c.timeLeft, 3);
      c.cancelTimer();
      await tester.pump(const Duration(seconds: 5));
      expect(c.timeLeft, 3); // no explotó ni seguía contando
    });
  });

  group('BombController — explosión y callbacks', () {
    testWidgets('la explosión otorga el punto al rival (onRoundResult)',
        (tester) async {
      final c = await setup(tester, bestOf: 5, timerSeconds: 1);
      String? loser;
      int? points;
      String? winner;
      c.onRoundResult = ({required loserName, required pointsEarned}) {
        loser = loserName;
        points = pointsEarned;
      };
      c.onWinner = ({required winnerName, required winnerColor}) =>
          winner = winnerName;

      c.startGame();
      final pierdeHe = c.isHeTurn; // el que tiene el turno explota
      await tester.pump(const Duration(seconds: 2));

      expect(loser, pierdeHe ? kPlayer1 : kPlayer2);
      expect(points, 1);
      if (pierdeHe) {
        expect(c.scoreShe, 1);
      } else {
        expect(c.scoreHe, 1);
      }
      expect(c.isPlaying, isFalse);
      expect(winner, isNull); // bestOf=5 => falta para ganar
    });

    testWidgets('con bestOf=1 la primera explosión termina (onWinner)',
        (tester) async {
      final c = await setup(tester, bestOf: 1, timerSeconds: 1);
      String? winner;
      c.onWinner = ({required winnerName, required winnerColor}) =>
          winner = winnerName;

      c.startGame();
      final pierdeHe = c.isHeTurn;
      await tester.pump(const Duration(seconds: 2));

      expect(winner, pierdeHe ? kPlayer2 : kPlayer1);
      expect(c.scoreHe + c.scoreShe, 1);
    });

    testWidgets('nextRoundAfterDialog arranca una ronda nueva', (tester) async {
      final c = await setup(tester, bestOf: 5, timerSeconds: 1);
      c.startGame();
      await tester.pump(const Duration(seconds: 2));
      expect(c.scoreHe + c.scoreShe, 1);

      final catAntes = c.currentCategory;
      c.nextRoundAfterDialog();
      expect(c.isPlaying, isFalse);
      expect(c.currentCategory, isNotNull);
      expect(c.currentCategory!.id, isNot(catAntes!.id));
      expect(c.scoreHe + c.scoreShe, 1); // no se pierde el marcador
    });
  });
}