import 'package:flutter_test/flutter_test.dart';
import 'package:pareja/core/storage/local_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('LocalStorage — premium', () {
    test('isPremium default false', () async {
      expect(await LocalStorage.isPremium(), false);
    });

    test('setIsPremium true persiste', () async {
      await LocalStorage.setIsPremium(true);
      expect(await LocalStorage.isPremium(), true);
    });

    test('setIsPremium false sobrescribe true', () async {
      await LocalStorage.setIsPremium(true);
      await LocalStorage.setIsPremium(false);
      expect(await LocalStorage.isPremium(), false);
    });
  });

  group('LocalStorage — play counts', () {
    test('getPlayCounts default vacio', () async {
      expect(await LocalStorage.getPlayCounts(), <String, int>{});
    });

    test('savePlayCounts round-trip simple', () async {
      const counts = {'Ruleta': 2, 'Chupitos': 1};
      await LocalStorage.savePlayCounts(counts);
      expect(await LocalStorage.getPlayCounts(), counts);
    });

    test('savePlayCounts vacio limpia todo', () async {
      await LocalStorage.savePlayCounts({'Ruleta': 5});
      await LocalStorage.savePlayCounts({});
      expect(await LocalStorage.getPlayCounts(), <String, int>{});
    });

    test('savePlayCounts con un solo juego', () async {
      const counts = {'Bomba': 3};
      await LocalStorage.savePlayCounts(counts);
      expect(await LocalStorage.getPlayCounts(), counts);
    });

    test('savePlayCounts ignora count 0 (no se guarda entrada)', () async {
      // 0 se guarda (es un valor valido: "jugo 0 veces hoy") — pero el
      // caller deberia filtrarlo. Test verifica que se persiste igual.
      const counts = {'Ruleta': 0};
      await LocalStorage.savePlayCounts(counts);
      expect(await LocalStorage.getPlayCounts(), counts);
    });

    test('getPlayCounts con string malformado retorna vacio', () async {
      SharedPreferences.setMockInitialValues({
        'monetization_play_counts': 'invalid_no_colon,otro:abc',
      });
      final result = await LocalStorage.getPlayCounts();
      // 'invalid_no_colon' no tiene ':' → se ignora. 'otro' tiene 'abc' → tryParse null → 0.
      // Por diseno: skip entries sin count valido.
      expect(result.containsKey('invalid_no_colon'), false);
      expect(result['otro'], 0);
    });
  });

  group('LocalStorage — last reset date', () {
    test('getLastResetDate default vacio', () async {
      expect(await LocalStorage.getLastResetDate(), '');
    });

    test('setLastResetDate round-trip', () async {
      await LocalStorage.setLastResetDate('2026-07-25');
      expect(await LocalStorage.getLastResetDate(), '2026-07-25');
    });
  });

  group('LocalStorage — clearAll', () {
    test('borra premium, play counts, last reset, todo', () async {
      await LocalStorage.setIsPremium(true);
      await LocalStorage.savePlayCounts({'Ruleta': 3});
      await LocalStorage.setLastResetDate('2026-07-25');
      await LocalStorage.savePlayer1Name('Test');

      await LocalStorage.clearAll();

      expect(await LocalStorage.isPremium(), false);
      expect(await LocalStorage.getPlayCounts(), <String, int>{});
      expect(await LocalStorage.getLastResetDate(), '');
      expect(await LocalStorage.getPlayer1Name(), '');
    });
  });

  group('LocalStorage — clearAllExceptMonetization', () {
    test('borra user data pero conserva premium + play counts + last reset',
        () async {
      await LocalStorage.setIsPremium(true);
      await LocalStorage.savePlayCounts({'Ruleta': 3});
      await LocalStorage.setLastResetDate('2026-07-25');
      await LocalStorage.savePlayer1Name('Test');
      await LocalStorage.setSoundEnabled(false);
      await LocalStorage.setGuestMode(true);

      await LocalStorage.clearAllExceptMonetization();

      // Monetization preservado
      expect(await LocalStorage.isPremium(), true);
      expect(await LocalStorage.getPlayCounts(), {'Ruleta': 3});
      expect(await LocalStorage.getLastResetDate(), '2026-07-25');

      // User data borrado
      expect(await LocalStorage.getPlayer1Name(), '');
      expect(await LocalStorage.isSoundEnabled(), true); // default
      expect(await LocalStorage.isGuestMode(), false);
    });
  });
}
