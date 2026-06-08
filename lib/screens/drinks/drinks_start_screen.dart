import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../controllers/drinks_controller.dart';
import '../../services/audio_service.dart';
import '../../widgets/game_button.dart';
import '../../widgets/game_help_modal.dart';
import '../../widgets/player_names_section.dart';
import '../../widgets/neon_background.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/selection_chip.dart';
import 'drinks_game_screen.dart';

class DrinksStartScreen extends StatefulWidget {
  const DrinksStartScreen({super.key});

  @override
  State<DrinksStartScreen> createState() => _DrinksStartScreenState();
}

class _DrinksStartScreenState extends State<DrinksStartScreen> {
  String _player1Name = 'ÉL';
  String _player2Name = 'ELLA';
  int _sipsPerGlass = 5;
  int _initialLevel = 1;
  int _levelingSpeed = 7;
  bool _isHotMode = false;
  bool _freeMode = false;
  int _totalGlasses = 5;

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
                  'Superen desafíos y tomen tragos. '
                  'El primero en llegar al límite pierde.',
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
              _buildSectionTitle(
                  'SORBOS POR VASO', Icons.local_drink),
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
                          '$_sipsPerGlass',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            shadows: [
                              Shadow(
                                color: Colors.pinkAccent,
                                blurRadius: 10,
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _sipsPerGlass.toDouble(),
                      min: 1,
                      max: 7,
                      divisions: 6,
                      activeColor: Colors.pinkAccent,
                      inactiveColor: Colors.white10,
                      onChanged: (val) => setState(
                          () => _sipsPerGlass = val.toInt()),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('MODO DE JUEGO', Icons.sports_esports),
              const SizedBox(height: 8),
              GlassCard(
                child: Column(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: SwitchListTile(
                        title: const Text('Modo Libre',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900)),
                        subtitle: const Text(
                          'Sin límite de vasos — juego perpetuo',
                          style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12),
                        ),
                        value: _freeMode,
                        activeThumbColor: Colors.orangeAccent,
                        onChanged: (val) =>
                            setState(() => _freeMode = val),
                      ),
                    ),
                    if (!_freeMode) ...[
                      const Divider(color: Colors.white10),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'VASOS A TOMAR:',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SelectionChipRow(
                              options: [1, 3, 5, 7, 10, 15]
                                  .map((n) => n.toString())
                                  .toList(),
                              selectedIntValue: _totalGlasses,
                              onIntSelected: (v) => setState(
                                  () => _totalGlasses = v),
                              accentColor: Colors.pinkAccent,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Al alcanzar $_totalGlasses vasos el juego termina',
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle(
                  'NIVEL INICIAL', Icons.trending_up),
              const SizedBox(height: 8),
              GlassCard(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Intensidad:',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          'Nivel $_initialLevel',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            shadows: [
                              Shadow(
                                color: Colors.purpleAccent,
                                blurRadius: 10,
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _initialLevel.toDouble(),
                      min: 1,
                      max: 8,
                      divisions: 7,
                      activeColor: Colors.purpleAccent,
                      inactiveColor: Colors.white10,
                      onChanged: (val) => setState(
                          () => _initialLevel = val.toInt()),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle(
                  'AJUSTES ADICIONALES', Icons.tune),
              const SizedBox(height: 8),
              GlassCard(
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Text(
                        'Velocidad de Subida de Nivel',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          _buildSpeedOption('Rápido', 4,
                              Colors.pinkAccent),
                          const SizedBox(width: 8),
                          _buildSpeedOption('Medio', 7,
                              Colors.purpleAccent),
                          const SizedBox(width: 8),
                          _buildSpeedOption('Lento', 10,
                              Colors.blueAccent),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: Text(
                        'Sube de nivel cada $_levelingSpeed turnos',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Divider(color: Colors.white10),
                    Material(
                      color: Colors.transparent,
                      child: SwitchListTile(
                        title: const Text('Modo Hot',
                            style: TextStyle(
                                color: Colors.white)),
                        subtitle: const Text(
                          'Incluye retos picantes',
                          style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12),
                        ),
                        value: _isHotMode,
                        activeThumbColor: Colors.pink,
                        onChanged: (val) =>
                            setState(() => _isHotMode = val),
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
        'CHUPITOS',
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

  Widget _buildSpeedOption(
      String label, int speed, Color color) {
    bool isSelected = _levelingSpeed == speed;
    return Expanded(
      child: InkWell(
        onTap: () =>
            setState(() => _levelingSpeed = speed),
        child: Container(
          padding:
              const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isSelected
                  ? color
                  : Colors.white10,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.2),
                      blurRadius: 10,
                    )
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : Colors.white54,
              fontWeight: isSelected
                  ? FontWeight.w900
                  : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStartButton() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 40),
      child: GameButton(
        text: 'EMPEZAR',
        onPressed: () async {
          final settings = context.read<SettingsProvider>();
          await settings.setPlayer1Name(_player1Name);
          await settings.setPlayer2Name(_player2Name);
          if (!mounted) return;
          final audioService =
              context.read<AudioService>();
          final settingsProvider =
              context.read<SettingsProvider>();
          final controller = DrinksController(
            audioService: audioService,
            settingsProvider: settingsProvider,
            sipsPerGlass: _sipsPerGlass,
            initialLevel: _initialLevel,
            levelingSpeed: _levelingSpeed,
            isHotMode: _isHotMode,
            freeMode: _freeMode,
            totalGlasses: _totalGlasses,
          );
          await controller.initGame();
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  DrinksGameScreen(controller: controller),
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
            '1', 'Se muestran desafíos y tragos para cada jugador.'),
        GameHelpModal.step(
            '2', 'Cada jugador cumple su reto o bebe.'),
        GameHelpModal.step(
            '3', 'El primero en llegar al límite de tragos pierde.'),
        GameHelpModal.text(
            'Los desafíos pueden ser: tomar un trago, hacer una pregunta, '
            'o una acción especial.'),
      ],
    );
  }
}
