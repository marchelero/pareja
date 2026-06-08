import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/audio_service.dart';
import '../../controllers/russian_roulette_controller.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/game_button.dart';
import '../../widgets/game_help_modal.dart';
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
  bool _wildMode = false;
  int _bulletCount = 2;

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
                child: AppBar(
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () {
                      _playSound();
                      Navigator.pop(context);
                    },
                  ),
                  title: const Text('RULETA RUSA', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold)),
                  centerTitle: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  foregroundColor: Colors.white,
                  actions: [Padding(padding: const EdgeInsets.only(right: 8), child: GameHelpModal.helpButton(_showHelpModal))],
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
                          player1Icon: context.read<SettingsProvider>().player1Icon,
                          player2Icon: context.read<SettingsProvider>().player2Icon,
                          player1Color: context.read<SettingsProvider>().player1Color,
                          player2Color: context.read<SettingsProvider>().player2Color,
                          onChanged: (p1, p2) {
                            context.read<SettingsProvider>().setPlayer1Name(p1);
                            context.read<SettingsProvider>().setPlayer2Name(p2);
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
                                  const SizedBox(height: 20),
                                  _buildSettingRow(
                                    icon: Icons.flash_on, title: 'Modo Salvaje:',
                                    child: Switch.adaptive(
                                      value: _wildMode,
                                      activeTrackColor: AppColors.modeRussianRoulette,
                                      activeThumbColor: AppColors.modeRussianRoulette,
                                      onChanged: (v) => setState(() => _wildMode = v),
                                    ),
                                  ),
                                  if (_wildMode) ...[
                                    const SizedBox(height: 15),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [2, 3, 4, 5].map((n) {
                                        final selected = _bulletCount == n;
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 5),
                                          child: GestureDetector(
                                            onTap: () => setState(() => _bulletCount = n),
                                            child: Container(
                                              width: 48, height: 48,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: selected
                                                    ? AppColors.modeRussianRoulette
                                                    : Colors.white.withValues(alpha: 0.1),
                                                border: Border.all(
                                                  color: selected
                                                      ? AppColors.modeRussianRoulette
                                                      : Colors.white.withValues(alpha: 0.2),
                                                  width: 2,
                                                ),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  '$n',
                                                  style: TextStyle(
                                                    color: selected ? Colors.white : Colors.white54,
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.only(top: 6),
                                      child: Text('balas', style: TextStyle(color: Colors.white38, fontSize: 12)),
                                    ),
                                  ],
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
                child: GameButton(
                  text: 'EMPEZAR',
                  onPressed: () async {
                    _playSound();
                    final audioService = context.read<AudioService>();
                    final settingsProvider = context.read<SettingsProvider>();
                    final controller = RussianRouletteController(
                      audioService: audioService,
                      settingsProvider: settingsProvider,
                      bestOf: _bestOf,
                      wildMode: _wildMode,
                      bulletCount: _bulletCount,
                    );
                    await controller.initGame();
                    if (!context.mounted) return;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => RussianRouletteGameScreen(controller: controller)),
                    );
                  },
                  style: GameButtonStyle.primary,
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

  void _showHelpModal() {
    GameHelpModal.show(
      context: context,
      sections: [
        GameHelpModal.step('1', 'Cada ronda se carga una bala en una posición aleatoria.'),
        GameHelpModal.step('2', 'Por turnos, cada jugador aprieta el gatillo.'),
        GameHelpModal.step('3', 'Si te disparan, pierdes la ronda. El otro suma un punto.'),
        GameHelpModal.bullet('Te disparan', 'pierdes la ronda, el rival suma 1.', Colors.redAccent, ''),
        GameHelpModal.bullet('Gana la partida', 'quien llegue primero a la puntuación objetivo.', Colors.greenAccent, ''),
      ],
    );
  }
}
