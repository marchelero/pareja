import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/premiado_controller.dart';
import '../../providers/settings_provider.dart';
import '../../services/audio_service.dart';
import '../../widgets/game_button.dart';
import '../../widgets/game_help_modal.dart';
import '../../widgets/neon_background.dart';
import '../../widgets/player_names_section.dart';
import 'premiado_game_screen.dart';

class PremiadoStartScreen extends StatefulWidget {
  const PremiadoStartScreen({super.key});

  @override
  State<PremiadoStartScreen> createState() => _PremiadoStartScreenState();
}

class _PremiadoStartScreenState extends State<PremiadoStartScreen> {
  int _bestOf = 3;

  int get _pointsToWin => (_bestOf / 2).floor() + 1;

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
                      child: Text('PREMIADO', textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 3)),
                    ),
                    const SizedBox(width: 48),
                    GameHelpModal.helpButton(_showHelpModal),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text('Cada uno pone un dedo y uno es elegido al azar.\nEl otro suma 1 punto.',
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
                    final settings = context.read<SettingsProvider>();
                    final audioService = context.read<AudioService>();
                    final controller = PremiadoController(
                      audioService: audioService,
                      settingsProvider: settings,
                      pointsToWin: _pointsToWin,
                    );
                    controller.initGame();
                    if (!context.mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PremiadoGameScreen(controller: controller)),
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
        GameHelpModal.step('1', 'Cada jugador coloca un dedo en la pantalla.'),
        GameHelpModal.step('2', 'Cuando ambos tocan, se selecciona aleatoriamente a uno.'),
        GameHelpModal.step('3', 'El seleccionado pierde la ronda y el otro suma un punto.'),
        GameHelpModal.bullet('Te seleccionan', 'pierdes la ronda, rival suma 1.', Colors.redAccent, ''),
        GameHelpModal.bullet('Gana la partida', 'quien llegue primero a la puntuación objetivo.', Colors.greenAccent, ''),
      ],
    );
  }
}
