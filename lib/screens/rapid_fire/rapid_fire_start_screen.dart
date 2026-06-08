import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../controllers/rapid_fire_controller.dart';
import '../../services/audio_service.dart';
import '../../widgets/game_button.dart';
import '../../widgets/game_help_modal.dart';
import '../../widgets/neon_background.dart';
import '../../widgets/player_names_section.dart';
import '../../widgets/glass_card.dart';
import '../../core/theme/app_colors.dart';
import 'rapid_fire_game_screen.dart';

class RapidFireStartScreen extends StatefulWidget {
  const RapidFireStartScreen({super.key});

  @override
  State<RapidFireStartScreen> createState() =>
      _RapidFireStartScreenState();
}

class _RapidFireStartScreenState extends State<RapidFireStartScreen> {
  int _targetScore = 10;
  String _player1Name = 'ÉL';
  String _player2Name = 'ELLA';
  Set<String> _allCategories = {};
  Set<String> _selectedCategories = {};
  bool _loading = true;

  static const _categoryIcons = {
    'Geografía': Icons.public,
    'Historia': Icons.auto_stories,
    'Ciencia': Icons.science,
    'Cultura General': Icons.lightbulb,
    'Películas': Icons.movie,
    'Música': Icons.music_note,
    'Deportes': Icons.sports_soccer,
    'Naturaleza': Icons.park,
    'Entretenimiento': Icons.videogame_asset,
    'Hot': Icons.favorite,
  };

  static const _categoryColors = {
    'Geografía': Color(0xFF4CAF50),
    'Historia': Color(0xFFFF9800),
    'Ciencia': Color(0xFF2196F3),
    'Cultura General': Color(0xFF9C27B0),
    'Películas': Color(0xFFE91E63),
    'Música': Color(0xFF00BCD4),
    'Deportes': Color(0xFFFF5722),
    'Naturaleza': Color(0xFF8BC34A),
    'Entretenimiento': Color(0xFF3F51B5),
    'Hot': Color(0xFFF44336),
  };

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/data/rapid_fire_questions.json',
      );
      final List<dynamic> data = json.decode(response);
      final cats = <String>{};
      for (final q in data) {
        final c = q['c'] as String?;
        if (c != null && c.isNotEmpty) cats.add(c);
      }
      if (!mounted) return;
      final sorted = cats.toList()..sort();
      setState(() {
        _allCategories = cats;
        _selectedCategories = sorted.take(3).toSet();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
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
                  'Respondan preguntas contrarreloj en distintas categorías. '
                  'Gana quien acierte más.',
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
                  _player1Name = p1;
                  _player2Name = p2;
                },
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('CATEGORÍAS', Icons.category),
              const SizedBox(height: 8),
              GlassCard(
                child: _loading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(
                              strokeWidth: 2),
                        ),
                      )
                    : _buildCategoryGrid(),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle(
                  'PUNTOS PARA GANAR', Icons.emoji_events),
              const SizedBox(height: 8),
              GlassCard(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Meta:',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          '$_targetScore',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            shadows: [
                              Shadow(
                                color: AppColors.modeRapidFire,
                                blurRadius: 10,
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _targetScore.toDouble(),
                      min: 3,
                      max: 20,
                      divisions: 17,
                      activeColor: AppColors.modeRapidFire,
                      inactiveColor: Colors.white10,
                      onChanged: (val) =>
                          setState(() => _targetScore = val.toInt()),
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
        'ALTO AL FUEGO',
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

  Widget _buildCategoryGrid() {
    final entries = _allCategories.toList()..sort();
    if (entries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text(
          'No se encontraron categorías',
          style: TextStyle(color: Colors.white54, fontSize: 14),
        ),
      );
    }

    return Column(
      children: [
        Text(
          'Selecciona las categorías',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: entries
              .map((cat) => _buildCategoryChip(cat))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String cat) {
    final selected = _selectedCategories.contains(cat);
    final icon = _categoryIcons[cat] ?? Icons.category;
    final Color chipColor =
        _categoryColors[cat] ?? AppColors.modeRapidFire;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (selected) {
            _selectedCategories.remove(cat);
          } else {
            _selectedCategories.add(cat);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? chipColor.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? chipColor.withValues(alpha: 0.7)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: selected ? chipColor : Colors.white54),
            const SizedBox(width: 6),
            Text(
              cat,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white54,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
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
          if (_selectedCategories.isEmpty &&
              _allCategories.isNotEmpty) return;
          final audioService = context.read<AudioService>();
          final settingsProvider =
              context.read<SettingsProvider>();
          if (_player1Name.isNotEmpty &&
              _player2Name.isNotEmpty) {
            await settingsProvider
                .setPlayer1Name(_player1Name);
            await settingsProvider
                .setPlayer2Name(_player2Name);
          }
          final controller = RapidFireController(
            audioService: audioService,
            settingsProvider: settingsProvider,
            targetScore: _targetScore,
          );
          controller.setSelectedCategories(_selectedCategories);
          await controller.initGame();
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  RapidFireGameScreen(controller: controller),
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
            '1', 'Sale una pregunta de opción múltiple.'),
        GameHelpModal.step(
            '2', 'El primero en responder correctamente gana el punto.'),
        GameHelpModal.step(
            '3', 'Si respondes mal, el otro puede robar la respuesta.'),
        GameHelpModal.bullet(null, 'Respuesta correcta', Colors.greenAccent,
            'sumas 1 punto.'),
        GameHelpModal.bullet(null, 'Gana la partida', Colors.amberAccent,
            'quien llegue primero a la puntuación objetivo.'),
      ],
    );
  }
}
