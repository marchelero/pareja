import 'package:flutter_test/flutter_test.dart';
import 'package:pareja/controllers/mentiroso_controller.dart';

import 'helpers.dart';

void main() {
  Future<MentirosoController> setup(WidgetTester tester,
      {int totalRounds = 5}) async {
    final c = MentirosoController(
      audioService: buildAudio(),
      totalRounds: totalRounds,
    );
    addTearDown(c.dispose);
    return c;
  }

  group('MentirosoController — dados y afirmaciones', () {
    testWidgets('rollDice genera dados 1..6 y evalúa las 8 afirmaciones',
        (tester) async {
      final c = await setup(tester);
      c.rollDice();
      expect(c.dice1, inInclusiveRange(1, 6));
      expect(c.dice2, inInclusiveRange(1, 6));

      final d1 = c.dice1;
      final d2 = c.dice2;
      expect(c.isStatementTrue(0), d1 + d2 > 10);
      expect(c.isStatementTrue(1), d1 == d2);
      expect(c.isStatementTrue(2), d1.isOdd && d2.isOdd);
      expect(c.isStatementTrue(3), d1.isEven && d2.isEven);
      expect(c.isStatementTrue(4), (d1 + d2).isEven);
      expect(c.isStatementTrue(5), d1 == 6 || d2 == 6);
      expect(c.isStatementTrue(6), d1 + d2 == 7);
      expect(c.isStatementTrue(7), d1 == 1 || d2 == 1);
    });

    testWidgets('las afirmaciones arrancan en false antes de tirar',
        (tester) async {
      final c = await setup(tester);
      for (var i = 0; i < 8; i++) {
        expect(c.isStatementTrue(i), isFalse);
      }
    });
  });

  group('MentirosoController — flujo de ronda', () {
    testWidgets('acierto del inquisidor suma punto al inquisidor',
        (tester) async {
      final c = await setup(tester);
      final settings = await buildSettings();
      c.setStartingPlayer(true); // ronda 1: P1 miente, P2 investiga

      c.rollDice();
      final wasTrue = c.isStatementTrue(0);
      c.revealDice();
      expect(c.selectedIndex, isNull);
      c.selectStatement(0);
      expect(c.selectedStatementText, MentirosoController.statements[0]);
      c.confirmBluff();
      expect(c.step, MentirosoStep.handoff);
      c.startInvestigation();
      expect(c.step, MentirosoStep.guess);

      c.guess(wasTrue); // el inquisidor adivina bien
      expect(c.step, MentirosoStep.result);
      expect(c.scoreP2, 1); // P2 = inquisidor = gana el punto
      expect(c.scoreP1, 0);
      expect(c.getRoundResultText(settings),
          anyOf(contains('acertó'), contains('descubrió')));
    });

    testWidgets('fallo del inquisidor suma punto al mentiroso',
        (tester) async {
      final c = await setup(tester);
      c.setStartingPlayer(true);

      c.rollDice();
      final wasTrue = c.isStatementTrue(0);
      c.revealDice();
      c.selectStatement(0);
      c.confirmBluff();
      c.startInvestigation();
      c.guess(!wasTrue); // el inquisidor se equivoca
      expect(c.scoreP1, 1); // P1 = mentiroso = gana el punto
      expect(c.scoreP2, 0);
    });

    testWidgets('guess sin declaración seleccionada no puntúa',
        (tester) async {
      final c = await setup(tester);
      c.rollDice();
      c.guess(true);
      expect(c.scoreP1, 0);
      expect(c.scoreP2, 0);
    });
  });

  group('MentirosoController — rotación y reseteo', () {
    testWidgets('isP1Liar alterna según ronda y start', (tester) async {
      final c = await setup(tester);
      c.setStartingPlayer(true);
      expect(c.round, 1);
      expect(c.isP1Liar, isTrue); // impar + arranca P1

      c.nextRound();
      expect(c.round, 2);
      expect(c.isP1Liar, isFalse); // par

      c.setStartingPlayer(false);
      expect(c.isP1Liar, isTrue); // par + arranca P2 => miente P1

      c.nextRound();
      expect(c.isP1Liar, isFalse); // impar + arranca P2 => miente P2
    });

    testWidgets('nextRound resetea dados, selección y afirmaciones',
        (tester) async {
      final c = await setup(tester);
      c.rollDice();
      c.revealDice();
      c.selectStatement(2);
      c.confirmBluff();
      c.startInvestigation();
      c.guess(true);

      c.nextRound();
      expect(c.step, MentirosoStep.roll);
      expect(c.dice1, 1);
      expect(c.dice2, 1);
      expect(c.selectedIndex, isNull);
      expect(c.guessIsVerdad, isNull);
      expect(c.selectedWasTrue, isFalse);
    });

    testWidgets('isGameOver se alcanza al llegar a totalRounds',
        (tester) async {
      final c = await setup(tester, totalRounds: 2);
      expect(c.isGameOver, isFalse);
      c.nextRound();
      expect(c.round, 2);
      expect(c.isGameOver, isTrue);
    });

    testWidgets('resetGame devuelve al estado inicial', (tester) async {
      final c = await setup(tester);
      c.rollDice();
      c.revealDice();
      c.selectStatement(0);
      c.confirmBluff();
      c.startInvestigation();
      c.guess(true);
      c.nextRound();

      c.resetGame();
      expect(c.round, 1);
      expect(c.scoreP1, 0);
      expect(c.scoreP2, 0);
      expect(c.step, MentirosoStep.roll);
      expect(c.dice1, 1);
      expect(c.dice2, 1);
    });
  });

  group('MentirosoController — nombres y resultado final', () {
    testWidgets('liarName/inquisitorName usan los display names',
        (tester) async {
      final settings = await buildSettings();
      final c = await setup(tester);
      c.setStartingPlayer(true);
      expect(c.liarName(settings), kPlayer1);
      expect(c.inquisitorName(settings), kPlayer2);
    });

    testWidgets('finalWinnerName respeta la puntuación', (tester) async {
      final c = await setup(tester);
      expect(c.finalWinnerName, 'Empate');

      c.scoreP1 = 5;
      c.scoreP2 = 2;
      expect(c.finalWinnerName, 'Gana Jugador 1');

      c.scoreP1 = 1;
      c.scoreP2 = 4;
      expect(c.finalWinnerName, 'Gana Jugador 2');
    });
  });
}