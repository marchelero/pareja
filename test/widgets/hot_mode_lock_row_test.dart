import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pareja/core/i18n/app_strings.dart';
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

    expect(find.text(AppStrings.hotModeFree), findsOneWidget);
    expect(find.text(AppStrings.hotModeGetPremium), findsOneWidget);
  });

  testWidgets('premium user: hint de Configuración sin CTA', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: HotModeLockRow(isPremium: true))),
    );

    expect(find.text(AppStrings.hotModePremiumHint), findsOneWidget);
    expect(find.text(AppStrings.hotModeGetPremium), findsNothing);
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

    await tester.tap(find.text(AppStrings.hotModeGetPremium));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(PaywallScreen), findsOneWidget);
  });
}
