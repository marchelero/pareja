import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../controllers/duel_controller.dart';
import '../../services/audio_service.dart';
import '../../widgets/game_button.dart';
import '../../widgets/game_help_modal.dart';
import '../../widgets/neon_background.dart';
import '../../core/theme/app_colors.dart';
import 'duel_game_screen.dart';

class DuelStartScreen extends StatefulWidget {
  const DuelStartScreen({super.key});

  @override
  State<DuelStartScreen> createState() => _DuelStartScreenState();
}

class _DuelStartScreenState extends State<DuelStartScreen> {
  String _player1Name = 'ÉL';
  String _player2Name = 'ELLA';
  int _maxRounds = 10;

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
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('DUELO NOCTURNO', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [Padding(padding: const EdgeInsets.only(right: 8), child: GameHelpModal.helpButton(_showHelpModal))],
      ),
      body: NeonBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildSectionTitle('RONDAS'),
              _buildCard(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Cantidad:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
                        Text('$_maxRounds', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, shadows: [Shadow(color: AppColors.modeMostLikely, blurRadius: 10)])),
                      ],
                    ),
                    Slider(
                      value: _maxRounds.toDouble(),
                      min: 5,
                      max: 20,
                      divisions: 15,
                      activeColor: AppColors.modeMostLikely,
                      inactiveColor: Colors.white10,
                      onChanged: (val) => setState(() => _maxRounds = val.toInt()),
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

  Widget _buildStartButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: GameButton(
        text: 'EMPEZAR',
        onPressed: () async {
          await context.read<SettingsProvider>().setPlayer1Name(_player1Name);
          await context.read<SettingsProvider>().setPlayer2Name(_player2Name);
          if (!mounted) return;
          final audioService = context.read<AudioService>();
          final settingsProvider = context.read<SettingsProvider>();
          final controller = DuelController(
            audioService: audioService,
            settingsProvider: settingsProvider,
            maxRounds: _maxRounds,
          );
          await controller.initGame();
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DuelGameScreen(controller: controller),
            ),
          );
        },
        style: GameButtonStyle.primary,
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
          shadows: [Shadow(color: Colors.black, blurRadius: 5)],
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: child,
        ),
      ),
    );
  }

  void _showHelpModal() {
    GameHelpModal.show(
      context: context,
      sections: [
        GameHelpModal.step('1', 'Sale una frase: "¿Quién es más probable que...".'),
        GameHelpModal.step('2', 'Discutan y elijan quién se lleva la frase (tú o él/ella).'),
        GameHelpModal.bullet('Pierdes', 'si tu pareja no coincide contigo.', Colors.redAccent, ''),
        GameHelpModal.bullet('Ganas', 'si tu pareja coincide contigo.', Colors.greenAccent, ''),
      ],
    );
  }
}
