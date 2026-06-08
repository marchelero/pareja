import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/atiempo_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/settings_provider.dart';
import '../../services/audio_service.dart';
import '../questions/coin_flip_screen.dart';
import '../../widgets/game_button.dart';
import '../../widgets/game_help_modal.dart';
import '../../widgets/neon_background.dart';
import '../../widgets/player_names_section.dart';
import 'atiempo_game_screen.dart';

class ATiempoStartScreen extends StatefulWidget {
  const ATiempoStartScreen({super.key});

  @override
  State<ATiempoStartScreen> createState() => _ATiempoStartScreenState();
}

class _ATiempoStartScreenState extends State<ATiempoStartScreen> {
  String _player1Name = 'ÉL';
  String _player2Name = 'ELLA';
  int _pointsPerRound = 3;
  int _matchRounds = 3;
  double _targetTime = 10.0;
  bool _wildMode = false;

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
        title: const Text('A TIEMPO', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold)),
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
              _buildSectionTitle('JUGADORES'),
              const SizedBox(height: 8),
              PlayerNamesSection(
                player1Icon: context.read<SettingsProvider>().player1Icon,
                player2Icon: context.read<SettingsProvider>().player2Icon,
                player1Color: context.read<SettingsProvider>().player1Color,
                player2Color: context.read<SettingsProvider>().player2Color,
                onChanged: (p1, p2) => setState(() {
                  _player1Name = p1;
                  _player2Name = p2;
                }),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('PUNTOS PARA GANAR RONDA'),
              _buildCard(
                child: Row(
                  children: [3, 5, 7].map((v) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: v > 3 ? 8 : 0),
                      child: _buildChip('$v', v == _pointsPerRound, AppColors.modeATiempo, () => setState(() => _pointsPerRound = v)),
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('RONDAS AL MEJOR DE'),
              _buildCard(
                child: Row(
                  children: [3, 5, 7].map((v) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: v > 3 ? 8 : 0),
                      child: _buildChip('$v', v == _matchRounds, AppColors.modeATiempo, () => setState(() => _matchRounds = v)),
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('TIEMPO OBJETIVO (segundos)'),
              _buildCard(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Objetivo:', style: TextStyle(color: _wildMode ? Colors.white.withValues(alpha: 0.3) : Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
                        Text('${_targetTime.toInt()}s', style: TextStyle(color: _wildMode ? Colors.white.withValues(alpha: 0.2) : AppColors.modeATiempo, fontSize: 28, fontWeight: FontWeight.w900, shadows: _wildMode ? null : [Shadow(color: AppColors.modeATiempo, blurRadius: 10)])),
                      ],
                    ),
                    if (_wildMode)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shuffle, color: Colors.white.withValues(alpha: 0.3), size: 16),
                            const SizedBox(width: 8),
                            Text('Automático (1s — 10s)', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1)),
                          ],
                        ),
                      )
                    else
                      SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: AppColors.modeATiempo,
                          inactiveTrackColor: Colors.white10,
                          thumbColor: AppColors.modeATiempo,
                          overlayColor: AppColors.modeATiempo.withValues(alpha: 0.2),
                        ),
                        child: Slider(
                          value: _targetTime,
                          min: 1, max: 10, divisions: 9,
                          onChanged: (val) => setState(() => _targetTime = val),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('MODO SALVAJE', style: TextStyle(color: _wildMode ? const Color(0xFFFFD700) : Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2)),
                        Text('Objetivo aleatorio cada ronda', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    Switch(
                      value: _wildMode,
                      activeThumbColor: const Color(0xFFFFD700),
                      activeTrackColor: const Color(0xFFFFD700).withValues(alpha: 0.3),
                      onChanged: (val) => setState(() => _wildMode = val),
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

  Widget _buildChip(String label, bool selected, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.15),
          ),
        ),
        child: Center(
          child: Text(label, style: TextStyle(
            color: selected ? Colors.white : Colors.white.withValues(alpha: 0.7),
            fontSize: 20,
            fontWeight: FontWeight.w900,
          )),
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
          final settings = context.read<SettingsProvider>();
          final audioService = context.read<AudioService>();
          await settings.setPlayer1Name(_player1Name);
          await settings.setPlayer2Name(_player2Name);
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CoinFlipScreen(
                player1Name: _player1Name,
                player2Name: _player2Name,
                player1Color: settings.player1Color,
                player2Color: settings.player2Color,
                createGameScreen: (isP1Winner) async {
                  final controller = ATiempoController(
                    audioService: audioService,
                    settingsProvider: settings,
                    pointsPerRound: _pointsPerRound,
                    matchRounds: _matchRounds,
                    targetTime: _targetTime,
                    wildMode: _wildMode,
                  );
                  controller.initGame();
                  controller.setStartingPlayer(isP1Winner);
                  return ATiempoGameScreen(controller: controller);
                },
              ),
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
      child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 2, shadows: [Shadow(color: Colors.black, blurRadius: 5)])),
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
        GameHelpModal.step('1', 'Cada jugador debe parar el cronómetro lo más cerca posible del tiempo objetivo.'),
        GameHelpModal.step('2', 'El jugador activo pulsa "PARAR" para detener el tiempo.'),
        GameHelpModal.step('3', 'El que se acerque más al objetivo gana la ronda.'),
        GameHelpModal.bullet('Gana la ronda', 'quien se acerque más al tiempo objetivo.', Colors.greenAccent, 'suma 1 punto'),
        GameHelpModal.bullet('Gana la partida', 'quien gane más rondas.', Colors.amberAccent, 'mejor de 3/5'),
      ],
    );
  }
}
