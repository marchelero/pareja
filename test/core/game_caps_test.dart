import 'package:flutter_test/flutter_test.dart';
import 'package:pareja/core/constants/game_caps.dart';

void main() {
  group('GameCap', () {
    test('hay exactamente 14 juegos definidos', () {
      expect(GameCap.values.length, 14);
    });

    test('3 pesados sin cap', () {
      final pesados = GameCap.values.where((g) => g.tier == GameTier.pesado);
      expect(pesados.length, 3);
      for (final g in pesados) {
        expect(g.isCapped, false, reason: '${g.displayName} no deberia tener cap');
        expect(g.dailyCap, 0);
      }
    });

    test('5 medianos con cap 3/dia', () {
      final medianos = GameCap.values.where((g) => g.tier == GameTier.mediano);
      expect(medianos.length, 5);
      for (final g in medianos) {
        expect(g.isCapped, true, reason: '${g.displayName} deberia tener cap');
        expect(g.dailyCap, 3);
      }
    });

    test('6 ligeros sin cap', () {
      final ligeros = GameCap.values.where((g) => g.tier == GameTier.ligero);
      expect(ligeros.length, 6);
      for (final g in ligeros) {
        expect(g.isCapped, false);
        expect(g.dailyCap, 0);
      }
    });

    test('nombres exactos de los 14 juegos matchean', () {
      const esperados = <String>{
        'Yo Nunca',
        'Preguntas',
        'Sin palabras',
        'Ruleta',
        'Chupitos',
        'Bomba',
        'Duelo Nocturno',
        'Alto al Fuego',
        'Ruleta Rusa',
        'Memoria',
        'Pares',
        'Mentiroso',
        'A TIEMPO',
        'Premiado',
      };
      final actuales = GameCap.values.map((g) => g.displayName).toSet();
      expect(actuales, esperados);
    });

    group('fromName', () {
      test('encuentra juego por nombre exacto', () {
        expect(GameCap.fromName('Ruleta'), GameCap.ruleta);
        expect(GameCap.fromName('Duelo Nocturno'), GameCap.dueloNocturno);
        expect(GameCap.fromName('A TIEMPO'), GameCap.aTiempo);
      });

      test('case-sensitive: lowercase retorna null', () {
        expect(GameCap.fromName('ruleta'), isNull);
        expect(GameCap.fromName('A tiempo'), isNull);
      });

      test('nombre desconocido retorna null', () {
        expect(GameCap.fromName('No Existe'), isNull);
        expect(GameCap.fromName(''), isNull);
      });
    });

    test('defaultCap == dailyCap', () {
      for (final g in GameCap.values) {
        expect(g.defaultCap, g.dailyCap);
      }
    });
  });
}
