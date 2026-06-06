import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/pairs_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/settings_provider.dart';
import '../../services/audio_service.dart';
import '../questions/coin_flip_screen.dart';
import '../../widgets/game_button.dart';
import '../../widgets/neon_background.dart';
import '../../widgets/player_names_section.dart';
import 'pairs_game_screen.dart';

class PairsStartScreen extends StatefulWidget {
  const PairsStartScreen({super.key});

  @override
  State<PairsStartScreen> createState() => _PairsStartScreenState();
}

class _PairsStartScreenState extends State<PairsStartScreen> {
  String _player1Name = 'ÉL';
  String _player2Name = 'ELLA';
  int _maxRounds = 3;
  int _gridRows = 4;
  int _gridCols = 5;

  static const _gridOptions = [
    ('3×3', 3, 3),
    ('3×4', 3, 4),
    ('4×4', 4, 4),
    ('4×5', 4, 5),
    ('5×5', 5, 5),
  ];

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
        title: const Text('PARES', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
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
              _buildSectionTitle('RONDAS'),
              _buildCard(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Rondas:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
                        Text('$_maxRounds', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, shadows: [Shadow(color: AppColors.modePairs, blurRadius: 10)])),
                      ],
                    ),
                    Slider(
                      value: _maxRounds.toDouble(), min: 1, max: 7, divisions: 3,
                      activeColor: AppColors.modePairs,
                      inactiveColor: Colors.white10,
                      onChanged: (val) => setState(() => _maxRounds = val.toInt()),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('TABLERO'),
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tamaño del tablero', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
                    const SizedBox(height: 12),
                    Row(
                      children: [1, 2, 3].asMap().entries.map((e) {
                        final (label, rows, cols) = _gridOptions[e.value];
                        final selected = _gridRows == rows && _gridCols == cols;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(left: e.key > 0 ? 8 : 0),
                            child: GestureDetector(
                              onTap: () => setState(() {
                                _gridRows = rows;
                                _gridCols = cols;
                              }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: selected ? AppColors.modePairs.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: selected ? AppColors.modePairs.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.15),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(label, style: TextStyle(
                                      color: selected ? Colors.white : Colors.white.withValues(alpha: 0.7),
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                    )),
                                    const SizedBox(height: 4),
                                    Text('${rows * cols} fichas', style: TextStyle(
                                      color: selected ? AppColors.modePairs : Colors.white.withValues(alpha: 0.4),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1,
                                    )),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CoinFlipScreen(
                player1Name: _player1Name,
                player2Name: _player2Name,
                player1Color: context.read<SettingsProvider>().player1Color,
                player2Color: context.read<SettingsProvider>().player2Color,
                createGameScreen: (isP1Winner) async {
                  final audioService = context.read<AudioService>();
                  final settingsProvider = context.read<SettingsProvider>();
                  final controller = PairsController(
                    audioService: audioService,
                    settingsProvider: settingsProvider,
                    maxRounds: _maxRounds,
                    gridRows: _gridRows,
                    gridCols: _gridCols,
                  );
                  controller.initGame();
                  controller.setStartingPlayer(isP1Winner);
                  return PairsGameScreen(controller: controller);
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
}
