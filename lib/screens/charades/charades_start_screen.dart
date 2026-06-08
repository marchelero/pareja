import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/audio_service.dart';
import '../../controllers/charades_controller.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/game_button.dart';
import '../../widgets/game_help_modal.dart';
import '../../widgets/neon_background.dart';
import '../../widgets/player_names_section.dart';
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

  @override
  void initState() {
    super.initState();
  }

  void _playSound() {
    context.read<AudioService>().playClick();
  }

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
      body: NeonBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        _playSound();
                        Navigator.pop(context);
                      },
                    ),
                    const Expanded(
                      child: Text(
                        'SIN PALABRAS',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    GameHelpModal.helpButton(_showHelpModal),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Act\u00faa sin hablar y haz que tu pareja adivine.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
              const SizedBox(height: 15),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: PlayerNamesSection(
                          player1Icon: context
                              .read<SettingsProvider>()
                              .player1Icon,
                          player2Icon: context
                              .read<SettingsProvider>()
                              .player2Icon,
                          player1Color: context
                              .read<SettingsProvider>()
                              .player1Color,
                          player2Color: context
                              .read<SettingsProvider>()
                              .player2Color,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildSettingsCard(),
                      const SizedBox(height: 25),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 20,
                ),
                child: GameButton(
                  text: 'EMPEZAR',
                  onPressed: _selectedCategories.isEmpty
                      ? () {}
                      : () async {
                          _playSound();
                          final audioService = context.read<AudioService>();
                          final settingsProvider = context
                              .read<SettingsProvider>();
                          final controller = CharadesController(
                            audioService: audioService,
                            settingsProvider: settingsProvider,
                            selectedCategories: _selectedCategories.toList(),
                            singleCategoryMode: _singleCategoryMode,
                            timerSeconds: _timerSeconds,
                            pointsToWin: _pointsToWin,
                            strikesForPenance: _strikesForPenance,
                            isHotMode: _isHotMode,
                          );
                          await controller.initGame();
                          if (!context.mounted) return;
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  CharadesGameScreen(controller: controller),
                            ),
                          );
                        },
                  style: GameButtonStyle.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Column(
              children: [
                Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                    unselectedWidgetColor: Colors.white54,
                  ),
                  child: Material(
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
                      title: Text(
                        'CATEGOR\u00cdAS',
                        style: const TextStyle(
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
                        _buildSettingRow(
                          icon: Icons.shuffle,
                          iconColor: Colors.amberAccent,
                          title: _singleCategoryMode
                              ? 'Categor\u00eda \u00fanica (al azar)'
                              : 'Varias categor\u00edas',
                          child: Switch(
                            value: _singleCategoryMode,
                            onChanged: (value) {
                              _playSound();
                              setState(() => _singleCategoryMode = value);
                            },
                            activeThumbColor: Colors.amberAccent,
                            activeTrackColor: Colors.amberAccent.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(color: Colors.white12, height: 1),
                ),
                _buildSettingRow(
                  icon: Icons.hourglass_bottom,
                  title: 'Tiempo:',
                  child: DropdownButton<int>(
                    value: _timerSeconds,
                    dropdownColor: Colors.black87,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    underline: const SizedBox(),
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.white70,
                    ),
                    items: [30, 45, 60].map((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text('$value s'),
                      );
                    }).toList(),
                    onChanged: (int? newValue) {
                      if (newValue != null) {
                        _playSound();
                        setState(() => _timerSeconds = newValue);
                      }
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(color: Colors.white12, height: 1),
                ),
                _buildSettingRow(
                  icon: Icons.emoji_events,
                  title: 'Puntos para ganar:',
                  child: DropdownButton<int>(
                    value: _pointsToWin,
                    dropdownColor: Colors.black87,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    underline: const SizedBox(),
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.white70,
                    ),
                    items: [3, 5, 7].map((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text('$value'),
                      );
                    }).toList(),
                    onChanged: (int? newValue) {
                      if (newValue != null) {
                        _playSound();
                        setState(() => _pointsToWin = newValue);
                      }
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(color: Colors.white12, height: 1),
                ),
                _buildSettingRow(
                  icon: Icons.flash_on,
                  title: 'Strikes por penitencia:',
                  child: DropdownButton<int>(
                    value: _strikesForPenance,
                    dropdownColor: Colors.black87,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    underline: const SizedBox(),
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.white70,
                    ),
                    items: [5, 7].map((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text('$value'),
                      );
                    }).toList(),
                    onChanged: (int? newValue) {
                      if (newValue != null) {
                        _playSound();
                        setState(() => _strikesForPenance = newValue);
                      }
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(color: Colors.white12, height: 1),
                ),
                _buildSettingRow(
                  icon: Icons.whatshot,
                  iconColor: Colors.pinkAccent,
                  title: 'Modo Hot',
                  child: Switch(
                    value: _isHotMode,
                    onChanged: (value) {
                      _playSound();
                      setState(() => _isHotMode = value);
                    },
                    activeThumbColor: Colors.pinkAccent,
                    activeTrackColor: Colors.pinkAccent.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
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
        if (isHotCategory && !_isHotMode) return const SizedBox.shrink();
        return GestureDetector(
          onTap: () => _toggleCategory(e.key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.deepPurple.withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isSelected ? Colors.deepPurple : Colors.white12,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _categoryIcons[e.key],
                  color: isSelected ? Colors.white : Colors.white54,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  e.value,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white54,
                    fontSize: 13,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    Color iconColor = Colors.white70,
    required String title,
    required Widget child,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 15),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        child,
      ],
    );
  }

  void _showHelpModal() {
    GameHelpModal.show(
      context: context,
      sections: [
        GameHelpModal.step('1', 'Tu pareja debe adivinar la palabra que aparece en pantalla.'),
        GameHelpModal.step('2', 'Tú haces gestos y señas sin hablar ni deletrear.'),
        GameHelpModal.step('3', 'Tienes 60 segundos para adivinar. Si aciertas, ganan.'),
        GameHelpModal.bullet('Adivina', 'suman un punto.', Colors.greenAccent, ''),
        GameHelpModal.bullet('No adivina', 'penitencia.', Colors.redAccent, ''),
      ],
    );
  }
}
