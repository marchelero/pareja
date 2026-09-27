import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pareja/providers/monetization_provider.dart';
import 'package:pareja/screens/paywall/paywall_screen.dart';
import 'package:pareja/widgets/hot_mode_lock_row.dart';

void main() {
  testWidgets('free user: muestra mensaje Requiere Premium + CTA', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: HotModeLockRow(isPremium: false))),
    );

    expect(find.text('Modo Hot (+18) — Requiere Premium'), findsOneWidget);
    expect(find.text('Obtener Premium'), findsOneWidget);
  });

  testWidgets('premium user: hint de Configuración sin CTA', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: HotModeLockRow(isPremium: true))),
    );

    expect(
      find.text('Modo Hot bloqueado. Actívalo en Configuración.'),
      findsOneWidget,
    );
    expect(find.text('Obtener Premium'), findsNothing);
  });

  testWidgets('CTA navega a PaywallScreen', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => MonetizationProvider()),
        ],
        child: const MaterialApp(
          home: Scaffold(body: HotModeLockRow(isPremium: false)),
        ),
      ),
    );

    await tester.tap(find.text('Obtener Premium'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(PaywallScreen), findsOneWidget);
  });
}
