import 'package:flutter/material.dart';
import 'questions/questions_start_screen.dart';
import 'roulette/roulette_start_screen.dart';
import 'drinks/drinks_start_screen.dart';
import 'bomb/bomb_start_screen.dart';
import 'most_likely/most_likely_start_screen.dart';
import 'package:audioplayers/audioplayers.dart';
import '../widgets/neon_background.dart';
import 'dart:ui';

class GamesMenuScreen extends StatefulWidget {
  const GamesMenuScreen({super.key});

  @override
  State<GamesMenuScreen> createState() => _GamesMenuScreenState();
}

class _GamesMenuScreenState extends State<GamesMenuScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> _playSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/clic.mp3'));
    } catch (e) {
      // Ignore errors (fallback)
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NeonBackground(
        child: Column(
          children: [
            AppBar(
              title: const Text(
                'LOVEPLAY - JUEGOS',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: Colors.white,
                  shadows: [
                    Shadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 2)),
                  ],
                ),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
            ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                padding: const EdgeInsets.all(20),
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
        children: [
          _GameCard(
            title: 'Preguntas',
            icon: Icons.question_answer,
            color: Colors.orange,
            onTap: () {
              _playSound();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const QuestionsStartScreen()),
              );
            },
          ),
          _GameCard(
            title: 'Ruleta',
            icon: Icons.casino,
            color: Colors.blue,
            onTap: () {
              _playSound();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RouletteStartScreen()),
              );
            },
          ),
          _GameCard(
            title: 'Chupitos',
            icon: Icons.local_bar,
            color: Colors.red.shade900,
            onTap: () {
              _playSound();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DrinksStartScreen()),
              );
            },
          ),
          _GameCard(
            title: 'Lo Más Probable',
            icon: Icons.psychology,
            color: Colors.teal,
            onTap: () {
              _playSound();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MostLikelyStartScreen()),
              );
            },
          ),
          _GameCard(
            title: 'Bomba',
            icon: Icons.timer,
            color: Colors.deepOrange,
            onTap: () {
              _playSound();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BombStartScreen()),
              );
            },
          ),
          _GameCard(
            title: 'Otros',
            icon: Icons.more_horiz,
            color: Colors.blueGrey,
            onTap: () {},
            enabled: false,
          ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool enabled;

  const _GameCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 60, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (!enabled)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    'Próximamente',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
