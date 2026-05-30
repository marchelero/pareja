import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../controllers/drinks_controller.dart';
import '../../services/audio_service.dart';
import '../../widgets/player_names_section.dart';
import 'drinks_game_screen.dart';
import '../../widgets/neon_background.dart';

class DrinksStartScreen extends StatefulWidget {
  const DrinksStartScreen({super.key});

  @override
  State<DrinksStartScreen> createState() => _DrinksStartScreenState();
}

class _DrinksStartScreenState extends State<DrinksStartScreen> {
  String _heName = 'ÉL';
  String _sheName = 'ELLA';
  int _sipsPerGlass = 5;
  int _initialLevel = 1;
  int _levelingSpeed = 7;
  bool _isHotMode = true;

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
        title: const Text('CONFIGURACIÓN CHUPITOS', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: NeonBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
            _buildSectionTitle('Jugadores'),
            PlayerNamesSection(
              onChanged: (he, she) => setState(() {
                _heName = he;
                _sheName = she;
              }),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('SORBOS POR VASO'),
            _buildCard(
              child: Column(
                children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Cantidad:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
                        Text('$_sipsPerGlass', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, shadows: [Shadow(color: Colors.pinkAccent, blurRadius: 10)])),
                      ],
                    ),
                    Slider(
                      value: _sipsPerGlass.toDouble(),
                      min: 1,
                      max: 7,
                      divisions: 6,
                      activeColor: Colors.pinkAccent,
                      inactiveColor: Colors.white10,
                      onChanged: (val) => setState(() => _sipsPerGlass = val.toInt()),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('NIVEL INICIAL'),
            _buildCard(
              child: Column(
                children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Intensidad:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
                        Text('Nivel $_initialLevel', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, shadows: [Shadow(color: Colors.purpleAccent, blurRadius: 10)])),
                      ],
                    ),
                    Slider(
                      value: _initialLevel.toDouble(),
                      min: 1,
                      max: 8,
                      divisions: 7,
                      activeColor: Colors.purpleAccent,
                      inactiveColor: Colors.white10,
                      onChanged: (val) => setState(() => _initialLevel = val.toInt()),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('AJUSTES ADICIONALES'),
            _buildCard(
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text('Velocidad de Subida de Nivel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                          _buildSpeedOption('Rápido', 4, Colors.pinkAccent),
                          const SizedBox(width: 8),
                          _buildSpeedOption('Medio', 7, Colors.purpleAccent),
                          const SizedBox(width: 8),
                          _buildSpeedOption('Lento', 10, Colors.blueAccent),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Text(
                      'Sube de nivel cada $_levelingSpeed turnos',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ),
                  const Divider(color: Colors.white10),
                  SwitchListTile(
                    title: const Text('Modo Hot', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Incluye retos picantes', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    value: _isHotMode,
                    activeThumbColor: Colors.pink,
                    onChanged: (val) => setState(() => _isHotMode = val),
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
          width: double.infinity,
          height: 65,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.pink.withValues(alpha: 0.6), Colors.purple.withValues(alpha: 0.4)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(color: Colors.pink.withValues(alpha: 0.3), blurRadius: 15, spreadRadius: 2),
            ],
          ),
          child: InkWell(
            onTap: () async {
              await context.read<SettingsProvider>().saveNames(_heName, _sheName);
              if (!mounted) return;
              final audioService = context.read<AudioService>();
              final settingsProvider = context.read<SettingsProvider>();
              final controller = DrinksController(
                audioService: audioService,
                settingsProvider: settingsProvider,
                sipsPerGlass: _sipsPerGlass,
                initialLevel: _initialLevel,
                levelingSpeed: _levelingSpeed,
                isHotMode: _isHotMode,
              );
              await controller.initGame();
              if (!mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DrinksGameScreen(controller: controller),
                ),
              );
            },
            child: const Center(
              child: Text(
                '¡EMPEZAR!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
            ),
          ),
        ),
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

  Widget _buildSpeedOption(String label, int speed, Color color) {
    bool isSelected = _levelingSpeed == speed;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _levelingSpeed = speed),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: isSelected ? color : Colors.white10),
            boxShadow: isSelected ? [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 10)] : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white54,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
