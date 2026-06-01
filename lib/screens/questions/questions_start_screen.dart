import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import 'coin_flip_screen.dart';
import '../../widgets/neon_background.dart';
import '../../widgets/player_names_section.dart';

class QuestionsStartScreen extends StatefulWidget {
  const QuestionsStartScreen({super.key});

  @override
  State<QuestionsStartScreen> createState() => _QuestionsStartScreenState();
}

class _QuestionsStartScreenState extends State<QuestionsStartScreen> {
  String _heName = 'ÉL';
  String _sheName = 'ELLA';
  int _selectedRounds = 10;
  final List<int> _roundOptions = [10, 20, 30, 40, 50];

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _heName = settings.heName;
    _sheName = settings.sheName;
  }

  final List<Map<String, dynamic>> _categories = [
    {'name': 'General', 'icon': Icons.all_inclusive, 'color': Colors.blue},
    {'name': 'Romántico', 'icon': Icons.favorite, 'color': Colors.pink},
    {'name': 'Picante', 'icon': Icons.whatshot, 'color': Colors.deepOrange},
    {'name': 'Convivencia', 'icon': Icons.home, 'color': Colors.green},
    {'name': 'Futuro', 'icon': Icons.rocket_launch, 'color': Colors.purple},
    {'name': 'Viajes', 'icon': Icons.flight, 'color': Colors.teal},
    {
      'name': 'Pasatiempos',
      'icon': Icons.sports_esports,
      'color': Colors.indigo,
    },
    {'name': 'Valores', 'icon': Icons.balance, 'color': Colors.brown},
    {'name': 'Humor', 'icon': Icons.mood, 'color': Colors.yellow.shade800},
    {'name': 'Profundo', 'icon': Icons.psychology, 'color': Colors.blueGrey},
    {'name': 'Trivia', 'icon': Icons.quiz, 'color': Colors.indigo},
    {
      'name': 'Flirteo',
      'icon': Icons.favorite_border,
      'color': Colors.redAccent,
    },
  ];
  final Set<String> _selectedCategories = {'General', 'Romántico'};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NeonBackground(
        child: Column(
          children: [
            AppBar(
              title: const Text(
                'CONFIGURAR PARTIDA',
                style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              foregroundColor: Colors.white,
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Jugadores', Icons.people),
                      const SizedBox(height: 15),
                      PlayerNamesSection(
                        onChanged: (he, she) => setState(() {
                          _heName = he;
                          _sheName = she;
                        }),
                      ),
                      const SizedBox(height: 30),
                      _buildSectionTitle('Número de Preguntas', Icons.timer),
                      const SizedBox(height: 15),
                      SizedBox(
                        height: 80,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _roundOptions.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final rounds = _roundOptions[index];
                            final isSelected = _selectedRounds == rounds;
                            return _RoundCard(
                              rounds: rounds,
                              isSelected: isSelected,
                              onTap: () =>
                                  setState(() => _selectedRounds = rounds),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 35),
                      _buildGlassCard(
                        child: Theme(
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
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _categories.map((cat) {
                                    final isSelected = _selectedCategories
                                        .contains(cat['name']);
                                    final catColor = cat['color'] as Color;
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          if (isSelected) {
                                            if (_selectedCategories.length >
                                                1) {
                                              _selectedCategories.remove(
                                                cat['name'],
                                              );
                                            }
                                          } else {
                                            _selectedCategories.add(
                                              cat['name'],
                                            );
                                          }
                                        });
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? catColor.withValues(alpha: 0.3)
                                              : Colors.white.withValues(
                                                  alpha: 0.08,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                          border: Border.all(
                                            color: isSelected
                                                ? catColor
                                                : Colors.white24,
                                            width: isSelected ? 2 : 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              cat['icon'] as IconData,
                                              color: isSelected
                                                  ? Colors.white
                                                  : Colors.white54,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              cat['name'] as String,
                                              style: TextStyle(
                                                color: isSelected
                                                    ? Colors.white
                                                    : Colors.white54,
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
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      _buildStartButton(context),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
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

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.pinkAccent, size: 24),
        const SizedBox(width: 10),
        Text(
          title.toUpperCase(),
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

  Widget _buildStartButton(BuildContext context) {
    return _buildGlassCard(
      child: InkWell(
        onTap: () async {
          final navigator = Navigator.of(context);
          await context.read<SettingsProvider>().saveNames(_heName, _sheName);
          if (!mounted) return;
          navigator.push(
            MaterialPageRoute(
              builder: (context) => CoinFlipScreen(
                maxRounds: _selectedRounds,
                categories: _selectedCategories.toList(),
                heName: _heName,
                sheName: _sheName,
              ),
            ),
          );
        },
        child: Container(
          width: double.infinity,
          height: 45,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.pink.withValues(alpha: 0.6),
                Colors.purple.withValues(alpha: 0.4),
              ],
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Text(
            '¡EMPEZAR PARTIDA!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundCard extends StatelessWidget {
  final int rounds;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoundCard({
    required this.rounds,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 70,
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? Colors.orange : Colors.grey.shade300,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$rounds',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              'Preg.',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white70 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
