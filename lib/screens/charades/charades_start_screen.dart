import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/audio_service.dart';
import '../../controllers/charades_controller.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/game_button.dart';
import '../../widgets/game_help_modal.dart';
import '../../widgets/neon_background.dart';
import '../../widgets/player_names_section.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/setting_row.dart';
import '../../widgets/selection_chip.dart';
import 'charades_game_screen.dart';

class CharadesStartScreen extends StatefulWidget {
  const CharadesStartScreen({super.key});

  @override
  State<CharadesStartScreen> createState() => _CharadesStartScreenState();
}

class _CharadesStartScreenState extends State<CharadesStartScreen> {
  static const Map<String, String> _categoryLabels = {
    'peliculas': 'Pel\u00edculas',
    'canciones': 'Canciones',
    'series': 'Series',
    'personajes': 'Personajes',
    'celebridades': 'Celebridades',
    'animales': 'Animales',
    'profesiones': 'Profesiones',
    'comidas': 'Comidas',
    'acciones': 'Acciones Cotidianas',
    'lugares': 'Lugares',
    'deportes': 'Deportes',
    'superheroes': 'Superh\u00e9roes',
    'disney': 'Disney',
    'videojuegos': 'Videojuegos',
    'posiciones_sexuales': 'Posiciones Sexuales',
    'libros': 'Libros',
    'marcas': 'Marcas',
    'bailes': 'Bailes',
  };

  static const Map<String, IconData> _categoryIcons = {
    'peliculas': Icons.movie,
    'canciones': Icons.music_note,
    'series': Icons.tv,
    'personajes': Icons.face,
    'celebridades': Icons.star,
    'animales': Icons.pets,
    'profesiones': Icons.work,
    'comidas': Icons.restaurant,
    'acciones': Icons.directions_run,
    'lugares': Icons.public,
    'deportes': Icons.sports_soccer,
    'superheroes': Icons.flash_on,
    'disney': Icons.castle,
    'videojuegos': Icons.videogame_asset,
    'posiciones_sexuales': Icons.favorite,
    'libros': Icons.menu_book,
    'marcas': Icons.local_offer,
    'bailes': Icons.redeem,
  };

  final Set<String> _selectedCategories = {'peliculas'};
  int _timerSeconds = 30;
  int _pointsToWin = 3;
  int _strikesForPenance = 5;
  bool _isHotMode = false;
  bool _singleCategoryMode = false;

  void _playSound() => context.read<AudioService>().playClick();

  void _toggleCategory(String key) {
    _playSound();
    setState(() {
      if (_selectedCategories.contains(key)) {
        _selectedCategories.remove(key);
      } else {
        _selectedCategories.add(key);
      }
    });
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
                  'Act\u00faa sin hablar y haz que tu pareja adivine.',
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
                    _buildCategoriesSection(),
                    const SettingDivider(),
                    SettingRow(
                      icon: Icons.hourglass_bottom,
                      title: 'Tiempo:',
                      child: SettingDropdown<int>(
                        value: _timerSeconds,
                        items: [30, 45, 60],
                        labelBuilder: (v) => '$v s',
                        onChanged: (v) {
                          if (v != null) {
                            _playSound();
                            setState(() => _timerSeconds = v);
                          }
                        },
                      ),
                    ),
                    const SettingDivider(),
                    SettingRow(
                      icon: Icons.emoji_events,
                      title: 'Puntos para ganar:',
                      child: SettingDropdown<int>(
                        value: _pointsToWin,
                        items: [3, 5, 7],
                        labelBuilder: (v) => '$v',
                        onChanged: (v) {
                          if (v != null) {
                            _playSound();
                            setState(() => _pointsToWin = v);
                          }
                        },
                      ),
                    ),
                    const SettingDivider(),
                    SettingRow(
                      icon: Icons.flash_on,
                      title: 'Strikes por penitencia:',
                      child: SettingDropdown<int>(
                        value: _strikesForPenance,
                        items: [5, 7],
                        labelBuilder: (v) => '$v',
                        onChanged: (v) {
                          if (v != null) {
                            _playSound();
                            setState(() => _strikesForPenance = v);
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
        'SIN PALABRAS',
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

  Widget _buildCategoriesSection() {
    return Material(
      type: MaterialType.transparency,
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        initiallyExpanded: true,
        leading: const Icon(
          Icons.category,
          color: Colors.white70,
          size: 24,
        ),
        title: const Text(
          'CATEGOR\u00cdAS',
          style: TextStyle(
            color: Colors.white54,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            fontSize: 12,
          ),
        ),
        children: [
          const SizedBox(height: 8),
          _buildCategoriesGrid(),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.shuffle,
                      color: Colors.amberAccent, size: 24),
                  const SizedBox(width: 15),
                  Text(
                    _singleCategoryMode
                        ? 'Categor\u00eda \u00fanica (al azar)'
                        : 'Varias categor\u00edas',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Switch(
                value: _singleCategoryMode,
                onChanged: (value) {
                  _playSound();
                  setState(() => _singleCategoryMode = value);
                },
                activeThumbColor: Colors.amberAccent,
                activeTrackColor:
                    Colors.amberAccent.withValues(alpha: 0.5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesGrid() {
    final entries = _categoryLabels.entries.toList();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: entries.map((e) {
        final isSelected = _selectedCategories.contains(e.key);
        final isHotCategory = e.key == 'posiciones_sexuales';
        if (isHotCategory && !_isHotMode) {
          return const SizedBox.shrink();
        }
        return CategoryChip(
          label: e.value,
          icon: _categoryIcons[e.key] ?? Icons.category,
          isSelected: isSelected,
          chipColor: Colors.deepPurple,
          onTap: () => _toggleCategory(e.key),
        );
      }).toList(),
    );
  }

  Widget _buildStartButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: GameButton(
        text: 'EMPEZAR',
        onPressed: _selectedCategories.isEmpty
            ? () {}
            : () async {
                _playSound();
                final audioService = context.read<AudioService>();
                final settingsProvider =
                    context.read<SettingsProvider>();
                final controller = CharadesController(
                  audioService: audioService,
                  settingsProvider: settingsProvider,
                  selectedCategories:
                      _selectedCategories.toList(),
                  singleCategoryMode: _singleCategoryMode,
                  timerSeconds: _timerSeconds,
                  pointsToWin: _pointsToWin,
                  strikesForPenance: _strikesForPenance,
                  isHotMode: _isHotMode,
                );
                await controller.initGame();
                if (!mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CharadesGameScreen(
                        controller: controller),
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
            '1', 'Tu pareja debe adivinar la palabra que aparece en pantalla.'),
        GameHelpModal.step(
            '2', 'Tú haces gestos y señas sin hablar ni deletrear.'),
        GameHelpModal.step(
            '3', 'Tienes 60 segundos para adivinar. Si aciertas, ganan.'),
        GameHelpModal.bullet(
            'Adivina', 'suman un punto.', Colors.greenAccent, ''),
        GameHelpModal.bullet(
            'No adivina', 'penitencia.', Colors.redAccent, ''),
      ],
    );
  }
}
