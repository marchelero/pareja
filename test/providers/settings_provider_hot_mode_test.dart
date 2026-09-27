import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pareja/providers/settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('hot mode gate', () {
    test('default is false after load', () async {
      final p = SettingsProvider();
      await p.load();
      expect(p.hotModeEnabled, isFalse);
    });

    test('setHotModeEnabled(true) updates state and notifies', () async {
      final p = SettingsProvider();
      await p.load();
      var notified = 0;
      p.addListener(() => notified++);

      await p.setHotModeEnabled(true);

      expect(p.hotModeEnabled, isTrue);
      expect(notified, 1);
    });

    test('setHotModeEnabled persists across new instance', () async {
      final p1 = SettingsProvider();
      await p1.load();
      await p1.setHotModeEnabled(true);

      final p2 = SettingsProvider();
      await p2.load();

      expect(p2.hotModeEnabled, isTrue);
    });

    test('setHotModeEnabled(false) overrides previous true', () async {
      final p = SettingsProvider();
      await p.load();
      await p.setHotModeEnabled(true);
      await p.setHotModeEnabled(false);
      expect(p.hotModeEnabled, isFalse);
    });
  });

  group('age verification', () {
    test('default is false after load', () async {
      final p = SettingsProvider();
      await p.load();
      expect(p.ageVerified, isFalse);
    });

    test('setAgeVerified(true) updates state and notifies', () async {
      final p = SettingsProvider();
      await p.load();
      var notified = 0;
      p.addListener(() => notified++);

      await p.setAgeVerified(true);

      expect(p.ageVerified, isTrue);
      expect(notified, 1);
    });

    test('setAgeVerified persists across new instance', () async {
      final p1 = SettingsProvider();
      await p1.load();
      await p1.setAgeVerified(true);

      final p2 = SettingsProvider();
      await p2.load();

      expect(p2.ageVerified, isTrue);
    });
  });

  group('resetAllData', () {
    test('clears hot mode and age verification', () async {
      final p = SettingsProvider();
      await p.load();
      await p.setHotModeEnabled(true);
      await p.setAgeVerified(true);

      await p.resetAllData();

      expect(p.hotModeEnabled, isFalse);
      expect(p.ageVerified, isFalse);
    });
  });
}
