import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/audio_service.dart';
import '../../services/haptics_service.dart';
import '../../controllers/russian_roulette_controller.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/game_button.dart';
import '../../widgets/game_help_modal.dart';
import '../../widgets/neon_background.dart';
import '../../widgets/player_names_section.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/setting_row.dart';
import '../../core/theme/app_colors.dart';
import 'russian_roulette_game_screen.dart';

class RussianRouletteStartScreen extends StatefulWidget {
  const RussianRouletteStartScreen({super.key});

  @override
  State<RussianRouletteStartScreen> createState() =>
      _RussianRouletteStartScreenState();
}

class _RussianRouletteStartScreenState
    extends State<RussianRouletteStartScreen> {
  int _bestOf = 3;
  bool _wildMode = false;
  int _bulletCount = 2;

  void _playSound() => context.read<AudioService>().playClick();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: NeonBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Text(
                  'Tira del gatillo… pero no sabes en qué cámara está la bala.\n'
                  '¡El que se lleva el disparo pierde la ronda!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
              _buildSectionTitle('JUGADORES', Icons.people),
              const SizedBox(height: 8),
              PlayerNamesSection(
                player1Icon:
                    context.read<SettingsProvider>().player1Icon,
                player2Icon:
                    context.read<SettingsProvider>().player2Icon,
                player1Color:
                    context.read<SettingsProvider>().player1Color,
                player2Color:
                    context.read<SettingsProvider>().player2Color,
                onChanged: (p1, p2) {},
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('CONFIGURACIÓN', Icons.tune),
              const SizedBox(height: 8),
              GlassCard(
                child: Column(
                  children: [
                    SettingRow(
                      icon: Icons.emoji_events,
                      title: 'Formato:',
                      child: SettingDropdown<int>(
                        value: _bestOf,
                        items: [3, 5, 7],
                        labelBuilder: (v) => 'Al mejor de $v',
                        onChanged: (v) {
                          if (v != null) {
                            _playSound();
                            setState(() => _bestOf = v);
                          }
                        },
                      ),
                    ),
                    const SettingDivider(),
                    SettingRow(
                      icon: Icons.flash_on,
                      title: 'Modo Salvaje:',
                      child: SettingSwitch(
                        value: _wildMode,
                        onChanged: (v) =>
                            setState(() => _wildMode = v),
                        activeColor: AppColors.modeRussianRoulette,
                      ),
                    ),
                    if (_wildMode) ...[
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [2, 3, 4, 5].map((n) {
                          final selected = _bulletCount == n;
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5),
                            child: GestureDetector(
                              onTap: () {
                                HapticsService.light();
                                setState(() => _bulletCount = n);
                              },
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: selected
                                      ? AppColors
                                          .modeRussianRoulette
                                      : Colors.white
                                          .withValues(alpha: 0.1),
                                  border: Border.all(
                                    color: selected
                                        ? AppColors
                                            .modeRussianRoulette
                                        : Colors.white.withValues(
                                            alpha: 0.2),
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '$n',
                                    style: TextStyle(
                                      color: selected
                                          ? Colors.white
                                          : Colors.white54,
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
                        child: Text(
                          'balas',
                          style: TextStyle(
                              color: Colors.white38, fontSize: 12),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 40),
              _buildStartButton(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text(
        'RULETA RUSA',
        style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios),
        onPressed: () {
          HapticsService.light();
          _playSound();
          Navigator.pop(context);
        },
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GameHelpModal.helpButton(_showHelpModal),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.pinkAccent, size: 24),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: Colors.white70,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildStartButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
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
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RussianRouletteGameScreen(
                  controller: controller),
            ),
          );
        },
        style: GameButtonStyle.primary,
      ),
    );
  }

  void _showHelpModal() {
    GameHelpModal.show(
      context: context,
      sections: [
        GameHelpModal.step(
            '1', 'Cada ronda se carga una bala en una posición aleatoria.'),
        GameHelpModal.step(
            '2', 'Por turnos, cada jugador aprieta el gatillo.'),
        GameHelpModal.step(
            '3', 'Si te disparan, pierdes la ronda. El otro suma un punto.'),
        GameHelpModal.bullet(null, 'Te disparan', Colors.redAccent,
            'pierdes la ronda, el rival suma 1.'),
        GameHelpModal.bullet(null, 'Gana la partida', Colors.greenAccent,
            'quien llegue primero a la puntuación objetivo.'),
      ],
    );
  }
}
