import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/audio_service.dart';
import '../../controllers/roulette_controller.dart';
import '../questions/coin_flip_screen.dart';
import '../../widgets/game_button.dart';
import '../../widgets/game_help_modal.dart';
import '../../widgets/neon_background.dart';
import '../../widgets/player_names_section.dart';
import '../../widgets/glass_card.dart';
import 'roulette_game_screen.dart';

class RouletteStartScreen extends StatefulWidget {
  const RouletteStartScreen({super.key});

  @override
  State<RouletteStartScreen> createState() => _RouletteStartScreenState();
}

class _RouletteStartScreenState extends State<RouletteStartScreen> {
  String _player1Name = 'ÉL';
  String _player2Name = 'ELLA';
  bool _isDareMode = false;

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
                  'Giren la ruleta y cumplan el desafío que salga. '
                  'Gana el primero en llegar a la meta.',
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
                  setState(() {
                    _player1Name = p1;
                    _player2Name = p2;
                  });
                },
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('TIPO DE RULETA', Icons.auto_awesome),
              const SizedBox(height: 8),
              GlassCard(
                child: Row(
                  children: [
                    Expanded(
                      child: _ModeCard(
                        title: 'Normal',
                        subtitle: 'Diversión suave',
                        icon: Icons.sentiment_satisfied,
                        color: Colors.blue,
                        isSelected: !_isDareMode,
                        onTap: () =>
                            setState(() => _isDareMode = false),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _ModeCard(
                        title: 'Atrevida',
                        subtitle: 'Más picante',
                        icon: Icons.whatshot,
                        color: Colors.deepOrange,
                        isSelected: _isDareMode,
                        onTap: () =>
                            setState(() => _isDareMode = true),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildResetProgressCard(),
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
        'RULETA',
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

  Widget _buildResetProgressCard() {
    return GlassCard(
      child: InkWell(
        onTap: () async {
          final settings = context.read<SettingsProvider>();
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF1A0A2E),
              title: const Text('Reiniciar progreso',
                  style: TextStyle(color: Colors.white)),
              content: const Text(
                '¿Estás seguro de que quieres reiniciar '
                'el progreso de la ruleta?',
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(context, false),
                  child: const Text('Cancelar',
                      style: TextStyle(color: Colors.white54)),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.pop(context, true),
                  child: const Text('Reiniciar',
                      style:
                          TextStyle(color: Colors.pinkAccent)),
                ),
              ],
            ),
          );
          if (confirm == true) {
            await settings.resetRouletteProgress();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('Progreso de ruleta reiniciado')),
              );
            }
          }
        },
        child: Container(
          width: double.infinity,
          height: 45,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(
                color: Colors.redAccent.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.refresh,
                  color: Colors.redAccent, size: 18),
              SizedBox(width: 8),
              Text(
                'REINICIAR PROGRESO',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Colors.redAccent,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
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

          if (!context.mounted) return;

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
                  final audioService =
                      context.read<AudioService>();
                  final settingsProvider =
                      context.read<SettingsProvider>();
                  final controller = RouletteController(
                    audioService: audioService,
                    settingsProvider: settingsProvider,
                    isDareMode: _isDareMode,
                    startingPlayerIsP1: isP1Winner,
                  );
                  await controller.initGame();
                  return RouletteGameScreen(
                      controller: controller);
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
        GameHelpModal.step('1', 'Gira la ruleta para ver tu desafío.'),
        GameHelpModal.step('2', 'Cumple el desafío que aparezca.'),
        GameHelpModal.step(
            '3', 'El modo Atrevida añade desafíos más intensos.'),
        GameHelpModal.text(
            'Los desafíos pueden ser preguntas, acciones, o pruebas para ambos.'),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? color : Colors.white.withValues(alpha: 0.1),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 40,
                color: isSelected ? Colors.white : color),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white70 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
