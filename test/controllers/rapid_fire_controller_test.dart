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
    // NOTA: initGame() carga el JSON via rootBundle (exige runAsync) y de paso
    // crea el buzz timer como Timer REAL de 50ms. Por eso cada test termina
    // llamando controller.dispose() EN EL CUERPO (cancela buzz/input/next
    // timers): el check de flutter_test contra timers pendientes corre ANTES
    // que addTearDown, y un timer real no responde a los pump() de la zona
    // fake. Solo buzz()/selectAnswer()/dispose() lo detienen.
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
      c.dispose();
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
      // _rebuildAvailable repuebla desde _allQuestions (restaura la pregunta
      // que initGame ya habia consumido) => totalAntes + 1.
      expect(c.totalQuestions, totalAntes + 1);
      c.dispose();
    });

    testWidgets('selectAnswer en idle no hace nada', (tester) async {
      final c = await setup(tester);
      final idx = c.correctAnswerIndex;
      c.selectAnswer(idx);
      expect(c.state, RapidFireState.idle);
      expect(c.player1Score, 0);
      expect(c.player2Score, 0);
      c.dispose();
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
      c.dispose();
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
      c.dispose();
    });

    testWidgets('respuesta incorrecta da el punto al rival', (tester) async {
      final c = await setup(tester, targetScore: 10);
      c.buzz('she');
      final wrong = (c.correctAnswerIndex + 1) % 4;
      c.selectAnswer(wrong);
      expect(c.state, RapidFireState.showingResult);
      expect(c.player2Score, 0);
      expect(c.player1Score, 1);
      c.dispose();
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
      c.dispose();
    });
  });

  group('RapidFireController — timeouts', () {
    testWidgets('timeout de respuesta reparte el punto y termina',
        (tester) async {
      final c = await setup(tester, targetScore: 1);
      String? winner;
      String? loser;
      c.onGameFinished = ({required winnerName, required loserName}) {
        winner = winnerName;
        loser = loserName;
      };

      // NOTA: el buzzer real de initGame no responde a pump() (zona fake).
      // Se entra al input timer con un buzz explicito: es un timer fake, y
      // expira con pump(6s) > los 5.0s asignados.
      c.buzz('he');
      await tester.pump(const Duration(seconds: 6));
      expect(c.state, RapidFireState.showingResult);
      expect(c.player1Score + c.player2Score, 1); // he timeout => +1 she

      await tester.pump(const Duration(milliseconds: 2100));
      expect(c.state, RapidFireState.finished);
      expect(winner, isNotNull);
      expect(winner, c.player1Score > c.player2Score ? kPlayer1 : kPlayer2);
      expect(loser, winner == kPlayer1 ? kPlayer2 : kPlayer1);
      c.dispose();
    });
  });
}