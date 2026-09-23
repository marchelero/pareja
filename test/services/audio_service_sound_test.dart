import 'package:flutter_test/flutter_test.dart';
import 'package:pareja/services/audio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AudioService sound enabled persistence', () {
    testWidgets('reads persisted sound_enabled=false at startup',
        (tester) async {
      SharedPreferences.setMockInitialValues({'sound_enabled': false});
      final audio = AudioService();
      await tester.pump();
      expect(audio.enabled, isFalse);
    });

    testWidgets('setEnabled(false) + play no crash', (tester) async {
      final audio = AudioService();
      audio.setEnabled(false);
      await audio.play('clic.mp3');
      expect(audio.enabled, isFalse);
    });
  });
}