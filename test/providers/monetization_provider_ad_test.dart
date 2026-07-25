import 'package:flutter_test/flutter_test.dart';
import 'package:pareja/core/constants/game_caps.dart';
import 'package:pareja/providers/monetization_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/fake_ad_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('MonetizationProvider.watchAdForGameWithReward', () {
    test('ad success + capped game: count decrementa, retorna true', () async {
      final fake = FakeAdService()..rewardedResult = true;
      final p = MonetizationProvider(adService: fake);
      await p.load();
      await p.recordPlay(GameCap.ruleta);
      await p.recordPlay(GameCap.ruleta);
      await p.recordPlay(GameCap.ruleta);
      expect(p.remainingPlays(GameCap.ruleta), 0);

      final success = await p.watchAdForGameWithReward(GameCap.ruleta);

      expect(success, true);
      expect(p.remainingPlays(GameCap.ruleta), 1);
      expect(fake.rewardedCallCount, 1);
    });

    test('ad fail (user cerro): count NO cambia, retorna false', () async {
      final fake = FakeAdService()..rewardedResult = false;
      final p = MonetizationProvider(adService: fake);
      await p.load();
      await p.recordPlay(GameCap.ruleta);
      await p.recordPlay(GameCap.ruleta);
      await p.recordPlay(GameCap.ruleta);
      expect(p.remainingPlays(GameCap.ruleta), 0);

      final success = await p.watchAdForGameWithReward(GameCap.ruleta);

      expect(success, false);
      // El count sigue en 3 (no se desconto).
      expect(p.remainingPlays(GameCap.ruleta), 0);
      expect(fake.rewardedCallCount, 1);
    });

    test('ad success pero juego NO capped: retorna false, no muestra ad',
        () async {
      final fake = FakeAdService()..rewardedResult = true;
      final p = MonetizationProvider(adService: fake);
      await p.load();

      final success = await p.watchAdForGameWithReward(GameCap.yoNunca);

      // No deberia mostrar el ad (uncapped).
      expect(fake.rewardedCallCount, 0);
      expect(success, false);
    });

    test('ad success en premium user: retorna false, no consume play', () async {
      final fake = FakeAdService()..rewardedResult = true;
      final p = MonetizationProvider(adService: fake);
      await p.load();
      await p.setPremium(true);

      final success = await p.watchAdForGameWithReward(GameCap.ruleta);

      // Premium: el metodo no tiene sentido, no muestra ad.
      expect(fake.rewardedCallCount, 0);
      expect(success, false);
    });
  });

  group('MonetizationProvider — AdService default', () {
    test('default adService es NoOpAdService (no falla en test)', () async {
      final p = MonetizationProvider();
      await p.load();
      // NoOpAdService.showRewardedAd retorna false.
      final success = await p.watchAdForGameWithReward(GameCap.ruleta);
      expect(success, false);
    });
  });
}
