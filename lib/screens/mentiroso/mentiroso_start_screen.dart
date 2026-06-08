import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/mentiroso_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/settings_provider.dart';
import '../../services/audio_service.dart';
import '../../widgets/game_button.dart';
import '../../widgets/game_help_modal.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/neon_background.dart';
import '../../widgets/player_names_section.dart';
import '../questions/coin_flip_screen.dart';
import 'mentiroso_game_screen.dart';

class MentirosoStartScreen extends StatefulWidget {
  const MentirosoStartScreen({super.key});

  @override
  State<MentirosoStartScreen> createState() => _MentirosoStartScreenState();
}

class _MentirosoStartScreenState extends State<MentirosoStartScreen> {
  int _totalRounds = 5;

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
                  'Lanza los dados y haz una afirmaci\u00f3n. '
                  'El otro debe descubrir si dices la verdad o mientes.',
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
                onChanged: (p1, p2) {
                  context
                      .read<SettingsProvider>()
                      .setPlayer1Name(p1);
                  context
                      .read<SettingsProvider>()
                      .setPlayer2Name(p2);
                  setState(() {});
                },
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('RONDAS', Icons.repeat),
              const SizedBox(height: 8),
              GlassCard(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Cantidad:',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          '$_totalRounds',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            shadows: [
                              Shadow(
                                color: AppColors.modeMentiroso,
                                blurRadius: 10,
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _totalRounds.toDouble(),
                      min: 3,
                      max: 11,
                      divisions: 8,
                      activeColor: AppColors.modeMentiroso,
                      inactiveColor: Colors.white10,
                      onChanged: (val) =>
                          setState(() => _totalRounds = val.toInt()),
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
        'MENTIROSO',
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
        Icon(icon, color: AppColors.modeMentiroso, size: 24),
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
        onPressed: () {
          final settings = context.read<SettingsProvider>();
          final audioService = context.read<AudioService>();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CoinFlipScreen(
                player1Name: settings.displayName1,
                player2Name: settings.displayName2,
                player1Color: settings.player1Color,
                player2Color: settings.player2Color,
                createGameScreen: (isP1Winner) async {
                  final controller = MentirosoController(
                    audioService: audioService,
                    totalRounds: _totalRounds,
                  );
                  controller.setStartingPlayer(isP1Winner);
                  return MentirosoGameScreen(controller: controller);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  void _showHelpModal() {
    GameHelpModal.show(
      context: context,
      sections: [
        GameHelpModal.step('1', 'El jugador activo lanza los dados y ve su resultado.'),
        GameHelpModal.step('2', 'Elige una afirmaci\u00f3n (puede ser verdad o mentira).'),
        GameHelpModal.step('3', 'Pasa el celular al otro jugador.'),
        GameHelpModal.step('4', 'El segundo jugador debe decidir si la afirmaci\u00f3n es verdad o mentira.'),
        GameHelpModal.bullet(null, 'Acierta', Colors.greenAccent, 'punto para el que adivina'),
        GameHelpModal.bullet(null, 'Falla', Colors.redAccent, 'punto para el mentiroso'),
        GameHelpModal.bullet(null, 'Gana', AppColors.modeMentiroso, 'quien m\u00e1s puntos acumule al final'),
      ],
    );
  }
}
