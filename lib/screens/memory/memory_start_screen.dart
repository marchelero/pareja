import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/memory_controller.dart';
import '../../services/audio_service.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/neon_background.dart';
import '../../widgets/player_names_section.dart';
import '../../core/theme/app_colors.dart';
import 'memory_game_screen.dart';

class MemoryStartScreen extends StatefulWidget {
  const MemoryStartScreen({super.key});

  @override
  State<MemoryStartScreen> createState() => _MemoryStartScreenState();
}

class _MemoryStartScreenState extends State<MemoryStartScreen> {
  String _heName = 'ÉL';
  String _sheName = 'ELLA';
  int _maxRounds = 8;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _heName = settings.heName;
    _sheName = settings.sheName;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('MEMORIA', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold)),
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
                onChanged: (he, she) => setState(() {
                  _heName = he;
                  _sheName = she;
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
                        const Text('Cantidad:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
                        Text('$_maxRounds', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, shadows: [Shadow(color: AppColors.modeMemory, blurRadius: 10)])),
                      ],
                    ),
                    Slider(
                      value: _maxRounds.toDouble(), min: 3, max: 15, divisions: 12,
                      activeColor: AppColors.modeMemory,
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity, height: 65,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.modeMemory.withValues(alpha: 0.6), Colors.blue.withValues(alpha: 0.3)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            boxShadow: [BoxShadow(color: AppColors.modeMemory.withValues(alpha: 0.3), blurRadius: 15, spreadRadius: 2)],
          ),
          child: InkWell(
            onTap: () async {
              await context.read<SettingsProvider>().saveNames(_heName, _sheName);
              if (!mounted) return;
              final audioService = context.read<AudioService>();
              final settingsProvider = context.read<SettingsProvider>();
              final controller = MemoryController(
                audioService: audioService,
                settingsProvider: settingsProvider,
                maxRounds: _maxRounds,
              );
              await controller.initGame();
              if (!mounted) return;
              Navigator.push(context, MaterialPageRoute(
                builder: (context) => MemoryGameScreen(controller: controller),
              ));
            },
            child: const Center(child: Text('¡EMPEZAR!', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 3))),
          ),
        ),
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
