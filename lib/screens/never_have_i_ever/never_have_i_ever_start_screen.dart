import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/audio_service.dart';
import '../../controllers/never_have_i_ever_controller.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/neon_background.dart';
import '../../widgets/player_names_section.dart';
import 'never_have_i_ever_game_screen.dart';

class NeverHaveIEverStartScreen extends StatefulWidget {
  const NeverHaveIEverStartScreen({super.key});

  @override
  State<NeverHaveIEverStartScreen> createState() => _NeverHaveIEverStartScreenState();
}

class _NeverHaveIEverStartScreenState extends State<NeverHaveIEverStartScreen> {
  int _rounds = 10;
  int _pointsToWin = 5;
  int _strikesForPenance = 3;
  bool _isHotMode = false;

  void _playSound() {
    context.read<AudioService>().playClick();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NeonBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () {
                        _playSound();
                        Navigator.pop(context);
                      },
                    ),
                    const Expanded(
                      child: Text('YO NUNCA \u{1F48B}', textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 3)),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text('Responde YO o NUNCA. Si hay disparidad, quien dijo YO recibe un strike.',
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 14)),
              ),
              const SizedBox(height: 15),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: PlayerNamesSection(
                          onChanged: (he, she) {
                            context.read<SettingsProvider>().saveNames(he, she);
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.all(25),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Column(
                                children: [
                                  _buildSettingRow(
                                    icon: Icons.repeat, title: 'Rondas:',
                                    child: DropdownButton<int>(
                                      value: _rounds,
                                      dropdownColor: Colors.black87,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                      underline: const SizedBox(),
                                      icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                                      items: [5, 10, 15, 20].map((int value) {
                                        return DropdownMenuItem<int>(value: value, child: Text('$value rondas'));
                                      }).toList(),
                                      onChanged: (int? newValue) {
                                        if (newValue != null) { _playSound(); setState(() => _rounds = newValue); }
                                      },
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 10),
                                    child: Divider(color: Colors.white12, height: 1),
                                  ),
                                  _buildSettingRow(
                                    icon: Icons.emoji_events, title: 'Puntos para ganar:',
                                    child: DropdownButton<int>(
                                      value: _pointsToWin,
                                      dropdownColor: Colors.black87,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                      underline: const SizedBox(),
                                      icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                                      items: [3, 5, 7].map((int value) {
                                        return DropdownMenuItem<int>(value: value, child: Text('$value puntos'));
                                      }).toList(),
                                      onChanged: (int? newValue) {
                                        if (newValue != null) { _playSound(); setState(() => _pointsToWin = newValue); }
                                      },
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 10),
                                    child: Divider(color: Colors.white12, height: 1),
                                  ),
                                  _buildSettingRow(
                                    icon: Icons.bolt, title: 'Strikes por penitencia:',
                                    child: DropdownButton<int>(
                                      value: _strikesForPenance,
                                      dropdownColor: Colors.black87,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                      underline: const SizedBox(),
                                      icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                                      items: [3, 5].map((int value) {
                                        return DropdownMenuItem<int>(value: value, child: Text('$value strikes'));
                                      }).toList(),
                                      onChanged: (int? newValue) {
                                        if (newValue != null) { _playSound(); setState(() => _strikesForPenance = newValue); }
                                      },
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 10),
                                    child: Divider(color: Colors.white12, height: 1),
                                  ),
                                  _buildSettingRow(
                                    icon: Icons.whatshot, iconColor: Colors.pinkAccent, title: 'Modo Hot',
                                    child: Switch(
                                      value: _isHotMode,
                                      onChanged: (value) { _playSound(); setState(() => _isHotMode = value); },
                                      activeThumbColor: Colors.pinkAccent,
                                      activeTrackColor: Colors.pinkAccent.withValues(alpha: 0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                child: SizedBox(
                  width: double.infinity, height: 60,
                  child: ElevatedButton(
                    onPressed: () async {
                      _playSound();
                      final audioService = context.read<AudioService>();
                      final settingsProvider = context.read<SettingsProvider>();
                      final controller = NeverHaveIEverController(
                        audioService: audioService,
                        settingsProvider: settingsProvider,
                        rounds: _rounds,
                        pointsToWin: _pointsToWin,
                        strikesForPenance: _strikesForPenance,
                        isHotMode: _isHotMode,
                      );
                      await controller.initGame();
                      if (!context.mounted) return;
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => NeverHaveIEverGameScreen(controller: controller)),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isHotMode ? Colors.pink : const Color(0xFFFF416C),
                      foregroundColor: Colors.white, elevation: 10,
                      shadowColor: _isHotMode ? Colors.pink : const Color(0xFFFF416C),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('\u{1F680} \u{A1}EMPEZAR!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingRow({required IconData icon, Color iconColor = Colors.white70, required String title, required Widget child}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 15),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        child,
      ],
    );
  }
}
