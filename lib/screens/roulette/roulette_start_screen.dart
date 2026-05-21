import 'package:flutter/material.dart';
import '../../core/storage/local_storage.dart';
import '../questions/coin_flip_screen.dart';
import '../../widgets/neon_background.dart';
import '../../widgets/player_names_section.dart';
import 'dart:ui';

class RouletteStartScreen extends StatefulWidget {
  const RouletteStartScreen({super.key});

  @override
  State<RouletteStartScreen> createState() => _RouletteStartScreenState();
}

class _RouletteStartScreenState extends State<RouletteStartScreen> {
  String _heName = 'ÉL';
  String _sheName = 'ELLA';
  bool _isDareMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NeonBackground(
        child: Column(
          children: [
            AppBar(
              title: const Text('CARTAS - CONFIGURAR', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
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
              _buildSectionTitle('Tipo de Ruleta', Icons.auto_awesome),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: _ModeCard(
                      title: 'Normal',
                      subtitle: 'Diversión suave',
                      icon: Icons.sentiment_satisfied,
                      color: Colors.blue,
                      isSelected: !_isDareMode,
                      onTap: () => setState(() => _isDareMode = false),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _ModeCard(
                      title: 'Atrevida',
                      subtitle: 'Más picante',
                      icon: Icons.whatshot,
                      color: Colors.deepOrange,
                      isSelected: _isDareMode,
                      onTap: () => setState(() => _isDareMode = true),
                    ),
                  ),
                ],
              ),
                      const SizedBox(height: 40),
                      _buildStartButton(context),
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

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildStartButton(BuildContext context) {
    return _buildGlassCard(
      child: InkWell(
        onTap: () async {
          await LocalStorage.saveNames(_heName, _sheName);

          if (!context.mounted) return;

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CoinFlipScreen(
                maxRounds: 0,
                categories: const [],
                heName: _heName,
                sheName: _sheName,
                isRoulette: true,
                isDareMode: _isDareMode,
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
              colors: [Colors.pink.withOpacity(0.6), Colors.purple.withOpacity(0.4)],
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Text(
            '¡EMPEZAR!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2),
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.6) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: isSelected ? color : Colors.white.withOpacity(0.1), width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: isSelected ? Colors.white : color),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: isSelected ? Colors.white70 : Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
