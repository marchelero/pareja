import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/tiradedos_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/settings_provider.dart';
import '../../services/audio_service.dart';
import '../../widgets/game_button.dart';
import '../../widgets/neon_background.dart';
import '../../widgets/player_names_section.dart';
import 'tiradedos_game_screen.dart';

class TiradedosStartScreen extends StatefulWidget {
  const TiradedosStartScreen({super.key});

  @override
  State<TiradedosStartScreen> createState() => _TiradedosStartScreenState();
}

class _TiradedosStartScreenState extends State<TiradedosStartScreen> {
  String _player1Name = '';
  String _player2Name = '';

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
        title: const Text('TIRADEDOS', style: TextStyle(letterSpacing: 3, fontWeight: FontWeight.w900)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: NeonBackground(
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),
              Icon(Icons.touch_app, size: 72, color: AppColors.modeTiradedos.withValues(alpha: 0.6)),
              const SizedBox(height: 16),
              Text(
                'SELECTOR DE VÍCTIMA',
                style: TextStyle(
                  color: AppColors.modeTiradedos,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Cada uno pone un dedo en la pantalla.\nUno será elegido al azar.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildCard(
                  child: PlayerNamesSection(
                    player1Icon: context.read<SettingsProvider>().player1Icon,
                    player2Icon: context.read<SettingsProvider>().player2Icon,
                    player1Color: context.read<SettingsProvider>().player1Color,
                    player2Color: context.read<SettingsProvider>().player2Color,
                    onChanged: (p1, p2) => setState(() {
                      _player1Name = p1;
                      _player2Name = p2;
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: GameButton(
                  text: 'EMPEZAR',
                  customColor: AppColors.modeTiradedos,
                  onPressed: () async {
                    final settings = context.read<SettingsProvider>();
                    final audioService = context.read<AudioService>();
                    final nav = Navigator.of(context);
                    await settings.setPlayer1Name(_player1Name);
                    await settings.setPlayer2Name(_player2Name);
                    if (!mounted) return;
                    final controller = TiradedosController(
                      audioService: audioService,
                      settingsProvider: settings,
                    );
                    controller.initGame();
                    nav.push(
                      MaterialPageRoute(
                        builder: (context) => TiradedosGameScreen(controller: controller),
                      ),
                    );
                  },
                  style: GameButtonStyle.primary,
                ),
              ),
              const SizedBox(height: 60),
            ],
          ),
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
}
