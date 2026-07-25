import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pareja/providers/settings_provider.dart';
import 'package:pareja/screens/settings/age_gate_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('AgeGateModal rejects under-18 date', (tester) async {
    final now = DateTime.now();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                final result = await AgeGateModal.show(context);
                debugPrint('modal result: $result');
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Verificación de edad'), findsOneWidget);
    expect(find.text('VERIFICAR'), findsOneWidget);
    expect(find.text('CANCELAR'), findsOneWidget);

    // No date picked yet → error
    await tester.tap(find.text('VERIFICAR'));
    await tester.pumpAndSettle();
    expect(find.textContaining('selecciona una fecha'), findsOneWidget);
    // ignore: unused_local_variable
    final _ = now; // referenced to silence lint
  });

  test('SettingsProvider.gate progression: default → age verified → hot on', () async {
    final p = SettingsProvider();
    await p.load();
    expect(p.hotModeEnabled, isFalse);
    expect(p.ageVerified, isFalse);
    expect(p.adultContentAvailable, isFalse);

    await p.setAgeVerified(true);
    expect(p.adultContentAvailable, isFalse); // hot still off

    await p.setHotModeEnabled(true);
    expect(p.adultContentAvailable, isTrue);
  });
}
