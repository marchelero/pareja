import 'package:flutter_test/flutter_test.dart';
import 'package:pareja/core/storage/local_storage.dart';
import 'package:pareja/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('SettingsProvider.resetAllData — preserva premium', () {
    test('user data se resetea, premium se mantiene', () async {
      // Setup: user con premium + data de uso.
      await LocalStorage.setIsPremium(true);
      await LocalStorage.savePlayCounts({'Ruleta': 2});
      await LocalStorage.savePlayer1Name('Marce');
      await LocalStorage.setFriendsMode(true);
      await LocalStorage.setSoundEnabled(false);

      final settings = SettingsProvider();
      await settings.load();
      expect(settings.player1Name, 'Marce');
      expect(settings.friendsMode, true);
      expect(settings.soundEnabled, false);

      await settings.resetAllData();

      // User data reseteado a defaults
      expect(settings.player1Name, 'ÉL'); // default he name (con acento)
      expect(settings.friendsMode, false);
      expect(settings.soundEnabled, true);

      // Pero premium persistido en LocalStorage
      expect(await LocalStorage.isPremium(), true);
      // Y play counts (parte de monetization) tambien
      expect(await LocalStorage.getPlayCounts(), {'Ruleta': 2});
    });

    test('reset sin premium previo: premium sigue false', () async {
      await LocalStorage.savePlayer1Name('Test');

      final settings = SettingsProvider();
      await settings.load();
      await settings.resetAllData();

      expect(await LocalStorage.isPremium(), false);
      expect(settings.player1Name, 'ÉL');
    });
  });
}
