import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/audio_service.dart';
import '../../controllers/never_have_i_ever_controller.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/game_button.dart';
import '../../widgets/game_help_modal.dart';
import '../../widgets/neon_background.dart';
import '../../widgets/player_names_section.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/setting_row.dart';
import 'never_have_i_ever_game_screen.dart';

class NeverHaveIEverStartScreen extends StatefulWidget {
  const NeverHaveIEverStartScreen({super.key});

  @override
  State<NeverHaveIEverStartScreen> createState() =>
      _NeverHaveIEverStartScreenState();
}

class _NeverHaveIEverStartScreenState
    extends State<NeverHaveIEverStartScreen> {
  int _rounds = 10;
  int _pointsToWin = 5;
  int _strikesForPenance = 3;
  bool _isHotMode = false;

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
                  'Responde YO o NUNCA. '
                  'Si hay disparidad, quien dijo YO recibe un strike.',
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
                      icon: Icons.repeat,
                      title: 'Rondas:',
                      child: SettingDropdown<int>(
                        value: _rounds,
                        items: [5, 10, 15, 20],
                        labelBuilder: (v) => '$v rondas',
                        onChanged: (v) {
                          if (v != null) {
                            _playSound();
                            setState(() => _rounds = v);
                          }
                        },
                      ),
                    ),
                    const SettingDivider(),
                    SettingRow(
                      icon: Icons.emoji_events,
                      title: 'Puntos para ganar:',
                      child: SettingDropdown<int>(
                        value: _pointsToWin,
                        items: [3, 5, 7],
                        labelBuilder: (v) => '$v puntos',
                        onChanged: (v) {
                          if (v != null) {
                            _playSound();
                            setState(() => _pointsToWin = v);
                          }
                        },
                      ),
                    ),
                    const SettingDivider(),
                    SettingRow(
                      icon: Icons.bolt,
                      title: 'Strikes por penitencia:',
                      child: SettingDropdown<int>(
                        value: _strikesForPenance,
                        items: [3, 5],
                        labelBuilder: (v) => '$v strikes',
                        onChanged: (v) {
                          if (v != null) {
                            _playSound();
                            setState(() => _strikesForPenance = v);
                          }
                        },
                      ),
                    ),
                    const SettingDivider(),
                    SettingRow(
                      icon: Icons.whatshot,
                      iconColor: Colors.pinkAccent,
                      title: 'Modo Hot',
                      child: SettingSwitch(
                        value: _isHotMode,
                        onChanged: (v) {
                          _playSound();
                          setState(() => _isHotMode = v);
                        },
                      ),
                    ),
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
        'YO NUNCA',
        style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios),
        onPressed: () {
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
          final controller = NeverHaveIEverController(
            audioService: audioService,
            settingsProvider: settingsProvider,
            rounds: _rounds,
            pointsToWin: _pointsToWin,
            strikesForPenance: _strikesForPenance,
            isHotMode: _isHotMode,
          );
          await controller.initGame();
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NeverHaveIEverGameScreen(
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
        GameHelpModal.step('1', 'Se muestra una pregunta.'),
        GameHelpModal.step('2', 'Cada jugador responde por turno:'),
        GameHelpModal.bullet(
            'SI', 'SI, LO HE HECHO', Colors.greenAccent, 'lo has hecho'),
        GameHelpModal.bullet(
            'NO', 'NUNCA', Colors.orangeAccent, 'nunca lo has hecho'),
        GameHelpModal.step('3', 'RESULTADO:'),
        GameHelpModal.bullet(null, 'Si uno dice SI y el otro NO',
            Colors.orangeAccent, 'el que dijo NO gana 1 punto'),
        GameHelpModal.bullet(null, 'Si ambos dicen igual', Colors.grey,
            'nadie gana puntos'),
        GameHelpModal.step('4', '3 strikes = penitencia'),
      ],
    );
  }
}
