import 'package:pareja/providers/settings_provider.dart';
import 'package:pareja/services/audio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Helpers compartidos para los tests de `lib/controllers/`.
//
// Reglas de oro (aprendidas a lo largo de esta suite):
//  - JAMAS hacer await de metodos de AudioService (play/stop/dispose):
//    el metodo channel de audioplayers no responde en flutter test y
//    colgaria el test para siempre. Los controllers llaman al audio
//    fire-and-forget; con `setEnabled(false)` esas llamadas son no-ops
//    seguros.
//  - Todas las prefs de SharedPreferences se siembran aca para que los
//    nombres/colores de los jugadores sean deterministas.

const kPlayer1 = 'Marcelo';
const kPlayer2 = 'Martina';

/// AudioService con el sonido forzado a OFF.
AudioService buildAudio() {
  final audio = AudioService();
  audio.setEnabled(false);
  return audio;
}

/// SettingsProvider cargado con prefs deterministicas (sonido off,
/// vibracion off, nombres custom). `extraPrefs` permite sembrar mas keys
/// (p. ej. `used_drink_tasks`, `roulette_spin_count`).
Future<SettingsProvider> buildSettings({
  String player1 = kPlayer1,
  String player2 = kPlayer2,
  int rouletteSpinCount = 0,
  Map<String, Object> extraPrefs = const {},
}) async {
  SharedPreferences.setMockInitialValues({
    'sound_enabled': false,
    'vibration_enabled': false,
    'player1_name': player1,
    'player2_name': player2,
    'roulette_spin_count': rouletteSpinCount,
    ...extraPrefs,
  });
  final s = SettingsProvider();
  await s.load();
  return s;
}