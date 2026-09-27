import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pareja/core/i18n/app_strings.dart';
import 'package:pareja/providers/monetization_provider.dart';
import 'package:pareja/screens/paywall/paywall_screen.dart';
import 'package:pareja/services/billing_service.dart';
import '../helpers/fake_billing_service.dart';

Future<void> _pumpPaywall(
  WidgetTester tester, {
  required MonetizationProvider monetization,
}) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [ChangeNotifierProvider.value(value: monetization)],
      child: const MaterialApp(home: PaywallScreen()),
    ),
  );
}

/// El botón de compra queda bajo el fold en el viewport de test (600px):
/// lo traemos a la vista antes de tapar.
Future<void> _tapBuy(WidgetTester tester) async {
  final buy = find.text(AppStrings.paywallBuy);
  await tester.ensureVisible(buy);
  await tester.pump();
  await tester.tap(buy);
}

Future<void> _tapRestore(WidgetTester tester) async {
  final restore = find.text(AppStrings.paywallRestore);
  await tester.ensureVisible(restore);
  await tester.pump();
  await tester.tap(restore);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase 3.4 — PaywallScreen', () {
    testWidgets('free user: ve beneficios + botón comprar + restaurar', (
      tester,
    ) async {
      final mp = MonetizationProvider(billingService: FakeBillingService());
      await mp.load();

      await _pumpPaywall(tester, monetization: mp);

      expect(find.text('Pareja Premium'), findsOneWidget);
      expect(find.text(AppStrings.paywallBuy), findsOneWidget);
      expect(find.text(AppStrings.paywallRestore), findsOneWidget);
      expect(find.text(AppStrings.paywallBenefitHot18), findsOneWidget);
      expect(find.text(AppStrings.paywallPremiumActive), findsNothing);
    });

    testWidgets('compra exitosa: muestra Premium activado', (tester) async {
      final mp = MonetizationProvider(billingService: FakeBillingService());
      await mp.load();

      await _pumpPaywall(tester, monetization: mp);
      await _tapBuy(tester);
      await tester.pump();

      expect(mp.isPremium, isTrue);
      expect(find.text(AppStrings.paywallPremiumActive), findsOneWidget);
      expect(find.text(AppStrings.paywallClose), findsOneWidget);
      expect(find.text(AppStrings.paywallBuy), findsNothing);
    });

    testWidgets('compra cancelada: snackbar sin activar premium', (
      tester,
    ) async {
      final mp = MonetizationProvider(
        billingService: FakeBillingService(
          defaultOutcome: PurchaseOutcome.cancelled,
        ),
      );
      await mp.load();

      await _pumpPaywall(tester, monetization: mp);
      await _tapBuy(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text(AppStrings.paywallPurchaseCancelled), findsOneWidget);
      expect(mp.isPremium, isFalse);
    });

    testWidgets('compra fallida: snackbar de error', (tester) async {
      final mp = MonetizationProvider(
        billingService: FakeBillingService(
          defaultOutcome: PurchaseOutcome.failed,
        ),
      );
      await mp.load();

      await _pumpPaywall(tester, monetization: mp);
      await _tapBuy(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text(AppStrings.paywallPurchaseFailed), findsOneWidget);
    });

    testWidgets('sin billing (device sin store): snackbar unavailable', (
      tester,
    ) async {
      final mp = MonetizationProvider();
      await mp.load();

      await _pumpPaywall(tester, monetization: mp);
      await _tapBuy(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text(AppStrings.paywallPurchaseUnavailable), findsOneWidget);
    });

    testWidgets('restore con compras previas: snackbar de confirmación', (
      tester,
    ) async {
      final mp = MonetizationProvider(
        billingService: FakeBillingService(restoreResult: true),
      );
      await mp.load();

      await _pumpPaywall(tester, monetization: mp);
      await _tapRestore(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text(AppStrings.paywallRestoreSuccess), findsOneWidget);
      expect(mp.isPremium, isTrue);
    });

    testWidgets('restore sin compras: snackbar informativo', (tester) async {
      final mp = MonetizationProvider(
        billingService: FakeBillingService(restoreResult: false),
      );
      await mp.load();

      await _pumpPaywall(tester, monetization: mp);
      await _tapRestore(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text(AppStrings.paywallRestoreNone), findsOneWidget);
      expect(mp.isPremium, isFalse);
    });

    testWidgets('usuario ya premium al abrir: banner activado directo', (
      tester,
    ) async {
      final mp = MonetizationProvider(billingService: FakeBillingService());
      await mp.load();
      await mp.setPremium(true);

      await _pumpPaywall(tester, monetization: mp);

      expect(find.text(AppStrings.paywallPremiumActive), findsOneWidget);
      expect(find.text(AppStrings.paywallBuy), findsNothing);
    });
  });
}
