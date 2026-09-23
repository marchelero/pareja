import 'package:flutter_test/flutter_test.dart';
import 'package:pareja/core/constants/game_caps.dart';
import 'package:pareja/core/utils/date_utils.dart';
import 'package:pareja/providers/monetization_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  Future<MonetizationProvider> freshProvider({
    Map<String, Object> initialPrefs = const {},
  }) async {
    SharedPreferences.setMockInitialValues(initialPrefs);
    final p = MonetizationProvider();
    await p.load();
    return p;
  }

  /// Como freshProvider pero NO resetea prefs — asume que setUp() ya limpio
  /// o que otra operacion del test ya escribio en prefs. Usar para verificar
  /// que un estado persistido se carga correctamente despues de un "restart".
  Future<MonetizationProvider> reloadProvider() async {
    final p = MonetizationProvider();
    await p.load();
    return p;
  }

  group('MonetizationProvider — initial state', () {
    test('default isPremium false', () async {
      final p = await freshProvider();
      expect(p.isPremium, false);
    });

    test('isLoaded true despues de load', () async {
      final p = await freshProvider();
      expect(p.isLoaded, true);
    });
  });

  group('MonetizationProvider — canPlay (free, no cap)', () {
    test('ligeros (A TIEMPO) siempre playable', () async {
      final p = await freshProvider();
      expect(p.canPlay(GameCap.aTiempo), true);
    });

    test('pesados (Yo Nunca) siempre playable', () async {
      final p = await freshProvider();
      expect(p.canPlay(GameCap.yoNunca), true);
    });

    test('mediano (Ruleta) playable con 0 plays', () async {
      final p = await freshProvider();
      expect(p.canPlay(GameCap.ruleta), true);
    });
  });

  group('MonetizationProvider — remainingPlays (free, capped)', () {
    test('mediano nuevo: 3 restantes', () async {
      final p = await freshProvider();
      expect(p.remainingPlays(GameCap.ruleta), 3);
    });

    test('despues de 1 play: 2 restantes', () async {
      final p = await freshProvider();
      await p.recordPlay(GameCap.ruleta);
      expect(p.remainingPlays(GameCap.ruleta), 2);
    });

    test('despues de 3 plays: 0 restantes, no puede jugar', () async {
      final p = await freshProvider();
      await p.recordPlay(GameCap.ruleta);
      await p.recordPlay(GameCap.ruleta);
      await p.recordPlay(GameCap.ruleta);
      expect(p.remainingPlays(GameCap.ruleta), 0);
      expect(p.canPlay(GameCap.ruleta), false);
    });

    test('cap es per-game: Ruleta agotado no afecta Chupitos', () async {
      final p = await freshProvider();
      await p.recordPlay(GameCap.ruleta);
      await p.recordPlay(GameCap.ruleta);
      await p.recordPlay(GameCap.ruleta);
      expect(p.remainingPlays(GameCap.ruleta), 0);
      expect(p.remainingPlays(GameCap.chupitos), 3);
    });

    test('no-capped games retornan -1 (unlimited sentinel)', () async {
      final p = await freshProvider();
      expect(p.remainingPlays(GameCap.aTiempo), -1);
      expect(p.remainingPlays(GameCap.yoNunca), -1);
    });
  });

  group('MonetizationProvider — watchAdForGame', () {
    test('+1 jugada para juego especifico', () async {
      final p = await freshProvider();
      await p.recordPlay(GameCap.ruleta);
      await p.recordPlay(GameCap.ruleta);
      await p.recordPlay(GameCap.ruleta);
      expect(p.remainingPlays(GameCap.ruleta), 0);

      await p.watchAdForGame(GameCap.ruleta);

      expect(p.remainingPlays(GameCap.ruleta), 1);
      expect(p.canPlay(GameCap.ruleta), true);
    });

    test('ad en juego capped no afecta otros juegos capped', () async {
      final p = await freshProvider();
      await p.recordPlay(GameCap.chupitos);
      await p.recordPlay(GameCap.chupitos);
      await p.recordPlay(GameCap.chupitos);

      await p.watchAdForGame(GameCap.bomba);

      expect(p.remainingPlays(GameCap.chupitos), 0);
      expect(p.remainingPlays(GameCap.bomba), 4);
    });

    test('ad en juego no-capped: no-op (sigue -1)', () async {
      final p = await freshProvider();
      await p.watchAdForGame(GameCap.yoNunca);
      expect(p.remainingPlays(GameCap.yoNunca), -1);
    });
  });

  group('MonetizationProvider — premium', () {
    test('setPremium true: sin caps', () async {
      final p = await freshProvider();
      await p.recordPlay(GameCap.ruleta);
      await p.recordPlay(GameCap.ruleta);
      await p.recordPlay(GameCap.ruleta);
      expect(p.canPlay(GameCap.ruleta), false);

      await p.setPremium(true);

      expect(p.isPremium, true);
      expect(p.canPlay(GameCap.ruleta), true);
      expect(p.remainingPlays(GameCap.ruleta), -1);
    });

    test('setPremium true: persisted en LocalStorage', () async {
      final p = await freshProvider();
      await p.setPremium(true);

      // Reload desde prefs (sin resetear — verifica persistencia).
      final p2 = await reloadProvider();
      expect(p2.isPremium, true);
    });

    test('setPremium false: re-habilita caps', () async {
      final p = await freshProvider();
      await p.setPremium(true);
      await p.recordPlay(GameCap.ruleta);
      await p.recordPlay(GameCap.ruleta);
      await p.recordPlay(GameCap.ruleta);

      await p.setPremium(false);

      // Counts se preservan (no se borran al quitar premium).
      expect(p.remainingPlays(GameCap.ruleta), 0);
    });
  });

  group('MonetizationProvider — day rollover', () {
    test('cargar con last_reset ayer: limpia play counts', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayKey = DateUtils.dayKey(yesterday);

      final p = await freshProvider(initialPrefs: {
        'monetization_play_counts': 'Ruleta:3,Chupitos:2',
        'monetization_last_reset_date': yesterdayKey,
      });
      await p.load();

      // Play counts del dia previo NO se respetan — nuevo dia, cap fresh.
      expect(p.remainingPlays(GameCap.ruleta), 3);
      expect(p.remainingPlays(GameCap.chupitos), 3);
    });

    test('cargar con last_reset hoy: respeta play counts', () async {
      final todayKey = DateUtils.dayKey(DateTime.now());

      final p = await freshProvider(initialPrefs: {
        'monetization_play_counts': 'Ruleta:2',
        'monetization_last_reset_date': todayKey,
      });
      await p.load();

      expect(p.remainingPlays(GameCap.ruleta), 1);
    });

    test('cargar con last_reset vacio (primer arranque): cap fresh', () async {
      final p = await freshProvider();
      expect(p.remainingPlays(GameCap.ruleta), 3);
    });

    test('recordPlay actualiza last_reset a hoy', () async {
      final p = await freshProvider();
      await p.recordPlay(GameCap.ruleta);

      final stored = await SharedPreferences.getInstance();
      final lastReset = stored.getString('monetization_last_reset_date') ?? '';
      expect(lastReset, DateUtils.dayKey(DateTime.now()));
    });
  });

  group('MonetizationProvider — recordPlay', () {
    test('incrementa count en LocalStorage', () async {
      final p = await freshProvider();
      await p.recordPlay(GameCap.bomba);
      await p.recordPlay(GameCap.bomba);

      final stored = await SharedPreferences.getInstance();
      final counts = stored.getString('monetization_play_counts') ?? '';
      expect(counts.contains('Bomba:2'), true);
    });

    test('recordPlay en juego no-capped: igual registra (para stats)', () async {
      // Decision: no-capped games SI registran plays. Asi sabemos
      // cuanto jugaron en el dia. Pero el cap logic los ignora.
      final p = await freshProvider();
      await p.recordPlay(GameCap.aTiempo);
      await p.recordPlay(GameCap.aTiempo);

      expect(p.remainingPlays(GameCap.aTiempo), -1);
      expect(p.canPlay(GameCap.aTiempo), true);
    });
  });

  group('MonetizationProvider — resetAllData preserva premium', () {
    test('resetAllData en SettingsProvider: MonetizationProvider NO se reinicia solo',
        () async {
      // El reset vive en SettingsProvider, no en MonetizationProvider.
      // El test verifica que MonetizationProvider.load() respeta premium
      // persistido — el flujo completo de reset+reload se testea en
      // settings_provider_test.dart.
      final p = await freshProvider();
      await p.setPremium(true);
      expect(p.isPremium, true);

      // Simular restart: nuevo provider, mismos prefs.
      final p2 = await reloadProvider();
      expect(p2.isPremium, true);
    });
  });

  group('MonetizationProvider — rollover', () {
    test('load con fecha de ayer: resetea counts y persiste día nuevo', () async {
      SharedPreferences.setMockInitialValues({
        'monetization_is_premium': false,
        'monetization_play_counts': 'Ruleta:3',
        'monetization_last_reset_date': '2026-09-22', // ayer (hoy es 2026-09-23)
      });
      final p = MonetizationProvider(clock: () => DateTime(2026, 9, 23, 10));
      await p.load();
      expect(p.remainingPlays(GameCap.ruleta), 3);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('monetization_last_reset_date'), '2026-09-23');
    });

    test('sin reiniciar la app, pasada la medianoche el cap se reestablece en remainingPlays', () async {
      var now = DateTime(2026, 9, 22, 23, 59);
      SharedPreferences.setMockInitialValues({
        'monetization_is_premium': false,
        'monetization_play_counts': 'Ruleta:3',
        'monetization_last_reset_date': '2026-09-22',
      });
      final p = MonetizationProvider(clock: () => now);
      await p.load();
      expect(p.remainingPlays(GameCap.ruleta), 0);

      now = DateTime(2026, 9, 23, 0, 1); // pasó la medianoche
      expect(p.canPlay(GameCap.ruleta), isTrue);
      expect(p.remainingPlays(GameCap.ruleta), 3);

      await p.recordPlay(GameCap.ruleta);
      expect(p.remainingPlays(GameCap.ruleta), 2);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('monetization_last_reset_date'), '2026-09-23');
    });
  });
}
