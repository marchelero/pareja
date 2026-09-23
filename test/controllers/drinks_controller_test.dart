import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pareja/controllers/drinks_controller.dart';
import 'package:pareja/core/models/drink_task.dart';

import 'helpers.dart';

void main() {
  Future<DrinksController> setup(WidgetTester tester,
      {int sipsPerGlass = 3,
      int initialLevel = 1,
      int levelingSpeed = 3,
      bool isHotMode = false,
      bool freeMode = false,
      int totalGlasses = 2,
      Map<String, Object> extraPrefs = const {}}) async {
    final settings = await buildSettings(extraPrefs: extraPrefs);
    final controller = DrinksController(
      audioService: buildAudio(),
      settingsProvider: settings,
      sipsPerGlass: sipsPerGlass,
      initialLevel: initialLevel,
      levelingSpeed: levelingSpeed,
      isHotMode: isHotMode,
      freeMode: freeMode,
      totalGlasses: totalGlasses,
    );
    await tester.runAsync(() => controller.initGame());
    return controller;
  }

  group('DrinksController — estado inicial', () {
    testWidgets('initGame carga tareas reales y vasos llenos',
        (tester) async {
      final c = await setup(tester);
      expect(c.isLoading, isFalse);
      expect(c.player1Name, kPlayer1);
      expect(c.player2Name, kPlayer2);
      expect(c.heSipsLeft, 3);
      expect(c.sheSipsLeft, 3);
      expect(c.currentLevel, 1);
      expect(c.currentTask, isNotNull);
    });

    testWidgets('las tareas normales respetan la intensidad del nivel',
        (tester) async {
      final c = await setup(tester, levelingSpeed: 5);
      expect(c.currentTask, isNotNull);
      expect(c.currentTask!.intensity, lessThanOrEqualTo(c.currentLevel));
    });
  });

  group('DrinksController — sorbos y vasos', () {
    testWidgets('aplicar sorbos vacía el vaso y llama onGameOver',
        (tester) async {
      final c = await setup(tester);
      String? gameOver;
      c.onGameOver = (name) => gameOver = name;

      final vacated = c.applySips(DrinkTarget.he, 3);
      expect(vacated, isTrue);
      expect(c.heSipsLeft, 0);
      expect(gameOver, kPlayer1);
    });

    testWidgets('99 sorbos vacía el vaso de una', (tester) async {
      final c = await setup(tester);
      c.applySips(DrinkTarget.she, 99);
      expect(c.sheSipsLeft, 0);
    });

    testWidgets('resetPlayerGlasses vuelve a llenar el vaso', (tester) async {
      final c = await setup(tester);
      final vacated = c.applySips(DrinkTarget.he, 3);
      expect(vacated, isTrue);
      c.resetPlayerGlasses(kPlayer1);
      expect(c.heSipsLeft, 3);
    });

    testWidgets('aplicar a both vacía los dos vasos', (tester) async {
      final c = await setup(tester);
      String? gameOver;
      c.onGameOver = (name) => gameOver = name;
      c.applySips(DrinkTarget.both, 3);
      expect(c.heSipsLeft, 0);
      expect(c.sheSipsLeft, 0);
      expect(gameOver, kPlayer1); // se reporta al primero que se vacía
    });

    testWidgets('llenar el total de vasos termina con onGameFinished',
        (tester) async {
      final c = await setup(tester, totalGlasses: 2);
      String? gameOverP1;
      String? finished;
      c.onGameOver = (name) => gameOverP1 = name;
      c.onGameFinished = (name) => finished = name;

      c.applySips(DrinkTarget.he, 3); // vaso 1
      expect(gameOverP1, kPlayer1);
      expect(finished, isNull);

      c.resetPlayerGlasses(kPlayer1);
      c.applySips(DrinkTarget.he, 99); // vaso 2
      expect(c.heGlassesDrunk, 2);
      expect(finished, kPlayer2); // gana el rival
      expect(gameOverP1, kPlayer1); // onGameOver ya no se volvió a llamar
    });

    testWidgets('freeMode nunca lanza onGameFinished', (tester) async {
      final c = await setup(tester, freeMode: true, totalGlasses: 1);
      String? gameOver;
      bool finished = false;
      c.onGameOver = (name) => gameOver = name;
      c.onGameFinished = (name) => finished = true;

      c.applySips(DrinkTarget.he, 99);
      expect(gameOver, kPlayer1);
      expect(finished, isFalse);
      // Control: con freeMode=false el mismo caso cerraría la partida.
      final d = await setup(tester, totalGlasses: 1);
      bool finished2 = false;
      d.onGameFinished = (name) => finished2 = true;
      d.applySips(DrinkTarget.he, 99);
      expect(finished2, isTrue);
    });
  });

  group('DrinksController — niveles', () {
    testWidgets('cada levelingSpeed turnos sube de nivel y avisa',
        (tester) async {
      final c = await setup(tester, levelingSpeed: 2);
      int? levelUp;
      c.onLevelUp = (level) => levelUp = level;

      expect(c.turnCount, 1);
      expect(c.currentLevel, 1);
      expect(levelUp, isNull);

      c.nextTurnFromUI();
      expect(c.turnCount, 2);
      expect(c.currentLevel, 2);
      expect(levelUp, 2);
      expect(c.currentTask!.id, 'levelup_info_2');
      expect(c.activePlayerName, isNull);
    });

    testWidgets('modo hot con nivel>=5 construye el reto de prendas',
        (tester) async {
      final c = await setup(tester,
          isHotMode: true, initialLevel: 4, levelingSpeed: 1);
      int? levelUp;
      c.onLevelUp = (level) => levelUp = level;

      expect(c.currentLevel, 5);
      expect(levelUp, 5);
      expect(c.currentTask!.id, 'levelup_clothing_5');
      expect(c.currentTask!.type, DrinkType.challenge);
      expect(c.currentTask!.target, DrinkTarget.both);
    });

    testWidgets('nextTurnFromUI cambia de tarea en un turno normal',
        (tester) async {
      final c = await setup(tester, levelingSpeed: 3);
      final taskAntes = c.currentTask;
      c.nextTurnFromUI();
      expect(c.turnCount, 2);
      expect(c.currentTask, isNotNull);
      expect(c.currentTask != taskAntes, isTrue); // turno nuevo, tarea nueva
    });
  });

  group('DrinksController — tareas usadas', () {
    testWidgets('no repite tareas ya usadas (filtra desde prefs)',
        (tester) async {
      // Toma la primera tarea real del JSON y la marca como usada.
      final raw =
          await rootBundle.loadString('assets/data/drinks_tasks.json');
      final data = json.decode(raw) as List;
      final usedId = (data.first as Map)['id'] as String;

      final c = await setup(
        tester,
        extraPrefs: {'used_drink_tasks': <String>[usedId]},
      );
      expect(c.currentTask, isNotNull);
      expect(c.currentTask!.id, isNot(usedId));
    });
  });
}