import 'package:flutter_test/flutter_test.dart';
import 'package:pareja/controllers/charades_controller.dart';

import 'helpers.dart';

void main() {
  Future<CharadesController> setup(WidgetTester tester,
      {List<String> selectedCategories = const ['peliculas'],
      bool singleCategoryMode = false,
      int timerSeconds = 5,
      int pointsToWin = 3,
      int strikesForPenance = 3,
      bool isHotMode = false}) async {
    final settings = await buildSettings();
    final controller = CharadesController(
      audioService: buildAudio(),
      settingsProvider: settings,
      selectedCategories: selectedCategories,
      singleCategoryMode: singleCategoryMode,
      timerSeconds: timerSeconds,
      pointsToWin: pointsToWin,
      strikesForPenance: strikesForPenance,
      isHotMode: isHotMode,
    );
    addTearDown(controller.dispose);
    await tester.runAsync(() => controller.initGame());
    return controller;
  }

  group('CharadesController — carga y palabras', () {
    testWidgets('carga palabras reales y filtra la categoría seleccionada',
        (tester) async {
      final c = await setup(tester);
      expect(c.isLoading, isFalse);
      c.showNewWord();
      expect(c.currentWord, isNotNull);
      expect(c.currentWord!.category, 'peliculas');
      expect(c.currentWord!.isHot, isFalse); // modo no caliente
      expect(c.currentPlayerName, kPlayer1);
      expect(c.partnerName, kPlayer2);
    });

    testWidgets('singleCategoryMode restringe a una sola categoría',
        (tester) async {
      final c = await setup(tester,
          selectedCategories: const ['peliculas', 'musica'],
          singleCategoryMode: true);
      c.showNewWord();
      expect(c.currentWord, isNotNull);
      expect(
        const ['peliculas', 'musica'].contains(c.currentWord!.category),
        isTrue,
      );
    });

    testWidgets('showNewWord limpia el estado de la ronda anterior',
        (tester) async {
      final c = await setup(tester);
      c.showNewWord();
      c.startTurn();
      c.guessCorrect();
      expect(c.roundDone, isTrue);

      c.showNewWord();
      expect(c.roundDone, isFalse);
      expect(c.wasGuessed, isFalse);
      expect(c.isPlaying, isFalse);
      expect(c.turnReady, isFalse);
    });
  });

  group('CharadesController — turnos', () {
    testWidgets('startTurn activa el turno y cuenta regresiva',
        (tester) async {
      final c = await setup(tester, timerSeconds: 5);
      c.showNewWord();
      c.startTurn();
      expect(c.turnReady, isTrue);
      expect(c.isPlaying, isTrue);
      expect(c.timeLeft, 5);

      await tester.pump(const Duration(seconds: 2));
      expect(c.timeLeft, 3);
    });

    testWidgets('guessCorrect suma punto al jugador activo', (tester) async {
      final c = await setup(tester, pointsToWin: 3);
      c.showNewWord();
      final turnoHe = c.isHeTurn;
      c.startTurn();
      c.guessCorrect();
      expect(c.wasGuessed, isTrue);
      expect(c.roundDone, isTrue);
      expect(c.isPlaying, isFalse);
      if (turnoHe) {
        expect(c.scoreHe, 1);
      } else {
        expect(c.scoreShe, 1);
      }
    });

    testWidgets('timeout termina la ronda sin punto y cancela el timer',
        (tester) async {
      final c = await setup(tester, timerSeconds: 2);
      c.showNewWord();
      c.startTurn();
      await tester.pump(const Duration(seconds: 3));
      expect(c.roundDone, isTrue);
      expect(c.wasGuessed, isFalse);
      expect(c.isPlaying, isFalse);
      expect(c.scoreHe + c.scoreShe, 0);
    });

    testWidgets('cancelTimer detiene la cuenta sin timeout', (tester) async {
      final c = await setup(tester, timerSeconds: 2);
      c.showNewWord();
      c.startTurn();
      c.cancelTimer();
      await tester.pump(const Duration(seconds: 5));
      expect(c.roundDone, isFalse);
      expect(c.isPlaying, isTrue);
    });
  });

  group('CharadesController — penitencias y winner', () {
    testWidgets('clearPenance resetea la penitencia sin arrojar',
        (tester) async {
      final c = await setup(tester, strikesForPenance: 1);
      c.clearPenance();
      expect(c.penanceText, isNull);
      expect(c.strikesHe, 0);
      expect(c.strikesShe, 0);
    });

    testWidgets('el timeout aplica strikes según regla aleatoria',
        (tester) async {
      final c = await setup(tester, timerSeconds: 1, strikesForPenance: 3);
      c.showNewWord();
      c.startTurn();
      await tester.pump(const Duration(seconds: 2));
      expect(c.roundDone, isTrue);
      // Las strikes aleatorias (0, P1, P2 o ambos) respetan el rango.
      expect(c.strikesHe, inInclusiveRange(0, 1));
      expect(c.strikesShe, inInclusiveRange(0, 1));

      c.clearPenance();
      expect(c.penanceText, isNull);
      expect(c.strikesHe, 0);
      expect(c.strikesShe, 0);
    });

    testWidgets('al llegar al match point y ganar llama onGameWinner',
        (tester) async {
      final c = await setup(tester, pointsToWin: 1);
      String? winner;
      c.onGameWinner = (name) => winner = name;

      // P1 adivina => match point para P1.
      c.showNewWord();
      c.startTurn();
      c.guessCorrect();
      expect(c.scoreHe, 1);

      // P2 recibe palabra nueva (no se cierra todavia).
      c.nextRound();
      expect(c.winner, isNull);
      expect(c.currentPlayerName, kPlayer2);
      expect(c.currentWord, isNotNull);

      // Al volver el turno a P1 con ventaja se cierra la partida.
      c.nextRound();
      expect(c.winner, kPlayer1);
      expect(winner, kPlayer1);
    });

    testWidgets('el match point igualado continúa en vez de cerrar',
        (tester) async {
      final c = await setup(tester, pointsToWin: 1);
      String? winner;
      c.onGameWinner = (name) => winner = name;

      c.showNewWord();
      c.startTurn();
      c.guessCorrect(); // P1: 1 punto
      c.nextRound(); // turno de P2

      c.showNewWord();
      c.startTurn();
      c.guessCorrect(); // P2: 1 punto -> empate
      expect(c.scoreShe, 1);

      c.nextRound(); // turno de P1, match point igualado
      expect(c.winner, isNull);
      expect(winner, isNull);
      expect(c.currentWord, isNotNull); // la partida sigue
    });
  });
}