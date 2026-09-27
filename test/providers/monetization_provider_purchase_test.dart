import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pareja/core/storage/local_storage.dart';
import 'package:pareja/providers/monetization_provider.dart';
import 'package:pareja/services/billing_service.dart';
import '../helpers/fake_billing_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase 3.4 — purchasePremium', () {
    test('success persiste premium y sobrevive reload', () async {
      final billing = FakeBillingService();
      final mp = MonetizationProvider(billingService: billing);
      await mp.load();

      final outcome = await mp.purchasePremium();

      expect(outcome, PurchaseOutcome.success);
      expect(mp.isPremium, isTrue);
      expect(await LocalStorage.isPremium(), isTrue);

      final reloaded = MonetizationProvider(
        billingService: FakeBillingService(),
      );
      await reloaded.load();
      expect(reloaded.isPremium, isTrue);
    });

    test('cancelled no activa premium', () async {
      final billing = FakeBillingService(
        defaultOutcome: PurchaseOutcome.cancelled,
      );
      final mp = MonetizationProvider(billingService: billing);
      await mp.load();

      final outcome = await mp.purchasePremium();

      expect(outcome, PurchaseOutcome.cancelled);
      expect(mp.isPremium, isFalse);
    });

    test('failed no activa premium', () async {
      final billing = FakeBillingService(
        defaultOutcome: PurchaseOutcome.failed,
      );
      final mp = MonetizationProvider(billingService: billing);
      await mp.load();

      final outcome = await mp.purchasePremium();

      expect(outcome, PurchaseOutcome.failed);
      expect(mp.isPremium, isFalse);
    });

    test('sin billingService retorna unavailable', () async {
      final mp = MonetizationProvider();

      final outcome = await mp.purchasePremium();

      expect(outcome, PurchaseOutcome.unavailable);
      expect(mp.isPremium, isFalse);
    });

    test('billing no disponible (store ausente) retorna unavailable', () async {
      final billing = FakeBillingService(available: false);
      final mp = MonetizationProvider(billingService: billing);
      await mp.load();

      final outcome = await mp.purchasePremium();

      expect(outcome, PurchaseOutcome.unavailable);
      // El provider delega en el servicio; es el servicio quien reporta
      // que el store no está disponible.
      expect(billing.purchaseCalls, 1);
      expect(mp.isPremium, isFalse);
    });
  });

  group('Phase 3.4 — restorePurchases', () {
    test('restore exitoso activa premium si no lo era', () async {
      final billing = FakeBillingService(restoreResult: true);
      final mp = MonetizationProvider(billingService: billing);
      await mp.load();

      final restored = await mp.restorePurchases();

      expect(restored, isTrue);
      expect(mp.isPremium, isTrue);
      expect(await LocalStorage.isPremium(), isTrue);
    });

    test('restore sin compras previas no activa premium', () async {
      final billing = FakeBillingService(restoreResult: false);
      final mp = MonetizationProvider(billingService: billing);
      await mp.load();

      final restored = await mp.restorePurchases();

      expect(restored, isFalse);
      expect(mp.isPremium, isFalse);
    });

    test('sin billingService retorna false', () async {
      final mp = MonetizationProvider();

      final restored = await mp.restorePurchases();

      expect(restored, isFalse);
    });
  });
}
