import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/memory_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/settings_provider.dart';
import '../../services/audio_service.dart';
import '../questions/coin_flip_screen.dart';
import '../../widgets/game_button.dart';
import '../../widgets/game_help_modal.dart';
import '../../widgets/neon_background.dart';
import '../../widgets/player_names_section.dart';
import '../../widgets/glass_card.dart';
import 'memory_game_screen.dart';

class MemoryStartScreen extends StatefulWidget {
  const MemoryStartScreen({super.key});

  @override
  State<MemoryStartScreen> createState() => _MemoryStartScreenState();
}

class _MemoryStartScreenState extends State<MemoryStartScreen> {
  String _player1Name = 'ÉL';
  String _player2Name = 'ELLA';
  int _maxRounds = 8;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _player1Name = settings.player1Name;
    _player2Name = settings.player2Name;
  }

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
                  'Encuentren pares de cartas. '
                  'Gana quien tenga más pares al final.',
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
                  context.read<SettingsProvider>().setPlayer1Name(p1);
                  context.read<SettingsProvider>().setPlayer2Name(p2);
                  setState(() {
                    _player1Name = p1;
                    _player2Name = p2;
                  });
                },
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('RONDAS', Icons.repeat),
              const SizedBox(height: 8),
              GlassCard(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
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
                          '$_maxRounds',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            shadows: [
                              Shadow(
                                color: AppColors.modeMemory,
                                blurRadius: 10,
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _maxRounds.toDouble(),
                      min: 3,
                      max: 15,
                      divisions: 12,
                      activeColor: AppColors.modeMemory,
                      inactiveColor: Colors.white10,
                      onChanged: (val) =>
                          setState(() => _maxRounds = val.toInt()),
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
        'MEMORIA',
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
          await context
              .read<SettingsProvider>()
              .setPlayer1Name(_player1Name);
          await context
              .read<SettingsProvider>()
              .setPlayer2Name(_player2Name);
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CoinFlipScreen(
                player1Name: _player1Name,
                player2Name: _player2Name,
                player1Color:
                    context.read<SettingsProvider>().player1Color,
                player2Color:
                    context.read<SettingsProvider>().player2Color,
                createGameScreen: (isP1Winner) async {
                  final audioService = context.read<AudioService>();
                  final settingsProvider =
                      context.read<SettingsProvider>();
                  final controller = MemoryController(
                    audioService: audioService,
                    settingsProvider: settingsProvider,
                    maxRounds: _maxRounds,
                  );
                  await controller.initGame();
                  controller.setStartingPlayer(isP1Winner);
                  controller.startRound();
                  return MemoryGameScreen(controller: controller);
                },
              ),
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
            '1', 'Se ilumina una secuencia de colores.'),
        GameHelpModal.step('2',
            'Repite la secuencia tocando los botones en el mismo orden.'),
        GameHelpModal.step('3',
            'Cada ronda añade un color más. Si fallas, pierdes la ronda.'),
        GameHelpModal.bullet(null, 'Pierde la ronda', Colors.redAccent,
            'quien falle al repetir la secuencia.'),
        GameHelpModal.bullet(
            null, 'Gana la partida', Colors.greenAccent,
            'quien gane más rondas.'),
      ],
    );
  }
}
