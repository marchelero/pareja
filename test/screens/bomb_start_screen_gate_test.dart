import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pareja/providers/monetization_provider.dart';
import 'package:pareja/providers/settings_provider.dart';
import 'package:pareja/screens/bomb/bomb_start_screen.dart';
import 'package:pareja/services/audio_service.dart';
import 'package:pareja/widgets/hot_mode_lock_row.dart';
import 'package:pareja/widgets/setting_row.dart';

Future<void> _pumpBomb(WidgetTester tester,
    {required SettingsProvider settings, required MonetizationProvider monetization}) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: monetization),
        ChangeNotifierProvider.value(value: AudioService()),
      ],
      child: const MaterialApp(home: BombStartScreen()),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase 3.5 — gate premium en start screens', () {
    testWidgets('free user: ve HotModeLockRow con CTA, sin toggle', (tester) async {
      final settings = SettingsProvider();
      await settings.load();
      final monetization = MonetizationProvider();
      await monetization.setPremium(false);

      await _pumpBomb(tester, settings: settings, monetization: monetization);

      expect(find.text('Modo Hot (+18) — Requiere Premium'), findsOneWidget);
      expect(find.text('Obtener Premium'), findsOneWidget);
      expect(find.text('Modo Hot'), findsNothing);
    });

    testWidgets('free user con hot mode previamente activado: aun asi ve el gate',
        (tester) async {
      final settings = SettingsProvider();
      await settings.load();
      await settings.setHotModeEnabled(true);
      final monetization = MonetizationProvider();
      await monetization.setPremium(false);

      await _pumpBomb(tester, settings: settings, monetization: monetization);

      expect(find.byType(HotModeLockRow), findsOneWidget);
      expect(find.text('Modo Hot'), findsNothing);
    });

    testWidgets('premium + hot mode activo: toggle visible y funcional',
        (tester) async {
      final settings = SettingsProvider();
      await settings.load();
      await settings.setHotModeEnabled(true);
      final monetization = MonetizationProvider();
      await monetization.setPremium(true);

      await _pumpBomb(tester, settings: settings, monetization: monetization);

      expect(find.text('Modo Hot'), findsOneWidget);
      expect(find.byType(HotModeLockRow), findsNothing);
      expect(find.byType(SettingSwitch), findsOneWidget);
    });

    testWidgets('premium sin hot mode: hint de configuración sin CTA',
        (tester) async {
      final settings = SettingsProvider();
      await settings.load();
      final monetization = MonetizationProvider();
      await monetization.setPremium(true);

      await _pumpBomb(tester, settings: settings, monetization: monetization);

      expect(find.byType(HotModeLockRow), findsOneWidget);
      expect(
        find.text('Modo Hot bloqueado. Actívalo en Configuración.'),
        findsOneWidget,
      );
      expect(find.text('Obtener Premium'), findsNothing);
    });
  });
}