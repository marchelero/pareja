import 'package:flutter_test/flutter_test.dart';
import 'package:pareja/controllers/questions_controller.dart';
import 'package:pareja/core/models/player.dart';
import 'package:pareja/core/models/question.dart';
import 'package:pareja/data/questions_repository.dart';

import 'helpers.dart';

class _FakeRepo extends QuestionsRepository {
  _FakeRepo(this.questions);
  final List<Question> questions;

  @override
  Future<List<Question>> loadQuestions() async => questions;
}

void main() {
  final fixtures = <Question>[
    Question(
      id: 1,
      text: 'Primera pregunta para ÉL',
      category: 'Romántico',
      target: Target.male,
    ),
    Question(
      id: 2,
      text: 'Primera pregunta para ELLA',
      category: 'Romántico',
      target: Target.female,
    ),
    Question(
      id: 3,
      text: 'Pregunta general',
      category: 'General',
      target: Target.any,
    ),
    Question(
      id: 4,
      text: 'SD para ÉL',
      category: 'Picante',
      target: Target.male,
      isSuddenDeath: true,
    ),
    Question(
      id: 5,
      text: 'SD para ELLA',
      category: 'Futuro',
      target: Target.female,
      isSuddenDeath: true,
    ),
    Question(
      id: 6,
      text: 'Otra general',
      category: 'General',
      target: Target.any,
    ),
  ];

  Future<QuestionsController> setup(WidgetTester tester,
      {List<Question>? repo,
      List<String> categories = const ['Romántico'],
      int maxRounds = 3,
      bool startingPlayerIsP1 = true}) async {
    final settings = await buildSettings();
    final controller = QuestionsController(
      repository: _FakeRepo(repo ?? fixtures),
      audioService: buildAudio(),
      settingsProvider: settings,
      maxRounds: maxRounds,
      categories: categories,
      startingPlayerIsP1: startingPlayerIsP1,
    );
    addTearDown(controller.dispose);
    await controller.initGame();
    return controller;
  }

  group('QuestionsController — initGame', () {
    testWidgets('arranca con el jugador inicial y una pregunta válida',
        (tester) async {
      final c = await setup(tester);
      expect(c.isLoading, isFalse);
      expect(c.player1.name, kPlayer1);
      expect(c.player2.name, kPlayer2);
      expect(c.currentPlayer, c.player1);
      expect(c.currentRound, 1);
      expect(c.currentQuestion!.id, 1); // única válida para P1 en Romántico
      expect(c.backgroundColor, c.settingsProvider.player1Color);
    });

    testWidgets('backgroundColor sigue al jugador activo', (tester) async {
      final c = await setup(tester);
      c.addPoints(2);
      expect(c.currentPlayer, c.player2);
      expect(c.backgroundColor, c.settingsProvider.player2Color);
    });
  });

  group('QuestionsController — puntuación', () {
    testWidgets('addPoints 2 y 1 reparten puntos perfectos/parciales',
        (tester) async {
      final c = await setup(tester, categories: const ['Romántico']);
      c.addPoints(2);
      expect(c.player1.score, 2);
      expect(c.player1.perfectAnswers, 1);
      expect(c.currentPlayer, c.player2);

      c.addPoints(1);
      expect(c.player2.score, 1);
      expect(c.player2.partialAnswers, 1);
    });

    testWidgets('addPoints con fallo cuenta failedAnswers sin puntos',
        (tester) async {
      final c = await setup(tester, categories: const ['Romántico']);
      c.addPoints(0);
      expect(c.player1.score, 0);
      expect(c.player1.failedAnswers, 1);
    });

    testWidgets('formatQuestionText reemplaza ELLA y ÉL', (tester) async {
      final c = await setup(tester);
      expect(c.formatQuestionText('ELLA'), kPlayer2);
      expect(c.formatQuestionText('ÉL'), kPlayer1);
      expect(c.formatQuestionText('Hola ELLA, te saluda ÉL'),
          'Hola $kPlayer2, te saluda $kPlayer1');
    });
  });

  group('QuestionsController — sudden death', () {
    testWidgets('las dos respuestas correctas cierran con onGameFinished',
        (tester) async {
      final c = await setup(tester,
          categories: const ['Romántico', 'Picante', 'Futuro']);
      (Player, Player)? finished;
      c.onGameFinished = (p1, p2) => finished = (p1, p2);

      c.activateSuddenDeath();
      expect(c.isSuddenDeath, isTrue);
      expect(c.currentPlayer, c.player1);
      expect(c.currentQuestion!.isSuddenDeath, isTrue);

      c.addPoints(7);
      expect(c.player1.suddenDeathPoints, 7);
      expect(c.player1.suddenDeathCorrect, isTrue);

      expect(c.currentPlayer, c.player2);
      expect(c.currentQuestion!.isSuddenDeath, isTrue);
      c.addPoints(7);

      expect(finished, isNotNull);
      expect(finished!.$1.suddenDeathPoints, 7);
      expect(finished!.$2.suddenDeathPoints, 7);
    });

    testWidgets('responder mal en sudden death reinicia los puntos',
        (tester) async {
      final c = await setup(tester,
          categories: const ['Romántico', 'Picante', 'Futuro']);
      (Player, Player)? finished;
      c.onGameFinished = (p1, p2) => finished = (p1, p2);

      c.activateSuddenDeath();
      c.addPoints(3); // ni 7 => fallo en esta ronda
      expect(c.player1.suddenDeathPoints, 0);
      expect(c.player1.suddenDeathCorrect, isFalse);

      c.addPoints(7); // P2 acierta
      expect(c.player2.suddenDeathPoints, 7);
      expect(finished, isNotNull);
    });
  });

  group('QuestionsController — fin de partida', () {
    testWidgets('agotar las rondas llama onGameFinished una sola vez',
        (tester) async {
      final c = await setup(tester, maxRounds: 1);
      int calls = 0;
      (Player, Player)? finished;
      c.onGameFinished = (p1, p2) {
        calls++;
        finished = (p1, p2);
      };

      c.addPoints(2);
      expect(calls, 1);
      expect(finished!.$1.score, 2);
    });

    testWidgets('sin preguntas disponible cierra en initGame', (tester) async {
      final settings = await buildSettings();
      final c = QuestionsController(
        repository: _FakeRepo(const <Question>[]),
        audioService: buildAudio(),
        settingsProvider: settings,
        maxRounds: 3,
        categories: const ['Romántico'],
        startingPlayerIsP1: true,
      );
      int calls = 0;
      c.onGameFinished = (p1, p2) => calls++;
      await c.initGame();
      expect(calls, 1);
      expect(c.currentQuestion, isNull);
      expect(c.isLoading, isFalse);
    });
  });
}