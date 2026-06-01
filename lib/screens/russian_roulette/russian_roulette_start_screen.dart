import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/audio_service.dart';
import '../../controllers/russian_roulette_controller.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/neon_background.dart';
import '../../widgets/player_names_section.dart';
import '../../core/theme/app_colors.dart';
import 'russian_roulette_game_screen.dart';

class RussianRouletteStartScreen extends StatefulWidget {
  const RussianRouletteStartScreen({super.key});

  @override
  State<RussianRouletteStartScreen> createState() => _RussianRouletteStartScreenState();
}

class _RussianRouletteStartScreenState extends State<RussianRouletteStartScreen> {
  int _bestOf = 3;

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
                      child: Text('RULETA RUSA', textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 3)),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text('Tira del gatillo… pero no sabes en qué cámara está la bala.\n¡El que se lleva el disparo pierde la ronda!',
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
                                    icon: Icons.emoji_events, title: 'Formato:',
                                    child: DropdownButton<int>(
                                      value: _bestOf, dropdownColor: Colors.black87,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                      underline: const SizedBox(),
                                      icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                                      items: [3, 5, 7].map((int value) {
                                        return DropdownMenuItem<int>(value: value, child: Text('Al mejor de $value'));
                                      }).toList(),
                                      onChanged: (int? newValue) {
                                        if (newValue != null) { _playSound(); setState(() => _bestOf = newValue); }
                                      },
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
                      final controller = RussianRouletteController(
                        audioService: audioService,
                        settingsProvider: settingsProvider,
                        bestOf: _bestOf,
                      );
                      await controller.initGame();
                      if (!context.mounted) return;
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => RussianRouletteGameScreen(controller: controller)),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.modeRussianRoulette,
                      foregroundColor: Colors.white, elevation: 10,
                      shadowColor: AppColors.modeRussianRoulette,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.gps_fixed, size: 24),
                        SizedBox(width: 10),
                        Text('¡EMPEZAR PARTIDA!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2)),
                      ],
                    ),
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
