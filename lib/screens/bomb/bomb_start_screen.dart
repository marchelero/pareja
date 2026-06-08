import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/audio_service.dart';
import '../../controllers/bomb_controller.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/game_button.dart';
import '../../widgets/game_help_modal.dart';
import '../../widgets/neon_background.dart';
import '../../widgets/player_names_section.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/setting_row.dart';
import 'bomb_game_screen.dart';

class BombStartScreen extends StatefulWidget {
  const BombStartScreen({super.key});

  @override
  State<BombStartScreen> createState() => _BombStartScreenState();
}

class _BombStartScreenState extends State<BombStartScreen> {
  bool _isHotMode = false;
  int _bestOf = 3;
  int _bombTimer = 5;

  bool _optPanic = false;
  bool _optGold = false;
  bool _optWild = false;
  bool _optAccel = false;

  void _playSound() => context.read<AudioService>().playClick();

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
                  'El primero en quedarse sin respuestas '
                  'le da 1 punto al rival.',
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
                onChanged: (p1, p2) {},
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('CONFIGURACIÓN', Icons.tune),
              const SizedBox(height: 8),
              GlassCard(
                child: Column(
                  children: [
                    SettingRow(
                      icon: Icons.emoji_events,
                      title: 'Formato:',
                      child: SettingDropdown<int>(
                        value: _bestOf,
                        items: [3, 5, 7],
                        labelBuilder: (v) => 'Al mejor de $v',
                        onChanged: (v) {
                          if (v != null) {
                            _playSound();
                            setState(() => _bestOf = v);
                          }
                        },
                      ),
                    ),
                    const SettingDivider(),
                    SettingRow(
                      icon: Icons.hourglass_bottom,
                      title: 'Tiempo:',
                      child: SettingDropdown<int>(
                        value: _bombTimer,
                        items: [5, 7],
                        labelBuilder: (v) => '$v Segundos',
                        onChanged: (v) {
                          if (v != null) {
                            _playSound();
                            setState(() => _bombTimer = v);
                          }
                        },
                      ),
                    ),
                    const SettingDivider(),
                    SettingRow(
                      icon: Icons.whatshot,
                      iconColor: Colors.pinkAccent,
                      title: 'Modo Hot',
                      child: SettingSwitch(
                        value: _isHotMode,
                        onChanged: (v) {
                          _playSound();
                          setState(() => _isHotMode = v);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildModifiersSection(),
              const SizedBox(height: 20),
              _buildModifierExplanations(),
              const SizedBox(height: 20),
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
        'LA BOMBA',
        style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios),
        onPressed: () {
          _playSound();
          Navigator.pop(context);
        },
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

  Widget _buildModifiersSection() {
    return Column(
      children: [
        const Text(
          'REGLAS GLOBALES (Toda la partida)',
          style: TextStyle(
            color: Colors.white54,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildModifierBtn(
                'Pánico', Icons.visibility_off, _optPanic,
                (v) => setState(() => _optPanic = v)),
            const SizedBox(width: 20),
            _buildModifierBtn(
                'Acelerar', Icons.speed, _optAccel,
                (v) => setState(() => _optAccel = v)),
          ],
        ),
        const SizedBox(height: 15),
        const Text(
          'EVENTOS (Turnos específicos)',
          style: TextStyle(
            color: Colors.white54,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildModifierBtn(
                'Dorado', Icons.star, _optGold,
                (v) => setState(() => _optGold = v)),
            const SizedBox(width: 20),
            _buildModifierBtn(
                'Comodín', Icons.style, _optWild,
                (v) => setState(() => _optWild = v)),
          ],
        ),
      ],
    );
  }

  Widget _buildModifierBtn(
    String label,
    IconData icon,
    bool isActive,
    Function(bool) onChanged,
  ) {
    return GestureDetector(
      onTap: () {
        _playSound();
        onChanged(!isActive);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 70,
        height: 75,
        decoration: BoxDecoration(
          color: isActive
              ? Colors.deepOrange.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isActive ? Colors.deepOrange : Colors.white12,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: isActive ? Colors.amber : Colors.white54,
                size: 28),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white54,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModifierExplanations() {
    if (!_optPanic && !_optGold && !_optWild && !_optAccel) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 40),
        child: Text(
          'Selecciona modificadores arriba para ver qué hacen.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white30,
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 30),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
            color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_optPanic)
            _buildExplanationRow(Icons.visibility_off,
                'Pánico: Oculta los números del reloj', Colors.white70),
          if (_optGold)
            _buildExplanationRow(Icons.star,
                'Dorado: Rondas al azar valen 2 puntos', Colors.amber),
          if (_optWild)
            _buildExplanationRow(Icons.style,
                'Comodín: 1 uso por partida para cambiar categoría',
                Colors.white70),
          if (_optAccel)
            _buildExplanationRow(Icons.speed,
                'Acelerar: El tiempo baja con cada toque', Colors.white70),
        ],
      ),
    );
  }

  Widget _buildExplanationRow(
      IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: TextStyle(color: color, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: GameButton(
        text: 'EMPEZAR',
        onPressed: () async {
          _playSound();
          final audioService = context.read<AudioService>();
          final settingsProvider = context.read<SettingsProvider>();
          final controller = BombController(
            audioService: audioService,
            settingsProvider: settingsProvider,
            isHotMode: _isHotMode,
            bestOf: _bestOf,
            timerSeconds: _bombTimer,
            optPanic: _optPanic,
            optGold: _optGold,
            optWild: _optWild,
            optAccel: _optAccel,
          );
          await controller.initGame();
          if (!context.mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  BombGameScreen(controller: controller),
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
            '1', 'Se muestra una categoría y un tiempo límite.'),
        GameHelpModal.step(
            '2',
            'Di una palabra relacionada con la categoría y '
            'toca la pantalla para pasar la bomba.'),
        GameHelpModal.step(
            '3',
            'El que se quede sin respuestas cuando explote la bomba pierde.'),
        GameHelpModal.bullet(null, 'Pierde la ronda', Colors.redAccent,
            'el rival suma 1 punto'),
        GameHelpModal.text(
          'Configuración adicional: Pánico (oculta el tiempo), '
          'Acelerar (menos tiempo cada vez), '
          'Dorado (rondas especiales de 2 puntos), '
          'Comodín (una ayuda por partida).',
        ),
      ],
    );
  }
}
