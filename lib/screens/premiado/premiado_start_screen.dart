import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/premiado_controller.dart';
import '../../providers/settings_provider.dart';
import '../../services/audio_service.dart';
import '../../widgets/game_button.dart';
import '../../widgets/game_help_modal.dart';
import '../../widgets/neon_background.dart';
import '../../widgets/player_names_section.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/setting_row.dart';
import 'premiado_game_screen.dart';

class PremiadoStartScreen extends StatefulWidget {
  const PremiadoStartScreen({super.key});

  @override
  State<PremiadoStartScreen> createState() => _PremiadoStartScreenState();
}

class _PremiadoStartScreenState extends State<PremiadoStartScreen> {
  int _bestOf = 3;

  int get _pointsToWin => (_bestOf / 2).floor() + 1;

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
                  'Cada uno pone un dedo y uno es elegido al azar.\nEl otro suma 1 punto.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
              _buildSectionTitle('JUGADORES', Icons.people),
              const SizedBox(height: 8),
              PlayerNamesSection(
                player1Icon: context.read<SettingsProvider>().player1Icon,
                player2Icon: context.read<SettingsProvider>().player2Icon,
                player1Color: context.read<SettingsProvider>().player1Color,
                player2Color: context.read<SettingsProvider>().player2Color,
                onChanged: (p1, p2) {},
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('CONFIGURACIÓN', Icons.tune),
              const SizedBox(height: 8),
              GlassCard(
                child: SettingRow(
                  icon: Icons.emoji_events,
                  title: 'Formato:',
                  child: SettingDropdown<int>(
                    value: _bestOf,
                    items: [3, 5, 7],
                    labelBuilder: (v) => 'Al mejor de $v',
                    onChanged: (v) {
                      if (v != null) setState(() => _bestOf = v);
                    },
                  ),
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
        'PREMIADO',
        style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios),
        onPressed: () => Navigator.pop(context),
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
          final settings = context.read<SettingsProvider>();
          final audioService = context.read<AudioService>();
          final controller = PremiadoController(
            audioService: audioService,
            settingsProvider: settings,
            pointsToWin: _pointsToWin,
          );
          controller.initGame();
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  PremiadoGameScreen(controller: controller),
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
            '1', 'Cada jugador coloca un dedo en la pantalla.'),
        GameHelpModal.step('2',
            'Cuando ambos tocan, se selecciona aleatoriamente a uno.'),
        GameHelpModal.step(
            '3', 'El seleccionado pierde la ronda y el otro suma un punto.'),
        GameHelpModal.bullet(
            null, 'Te seleccionan', Colors.redAccent,
            'pierdes la ronda, rival suma 1.'),
        GameHelpModal.bullet(
            null, 'Gana la partida', Colors.greenAccent,
            'quien llegue primero a la puntuación objetivo.'),
      ],
    );
  }
}
