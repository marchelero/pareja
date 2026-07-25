import 'package:flutter_test/flutter_test.dart';
import 'package:pareja/core/constants/game_caps.dart';
import 'package:pareja/providers/monetization_provider.dart';
import 'package:pareja/widgets/gate_guard.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  Future<MonetizationProvider> provider({
    bool premium = false,
    Map<String, int> counts = const {},
  }) async {
    SharedPreferences.setMockInitialValues({});
    final p = MonetizationProvider();
    await p.load();
    if (premium) await p.setPremium(true);
    for (final entry in counts.entries) {
      final game = GameCap.fromName(entry.key);
      if (game == null) continue;
      for (int i = 0; i < entry.value; i++) {
        await p.recordPlay(game);
      }
    }
    return p;
  }

  group('GateGuard.evaluate', () {
    test('uncapped game: allow sin chequear counts', () async {
      final p = await provider();
      expect(GateGuard.evaluate(p, GameCap.yoNunca), GateDecision.allow);
      expect(GateGuard.evaluate(p, GameCap.aTiempo), GateDecision.allow);
    });

    test('capped game, 0 plays used: allow', () async {
      final p = await provider();
      expect(GateGuard.evaluate(p, GameCap.ruleta), GateDecision.allow);
    });

    test('capped game, plays < cap: allow', () async {
      final p = await provider(counts: {'Ruleta': 1});
      expect(GateGuard.evaluate(p, GameCap.ruleta), GateDecision.allow);
    });

    test('capped game, plays == cap: showModal', () async {
      final p = await provider(counts: {'Ruleta': 3});
      expect(GateGuard.evaluate(p, GameCap.ruleta), GateDecision.showModal);
    });

    test('capped game, plays > cap (con ad bonus consumido): showModal',
        () async {
      final p = await provider(counts: {'Ruleta': 5});
      expect(GateGuard.evaluate(p, GameCap.ruleta), GateDecision.showModal);
    });

    test('capped game + premium: allow sin chequear counts', () async {
      final p = await provider(premium: true, counts: {'Ruleta': 100});
      expect(GateGuard.evaluate(p, GameCap.ruleta), GateDecision.allow);
    });

    test('cap es per-game: Chupitos lleno no bloquea Ruleta', () async {
      final p = await provider(counts: {'Chupitos': 3});
      expect(GateGuard.evaluate(p, GameCap.chupitos), GateDecision.showModal);
      expect(GateGuard.evaluate(p, GameCap.ruleta), GateDecision.allow);
    });
  });
}
