import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pareja/data/ad_service.dart';

void main() {
  group('NoOpAdService', () {
    const service = NoOpAdService();

    test('isAvailable: false', () {
      expect(service.isAvailable, false);
    });

    test('initialize: no falla, no hace nada', () async {
      await service.initialize();
    });

    test('showRewardedAd: retorna false', () async {
      expect(await service.showRewardedAd(), false);
    });

    test('buildBannerAd: retorna SizedBox vacio', () {
      final widget = service.buildBannerAd();
      expect(widget, isA<SizedBox>());
    });

    test('dispose: no falla', () async {
      await service.dispose();
    });
  });
}
