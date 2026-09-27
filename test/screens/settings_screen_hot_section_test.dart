import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pareja/core/i18n/app_strings.dart';
import 'package:pareja/providers/monetization_provider.dart';
import 'package:pareja/providers/settings_provider.dart';
import 'package:pareja/screens/settings/age_gate_modal.dart';
import 'package:pareja/screens/settings_screen.dart';
import 'package:pareja/services/audio_service.dart';

Future<void> _pumpSettings(
  WidgetTester tester, {
  required SettingsProvider settings,
  required MonetizationProvider monetization,
}) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: monetization),
        ChangeNotifierProvider.value(value: AudioService()),
      ],
      child: const MaterialApp(home: SettingsScreen()),
    ),
  );
}

/// El toggle del Modo adulto es un AnimatedContainer de 50x30 dentro de un
/// GestureDetector. Esta predicate lo aísla del resto de la pantalla.
Finder get _hotToggle => find.byWidgetPredicate(
  (w) =>
      w is AnimatedContainer &&
      w.constraints != null &&
      w.constraints!.maxWidth == 50 &&
      w.constraints!.maxHeight == 30,
);

Future<void> _scrollToHotSection(WidgetTester tester, String title) async {
  await tester.scrollUntilVisible(
    find.text(title),
    150,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase 3.5 — Modo adulto premium-only', () {
    testWidgets('free user: gate con CTA, sin toggle', (tester) async {
      final settings = SettingsProvider();
      await settings.load();
      final monetization = MonetizationProvider();
      await monetization.setPremium(false);

      await _pumpSettings(
        tester,
        settings: settings,
        monetization: monetization,
      );
      await _scrollToHotSection(tester, AppStrings.adultContentTitle);

      expect(find.text(AppStrings.adultContentTitle), findsOneWidget);
      expect(find.text(AppStrings.adultContentLockedDesc), findsOneWidget);
      expect(find.text(AppStrings.hotModeGetPremium), findsOneWidget);
      expect(_hotToggle, findsNothing);
    });

    testWidgets('premium + edad verificada: toggle activa/desactiva', (
      tester,
    ) async {
      final settings = SettingsProvider();
      await settings.load();
      await settings.setAgeVerified(true);
      final monetization = MonetizationProvider();
      await monetization.setPremium(true);

      await _pumpSettings(
        tester,
        settings: settings,
        monetization: monetization,
      );
      await _scrollToHotSection(tester, AppStrings.adultContentTitleBase);

      expect(find.text(AppStrings.adultContentVerifiedHint), findsOneWidget);
      expect(find.text(AppStrings.hotModeGetPremium), findsNothing);

      await tester.tap(_hotToggle);
      await tester.pump();

      expect(settings.hotModeEnabled, isTrue);
      expect(find.text(AppStrings.adultContentActive), findsOneWidget);

      await tester.tap(_hotToggle);
      await tester.pump();

      expect(settings.hotModeEnabled, isFalse);
    });

    testWidgets('premium sin verificar: toggle abre AgeGateModal', (
      tester,
    ) async {
      final settings = SettingsProvider();
      await settings.load();
      final monetization = MonetizationProvider();
      await monetization.setPremium(true);

      await _pumpSettings(
        tester,
        settings: settings,
        monetization: monetization,
      );
      await _scrollToHotSection(tester, AppStrings.adultContentTitleBase);

      expect(find.text(AppStrings.adultContentVerifyRequired), findsOneWidget);

      await tester.tap(_hotToggle);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(AgeGateModal), findsOneWidget);
      expect(settings.hotModeEnabled, isFalse);
    });
  });
}
