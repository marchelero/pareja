import 'package:flutter_test/flutter_test.dart';
import 'package:pareja/controllers/rapid_fire_controller.dart';

import 'helpers.dart';

void main() {
  Future<RapidFireController> setup(WidgetTester tester,
      {int targetScore = 10}) async {
    final settings = await buildSettings();
    final controller = RapidFireController(
      audioService: buildAudio(),
      settingsProvider: settings,
      targetScore: targetScore,
    );
    addTearDown(controller.dispose);
    await tester.runAsync(() => controller.initGame());
    return controller;
  }

  group('RapidFireController — carga y filtros', () {
    testWidgets('carga preguntas reales del JSON', (tester) async {
      final c = await setup(tester);
      expect(c.state, RapidFireState.idle);
      expect(c.currentQuestion, isNotNull);
      expect(c.allCategories, isNotEmpty);
      expect(c.selectedCategories, c.allCategories);
      expect(c.totalQuestions, greaterThan(0));
      expect(c.player1Name, kPlayer1);
      expect(c.player2Name, kPlayer2);
      expect(c.questionIndex, 1);
    });

    testWidgets('setSelectedCategories filtra las preguntas disponibles',
        (tester) async {
      final c = await setup(tester);
      final totalAntes = c.totalQuestions;
      c.setSelectedCategories({'Geografía'});
      expect(c.selectedCategories, {'Geografía'});
      expect(c.totalQuestions, lessThan(totalAntes));
      expect(c.totalQuestions, greaterThan(0));

      c.setSelectedCategories({});
      expect(c.selectedCategories, isEmpty);
      expect(c.totalQuestions, totalAntes);
    });

    testWidgets('selectAnswer en idle no hace nada', (tester) async {
      final c = await setup(tester);
      final idx = c.correctAnswerIndex;
      c.selectAnswer(idx);
      expect(c.state, RapidFireState.idle);
      expect(c.player1Score, 0);
      expect(c.player2Score, 0);
    });
  });

  group('RapidFireController — buzz y respuestas', () {
    testWidgets('buzz fija al jugador y bloquea un segundo buzz',
        (tester) async {
      final c = await setup(tester);
      c.buzz('he');
      expect(c.state, RapidFireState.buzzed);
      expect(c.buzzerPlayer, 'he');
      expect(c.isHeTurn, isTrue);

      c.buzz('she'); // re-buzz en estado buzzed => ignorado
      expect(c.buzzerPlayer, 'he');
    });

    testWidgets('respuesta correcta puntúa y avanza a la siguiente pregunta',
        (tester) async {
      final c = await setup(tester);
      c.buzz('he');
      final right = c.correctAnswerIndex;
      c.selectAnswer(right);
      expect(c.state, RapidFireState.showingResult);
      expect(c.player1Score, 1);
      expect(c.player2Score, 0);
      expect(c.lastCorrectAnswer, isNotNull);

      await tester.pump(const Duration(milliseconds: 2100));
      expect(c.state, RapidFireState.idle);
      expect(c.questionIndex, 2);
    });

    testWidgets('respuesta incorrecta da el punto al rival', (tester) async {
      final c = await setup(tester, targetScore: 10);
      c.buzz('she');
      final wrong = (c.correctAnswerIndex + 1) % 4;
      c.selectAnswer(wrong);
      expect(c.state, RapidFireState.showingResult);
      expect(c.player2Score, 0);
      expect(c.player1Score, 1);
    });

    testWidgets('ronda completa llama onGameFinished con targetScore=1',
        (tester) async {
      final c = await setup(tester, targetScore: 1);
      String? winner;
      String? loser;
      c.onGameFinished = ({required winnerName, required loserName}) {
        winner = winnerName;
        loser = loserName;
      };

      c.buzz('he');
      c.selectAnswer(c.correctAnswerIndex);
      expect(c.player1Score, 1); // ya llega al target

      await tester.pump(const Duration(milliseconds: 2100));
      expect(c.state, RapidFireState.finished);
      expect(c.isGameOver, isTrue);
      expect(winner, kPlayer1);
      expect(loser, kPlayer2);
    });
  });

  group('RapidFireController — timeouts', () {
    testWidgets('timeout de buzz y de respuesta reparte el punto y termina',
        (tester) async {
      final c = await setup(tester, targetScore: 1);
      String? winner;
      String? loser;
      c.onGameFinished = ({required winnerName, required loserName}) {
        winner = winnerName;
        loser = loserName;
      };

      // Sin pulsar nada: el buzz timer expira a los 10s.
      await tester.pump(const Duration(seconds: 11));
      expect(c.state, RapidFireState.buzzed);
      expect(c.buzzerPlayer, isNotNull);

      // El timer de respuesta expira a los 5s y le da el punto a "he"/"she".
      await tester.pump(const Duration(seconds: 6));
      expect(c.state, RapidFireState.showingResult);
      expect(c.player1Score + c.player2Score, 1);

      await tester.pump(const Duration(milliseconds: 2100));
      expect(c.state, RapidFireState.finished);
      expect(winner, isNotNull);
      // El ganador es quien tiene el punto.
      expect(winner, c.player1Score > c.player2Score ? kPlayer1 : kPlayer2);
      expect(loser, winner == kPlayer1 ? kPlayer2 : kPlayer1);
    });
  });
}