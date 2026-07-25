import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pareja/core/storage/local_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('hot mode', () {
    test('default is false', () async {
      expect(await LocalStorage.isHotModeEnabled(), isFalse);
    });

    test('setHotModeEnabled(true) persists', () async {
      await LocalStorage.setHotModeEnabled(true);
      expect(await LocalStorage.isHotModeEnabled(), isTrue);
    });

    test('setHotModeEnabled(false) overrides previous true', () async {
      await LocalStorage.setHotModeEnabled(true);
      await LocalStorage.setHotModeEnabled(false);
      expect(await LocalStorage.isHotModeEnabled(), isFalse);
    });
  });

  group('age verification', () {
    test('default is false', () async {
      expect(await LocalStorage.isAgeVerified(), isFalse);
    });

    test('setAgeVerified(true) persists', () async {
      await LocalStorage.setAgeVerified(true);
      expect(await LocalStorage.isAgeVerified(), isTrue);
    });

    test('setAgeVerified(false) overrides previous true', () async {
      await LocalStorage.setAgeVerified(true);
      await LocalStorage.setAgeVerified(false);
      expect(await LocalStorage.isAgeVerified(), isFalse);
    });
  });

  group('reset all', () {
    test('clearAll wipes both flags', () async {
      await LocalStorage.setHotModeEnabled(true);
      await LocalStorage.setAgeVerified(true);
      await LocalStorage.clearAll();
      expect(await LocalStorage.isHotModeEnabled(), isFalse);
      expect(await LocalStorage.isAgeVerified(), isFalse);
    });
  });
}
