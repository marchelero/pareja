import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
      providers: [
        ChangeNotifierProvider.value(value: monetization),
      ],
      child: const MaterialApp(home: PaywallScreen()),
    ),
  );
}

/// El botón de compra queda bajo el fold en el viewport de test (600px):
/// lo traemos a la vista antes de tapar.
Future<void> _tapBuy(WidgetTester tester) async {
  final buy = find.text('COMPRAR — \$4.99');
  await tester.ensureVisible(buy);
  await tester.pump();
  await tester.tap(buy);
}

Future<void> _tapRestore(WidgetTester tester) async {
  final restore = find.text('Restaurar compras');
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
    testWidgets('free user: ve beneficios + botón comprar + restaurar',
        (tester) async {
      final mp = MonetizationProvider(billingService: FakeBillingService());
      await mp.load();

      await _pumpPaywall(tester, monetization: mp);

      expect(find.text('Pareja Premium'), findsOneWidget);
      expect(find.text('COMPRAR — \$4.99'), findsOneWidget);
      expect(find.text('Restaurar compras'), findsOneWidget);
      expect(find.text('Modo +18 desbloqueado'), findsOneWidget);
      expect(find.text('✓ Premium activado'), findsNothing);
    });

    testWidgets('compra exitosa: muestra Premium activado', (tester) async {
      final mp = MonetizationProvider(billingService: FakeBillingService());
      await mp.load();

      await _pumpPaywall(tester, monetization: mp);
      await _tapBuy(tester);
      await tester.pump();

      expect(mp.isPremium, isTrue);
      expect(find.text('✓ Premium activado'), findsOneWidget);
      expect(find.text('CERRAR'), findsOneWidget);
      expect(find.text('COMPRAR — \$4.99'), findsNothing);
    });

    testWidgets('compra cancelada: snackbar sin activar premium', (tester) async {
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

      expect(find.text('Compra cancelada.'), findsOneWidget);
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

      expect(
        find.text('No se pudo completar la compra. Inténtalo de nuevo.'),
        findsOneWidget,
      );
    });

    testWidgets('sin billing (device sin store): snackbar unavailable',
        (tester) async {
      final mp = MonetizationProvider();
      await mp.load();

      await _pumpPaywall(tester, monetization: mp);
      await _tapBuy(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.text('Las compras no están disponibles en este device.'),
        findsOneWidget,
      );
    });

    testWidgets('restore con compras previas: snackbar de confirmación',
        (tester) async {
      final mp = MonetizationProvider(
        billingService: FakeBillingService(restoreResult: true),
      );
      await mp.load();

      await _pumpPaywall(tester, monetization: mp);
      await _tapRestore(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.text('Compras restauradas. ¡Bienvenido de nuevo!'),
        findsOneWidget,
      );
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

      expect(find.text('No se encontraron compras previas.'), findsOneWidget);
      expect(mp.isPremium, isFalse);
    });

    testWidgets('usuario ya premium al abrir: banner activado directo',
        (tester) async {
      final mp = MonetizationProvider(billingService: FakeBillingService());
      await mp.load();
      await mp.setPremium(true);

      await _pumpPaywall(tester, monetization: mp);

      expect(find.text('✓ Premium activado'), findsOneWidget);
      expect(find.text('COMPRAR — \$4.99'), findsNothing);
    });
  });
}