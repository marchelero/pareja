import 'package:flutter/widgets.dart';
import 'package:pareja/data/ad_service.dart';

/// AdService fake para tests. Controlable via flags.
///
/// Uso:
/// ```dart
/// final fake = FakeAdService();
/// fake.rewardedResult = true; // ad will "succeed"
/// final provider = MonetizationProvider(adService: fake);
/// ```
class FakeAdService implements AdService {
  /// Lo que retorna showRewardedAd() la proxima vez que se llame.
  bool rewardedResult = false;

  /// Cuantas veces se llamo showRewardedAd (para assertions).
  int rewardedCallCount = 0;

  /// Si el ad service esta "disponible" (afecta isAvailable).
  bool available = true;

  /// Widget retornado por buildBannerAd (default: SizedBox.shrink).
  Widget bannerWidget = const SizedBox.shrink();

  /// Si initialize() fue llamado.
  bool initializeCalled = false;

  @override
  Future<void> initialize() async {
    initializeCalled = true;
  }

  @override
  Future<bool> showRewardedAd() async {
    rewardedCallCount++;
    return rewardedResult;
  }

  @override
  Widget buildBannerAd() => bannerWidget;

  @override
  bool get isAvailable => available;

  @override
  Future<void> dispose() async {}
}
