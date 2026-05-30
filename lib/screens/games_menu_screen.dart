import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audio_service.dart';
import 'questions/questions_start_screen.dart';
import 'roulette/roulette_start_screen.dart';
import 'drinks/drinks_start_screen.dart';
import 'bomb/bomb_start_screen.dart';
import 'never_have_i_ever/never_have_i_ever_start_screen.dart';
import 'charades/charades_start_screen.dart';
import '../widgets/neon_background.dart';

class GamesMenuScreen extends StatelessWidget {
  const GamesMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final audioService = context.read<AudioService>();

    return Scaffold(
      body: NeonBackground(
        child: Column(
          children: [
            AppBar(
              title: const Text('DATE GAMES \u{1F319} JUEGOS', style: TextStyle(
                fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.white,
                shadows: [Shadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 2))],
              )),
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
                    title: 'Preguntas', icon: Icons.question_answer, color: Colors.orange,
                    onTap: () { audioService.playClick(); Navigator.push(context, MaterialPageRoute(builder: (context) => const QuestionsStartScreen())); },
                  ),
                  _GameCard(
                    title: 'Ruleta', icon: Icons.casino, color: Colors.blue,
                    onTap: () { audioService.playClick(); Navigator.push(context, MaterialPageRoute(builder: (context) => const RouletteStartScreen())); },
                  ),
                  _GameCard(
                    title: 'Chupitos', icon: Icons.local_bar, color: Colors.red.shade900,
                    onTap: () { audioService.playClick(); Navigator.push(context, MaterialPageRoute(builder: (context) => const DrinksStartScreen())); },
                  ),
                  _GameCard(
                    title: 'Bomba', icon: Icons.timer, color: Colors.deepOrange,
                    onTap: () { audioService.playClick(); Navigator.push(context, MaterialPageRoute(builder: (context) => const BombStartScreen())); },
                  ),
                  _GameCard(
                    title: 'Yo Nunca', icon: Icons.psychology, color: Colors.teal,
                    onTap: () { audioService.playClick(); Navigator.push(context, MaterialPageRoute(builder: (context) => const NeverHaveIEverStartScreen())); },
                  ),
                  _GameCard(
                    title: 'Dígalo con Mímica', icon: Icons.theater_comedy, color: Colors.deepPurple,
                    onTap: () { audioService.playClick(); Navigator.push(context, MaterialPageRoute(builder: (context) => const CharadesStartScreen())); },
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

  const _GameCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: Colors.white),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
